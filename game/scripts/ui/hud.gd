extends CanvasLayer

## HUD: HP, XP, level, timer, kills, dash cooldown.

@onready var hp_bar: ProgressBar = $MarginContainer/VBox/HPBar
@onready var character_hp_bar: Control = $MarginContainer/VBox/CharacterHPBar
@onready var xp_bar: ProgressBar = $MarginContainer/VBox/XPBar
@onready var level_label: Label = $MarginContainer/VBox/LevelLabel
@onready var fps_label: Label = $MarginContainer/VBox/FPSLabel
@onready var time_label: Label = $TopRight/TimeLabel
@onready var kill_label: Label = $TopRight/KillLabel
@onready var dash_label: Label = $BottomCenter/DashVBox/DashLabel
@onready var dash_cooldown_bar: ProgressBar = $BottomCenter/DashVBox/DashCooldownBar
@onready var event_label: Label = $EventNotification/EventLabel

var event_display_timer: float = 0.0
var achievement_check_timer: float = 0.0

# Damage feedback on HP bar
var _ghost_hp: float = -1.0  # Ghost bar value (delayed HP loss indicator)
var _ghost_hp_delay: float = 0.0  # Timer before ghost starts draining
var _hp_punch_timer: float = 0.0  # HP bar shake timer
var _hp_bar_original_pos: Vector2 = Vector2.ZERO
var _prev_hp: int = -1  # Track HP changes for flash

# Weapon/Item icon containers and boss HP bar (created in _ready)
var weapon_container: HBoxContainer
var item_container: HBoxContainer
var boss_hp_bar: ProgressBar
var boss_name_label: Label

# Cache to avoid rebuilding every frame
var _prev_weapon_hash: String = ""
var _prev_item_hash: String = ""

# Synergy display
var synergy_container: Control = null
var _synergy_update_timer: float = 0.0
var _prev_synergy_hash: String = ""

# Achievement popup handled by AchievementPopup autoload (CanvasLayer)

# Multiplayer HUD (delegated to HUDMultiplayer)
var _mp_hud: HUDMultiplayer = null

# Minimap
var minimap: Control = null

# XP progress text label (overlaid on XP bar)
var _xp_text_label: Label = null
var _prev_boss_hp: float = -1.0
var _boss_ghost_hp: float = -1.0
var _boss_shake_timer: float = 0.0

# Chest arrows and quest display
var _chest_arrows: Dictionary = {}  # chest_instance_id -> Label
var _merchant_arrow: Label = null  # Seta apontando para o mercador
var _quest_label: Label = null
var _quest_progress_bar: ProgressBar = null

# Achievement tracker
var _achievement_tracker: Control = null

# Damage vignette overlay
var _damage_vignette: ColorRect = null

