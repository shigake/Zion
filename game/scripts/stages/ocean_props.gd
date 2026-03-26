extends Node3D

## Gera props procedurais para Fundo do Oceano estilo BotW: recifes de coral
## bioluminescentes, bolhas cintilantes, ruinas antigas com arcos e estatuas,
## algas com movimento, aguas-vivas, baus de tesouro, naufragio, raios de luz.
## Correntes de agua empurram o jogador.

@export var num_corals: int = 40
@export var num_ruins: int = 15
@export var num_seaweed: int = 30
@export var num_current_zones: int = 6
@export var num_jellyfish: int = 10
@export var num_treasure_chests: int = 5
@export var num_starfish: int = 20
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var coral_colors: Array[Color] = [
	Color(1.0, 0.2, 0.45),  # Rosa coral vibrante
	Color(1.0, 0.5, 0.05),  # Laranja intenso
	Color(0.1, 0.95, 0.5),  # Verde neon
	Color(0.7, 0.15, 0.95), # Roxo vibrante
	Color(1.0, 0.85, 0.1),  # Amarelo dourado
	Color(0.0, 0.85, 0.85), # Ciano brilhante
	Color(1.0, 0.1, 0.1),   # Vermelho vivo
]

var current_zones: Array[Dictionary] = []
var current_timer: float = 0.0
var current_change_interval: float = 8.0

## Referencia para rotacao do moinho (N/A aqui, mas mantemos consistencia)
var _windmill_blades: MeshInstance3D = null

func _ready() -> void:
	rng.randomize()
	_generate_corals()
	_generate_bubbles()
	_generate_ruins()
	_generate_seaweed()
	_generate_kelp_forests()
	_generate_current_zones()
	_generate_jellyfish()
	_generate_treasure_chests()
	_generate_shipwreck()
	_generate_sea_floor_details()
	_generate_underwater_light_rays()
	_generate_ambient_lights()
	_add_real_models()

func _add_real_models() -> void:
	## Adiciona modelos Kenney — rochas, lirios, musgo (algas)
	ModelFactory.scatter_nature_props(self, "stone_large", 12, area_size, Vector2(1.5, 3.0))
	ModelFactory.scatter_nature_props(self, "stone_small", 15, area_size, Vector2(0.8, 1.5))
	ModelFactory.scatter_nature_props(self, "rock_large", 10, area_size, Vector2(1.5, 3.0))
	ModelFactory.scatter_nature_props(self, "lily", 12, area_size, Vector2(1.0, 2.0))
	ModelFactory.scatter_nature_props(self, "hanging_moss", 15, area_size, Vector2(1.0, 2.5))
	ModelFactory.scatter_nature_props(self, "plant_flat", 15, area_size, Vector2(1.0, 2.0))
	ModelFactory.scatter_nature_props(self, "grass", 20, area_size, Vector2(1.0, 2.0))

func _process(delta: float) -> void:
	## Muda direcao da corrente periodicamente
	current_timer += delta
	if current_timer >= current_change_interval:
		current_timer = 0.0
		for zone in current_zones:
			zone["direction"] = Vector3(
				rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)
			).normalized()

	## Aplica empurrao de corrente nos jogadores dentro das zonas
	for zone in current_zones:
		var area: Area3D = zone["area"]
		if not is_instance_valid(area):
			continue
		var bodies = area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("players") and body is CharacterBody3D:
				body.velocity += zone["direction"] * 3.0 * delta

## ─── CORAIS COM BIOLUMINESCENCIA ─────────────────────────────────────────────

