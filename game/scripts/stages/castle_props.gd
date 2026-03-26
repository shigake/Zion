extends Node3D

## Gera props procedurais para Castelo do Vampiro estilo BotW: pilares goticos com
## arcobotantes e gargulas, candelabros, vitrais com molduras de chumbo, caixoes,
## trono, estantes de livros, lustres, tapecarias, armaduras decorativas.
## Areas escuras fortalecem inimigos; tochas criam zonas seguras.

@export var num_pillars: int = 30
@export var num_candelabras: int = 12
@export var num_stained_glass: int = 15
@export var num_coffins: int = 20
@export var num_dark_zones: int = 8
@export var num_torches: int = 10
@export var num_bookshelves: int = 8
@export var num_chandeliers: int = 4
@export var num_tapestries: int = 10
@export var num_armor_stands: int = 6
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
	_generate_throne()
	_generate_bookshelves()
	_generate_chandeliers()
	_generate_tapestries()
	_generate_armor_stands()
	_generate_fog_particles()
	_generate_bat_particles()
	_generate_atmospheric_lights()

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

## ---- Materiais reutilizaveis ----

func _make_stone_mat(shade: float = 0.2) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(shade, shade * 0.9, shade * 1.1)
	mat.roughness = 0.7
	return mat

func _make_dark_metal_mat() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.13, 0.12)
	mat.metallic = 0.8
	mat.roughness = 0.4
	return mat

func _make_gold_mat() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.55, 0.15)
	mat.metallic = 0.9
	mat.roughness = 0.25
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.3, 0.05)
	mat.emission_energy_multiplier = 0.3
	return mat

func _make_wood_mat(dark: bool = true) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	if dark:
		mat.albedo_color = Color(0.18, 0.1, 0.06)
	else:
		mat.albedo_color = Color(0.3, 0.18, 0.08)
	mat.roughness = 0.8
	return mat

## ---- Pilares goticos com arcobotantes e gargulas ----

func _generate_gothic_pillars() -> void:
	var pillar_positions: Array[Vector3] = []

	for i in range(num_pillars):
		var pillar = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		pillar.position = Vector3(x, 0, z)
		pillar_positions.append(pillar.position)

		var height = rng.randf_range(4.0, 9.0)

		## Coluna gotica principal
		var col_mesh = CylinderMesh.new()
		col_mesh.top_radius = 0.25
		col_mesh.bottom_radius = 0.4
		col_mesh.height = height
		var col_mat = _make_stone_mat(0.2)
		col_mesh.surface_set_material(0, col_mat)

		var col_inst = MeshInstance3D.new()
		col_inst.mesh = col_mesh
		col_inst.position.y = height / 2.0
		pillar.add_child(col_inst)

		## Nervuras decorativas na coluna (4 tiras verticais)
		for r in range(4):
			var rib_mesh = BoxMesh.new()
			rib_mesh.size = Vector3(0.06, height * 0.9, 0.06)
			var rib_mat = _make_stone_mat(0.16)
			rib_mesh.surface_set_material(0, rib_mat)

			var rib_inst = MeshInstance3D.new()
			rib_inst.mesh = rib_mesh
			var angle = (float(r) / 4.0) * TAU
			rib_inst.position = Vector3(cos(angle) * 0.32, height / 2.0, sin(angle) * 0.32)
			pillar.add_child(rib_inst)

		## Topo decorativo (ponta gotica)
		var top_mesh = CylinderMesh.new()
		top_mesh.top_radius = 0.0
		top_mesh.bottom_radius = 0.35
		top_mesh.height = 1.2
		var top_mat = _make_stone_mat(0.15)
		top_mesh.surface_set_material(0, top_mat)

		var top_inst = MeshInstance3D.new()
		top_inst.mesh = top_mesh
		top_inst.position.y = height + 0.6
		pillar.add_child(top_inst)

		## Base ornamentada
		var base_mesh = CylinderMesh.new()
		base_mesh.top_radius = 0.45
		base_mesh.bottom_radius = 0.55
		base_mesh.height = 0.3
		base_mesh.surface_set_material(0, _make_stone_mat(0.18))

		var base_inst = MeshInstance3D.new()
		base_inst.mesh = base_mesh
		base_inst.position.y = 0.15
		pillar.add_child(base_inst)

		## Gargula no topo (30% dos pilares)
		if rng.randi() % 100 < 30:
			_add_gargoyle(pillar, height + 1.0)

		add_child(pillar)

	## Arcobotantes conectando pilares proximos
	_generate_flying_buttresses(pillar_positions)

func _add_gargoyle(parent: Node3D, y_pos: float) -> void:
	var gargoyle = Node3D.new()
	var facing_angle = rng.randf_range(0, TAU)
	gargoyle.position = Vector3(0, y_pos, 0)
	gargoyle.rotation.y = facing_angle

	var stone_mat = _make_stone_mat(0.14)

	## Cabeca da gargula (esfera)
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.2
	head_mesh.height = 0.35
	head_mesh.surface_set_material(0, stone_mat)

	var head_inst = MeshInstance3D.new()
	head_inst.mesh = head_mesh
	head_inst.position = Vector3(0.3, 0.15, 0)
	gargoyle.add_child(head_inst)

	## Corpo da gargula (caixa)
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(0.4, 0.25, 0.2)
	body_mesh.surface_set_material(0, stone_mat)

	var body_inst = MeshInstance3D.new()
	body_inst.mesh = body_mesh
	body_inst.position = Vector3(0.1, 0, 0)
	gargoyle.add_child(body_inst)

	## Asas (boxes angulados)
	for side in [-1.0, 1.0]:
		var wing_mesh = BoxMesh.new()
		wing_mesh.size = Vector3(0.3, 0.04, 0.35)
		wing_mesh.surface_set_material(0, stone_mat)

		var wing_inst = MeshInstance3D.new()
		wing_inst.mesh = wing_mesh
		wing_inst.position = Vector3(0.05, 0.1, side * 0.25)
		wing_inst.rotation.x = side * 0.4
		gargoyle.add_child(wing_inst)

	parent.add_child(gargoyle)

