extends CanvasLayer

## HUD: HP, XP, level, timer, kills, dash cooldown.

@onready var hp_bar: ProgressBar = $MarginContainer/VBox/HPBar
@onready var xp_bar: ProgressBar = $MarginContainer/VBox/XPBar
@onready var level_label: Label = $MarginContainer/VBox/LevelLabel
var themed_hp: Control = null
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

# Cache to avoid rebuilding every frame
var _prev_weapon_hash: String = ""
var _prev_item_hash: String = ""

# Synergy display
var synergy_container: VBoxContainer = null
var _synergy_update_timer: float = 0.0
var _prev_synergy_hash: String = ""

# Separate achievement notification container (icon + label)
var achievement_container: HBoxContainer = null
var achievement_icon: TextureRect = null
var achievement_label: Label = null

# Multiplayer ally HP bars (painel top-right com barras coloridas)
var ally_hp_panel: PanelContainer = null
var ally_hp_container: VBoxContainer = null
var ping_label: Label = null
var ally_arrows: Dictionary = {}  # peer_id -> Label (setas direcionais na borda da tela)
var _prev_ally_hash: String = ""
var _ally_bars: Dictionary = {}  # peer_id -> ProgressBar
var _ally_name_labels: Dictionary = {}  # peer_id -> Label
var _ally_hp_labels: Dictionary = {}  # peer_id -> Label (texto HP numérico)

# Host migration overlay
var migration_label: Label = null

# Minimap
var minimap: Control = null

func _ready() -> void:
	GameManager.player_leveled_up.connect(_on_level_up)
	GameManager.game_over.connect(_on_game_over)
	event_label.visible = false

	# Setup weapon icons container (bottom-left) and item icons (bottom-right)
	weapon_container = $WeaponPanel/WeaponIcons
	item_container = $ItemPanel/ItemIcons
	boss_hp_bar = $BossHPBar
	boss_hp_bar.visible = false

	# Conecta ao EventManager se existir
	await get_tree().process_frame
	var em = get_tree().current_scene.get_node_or_null("EventManager")
	if em:
		em.event_started.connect(_on_event_started)
		em.event_ended.connect(_on_event_ended)
		em.event_warning.connect(_on_event_warning)

	# Miniboss name display
	GameManager.miniboss_spawned.connect(_on_miniboss_spawned)

	# Achievement notification
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

	# Themed HP bar (replaces the basic ProgressBar)
	hp_bar.visible = false
	var themed_script = preload("res://scripts/ui/themed_hp_bar.gd")
	themed_hp = Control.new()
	themed_hp.set_script(themed_script)
	themed_hp.custom_minimum_size = Vector2(260, 28)
	# Insert in the VBox where HPBar was
	var vbox = $MarginContainer/VBox
	vbox.add_child(themed_hp)
	vbox.move_child(themed_hp, hp_bar.get_index())

	_prev_hp = GameManager.player_hp

	# Connect damage feedback signal
	if ScreenEffects.has_signal("player_took_damage"):
		ScreenEffects.player_took_damage.connect(_on_player_took_damage)

	# XP bar — slimmer, with glow fill and level badge
	xp_bar.custom_minimum_size = Vector2(260, 10)
	var xp_fill = StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.3, 0.6, 1.0)
	xp_fill.set_corner_radius_all(5)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)

	var xp_bg = StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.03, 0.03, 0.1, 0.8)
	xp_bg.set_corner_radius_all(5)
	xp_bg.set_border_width_all(1)
	xp_bg.border_color = Color(0.15, 0.2, 0.4, 0.5)
	xp_bar.add_theme_stylebox_override("background", xp_bg)

	# Level label styling — integrate above XP bar
	level_label.theme_override_font_sizes = { "font_size": 13 }
	level_label.theme_override_colors = { "font_color": Color(0.6, 0.8, 1.0, 0.9) }

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

	# Dash cooldown bar styling (cyan, pequena)
	dash_cooldown_bar.visible = false
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

	# Event notification styling
	event_label.add_theme_font_size_override("font_size", 28)
	event_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	# Separate achievement notification (icon + label, below event label)
	achievement_container = HBoxContainer.new()
	achievement_container.name = "AchievementContainer"
	achievement_container.visible = false
	achievement_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	achievement_container.offset_top = 80  # Below event label
	achievement_container.offset_left = -300
	achievement_container.offset_right = 300
	achievement_container.alignment = BoxContainer.ALIGNMENT_CENTER
	achievement_container.add_theme_constant_override("separation", 8)

	achievement_icon = TextureRect.new()
	achievement_icon.custom_minimum_size = Vector2(32, 32)
	achievement_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	achievement_icon.visible = false
	achievement_container.add_child(achievement_icon)

	achievement_label = Label.new()
	achievement_label.name = "AchievementLabel"
	achievement_label.add_theme_font_size_override("font_size", 24)
	achievement_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	achievement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievement_container.add_child(achievement_label)

	add_child(achievement_container)

	# Synergy indicator area (bottom-left, below weapon icons)
	synergy_container = VBoxContainer.new()
	synergy_container.name = "SynergyContainer"
	synergy_container.anchor_left = 0.0
	synergy_container.anchor_top = 1.0
	synergy_container.anchor_right = 0.0
	synergy_container.anchor_bottom = 1.0
	synergy_container.offset_left = 10.0
	synergy_container.offset_top = -120.0
	synergy_container.offset_right = 200.0
	synergy_container.offset_bottom = -10.0
	synergy_container.add_theme_constant_override("separation", 2)
	add_child(synergy_container)

	# Minimap (bottom-right, hexagonal)
	var minimap_script = preload("res://scripts/ui/minimap.gd")
	minimap = Control.new()
	minimap.set_script(minimap_script)
	minimap.anchor_left = 1.0
	minimap.anchor_top = 1.0
	minimap.anchor_right = 1.0
	minimap.anchor_bottom = 1.0
	minimap.offset_left = -165.0
	minimap.offset_top = -165.0
	minimap.offset_right = -10.0
	minimap.offset_bottom = -10.0
	add_child(minimap)

	# Touch controls (mobile only — joystick + dash button)
	var touch_controls_scene = preload("res://scenes/ui/touch_controls.tscn")
	var touch_controls = touch_controls_scene.instantiate()
	add_child(touch_controls)

	# Multiplayer ally HP bars (painel top-right com barras coloridas)
	if MultiplayerManager.is_online:
		_setup_ally_hp_panel()
		_setup_ping_label()
		_setup_migration_label()
		# Conecta sinais de host migration
		MultiplayerManager.host_migration_started.connect(_on_host_migration_started)
		MultiplayerManager.host_migration_completed.connect(_on_host_migration_completed)
		MultiplayerManager.reconnection_attempted.connect(_on_reconnection_attempted)
		MultiplayerManager.reconnection_succeeded.connect(_on_reconnection_succeeded)
		MultiplayerManager.reconnection_failed.connect(_on_reconnection_failed)

