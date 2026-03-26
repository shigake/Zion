extends Node3D

## Gera props procedurais para Estacao Espacial estilo BotW: corredores metalicos com portas,
## janelas com campo estelar, tubulacoes, consoles, sala de controle, criopods, containers de carga,
## displays holograficos, secoes danificadas. Zonas de gravidade zero aumentam velocidade em 50%.

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
	_generate_control_room()
	_generate_cryopods()
	_generate_cargo_containers()
	_generate_holographic_displays()
	_generate_damaged_sections()
	_generate_ambient_lights()
	_generate_star_particles()
	_generate_nebula_clouds()
	_add_real_models()

func _add_real_models() -> void:
	## Adiciona modelos Kenney — rochas flutuantes no espaco
	ModelFactory.scatter_nature_props(self, "rock_large", 15, area_size, Vector2(1.0, 3.0), rng.randf_range(-5.0, 5.0))
	ModelFactory.scatter_nature_props(self, "rock_tall", 10, area_size, Vector2(1.0, 2.5), rng.randf_range(-3.0, 3.0))
	ModelFactory.scatter_nature_props(self, "stone_large", 10, area_size, Vector2(1.0, 2.0), rng.randf_range(-4.0, 4.0))
	ModelFactory.scatter_dungeon_props(self, "dungeon_column", 8, area_size, Vector2(1.5, 2.0))
	ModelFactory.scatter_dungeon_props(self, "dungeon_barrel", 6, area_size, Vector2(1.0, 1.5))

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

## ---- CORREDORES METALICOS COM PORTAS E FAIXAS ----
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

		## Parede metalica
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

		## Faixa de luz no topo
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

		## Painel lateral decorativo
		var panel_mesh = BoxMesh.new()
		panel_mesh.size = Vector3(0.08, height * 0.6, depth * 0.8)
		var panel_mat = StandardMaterial3D.new()
		panel_mat.albedo_color = Color(0.38, 0.4, 0.43)
		panel_mat.metallic = 0.85
		panel_mat.roughness = 0.25
		panel_mesh.surface_set_material(0, panel_mat)

		var panel_inst = MeshInstance3D.new()
		panel_inst.mesh = panel_mesh
		panel_inst.position = Vector3(width / 2.0 + 0.04, height * 0.4, 0)
		corridor.add_child(panel_inst)

		## Molduras de portas (a cada 3 corredores)
		if i % 3 == 0:
			var door_frame = Node3D.new()

			## Pilar esquerdo da porta
			var dl_mesh = BoxMesh.new()
			dl_mesh.size = Vector3(0.15, 2.8, 0.2)
			var door_mat = StandardMaterial3D.new()
			door_mat.albedo_color = Color(0.35, 0.37, 0.4)
			door_mat.metallic = 0.9
			door_mat.roughness = 0.2
			dl_mesh.surface_set_material(0, door_mat)

			var dl_inst = MeshInstance3D.new()
			dl_inst.mesh = dl_mesh
			dl_inst.position = Vector3(-width * 0.35, 1.4, depth / 2.0 + 0.15)
			door_frame.add_child(dl_inst)

			## Pilar direito da porta
			var dr_inst = MeshInstance3D.new()
			dr_inst.mesh = dl_mesh
			dr_inst.position = Vector3(width * 0.35, 1.4, depth / 2.0 + 0.15)
			door_frame.add_child(dr_inst)

			## Verga da porta (topo)
			var dt_mesh = BoxMesh.new()
			dt_mesh.size = Vector3(width * 0.7 + 0.15, 0.15, 0.2)
			dt_mesh.surface_set_material(0, door_mat)

			var dt_inst = MeshInstance3D.new()
			dt_inst.mesh = dt_mesh
			dt_inst.position = Vector3(0, 2.85, depth / 2.0 + 0.15)
			door_frame.add_child(dt_inst)

			corridor.add_child(door_frame)

		## Faixas de cautela amarelo/preto (a cada 4 corredores)
		if i % 4 == 0:
			for s in range(3):
				var caution_mesh = BoxMesh.new()
				caution_mesh.size = Vector3(width * 0.12, 0.08, depth + 0.1)
				var caution_mat = StandardMaterial3D.new()
				if s % 2 == 0:
					caution_mat.albedo_color = Color(0.9, 0.75, 0.0)
				else:
					caution_mat.albedo_color = Color(0.1, 0.1, 0.1)
				caution_mat.roughness = 0.6
				caution_mesh.surface_set_material(0, caution_mat)

				var caution_inst = MeshInstance3D.new()
				caution_inst.mesh = caution_mesh
				caution_inst.position = Vector3(
					-width * 0.2 + s * width * 0.12,
					0.05,
					0
				)
				corridor.add_child(caution_inst)

		add_child(corridor)