func _generate_flying_buttresses(positions: Array[Vector3]) -> void:
	## Conecta pilares proximos (distancia < 15) com arcobotantes
	var connected: Dictionary = {}
	for i in range(positions.size()):
		for j in range(i + 1, positions.size()):
			var dist = positions[i].distance_to(positions[j])
			if dist < 15.0 and dist > 4.0:
				var key = str(i) + "_" + str(j)
				if connected.has(key):
					continue
				## Apenas 25% dos pares proximos
				if rng.randi() % 100 > 25:
					continue
				connected[key] = true

				var buttress = Node3D.new()
				var mid = (positions[i] + positions[j]) / 2.0
				buttress.position = mid

				var dir = (positions[j] - positions[i]).normalized()
				var length = dist
				var angle_y = atan2(dir.x, dir.z)

				## Arco do arcobotante (caixa angulada)
				var arc_mesh = BoxMesh.new()
				arc_mesh.size = Vector3(0.2, 0.15, length)
				var arc_mat = _make_stone_mat(0.17)
				arc_mesh.surface_set_material(0, arc_mat)

				var arc_inst = MeshInstance3D.new()
				arc_inst.mesh = arc_mesh
				arc_inst.rotation.y = angle_y
				arc_inst.position.y = rng.randf_range(2.5, 4.5)
				arc_inst.rotation.x = -0.25
				buttress.add_child(arc_inst)

				add_child(buttress)

## ---- Candelabros ----

func _generate_candelabras() -> void:
	for i in range(num_candelabras):
		var cand = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 4 and abs(z) < 4:
			x += 7.0
		cand.position = Vector3(x, 0, z)

		var pole_mat = _make_gold_mat()

		## Poste principal
		var pole_mesh = CylinderMesh.new()
		pole_mesh.top_radius = 0.04
		pole_mesh.bottom_radius = 0.08
		pole_mesh.height = 1.8
		pole_mesh.surface_set_material(0, pole_mat)

		var pole_inst = MeshInstance3D.new()
		pole_inst.mesh = pole_mesh
		pole_inst.position.y = 0.9
		cand.add_child(pole_inst)

		## Base ornamentada
		var base_mesh = CylinderMesh.new()
		base_mesh.top_radius = 0.15
		base_mesh.bottom_radius = 0.2
		base_mesh.height = 0.1
		base_mesh.surface_set_material(0, pole_mat)

		var base_inst = MeshInstance3D.new()
		base_inst.mesh = base_mesh
		base_inst.position.y = 0.05
		cand.add_child(base_inst)

		## Bracos com velas
		var num_arms = rng.randi_range(3, 5)
		for a in range(num_arms):
			var arm_angle = (float(a) / num_arms) * TAU
			var arm_length = 0.4

			## Braco
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

			## Vela
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

		## Luz do candelabro
		var light = OmniLight3D.new()
		light.position.y = 2.1
		light.light_color = Color(1.0, 0.7, 0.3)
		light.light_energy = 0.6
		light.omni_range = 6.0
		light.omni_attenuation = 2.0
		cand.add_child(light)

		add_child(cand)

## ---- Vitrais com moldura de chumbo e piscinas de luz ----

func _generate_stained_glass() -> void:
	var glass_colors: Array[Color] = [
		Color(0.9, 0.1, 0.1, 0.6),   # Vermelho vibrante
		Color(0.1, 0.15, 0.95, 0.6),  # Azul profundo
		Color(0.7, 0.1, 0.85, 0.6),   # Roxo real
		Color(0.1, 0.8, 0.35, 0.6),   # Verde esmeralda
		Color(1.0, 0.8, 0.1, 0.6),    # Dourado brilhante
		Color(0.1, 0.7, 0.9, 0.6),    # Ciano celestial
	]

	for i in range(num_stained_glass):
		var glass = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		var glass_y = rng.randf_range(3.0, 6.0)
		glass.position = Vector3(x, glass_y, z)

		var w = rng.randf_range(1.5, 3.0)
		var h = rng.randf_range(2.0, 4.0)
		var rot_y = rng.randf_range(0, TAU)

		## Moldura exterior
		var frame_mesh = BoxMesh.new()
		frame_mesh.size = Vector3(w, h, 0.15)
		var frame_mat = StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.12, 0.08, 0.08)
		frame_mat.roughness = 0.8
		frame_mesh.surface_set_material(0, frame_mat)

		var frame_inst = MeshInstance3D.new()
		frame_inst.mesh = frame_mesh
		frame_inst.rotation.y = rot_y
		glass.add_child(frame_inst)

		## Vidro colorido
		var color = glass_colors[rng.randi() % glass_colors.size()]
		var pane_mesh = BoxMesh.new()
		pane_mesh.size = Vector3(w - 0.2, h - 0.2, 0.03)
		var pane_mat = StandardMaterial3D.new()
		pane_mat.albedo_color = color
		pane_mat.emission_enabled = true
		pane_mat.emission = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2)
		pane_mat.emission_energy_multiplier = 2.5
		pane_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pane_mesh.surface_set_material(0, pane_mat)

		var pane_inst = MeshInstance3D.new()
		pane_inst.mesh = pane_mesh
		pane_inst.rotation.y = rot_y
		glass.add_child(pane_inst)

		## Moldura de chumbo (grade sobre o vidro)
		var lead_mat = StandardMaterial3D.new()
		lead_mat.albedo_color = Color(0.06, 0.05, 0.05)
		lead_mat.metallic = 0.6
		lead_mat.roughness = 0.5

		## Barras verticais de chumbo
		var num_v_bars = int(w / 0.5)
		for v in range(num_v_bars):
			var bar_mesh = BoxMesh.new()
			bar_mesh.size = Vector3(0.03, h - 0.25, 0.04)
			bar_mesh.surface_set_material(0, lead_mat)

			var bar_inst = MeshInstance3D.new()
			bar_inst.mesh = bar_mesh
			var bar_x = -w / 2.0 + 0.2 + v * (w - 0.4) / maxf(num_v_bars - 1, 1)
			bar_inst.position = Vector3(bar_x, 0, 0.02)
			bar_inst.rotation.y = rot_y
			glass.add_child(bar_inst)

		## Barras horizontais de chumbo
		var num_h_bars = int(h / 0.6)
		for hb in range(num_h_bars):
			var hbar_mesh = BoxMesh.new()
			hbar_mesh.size = Vector3(w - 0.25, 0.03, 0.04)
			hbar_mesh.surface_set_material(0, lead_mat)

			var hbar_inst = MeshInstance3D.new()
			hbar_inst.mesh = hbar_mesh
			var bar_y = -h / 2.0 + 0.2 + hb * (h - 0.4) / maxf(num_h_bars - 1, 1)
			hbar_inst.position = Vector3(0, bar_y, 0.02)
			hbar_inst.rotation.y = rot_y
			glass.add_child(hbar_inst)

		## Piscina de luz colorida no chao
		var pool_mesh = CylinderMesh.new()
		pool_mesh.top_radius = w * 0.6
		pool_mesh.bottom_radius = w * 0.6
		pool_mesh.height = 0.02
		var pool_mat = StandardMaterial3D.new()
		pool_mat.albedo_color = Color(color.r, color.g, color.b, 0.2)
		pool_mat.emission_enabled = true
		pool_mat.emission = Color(color.r, color.g, color.b)
		pool_mat.emission_energy_multiplier = 1.0
		pool_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pool_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pool_mesh.surface_set_material(0, pool_mat)

		var pool_inst = MeshInstance3D.new()
		pool_inst.mesh = pool_mesh
		pool_inst.position.y = -glass_y + 0.03
		glass.add_child(pool_inst)

		add_child(glass)

