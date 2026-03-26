extends Node3D

## Gera props aleatorios na Fazenda do Apocalipse: silos, milho, fardos, cercas, trator.

@export var num_silos: int = 3
@export var num_corn_stalks: int = 20
@export var num_hay_bales: int = 10
@export var num_fences: int = 5
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_generate_silos()
	_generate_corn_field()
	_generate_hay_bales()
	_generate_broken_fences()
	_generate_broken_tractor()
	_generate_ambient_lights()
	_generate_dust_particles()

func _generate_silos() -> void:
	for i in range(num_silos):
		var silo = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 10 and abs(z) < 10:
			x += 15.0
		silo.position = Vector3(x, 0, z)

		# Corpo do silo (cilindro alto)
		var body_mesh = CylinderMesh.new()
		body_mesh.top_radius = 1.5
		body_mesh.bottom_radius = 1.5
		body_mesh.height = 8.0
		var body_mat = StandardMaterial3D.new()
		body_mat.albedo_color = Color(0.55, 0.55, 0.5)
		body_mat.roughness = 0.85
		body_mat.metallic = 0.2
		body_mesh.surface_set_material(0, body_mat)

		var body = MeshInstance3D.new()
		body.mesh = body_mesh
		body.position.y = 4.0
		silo.add_child(body)

		# Topo do silo (cone)
		var top_mesh = CylinderMesh.new()
		top_mesh.top_radius = 0.1
		top_mesh.bottom_radius = 1.6
		top_mesh.height = 2.0
		var top_mat = StandardMaterial3D.new()
		top_mat.albedo_color = Color(0.4, 0.3, 0.25)
		top_mat.roughness = 0.9
		top_mesh.surface_set_material(0, top_mat)

		var top_part = MeshInstance3D.new()
		top_part.mesh = top_mesh
		top_part.position.y = 9.0
		silo.add_child(top_part)

		add_child(silo)

var corn_hide_area: Area3D = null

func _generate_corn_field() -> void:
	# Milho em fileiras
	var start_x = rng.randf_range(-30, -10)
	var start_z = rng.randf_range(-30, -10)
	var row_spacing = 2.0
	var col_spacing = 1.5
	var stalks_per_row = 5
	var num_rows = num_corn_stalks / stalks_per_row

	var stalk_mat = StandardMaterial3D.new()
	stalk_mat.albedo_color = Color(0.4, 0.55, 0.15)
	stalk_mat.roughness = 0.8

	var leaf_mat = StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.45, 0.6, 0.1)
	leaf_mat.roughness = 0.7

	for row in range(num_rows):
		for col in range(stalks_per_row):
			var stalk = Node3D.new()
			var x = start_x + col * col_spacing + rng.randf_range(-0.3, 0.3)
			var z = start_z + row * row_spacing + rng.randf_range(-0.3, 0.3)
			stalk.position = Vector3(x, 0, z)

			# Caule
			var stalk_mesh = CylinderMesh.new()
			var height = rng.randf_range(2.0, 3.5)
			stalk_mesh.top_radius = 0.03
			stalk_mesh.bottom_radius = 0.06
			stalk_mesh.height = height
			stalk_mesh.surface_set_material(0, stalk_mat)

			var stalk_inst = MeshInstance3D.new()
			stalk_inst.mesh = stalk_mesh
			stalk_inst.position.y = height / 2.0
			stalk.add_child(stalk_inst)

			# Folhas (boxes finos inclinados)
			for l in range(rng.randi_range(2, 3)):
				var leaf_mesh = BoxMesh.new()
				leaf_mesh.size = Vector3(0.6, 0.02, 0.15)
				leaf_mesh.surface_set_material(0, leaf_mat)
				var leaf = MeshInstance3D.new()
				leaf.mesh = leaf_mesh
				leaf.position.y = height * rng.randf_range(0.3, 0.8)
				leaf.rotation.z = rng.randf_range(-0.8, 0.8)
				leaf.rotation.y = rng.randf() * TAU
				stalk.add_child(leaf)

			add_child(stalk)

	# Create hiding zone over the cornfield
	corn_hide_area = Area3D.new()
	corn_hide_area.name = "CornHideZone"
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(stalks_per_row * col_spacing + 2.0, 4.0, num_rows * row_spacing + 2.0)
	col.shape = box
	corn_hide_area.add_child(col)
	corn_hide_area.collision_layer = 0
	corn_hide_area.collision_mask = 1  # Detect players
	var center_x = start_x + (stalks_per_row * col_spacing) / 2.0
	var center_z = start_z + (num_rows * row_spacing) / 2.0
	corn_hide_area.position = Vector3(center_x, 2.0, center_z)
	add_child(corn_hide_area)
	corn_hide_area.body_entered.connect(_on_corn_entered)
	corn_hide_area.body_exited.connect(_on_corn_exited)

