extends Node3D

## Gera props procedurais para Estacao Espacial: corredores metalicos, janelas com estrelas,
## tubulacoes, consoles. Zonas de gravidade zero aumentam velocidade em 50%.

@export var num_corridors: int = 25
@export var num_windows: int = 20
@export var num_pipes: int = 30
@export var num_consoles: int = 15
@export var num_zero_g_zones: int = 6
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var zero_g_zones: Array[Area3D] = []
var affected_bodies: Dictionary = {}

func _ready() -> void:
	rng.randomize()
	_generate_corridors()
	_generate_windows()
	_generate_pipes()
	_generate_consoles()
	_generate_zero_g_zones()
	_generate_ambient_lights()
	_generate_star_particles()

func _process(_delta: float) -> void:
	# Track bodies in zero-g zones for speed boost
	var currently_in: Dictionary = {}
	for area in zero_g_zones:
		if not is_instance_valid(area):
			continue
		var bodies = area.get_overlapping_bodies()
		for body in bodies:
			currently_in[body] = true
			if not affected_bodies.has(body):
				affected_bodies[body] = true
				if body.is_in_group("players"):
					GameManager.speed_mult += 0.5
				elif body.is_in_group("enemies") and body.has_method("set_speed_multiplier"):
					body.set_speed_multiplier(1.5)

	# Remove boost from bodies that left
	var to_remove: Array = []
	for body in affected_bodies:
		if not currently_in.has(body):
			to_remove.append(body)
			if is_instance_valid(body):
				if body.is_in_group("players"):
					GameManager.speed_mult -= 0.5
				elif body.is_in_group("enemies") and body.has_method("set_speed_multiplier"):
					body.set_speed_multiplier(1.0)
	for body in to_remove:
		affected_bodies.erase(body)

func _generate_corridors() -> void:
	for i in range(num_corridors):
		var corridor = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		corridor.position = Vector3(x, 0, z)

		var height = rng.randf_range(3.0, 6.0)
		var width = rng.randf_range(1.5, 4.0)
		var depth = rng.randf_range(1.5, 4.0)

		# Parede metalica
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(width, height, depth)
		var wall_mat = StandardMaterial3D.new()
		wall_mat.albedo_color = Color(0.45, 0.48, 0.5)
		wall_mat.roughness = 0.3
		wall_mat.metallic = 0.8
		wall_mesh.surface_set_material(0, wall_mat)

		var wall_inst = MeshInstance3D.new()
		wall_inst.mesh = wall_mesh
		wall_inst.position.y = height / 2.0
		corridor.add_child(wall_inst)

		# Faixa de luz no topo
		var strip_mesh = BoxMesh.new()
		strip_mesh.size = Vector3(width + 0.05, 0.1, depth + 0.05)
		var strip_mat = StandardMaterial3D.new()
		strip_mat.albedo_color = Color(0.4, 0.8, 1.0)
		strip_mat.emission_enabled = true
		strip_mat.emission = Color(0.3, 0.6, 0.9)
		strip_mat.emission_energy_multiplier = 2.0
		strip_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		strip_mesh.surface_set_material(0, strip_mat)

		var strip_inst = MeshInstance3D.new()
		strip_inst.mesh = strip_mesh
		strip_inst.position.y = height
		corridor.add_child(strip_inst)

		add_child(corridor)

func _generate_windows() -> void:
	for i in range(num_windows):
		var window = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		window.position = Vector3(x, rng.randf_range(2.0, 4.0), z)

		# Moldura
		var frame_mesh = BoxMesh.new()
		var w = rng.randf_range(2.0, 4.0)
		var h = rng.randf_range(1.5, 2.5)
		frame_mesh.size = Vector3(w, h, 0.15)
		var frame_mat = StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.35, 0.38, 0.4)
		frame_mat.metallic = 0.9
		frame_mat.roughness = 0.2
		frame_mesh.surface_set_material(0, frame_mat)

		var frame_inst = MeshInstance3D.new()
		frame_inst.mesh = frame_mesh
		frame_inst.rotation.y = rng.randf_range(0, TAU)
		window.add_child(frame_inst)

		# Vidro — azul escuro emissivo (estrelas)
		var glass_mesh = BoxMesh.new()
		glass_mesh.size = Vector3(w - 0.3, h - 0.3, 0.05)
		var glass_mat = StandardMaterial3D.new()
		glass_mat.albedo_color = Color(0.02, 0.03, 0.1, 0.8)
		glass_mat.emission_enabled = true
		glass_mat.emission = Color(0.05, 0.08, 0.2)
		glass_mat.emission_energy_multiplier = 1.5
		glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass_mesh.surface_set_material(0, glass_mat)

		var glass_inst = MeshInstance3D.new()
		glass_inst.mesh = glass_mesh
		glass_inst.rotation = frame_inst.rotation
		window.add_child(glass_inst)

		add_child(window)

