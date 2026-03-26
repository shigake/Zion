extends Node3D

## Gera props procedurais para Arena Gladiadora estilo BotW: paredes do coliseu com
## arquibancadas, pilares detalhados, portoes de ferro, tochas dramaticas, racks de armas,
## podio de vitoria, manchas de sangue, silhuetas de multidao. Multidao joga itens (cura/dano).

@export var num_wall_segments: int = 24
@export var num_pillars: int = 20
@export var num_torches: int = 20
@export var num_gates: int = 4
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var crowd_timer: float = 0.0
var crowd_interval: float = 5.0

func _ready() -> void:
	rng.randomize()
	_generate_coliseum_walls()
	_generate_seating_tiers()
	_generate_crowd_silhouettes()
	_generate_pillars()
	_generate_fallen_pillar_fragments()
	_generate_iron_gates()
	_generate_torches()
	_generate_weapon_racks()
	_generate_blood_stains()
	_generate_victory_podium()
	_generate_sand_particles()
	_generate_dust_devil()
	_generate_arena_lighting()
	_add_real_models()

func _add_real_models() -> void:
	## Adiciona modelos Kenney — colunas, estátuas, tendas, rochas
	ModelFactory.scatter_nature_props(self, "statue", 8, area_size, Vector2(1.5, 2.5))
	ModelFactory.scatter_nature_props(self, "stone_tall", 12, area_size, Vector2(1.5, 3.0))
	ModelFactory.scatter_nature_props(self, "tent", 4, area_size, Vector2(1.5, 2.0))
	ModelFactory.scatter_nature_props(self, "campfire", 5, area_size, Vector2(1.0, 1.5))
	ModelFactory.scatter_nature_props(self, "rock_large", 8, area_size, Vector2(1.0, 2.0))
	ModelFactory.scatter_nature_props(self, "sign", 4, area_size, Vector2(1.0, 1.5))
	ModelFactory.scatter_dungeon_props(self, "dungeon_banner", 6, area_size, Vector2(1.0, 1.5))
	ModelFactory.scatter_dungeon_props(self, "dungeon_barrel", 8, area_size, Vector2(1.0, 1.5))

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	# Crowd throws items periodically
	crowd_timer += delta
	if crowd_timer >= crowd_interval:
		crowd_timer = 0.0
		crowd_interval = rng.randf_range(4.0, 8.0)
		_crowd_throw_item()

