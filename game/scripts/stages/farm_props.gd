extends Node3D

## Gera props aleatorios na Fazenda do Apocalipse estilo BotW: silos, milharal
## com mecanica de esconder, fardos de feno empilhados, cercas quebradas, trator,
## moinho de vento, espantalhos, aboboras, poco, galinheiro, flores silvestres.
## Iluminacao quente de golden hour.

@export var num_silos: int = 3
@export var num_corn_stalks: int = 20
@export var num_hay_bales: int = 10
@export var num_fences: int = 8
@export var num_pumpkins: int = 15
@export var num_scarecrows: int = 4
@export var num_wildflowers: int = 25
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Referencia para rotacao das pas do moinho
var _windmill_blades: Node3D = null

var corn_hide_area: Area3D = null

func _ready() -> void:
	rng.randomize()
	_generate_silos()
	_generate_corn_field()
	_generate_hay_bales()
	_generate_broken_fences()
	_generate_broken_tractor()
	_generate_windmill()
	_generate_scarecrows()
	_generate_pumpkin_patch()
	_generate_water_well()
	_generate_chicken_coop()
	_generate_wildflowers()
	_generate_ambient_lights()
	_generate_dust_particles()
	_generate_pollen_particles()
	_add_real_models()

func _add_real_models() -> void:
	## Adiciona modelos Kenney reais — arvores outonais, cercas, cultivos
	ModelFactory.scatter_nature_props(self, "tree_fall", 15, area_size, Vector2(1.5, 3.0))
	ModelFactory.scatter_nature_props(self, "tree", 5, area_size, Vector2(1.5, 2.5))
	ModelFactory.scatter_nature_props(self, "fence", 15, area_size, Vector2(1.0, 1.5))
	ModelFactory.scatter_nature_props(self, "crops", 20, area_size, Vector2(1.0, 1.5))
	ModelFactory.scatter_nature_props(self, "rock_small", 10, area_size, Vector2(0.6, 1.2))
	ModelFactory.scatter_nature_props(self, "grass", 25, area_size, Vector2(1.0, 2.0))
	ModelFactory.scatter_nature_props(self, "flower", 15, area_size, Vector2(0.8, 1.5))
	ModelFactory.scatter_nature_props(self, "log", 5, area_size, Vector2(1.0, 1.5))
	ModelFactory.scatter_nature_props(self, "bush", 8, area_size, Vector2(1.0, 1.8))

func _process(delta: float) -> void:
	## Rotacao lenta das pas do moinho
	if _windmill_blades and is_instance_valid(_windmill_blades):
		_windmill_blades.rotation.z += delta * 0.4

## ─── SILOS ───────────────────────────────────────────────────────────────────

func _generate_silos() -> void:
	for i in range(num_silos):
		var silo = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 10 and abs(z) < 10:
			x += 15.0
		silo.position = Vector3(x, 0, z)

		## Corpo do silo (cilindro alto)
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

		## Topo do silo (cone)
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

## ─── MILHARAL COM MECANICA DE ESCONDER ───────────────────────────────────────

func _generate_corn_field() -> void:
	## Milho em fileiras mais densas
	var start_x = rng.randf_range(-30, -10)
	var start_z = rng.randf_range(-30, -10)
	var row_spacing = 1.8
	var col_spacing = 1.3
	var stalks_per_row = 6
	var num_rows = int(num_corn_stalks / stalks_per_row) + 1

	var stalk_mat = StandardMaterial3D.new()
	stalk_mat.albedo_color = Color(0.4, 0.55, 0.15)
	stalk_mat.roughness = 0.8

	var leaf_mat = StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.45, 0.6, 0.1)
	leaf_mat.roughness = 0.7

	var ear_mat = StandardMaterial3D.new()
	ear_mat.albedo_color = Color(0.9, 0.8, 0.2)
	ear_mat.roughness = 0.75

	var husk_mat = StandardMaterial3D.new()
	husk_mat.albedo_color = Color(0.35, 0.5, 0.1)
	husk_mat.roughness = 0.7

	for row in range(num_rows):
		for col_idx in range(stalks_per_row):
			var stalk = Node3D.new()
			var x = start_x + col_idx * col_spacing + rng.randf_range(-0.3, 0.3)
			var z = start_z + row * row_spacing + rng.randf_range(-0.3, 0.3)
			stalk.position = Vector3(x, 0, z)

			## Caule
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

			## Folhas (boxes finos inclinados)
			for l in range(rng.randi_range(2, 4)):
				var leaf_mesh = BoxMesh.new()
				leaf_mesh.size = Vector3(0.6, 0.02, 0.15)
				leaf_mesh.surface_set_material(0, leaf_mat)
				var leaf = MeshInstance3D.new()
				leaf.mesh = leaf_mesh
				leaf.position.y = height * rng.randf_range(0.3, 0.8)
				leaf.rotation.z = rng.randf_range(-0.8, 0.8)
				leaf.rotation.y = rng.randf() * TAU
				stalk.add_child(leaf)

			## Espiga de milho (cilindro amarelo com folha verde)
			if rng.randf() < 0.6:
				var ear_mesh = CylinderMesh.new()
				ear_mesh.top_radius = 0.04
				ear_mesh.bottom_radius = 0.06
				ear_mesh.height = 0.3
				ear_mesh.surface_set_material(0, ear_mat)
				var ear_inst = MeshInstance3D.new()
				ear_inst.mesh = ear_mesh
				ear_inst.position = Vector3(rng.randf_range(-0.1, 0.1), height * 0.6, 0.08)
				ear_inst.rotation.z = rng.randf_range(0.3, 0.8)
				stalk.add_child(ear_inst)

				## Folha da espiga (husk)
				var husk_mesh = BoxMesh.new()
				husk_mesh.size = Vector3(0.12, 0.25, 0.02)
				husk_mesh.surface_set_material(0, husk_mat)
				var husk_inst = MeshInstance3D.new()
				husk_inst.mesh = husk_mesh
				husk_inst.position = ear_inst.position + Vector3(0.06, 0, 0)
				husk_inst.rotation.z = ear_inst.rotation.z + 0.2
				stalk.add_child(husk_inst)

			add_child(stalk)

	## Zona de esconderijo sobre o milharal — MECANICA DE GAMEPLAY
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

