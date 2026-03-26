extends Node3D

## Gera props aleatorios no cemiterio: lapides, arvores mortas, luzes, cercas, lanternas, velas, vagalumes.
## Estilo BotW — low-poly estilizado com iluminacao atmosferica fantasmagorica.

@export var num_tombstones: int = 60
@export var num_trees: int = 25
@export var num_lights: int = 18
@export var num_coffins: int = 15
@export var num_open_coffins: int = 8
@export var num_holes: int = 12
@export var num_shovels: int = 10
@export var num_fences: int = 15
@export var num_lanterns: int = 8
@export var num_candle_graves: int = 10
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_generate_tombstones()
	_generate_cross_tombstones()
	_generate_dead_trees()
	_generate_coffins()
	_generate_open_coffins()
	_generate_holes()
	_generate_shovels()
	_generate_iron_fences()
	_generate_floating_lanterns()
	_generate_candle_graves()
	_generate_ambient_lights()
	_generate_ground_fog()
	_generate_fireflies()

## -------------------------------------------------------
## Lapides com variedade: rachadas, com musgo, inclinadas
## -------------------------------------------------------
func _generate_tombstones() -> void:
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.35, 0.35, 0.32)
	base_mat.roughness = 0.9

	var moss_mat = StandardMaterial3D.new()
	moss_mat.albedo_color = Color(0.15, 0.35, 0.12)
	moss_mat.roughness = 1.0

	var crack_mat = StandardMaterial3D.new()
	crack_mat.albedo_color = Color(0.22, 0.22, 0.2)
	crack_mat.roughness = 1.0

	for i in range(num_tombstones):
		var tombstone = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		## Evita o centro (spawn do player)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		tombstone.position = Vector3(x, 0, z)
		tombstone.rotation.y = rng.randf() * TAU

		## Variacao de tamanho maior
		var s = rng.randf_range(0.5, 1.6)
		tombstone.scale = Vector3(s, s, s)

		## Inclinacao aleatoria — algumas lapides tortas pelo tempo
		if rng.randf() < 0.35:
			tombstone.rotation.x = rng.randf_range(-0.12, 0.12)
			tombstone.rotation.z = rng.randf_range(-0.15, 0.15)

		## Corpo principal da lapide
		var tombstone_mesh = BoxMesh.new()
		var width = rng.randf_range(0.3, 0.55)
		var height = rng.randf_range(0.6, 1.1)
		tombstone_mesh.size = Vector3(width, height, 0.12)
		tombstone_mesh.surface_set_material(0, base_mat)
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = tombstone_mesh
		mesh_inst.position.y = height / 2.0
		tombstone.add_child(mesh_inst)

		## Base/pedestal da lapide
		var base_mesh = BoxMesh.new()
		base_mesh.size = Vector3(width + 0.1, 0.1, 0.2)
		base_mesh.surface_set_material(0, base_mat)
		var base_inst = MeshInstance3D.new()
		base_inst.mesh = base_mesh
		base_inst.position.y = 0.05
		tombstone.add_child(base_inst)

		## Musgo no topo (mancha verde)
		if rng.randf() < 0.4:
			var moss_mesh = BoxMesh.new()
			moss_mesh.size = Vector3(width * 0.6, 0.04, 0.13)
			moss_mesh.surface_set_material(0, moss_mat)
			var moss = MeshInstance3D.new()
			moss.mesh = moss_mesh
			moss.position.y = height - 0.02
			tombstone.add_child(moss)

		## Rachadura (tira fina escura na frente)
		if rng.randf() < 0.3:
			var crack_mesh = BoxMesh.new()
			crack_mesh.size = Vector3(0.02, height * rng.randf_range(0.3, 0.7), 0.13)
			crack_mesh.surface_set_material(0, crack_mat)
			var crack = MeshInstance3D.new()
			crack.mesh = crack_mesh
			crack.position = Vector3(rng.randf_range(-width * 0.3, width * 0.3), height * 0.4, 0)
			tombstone.add_child(crack)

		add_child(tombstone)