func _process(delta: float) -> void:
	_update_hp()
	_update_xp()
	_update_time()
	_update_kills()
	_update_weapon_icons()
	_update_item_icons()
	_update_boss_hp()
	_update_dash()
	_update_ally_hp()
	_update_ping()
	_update_ally_arrows()
	_update_synergies(delta)
	# Check achievements every 10s
	achievement_check_timer += delta
	if achievement_check_timer >= 10.0:
		achievement_check_timer = 0.0
		AchievementManager.check_achievements()

func _update_hp() -> void:
	var max_hp = int(GameManager.player_max_hp * GameManager.max_hp_mult)
	var current_hp = GameManager.player_hp

	# Update themed HP bar
	if themed_hp and themed_hp.has_method("update_hp"):
		themed_hp.update_hp(current_hp, max_hp)

	# Keep hidden ProgressBar in sync for anything else that reads it
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	_prev_hp = current_hp

	# Ghost HP drain (delayed white bar effect via fill color transition)
	if _ghost_hp > 0:
		if _ghost_hp_delay > 0:
			_ghost_hp_delay -= get_process_delta_time()
		else:
			_ghost_hp = lerpf(_ghost_hp, float(current_hp), get_process_delta_time() * 4.0)
			if absf(_ghost_hp - float(current_hp)) < 1.0:
				_ghost_hp = -1.0  # Done

	# Lerp HP bar fill color back to green
	var fill_style = hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		fill_style.bg_color = fill_style.bg_color.lerp(Color(0.2, 0.8, 0.3), get_process_delta_time() * 5.0)

	# HP bar punch (shake) animation
	if _hp_punch_timer > 0:
		_hp_punch_timer -= get_process_delta_time()
		var offset_x = randf_range(-3.0, 3.0) * (_hp_punch_timer / 0.2)
		var offset_y = randf_range(-2.0, 2.0) * (_hp_punch_timer / 0.2)
		hp_bar.position = _hp_bar_original_pos + Vector2(offset_x, offset_y)
	else:
		hp_bar.position = _hp_bar_original_pos