## ---- Caixoes com alguns encostados na parede e teias de aranha ----

func _generate_coffins() -> void:
	for i in range(num_coffins):
		var coffin = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		coffin.position = Vector3(x, 0, z)
		coffin.rotation.y = rng.randf_range(0, TAU)

		## Corpo do caixao
		var body_mesh = BoxMesh.new()
		body_mesh.size = Vector3(0.7, 0.4, 2.0)
		var body_mat = _make_wood_mat(true)
		body_mesh.surface_set_material(0, body_mat)

		var body_inst = MeshInstance3D.new()
		body_inst.mesh = body_mesh
		body_inst.position.y = 0.2
		coffin.add_child(body_inst)

		## Cruz decorativa no topo do caixao
		var cross_mat = _make_gold_mat()
		var cross_v = BoxMesh.new()
		cross_v.size = Vector3(0.04, 0.01, 0.3)
		cross_v.surface_set_material(0, cross_mat)
		var cross_v_inst = MeshInstance3D.new()
		cross_v_inst.mesh = cross_v
		cross_v_inst.position.y = 0.42
		coffin.add_child(cross_v_inst)

		var cross_h = BoxMesh.new()
		cross_h.size = Vector3(0.04, 0.01, 0.15)
		cross_h.surface_set_material(0, cross_mat)
		var cross_h_inst = MeshInstance3D.new()
		cross_h_inst.mesh = cross_h
		cross_h_inst.position.y = 0.42
		cross_h_inst.position.z = 0.05
		cross_h_inst.rotation.y = PI / 2.0
		coffin.add_child(cross_h_inst)

		## Tampa (levemente levantada em alguns)
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
			## Tampa aberta
			lid_inst.rotation.z = rng.randf_range(0.3, 0.6)
			lid_inst.position.x += 0.2

		## Alguns caixoes encostados na parede (inclinados)
		if rng.randi() % 4 == 0:
			coffin.rotation.x = rng.randf_range(0.6, 1.1)
			coffin.position.y = 0.5

		coffin.add_child(lid_inst)

		## Teias de aranha em alguns caixoes
		if rng.randi() % 3 == 0:
			_add_cobwebs(coffin)

		add_child(coffin)

func _add_cobwebs(parent: Node3D) -> void:
	var web_mat = StandardMaterial3D.new()
	web_mat.albedo_color = Color(0.8, 0.8, 0.8, 0.08)
	web_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	web_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	web_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var num_webs = rng.randi_range(1, 3)
	for w in range(num_webs):
		var web_mesh = BoxMesh.new()
		web_mesh.size = Vector3(
			rng.randf_range(0.3, 0.8),
			0.005,
			rng.randf_range(0.3, 0.8)
		)
		web_mesh.surface_set_material(0, web_mat)

		var web_inst = MeshInstance3D.new()
		web_inst.mesh = web_mesh
		web_inst.position = Vector3(
			rng.randf_range(-0.3, 0.3),
			rng.randf_range(0.3, 0.5),
			rng.randf_range(-0.8, 0.8)
		)
		web_inst.rotation = Vector3(
			rng.randf_range(-0.3, 0.3),
			rng.randf_range(0, TAU),
			rng.randf_range(-0.3, 0.3)
		)
		parent.add_child(web_inst)

## ---- Zonas escuras (buff inimigos) ----

func _generate_dark_zones() -> void:
	for i in range(num_dark_zones):
		var zone_node = Node3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		zone_node.position = Vector3(x, 0, z)

		var zone_size = rng.randf_range(10.0, 18.0)

		## Visual — mancha escura no chao
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

		## Luz roxa/azul de acento na zona escura
		var accent = OmniLight3D.new()
		accent.position.y = 1.5
		accent.light_color = Color(0.3, 0.1, 0.6)
		accent.light_energy = 0.4
		accent.omni_range = zone_size * 0.6
		accent.omni_attenuation = 2.5
		zone_node.add_child(accent)

		## Area3D
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

## ---- Tochas (zonas seguras) ----