func _generate_corals() -> void:
	for i in range(num_corals):
		var coral = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		coral.position = Vector3(x, 0, z)

		var color = coral_colors[rng.randi() % coral_colors.size()]
		var coral_type = rng.randi() % 3

		if coral_type == 0:
			## Coral esfera com polipos
			var mesh = SphereMesh.new()
			mesh.radius = rng.randf_range(0.5, 1.5)
			mesh.height = mesh.radius * 1.5
			var mat = StandardMaterial3D.new()
			mat.albedo_color = color
			mat.roughness = 0.5
			mat.emission_enabled = true
			mat.emission = color * 0.4
			mat.emission_energy_multiplier = 1.0
			mesh.surface_set_material(0, mat)

			var inst = MeshInstance3D.new()
			inst.mesh = mesh
			inst.position.y = mesh.radius * 0.5
			coral.add_child(inst)

			## Polipos pequenos (esferas minusculas na superficie)
			var num_polyps = rng.randi_range(3, 7)
			for p in range(num_polyps):
				var polyp_mesh = SphereMesh.new()
				polyp_mesh.radius = rng.randf_range(0.06, 0.12)
				polyp_mesh.height = polyp_mesh.radius * 2.0
				var polyp_mat = StandardMaterial3D.new()
				var polyp_color = color.lightened(0.3)
				polyp_mat.albedo_color = polyp_color
				polyp_mat.emission_enabled = true
				polyp_mat.emission = polyp_color
				polyp_mat.emission_energy_multiplier = 1.5
				polyp_mesh.surface_set_material(0, polyp_mat)
				var polyp_inst = MeshInstance3D.new()
				polyp_inst.mesh = polyp_mesh
				var angle_h = rng.randf() * TAU
				var angle_v = rng.randf_range(-0.5, 0.8)
				var r = mesh.radius * 0.95
				polyp_inst.position = Vector3(
					cos(angle_h) * cos(angle_v) * r,
					sin(angle_v) * r + mesh.radius * 0.5,
					sin(angle_h) * cos(angle_v) * r
				)
				coral.add_child(polyp_inst)

			## Bioluminescencia pulsante
			_add_bioluminescence_tween(inst, mat, color)

		elif coral_type == 1:
			## Coral cilindrico (tipo tubo) com polipos
			var num_tubes = rng.randi_range(2, 5)
			for t in range(num_tubes):
				var mesh = CylinderMesh.new()
				mesh.top_radius = rng.randf_range(0.1, 0.3)
				mesh.bottom_radius = rng.randf_range(0.15, 0.4)
				mesh.height = rng.randf_range(0.8, 2.5)
				var mat = StandardMaterial3D.new()
				mat.albedo_color = color
				mat.roughness = 0.45
				mat.emission_enabled = true
				mat.emission = color * 0.4
				mat.emission_energy_multiplier = 1.0
				mesh.surface_set_material(0, mat)

				var inst = MeshInstance3D.new()
				inst.mesh = mesh
				inst.position = Vector3(rng.randf_range(-0.5, 0.5), mesh.height / 2.0, rng.randf_range(-0.5, 0.5))
				inst.rotation = Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
				coral.add_child(inst)

				## Polipo no topo do tubo
				var polyp_mesh = SphereMesh.new()
				polyp_mesh.radius = mesh.top_radius * 1.2
				polyp_mesh.height = polyp_mesh.radius * 1.5
				var polyp_mat = StandardMaterial3D.new()
				var polyp_color = color.lightened(0.4)
				polyp_mat.albedo_color = polyp_color
				polyp_mat.emission_enabled = true
				polyp_mat.emission = polyp_color
				polyp_mat.emission_energy_multiplier = 2.0
				polyp_mesh.surface_set_material(0, polyp_mat)
				var polyp_inst = MeshInstance3D.new()
				polyp_inst.mesh = polyp_mesh
				polyp_inst.position = inst.position + Vector3(0, mesh.height / 2.0, 0)
				coral.add_child(polyp_inst)

				_add_bioluminescence_tween(inst, mat, color)
		else:
			## Coral plano (tipo leque) com brilho
			var mesh = BoxMesh.new()
			mesh.size = Vector3(rng.randf_range(1.0, 2.5), rng.randf_range(1.0, 2.0), 0.08)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(color.r, color.g, color.b, 0.85)
			mat.roughness = 0.35
			mat.emission_enabled = true
			mat.emission = color * 0.5
			mat.emission_energy_multiplier = 1.2
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.surface_set_material(0, mat)

			var inst = MeshInstance3D.new()
			inst.mesh = mesh
			inst.position.y = mesh.size.y / 2.0
			inst.rotation.y = rng.randf_range(0, TAU)
			coral.add_child(inst)

			_add_bioluminescence_tween(inst, mat, color)

		add_child(coral)