func _update_xp() -> void:
	xp_bar.max_value = GameManager.player_xp_to_next
	xp_bar.value = GameManager.player_xp

func _update_time() -> void:
	var t = int(GameManager.game_time)
	time_label.text = "%02d:%02d" % [t / 60, t % 60]

func _update_kills() -> void:
	kill_label.text = LocaleManager.tr_key("kills") % [GameManager.total_kills, GameManager.crystals_this_run]

func _on_level_up(_new_level: int) -> void:
	level_label.text = "Lv. %d" % _new_level
	# Scale bounce animation
	var tween = create_tween()
	level_label.scale = Vector2(1.6, 1.6)
	level_label.modulate = Color(1.0, 1.0, 0.3)
	tween.tween_property(level_label, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property(level_label, "modulate", Color.WHITE, 0.5)

func _on_game_over() -> void:
	pass

func _on_player_took_damage() -> void:
	# HP bar punch effect
	_hp_punch_timer = 0.2
	# Scale bounce on HP bar
	var tween = create_tween()
	hp_bar.scale = Vector2(1.08, 1.15)
	tween.tween_property(hp_bar, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _on_achievement_unlocked(_id: String, name: String) -> void:
	achievement_label.text = LocaleManager.tr_key("achievement_label") % name

	# Load achievement icon SVG if available
	var icon_path = "res://assets/icons/achievements/%s.svg" % _id
	var icon_tex = load(icon_path) if ResourceLoader.exists(icon_path) else null
	if icon_tex:
		achievement_icon.texture = icon_tex
		achievement_icon.visible = true
	else:
		achievement_icon.visible = false

	achievement_container.visible = true
	achievement_container.modulate = Color(1.0, 0.85, 0.2)
	achievement_container.scale = Vector2(1.5, 1.5)
	var tween = create_tween()
	tween.tween_property(achievement_container, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_interval(3.0)
	tween.tween_callback(func(): achievement_container.visible = false)

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
	event_label.scale = Vector2(1.5, 1.5)
	var tween = create_tween()
	tween.tween_property(event_label, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _on_event_ended(_event_name: String) -> void:
	event_label.visible = false

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
		panel.custom_minimum_size = Vector2(32, 32)
		# Type-colored border
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.12, 0.85)
		style.border_color = color
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("panel", style)

		var _icon_path := "res://assets/icons/weapons/%s.svg" % w.id
		var _icon_tex = load(_icon_path) if ResourceLoader.exists(_icon_path) else null
		var icon_node: Control
		if _icon_tex:
			var tex_rect := TextureRect.new()
			tex_rect.texture = _icon_tex
			tex_rect.custom_minimum_size = Vector2(28, 28)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_node = tex_rect
		else:
			var rect := ColorRect.new()
			rect.custom_minimum_size = Vector2(28, 28)
			rect.color = color
			icon_node = rect
		panel.add_child(icon_node)

		# Level badge (bottom-right corner)
		var lbl := Label.new()
		lbl.text = str(w.level)
		lbl.theme_override_font_sizes = { "font_size": 9 }
		lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		lbl.offset_left = -12
		lbl.offset_top = -14
		lbl.theme_override_colors = { "font_color": Color(1, 0.9, 0.3) }
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

	for it in items:
		var data = ItemDB.items.get(it.id, {})
		var color = data.get("color", Color.WHITE)

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(32, 32)
		# Item-colored border
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.12, 0.85)
		style.border_color = Color(0.3, 0.7, 0.9)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("panel", style)

		var _icon_path := "res://assets/icons/items/%s.svg" % it.id
		var _icon_tex = load(_icon_path) if ResourceLoader.exists(_icon_path) else null
		var icon_node: Control
		if _icon_tex:
			var tex_rect := TextureRect.new()
			tex_rect.texture = _icon_tex
			tex_rect.custom_minimum_size = Vector2(28, 28)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_node = tex_rect
		else:
			var rect := ColorRect.new()
			rect.custom_minimum_size = Vector2(28, 28)
			rect.color = color
			icon_node = rect
		panel.add_child(icon_node)

		# Level badge (bottom-right corner)
		var lbl := Label.new()
		lbl.text = str(it.level)
		lbl.theme_override_font_sizes = { "font_size": 9 }
		lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		lbl.offset_left = -12
		lbl.offset_top = -14
		lbl.theme_override_colors = { "font_color": Color(0.5, 0.9, 1.0) }
		icon_node.add_child(lbl)

		item_container.add_child(panel)

# --------------- Boss HP Bar ---------------

func _update_boss_hp() -> void:
	var bosses := get_tree().get_nodes_in_group("boss")
	if bosses.is_empty():
		boss_hp_bar.visible = false
		return

	var boss = bosses[0]
	boss_hp_bar.visible = true
	if boss.has_method("get_max_hp"):
		boss_hp_bar.max_value = boss.get_max_hp()
	elif "max_hp" in boss:
		boss_hp_bar.max_value = boss.max_hp
	else:
		boss_hp_bar.max_value = 100

	if "hp" in boss:
		boss_hp_bar.value = boss.hp
	elif "current_hp" in boss:
		boss_hp_bar.value = boss.current_hp
	else:
		boss_hp_bar.value = boss_hp_bar.max_value

func _update_dash() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var p = players[0]
	if not "dash_cooldown_timer" in p or not "dash_cooldown" in p:
		return
	if p.dash_cooldown_timer > 0:
		dash_label.text = "[SPACE] Dash"
		dash_label.modulate = Color(0.5, 0.5, 0.5)
		# Barra carrega de 0 ate 1 conforme o cooldown passa
		var progress = 1.0 - (p.dash_cooldown_timer / p.dash_cooldown)
		dash_cooldown_bar.value = clampf(progress, 0.0, 1.0)
		dash_cooldown_bar.visible = true
	else:
		dash_label.text = "[SPACE] Dash"
		dash_label.modulate = Color.WHITE
		dash_cooldown_bar.value = 1.0
		dash_cooldown_bar.visible = false

func _update_ally_hp() -> void:
	if not ally_hp_container or not MultiplayerManager.is_online:
		return
	var players = get_tree().get_nodes_in_group("players")
	if players.size() <= 1:
		return

	# Build a hash of ally player IDs to detect structural changes
	var ally_hash := ""
	for p in players:
		if not is_instance_valid(p) or not "player_id" in p:
			continue
		if p.is_local:
			continue
		ally_hash += str(p.player_id) + ","

	# Only rebuild nodes if the set of players changed
	if ally_hash != _prev_ally_hash:
		_prev_ally_hash = ally_hash
		_ally_bars.clear()
		for child in ally_hp_container.get_children():
			child.queue_free()

		var colors = MultiplayerManager.get_player_colors()
		for p in players:
			if not is_instance_valid(p) or not "player_id" in p:
				continue
			if p.is_local:
				continue
			var hbox = HBoxContainer.new()
			var name_lbl = Label.new()
			name_lbl.text = "P%d" % p.player_id
			name_lbl.add_theme_font_size_override("font_size", 12)
			name_lbl.custom_minimum_size = Vector2(30, 0)
			hbox.add_child(name_lbl)
			var bar = ProgressBar.new()
			bar.custom_minimum_size = Vector2(100, 12)
			var ally_max_hp = MultiplayerManager.get_player_max_hp(p.player_id)
			var ally_hp = MultiplayerManager.get_player_hp(p.player_id)
			bar.max_value = ally_max_hp
			bar.value = ally_hp
			bar.show_percentage = false
			var fill = StyleBoxFlat.new()
			fill.bg_color = colors.get(p.player_id, Color.GREEN)
			fill.set_corner_radius_all(2)
			bar.add_theme_stylebox_override("fill", fill)
			hbox.add_child(bar)
			ally_hp_container.add_child(hbox)
			_ally_bars[p.player_id] = bar
	else:
		# Just update bar values without rebuilding
		for p in players:
			if not is_instance_valid(p) or not "player_id" in p:
				continue
			if p.is_local:
				continue
			if p.player_id in _ally_bars and is_instance_valid(_ally_bars[p.player_id]):
				var ally_max_hp = MultiplayerManager.get_player_max_hp(p.player_id)
				var ally_hp = MultiplayerManager.get_player_hp(p.player_id)
				_ally_bars[p.player_id].max_value = ally_max_hp
				_ally_bars[p.player_id].value = ally_hp

func _update_ping() -> void:
	if not ping_label or not MultiplayerManager.is_online:
		return
	# Get approximate round-trip time
	var peer = multiplayer.multiplayer_peer
	if peer and not multiplayer.is_server():
		# ENet peer has get_peer method
		var rtt = 0
		if peer.has_method("get_peer"):
			var enet_peer = peer.get_peer(1)
			if enet_peer:
				rtt = enet_peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
		ping_label.text = "Ping: %dms" % rtt
	else:
		ping_label.text = "Host"

func _update_ally_arrows() -> void:
	if not MultiplayerManager.is_online:
		return
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	var viewport_size = get_viewport().get_visible_rect().size
	var local_player = get_tree().get_first_node_in_group("players")
	if not local_player or not is_instance_valid(local_player):
		return
	var players = get_tree().get_nodes_in_group("players")
	var colors = MultiplayerManager.get_player_colors()
	for p in players:
		if not is_instance_valid(p) or p == local_player:
			continue
		var pid = p.player_id if "player_id" in p else 0
		# Check if ally is off-screen
		var screen_pos = camera.unproject_position(p.global_position)
		var margin = 40.0
		var is_offscreen = screen_pos.x < margin or screen_pos.x > viewport_size.x - margin or screen_pos.y < margin or screen_pos.y > viewport_size.y - margin
		if not is_offscreen:
			if pid in ally_arrows and is_instance_valid(ally_arrows[pid]):
				ally_arrows[pid].visible = false
			continue
		# Create or reuse arrow label
		if pid not in ally_arrows or not is_instance_valid(ally_arrows[pid]):
			var arrow = Label.new()
			arrow.add_theme_font_size_override("font_size", 24)
			arrow.add_theme_color_override("font_color", colors.get(pid, Color.GREEN))
			add_child(arrow)
			ally_arrows[pid] = arrow
		var arrow: Label = ally_arrows[pid]
		arrow.visible = true
		# Clamp position to screen edges
		var clamped = Vector2(
			clampf(screen_pos.x, margin, viewport_size.x - margin),
			clampf(screen_pos.y, margin, viewport_size.y - margin)
		)
		arrow.position = clamped
		# Direction arrow character
		var dir = (screen_pos - viewport_size / 2).normalized()
		if absf(dir.x) > absf(dir.y):
			arrow.text = ">" if dir.x > 0 else "<"
		else:
			arrow.text = "v" if dir.y > 0 else "^"
		arrow.text += " P%d" % pid

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

	# Clear old labels
	for child in synergy_container.get_children():
		child.queue_free()

	var synergy_display := {
		"fire_fire": {"name": "Explosion", "color": Color(1.0, 0.6, 0.1)},
		"ice_ice": {"name": "Shatter", "color": Color(0.4, 0.9, 1.0)},
		"electric_electric": {"name": "Chain", "color": Color(1.0, 1.0, 0.3)},
		"dark_dark": {"name": "Darkness", "color": Color(0.7, 0.3, 0.9)},
		"fire_ice": {"name": "Steam", "color": Color.WHITE},
		"electric_ice": {"name": "Conductor", "color": Color(0.3, 0.5, 1.0)},
	}

	for syn_id in synergies:
		var info = synergy_display.get(syn_id, null)
		if info == null:
			continue
		var lbl = Label.new()
		lbl.text = info["name"]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", info["color"])
		synergy_container.add_child(lbl)

# ---- Multiplayer HUD stubs (sinais conectados mas funcoes pendentes) ----

func _setup_ally_hp_panel() -> void:
	pass  # TODO: painel com barras de HP dos aliados

func _setup_ping_label() -> void:
	pass  # TODO: label de ping no canto

func _setup_migration_label() -> void:
	pass  # TODO: label de host migration

func _on_host_migration_started() -> void:
	pass

func _on_host_migration_completed(_data: Variant = null) -> void:
	pass

func _on_reconnection_attempted() -> void:
	pass

func _on_reconnection_succeeded() -> void:
	pass

func _on_reconnection_failed() -> void:
	pass