## -------------------------------------------------------
## Lapides em formato de cruz — segundo tipo
## -------------------------------------------------------
func _generate_cross_tombstones() -> void:
	var cross_mat = StandardMaterial3D.new()
	cross_mat.albedo_color = Color(0.4, 0.38, 0.35)
	cross_mat.roughness = 0.85

	var moss_mat = StandardMaterial3D.new()
	moss_mat.albedo_color = Color(0.12, 0.3, 0.1)
	moss_mat.roughness = 1.0

	## Gera cerca de 20 cruzes adicionais
	for i in range(20):
		var cross = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		cross.position = Vector3(x, 0, z)
		cross.rotation.y = rng.randf() * TAU

		var s = rng.randf_range(0.6, 1.3)
		cross.scale = Vector3(s, s, s)

		## Inclinacao sutil
		if rng.randf() < 0.3:
			cross.rotation.z = rng.randf_range(-0.1, 0.1)

		## Pilar vertical da cruz
		var vert_mesh = BoxMesh.new()
		vert_mesh.size = Vector3(0.1, 1.2, 0.1)
		vert_mesh.surface_set_material(0, cross_mat)
		var vert = MeshInstance3D.new()
		vert.mesh = vert_mesh
		vert.position.y = 0.6
		cross.add_child(vert)

		## Barra horizontal da cruz
		var horiz_mesh = BoxMesh.new()
		horiz_mesh.size = Vector3(0.6, 0.1, 0.1)
		horiz_mesh.surface_set_material(0, cross_mat)
		var horiz = MeshInstance3D.new()
		horiz.mesh = horiz_mesh
		horiz.position.y = 0.9
		cross.add_child(horiz)

		## Musgo ocasional no topo da cruz
		if rng.randf() < 0.35:
			var moss_mesh = BoxMesh.new()
			moss_mesh.size = Vector3(0.12, 0.04, 0.12)
			moss_mesh.surface_set_material(0, moss_mat)
			var moss = MeshInstance3D.new()
			moss.mesh = moss_mesh
			moss.position.y = 1.2
			cross.add_child(moss)

		add_child(cross)

## -------------------------------------------------------
## Arvores mortas com mais galhos, musgo pendente, wisps fantasmagoricos
## -------------------------------------------------------
func _generate_dead_trees() -> void:
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.2, 0.15, 0.1)
	trunk_mat.roughness = 0.9

	var vine_mat = StandardMaterial3D.new()
	vine_mat.albedo_color = Color(0.15, 0.28, 0.1)
	vine_mat.roughness = 0.85

	var wisp_mat = StandardMaterial3D.new()
	wisp_mat.albedo_color = Color(0.4, 0.8, 0.5, 0.6)
	wisp_mat.emission_enabled = true
	wisp_mat.emission = Color(0.3, 0.7, 0.5)
	wisp_mat.emission_energy_multiplier = 3.0
	wisp_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wisp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for i in range(num_trees):
		var tree = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 8 and abs(z) < 8:
			x += 12.0
		tree.position = Vector3(x, 0, z)

		## Tronco principal
		var trunk_mesh = CylinderMesh.new()
		trunk_mesh.top_radius = 0.08
		trunk_mesh.bottom_radius = rng.randf_range(0.18, 0.28)
		var tree_height = rng.randf_range(2.0, 4.5)
		trunk_mesh.height = tree_height
		trunk_mesh.surface_set_material(0, trunk_mat)

		var trunk = MeshInstance3D.new()
		trunk.mesh = trunk_mesh
		trunk.position.y = trunk_mesh.height / 2.0
		tree.add_child(trunk)

		## Galhos principais (3-6 cilindros finos inclinados)
		var num_branches = rng.randi_range(3, 6)
		for j in range(num_branches):
			var branch_mesh = CylinderMesh.new()
			branch_mesh.top_radius = 0.015
			branch_mesh.bottom_radius = rng.randf_range(0.04, 0.07)
			branch_mesh.height = rng.randf_range(0.6, 1.8)
			branch_mesh.surface_set_material(0, trunk_mat)

			var branch = MeshInstance3D.new()
			branch.mesh = branch_mesh
			branch.position.y = tree_height * rng.randf_range(0.4, 0.95)
			branch.rotation.z = rng.randf_range(-1.2, 1.2)
			branch.rotation.x = rng.randf_range(-0.6, 0.6)
			tree.add_child(branch)

			## Sub-galhos menores saindo dos galhos principais
			if rng.randf() < 0.5:
				var sub_mesh = CylinderMesh.new()
				sub_mesh.top_radius = 0.01
				sub_mesh.bottom_radius = 0.025
				sub_mesh.height = rng.randf_range(0.3, 0.7)
				sub_mesh.surface_set_material(0, trunk_mat)
				var sub_branch = MeshInstance3D.new()
				sub_branch.mesh = sub_mesh
				sub_branch.position.y = tree_height * rng.randf_range(0.5, 0.9)
				sub_branch.rotation.z = rng.randf_range(-1.5, 1.5)
				sub_branch.rotation.x = rng.randf_range(-0.8, 0.8)
				tree.add_child(sub_branch)

		## Musgo/cipó pendente (caixas finas verdes penduradas nos galhos)
		if rng.randf() < 0.6:
			var num_vines = rng.randi_range(2, 5)
			for v in range(num_vines):
				var vine_mesh = BoxMesh.new()
				var vine_length = rng.randf_range(0.5, 1.5)
				vine_mesh.size = Vector3(0.03, vine_length, 0.03)
				vine_mesh.surface_set_material(0, vine_mat)
				var vine = MeshInstance3D.new()
				vine.mesh = vine_mesh
				vine.position = Vector3(
					rng.randf_range(-0.5, 0.5),
					tree_height * rng.randf_range(0.5, 0.85) - vine_length * 0.3,
					rng.randf_range(-0.5, 0.5)
				)
				tree.add_child(vine)

		## Wisps fantasmagoricos perto de algumas arvores
		if rng.randf() < 0.4:
			var num_wisps = rng.randi_range(1, 3)
			for w in range(num_wisps):
				var wisp_mesh = SphereMesh.new()
				wisp_mesh.radius = rng.randf_range(0.06, 0.12)
				wisp_mesh.height = wisp_mesh.radius * 2.0
				wisp_mesh.surface_set_material(0, wisp_mat)
				var wisp = MeshInstance3D.new()
				wisp.mesh = wisp_mesh
				wisp.position = Vector3(
					rng.randf_range(-1.0, 1.0),
					rng.randf_range(1.0, tree_height * 0.8),
					rng.randf_range(-1.0, 1.0)
				)
				tree.add_child(wisp)

		add_child(tree)

