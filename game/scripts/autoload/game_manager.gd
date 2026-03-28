extends Node

## Estado global do jogo: XP, level, dificuldade, pause, stats.

signal player_leveled_up(new_level: int)
signal enemy_killed(position: Vector3, xp_value: int)
signal player_died()
signal game_over()
signal weapon_added(weapon_id: String)
signal weapon_upgraded(weapon_id: String, new_level: int)
signal miniboss_spawned(boss_name: String)
signal boss_spawned(boss_name: String)
signal boss_died(boss_name: String)

# Tempo e dificuldade
var game_time: float = 0.0
var enemies_alive: int = 0
var max_enemies: int = 500
# Cached enemy list (updated once per frame to avoid 45+ get_nodes_in_group calls)
var _cached_enemies: Array = []
var _enemies_cache_frame: int = -1
var _cached_players: Array = []
var _players_cache_frame: int = -1

# Spatial grid for O(1) neighbor lookups (enemy separation, AoE targeting)
var _spatial_grid: Dictionary = {}  # Vector2i -> Array[Node3D]
var _spatial_grid_frame: int = -1
const SPATIAL_CELL_SIZE: float = 3.0  # Matches separation radius

# Cached nearest player per frame (avoid per-enemy iteration)
var _cached_nearest_player: Dictionary = {}  # enemy_instance_id -> Node3D
var _nearest_player_frame: int = -1
var total_kills: int = 0
var total_damage_dealt: int = 0
var peak_enemies: int = 0
var events_triggered: Array[String] = []

# Per-weapon damage tracking (weapon_id -> total damage dealt)
var weapon_damage_dealt: Dictionary = {}
# Context: set by weapon scripts before dealing damage so enemy_base can attribute it
var _last_attacking_weapon: String = ""

# Run timeline: key events during the run
var run_timeline: Array = []  # [{time: float, event: String}]
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
var game_mode: String = "normal"  # "normal", "endless", "boss_rush", "hyper", "daily", "new_game_plus"
var run_time_limit: float = 900.0  # 15 min default

# New Game+
var new_game_plus: bool = false
var ng_plus_weapons: Array[Dictionary] = []  # Weapons carried from previous victory run

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
var master_key_active: bool = false
var auto_play: bool = false  # Auto-pick random choices on level up
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
	# Connect signals for run timeline tracking
	player_leveled_up.connect(_on_timeline_level_up)
	weapon_added.connect(_on_timeline_weapon_added)
	weapon_upgraded.connect(_on_timeline_weapon_upgraded)
	boss_spawned.connect(_on_timeline_boss_spawned)
	miniboss_spawned.connect(_on_timeline_miniboss_spawned)
	boss_died.connect(_on_timeline_boss_died)
	LogManager.info("Game", "GameManager ready")

func _process(delta: float) -> void:
	if not paused and not is_game_over:
		game_time += delta
		if enemies_alive > peak_enemies:
			peak_enemies = enemies_alive

# ---------------------------------------------------------------------------
# Weapon damage tracking
# ---------------------------------------------------------------------------

## Record damage dealt by a specific weapon. Called from enemy_base.take_damage.
func record_weapon_damage(weapon_id: String, amount: int) -> void:
	if weapon_id.is_empty():
		return
	weapon_damage_dealt[weapon_id] = weapon_damage_dealt.get(weapon_id, 0) + amount

# ---------------------------------------------------------------------------
# Run timeline
# ---------------------------------------------------------------------------

## Add an event to the run timeline.
func add_timeline_event(event_text: String) -> void:
	run_timeline.append({"time": game_time, "event": event_text})

func _on_timeline_level_up(new_level: int) -> void:
	# Track milestone levels
	if new_level in [5, 10, 15, 20, 25, 30]:
		add_timeline_event("Level %d" % new_level)

func _on_timeline_weapon_added(weapon_id: String) -> void:
	var data = WeaponDB.weapons.get(weapon_id, {})
	var wname = data.get("name", weapon_id)
	if player_weapons.size() == 1:
		add_timeline_event("Primeira arma: %s" % wname)
	else:
		add_timeline_event("Nova arma: %s" % wname)

