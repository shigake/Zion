extends Node

## Estado global do jogo: XP, level, dificuldade, pause, stats.

signal player_leveled_up(new_level: int)
signal enemy_killed(position: Vector3, xp_value: int)
signal player_died()
signal game_over()
signal weapon_added(weapon_id: String)
signal weapon_upgraded(weapon_id: String, new_level: int)
signal miniboss_spawned(boss_name: String)

# Tempo e dificuldade
var game_time: float = 0.0
var enemies_alive: int = 0
var max_enemies: int = 500
var total_kills: int = 0
var total_damage_dealt: int = 0
var peak_enemies: int = 0
var events_triggered: Array[String] = []
var paused: bool = false
var is_game_over: bool = false
var is_victory: bool = false  # true se boss morreu, false se jogador morreu

# Player stats base
var player_level: int = 1
var player_xp: int = 0
var player_xp_to_next: int = 5
var player_max_hp: int = 100
var player_hp: int = 100
var crystals_this_run: int = 0

# Selecao pre-run
var selected_character: String = "ronin"
var selected_stage: String = "cemetery"
var selected_relic: String = ""

# Bonuses permanentes da loja
var perm_damage_mult: float = 1.0
var perm_speed_mult: float = 1.0
var perm_armor: int = 0
var xp_mult: float = 1.0
var rerolls: int = 1
var veteran_relic_active: bool = false

# Modo de jogo
var game_mode: String = "normal"  # "normal", "endless", "boss_rush", "hyper"
var run_time_limit: float = 1800.0  # 30 min default

# Weapons e items do jogador
var player_weapons: Array[Dictionary] = []  # {id, level}
var player_items: Array[Dictionary] = []    # {id, level}
var MAX_WEAPONS: int = 4  # Base 4, upgradeable to 6
const MAX_ITEMS := 6

# Revive e Banish
var revives_remaining: int = 0
var banishes: int = 0
var banished_options: Array[String] = []  # IDs banidos desta run

# Modificadores dos itens passivos (recalculados)
var speed_mult: float = 1.0
var attack_speed_mult: float = 1.0
var max_hp_mult: float = 1.0
var area_mult: float = 1.0
var magnet_mult: float = 1.0
var cooldown_mult: float = 1.0
var dodge_chance: float = 0.0
var lifesteal: float = 0.0
var thorns_mult: float = 0.0
var luck_mult: float = 1.0
var extra_projectiles: int = 0
var summon_damage_mult: float = 1.0
var attack_size_mult: float = 1.0
var explosion_damage_mult: float = 1.0
var fire_ground_active: bool = false
var weapon_level_bonus: int = 0
var accuracy_mult: float = 1.0
var low_hp_damage_bonus: float = 0.0
var player_hidden: bool = false
var electric_damage_mult: float = 1.0
var crit_chance: float = 0.0
var crit_multiplier: float = 2.0

# Map boundary (half-size, stages are 200x200 so default ±95 with margin)
var map_half_size: float = 95.0

# Manual aiming (right stick)
var manual_aim: bool = false
var aim_direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	_register_input_actions()
	LogManager.info("Game", "GameManager ready")

func _process(delta: float) -> void:
	if not paused and not is_game_over:
		game_time += delta
		if enemies_alive > peak_enemies:
			peak_enemies = enemies_alive

func _register_input_actions() -> void:
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("dash", KEY_SPACE)
	_add_key_action("interact", KEY_E)
	# Gamepad
	_add_joypad_actions()

func _add_key_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event = InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action_name, event)

func _add_joypad_actions() -> void:
	# Left stick movement
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	# A/X = Dash
	_add_joy_button("dash", JOY_BUTTON_A)
	# B/Circle = Interact
	_add_joy_button("interact", JOY_BUTTON_B)
	# Start = Pause
	_add_joy_button("pause", JOY_BUTTON_START)
	# D-Pad for UI navigation
	_add_joy_button("ui_up", JOY_BUTTON_DPAD_UP)
	_add_joy_button("ui_down", JOY_BUTTON_DPAD_DOWN)
	_add_joy_button("ui_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button("ui_right", JOY_BUTTON_DPAD_RIGHT)
	# B/Circle = Cancel (back navigation)
	_add_joy_button("ui_cancel", JOY_BUTTON_B)

func _add_joy_axis(action_name: String, axis: int, axis_value: float) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action_name, event)

func _add_joy_button(action_name: String, button: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event = InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action_name, event)