func _on_corn_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		GameManager.player_hidden = true
		# Visual: make player semi-transparent
		if "mesh" in body:
			var mat = body.mesh.material_override
			if mat is ShaderMaterial:
				mat.set_shader_parameter("albedo_color", Color(body.original_color.r, body.original_color.g, body.original_color.b, 0.5))

func _on_corn_exited(body: Node3D) -> void:
	if body.is_in_group("players"):
		GameManager.player_hidden = false
		# Restore opacity
		if "mesh" in body:
			var mat = body.mesh.material_override
			if mat is ShaderMaterial:
				mat.set_shader_parameter("albedo_color", body.original_color)

func _generate_hay_bales() -> void:
	var hay_mat = StandardMaterial3D.new()
	hay_mat.albedo_color = Color(0.75, 0.65, 0.3)
	hay_mat.roughness = 0.95

	for i in range(num_hay_bales):
		var bale_mesh = BoxMesh.new()
		var is_round = rng.randf() < 0.4
		var bale: MeshInstance3D

		if is_round:
			# Fardo redondo
			var cyl_mesh = CylinderMesh.new()
			cyl_mesh.top_radius = 0.6
			cyl_mesh.bottom_radius = 0.6
			cyl_mesh.height = 0.8
			cyl_mesh.surface_set_material(0, hay_mat)
			bale = MeshInstance3D.new()
			bale.mesh = cyl_mesh
		else:
			# Fardo retangular
			bale_mesh.size = Vector3(
				rng.randf_range(0.8, 1.4),
				rng.randf_range(0.5, 0.8),
				rng.randf_range(0.6, 1.0)
			)
			bale_mesh.surface_set_material(0, hay_mat)
			bale = MeshInstance3D.new()
			bale.mesh = bale_mesh

		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		bale.position = Vector3(x, 0.4, z)
		bale.rotation.y = rng.randf() * TAU
		add_child(bale)

func _generate_broken_fences() -> void:
	var fence_mat = StandardMaterial3D.new()
	fence_mat.albedo_color = Color(0.35, 0.25, 0.15)
	fence_mat.roughness = 0.95

	for i in range(num_fences):
		var fence = Node3D.new()
		var x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		var z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		fence.position = Vector3(x, 0, z)
		fence.rotation.y = rng.randf() * TAU

		# Postes da cerca (2-3 verticais)
		var num_posts = rng.randi_range(2, 3)
		for p in range(num_posts):
			var post_mesh = BoxMesh.new()
			post_mesh.size = Vector3(0.1, rng.randf_range(0.6, 1.2), 0.1)
			post_mesh.surface_set_material(0, fence_mat)
			var post = MeshInstance3D.new()
			post.mesh = post_mesh
			post.position = Vector3(p * 1.5, post_mesh.size.y / 2.0, 0)
			# Alguns postes inclinados (quebrados)
			if rng.randf() < 0.4:
				post.rotation.z = rng.randf_range(-0.4, 0.4)
				post.rotation.x = rng.randf_range(-0.2, 0.2)
			fence.add_child(post)

		# Barras horizontais (algumas caidas)
		for b in range(rng.randi_range(1, 2)):
			var bar_mesh = BoxMesh.new()
			bar_mesh.size = Vector3(num_posts * 1.5, 0.06, 0.06)
			bar_mesh.surface_set_material(0, fence_mat)
			var bar = MeshInstance3D.new()
			bar.mesh = bar_mesh
			bar.position = Vector3((num_posts - 1) * 0.75, 0.3 + b * 0.35, 0)
			if rng.randf() < 0.3:
				bar.rotation.z = rng.randf_range(-0.2, 0.2)
			fence.add_child(bar)

		add_child(fence)