## ---- PAREDES DO COLISEU ----
func _generate_coliseum_walls() -> void:
	var wall_radius = area_size * 0.85
	for i in range(num_wall_segments):
		var angle = (float(i) / num_wall_segments) * TAU
		var x = cos(angle) * wall_radius
		var z = sin(angle) * wall_radius

		var wall = Node3D.new()
		wall.position = Vector3(x, 0, z)
		wall.rotation.y = -angle + PI / 2.0

		var wall_height = rng.randf_range(8.0, 12.0)
		var wall_width = (TAU * wall_radius) / num_wall_segments + 1.0

		## Parede principal
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(wall_width, wall_height, 1.5)
		var wall_mat = StandardMaterial3D.new()
		wall_mat.albedo_color = Color(0.6, 0.5, 0.35)
		wall_mat.roughness = 0.9
		wall_mesh.surface_set_material(0, wall_mat)

		var wall_inst = MeshInstance3D.new()
		wall_inst.mesh = wall_mesh
		wall_inst.position.y = wall_height / 2.0
		wall.add_child(wall_inst)

		## Arcos decorativos na parede (a cada 3 segmentos)
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

		## Faixa decorativa horizontal no meio da parede
		var band_mesh = BoxMesh.new()
		band_mesh.size = Vector3(wall_width + 0.1, 0.4, 0.3)
		var band_mat = StandardMaterial3D.new()
		band_mat.albedo_color = Color(0.45, 0.35, 0.25)
		band_mat.roughness = 0.85
		band_mesh.surface_set_material(0, band_mat)

		var band_inst = MeshInstance3D.new()
		band_inst.mesh = band_mesh
		band_inst.position.y = wall_height * 0.5
		band_inst.position.z = -0.8
		wall.add_child(band_inst)

		## Escudos/bandeiras decorativas em intervalos (a cada 4 segmentos)
		if i % 4 == 0:
			var banner_colors: Array[Color] = [
				Color(0.7, 0.15, 0.1),
				Color(0.1, 0.2, 0.6),
				Color(0.6, 0.5, 0.1),
				Color(0.15, 0.5, 0.15),
			]

			## Escudo
			var shield_mesh = BoxMesh.new()
			shield_mesh.size = Vector3(0.8, 1.0, 0.1)
			var shield_mat = StandardMaterial3D.new()
			shield_mat.albedo_color = banner_colors[i % banner_colors.size()]
			shield_mat.roughness = 0.5
			shield_mat.metallic = 0.4
			shield_mesh.surface_set_material(0, shield_mat)

			var shield_inst = MeshInstance3D.new()
			shield_inst.mesh = shield_mesh
			shield_inst.position.y = wall_height * 0.7
			shield_inst.position.z = -1.0
			wall.add_child(shield_inst)

			## Bandeira pendente abaixo do escudo
			var flag_mesh = BoxMesh.new()
			flag_mesh.size = Vector3(0.6, 1.8, 0.04)
			var flag_mat = StandardMaterial3D.new()
			flag_mat.albedo_color = banner_colors[(i + 1) % banner_colors.size()]
			flag_mat.roughness = 0.95
			flag_mesh.surface_set_material(0, flag_mat)

			var flag_inst = MeshInstance3D.new()
			flag_inst.mesh = flag_mesh
			flag_inst.position.y = wall_height * 0.7 - 1.4
			flag_inst.position.z = -1.0
			wall.add_child(flag_inst)

		## Cornija no topo da parede
		if i % 2 == 0:
			var cornice_mesh = BoxMesh.new()
			cornice_mesh.size = Vector3(wall_width + 0.2, 0.3, 2.0)
			var cornice_mat = StandardMaterial3D.new()
			cornice_mat.albedo_color = Color(0.55, 0.45, 0.32)
			cornice_mat.roughness = 0.85
			cornice_mesh.surface_set_material(0, cornice_mat)

			var cornice_inst = MeshInstance3D.new()
			cornice_inst.mesh = cornice_mesh
			cornice_inst.position.y = wall_height + 0.15
			wall.add_child(cornice_inst)

		add_child(wall)

## ---- ARQUIBANCADAS (SEATING TIERS) ----
func _generate_seating_tiers() -> void:
	var wall_radius = area_size * 0.85
	var num_tiers: int = 5
	for tier in range(num_tiers):
		var tier_radius = wall_radius + 1.5 + tier * 2.0
		var tier_height = 1.0 + tier * 1.5
		var num_seats: int = 20

		for i in range(num_seats):
			var angle = (float(i) / num_seats) * TAU
			var x = cos(angle) * tier_radius
			var z = sin(angle) * tier_radius

			var seat = MeshInstance3D.new()
			var seat_mesh = BoxMesh.new()
			seat_mesh.size = Vector3(
				(TAU * tier_radius) / num_seats * 0.9,
				0.5,
				1.8
			)
			var seat_mat = StandardMaterial3D.new()
			## Cores alternadas para dar profundidade
			if tier % 2 == 0:
				seat_mat.albedo_color = Color(0.55, 0.45, 0.32)
			else:
				seat_mat.albedo_color = Color(0.5, 0.4, 0.28)
			seat_mat.roughness = 0.9
			seat_mesh.surface_set_material(0, seat_mat)

			seat.mesh = seat_mesh
			seat.position = Vector3(x, tier_height, z)
			seat.rotation.y = -angle + PI / 2.0
			add_child(seat)

