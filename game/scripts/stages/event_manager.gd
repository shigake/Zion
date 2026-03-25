extends Node3D

## Gerencia eventos especiais durante a run.
## Eventos: Horda Dourada (min 5), Treasure Goblin (aleatorio), Merchant (aleatorio)

signal event_started(event_name: String)
signal event_ended(event_name: String)

var active_event: String = ""
var event_timer: float = 0.0
var next_random_event_time: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Eventos fixos por tempo
var timed_events: Dictionary = {
	300.0: "golden_horde",   # Min 5
	600.0: "roulette",        # Min 10
}
var triggered_timed: Array = []

func _ready() -> void:
	rng.randomize()
	next_random_event_time = rng.randf_range(180, 300)  # Primeiro evento aleatorio entre 3-5 min

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	# Evento ativo
	if active_event != "":
		event_timer -= delta
		if event_timer <= 0:
			_end_event()
		return

	# Check timed events
	for time in timed_events:
		if GameManager.game_time >= time and time not in triggered_timed:
			triggered_timed.append(time)
			_start_event(timed_events[time])
			return

	# Check random events
	if GameManager.game_time >= next_random_event_time:
		var random_events = ["treasure_goblin", "merchant"]
		var event = random_events[rng.randi() % random_events.size()]
		_start_event(event)
		next_random_event_time = GameManager.game_time + rng.randf_range(120, 240)

func _start_event(event_name: String) -> void:
	active_event = event_name
	event_started.emit(event_name)

	match event_name:
		"golden_horde":
			event_timer = 20.0
			_spawn_golden_horde()
		"treasure_goblin":
			event_timer = 30.0
			_spawn_treasure_goblin()
		"merchant":
			event_timer = 30.0
			_spawn_merchant()
		"roulette":
			event_timer = 5.0
			_do_roulette()

func _end_event() -> void:
	var ended = active_event
	active_event = ""
	event_ended.emit(ended)

func _spawn_golden_horde() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var center = players[0].global_position
	var slime_scene = preload("res://scenes/enemies/slime.tscn")

	for i in range(30):
		var angle = rng.randf() * TAU
		var pos = center + Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(15, 25)
		var enemy = slime_scene.instantiate()
		enemy.global_position = pos
		if enemy is EnemyBase3D:
			enemy.enemy_color = Color(1.0, 0.85, 0.2)
			enemy.xp_drop = 5
			enemy.max_hp = 5
			enemy.hp = 5
		get_parent().add_child(enemy)
		GameManager.enemies_alive += 1

func _spawn_treasure_goblin() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var center = players[0].global_position
	var bat_scene = preload("res://scenes/enemies/bat.tscn")

	var goblin = bat_scene.instantiate()
	goblin.global_position = center + Vector3(10, 0, 10)
	if goblin is EnemyBase3D:
		goblin.enemy_color = Color(0.2, 1.0, 0.3)
		goblin.speed = 8.0  # Rapido, foge
		goblin.max_hp = 100
		goblin.hp = 100
		goblin.xp_drop = 30
		goblin.scale = Vector3(1.5, 1.5, 1.5)
	get_parent().add_child(goblin)
	GameManager.enemies_alive += 1

func _spawn_merchant() -> void:
	# Merchant e um NPC parado que oferece 3 itens por cristais
	# TODO: Implementar UI de merchant (por enquanto dropa 3 items gratis)
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var center = players[0].global_position
	var offset = Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5))

	# Dropa 3 XP gems grandes como placeholder
	var gem_scene = preload("res://scenes/xp_gem.tscn")
	for i in range(3):
		var gem = gem_scene.instantiate()
		gem.global_position = center + offset + Vector3(i * 1.0, 0, 0)
		gem.xp_value = 10
		get_parent().call_deferred("add_child", gem)

func _do_roulette() -> void:
	# Roda da fortuna: efeito aleatorio
	var effects = ["speed_boost", "damage_boost", "heal", "slow"]
	var effect = effects[rng.randi() % effects.size()]
	match effect:
		"speed_boost":
			GameManager.speed_mult += 0.5
		"damage_boost":
			GameManager.perm_damage_mult += 0.3
		"heal":
			GameManager.heal(50)
		"slow":
			GameManager.speed_mult = maxf(0.5, GameManager.speed_mult - 0.3)
