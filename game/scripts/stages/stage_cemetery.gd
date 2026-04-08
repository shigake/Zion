extends BaseStage

## Fase Cemiterio

func _ready() -> void:
	music_track = "cemetery"
	super._ready()
	_add_ambient_leaves()

## Folhas secas caindo lentamente — ambiente sombrio do cemiterio
func _add_ambient_leaves() -> void:
	var particles = GPUParticles3D.new()
	particles.name = "AmbientLeaves"
	particles.amount = 12
	particles.lifetime = 8.0
	particles.visibility_aabb = AABB(Vector3(-50, -5, -50), Vector3(100, 20, 100))

	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(40, 0.5, 40)
	mat.direction = Vector3(0.2, -1, 0.1)
	mat.spread = 15.0
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 0.6
	mat.gravity = Vector3(0, -0.15, 0)
	mat.angular_velocity_min = -20.0
	mat.angular_velocity_max = 20.0
	mat.scale_min = 0.15
	mat.scale_max = 0.3
	mat.color = Color(0.35, 0.25, 0.15, 0.6)

	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.4, 0.25)

	particles.process_material = mat
	particles.draw_pass_1 = mesh
	particles.position = Vector3(0, 12, 0)
	add_child(particles)