## ---- SILHUETAS DA MULTIDAO ----
func _generate_crowd_silhouettes() -> void:
	var wall_radius = area_size * 0.85
	var num_crowd: int = 50

	for i in range(num_crowd):
		var tier = rng.randi_range(0, 4)
		var tier_radius = wall_radius + 1.5 + tier * 2.0
		var tier_height = 1.0 + tier * 1.5 + 0.25

		var angle = rng.randf_range(0, TAU)
		var x = cos(angle) * tier_radius
		var z = sin(angle) * tier_radius

		var person = Node3D.new()
		person.position = Vector3(x, tier_height, z)
		person.rotation.y = -angle + PI

		var body_h = rng.randf_range(0.7, 1.1)

		## Corpo (caixa escura)
		var body_mesh = BoxMesh.new()
		body_mesh.size = Vector3(0.35, body_h, 0.25)
		var body_mat = StandardMaterial3D.new()
		var shade = rng.randf_range(0.08, 0.2)
		body_mat.albedo_color = Color(shade, shade * 0.9, shade * 0.8)
		body_mat.roughness = 1.0
		body_mesh.surface_set_material(0, body_mat)

		var body_inst = MeshInstance3D.new()
		body_inst.mesh = body_mesh
		body_inst.position.y = body_h / 2.0
		person.add_child(body_inst)

		## Cabeca (esfera escura)
		var head_mesh = SphereMesh.new()
		head_mesh.radius = rng.randf_range(0.12, 0.18)
		head_mesh.height = head_mesh.radius * 2.0
		var head_mat = StandardMaterial3D.new()
		head_mat.albedo_color = Color(shade * 1.1, shade, shade * 0.9)
		head_mat.roughness = 1.0
		head_mesh.surface_set_material(0, head_mat)

		var head_inst = MeshInstance3D.new()
		head_inst.mesh = head_mesh
		head_inst.position.y = body_h + head_mesh.radius
		person.add_child(head_inst)

		add_child(person)

## ---- PILARES DETALHADOS ----
func _generate_pillars() -> void:
	for i in range(num_pillars):
		var pillar = Node3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		pillar.position = Vector3(x, 0, z)

		var height = rng.randf_range(3.0, 7.0)
		var is_damaged = rng.randi() % 4 == 0

		## Coluna principal
		var col_mesh = CylinderMesh.new()
		col_mesh.top_radius = 0.35
		col_mesh.bottom_radius = 0.45
		col_mesh.height = height if not is_damaged else height * 0.6
		var col_mat = StandardMaterial3D.new()
		col_mat.albedo_color = Color(0.65, 0.55, 0.4)
		col_mat.roughness = 0.8
		col_mesh.surface_set_material(0, col_mat)

		var actual_h = col_mesh.height
		var col_inst = MeshInstance3D.new()
		col_inst.mesh = col_mesh
		col_inst.position.y = actual_h / 2.0
		pillar.add_child(col_inst)

		## Capitel detalhado (cilindros empilhados de raio decrescente)
		if not is_damaged:
			var cap_radii: Array[float] = [0.55, 0.48, 0.4]
			var cap_heights: Array[float] = [0.15, 0.12, 0.1]
			var cap_y = actual_h
			for ci in range(cap_radii.size()):
				var cap_mesh = CylinderMesh.new()
				cap_mesh.top_radius = cap_radii[ci] - 0.05
				cap_mesh.bottom_radius = cap_radii[ci]
				cap_mesh.height = cap_heights[ci]
				var cap_mat = StandardMaterial3D.new()
				cap_mat.albedo_color = Color(0.6, 0.5, 0.38)
				cap_mat.roughness = 0.7
				cap_mesh.surface_set_material(0, cap_mat)

				var cap_inst = MeshInstance3D.new()
				cap_inst.mesh = cap_mesh
				cap_inst.position.y = cap_y + cap_heights[ci] / 2.0
				pillar.add_child(cap_inst)
				cap_y += cap_heights[ci]

			## Placa de topo quadrada
			var top_mesh = BoxMesh.new()
			top_mesh.size = Vector3(1.0, 0.2, 1.0)
			var top_mat = StandardMaterial3D.new()
			top_mat.albedo_color = Color(0.58, 0.48, 0.36)
			top_mat.roughness = 0.75
			top_mesh.surface_set_material(0, top_mat)

			var top_inst = MeshInstance3D.new()
			top_inst.mesh = top_mesh
			top_inst.position.y = cap_y + 0.1
			pillar.add_child(top_inst)
		else:
			## Dano de batalha — pedaco faltando no topo
			var chunk_mesh = BoxMesh.new()
			chunk_mesh.size = Vector3(0.3, 0.4, 0.3)
			var chunk_mat = StandardMaterial3D.new()
			chunk_mat.albedo_color = Color(0.7, 0.6, 0.45)
			chunk_mat.roughness = 0.95
			chunk_mesh.surface_set_material(0, chunk_mat)

			var chunk_inst = MeshInstance3D.new()
			chunk_inst.mesh = chunk_mesh
			chunk_inst.position = Vector3(0.15, actual_h - 0.1, 0.1)
			pillar.add_child(chunk_inst)

		## Base decorativa
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

		## Segunda base mais larga
		var base2_mesh = BoxMesh.new()
		base2_mesh.size = Vector3(1.4, 0.15, 1.4)
		var base2_mat = StandardMaterial3D.new()
		base2_mat.albedo_color = Color(0.5, 0.4, 0.3)
		base2_mat.roughness = 0.95
		base2_mesh.surface_set_material(0, base2_mat)

		var base2_inst = MeshInstance3D.new()
		base2_inst.mesh = base2_mesh
		base2_inst.position.y = 0.075
		pillar.add_child(base2_inst)

		add_child(pillar)

