extends CanvasLayer

## HUD: HP, XP, level, timer, kills, dash cooldown.

@onready var hp_bar: ProgressBar = $MarginContainer/VBox/HPBar
@onready var character_hp_bar: Control = $MarginContainer/VBox/CharacterHPBar
@onready var xp_bar: ProgressBar = $MarginContainer/VBox/XPBar
@onready var level_label: Label = $MarginContainer/VBox/LevelLabel
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

	# Character-themed HP bar — inicializa com personagem selecionado
	hp_bar.visible = false
	character_hp_bar.set_character(GameManager.selected_character)
	character_hp_bar.set_hp(float(GameManager.player_hp), float(GameManager.player_max_hp * GameManager.max_hp_mult))
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
	level_label.add_theme_font_size_override("font_size", 13)
	level_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 0.9))

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
		_update_time()
		_update_kills()
		_update_weapon_icons()
		_update_item_icons()
		_update_boss_hp()
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

	# Atualiza a barra de HP temática por personagem
	character_hp_bar.set_hp(float(current_hp), float(max_hp))
	_prev_hp = current_hp

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
	# Punch effect na barra temática
	character_hp_bar.trigger_punch()
	# Scale bounce na barra temática
	var tween = create_tween()
	character_hp_bar.scale = Vector2(1.08, 1.15)
	tween.tween_property(character_hp_bar, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _on_achievement_unlocked(_id: String, name: String) -> void:
	achievement_label.text = LocaleManager.tr_key("achievement_label") % name

	# Load achievement icon sprite if available
	var icon_path = "res://assets/sprites/achievements/%s.png" % _id
	var icon_tex = load(icon_path) if ResourceLoader.exists(icon_path) else null
	if icon_tex:
		achievement_icon.texture = icon_tex
		achievement_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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

		var _icon_path := "res://assets/sprites/weapons/%s.png" % w.id
		var _icon_tex = load(_icon_path) if ResourceLoader.exists(_icon_path) else null
		var icon_node: Control
		if _icon_tex:
			var tex_rect := TextureRect.new()
			tex_rect.texture = _icon_tex
			tex_rect.custom_minimum_size = Vector2(28, 28)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		lbl.offset_left = -12
		lbl.offset_top = -14
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

		var _icon_path := "res://assets/sprites/items/%s.png" % it.id
		var _icon_tex = load(_icon_path) if ResourceLoader.exists(_icon_path) else null
		var icon_node: Control
		if _icon_tex:
			var tex_rect := TextureRect.new()
			tex_rect.texture = _icon_tex
			tex_rect.custom_minimum_size = Vector2(28, 28)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		lbl.offset_left = -12
		lbl.offset_top = -14
		lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
		icon_node.add_child(lbl)

		item_container.add_child(panel)

# --------------- Boss HP Bar ---------------

func _update_boss_hp() -> void:
	# Use cached group lookup from GameManager instead of direct tree query
	var bosses := get_tree().get_nodes_in_group("boss")  # Small group, no perf concern
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
	var players = GameManager.get_players()
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
		if ally_hp_panel:
			ally_hp_panel.visible = false
		return
	var players_list = GameManager.get_players()
	if players_list.size() <= 1:
		if ally_hp_panel:
			ally_hp_panel.visible = false
		return
	if ally_hp_panel:
		ally_hp_panel.visible = true

	# Build a hash of ally player IDs to detect structural changes
	var ally_hash := ""
	for p in players_list:
		if not is_instance_valid(p) or not "player_id" in p:
			continue
		if p.is_local:
			continue
		ally_hash += str(p.player_id) + ","

	# Only rebuild nodes if the set of players changed
	if ally_hash != _prev_ally_hash:
		_prev_ally_hash = ally_hash
		_ally_bars.clear()
		_ally_name_labels.clear()
		_ally_hp_labels.clear()
		for child in ally_hp_container.get_children():
			child.queue_free()

		var colors = MultiplayerManager.get_player_colors()
		for p in players_list:
			if not is_instance_valid(p) or not "player_id" in p:
				continue
			if p.is_local:
				continue

			var pid = p.player_id
			var color = colors.get(pid, Color.GREEN)

			# Container vertical por aliado
			var ally_vbox = VBoxContainer.new()
			ally_vbox.add_theme_constant_override("separation", 1)

			# Linha 1: nome + HP numerico
			var top_hbox = HBoxContainer.new()
			top_hbox.add_theme_constant_override("separation", 4)

			# Indicador de cor (bolinha)
			var color_dot = ColorRect.new()
			color_dot.custom_minimum_size = Vector2(8, 8)
			color_dot.color = color
			top_hbox.add_child(color_dot)

			var name_lbl = Label.new()
			# Tenta pegar nome do personagem
			var char_name = "P%d" % pid
			if pid in MultiplayerManager.players:
				var char_id = MultiplayerManager.players[pid].get("character", "")
				if char_id != "":
					char_name = char_id.capitalize()
			name_lbl.text = char_name
			name_lbl.add_theme_font_size_override("font_size", 11)
			name_lbl.add_theme_color_override("font_color", color)
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			top_hbox.add_child(name_lbl)
			_ally_name_labels[pid] = name_lbl

			var hp_lbl = Label.new()
			var ally_hp = MultiplayerManager.get_player_hp(pid)
			var ally_max_hp = MultiplayerManager.get_player_max_hp(pid)
			hp_lbl.text = "%d/%d" % [ally_hp, ally_max_hp]
			hp_lbl.add_theme_font_size_override("font_size", 10)
			hp_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
			hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			top_hbox.add_child(hp_lbl)
			_ally_hp_labels[pid] = hp_lbl

			ally_vbox.add_child(top_hbox)

			# Linha 2: barra de HP
			var bar = ProgressBar.new()
			bar.custom_minimum_size = Vector2(140, 10)
			bar.max_value = ally_max_hp
			bar.value = ally_hp
			bar.show_percentage = false

			var fill = StyleBoxFlat.new()
			fill.bg_color = color
			fill.set_corner_radius_all(3)
			bar.add_theme_stylebox_override("fill", fill)

			var bar_bg = StyleBoxFlat.new()
			bar_bg.bg_color = Color(0.1, 0.1, 0.15, 0.9)
			bar_bg.set_corner_radius_all(3)
			bar_bg.set_border_width_all(1)
			bar_bg.border_color = color * Color(1, 1, 1, 0.3)
			bar.add_theme_stylebox_override("background", bar_bg)

			ally_vbox.add_child(bar)
			ally_hp_container.add_child(ally_vbox)
			_ally_bars[pid] = bar
	else:
		# Just update bar values and HP text without rebuilding
		for p in players_list:
			if not is_instance_valid(p) or not "player_id" in p:
				continue
			if p.is_local:
				continue
			var pid = p.player_id
			var ally_max_hp = MultiplayerManager.get_player_max_hp(pid)
			var ally_hp = MultiplayerManager.get_player_hp(pid)
			if pid in _ally_bars and is_instance_valid(_ally_bars[pid]):
				_ally_bars[pid].max_value = ally_max_hp
				# Interpola suavemente o valor da barra
				_ally_bars[pid].value = lerpf(_ally_bars[pid].value, float(ally_hp), 0.15)
			if pid in _ally_hp_labels and is_instance_valid(_ally_hp_labels[pid]):
				_ally_hp_labels[pid].text = "%d/%d" % [ally_hp, ally_max_hp]
				# Vermelho se HP < 25%
				if ally_max_hp > 0 and float(ally_hp) / float(ally_max_hp) < 0.25:
					_ally_hp_labels[pid].add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
				else:
					_ally_hp_labels[pid].add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))