func add_xp(amount: int) -> void:
	if is_game_over:
		return
	var final_mult = xp_mult
	if game_mode == "hyper":
		final_mult *= 2.0
	player_xp += int(amount * final_mult)
	while player_xp >= player_xp_to_next:
		player_xp -= player_xp_to_next
		player_level += 1
		player_xp_to_next = int(player_xp_to_next * 1.15) + 3
		player_leveled_up.emit(player_level)
		AudioManager.play_sfx("level_up")
		# Level up particles
		var players = get_tree().get_nodes_in_group("players")
		if not players.is_empty():
			ParticleFactory.spawn_level_up_particles(players[0].global_position)
			ScreenEffects.shake(0.1)

func get_difficulty_multiplier() -> float:
	# Cresce mais devagar, cap em 8x
	return minf(8.0, 1.0 + (game_time / 60.0) * 0.35)

# ---- Multiplayer Scaling ----
func get_mp_hp_mult() -> float:
	var count = MultiplayerManager.get_player_count()
	return [1.0, 1.0, 1.3, 1.6, 2.0][mini(count, 4)]

func get_mp_spawn_mult() -> float:
	var count = MultiplayerManager.get_player_count()
	return [1.0, 1.0, 1.2, 1.4, 1.6][mini(count, 4)]

func get_mp_boss_hp_mult() -> float:
	var count = MultiplayerManager.get_player_count()
	return [1.0, 1.0, 1.5, 2.0, 2.5][mini(count, 4)]

func take_damage(amount: int) -> void:
	if is_game_over:
		return
	# Dodge check
	if dodge_chance > 0.0 and randf() < dodge_chance:
		AchievementManager._run_dodges += 1
		return  # Dodged!
	AudioManager.play_sfx("player_hurt")
	var reduced = maxi(1, amount - perm_armor)
	# Thorns: reflect damage to nearest enemy
	if thorns_mult > 0.0:
		var reflected = int(reduced * thorns_mult)
		if reflected > 0:
			var enemies = get_tree().get_nodes_in_group("enemies")
			var players = get_tree().get_nodes_in_group("players")
			if not players.is_empty() and not enemies.is_empty():
				var player_pos = players[0].global_position
				var nearest: Node3D = null
				var min_dist = INF
				for e in enemies:
					if is_instance_valid(e) and e.has_method("take_damage"):
						var d = player_pos.distance_squared_to(e.global_position)
						if d < min_dist:
							min_dist = d
							nearest = e
				if nearest:
					nearest.call_deferred("take_damage", reflected, "physical")
	player_hp -= reduced
	# Lifesteal tracking (applied by weapons on hit, not here)
	if player_hp <= 0:
		# Revive check
		if revives_remaining > 0:
			revives_remaining -= 1
			player_hp = get_effective_max_hp() / 2
			ScreenEffects.shake(0.3)
			return
		player_hp = 0
		is_game_over = true
		LogManager.info("Game", "Player died at %.1fs, kills: %d, level: %d" % [game_time, total_kills, player_level])
		player_died.emit()
		game_over.emit()

func heal(amount: int) -> void:
	var heal_amount = amount
	if selected_character == "chef":
		heal_amount *= 2
	var effective_max = get_effective_max_hp()
	player_hp = mini(player_hp + heal_amount, effective_max)

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
			if it["level"] >= 5:
				AchievementManager.on_legendary_item()
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
	dodge_chance = 0.0
	lifesteal = 0.0
	thorns_mult = 0.0
	luck_mult = 1.0
	extra_projectiles = 0
	summon_damage_mult = 1.0
	attack_size_mult = 1.0
	explosion_damage_mult = 1.0
	fire_ground_active = false
	weapon_level_bonus = 0
	accuracy_mult = 1.0

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
				var new_max = get_effective_max_hp()
				player_hp = mini(player_hp + int(player_max_hp * data["value_per_level"]), new_max)
			"area":
				area_mult += value
			"magnet":
				magnet_mult += value
			"cooldown":
				cooldown_mult = maxf(0.3, cooldown_mult - value)
			"dodge":
				dodge_chance = minf(0.7, dodge_chance + value)
			"xp_bonus":
				xp_mult += value
			"explosion_damage":
				explosion_damage_mult += value
			"lifesteal":
				lifesteal += value
			"thorns":
				thorns_mult += value
			"luck":
				luck_mult += value
			"extra_projectiles":
				extra_projectiles += int(value)
			"summon_damage":
				summon_damage_mult += value
			"attack_size":
				attack_size_mult += value
			"fire_ground":
				fire_ground_active = level > 0
			"weapon_level_bonus":
				weapon_level_bonus = int(value)
			"accuracy":
				accuracy_mult += value
			"electric_damage":
				electric_damage_mult += value