## ---- FRAGMENTOS DE PILARES CAIDOS ----
func _generate_fallen_pillar_fragments() -> void:
	for i in range(8):
		var frag = Node3D.new()
		var x = rng.randf_range(-area_size * 0.55, area_size * 0.55)
		var z = rng.randf_range(-area_size * 0.55, area_size * 0.55)
		if abs(x) < 6 and abs(z) < 6:
			x += 9.0
		frag.position = Vector3(x, 0, z)
		frag.rotation.y = rng.randf_range(0, TAU)

		## Cilindro deitado (pilar caido)
		var cyl_mesh = CylinderMesh.new()
		cyl_mesh.top_radius = rng.randf_range(0.25, 0.4)
		cyl_mesh.bottom_radius = cyl_mesh.top_radius + 0.05
		cyl_mesh.height = rng.randf_range(1.5, 3.5)
		var cyl_mat = StandardMaterial3D.new()
		cyl_mat.albedo_color = Color(0.6, 0.52, 0.38)
		cyl_mat.roughness = 0.9
		cyl_mesh.surface_set_material(0, cyl_mat)

		var cyl_inst = MeshInstance3D.new()
		cyl_inst.mesh = cyl_mesh
		cyl_inst.position.y = cyl_mesh.top_radius
		cyl_inst.rotation.z = PI / 2.0
		frag.add_child(cyl_inst)

		## Pedacos de pedra ao redor
		for j in range(rng.randi_range(2, 4)):
			var rock_mesh = BoxMesh.new()
			var rs = rng.randf_range(0.15, 0.35)
			rock_mesh.size = Vector3(rs, rs * 0.7, rs * 0.9)
			var rock_mat = StandardMaterial3D.new()
			rock_mat.albedo_color = Color(0.58, 0.48, 0.35)
			rock_mat.roughness = 0.95
			rock_mesh.surface_set_material(0, rock_mat)

			var rock_inst = MeshInstance3D.new()
			rock_inst.mesh = rock_mesh
			rock_inst.position = Vector3(
				rng.randf_range(-1.0, 1.0),
				rs * 0.35,
				rng.randf_range(-0.8, 0.8)
			)
			rock_inst.rotation = Vector3(
				rng.randf_range(-0.3, 0.3),
				rng.randf_range(0, TAU),
				rng.randf_range(-0.3, 0.3)
			)
			frag.add_child(rock_inst)

		add_child(frag)

