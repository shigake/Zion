extends Node3D

## Gera props procedurais para Tokyo Cyberpunk estilo BotW: predios com janelas neon,
## billboards com flicker, placas de rua, maquinas de venda, pocas reflexivas,
## chuva com respingos, fios entre predios, efeito glitch, iluminacao dramatica.
## Paineis eletricos causam 10 dano a cada 2 seg.

@export var num_buildings: int = 35
@export var num_billboards: int = 20
@export var num_electric_panels: int = 12
@export var num_street_signs: int = 15
@export var num_vending_machines: int = 8
@export var num_puddles: int = 12
@export var num_wire_tangles: int = 10
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var neon_colors: Array[Color] = [
	Color(1.0, 0.0, 0.5),   ## Rosa neon
	Color(0.0, 0.8, 1.0),   ## Ciano neon
	Color(0.5, 0.0, 1.0),   ## Roxo neon
	Color(1.0, 0.3, 0.0),   ## Laranja neon
	Color(0.0, 1.0, 0.3),   ## Verde neon
]

var electric_panels: Array[Area3D] = []
var electric_timer: float = 0.0

## Paineis de billboard para efeito de flickering
var billboard_panels: Array[MeshInstance3D] = []
var billboard_materials: Array[StandardMaterial3D] = []
var billboard_base_energy: Array[float] = []
var flicker_timer: float = 0.0

## Posicoes dos predios para conectar fios
var building_positions: Array[Vector3] = []
var building_heights: Array[float] = []

func _ready() -> void:
	rng.randomize()
	_generate_buildings()
	_generate_billboards()
	_generate_electric_panels()
	_generate_street_signs()
	_generate_vending_machines()
	_generate_puddles()
	_generate_rain()
	_generate_wire_tangles()
	_generate_glitch_particles()
	_generate_neon_lights()
	_add_real_models()

func _add_real_models() -> void:
	## Adiciona modelos Kenney — arvores decorativas urbanas, rochas, tochas
	ModelFactory.scatter_nature_props(self, "tree_pine", 8, area_size, Vector2(1.0, 2.0))
	ModelFactory.scatter_nature_props(self, "rock_small", 10, area_size, Vector2(0.5, 1.0))
	ModelFactory.scatter_nature_props(self, "stone_small", 8, area_size, Vector2(0.5, 1.0))
	ModelFactory.scatter_nature_props(self, "bush", 6, area_size, Vector2(0.8, 1.5))
	ModelFactory.scatter_nature_props(self, "plant_flat", 10, area_size, Vector2(0.6, 1.2))

func _process(delta: float) -> void:
	## Paineis eletricos causam 10 de dano a cada 2 segundos
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

	## Flickering dos billboards
	flicker_timer += delta
	if flicker_timer >= 0.1:
		flicker_timer = 0.0
		for idx in range(billboard_materials.size()):
			if not is_instance_valid(billboard_panels[idx]):
				continue
			var mat = billboard_materials[idx]
			## Chance de flicker rapido
			if rng.randf() < 0.08:
				mat.emission_energy_multiplier = rng.randf_range(0.3, 1.0)
			else:
				mat.emission_energy_multiplier = billboard_base_energy[idx] + rng.randf_range(-0.2, 0.2)

