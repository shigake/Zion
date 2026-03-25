extends Area3D

## Projetil homing do Staff. Persegue o alvo e causa dano ao colidir.

@export var speed: float = 14.0
@export var damage: int = 8
@export var lifetime: float = 5.0
@export var homing_strength: float = 8.0

var target: Node3D = null
var direction: Vector3 = Vector3.FORWARD
var timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()

func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
		return

	# Homing: ajusta direcao em direcao ao alvo
	if target and is_instance_valid(target):
		var to_target = (target.global_position - global_position).normalized()
		to_target.y = 0
		direction = direction.lerp(to_target, homing_strength * delta).normalized()

	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		body.call_deferred("take_damage", damage)
		queue_free()
