extends Node3D

## Gera props aleatorios no cemiterio: lapides, arvores mortas, luzes.

@export var num_tombstones: int = 60
@export var num_trees: int = 25
@export var num_lights: int = 12
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_generate_tombstones()
	_generate_dead_trees()
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