func _generate_torches() -> void:
	for i in range(num_torches):
		var torch = Node3D.new()
		var x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		var z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		torch.position = Vector3(x, 0, z)

		## Poste
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

		## Suporte da tocha (braco metalico)
		var bracket_mesh = BoxMesh.new()
		bracket_mesh.size = Vector3(0.15, 0.04, 0.04)
		bracket_mesh.surface_set_material(0, _make_dark_metal_mat())
		var bracket_inst = MeshInstance3D.new()
		bracket_inst.mesh = bracket_mesh
		bracket_inst.position = Vector3(0.1, 1.95, 0)
		torch.add_child(bracket_inst)

		## Prato da tocha
		var dish_mesh = CylinderMesh.new()
		dish_mesh.top_radius = 0.12
		dish_mesh.bottom_radius = 0.08
		dish_mesh.height = 0.08
		dish_mesh.surface_set_material(0, _make_dark_metal_mat())
		var dish_inst = MeshInstance3D.new()
		dish_inst.mesh = dish_mesh
		dish_inst.position.y = 2.0
		torch.add_child(dish_inst)

		## Chama (particulas)
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

		## Luz quente
		var light = OmniLight3D.new()
		light.position.y = 2.3
		light.light_color = Color(1.0, 0.7, 0.3)
		light.light_energy = 1.0
		light.omni_range = 10.0
		light.omni_attenuation = 2.0
		torch.add_child(light)

		## Safe zone area (cancela buff de escuridao)
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

## ---- Trono ornamentado ----

func _generate_throne() -> void:
	var throne = Node3D.new()
	## Posicionar longe do centro
	var angle = rng.randf_range(0, TAU)
	var dist = rng.randf_range(area_size * 0.5, area_size * 0.7)
	throne.position = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	throne.rotation.y = angle + PI  ## Virado para o centro

	var dark_red_mat = StandardMaterial3D.new()
	dark_red_mat.albedo_color = Color(0.4, 0.05, 0.05)
	dark_red_mat.roughness = 0.5

	var gold_mat = _make_gold_mat()

	## Assento
	var seat_mesh = BoxMesh.new()
	seat_mesh.size = Vector3(1.5, 0.15, 1.2)
	seat_mesh.surface_set_material(0, dark_red_mat)
	var seat_inst = MeshInstance3D.new()
	seat_inst.mesh = seat_mesh
	seat_inst.position.y = 0.8
	throne.add_child(seat_inst)

	## Pernas do trono (4)
	for lx in [-0.6, 0.6]:
		for lz in [-0.5, 0.5]:
			var leg_mesh = BoxMesh.new()
			leg_mesh.size = Vector3(0.12, 0.8, 0.12)
			leg_mesh.surface_set_material(0, gold_mat)
			var leg_inst = MeshInstance3D.new()
			leg_inst.mesh = leg_mesh
			leg_inst.position = Vector3(lx, 0.4, lz)
			throne.add_child(leg_inst)

	## Encosto alto (costas do trono)
	var back_mesh = BoxMesh.new()
	back_mesh.size = Vector3(1.6, 2.5, 0.12)
	back_mesh.surface_set_material(0, dark_red_mat)
	var back_inst = MeshInstance3D.new()
	back_inst.mesh = back_mesh
	back_inst.position = Vector3(0, 2.1, -0.55)
	throne.add_child(back_inst)

	## Detalhes dourados no encosto
	var detail_mesh = BoxMesh.new()
	detail_mesh.size = Vector3(1.3, 2.0, 0.02)
	detail_mesh.surface_set_material(0, gold_mat)
	var detail_inst = MeshInstance3D.new()
	detail_inst.mesh = detail_mesh
	detail_inst.position = Vector3(0, 2.1, -0.48)
	throne.add_child(detail_inst)

	## Apoios de braco
	for side in [-0.75, 0.75]:
		var arm_mesh = BoxMesh.new()
		arm_mesh.size = Vector3(0.12, 0.5, 1.0)
		arm_mesh.surface_set_material(0, dark_red_mat)
		var arm_inst = MeshInstance3D.new()
		arm_inst.mesh = arm_mesh
		arm_inst.position = Vector3(side, 1.1, 0)
		throne.add_child(arm_inst)

		## Topo dourado do apoio de braco
		var arm_top_mesh = BoxMesh.new()
		arm_top_mesh.size = Vector3(0.15, 0.05, 1.05)
		arm_top_mesh.surface_set_material(0, gold_mat)
		var arm_top_inst = MeshInstance3D.new()
		arm_top_inst.mesh = arm_top_mesh
		arm_top_inst.position = Vector3(side, 1.35, 0)
		throne.add_child(arm_top_inst)

	## Cranio decorativo no topo do encosto
	var skull_mesh = SphereMesh.new()
	skull_mesh.radius = 0.2
	skull_mesh.height = 0.25
	var skull_mat = StandardMaterial3D.new()
	skull_mat.albedo_color = Color(0.85, 0.8, 0.7)
	skull_mat.roughness = 0.6
	skull_mesh.surface_set_material(0, skull_mat)
	var skull_inst = MeshInstance3D.new()
	skull_inst.mesh = skull_mesh
	skull_inst.position = Vector3(0, 3.5, -0.55)
	throne.add_child(skull_inst)

	## Olhos do cranio (emissivos vermelhos)
	for ex in [-0.06, 0.06]:
		var eye_mesh = SphereMesh.new()
		eye_mesh.radius = 0.03
		eye_mesh.height = 0.06
		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = Color(1.0, 0.1, 0.1)
		eye_mat.emission_enabled = true
		eye_mat.emission = Color(1.0, 0.0, 0.0)
		eye_mat.emission_energy_multiplier = 3.0
		eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		eye_mesh.surface_set_material(0, eye_mat)
		var eye_inst = MeshInstance3D.new()
		eye_inst.mesh = eye_mesh
		eye_inst.position = Vector3(ex, 3.52, -0.38)
		throne.add_child(eye_inst)

	## Ponta gotica no topo
	var spire_mesh = CylinderMesh.new()
	spire_mesh.top_radius = 0.0
	spire_mesh.bottom_radius = 0.15
	spire_mesh.height = 0.6
	spire_mesh.surface_set_material(0, gold_mat)
	var spire_inst = MeshInstance3D.new()
	spire_inst.mesh = spire_mesh
	spire_inst.position = Vector3(0, 3.9, -0.55)
	throne.add_child(spire_inst)

	add_child(throne)