## ---- JANELAS COM CAMPO ESTELAR E PLANETAS ----
func _generate_windows() -> void:
	for i in range(num_windows):
		var window = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		window.position = Vector3(x, rng.randf_range(2.0, 4.0), z)

		var w = rng.randf_range(2.0, 4.0)
		var h = rng.randf_range(1.5, 2.5)

		## Moldura metalica
		var frame_mesh = BoxMesh.new()
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

		## Vidro — azul escuro emissivo (estrelas)
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

		## Estrelas atras da janela (pequenos pontos emissivos)
		var rot_y = frame_inst.rotation.y
		for s in range(rng.randi_range(3, 7)):
			var star_mesh = SphereMesh.new()
			star_mesh.radius = rng.randf_range(0.02, 0.06)
			star_mesh.height = star_mesh.radius * 2.0
			var star_mat = StandardMaterial3D.new()
			star_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
			star_mat.emission_enabled = true
			star_mat.emission = Color(0.9, 0.9, 1.0)
			star_mat.emission_energy_multiplier = 4.0
			star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			star_mesh.surface_set_material(0, star_mat)

			var star_inst = MeshInstance3D.new()
			star_inst.mesh = star_mesh
			## Posiciona atras do vidro no referencial da janela
			var sx = rng.randf_range(-w * 0.35, w * 0.35)
			var sy = rng.randf_range(-h * 0.3, h * 0.3)
			var local_offset = Vector3(sx, sy, -0.15)
			## Rota pelo mesmo angulo da moldura
			var rotated = local_offset.rotated(Vector3.UP, rot_y)
			star_inst.position = rotated
			window.add_child(star_inst)

		## Planeta/nebula atras de algumas janelas (20% de chance)
		if rng.randi() % 5 == 0:
			var planet_mesh = SphereMesh.new()
			planet_mesh.radius = rng.randf_range(0.4, 0.8)
			planet_mesh.height = planet_mesh.radius * 2.0
			var planet_mat = StandardMaterial3D.new()
			var planet_colors: Array[Color] = [
				Color(0.2, 0.4, 0.8, 0.5),
				Color(0.8, 0.3, 0.2, 0.4),
				Color(0.3, 0.7, 0.4, 0.45),
				Color(0.6, 0.3, 0.7, 0.4),
			]
			var pc = planet_colors[rng.randi() % planet_colors.size()]
			planet_mat.albedo_color = pc
			planet_mat.emission_enabled = true
			planet_mat.emission = Color(pc.r, pc.g, pc.b)
			planet_mat.emission_energy_multiplier = 2.0
			planet_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			planet_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			planet_mesh.surface_set_material(0, planet_mat)

			var planet_inst = MeshInstance3D.new()
			planet_inst.mesh = planet_mesh
			var p_offset = Vector3(
				rng.randf_range(-0.3, 0.3),
				rng.randf_range(-0.2, 0.2),
				-0.3
			).rotated(Vector3.UP, rot_y)
			planet_inst.position = p_offset
			window.add_child(planet_inst)

		add_child(window)

## ---- TUBULACOES ----
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

		## Juntas nos tubos (a cada 2)
		if i % 2 == 0:
			var joint_mesh = CylinderMesh.new()
			joint_mesh.top_radius = pipe_mesh.top_radius + 0.03
			joint_mesh.bottom_radius = joint_mesh.top_radius
			joint_mesh.height = 0.12
			var joint_mat = StandardMaterial3D.new()
			joint_mat.albedo_color = Color(0.35, 0.37, 0.4)
			joint_mat.metallic = 0.95
			joint_mat.roughness = 0.15
			joint_mesh.surface_set_material(0, joint_mat)

			var joint_inst = MeshInstance3D.new()
			joint_inst.mesh = joint_mesh
			joint_inst.rotation = pipe_inst.rotation
			pipe.add_child(joint_inst)

		add_child(pipe)

## ---- CONSOLES ----
func _generate_consoles() -> void:
	for i in range(num_consoles):
		var console = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 4 and abs(z) < 4:
			x += 7.0
		console.position = Vector3(x, 0, z)

		## Base do console
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

		## Tela do console
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

		## Botoes no painel (pequenas caixas coloridas)
		for b in range(rng.randi_range(2, 4)):
			var btn_mesh = BoxMesh.new()
			btn_mesh.size = Vector3(0.06, 0.04, 0.04)
			var btn_mat = StandardMaterial3D.new()
			var btn_colors: Array[Color] = [
				Color(0.9, 0.2, 0.1),
				Color(0.1, 0.8, 0.2),
				Color(0.9, 0.8, 0.1),
			]
			btn_mat.albedo_color = btn_colors[rng.randi() % btn_colors.size()]
			btn_mat.emission_enabled = true
			btn_mat.emission = btn_mat.albedo_color
			btn_mat.emission_energy_multiplier = 1.5
			btn_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			btn_mesh.surface_set_material(0, btn_mat)

			var btn_inst = MeshInstance3D.new()
			btn_inst.mesh = btn_mesh
			btn_inst.position = Vector3(
				-0.25 + b * 0.15,
				0.82,
				-0.1
			)
			console.add_child(btn_inst)

		console.rotation.y = rng.randf_range(0, TAU)
		add_child(console)