## ─── FARDOS DE FENO EMPILHADOS ───────────────────────────────────────────────

func _generate_hay_bales() -> void:
	var hay_mat = StandardMaterial3D.new()
	hay_mat.albedo_color = Color(0.75, 0.65, 0.3)
	hay_mat.roughness = 0.95

	var bales_placed = 0
	while bales_placed < num_hay_bales:
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0

		## Decidir se e um grupo empilhado ou individual
		var stack_count = 1
		if rng.randf() < 0.35 and bales_placed + 3 <= num_hay_bales:
			stack_count = rng.randi_range(2, 3)

		for s in range(stack_count):
			var is_round = rng.randf() < 0.4
			var bale: MeshInstance3D

			if is_round:
				## Fardo redondo
				var cyl_mesh = CylinderMesh.new()
				cyl_mesh.top_radius = 0.6
				cyl_mesh.bottom_radius = 0.6
				cyl_mesh.height = 0.8
				cyl_mesh.surface_set_material(0, hay_mat)
				bale = MeshInstance3D.new()
				bale.mesh = cyl_mesh
			else:
				## Fardo retangular
				var bale_mesh = BoxMesh.new()
				bale_mesh.size = Vector3(
					rng.randf_range(0.8, 1.4),
					rng.randf_range(0.5, 0.8),
					rng.randf_range(0.6, 1.0)
				)
				bale_mesh.surface_set_material(0, hay_mat)
				bale = MeshInstance3D.new()
				bale.mesh = bale_mesh

			## Empilhar verticalmente
			var stack_y = 0.4 + s * 0.75
			bale.position = Vector3(x + rng.randf_range(-0.2, 0.2), stack_y, z + rng.randf_range(-0.2, 0.2))
			bale.rotation.y = rng.randf() * TAU
			if s > 0:
				bale.rotation.z = rng.randf_range(-0.08, 0.08)
			add_child(bale)

			bales_placed += 1
			if bales_placed >= num_hay_bales:
				break

		## Particulas de palha perto dos fardos
		if stack_count > 1:
			_add_straw_particles(Vector3(x, 0.5, z))

## Particulas de palha flutuando perto dos fardos
func _add_straw_particles(pos: Vector3) -> void:
	var straw = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0.5, 0)
	mat.spread = 90.0
	mat.initial_velocity_min = 0.05
	mat.initial_velocity_max = 0.15
	mat.gravity = Vector3(0, -0.05, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.8
	mat.color = Color(0.8, 0.7, 0.3, 0.15)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(1.5, 0.3, 1.5)

	straw.process_material = mat
	straw.amount = 8
	straw.lifetime = 4.0
	straw.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 4, 6))

	var draw_pass = BoxMesh.new()
	draw_pass.size = Vector3(0.15, 0.02, 0.02)
	var straw_mat = StandardMaterial3D.new()
	straw_mat.albedo_color = Color(0.85, 0.75, 0.35, 0.2)
	straw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	straw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, straw_mat)
	straw.draw_pass_1 = draw_pass

	straw.position = pos
	add_child(straw)