## Cria tween de pulsacao bioluminescente no coral
func _add_bioluminescence_tween(inst: MeshInstance3D, mat: StandardMaterial3D, color: Color) -> void:
	var tween = create_tween()
	tween.set_loops()
	var base_energy = mat.emission_energy_multiplier
	var duration = rng.randf_range(1.5, 3.5)
	var delay = rng.randf_range(0.0, 2.0)
	tween.tween_interval(delay)
	tween.tween_property(mat, "emission_energy_multiplier", base_energy * 2.5, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(mat, "emission_energy_multiplier", base_energy, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## ─── BOLHAS APRIMORADAS ──────────────────────────────────────────────────────

func _generate_bubbles() -> void:
	var bubbles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 25.0
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 1.8
	mat.gravity = Vector3(0, 0.4, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.3
	mat.color = Color(0.6, 0.85, 1.0, 0.5)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(60, 0.5, 60)

	bubbles.process_material = mat
	bubbles.amount = 150
	bubbles.lifetime = 7.0
	bubbles.visibility_aabb = AABB(Vector3(-70, -1, -70), Vector3(140, 25, 140))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.1
	draw_pass.height = 0.1
	var bubble_mat = StandardMaterial3D.new()
	bubble_mat.albedo_color = Color(0.7, 0.92, 1.0, 0.35)
	bubble_mat.emission_enabled = true
	bubble_mat.emission = Color(0.6, 0.85, 1.0)
	bubble_mat.emission_energy_multiplier = 2.0
	bubble_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubble_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, bubble_mat)
	bubbles.draw_pass_1 = draw_pass

	bubbles.position = Vector3(0, 0.5, 0)
	add_child(bubbles)

## ─── RUINAS COM ARCOS, MOSAICOS E ESTATUAS ───────────────────────────────────

func _generate_ruins() -> void:
	for i in range(num_ruins):
		var ruin = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		ruin.position = Vector3(x, 0, z)

		var ruin_type = rng.randi() % 4
		if ruin_type == 0:
			## Coluna quebrada
			_create_broken_column(ruin)
		elif ruin_type == 1:
			## Bloco de pedra caido
			_create_fallen_block(ruin)
		elif ruin_type == 2:
			## Arco quebrado (duas colunas + lintel)
			_create_broken_arch(ruin)
		else:
			## Estatua antiga
			_create_ancient_statue(ruin)

		## Mosaicos no chao perto de ruinas
		if rng.randf() < 0.5:
			_create_mosaic_floor(ruin)

		add_child(ruin)

func _create_broken_column(ruin: Node3D) -> void:
	var col_mesh = CylinderMesh.new()
	var height = rng.randf_range(2.0, 5.0)
	col_mesh.top_radius = 0.4
	col_mesh.bottom_radius = 0.5
	col_mesh.height = height
	var col_mat = StandardMaterial3D.new()
	col_mat.albedo_color = Color(0.5, 0.55, 0.45)
	col_mat.roughness = 0.9
	col_mesh.surface_set_material(0, col_mat)

	var col_inst = MeshInstance3D.new()
	col_inst.mesh = col_mesh
	col_inst.position.y = height / 2.0
	col_inst.rotation = Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
	ruin.add_child(col_inst)

func _create_fallen_block(ruin: Node3D) -> void:
	var block_mesh = BoxMesh.new()
	block_mesh.size = Vector3(
		rng.randf_range(1.5, 3.0),
		rng.randf_range(0.5, 1.5),
		rng.randf_range(1.0, 2.5)
	)
	var block_mat = StandardMaterial3D.new()
	block_mat.albedo_color = Color(0.45, 0.48, 0.4)
	block_mat.roughness = 0.9
	block_mesh.surface_set_material(0, block_mat)

	var block_inst = MeshInstance3D.new()
	block_inst.mesh = block_mesh
	block_inst.position.y = block_mesh.size.y / 2.0
	block_inst.rotation.y = rng.randf_range(0, TAU)
	ruin.add_child(block_inst)

func _create_broken_arch(ruin: Node3D) -> void:
	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.5, 0.52, 0.45)
	stone_mat.roughness = 0.9

	var arch_width = rng.randf_range(3.0, 5.0)
	var col_height = rng.randf_range(3.0, 5.0)

	## Coluna esquerda
	var left_col = CylinderMesh.new()
	left_col.top_radius = 0.35
	left_col.bottom_radius = 0.45
	left_col.height = col_height
	left_col.surface_set_material(0, stone_mat)
	var left_inst = MeshInstance3D.new()
	left_inst.mesh = left_col
	left_inst.position = Vector3(-arch_width / 2.0, col_height / 2.0, 0)
	ruin.add_child(left_inst)

	## Coluna direita (pode estar quebrada)
	var right_height = col_height * rng.randf_range(0.4, 1.0)
	var right_col = CylinderMesh.new()
	right_col.top_radius = 0.35
	right_col.bottom_radius = 0.45
	right_col.height = right_height
	right_col.surface_set_material(0, stone_mat)
	var right_inst = MeshInstance3D.new()
	right_inst.mesh = right_col
	right_inst.position = Vector3(arch_width / 2.0, right_height / 2.0, 0)
	if rng.randf() < 0.4:
		right_inst.rotation.z = rng.randf_range(-0.2, 0.2)
	ruin.add_child(right_inst)

	## Lintel no topo (pode estar caido se coluna quebrada)
	var lintel_mesh = BoxMesh.new()
	lintel_mesh.size = Vector3(arch_width + 0.8, 0.4, 0.6)
	lintel_mesh.surface_set_material(0, stone_mat)
	var lintel_inst = MeshInstance3D.new()
	lintel_inst.mesh = lintel_mesh
	if right_height < col_height * 0.7:
		## Lintel caido
		lintel_inst.position = Vector3(arch_width * 0.2, 0.3, rng.randf_range(-0.5, 0.5))
		lintel_inst.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0, TAU), rng.randf_range(-0.3, 0.3))
	else:
		lintel_inst.position = Vector3(0, col_height + 0.2, 0)
	ruin.add_child(lintel_inst)

