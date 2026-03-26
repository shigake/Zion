extends Node3D

## Gera props procedurais para Castelo do Vampiro: pilares goticos, candelabros,
## vitrais, caixoes. Areas escuras fortalecem inimigos; tochas criam zonas seguras.

@export var num_pillars: int = 30
@export var num_candelabras: int = 12
@export var num_stained_glass: int = 15
@export var num_coffins: int = 20
@export var num_dark_zones: int = 8
@export var num_torches: int = 10
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var dark_zones: Array[Area3D] = []
var torch_zones: Array[Area3D] = []
var dark_buff_timer: float = 0.0

func _ready() -> void:
	rng.randomize()
	_generate_gothic_pillars()
	_generate_candelabras()
	_generate_stained_glass()
	_generate_coffins()
	_generate_dark_zones()
	_generate_torches()
	_generate_fog_particles()

func _process(delta: float) -> void:
	dark_buff_timer += delta
	if dark_buff_timer < 1.0:
		return
	dark_buff_timer = 0.0

	# Check enemies in dark zones (not near torches) — 30% stronger
	for dark_area in dark_zones:
		if not is_instance_valid(dark_area):
			continue
		var bodies = dark_area.get_overlapping_bodies()
		for body in bodies:
			if not body.is_in_group("enemies"):
				continue
			# Check if enemy is also in a torch safe zone
			var in_safe_zone = false
			for torch_area in torch_zones:
				if not is_instance_valid(torch_area):
					continue
				if torch_area.get_overlapping_bodies().has(body):
					in_safe_zone = true
					break
			if not in_safe_zone and body.has_method("set_damage_multiplier"):
				body.set_damage_multiplier(1.3)
			elif in_safe_zone and body.has_method("set_damage_multiplier"):
				body.set_damage_multiplier(1.0)

func _generate_gothic_pillars() -> void:
	for i in range(num_pillars):
		var pillar = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		pillar.position = Vector3(x, 0, z)

		var height = rng.randf_range(4.0, 9.0)

		# Coluna gotica
		var col_mesh = CylinderMesh.new()
		col_mesh.top_radius = 0.25
		col_mesh.bottom_radius = 0.4
		col_mesh.height = height
		var col_mat = StandardMaterial3D.new()
		col_mat.albedo_color = Color(0.2, 0.18, 0.22)
		col_mat.roughness = 0.7
		col_mesh.surface_set_material(0, col_mat)

		var col_inst = MeshInstance3D.new()
		col_inst.mesh = col_mesh
		col_inst.position.y = height / 2.0
		pillar.add_child(col_inst)

		# Topo decorativo (ponta gotica)
		var top_mesh = CylinderMesh.new()
		top_mesh.top_radius = 0.0
		top_mesh.bottom_radius = 0.35
		top_mesh.height = 1.2
		var top_mat = StandardMaterial3D.new()
		top_mat.albedo_color = Color(0.15, 0.12, 0.18)
		top_mat.roughness = 0.6
		top_mesh.surface_set_material(0, top_mat)

		var top_inst = MeshInstance3D.new()
		top_inst.mesh = top_mesh
		top_inst.position.y = height + 0.6
		pillar.add_child(top_inst)

		add_child(pillar)

func _generate_candelabras() -> void:
	for i in range(num_candelabras):
		var cand = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 4 and abs(z) < 4:
			x += 7.0
		cand.position = Vector3(x, 0, z)

		# Poste principal
		var pole_mesh = CylinderMesh.new()
		pole_mesh.top_radius = 0.04
		pole_mesh.bottom_radius = 0.08
		pole_mesh.height = 1.8
		var pole_mat = StandardMaterial3D.new()
		pole_mat.albedo_color = Color(0.5, 0.4, 0.15)
		pole_mat.metallic = 0.7
		pole_mat.roughness = 0.3
		pole_mesh.surface_set_material(0, pole_mat)

		var pole_inst = MeshInstance3D.new()
		pole_inst.mesh = pole_mesh
		pole_inst.position.y = 0.9
		cand.add_child(pole_inst)

		# Base
		var base_mesh = CylinderMesh.new()
		base_mesh.top_radius = 0.15
		base_mesh.bottom_radius = 0.2
		base_mesh.height = 0.1
		base_mesh.surface_set_material(0, pole_mat)

		var base_inst = MeshInstance3D.new()
		base_inst.mesh = base_mesh
		base_inst.position.y = 0.05
		cand.add_child(base_inst)

		# Bracos com velas
		var num_arms = rng.randi_range(3, 5)
		for a in range(num_arms):
			var arm_angle = (float(a) / num_arms) * TAU
			var arm_length = 0.4

			# Braco
			var arm_mesh = CylinderMesh.new()
			arm_mesh.top_radius = 0.02
			arm_mesh.bottom_radius = 0.02
			arm_mesh.height = arm_length
			arm_mesh.surface_set_material(0, pole_mat)

			var arm_inst = MeshInstance3D.new()
			arm_inst.mesh = arm_mesh
			arm_inst.position = Vector3(cos(arm_angle) * arm_length / 2.0, 1.8, sin(arm_angle) * arm_length / 2.0)
			arm_inst.rotation.z = PI / 2.0
			arm_inst.rotation.y = arm_angle
			cand.add_child(arm_inst)

			# Vela
			var candle_mesh = CylinderMesh.new()
			candle_mesh.top_radius = 0.04
			candle_mesh.bottom_radius = 0.04
			candle_mesh.height = 0.2
			var candle_mat = StandardMaterial3D.new()
			candle_mat.albedo_color = Color(0.9, 0.85, 0.7)
			candle_mesh.surface_set_material(0, candle_mat)

			var candle_inst = MeshInstance3D.new()
			candle_inst.mesh = candle_mesh
			candle_inst.position = Vector3(cos(arm_angle) * arm_length, 1.9, sin(arm_angle) * arm_length)
			cand.add_child(candle_inst)

		# Luz do candelabro
		var light = OmniLight3D.new()
		light.position.y = 2.1
		light.light_color = Color(1.0, 0.7, 0.3)
		light.light_energy = 0.6
		light.omni_range = 6.0
		light.omni_attenuation = 2.0
		cand.add_child(light)

		add_child(cand)

