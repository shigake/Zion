extends BaseStage

## Fase Floresta Encantada

func _ready() -> void:
	music_track = "forest"
	super._ready()
	_add_ambient_leaves()
	_add_fireflies()

## Folhas verdes caindo suavemente pela floresta
func _add_ambient_leaves() -> void:
	var particles = GPUParticles3D.new()
	particles.name = "AmbientLeaves"
	particles.amount = 15
	particles.lifetime = 10.0
	particles.visibility_aabb = AABB(Vector3(-50, -5, -50), Vector3(100, 20, 100))

	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(40, 0.5, 40)
	mat.direction = Vector3(0.15, -1, 0.05)
	mat.spread = 20.0
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.5
	mat.gravity = Vector3(0, -0.1, 0)
	mat.angular_velocity_min = -15.0
	mat.angular_velocity_max = 15.0
	mat.scale_min = 0.12
	mat.scale_max = 0.28
	mat.color = Color(0.2, 0.45, 0.12, 0.55)

	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.35, 0.2)

	particles.process_material = mat
	particles.draw_pass_1 = mesh
	particles.position = Vector3(0, 12, 0)
	add_child(particles)

## Vagalumes sutis — pequenos pontos brilhantes flutuando
func _add_fireflies() -> void:
	var particles = GPUParticles3D.new()
	particles.name = "Fireflies"
	particles.amount = 10
	particles.lifetime = 6.0
	particles.visibility_aabb = AABB(Vector3(-50, -5, -50), Vector3(100, 15, 100))

	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(35, 3, 35)
	mat.direction = Vector3(0, 0.3, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 0.1
	mat.initial_velocity_max = 0.3
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 0.06
	mat.scale_max = 0.12
	mat.color = Color(0.7, 0.95, 0.3, 0.7)

	var mesh = SphereMesh.new()
	mesh.radius = 0.08
	mesh.height = 0.16

	var glow_mat = StandardMaterial3D.new()
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.6, 0.9, 0.2)
	glow_mat.emission_energy_multiplier = 3.0
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.albedo_color = Color(0.7, 0.95, 0.3, 0.7)
	mesh.material = glow_mat

	particles.process_material = mat
	particles.draw_pass_1 = mesh
	particles.position = Vector3(0, 3, 0)
	add_child(particles)
