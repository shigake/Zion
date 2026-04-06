extends Node3D

## Spawna inimigos fora da area visivel, com dificuldade crescente.
## Segue tabela de spawn por minuto da spec.

@export var base_spawn_interval: float = 1.0  # Era 1.2 — spawns mais rapidos
@export var base_enemies_per_spawn: int = 3   # Era 2 — mais inimigos por onda

var spawn_timer: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Enemy scenes
var slime_scene: PackedScene = preload("res://scenes/enemies/slime.tscn")
var bat_scene: PackedScene = preload("res://scenes/enemies/bat.tscn")
var skeleton_scene: PackedScene = preload("res://scenes/enemies/skeleton.tscn")
var zombie_scene: PackedScene = preload("res://scenes/enemies/zombie_runner.tscn")
var ghost_scene: PackedScene = preload("res://scenes/enemies/ghost.tscn")
var slime_big_scene: PackedScene = preload("res://scenes/enemies/slime_big.tscn")
var archer_scene: PackedScene = preload("res://scenes/enemies/skeleton_archer.tscn")
var bomber_scene: PackedScene = preload("res://scenes/enemies/bomber.tscn")
var tank_scene: PackedScene = preload("res://scenes/enemies/tank.tscn")
var swarm_scene: PackedScene = preload("res://scenes/enemies/swarm.tscn")
var mimic_scene: PackedScene = preload("res://scenes/enemies/mimic.tscn")
var tooth_fairy_scene: PackedScene = preload("res://scenes/enemies/tooth_fairy.tscn")

# Ghost variants (cemetery-specific)
var ghost_white_scene: PackedScene = preload("res://scenes/enemies/ghost_white.tscn")
var ghost_green_scene: PackedScene = preload("res://scenes/enemies/ghost_green.tscn")
var ghost_blue_scene: PackedScene = preload("res://scenes/enemies/ghost_blue.tscn")
var ghost_red_scene: PackedScene = preload("res://scenes/enemies/ghost_red.tscn")

# Boss (suporta multiplos bosses por partida)
var _bosses_spawned: int = 0
var _next_boss_time: float = GameConstants.BOSS_SPAWN_TIME
var miniboss_spawned: bool = false

# Boss Rush mode
var _boss_rush_stages: Array = GameConstants.ALL_STAGES.duplicate()
var _boss_rush_index: int = 0
var _boss_rush_cooldown: float = 0.0
var _boss_rush_active_boss: bool = false

# Cached FPS value — updated once per _process to avoid redundant Engine calls
var _cached_fps: float = 60.0

# Cached stage skin data (resolved once at start instead of per-spawn)
var _cached_skin_colors: Array = []
var _cached_skin_names: Dictionary = {}
var _cached_skin_stage: String = ""

# Boss scene cache — preload to avoid load() during gameplay
var _boss_scene_cache: Dictionary = {}  # path -> PackedScene

func _ready() -> void:
	rng.randomize()
	_cache_stage_skin()
	# Pre-warm ObjectPool with ALL enemy types to avoid first-spawn stutters.
	# Loading screen already prewarms, but spawner adds extras for in-game pool.
	ObjectPool.prewarm(slime_scene, 15)
	ObjectPool.prewarm(bat_scene, 10)
	ObjectPool.prewarm(skeleton_scene, 8)
	ObjectPool.prewarm(ghost_scene, 5)
	ObjectPool.prewarm(zombie_scene, 5)
	ObjectPool.prewarm(slime_big_scene, 5)
	ObjectPool.prewarm(skeleton_scene, 5)
	ObjectPool.prewarm(bomber_scene, 3)
	ObjectPool.prewarm(tank_scene, 3)
	ObjectPool.prewarm(swarm_scene, 3)
	# Cemetery ghost variants
	if GameManager.selected_stage == "cemetery" or GameManager.selected_stage == "":
		ObjectPool.prewarm(ghost_white_scene, 5)
		ObjectPool.prewarm(ghost_green_scene, 5)
		ObjectPool.prewarm(ghost_blue_scene, 5)
		ObjectPool.prewarm(ghost_red_scene, 5)

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	_cached_fps = Engine.get_frames_per_second()

	var mult = GameManager.get_difficulty_multiplier()
	# Hyper mode: 2x spawn rate
	if GameManager.game_mode == "hyper":
		mult *= 2.0
	# Mutation: endless horde
	mult *= MutationManager.get_spawn_modifier()
	var interval = maxf(GameConstants.SPAWN_MIN_INTERVAL, base_spawn_interval / mult)

	# Boss Rush: spawn bosses sequentially instead of normal enemies
	if GameManager.game_mode == "boss_rush":
		_process_boss_rush(delta)
		return

	spawn_timer += delta
	if spawn_timer >= interval:
		spawn_timer = 0.0
		_spawn_wave(mult)

	# Boss a cada BOSS_SPAWN_INTERVAL (5 min)
	if GameManager.game_time >= _next_boss_time:
		_next_boss_time += GameConstants.BOSS_SPAWN_INTERVAL
		_bosses_spawned += 1
		_spawn_boss()

