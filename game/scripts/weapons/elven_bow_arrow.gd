extends Area3D

## Flecha elfica — perfura todos os inimigos e ricocheta uma vez apos distancia.

@export var speed: float = 20.0
@export var damage: int = 12
@export var lifetime: float = 4.0

var direction: Vector3 = Vector3.FORWARD
var timer: float = 0.0
var damage_type: String = "physical"
var pierce: bool = true
var ricochet_distance: float = 15.0
var distance_traveled: float = 0.0
var has_ricocheted: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
		return

	var move = direction * speed * delta
	global_position += move
	distance_traveled += move.length()

	# Ricocheta uma vez apos percorrer ricochet_distance
	if not has_ricocheted and distance_traveled >= ricochet_distance:
		has_ricocheted = true
		var angle = randf_range(-PI, PI)
		direction = direction.rotated(Vector3.UP, angle).normalized()

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		body.call_deferred("take_damage", damage, damage_type)
		# Nao faz queue_free — perfura todos os inimigos
