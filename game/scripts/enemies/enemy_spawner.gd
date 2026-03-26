extends Node3D

## Spawna inimigos fora da area visivel, com dificuldade crescente.
## Segue tabela de spawn por minuto da spec.

@export var spawn_distance: float = 25.0
@export var base_spawn_interval: float = 1.2
@export var base_enemies_per_spawn: int = 2

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

# Boss
var boss_spawned: bool = false
var miniboss_spawned: bool = false

func _ready() -> void:
	rng.randomize()

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var mult = GameManager.get_difficulty_multiplier()
	var interval = maxf(0.15, base_spawn_interval / mult)

	spawn_timer += delta
	if spawn_timer >= interval:
		spawn_timer = 0.0
		_spawn_wave(mult)

	# Mini-boss no minuto 12
	if not miniboss_spawned and GameManager.game_time >= 720.0:
		miniboss_spawned = true
		_spawn_miniboss()

	# Boss no minuto 25
	if not boss_spawned and GameManager.game_time >= 1500.0:
		boss_spawned = true
		_spawn_boss()

func _spawn_wave(mult: float) -> void:
	if GameManager.enemies_alive >= GameManager.max_enemies:
		return

	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
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

		var angle = rng.randf() * TAU
		var spawn_pos = target_pos + Vector3(cos(angle), 0, sin(angle)) * spawn_distance

		# Elite enemies after minute 15
		if minute >= 15.0 and rng.randf() < 0.1:
			_make_elite(enemy)

		add_child(enemy)
		enemy.global_position = spawn_pos
		GameManager.enemies_alive += 1

func _pick_enemy(minute: float) -> Node3D:
	var roll = rng.randf()

	if minute < 2.0:
		# So slimes
		return slime_scene.instantiate()
	elif minute < 5.0:
		# Slimes + Bats
		if roll < 0.7:
			return slime_scene.instantiate()
		else:
			return bat_scene.instantiate()
	elif minute < 8.0:
		# Skeletons + Bats + Slimes Grandes
		if roll < 0.3:
			return slime_scene.instantiate()
		elif roll < 0.5:
			return bat_scene.instantiate()
		elif roll < 0.75:
			return skeleton_scene.instantiate()
		else:
			return slime_big_scene.instantiate()
	elif minute < 12.0:
		# Archers + Zombies + Ghosts + Bombers
		if roll < 0.2:
			return archer_scene.instantiate()
		elif roll < 0.4:
			return zombie_scene.instantiate()
		elif roll < 0.6:
			return ghost_scene.instantiate()
		elif roll < 0.8:
			return bomber_scene.instantiate()
		else:
			return skeleton_scene.instantiate()
	elif minute < 20.0:
		# Mix de tudo + Tanks + Swarms
		if roll < 0.06:
			return tank_scene.instantiate()
		elif roll < 0.10:
			return swarm_scene.instantiate()
		elif roll < 0.13:
			return mimic_scene.instantiate()
		var scenes = [slime_scene, bat_scene, skeleton_scene, zombie_scene, ghost_scene,
			slime_big_scene, archer_scene, bomber_scene]
		return scenes[rng.randi() % scenes.size()].instantiate()
	else:
		# Endgame: tudo, mais tanks, bombers, swarms
		var scenes = [skeleton_scene, zombie_scene, ghost_scene, bomber_scene,
			slime_big_scene, archer_scene, tank_scene, swarm_scene, mimic_scene]
		return scenes[rng.randi() % scenes.size()].instantiate()

func _make_elite(enemy: Node3D) -> void:
	if enemy is EnemyBase3D:
		enemy.max_hp = int(enemy.max_hp * 3.0)
		enemy.hp = enemy.max_hp
		enemy.damage = int(enemy.damage * 1.5)
		enemy.xp_drop = enemy.xp_drop * 5
		enemy.speed *= 1.2
		enemy.enemy_color = Color(1.0, 0.85, 0.2)  # Dourado
		enemy.scale = Vector3(1.3, 1.3, 1.3)