## ===================== PREDIOS COM JANELAS =====================

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

		## Guardar posicao para conectar fios depois
		building_positions.append(Vector3(x, 0, z))
		building_heights.append(height)

		## Corpo do predio
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

		## Telhado escalonado em alguns predios
		if rng.randf() < 0.35:
			var step_height = rng.randf_range(1.0, 3.0)
			var step_mesh = BoxMesh.new()
			step_mesh.size = Vector3(width * 0.65, step_height, depth * 0.65)
			var step_mat = StandardMaterial3D.new()
			step_mat.albedo_color = Color(0.1, 0.1, 0.14)
			step_mat.roughness = 0.3
			step_mat.metallic = 0.5
			step_mesh.surface_set_material(0, step_mat)

			var step_inst = MeshInstance3D.new()
			step_inst.mesh = step_mesh
			step_inst.position.y = height + step_height / 2.0
			building.add_child(step_inst)

		## Faixas neon nas laterais
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

		## Grade de janelas (quadradinhos emissivos nas faces do predio)
		var win_color = neon_colors[rng.randi() % neon_colors.size()]
		var warm_window = rng.randf() < 0.4
		if warm_window:
			win_color = Color(1.0, 0.85, 0.5)  ## Janela quente amarelada

		var rows = int(height / 1.2)
		var cols_w = int(width / 0.8)
		var cols_d = int(depth / 0.8)

		## Janelas na face frontal (Z+) e traseira (Z-)
		for row in range(rows):
			for col in range(cols_w):
				if rng.randf() < 0.3:
					continue  ## Nem todas as janelas estao acesas
				var win_mesh = BoxMesh.new()
				win_mesh.size = Vector3(0.35, 0.35, 0.02)
				var win_mat = StandardMaterial3D.new()
				var dimmed = rng.randf_range(0.4, 1.0)
				win_mat.albedo_color = Color(win_color.r * dimmed, win_color.g * dimmed, win_color.b * dimmed, 0.8)
				win_mat.emission_enabled = true
				win_mat.emission = win_color
				win_mat.emission_energy_multiplier = rng.randf_range(1.0, 2.5)
				win_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				win_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				win_mesh.surface_set_material(0, win_mat)

				var win_x = -width / 2.0 + 0.5 + col * (width - 1.0) / maxf(cols_w - 1, 1)
				var win_y = 1.0 + row * 1.2

				## Face frontal
				var win_inst_f = MeshInstance3D.new()
				win_inst_f.mesh = win_mesh
				win_inst_f.position = Vector3(win_x, win_y, depth / 2.0 + 0.02)
				building.add_child(win_inst_f)

				## Face traseira (apenas algumas)
				if rng.randf() < 0.5:
					var win_inst_b = MeshInstance3D.new()
					win_inst_b.mesh = win_mesh
					win_inst_b.position = Vector3(win_x, win_y, -depth / 2.0 - 0.02)
					building.add_child(win_inst_b)

		## Janelas nas faces laterais (X+ e X-)
		for row in range(rows):
			for col in range(cols_d):
				if rng.randf() < 0.4:
					continue
				var win_mesh_s = BoxMesh.new()
				win_mesh_s.size = Vector3(0.02, 0.35, 0.35)
				var win_mat_s = StandardMaterial3D.new()
				var dimmed_s = rng.randf_range(0.4, 1.0)
				win_mat_s.albedo_color = Color(win_color.r * dimmed_s, win_color.g * dimmed_s, win_color.b * dimmed_s, 0.8)
				win_mat_s.emission_enabled = true
				win_mat_s.emission = win_color
				win_mat_s.emission_energy_multiplier = rng.randf_range(1.0, 2.5)
				win_mat_s.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				win_mat_s.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				win_mesh_s.surface_set_material(0, win_mat_s)

				var win_z = -depth / 2.0 + 0.5 + col * (depth - 1.0) / maxf(cols_d - 1, 1)
				var win_y = 1.0 + row * 1.2

				var win_inst_r = MeshInstance3D.new()
				win_inst_r.mesh = win_mesh_s
				win_inst_r.position = Vector3(width / 2.0 + 0.02, win_y, win_z)
				building.add_child(win_inst_r)

		## Antena/prato de satelite no topo de alguns predios
		if rng.randf() < 0.5:
			## Antena (cilindro fino vertical)
			var antenna_mesh = CylinderMesh.new()
			antenna_mesh.top_radius = 0.02
			antenna_mesh.bottom_radius = 0.03
			antenna_mesh.height = rng.randf_range(1.0, 2.5)
			var antenna_mat = StandardMaterial3D.new()
			antenna_mat.albedo_color = Color(0.3, 0.3, 0.35)
			antenna_mat.metallic = 0.8
			antenna_mesh.surface_set_material(0, antenna_mat)

			var antenna_inst = MeshInstance3D.new()
			antenna_inst.mesh = antenna_mesh
			antenna_inst.position.y = height + antenna_mesh.height / 2.0
			antenna_inst.position.x = rng.randf_range(-width * 0.3, width * 0.3)
			building.add_child(antenna_inst)

			## Prato de satelite (cilindro achatado inclinado)
			if rng.randf() < 0.4:
				var dish_mesh = CylinderMesh.new()
				dish_mesh.top_radius = 0.4
				dish_mesh.bottom_radius = 0.35
				dish_mesh.height = 0.08
				var dish_mat = StandardMaterial3D.new()
				dish_mat.albedo_color = Color(0.4, 0.4, 0.45)
				dish_mat.metallic = 0.7
				dish_mesh.surface_set_material(0, dish_mat)

				var dish_inst = MeshInstance3D.new()
				dish_inst.mesh = dish_mesh
				dish_inst.position = Vector3(
					rng.randf_range(-width * 0.3, width * 0.3),
					height + 0.2,
					rng.randf_range(-depth * 0.3, depth * 0.3)
				)
				dish_inst.rotation.x = rng.randf_range(0.3, 0.7)
				dish_inst.rotation.y = rng.randf_range(0, TAU)
				building.add_child(dish_inst)

		add_child(building)

