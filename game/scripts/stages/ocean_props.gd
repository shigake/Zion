extends Node3D

## Gera props procedurais para Fundo do Oceano: recifes de coral, bolhas,
## ruinas antigas, algas. Correntes de agua empurram o jogador.

@export var num_corals: int = 40
@export var num_ruins: int = 15
@export var num_seaweed: int = 30
@export var num_current_zones: int = 6
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var coral_colors: Array[Color] = [
	Color(1.0, 0.3, 0.4),   # Rosa coral
	Color(1.0, 0.6, 0.1),   # Laranja
	Color(0.3, 0.8, 0.5),   # Verde agua
	Color(0.6, 0.2, 0.8),   # Roxo
	Color(1.0, 0.8, 0.2),   # Amarelo
]

var current_zones: Array[Dictionary] = []
var current_timer: float = 0.0
var current_change_interval: float = 8.0

func _ready() -> void:
	rng.randomize()
	_generate_corals()
	_generate_bubbles()
	_generate_ruins()
	_generate_seaweed()
	_generate_current_zones()
	_generate_ambient_lights()

func _process(delta: float) -> void:
	# Change current direction periodically
	current_timer += delta
	if current_timer >= current_change_interval:
		current_timer = 0.0
		for zone in current_zones:
			zone["direction"] = Vector3(
				rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)
			).normalized()

	# Apply water current push to players in zones
	for zone in current_zones:
		var area: Area3D = zone["area"]
		if not is_instance_valid(area):
			continue
		var bodies = area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("players") and body is CharacterBody3D:
				body.velocity += zone["direction"] * 3.0 * delta

func _generate_corals() -> void:
	for i in range(num_corals):
		var coral = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		coral.position = Vector3(x, 0, z)

		var color = coral_colors[rng.randi() % coral_colors.size()]
		var coral_type = rng.randi() % 3

		if coral_type == 0:
			# Coral esfera
			var mesh = SphereMesh.new()
			mesh.radius = rng.randf_range(0.5, 1.5)
			mesh.height = mesh.radius * 1.5
			var mat = StandardMaterial3D.new()
			mat.albedo_color = color
			mat.roughness = 0.6
			mat.emission_enabled = true
			mat.emission = color * 0.2
			mat.emission_energy_multiplier = 0.5
			mesh.surface_set_material(0, mat)

			var inst = MeshInstance3D.new()
			inst.mesh = mesh
			inst.position.y = mesh.radius * 0.5
			coral.add_child(inst)
		elif coral_type == 1:
			# Coral cilindrico (tipo tubo)
			var num_tubes = rng.randi_range(2, 5)
			for t in range(num_tubes):
				var mesh = CylinderMesh.new()
				mesh.top_radius = rng.randf_range(0.1, 0.3)
				mesh.bottom_radius = rng.randf_range(0.15, 0.4)
				mesh.height = rng.randf_range(0.8, 2.5)
				var mat = StandardMaterial3D.new()
				mat.albedo_color = color
				mat.roughness = 0.5
				mat.emission_enabled = true
				mat.emission = color * 0.3
				mat.emission_energy_multiplier = 0.5
				mesh.surface_set_material(0, mat)

				var inst = MeshInstance3D.new()
				inst.mesh = mesh
				inst.position = Vector3(rng.randf_range(-0.5, 0.5), mesh.height / 2.0, rng.randf_range(-0.5, 0.5))
				inst.rotation = Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
				coral.add_child(inst)
		else:
			# Coral plano (tipo leque)
			var mesh = BoxMesh.new()
			mesh.size = Vector3(rng.randf_range(1.0, 2.5), rng.randf_range(1.0, 2.0), 0.08)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
			mat.roughness = 0.4
			mat.emission_enabled = true
			mat.emission = color * 0.3
			mat.emission_energy_multiplier = 0.8
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.surface_set_material(0, mat)

			var inst = MeshInstance3D.new()
			inst.mesh = mesh
			inst.position.y = mesh.size.y / 2.0
			inst.rotation.y = rng.randf_range(0, TAU)
			coral.add_child(inst)

		add_child(coral)

func _generate_bubbles() -> void:
	var bubbles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 20.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 1.5
	mat.gravity = Vector3(0, 0.3, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.2
	mat.color = Color(0.6, 0.8, 1.0, 0.4)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(50, 0.5, 50)

	bubbles.process_material = mat
	bubbles.amount = 100
	bubbles.lifetime = 6.0
	bubbles.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 20, 120))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.1
	draw_pass.height = 0.1
	var bubble_mat = StandardMaterial3D.new()
	bubble_mat.albedo_color = Color(0.7, 0.9, 1.0, 0.3)
	bubble_mat.emission_enabled = true
	bubble_mat.emission = Color(0.5, 0.7, 1.0)
	bubble_mat.emission_energy_multiplier = 1.0
	bubble_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubble_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, bubble_mat)
	bubbles.draw_pass_1 = draw_pass

	bubbles.position = Vector3(0, 0.5, 0)
	add_child(bubbles)