## ---- Estantes de livros ----

func _generate_bookshelves() -> void:
	var book_colors: Array[Color] = [
		Color(0.5, 0.05, 0.05),  # Vermelho escuro
		Color(0.05, 0.15, 0.4),  # Azul marinho
		Color(0.2, 0.1, 0.02),   # Marrom
		Color(0.05, 0.3, 0.1),   # Verde escuro
		Color(0.3, 0.1, 0.3),    # Roxo
		Color(0.5, 0.4, 0.1),    # Dourado
	]

	for i in range(num_bookshelves):
		var shelf = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		shelf.position = Vector3(x, 0, z)
		shelf.rotation.y = rng.randf_range(0, TAU)

		var shelf_w = rng.randf_range(2.0, 3.5)
		var shelf_h = rng.randf_range(3.0, 5.0)
		var shelf_d = 0.4

		var wood_mat = _make_wood_mat(true)

		## Estrutura principal da estante
		var frame_mesh = BoxMesh.new()
		frame_mesh.size = Vector3(shelf_w, shelf_h, shelf_d)
		frame_mesh.surface_set_material(0, wood_mat)
		var frame_inst = MeshInstance3D.new()
		frame_inst.mesh = frame_mesh
		frame_inst.position.y = shelf_h / 2.0
		shelf.add_child(frame_inst)

		## Prateleiras (divisorias horizontais)
		var num_shelves = int(shelf_h / 0.8)
		for s in range(num_shelves):
			var div_mesh = BoxMesh.new()
			div_mesh.size = Vector3(shelf_w - 0.05, 0.04, shelf_d)
			div_mesh.surface_set_material(0, wood_mat)
			var div_inst = MeshInstance3D.new()
			div_inst.mesh = div_mesh
			div_inst.position.y = 0.3 + s * (shelf_h - 0.4) / maxf(num_shelves - 1, 1)
			shelf.add_child(div_inst)

			## Livros nesta prateleira
			var books_in_row = rng.randi_range(4, 10)
			var book_x_start = -shelf_w / 2.0 + 0.15
			var cursor_x = book_x_start
			for b in range(books_in_row):
				var book_w = rng.randf_range(0.06, 0.14)
				var book_h = rng.randf_range(0.4, 0.7)
				if cursor_x + book_w > shelf_w / 2.0 - 0.1:
					break

				var book_mesh = BoxMesh.new()
				book_mesh.size = Vector3(book_w, book_h, shelf_d * 0.7)
				var book_mat = StandardMaterial3D.new()
				book_mat.albedo_color = book_colors[rng.randi() % book_colors.size()]
				book_mat.roughness = 0.6
				book_mesh.surface_set_material(0, book_mat)

				var book_inst = MeshInstance3D.new()
				book_inst.mesh = book_mesh
				book_inst.position = Vector3(
					cursor_x + book_w / 2.0,
					div_inst.position.y + 0.02 + book_h / 2.0,
					0
				)
				## Alguns livros levemente inclinados
				if rng.randi() % 5 == 0:
					book_inst.rotation.z = rng.randf_range(-0.15, 0.15)
				shelf.add_child(book_inst)
				cursor_x += book_w + 0.01

		add_child(shelf)

## ---- Lustres pendurados ----

func _generate_chandeliers() -> void:
	for i in range(num_chandeliers):
		var chandelier = Node3D.new()
		var x = rng.randf_range(-area_size * 0.4, area_size * 0.4)
		var z = rng.randf_range(-area_size * 0.4, area_size * 0.4)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		var hang_y = rng.randf_range(6.0, 8.0)
		chandelier.position = Vector3(x, hang_y, z)

		var metal_mat = _make_dark_metal_mat()
		var gold_mat = _make_gold_mat()

		## Corrente (cilindros finos subindo)
		var chain_height = 3.0
		var chain_mesh = CylinderMesh.new()
		chain_mesh.top_radius = 0.02
		chain_mesh.bottom_radius = 0.02
		chain_mesh.height = chain_height
		chain_mesh.surface_set_material(0, metal_mat)
		var chain_inst = MeshInstance3D.new()
		chain_inst.mesh = chain_mesh
		chain_inst.position.y = chain_height / 2.0
		chandelier.add_child(chain_inst)

		## Anel principal do lustre
		var ring_segments = 12
		var ring_radius = 1.0
		for seg in range(ring_segments):
			var seg_angle = (float(seg) / ring_segments) * TAU
			var next_angle = (float(seg + 1) / ring_segments) * TAU
			var mid_angle = (seg_angle + next_angle) / 2.0

			var seg_mesh = BoxMesh.new()
			seg_mesh.size = Vector3(0.06, 0.06, ring_radius * TAU / ring_segments * 1.05)
			seg_mesh.surface_set_material(0, gold_mat)

			var seg_inst = MeshInstance3D.new()
			seg_inst.mesh = seg_mesh
			seg_inst.position = Vector3(cos(mid_angle) * ring_radius, 0, sin(mid_angle) * ring_radius)
			seg_inst.rotation.y = mid_angle + PI / 2.0
			chandelier.add_child(seg_inst)

		## Velas no anel (8 velas)
		var num_candles = 8
		for c in range(num_candles):
			var c_angle = (float(c) / num_candles) * TAU
			var cx = cos(c_angle) * ring_radius
			var cz = sin(c_angle) * ring_radius

			## Base da vela
			var base_mesh = CylinderMesh.new()
			base_mesh.top_radius = 0.05
			base_mesh.bottom_radius = 0.06
			base_mesh.height = 0.05
			base_mesh.surface_set_material(0, gold_mat)
			var base_inst = MeshInstance3D.new()
			base_inst.mesh = base_mesh
			base_inst.position = Vector3(cx, 0.03, cz)
			chandelier.add_child(base_inst)

			## Vela
			var candle_mesh = CylinderMesh.new()
			candle_mesh.top_radius = 0.03
			candle_mesh.bottom_radius = 0.035
			candle_mesh.height = 0.2
			var candle_mat = StandardMaterial3D.new()
			candle_mat.albedo_color = Color(0.9, 0.85, 0.7)
			candle_mesh.surface_set_material(0, candle_mat)
			var candle_inst = MeshInstance3D.new()
			candle_inst.mesh = candle_mesh
			candle_inst.position = Vector3(cx, 0.16, cz)
			chandelier.add_child(candle_inst)

		## Luz principal do lustre (quente)
		var light = OmniLight3D.new()
		light.position.y = 0.3
		light.light_color = Color(1.0, 0.75, 0.4)
		light.light_energy = 1.2
		light.omni_range = 14.0
		light.omni_attenuation = 1.8
		chandelier.add_child(light)

		add_child(chandelier)

