extends CanvasLayer

## HUD: HP, XP, level, timer, kills, dash cooldown.

@onready var hp_bar: ProgressBar = $MarginContainer/VBox/HPBar
@onready var xp_bar: ProgressBar = $MarginContainer/VBox/XPBar
@onready var level_label: Label = $MarginContainer/VBox/LevelLabel
@onready var time_label: Label = $TopRight/TimeLabel
@onready var kill_label: Label = $TopRight/KillLabel
@onready var dash_label: Label = $BottomCenter/DashVBox/DashLabel
@onready var dash_cooldown_bar: ProgressBar = $BottomCenter/DashVBox/DashCooldownBar
@onready var event_label: Label = $EventNotification/EventLabel

var event_display_timer: float = 0.0
var achievement_check_timer: float = 0.0

# Weapon/Item icon containers and boss HP bar (created in _ready)
var weapon_container: HBoxContainer
var item_container: HBoxContainer
var boss_hp_bar: ProgressBar

# Cache to avoid rebuilding every frame
var _prev_weapon_hash: String = ""
var _prev_item_hash: String = ""

# Multiplayer ally HP bars
var ally_hp_container: VBoxContainer = null
var ping_label: Label = null
var ally_arrows: Dictionary = {}  # peer_id -> Label

# Minimap
var minimap: Control = null

func _ready() -> void:
	GameManager.player_leveled_up.connect(_on_level_up)
	GameManager.game_over.connect(_on_game_over)
	event_label.visible = false

	# Setup weapon icons container (bottom-left)
	weapon_container = $WeaponIcons
	item_container = $ItemIcons
	boss_hp_bar = $BossHPBar
	boss_hp_bar.visible = false

	# Conecta ao EventManager se existir
	await get_tree().process_frame
	var em = get_tree().current_scene.get_node_or_null("EventManager")
	if em:
		em.event_started.connect(_on_event_started)
		em.event_ended.connect(_on_event_ended)

	# Achievement notification
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

	# Custom HP bar colors
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.2, 0.8, 0.3)
	hp_fill.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)

	var hp_bg = StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.15, 0.05, 0.05)
	hp_bg.set_corner_radius_all(4)
	hp_bg.set_border_width_all(1)
	hp_bg.border_color = Color(0.3, 0.1, 0.1)
	hp_bar.add_theme_stylebox_override("background", hp_bg)

	# Custom XP bar colors
	var xp_fill = StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.3, 0.5, 1.0)
	xp_fill.set_corner_radius_all(4)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)

	var xp_bg = StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.05, 0.05, 0.15)
	xp_bg.set_corner_radius_all(4)
	xp_bg.set_border_width_all(1)
	xp_bg.border_color = Color(0.1, 0.1, 0.3)
	xp_bar.add_theme_stylebox_override("background", xp_bg)

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

	# Multiplayer ally HP bars (top-left, below main HP bar)
	if MultiplayerManager.is_online:
		ally_hp_container = VBoxContainer.new()
		ally_hp_container.position = Vector2(20, 120)
		add_child(ally_hp_container)
		# Ping display
		ping_label = Label.new()
		ping_label.add_theme_font_size_override("font_size", 12)
		ping_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		ping_label.position = Vector2(get_viewport().get_visible_rect().size.x - 100, 10)
		add_child(ping_label)

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
	# Check achievements every 10s
	achievement_check_timer += delta
	if achievement_check_timer >= 10.0:
		achievement_check_timer = 0.0
		AchievementManager.check_achievements()

func _update_hp() -> void:
	var max_hp = int(GameManager.player_max_hp * GameManager.max_hp_mult)
	hp_bar.max_value = max_hp
	hp_bar.value = GameManager.player_hp

func _update_xp() -> void:
	xp_bar.max_value = GameManager.player_xp_to_next
	xp_bar.value = GameManager.player_xp

func _update_time() -> void:
	var t = int(GameManager.game_time)
	time_label.text = "%02d:%02d" % [t / 60, t % 60]

func _update_kills() -> void:
	kill_label.text = "Kills: %d | Cristais: %d" % [GameManager.total_kills, GameManager.crystals_this_run]

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

func _on_achievement_unlocked(_id: String, name: String) -> void:
	event_label.text = "ACHIEVEMENT: %s" % name
	event_label.visible = true
	event_label.modulate = Color(1.0, 0.85, 0.2)
	event_label.scale = Vector2(1.5, 1.5)
	var tween = create_tween()
	tween.tween_property(event_label, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_interval(3.0)
	tween.tween_callback(func(): event_label.visible = false)

func _on_event_started(event_name: String) -> void:
	var locale_key = "event_" + event_name
	var text = LocaleManager.tr_key(locale_key)
	# Fallback to hardcoded if locale key not found
	if text == locale_key:
		var display_names = {
			"golden_horde": "HORDA DOURADA!",
			"treasure_goblin": "TREASURE GOBLIN!",
			"merchant": "MERCADOR APARECEU!",
			"roulette": "RODA DA FORTUNA!",
			"eclipse": "ECLIPSE!",
			"meteor_shower": "CHUVA DE METEOROS!",
			"angel_challenge": "DESAFIO DO ANJO!",
			"portal_dimensional": "PORTAL DIMENSIONAL!",
			"chest_mimic": "BAU MIMIC!",
			"fever_mode": "FEVER MODE!",
		}
		text = display_names.get(event_name, event_name.to_upper())
	event_label.text = text
	event_label.visible = true

func _on_event_ended(_event_name: String) -> void:
	event_label.visible = false

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
		panel.custom_minimum_size = Vector2(24, 24)

		var rect := ColorRect.new()
		rect.custom_minimum_size = Vector2(24, 24)
		rect.color = color
		panel.add_child(rect)

		var lbl := Label.new()
		lbl.text = str(w.level)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.add_child(lbl)

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
		panel.custom_minimum_size = Vector2(24, 24)

		var rect := ColorRect.new()
		rect.custom_minimum_size = Vector2(24, 24)
		rect.color = color
		panel.add_child(rect)

		var lbl := Label.new()
		lbl.text = str(it.level)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.add_child(lbl)

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
	# Rebuild ally HP bars (cheap, only runs in multiplayer)
	for child in ally_hp_container.get_children():
		child.queue_free()
	var colors = MultiplayerManager.get_player_colors()
	for p in players:
		if not is_instance_valid(p) or not "player_id" in p:
			continue
		if p.is_local:
			continue  # Skip local player (shown in main HP bar)
		var hbox = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = "P%d" % p.player_id
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.custom_minimum_size = Vector2(30, 0)
		hbox.add_child(name_lbl)
		var bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(100, 12)
		bar.max_value = GameManager.get_effective_max_hp()
		bar.value = GameManager.player_hp  # In full multiplayer, each player would have own HP
		bar.show_percentage = false
		var fill = StyleBoxFlat.new()
		fill.bg_color = colors.get(p.player_id, Color.GREEN)
		fill.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("fill", fill)
		hbox.add_child(bar)
		ally_hp_container.add_child(hbox)

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