## ---- PORTOES DE FERRO ----
func _generate_iron_gates() -> void:
	for i in range(num_gates):
		var angle = (float(i) / num_gates) * TAU
		var gate_radius = area_size * 0.6
		var x = cos(angle) * gate_radius
		var z = sin(angle) * gate_radius

		var gate = Node3D.new()
		gate.position = Vector3(x, 0, z)
		gate.rotation.y = -angle

		## Moldura do portao
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

		## Barras de ferro
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

		## Barra horizontal de reforco
		var hbar_mesh = CylinderMesh.new()
		hbar_mesh.top_radius = 0.05
		hbar_mesh.bottom_radius = 0.05
		hbar_mesh.height = 3.5
		var hbar_mat = StandardMaterial3D.new()
		hbar_mat.albedo_color = Color(0.25, 0.22, 0.2)
		hbar_mat.metallic = 0.8
		hbar_mat.roughness = 0.3
		hbar_mesh.surface_set_material(0, hbar_mat)

		var hbar_inst = MeshInstance3D.new()
		hbar_inst.mesh = hbar_mesh
		hbar_inst.position = Vector3(0, 3.5, 0)
		hbar_inst.rotation.z = PI / 2.0
		gate.add_child(hbar_inst)

		## Espigoes no topo das barras
		for b in range(5):
			var spike_mesh = CylinderMesh.new()
			spike_mesh.top_radius = 0.0
			spike_mesh.bottom_radius = 0.04
			spike_mesh.height = 0.3
			var spike_mat = StandardMaterial3D.new()
			spike_mat.albedo_color = Color(0.2, 0.18, 0.15)
			spike_mat.metallic = 0.9
			spike_mat.roughness = 0.2
			spike_mesh.surface_set_material(0, spike_mat)

			var spike_inst = MeshInstance3D.new()
			spike_inst.mesh = spike_mesh
			spike_inst.position = Vector3(-1.5 + b * 0.75, 4.9, 0)
			gate.add_child(spike_inst)

		add_child(gate)

## ---- TOCHAS COM CHAMAS MAIORES E FUMACA ----
func _generate_torches() -> void:
	for i in range(num_torches):
		var torch = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 4 and abs(z) < 4:
			x += 7.0
		torch.position = Vector3(x, 0, z)

		## Poste da tocha
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

		## Suporte da tocha (copo)
		var cup_mesh = CylinderMesh.new()
		cup_mesh.top_radius = 0.15
		cup_mesh.bottom_radius = 0.08
		cup_mesh.height = 0.25
		var cup_mat = StandardMaterial3D.new()
		cup_mat.albedo_color = Color(0.25, 0.18, 0.1)
		cup_mat.metallic = 0.3
		cup_mat.roughness = 0.7
		cup_mesh.surface_set_material(0, cup_mat)

		var cup_inst = MeshInstance3D.new()
		cup_inst.mesh = cup_mesh
		cup_inst.position.y = 2.5
		torch.add_child(cup_inst)

		## Chama grande (particulas)
		var flame = GPUParticles3D.new()
		var flame_mat = ParticleProcessMaterial.new()
		flame_mat.direction = Vector3(0, 1, 0)
		flame_mat.spread = 20.0
		flame_mat.initial_velocity_min = 0.8
		flame_mat.initial_velocity_max = 2.5
		flame_mat.gravity = Vector3(0, 0.8, 0)
		flame_mat.scale_min = 0.08
		flame_mat.scale_max = 0.25
		flame_mat.color = Color(1.0, 0.6, 0.1, 0.9)

		flame.process_material = flame_mat
		flame.amount = 25
		flame.lifetime = 0.9
		flame.visibility_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 4, 2))

		var flame_draw = SphereMesh.new()
		flame_draw.radius = 0.1
		flame_draw.height = 0.16
		var flame_draw_mat = StandardMaterial3D.new()
		flame_draw_mat.albedo_color = Color(1.0, 0.7, 0.2, 0.85)
		flame_draw_mat.emission_enabled = true
		flame_draw_mat.emission = Color(1.0, 0.5, 0.0)
		flame_draw_mat.emission_energy_multiplier = 5.0
		flame_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		flame_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flame_draw.surface_set_material(0, flame_draw_mat)
		flame.draw_pass_1 = flame_draw

		flame.position.y = 2.7
		torch.add_child(flame)

		## Fumaca acima da chama
		var smoke = GPUParticles3D.new()
		var smoke_mat = ParticleProcessMaterial.new()
		smoke_mat.direction = Vector3(0, 1, 0)
		smoke_mat.spread = 25.0
		smoke_mat.initial_velocity_min = 0.3
		smoke_mat.initial_velocity_max = 0.8
		smoke_mat.gravity = Vector3(0.2, 0.3, 0)
		smoke_mat.scale_min = 0.1
		smoke_mat.scale_max = 0.3
		smoke_mat.color = Color(0.3, 0.28, 0.25, 0.25)

		smoke.process_material = smoke_mat
		smoke.amount = 8
		smoke.lifetime = 2.0
		smoke.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 6, 4))

		var smoke_draw = SphereMesh.new()
		smoke_draw.radius = 0.15
		smoke_draw.height = 0.2
		var smoke_draw_mat = StandardMaterial3D.new()
		smoke_draw_mat.albedo_color = Color(0.35, 0.3, 0.28, 0.2)
		smoke_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smoke_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smoke_draw.surface_set_material(0, smoke_draw_mat)
		smoke.draw_pass_1 = smoke_draw

		smoke.position.y = 3.5
		torch.add_child(smoke)

		## Luz pontual quente
		var light = OmniLight3D.new()
		light.position.y = 2.9
		light.light_color = Color(1.0, 0.65, 0.25)
		light.light_energy = 1.2
		light.omni_range = 12.0
		light.omni_attenuation = 1.8
		torch.add_child(light)

		add_child(torch)