func _create_ancient_statue(ruin: Node3D) -> void:
	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.48, 0.5, 0.42)
	stone_mat.roughness = 0.85

	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.3, 0.6, 0.7)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.2, 0.5, 0.6)
	glow_mat.emission_energy_multiplier = 0.8

	## Base/pedestal
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(1.2, 0.4, 1.2)
	base_mesh.surface_set_material(0, stone_mat)
	var base_inst = MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.position.y = 0.2
	ruin.add_child(base_inst)

	## Torso (caixa)
	var torso_mesh = BoxMesh.new()
	torso_mesh.size = Vector3(0.7, 1.5, 0.5)
	torso_mesh.surface_set_material(0, stone_mat)
	var torso_inst = MeshInstance3D.new()
	torso_inst.mesh = torso_mesh
	torso_inst.position.y = 1.15
	ruin.add_child(torso_inst)

	## Cabeca (esfera)
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.3
	head_mesh.height = 0.55
	head_mesh.surface_set_material(0, stone_mat)
	var head_inst = MeshInstance3D.new()
	head_inst.mesh = head_mesh
	head_inst.position.y = 2.15
	ruin.add_child(head_inst)

	## Olhos brilhantes (emisssao)
	for side in [-0.12, 0.12]:
		var eye_mesh = SphereMesh.new()
		eye_mesh.radius = 0.05
		eye_mesh.height = 0.08
		eye_mesh.surface_set_material(0, glow_mat)
		var eye_inst = MeshInstance3D.new()
		eye_inst.mesh = eye_mesh
		eye_inst.position = Vector3(side, 2.2, 0.28)
		ruin.add_child(eye_inst)

	## Pode estar quebrada — inclinar levemente
	if rng.randf() < 0.4:
		ruin.rotation.z = rng.randf_range(-0.15, 0.15)

func _create_mosaic_floor(ruin: Node3D) -> void:
	var mosaic_colors: Array[Color] = [
		Color(0.2, 0.5, 0.6), Color(0.6, 0.5, 0.2),
		Color(0.4, 0.3, 0.5), Color(0.3, 0.6, 0.4),
	]
	var num_tiles = rng.randi_range(4, 10)
	for t in range(num_tiles):
		var tile_mesh = BoxMesh.new()
		tile_mesh.size = Vector3(rng.randf_range(0.3, 0.6), 0.03, rng.randf_range(0.3, 0.6))
		var tile_mat = StandardMaterial3D.new()
		tile_mat.albedo_color = mosaic_colors[rng.randi() % mosaic_colors.size()]
		tile_mat.roughness = 0.7
		tile_mat.emission_enabled = true
		tile_mat.emission = tile_mat.albedo_color * 0.15
		tile_mat.emission_energy_multiplier = 0.3
		tile_mesh.surface_set_material(0, tile_mat)
		var tile_inst = MeshInstance3D.new()
		tile_inst.mesh = tile_mesh
		tile_inst.position = Vector3(
			rng.randf_range(-2.0, 2.0),
			0.02,
			rng.randf_range(-2.0, 2.0)
		)
		ruin.add_child(tile_inst)

## ─── ALGAS COM ANIMACAO DE BALANCO ───────────────────────────────────────────

func _generate_seaweed() -> void:
	for i in range(num_seaweed):
		var weed = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		weed.position = Vector3(x, 0, z)

		var num_blades = rng.randi_range(2, 5)
		for b in range(num_blades):
			var blade_mesh = BoxMesh.new()
			var blade_height = rng.randf_range(1.0, 3.0)
			blade_mesh.size = Vector3(0.08, blade_height, 0.15)
			var blade_mat = StandardMaterial3D.new()
			## Mais variedade de cor — verde escuro a verde limao
			var green = rng.randf_range(0.25, 0.85)
			var red = rng.randf_range(0.02, 0.15)
			blade_mat.albedo_color = Color(red, green, 0.1, 0.8)
			blade_mat.roughness = 0.65
			blade_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			blade_mesh.surface_set_material(0, blade_mat)

			var blade_inst = MeshInstance3D.new()
			blade_inst.mesh = blade_mesh
			blade_inst.position = Vector3(rng.randf_range(-0.3, 0.3), blade_height / 2.0, rng.randf_range(-0.3, 0.3))
			blade_inst.rotation = Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(0, TAU), rng.randf_range(-0.1, 0.1))
			weed.add_child(blade_inst)

			## Animacao suave de balanco
			_add_sway_tween(blade_inst)

		add_child(weed)