## ---- ZONAS DE GRAVIDADE ZERO (SPEED BOOST) ----
func _generate_zero_g_zones() -> void:
	for i in range(num_zero_g_zones):
		var zone_node = Node3D.new()
		var x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		var z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		zone_node.position = Vector3(x, 0, z)

		var zone_size = rng.randf_range(8.0, 14.0)

		## Visual — painel de chao brilhante
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

		## Borda da zona (moldura fina)
		var border_mesh = BoxMesh.new()
		border_mesh.size = Vector3(zone_size + 0.2, 0.08, zone_size + 0.2)
		var border_mat = StandardMaterial3D.new()
		border_mat.albedo_color = Color(0.3, 0.7, 1.0, 0.3)
		border_mat.emission_enabled = true
		border_mat.emission = Color(0.2, 0.5, 0.9)
		border_mat.emission_energy_multiplier = 2.5
		border_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		border_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		border_mesh.surface_set_material(0, border_mat)

		var border_inst = MeshInstance3D.new()
		border_inst.mesh = border_mesh
		border_inst.position.y = 0.02
		zone_node.add_child(border_inst)

		## Area3D para deteccao de colisao
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

## ---- SALA DE CONTROLE ----
func _generate_control_room() -> void:
	var room = Node3D.new()
	room.position = Vector3(
		rng.randf_range(-area_size * 0.3, area_size * 0.3),
		0,
		rng.randf_range(20, 35)
	)
	room.rotation.y = rng.randf_range(0, TAU)

	## Estrutura principal (caixa grande)
	var main_mesh = BoxMesh.new()
	main_mesh.size = Vector3(8.0, 4.5, 6.0)
	var main_mat = StandardMaterial3D.new()
	main_mat.albedo_color = Color(0.4, 0.43, 0.46)
	main_mat.metallic = 0.85
	main_mat.roughness = 0.25
	main_mesh.surface_set_material(0, main_mat)

	var main_inst = MeshInstance3D.new()
	main_inst.mesh = main_mesh
	main_inst.position.y = 2.25
	room.add_child(main_inst)

	## Faixa de luz no topo
	var top_strip_mesh = BoxMesh.new()
	top_strip_mesh.size = Vector3(8.1, 0.12, 6.1)
	var top_strip_mat = StandardMaterial3D.new()
	top_strip_mat.albedo_color = Color(0.3, 0.7, 1.0)
	top_strip_mat.emission_enabled = true
	top_strip_mat.emission = Color(0.2, 0.5, 0.9)
	top_strip_mat.emission_energy_multiplier = 2.5
	top_strip_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	top_strip_mesh.surface_set_material(0, top_strip_mat)

	var top_strip_inst = MeshInstance3D.new()
	top_strip_inst.mesh = top_strip_mesh
	top_strip_inst.position.y = 4.55
	room.add_child(top_strip_inst)

	## Telas de console internas (3 telas no fundo)
	for s in range(3):
		var scr_mesh = BoxMesh.new()
		scr_mesh.size = Vector3(1.8, 1.2, 0.06)
		var scr_mat = StandardMaterial3D.new()
		var scr_colors: Array[Color] = [
			Color(0.0, 0.7, 0.3),
			Color(0.3, 0.5, 1.0),
			Color(0.9, 0.6, 0.0),
		]
		scr_mat.albedo_color = scr_colors[s]
		scr_mat.emission_enabled = true
		scr_mat.emission = scr_colors[s]
		scr_mat.emission_energy_multiplier = 2.5
		scr_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		scr_mesh.surface_set_material(0, scr_mat)

		var scr_inst = MeshInstance3D.new()
		scr_inst.mesh = scr_mesh
		scr_inst.position = Vector3(-2.5 + s * 2.5, 3.0, -2.8)
		room.add_child(scr_inst)

	## Janela grande panoramica (frente)
	var big_win_mesh = BoxMesh.new()
	big_win_mesh.size = Vector3(6.0, 2.5, 0.08)
	var big_win_mat = StandardMaterial3D.new()
	big_win_mat.albedo_color = Color(0.02, 0.04, 0.12, 0.7)
	big_win_mat.emission_enabled = true
	big_win_mat.emission = Color(0.04, 0.06, 0.15)
	big_win_mat.emission_energy_multiplier = 1.0
	big_win_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	big_win_mesh.surface_set_material(0, big_win_mat)

	var big_win_inst = MeshInstance3D.new()
	big_win_inst.mesh = big_win_mesh
	big_win_inst.position = Vector3(0, 2.8, 3.05)
	room.add_child(big_win_inst)

	## Antena de radar no topo (disco + braco)
	var dish_mesh = CylinderMesh.new()
	dish_mesh.top_radius = 1.2
	dish_mesh.bottom_radius = 1.0
	dish_mesh.height = 0.12
	var dish_mat = StandardMaterial3D.new()
	dish_mat.albedo_color = Color(0.5, 0.52, 0.55)
	dish_mat.metallic = 0.9
	dish_mat.roughness = 0.2
	dish_mesh.surface_set_material(0, dish_mat)

	var dish_inst = MeshInstance3D.new()
	dish_inst.mesh = dish_mesh
	dish_inst.position.y = 5.2
	dish_inst.rotation.x = -0.3
	room.add_child(dish_inst)

	## Braco da antena
	var arm_mesh = CylinderMesh.new()
	arm_mesh.top_radius = 0.06
	arm_mesh.bottom_radius = 0.06
	arm_mesh.height = 0.8
	var arm_mat = StandardMaterial3D.new()
	arm_mat.albedo_color = Color(0.4, 0.42, 0.45)
	arm_mat.metallic = 0.9
	arm_mesh.surface_set_material(0, arm_mat)

	var arm_inst = MeshInstance3D.new()
	arm_inst.mesh = arm_mesh
	arm_inst.position.y = 4.8
	room.add_child(arm_inst)

	## Luz interior
	var room_light = OmniLight3D.new()
	room_light.position = Vector3(0, 3.5, 0)
	room_light.light_color = Color(0.4, 0.6, 1.0)
	room_light.light_energy = 0.8
	room_light.omni_range = 10.0
	room_light.omni_attenuation = 1.5
	room.add_child(room_light)

	add_child(room)