## ─── CERCAS QUEBRADAS (MAIS LONGAS) ──────────────────────────────────────────

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

		## Mais postes para cercas mais longas
		var num_posts = rng.randi_range(3, 6)
		for p in range(num_posts):
			var post_mesh = BoxMesh.new()
			post_mesh.size = Vector3(0.1, rng.randf_range(0.6, 1.2), 0.1)
			post_mesh.surface_set_material(0, fence_mat)
			var post = MeshInstance3D.new()
			post.mesh = post_mesh
			post.position = Vector3(p * 1.5, post_mesh.size.y / 2.0, 0)
			## Alguns postes inclinados (quebrados)
			if rng.randf() < 0.35:
				post.rotation.z = rng.randf_range(-0.5, 0.5)
				post.rotation.x = rng.randf_range(-0.25, 0.25)
			fence.add_child(post)

		## Barras horizontais (algumas caidas)
		for b in range(rng.randi_range(1, 3)):
			var bar_mesh = BoxMesh.new()
			bar_mesh.size = Vector3(num_posts * 1.5, 0.06, 0.06)
			bar_mesh.surface_set_material(0, fence_mat)
			var bar = MeshInstance3D.new()
			bar.mesh = bar_mesh
			bar.position = Vector3((num_posts - 1) * 0.75, 0.3 + b * 0.3, 0)
			if rng.randf() < 0.3:
				bar.rotation.z = rng.randf_range(-0.25, 0.25)
			fence.add_child(bar)

		## Secao caida (tabuas no chao)
		if rng.randf() < 0.4:
			var fallen_mesh = BoxMesh.new()
			fallen_mesh.size = Vector3(rng.randf_range(1.5, 3.0), 0.06, 0.06)
			fallen_mesh.surface_set_material(0, fence_mat)
			var fallen = MeshInstance3D.new()
			fallen.mesh = fallen_mesh
			fallen.position = Vector3(num_posts * 1.5 + 1.0, 0.04, rng.randf_range(-0.3, 0.3))
			fallen.rotation.y = rng.randf_range(-0.3, 0.3)
			fence.add_child(fallen)

		add_child(fence)

## ─── TRATOR QUEBRADO ─────────────────────────────────────────────────────────

func _generate_broken_tractor() -> void:
	var tractor = Node3D.new()
	## Posicao fixa, longe do spawn
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

	## Corpo principal
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(2.0, 1.2, 3.5)
	body_mesh.surface_set_material(0, red_mat)
	var body = MeshInstance3D.new()
	body.mesh = body_mesh
	body.position = Vector3(0, 1.0, 0)
	tractor.add_child(body)

	## Capo (frente)
	var hood_mesh = BoxMesh.new()
	hood_mesh.size = Vector3(1.5, 0.8, 2.0)
	hood_mesh.surface_set_material(0, rust_mat)
	var hood = MeshInstance3D.new()
	hood.mesh = hood_mesh
	hood.position = Vector3(0, 0.7, -2.5)
	tractor.add_child(hood)

	## Cabine
	var cabin_mesh = BoxMesh.new()
	cabin_mesh.size = Vector3(1.8, 1.2, 1.5)
	cabin_mesh.surface_set_material(0, red_mat)
	var cabin = MeshInstance3D.new()
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 2.0, 0.5)
	## Cabine levemente torta (trator quebrado)
	cabin.rotation.z = 0.08
	tractor.add_child(cabin)

	## Rodas (cilindros)
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
		## Uma roda faltando/caida
		if w == 0:
			wheel.position.y = 0.2
			wheel.rotation.x = 0.5
		tractor.add_child(wheel)

	## Escapamento (cilindro fino vertical)
	var exhaust_mesh = CylinderMesh.new()
	exhaust_mesh.top_radius = 0.06
	exhaust_mesh.bottom_radius = 0.08
	exhaust_mesh.height = 1.5
	exhaust_mesh.surface_set_material(0, dark_mat)
	var exhaust = MeshInstance3D.new()
	exhaust.mesh = exhaust_mesh
	exhaust.position = Vector3(0.5, 2.0, -1.8)
	## Escapamento torto
	exhaust.rotation.z = 0.15
	tractor.add_child(exhaust)

	add_child(tractor)

## ─── MOINHO DE VENTO ─────────────────────────────────────────────────────────

