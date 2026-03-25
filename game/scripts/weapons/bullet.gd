extends Area3D

## Projetil generico (metralhadora, etc). Vai reto e causa dano ao colidir.

@export var speed: float = 22.0
@export var damage: int = 4
@export var lifetime: float = 2.0

var direction: Vector3 = Vector3.FORWARD
var timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
		return
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		body.call_deferred("take_damage", damage)
		queue_free()