## ---- CRIOPODS ----
func _generate_cryopods() -> void:
	for i in range(6):
		var pod = Node3D.new()
		var angle = (float(i) / 6.0) * TAU + 0.5
		var pod_radius = rng.randf_range(area_size * 0.25, area_size * 0.45)
		pod.position = Vector3(
			cos(angle) * pod_radius,
			0,
			sin(angle) * pod_radius
		)
		pod.rotation.y = -angle

		## Corpo do pod (cilindro vertical)
		var body_mesh = CylinderMesh.new()
		body_mesh.top_radius = 0.5
		body_mesh.bottom_radius = 0.55
		body_mesh.height = 2.2
		var body_mat = StandardMaterial3D.new()
		body_mat.albedo_color = Color(0.5, 0.53, 0.56)
		body_mat.metallic = 0.8
		body_mat.roughness = 0.25
		body_mesh.surface_set_material(0, body_mat)

		var body_inst = MeshInstance3D.new()
		body_inst.mesh = body_mesh
		body_inst.position.y = 1.1
		pod.add_child(body_inst)

		## Tampa superior (hemisferio = meia esfera)
		var top_mesh = SphereMesh.new()
		top_mesh.radius = 0.5
		top_mesh.height = 0.5
		var top_mat = StandardMaterial3D.new()
		top_mat.albedo_color = Color(0.45, 0.48, 0.52)
		top_mat.metallic = 0.85
		top_mat.roughness = 0.2
		top_mesh.surface_set_material(0, top_mat)

		var top_inst = MeshInstance3D.new()
		top_inst.mesh = top_mesh
		top_inst.position.y = 2.2
		pod.add_child(top_inst)

		## Base (hemisferio inferior)
		var bot_inst = MeshInstance3D.new()
		bot_inst.mesh = top_mesh
		bot_inst.position.y = 0.0
		bot_inst.rotation.x = PI
		pod.add_child(bot_inst)

		## Vidro azul/branco brilhante (janela frontal)
		var glass_mesh = BoxMesh.new()
		glass_mesh.size = Vector3(0.4, 1.2, 0.04)
		var glass_mat = StandardMaterial3D.new()
		glass_mat.albedo_color = Color(0.3, 0.6, 1.0, 0.4)
		glass_mat.emission_enabled = true
		glass_mat.emission = Color(0.2, 0.5, 0.9)
		glass_mat.emission_energy_multiplier = 3.0
		glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glass_mesh.surface_set_material(0, glass_mat)

		var glass_inst = MeshInstance3D.new()
		glass_inst.mesh = glass_mesh
		glass_inst.position = Vector3(0, 1.2, 0.55)
		pod.add_child(glass_inst)

		## Alguns pods com vidro rachado (30% de chance)
		if rng.randi() % 3 == 0:
			var crack_mesh = BoxMesh.new()
			crack_mesh.size = Vector3(0.5, 0.04, 0.06)
			var crack_mat = StandardMaterial3D.new()
			crack_mat.albedo_color = Color(0.7, 0.7, 0.75, 0.6)
			crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			crack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			crack_mesh.surface_set_material(0, crack_mat)

			var crack_inst = MeshInstance3D.new()
			crack_inst.mesh = crack_mesh
			crack_inst.position = Vector3(rng.randf_range(-0.1, 0.1), 1.3, 0.57)
			crack_inst.rotation.z = rng.randf_range(-0.5, 0.5)
			pod.add_child(crack_inst)

		## Brilho azul do pod
		var pod_light = OmniLight3D.new()
		pod_light.position = Vector3(0, 1.2, 0.6)
		pod_light.light_color = Color(0.3, 0.5, 1.0)
		pod_light.light_energy = 0.5
		pod_light.omni_range = 4.0
		pod_light.omni_attenuation = 2.0
		pod.add_child(pod_light)

		add_child(pod)

