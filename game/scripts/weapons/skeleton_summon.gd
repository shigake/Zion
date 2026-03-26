extends CharacterBody3D

## Esqueleto invocado pelo Necromante. Persegue e ataca inimigos.

@export var speed: float = 5.0
@export var damage: int = 6
@export var lifetime: float = 10.0
@export var attack_range: float = 1.2
@export var attack_cooldown: float = 0.8

var target: Node3D = null
var timer: float = 0.0
var attack_timer: float = 0.0

func _ready() -> void:
	add_to_group("player_summons")

func _physics_process(delta: float) -> void:
	if GameManager.paused:
		return

	timer += delta
	if timer >= lifetime:
		queue_free()
		return

	attack_timer -= delta

	_find_target()
	if target and is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		dir.y = 0
		var dist = global_position.distance_to(target.global_position)

		if dist > attack_range:
			velocity = dir * speed
			move_and_slide()
		elif attack_timer <= 0:
			_attack()
			attack_timer = attack_cooldown

func _find_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		target = null
		return
	var min_dist = INF
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d = global_position.distance_squared_to(e.global_position)
		if d < min_dist:
			min_dist = d
			target = e

func _attack() -> void:
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.call_deferred("take_damage", damage, "dark")