func _generate_windmill() -> void:
	var windmill = Node3D.new()
	## Posicionar longe do centro
	var wm_x = rng.randf_range(25, 40) * (1 if rng.randf() > 0.5 else -1)
	var wm_z = rng.randf_range(25, 40) * (1 if rng.randf() > 0.5 else -1)
	windmill.position = Vector3(wm_x, 0, wm_z)

	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.6, 0.55, 0.45)
	stone_mat.roughness = 0.9

	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.35, 0.25, 0.15)
	roof_mat.roughness = 0.85

	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.4, 0.3, 0.18)
	wood_mat.roughness = 0.9

	## Corpo do moinho (caixa alta)
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(3.0, 8.0, 3.0)
	body_mesh.surface_set_material(0, stone_mat)
	var body_inst = MeshInstance3D.new()
	body_inst.mesh = body_mesh
	body_inst.position.y = 4.0
	windmill.add_child(body_inst)

	## Telhado conico
	var roof_mesh = CylinderMesh.new()
	roof_mesh.top_radius = 0.2
	roof_mesh.bottom_radius = 2.3
	roof_mesh.height = 2.5
	roof_mesh.surface_set_material(0, roof_mat)
	var roof_inst = MeshInstance3D.new()
	roof_inst.mesh = roof_mesh
	roof_inst.position.y = 9.25
	windmill.add_child(roof_inst)

	## Porta
	var door_mesh = BoxMesh.new()
	door_mesh.size = Vector3(0.8, 1.6, 0.05)
	var door_mat = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.3, 0.2, 0.1)
	door_mat.roughness = 0.9
	door_mesh.surface_set_material(0, door_mat)
	var door_inst = MeshInstance3D.new()
	door_inst.mesh = door_mesh
	door_inst.position = Vector3(0, 0.8, 1.53)
	windmill.add_child(door_inst)

	## Janelas
	for win_y in [3.5, 6.0]:
		var win_mesh = BoxMesh.new()
		win_mesh.size = Vector3(0.5, 0.5, 0.05)
		var win_mat = StandardMaterial3D.new()
		win_mat.albedo_color = Color(0.6, 0.5, 0.3, 0.6)
		win_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		win_mat.emission_enabled = true
		win_mat.emission = Color(0.8, 0.6, 0.2)
		win_mat.emission_energy_multiplier = 0.5
		win_mesh.surface_set_material(0, win_mat)
		var win_inst = MeshInstance3D.new()
		win_inst.mesh = win_mesh
		win_inst.position = Vector3(0, win_y, 1.53)
		windmill.add_child(win_inst)

	## Eixo das pas
	var axle_mesh = CylinderMesh.new()
	axle_mesh.top_radius = 0.1
	axle_mesh.bottom_radius = 0.1
	axle_mesh.height = 0.6
	axle_mesh.surface_set_material(0, wood_mat)
	var axle_inst = MeshInstance3D.new()
	axle_inst.mesh = axle_mesh
	axle_inst.position = Vector3(0, 7.5, 1.8)
	axle_inst.rotation.x = PI / 2.0
	windmill.add_child(axle_inst)

	## Pas (4 bracos em cruz) — rotacionam via _process
	_windmill_blades = Node3D.new()
	_windmill_blades.position = Vector3(0, 7.5, 2.1)

	for blade_idx in range(4):
		var blade_arm = BoxMesh.new()
		blade_arm.size = Vector3(0.12, 4.0, 0.05)
		blade_arm.surface_set_material(0, wood_mat)
		var arm_inst = MeshInstance3D.new()
		arm_inst.mesh = blade_arm
		var angle = (float(blade_idx) / 4.0) * TAU
		arm_inst.position = Vector3(cos(angle) * 2.0, sin(angle) * 2.0, 0)
		arm_inst.rotation.z = angle
		_windmill_blades.add_child(arm_inst)

		## Tecido da pa (caixa fina ao lado do braco)
		var sail_mesh = BoxMesh.new()
		sail_mesh.size = Vector3(0.8, 3.5, 0.02)
		var sail_mat = StandardMaterial3D.new()
		sail_mat.albedo_color = Color(0.85, 0.8, 0.7, 0.8)
		sail_mat.roughness = 0.9
		sail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sail_mesh.surface_set_material(0, sail_mat)
		var sail_inst = MeshInstance3D.new()
		sail_inst.mesh = sail_mesh
		sail_inst.position = Vector3(cos(angle) * 2.0 + cos(angle + PI / 2.0) * 0.45, sin(angle) * 2.0 + sin(angle + PI / 2.0) * 0.45, 0)
		sail_inst.rotation.z = angle
		_windmill_blades.add_child(sail_inst)

	windmill.add_child(_windmill_blades)
	add_child(windmill)

## ─── ESPANTALHOS ─────────────────────────────────────────────────────────────