## ---- CONTAINERS DE CARGA ----
func _generate_cargo_containers() -> void:
	var container_colors: Array[Color] = [
		Color(0.8, 0.4, 0.1),
		Color(0.2, 0.4, 0.7),
		Color(0.2, 0.6, 0.25),
		Color(0.45, 0.45, 0.48),
	]
	var stencil_colors: Array[Color] = [
		Color(0.95, 0.95, 0.95),
		Color(0.9, 0.8, 0.1),
		Color(0.1, 0.1, 0.1),
	]

	## 4 grupos de containers empilhados
	for g in range(4):
		var group_x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var group_z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		if abs(group_x) < 8 and abs(group_z) < 8:
			group_x += 12.0
		var group_rot = rng.randf_range(0, TAU)

		var containers_in_group = rng.randi_range(2, 3)
		for c in range(containers_in_group):
			var container = Node3D.new()
			var stack_y = c * 1.3
			container.position = Vector3(
				group_x + rng.randf_range(-0.5, 0.5),
				stack_y,
				group_z + rng.randf_range(-0.5, 0.5)
			)
			container.rotation.y = group_rot + rng.randf_range(-0.2, 0.2)

			var cw = rng.randf_range(1.5, 2.5)
			var ch = rng.randf_range(1.0, 1.3)
			var cd = rng.randf_range(1.0, 1.5)
			var cc = container_colors[rng.randi() % container_colors.size()]

			## Caixa do container
			var box_mesh = BoxMesh.new()
			box_mesh.size = Vector3(cw, ch, cd)
			var box_mat = StandardMaterial3D.new()
			box_mat.albedo_color = cc
			box_mat.roughness = 0.6
			box_mat.metallic = 0.3
			box_mesh.surface_set_material(0, box_mat)

			var box_inst = MeshInstance3D.new()
			box_inst.mesh = box_mesh
			box_inst.position.y = ch / 2.0
			container.add_child(box_inst)

			## Marcacao estencilada (caixa plana no lado)
			var stencil_mesh = BoxMesh.new()
			stencil_mesh.size = Vector3(cw * 0.3, ch * 0.3, 0.02)
			var stencil_mat = StandardMaterial3D.new()
			stencil_mat.albedo_color = stencil_colors[rng.randi() % stencil_colors.size()]
			stencil_mat.roughness = 0.8
			stencil_mesh.surface_set_material(0, stencil_mat)

			var stencil_inst = MeshInstance3D.new()
			stencil_inst.mesh = stencil_mesh
			stencil_inst.position = Vector3(0, ch / 2.0, cd / 2.0 + 0.02)
			container.add_child(stencil_inst)

			## Reforco metalico na borda
			var edge_mesh = BoxMesh.new()
			edge_mesh.size = Vector3(cw + 0.05, 0.06, cd + 0.05)
			var edge_mat = StandardMaterial3D.new()
			edge_mat.albedo_color = Color(0.35, 0.37, 0.4)
			edge_mat.metallic = 0.8
			edge_mat.roughness = 0.2
			edge_mesh.surface_set_material(0, edge_mat)

			var edge_inst = MeshInstance3D.new()
			edge_inst.mesh = edge_mesh
			edge_inst.position.y = ch
			container.add_child(edge_inst)

			add_child(container)