## ---- Tapecarias nas paredes ----

func _generate_tapestries() -> void:
	var tapestry_colors: Array[Color] = [
		Color(0.5, 0.02, 0.05),   # Carmesim
		Color(0.25, 0.05, 0.35),  # Roxo real
		Color(0.05, 0.08, 0.35),  # Azul escuro
		Color(0.4, 0.3, 0.05),    # Dourado velho
		Color(0.3, 0.02, 0.15),   # Borgonha
	]

	for i in range(num_tapestries):
		var tapestry = Node3D.new()
		var x = rng.randf_range(-area_size * 0.85, area_size * 0.85)
		var z = rng.randf_range(-area_size * 0.85, area_size * 0.85)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		tapestry.position = Vector3(x, rng.randf_range(2.0, 4.0), z)
		tapestry.rotation.y = rng.randf_range(0, TAU)

		var t_width = rng.randf_range(1.0, 2.0)
		var t_height = rng.randf_range(2.5, 4.5)
		var color = tapestry_colors[rng.randi() % tapestry_colors.size()]

		## Barra superior (suporte dourado)
		var bar_mesh = CylinderMesh.new()
		bar_mesh.top_radius = 0.04
		bar_mesh.bottom_radius = 0.04
		bar_mesh.height = t_width + 0.2
		bar_mesh.surface_set_material(0, _make_gold_mat())
		var bar_inst = MeshInstance3D.new()
		bar_inst.mesh = bar_mesh
		bar_inst.position.y = t_height / 2.0
		bar_inst.rotation.z = PI / 2.0
		tapestry.add_child(bar_inst)

		## Tecido principal
		var fabric_mesh = BoxMesh.new()
		fabric_mesh.size = Vector3(t_width, t_height, 0.03)
		var fabric_mat = StandardMaterial3D.new()
		fabric_mat.albedo_color = color
		fabric_mat.roughness = 0.9
		fabric_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		fabric_mesh.surface_set_material(0, fabric_mat)
		var fabric_inst = MeshInstance3D.new()
		fabric_inst.mesh = fabric_mesh
		tapestry.add_child(fabric_inst)

		## Franja dourada na borda inferior
		var fringe_mesh = BoxMesh.new()
		fringe_mesh.size = Vector3(t_width, 0.08, 0.035)
		fringe_mesh.surface_set_material(0, _make_gold_mat())
		var fringe_inst = MeshInstance3D.new()
		fringe_inst.mesh = fringe_mesh
		fringe_inst.position.y = -t_height / 2.0
		tapestry.add_child(fringe_inst)

		## Bordas esfarrapadas em algumas (pedacos menores na base)
		if rng.randi() % 3 == 0:
			var num_tatters = rng.randi_range(3, 6)
			for t in range(num_tatters):
				var tatter_mesh = BoxMesh.new()
				var tw = rng.randf_range(0.1, 0.3)
				var th = rng.randf_range(0.2, 0.6)
				tatter_mesh.size = Vector3(tw, th, 0.025)
				var tatter_mat = StandardMaterial3D.new()
				tatter_mat.albedo_color = Color(color.r * 0.8, color.g * 0.8, color.b * 0.8)
				tatter_mat.roughness = 0.9
				tatter_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				tatter_mesh.surface_set_material(0, tatter_mat)
				var tatter_inst = MeshInstance3D.new()
				tatter_inst.mesh = tatter_mesh
				tatter_inst.position = Vector3(
					rng.randf_range(-t_width / 2.5, t_width / 2.5),
					-t_height / 2.0 - th / 2.0,
					0
				)
				tatter_inst.rotation.z = rng.randf_range(-0.2, 0.2)
				tapestry.add_child(tatter_inst)

		## Simbolo central (losango dourado simplificado)
		var sym_mesh = BoxMesh.new()
		sym_mesh.size = Vector3(0.4, 0.4, 0.005)
		sym_mesh.surface_set_material(0, _make_gold_mat())
		var sym_inst = MeshInstance3D.new()
		sym_inst.mesh = sym_mesh
		sym_inst.rotation.z = PI / 4.0
		sym_inst.position.z = 0.02
		tapestry.add_child(sym_inst)

		add_child(tapestry)

## ---- Armaduras decorativas ----