func _spawn_wave(mult: float) -> void:
	if GameManager.enemies_alive >= GameManager.max_enemies:
		return
	# Dynamic FPS-based hard cap on enemies (uses cached value from _process)
	var fps = _cached_fps
	var dynamic_cap = 150
	if fps < 45: dynamic_cap = 100
	if fps < 35: dynamic_cap = 70
	if fps < 25: dynamic_cap = 40
	if GameManager.enemies_alive >= dynamic_cap:
		return
	# Dynamic cap: reduce spawns when FPS is low — aggressive throttling
	if fps < GameConstants.FPS_CRITICAL and GameManager.enemies_alive > GameConstants.ENEMIES_CAP_CRITICAL:
		return  # Critical: hard stop spawning
	if fps < GameConstants.FPS_LOW and GameManager.enemies_alive > GameConstants.ENEMIES_CAP_LOW:
		return  # Low FPS: stop spawning early
	if fps < GameConstants.FPS_MEDIUM and GameManager.enemies_alive > GameConstants.ENEMIES_CAP_MEDIUM:
		return  # Medium FPS: soft cap
	# At low FPS, reduce wave size
	if fps < 35.0:
		mult *= GameConstants.FPS_LOW_SPAWN_MULT

	var players = GameManager.get_players()
	if players.is_empty():
		return
	if not is_instance_valid(players[0]) or not players[0].is_inside_tree():
		return

	var target_pos = players[0].global_position
	var count = int(base_enemies_per_spawn * mult * GameManager.get_mp_spawn_mult())
	count = mini(count, GameManager.max_enemies - GameManager.enemies_alive)

	var minute = GameManager.game_time / 60.0

	for i in range(count):
		if GameManager.enemies_alive >= GameManager.max_enemies:
			break
		var enemy = _pick_enemy(minute)
		if enemy == null:
			continue

		var spawn_pos = GameManager.get_annulus_position(target_pos)

		# Apply stage-specific skin (color + name)
		_apply_stage_skin(enemy)

		# Elite enemies after minute 15
		if minute >= GameConstants.ELITE_MIN_MINUTE and rng.randf() < GameConstants.ELITE_SPAWN_CHANCE:
			_make_elite(enemy)

		add_child(enemy)
		enemy.global_position = spawn_pos
		GameManager.enemies_alive += 1

func _pick_ghost_variant() -> Node3D:
	## No cemiterio, retorna um dos 4 fantasminhas coloridos. Fora do cemiterio, ghost normal.
	if GameManager.selected_stage == "cemetery" or GameManager.selected_stage == "":
		var ghost_scenes = [ghost_white_scene, ghost_green_scene, ghost_blue_scene, ghost_red_scene]
		return ObjectPool.get_instance(ghost_scenes[rng.randi() % ghost_scenes.size()])
	return ObjectPool.get_instance(ghost_scene)

