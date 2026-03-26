extends Node3D

## Gera props aleatorios na Floresta Encantada: cogumelos gigantes, arvores, rio brilhante, particulas.

@export var num_mushrooms: int = 40
@export var num_trees: int = 30
@export var num_river_segments: int = 15
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var cap_colors: Array[Color] = [
	Color(0.8, 0.1, 0.1),   # Vermelho
	Color(0.2, 0.2, 0.9),   # Azul
	Color(0.6, 0.1, 0.7),   # Roxo
	Color(0.9, 0.2, 0.5),   # Rosa
	Color(0.1, 0.6, 0.8),   # Ciano
]

var buff_mushrooms: Array = []

func _ready() -> void:
	rng.randomize()
	_generate_mushrooms()
	_generate_trees()
	_generate_river()
	_generate_sparkles()
	_generate_ambient_lights()

func _generate_mushrooms() -> void:
	for i in range(num_mushrooms):
		var mushroom = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		mushroom.position = Vector3(x, 0, z)

		var scale_factor = rng.randf_range(0.6, 1.8)

		# Tronco do cogumelo
		var trunk_mesh = CylinderMesh.new()
		trunk_mesh.top_radius = 0.15 * scale_factor
		trunk_mesh.bottom_radius = 0.25 * scale_factor
		trunk_mesh.height = rng.randf_range(1.0, 2.5) * scale_factor
		var trunk_mat = StandardMaterial3D.new()
		trunk_mat.albedo_color = Color(0.85, 0.82, 0.7)
		trunk_mat.roughness = 0.8
		trunk_mesh.surface_set_material(0, trunk_mat)

		var trunk = MeshInstance3D.new()
		trunk.mesh = trunk_mesh
		trunk.position.y = trunk_mesh.height / 2.0
		mushroom.add_child(trunk)

		# Chapeu do cogumelo (esfera achatada)
		var cap_mesh = SphereMesh.new()
		cap_mesh.radius = 0.6 * scale_factor
		cap_mesh.height = 0.5 * scale_factor
		var cap_mat = StandardMaterial3D.new()
		cap_mat.albedo_color = cap_colors[rng.randi() % cap_colors.size()]
		cap_mat.roughness = 0.5
		cap_mat.emission_enabled = true
		cap_mat.emission = cap_mat.albedo_color * 0.3
		cap_mat.emission_energy_multiplier = 0.5
		cap_mesh.surface_set_material(0, cap_mat)

		var cap = MeshInstance3D.new()
		cap.mesh = cap_mesh
		cap.position.y = trunk_mesh.height + 0.1 * scale_factor
		mushroom.add_child(cap)

		add_child(mushroom)

		# Every 4th mushroom is interactive (gives buff)
		if i % 4 == 0:
			var area = Area3D.new()
			area.name = "BuffArea"
			var col = CollisionShape3D.new()
			var shape = SphereShape3D.new()
			shape.radius = 1.5
			col.shape = shape
			area.add_child(col)
			area.collision_layer = 0
			area.collision_mask = 1  # Detect players
			mushroom.add_child(area)
			mushroom.add_to_group("buff_mushrooms")
			buff_mushrooms.append(mushroom)
			area.body_entered.connect(_on_buff_mushroom_entered.bind(mushroom))
			# Make buff mushrooms glow brighter
			cap.material_override = cap_mat
			cap_mat.emission_energy_multiplier = 2.0

func _generate_trees() -> void:
	for i in range(num_trees):
		var tree = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 8 and abs(z) < 8:
			x += 12.0
		tree.position = Vector3(x, 0, z)

		var height = rng.randf_range(4.0, 7.0)

		# Tronco alto
		var trunk_mesh = CylinderMesh.new()
		trunk_mesh.top_radius = 0.15
		trunk_mesh.bottom_radius = 0.35
		trunk_mesh.height = height
		var trunk_mat = StandardMaterial3D.new()
		trunk_mat.albedo_color = Color(0.25, 0.18, 0.1)
		trunk_mat.roughness = 0.9
		trunk_mesh.surface_set_material(0, trunk_mat)

		var trunk = MeshInstance3D.new()
		trunk.mesh = trunk_mesh
		trunk.position.y = height / 2.0
		tree.add_child(trunk)

		# Copa verde (esfera grande)
		var canopy_mesh = SphereMesh.new()
		var canopy_radius = rng.randf_range(1.5, 3.0)
		canopy_mesh.radius = canopy_radius
		canopy_mesh.height = canopy_radius * 1.6
		var canopy_mat = StandardMaterial3D.new()
		var green_val = rng.randf_range(0.3, 0.6)
		canopy_mat.albedo_color = Color(0.05, green_val, 0.1)
		canopy_mat.roughness = 0.7
		canopy_mesh.surface_set_material(0, canopy_mat)

		var canopy = MeshInstance3D.new()
		canopy.mesh = canopy_mesh
		canopy.position.y = height + canopy_radius * 0.3
		tree.add_child(canopy)

		add_child(tree)

