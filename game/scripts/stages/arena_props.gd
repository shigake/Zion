extends Node3D

## Gera props procedurais para Arena Gladiadora: paredes do coliseu, portoes,
## pilares, tochas. Multidao joga itens aleatorios (cura ou dano).

@export var num_wall_segments: int = 24
@export var num_pillars: int = 20
@export var num_torches: int = 16
@export var num_gates: int = 4
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var crowd_timer: float = 0.0
var crowd_interval: float = 5.0

func _ready() -> void:
	rng.randomize()
	_generate_coliseum_walls()
	_generate_pillars()
	_generate_iron_gates()
	_generate_torches()
	_generate_sand_particles()

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	# Crowd throws items periodically
	crowd_timer += delta
	if crowd_timer >= crowd_interval:
		crowd_timer = 0.0
		crowd_interval = rng.randf_range(4.0, 8.0)
		_crowd_throw_item()

func _generate_coliseum_walls() -> void:
	var wall_radius = area_size * 0.85
	for i in range(num_wall_segments):
		var angle = (float(i) / num_wall_segments) * TAU
		var x = cos(angle) * wall_radius
		var z = sin(angle) * wall_radius

		var wall = Node3D.new()
		wall.position = Vector3(x, 0, z)
		wall.rotation.y = -angle + PI / 2.0

		# Parede principal
		var wall_mesh = BoxMesh.new()
		var wall_height = rng.randf_range(8.0, 12.0)
		var wall_width = (TAU * wall_radius) / num_wall_segments + 1.0
		wall_mesh.size = Vector3(wall_width, wall_height, 1.5)
		var wall_mat = StandardMaterial3D.new()
		wall_mat.albedo_color = Color(0.6, 0.5, 0.35)
		wall_mat.roughness = 0.9
		wall_mesh.surface_set_material(0, wall_mat)

		var wall_inst = MeshInstance3D.new()
		wall_inst.mesh = wall_mesh
		wall_inst.position.y = wall_height / 2.0
		wall.add_child(wall_inst)

		# Arcos decorativos na parede (a cada 3 segmentos)
		if i % 3 == 0:
			var arch_mesh = BoxMesh.new()
			arch_mesh.size = Vector3(wall_width * 0.4, 2.0, 0.3)
			var arch_mat = StandardMaterial3D.new()
			arch_mat.albedo_color = Color(0.5, 0.4, 0.3)
			arch_mat.roughness = 0.8
			arch_mesh.surface_set_material(0, arch_mat)

			var arch_inst = MeshInstance3D.new()
			arch_inst.mesh = arch_mesh
			arch_inst.position.y = wall_height - 1.5
			arch_inst.position.z = -0.7
			wall.add_child(arch_inst)

		add_child(wall)

func _generate_pillars() -> void:
	for i in range(num_pillars):
		var pillar = Node3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		pillar.position = Vector3(x, 0, z)

		var height = rng.randf_range(3.0, 7.0)

		# Coluna
		var col_mesh = CylinderMesh.new()
		col_mesh.top_radius = 0.35
		col_mesh.bottom_radius = 0.45
		col_mesh.height = height
		var col_mat = StandardMaterial3D.new()
		col_mat.albedo_color = Color(0.65, 0.55, 0.4)
		col_mat.roughness = 0.8
		col_mesh.surface_set_material(0, col_mat)

		var col_inst = MeshInstance3D.new()
		col_inst.mesh = col_mesh
		col_inst.position.y = height / 2.0
		pillar.add_child(col_inst)

		# Capitel (topo)
		var cap_mesh = BoxMesh.new()
		cap_mesh.size = Vector3(1.0, 0.3, 1.0)
		var cap_mat = StandardMaterial3D.new()
		cap_mat.albedo_color = Color(0.6, 0.5, 0.38)
		cap_mat.roughness = 0.7
		cap_mesh.surface_set_material(0, cap_mat)

		var cap_inst = MeshInstance3D.new()
		cap_inst.mesh = cap_mesh
		cap_inst.position.y = height + 0.15
		pillar.add_child(cap_inst)

		# Base
		var base_mesh = BoxMesh.new()
		base_mesh.size = Vector3(1.2, 0.25, 1.2)
		var base_mat = StandardMaterial3D.new()
		base_mat.albedo_color = Color(0.55, 0.45, 0.35)
		base_mat.roughness = 0.9
		base_mesh.surface_set_material(0, base_mat)

		var base_inst = MeshInstance3D.new()
		base_inst.mesh = base_mesh
		base_inst.position.y = 0.125
		pillar.add_child(base_inst)

		add_child(pillar)

func _generate_iron_gates() -> void:
	for i in range(num_gates):
		var angle = (float(i) / num_gates) * TAU
		var gate_radius = area_size * 0.6
		var x = cos(angle) * gate_radius
		var z = sin(angle) * gate_radius

		var gate = Node3D.new()
		gate.position = Vector3(x, 0, z)
		gate.rotation.y = -angle

		# Moldura do portao
		var frame_mesh = BoxMesh.new()
		frame_mesh.size = Vector3(4.0, 5.0, 0.5)
		var frame_mat = StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.3, 0.25, 0.2)
		frame_mat.roughness = 0.5
		frame_mat.metallic = 0.6
		frame_mesh.surface_set_material(0, frame_mat)

		var frame_inst = MeshInstance3D.new()
		frame_inst.mesh = frame_mesh
		frame_inst.position.y = 2.5
		gate.add_child(frame_inst)

		# Barras de ferro
		for b in range(5):
			var bar_mesh = CylinderMesh.new()
			bar_mesh.top_radius = 0.06
			bar_mesh.bottom_radius = 0.06
			bar_mesh.height = 4.5
			var bar_mat = StandardMaterial3D.new()
			bar_mat.albedo_color = Color(0.25, 0.22, 0.2)
			bar_mat.metallic = 0.8
			bar_mat.roughness = 0.3
			bar_mesh.surface_set_material(0, bar_mat)

			var bar_inst = MeshInstance3D.new()
			bar_inst.mesh = bar_mesh
			bar_inst.position = Vector3(-1.5 + b * 0.75, 2.5, 0)
			gate.add_child(bar_inst)

		add_child(gate)