func _pick_enemy(minute: float) -> Node3D:
	var roll = rng.randf()
	var is_cemetery = GameManager.selected_stage == "cemetery" or GameManager.selected_stage == ""

	if minute < GameConstants.SPAWN_PHASE_1_END:
		# So slimes (+ fantasminhas brancos no cemiterio)
		if is_cemetery and roll > GameConstants.SPAWN_GHOST_CEMETERY_CHANCE:
			return ObjectPool.get_instance(ghost_white_scene)
		return ObjectPool.get_instance(slime_scene)
	elif minute < GameConstants.SPAWN_PHASE_2_END:
		# Slimes + Bats (+ fantasminhas no cemiterio)
		if is_cemetery and roll < 0.25:
			return _pick_ghost_variant()
		elif roll < 0.7:
			return ObjectPool.get_instance(slime_scene)
		else:
			return ObjectPool.get_instance(bat_scene)
	elif minute < GameConstants.SPAWN_PHASE_3_END:
		# Skeletons + Bats + Slimes Grandes (+ fantasminhas)
		# Fada dos Dentes: 3% de chance a partir do minuto 5
		if roll < GameConstants.SPAWN_TOOTH_FAIRY_CHANCE:
			return ObjectPool.get_instance(tooth_fairy_scene)
		if is_cemetery and roll < 0.2:
			return _pick_ghost_variant()
		elif roll < 0.3:
			return ObjectPool.get_instance(slime_scene)
		elif roll < 0.5:
			return ObjectPool.get_instance(bat_scene)
		elif roll < 0.75:
			return ObjectPool.get_instance(skeleton_scene)
		else:
			return ObjectPool.get_instance(slime_big_scene)
	elif minute < GameConstants.SPAWN_PHASE_4_END:
		# Archers + Zombies + Ghosts + Bombers
		# Fada dos Dentes: 3% de chance
		if roll < GameConstants.SPAWN_TOOTH_FAIRY_CHANCE:
			return ObjectPool.get_instance(tooth_fairy_scene)
		if roll < 0.2:
			return ObjectPool.get_instance(archer_scene)
		elif roll < 0.4:
			return ObjectPool.get_instance(zombie_scene)
		elif roll < 0.6:
			return _pick_ghost_variant()
		elif roll < 0.8:
			return ObjectPool.get_instance(bomber_scene)
		else:
			return ObjectPool.get_instance(skeleton_scene)
	elif minute < GameConstants.SPAWN_PHASE_5_END:
		# Mix de tudo + Tanks + Swarms
		# Fada dos Dentes: 3% de chance
		if roll < GameConstants.SPAWN_TOOTH_FAIRY_CHANCE:
			return ObjectPool.get_instance(tooth_fairy_scene)
		if roll < 0.06:
			return ObjectPool.get_instance(tank_scene)
		elif roll < 0.10:
			return ObjectPool.get_instance(swarm_scene)
		elif roll < 0.13:
			return ObjectPool.get_instance(mimic_scene)
		if is_cemetery:
			var scenes = [slime_scene, bat_scene, skeleton_scene, zombie_scene,
				ghost_white_scene, ghost_green_scene, ghost_blue_scene, ghost_red_scene,
				slime_big_scene, archer_scene, bomber_scene]
			return ObjectPool.get_instance(scenes[rng.randi() % scenes.size()])
		var scenes = [slime_scene, bat_scene, skeleton_scene, zombie_scene, ghost_scene,
			slime_big_scene, archer_scene, bomber_scene]
		return ObjectPool.get_instance(scenes[rng.randi() % scenes.size()])
	else:
		# Endgame: tudo, mais tanks, bombers, swarms
		# Fada dos Dentes: 3% de chance
		if roll < GameConstants.SPAWN_TOOTH_FAIRY_CHANCE:
			return ObjectPool.get_instance(tooth_fairy_scene)
		if is_cemetery:
			var scenes = [skeleton_scene, zombie_scene, ghost_white_scene, ghost_green_scene,
				ghost_blue_scene, ghost_red_scene, bomber_scene, slime_big_scene,
				archer_scene, tank_scene, swarm_scene, mimic_scene]
			return ObjectPool.get_instance(scenes[rng.randi() % scenes.size()])
		var scenes = [skeleton_scene, zombie_scene, ghost_scene, bomber_scene,
			slime_big_scene, archer_scene, tank_scene, swarm_scene, mimic_scene]
		return ObjectPool.get_instance(scenes[rng.randi() % scenes.size()])