## ---- DISPLAYS HOLOGRAFICOS ----
func _generate_holographic_displays() -> void:
	for i in range(8):
		var holo = Node3D.new()
		var x = rng.randf_range(-area_size * 0.55, area_size * 0.55)
		var z = rng.randf_range(-area_size * 0.55, area_size * 0.55)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		holo.position = Vector3(x, 0, z)

		## Base do projetor
		var base_mesh = CylinderMesh.new()
		base_mesh.top_radius = 0.3
		base_mesh.bottom_radius = 0.35
		base_mesh.height = 0.15
		var base_mat = StandardMaterial3D.new()
		base_mat.albedo_color = Color(0.35, 0.38, 0.42)
		base_mat.metallic = 0.8
		base_mat.roughness = 0.3
		base_mesh.surface_set_material(0, base_mat)

		var base_inst = MeshInstance3D.new()
		base_inst.mesh = base_mesh
		base_inst.position.y = 1.0
		holo.add_child(base_inst)

		## Projecao holografica (forma semi-transparente flutuante)
		var holo_tint = Color(0.1, 0.8, 0.4, 0.25) if rng.randi() % 2 == 0 else Color(0.2, 0.5, 1.0, 0.25)
		var holo_shapes: Array[int] = [0, 1, 2]  # 0=esfera, 1=caixa, 2=cilindro
		var shape_type = holo_shapes[rng.randi() % holo_shapes.size()]

		var holo_inst = MeshInstance3D.new()
		var holo_mat = StandardMaterial3D.new()
		holo_mat.albedo_color = holo_tint
		holo_mat.emission_enabled = true
		holo_mat.emission = Color(holo_tint.r, holo_tint.g, holo_tint.b)
		holo_mat.emission_energy_multiplier = 3.5
		holo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		holo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

		if shape_type == 0:
			var s_mesh = SphereMesh.new()
			s_mesh.radius = rng.randf_range(0.2, 0.5)
			s_mesh.height = s_mesh.radius * 2.0
			s_mesh.surface_set_material(0, holo_mat)
			holo_inst.mesh = s_mesh
		elif shape_type == 1:
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(
				rng.randf_range(0.3, 0.6),
				rng.randf_range(0.3, 0.6),
				rng.randf_range(0.3, 0.6)
			)
			b_mesh.surface_set_material(0, holo_mat)
			holo_inst.mesh = b_mesh
		else:
			var c_mesh = CylinderMesh.new()
			c_mesh.top_radius = rng.randf_range(0.15, 0.3)
			c_mesh.bottom_radius = c_mesh.top_radius
			c_mesh.height = rng.randf_range(0.4, 0.8)
			c_mesh.surface_set_material(0, holo_mat)
			holo_inst.mesh = c_mesh

		holo_inst.position.y = rng.randf_range(1.5, 2.2)
		holo_inst.rotation.y = rng.randf_range(0, TAU)
		holo.add_child(holo_inst)

		## Raio do projetor (cilindro fino transparente)
		var ray_mesh = CylinderMesh.new()
		ray_mesh.top_radius = 0.02
		ray_mesh.bottom_radius = 0.08
		ray_mesh.height = holo_inst.position.y - 1.0
		var ray_mat = StandardMaterial3D.new()
		ray_mat.albedo_color = Color(holo_tint.r, holo_tint.g, holo_tint.b, 0.1)
		ray_mat.emission_enabled = true
		ray_mat.emission = Color(holo_tint.r, holo_tint.g, holo_tint.b)
		ray_mat.emission_energy_multiplier = 1.5
		ray_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ray_mesh.surface_set_material(0, ray_mat)

		var ray_inst = MeshInstance3D.new()
		ray_inst.mesh = ray_mesh
		ray_inst.position.y = 1.0 + ray_mesh.height / 2.0
		holo.add_child(ray_inst)

		## Leve luz no holograma
		var holo_light = OmniLight3D.new()
		holo_light.position.y = holo_inst.position.y
		holo_light.light_color = Color(holo_tint.r, holo_tint.g, holo_tint.b)
		holo_light.light_energy = 0.4
		holo_light.omni_range = 4.0
		holo_light.omni_attenuation = 2.0
		holo.add_child(holo_light)

		add_child(holo)