func _update_ping() -> void:
	if not ping_label or not MultiplayerManager.is_online:
		return
	if multiplayer.is_server():
		ping_label.text = "Host"
		ping_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	else:
		var rtt = MultiplayerManager.get_ping()
		ping_label.text = "Ping: %dms" % rtt
		ping_label.add_theme_color_override("font_color", MultiplayerManager.get_ping_color())

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
	var players_in_group = GameManager.get_players()
	var colors = MultiplayerManager.get_player_colors()
	for p in players_in_group:
		if not is_instance_valid(p) or p == local_player:
			continue
		var pid = p.player_id if "player_id" in p else 0
		# Distancia 3D entre jogadores
		var dist_3d = local_player.global_position.distance_to(p.global_position)
		# Checa se o aliado esta atras da camera
		var behind_camera = camera.global_transform.basis.z.dot(p.global_position - camera.global_position) > 0
		var screen_pos = camera.unproject_position(p.global_position)
		# Se esta atras da camera, inverte a posicao na tela
		if behind_camera:
			screen_pos = viewport_size - screen_pos
		var margin = 40.0
		var is_offscreen = behind_camera or screen_pos.x < margin or screen_pos.x > viewport_size.x - margin or screen_pos.y < margin or screen_pos.y > viewport_size.y - margin
		if not is_offscreen:
			if pid in ally_arrows and is_instance_valid(ally_arrows[pid]):
				ally_arrows[pid].visible = false
			continue
		# Create or reuse arrow label
		if pid not in ally_arrows or not is_instance_valid(ally_arrows[pid]):
			var arrow = Label.new()
			arrow.add_theme_font_size_override("font_size", 18)
			arrow.add_theme_color_override("font_color", colors.get(pid, Color.GREEN))
			arrow.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
			arrow.add_theme_constant_override("shadow_offset_x", 1)
			arrow.add_theme_constant_override("shadow_offset_y", 1)
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
		# Direction arrow character (unicode arrows mais bonitos)
		var dir = (screen_pos - viewport_size / 2).normalized()
		var arrow_char: String
		if absf(dir.x) > absf(dir.y):
			arrow_char = "►" if dir.x > 0 else "◄"
		else:
			arrow_char = "▼" if dir.y > 0 else "▲"
		# Mostra distancia estimada
		var dist_text = "%dm" % int(dist_3d) if dist_3d >= 10 else "%.0fm" % dist_3d
		arrow.text = "%s P%d %s" % [arrow_char, pid, dist_text]
		# Opacidade baseada na distancia (mais longe = mais opaco/visivel)
		var alpha = clampf(remap(dist_3d, 5.0, 50.0, 0.5, 1.0), 0.5, 1.0)
		arrow.modulate.a = alpha

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