## ---- RACKS DE ARMAS ----
func _generate_weapon_racks() -> void:
	for i in range(6):
		var angle = (float(i) / 6.0) * TAU + 0.3
		var rack_radius = area_size * 0.55
		var x = cos(angle) * rack_radius
		var z = sin(angle) * rack_radius

		var rack = Node3D.new()
		rack.position = Vector3(x, 0, z)
		rack.rotation.y = -angle + PI / 2.0

		## Moldura de madeira (base)
		var frame_mesh = BoxMesh.new()
		frame_mesh.size = Vector3(2.0, 2.2, 0.3)
		var frame_mat = StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.35, 0.22, 0.1)
		frame_mat.roughness = 0.9
		frame_mesh.surface_set_material(0, frame_mat)

		var frame_inst = MeshInstance3D.new()
		frame_inst.mesh = frame_mesh
		frame_inst.position.y = 1.1
		rack.add_child(frame_inst)

		## Postes verticais laterais
		for side in [-1.0, 1.0]:
			var post_mesh = CylinderMesh.new()
			post_mesh.top_radius = 0.04
			post_mesh.bottom_radius = 0.05
			post_mesh.height = 2.4
			var post_mat = StandardMaterial3D.new()
			post_mat.albedo_color = Color(0.3, 0.2, 0.1)
			post_mat.roughness = 0.9
			post_mesh.surface_set_material(0, post_mat)

			var post_inst = MeshInstance3D.new()
			post_inst.mesh = post_mesh
			post_inst.position = Vector3(side * 0.9, 1.2, 0.18)
			rack.add_child(post_inst)

		## Espada (caixa fina)
		var sword_mesh = BoxMesh.new()
		sword_mesh.size = Vector3(0.08, 1.4, 0.03)
		var sword_mat = StandardMaterial3D.new()
		sword_mat.albedo_color = Color(0.6, 0.6, 0.65)
		sword_mat.metallic = 0.9
		sword_mat.roughness = 0.2
		sword_mesh.surface_set_material(0, sword_mat)

		var sword_inst = MeshInstance3D.new()
		sword_inst.mesh = sword_mesh
		sword_inst.position = Vector3(-0.5, 1.3, 0.2)
		rack.add_child(sword_inst)

		## Guarda da espada
		var guard_mesh = BoxMesh.new()
		guard_mesh.size = Vector3(0.25, 0.04, 0.06)
		var guard_mat = StandardMaterial3D.new()
		guard_mat.albedo_color = Color(0.5, 0.4, 0.15)
		guard_mat.metallic = 0.7
		guard_mesh.surface_set_material(0, guard_mat)

		var guard_inst = MeshInstance3D.new()
		guard_inst.mesh = guard_mesh
		guard_inst.position = Vector3(-0.5, 0.6, 0.2)
		rack.add_child(guard_inst)

		## Escudo (disco plano)
		var shield_mesh = CylinderMesh.new()
		shield_mesh.top_radius = 0.4
		shield_mesh.bottom_radius = 0.4
		shield_mesh.height = 0.06
		var shield_mat = StandardMaterial3D.new()
		shield_mat.albedo_color = Color(0.5, 0.35, 0.15)
		shield_mat.metallic = 0.5
		shield_mat.roughness = 0.4
		shield_mesh.surface_set_material(0, shield_mat)

		var shield_inst = MeshInstance3D.new()
		shield_inst.mesh = shield_mesh
		shield_inst.position = Vector3(0.1, 1.2, 0.2)
		shield_inst.rotation.x = PI / 2.0
		rack.add_child(shield_inst)

		## Lanca (cilindro fino)
		var spear_mesh = CylinderMesh.new()
		spear_mesh.top_radius = 0.02
		spear_mesh.bottom_radius = 0.025
		spear_mesh.height = 2.0
		var spear_mat = StandardMaterial3D.new()
		spear_mat.albedo_color = Color(0.35, 0.25, 0.12)
		spear_mat.roughness = 0.85
		spear_mesh.surface_set_material(0, spear_mat)

		var spear_inst = MeshInstance3D.new()
		spear_inst.mesh = spear_mesh
		spear_inst.position = Vector3(0.55, 1.1, 0.2)
		rack.add_child(spear_inst)

		## Ponta da lanca
		var spear_tip_mesh = CylinderMesh.new()
		spear_tip_mesh.top_radius = 0.0
		spear_tip_mesh.bottom_radius = 0.04
		spear_tip_mesh.height = 0.15
		var spear_tip_mat = StandardMaterial3D.new()
		spear_tip_mat.albedo_color = Color(0.6, 0.6, 0.65)
		spear_tip_mat.metallic = 0.8
		spear_tip_mesh.surface_set_material(0, spear_tip_mat)

		var spear_tip_inst = MeshInstance3D.new()
		spear_tip_inst.mesh = spear_tip_mesh
		spear_tip_inst.position = Vector3(0.55, 2.18, 0.2)
		rack.add_child(spear_tip_inst)

		add_child(rack)