## ---- SECOES DANIFICADAS ----
func _generate_damaged_sections() -> void:
	for i in range(4):
		var section = Node3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		if abs(x) < 7 and abs(z) < 7:
			x += 10.0
		section.position = Vector3(x, 0, z)
		section.rotation.y = rng.randf_range(0, TAU)

		## Painel quebrado (caixa inclinada)
		var panel_mesh = BoxMesh.new()
		panel_mesh.size = Vector3(2.0, 1.5, 0.1)
		var panel_mat = StandardMaterial3D.new()
		panel_mat.albedo_color = Color(0.35, 0.3, 0.28)
		panel_mat.metallic = 0.6
		panel_mat.roughness = 0.5
		panel_mesh.surface_set_material(0, panel_mat)

		var panel_inst = MeshInstance3D.new()
		panel_inst.mesh = panel_mesh
		panel_inst.position = Vector3(0, 1.2, 0)
		panel_inst.rotation = Vector3(
			rng.randf_range(-0.3, 0.3),
			0,
			rng.randf_range(-0.2, 0.2)
		)
		section.add_child(panel_inst)

		## Fios expostos (cilindros finos coloridos)
		var wire_colors: Array[Color] = [
			Color(0.9, 0.2, 0.1),
			Color(0.1, 0.6, 0.9),
			Color(0.9, 0.8, 0.1),
			Color(0.1, 0.8, 0.2),
		]
		for w in range(rng.randi_range(3, 5)):
			var wire_mesh = CylinderMesh.new()
			wire_mesh.top_radius = 0.015
			wire_mesh.bottom_radius = 0.015
			wire_mesh.height = rng.randf_range(0.5, 1.5)
			var wire_mat = StandardMaterial3D.new()
			wire_mat.albedo_color = wire_colors[rng.randi() % wire_colors.size()]
			wire_mat.roughness = 0.7
			wire_mesh.surface_set_material(0, wire_mat)

			var wire_inst = MeshInstance3D.new()
			wire_inst.mesh = wire_mesh
			wire_inst.position = Vector3(
				rng.randf_range(-0.8, 0.8),
				rng.randf_range(0.8, 1.8),
				rng.randf_range(-0.2, 0.2)
			)
			wire_inst.rotation = Vector3(
				rng.randf_range(-1.0, 1.0),
				rng.randf_range(-0.5, 0.5),
				rng.randf_range(-1.0, 1.0)
			)
			section.add_child(wire_inst)

		## Particulas de faiscas
		var sparks = GPUParticles3D.new()
		var spark_mat = ParticleProcessMaterial.new()
		spark_mat.direction = Vector3(0, -1, 0.5)
		spark_mat.spread = 40.0
		spark_mat.initial_velocity_min = 1.0
		spark_mat.initial_velocity_max = 3.0
		spark_mat.gravity = Vector3(0, -3.0, 0)
		spark_mat.scale_min = 0.02
		spark_mat.scale_max = 0.05
		spark_mat.color = Color(1.0, 0.8, 0.2, 0.9)

		sparks.process_material = spark_mat
		sparks.amount = 12
		sparks.lifetime = 0.6
		sparks.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))

		var spark_draw = SphereMesh.new()
		spark_draw.radius = 0.03
		spark_draw.height = 0.03
		var spark_draw_mat = StandardMaterial3D.new()
		spark_draw_mat.albedo_color = Color(1.0, 0.9, 0.3, 0.9)
		spark_draw_mat.emission_enabled = true
		spark_draw_mat.emission = Color(1.0, 0.7, 0.1)
		spark_draw_mat.emission_energy_multiplier = 5.0
		spark_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		spark_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		spark_draw.surface_set_material(0, spark_draw_mat)
		sparks.draw_pass_1 = spark_draw

		sparks.position = Vector3(0, 1.5, 0)
		section.add_child(sparks)

		## Luz vermelha de emergencia
		var red_light = OmniLight3D.new()
		red_light.position = Vector3(0, 2.0, 0)
		red_light.light_color = Color(1.0, 0.15, 0.1)
		red_light.light_energy = 0.8
		red_light.omni_range = 6.0
		red_light.omni_attenuation = 2.0
		section.add_child(red_light)

		## Sinalizador visual vermelho (esfera emissiva)
		var warn_mesh = SphereMesh.new()
		warn_mesh.radius = 0.1
		warn_mesh.height = 0.2
		var warn_mat = StandardMaterial3D.new()
		warn_mat.albedo_color = Color(1.0, 0.1, 0.05, 0.8)
		warn_mat.emission_enabled = true
		warn_mat.emission = Color(1.0, 0.1, 0.05)
		warn_mat.emission_energy_multiplier = 4.0
		warn_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		warn_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		warn_mesh.surface_set_material(0, warn_mat)

		var warn_inst = MeshInstance3D.new()
		warn_inst.mesh = warn_mesh
		warn_inst.position = Vector3(1.2, 2.5, 0)
		section.add_child(warn_inst)

		add_child(section)

