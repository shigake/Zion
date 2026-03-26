extends Area3D

## Projetil da Bazuca. Vai ate o alvo e explode em area.

@export var speed: float = 12.0
@export var damage: int = 30
@export var explosion_radius: float = 3.0

var target_pos: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	direction = (target_pos - global_position).normalized()
	direction.y = 0

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	# Chegou no alvo
	var flat_pos = Vector3(global_position.x, 0, global_position.z)
	var flat_target = Vector3(target_pos.x, 0, target_pos.z)
	if flat_pos.distance_to(flat_target) < 0.5:
		_explode()

func _explode() -> void:
	# Dano em area
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) <= explosion_radius:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", damage, "fire")

	# Visual: flash (placeholder — escala uma esfera rapidamente)
	var explosion_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = explosion_radius
	sphere.height = explosion_radius * 2
	explosion_mesh.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.1, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.2)
	mat.emission_energy_multiplier = 3.0
	explosion_mesh.set_surface_override_material(0, mat)
	explosion_mesh.global_position = global_position
	get_tree().current_scene.add_child(explosion_mesh)

	# Fade out
	var tween = explosion_mesh.create_tween()
	tween.tween_property(mat, "albedo_color", Color(1, 0.5, 0.1, 0), 0.4)
	tween.tween_callback(explosion_mesh.queue_free)

	queue_free()