## ===================== BILLBOARDS COM FLICKERING =====================

func _generate_billboards() -> void:
	for i in range(num_billboards):
		var billboard = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		billboard.position = Vector3(x, rng.randf_range(3.0, 6.0), z)

		## Poste
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

		## Moldura/borda do billboard
		var panel_w = rng.randf_range(2.0, 4.0)
		var panel_h = rng.randf_range(1.0, 2.0)
		var rot_y = rng.randf_range(0, TAU)

		var frame_mesh = BoxMesh.new()
		frame_mesh.size = Vector3(panel_w + 0.2, panel_h + 0.2, 0.08)
		var frame_mat = StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.15, 0.15, 0.2)
		frame_mat.metallic = 0.7
		frame_mesh.surface_set_material(0, frame_mat)

		var frame_inst = MeshInstance3D.new()
		frame_inst.mesh = frame_mesh
		frame_inst.rotation.y = rot_y
		billboard.add_child(frame_inst)

		## Painel holografico
		var panel_mesh = BoxMesh.new()
		panel_mesh.size = Vector3(panel_w, panel_h, 0.05)
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
		panel_inst.rotation.y = rot_y
		panel_inst.position.z = 0.02  ## Levemente na frente da moldura
		billboard.add_child(panel_inst)

		## Registrar para flickering
		billboard_panels.append(panel_inst)
		billboard_materials.append(panel_mat)
		billboard_base_energy.append(panel_mat.emission_energy_multiplier)

		add_child(billboard)

## ===================== PAINEIS ELETRICOS (DANO) =====================

func _generate_electric_panels() -> void:
	for i in range(num_electric_panels):
		var panel_node = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		panel_node.position = Vector3(x, 0, z)

		## Painel visual no chao
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

		## Area3D para detectar corpos (identico ao original)
		var area = Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 3  ## Players (1) + Enemies (2)
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(panel_size, 1.0, panel_size)
		col.shape = shape
		col.position.y = 0.5
		area.add_child(col)
		panel_node.add_child(area)
		electric_panels.append(area)

		## Particulas de eletricidade
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

## ===================== PLACAS DE RUA NEON =====================

func _generate_street_signs() -> void:
	for i in range(num_street_signs):
		var sign_node = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		sign_node.position = Vector3(x, 0, z)

		## Poste fino
		var pole_height = rng.randf_range(2.5, 4.0)
		var pole_mesh = CylinderMesh.new()
		pole_mesh.top_radius = 0.04
		pole_mesh.bottom_radius = 0.05
		pole_mesh.height = pole_height
		var pole_mat = StandardMaterial3D.new()
		pole_mat.albedo_color = Color(0.25, 0.25, 0.3)
		pole_mat.metallic = 0.7
		pole_mesh.surface_set_material(0, pole_mat)

		var pole_inst = MeshInstance3D.new()
		pole_inst.mesh = pole_mesh
		pole_inst.position.y = pole_height / 2.0
		sign_node.add_child(pole_inst)

		## Placa neon (caixa fina com emissao)
		var sign_w = rng.randf_range(1.0, 2.5)
		var sign_h = rng.randf_range(0.4, 0.8)
		var sign_mesh = BoxMesh.new()
		sign_mesh.size = Vector3(sign_w, sign_h, 0.06)
		var sign_color = neon_colors[rng.randi() % neon_colors.size()]
		var sign_mat = StandardMaterial3D.new()
		sign_mat.albedo_color = sign_color
		sign_mat.emission_enabled = true
		sign_mat.emission = sign_color
		sign_mat.emission_energy_multiplier = rng.randf_range(2.5, 4.0)
		sign_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sign_mesh.surface_set_material(0, sign_mat)

		var sign_inst = MeshInstance3D.new()
		sign_inst.mesh = sign_mesh
		sign_inst.position.y = pole_height + sign_h / 2.0
		sign_inst.rotation.y = rng.randf_range(0, TAU)
		sign_node.add_child(sign_inst)

		## Fundo escuro atras da placa (moldura)
		var back_mesh = BoxMesh.new()
		back_mesh.size = Vector3(sign_w + 0.1, sign_h + 0.1, 0.04)
		var back_mat = StandardMaterial3D.new()
		back_mat.albedo_color = Color(0.05, 0.05, 0.08)
		back_mat.metallic = 0.5
		back_mesh.surface_set_material(0, back_mat)

		var back_inst = MeshInstance3D.new()
		back_inst.mesh = back_mesh
		back_inst.position = sign_inst.position
		back_inst.position.z -= 0.04
		back_inst.rotation.y = sign_inst.rotation.y
		sign_node.add_child(back_inst)

		add_child(sign_node)

