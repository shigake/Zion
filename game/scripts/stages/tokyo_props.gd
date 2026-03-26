extends Node3D

## Gera props procedurais para Tokyo Cyberpunk: predios neon, billboards holograficos,
## chuva, paineis eletricos que causam dano.

@export var num_buildings: int = 35
@export var num_billboards: int = 20
@export var num_electric_panels: int = 12
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var neon_colors: Array[Color] = [
	Color(1.0, 0.0, 0.5),   # Rosa neon
	Color(0.0, 0.8, 1.0),   # Ciano neon
	Color(0.5, 0.0, 1.0),   # Roxo neon
	Color(1.0, 0.3, 0.0),   # Laranja neon
	Color(0.0, 1.0, 0.3),   # Verde neon
]

var electric_panels: Array[Area3D] = []
var electric_timer: float = 0.0

func _ready() -> void:
	rng.randomize()
	_generate_buildings()
	_generate_billboards()
	_generate_electric_panels()
	_generate_rain()
	_generate_neon_lights()

func _process(delta: float) -> void:
	# Electric panels deal 10 damage every 2 seconds
	electric_timer += delta
	if electric_timer >= 2.0:
		electric_timer = 0.0
		for panel_area in electric_panels:
			if not is_instance_valid(panel_area):
				continue
			var bodies = panel_area.get_overlapping_bodies()
			for body in bodies:
				if body.is_in_group("players") and body.has_method("take_damage"):
					body.take_damage(10)
				elif body.is_in_group("enemies") and body.has_method("take_damage"):
					body.take_damage(10)

func _generate_buildings() -> void:
	for i in range(num_buildings):
		var building = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 8 and abs(z) < 8:
			x += 12.0
		building.position = Vector3(x, 0, z)

		var height = rng.randf_range(6.0, 18.0)
		var width = rng.randf_range(2.0, 5.0)
		var depth = rng.randf_range(2.0, 5.0)

		# Corpo do predio
		var body_mesh = BoxMesh.new()
		body_mesh.size = Vector3(width, height, depth)
		var body_mat = StandardMaterial3D.new()
		body_mat.albedo_color = Color(0.08, 0.08, 0.12)
		body_mat.roughness = 0.3
		body_mat.metallic = 0.6
		body_mesh.surface_set_material(0, body_mat)

		var body_inst = MeshInstance3D.new()
		body_inst.mesh = body_mesh
		body_inst.position.y = height / 2.0
		building.add_child(body_inst)

		# Faixas neon nas laterais
		var neon_color = neon_colors[rng.randi() % neon_colors.size()]
		var num_stripes = rng.randi_range(2, 5)
		for s in range(num_stripes):
			var stripe_mesh = BoxMesh.new()
			stripe_mesh.size = Vector3(width + 0.05, 0.15, depth + 0.05)
			var stripe_mat = StandardMaterial3D.new()
			stripe_mat.albedo_color = neon_color
			stripe_mat.emission_enabled = true
			stripe_mat.emission = neon_color
			stripe_mat.emission_energy_multiplier = 3.0
			stripe_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			stripe_mesh.surface_set_material(0, stripe_mat)

			var stripe_inst = MeshInstance3D.new()
			stripe_inst.mesh = stripe_mesh
			stripe_inst.position.y = (s + 1) * (height / (num_stripes + 1))
			building.add_child(stripe_inst)

		add_child(building)

func _generate_billboards() -> void:
	for i in range(num_billboards):
		var billboard = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		billboard.position = Vector3(x, rng.randf_range(3.0, 6.0), z)

		# Poste
		var pole_mesh = CylinderMesh.new()
		pole_mesh.top_radius = 0.05
		pole_mesh.bottom_radius = 0.05
		pole_mesh.height = billboard.position.y
		var pole_mat = StandardMaterial3D.new()
		pole_mat.albedo_color = Color(0.3, 0.3, 0.35)
		pole_mat.metallic = 0.8
		pole_mesh.surface_set_material(0, pole_mat)

		var pole = MeshInstance3D.new()
		pole.mesh = pole_mesh
		pole.position.y = -billboard.position.y / 2.0
		billboard.add_child(pole)

		# Painel holografico
		var panel_mesh = BoxMesh.new()
		panel_mesh.size = Vector3(rng.randf_range(2.0, 4.0), rng.randf_range(1.0, 2.0), 0.05)
		var panel_mat = StandardMaterial3D.new()
		var holo_color = neon_colors[rng.randi() % neon_colors.size()]
		panel_mat.albedo_color = Color(holo_color.r, holo_color.g, holo_color.b, 0.7)
		panel_mat.emission_enabled = true
		panel_mat.emission = holo_color
		panel_mat.emission_energy_multiplier = 2.0
		panel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		panel_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		panel_mesh.surface_set_material(0, panel_mat)

		var panel_inst = MeshInstance3D.new()
		panel_inst.mesh = panel_mesh
		panel_inst.rotation.y = rng.randf_range(0, TAU)
		billboard.add_child(panel_inst)

		add_child(billboard)