## Stage skin data: { stage_name: { "colors": [Color, ...], "names": { NodeName: ThemedName } } }
var _stage_skins: Dictionary = {
	"forest": {
		"colors": [Color(0.2, 0.6, 0.2), Color(0.3, 0.7, 0.3), Color(0.4, 0.2, 0.5), Color(0.15, 0.5, 0.15), Color(0.5, 0.3, 0.6)],
		"names": {
			"Slime": "Mushroom Slime", "Bat": "Evil Pixie", "Skeleton": "Treant",
			"ZombieRunner": "Corrupted Unicorn", "Ghost": "Will-o-Wisp", "SlimeBig": "Giant Mushroom",
			"SkeletonArcher": "Elf Archer", "Bomber": "Spore Bomber", "Tank": "Ancient Treant",
			"Swarm": "Fairy Swarm", "Mimic": "Treasure Mushroom", "ToothFairy": "Forest Sprite",
		},
	},
	"farm": {
		"colors": [Color(0.6, 0.4, 0.2), Color(0.7, 0.6, 0.2), Color(0.5, 0.35, 0.15), Color(0.8, 0.7, 0.3), Color(0.55, 0.45, 0.2)],
		"names": {
			"Slime": "Cow Slime", "Bat": "Killer Chicken", "Skeleton": "Scarecrow",
			"ZombieRunner": "Zombie Cow", "Ghost": "Phantom Crow", "SlimeBig": "Mud Blob",
			"SkeletonArcher": "Pitchfork Thrower", "Bomber": "Exploding Pumpkin", "Tank": "Bull",
			"Swarm": "Locust Swarm", "Mimic": "Hay Bale Mimic", "ToothFairy": "Harvest Pixie",
		},
	},
	"tokyo": {
		"colors": [Color(0.0, 0.9, 0.9), Color(0.9, 0.2, 0.9), Color(0.2, 0.8, 1.0), Color(0.0, 1.0, 0.5), Color(0.8, 0.0, 1.0)],
		"names": {
			"Slime": "Nano Slime", "Bat": "Drone", "Skeleton": "Robot Samurai",
			"ZombieRunner": "Android", "Ghost": "Hologram", "SlimeBig": "Mecha Slime",
			"SkeletonArcher": "Sniper Bot", "Bomber": "Grenade Drone", "Tank": "Mech Walker",
			"Swarm": "Nano Swarm", "Mimic": "Vending Machine", "ToothFairy": "Neon Fairy",
		},
	},
	"volcano": {
		"colors": [Color(0.9, 0.2, 0.0), Color(1.0, 0.5, 0.0), Color(0.8, 0.1, 0.1), Color(1.0, 0.3, 0.1), Color(0.7, 0.15, 0.0)],
		"names": {
			"Slime": "Magma Slime", "Bat": "Fire Imp", "Skeleton": "Lava Golem",
			"ZombieRunner": "Demon", "Ghost": "Ash Wraith", "SlimeBig": "Magma Blob",
			"SkeletonArcher": "Flame Archer", "Bomber": "Lava Bomber", "Tank": "Obsidian Giant",
			"Swarm": "Ember Swarm", "Mimic": "Volcanic Rock Mimic", "ToothFairy": "Flame Wisp",
		},
	},
	"ocean": {
		"colors": [Color(0.1, 0.4, 0.8), Color(0.0, 0.7, 0.7), Color(0.2, 0.5, 0.9), Color(0.0, 0.6, 0.5), Color(0.15, 0.3, 0.7)],
		"names": {
			"Slime": "Jellyfish", "Bat": "Flying Fish", "Skeleton": "Crab",
			"ZombieRunner": "Zombie Shark", "Ghost": "Ghost Ship", "SlimeBig": "Giant Jellyfish",
			"SkeletonArcher": "Harpoon Fisher", "Bomber": "Pufferfish", "Tank": "Hermit Crab",
			"Swarm": "Piranha School", "Mimic": "Treasure Chest", "ToothFairy": "Sea Sprite",
		},
	},
	"arena": {
		"colors": [Color(0.8, 0.65, 0.2), Color(0.7, 0.5, 0.15), Color(0.9, 0.75, 0.3), Color(0.6, 0.4, 0.1), Color(0.85, 0.6, 0.25)],
		"names": {
			"Slime": "Slime Gladiator", "Bat": "Eagle", "Skeleton": "Centurion",
			"ZombieRunner": "Lion", "Ghost": "Arena Spirit", "SlimeBig": "War Elephant",
			"SkeletonArcher": "Bowman", "Bomber": "Fire Juggler", "Tank": "Champion",
			"Swarm": "Chariot Charge", "Mimic": "Trophy Mimic", "ToothFairy": "Golden Cherub",
		},
	},
	"space": {
		"colors": [Color(0.5, 0.2, 0.8), Color(0.2, 0.8, 0.3), Color(0.6, 0.1, 0.9), Color(0.3, 0.9, 0.4), Color(0.4, 0.3, 0.7)],
		"names": {
			"Slime": "Alien Parasite", "Bat": "Space Drone", "Skeleton": "Xenomorph",
			"ZombieRunner": "Mutant", "Ghost": "Void Phantom", "SlimeBig": "Cosmic Blob",
			"SkeletonArcher": "Laser Turret", "Bomber": "Plasma Mine", "Tank": "Mech Titan",
			"Swarm": "Zerg Swarm", "Mimic": "Pod Mimic", "ToothFairy": "Stardust Fairy",
		},
	},
	"castle": {
		"colors": [Color(0.5, 0.05, 0.1), Color(0.15, 0.05, 0.1), Color(0.6, 0.0, 0.15), Color(0.1, 0.1, 0.1), Color(0.4, 0.0, 0.2)],
		"names": {
			"Slime": "Blood Slime", "Bat": "Vampire Bat", "Skeleton": "Armor",
			"ZombieRunner": "Gargoyle", "Ghost": "Banshee", "SlimeBig": "Dark Ooze",
			"SkeletonArcher": "Crossbow Knight", "Bomber": "Alchemist", "Tank": "Iron Golem",
			"Swarm": "Rat Swarm", "Mimic": "Cursed Chest", "ToothFairy": "Blood Pixie",
		},
	},
	"candy": {
		"colors": [Color(1.0, 0.5, 0.7), Color(0.7, 0.9, 1.0), Color(0.9, 0.7, 1.0), Color(1.0, 0.8, 0.4), Color(0.6, 1.0, 0.7)],
		"names": {
			"Slime": "Gummy Bear", "Bat": "Candy Bat", "Skeleton": "Cookie Ninja",
			"ZombieRunner": "Cupcake", "Ghost": "Cotton Candy Ghost", "SlimeBig": "Jawbreaker",
			"SkeletonArcher": "Candy Cane Archer", "Bomber": "Popcorn Bomber", "Tank": "Chocolate Golem",
			"Swarm": "Sprinkle Swarm", "Mimic": "Candy Box Mimic", "ToothFairy": "Sugar Fairy",
		},
	},
}