func _generate_scarecrows() -> void:
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.25, 0.12)
	wood_mat.roughness = 0.95

	var hay_body_mat = StandardMaterial3D.new()
	hay_body_mat.albedo_color = Color(0.7, 0.6, 0.25)
	hay_body_mat.roughness = 0.95

	var hat_mat = StandardMaterial3D.new()
	hat_mat.albedo_color = Color(0.3, 0.2, 0.1)
	hat_mat.roughness = 0.9

	var cloth_mat = StandardMaterial3D.new()
	cloth_mat.albedo_color = Color(0.4, 0.25, 0.2)
	cloth_mat.roughness = 0.85

	for i in range(num_scarecrows):
		var sc = Node3D.new()
		var angle = (float(i) / num_scarecrows) * TAU + rng.randf_range(-0.3, 0.3)
		var dist = rng.randf_range(20, 45)
		sc.position = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		sc.rotation.y = rng.randf() * TAU

		## Poste vertical
		var post_mesh = CylinderMesh.new()
		post_mesh.top_radius = 0.05
		post_mesh.bottom_radius = 0.07
		post_mesh.height = 2.5
		post_mesh.surface_set_material(0, wood_mat)
		var post_inst = MeshInstance3D.new()
		post_inst.mesh = post_mesh
		post_inst.position.y = 1.25
		sc.add_child(post_inst)

		## Braco horizontal (cruz)
		var arm_mesh = CylinderMesh.new()
		arm_mesh.top_radius = 0.04
		arm_mesh.bottom_radius = 0.04
		arm_mesh.height = 1.8
		arm_mesh.surface_set_material(0, wood_mat)
		var arm_inst = MeshInstance3D.new()
		arm_inst.mesh = arm_mesh
		arm_inst.position.y = 2.0
		arm_inst.rotation.z = PI / 2.0
		sc.add_child(arm_inst)

		## Corpo de palha (caixa)
		var body_mesh = BoxMesh.new()
		body_mesh.size = Vector3(0.5, 0.7, 0.3)
		body_mesh.surface_set_material(0, hay_body_mat)
		var body_inst = MeshInstance3D.new()
		body_inst.mesh = body_mesh
		body_inst.position.y = 1.8
		sc.add_child(body_inst)

		## Cabeca (esfera)
		var head_mesh = SphereMesh.new()
		head_mesh.radius = 0.2
		head_mesh.height = 0.35
		head_mesh.surface_set_material(0, hay_body_mat)
		var head_inst = MeshInstance3D.new()
		head_inst.mesh = head_mesh
		head_inst.position.y = 2.45
		sc.add_child(head_inst)

		## Chapeu
		var brim_mesh = CylinderMesh.new()
		brim_mesh.top_radius = 0.35
		brim_mesh.bottom_radius = 0.35
		brim_mesh.height = 0.04
		brim_mesh.surface_set_material(0, hat_mat)
		var brim_inst = MeshInstance3D.new()
		brim_inst.mesh = brim_mesh
		brim_inst.position.y = 2.6
		sc.add_child(brim_inst)

		var crown_mesh = CylinderMesh.new()
		crown_mesh.top_radius = 0.18
		crown_mesh.bottom_radius = 0.2
		crown_mesh.height = 0.25
		crown_mesh.surface_set_material(0, hat_mat)
		var crown_inst = MeshInstance3D.new()
		crown_inst.mesh = crown_mesh
		crown_inst.position.y = 2.75
		sc.add_child(crown_inst)

		## Roupa pendurada (caixa fina nos bracos)
		var sleeve_mesh = BoxMesh.new()
		sleeve_mesh.size = Vector3(0.15, 0.4, 0.12)
		sleeve_mesh.surface_set_material(0, cloth_mat)
		for side in [-0.7, 0.7]:
			var sleeve_inst = MeshInstance3D.new()
			sleeve_inst.mesh = sleeve_mesh
			sleeve_inst.position = Vector3(side, 1.85, 0)
			sleeve_inst.rotation.z = rng.randf_range(-0.15, 0.15)
			sc.add_child(sleeve_inst)

		add_child(sc)

## ─── PLANTACAO DE ABOBORAS ───────────────────────────────────────────────────

func _generate_pumpkin_patch() -> void:
	for i in range(num_pumpkins):
		var pumpkin = Node3D.new()
		var x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		var z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		if abs(x) < 5 and abs(z) < 5:
			x += 7.0
		pumpkin.position = Vector3(x, 0, z)

		## Corpo da abobora (esfera achatada = laranja)
		var body_mesh = SphereMesh.new()
		var pump_size = rng.randf_range(0.2, 0.45)
		body_mesh.radius = pump_size
		body_mesh.height = pump_size * 1.3  # Levemente achatada
		var body_mat = StandardMaterial3D.new()
		body_mat.albedo_color = Color(
			rng.randf_range(0.85, 1.0),
			rng.randf_range(0.4, 0.6),
			rng.randf_range(0.0, 0.1)
		)
		body_mat.roughness = 0.7
		body_mesh.surface_set_material(0, body_mat)
		var body_inst = MeshInstance3D.new()
		body_inst.mesh = body_mesh
		body_inst.position.y = pump_size * 0.65
		pumpkin.add_child(body_inst)

		## Talo verde no topo
		var stem_mesh = CylinderMesh.new()
		stem_mesh.top_radius = 0.02
		stem_mesh.bottom_radius = 0.03
		stem_mesh.height = 0.12
		var stem_mat = StandardMaterial3D.new()
		stem_mat.albedo_color = Color(0.2, 0.4, 0.1)
		stem_mat.roughness = 0.8
		stem_mesh.surface_set_material(0, stem_mat)
		var stem_inst = MeshInstance3D.new()
		stem_inst.mesh = stem_mesh
		stem_inst.position.y = pump_size * 1.3 + 0.06
		pumpkin.add_child(stem_inst)

		add_child(pumpkin)