func _generate_stained_glass() -> void:
	var glass_colors: Array[Color] = [
		Color(0.8, 0.1, 0.1, 0.5),   # Vermelho
		Color(0.1, 0.1, 0.8, 0.5),   # Azul
		Color(0.6, 0.1, 0.7, 0.5),   # Roxo
		Color(0.1, 0.7, 0.3, 0.5),   # Verde
		Color(0.9, 0.7, 0.1, 0.5),   # Dourado
	]

	for i in range(num_stained_glass):
		var glass = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		glass.position = Vector3(x, rng.randf_range(3.0, 6.0), z)

		var w = rng.randf_range(1.5, 3.0)
		var h = rng.randf_range(2.0, 4.0)

		# Moldura
		var frame_mesh = BoxMesh.new()
		frame_mesh.size = Vector3(w, h, 0.15)
		var frame_mat = StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.15, 0.1, 0.1)
		frame_mat.roughness = 0.8
		frame_mesh.surface_set_material(0, frame_mat)

		var frame_inst = MeshInstance3D.new()
		frame_inst.mesh = frame_mesh
		frame_inst.rotation.y = rng.randf_range(0, TAU)
		glass.add_child(frame_inst)

		# Vidro colorido
		var color = glass_colors[rng.randi() % glass_colors.size()]
		var pane_mesh = BoxMesh.new()
		pane_mesh.size = Vector3(w - 0.2, h - 0.2, 0.03)
		var pane_mat = StandardMaterial3D.new()
		pane_mat.albedo_color = color
		pane_mat.emission_enabled = true
		pane_mat.emission = Color(color.r, color.g, color.b)
		pane_mat.emission_energy_multiplier = 1.5
		pane_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pane_mesh.surface_set_material(0, pane_mat)

		var pane_inst = MeshInstance3D.new()
		pane_inst.mesh = pane_mesh
		pane_inst.rotation = frame_inst.rotation
		glass.add_child(pane_inst)

		add_child(glass)

func _generate_coffins() -> void:
	for i in range(num_coffins):
		var coffin = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		coffin.position = Vector3(x, 0, z)
		coffin.rotation.y = rng.randf_range(0, TAU)

		# Corpo do caixao
		var body_mesh = BoxMesh.new()
		body_mesh.size = Vector3(0.7, 0.4, 2.0)
		var body_mat = StandardMaterial3D.new()
		body_mat.albedo_color = Color(0.2, 0.12, 0.08)
		body_mat.roughness = 0.8
		body_mesh.surface_set_material(0, body_mat)

		var body_inst = MeshInstance3D.new()
		body_inst.mesh = body_mesh
		body_inst.position.y = 0.2
		coffin.add_child(body_inst)

		# Tampa (levemente levantada em alguns)
		var lid_mesh = BoxMesh.new()
		lid_mesh.size = Vector3(0.75, 0.08, 2.05)
		var lid_mat = StandardMaterial3D.new()
		lid_mat.albedo_color = Color(0.18, 0.1, 0.06)
		lid_mat.roughness = 0.7
		lid_mesh.surface_set_material(0, lid_mat)

		var lid_inst = MeshInstance3D.new()
		lid_inst.mesh = lid_mesh
		lid_inst.position.y = 0.44
		if rng.randi() % 3 == 0:
			# Tampa aberta
			lid_inst.rotation.z = rng.randf_range(0.3, 0.6)
			lid_inst.position.x += 0.2
		coffin.add_child(lid_inst)

		add_child(coffin)