## Florestas de kelp — mais altas e densas
func _generate_kelp_forests() -> void:
	var num_patches = 5
	for p in range(num_patches):
		var patch_x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var patch_z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(patch_x) < 8 and abs(patch_z) < 8:
			patch_x += 12.0

		var num_kelp = rng.randi_range(8, 15)
		for k in range(num_kelp):
			var kelp = Node3D.new()
			kelp.position = Vector3(
				patch_x + rng.randf_range(-3.0, 3.0),
				0,
				patch_z + rng.randf_range(-3.0, 3.0)
			)

			var blade_height = rng.randf_range(3.5, 7.0)
			var blade_mesh = BoxMesh.new()
			blade_mesh.size = Vector3(0.1, blade_height, 0.2)
			var blade_mat = StandardMaterial3D.new()
			var green = rng.randf_range(0.35, 0.7)
			blade_mat.albedo_color = Color(0.05, green, 0.08, 0.75)
			blade_mat.roughness = 0.6
			blade_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			blade_mesh.surface_set_material(0, blade_mat)

			var blade_inst = MeshInstance3D.new()
			blade_inst.mesh = blade_mesh
			blade_inst.position.y = blade_height / 2.0
			blade_inst.rotation = Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(0, TAU), rng.randf_range(-0.08, 0.08))
			kelp.add_child(blade_inst)

			## Folhas laterais ao longo do caule
			var num_leaves = rng.randi_range(2, 4)
			for l in range(num_leaves):
				var leaf_mesh = BoxMesh.new()
				leaf_mesh.size = Vector3(0.4, 0.03, 0.12)
				var leaf_mat = StandardMaterial3D.new()
				leaf_mat.albedo_color = Color(0.08, rng.randf_range(0.4, 0.65), 0.1, 0.7)
				leaf_mat.roughness = 0.6
				leaf_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				leaf_mesh.surface_set_material(0, leaf_mat)
				var leaf_inst = MeshInstance3D.new()
				leaf_inst.mesh = leaf_mesh
				leaf_inst.position.y = blade_height * rng.randf_range(0.2, 0.8)
				leaf_inst.rotation.z = rng.randf_range(-0.6, 0.6)
				leaf_inst.rotation.y = rng.randf() * TAU
				kelp.add_child(leaf_inst)

			_add_sway_tween(blade_inst)
			add_child(kelp)