func _cache_stage_skin() -> void:
	var stage: String = GameManager.selected_stage
	_cached_skin_stage = stage
	if stage == "cemetery" or stage == "" or not _stage_skins.has(stage):
		_cached_skin_colors = []
		_cached_skin_names = {}
		return
	var skin_data: Dictionary = _stage_skins[stage]
	_cached_skin_colors = skin_data["colors"]
	_cached_skin_names = skin_data["names"]

func _apply_stage_skin(enemy: Node3D) -> void:
	if _cached_skin_colors.is_empty():
		return
	# Apply themed color (uses cached array)
	if enemy is EnemyBase3D:
		enemy.enemy_color = _cached_skin_colors[rng.randi() % _cached_skin_colors.size()]
	# Apply themed name (display only; model lookup uses scene_file_path)
	var base_name: String = enemy.name
	if _cached_skin_names.has(base_name):
		enemy.name = _cached_skin_names[base_name]

func _process_boss_rush(delta: float) -> void:
	if _boss_rush_index >= _boss_rush_stages.size():
		# All 10 bosses defeated!
		GameManager.is_victory = true
		GameManager.is_game_over = true
		GameManager.game_over.emit()
		return

	# Cooldown between bosses
	if _boss_rush_cooldown > 0:
		_boss_rush_cooldown -= delta
		return

	# Spawn some filler enemies to keep it interesting
	spawn_timer += delta
	if spawn_timer >= GameConstants.BOSS_RUSH_FILLER_INTERVAL:
		spawn_timer = 0.0
		var mult = 1.0 + _boss_rush_index * GameConstants.BOSS_RUSH_MULT_PER_BOSS
		_spawn_wave(mult)

	# Check if current boss is dead
	if _boss_rush_active_boss:
		var bosses = get_tree().get_nodes_in_group("boss")
		if bosses.is_empty():
			_boss_rush_active_boss = false
			_boss_rush_index += 1
			_boss_rush_cooldown = GameConstants.BOSS_RUSH_COOLDOWN  # Break between bosses
			# Heal player between bosses
			GameManager.heal(GameManager.get_effective_max_hp() / 2)
			GameManager.add_xp(GameConstants.BOSS_RUSH_XP_REWARD)
		return

	# Spawn next boss
	var players = GameManager.get_players()
	if players.is_empty():
		return
	if not is_instance_valid(players[0]) or not players[0].is_inside_tree():
		return
	var pos = players[0].global_position
	var spawn_pos = GameManager.get_annulus_position(pos, GameConstants.BOSS_ANNULUS_MIN_RADIUS, GameConstants.BOSS_ANNULUS_MAX_RADIUS)

	# Temporarily set selected_stage to get the right boss
	var original_stage = GameManager.selected_stage
	GameManager.selected_stage = _boss_rush_stages[_boss_rush_index]

	AudioManager.play_music("boss")

	var path = _get_random_boss_path(_boss_rush_stages[_boss_rush_index])
	var boss = _get_cached_boss_scene(path).instantiate()
	add_child(boss)
	boss.global_position = spawn_pos
	GameManager.enemies_alive += 1
	GameManager.boss_spawned.emit(boss.name)
	_boss_rush_active_boss = true

	# Dramatic boss entrance effects (includes SFX: boss_roar + boss_appear)
	ScreenEffects.boss_entrance_effect()
	ScreenEffects.boss_title_card(boss.name)
	# Boss scale-up entrance animation with invincibility
	if boss.has_method("play_boss_entrance"):
		boss.play_boss_entrance()

	# Restore original stage
	GameManager.selected_stage = original_stage