## ─── POCO DE AGUA ────────────────────────────────────────────────────────────

func _generate_water_well() -> void:
	var well = Node3D.new()
	var well_x = rng.randf_range(-25, -10) * (1 if rng.randf() > 0.5 else -1)
	var well_z = rng.randf_range(15, 30) * (1 if rng.randf() > 0.5 else -1)
	well.position = Vector3(well_x, 0, well_z)

	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.5, 0.48, 0.42)
	stone_mat.roughness = 0.9

	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.25, 0.12)
	wood_mat.roughness = 0.9

	## Base do poco (cilindro oco = parede baixa)
	var wall_mesh = CylinderMesh.new()
	wall_mesh.top_radius = 0.9
	wall_mesh.bottom_radius = 1.0
	wall_mesh.height = 0.8
	wall_mesh.surface_set_material(0, stone_mat)
	var wall_inst = MeshInstance3D.new()
	wall_inst.mesh = wall_mesh
	wall_inst.position.y = 0.4
	well.add_child(wall_inst)

	## Interior escuro (cilindro menor escuro)
	var inner_mesh = CylinderMesh.new()
	inner_mesh.top_radius = 0.7
	inner_mesh.bottom_radius = 0.7
	inner_mesh.height = 0.05
	var inner_mat = StandardMaterial3D.new()
	inner_mat.albedo_color = Color(0.05, 0.08, 0.12)
	inner_mat.roughness = 1.0
	inner_mesh.surface_set_material(0, inner_mat)
	var inner_inst = MeshInstance3D.new()
	inner_inst.mesh = inner_mesh
	inner_inst.position.y = 0.82
	well.add_child(inner_inst)

	## Postes do telhado (2 verticais)
	for side in [-0.7, 0.7]:
		var post_mesh = CylinderMesh.new()
		post_mesh.top_radius = 0.05
		post_mesh.bottom_radius = 0.06
		post_mesh.height = 1.8
		post_mesh.surface_set_material(0, wood_mat)
		var post_inst = MeshInstance3D.new()
		post_inst.mesh = post_mesh
		post_inst.position = Vector3(side, 1.7, 0)
		well.add_child(post_inst)

	## Trave horizontal no topo
	var beam_mesh = BoxMesh.new()
	beam_mesh.size = Vector3(1.6, 0.08, 0.08)
	beam_mesh.surface_set_material(0, wood_mat)
	var beam_inst = MeshInstance3D.new()
	beam_inst.mesh = beam_mesh
	beam_inst.position.y = 2.65
	well.add_child(beam_inst)

	## Telhado em V (duas caixas inclinadas)
	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.3, 0.2, 0.1)
	roof_mat.roughness = 0.9

	for side_angle in [-0.5, 0.5]:
		var roof_mesh = BoxMesh.new()
		roof_mesh.size = Vector3(1.8, 0.05, 1.0)
		roof_mesh.surface_set_material(0, roof_mat)
		var roof_inst = MeshInstance3D.new()
		roof_inst.mesh = roof_mesh
		roof_inst.position = Vector3(0, 2.85, side_angle * 0.6)
		roof_inst.rotation.x = side_angle
		well.add_child(roof_inst)

	## Balde (caixinha pendurada)
	var bucket_mesh = BoxMesh.new()
	bucket_mesh.size = Vector3(0.2, 0.2, 0.2)
	var bucket_mat = StandardMaterial3D.new()
	bucket_mat.albedo_color = Color(0.4, 0.35, 0.3)
	bucket_mat.roughness = 0.8
	bucket_mat.metallic = 0.2
	bucket_mesh.surface_set_material(0, bucket_mat)
	var bucket_inst = MeshInstance3D.new()
	bucket_inst.mesh = bucket_mesh
	bucket_inst.position = Vector3(0, 1.5, 0)
	well.add_child(bucket_inst)

	## Corda (cilindro fino)
	var rope_mesh = CylinderMesh.new()
	rope_mesh.top_radius = 0.015
	rope_mesh.bottom_radius = 0.015
	rope_mesh.height = 1.1
	var rope_mat = StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.5, 0.4, 0.25)
	rope_mat.roughness = 0.95
	rope_mesh.surface_set_material(0, rope_mat)
	var rope_inst = MeshInstance3D.new()
	rope_inst.mesh = rope_mesh
	rope_inst.position = Vector3(0, 2.1, 0)
	well.add_child(rope_inst)

	add_child(well)

## ─── GALINHEIRO ──────────────────────────────────────────────────────────────

