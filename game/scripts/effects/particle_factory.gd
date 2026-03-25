extends Node

## Fabrica de particulas. Cria efeitos visuais em posicoes 3D.

func spawn_hit_particles(pos: Vector3, color: Color = Color.WHITE, count: int = 6) -> void:
	var particles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, -8, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.12
	mat.color = color

	particles.process_material = mat
	particles.amount = count
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 1.0

	# Mesh
	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.08
	draw_pass.height = 0.16
	var draw_mat = StandardMaterial3D.new()
	draw_mat.albedo_color = color
	draw_mat.emission_enabled = true
	draw_mat.emission = color
	draw_mat.emission_energy_multiplier = 2.0
	draw_pass.surface_set_material(0, draw_mat)
	particles.draw_pass_1 = draw_pass

	particles.global_position = pos
	_add_to_scene(particles, 1.0)

func spawn_death_particles(pos: Vector3, color: Color, count: int = 12) -> void:
	var particles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, -6, 0)
	mat.scale_min = 0.08
	mat.scale_max = 0.2
	mat.color = color

	particles.process_material = mat
	particles.amount = count
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 1.0

	var draw_pass = BoxMesh.new()
	draw_pass.size = Vector3(0.1, 0.1, 0.1)
	var draw_mat = StandardMaterial3D.new()
	draw_mat.albedo_color = color
	draw_mat.emission_enabled = true
	draw_mat.emission = color
	draw_mat.emission_energy_multiplier = 1.5
	draw_pass.surface_set_material(0, draw_mat)
	particles.draw_pass_1 = draw_pass

	particles.global_position = pos
	_add_to_scene(particles, 1.5)

func spawn_collect_particles(pos: Vector3, color: Color = Color(0.2, 0.6, 1.0)) -> void:
	var particles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, 2, 0)  # Sobe
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = color

	particles.process_material = mat
	particles.amount = 4
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 1.0

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.05
	draw_pass.height = 0.1
	var draw_mat = StandardMaterial3D.new()
	draw_mat.albedo_color = color
	draw_mat.emission_enabled = true
	draw_mat.emission = color
	draw_mat.emission_energy_multiplier = 3.0
	draw_pass.surface_set_material(0, draw_mat)
	particles.draw_pass_1 = draw_pass

	particles.global_position = pos
	_add_to_scene(particles, 1.0)

func spawn_level_up_particles(pos: Vector3) -> void:
	var particles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 6.0
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.15
	mat.color = Color(1.0, 0.9, 0.3)

	particles.process_material = mat
	particles.amount = 20
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 0.8

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.06
	draw_pass.height = 0.12
	var draw_mat = StandardMaterial3D.new()
	draw_mat.albedo_color = Color(1, 0.9, 0.3)
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(1, 0.85, 0.2)
	draw_mat.emission_energy_multiplier = 3.0
	draw_pass.surface_set_material(0, draw_mat)
	particles.draw_pass_1 = draw_pass

	particles.global_position = pos
	_add_to_scene(particles, 2.0)

func spawn_explosion_particles(pos: Vector3, radius: float = 3.0) -> void:
	var particles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = radius * 2
	mat.initial_velocity_max = radius * 4
	mat.gravity = Vector3(0, -4, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.3
	mat.color = Color(1.0, 0.5, 0.1)

	particles.process_material = mat
	particles.amount = 15
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 1.0

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.1
	draw_pass.height = 0.2
	var draw_mat = StandardMaterial3D.new()
	draw_mat.albedo_color = Color(1, 0.5, 0.1)
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(1, 0.4, 0.05)
	draw_mat.emission_energy_multiplier = 4.0
	draw_pass.surface_set_material(0, draw_mat)
	particles.draw_pass_1 = draw_pass

	particles.global_position = pos
	_add_to_scene(particles, 1.5)

func _add_to_scene(node: Node3D, cleanup_time: float) -> void:
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if scene:
		scene.add_child(node)
		# Auto cleanup
		var timer = Timer.new()
		timer.wait_time = cleanup_time
		timer.one_shot = true
		timer.timeout.connect(node.queue_free)
		node.add_child(timer)
		timer.start()