## ---- MANCHAS DE SANGUE ----
func _generate_blood_stains() -> void:
	for i in range(10):
		var x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		var z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		if abs(x) < 4 and abs(z) < 4:
			x += 6.0

		var stain = MeshInstance3D.new()
		var stain_mesh = BoxMesh.new()
		var sz = rng.randf_range(0.5, 1.8)
		stain_mesh.size = Vector3(sz, 0.02, sz * rng.randf_range(0.6, 1.2))
		var stain_mat = StandardMaterial3D.new()
		stain_mat.albedo_color = Color(0.35, 0.06, 0.04, 0.6)
		stain_mat.roughness = 1.0
		stain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		stain_mesh.surface_set_material(0, stain_mat)

		stain.mesh = stain_mesh
		stain.position = Vector3(x, 0.02, z)
		stain.rotation.y = rng.randf_range(0, TAU)
		add_child(stain)

## ---- PODIO DE VITORIA ----
func _generate_victory_podium() -> void:
	var podium = Node3D.new()
	podium.position = Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(15, 25))

	## Degrau 1 (maior, base)
	var step1_mesh = BoxMesh.new()
	step1_mesh.size = Vector3(5.0, 0.5, 3.0)
	var step1_mat = StandardMaterial3D.new()
	step1_mat.albedo_color = Color(0.55, 0.48, 0.35)
	step1_mat.roughness = 0.8
	step1_mesh.surface_set_material(0, step1_mat)

	var step1_inst = MeshInstance3D.new()
	step1_inst.mesh = step1_mesh
	step1_inst.position.y = 0.25
	podium.add_child(step1_inst)

	## Degrau 2 (medio)
	var step2_mesh = BoxMesh.new()
	step2_mesh.size = Vector3(3.5, 0.5, 2.2)
	var step2_mat = StandardMaterial3D.new()
	step2_mat.albedo_color = Color(0.6, 0.52, 0.38)
	step2_mat.roughness = 0.75
	step2_mesh.surface_set_material(0, step2_mat)

	var step2_inst = MeshInstance3D.new()
	step2_inst.mesh = step2_mesh
	step2_inst.position.y = 0.75
	podium.add_child(step2_inst)

	## Degrau 3 (topo — dourado)
	var step3_mesh = BoxMesh.new()
	step3_mesh.size = Vector3(2.0, 0.5, 1.5)
	var step3_mat = StandardMaterial3D.new()
	step3_mat.albedo_color = Color(0.75, 0.6, 0.2)
	step3_mat.roughness = 0.4
	step3_mat.metallic = 0.5
	step3_mat.emission_enabled = true
	step3_mat.emission = Color(0.4, 0.3, 0.05)
	step3_mat.emission_energy_multiplier = 0.5
	step3_mesh.surface_set_material(0, step3_mat)

	var step3_inst = MeshInstance3D.new()
	step3_inst.mesh = step3_mesh
	step3_inst.position.y = 1.25
	podium.add_child(step3_inst)

	## Leve brilho dourado acima do podio
	var podium_light = OmniLight3D.new()
	podium_light.position.y = 2.5
	podium_light.light_color = Color(1.0, 0.85, 0.4)
	podium_light.light_energy = 0.6
	podium_light.omni_range = 6.0
	podium_light.omni_attenuation = 2.0
	podium.add_child(podium_light)

	add_child(podium)