func _generate_chicken_coop() -> void:
	var coop = Node3D.new()
	var cx = rng.randf_range(10, 30) * (1 if rng.randf() > 0.5 else -1)
	var cz = rng.randf_range(-30, -10)
	coop.position = Vector3(cx, 0, cz)
	coop.rotation.y = rng.randf() * TAU

	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.4, 0.28, 0.12)
	wood_mat.roughness = 0.9

	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.5, 0.2, 0.15)
	roof_mat.roughness = 0.85

	## Corpo do galinheiro
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(2.0, 1.2, 1.5)
	body_mesh.surface_set_material(0, wood_mat)
	var body_inst = MeshInstance3D.new()
	body_inst.mesh = body_mesh
	body_inst.position.y = 0.6
	coop.add_child(body_inst)

	## Telhado inclinado (duas caixas em V)
	for side in [-0.35, 0.35]:
		var roof_mesh = BoxMesh.new()
		roof_mesh.size = Vector3(2.2, 0.06, 1.0)
		roof_mesh.surface_set_material(0, roof_mat)
		var roof_inst = MeshInstance3D.new()
		roof_inst.mesh = roof_mesh
		roof_inst.position = Vector3(0, 1.4, side)
		roof_inst.rotation.x = side * 1.2
		coop.add_child(roof_inst)

	## Porta pequena
	var door_mesh = BoxMesh.new()
	door_mesh.size = Vector3(0.4, 0.5, 0.05)
	var door_mat = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.3, 0.18, 0.08)
	door_mat.roughness = 0.9
	door_mesh.surface_set_material(0, door_mat)
	var door_inst = MeshInstance3D.new()
	door_inst.mesh = door_mesh
	door_inst.position = Vector3(0, 0.35, 0.76)
	coop.add_child(door_inst)

	## Galinhas (esferas brancas pequenas)
	var chicken_mat = StandardMaterial3D.new()
	chicken_mat.albedo_color = Color(0.92, 0.9, 0.85)
	chicken_mat.roughness = 0.8

	var beak_mat = StandardMaterial3D.new()
	beak_mat.albedo_color = Color(0.9, 0.6, 0.1)
	beak_mat.roughness = 0.7

	for c in range(4):
		var chicken = Node3D.new()
		chicken.position = Vector3(
			rng.randf_range(-2.0, 2.0),
			0,
			rng.randf_range(1.0, 3.0)
		)

		## Corpo
		var ch_body_mesh = SphereMesh.new()
		ch_body_mesh.radius = 0.12
		ch_body_mesh.height = 0.2
		ch_body_mesh.surface_set_material(0, chicken_mat)
		var ch_body = MeshInstance3D.new()
		ch_body.mesh = ch_body_mesh
		ch_body.position.y = 0.12
		chicken.add_child(ch_body)

		## Cabeca
		var ch_head_mesh = SphereMesh.new()
		ch_head_mesh.radius = 0.06
		ch_head_mesh.height = 0.1
		ch_head_mesh.surface_set_material(0, chicken_mat)
		var ch_head = MeshInstance3D.new()
		ch_head.mesh = ch_head_mesh
		ch_head.position = Vector3(0, 0.22, 0.08)
		chicken.add_child(ch_head)

		## Bico
		var beak_mesh = BoxMesh.new()
		beak_mesh.size = Vector3(0.03, 0.02, 0.04)
		beak_mesh.surface_set_material(0, beak_mat)
		var beak_inst = MeshInstance3D.new()
		beak_inst.mesh = beak_mesh
		beak_inst.position = Vector3(0, 0.21, 0.14)
		chicken.add_child(beak_inst)

		coop.add_child(chicken)

	add_child(coop)

## ─── FLORES SILVESTRES ───────────────────────────────────────────────────────

func _generate_wildflowers() -> void:
	var flower_colors: Array[Color] = [
		Color(1.0, 0.9, 0.2),   # Amarelo
		Color(1.0, 1.0, 0.95),  # Branco
		Color(0.6, 0.3, 0.8),   # Roxo
		Color(1.0, 0.4, 0.5),   # Rosa
		Color(0.3, 0.5, 1.0),   # Azul
	]

	var stem_mat = StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.25, 0.5, 0.15)
	stem_mat.roughness = 0.8

	for i in range(num_wildflowers):
		var flower = Node3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		flower.position = Vector3(x, 0, z)

		## Caule fino
		var stem_height = rng.randf_range(0.2, 0.5)
		var stem_mesh = CylinderMesh.new()
		stem_mesh.top_radius = 0.01
		stem_mesh.bottom_radius = 0.015
		stem_mesh.height = stem_height
		stem_mesh.surface_set_material(0, stem_mat)
		var stem_inst = MeshInstance3D.new()
		stem_inst.mesh = stem_mesh
		stem_inst.position.y = stem_height / 2.0
		flower.add_child(stem_inst)

		## Flor no topo (esfera colorida)
		var color = flower_colors[rng.randi() % flower_colors.size()]
		var bloom_mesh = SphereMesh.new()
		bloom_mesh.radius = rng.randf_range(0.04, 0.08)
		bloom_mesh.height = bloom_mesh.radius * 1.5
		var bloom_mat = StandardMaterial3D.new()
		bloom_mat.albedo_color = color
		bloom_mat.roughness = 0.5
		bloom_mat.emission_enabled = true
		bloom_mat.emission = color * 0.3
		bloom_mat.emission_energy_multiplier = 0.4
		bloom_mesh.surface_set_material(0, bloom_mat)
		var bloom_inst = MeshInstance3D.new()
		bloom_inst.mesh = bloom_mesh
		bloom_inst.position.y = stem_height + bloom_mesh.radius
		flower.add_child(bloom_inst)

		## Leve inclinacao
		flower.rotation = Vector3(
			rng.randf_range(-0.15, 0.15),
			rng.randf() * TAU,
			rng.randf_range(-0.1, 0.1)
		)

		add_child(flower)