## -------------------------------------------------------
## Caixoes fechados espalhados pelo cemiterio
## -------------------------------------------------------
func _generate_coffins() -> void:
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

		## Corpo do caixao (hexagonal simplificado como box)
		var body_mesh = BoxMesh.new()
		body_mesh.size = Vector3(0.6, 0.25, 1.8)
		body_mesh.surface_set_material(0, wood_mat)
		var body = MeshInstance3D.new()
		body.mesh = body_mesh
		body.position.y = 0.125
		coffin.add_child(body)

		## Tampa do caixao
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

		## Cruz na tampa
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

## -------------------------------------------------------
## Caixoes abertos — tampa inclinada, interior visivel
## -------------------------------------------------------
func _generate_open_coffins() -> void:
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

		## Corpo do caixao
		var body_mesh = BoxMesh.new()
		body_mesh.size = Vector3(0.6, 0.25, 1.8)
		body_mesh.surface_set_material(0, wood_mat)
		var body = MeshInstance3D.new()
		body.mesh = body_mesh
		body.position.y = 0.125
		coffin.add_child(body)

		## Interior escuro (um pouco menor)
		var inner_mesh = BoxMesh.new()
		inner_mesh.size = Vector3(0.5, 0.04, 1.7)
		inner_mesh.surface_set_material(0, inner_mat)
		var inner = MeshInstance3D.new()
		inner.mesh = inner_mesh
		inner.position.y = 0.24
		coffin.add_child(inner)

		## Tampa aberta (inclinada pra tras)
		var lid_mesh = BoxMesh.new()
		lid_mesh.size = Vector3(0.65, 0.06, 1.85)
		var lid_mat = StandardMaterial3D.new()
		lid_mat.albedo_color = Color(0.25, 0.14, 0.06)
		lid_mesh.surface_set_material(0, lid_mat)
		var lid = MeshInstance3D.new()
		lid.mesh = lid_mesh
		## Posiciona atras e inclinada
		lid.position = Vector3(0, 0.5, -0.85)
		lid.rotation.x = deg_to_rad(-60)
		coffin.add_child(lid)

		add_child(coffin)