func _generate_river() -> void:
	# Rio sinuoso no chao com segmentos brilhantes azuis
	var river_x = rng.randf_range(-20, 20)
	var segment_length = 12.0

	for i in range(num_river_segments):
		var seg_mesh = BoxMesh.new()
		seg_mesh.size = Vector3(rng.randf_range(2.5, 4.0), 0.05, segment_length)
		var seg_mat = StandardMaterial3D.new()
		seg_mat.albedo_color = Color(0.1, 0.3, 0.8, 0.7)
		seg_mat.emission_enabled = true
		seg_mat.emission = Color(0.05, 0.2, 0.6)
		seg_mat.emission_energy_multiplier = 1.5
		seg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		seg_mat.roughness = 0.1
		seg_mat.metallic = 0.3
		seg_mesh.surface_set_material(0, seg_mat)

		var seg = MeshInstance3D.new()
		seg.mesh = seg_mesh
		river_x += rng.randf_range(-5, 5)
		river_x = clampf(river_x, -40, 40)
		var z_pos = -area_size + i * segment_length
		seg.position = Vector3(river_x, 0.02, z_pos)
		seg.rotation.y = rng.randf_range(-0.3, 0.3)
		add_child(seg)

func _generate_sparkles() -> void:
	# Particulas brilhantes flutuando para cima — efeito magico
	var sparkles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 0.8
	mat.gravity = Vector3(0, -0.05, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.3
	mat.color = Color(0.5, 0.9, 0.4, 0.8)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(50, 0.5, 50)

	sparkles.process_material = mat
	sparkles.amount = 60
	sparkles.lifetime = 5.0
	sparkles.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 15, 120))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.08
	draw_pass.height = 0.08
	var sparkle_mat = StandardMaterial3D.new()
	sparkle_mat.albedo_color = Color(0.6, 1.0, 0.4, 0.9)
	sparkle_mat.emission_enabled = true
	sparkle_mat.emission = Color(0.4, 0.9, 0.3)
	sparkle_mat.emission_energy_multiplier = 3.0
	sparkle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sparkle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, sparkle_mat)
	sparkles.draw_pass_1 = draw_pass

	sparkles.position = Vector3(0, 1.0, 0)
	add_child(sparkles)

func _on_buff_mushroom_entered(body: Node3D, mushroom: Node3D) -> void:
	if not body.is_in_group("players"):
		return
	if not is_instance_valid(mushroom) or not mushroom.is_inside_tree():
		return

	# Pick random buff
	var buff = rng.randi() % 3
	match buff:
		0:  # Speed boost +30% for 10s
			GameManager.speed_mult += 0.3
			get_tree().create_timer(10.0).timeout.connect(func():
				GameManager.speed_mult -= 0.3
			)
		1:  # Damage boost +20% for 10s
			GameManager.perm_damage_mult += 0.2
			get_tree().create_timer(10.0).timeout.connect(func():
				GameManager.perm_damage_mult -= 0.2
			)
		2:  # Heal 20 HP
			GameManager.heal(20)

	AudioManager.play_sfx("collect_xp")
	# Shrink and disappear
	var tween = create_tween()
	tween.tween_property(mushroom, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(mushroom.queue_free)

func _generate_ambient_lights() -> void:
	# Luzes pontuais com tons magicos
	var light_colors: Array[Color] = [
		Color(0.2, 0.8, 0.3),   # Verde
		Color(0.3, 0.3, 0.9),   # Azul
		Color(0.6, 0.2, 0.8),   # Roxo
	]
	for i in range(10):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		light.position = Vector3(x, 2.0, z)
		light.light_color = light_colors[rng.randi() % light_colors.size()]
		light.light_energy = 0.5
		light.omni_range = 10.0
		light.omni_attenuation = 2.0
		add_child(light)