func _ready() -> void:
	GameManager.player_leveled_up.connect(_on_level_up)
	GameManager.game_over.connect(_on_game_over)
	event_label.visible = false

	# Setup weapon icons container (bottom-left) and item icons (bottom-right)
	weapon_container = $WeaponPanel/WeaponIcons
	weapon_container.add_theme_constant_override("separation", GameConstants.HUD_ICON_SEPARATION)
	item_container = $ItemPanel/ItemIcons
	item_container.add_theme_constant_override("separation", GameConstants.HUD_ICON_SEPARATION)
	boss_hp_bar = $BossHPBar
	boss_hp_bar.visible = false

	# Boss name label — centered above boss HP bar
	boss_name_label = Label.new()
	boss_name_label.name = "BossNameLabel"
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 16)
	boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	boss_name_label.add_theme_constant_override("outline_size", 2)
	boss_name_label.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0))
	boss_name_label.anchor_left = 0.3
	boss_name_label.anchor_right = 0.7
	boss_name_label.offset_top = 30.0
	boss_name_label.offset_bottom = 50.0
	boss_name_label.visible = false
	add_child(boss_name_label)

	# Connect boss_spawned signal for boss name display
	GameManager.boss_spawned.connect(_on_boss_spawned)

	# Conecta ao EventManager se existir
	await get_tree().process_frame
	var em = get_tree().current_scene.get_node_or_null("EventManager") if get_tree().current_scene else null
	if em and em.has_signal("event_started"):
		em.event_started.connect(_on_event_started)
		em.event_ended.connect(_on_event_ended)
		em.event_warning.connect(_on_event_warning)

	# Miniboss name display
	GameManager.miniboss_spawned.connect(_on_miniboss_spawned)

	# Achievement popup handled by AchievementPopup autoload

	# HP bar do HUD escondida — player tem barra world-space agora
	hp_bar.visible = false
	character_hp_bar.visible = false
	_prev_hp = GameManager.player_hp

	# Connect damage feedback signal
	if ScreenEffects.has_signal("player_took_damage"):
		ScreenEffects.player_took_damage.connect(_on_player_took_damage)

	# XP bar hidden — player has world-space XP bar below HP near character
	xp_bar.visible = false

	# PRD 57: Evolution tracker
	var evo_script = load("res://scripts/ui/evolution_tracker.gd")
	if evo_script:
		var evo = Control.new()
		evo.name = "EvolutionTracker"
		evo.set_script(evo_script)
		evo.set_anchors_preset(Control.PRESET_FULL_RECT)
		evo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(evo)

	# PRD 55: Damage direction indicator
	var ddi_script = load("res://scripts/ui/damage_direction_indicator.gd")
	if ddi_script:
		var ddi = Control.new()
		ddi.name = "DamageDirectionIndicator"
		ddi.set_script(ddi_script)
		ddi.set_anchors_preset(Control.PRESET_FULL_RECT)
		ddi.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ddi)

	# Level label styling — prominent gold with outline
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	level_label.add_theme_constant_override("outline_size", 3)
	level_label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))

	# FPS label styling — small, semi-transparent white
	fps_label.add_theme_font_size_override("font_size", 12)
	fps_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.6))
	fps_label.add_theme_constant_override("outline_size", 2)
	fps_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.5))

	# Boss HP bar styling (red)
	var boss_fill = StyleBoxFlat.new()
	boss_fill.bg_color = Color(0.9, 0.15, 0.15)
	boss_fill.set_corner_radius_all(4)
	boss_hp_bar.add_theme_stylebox_override("fill", boss_fill)

	var boss_bg = StyleBoxFlat.new()
	boss_bg.bg_color = Color(0.15, 0.05, 0.05)
	boss_bg.set_corner_radius_all(4)
	boss_bg.set_border_width_all(1)
	boss_bg.border_color = Color(0.4, 0.1, 0.1)
	boss_hp_bar.add_theme_stylebox_override("background", boss_bg)

	# Dash label — bigger font for visibility
	dash_label.add_theme_font_size_override("font_size", 14)

	# Dash cooldown bar styling (cyan, wider)
	dash_cooldown_bar.visible = false
	dash_cooldown_bar.custom_minimum_size = Vector2(120, 8)
	var dash_fill = StyleBoxFlat.new()
	dash_fill.bg_color = Color(0.2, 0.85, 1.0)
	dash_fill.set_corner_radius_all(3)
	dash_cooldown_bar.add_theme_stylebox_override("fill", dash_fill)
	var dash_bg = StyleBoxFlat.new()
	dash_bg.bg_color = Color(0.1, 0.1, 0.15)
	dash_bg.set_corner_radius_all(3)
	dash_bg.set_border_width_all(1)
	dash_bg.border_color = Color(0.2, 0.3, 0.4)
	dash_cooldown_bar.add_theme_stylebox_override("background", dash_bg)

	# Timer label — premium styling with outline
	time_label.add_theme_font_size_override("font_size", 22)
	time_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	time_label.add_theme_constant_override("outline_size", 3)
	time_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))

	# Kill label — gold accent with outline
	kill_label.add_theme_font_size_override("font_size", 16)
	kill_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	kill_label.add_theme_constant_override("outline_size", 2)
	kill_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.7))

	# Event notification styling — larger, bolder
	event_label.add_theme_font_size_override("font_size", 32)
	event_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	event_label.add_theme_constant_override("outline_size", 4)
	event_label.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.0))

	# Achievement popup now handled by AchievementPopup autoload (CanvasLayer 10)

	# Synergy HUD — icon-based with tooltips (replaces old text-based display)
	var synergy_hud_script = preload("res://scripts/ui/synergy_hud.gd")
	synergy_container = Control.new()
	synergy_container.set_script(synergy_hud_script)
	synergy_container.name = "SynergyHUD"
	synergy_container.anchor_left = 0.0
	synergy_container.anchor_top = 1.0
	synergy_container.anchor_right = 0.0
	synergy_container.anchor_bottom = 1.0
	synergy_container.offset_left = 10.0
	synergy_container.offset_top = -210.0
	synergy_container.offset_right = 300.0
	synergy_container.offset_bottom = -130.0
	add_child(synergy_container)

	# Minimap (bottom-right, hexagonal)
	var minimap_script = preload("res://scripts/ui/minimap.gd")
	minimap = Control.new()
	minimap.set_script(minimap_script)
	minimap.anchor_left = 1.0
	minimap.anchor_top = 1.0
	minimap.anchor_right = 1.0
	minimap.anchor_bottom = 1.0
	minimap.offset_left = -155.0
	minimap.offset_top = -260.0
	minimap.offset_right = -10.0
	minimap.offset_bottom = -130.0
	add_child(minimap)

	# Touch controls (mobile only — joystick + dash button)
	var touch_controls_scene = preload("res://scenes/ui/touch_controls.tscn")
	var touch_controls = touch_controls_scene.instantiate()
	add_child(touch_controls)

	# Multiplayer HUD (ally HP, ping, arrows, migration)
	if MultiplayerManager.is_online:
		_mp_hud = HUDMultiplayer.new()
		_mp_hud.setup(self)

	# Quest display (top-center)
	_quest_label = Label.new()
	_quest_label.name = "QuestLabel"
	_quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_label.add_theme_font_size_override("font_size", 14)
	_quest_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	_quest_label.add_theme_constant_override("outline_size", 2)
	_quest_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	_quest_label.anchor_left = 0.25
	_quest_label.anchor_right = 0.75
	_quest_label.offset_top = 130.0
	_quest_label.offset_bottom = 150.0
	_quest_label.visible = false
	add_child(_quest_label)

	_quest_progress_bar = ProgressBar.new()
	_quest_progress_bar.name = "QuestProgressBar"
	_quest_progress_bar.anchor_left = 0.35
	_quest_progress_bar.anchor_right = 0.65
	_quest_progress_bar.offset_top = 152.0
	_quest_progress_bar.offset_bottom = 158.0
	_quest_progress_bar.show_percentage = false
	_quest_progress_bar.custom_minimum_size = Vector2(0, 6)
	var qp_fill = StyleBoxFlat.new()
	qp_fill.bg_color = Color(0.9, 0.8, 0.2)
	qp_fill.set_corner_radius_all(3)
	_quest_progress_bar.add_theme_stylebox_override("fill", qp_fill)
	var qp_bg = StyleBoxFlat.new()
	qp_bg.bg_color = Color(0.1, 0.1, 0.12, 0.7)
	qp_bg.set_corner_radius_all(3)
	_quest_progress_bar.add_theme_stylebox_override("background", qp_bg)
	_quest_progress_bar.visible = false
	add_child(_quest_progress_bar)

	# Quest signals
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_progress.connect(_on_quest_progress)

	# Bestiary milestone notification
	GameManager.bestiary_milestone_reached.connect(_on_bestiary_milestone)

	# Achievement progress tracker (top-left, below quest area)
	var ach_tracker_script = preload("res://scripts/ui/achievement_tracker.gd")
	_achievement_tracker = Control.new()
	_achievement_tracker.set_script(ach_tracker_script)
	_achievement_tracker.name = "AchievementTracker"
	add_child(_achievement_tracker)

	# Damage vignette — red border flash when player takes damage
	_damage_vignette = ColorRect.new()
	_damage_vignette.name = "DamageVignette"
	_damage_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_vignette.color = Color(0.8, 0.0, 0.0, 0.0)
	_damage_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_damage_vignette)

	# Evolution available notification (PRD 40)
	_evo_notify_label = Label.new()
	_evo_notify_label.name = "EvoNotifyLabel"
	_evo_notify_label.text = ""
	_evo_notify_label.visible = false
	_evo_notify_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_evo_notify_label.add_theme_font_size_override("font_size", 16)
	_evo_notify_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_evo_notify_label.add_theme_constant_override("outline_size", 2)
	_evo_notify_label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	_evo_notify_label.anchor_left = 0.25
	_evo_notify_label.anchor_right = 0.75
	_evo_notify_label.anchor_top = 0.15
	_evo_notify_label.anchor_bottom = 0.2
	add_child(_evo_notify_label)

