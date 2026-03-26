extends Node3D

## Gera props aleatorios no cemiterio: lapides, arvores mortas, luzes.

@export var num_tombstones: int = 60
@export var num_trees: int = 25
@export var num_lights: int = 12
@export var num_coffins: int = 15
@export var num_open_coffins: int = 8
@export var num_holes: int = 12
@export var num_shovels: int = 10
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_generate_tombstones()
	_generate_dead_trees()
	_generate_coffins()
	_generate_open_coffins()
	_generate_holes()
	_generate_shovels()
	_generate_ambient_lights()
	_generate_ground_fog()

func _generate_tombstones() -> void:
	var tombstone_mesh = BoxMesh.new()
	tombstone_mesh.size = Vector3(0.4, 0.8, 0.15)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.35, 0.32)
	mat.roughness = 0.9
	tombstone_mesh.surface_set_material(0, mat)

	for i in range(num_tombstones):
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = tombstone_mesh
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		# Evita o centro (spawn do player)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		mesh_inst.position = Vector3(x, 0.4, z)
		mesh_inst.rotation.y = rng.randf() * TAU
		# Variacao de tamanho
		var s = rng.randf_range(0.7, 1.4)
		mesh_inst.scale = Vector3(s, s, s)
		add_child(mesh_inst)

func _generate_dead_trees() -> void:
	for i in range(num_trees):
		var tree = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 8 and abs(z) < 8:
			x += 12.0
		tree.position = Vector3(x, 0, z)

		# Tronco
		var trunk_mesh = CylinderMesh.new()
		trunk_mesh.top_radius = 0.08
		trunk_mesh.bottom_radius = 0.2
		trunk_mesh.height = rng.randf_range(2.0, 4.0)
		var trunk_mat = StandardMaterial3D.new()
		trunk_mat.albedo_color = Color(0.2, 0.15, 0.1)
		trunk_mesh.surface_set_material(0, trunk_mat)

		var trunk = MeshInstance3D.new()
		trunk.mesh = trunk_mesh
		trunk.position.y = trunk_mesh.height / 2.0
		tree.add_child(trunk)

		# Galhos (2-3 cilindros finos inclinados)
		for j in range(rng.randi_range(2, 4)):
			var branch_mesh = CylinderMesh.new()
			branch_mesh.top_radius = 0.02
			branch_mesh.bottom_radius = 0.06
			branch_mesh.height = rng.randf_range(0.8, 1.5)
			branch_mesh.surface_set_material(0, trunk_mat)

			var branch = MeshInstance3D.new()
			branch.mesh = branch_mesh
			branch.position.y = trunk_mesh.height * rng.randf_range(0.5, 0.9)
			branch.rotation.z = rng.randf_range(-1.0, 1.0)
			branch.rotation.x = rng.randf_range(-0.5, 0.5)
			tree.add_child(branch)

		add_child(tree)

func _generate_coffins() -> void:
	## Caixoes fechados espalhados pelo cemiterio
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.3, 0.18, 0.08)
	wood_mat.roughness = 0.85

	for i in range(num_coffins):
		var coffin = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		coffin.position = Vector3(x, 0, z)
		coffin.rotation.y = rng.randf() * TAU

		# Corpo do caixao (hexagonal simplificado como box)
		var body_mesh = BoxMesh.new()
		body_mesh.size = Vector3(0.6, 0.25, 1.8)
		body_mesh.surface_set_material(0, wood_mat)
		var body = MeshInstance3D.new()
		body.mesh = body_mesh
		body.position.y = 0.125
		coffin.add_child(body)

		# Tampa do caixao
		var lid_mesh = BoxMesh.new()
		lid_mesh.size = Vector3(0.65, 0.06, 1.85)
		var lid_mat = StandardMaterial3D.new()
		lid_mat.albedo_color = Color(0.25, 0.14, 0.06)
		lid_mat.roughness = 0.9
		lid_mesh.surface_set_material(0, lid_mat)
		var lid = MeshInstance3D.new()
		lid.mesh = lid_mesh
		lid.position.y = 0.28
		coffin.add_child(lid)

		# Cruz na tampa
		var cross_v = MeshInstance3D.new()
		var cv_mesh = BoxMesh.new()
		cv_mesh.size = Vector3(0.04, 0.07, 0.3)
		var cross_mat = StandardMaterial3D.new()
		cross_mat.albedo_color = Color(0.5, 0.45, 0.35)
		cv_mesh.surface_set_material(0, cross_mat)
		cross_v.mesh = cv_mesh
		cross_v.position = Vector3(0, 0.32, -0.3)
		coffin.add_child(cross_v)

		var cross_h = MeshInstance3D.new()
		var ch_mesh = BoxMesh.new()
		ch_mesh.size = Vector3(0.04, 0.07, 0.15)
		ch_mesh.surface_set_material(0, cross_mat)
		cross_h.mesh = ch_mesh
		cross_h.position = Vector3(0, 0.32, -0.35)
		cross_h.rotation.y = deg_to_rad(90)
		coffin.add_child(cross_h)

		add_child(coffin)