## ---- PARTICULAS DE AREIA (VENTO + MAIS VOLUME) ----
func _generate_sand_particles() -> void:
	var sand = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(1, -0.2, 0.3)
	mat.spread = 35.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 1.5
	mat.gravity = Vector3(0.8, -0.5, 0.3)
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = Color(0.8, 0.7, 0.5, 0.3)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(45, 0.5, 45)

	sand.process_material = mat
	sand.amount = 80
	sand.lifetime = 4.0
	sand.visibility_aabb = AABB(Vector3(-55, -1, -55), Vector3(110, 5, 110))

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

## ---- EFEITO DE REDEMOINHO DE POEIRA ----
func _generate_dust_devil() -> void:
	var devil = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 10.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, 0.5, 0)
	mat.angular_velocity_min = 200.0
	mat.angular_velocity_max = 400.0
	mat.scale_min = 0.04
	mat.scale_max = 0.12
	mat.color = Color(0.75, 0.65, 0.45, 0.35)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 1.5

	devil.process_material = mat
	devil.amount = 40
	devil.lifetime = 2.5
	devil.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 8, 6))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.05
	draw_pass.height = 0.05
	var dust_mat = StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.7, 0.6, 0.4, 0.3)
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, dust_mat)
	devil.draw_pass_1 = draw_pass

	## Posiciona o redemoinho em ponto aleatorio da arena
	devil.position = Vector3(
		rng.randf_range(-15, 15),
		0.0,
		rng.randf_range(-15, 15)
	)
	add_child(devil)

## ---- ILUMINACAO DRAMATICA DA ARENA ----
func _generate_arena_lighting() -> void:
	## Luar azul frio vindo de cima
	var moonlight = DirectionalLight3D.new()
	moonlight.light_color = Color(0.4, 0.5, 0.8)
	moonlight.light_energy = 0.3
	moonlight.rotation = Vector3(-1.2, 0.5, 0)
	add_child(moonlight)

	## Luzes quentes douradas espalhadas (como se vindas das tochas ao longe)
	for i in range(8):
		var angle = (float(i) / 8.0) * TAU
		var radius = area_size * 0.4
		var light = OmniLight3D.new()
		light.position = Vector3(
			cos(angle) * radius,
			rng.randf_range(3.0, 5.0),
			sin(angle) * radius
		)
		light.light_color = Color(1.0, 0.7, 0.3)
		light.light_energy = 0.5
		light.omni_range = 15.0
		light.omni_attenuation = 2.0
		add_child(light)

	## Luzes de destaque azuladas nos cantos
	for i in range(4):
		var angle = (float(i) / 4.0) * TAU + PI / 4.0
		var radius = area_size * 0.65
		var light = OmniLight3D.new()
		light.position = Vector3(
			cos(angle) * radius,
			6.0,
			sin(angle) * radius
		)
		light.light_color = Color(0.3, 0.4, 0.7)
		light.light_energy = 0.35
		light.omni_range = 12.0
		light.omni_attenuation = 2.5
		add_child(light)

	## Luz central quente para o centro da arena
	var center_light = OmniLight3D.new()
	center_light.position = Vector3(0, 8, 0)
	center_light.light_color = Color(1.0, 0.85, 0.5)
	center_light.light_energy = 0.6
	center_light.omni_range = 20.0
	center_light.omni_attenuation = 1.5
	add_child(center_light)

## ---- MECANICA: MULTIDAO JOGA ITEM ----
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