## ---- ILUMINACAO AMBIENTE (MISTURA FRIO + QUENTE) ----
func _generate_ambient_lights() -> void:
	## Luzes azuis/brancas da estacao (frias)
	for i in range(8):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		light.position = Vector3(x, 3.0, z)
		light.light_color = Color(0.5, 0.7, 1.0)
		light.light_energy = 0.45
		light.omni_range = 10.0
		light.omni_attenuation = 2.0
		add_child(light)

	## Luzes ambar de emergencia (quentes)
	for i in range(4):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		var z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		light.position = Vector3(x, 2.5, z)
		light.light_color = Color(1.0, 0.7, 0.3)
		light.light_energy = 0.35
		light.omni_range = 8.0
		light.omni_attenuation = 2.5
		add_child(light)

	## Luz direcional fria de cima (iluminacao geral da estacao)
	var station_light = DirectionalLight3D.new()
	station_light.light_color = Color(0.5, 0.6, 0.8)
	station_light.light_energy = 0.25
	station_light.rotation = Vector3(-1.0, 0.3, 0)
	add_child(station_light)

	## Luzes de acento roxas/cyan em cantos
	for i in range(4):
		var angle = (float(i) / 4.0) * TAU + PI / 4.0
		var radius = area_size * 0.5
		var light = OmniLight3D.new()
		light.position = Vector3(cos(angle) * radius, 4.0, sin(angle) * radius)
		if i % 2 == 0:
			light.light_color = Color(0.5, 0.2, 0.8)
		else:
			light.light_color = Color(0.1, 0.8, 0.7)
		light.light_energy = 0.25
		light.omni_range = 10.0
		light.omni_attenuation = 2.0
		add_child(light)

## ---- PARTICULAS DE ESTRELAS (MAIS DENSAS + SHOOTING STARS) ----
func _generate_star_particles() -> void:
	## Estrelas distantes
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
	mat.emission_box_extents = Vector3(70, 25, 70)

	stars.process_material = mat
	stars.amount = 120
	stars.lifetime = 12.0
	stars.visibility_aabb = AABB(Vector3(-80, -5, -80), Vector3(160, 35, 160))

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

	stars.position = Vector3(0, 12, 0)
	add_child(stars)

	## Estrelas cadentes (particulas rapidas e brilhantes)
	var shooting = GPUParticles3D.new()
	var shoot_mat = ParticleProcessMaterial.new()
	shoot_mat.direction = Vector3(1, -0.3, 0.5)
	shoot_mat.spread = 15.0
	shoot_mat.initial_velocity_min = 15.0
	shoot_mat.initial_velocity_max = 30.0
	shoot_mat.gravity = Vector3(0, -1.0, 0)
	shoot_mat.scale_min = 0.03
	shoot_mat.scale_max = 0.08
	shoot_mat.color = Color(1.0, 1.0, 0.9, 0.9)
	shoot_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	shoot_mat.emission_box_extents = Vector3(50, 10, 50)

	shooting.process_material = shoot_mat
	shooting.amount = 3
	shooting.lifetime = 1.5
	shooting.visibility_aabb = AABB(Vector3(-80, -5, -80), Vector3(160, 35, 160))

	var shoot_draw = SphereMesh.new()
	shoot_draw.radius = 0.04
	shoot_draw.height = 0.04
	var shoot_draw_mat = StandardMaterial3D.new()
	shoot_draw_mat.albedo_color = Color(1.0, 1.0, 0.8, 0.95)
	shoot_draw_mat.emission_enabled = true
	shoot_draw_mat.emission = Color(1.0, 0.95, 0.7)
	shoot_draw_mat.emission_energy_multiplier = 6.0
	shoot_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shoot_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shoot_draw.surface_set_material(0, shoot_draw_mat)
	shooting.draw_pass_1 = shoot_draw

	shooting.position = Vector3(0, 18, 0)
	add_child(shooting)

## ---- NUVENS DE NEBULOSA (ESFERAS DISTANTES BRILHANTES) ----
func _generate_nebula_clouds() -> void:
	var nebula_colors: Array[Color] = [
		Color(0.3, 0.1, 0.6, 0.08),
		Color(0.1, 0.3, 0.7, 0.06),
		Color(0.6, 0.15, 0.3, 0.07),
		Color(0.1, 0.5, 0.5, 0.06),
		Color(0.5, 0.3, 0.1, 0.05),
	]

	for i in range(5):
		var nebula_mesh = SphereMesh.new()
		nebula_mesh.radius = rng.randf_range(8.0, 18.0)
		nebula_mesh.height = nebula_mesh.radius * 2.0
		var nebula_mat = StandardMaterial3D.new()
		var nc = nebula_colors[i % nebula_colors.size()]
		nebula_mat.albedo_color = nc
		nebula_mat.emission_enabled = true
		nebula_mat.emission = Color(nc.r * 2.0, nc.g * 2.0, nc.b * 2.0)
		nebula_mat.emission_energy_multiplier = 1.5
		nebula_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		nebula_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		nebula_mesh.surface_set_material(0, nebula_mat)

		var nebula_inst = MeshInstance3D.new()
		nebula_inst.mesh = nebula_mesh
		nebula_inst.position = Vector3(
			rng.randf_range(-60, 60),
			rng.randf_range(15, 30),
			rng.randf_range(-60, 60)
		)
		add_child(nebula_inst)