func _on_timeline_weapon_upgraded(weapon_id: String, new_level: int) -> void:
	if new_level == 8:
		var data = WeaponDB.weapons.get(weapon_id, {})
		var wname = data.get("name", weapon_id)
		add_timeline_event("Max level: %s" % wname)
	# Check if this triggered an evolution
	for evo_id in EvolutionDB.evolved_weapons:
		if evo_id == weapon_id:
			var evo = EvolutionDB.get_evolution(evo_id)
			var evo_name = evo.get("name", evo_id)
			add_timeline_event("Evolucao: %s" % evo_name)

func _on_timeline_boss_spawned(boss_name: String) -> void:
	add_timeline_event("Boss: %s" % boss_name)

func _on_timeline_miniboss_spawned(boss_name: String) -> void:
	add_timeline_event("Mini-boss: %s" % boss_name)

func _on_timeline_boss_died(boss_name: String) -> void:
	add_timeline_event("Boss derrotado: %s" % boss_name)

## Returns cached enemy list (refreshed once per frame). Use this instead of get_tree().get_nodes_in_group("enemies").
func get_enemies() -> Array:
	var frame = Engine.get_process_frames()
	if frame != _enemies_cache_frame:
		_enemies_cache_frame = frame
		_cached_enemies = get_tree().get_nodes_in_group("enemies")
	return _cached_enemies

## Returns cached player list (refreshed once per frame).
func get_players() -> Array:
	var frame = Engine.get_process_frames()
	if frame != _players_cache_frame:
		_players_cache_frame = frame
		_cached_players = get_tree().get_nodes_in_group("players")
	return _cached_players

## Spatial grid — rebuilt once per frame for O(1) neighbor queries.
func _rebuild_spatial_grid() -> void:
	var frame = Engine.get_process_frames()
	if frame == _spatial_grid_frame:
		return
	_spatial_grid_frame = frame
	_spatial_grid.clear()
	var enemies = get_enemies()
	for e in enemies:
		if not is_instance_valid(e) or e.is_dead:
			continue
		var cell = _pos_to_cell(e.global_position)
		if not _spatial_grid.has(cell):
			_spatial_grid[cell] = []
		_spatial_grid[cell].append(e)

func _pos_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / SPATIAL_CELL_SIZE)), int(floor(pos.z / SPATIAL_CELL_SIZE)))

## Get nearby enemies from spatial grid (O(1) instead of O(n)).
func get_nearby_enemies(pos: Vector3, radius: float) -> Array:
	_rebuild_spatial_grid()
	var cell = _pos_to_cell(pos)
	var cells_to_check = int(ceil(radius / SPATIAL_CELL_SIZE))
	var result: Array = []
	for dx in range(-cells_to_check, cells_to_check + 1):
		for dz in range(-cells_to_check, cells_to_check + 1):
			var check_cell = Vector2i(cell.x + dx, cell.y + dz)
			if _spatial_grid.has(check_cell):
				result.append_array(_spatial_grid[check_cell])
	return result

## Get enemies in radius with distance check (for AoE).
func get_enemies_in_radius(pos: Vector3, radius: float) -> Array:
	var candidates = get_nearby_enemies(pos, radius)
	var result: Array = []
	var radius_sq = radius * radius
	for e in candidates:
		if is_instance_valid(e) and not e.is_dead:
			var diff = pos - e.global_position
			diff.y = 0
			if diff.length_squared() <= radius_sq:
				result.append(e)
	return result

func _register_input_actions() -> void:
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("dash", KEY_SPACE)
	_add_key_action("interact", KEY_E)
	_add_key_action("inventory", KEY_TAB)
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
		var players = get_players()
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
	# Armor: percentage-based damage reduction (diminishing returns)
	# Formula: reduction = armor / (armor + 50), caps around ~60% at max armor
	var armor_reduction := perm_armor / float(perm_armor + 50)
	var reduced = maxi(1, int(amount * (1.0 - armor_reduction)))
	# Thorns: reflect damage to nearest enemy
	if thorns_mult > 0.0:
		var reflected = int(reduced * thorns_mult)
		if reflected > 0:
			var enemies = get_enemies()
			var players = get_players()
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
	# Sync HP com aliados no multiplayer
	MultiplayerManager.notify_damage(player_hp, get_effective_max_hp())
	# Lifesteal tracking (applied by weapons on hit, not here)
	if player_hp <= 0:
		# One-shot kill detection (possible balance issue or bug)
		if amount > get_effective_max_hp() / 2:
			LogManager.warn("Balance", "One-shot kill! Damage: %d, Max HP: %d" % [amount, get_effective_max_hp()])
		# Revive check
		if revives_remaining > 0:
			revives_remaining -= 1
			player_hp = get_effective_max_hp() / 2
			ScreenEffects.shake(0.3)
			return
		player_hp = 0
		# Multiplayer: spawn tombstone instead of game over
		if MultiplayerManager.is_online and MultiplayerManager.get_player_count() > 1:
			_spawn_tombstone()
			LogManager.info("Game", "Player died in MP at %.1fs, tombstone spawned" % game_time)
			player_died.emit()
			return
		is_game_over = true
		LogManager.info("Game", "Player died at %.1fs, kills: %d, level: %d" % [game_time, total_kills, player_level])
		player_died.emit()
		game_over.emit()