func _make_elite(enemy: Node3D) -> void:
	if enemy is EnemyBase3D:
		enemy.max_hp = int(enemy.max_hp * GameConstants.ELITE_HP_MULT)
		enemy.hp = enemy.max_hp
		enemy.damage = int(enemy.damage * GameConstants.ELITE_DAMAGE_MULT)
		enemy.xp_drop = enemy.xp_drop * GameConstants.ELITE_XP_MULT
		enemy.speed *= GameConstants.ELITE_SPEED_MULT
		enemy.enemy_color = GameConstants.ELITE_COLOR
		enemy.scale = GameConstants.ELITE_SCALE
		AudioManager.play_sfx("enemy_growl")
		# Elite golden tint (no light for performance)
		var sprite = enemy.get_node_or_null("EnemySprite")
		if sprite:
			sprite.modulate = Color(1.0, 0.85, 0.2)

func _spawn_miniboss() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	if not is_instance_valid(players[0]) or not players[0].is_inside_tree():
		return
	var pos = players[0].global_position
	var spawn_pos = GameManager.get_annulus_position(pos)

	var stage = GameManager.selected_stage
	var boss: Node3D
	# Mini-boss config por stage: {hp, dmg, spd, xp, color, scale}
	var mb_config: Dictionary
	match stage:
		"forest":
			mb_config = {"hp": 600, "dmg": 25, "spd": 5.0, "color": Color(0.1, 0.0, 0.2), "name": "Shadow Treant"}
		"farm":
			mb_config = {"hp": 700, "dmg": 28, "spd": 5.5, "color": Color(0.5, 0.5, 0.5), "name": "Mad Bull"}
		"tokyo":
			mb_config = {"hp": 750, "dmg": 30, "spd": 5.0, "color": Color(0.2, 0.2, 0.3), "name": "Mecha Ninja"}
		"volcano":
			mb_config = {"hp": 850, "dmg": 32, "spd": 4.0, "color": Color(0.6, 0.1, 0.0), "name": "Cerberus"}
		"ocean":
			mb_config = {"hp": 800, "dmg": 30, "spd": 4.5, "color": Color(0.1, 0.3, 0.5), "name": "Baby Kraken"}
		"arena":
			mb_config = {"hp": 900, "dmg": 35, "spd": 4.5, "color": Color(0.7, 0.5, 0.1), "name": "Champion Gladiator"}
		"space":
			mb_config = {"hp": 950, "dmg": 32, "spd": 4.0, "color": Color(0.3, 0.6, 0.2), "name": "Alien Queen"}
		"castle":
			mb_config = {"hp": 1000, "dmg": 35, "spd": 5.0, "color": Color(0.5, 0.0, 0.2), "name": "Vampiress"}
		"candy":
			mb_config = {"hp": 1100, "dmg": 30, "spd": 3.5, "color": Color(0.9, 0.6, 0.7), "name": "Triple Layer Cake"}
		_:
			mb_config = {"hp": 500, "dmg": 25, "spd": 2.5, "color": Color(0.4, 0.15, 0.15), "name": "Giant Zombie"}

	boss = zombie_scene.instantiate()
	_apply_stage_skin(boss)
	if boss is EnemyBase3D:
		boss.max_hp = mb_config["hp"]
		boss.hp = mb_config["hp"]
		boss.damage = mb_config["dmg"]
		boss.speed = mb_config["spd"]
		boss.xp_drop = GameConstants.MINIBOSS_XP_DROP
		boss.enemy_color = mb_config["color"]
		boss.scale = GameConstants.MINIBOSS_SCALE
	add_child(boss)
	boss.global_position = spawn_pos
	GameManager.enemies_alive += 1
	GameManager.miniboss_spawned.emit(mb_config["name"])

