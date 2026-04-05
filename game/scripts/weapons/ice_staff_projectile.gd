extends Area3D

## Projetil cristal de gelo do Ice Staff — cristal 3D que gira enquanto viaja.

@export var speed: float = 10.0
@export var damage: int = 10
@export var lifetime: float = 4.0

var direction: Vector3 = Vector3.FORWARD
var timer: float = 0.0
var damage_type: String = "ice"
var weapon_id: String = ""
var _returning: bool = false
var _spin_speed: float = 6.0
var _crystal_model: Node3D = null
var _trail_particles: GPUParticles3D = null

# Shared meshes for pooling performance
static var _shared_front_cone: CylinderMesh = null
static var _shared_back_cone: CylinderMesh = null
static var _shared_ice_mat: StandardMaterial3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_setup_crystal_model()

func _ensure_shared_meshes() -> void:
	if not _shared_ice_mat:
		_shared_ice_mat = StandardMaterial3D.new()
		_shared_ice_mat.albedo_color = Color(0.4, 0.75, 1.0, 0.88)
		_shared_ice_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shared_ice_mat.metallic = 0.4
		_shared_ice_mat.roughness = 0.1
		_shared_ice_mat.emission_enabled = true
		_shared_ice_mat.emission = Color(0.3, 0.7, 1.0)
		_shared_ice_mat.emission_energy_multiplier = 1.8
	if not _shared_front_cone:
		_shared_front_cone = CylinderMesh.new()
		_shared_front_cone.top_radius = 0.0
		_shared_front_cone.bottom_radius = 0.10
		_shared_front_cone.height = 0.3
		_shared_front_cone.radial_segments = 6
	if not _shared_back_cone:
		_shared_back_cone = CylinderMesh.new()
		_shared_back_cone.top_radius = 0.10
		_shared_back_cone.bottom_radius = 0.0
		_shared_back_cone.height = 0.15
		_shared_back_cone.radial_segments = 6

func _setup_crystal_model() -> void:
	# Guard: don't recreate if already exists (pool reuse)
	if _crystal_model and is_instance_valid(_crystal_model):
		return
	_crystal_model = get_node_or_null("CrystalModel")
	if _crystal_model:
		return

	_ensure_shared_meshes()

	# Hide any existing sprite/mesh
	var existing = get_node_or_null("ProjectileSprite")
	if existing:
		existing.visible = false
	var existing_mesh = get_node_or_null("Mesh")
	if not existing_mesh:
		existing_mesh = get_node_or_null("MeshInstance3D")
	if existing_mesh:
		existing_mesh.visible = false

	# Diamond crystal shape: front cone + back cone
	_crystal_model = Node3D.new()
	_crystal_model.name = "CrystalModel"

	var front = MeshInstance3D.new()
	front.mesh = _shared_front_cone
	front.material_override = _shared_ice_mat
	front.rotation.x = -PI / 2.0  # Point forward
	front.position.z = 0.075
	_crystal_model.add_child(front)

	var back = MeshInstance3D.new()
	back.mesh = _shared_back_cone
	back.material_override = _shared_ice_mat
	back.rotation.x = -PI / 2.0
	back.position.z = -0.075
	_crystal_model.add_child(back)

	add_child(_crystal_model)

	# Ice trail particles
	_trail_particles = GPUParticles3D.new()
	_trail_particles.name = "IceTrail"
	_trail_particles.amount = 6
	_trail_particles.lifetime = 0.4
	_trail_particles.emitting = true
	var trail_mesh = SphereMesh.new()
	trail_mesh.radius = 0.04
	trail_mesh.height = 0.08
	var trail_mat = StandardMaterial3D.new()
	trail_mat.albedo_color = Color(0.5, 0.85, 1.0, 0.5)
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.emission_enabled = true
	trail_mat.emission = Color(0.4, 0.8, 1.0)
	trail_mat.emission_energy_multiplier = 1.5
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_mesh.surface_set_material(0, trail_mat)
	_trail_particles.draw_pass_1 = trail_mesh
	var trail_proc = ParticleProcessMaterial.new()
	trail_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	trail_proc.direction = Vector3(0, 0, 1)  # Backward from crystal
	trail_proc.initial_velocity_min = 0.1
	trail_proc.initial_velocity_max = 0.3
	trail_proc.gravity = Vector3(0, 0.2, 0)
	trail_proc.scale_min = 0.5
	trail_proc.scale_max = 1.2
	# Fade out trail
	var trail_color = GradientTexture1D.new()
	var tg = Gradient.new()
	tg.set_color(0, Color(0.5, 0.85, 1.0, 0.6))
	tg.set_color(1, Color(0.3, 0.7, 1.0, 0.0))
	trail_color.gradient = tg
	trail_proc.color_ramp = trail_color
	_trail_particles.process_material = trail_proc
	add_child(_trail_particles)

func _physics_process(delta: float) -> void:
	if _returning:
		return
	timer += delta
	if timer >= lifetime:
		_return_to_pool()
		return

	# Spin crystal on Z axis while traveling
	if _crystal_model:
		_crystal_model.rotate_z(_spin_speed * delta)

	if is_inside_tree():
		global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if _returning:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		GameManager._last_attacking_weapon = "ice_staff"
		body.call_deferred("take_damage", damage, damage_type)

## Detecao alternativa via Area3D (Hitbox do inimigo)
func _on_area_entered(area: Area3D) -> void:
	if _returning:
		return
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage") and parent.is_in_group("enemies"):
		GameManager._last_attacking_weapon = "ice_staff"
		parent.call_deferred("take_damage", damage, damage_type)

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
	# RESET CRITICO: limpa rotacao/escala residual da "vida anterior" no pool
	transform.basis = Basis()
	visible = true
	set_physics_process(true)
	# Reconecta signals se nao estiverem conectados
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	# Reconecta referencia do crystal model (pode ter sido perdida no pool)
	if not _crystal_model or not is_instance_valid(_crystal_model):
		_crystal_model = get_node_or_null("CrystalModel")
	if _crystal_model:
		_crystal_model.scale = Vector3.ONE
		_crystal_model.rotation = Vector3.ZERO
	# Restart trail emitting
	if not _trail_particles or not is_instance_valid(_trail_particles):
		_trail_particles = get_node_or_null("IceTrail")
	if _trail_particles:
		_trail_particles.emitting = true
	# Forca sincronizacao da posicao antes de rodar (so se ja estiver na arvore)
	if is_inside_tree():
		force_update_transform()
