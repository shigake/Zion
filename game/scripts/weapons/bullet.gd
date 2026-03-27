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
	_ensure_bullet_mesh()
	_spawn_muzzle_flash()

func _ensure_bullet_mesh() -> void:
	var mesh_instance = get_node_or_null("Mesh")
	if not mesh_instance:
		mesh_instance = get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		return
	# If the mesh is still a SphereMesh, replace it with a metallic bullet
	if mesh_instance.mesh is SphereMesh:
		var bullet_mesh = CylinderMesh.new()
		bullet_mesh.top_radius = 0.02
		bullet_mesh.bottom_radius = 0.04
		bullet_mesh.height = 0.15
		mesh_instance.mesh = bullet_mesh
		mesh_instance.rotation.x = deg_to_rad(90)  # Point forward

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.75, 0.2)
		mat.metallic = 0.8
		mat.roughness = 0.3
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.85, 0.3)
		mat.emission_energy_multiplier = 1.5
		mesh_instance.material_override = mat

func _spawn_muzzle_flash() -> void:
	var mesh_instance = get_node_or_null("Mesh")
	if not mesh_instance:
		mesh_instance = get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		return
	# Brief scale-up flash effect on spawn
	var original_scale = mesh_instance.scale
	mesh_instance.scale = original_scale * 2.5
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", original_scale, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Bright flash light that fades quickly
	var flash_light = OmniLight3D.new()
	flash_light.light_color = Color(1.0, 0.9, 0.4)
	flash_light.light_energy = 3.0
	flash_light.omni_range = 1.5
	add_child(flash_light)
	var light_tween = create_tween()
	light_tween.tween_property(flash_light, "light_energy", 0.0, 0.12).set_ease(Tween.EASE_OUT)
	light_tween.tween_callback(flash_light.queue_free)

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
	_spawn_muzzle_flash()