func _generate_dark_zones() -> void:
	for i in range(num_dark_zones):
		var zone_node = Node3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		zone_node.position = Vector3(x, 0, z)

		var zone_size = rng.randf_range(10.0, 18.0)

		# Visual — dark floor patch
		var vis_mesh = BoxMesh.new()
		vis_mesh.size = Vector3(zone_size, 0.04, zone_size)
		var vis_mat = StandardMaterial3D.new()
		vis_mat.albedo_color = Color(0.05, 0.0, 0.1, 0.3)
		vis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vis_mesh.surface_set_material(0, vis_mat)

		var vis_inst = MeshInstance3D.new()
		vis_inst.mesh = vis_mesh
		vis_inst.position.y = 0.02
		zone_node.add_child(vis_inst)

		# Area3D
		var area = Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 2  # Enemies only
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(zone_size, 2.0, zone_size)
		col.shape = shape
		col.position.y = 1.0
		area.add_child(col)
		zone_node.add_child(area)
		dark_zones.append(area)

		add_child(zone_node)

func _generate_torches() -> void:
	for i in range(num_torches):
		var torch = Node3D.new()
		var x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		var z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		torch.position = Vector3(x, 0, z)

		# Poste
		var pole_mesh = CylinderMesh.new()
		pole_mesh.top_radius = 0.06
		pole_mesh.bottom_radius = 0.1
		pole_mesh.height = 2.0
		var pole_mat = StandardMaterial3D.new()
		pole_mat.albedo_color = Color(0.25, 0.15, 0.08)
		pole_mat.roughness = 0.9
		pole_mesh.surface_set_material(0, pole_mat)

		var pole_inst = MeshInstance3D.new()
		pole_inst.mesh = pole_mesh
		pole_inst.position.y = 1.0
		torch.add_child(pole_inst)

		# Chama
		var flame = GPUParticles3D.new()
		var flame_mat = ParticleProcessMaterial.new()
		flame_mat.direction = Vector3(0, 1, 0)
		flame_mat.spread = 12.0
		flame_mat.initial_velocity_min = 0.5
		flame_mat.initial_velocity_max = 1.2
		flame_mat.gravity = Vector3(0, 0.3, 0)
		flame_mat.scale_min = 0.05
		flame_mat.scale_max = 0.12
		flame_mat.color = Color(1.0, 0.6, 0.1, 0.9)

		flame.process_material = flame_mat
		flame.amount = 12
		flame.lifetime = 0.7
		flame.visibility_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 3, 2))

		var flame_draw = SphereMesh.new()
		flame_draw.radius = 0.06
		flame_draw.height = 0.1
		var flame_draw_mat = StandardMaterial3D.new()
		flame_draw_mat.albedo_color = Color(1.0, 0.7, 0.2, 0.8)
		flame_draw_mat.emission_enabled = true
		flame_draw_mat.emission = Color(1.0, 0.5, 0.0)
		flame_draw_mat.emission_energy_multiplier = 4.0
		flame_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		flame_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flame_draw.surface_set_material(0, flame_draw_mat)
		flame.draw_pass_1 = flame_draw

		flame.position.y = 2.1
		torch.add_child(flame)

		# Luz
		var light = OmniLight3D.new()
		light.position.y = 2.3
		light.light_color = Color(1.0, 0.7, 0.3)
		light.light_energy = 1.0
		light.omni_range = 10.0
		light.omni_attenuation = 2.0
		torch.add_child(light)

		# Safe zone area (cancels dark buff)
		var safe_area = Area3D.new()
		safe_area.collision_layer = 0
		safe_area.collision_mask = 2  # Enemies
		var safe_col = CollisionShape3D.new()
		var safe_shape = SphereShape3D.new()
		safe_shape.radius = 10.0
		safe_col.shape = safe_shape
		safe_col.position.y = 1.0
		safe_area.add_child(safe_col)
		torch.add_child(safe_area)
		torch_zones.append(safe_area)

		add_child(torch)

func _generate_fog_particles() -> void:
	var fog = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0.3, 0, 0.2)
	mat.spread = 60.0
	mat.initial_velocity_min = 0.1
	mat.initial_velocity_max = 0.4
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.5
	mat.color = Color(0.15, 0.1, 0.2, 0.15)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(50, 0.5, 50)

	fog.process_material = mat
	fog.amount = 40
	fog.lifetime = 8.0
	fog.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 5, 120))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.8
	draw_pass.height = 0.4
	var fog_mat = StandardMaterial3D.new()
	fog_mat.albedo_color = Color(0.2, 0.15, 0.25, 0.1)
	fog_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, fog_mat)
	fog.draw_pass_1 = draw_pass

	fog.position = Vector3(0, 0.5, 0)
	add_child(fog)
