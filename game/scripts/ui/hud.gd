extends CanvasLayer

## HUD: HP, XP, level, timer, kills, dash cooldown.

@onready var hp_bar: ProgressBar = $MarginContainer/VBox/HPBar
@onready var xp_bar: ProgressBar = $MarginContainer/VBox/XPBar
@onready var level_label: Label = $MarginContainer/VBox/LevelLabel
@onready var time_label: Label = $TopRight/TimeLabel
@onready var kill_label: Label = $TopRight/KillLabel
@onready var dash_label: Label = $BottomCenter/DashLabel
@onready var event_label: Label = $EventNotification/EventLabel

var event_display_timer: float = 0.0

# Weapon/Item icon containers and boss HP bar (created in _ready)
var weapon_container: HBoxContainer
var item_container: HBoxContainer
var boss_hp_bar: ProgressBar

# Cache to avoid rebuilding every frame
var _prev_weapon_hash: String = ""
var _prev_item_hash: String = ""

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

func _process(_delta: float) -> void:
	_update_hp()
	_update_xp()
	_update_time()
	_update_kills()
	_update_weapon_icons()
	_update_item_icons()
	_update_boss_hp()

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

func _on_game_over() -> void:
	pass

func _on_event_started(event_name: String) -> void:
	var display_names = {
		"golden_horde": "HORDA DOURADA!",
		"treasure_goblin": "TREASURE GOBLIN!",
		"merchant": "MERCADOR APARECEU!",
		"roulette": "RODA DA FORTUNA!",
	}
	event_label.text = display_names.get(event_name, event_name.to_upper())
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