func reset() -> void:
	AchievementManager.reset_run()
	game_time = 0.0
	enemies_alive = 0
	total_kills = 0
	total_damage_dealt = 0
	peak_enemies = 0
	events_triggered.clear()
	paused = false
	is_game_over = false
	is_victory = false
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
	veteran_relic_active = false
	dodge_chance = 0.0
	lifesteal = 0.0
	thorns_mult = 0.0
	luck_mult = 1.0
	extra_projectiles = 0
	summon_damage_mult = 1.0
	attack_size_mult = 1.0
	explosion_damage_mult = 1.0
	fire_ground_active = false
	weapon_level_bonus = 0
	accuracy_mult = 1.0
	low_hp_damage_bonus = 0.0
	player_hidden = false
	electric_damage_mult = 1.0
	crit_chance = 0.0
	crit_multiplier = 2.0
	manual_aim = false
	aim_direction = Vector3.ZERO
	revives_remaining = 0
	banishes = 0
	banished_options.clear()
	MAX_WEAPONS = 4
	_apply_permanent_upgrades()
	_apply_character_bonuses()
	_apply_relic()
	LogManager.info("Game", "Run reset: char=%s, stage=%s, relic=%s, mode=%s" % [
		selected_character, selected_stage, selected_relic, game_mode
	])

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

	var cd_lvl = SaveManager.get_upgrade_level("cooldown_reduction")
	cooldown_mult = maxf(0.3, cooldown_mult - cd_lvl * 0.03)

	var luck_lvl = SaveManager.get_upgrade_level("luck")
	luck_mult += luck_lvl * 0.10

	var revive_lvl = SaveManager.get_upgrade_level("revive")
	revives_remaining = revive_lvl

	var slots_lvl = SaveManager.get_upgrade_level("weapon_slots")
	MAX_WEAPONS = 4 + slots_lvl

	var reroll_lvl = SaveManager.get_upgrade_level("reroll_shop")
	rerolls += reroll_lvl

	var banish_lvl = SaveManager.get_upgrade_level("banish_shop")
	banishes = banish_lvl

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
	if "dodge_bonus" in char_data:
		dodge_chance += char_data["dodge_bonus"]
	if "low_hp_damage_bonus" in char_data:
		low_hp_damage_bonus = char_data["low_hp_damage_bonus"]
	# Ronin: 20% crit chance
	if selected_character == "ronin":
		crit_chance = 0.20
	# Pirata: +20% crystal drop
	if selected_character == "pirata":
		luck_mult += 0.20  # Affects crystal drop rates
	# Necro: +1 summon (applied via extra_projectiles which summon weapons use)
	if selected_character == "necro":
		extra_projectiles += 1
	# Vampiro: lifesteal natural
	if selected_character == "vampiro":
		lifesteal += 0.03
	# Chef: cura 2x (tracked in heal function)
	# Engenheiro: cooldown reduction
	if selected_character == "engenheiro":
		cooldown_mult = maxf(0.3, cooldown_mult - 0.15)
	# Gladiador: armor
	if selected_character == "gladiador":
		perm_armor += 5
	# Mystery: all weapons at level 1 (added by stage script after reset)
	if selected_character == "mystery":
		MAX_WEAPONS = 23  # Allow all weapons

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
		"extra_weapon":
			# Pick a random weapon that isn't the starting weapon
			var all_ids = WeaponDB.get_all_weapon_ids()
			var starting_weapon = ""
			if not player_weapons.is_empty():
				starting_weapon = player_weapons[0]["id"]
			var candidates: Array = []
			for wid in all_ids:
				if wid != starting_weapon:
					candidates.append(wid)
			if not candidates.is_empty():
				var pick = candidates[randi() % candidates.size()]
				add_weapon(pick)
		"veteran":
			xp_mult += 0.20
			veteran_relic_active = true
		"extend_time":
			run_time_limit += 600.0  # +10 minutos
		"show_event_direction":
			pass  # Compass visual handled by HUD
		"double_chest":
			xp_mult += 1.0  # 2x XP from all sources

func get_effective_damage_mult() -> float:
	var mult = perm_damage_mult
	if low_hp_damage_bonus > 0.0 and player_hp < int(get_effective_max_hp() * 0.3):
		mult *= (1.0 + low_hp_damage_bonus)
	return mult

func get_electric_damage_mult() -> float:
	return electric_damage_mult

func get_accuracy_spread() -> float:
	# accuracy_mult reduces spread. 1.0 = normal, 2.0 = half spread
	return 1.0 / maxf(0.1, accuracy_mult)

func end_run() -> void:
	# Cristais = kills / 5 (minimo)
	crystals_this_run = maxi(total_kills / 5, 10)
	LogManager.info("Game", "Run ended: %s on %s, time: %.1fs, kills: %d, crystals: %d, victory: %s" % [
		selected_character, selected_stage, game_time, total_kills, crystals_this_run, str(is_victory)
	])
	SaveManager.end_run(crystals_this_run, game_time, total_kills)