## Adiciona animacao de balanco suave (rotacao leve)
func _add_sway_tween(inst: Node3D) -> void:
	var tween = create_tween()
	tween.set_loops()
	var sway_amount = rng.randf_range(0.04, 0.12)
	var duration = rng.randf_range(2.0, 4.0)
	var start_delay = rng.randf_range(0.0, 2.0)
	tween.tween_interval(start_delay)
	tween.tween_property(inst, "rotation:x", sway_amount, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(inst, "rotation:x", -sway_amount, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## ─── ZONAS DE CORRENTE (EMPURRA JOGADORES) ──────────────────────────────────

func _generate_current_zones() -> void:
	for i in range(num_current_zones):
		var zone_node = Node3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		zone_node.position = Vector3(x, 0, z)

		var zone_size = rng.randf_range(8.0, 15.0)

		## Indicador visual — plano azul transparente
		var vis_mesh = BoxMesh.new()
		vis_mesh.size = Vector3(zone_size, 0.04, zone_size)
		var vis_mat = StandardMaterial3D.new()
		vis_mat.albedo_color = Color(0.2, 0.5, 0.8, 0.15)
		vis_mat.emission_enabled = true
		vis_mat.emission = Color(0.1, 0.3, 0.6)
		vis_mat.emission_energy_multiplier = 1.0
		vis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vis_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		vis_mesh.surface_set_material(0, vis_mat)

		var vis_inst = MeshInstance3D.new()
		vis_inst.mesh = vis_mesh
		vis_inst.position.y = 0.02
		zone_node.add_child(vis_inst)

		## Area3D para detectar jogadores
		var area = Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 1  # Players only
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(zone_size, 2.0, zone_size)
		col.shape = shape
		col.position.y = 1.0
		area.add_child(col)
		zone_node.add_child(area)

		var direction = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
		current_zones.append({"area": area, "direction": direction})

		add_child(zone_node)

## ─── AGUAS-VIVAS FLUTUANTES ──────────────────────────────────────────────────

func _generate_jellyfish() -> void:
	var jelly_colors: Array[Color] = [
		Color(0.8, 0.3, 0.9, 0.6),  # Roxo translucido
		Color(0.3, 0.7, 1.0, 0.6),  # Azul ciano
		Color(1.0, 0.5, 0.7, 0.6),  # Rosa
		Color(0.4, 1.0, 0.8, 0.6),  # Turquesa
	]

	for i in range(num_jellyfish):
		var jelly = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var y = rng.randf_range(3.0, 8.0)
		jelly.position = Vector3(x, y, z)

		var color = jelly_colors[rng.randi() % jelly_colors.size()]

		## Corpo (hemisferio = meia esfera)
		var body_mesh = SphereMesh.new()
		body_mesh.radius = rng.randf_range(0.4, 0.8)
		body_mesh.height = body_mesh.radius * 1.2
		var body_mat = StandardMaterial3D.new()
		body_mat.albedo_color = color
		body_mat.roughness = 0.2
		body_mat.emission_enabled = true
		body_mat.emission = Color(color.r, color.g, color.b)
		body_mat.emission_energy_multiplier = 1.5
		body_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		body_mesh.surface_set_material(0, body_mat)
		var body_inst = MeshInstance3D.new()
		body_inst.mesh = body_mesh
		jelly.add_child(body_inst)

		## Tentaculos (cilindros finos pendentes)
		var num_tentacles = rng.randi_range(4, 8)
		for t in range(num_tentacles):
			var tent_mesh = CylinderMesh.new()
			var tent_length = rng.randf_range(1.0, 2.5)
			tent_mesh.top_radius = 0.015
			tent_mesh.bottom_radius = 0.008
			tent_mesh.height = tent_length
			var tent_mat = StandardMaterial3D.new()
			tent_mat.albedo_color = Color(color.r, color.g, color.b, 0.4)
			tent_mat.emission_enabled = true
			tent_mat.emission = Color(color.r, color.g, color.b)
			tent_mat.emission_energy_multiplier = 1.0
			tent_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			tent_mesh.surface_set_material(0, tent_mat)
			var tent_inst = MeshInstance3D.new()
			tent_inst.mesh = tent_mesh
			var angle = (float(t) / num_tentacles) * TAU
			var offset_r = body_mesh.radius * 0.5
			tent_inst.position = Vector3(
				cos(angle) * offset_r,
				-tent_length / 2.0 - body_mesh.height * 0.3,
				sin(angle) * offset_r
			)
			tent_inst.rotation = Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15))
			jelly.add_child(tent_inst)

		## Bobbing suave para cima e para baixo
		var bob_tween = create_tween()
		bob_tween.set_loops()
		var bob_dist = rng.randf_range(0.5, 1.5)
		var bob_duration = rng.randf_range(3.0, 6.0)
		bob_tween.tween_property(jelly, "position:y", y + bob_dist, bob_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob_tween.tween_property(jelly, "position:y", y - bob_dist, bob_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		## Pulsacao de brilho
		_add_bioluminescence_tween(body_inst, body_mat, Color(color.r, color.g, color.b))

		add_child(jelly)

## ─── BAUS DE TESOURO DECORATIVOS ─────────────────────────────────────────────

func _generate_treasure_chests() -> void:
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.75, 0.6, 0.15)
	gold_mat.roughness = 0.4
	gold_mat.metallic = 0.6
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(0.8, 0.65, 0.1)
	gold_mat.emission_energy_multiplier = 0.8

	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.22, 0.1)
	wood_mat.roughness = 0.9

	for i in range(num_treasure_chests):
		var chest = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		chest.position = Vector3(x, 0, z)
		chest.rotation.y = rng.randf() * TAU

		## Corpo do bau (caixa)
		var body_mesh = BoxMesh.new()
		body_mesh.size = Vector3(0.8, 0.5, 0.5)
		body_mesh.surface_set_material(0, wood_mat)
		var body_inst = MeshInstance3D.new()
		body_inst.mesh = body_mesh
		body_inst.position.y = 0.25
		chest.add_child(body_inst)

		## Faixas douradas
		for stripe_y in [0.05, 0.45]:
			var stripe_mesh = BoxMesh.new()
			stripe_mesh.size = Vector3(0.85, 0.06, 0.55)
			stripe_mesh.surface_set_material(0, gold_mat)
			var stripe_inst = MeshInstance3D.new()
			stripe_inst.mesh = stripe_mesh
			stripe_inst.position.y = stripe_y
			chest.add_child(stripe_inst)

		## Tampa semi-aberta (caixa rotacionada)
		var lid_mesh = BoxMesh.new()
		lid_mesh.size = Vector3(0.8, 0.08, 0.5)
		lid_mesh.surface_set_material(0, wood_mat)
		var lid_inst = MeshInstance3D.new()
		lid_inst.mesh = lid_mesh
		lid_inst.position = Vector3(0, 0.52, -0.2)
		lid_inst.rotation.x = -0.6  # semi-aberta
		chest.add_child(lid_inst)

		## Brilho saindo de dentro
		var glow_mesh = SphereMesh.new()
		glow_mesh.radius = 0.2
		glow_mesh.height = 0.3
		var glow_mat = StandardMaterial3D.new()
		glow_mat.albedo_color = Color(1.0, 0.85, 0.3, 0.4)
		glow_mat.emission_enabled = true
		glow_mat.emission = Color(1.0, 0.8, 0.2)
		glow_mat.emission_energy_multiplier = 3.0
		glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow_mesh.surface_set_material(0, glow_mat)
		var glow_inst = MeshInstance3D.new()
		glow_inst.mesh = glow_mesh
		glow_inst.position = Vector3(0, 0.4, 0)
		chest.add_child(glow_inst)

		add_child(chest)

## ─── NAUFRAGIO ───────────────────────────────────────────────────────────────

