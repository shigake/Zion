extends Area3D

## Projetil generico (metralhadora, etc). Vai reto e causa dano ao colidir.

@export var speed: float = 22.0
@export var damage: int = 4
@export var lifetime: float = 2.0

var direction: Vector3 = Vector3.FORWARD
var timer: float = 0.0
var damage_type: String = "physical"
var _returning: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _returning:
		return
	timer += delta
	if timer >= lifetime:
		_return_to_pool()
		return
	if is_inside_tree():
		global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if _returning:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		body.call_deferred("take_damage", damage, damage_type)
		_return_to_pool()
	elif body.has_method("take_damage") and body.is_in_group("players"):
		body.call_deferred("take_damage", damage)
		_return_to_pool()

func _return_to_pool() -> void:
	if _returning:
		return
	_returning = true
	timer = 0.0
	direction = Vector3.FORWARD
	monitoring = false
	call_deferred("_do_return")

func _do_return() -> void:
	if scene_file_path and not scene_file_path.is_empty():
		ObjectPool.return_instance(self, scene_file_path)
	else:
		queue_free()

func _reset_for_reuse() -> void:
	_returning = false
	monitoring = true
	timer = 0.0