## -------------------------------------------------------
## Buracos no chao — cilindros escuros rebaixados
## -------------------------------------------------------
func _generate_holes() -> void:
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

		## Buraco escuro (cilindro raso)
		var hole_mesh = CylinderMesh.new()
		hole_mesh.top_radius = rng.randf_range(0.5, 0.8)
		hole_mesh.bottom_radius = hole_mesh.top_radius * 0.8
		hole_mesh.height = 0.05
		hole_mesh.surface_set_material(0, hole_mat)
		var hole_inst = MeshInstance3D.new()
		hole_inst.mesh = hole_mesh
		hole_inst.position.y = 0.01
		hole.add_child(hole_inst)

		## Montinho de terra ao lado
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

## -------------------------------------------------------
## Pas fincadas no chao ou deitadas
## -------------------------------------------------------
func _generate_shovels() -> void:
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

		## Cabo da pa
		var handle_mesh = CylinderMesh.new()
		handle_mesh.top_radius = 0.02
		handle_mesh.bottom_radius = 0.025
		handle_mesh.height = 1.2
		handle_mesh.surface_set_material(0, handle_mat)
		var handle = MeshInstance3D.new()
		handle.mesh = handle_mesh

		## Lamina da pa
		var blade_mesh = BoxMesh.new()
		blade_mesh.size = Vector3(0.2, 0.02, 0.25)
		blade_mesh.surface_set_material(0, blade_mat)
		var blade = MeshInstance3D.new()
		blade.mesh = blade_mesh

		if rng.randf() < 0.6:
			## Fincada no chao (inclinada)
			var tilt = rng.randf_range(5, 25)
			shovel.rotation.x = deg_to_rad(tilt)
			handle.position.y = 0.6
			blade.position.y = -0.02
		else:
			## Deitada no chao
			shovel.rotation.x = deg_to_rad(85)
			handle.position = Vector3(0, 0.03, 0.5)
			blade.position = Vector3(0, 0.03, -0.1)

		shovel.add_child(handle)
		shovel.add_child(blade)
		add_child(shovel)

## -------------------------------------------------------
## Cercas de ferro gotico ao redor do perimetro
## -------------------------------------------------------
func _generate_iron_fences() -> void:
	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.12, 0.12, 0.14)
	iron_mat.roughness = 0.6
	iron_mat.metallic = 0.7

	var spike_mat = StandardMaterial3D.new()
	spike_mat.albedo_color = Color(0.1, 0.1, 0.12)
	spike_mat.roughness = 0.5
	spike_mat.metallic = 0.8

	## Distribui cercas ao longo do perimetro do mapa
	for i in range(num_fences):
		var fence = Node3D.new()

		## Posicao no perimetro (borda do mapa)
		var angle = (float(i) / float(num_fences)) * TAU
		var perimeter_dist = area_size * 0.85
		var fx = cos(angle) * perimeter_dist
		var fz = sin(angle) * perimeter_dist
		fence.position = Vector3(fx, 0, fz)
		## Rotaciona a cerca pra ficar tangente ao perimetro
		fence.rotation.y = angle + PI / 2.0

		## Barra horizontal inferior
		var bar_bottom_mesh = BoxMesh.new()
		bar_bottom_mesh.size = Vector3(4.0, 0.06, 0.06)
		bar_bottom_mesh.surface_set_material(0, iron_mat)
		var bar_bottom = MeshInstance3D.new()
		bar_bottom.mesh = bar_bottom_mesh
		bar_bottom.position.y = 0.4
		fence.add_child(bar_bottom)

		## Barra horizontal superior
		var bar_top_mesh = BoxMesh.new()
		bar_top_mesh.size = Vector3(4.0, 0.06, 0.06)
		bar_top_mesh.surface_set_material(0, iron_mat)
		var bar_top = MeshInstance3D.new()
		bar_top.mesh = bar_top_mesh
		bar_top.position.y = 1.4
		fence.add_child(bar_top)

		## Barras verticais com pontas (7 barras por segmento)
		for b in range(7):
			var bar_x = -1.5 + b * 0.5

			## Barra vertical
			var vert_mesh = CylinderMesh.new()
			vert_mesh.top_radius = 0.02
			vert_mesh.bottom_radius = 0.025
			vert_mesh.height = 1.6
			vert_mesh.surface_set_material(0, iron_mat)
			var vert = MeshInstance3D.new()
			vert.mesh = vert_mesh
			vert.position = Vector3(bar_x, 0.8, 0)
			fence.add_child(vert)

			## Ponta de lanca no topo (cone = cilindro com top_radius 0)
			var spike_mesh = CylinderMesh.new()
			spike_mesh.top_radius = 0.0
			spike_mesh.bottom_radius = 0.04
			spike_mesh.height = 0.15
			spike_mesh.surface_set_material(0, spike_mat)
			var spike = MeshInstance3D.new()
			spike.mesh = spike_mesh
			spike.position = Vector3(bar_x, 1.68, 0)
			fence.add_child(spike)

		add_child(fence)