func _generate_shipwreck() -> void:
	var ship = Node3D.new()
	## Longe do centro
	var ship_x = rng.randf_range(35, 55) * (1 if rng.randf() > 0.5 else -1)
	var ship_z = rng.randf_range(35, 55) * (1 if rng.randf() > 0.5 else -1)
	ship.position = Vector3(ship_x, 0, ship_z)
	ship.rotation.y = rng.randf() * TAU
	## Navio levemente inclinado
	ship.rotation.z = rng.randf_range(-0.2, 0.2)

	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.3, 0.2, 0.1)
	wood_mat.roughness = 0.95

	var dark_wood = StandardMaterial3D.new()
	dark_wood.albedo_color = Color(0.2, 0.13, 0.07)
	dark_wood.roughness = 0.95

	## Casco (grande caixa)
	var hull_mesh = BoxMesh.new()
	hull_mesh.size = Vector3(4.0, 2.0, 10.0)
	hull_mesh.surface_set_material(0, wood_mat)
	var hull_inst = MeshInstance3D.new()
	hull_inst.mesh = hull_mesh
	hull_inst.position.y = 1.0
	ship.add_child(hull_inst)

	## Proa (caixa afinada)
	var bow_mesh = BoxMesh.new()
	bow_mesh.size = Vector3(2.5, 1.5, 3.0)
	bow_mesh.surface_set_material(0, wood_mat)
	var bow_inst = MeshInstance3D.new()
	bow_inst.mesh = bow_mesh
	bow_inst.position = Vector3(0, 0.8, -6.0)
	bow_inst.rotation.x = 0.15
	ship.add_child(bow_inst)

	## Deck quebrado (plataforma)
	var deck_mesh = BoxMesh.new()
	deck_mesh.size = Vector3(3.5, 0.15, 8.0)
	deck_mesh.surface_set_material(0, dark_wood)
	var deck_inst = MeshInstance3D.new()
	deck_inst.mesh = deck_mesh
	deck_inst.position = Vector3(0, 2.1, -0.5)
	deck_inst.rotation.x = rng.randf_range(-0.05, 0.05)
	ship.add_child(deck_inst)

	## Mastro quebrado
	var mast_mesh = CylinderMesh.new()
	mast_mesh.top_radius = 0.12
	mast_mesh.bottom_radius = 0.18
	mast_mesh.height = 4.0
	mast_mesh.surface_set_material(0, dark_wood)
	var mast_inst = MeshInstance3D.new()
	mast_inst.mesh = mast_mesh
	mast_inst.position = Vector3(0, 3.5, 0)
	mast_inst.rotation.z = rng.randf_range(-0.3, 0.3)
	ship.add_child(mast_inst)

	## Cabine traseira
	var cabin_mesh = BoxMesh.new()
	cabin_mesh.size = Vector3(3.0, 1.8, 2.5)
	cabin_mesh.surface_set_material(0, dark_wood)
	var cabin_inst = MeshInstance3D.new()
	cabin_inst.mesh = cabin_mesh
	cabin_inst.position = Vector3(0, 2.8, 3.5)
	cabin_inst.rotation.z = rng.randf_range(-0.1, 0.1)
	ship.add_child(cabin_inst)

	## Buracos no casco (caixas escuras recuadas)
	for h in range(3):
		var hole_mesh = BoxMesh.new()
		hole_mesh.size = Vector3(0.1, rng.randf_range(0.6, 1.2), rng.randf_range(0.8, 1.5))
		var hole_mat = StandardMaterial3D.new()
		hole_mat.albedo_color = Color(0.05, 0.05, 0.05)
		hole_mat.roughness = 1.0
		hole_mesh.surface_set_material(0, hole_mat)
		var hole_inst = MeshInstance3D.new()
		hole_inst.mesh = hole_mesh
		var side = 2.05 if rng.randf() > 0.5 else -2.05
		hole_inst.position = Vector3(side, rng.randf_range(0.5, 1.5), rng.randf_range(-3, 3))
		ship.add_child(hole_inst)

	add_child(ship)

## ─── DETALHES DO FUNDO DO MAR ────────────────────────────────────────────────