## ===================== MAQUINAS DE VENDA =====================

func _generate_vending_machines() -> void:
	for i in range(num_vending_machines):
		var vm = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		vm.position = Vector3(x, 0, z)

		## Corpo da maquina (caixa)
		var vm_w = rng.randf_range(0.8, 1.2)
		var vm_h = rng.randf_range(1.6, 2.0)
		var vm_d = rng.randf_range(0.5, 0.8)
		var vm_mesh = BoxMesh.new()
		vm_mesh.size = Vector3(vm_w, vm_h, vm_d)
		var vm_mat = StandardMaterial3D.new()
		vm_mat.albedo_color = Color(0.12, 0.12, 0.15)
		vm_mat.roughness = 0.4
		vm_mat.metallic = 0.5
		vm_mesh.surface_set_material(0, vm_mat)

		var vm_inst = MeshInstance3D.new()
		vm_inst.mesh = vm_mesh
		vm_inst.position.y = vm_h / 2.0
		vm_inst.rotation.y = rng.randf_range(0, TAU)
		vm.add_child(vm_inst)

		## Tela frontal brilhante (painel emissivo)
		var screen_mesh = BoxMesh.new()
		screen_mesh.size = Vector3(vm_w * 0.75, vm_h * 0.6, 0.02)
		var screen_color = neon_colors[rng.randi() % neon_colors.size()]
		var screen_mat = StandardMaterial3D.new()
		screen_mat.albedo_color = Color(screen_color.r, screen_color.g, screen_color.b, 0.85)
		screen_mat.emission_enabled = true
		screen_mat.emission = screen_color
		screen_mat.emission_energy_multiplier = 2.5
		screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		screen_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		screen_mesh.surface_set_material(0, screen_mat)

		var screen_inst = MeshInstance3D.new()
		screen_inst.mesh = screen_mesh
		screen_inst.position = Vector3(0, 0, vm_d / 2.0 + 0.02)
		screen_inst.rotation.y = vm_inst.rotation.y
		## Posicionar relativo ao corpo
		screen_inst.position.y = vm_h * 0.55
		vm.add_child(screen_inst)

		## Luz pontual perto da tela
		var vm_light = OmniLight3D.new()
		vm_light.position = Vector3(0, vm_h * 0.5, vm_d / 2.0 + 0.5)
		vm_light.light_color = screen_color
		vm_light.light_energy = 0.3
		vm_light.omni_range = 3.0
		vm_light.omni_attenuation = 2.0
		vm.add_child(vm_light)

		add_child(vm)

## ===================== POCAS REFLEXIVAS =====================

func _generate_puddles() -> void:
	for i in range(num_puddles):
		var puddle = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 4 and abs(z) < 4:
			x += 6.0
		puddle.position = Vector3(x, 0.01, z)

		## Superficie reflexiva (caixa plana com metallic alto)
		var puddle_w = rng.randf_range(1.5, 4.0)
		var puddle_d = rng.randf_range(1.0, 3.0)
		var puddle_mesh = BoxMesh.new()
		puddle_mesh.size = Vector3(puddle_w, 0.02, puddle_d)
		var puddle_mat = StandardMaterial3D.new()
		puddle_mat.albedo_color = Color(0.15, 0.18, 0.25, 0.6)
		puddle_mat.metallic = 0.95
		puddle_mat.roughness = 0.05
		puddle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		puddle_mesh.surface_set_material(0, puddle_mat)

		var puddle_inst = MeshInstance3D.new()
		puddle_inst.mesh = puddle_mesh
		puddle_inst.rotation.y = rng.randf_range(0, TAU)
		puddle.add_child(puddle_inst)

		## Brilho sutil embaixo para simular reflexo de neon
		var neon_ref_color = neon_colors[rng.randi() % neon_colors.size()]
		var ref_mesh = BoxMesh.new()
		ref_mesh.size = Vector3(puddle_w * 0.6, 0.01, puddle_d * 0.6)
		var ref_mat = StandardMaterial3D.new()
		ref_mat.albedo_color = Color(neon_ref_color.r, neon_ref_color.g, neon_ref_color.b, 0.15)
		ref_mat.emission_enabled = true
		ref_mat.emission = neon_ref_color
		ref_mat.emission_energy_multiplier = 0.8
		ref_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ref_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ref_mesh.surface_set_material(0, ref_mat)

		var ref_inst = MeshInstance3D.new()
		ref_inst.mesh = ref_mesh
		ref_inst.position.y = 0.015
		ref_inst.rotation.y = puddle_inst.rotation.y
		puddle.add_child(ref_inst)

		add_child(puddle)