## -------------------------------------------------------
## Lanternas flutuantes com luz fantasmagorica azul/verde
## -------------------------------------------------------
func _generate_floating_lanterns() -> void:
	var lantern_colors: Array[Color] = [
		Color(0.2, 0.6, 0.8),   ## Azul fantasma
		Color(0.15, 0.7, 0.4),  ## Verde espectral
		Color(0.3, 0.5, 0.9),   ## Azul celeste
		Color(0.1, 0.8, 0.6),   ## Ciano fantasma
	]

	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.15, 0.15, 0.17)
	frame_mat.roughness = 0.5
	frame_mat.metallic = 0.6

	for i in range(num_lanterns):
		var lantern = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		var float_height = rng.randf_range(2.5, 4.5)
		lantern.position = Vector3(x, float_height, z)

		var color = lantern_colors[rng.randi() % lantern_colors.size()]

		## Estrutura da lanterna (cubo pequeno = armacao)
		var frame_mesh = BoxMesh.new()
		frame_mesh.size = Vector3(0.2, 0.3, 0.2)
		frame_mesh.surface_set_material(0, frame_mat)
		var frame = MeshInstance3D.new()
		frame.mesh = frame_mesh
		lantern.add_child(frame)

		## Tampa da lanterna
		var top_mesh = BoxMesh.new()
		top_mesh.size = Vector3(0.25, 0.04, 0.25)
		top_mesh.surface_set_material(0, frame_mat)
		var top_inst = MeshInstance3D.new()
		top_inst.mesh = top_mesh
		top_inst.position.y = 0.17
		lantern.add_child(top_inst)

		## Chama interna emissiva
		var glow_mat = StandardMaterial3D.new()
		glow_mat.albedo_color = Color(color.r, color.g, color.b, 0.7)
		glow_mat.emission_enabled = true
		glow_mat.emission = color
		glow_mat.emission_energy_multiplier = 4.0
		glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

		var glow_mesh = SphereMesh.new()
		glow_mesh.radius = 0.08
		glow_mesh.height = 0.16
		glow_mesh.surface_set_material(0, glow_mat)
		var glow = MeshInstance3D.new()
		glow.mesh = glow_mesh
		lantern.add_child(glow)

		## Gancho no topo (cilindro curvo simplificado)
		var hook_mesh = CylinderMesh.new()
		hook_mesh.top_radius = 0.01
		hook_mesh.bottom_radius = 0.01
		hook_mesh.height = 0.2
		hook_mesh.surface_set_material(0, frame_mat)
		var hook = MeshInstance3D.new()
		hook.mesh = hook_mesh
		hook.position.y = 0.27
		lantern.add_child(hook)

		## Luz pontual da lanterna
		var light = OmniLight3D.new()
		light.light_color = color
		light.light_energy = rng.randf_range(1.5, 2.5)
		light.omni_range = rng.randf_range(6.0, 10.0)
		light.omni_attenuation = 1.5
		lantern.add_child(light)

		add_child(lantern)