func _generate_sea_floor_details() -> void:
	## Estrelas do mar
	for i in range(num_starfish):
		var star = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		star.position = Vector3(x, 0.02, z)
		star.rotation.y = rng.randf() * TAU

		var star_color = Color(
			rng.randf_range(0.8, 1.0),
			rng.randf_range(0.2, 0.5),
			rng.randf_range(0.05, 0.2)
		)
		var star_mat = StandardMaterial3D.new()
		star_mat.albedo_color = star_color
		star_mat.roughness = 0.7

		## 5 bracos da estrela (caixas finas sobrepostas)
		for arm in range(5):
			var arm_mesh = BoxMesh.new()
			arm_mesh.size = Vector3(rng.randf_range(0.25, 0.4), 0.04, 0.08)
			arm_mesh.surface_set_material(0, star_mat)
			var arm_inst = MeshInstance3D.new()
			arm_inst.mesh = arm_mesh
			var angle = (float(arm) / 5.0) * TAU
			arm_inst.position = Vector3(cos(angle) * 0.15, 0, sin(angle) * 0.15)
			arm_inst.rotation.y = angle
			star.add_child(arm_inst)

		add_child(star)

	## Conchas (hemisferios pequenos)
	for i in range(15):
		var shell_mesh = SphereMesh.new()
		shell_mesh.radius = rng.randf_range(0.08, 0.18)
		shell_mesh.height = shell_mesh.radius * 1.0
		var shell_mat = StandardMaterial3D.new()
		shell_mat.albedo_color = Color(
			rng.randf_range(0.7, 0.95),
			rng.randf_range(0.6, 0.85),
			rng.randf_range(0.5, 0.7)
		)
		shell_mat.roughness = 0.5
		shell_mesh.surface_set_material(0, shell_mat)
		var shell_inst = MeshInstance3D.new()
		shell_inst.mesh = shell_mesh
		shell_inst.position = Vector3(
			rng.randf_range(-area_size * 0.8, area_size * 0.8),
			0.04,
			rng.randf_range(-area_size * 0.8, area_size * 0.8)
		)
		add_child(shell_inst)

	## Seixos espalhados
	for i in range(25):
		var pebble_mesh = SphereMesh.new()
		pebble_mesh.radius = rng.randf_range(0.04, 0.1)
		pebble_mesh.height = pebble_mesh.radius * 1.2
		var pebble_mat = StandardMaterial3D.new()
		pebble_mat.albedo_color = Color(
			rng.randf_range(0.3, 0.55),
			rng.randf_range(0.3, 0.5),
			rng.randf_range(0.25, 0.45)
		)
		pebble_mat.roughness = 0.85
		pebble_mesh.surface_set_material(0, pebble_mat)
		var pebble_inst = MeshInstance3D.new()
		pebble_inst.mesh = pebble_mesh
		pebble_inst.position = Vector3(
			rng.randf_range(-area_size * 0.9, area_size * 0.9),
			0.02,
			rng.randf_range(-area_size * 0.9, area_size * 0.9)
		)
		add_child(pebble_inst)

## ─── RAIOS DE LUZ SUBAQUATICOS ───────────────────────────────────────────────

func _generate_underwater_light_rays() -> void:
	var rays = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 8.0
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 0.7
	mat.gravity = Vector3(0, -0.1, 0)
	mat.scale_min = 0.8
	mat.scale_max = 2.0
	mat.color = Color(0.5, 0.8, 1.0, 0.06)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(50, 0.5, 50)

	rays.process_material = mat
	rays.amount = 30
	rays.lifetime = 10.0
	rays.visibility_aabb = AABB(Vector3(-60, -2, -60), Vector3(120, 30, 120))

	## Raios longos e finos (caixas altas)
	var draw_pass = BoxMesh.new()
	draw_pass.size = Vector3(0.3, 8.0, 0.15)
	var ray_mat = StandardMaterial3D.new()
	ray_mat.albedo_color = Color(0.6, 0.85, 1.0, 0.04)
	ray_mat.emission_enabled = true
	ray_mat.emission = Color(0.5, 0.75, 0.95)
	ray_mat.emission_energy_multiplier = 0.6
	ray_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, ray_mat)
	rays.draw_pass_1 = draw_pass

	rays.position = Vector3(0, 18.0, 0)
	add_child(rays)

## ─── ILUMINACAO AMBIENTE BotW ────────────────────────────────────────────────

func _generate_ambient_lights() -> void:
	var light_configs: Array[Dictionary] = [
		{"color": Color(0.1, 0.3, 0.85), "energy": 0.5},   # Azul profundo
		{"color": Color(0.0, 0.55, 0.65), "energy": 0.45},  # Teal
		{"color": Color(0.15, 0.45, 0.75), "energy": 0.4},  # Azul medio
		{"color": Color(0.0, 0.7, 0.6), "energy": 0.5},     # Ciano esverdeado
		{"color": Color(0.1, 0.2, 0.6), "energy": 0.35},    # Azul escuro
		{"color": Color(0.0, 0.8, 0.8), "energy": 0.55},    # Turquesa
		{"color": Color(0.2, 0.6, 0.9), "energy": 0.45},    # Azul claro
	]

	for i in range(14):
		var light = OmniLight3D.new()
		var config = light_configs[rng.randi() % light_configs.size()]

		## Algumas luzes posicionadas perto de corais (uplighting)
		var x: float
		var z: float
		var y: float
		if i < 6:
			## Luzes baixas perto do chao (uplighting em coral)
			x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
			z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
			y = rng.randf_range(0.3, 1.5)
		elif i < 10:
			## Luzes medias
			x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
			z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
			y = rng.randf_range(2.0, 5.0)
		else:
			## Luzes altas (simula luz vinda de cima)
			x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
			z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
			y = rng.randf_range(6.0, 10.0)

		light.position = Vector3(x, y, z)
		light.light_color = config["color"]
		light.light_energy = config["energy"]
		light.omni_range = rng.randf_range(8.0, 14.0)
		light.omni_attenuation = 1.8
		add_child(light)