## ─── ILUMINACAO GOLDEN HOUR BotW ─────────────────────────────────────────────

func _generate_ambient_lights() -> void:
	var light_configs: Array[Dictionary] = [
		{"color": Color(0.95, 0.75, 0.3), "energy": 0.5},  # Dourado quente
		{"color": Color(0.9, 0.55, 0.2), "energy": 0.45},  # Laranja por-do-sol
		{"color": Color(1.0, 0.85, 0.4), "energy": 0.4},   # Amarelo suave
		{"color": Color(0.85, 0.5, 0.25), "energy": 0.35},  # Ambar
		{"color": Color(1.0, 0.7, 0.35), "energy": 0.5},   # Golden
	]

	for i in range(10):
		var light = OmniLight3D.new()
		var config = light_configs[rng.randi() % light_configs.size()]

		var x: float
		var z: float
		var y: float
		if i < 4:
			## Luzes perto de estruturas (dramaticas)
			x = rng.randf_range(-area_size * 0.4, area_size * 0.4)
			z = rng.randf_range(-area_size * 0.4, area_size * 0.4)
			y = rng.randf_range(1.5, 3.0)
		elif i < 7:
			## Luzes medias espalhadas
			x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
			z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
			y = rng.randf_range(3.0, 5.0)
		else:
			## Luzes altas (simula sol)
			x = rng.randf_range(-area_size * 0.3, area_size * 0.3)
			z = rng.randf_range(-area_size * 0.3, area_size * 0.3)
			y = rng.randf_range(5.0, 8.0)

		light.position = Vector3(x, y, z)
		light.light_color = config["color"]
		light.light_energy = config["energy"]
		light.omni_range = rng.randf_range(10.0, 16.0)
		light.omni_attenuation = 1.8
		add_child(light)

## ─── POEIRA GOLDEN HOUR ──────────────────────────────────────────────────────

func _generate_dust_particles() -> void:
	## Particulas de poeira dourada flutuando
	var dust = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0.2, 0)
	mat.spread = 120.0
	mat.initial_velocity_min = 0.1
	mat.initial_velocity_max = 0.5
	mat.gravity = Vector3(0, -0.02, 0)
	mat.scale_min = 0.4
	mat.scale_max = 1.8
	mat.color = Color(0.85, 0.7, 0.3, 0.12)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(50, 2, 50)

	dust.process_material = mat
	dust.amount = 50
	dust.lifetime = 7.0
	dust.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 6, 120))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.3
	draw_pass.height = 0.15
	var dust_mat = StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.9, 0.75, 0.35, 0.1)
	dust_mat.emission_enabled = true
	dust_mat.emission = Color(0.85, 0.65, 0.2)
	dust_mat.emission_energy_multiplier = 0.3
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, dust_mat)
	dust.draw_pass_1 = draw_pass

	dust.position = Vector3(0, 1.5, 0)
	add_child(dust)

## Particulas de polen flutuando (pontos amarelos pequenos)
func _generate_pollen_particles() -> void:
	var pollen = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0.5, 0.3, 0.2)
	mat.spread = 160.0
	mat.initial_velocity_min = 0.02
	mat.initial_velocity_max = 0.1
	mat.gravity = Vector3(0, 0.01, 0)
	mat.scale_min = 0.2
	mat.scale_max = 0.5
	mat.color = Color(1.0, 0.9, 0.3, 0.2)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(40, 1.5, 40)

	pollen.process_material = mat
	pollen.amount = 40
	pollen.lifetime = 10.0
	pollen.visibility_aabb = AABB(Vector3(-50, -1, -50), Vector3(100, 5, 100))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.03
	draw_pass.height = 0.03
	var pollen_mat = StandardMaterial3D.new()
	pollen_mat.albedo_color = Color(1.0, 0.95, 0.4, 0.25)
	pollen_mat.emission_enabled = true
	pollen_mat.emission = Color(1.0, 0.85, 0.2)
	pollen_mat.emission_energy_multiplier = 0.8
	pollen_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pollen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, pollen_mat)
	pollen.draw_pass_1 = draw_pass

	pollen.position = Vector3(0, 1.0, 0)
	add_child(pollen)