## -------------------------------------------------------
## Lapides especiais com velas acesas
## -------------------------------------------------------
func _generate_candle_graves() -> void:
	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.32, 0.32, 0.3)
	stone_mat.roughness = 0.9

	var wax_mat = StandardMaterial3D.new()
	wax_mat.albedo_color = Color(0.85, 0.82, 0.7)
	wax_mat.roughness = 0.7

	var flame_mat = StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.7, 0.2, 0.9)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.6, 0.1)
	flame_mat.emission_energy_multiplier = 5.0
	flame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for i in range(num_candle_graves):
		var grave = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		grave.position = Vector3(x, 0, z)
		grave.rotation.y = rng.randf() * TAU

		## Lapide mais larga e baixa
		var stone_mesh = BoxMesh.new()
		stone_mesh.size = Vector3(0.5, 0.6, 0.12)
		stone_mesh.surface_set_material(0, stone_mat)
		var stone = MeshInstance3D.new()
		stone.mesh = stone_mesh
		stone.position.y = 0.3
		grave.add_child(stone)

		## Base
		var base_mesh = BoxMesh.new()
		base_mesh.size = Vector3(0.6, 0.08, 0.2)
		base_mesh.surface_set_material(0, stone_mat)
		var base_inst = MeshInstance3D.new()
		base_inst.mesh = base_mesh
		base_inst.position.y = 0.04
		grave.add_child(base_inst)

		## Velas (1-3 por lapide)
		var num_candles = rng.randi_range(1, 3)
		for c in range(num_candles):
			var candle_x = rng.randf_range(-0.2, 0.2)
			var candle_z = 0.15

			## Corpo da vela (cilindro fino)
			var candle_mesh = CylinderMesh.new()
			candle_mesh.top_radius = 0.02
			candle_mesh.bottom_radius = 0.025
			var candle_height = rng.randf_range(0.12, 0.25)
			candle_mesh.height = candle_height
			candle_mesh.surface_set_material(0, wax_mat)
			var candle = MeshInstance3D.new()
			candle.mesh = candle_mesh
			candle.position = Vector3(candle_x, candle_height / 2.0, candle_z)
			grave.add_child(candle)

			## Chama (esfera pequena emissiva)
			var flame_mesh = SphereMesh.new()
			flame_mesh.radius = 0.02
			flame_mesh.height = 0.05
			flame_mesh.surface_set_material(0, flame_mat)
			var flame = MeshInstance3D.new()
			flame.mesh = flame_mesh
			flame.position = Vector3(candle_x, candle_height + 0.02, candle_z)
			grave.add_child(flame)

		## Luz quente da vela
		var candle_light = OmniLight3D.new()
		candle_light.light_color = Color(1.0, 0.7, 0.3)
		candle_light.light_energy = rng.randf_range(0.6, 1.2)
		candle_light.omni_range = rng.randf_range(3.0, 5.0)
		candle_light.omni_attenuation = 1.8
		candle_light.position = Vector3(0, 0.4, 0.15)
		grave.add_child(candle_light)

		add_child(grave)

## -------------------------------------------------------
## Luzes ambiente com variedade de cores fantasmagoricas
## -------------------------------------------------------
func _generate_ambient_lights() -> void:
	var ghost_colors: Array[Color] = [
		Color(0.6, 0.75, 0.95),   ## Azul palido
		Color(0.4, 0.2, 0.7),     ## Roxo sombrio
		Color(0.2, 0.6, 0.4),     ## Verde espectral
		Color(0.3, 0.3, 0.9),     ## Azul profundo
		Color(0.5, 0.15, 0.6),    ## Roxo escuro
		Color(0.15, 0.7, 0.5),    ## Ciano fantasma
		Color(0.7, 0.3, 0.8),     ## Magenta suave
		Color(0.1, 0.5, 0.7),     ## Azul turquesa
	]

	for i in range(num_lights):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		light.position = Vector3(x, rng.randf_range(1.0, 3.0), z)
		light.light_color = ghost_colors[rng.randi() % ghost_colors.size()]
		light.light_energy = rng.randf_range(0.6, 2.0)
		light.omni_range = rng.randf_range(10.0, 22.0)
		light.omni_attenuation = rng.randf_range(1.5, 2.5)
		add_child(light)