# ---- Multiplayer HUD (ally HP, ping, host migration, reconexão) ----

func _setup_ally_hp_panel() -> void:
	## Painel top-right com barras de HP dos aliados (coloridas por jogador).
	ally_hp_panel = PanelContainer.new()
	ally_hp_panel.name = "AllyHPPanel"
	ally_hp_panel.anchor_left = 1.0
	ally_hp_panel.anchor_top = 0.0
	ally_hp_panel.anchor_right = 1.0
	ally_hp_panel.anchor_bottom = 0.0
	ally_hp_panel.offset_left = -180.0
	ally_hp_panel.offset_top = 60.0
	ally_hp_panel.offset_right = -10.0
	ally_hp_panel.offset_bottom = 200.0
	ally_hp_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.1, 0.75)
	panel_style.set_corner_radius_all(6)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(0.2, 0.3, 0.5, 0.6)
	panel_style.set_content_margin_all(8)
	ally_hp_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	# Titulo
	var title = Label.new()
	title.text = "Aliados"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	ally_hp_container = VBoxContainer.new()
	ally_hp_container.add_theme_constant_override("separation", 4)
	vbox.add_child(ally_hp_container)

	ally_hp_panel.add_child(vbox)
	add_child(ally_hp_panel)

func _setup_ping_label() -> void:
	## Label de ping (abaixo do painel de aliados ou top-right).
	ping_label = Label.new()
	ping_label.name = "PingLabel"
	ping_label.anchor_left = 1.0
	ping_label.anchor_top = 0.0
	ping_label.anchor_right = 1.0
	ping_label.anchor_bottom = 0.0
	ping_label.offset_left = -100.0
	ping_label.offset_top = 8.0
	ping_label.offset_right = -10.0
	ping_label.offset_bottom = 28.0
	ping_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ping_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ping_label.add_theme_font_size_override("font_size", 11)
	ping_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	add_child(ping_label)

