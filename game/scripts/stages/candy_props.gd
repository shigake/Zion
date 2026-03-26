extends Node3D

## Gera props procedurais para Mundo Doce: patches de chocolate, montanhas de sorvete,
## pilares de candy cane, gummy bears. Zonas de caramelo reduzem velocidade em 40%.

@export var num_chocolate: int = 20
@export var num_ice_cream: int = 15
@export var num_candy_canes: int = 25
@export var num_gummy_bears: int = 30
@export var num_caramel_zones: int = 8
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var caramel_zones: Array[Area3D] = []
var affected_bodies: Dictionary = {}

func _ready() -> void:
	rng.randomize()
	_generate_chocolate_patches()
	_generate_ice_cream_mountains()
	_generate_candy_canes()
	_generate_gummy_bears()
	_generate_caramel_zones()
	_generate_sprinkle_particles()
	_generate_ambient_lights()

func _process(_delta: float) -> void:
	# Track bodies in caramel zones for slow effect
	var currently_in: Dictionary = {}
	for area in caramel_zones:
		if not is_instance_valid(area):
			continue
		var bodies = area.get_overlapping_bodies()
		for body in bodies:
			currently_in[body] = true
			if not affected_bodies.has(body):
				affected_bodies[body] = true
				if body.is_in_group("players"):
					GameManager.speed_mult -= 0.4
				elif body.is_in_group("enemies") and body.has_method("set_speed_multiplier"):
					body.set_speed_multiplier(0.6)

	# Remove slow from bodies that left
	var to_remove: Array = []
	for body in affected_bodies:
		if not currently_in.has(body):
			to_remove.append(body)
			if is_instance_valid(body):
				if body.is_in_group("players"):
					GameManager.speed_mult += 0.4
				elif body.is_in_group("enemies") and body.has_method("set_speed_multiplier"):
					body.set_speed_multiplier(1.0)
	for body in to_remove:
		affected_bodies.erase(body)

func _generate_chocolate_patches() -> void:
	for i in range(num_chocolate):
		var patch = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		patch.position = Vector3(x, 0, z)

		var patch_mesh = BoxMesh.new()
		var size_x = rng.randf_range(2.0, 6.0)
		var size_z = rng.randf_range(2.0, 6.0)
		patch_mesh.size = Vector3(size_x, 0.08, size_z)
		var patch_mat = StandardMaterial3D.new()
		var brown = rng.randf_range(0.2, 0.35)
		patch_mat.albedo_color = Color(brown, brown * 0.5, brown * 0.2)
		patch_mat.roughness = 0.4
		patch_mat.metallic = 0.1
		patch_mesh.surface_set_material(0, patch_mat)

		var patch_inst = MeshInstance3D.new()
		patch_inst.mesh = patch_mesh
		patch_inst.position.y = 0.04
		patch_inst.rotation.y = rng.randf_range(0, TAU)
		patch.add_child(patch_inst)

		# Decoracao — pedacos de chocolate em cima
		var num_chunks = rng.randi_range(1, 3)
		for c in range(num_chunks):
			var chunk_mesh = BoxMesh.new()
			chunk_mesh.size = Vector3(
				rng.randf_range(0.3, 0.8),
				rng.randf_range(0.2, 0.5),
				rng.randf_range(0.3, 0.8)
			)
			var chunk_mat = StandardMaterial3D.new()
			chunk_mat.albedo_color = Color(0.25, 0.12, 0.05)
			chunk_mat.roughness = 0.3
			chunk_mesh.surface_set_material(0, chunk_mat)

			var chunk_inst = MeshInstance3D.new()
			chunk_inst.mesh = chunk_mesh
			chunk_inst.position = Vector3(
				rng.randf_range(-size_x / 3.0, size_x / 3.0),
				0.08 + chunk_mesh.size.y / 2.0,
				rng.randf_range(-size_z / 3.0, size_z / 3.0)
			)
			chunk_inst.rotation.y = rng.randf_range(0, TAU)
			patch.add_child(chunk_inst)

		add_child(patch)