## ===================== CHUVA COM RESPINGOS =====================

func _generate_rain() -> void:
	## Chuva principal (mais densa)
	var rain = GPUParticles3D.new()
	var rain_mat = ParticleProcessMaterial.new()
	rain_mat.direction = Vector3(0, -1, 0)
	rain_mat.spread = 5.0
	rain_mat.initial_velocity_min = 18.0
	rain_mat.initial_velocity_max = 25.0
	rain_mat.gravity = Vector3(0, -6.0, 0)
	rain_mat.scale_min = 0.02
	rain_mat.scale_max = 0.04
	rain_mat.color = Color(0.5, 0.6, 0.8, 0.4)
	rain_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rain_mat.emission_box_extents = Vector3(65, 0.5, 65)

	rain.process_material = rain_mat
	rain.amount = 500
	rain.lifetime = 1.8
	rain.visibility_aabb = AABB(Vector3(-75, -5, -75), Vector3(150, 45, 150))

	var drop_mesh = BoxMesh.new()
	drop_mesh.size = Vector3(0.02, 0.3, 0.02)
	var drop_mat = StandardMaterial3D.new()
	drop_mat.albedo_color = Color(0.6, 0.7, 0.9, 0.3)
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mesh.surface_set_material(0, drop_mat)
	rain.draw_pass_1 = drop_mesh

	rain.position = Vector3(0, 28.0, 0)
	add_child(rain)

	## Respingos no chao (particulas subindo quando chuva atinge o solo)
	var splash = GPUParticles3D.new()
	var splash_mat = ParticleProcessMaterial.new()
	splash_mat.direction = Vector3(0, 1, 0)
	splash_mat.spread = 60.0
	splash_mat.initial_velocity_min = 0.5
	splash_mat.initial_velocity_max = 1.5
	splash_mat.gravity = Vector3(0, -3.0, 0)
	splash_mat.scale_min = 0.02
	splash_mat.scale_max = 0.06
	splash_mat.color = Color(0.6, 0.7, 0.9, 0.3)
	splash_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	splash_mat.emission_box_extents = Vector3(60, 0.1, 60)

	splash.process_material = splash_mat
	splash.amount = 150
	splash.lifetime = 0.5
	splash.visibility_aabb = AABB(Vector3(-70, -1, -70), Vector3(140, 3, 140))

	var splash_draw = SphereMesh.new()
	splash_draw.radius = 0.03
	splash_draw.height = 0.03
	var splash_draw_mat = StandardMaterial3D.new()
	splash_draw_mat.albedo_color = Color(0.7, 0.8, 1.0, 0.25)
	splash_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	splash_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	splash_draw.surface_set_material(0, splash_draw_mat)
	splash.draw_pass_1 = splash_draw

	splash.position = Vector3(0, 0.05, 0)
	add_child(splash)

## ===================== FIOS ENTRE PREDIOS =====================

