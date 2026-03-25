extends Node

## Estado global do jogo: XP, level, dificuldade, pause.

signal player_leveled_up(new_level: int)
signal enemy_killed(position: Vector3, xp_value: int)
signal player_died()
signal game_over()

# Tempo e dificuldade
var game_time: float = 0.0
var enemies_alive: int = 0
var max_enemies: int = 500
var total_kills: int = 0
var paused: bool = false
var is_game_over: bool = false

# Player stats
var player_level: int = 1
var player_xp: int = 0
var player_xp_to_next: int = 5
var player_max_hp: int = 100
var player_hp: int = 100

# Weapons e items do jogador
var player_weapons: Array[Dictionary] = []  # {id, level}
var player_items: Array[Dictionary] = []    # {id, level}
const MAX_WEAPONS := 6
const MAX_ITEMS := 6

# Modificadores dos itens passivos
var speed_mult: float = 1.0
var attack_speed_mult: float = 1.0
var max_hp_mult: float = 1.0

func _ready() -> void:
	_register_input_actions()

func _process(delta: float) -> void:
	if not paused and not is_game_over:
		game_time += delta

func _register_input_actions() -> void:
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("dash", KEY_SPACE)

func _add_key_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event = InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action_name, event)

func add_xp(amount: int) -> void:
	if is_game_over:
		return
	player_xp += amount
	while player_xp >= player_xp_to_next:
		player_xp -= player_xp_to_next
		player_level += 1
		player_xp_to_next = int(player_xp_to_next * 1.3) + 2
		player_leveled_up.emit(player_level)

func get_difficulty_multiplier() -> float:
	# Dificuldade escala com o tempo
	return 1.0 + (game_time / 60.0) * 0.5

func take_damage(amount: int) -> void:
	if is_game_over:
		return
	player_hp -= amount
	if player_hp <= 0:
		player_hp = 0
		is_game_over = true
		player_died.emit()
		game_over.emit()

func heal(amount: int) -> void:
	var effective_max = int(player_max_hp * max_hp_mult)
	player_hp = mini(player_hp + amount, effective_max)

func has_weapon(weapon_id: String) -> bool:
	for w in player_weapons:
		if w["id"] == weapon_id:
			return true
	return false

func get_weapon_level(weapon_id: String) -> int:
	for w in player_weapons:
		if w["id"] == weapon_id:
			return w["level"]
	return 0

func add_weapon(weapon_id: String) -> bool:
	if has_weapon(weapon_id):
		return upgrade_weapon(weapon_id)
	if player_weapons.size() >= MAX_WEAPONS:
		return false
	player_weapons.append({"id": weapon_id, "level": 1})
	return true

func upgrade_weapon(weapon_id: String) -> bool:
	for w in player_weapons:
		if w["id"] == weapon_id and w["level"] < 8:
			w["level"] += 1
			return true
	return false

func has_item(item_id: String) -> bool:
	for it in player_items:
		if it["id"] == item_id:
			return true
	return false

func get_item_level(item_id: String) -> int:
	for it in player_items:
		if it["id"] == item_id:
			return it["level"]
	return 0

func add_item(item_id: String) -> bool:
	if has_item(item_id):
		return upgrade_item(item_id)
	if player_items.size() >= MAX_ITEMS:
		return false
	player_items.append({"id": item_id, "level": 1})
	_recalculate_item_bonuses()
	return true

func upgrade_item(item_id: String) -> bool:
	for it in player_items:
		if it["id"] == item_id and it["level"] < 5:
			it["level"] += 1
			_recalculate_item_bonuses()
			return true
	return false

func _recalculate_item_bonuses() -> void:
	speed_mult = 1.0
	attack_speed_mult = 1.0
	max_hp_mult = 1.0
	for it in player_items:
		var data = ItemDB.get_item(it["id"])
		if data.is_empty():
			continue
		var level = it["level"]
		match it["id"]:
			"boots":
				speed_mult += 0.15 * level
			"glove":
				attack_speed_mult += 0.20 * level
			"heart":
				max_hp_mult += 0.20 * level
				var new_max = int(player_max_hp * max_hp_mult)
				player_hp = mini(player_hp + int(player_max_hp * 0.20), new_max)

func reset() -> void:
	game_time = 0.0
	enemies_alive = 0
	total_kills = 0
	paused = false
	is_game_over = false
	player_level = 1
	player_xp = 0
	player_xp_to_next = 5
	player_max_hp = 100
	player_hp = 100
	player_weapons.clear()
	player_items.clear()
	speed_mult = 1.0
	attack_speed_mult = 1.0
	max_hp_mult = 1.0