func _generate_armor_stands() -> void:
	for i in range(num_armor_stands):
		var armor = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		armor.position = Vector3(x, 0, z)
		armor.rotation.y = rng.randf_range(0, TAU)

		var metal_mat = _make_dark_metal_mat()

		## Pedestal
		var ped_mesh = CylinderMesh.new()
		ped_mesh.top_radius = 0.35
		ped_mesh.bottom_radius = 0.4
		ped_mesh.height = 0.15
		ped_mesh.surface_set_material(0, _make_stone_mat(0.25))
		var ped_inst = MeshInstance3D.new()
		ped_inst.mesh = ped_mesh
		ped_inst.position.y = 0.075
		armor.add_child(ped_inst)

		## Pernas (2 cilindros)
		for side in [-0.12, 0.12]:
			var leg_mesh = CylinderMesh.new()
			leg_mesh.top_radius = 0.06
			leg_mesh.bottom_radius = 0.07
			leg_mesh.height = 0.8
			leg_mesh.surface_set_material(0, metal_mat)
			var leg_inst = MeshInstance3D.new()
			leg_inst.mesh = leg_mesh
			leg_inst.position = Vector3(side, 0.55, 0)
			armor.add_child(leg_inst)

			## Sabatons (pes)
			var foot_mesh = BoxMesh.new()
			foot_mesh.size = Vector3(0.1, 0.06, 0.18)
			foot_mesh.surface_set_material(0, metal_mat)
			var foot_inst = MeshInstance3D.new()
			foot_inst.mesh = foot_mesh
			foot_inst.position = Vector3(side, 0.18, 0.04)
			armor.add_child(foot_inst)

		## Torso (caixa)
		var torso_mesh = BoxMesh.new()
		torso_mesh.size = Vector3(0.4, 0.5, 0.25)
		torso_mesh.surface_set_material(0, metal_mat)
		var torso_inst = MeshInstance3D.new()
		torso_inst.mesh = torso_mesh
		torso_inst.position.y = 1.2
		armor.add_child(torso_inst)

		## Cintura
		var waist_mesh = BoxMesh.new()
		waist_mesh.size = Vector3(0.35, 0.15, 0.22)
		waist_mesh.surface_set_material(0, metal_mat)
		var waist_inst = MeshInstance3D.new()
		waist_inst.mesh = waist_mesh
		waist_inst.position.y = 0.95
		armor.add_child(waist_inst)

		## Bracos (cilindros)
		for side in [-0.28, 0.28]:
			var arm_mesh = CylinderMesh.new()
			arm_mesh.top_radius = 0.05
			arm_mesh.bottom_radius = 0.06
			arm_mesh.height = 0.55
			arm_mesh.surface_set_material(0, metal_mat)
			var arm_inst = MeshInstance3D.new()
			arm_inst.mesh = arm_mesh
			arm_inst.position = Vector3(side, 1.1, 0)
			armor.add_child(arm_inst)

			## Ombreiras (esferas achatadas)
			var shoulder_mesh = SphereMesh.new()
			shoulder_mesh.radius = 0.08
			shoulder_mesh.height = 0.06
			shoulder_mesh.surface_set_material(0, metal_mat)
			var shoulder_inst = MeshInstance3D.new()
			shoulder_inst.mesh = shoulder_mesh
			shoulder_inst.position = Vector3(side, 1.4, 0)
			armor.add_child(shoulder_inst)

		## Cabeca (capacete = esfera com viseira)
		var head_mesh = SphereMesh.new()
		head_mesh.radius = 0.14
		head_mesh.height = 0.28
		head_mesh.surface_set_material(0, metal_mat)
		var head_inst = MeshInstance3D.new()
		head_inst.mesh = head_mesh
		head_inst.position.y = 1.58
		armor.add_child(head_inst)

		## Viseira do capacete
		var visor_mesh = BoxMesh.new()
		visor_mesh.size = Vector3(0.18, 0.04, 0.06)
		var visor_mat = StandardMaterial3D.new()
		visor_mat.albedo_color = Color(0.08, 0.06, 0.05)
		visor_mat.metallic = 0.9
		visor_mat.roughness = 0.3
		visor_mesh.surface_set_material(0, visor_mat)
		var visor_inst = MeshInstance3D.new()
		visor_inst.mesh = visor_mesh
		visor_inst.position = Vector3(0, 1.56, 0.12)
		armor.add_child(visor_inst)

		## Pluma no capacete
		var plume_mesh = BoxMesh.new()
		plume_mesh.size = Vector3(0.03, 0.2, 0.2)
		var plume_mat = StandardMaterial3D.new()
		plume_mat.albedo_color = Color(0.5, 0.02, 0.05)
		plume_mat.roughness = 0.8
		plume_mesh.surface_set_material(0, plume_mat)
		var plume_inst = MeshInstance3D.new()
		plume_inst.mesh = plume_mesh
		plume_inst.position = Vector3(0, 1.75, -0.05)
		armor.add_child(plume_inst)

		## Escudo (caixa no braco esquerdo)
		var shield_mesh = BoxMesh.new()
		shield_mesh.size = Vector3(0.04, 0.5, 0.35)
		shield_mesh.surface_set_material(0, metal_mat)
		var shield_inst = MeshInstance3D.new()
		shield_inst.mesh = shield_mesh
		shield_inst.position = Vector3(-0.35, 1.1, 0.08)
		armor.add_child(shield_inst)

		## Emblema no escudo
		var emblem_mesh = SphereMesh.new()
		emblem_mesh.radius = 0.06
		emblem_mesh.height = 0.03
		emblem_mesh.surface_set_material(0, _make_gold_mat())
		var emblem_inst = MeshInstance3D.new()
		emblem_inst.mesh = emblem_mesh
		emblem_inst.position = Vector3(-0.37, 1.15, 0.08)
		armor.add_child(emblem_inst)

		## Espada (caixa fina no braco direito)
		var sword_mesh = BoxMesh.new()
		sword_mesh.size = Vector3(0.04, 0.9, 0.02)
		var sword_mat = StandardMaterial3D.new()
		sword_mat.albedo_color = Color(0.6, 0.6, 0.65)
		sword_mat.metallic = 0.95
		sword_mat.roughness = 0.15
		sword_mesh.surface_set_material(0, sword_mat)
		var sword_inst = MeshInstance3D.new()
		sword_inst.mesh = sword_mesh
		sword_inst.position = Vector3(0.35, 1.25, 0.05)
		armor.add_child(sword_inst)

		## Guarda da espada
		var guard_mesh = BoxMesh.new()
		guard_mesh.size = Vector3(0.02, 0.04, 0.12)
		guard_mesh.surface_set_material(0, _make_gold_mat())
		var guard_inst = MeshInstance3D.new()
		guard_inst.mesh = guard_mesh
		guard_inst.position = Vector3(0.35, 0.8, 0.05)
		armor.add_child(guard_inst)

		add_child(armor)