func _generate_ice_cream_mountains() -> void:
	var ice_cream_colors: Array[Color] = [
		Color(1.0, 0.8, 0.85),   # Morango
		Color(0.85, 0.7, 0.5),   # Baunilha
		Color(0.4, 0.25, 0.15),  # Chocolate
		Color(0.6, 0.9, 0.6),    # Menta
		Color(0.9, 0.85, 0.5),   # Banana
	]

	for i in range(num_ice_cream):
		var ice_cream = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		ice_cream.position = Vector3(x, 0, z)

		var scale = rng.randf_range(0.8, 2.0)

		# Cone (casquinha)
		var cone_mesh = CylinderMesh.new()
		cone_mesh.top_radius = 0.8 * scale
		cone_mesh.bottom_radius = 0.05 * scale
		cone_mesh.height = 2.5 * scale
		var cone_mat = StandardMaterial3D.new()
		cone_mat.albedo_color = Color(0.75, 0.6, 0.35)
		cone_mat.roughness = 0.7
		cone_mesh.surface_set_material(0, cone_mat)

		var cone_inst = MeshInstance3D.new()
		cone_inst.mesh = cone_mesh
		cone_inst.position.y = cone_mesh.height / 2.0
		ice_cream.add_child(cone_inst)

		# Bolas de sorvete
		var num_scoops = rng.randi_range(1, 3)
		for s in range(num_scoops):
			var scoop_mesh = SphereMesh.new()
			scoop_mesh.radius = rng.randf_range(0.6, 1.0) * scale
			scoop_mesh.height = scoop_mesh.radius * 2.0
			var scoop_mat = StandardMaterial3D.new()
			scoop_mat.albedo_color = ice_cream_colors[rng.randi() % ice_cream_colors.size()]
			scoop_mat.roughness = 0.4
			scoop_mesh.surface_set_material(0, scoop_mat)

			var scoop_inst = MeshInstance3D.new()
			scoop_inst.mesh = scoop_mesh
			scoop_inst.position.y = cone_mesh.height + scoop_mesh.radius * (s * 1.4 + 0.5)
			scoop_inst.position.x = rng.randf_range(-0.2, 0.2) * scale
			ice_cream.add_child(scoop_inst)

		add_child(ice_cream)

func _generate_candy_canes() -> void:
	var stripe_colors: Array[Color] = [
		Color(1.0, 0.1, 0.1),   # Vermelho
		Color(0.1, 0.8, 0.2),   # Verde
		Color(0.1, 0.3, 1.0),   # Azul
	]

	for i in range(num_candy_canes):
		var cane = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		cane.position = Vector3(x, 0, z)

		var height = rng.randf_range(2.5, 5.0)
		var stripe_color = stripe_colors[rng.randi() % stripe_colors.size()]

		# Bastao principal branco
		var stick_mesh = CylinderMesh.new()
		stick_mesh.top_radius = 0.15
		stick_mesh.bottom_radius = 0.15
		stick_mesh.height = height
		var stick_mat = StandardMaterial3D.new()
		stick_mat.albedo_color = Color(0.95, 0.95, 0.95)
		stick_mat.roughness = 0.3
		stick_mesh.surface_set_material(0, stick_mat)

		var stick_inst = MeshInstance3D.new()
		stick_inst.mesh = stick_mesh
		stick_inst.position.y = height / 2.0
		cane.add_child(stick_inst)

		# Faixas vermelhas (ou outra cor)
		var num_stripes = int(height / 0.6)
		for s in range(num_stripes):
			var stripe_mesh = CylinderMesh.new()
			stripe_mesh.top_radius = 0.17
			stripe_mesh.bottom_radius = 0.17
			stripe_mesh.height = 0.15
			var s_mat = StandardMaterial3D.new()
			s_mat.albedo_color = stripe_color
			s_mat.roughness = 0.3
			stripe_mesh.surface_set_material(0, s_mat)

			var stripe_inst = MeshInstance3D.new()
			stripe_inst.mesh = stripe_mesh
			stripe_inst.position.y = s * 0.6 + 0.3
			cane.add_child(stripe_inst)

		# Curva no topo
		var curve_mesh = SphereMesh.new()
		curve_mesh.radius = 0.2
		curve_mesh.height = 0.4
		var curve_mat = StandardMaterial3D.new()
		curve_mat.albedo_color = stripe_color
		curve_mat.roughness = 0.3
		curve_mesh.surface_set_material(0, curve_mat)

		var curve_inst = MeshInstance3D.new()
		curve_inst.mesh = curve_mesh
		curve_inst.position = Vector3(0.15, height + 0.1, 0)
		cane.add_child(curve_inst)

		add_child(cane)