func _setup_migration_label() -> void:
	## Overlay central exibido durante host migration / reconexão.
	migration_label = Label.new()
	migration_label.name = "MigrationLabel"
	migration_label.set_anchors_preset(Control.PRESET_CENTER)
	migration_label.offset_left = -200.0
	migration_label.offset_top = -30.0
	migration_label.offset_right = 200.0
	migration_label.offset_bottom = 30.0
	migration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	migration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	migration_label.add_theme_font_size_override("font_size", 22)
	migration_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	migration_label.visible = false
	add_child(migration_label)

	# Fundo escuro semi-transparente atrás da label
	var bg = ColorRect.new()
	bg.name = "MigrationBG"
	bg.color = Color(0.0, 0.0, 0.0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.visible = false
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.move_to_front()
	migration_label.move_to_front()

var _migration_bg: ColorRect :
	get:
		return get_node_or_null("MigrationBG")

func _show_migration_overlay(text: String) -> void:
	if migration_label:
		migration_label.text = text
		migration_label.visible = true
		migration_label.modulate = Color.WHITE
		# Animação de pulso
		var tween = create_tween().set_loops()
		tween.tween_property(migration_label, "modulate:a", 0.4, 0.6)
		tween.tween_property(migration_label, "modulate:a", 1.0, 0.6)
		migration_label.set_meta("pulse_tween", tween)
	if _migration_bg:
		_migration_bg.visible = true

func _hide_migration_overlay() -> void:
	if migration_label:
		# Para o pulso
		if migration_label.has_meta("pulse_tween"):
			var tw = migration_label.get_meta("pulse_tween") as Tween
			if tw and tw.is_valid():
				tw.kill()
		migration_label.visible = false
	if _migration_bg:
		_migration_bg.visible = false

func _flash_migration_message(text: String, color: Color, duration: float = 3.0) -> void:
	## Exibe mensagem temporária (sucesso/falha) e esconde o overlay.
	if migration_label:
		# Para qualquer pulso
		if migration_label.has_meta("pulse_tween"):
			var tw = migration_label.get_meta("pulse_tween") as Tween
			if tw and tw.is_valid():
				tw.kill()
		migration_label.text = text
		migration_label.modulate = color
		migration_label.visible = true
	if _migration_bg:
		_migration_bg.visible = true
	# Fade out após duration
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(_hide_migration_overlay)

func _on_host_migration_started() -> void:
	_show_migration_overlay("Migrando host...")

func _on_host_migration_completed(_new_host_id: Variant = null) -> void:
	var is_new_host = (typeof(_new_host_id) == TYPE_INT and _new_host_id == MultiplayerManager.local_player_id)
	var msg = "Voce e o novo host!" if is_new_host else "Host migrado com sucesso"
	_flash_migration_message(msg, Color(0.3, 0.95, 0.4), 3.0)

func _on_reconnection_attempted(attempt: Variant = null, max_attempts: Variant = null) -> void:
	var a = attempt if typeof(attempt) == TYPE_INT else 0
	var m = max_attempts if typeof(max_attempts) == TYPE_INT else MultiplayerManager.MAX_RECONNECT_ATTEMPTS
	_show_migration_overlay("Reconectando... (%d/%d)" % [a, m])

func _on_reconnection_succeeded() -> void:
	_flash_migration_message("Reconectado!", Color(0.3, 0.95, 0.4), 2.5)

func _on_reconnection_failed() -> void:
	_flash_migration_message("Falha na reconexao", Color(0.95, 0.3, 0.3), 4.0)