func _generate_ruins() -> void:
	for i in range(num_ruins):
		var ruin = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		ruin.position = Vector3(x, 0, z)

		var ruin_type = rng.randi() % 2
		if ruin_type == 0:
			# Coluna quebrada
			var col_mesh = CylinderMesh.new()
			var height = rng.randf_range(2.0, 5.0)
			col_mesh.top_radius = 0.4
			col_mesh.bottom_radius = 0.5
			col_mesh.height = height
			var col_mat = StandardMaterial3D.new()
			col_mat.albedo_color = Color(0.5, 0.5, 0.45)
			col_mat.roughness = 0.9
			col_mesh.surface_set_material(0, col_mat)

			var col_inst = MeshInstance3D.new()
			col_inst.mesh = col_mesh
			col_inst.position.y = height / 2.0
			col_inst.rotation = Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
			ruin.add_child(col_inst)
		else:
			# Bloco de pedra caido
			var block_mesh = BoxMesh.new()
			block_mesh.size = Vector3(
				rng.randf_range(1.5, 3.0),
				rng.randf_range(0.5, 1.5),
				rng.randf_range(1.0, 2.5)
			)
			var block_mat = StandardMaterial3D.new()
			block_mat.albedo_color = Color(0.45, 0.45, 0.4)
			block_mat.roughness = 0.9
			block_mesh.surface_set_material(0, block_mat)

			var block_inst = MeshInstance3D.new()
			block_inst.mesh = block_mesh
			block_inst.position.y = block_mesh.size.y / 2.0
			block_inst.rotation.y = rng.randf_range(0, TAU)
			ruin.add_child(block_inst)

		add_child(ruin)

func _generate_seaweed() -> void:
	for i in range(num_seaweed):
		var weed = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		weed.position = Vector3(x, 0, z)

		var num_blades = rng.randi_range(2, 5)
		for b in range(num_blades):
			var blade_mesh = BoxMesh.new()
			var blade_height = rng.randf_range(1.0, 3.0)
			blade_mesh.size = Vector3(0.08, blade_height, 0.15)
			var blade_mat = StandardMaterial3D.new()
			var green = rng.randf_range(0.3, 0.6)
			blade_mat.albedo_color = Color(0.05, green, 0.15, 0.8)
			blade_mat.roughness = 0.7
			blade_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			blade_mesh.surface_set_material(0, blade_mat)

			var blade_inst = MeshInstance3D.new()
			blade_inst.mesh = blade_mesh
			blade_inst.position = Vector3(rng.randf_range(-0.3, 0.3), blade_height / 2.0, rng.randf_range(-0.3, 0.3))
			blade_inst.rotation = Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(0, TAU), rng.randf_range(-0.1, 0.1))
			weed.add_child(blade_inst)

		add_child(weed)

func _generate_current_zones() -> void:
	for i in range(num_current_zones):
		var zone_node = Node3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		zone_node.position = Vector3(x, 0, z)

		var zone_size = rng.randf_range(8.0, 15.0)

		# Visual indicator — faint blue plane
		var vis_mesh = BoxMesh.new()
		vis_mesh.size = Vector3(zone_size, 0.04, zone_size)
		var vis_mat = StandardMaterial3D.new()
		vis_mat.albedo_color = Color(0.2, 0.5, 0.8, 0.15)
		vis_mat.emission_enabled = true
		vis_mat.emission = Color(0.1, 0.3, 0.6)
		vis_mat.emission_energy_multiplier = 1.0
		vis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vis_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		vis_mesh.surface_set_material(0, vis_mat)

		var vis_inst = MeshInstance3D.new()
		vis_inst.mesh = vis_mesh
		vis_inst.position.y = 0.02
		zone_node.add_child(vis_inst)

		# Area3D
		var area = Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 1  # Players only
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(zone_size, 2.0, zone_size)
		col.shape = shape
		col.position.y = 1.0
		area.add_child(col)
		zone_node.add_child(area)

		var direction = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
		current_zones.append({"area": area, "direction": direction})

		add_child(zone_node)

func _generate_ambient_lights() -> void:
	var light_colors: Array[Color] = [
		Color(0.1, 0.3, 0.8),
		Color(0.0, 0.5, 0.6),
		Color(0.2, 0.4, 0.7),
	]
	for i in range(10):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		light.position = Vector3(x, 2.0, z)
		light.light_color = light_colors[rng.randi() % light_colors.size()]
		light.light_energy = 0.4
		light.omni_range = 10.0
		light.omni_attenuation = 2.0
		add_child(light)