func _generate_wire_tangles() -> void:
	if building_positions.size() < 2:
		return

	for i in range(num_wire_tangles):
		## Escolher dois predios aleatorios para conectar
		var idx_a = rng.randi() % building_positions.size()
		var idx_b = rng.randi() % building_positions.size()
		if idx_a == idx_b:
			idx_b = (idx_b + 1) % building_positions.size()

		var pos_a = building_positions[idx_a]
		var pos_b = building_positions[idx_b]
		var dist = pos_a.distance_to(pos_b)

		## So conectar predios que nao estao muito distantes
		if dist > 30.0:
			continue

		## Altura do fio (varia entre os topos dos predios)
		var height_a = building_heights[idx_a] * rng.randf_range(0.4, 0.85)
		var height_b = building_heights[idx_b] * rng.randf_range(0.4, 0.85)

		## Criar 2-4 fios por conexao
		var num_wires = rng.randi_range(2, 4)
		for w in range(num_wires):
			var wire_start = Vector3(pos_a.x, height_a + w * 0.3, pos_a.z)
			var wire_end = Vector3(pos_b.x, height_b + w * 0.3, pos_b.z)
			var wire_center = (wire_start + wire_end) / 2.0

			## Cilindro fino representando o fio
			var wire_mesh = CylinderMesh.new()
			wire_mesh.top_radius = 0.015
			wire_mesh.bottom_radius = 0.015
			wire_mesh.height = dist
			var wire_mat = StandardMaterial3D.new()
			wire_mat.albedo_color = Color(0.1, 0.1, 0.12)
			wire_mat.roughness = 0.8
			wire_mesh.surface_set_material(0, wire_mat)

			var wire_inst = MeshInstance3D.new()
			wire_inst.mesh = wire_mesh
			wire_inst.position = wire_center
			## Rotacionar para apontar de A para B
			var dir = (wire_end - wire_start).normalized()
			wire_inst.position.y = (height_a + height_b) / 2.0 + w * 0.3 - rng.randf_range(0.5, 1.5)  ## Catenaria leve
			## Alinhar o cilindro na direcao correta
			if dir.length() > 0.001:
				wire_inst.look_at(wire_inst.position + dir, Vector3.UP)
				wire_inst.rotation.x += PI / 2.0  ## Cilindro aponta pra cima por padrao
			add_child(wire_inst)

## ===================== EFEITO GLITCH =====================

func _generate_glitch_particles() -> void:
	## Particulas de glitch — flashes coloridos aleatorios breves
	var glitch = GPUParticles3D.new()
	var glitch_mat = ParticleProcessMaterial.new()
	glitch_mat.direction = Vector3(0, 0, 0)
	glitch_mat.spread = 180.0
	glitch_mat.initial_velocity_min = 0.0
	glitch_mat.initial_velocity_max = 0.5
	glitch_mat.gravity = Vector3(0, 0, 0)
	glitch_mat.scale_min = 0.3
	glitch_mat.scale_max = 1.5
	glitch_mat.color = Color(1.0, 0.0, 0.8, 0.15)
	glitch_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	glitch_mat.emission_box_extents = Vector3(40, 5, 40)

	glitch.process_material = glitch_mat
	glitch.amount = 5
	glitch.lifetime = 0.2
	glitch.visibility_aabb = AABB(Vector3(-50, -2, -50), Vector3(100, 15, 100))

	var glitch_draw = BoxMesh.new()
	glitch_draw.size = Vector3(0.5, 0.08, 0.5)
	var glitch_draw_mat = StandardMaterial3D.new()
	glitch_draw_mat.albedo_color = Color(1.0, 0.0, 0.5, 0.1)
	glitch_draw_mat.emission_enabled = true
	glitch_draw_mat.emission = Color(0.0, 1.0, 1.0)
	glitch_draw_mat.emission_energy_multiplier = 6.0
	glitch_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glitch_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glitch_draw.surface_set_material(0, glitch_draw_mat)
	glitch.draw_pass_1 = glitch_draw

	glitch.position = Vector3(0, 3.0, 0)
	add_child(glitch)

## ===================== ILUMINACAO NEON DRAMATICA =====================

func _generate_neon_lights() -> void:
	## Cores com mais contraste — mistura quente e fria
	var dramatic_colors: Array[Color] = [
		Color(1.0, 0.0, 0.5),   ## Rosa neon
		Color(0.0, 0.8, 1.0),   ## Ciano neon
		Color(0.5, 0.0, 1.0),   ## Roxo neon
		Color(1.0, 0.3, 0.0),   ## Laranja quente
		Color(0.0, 1.0, 0.3),   ## Verde neon
		Color(1.0, 0.6, 0.2),   ## Amarelo quente
		Color(0.0, 0.5, 1.0),   ## Azul intenso
		Color(1.0, 0.0, 0.8),   ## Magenta
	]

	for i in range(20):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)

		## Variar altura — algumas perto do chao, outras mais altas
		var y_pos: float
		if i < 8:
			y_pos = rng.randf_range(1.0, 2.5)   ## Perto do chao para drama
		else:
			y_pos = rng.randf_range(2.5, 5.0)

		light.position = Vector3(x, y_pos, z)
		light.light_color = dramatic_colors[rng.randi() % dramatic_colors.size()]
		light.light_energy = rng.randf_range(0.4, 0.9)
		light.omni_range = rng.randf_range(6.0, 12.0)
		light.omni_attenuation = 2.0
		add_child(light)
