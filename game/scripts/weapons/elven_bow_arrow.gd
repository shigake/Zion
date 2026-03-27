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
		_spawn_ricochet_flash()

func _spawn_ricochet_flash() -> void:
	# Brief bright green flash on bounce
	var flash = MeshInstance3D.new()
	var flash_mesh = SphereMesh.new()
	flash_mesh.radius = 0.01
	flash_mesh.height = 0.02
	flash.mesh = flash_mesh

	var flash_mat = StandardMaterial3D.new()
	flash_mat.albedo_color = Color(0.3, 1.0, 0.3)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(0.2, 1.0, 0.3)
	flash_mat.emission_energy_multiplier = 4.0
	flash.material_override = flash_mat
	flash.scale = Vector3.ZERO

	get_tree().current_scene.add_child(flash)
	flash.global_position = global_position

	# Scale up then down: 0 -> 0.3 -> 0 in 0.15s
	var tween = flash.create_tween()
	tween.tween_property(flash, "scale", Vector3(0.3, 0.3, 0.3) * 30.0, 0.075).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(flash, "scale", Vector3.ZERO, 0.075).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(flash.queue_free)

	# Green flash light
	var light = OmniLight3D.new()
	light.light_color = Color(0.2, 1.0, 0.3)
	light.light_energy = 3.0
	light.omni_range = 2.0
	flash.add_child(light)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		body.call_deferred("take_damage", damage, damage_type)
		# Nao faz queue_free — perfura todos os inimigos