func _generate_gummy_bears() -> void:
	var gummy_colors: Array[Color] = [
		Color(1.0, 0.1, 0.1, 0.8),   # Vermelho
		Color(0.1, 0.9, 0.1, 0.8),   # Verde
		Color(1.0, 0.8, 0.0, 0.8),   # Amarelo
		Color(1.0, 0.5, 0.0, 0.8),   # Laranja
		Color(0.9, 0.9, 0.9, 0.8),   # Branco
	]

	for i in range(num_gummy_bears):
		var bear = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		bear.position = Vector3(x, 0, z)

		var scale = rng.randf_range(0.5, 1.5)
		var color = gummy_colors[rng.randi() % gummy_colors.size()]

		# Corpo (esfera achatada)
		var body_mesh = SphereMesh.new()
		body_mesh.radius = 0.4 * scale
		body_mesh.height = 0.7 * scale
		var body_mat = StandardMaterial3D.new()
		body_mat.albedo_color = color
		body_mat.roughness = 0.2
		body_mat.metallic = 0.1
		body_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		body_mesh.surface_set_material(0, body_mat)

		var body_inst = MeshInstance3D.new()
		body_inst.mesh = body_mesh
		body_inst.position.y = 0.35 * scale
		bear.add_child(body_inst)

		# Cabeca
		var head_mesh = SphereMesh.new()
		head_mesh.radius = 0.25 * scale
		head_mesh.height = 0.3 * scale
		head_mesh.surface_set_material(0, body_mat)

		var head_inst = MeshInstance3D.new()
		head_inst.mesh = head_mesh
		head_inst.position.y = 0.75 * scale
		bear.add_child(head_inst)

		# Orelhas
		for side in [-1.0, 1.0]:
			var ear_mesh = SphereMesh.new()
			ear_mesh.radius = 0.1 * scale
			ear_mesh.height = 0.1 * scale
			ear_mesh.surface_set_material(0, body_mat)

			var ear_inst = MeshInstance3D.new()
			ear_inst.mesh = ear_mesh
			ear_inst.position = Vector3(side * 0.2 * scale, 0.9 * scale, 0)
			bear.add_child(ear_inst)

		add_child(bear)

func _generate_caramel_zones() -> void:
	for i in range(num_caramel_zones):
		var zone_node = Node3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		zone_node.position = Vector3(x, 0, z)

		var zone_size = rng.randf_range(6.0, 12.0)

		# Visual — caramel colored sticky floor
		var vis_mesh = BoxMesh.new()
		vis_mesh.size = Vector3(zone_size, 0.05, zone_size)
		var vis_mat = StandardMaterial3D.new()
		vis_mat.albedo_color = Color(0.7, 0.45, 0.1, 0.5)
		vis_mat.emission_enabled = true
		vis_mat.emission = Color(0.5, 0.3, 0.05)
		vis_mat.emission_energy_multiplier = 0.5
		vis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vis_mat.roughness = 0.1
		vis_mat.metallic = 0.3
		vis_mesh.surface_set_material(0, vis_mat)

		var vis_inst = MeshInstance3D.new()
		vis_inst.mesh = vis_mesh
		vis_inst.position.y = 0.03
		zone_node.add_child(vis_inst)

		# Area3D
		var area = Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 3  # Players + Enemies
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(zone_size, 2.0, zone_size)
		col.shape = shape
		col.position.y = 1.0
		area.add_child(col)
		zone_node.add_child(area)
		caramel_zones.append(area)

		add_child(zone_node)

func _generate_sprinkle_particles() -> void:
	var sprinkles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.5
	mat.gravity = Vector3(0, -0.3, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = Color(1.0, 0.5, 0.7, 0.7)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(50, 0.5, 50)

	sprinkles.process_material = mat
	sprinkles.amount = 60
	sprinkles.lifetime = 5.0
	sprinkles.visibility_aabb = AABB(Vector3(-60, -2, -60), Vector3(120, 15, 120))

	var draw_pass = BoxMesh.new()
	draw_pass.size = Vector3(0.02, 0.06, 0.02)
	var sprinkle_mat = StandardMaterial3D.new()
	sprinkle_mat.albedo_color = Color(1.0, 0.3, 0.5, 0.8)
	sprinkle_mat.emission_enabled = true
	sprinkle_mat.emission = Color(1.0, 0.5, 0.6)
	sprinkle_mat.emission_energy_multiplier = 1.5
	sprinkle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sprinkle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, sprinkle_mat)
	sprinkles.draw_pass_1 = draw_pass

	sprinkles.position = Vector3(0, 10.0, 0)
	add_child(sprinkles)

func _generate_ambient_lights() -> void:
	var light_colors: Array[Color] = [
		Color(1.0, 0.5, 0.7),   # Rosa
		Color(0.5, 0.9, 0.5),   # Verde claro
		Color(1.0, 0.9, 0.3),   # Amarelo
	]
	for i in range(10):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		light.position = Vector3(x, 2.5, z)
		light.light_color = light_colors[rng.randi() % light_colors.size()]
		light.light_energy = 0.5
		light.omni_range = 10.0
		light.omni_attenuation = 2.0
		add_child(light)