func _get_cached_boss_scene(path: String) -> PackedScene:
	if path in _boss_scene_cache:
		return _boss_scene_cache[path]
	var scene = load(path)
	_boss_scene_cache[path] = scene
	return scene

func _get_random_boss_path(stage: String) -> String:
	var pool = GameConstants.BOSS_POOLS.get(stage, [])
	if pool.is_empty():
		return "res://scenes/enemies/boss_necromancer.tscn"
	var valid := []
	for path in pool:
		if ResourceLoader.exists(path):
			valid.append(path)
	if valid.is_empty():
		return pool[0]
	return valid[rng.randi() % valid.size()]

func _spawn_boss() -> void:
	# No endless mode, no boss
	if GameManager.game_mode == "endless":
		return

	var players = GameManager.get_players()
	if players.is_empty():
		return
	if not is_instance_valid(players[0]) or not players[0].is_inside_tree():
		return
	var pos = players[0].global_position
	var spawn_pos = GameManager.get_annulus_position(pos, GameConstants.BOSS_ANNULUS_MIN_RADIUS, GameConstants.BOSS_ANNULUS_MAX_RADIUS)

	AudioManager.play_music("boss")

	# Boss aleatorio do pool da fenda (cached para evitar stutter)
	var boss_scene_path: String = _get_random_boss_path(GameManager.selected_stage)
	var boss_scene_res = _get_cached_boss_scene(boss_scene_path)
	var boss = boss_scene_res.instantiate()
	add_child(boss)
	boss.global_position = spawn_pos
	GameManager.enemies_alive += 1
	GameManager.boss_spawned.emit(boss.name)

	# Dramatic boss entrance effects
	ScreenEffects.boss_entrance_effect()
	ScreenEffects.boss_title_card(boss.name)
	# Boss scale-up entrance animation with invincibility
	if boss.has_method("play_boss_entrance"):
		boss.play_boss_entrance()