## ---- Nevoa dupla camada + morcegos ----

func _generate_fog_particles() -> void:
	## Camada 1: nevoa baixa (chao)
	var ground_fog = GPUParticles3D.new()
	var gf_mat = ParticleProcessMaterial.new()
	gf_mat.direction = Vector3(0.3, 0, 0.2)
	gf_mat.spread = 60.0
	gf_mat.initial_velocity_min = 0.05
	gf_mat.initial_velocity_max = 0.2
	gf_mat.gravity = Vector3(0, 0, 0)
	gf_mat.scale_min = 0.8
	gf_mat.scale_max = 2.0
	gf_mat.color = Color(0.15, 0.1, 0.2, 0.12)
	gf_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	gf_mat.emission_box_extents = Vector3(60, 0.3, 60)

	ground_fog.process_material = gf_mat
	ground_fog.amount = 50
	ground_fog.lifetime = 10.0
	ground_fog.visibility_aabb = AABB(Vector3(-70, -1, -70), Vector3(140, 4, 140))

	var gf_draw = SphereMesh.new()
	gf_draw.radius = 1.2
	gf_draw.height = 0.5
	var gf_draw_mat = StandardMaterial3D.new()
	gf_draw_mat.albedo_color = Color(0.2, 0.15, 0.25, 0.08)
	gf_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gf_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gf_draw.surface_set_material(0, gf_draw_mat)
	ground_fog.draw_pass_1 = gf_draw

	ground_fog.position = Vector3(0, 0.3, 0)
	add_child(ground_fog)

	## Camada 2: nevoa alta (wisps)
	var high_fog = GPUParticles3D.new()
	var hf_mat = ParticleProcessMaterial.new()
	hf_mat.direction = Vector3(0.5, 0.1, 0.3)
	hf_mat.spread = 45.0
	hf_mat.initial_velocity_min = 0.1
	hf_mat.initial_velocity_max = 0.5
	hf_mat.gravity = Vector3(0, 0, 0)
	hf_mat.scale_min = 0.3
	hf_mat.scale_max = 1.0
	hf_mat.color = Color(0.12, 0.08, 0.18, 0.06)
	hf_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	hf_mat.emission_box_extents = Vector3(50, 2.0, 50)

	high_fog.process_material = hf_mat
	high_fog.amount = 30
	high_fog.lifetime = 7.0
	high_fog.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 10, 120))

	var hf_draw = SphereMesh.new()
	hf_draw.radius = 0.6
	hf_draw.height = 0.3
	var hf_draw_mat = StandardMaterial3D.new()
	hf_draw_mat.albedo_color = Color(0.18, 0.12, 0.22, 0.05)
	hf_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hf_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hf_draw.surface_set_material(0, hf_draw_mat)
	high_fog.draw_pass_1 = hf_draw

	high_fog.position = Vector3(0, 4.0, 0)
	add_child(high_fog)

func _generate_bat_particles() -> void:
	## Particulas de morcegos voando
	var bats = GPUParticles3D.new()
	var bat_mat = ParticleProcessMaterial.new()
	bat_mat.direction = Vector3(1, 0.2, 0.5)
	bat_mat.spread = 90.0
	bat_mat.initial_velocity_min = 2.0
	bat_mat.initial_velocity_max = 5.0
	bat_mat.gravity = Vector3(0, 0, 0)
	bat_mat.scale_min = 0.04
	bat_mat.scale_max = 0.1
	bat_mat.color = Color(0.08, 0.05, 0.1, 0.7)
	bat_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	bat_mat.emission_box_extents = Vector3(40, 3, 40)
	bat_mat.angular_velocity_min = 100.0
	bat_mat.angular_velocity_max = 300.0

	bats.process_material = bat_mat
	bats.amount = 20
	bats.lifetime = 4.0
	bats.visibility_aabb = AABB(Vector3(-60, -2, -60), Vector3(120, 15, 120))

	var bat_draw = BoxMesh.new()
	bat_draw.size = Vector3(0.15, 0.02, 0.08)
	var bat_draw_mat = StandardMaterial3D.new()
	bat_draw_mat.albedo_color = Color(0.06, 0.03, 0.08, 0.8)
	bat_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bat_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bat_draw.surface_set_material(0, bat_draw_mat)
	bats.draw_pass_1 = bat_draw

	bats.position = Vector3(0, 5.0, 0)
	add_child(bats)

## ---- Iluminacao atmosferica (mix quente/fria, 15+ luzes) ----

func _generate_atmospheric_lights() -> void:
	## Luzes de luar frio (azul/prata) — simulando luz entrando pelas janelas
	for i in range(6):
		var moon = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		moon.position = Vector3(x, rng.randf_range(4.0, 7.0), z)
		moon.light_color = Color(0.6, 0.65, 0.9)
		moon.light_energy = 0.3
		moon.omni_range = 12.0
		moon.omni_attenuation = 2.0
		add_child(moon)

	## Luzes quentes suaves (laranja/dourado) — velas e tochas dispersas
	for i in range(5):
		var warm = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		var z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		warm.position = Vector3(x, rng.randf_range(1.5, 3.5), z)
		warm.light_color = Color(1.0, 0.7, 0.35)
		warm.light_energy = 0.4
		warm.omni_range = 8.0
		warm.omni_attenuation = 2.5
		add_child(warm)

	## Luzes de acento dramaticas (vermelho/roxo)
	for i in range(4):
		var accent = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		accent.position = Vector3(x, rng.randf_range(0.5, 2.0), z)
		if rng.randi() % 2 == 0:
			accent.light_color = Color(0.6, 0.1, 0.15)
		else:
			accent.light_color = Color(0.3, 0.1, 0.5)
		accent.light_energy = 0.25
		accent.omni_range = 6.0
		accent.omni_attenuation = 3.0
		add_child(accent)
