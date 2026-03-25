extends Node

## Estado global do jogo: XP, level, dificuldade, pause, stats.

signal player_leveled_up(new_level: int)
signal enemy_killed(position: Vector3, xp_value: int)
signal player_died()
signal game_over()
signal weapon_added(weapon_id: String)
signal weapon_upgraded(weapon_id: String, new_level: int)

# Tempo e dificuldade
var game_time: float = 0.0
var enemies_alive: int = 0
var max_enemies: int = 500
var total_kills: int = 0
var total_damage_dealt: int = 0
var paused: bool = false
var is_game_over: bool = false

# Player stats base
var player_level: int = 1
var player_xp: int = 0
var player_xp_to_next: int = 5
var player_max_hp: int = 100
var player_hp: int = 100
var crystals_this_run: int = 0

# Selecao pre-run
var selected_character: String = "ronin"
var selected_relic: String = ""

# Bonuses permanentes da loja
var perm_damage_mult: float = 1.0
var perm_speed_mult: float = 1.0
var perm_armor: int = 0
var xp_mult: float = 1.0
var rerolls: int = 1

# Weapons e items do jogador
var player_weapons: Array[Dictionary] = []  # {id, level}
var player_items: Array[Dictionary] = []    # {id, level}
const MAX_WEAPONS := 6
const MAX_ITEMS := 6

# Modificadores dos itens passivos (recalculados)
var speed_mult: float = 1.0
var attack_speed_mult: float = 1.0
var max_hp_mult: float = 1.0
var area_mult: float = 1.0
var magnet_mult: float = 1.0
var cooldown_mult: float = 1.0

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
	_add_key_action("interact", KEY_E)

func _add_key_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event = InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action_name, event)

func add_xp(amount: int) -> void:
	if is_game_over:
		return
	player_xp += int(amount * xp_mult)
	while player_xp >= player_xp_to_next:
		player_xp -= player_xp_to_next
		player_level += 1
		player_xp_to_next = int(player_xp_to_next * 1.3) + 2
		player_leveled_up.emit(player_level)
		# Level up particles
		var players = get_tree().get_nodes_in_group("players")
		if not players.is_empty():
			ParticleFactory.spawn_level_up_particles(players[0].global_position)
			ScreenEffects.shake(0.1)

func get_difficulty_multiplier() -> float:
	return 1.0 + (game_time / 60.0) * 0.5

func take_damage(amount: int) -> void:
	if is_game_over:
		return
	var reduced = maxi(1, amount - perm_armor)
	player_hp -= reduced
	if player_hp <= 0:
		player_hp = 0
		is_game_over = true
		player_died.emit()
		game_over.emit()

func heal(amount: int) -> void:
	var effective_max = get_effective_max_hp()
	player_hp = mini(player_hp + amount, effective_max)

func get_effective_max_hp() -> int:
	return int(player_max_hp * max_hp_mult)

# ---- Weapons ----
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
	weapon_added.emit(weapon_id)
	return true

func upgrade_weapon(weapon_id: String) -> bool:
	for w in player_weapons:
		if w["id"] == weapon_id and w["level"] < 8:
			w["level"] += 1
			weapon_upgraded.emit(weapon_id, w["level"])
			return true
	return false

# ---- Items ----
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
	area_mult = 1.0
	magnet_mult = 1.0
	cooldown_mult = 1.0

	for it in player_items:
		var data = ItemDB.get_item(it["id"])
		if data.is_empty():
			continue
		var level = it["level"]
		var value = data["value_per_level"] * level
		match data["stat"]:
			"speed":
				speed_mult += value
			"attack_speed":
				attack_speed_mult += value
			"max_hp":
				max_hp_mult += value
				# Cura proporcional ao ganho
				var new_max = get_effective_max_hp()
				player_hp = mini(player_hp + int(player_max_hp * data["value_per_level"]), new_max)
			"area":
				area_mult += value
			"magnet":
				magnet_mult += value
			"cooldown":
				cooldown_mult = maxf(0.3, cooldown_mult - value)

func reset() -> void:
	game_time = 0.0
	enemies_alive = 0
	total_kills = 0
	total_damage_dealt = 0
	paused = false
	is_game_over = false
	player_level = 1
	player_xp = 0
	player_xp_to_next = 5
	player_max_hp = 100
	player_hp = 100
	crystals_this_run = 0
	player_weapons.clear()
	player_items.clear()
	speed_mult = 1.0
	attack_speed_mult = 1.0
	max_hp_mult = 1.0
	area_mult = 1.0
	magnet_mult = 1.0
	cooldown_mult = 1.0
	perm_damage_mult = 1.0
	perm_speed_mult = 1.0
	perm_armor = 0
	xp_mult = 1.0
	rerolls = 1
	_apply_permanent_upgrades()
	_apply_character_bonuses()
	_apply_relic()

func _apply_permanent_upgrades() -> void:
	var hp_lvl = SaveManager.get_upgrade_level("max_hp")
	player_max_hp += hp_lvl * 10
	player_hp = player_max_hp

	var speed_lvl = SaveManager.get_upgrade_level("speed")
	perm_speed_mult = 1.0 + speed_lvl * 0.05

	var dmg_lvl = SaveManager.get_upgrade_level("damage")
	perm_damage_mult = 1.0 + dmg_lvl * 0.05

	var armor_lvl = SaveManager.get_upgrade_level("armor")
	perm_armor = armor_lvl * 2

	var xp_lvl = SaveManager.get_upgrade_level("xp_bonus")
	xp_mult = 1.0 + xp_lvl * 0.10

	var mag_lvl = SaveManager.get_upgrade_level("magnetism")
	magnet_mult += mag_lvl * 0.20

func _apply_character_bonuses() -> void:
	var char_data = CharacterDB.get_character(selected_character)
	if char_data.is_empty():
		return
	if "speed_bonus" in char_data:
		perm_speed_mult += char_data["speed_bonus"]
	if "attack_speed_bonus" in char_data:
		attack_speed_mult += char_data["attack_speed_bonus"]
	if "area_bonus" in char_data:
		area_mult += char_data["area_bonus"]

func _apply_relic() -> void:
	if selected_relic.is_empty():
		return
	var relic = RelicDB.get_relic(selected_relic)
	if relic.is_empty():
		return
	match relic["effect"]:
		"bonus_hp":
			player_max_hp = int(player_max_hp * 1.5)
			player_hp = player_max_hp
		"extra_reroll":
			rerolls += 1

func end_run() -> void:
	# Cristais = kills / 5 (minimo)
	crystals_this_run = maxi(total_kills / 5, 10)
	SaveManager.end_run(crystals_this_run, game_time, total_kills)