## -------------------------------------------------------
## Nevoa no chao — duas camadas com alturas diferentes
## -------------------------------------------------------
func _generate_ground_fog() -> void:
	## Camada 1 — nevoa rasteira densa
	var fog1 = GPUParticles3D.new()
	var mat1 = ParticleProcessMaterial.new()
	mat1.direction = Vector3(1, 0, 0)
	mat1.spread = 180.0
	mat1.initial_velocity_min = 0.15
	mat1.initial_velocity_max = 0.4
	mat1.gravity = Vector3(0, 0, 0)
	mat1.scale_min = 2.5
	mat1.scale_max = 6.0
	mat1.color = Color(0.3, 0.35, 0.25, 0.15)
	mat1.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat1.emission_box_extents = Vector3(45, 0.1, 45)

	fog1.process_material = mat1
	fog1.amount = 60
	fog1.lifetime = 10.0
	fog1.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 3, 120))

	var draw_pass1 = SphereMesh.new()
	draw_pass1.radius = 1.2
	draw_pass1.height = 0.3
	var fog_mat1 = StandardMaterial3D.new()
	fog_mat1.albedo_color = Color(0.3, 0.35, 0.25, 0.1)
	fog_mat1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_mat1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass1.surface_set_material(0, fog_mat1)
	fog1.draw_pass_1 = draw_pass1

	fog1.position = Vector3(0, 0.2, 0)
	add_child(fog1)

	## Camada 2 — nevoa fina mais alta e espalhada
	var fog2 = GPUParticles3D.new()
	var mat2 = ParticleProcessMaterial.new()
	mat2.direction = Vector3(0.5, 0.1, 0.5)
	mat2.spread = 180.0
	mat2.initial_velocity_min = 0.1
	mat2.initial_velocity_max = 0.3
	mat2.gravity = Vector3(0, 0, 0)
	mat2.scale_min = 3.0
	mat2.scale_max = 8.0
	mat2.color = Color(0.25, 0.3, 0.35, 0.08)
	mat2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat2.emission_box_extents = Vector3(50, 0.2, 50)

	fog2.process_material = mat2
	fog2.amount = 35
	fog2.lifetime = 12.0
	fog2.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 5, 120))

	var draw_pass2 = SphereMesh.new()
	draw_pass2.radius = 1.5
	draw_pass2.height = 0.4
	var fog_mat2 = StandardMaterial3D.new()
	fog_mat2.albedo_color = Color(0.2, 0.25, 0.3, 0.06)
	fog_mat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass2.surface_set_material(0, fog_mat2)
	fog2.draw_pass_1 = draw_pass2

	fog2.position = Vector3(0, 1.0, 0)
	add_child(fog2)

## -------------------------------------------------------
## Vagalumes — particulas emissivas flutuando lentamente
## -------------------------------------------------------
func _generate_fireflies() -> void:
	var fireflies = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0.5, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 0.1
	mat.initial_velocity_max = 0.4
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.6
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(50, 2, 50)

	## Cores alternando entre verde e azul espectral
	mat.color = Color(0.3, 0.9, 0.5, 0.9)

	fireflies.process_material = mat
	fireflies.amount = 50
	fireflies.lifetime = 6.0
	fireflies.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 8, 120))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.04
	draw_pass.height = 0.04
	var fly_mat = StandardMaterial3D.new()
	fly_mat.albedo_color = Color(0.3, 1.0, 0.5, 0.9)
	fly_mat.emission_enabled = true
	fly_mat.emission = Color(0.2, 0.8, 0.4)
	fly_mat.emission_energy_multiplier = 5.0
	fly_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fly_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, fly_mat)
	fireflies.draw_pass_1 = draw_pass

	fireflies.position = Vector3(0, 1.5, 0)
	add_child(fireflies)

	## Segunda camada de vagalumes azuis
	var fireflies2 = GPUParticles3D.new()
	var mat2 = ParticleProcessMaterial.new()
	mat2.direction = Vector3(0, 0.3, 0)
	mat2.spread = 180.0
	mat2.initial_velocity_min = 0.05
	mat2.initial_velocity_max = 0.25
	mat2.gravity = Vector3(0, 0, 0)
	mat2.scale_min = 0.2
	mat2.scale_max = 0.5
	mat2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat2.emission_box_extents = Vector3(45, 3, 45)
	mat2.color = Color(0.3, 0.5, 1.0, 0.8)

	fireflies2.process_material = mat2
	fireflies2.amount = 30
	fireflies2.lifetime = 8.0
	fireflies2.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 8, 120))

	var draw_pass2 = SphereMesh.new()
	draw_pass2.radius = 0.03
	draw_pass2.height = 0.03
	var fly_mat2 = StandardMaterial3D.new()
	fly_mat2.albedo_color = Color(0.3, 0.5, 1.0, 0.85)
	fly_mat2.emission_enabled = true
	fly_mat2.emission = Color(0.2, 0.4, 0.9)
	fly_mat2.emission_energy_multiplier = 4.0
	fly_mat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fly_mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass2.surface_set_material(0, fly_mat2)
	fireflies2.draw_pass_1 = draw_pass2

	fireflies2.position = Vector3(0, 2.5, 0)
	add_child(fireflies2)
