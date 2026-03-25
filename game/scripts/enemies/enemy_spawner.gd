extends Node3D

## Spawna inimigos fora da area visivel, com dificuldade crescente.

@export var spawn_distance: float = 25.0
@export var base_spawn_interval: float = 1.2
@export var base_enemies_per_spawn: int = 2

var spawn_timer: float = 0.0
var slime_scene: PackedScene = preload("res://scenes/enemies/slime.tscn")
var bat_scene: PackedScene = preload("res://scenes/enemies/bat.tscn")
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var mult = GameManager.get_difficulty_multiplier()
	var interval = maxf(0.2, base_spawn_interval / mult)

	spawn_timer += delta
	if spawn_timer >= interval:
		spawn_timer = 0.0
		_spawn_wave(mult)

func _spawn_wave(mult: float) -> void:
	if GameManager.enemies_alive >= GameManager.max_enemies:
		return

	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return

	var target_pos = players[0].global_position
	var count = int(base_enemies_per_spawn * mult)
	count = mini(count, GameManager.max_enemies - GameManager.enemies_alive)

	for i in range(count):
		var angle = rng.randf() * TAU
		var spawn_pos = target_pos + Vector3(cos(angle), 0, sin(angle)) * spawn_distance

		var enemy: Node3D
		# Bats aparecem depois de 1 minuto, chance aumenta com tempo
		if GameManager.game_time > 60.0 and rng.randf() < minf(0.5, GameManager.game_time / 300.0):
			enemy = bat_scene.instantiate()
		else:
			enemy = slime_scene.instantiate()

		enemy.global_position = spawn_pos
		add_child(enemy)
		GameManager.enemies_alive += 1