func _generate_pipes() -> void:
	for i in range(num_pipes):
		var pipe = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		pipe.position = Vector3(x, rng.randf_range(0.5, 4.0), z)

		var pipe_mesh = CylinderMesh.new()
		pipe_mesh.top_radius = rng.randf_range(0.05, 0.15)
		pipe_mesh.bottom_radius = pipe_mesh.top_radius
		pipe_mesh.height = rng.randf_range(3.0, 10.0)
		var pipe_mat = StandardMaterial3D.new()
		pipe_mat.albedo_color = Color(0.4, 0.42, 0.45)
		pipe_mat.metallic = 0.9
		pipe_mat.roughness = 0.2
		pipe_mesh.surface_set_material(0, pipe_mat)

		var pipe_inst = MeshInstance3D.new()
		pipe_inst.mesh = pipe_mesh
		# Random orientation — horizontal or vertical
		if rng.randi() % 2 == 0:
			pipe_inst.rotation.z = PI / 2.0
		pipe_inst.rotation.y = rng.randf_range(0, TAU)
		pipe.add_child(pipe_inst)

		add_child(pipe)

func _generate_consoles() -> void:
	for i in range(num_consoles):
		var console = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 4 and abs(z) < 4:
			x += 7.0
		console.position = Vector3(x, 0, z)

		# Base do console
		var base_mesh = BoxMesh.new()
		base_mesh.size = Vector3(1.2, 0.8, 0.6)
		var base_mat = StandardMaterial3D.new()
		base_mat.albedo_color = Color(0.3, 0.32, 0.35)
		base_mat.metallic = 0.7
		base_mat.roughness = 0.3
		base_mesh.surface_set_material(0, base_mat)

		var base_inst = MeshInstance3D.new()
		base_inst.mesh = base_mesh
		base_inst.position.y = 0.4
		console.add_child(base_inst)

		# Tela do console
		var screen_mesh = BoxMesh.new()
		screen_mesh.size = Vector3(0.8, 0.5, 0.05)
		var screen_mat = StandardMaterial3D.new()
		var screen_colors: Array[Color] = [
			Color(0.0, 0.8, 0.3),
			Color(0.3, 0.6, 1.0),
			Color(1.0, 0.5, 0.0),
		]
		var sc = screen_colors[rng.randi() % screen_colors.size()]
		screen_mat.albedo_color = sc
		screen_mat.emission_enabled = true
		screen_mat.emission = sc
		screen_mat.emission_energy_multiplier = 2.0
		screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		screen_mesh.surface_set_material(0, screen_mat)

		var screen_inst = MeshInstance3D.new()
		screen_inst.mesh = screen_mesh
		screen_inst.position = Vector3(0, 1.0, -0.25)
		screen_inst.rotation.x = -0.3
		console.add_child(screen_inst)

		console.rotation.y = rng.randf_range(0, TAU)
		add_child(console)

func _generate_zero_g_zones() -> void:
	for i in range(num_zero_g_zones):
		var zone_node = Node3D.new()
		var x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		var z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		zone_node.position = Vector3(x, 0, z)

		var zone_size = rng.randf_range(8.0, 14.0)

		# Visual — glowing floor panel
		var vis_mesh = BoxMesh.new()
		vis_mesh.size = Vector3(zone_size, 0.04, zone_size)
		var vis_mat = StandardMaterial3D.new()
		vis_mat.albedo_color = Color(0.2, 0.6, 1.0, 0.12)
		vis_mat.emission_enabled = true
		vis_mat.emission = Color(0.1, 0.4, 0.8)
		vis_mat.emission_energy_multiplier = 1.5
		vis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vis_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		vis_mesh.surface_set_material(0, vis_mat)

		var vis_inst = MeshInstance3D.new()
		vis_inst.mesh = vis_mesh
		vis_inst.position.y = 0.03
		zone_node.add_child(vis_inst)

		# Area3D
		var area = Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 3
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(zone_size, 2.0, zone_size)
		col.shape = shape
		col.position.y = 1.0
		area.add_child(col)
		zone_node.add_child(area)
		zero_g_zones.append(area)

		add_child(zone_node)

func _generate_ambient_lights() -> void:
	for i in range(10):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		light.position = Vector3(x, 3.0, z)
		light.light_color = Color(0.5, 0.7, 1.0)
		light.light_energy = 0.4
		light.omni_range = 8.0
		light.omni_attenuation = 2.0
		add_child(light)

func _generate_star_particles() -> void:
	# Distant stars effect
	var stars = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 0.0
	mat.initial_velocity_max = 0.05
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 0.02
	mat.scale_max = 0.06
	mat.color = Color(0.9, 0.9, 1.0, 0.7)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(60, 20, 60)

	stars.process_material = mat
	stars.amount = 80
	stars.lifetime = 10.0
	stars.visibility_aabb = AABB(Vector3(-70, -5, -70), Vector3(140, 30, 140))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.03
	draw_pass.height = 0.03
	var star_mat = StandardMaterial3D.new()
	star_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
	star_mat.emission_enabled = true
	star_mat.emission = Color(0.8, 0.8, 1.0)
	star_mat.emission_energy_multiplier = 3.0
	star_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, star_mat)
	stars.draw_pass_1 = draw_pass

	stars.position = Vector3(0, 10, 0)
	add_child(stars)