func _generate_electric_panels() -> void:
	for i in range(num_electric_panels):
		var panel_node = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		panel_node.position = Vector3(x, 0, z)

		# Painel visual no chao
		var panel_mesh = BoxMesh.new()
		var panel_size = rng.randf_range(3.0, 6.0)
		panel_mesh.size = Vector3(panel_size, 0.05, panel_size)
		var panel_mat = StandardMaterial3D.new()
		panel_mat.albedo_color = Color(0.0, 0.6, 1.0, 0.5)
		panel_mat.emission_enabled = true
		panel_mat.emission = Color(0.0, 0.4, 0.8)
		panel_mat.emission_energy_multiplier = 2.5
		panel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		panel_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		panel_mesh.surface_set_material(0, panel_mat)

		var panel_vis = MeshInstance3D.new()
		panel_vis.mesh = panel_mesh
		panel_vis.position.y = 0.03
		panel_node.add_child(panel_vis)

		# Area3D para detectar corpos
		var area = Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 3  # Players (1) + Enemies (2)
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(panel_size, 1.0, panel_size)
		col.shape = shape
		col.position.y = 0.5
		area.add_child(col)
		panel_node.add_child(area)
		electric_panels.append(area)

		# Particulas de eletricidade
		var sparks = GPUParticles3D.new()
		var spark_mat = ParticleProcessMaterial.new()
		spark_mat.direction = Vector3(0, 1, 0)
		spark_mat.spread = 80.0
		spark_mat.initial_velocity_min = 1.0
		spark_mat.initial_velocity_max = 3.0
		spark_mat.gravity = Vector3(0, -2.0, 0)
		spark_mat.scale_min = 0.05
		spark_mat.scale_max = 0.15
		spark_mat.color = Color(0.3, 0.7, 1.0, 0.9)
		spark_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		spark_mat.emission_box_extents = Vector3(panel_size / 2.0, 0.1, panel_size / 2.0)

		sparks.process_material = spark_mat
		sparks.amount = 20
		sparks.lifetime = 1.0
		sparks.visibility_aabb = AABB(Vector3(-panel_size, -1, -panel_size), Vector3(panel_size * 2, 4, panel_size * 2))

		var spark_draw = SphereMesh.new()
		spark_draw.radius = 0.04
		spark_draw.height = 0.04
		var spark_draw_mat = StandardMaterial3D.new()
		spark_draw_mat.albedo_color = Color(0.5, 0.8, 1.0)
		spark_draw_mat.emission_enabled = true
		spark_draw_mat.emission = Color(0.3, 0.6, 1.0)
		spark_draw_mat.emission_energy_multiplier = 5.0
		spark_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		spark_draw.surface_set_material(0, spark_draw_mat)
		sparks.draw_pass_1 = spark_draw

		sparks.position.y = 0.1
		panel_node.add_child(sparks)

		add_child(panel_node)

func _generate_rain() -> void:
	var rain = GPUParticles3D.new()
	var rain_mat = ParticleProcessMaterial.new()
	rain_mat.direction = Vector3(0, -1, 0)
	rain_mat.spread = 5.0
	rain_mat.initial_velocity_min = 15.0
	rain_mat.initial_velocity_max = 20.0
	rain_mat.gravity = Vector3(0, -5.0, 0)
	rain_mat.scale_min = 0.02
	rain_mat.scale_max = 0.04
	rain_mat.color = Color(0.5, 0.6, 0.8, 0.4)
	rain_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rain_mat.emission_box_extents = Vector3(60, 0.5, 60)

	rain.process_material = rain_mat
	rain.amount = 300
	rain.lifetime = 2.0
	rain.visibility_aabb = AABB(Vector3(-70, -5, -70), Vector3(140, 40, 140))

	var drop_mesh = BoxMesh.new()
	drop_mesh.size = Vector3(0.02, 0.3, 0.02)
	var drop_mat = StandardMaterial3D.new()
	drop_mat.albedo_color = Color(0.6, 0.7, 0.9, 0.3)
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mesh.surface_set_material(0, drop_mat)
	rain.draw_pass_1 = drop_mesh

	rain.position = Vector3(0, 25.0, 0)
	add_child(rain)

func _generate_neon_lights() -> void:
	for i in range(15):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		light.position = Vector3(x, rng.randf_range(1.5, 4.0), z)
		light.light_color = neon_colors[rng.randi() % neon_colors.size()]
		light.light_energy = 0.6
		light.omni_range = 8.0
		light.omni_attenuation = 2.0
		add_child(light)