func _generate_open_coffins() -> void:
	## Caixoes abertos — tampa inclinada, interior visivel
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.28, 0.16, 0.07)
	wood_mat.roughness = 0.85
	var inner_mat = StandardMaterial3D.new()
	inner_mat.albedo_color = Color(0.15, 0.08, 0.04)

	for i in range(num_open_coffins):
		var coffin = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		coffin.position = Vector3(x, 0, z)
		coffin.rotation.y = rng.randf() * TAU

		# Corpo do caixao
		var body_mesh = BoxMesh.new()
		body_mesh.size = Vector3(0.6, 0.25, 1.8)
		body_mesh.surface_set_material(0, wood_mat)
		var body = MeshInstance3D.new()
		body.mesh = body_mesh
		body.position.y = 0.125
		coffin.add_child(body)

		# Interior escuro (um pouco menor)
		var inner_mesh = BoxMesh.new()
		inner_mesh.size = Vector3(0.5, 0.04, 1.7)
		inner_mesh.surface_set_material(0, inner_mat)
		var inner = MeshInstance3D.new()
		inner.mesh = inner_mesh
		inner.position.y = 0.24
		coffin.add_child(inner)

		# Tampa aberta (inclinada pra tras)
		var lid_mesh = BoxMesh.new()
		lid_mesh.size = Vector3(0.65, 0.06, 1.85)
		var lid_mat = StandardMaterial3D.new()
		lid_mat.albedo_color = Color(0.25, 0.14, 0.06)
		lid_mesh.surface_set_material(0, lid_mat)
		var lid = MeshInstance3D.new()
		lid.mesh = lid_mesh
		# Posiciona atras e inclinada
		lid.position = Vector3(0, 0.5, -0.85)
		lid.rotation.x = deg_to_rad(-60)
		coffin.add_child(lid)

		add_child(coffin)

func _generate_holes() -> void:
	## Buracos no chao — cilindros escuros rebaixados
	var hole_mat = StandardMaterial3D.new()
	hole_mat.albedo_color = Color(0.05, 0.03, 0.02)
	hole_mat.roughness = 1.0

	var dirt_mat = StandardMaterial3D.new()
	dirt_mat.albedo_color = Color(0.25, 0.18, 0.1)
	dirt_mat.roughness = 0.95

	for i in range(num_holes):
		var hole = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		hole.position = Vector3(x, 0, z)

		# Buraco escuro (cilindro raso)
		var hole_mesh = CylinderMesh.new()
		hole_mesh.top_radius = rng.randf_range(0.5, 0.8)
		hole_mesh.bottom_radius = hole_mesh.top_radius * 0.8
		hole_mesh.height = 0.05
		hole_mesh.surface_set_material(0, hole_mat)
		var hole_inst = MeshInstance3D.new()
		hole_inst.mesh = hole_mesh
		hole_inst.position.y = 0.01
		hole.add_child(hole_inst)

		# Montinho de terra ao lado
		var dirt_mesh = SphereMesh.new()
		dirt_mesh.radius = rng.randf_range(0.3, 0.5)
		dirt_mesh.height = dirt_mesh.radius * 0.8
		dirt_mesh.surface_set_material(0, dirt_mat)
		var dirt = MeshInstance3D.new()
		dirt.mesh = dirt_mesh
		dirt.position = Vector3(hole_mesh.top_radius + 0.3, dirt_mesh.height * 0.3, 0)
		dirt.scale = Vector3(1.0, 0.5, 1.0)
		hole.add_child(dirt)

		add_child(hole)

func _generate_shovels() -> void:
	## Pas fincadas no chao ou deitadas
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.35, 0.22, 0.1)
	handle_mat.roughness = 0.8
	var blade_mat = StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.4, 0.4, 0.38)
	blade_mat.roughness = 0.6
	blade_mat.metallic = 0.4

	for i in range(num_shovels):
		var shovel = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 6 and abs(z) < 6:
			x += 9.0
		shovel.position = Vector3(x, 0, z)
		shovel.rotation.y = rng.randf() * TAU

		# Cabo da pa
		var handle_mesh = CylinderMesh.new()
		handle_mesh.top_radius = 0.02
		handle_mesh.bottom_radius = 0.025
		handle_mesh.height = 1.2
		handle_mesh.surface_set_material(0, handle_mat)
		var handle = MeshInstance3D.new()
		handle.mesh = handle_mesh

		# Lamina da pa
		var blade_mesh = BoxMesh.new()
		blade_mesh.size = Vector3(0.2, 0.02, 0.25)
		blade_mesh.surface_set_material(0, blade_mat)
		var blade = MeshInstance3D.new()
		blade.mesh = blade_mesh

		if rng.randf() < 0.6:
			# Fincada no chao (inclinada)
			var tilt = rng.randf_range(5, 25)
			shovel.rotation.x = deg_to_rad(tilt)
			handle.position.y = 0.6
			blade.position.y = -0.02
		else:
			# Deitada no chao
			shovel.rotation.x = deg_to_rad(85)
			handle.position = Vector3(0, 0.03, 0.5)
			blade.position = Vector3(0, 0.03, -0.1)

		shovel.add_child(handle)
		shovel.add_child(blade)
		add_child(shovel)

func _generate_ambient_lights() -> void:
	# Luzes pontuais (tipo velas em lapides)
	for i in range(num_lights):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		light.position = Vector3(x, 1.5, z)
		light.light_color = Color(0.6, 0.75, 0.95)
		light.light_energy = 1.2
		light.omni_range = 16.0
		light.omni_attenuation = 2.0
		add_child(light)

func _generate_ground_fog() -> void:
	# Fog particles no chao
	var fog = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.5
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = Color(0.3, 0.35, 0.25, 0.15)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(30, 0.1, 30)

	fog.process_material = mat
	fog.amount = 40
	fog.lifetime = 8.0
	fog.visibility_aabb = AABB(Vector3(-50, -1, -50), Vector3(100, 3, 100))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 1.0
	draw_pass.height = 0.3
	var fog_mat = StandardMaterial3D.new()
	fog_mat.albedo_color = Color(0.3, 0.35, 0.25, 0.12)
	fog_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, fog_mat)
	fog.draw_pass_1 = draw_pass

	fog.position = Vector3(0, 0.3, 0)
	add_child(fog)