# Evolution available notification (PRD 40)
var _evo_notify_label: Label = null
var _evo_notify_timer: float = 0.0
var _evo_check_timer: float = 0.0
var _last_evo_available: String = ""

var _slow_update_timer: float = 0.0
const SLOW_UPDATE_INTERVAL: float = 0.2  # 5x per second for non-critical UI

func _process(delta: float) -> void:
	# Critical: update every frame (smooth bars)
	_update_hp()
	_update_xp()
	_update_dash()

	# Slow updates: 5x/sec is enough for text/icons
	_slow_update_timer += delta
	if _slow_update_timer >= SLOW_UPDATE_INTERVAL:
		_slow_update_timer = 0.0
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
		_update_time()
		_update_kills()
		_update_weapon_icons()
		_update_item_icons()
		_update_boss_hp()
		if _mp_hud:
			_mp_hud.update_ally_hp()
			_mp_hud.update_ping()
			_mp_hud.update_ally_arrows()

	_update_synergies(delta)
	_update_chest_arrows()
	_update_merchant_arrow()
	_update_evo_notification(delta)
	# Check achievements every 10s
	achievement_check_timer += delta
	if achievement_check_timer >= 10.0:
		achievement_check_timer = 0.0
		AchievementManager.check_achievements()

func _update_hp() -> void:
	var max_hp = int(GameManager.player_max_hp * GameManager.max_hp_mult)
	var current_hp = GameManager.player_hp

	# Atualiza a barra de HP temática por personagem
	character_hp_bar.set_hp(float(current_hp), float(max_hp))
	_prev_hp = current_hp

func _update_xp() -> void:
	pass  # XP bar hidden — using world-space bar near character

func _update_time() -> void:
	var t = int(GameManager.game_time)
	time_label.text = "%02d:%02d" % [t / 60, t % 60]
	# Red pulse when less than 3 minutes remaining
	if "run_time_limit" in GameManager:
		var remaining = GameManager.run_time_limit - GameManager.game_time
		if remaining < 180.0 and remaining > 0 and GameManager.game_mode != "endless":
			time_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
			time_label.modulate.a = 0.7 + sin(GameManager.game_time * 4.0) * 0.3
		else:
			time_label.add_theme_color_override("font_color", Color.WHITE)
			time_label.modulate.a = 1.0