func _generate_broken_tractor() -> void:
	var tractor = Node3D.new()
	# Posicao fixa, longe do spawn
	tractor.position = Vector3(rng.randf_range(15, 25), 0, rng.randf_range(15, 25))
	tractor.rotation.y = rng.randf_range(0, TAU)

	var red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color(0.6, 0.15, 0.1)
	red_mat.roughness = 0.85

	var rust_mat = StandardMaterial3D.new()
	rust_mat.albedo_color = Color(0.45, 0.25, 0.1)
	rust_mat.roughness = 0.95

	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.15, 0.15, 0.15)
	dark_mat.roughness = 0.6
	dark_mat.metallic = 0.3

	# Corpo principal
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(2.0, 1.2, 3.5)
	body_mesh.surface_set_material(0, red_mat)
	var body = MeshInstance3D.new()
	body.mesh = body_mesh
	body.position = Vector3(0, 1.0, 0)
	tractor.add_child(body)

	# Capo (frente)
	var hood_mesh = BoxMesh.new()
	hood_mesh.size = Vector3(1.5, 0.8, 2.0)
	hood_mesh.surface_set_material(0, rust_mat)
	var hood = MeshInstance3D.new()
	hood.mesh = hood_mesh
	hood.position = Vector3(0, 0.7, -2.5)
	tractor.add_child(hood)

	# Cabine
	var cabin_mesh = BoxMesh.new()
	cabin_mesh.size = Vector3(1.8, 1.2, 1.5)
	cabin_mesh.surface_set_material(0, red_mat)
	var cabin = MeshInstance3D.new()
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 2.0, 0.5)
	# Cabine levemente torta (trator quebrado)
	cabin.rotation.z = 0.08
	tractor.add_child(cabin)

	# Rodas (cilindros)
	var wheel_positions = [
		Vector3(-1.2, 0.5, -1.5),  # Frente esquerda
		Vector3(1.2, 0.5, -1.5),   # Frente direita
		Vector3(-1.3, 0.7, 1.2),   # Tras esquerda (maior)
		Vector3(1.3, 0.7, 1.2),    # Tras direita (maior)
	]
	for w in range(wheel_positions.size()):
		var wheel_mesh = CylinderMesh.new()
		var is_back = w >= 2
		wheel_mesh.top_radius = 0.5 if is_back else 0.35
		wheel_mesh.bottom_radius = 0.5 if is_back else 0.35
		wheel_mesh.height = 0.3
		wheel_mesh.surface_set_material(0, dark_mat)
		var wheel = MeshInstance3D.new()
		wheel.mesh = wheel_mesh
		wheel.position = wheel_positions[w]
		wheel.rotation.z = PI / 2.0
		# Uma roda faltando/caida
		if w == 0:
			wheel.position.y = 0.2
			wheel.rotation.x = 0.5
		tractor.add_child(wheel)

	# Escapamento (cilindro fino vertical)
	var exhaust_mesh = CylinderMesh.new()
	exhaust_mesh.top_radius = 0.06
	exhaust_mesh.bottom_radius = 0.08
	exhaust_mesh.height = 1.5
	exhaust_mesh.surface_set_material(0, dark_mat)
	var exhaust = MeshInstance3D.new()
	exhaust.mesh = exhaust_mesh
	exhaust.position = Vector3(0.5, 2.0, -1.8)
	# Escapamento torto
	exhaust.rotation.z = 0.15
	tractor.add_child(exhaust)

	add_child(tractor)

func _generate_ambient_lights() -> void:
	var light_colors: Array[Color] = [
		Color(0.9, 0.7, 0.3),  # Amarelo quente
		Color(0.8, 0.5, 0.2),  # Laranja
	]
	for i in range(6):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		var z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		light.position = Vector3(x, 2.5, z)
		light.light_color = light_colors[rng.randi() % light_colors.size()]
		light.light_energy = 0.3
		light.omni_range = 10.0
		light.omni_attenuation = 2.0
		add_child(light)

func _generate_dust_particles() -> void:
	# Particulas de poeira flutuando
	var dust = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0.2, 0)
	mat.spread = 120.0
	mat.initial_velocity_min = 0.1
	mat.initial_velocity_max = 0.4
	mat.gravity = Vector3(0, -0.02, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.5
	mat.color = Color(0.6, 0.5, 0.3, 0.1)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(40, 1, 40)

	dust.process_material = mat
	dust.amount = 30
	dust.lifetime = 6.0
	dust.visibility_aabb = AABB(Vector3(-50, -1, -50), Vector3(100, 5, 100))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.3
	draw_pass.height = 0.15
	var dust_mat = StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.6, 0.5, 0.3, 0.08)
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, dust_mat)
	dust.draw_pass_1 = draw_pass

	dust.position = Vector3(0, 1.0, 0)
	add_child(dust)