func _generate_torches() -> void:
	for i in range(num_torches):
		var torch = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 4 and abs(z) < 4:
			x += 7.0
		torch.position = Vector3(x, 0, z)

		# Poste da tocha
		var pole_mesh = CylinderMesh.new()
		pole_mesh.top_radius = 0.05
		pole_mesh.bottom_radius = 0.08
		pole_mesh.height = 2.5
		var pole_mat = StandardMaterial3D.new()
		pole_mat.albedo_color = Color(0.3, 0.2, 0.1)
		pole_mat.roughness = 0.9
		pole_mesh.surface_set_material(0, pole_mat)

		var pole_inst = MeshInstance3D.new()
		pole_inst.mesh = pole_mesh
		pole_inst.position.y = 1.25
		torch.add_child(pole_inst)

		# Chama (particulas)
		var flame = GPUParticles3D.new()
		var flame_mat = ParticleProcessMaterial.new()
		flame_mat.direction = Vector3(0, 1, 0)
		flame_mat.spread = 15.0
		flame_mat.initial_velocity_min = 0.5
		flame_mat.initial_velocity_max = 1.5
		flame_mat.gravity = Vector3(0, 0.5, 0)
		flame_mat.scale_min = 0.05
		flame_mat.scale_max = 0.15
		flame_mat.color = Color(1.0, 0.6, 0.1, 0.9)

		flame.process_material = flame_mat
		flame.amount = 15
		flame.lifetime = 0.8
		flame.visibility_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 3, 2))

		var flame_draw = SphereMesh.new()
		flame_draw.radius = 0.08
		flame_draw.height = 0.12
		var flame_draw_mat = StandardMaterial3D.new()
		flame_draw_mat.albedo_color = Color(1.0, 0.7, 0.2, 0.8)
		flame_draw_mat.emission_enabled = true
		flame_draw_mat.emission = Color(1.0, 0.5, 0.0)
		flame_draw_mat.emission_energy_multiplier = 4.0
		flame_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		flame_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flame_draw.surface_set_material(0, flame_draw_mat)
		flame.draw_pass_1 = flame_draw

		flame.position.y = 2.6
		torch.add_child(flame)

		# Point light
		var light = OmniLight3D.new()
		light.position.y = 2.8
		light.light_color = Color(1.0, 0.7, 0.3)
		light.light_energy = 0.8
		light.omni_range = 8.0
		light.omni_attenuation = 2.0
		torch.add_child(light)

		add_child(torch)

func _generate_sand_particles() -> void:
	var sand = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 1.0
	mat.gravity = Vector3(0, -0.5, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = Color(0.8, 0.7, 0.5, 0.3)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(40, 0.5, 40)

	sand.process_material = mat
	sand.amount = 50
	sand.lifetime = 4.0
	sand.visibility_aabb = AABB(Vector3(-50, -1, -50), Vector3(100, 5, 100))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.04
	draw_pass.height = 0.04
	var sand_mat = StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.8, 0.7, 0.5, 0.3)
	sand_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sand_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, sand_mat)
	sand.draw_pass_1 = draw_pass

	sand.position = Vector3(0, 0.5, 0)
	add_child(sand)

func _crowd_throw_item() -> void:
	# Find player position
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var player = players[0]
	var target_pos = player.global_position + Vector3(
		rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8)
	)

	var is_heal = rng.randi() % 2 == 0

	var item = Node3D.new()
	item.position = Vector3(target_pos.x, 10.0, target_pos.z)

	# Visual
	var item_mesh = SphereMesh.new()
	item_mesh.radius = 0.4
	item_mesh.height = 0.4
	var item_mat = StandardMaterial3D.new()
	if is_heal:
		item_mat.albedo_color = Color(0.2, 1.0, 0.3)
		item_mat.emission_enabled = true
		item_mat.emission = Color(0.1, 0.8, 0.2)
		item_mat.emission_energy_multiplier = 2.0
	else:
		item_mat.albedo_color = Color(1.0, 0.2, 0.1)
		item_mat.emission_enabled = true
		item_mat.emission = Color(0.8, 0.1, 0.0)
		item_mat.emission_energy_multiplier = 2.0
	item_mesh.surface_set_material(0, item_mat)

	var item_inst = MeshInstance3D.new()
	item_inst.mesh = item_mesh
	item.add_child(item_inst)

	add_child(item)

	# Animate falling
	var tween = create_tween()
	tween.tween_property(item, "position:y", 0.3, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		# Apply effect in area
		var effect_area = Area3D.new()
		effect_area.collision_layer = 0
		effect_area.collision_mask = 3
		var col = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 3.0
		col.shape = shape
		effect_area.add_child(col)
		item.add_child(effect_area)

		# Wait one frame for physics
		await get_tree().process_frame
		await get_tree().process_frame

		var bodies = effect_area.get_overlapping_bodies()
		for body in bodies:
			if is_heal:
				if body.is_in_group("players"):
					GameManager.heal(15)
			else:
				if body.has_method("take_damage"):
					body.take_damage(15)

		# Cleanup after 1 second
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(item):
			item.queue_free()
	)