func _update_kills() -> void:
	kill_label.text = LocaleManager.tr_key("kills") % [GameManager.total_kills, GameManager.crystals_this_run]

func _on_level_up(_new_level: int) -> void:
	level_label.text = "Lv. %d" % _new_level
	# Scale bounce animation with gold flash
	var tween = create_tween()
	level_label.scale = Vector2(1.6, 1.6)
	level_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5))
	tween.tween_property(level_label, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_callback(func():
		level_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	).set_delay(0.5)

func _on_game_over() -> void:
	pass

func _on_player_took_damage() -> void:
	# Punch effect na barra temática
	character_hp_bar.trigger_punch()
	# Scale bounce na barra temática
	var tween = create_tween()
	character_hp_bar.scale = Vector2(1.08, 1.15)
	tween.tween_property(character_hp_bar, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	# Red vignette flash on damage
	_flash_damage_vignette()

func _flash_damage_vignette() -> void:
	if not _damage_vignette:
		return
	_damage_vignette.color.a = 0.25
	var tw = create_tween()
	tw.tween_property(_damage_vignette, "color:a", 0.0, 0.35).set_ease(Tween.EASE_OUT)

# _on_achievement_unlocked removed — handled by AchievementPopup autoload

func _on_event_started(event_name: String) -> void:
	var locale_key = "event_" + event_name
	var text = LocaleManager.tr_key(locale_key)
	# Fallback to hardcoded if locale key not found
	if text == locale_key:
		var display_names = {
			"golden_horde": "Horda dourada!",
			"elite_horde": "Horda elite!",
			"massive_horde": "Horda massiva!",
			"miniboss": "Mini-boss!",
			"miniboss_strong": "Mega mini-boss!",
			"treasure_goblin": "Treasure goblin!",
			"merchant": "Mercador apareceu!",
			"roulette": "Roda da fortuna!",
			"eclipse": "Eclipse!",
			"meteor_shower": "Chuva de meteoros!",
			"angel_challenge": "Desafio do anjo!",
			"portal_dimensional": "Portal dimensional!",
			"chest_mimic": "Bau mimic!",
			"fever_mode": "Fever mode!",
		}
		text = display_names.get(event_name, event_name.capitalize())

	# Cores especiais por tipo de evento
	var event_colors = {
		"elite_horde": Color(1.0, 0.85, 0.2),
		"massive_horde": Color(1.0, 0.3, 0.3),
		"miniboss": Color(1.0, 0.3, 0.3),
		"miniboss_strong": Color(0.8, 0.1, 0.1),
		"golden_horde": Color(1.0, 0.85, 0.2),
		"eclipse": Color(0.5, 0.3, 0.8),
		"meteor_shower": Color(1.0, 0.5, 0.0),
		"portal_dimensional": Color(0.6, 0.3, 1.0),
	}
	var color = event_colors.get(event_name, Color(1.0, 0.85, 0.2))

	event_label.text = text
	event_label.visible = true
	event_label.modulate = color
	event_label.modulate.a = 0.0
	event_label.scale = Vector2(1.8, 1.8)
	event_label.pivot_offset = event_label.size / 2.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(event_label, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(event_label, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)

func _on_event_ended(_event_name: String) -> void:
	# Fade-out instead of hard cut
	var tween = create_tween()
	tween.tween_property(event_label, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): event_label.visible = false)

func _on_event_warning(event_name: String, seconds_left: float) -> void:
	# Mostra aviso "INCOMING" antes do evento
	var warning_names = {
		"golden_horde": "Horda dourada",
		"elite_horde": "Horda elite",
		"massive_horde": "Horda massiva",
		"miniboss": "Mini-boss",
		"miniboss_strong": "Mega mini-boss",
		"eclipse": "Eclipse",
		"meteor_shower": "Chuva de meteoros",
		"roulette": "Roda da fortuna",
		"portal_dimensional": "Portal dimensional",
	}
	var name = warning_names.get(event_name, event_name.capitalize())
	event_label.text = "⚠ %s em %ds!" % [name, int(seconds_left)]
	event_label.visible = true
	event_label.modulate = Color(1.0, 1.0, 0.5, 0.8)
	event_label.scale = Vector2(1.2, 1.2)
	var tween = create_tween()
	tween.tween_property(event_label, "scale", Vector2.ONE, 0.3)
	# Pisca o aviso
	tween.tween_property(event_label, "modulate:a", 0.4, 0.5)
	tween.tween_property(event_label, "modulate:a", 0.9, 0.5)
	tween.tween_property(event_label, "modulate:a", 0.4, 0.5)
	tween.tween_callback(func(): event_label.visible = false)

func _on_boss_spawned(bname: String) -> void:
	if boss_name_label:
		boss_name_label.text = bname.replace("_", " ").capitalize()
		boss_name_label.visible = true
		# Scale-in animation
		boss_name_label.scale = Vector2(1.5, 1.5)
		var tween = create_tween()
		tween.tween_property(boss_name_label, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _on_miniboss_spawned(boss_name: String) -> void:
	event_label.text = "MINIBOSS: %s" % boss_name
	event_label.visible = true
	event_label.modulate = Color(1.0, 0.3, 0.3)
	event_label.scale = Vector2(1.5, 1.5)
	var tween = create_tween()
	tween.tween_property(event_label, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property(event_label, "modulate", Color(1.0, 0.85, 0.2), 0.5)
	tween.tween_interval(4.0)
	tween.tween_callback(func(): event_label.visible = false)

# --------------- Icon Size Helper ---------------

func _get_icon_sizes(count: int) -> Dictionary:
	if count <= GameConstants.HUD_ICON_LARGE_MAX:
		return GameConstants.HUD_ICON_SIZES["large"]
	elif count <= GameConstants.HUD_ICON_MEDIUM_MAX:
		return GameConstants.HUD_ICON_SIZES["medium"]
	else:
		return GameConstants.HUD_ICON_SIZES["small"]

# --------------- Weapon Icons ---------------

func _update_weapon_icons() -> void:
	var weapons := GameManager.player_weapons
	var hash := ""
	for w in weapons:
		hash += "%s:%d," % [w.id, w.level]
	if hash == _prev_weapon_hash:
		return
	_prev_weapon_hash = hash

	# Clear previous icons
	for child in weapon_container.get_children():
		child.queue_free()

	if weapons.is_empty():
		return

	var sizes := _get_icon_sizes(weapons.size())
	weapon_container.add_theme_constant_override("separation", GameConstants.HUD_ICON_SEPARATION)

	var type_colors := {
		"melee": Color(0.9, 0.2, 0.2),
		"ranged": Color(0.2, 0.4, 0.9),
		"summon": Color(0.2, 0.8, 0.3),
	}

	for w in weapons:
		var data = WeaponDB.weapons.get(w.id, {})
		var weapon_type = data.get("type", "melee")
		var color = type_colors.get(weapon_type, Color.WHITE)

		var panel := PanelContainer.new()
		panel.custom_minimum_size = sizes.panel
		# Type-colored border
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.12, 0.85)
		style.border_color = color
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		panel.add_theme_stylebox_override("panel", style)

		var _icon_path := "res://assets/sprites/weapons/%s.png" % w.id
		var _icon_tex = load(_icon_path) if ResourceLoader.exists(_icon_path) else null
		var icon_node: Control
		if _icon_tex:
			var tex_rect := TextureRect.new()
			tex_rect.texture = _icon_tex
			tex_rect.custom_minimum_size = sizes.texture
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_node = tex_rect
		else:
			var rect := ColorRect.new()
			rect.custom_minimum_size = sizes.texture
			rect.color = color
			icon_node = rect
		panel.add_child(icon_node)

		# Level badge (bottom-right corner)
		var lbl := Label.new()
		lbl.text = str(w.level)
		lbl.add_theme_font_size_override("font_size", sizes.font)
		lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		lbl.offset_left = -(sizes.font + 6)
		lbl.offset_top = -(sizes.font + 6)
		lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		icon_node.add_child(lbl)

		weapon_container.add_child(panel)

# --------------- Item Icons ---------------

func _update_item_icons() -> void:
	var items := GameManager.player_items
	var hash := ""
	for it in items:
		hash += "%s:%d," % [it.id, it.level]
	if hash == _prev_item_hash:
		return
	_prev_item_hash = hash

	# Clear previous icons
	for child in item_container.get_children():
		child.queue_free()

	if items.is_empty():
		return

	var sizes := _get_icon_sizes(items.size())
	item_container.add_theme_constant_override("separation", GameConstants.HUD_ICON_SEPARATION)

	# Determine if we need 2 rows
	var use_grid := items.size() > GameConstants.HUD_ICON_MAX_PER_ROW
	var containers: Array[HBoxContainer] = []

	if use_grid:
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		var row1 := HBoxContainer.new()
		row1.add_theme_constant_override("separation", GameConstants.HUD_ICON_SEPARATION)
		row1.alignment = BoxContainer.ALIGNMENT_END
		var row2 := HBoxContainer.new()
		row2.add_theme_constant_override("separation", GameConstants.HUD_ICON_SEPARATION)
		row2.alignment = BoxContainer.ALIGNMENT_END
		vbox.add_child(row1)
		vbox.add_child(row2)
		item_container.add_child(vbox)
		containers = [row1, row2]
	else:
		containers = [item_container]

	var first_row_count := ceili(items.size() / 2.0) if use_grid else items.size()

	for i in range(items.size()):
		var it = items[i]
		var data = ItemDB.items.get(it.id, {})
		var color = data.get("color", Color.WHITE)

		var panel := PanelContainer.new()
		panel.custom_minimum_size = sizes.panel
		# Item-colored border
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.12, 0.85)
		style.border_color = Color(0.3, 0.7, 0.9)
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		panel.add_theme_stylebox_override("panel", style)

		var _icon_path := "res://assets/sprites/items/%s.png" % it.id
		var _icon_tex = load(_icon_path) if ResourceLoader.exists(_icon_path) else null
		var icon_node: Control
		if _icon_tex:
			var tex_rect := TextureRect.new()
			tex_rect.texture = _icon_tex
			tex_rect.custom_minimum_size = sizes.texture
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_node = tex_rect
		else:
			var rect := ColorRect.new()
			rect.custom_minimum_size = sizes.texture
			rect.color = color
			icon_node = rect
		panel.add_child(icon_node)

		# Level badge (bottom-right corner)
		var lbl := Label.new()
		lbl.text = str(it.level)
		lbl.add_theme_font_size_override("font_size", sizes.font)
		lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		lbl.offset_left = -(sizes.font + 6)
		lbl.offset_top = -(sizes.font + 6)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
		icon_node.add_child(lbl)

		# Determine target container
		if use_grid:
			if i < first_row_count:
				containers[0].add_child(panel)
			else:
				containers[1].add_child(panel)
		else:
			containers[0].add_child(panel)

# --------------- Boss HP Bar ---------------

func _update_boss_hp() -> void:
	# Use cached group lookup from GameManager instead of direct tree query
	var bosses := get_tree().get_nodes_in_group("boss")  # Small group, no perf concern
	if bosses.is_empty():
		boss_hp_bar.visible = false
		if boss_name_label:
			boss_name_label.visible = false
		return

	var boss = bosses[0]
	boss_hp_bar.visible = true
	if boss_name_label and not boss_name_label.visible:
		# Show name from boss node if signal was missed
		var bname = boss.name if "name" in boss else "Boss"
		boss_name_label.text = str(bname).replace("_", " ").capitalize()
		boss_name_label.visible = true
	if boss.has_method("get_max_hp"):
		boss_hp_bar.max_value = boss.get_max_hp()
	elif "max_hp" in boss:
		boss_hp_bar.max_value = boss.max_hp
	else:
		boss_hp_bar.max_value = 100

	var current_boss_hp: float
	if "hp" in boss:
		current_boss_hp = boss.hp
	elif "current_hp" in boss:
		current_boss_hp = boss.current_hp
	else:
		current_boss_hp = boss_hp_bar.max_value
	boss_hp_bar.value = current_boss_hp

	# Ghost HP (mostra dano recente como sombra)
	if _prev_boss_hp < 0:
		_prev_boss_hp = current_boss_hp
		_boss_ghost_hp = current_boss_hp
	if current_boss_hp < _prev_boss_hp:
		# Boss tomou dano — shake + ghost
		_boss_shake_timer = 0.15
		_boss_ghost_hp = _prev_boss_hp
	_prev_boss_hp = current_boss_hp
	# Ghost drains slowly
	if _boss_ghost_hp > current_boss_hp:
		_boss_ghost_hp = lerpf(_boss_ghost_hp, current_boss_hp, 0.05)

	# Shake horizontal
	if _boss_shake_timer > 0:
		_boss_shake_timer -= get_process_delta_time()
		boss_hp_bar.position.x = sin(Time.get_ticks_msec() * 0.05) * 3.0
	else:
		boss_hp_bar.position.x = 0.0

	# Pulse boss HP bar red when below 25%
	var boss_ratio = current_boss_hp / boss_hp_bar.max_value if boss_hp_bar.max_value > 0 else 1.0
	if boss_ratio < 0.25 and boss_ratio > 0:
		var pulse = sin(Time.get_ticks_msec() * 0.008) * 0.3 + 0.7
		boss_hp_bar.modulate = Color(1.0, pulse, pulse)
	else:
		boss_hp_bar.modulate = Color.WHITE

func _update_dash() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	var p = players[0]
	if not "dash_cooldown_timer" in p or not "dash_cooldown" in p:
		return
	if p.dash_cooldown_timer > 0:
		var remaining_cd = snappedf(p.dash_cooldown_timer, 0.1)
		dash_label.text = "%.1f" % remaining_cd
		dash_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		# Barra carrega de 0 ate 1 conforme o cooldown passa
		var progress = 1.0 - (p.dash_cooldown_timer / p.dash_cooldown)
		dash_cooldown_bar.value = clampf(progress, 0.0, 1.0)
		dash_cooldown_bar.visible = true
	else:
		dash_label.text = "DASH"
		dash_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
		dash_cooldown_bar.value = 1.0
		dash_cooldown_bar.visible = false

## Multiplayer ally HP, ping, arrows — delegated to HUDMultiplayer

# --------------- Synergy Display ---------------

func _update_synergies(delta: float) -> void:
	_synergy_update_timer += delta
	if _synergy_update_timer < 2.0:
		return
	_synergy_update_timer = 0.0

	var synergies = SynergySystem.active_synergies
	var hash := ",".join(synergies)
	if hash == _prev_synergy_hash:
		return
	_prev_synergy_hash = hash

	# SynergyHUD handles display via signals; just remove stale icons
	if synergy_container.has_method("remove_stale_synergies"):
		synergy_container.remove_stale_synergies()

# --------------- Chest Arrows ---------------

func _update_chest_arrows() -> void:
	var chests = ChestManager.get_active_chests()
	var camera = get_viewport().get_camera_3d()
	if not camera:
		# Cleanup all arrows
		for arrow in _chest_arrows.values():
			if is_instance_valid(arrow):
				arrow.queue_free()
		_chest_arrows.clear()
		return
	var viewport_size = get_viewport().get_visible_rect().size
	var local_player = get_tree().get_first_node_in_group("players")
	if not local_player or not is_instance_valid(local_player):
		return

	# Remove arrows for chests that no longer exist
	var valid_ids := []
	for chest in chests:
		if is_instance_valid(chest):
			valid_ids.append(chest.get_instance_id())
	for cid in _chest_arrows.keys():
		if cid not in valid_ids:
			if is_instance_valid(_chest_arrows[cid]):
				_chest_arrows[cid].queue_free()
			_chest_arrows.erase(cid)

	for chest in chests:
		if not is_instance_valid(chest):
			continue
		var cid = chest.get_instance_id()
		var dist = local_player.global_position.distance_to(chest.global_position)
		var behind = camera.global_transform.basis.z.dot(chest.global_position - camera.global_position) > 0
		var screen_pos = camera.unproject_position(chest.global_position + Vector3(0, 1, 0))
		if behind:
			screen_pos = viewport_size - screen_pos
		var margin = 50.0
		var offscreen = behind or screen_pos.x < margin or screen_pos.x > viewport_size.x - margin or screen_pos.y < margin or screen_pos.y > viewport_size.y - margin

		# Create or reuse arrow
		if cid not in _chest_arrows or not is_instance_valid(_chest_arrows[cid]):
			var arrow = Label.new()
			arrow.add_theme_font_size_override("font_size", 20)
			arrow.add_theme_color_override("font_color", GameConstants.CHEST_ARROW_COLOR)
			arrow.add_theme_constant_override("outline_size", 2)
			arrow.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
			add_child(arrow)
			_chest_arrows[cid] = arrow

		var arrow: Label = _chest_arrows[cid]
		if not offscreen and dist < 5.0:
			arrow.visible = false
			continue
		arrow.visible = true
		var clamped = Vector2(
			clampf(screen_pos.x, margin, viewport_size.x - margin),
			clampf(screen_pos.y, margin, viewport_size.y - margin)
		)
		arrow.position = clamped - Vector2(20, 10)
		var dir = (screen_pos - viewport_size / 2).normalized()
		var arrow_char: String
		if absf(dir.x) > absf(dir.y):
			arrow_char = "►" if dir.x > 0 else "◄"
		else:
			arrow_char = "▼" if dir.y > 0 else "▲"
		arrow.text = "%s 📦 %dm" % [arrow_char, int(dist)]
		arrow.modulate.a = clampf(remap(dist, 3.0, 30.0, 0.6, 1.0), 0.6, 1.0)

# --------------- Merchant Arrow ---------------

func _update_merchant_arrow() -> void:
	var merchants = get_tree().get_nodes_in_group("merchant")
	var camera = get_viewport().get_camera_3d()

	# Sem mercador ativo ou sem câmera — esconde seta
	if merchants.is_empty() or not camera:
		if is_instance_valid(_merchant_arrow):
			_merchant_arrow.visible = false
		return

	var merchant_node = merchants[0]
	if not is_instance_valid(merchant_node):
		if is_instance_valid(_merchant_arrow):
			_merchant_arrow.visible = false
		return

	var local_player = get_tree().get_first_node_in_group("players")
	if not local_player or not is_instance_valid(local_player):
		if is_instance_valid(_merchant_arrow):
			_merchant_arrow.visible = false
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var dist = local_player.global_position.distance_to(merchant_node.global_position)
	var behind = camera.global_transform.basis.z.dot(merchant_node.global_position - camera.global_position) > 0
	var screen_pos = camera.unproject_position(merchant_node.global_position + Vector3(0, 1.5, 0))
	if behind:
		screen_pos = viewport_size - screen_pos
	var margin = 50.0
	var offscreen = behind or screen_pos.x < margin or screen_pos.x > viewport_size.x - margin or screen_pos.y < margin or screen_pos.y > viewport_size.y - margin

	# Cria label se não existe
	if not is_instance_valid(_merchant_arrow):
		_merchant_arrow = Label.new()
		_merchant_arrow.add_theme_font_size_override("font_size", 20)
		_merchant_arrow.add_theme_color_override("font_color", GameConstants.MERCHANT_ARROW_COLOR)
		_merchant_arrow.add_theme_constant_override("outline_size", 2)
		_merchant_arrow.add_theme_color_override("font_outline_color", Color(0.0, 0.1, 0.2))
		add_child(_merchant_arrow)

	# Perto e na tela — esconde seta
	if not offscreen and dist < 5.0:
		_merchant_arrow.visible = false
		return

	_merchant_arrow.visible = true
	var clamped = Vector2(
		clampf(screen_pos.x, margin, viewport_size.x - margin),
		clampf(screen_pos.y, margin, viewport_size.y - margin)
	)
	_merchant_arrow.position = clamped - Vector2(20, 10)
	var dir = (screen_pos - viewport_size / 2).normalized()
	var arrow_char: String
	if absf(dir.x) > absf(dir.y):
		arrow_char = "►" if dir.x > 0 else "◄"
	else:
		arrow_char = "▼" if dir.y > 0 else "▲"
	_merchant_arrow.text = "%s 🧙 %dm" % [arrow_char, int(dist)]
	_merchant_arrow.modulate.a = clampf(remap(dist, 3.0, 30.0, 0.6, 1.0), 0.6, 1.0)

# --------------- Quest UI ---------------

func _on_quest_started(quest: Dictionary) -> void:
	if _quest_label:
		_quest_label.text = quest.get("display_name", "Quest")
		_quest_label.visible = true
		_quest_label.scale = Vector2(1.3, 1.3)
		var tween = create_tween()
		tween.tween_property(_quest_label, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if _quest_progress_bar:
		_quest_progress_bar.value = 0
		_quest_progress_bar.visible = true

func _on_quest_completed(_quest: Dictionary) -> void:
	if _quest_label:
		_quest_label.text = "Quest completa!"
		_quest_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		var tween = create_tween()
		tween.tween_property(_quest_label, "scale", Vector2(1.4, 1.4), 0.2)
		tween.tween_property(_quest_label, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT)
		tween.tween_interval(2.0)
		tween.tween_callback(func():
			_quest_label.visible = false
			_quest_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
		)
	if _quest_progress_bar:
		_quest_progress_bar.value = _quest_progress_bar.max_value
		var tween2 = create_tween()
		tween2.tween_interval(2.0)
		tween2.tween_callback(func(): _quest_progress_bar.visible = false)

func _on_quest_progress(quest: Dictionary, current: int, target: int) -> void:
	if _quest_progress_bar:
		_quest_progress_bar.max_value = target
		_quest_progress_bar.value = current
	if _quest_label and quest.has("display_name"):
		_quest_label.text = "%s (%d/%d)" % [quest["display_name"], current, target]

# --------------- Bestiary milestone notification ---------------

func _on_bestiary_milestone(enemy_id: String, _kills: int, label: String, crystals: int) -> void:
	## Show a slide-in notification when a bestiary milestone is reached.
	var display_name := enemy_id.replace("_", " ").capitalize()
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.15, 0.9)
	style.set_corner_radius_all(6)
	style.set_border_width_all(1)
	style.border_color = Color(0.6, 0.5, 0.2, 0.8)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left = 0.0
	panel.anchor_top = 0.35
	panel.offset_left = -300.0  # Start offscreen
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.size = Vector2(280, 0)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "Bestiario atualizado!"
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title_lbl)

	var name_lbl = Label.new()
	name_lbl.text = "%s — \"%s\" (%d)" % [display_name, label, _kills]
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	var reward_lbl = Label.new()
	reward_lbl.text = "+%d cristais | Novo desbloqueio!" % crystals
	reward_lbl.add_theme_font_size_override("font_size", 10)
	reward_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.4))
	vbox.add_child(reward_lbl)

	add_child(panel)
	AudioManager.play_sfx("chest_open")  # Reuse chest_open SFX for milestone

	# Slide-in animation
	var tween = create_tween()
	tween.tween_property(panel, "offset_left", 10.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(GameConstants.BESTIARY_NOTIFICATION_DURATION)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)