func _spawn_tombstone() -> void:
	var players = get_players()
	var death_pos = Vector3.ZERO
	if not players.is_empty():
		death_pos = players[0].global_position
	var tombstone_script = preload("res://scripts/player/tombstone.gd")
	var tombstone = Node3D.new()
	tombstone.set_script(tombstone_script)
	tombstone.name = "Tombstone_%d" % MultiplayerManager.local_player_id
	tombstone.dead_peer_id = MultiplayerManager.local_player_id
	tombstone.global_position = death_pos
	tombstone.player_revived.connect(_on_player_revived)
	get_tree().current_scene.call_deferred("add_child", tombstone)

func _on_player_revived(_peer_id: int) -> void:
	is_game_over = false
	LogManager.info("Game", "Player revived via tombstone")

func heal(amount: int) -> void:
	var heal_amount = amount
	if selected_character == "chef":
		heal_amount *= 2
	# Mutation: weakened healing
	heal_amount = int(heal_amount * MutationManager.get_heal_modifier())
	var effective_max = get_effective_max_hp()
	player_hp = mini(player_hp + heal_amount, effective_max)
	# Sync HP com aliados no multiplayer
	MultiplayerManager.notify_damage(player_hp, effective_max)

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
	# Track for codex
	SaveManager.track_codex(weapon_id)
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
	master_key_active = false
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
	weapon_damage_dealt.clear()
	_last_attacking_weapon = ""
	run_timeline.clear()
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
	master_key_active = false
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
	# Reset NG+ flag (preserved across reset only if mode is new_game_plus)
	if game_mode != "new_game_plus":
		new_game_plus = false
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
	# Vampiro: lifesteal natural + 10% attack speed
	if selected_character == "vampiro":
		lifesteal += 0.05
		attack_speed_mult += 0.10
	# Chef: cura 2x (tracked in heal function)
	# Engenheiro: cooldown reduction
	if selected_character == "engenheiro":
		cooldown_mult = maxf(0.3, cooldown_mult - 0.15)
	# Gladiador: armor + 15% max HP
	if selected_character == "gladiador":
		perm_armor += 8
		max_hp_mult += 0.15
	# Bruxa: +2 summons + 20% summon damage
	if selected_character == "bruxa":
		extra_projectiles += 2
		summon_damage_mult += 0.20
	# Mystery: starts with 3 random weapons (not all)
	if selected_character == "mystery":
		MAX_WEAPONS = 8  # Higher cap but not unlimited

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
			master_key_active = true  # Doubles XP gem and crystal drops from enemies

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
	# Cristais = kills / 5 (minimo), com multiplicador de mutacoes
	crystals_this_run = maxi(int(maxi(total_kills / 5, 10) * MutationManager.get_crystal_multiplier()), 10)
	LogManager.info("Game", "Run ended: %s on %s, time: %.1fs, kills: %d, crystals: %d, victory: %s" % [
		selected_character, selected_stage, game_time, total_kills, crystals_this_run, str(is_victory)
	])
	# Save weapons for New Game+ on victory
	if is_victory:
		ng_plus_weapons.clear()
		for w in player_weapons:
			ng_plus_weapons.append({"id": w["id"], "level": w["level"]})
	SaveManager.end_run(crystals_this_run, game_time, total_kills)
	# Save best run for comparison on game over screen
	var run_dps: float = 0.0
	if game_time > 0:
		run_dps = total_damage_dealt / game_time
	SaveManager.save_best_run({
		"time": game_time,
		"kills": total_kills,
		"dps": run_dps,
		"level": player_level,
		"crystals": crystals_this_run,
		"damage": total_damage_dealt,
	})