func _spawn_miniboss() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var pos = players[0].global_position
	var angle = rng.randf() * TAU
	var spawn_pos = pos + Vector3(cos(angle), 0, sin(angle)) * 15.0

	var stage = GameManager.selected_stage
	var boss: Node3D
	# Mini-boss config por stage: {hp, dmg, spd, xp, color, scale}
	var mb_config: Dictionary
	match stage:
		"forest":
			mb_config = {"hp": 600, "dmg": 30, "spd": 6.0, "color": Color(0.1, 0.0, 0.2)}
		"farm":
			mb_config = {"hp": 800, "dmg": 35, "spd": 8.0, "color": Color(0.5, 0.5, 0.5)}
		"tokyo":
			# Mecha Ninja: rapido com dash
			mb_config = {"hp": 700, "dmg": 30, "spd": 7.0, "color": Color(0.2, 0.2, 0.3)}
		"volcano":
			# Cerberus: 3 cabecas (representado como tanque triplo)
			mb_config = {"hp": 1000, "dmg": 40, "spd": 3.0, "color": Color(0.6, 0.1, 0.0)}
		"ocean":
			# Kraken Bebe: tentaculos
			mb_config = {"hp": 800, "dmg": 35, "spd": 4.0, "color": Color(0.1, 0.3, 0.5)}
		"arena":
			# Gladiador Campeao: parry
			mb_config = {"hp": 900, "dmg": 45, "spd": 5.0, "color": Color(0.7, 0.5, 0.1)}
		"space":
			# Alien Queen: spawna ovos
			mb_config = {"hp": 850, "dmg": 30, "spd": 3.5, "color": Color(0.3, 0.6, 0.2)}
		"castle":
			# Vampiresa: charm
			mb_config = {"hp": 700, "dmg": 35, "spd": 6.0, "color": Color(0.5, 0.0, 0.2)}
		"candy":
			# Bolo de 3 Andares
			mb_config = {"hp": 1200, "dmg": 25, "spd": 2.0, "color": Color(0.9, 0.6, 0.7)}
		_:
			# Zombie Gigante (default/cemetery)
			mb_config = {"hp": 500, "dmg": 25, "spd": 2.5, "color": Color(0.4, 0.15, 0.15)}

	boss = zombie_scene.instantiate()
	if boss is EnemyBase3D:
		boss.max_hp = mb_config["hp"]
		boss.hp = mb_config["hp"]
		boss.damage = mb_config["dmg"]
		boss.speed = mb_config["spd"]
		boss.xp_drop = 50
		boss.enemy_color = mb_config["color"]
		boss.scale = Vector3(2.5, 2.5, 2.5)
	add_child(boss)
	boss.global_position = spawn_pos
	GameManager.enemies_alive += 1

func _spawn_boss() -> void:
	# No endless mode, no boss
	if GameManager.game_mode == "endless":
		return

	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var pos = players[0].global_position
	var spawn_pos = pos + Vector3(0, 0, -15)

	AudioManager.play_sfx("boss_appear")
	AudioManager.play_music("boss")

	# Boss por stage
	var boss_paths = {
		"cemetery": "res://scenes/enemies/boss_necromancer.tscn",
		"forest": "res://scenes/enemies/boss_fairy_queen.tscn",
		"farm": "res://scenes/enemies/boss_alien_cow.tscn",
		"tokyo": "res://scenes/enemies/boss_ai_overlord.tscn",
		"volcano": "res://scenes/enemies/boss_demon_lord.tscn",
		"ocean": "res://scenes/enemies/boss_leviathan.tscn",
		"arena": "res://scenes/enemies/boss_emperor.tscn",
		"space": "res://scenes/enemies/boss_singularity.tscn",
		"castle": "res://scenes/enemies/boss_dracula.tscn",
		"candy": "res://scenes/enemies/boss_sugar_king.tscn",
	}
	var boss_scene_path: String = boss_paths.get(GameManager.selected_stage, "res://scenes/enemies/boss_necromancer.tscn")
	var boss_scene_res = load(boss_scene_path)
	var boss = boss_scene_res.instantiate()
	add_child(boss)
	boss.global_position = spawn_pos
	GameManager.enemies_alive += 1