func _update_evo_notification(delta: float) -> void:
	# Fade out active notification
	if _evo_notify_timer > 0:
		_evo_notify_timer -= delta
		if _evo_notify_timer <= 0.5:
			if _evo_notify_label:
				_evo_notify_label.modulate.a = _evo_notify_timer / 0.5
		if _evo_notify_timer <= 0:
			if _evo_notify_label:
				_evo_notify_label.visible = false
				_evo_notify_label.modulate.a = 1.0

	# Check for newly available evolutions every 2 seconds
	_evo_check_timer += delta
	if _evo_check_timer < 2.0:
		return
	_evo_check_timer = 0.0

	var available_evo_id = EvolutionDB.check_evolution_available()
	if available_evo_id != "" and available_evo_id != _last_evo_available:
		_last_evo_available = available_evo_id
		var evo = EvolutionDB.get_evolution(available_evo_id)
		var evo_name = evo.get("name", available_evo_id.capitalize())
		if _evo_notify_label:
			_evo_notify_label.text = LocaleManager.tr_key("evo_available_now") % evo_name
			_evo_notify_label.visible = true
			_evo_notify_label.modulate.a = 1.0
			_evo_notify_timer = GameConstants.EVO_AVAILABLE_NOTIFICATION_DURATION
		AudioManager.play_sfx("level_up", -0.2)

## Multiplayer setup/migration/reconnection — delegated to HUDMultiplayer
