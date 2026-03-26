extends Node3D

## Gera props procedurais para Mundo Doce estilo BotW: patches de chocolate, montanhas
## de sorvete com cereja e gotejamento, candy canes, gummy bears com wobble, arvores de
## pirulito, nuvens de algodao doce, plataformas de cookie, rio de doce, cupcake houses,
## arco-iris. Zonas de caramelo reduzem velocidade em 40%.

@export var num_chocolate: int = 20
@export var num_ice_cream: int = 15
@export var num_candy_canes: int = 25
@export var num_gummy_bears: int = 30
@export var num_caramel_zones: int = 8
@export var num_lollipop_trees: int = 12
@export var num_cotton_candy: int = 8
@export var num_cookie_platforms: int = 6
@export var num_cupcake_houses: int = 3
@export var num_gummy_worms: int = 15
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var caramel_zones: Array[Area3D] = []
var affected_bodies: Dictionary = {}
var wobble_bears: Array[Node3D] = []
var wobble_time: float = 0.0

func _ready() -> void:
	rng.randomize()
	_generate_chocolate_patches()
	_generate_ice_cream_mountains()
	_generate_candy_canes()
	_generate_gummy_bears()
	_generate_gummy_worms()
	_generate_caramel_zones()
	_generate_lollipop_trees()
	_generate_cotton_candy_clouds()
	_generate_cookie_platforms()
	_generate_cupcake_houses()
	_generate_candy_river()
	_generate_rainbow()
	_generate_sprinkle_particles()
	_generate_confetti_particles()
	_generate_ambient_lights()
	_add_real_models()

func _add_real_models() -> void:
	## Adiciona modelos Kenney — cogumelos coloridos, flores, arvores estilizadas
	ModelFactory.scatter_nature_props(self, "mushroom", 20, area_size, Vector2(1.5, 3.0))
	ModelFactory.scatter_nature_props(self, "mushroom_group", 10, area_size, Vector2(1.5, 3.0))
	ModelFactory.scatter_nature_props(self, "flower", 25, area_size, Vector2(1.0, 2.5))
	ModelFactory.scatter_nature_props(self, "tree", 8, area_size, Vector2(1.5, 3.0))
	ModelFactory.scatter_nature_props(self, "bush", 12, area_size, Vector2(1.0, 2.0))
	ModelFactory.scatter_nature_props(self, "grass", 15, area_size, Vector2(1.0, 2.0))
	ModelFactory.scatter_nature_props(self, "plant_flat", 10, area_size, Vector2(1.0, 2.0))

func _process(delta: float) -> void:
	## Efeito de slow do caramelo
	var currently_in: Dictionary = {}
	for area in caramel_zones:
		if not is_instance_valid(area):
			continue
		var bodies = area.get_overlapping_bodies()
		for body in bodies:
			currently_in[body] = true
			if not affected_bodies.has(body):
				affected_bodies[body] = true
				if body.is_in_group("players"):
					GameManager.speed_mult -= 0.4
				elif body.is_in_group("enemies") and body.has_method("set_speed_multiplier"):
					body.set_speed_multiplier(0.6)

	## Remove slow dos corpos que sairam
	var to_remove: Array = []
	for body in affected_bodies:
		if not currently_in.has(body):
			to_remove.append(body)
			if is_instance_valid(body):
				if body.is_in_group("players"):
					GameManager.speed_mult += 0.4
				elif body.is_in_group("enemies") and body.has_method("set_speed_multiplier"):
					body.set_speed_multiplier(1.0)
	for body in to_remove:
		affected_bodies.erase(body)

	## Wobble suave nos gummy bears
	wobble_time += delta
	for bear in wobble_bears:
		if is_instance_valid(bear):
			var wobble = 1.0 + sin(wobble_time * 2.0 + bear.position.x) * 0.05
			var wobble_y = 1.0 + sin(wobble_time * 2.0 + bear.position.z + 1.0) * 0.05
			bear.scale = Vector3(wobble, wobble_y, wobble)

## ---- Materiais reutilizaveis ----

func _make_candy_mat(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.3
	mat.metallic = 0.05
	if emissive:
		mat.emission_enabled = true
		mat.emission = Color(color.r * 0.5, color.g * 0.5, color.b * 0.5)
		mat.emission_energy_multiplier = 0.5
	return mat

func _make_translucent_mat(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.2
	mat.metallic = 0.1
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

## ---- Patches de chocolate ----

func _generate_chocolate_patches() -> void:
	for i in range(num_chocolate):
		var patch = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		patch.position = Vector3(x, 0, z)

		var patch_mesh = BoxMesh.new()
		var size_x = rng.randf_range(2.0, 6.0)
		var size_z = rng.randf_range(2.0, 6.0)
		patch_mesh.size = Vector3(size_x, 0.08, size_z)
		var brown = rng.randf_range(0.2, 0.35)
		var patch_mat = StandardMaterial3D.new()
		patch_mat.albedo_color = Color(brown, brown * 0.5, brown * 0.2)
		patch_mat.roughness = 0.4
		patch_mat.metallic = 0.1
		patch_mesh.surface_set_material(0, patch_mat)

		var patch_inst = MeshInstance3D.new()
		patch_inst.mesh = patch_mesh
		patch_inst.position.y = 0.04
		patch_inst.rotation.y = rng.randf_range(0, TAU)
		patch.add_child(patch_inst)

		## Pedacos de chocolate em cima
		var num_chunks = rng.randi_range(1, 3)
		for c in range(num_chunks):
			var chunk_mesh = BoxMesh.new()
			chunk_mesh.size = Vector3(
				rng.randf_range(0.3, 0.8),
				rng.randf_range(0.2, 0.5),
				rng.randf_range(0.3, 0.8)
			)
			var chunk_mat = StandardMaterial3D.new()
			chunk_mat.albedo_color = Color(0.25, 0.12, 0.05)
			chunk_mat.roughness = 0.3
			chunk_mesh.surface_set_material(0, chunk_mat)

			var chunk_inst = MeshInstance3D.new()
			chunk_inst.mesh = chunk_mesh
			chunk_inst.position = Vector3(
				rng.randf_range(-size_x / 3.0, size_x / 3.0),
				0.08 + chunk_mesh.size.y / 2.0,
				rng.randf_range(-size_z / 3.0, size_z / 3.0)
			)
			chunk_inst.rotation.y = rng.randf_range(0, TAU)
			patch.add_child(chunk_inst)

		add_child(patch)

## ---- Montanhas de sorvete com cereja e gotejamento ----

func _generate_ice_cream_mountains() -> void:
	var ice_cream_colors: Array[Color] = [
		Color(1.0, 0.8, 0.85),   # Morango
		Color(0.85, 0.7, 0.5),   # Baunilha
		Color(0.4, 0.25, 0.15),  # Chocolate
		Color(0.6, 0.9, 0.6),    # Menta
		Color(0.9, 0.85, 0.5),   # Banana
		Color(0.8, 0.6, 0.9),    # Uva
	]

	for i in range(num_ice_cream):
		var ice_cream = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		ice_cream.position = Vector3(x, 0, z)

		var s = rng.randf_range(0.8, 2.0)

		## Cone (casquinha) com padrao waffle (listras cruzadas)
		var cone_mesh = CylinderMesh.new()
		cone_mesh.top_radius = 0.8 * s
		cone_mesh.bottom_radius = 0.05 * s
		cone_mesh.height = 2.5 * s
		var cone_mat = StandardMaterial3D.new()
		cone_mat.albedo_color = Color(0.75, 0.6, 0.35)
		cone_mat.roughness = 0.7
		cone_mesh.surface_set_material(0, cone_mat)

		var cone_inst = MeshInstance3D.new()
		cone_inst.mesh = cone_mesh
		cone_inst.position.y = cone_mesh.height / 2.0
		ice_cream.add_child(cone_inst)

		## Faixas decorativas do waffle (listras diagonais)
		for w in range(3):
			var waffle_mesh = CylinderMesh.new()
			waffle_mesh.top_radius = 0.82 * s
			waffle_mesh.bottom_radius = 0.82 * s
			waffle_mesh.height = 0.03
			var waffle_mat = StandardMaterial3D.new()
			waffle_mat.albedo_color = Color(0.6, 0.45, 0.2)
			waffle_mat.roughness = 0.8
			waffle_mesh.surface_set_material(0, waffle_mat)
			var waffle_inst = MeshInstance3D.new()
			waffle_inst.mesh = waffle_mesh
			waffle_inst.position.y = cone_mesh.height * 0.5 + w * 0.4 * s
			ice_cream.add_child(waffle_inst)

		## Bolas de sorvete
		var num_scoops = rng.randi_range(1, 3)
		var top_scoop_y = 0.0
		for sc in range(num_scoops):
			var scoop_color = ice_cream_colors[rng.randi() % ice_cream_colors.size()]
			var scoop_mesh = SphereMesh.new()
			scoop_mesh.radius = rng.randf_range(0.6, 1.0) * s
			scoop_mesh.height = scoop_mesh.radius * 2.0
			var scoop_mat = StandardMaterial3D.new()
			scoop_mat.albedo_color = scoop_color
			scoop_mat.roughness = 0.4
			scoop_mesh.surface_set_material(0, scoop_mat)

			var scoop_inst = MeshInstance3D.new()
			scoop_inst.mesh = scoop_mesh
			scoop_inst.position.y = cone_mesh.height + scoop_mesh.radius * (sc * 1.4 + 0.5)
			scoop_inst.position.x = rng.randf_range(-0.2, 0.2) * s
			ice_cream.add_child(scoop_inst)
			top_scoop_y = scoop_inst.position.y + scoop_mesh.radius

			## Gotejamento (esferas pequenas escorrendo)
			var num_drips = rng.randi_range(1, 3)
			for d in range(num_drips):
				var drip_angle = rng.randf_range(0, TAU)
				var drip_r = scoop_mesh.radius * 0.8
				for dd in range(3):
					var drip_mesh = SphereMesh.new()
					var drip_size = rng.randf_range(0.05, 0.12) * s
					drip_mesh.radius = drip_size
					drip_mesh.height = drip_size * 2.0
					var drip_mat = StandardMaterial3D.new()
					drip_mat.albedo_color = scoop_color
					drip_mat.roughness = 0.3
					drip_mesh.surface_set_material(0, drip_mat)
					var drip_inst = MeshInstance3D.new()
					drip_inst.mesh = drip_mesh
					drip_inst.position = Vector3(
						cos(drip_angle) * drip_r,
						scoop_inst.position.y - scoop_mesh.radius * 0.5 - dd * 0.15 * s,
						sin(drip_angle) * drip_r
					)
					ice_cream.add_child(drip_inst)

		## Cereja no topo
		var cherry_mesh = SphereMesh.new()
		cherry_mesh.radius = 0.12 * s
		cherry_mesh.height = 0.24 * s
		var cherry_mat = StandardMaterial3D.new()
		cherry_mat.albedo_color = Color(0.9, 0.05, 0.05)
		cherry_mat.roughness = 0.2
		cherry_mat.metallic = 0.1
		cherry_mat.emission_enabled = true
		cherry_mat.emission = Color(0.5, 0.0, 0.0)
		cherry_mat.emission_energy_multiplier = 0.3
		cherry_mesh.surface_set_material(0, cherry_mat)
		var cherry_inst = MeshInstance3D.new()
		cherry_inst.mesh = cherry_mesh
		cherry_inst.position.y = top_scoop_y + 0.1 * s
		ice_cream.add_child(cherry_inst)

		## Talo da cereja
		var stem_mesh = CylinderMesh.new()
		stem_mesh.top_radius = 0.01 * s
		stem_mesh.bottom_radius = 0.015 * s
		stem_mesh.height = 0.2 * s
		var stem_mat = StandardMaterial3D.new()
		stem_mat.albedo_color = Color(0.15, 0.5, 0.1)
		stem_mat.roughness = 0.6
		stem_mesh.surface_set_material(0, stem_mat)
		var stem_inst = MeshInstance3D.new()
		stem_inst.mesh = stem_mesh
		stem_inst.position.y = top_scoop_y + 0.2 * s
		stem_inst.rotation.z = rng.randf_range(-0.3, 0.3)
		ice_cream.add_child(stem_inst)

		add_child(ice_cream)

## ---- Candy canes ----

func _generate_candy_canes() -> void:
	var stripe_colors: Array[Color] = [
		Color(1.0, 0.1, 0.1),   # Vermelho
		Color(0.1, 0.8, 0.2),   # Verde
		Color(0.1, 0.3, 1.0),   # Azul
		Color(1.0, 0.4, 0.8),   # Rosa
	]

	for i in range(num_candy_canes):
		var cane = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		cane.position = Vector3(x, 0, z)

		var height = rng.randf_range(2.5, 5.0)
		var stripe_color = stripe_colors[rng.randi() % stripe_colors.size()]

		## Bastao principal branco
		var stick_mesh = CylinderMesh.new()
		stick_mesh.top_radius = 0.15
		stick_mesh.bottom_radius = 0.15
		stick_mesh.height = height
		var stick_mat = StandardMaterial3D.new()
		stick_mat.albedo_color = Color(0.95, 0.95, 0.95)
		stick_mat.roughness = 0.3
		stick_mesh.surface_set_material(0, stick_mat)

		var stick_inst = MeshInstance3D.new()
		stick_inst.mesh = stick_mesh
		stick_inst.position.y = height / 2.0
		cane.add_child(stick_inst)

		## Faixas coloridas
		var num_stripes = int(height / 0.6)
		for st in range(num_stripes):
			var stripe_mesh = CylinderMesh.new()
			stripe_mesh.top_radius = 0.17
			stripe_mesh.bottom_radius = 0.17
			stripe_mesh.height = 0.15
			var s_mat = StandardMaterial3D.new()
			s_mat.albedo_color = stripe_color
			s_mat.roughness = 0.3
			stripe_mesh.surface_set_material(0, s_mat)

			var stripe_inst = MeshInstance3D.new()
			stripe_inst.mesh = stripe_mesh
			stripe_inst.position.y = st * 0.6 + 0.3
			cane.add_child(stripe_inst)

		## Curva no topo
		var curve_mesh = SphereMesh.new()
		curve_mesh.radius = 0.2
		curve_mesh.height = 0.4
		var curve_mat = StandardMaterial3D.new()
		curve_mat.albedo_color = stripe_color
		curve_mat.roughness = 0.3
		curve_mesh.surface_set_material(0, curve_mat)

		var curve_inst = MeshInstance3D.new()
		curve_inst.mesh = curve_mesh
		curve_inst.position = Vector3(0.15, height + 0.1, 0)
		cane.add_child(curve_inst)

		add_child(cane)

## ---- Gummy bears com translucidez e wobble ----

func _generate_gummy_bears() -> void:
	var gummy_colors: Array[Color] = [
		Color(1.0, 0.1, 0.1, 0.6),   # Vermelho
		Color(0.1, 0.9, 0.1, 0.6),   # Verde
		Color(1.0, 0.8, 0.0, 0.6),   # Amarelo
		Color(1.0, 0.5, 0.0, 0.6),   # Laranja
		Color(0.9, 0.9, 0.9, 0.6),   # Branco
		Color(0.8, 0.2, 0.8, 0.6),   # Roxo
	]

	for i in range(num_gummy_bears):
		var bear = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		bear.position = Vector3(x, 0, z)

		var sc = rng.randf_range(0.5, 1.5)
		var color = gummy_colors[rng.randi() % gummy_colors.size()]

		var body_mat = _make_translucent_mat(color)
		## Brilho sutil de gummy
		body_mat.emission_enabled = true
		body_mat.emission = Color(color.r * 0.3, color.g * 0.3, color.b * 0.3)
		body_mat.emission_energy_multiplier = 0.4

		## Corpo (esfera achatada)
		var body_mesh = SphereMesh.new()
		body_mesh.radius = 0.4 * sc
		body_mesh.height = 0.7 * sc
		body_mesh.surface_set_material(0, body_mat)

		var body_inst = MeshInstance3D.new()
		body_inst.mesh = body_mesh
		body_inst.position.y = 0.35 * sc
		bear.add_child(body_inst)

		## Cabeca
		var head_mesh = SphereMesh.new()
		head_mesh.radius = 0.25 * sc
		head_mesh.height = 0.3 * sc
		head_mesh.surface_set_material(0, body_mat)

		var head_inst = MeshInstance3D.new()
		head_inst.mesh = head_mesh
		head_inst.position.y = 0.75 * sc
		bear.add_child(head_inst)

		## Orelhas
		for side in [-1.0, 1.0]:
			var ear_mesh = SphereMesh.new()
			ear_mesh.radius = 0.1 * sc
			ear_mesh.height = 0.1 * sc
			ear_mesh.surface_set_material(0, body_mat)

			var ear_inst = MeshInstance3D.new()
			ear_inst.mesh = ear_mesh
			ear_inst.position = Vector3(side * 0.2 * sc, 0.9 * sc, 0)
			bear.add_child(ear_inst)

		## Olhinhos (pontos pretos)
		for side in [-0.06, 0.06]:
			var eye_mesh = SphereMesh.new()
			eye_mesh.radius = 0.025 * sc
			eye_mesh.height = 0.025 * sc
			var eye_mat = StandardMaterial3D.new()
			eye_mat.albedo_color = Color(0.05, 0.05, 0.05)
			eye_mesh.surface_set_material(0, eye_mat)
			var eye_inst = MeshInstance3D.new()
			eye_inst.mesh = eye_mesh
			eye_inst.position = Vector3(side * sc, 0.78 * sc, 0.2 * sc)
			bear.add_child(eye_inst)

		## Pernas curtas
		for side in [-0.12, 0.12]:
			var leg_mesh = SphereMesh.new()
			leg_mesh.radius = 0.1 * sc
			leg_mesh.height = 0.15 * sc
			leg_mesh.surface_set_material(0, body_mat)
			var leg_inst = MeshInstance3D.new()
			leg_inst.mesh = leg_mesh
			leg_inst.position = Vector3(side * sc, 0.07 * sc, 0)
			bear.add_child(leg_inst)

		wobble_bears.append(bear)
		add_child(bear)

## ---- Gummy worms ----

func _generate_gummy_worms() -> void:
	var worm_colors: Array[Color] = [
		Color(1.0, 0.3, 0.3, 0.65),
		Color(0.3, 1.0, 0.3, 0.65),
		Color(1.0, 1.0, 0.2, 0.65),
		Color(1.0, 0.5, 0.8, 0.65),
		Color(0.4, 0.7, 1.0, 0.65),
	]

	for i in range(num_gummy_worms):
		var worm = Node3D.new()
		var x = rng.randf_range(-area_size * 0.9, area_size * 0.9)
		var z = rng.randf_range(-area_size * 0.9, area_size * 0.9)
		worm.position = Vector3(x, 0.03, z)
		worm.rotation.y = rng.randf_range(0, TAU)

		var color = worm_colors[rng.randi() % worm_colors.size()]
		var worm_mat = _make_translucent_mat(color)
		worm_mat.emission_enabled = true
		worm_mat.emission = Color(color.r * 0.3, color.g * 0.3, color.b * 0.3)
		worm_mat.emission_energy_multiplier = 0.3

		## Segmentos do worm (cilindros curvando)
		var num_segments = rng.randi_range(4, 7)
		var seg_len = rng.randf_range(0.15, 0.25)
		var curve_dir = rng.randf_range(-0.3, 0.3)
		var cx = 0.0
		var cz = 0.0
		var cur_angle = 0.0
		for seg in range(num_segments):
			var seg_mesh = CylinderMesh.new()
			seg_mesh.top_radius = 0.04
			seg_mesh.bottom_radius = 0.04
			seg_mesh.height = seg_len
			seg_mesh.surface_set_material(0, worm_mat)

			var seg_inst = MeshInstance3D.new()
			seg_inst.mesh = seg_mesh
			seg_inst.position = Vector3(cx, 0, cz)
			seg_inst.rotation.z = PI / 2.0
			seg_inst.rotation.y = cur_angle
			worm.add_child(seg_inst)

			cx += cos(cur_angle) * seg_len
			cz += sin(cur_angle) * seg_len
			cur_angle += curve_dir

		add_child(worm)

## ---- Zonas de caramelo (slow debuff) ----

func _generate_caramel_zones() -> void:
	for i in range(num_caramel_zones):
		var zone_node = Node3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		zone_node.position = Vector3(x, 0, z)

		var zone_size = rng.randf_range(6.0, 12.0)

		## Visual — chao de caramelo pegajoso
		var vis_mesh = BoxMesh.new()
		vis_mesh.size = Vector3(zone_size, 0.05, zone_size)
		var vis_mat = StandardMaterial3D.new()
		vis_mat.albedo_color = Color(0.7, 0.45, 0.1, 0.5)
		vis_mat.emission_enabled = true
		vis_mat.emission = Color(0.5, 0.3, 0.05)
		vis_mat.emission_energy_multiplier = 0.5
		vis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vis_mat.roughness = 0.1
		vis_mat.metallic = 0.3
		vis_mesh.surface_set_material(0, vis_mat)

		var vis_inst = MeshInstance3D.new()
		vis_inst.mesh = vis_mesh
		vis_inst.position.y = 0.03
		zone_node.add_child(vis_inst)

		## Bolhas de caramelo (esferas pequenas)
		var num_bubbles = rng.randi_range(3, 6)
		for b in range(num_bubbles):
			var bubble_mesh = SphereMesh.new()
			var br = rng.randf_range(0.08, 0.2)
			bubble_mesh.radius = br
			bubble_mesh.height = br * 1.5
			var bubble_mat = StandardMaterial3D.new()
			bubble_mat.albedo_color = Color(0.8, 0.5, 0.1, 0.4)
			bubble_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			bubble_mat.emission_enabled = true
			bubble_mat.emission = Color(0.6, 0.35, 0.05)
			bubble_mat.emission_energy_multiplier = 0.4
			bubble_mesh.surface_set_material(0, bubble_mat)
			var bubble_inst = MeshInstance3D.new()
			bubble_inst.mesh = bubble_mesh
			bubble_inst.position = Vector3(
				rng.randf_range(-zone_size * 0.4, zone_size * 0.4),
				0.06 + br,
				rng.randf_range(-zone_size * 0.4, zone_size * 0.4)
			)
			zone_node.add_child(bubble_inst)

		## Area3D
		var area = Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 3  # Players + Enemies
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(zone_size, 2.0, zone_size)
		col.shape = shape
		col.position.y = 1.0
		area.add_child(col)
		zone_node.add_child(area)
		caramel_zones.append(area)

		add_child(zone_node)

## ---- Arvores de pirulito ----

func _generate_lollipop_trees() -> void:
	var lollipop_colors: Array[Array] = [
		[Color(1.0, 0.2, 0.4), Color(0.95, 0.95, 0.95)],    # Rosa + Branco
		[Color(0.2, 0.8, 0.3), Color(1.0, 1.0, 0.3)],        # Verde + Amarelo
		[Color(0.3, 0.4, 1.0), Color(0.95, 0.95, 0.95)],     # Azul + Branco
		[Color(1.0, 0.5, 0.0), Color(0.9, 0.1, 0.1)],        # Laranja + Vermelho
		[Color(0.7, 0.2, 0.9), Color(1.0, 0.7, 0.9)],        # Roxo + Rosa claro
	]

	for i in range(num_lollipop_trees):
		var tree = Node3D.new()
		var x = rng.randf_range(-area_size * 0.9, area_size * 0.9)
		var z = rng.randf_range(-area_size * 0.9, area_size * 0.9)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		tree.position = Vector3(x, 0, z)

		var scale_f = rng.randf_range(0.7, 1.5)
		var stick_h = rng.randf_range(2.5, 5.0) * scale_f
		var disc_r = rng.randf_range(0.8, 1.5) * scale_f
		var colors = lollipop_colors[rng.randi() % lollipop_colors.size()]

		## Bastao (cilindro fino)
		var stick_mesh = CylinderMesh.new()
		stick_mesh.top_radius = 0.06 * scale_f
		stick_mesh.bottom_radius = 0.08 * scale_f
		stick_mesh.height = stick_h
		var stick_mat = StandardMaterial3D.new()
		stick_mat.albedo_color = Color(0.9, 0.85, 0.75)
		stick_mat.roughness = 0.3
		stick_mesh.surface_set_material(0, stick_mat)
		var stick_inst = MeshInstance3D.new()
		stick_inst.mesh = stick_mesh
		stick_inst.position.y = stick_h / 2.0
		tree.add_child(stick_inst)

		## Disco do pirulito (cilindro achatado) — metade cor 1
		var disc1_mesh = CylinderMesh.new()
		disc1_mesh.top_radius = disc_r
		disc1_mesh.bottom_radius = disc_r
		disc1_mesh.height = 0.15 * scale_f
		var disc1_mat = _make_candy_mat(colors[0], true)
		disc1_mesh.surface_set_material(0, disc1_mat)
		var disc1_inst = MeshInstance3D.new()
		disc1_inst.mesh = disc1_mesh
		disc1_inst.position.y = stick_h + 0.08 * scale_f
		disc1_inst.rotation.x = PI / 2.0
		## Metade do disco (deslocado levemente)
		disc1_inst.position.z = 0.01
		tree.add_child(disc1_inst)

		## Disco do pirulito — metade cor 2 (sobreposto no outro lado)
		var disc2_mesh = CylinderMesh.new()
		disc2_mesh.top_radius = disc_r * 0.85
		disc2_mesh.bottom_radius = disc_r * 0.85
		disc2_mesh.height = 0.16 * scale_f
		var disc2_mat = _make_candy_mat(colors[1], true)
		disc2_mesh.surface_set_material(0, disc2_mat)
		var disc2_inst = MeshInstance3D.new()
		disc2_inst.mesh = disc2_mesh
		disc2_inst.position.y = stick_h + 0.08 * scale_f
		disc2_inst.rotation.x = PI / 2.0
		disc2_inst.position.z = -0.01
		tree.add_child(disc2_inst)

		## Espiral hint (anel fino de contraste)
		var spiral_mesh = CylinderMesh.new()
		spiral_mesh.top_radius = disc_r * 0.55
		spiral_mesh.bottom_radius = disc_r * 0.55
		spiral_mesh.height = 0.17 * scale_f
		spiral_mesh.surface_set_material(0, disc1_mat)
		var spiral_inst = MeshInstance3D.new()
		spiral_inst.mesh = spiral_mesh
		spiral_inst.position.y = stick_h + 0.08 * scale_f
		spiral_inst.rotation.x = PI / 2.0
		tree.add_child(spiral_inst)

		add_child(tree)

## ---- Nuvens de algodao doce flutuando ----

func _generate_cotton_candy_clouds() -> void:
	var cloud_colors: Array[Color] = [
		Color(1.0, 0.75, 0.85, 0.7),  # Rosa
		Color(0.7, 0.85, 1.0, 0.7),   # Azul claro
		Color(1.0, 1.0, 0.75, 0.7),   # Amarelo claro
		Color(0.95, 0.95, 0.95, 0.7),  # Branco
		Color(0.85, 0.7, 1.0, 0.7),   # Lavanda
	]

	for i in range(num_cotton_candy):
		var cloud = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var cloud_y = rng.randf_range(5.0, 8.0)
		cloud.position = Vector3(x, cloud_y, z)

		var base_color = cloud_colors[rng.randi() % cloud_colors.size()]

		## Cluster de 3-5 esferas formando nuvem
		var num_puffs = rng.randi_range(3, 5)
		for p in range(num_puffs):
			var puff_mesh = SphereMesh.new()
			var pr = rng.randf_range(0.6, 1.5)
			puff_mesh.radius = pr
			puff_mesh.height = pr * 1.6
			var puff_mat = StandardMaterial3D.new()
			puff_mat.albedo_color = Color(
				base_color.r + rng.randf_range(-0.05, 0.05),
				base_color.g + rng.randf_range(-0.05, 0.05),
				base_color.b + rng.randf_range(-0.05, 0.05),
				base_color.a
			)
			puff_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			puff_mat.roughness = 0.9
			puff_mat.emission_enabled = true
			puff_mat.emission = Color(base_color.r * 0.4, base_color.g * 0.4, base_color.b * 0.4)
			puff_mat.emission_energy_multiplier = 0.5
			puff_mesh.surface_set_material(0, puff_mat)

			var puff_inst = MeshInstance3D.new()
			puff_inst.mesh = puff_mesh
			puff_inst.position = Vector3(
				rng.randf_range(-1.0, 1.0),
				rng.randf_range(-0.3, 0.3),
				rng.randf_range(-1.0, 1.0)
			)
			cloud.add_child(puff_inst)

		add_child(cloud)

## ---- Plataformas de cookie ----

func _generate_cookie_platforms() -> void:
	for i in range(num_cookie_platforms):
		var cookie = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		cookie.position = Vector3(x, 0, z)

		var cookie_r = rng.randf_range(1.5, 3.0)

		## Corpo do cookie (cilindro achatado marrom)
		var cookie_mesh = CylinderMesh.new()
		cookie_mesh.top_radius = cookie_r
		cookie_mesh.bottom_radius = cookie_r
		cookie_mesh.height = 0.25
		var cookie_mat = StandardMaterial3D.new()
		cookie_mat.albedo_color = Color(0.75, 0.55, 0.3)
		cookie_mat.roughness = 0.7
		cookie_mesh.surface_set_material(0, cookie_mat)

		var cookie_inst = MeshInstance3D.new()
		cookie_inst.mesh = cookie_mesh
		cookie_inst.position.y = 0.125
		cookie.add_child(cookie_inst)

		## Borda mais escura (anel)
		var edge_mesh = CylinderMesh.new()
		edge_mesh.top_radius = cookie_r + 0.02
		edge_mesh.bottom_radius = cookie_r + 0.02
		edge_mesh.height = 0.22
		var edge_mat = StandardMaterial3D.new()
		edge_mat.albedo_color = Color(0.6, 0.4, 0.2)
		edge_mat.roughness = 0.7
		edge_mesh.surface_set_material(0, edge_mat)
		var edge_inst = MeshInstance3D.new()
		edge_inst.mesh = edge_mesh
		edge_inst.position.y = 0.12
		cookie.add_child(edge_inst)

		## Chocolate chips (esferas escuras no topo)
		var num_chips = rng.randi_range(5, 12)
		for c in range(num_chips):
			var chip_angle = rng.randf_range(0, TAU)
			var chip_dist = rng.randf_range(0.2, cookie_r * 0.8)
			var chip_mesh = SphereMesh.new()
			var chip_r = rng.randf_range(0.08, 0.18)
			chip_mesh.radius = chip_r
			chip_mesh.height = chip_r * 1.2
			var chip_mat = StandardMaterial3D.new()
			chip_mat.albedo_color = Color(0.15, 0.08, 0.03)
			chip_mat.roughness = 0.4
			chip_mesh.surface_set_material(0, chip_mat)
			var chip_inst = MeshInstance3D.new()
			chip_inst.mesh = chip_mesh
			chip_inst.position = Vector3(
				cos(chip_angle) * chip_dist,
				0.25 + chip_r * 0.3,
				sin(chip_angle) * chip_dist
			)
			cookie.add_child(chip_inst)

		add_child(cookie)

## ---- Cupcake houses ----

func _generate_cupcake_houses() -> void:
	var frosting_colors: Array[Color] = [
		Color(1.0, 0.6, 0.75),   # Rosa
		Color(0.7, 0.9, 1.0),    # Azul claro
		Color(0.9, 1.0, 0.6),    # Verde lima
	]

	for i in range(num_cupcake_houses):
		var cupcake = Node3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		if abs(x) < 8 and abs(z) < 8:
			x += 12.0
		cupcake.position = Vector3(x, 0, z)

		var sc = rng.randf_range(1.0, 1.5)

		## Wrapper/base (cilindro com listras)
		var base_mesh = CylinderMesh.new()
		base_mesh.top_radius = 1.5 * sc
		base_mesh.bottom_radius = 1.0 * sc
		base_mesh.height = 2.0 * sc
		var base_mat = StandardMaterial3D.new()
		base_mat.albedo_color = Color(0.85, 0.75, 0.55)
		base_mat.roughness = 0.6
		base_mesh.surface_set_material(0, base_mat)
		var base_inst = MeshInstance3D.new()
		base_inst.mesh = base_mesh
		base_inst.position.y = 1.0 * sc
		cupcake.add_child(base_inst)

		## Linhas do wrapper
		for ln in range(6):
			var line_mesh = BoxMesh.new()
			line_mesh.size = Vector3(0.02, 2.0 * sc, 0.02)
			var line_mat = StandardMaterial3D.new()
			line_mat.albedo_color = Color(0.7, 0.6, 0.4)
			line_mat.roughness = 0.7
			line_mesh.surface_set_material(0, line_mat)
			var line_inst = MeshInstance3D.new()
			line_inst.mesh = line_mesh
			var la = (float(ln) / 6.0) * TAU
			line_inst.position = Vector3(cos(la) * 1.25 * sc, 1.0 * sc, sin(la) * 1.25 * sc)
			cupcake.add_child(line_inst)

		## Frosting (esferas empilhadas diminuindo)
		var frosting_color = frosting_colors[i % frosting_colors.size()]
		var frosting_mat = _make_candy_mat(frosting_color, true)
		var frosting_y = 2.0 * sc
		var frosting_sizes = [1.4, 1.1, 0.8, 0.5]
		for fi in range(frosting_sizes.size()):
			var fr = frosting_sizes[fi] * sc
			var frost_mesh = SphereMesh.new()
			frost_mesh.radius = fr
			frost_mesh.height = fr * 1.2
			frost_mesh.surface_set_material(0, frosting_mat)
			var frost_inst = MeshInstance3D.new()
			frost_inst.mesh = frost_mesh
			frost_inst.position.y = frosting_y + fr * 0.5
			cupcake.add_child(frost_inst)
			frosting_y += fr * 0.8

		## Sprinkles no frosting (pequenas caixas coloridas)
		for sp in range(8):
			var sp_mesh = BoxMesh.new()
			sp_mesh.size = Vector3(0.03, 0.08, 0.03)
			var sp_mat = StandardMaterial3D.new()
			sp_mat.albedo_color = Color(rng.randf(), rng.randf(), rng.randf())
			sp_mat.emission_enabled = true
			sp_mat.emission = sp_mat.albedo_color
			sp_mat.emission_energy_multiplier = 0.5
			sp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sp_mesh.surface_set_material(0, sp_mat)
			var sp_inst = MeshInstance3D.new()
			sp_inst.mesh = sp_mesh
			var sp_angle = rng.randf_range(0, TAU)
			var sp_dist = rng.randf_range(0.3, 1.0) * sc
			sp_inst.position = Vector3(
				cos(sp_angle) * sp_dist,
				rng.randf_range(2.5, 3.5) * sc,
				sin(sp_angle) * sp_dist
			)
			sp_inst.rotation = Vector3(rng.randf_range(0, TAU), rng.randf_range(0, TAU), 0)
			cupcake.add_child(sp_inst)

		## Vela no topo
		var candle_mesh = CylinderMesh.new()
		candle_mesh.top_radius = 0.05 * sc
		candle_mesh.bottom_radius = 0.06 * sc
		candle_mesh.height = 0.6 * sc
		var candle_mat = StandardMaterial3D.new()
		candle_mat.albedo_color = Color(0.9, 0.9, 0.3)
		candle_mat.roughness = 0.4
		candle_mesh.surface_set_material(0, candle_mat)
		var candle_inst = MeshInstance3D.new()
		candle_inst.mesh = candle_mesh
		candle_inst.position.y = frosting_y + 0.3 * sc
		cupcake.add_child(candle_inst)

		## Chama da vela (particulas)
		var flame = GPUParticles3D.new()
		var flame_mat = ParticleProcessMaterial.new()
		flame_mat.direction = Vector3(0, 1, 0)
		flame_mat.spread = 8.0
		flame_mat.initial_velocity_min = 0.3
		flame_mat.initial_velocity_max = 0.6
		flame_mat.gravity = Vector3(0, 0.2, 0)
		flame_mat.scale_min = 0.03
		flame_mat.scale_max = 0.08
		flame_mat.color = Color(1.0, 0.7, 0.2, 0.9)

		flame.process_material = flame_mat
		flame.amount = 8
		flame.lifetime = 0.5
		flame.visibility_aabb = AABB(Vector3(-0.5, -0.5, -0.5), Vector3(1, 2, 1))

		var flame_draw = SphereMesh.new()
		flame_draw.radius = 0.04
		flame_draw.height = 0.06
		var flame_draw_mat = StandardMaterial3D.new()
		flame_draw_mat.albedo_color = Color(1.0, 0.8, 0.3, 0.8)
		flame_draw_mat.emission_enabled = true
		flame_draw_mat.emission = Color(1.0, 0.5, 0.0)
		flame_draw_mat.emission_energy_multiplier = 3.0
		flame_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		flame_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flame_draw.surface_set_material(0, flame_draw_mat)
		flame.draw_pass_1 = flame_draw

		flame.position.y = frosting_y + 0.65 * sc
		cupcake.add_child(flame)

		add_child(cupcake)

## ---- Rio de doce (candy river) ----

func _generate_candy_river() -> void:
	var river = Node3D.new()
	river.position = Vector3(0, 0, 0)

	## Rio sinuoso feito de segmentos
	var num_segments = 20
	var river_z_start = -area_size * 0.6
	var river_z_end = area_size * 0.6
	var segment_len = (river_z_end - river_z_start) / num_segments
	var river_x = rng.randf_range(-15.0, 15.0)

	var river_mat = StandardMaterial3D.new()
	river_mat.albedo_color = Color(1.0, 0.3, 0.6, 0.5)
	river_mat.emission_enabled = true
	river_mat.emission = Color(0.8, 0.2, 0.5)
	river_mat.emission_energy_multiplier = 1.0
	river_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	river_mat.roughness = 0.05
	river_mat.metallic = 0.2

	for seg in range(num_segments):
		var seg_z = river_z_start + seg * segment_len
		river_x += rng.randf_range(-3.0, 3.0)
		river_x = clampf(river_x, -30.0, 30.0)

		var width = rng.randf_range(2.5, 4.5)

		var seg_mesh = BoxMesh.new()
		seg_mesh.size = Vector3(width, 0.06, segment_len + 0.5)
		seg_mesh.surface_set_material(0, river_mat)

		var seg_inst = MeshInstance3D.new()
		seg_inst.mesh = seg_mesh
		seg_inst.position = Vector3(river_x, 0.02, seg_z + segment_len / 2.0)
		river.add_child(seg_inst)

		## Bolhas na superficie
		if rng.randi() % 3 == 0:
			var bubble_mesh = SphereMesh.new()
			bubble_mesh.radius = rng.randf_range(0.06, 0.15)
			bubble_mesh.height = bubble_mesh.radius * 2.0
			var bubble_mat = StandardMaterial3D.new()
			bubble_mat.albedo_color = Color(1.0, 0.5, 0.7, 0.3)
			bubble_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			bubble_mat.emission_enabled = true
			bubble_mat.emission = Color(1.0, 0.4, 0.6)
			bubble_mat.emission_energy_multiplier = 0.5
			bubble_mesh.surface_set_material(0, bubble_mat)
			var bubble_inst = MeshInstance3D.new()
			bubble_inst.mesh = bubble_mesh
			bubble_inst.position = Vector3(
				river_x + rng.randf_range(-width * 0.3, width * 0.3),
				0.08,
				seg_z + rng.randf_range(0, segment_len)
			)
			river.add_child(bubble_inst)

	add_child(river)

## ---- Arco-iris ----

func _generate_rainbow() -> void:
	var rainbow = Node3D.new()
	var rx = rng.randf_range(-area_size * 0.3, area_size * 0.3)
	var rz = rng.randf_range(-area_size * 0.3, area_size * 0.3)
	rainbow.position = Vector3(rx, 0, rz)
	rainbow.rotation.y = rng.randf_range(0, TAU)

	var rainbow_colors: Array[Color] = [
		Color(1.0, 0.0, 0.0, 0.6),    # Vermelho
		Color(1.0, 0.5, 0.0, 0.6),    # Laranja
		Color(1.0, 1.0, 0.0, 0.6),    # Amarelo
		Color(0.0, 1.0, 0.0, 0.6),    # Verde
		Color(0.0, 0.5, 1.0, 0.6),    # Azul
		Color(0.3, 0.0, 0.8, 0.6),    # Indigo
		Color(0.6, 0.0, 1.0, 0.6),    # Violeta
	]

	var arc_radius = 20.0
	var arc_height = 15.0
	var num_arc_segments = 16

	for ci in range(rainbow_colors.size()):
		var band_r = arc_radius + ci * 0.6
		var color = rainbow_colors[ci]

		var band_mat = StandardMaterial3D.new()
		band_mat.albedo_color = color
		band_mat.emission_enabled = true
		band_mat.emission = Color(color.r, color.g, color.b)
		band_mat.emission_energy_multiplier = 1.5
		band_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		band_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

		for seg in range(num_arc_segments):
			var t = float(seg) / (num_arc_segments - 1)
			var angle = t * PI  ## Meio circulo
			var bx = cos(angle) * band_r
			var by = sin(angle) * arc_height * (sin(angle))  ## Arco parabolico
			var next_t = float(seg + 1) / (num_arc_segments - 1)
			var next_angle = next_t * PI

			var seg_mesh = BoxMesh.new()
			seg_mesh.size = Vector3(0.3, 0.15, band_r * PI / num_arc_segments * 1.1)
			seg_mesh.surface_set_material(0, band_mat)

			var seg_inst = MeshInstance3D.new()
			seg_inst.mesh = seg_mesh
			seg_inst.position = Vector3(bx, by, 0)

			## Rotacionar para acompanhar o arco
			var mid_angle = (angle + next_angle) / 2.0
			seg_inst.rotation.z = mid_angle - PI / 2.0
			rainbow.add_child(seg_inst)

	add_child(rainbow)

## ---- Sprinkles coloridos (multicolorido via material emissivo) ----

func _generate_sprinkle_particles() -> void:
	var sprinkles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.5
	mat.gravity = Vector3(0, -0.3, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.1
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(60, 0.5, 60)

	## Rampa de cores para sprinkles multicoloridos
	var color_ramp = Gradient.new()
	color_ramp.set_color(0, Color(1.0, 0.2, 0.4, 0.8))
	color_ramp.add_point(0.2, Color(1.0, 0.8, 0.0, 0.8))
	color_ramp.add_point(0.4, Color(0.2, 1.0, 0.3, 0.8))
	color_ramp.add_point(0.6, Color(0.3, 0.5, 1.0, 0.8))
	color_ramp.add_point(0.8, Color(0.9, 0.3, 0.9, 0.8))
	color_ramp.set_color(1, Color(1.0, 0.5, 0.2, 0.8))

	var color_texture = GradientTexture1D.new()
	color_texture.gradient = color_ramp
	mat.color_ramp = color_texture

	sprinkles.process_material = mat
	sprinkles.amount = 100
	sprinkles.lifetime = 5.0
	sprinkles.visibility_aabb = AABB(Vector3(-70, -2, -70), Vector3(140, 15, 140))

	var draw_pass = BoxMesh.new()
	draw_pass.size = Vector3(0.02, 0.06, 0.02)
	var sprinkle_mat = StandardMaterial3D.new()
	sprinkle_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
	sprinkle_mat.emission_enabled = true
	sprinkle_mat.emission = Color(1.0, 0.8, 0.9)
	sprinkle_mat.emission_energy_multiplier = 1.5
	sprinkle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sprinkle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, sprinkle_mat)
	sprinkles.draw_pass_1 = draw_pass

	sprinkles.position = Vector3(0, 10.0, 0)
	add_child(sprinkles)

## ---- Confetes (particulas maiores e achatadas) ----

func _generate_confetti_particles() -> void:
	var confetti = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 50.0
	mat.initial_velocity_min = 0.1
	mat.initial_velocity_max = 0.3
	mat.gravity = Vector3(0, -0.15, 0)
	mat.scale_min = 0.08
	mat.scale_max = 0.2
	mat.angular_velocity_min = 50.0
	mat.angular_velocity_max = 200.0
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(55, 0.5, 55)

	var color_ramp = Gradient.new()
	color_ramp.set_color(0, Color(1.0, 0.3, 0.5, 0.6))
	color_ramp.add_point(0.25, Color(0.3, 1.0, 0.5, 0.6))
	color_ramp.add_point(0.5, Color(0.4, 0.6, 1.0, 0.6))
	color_ramp.add_point(0.75, Color(1.0, 0.9, 0.2, 0.6))
	color_ramp.set_color(1, Color(0.9, 0.4, 1.0, 0.6))

	var color_texture = GradientTexture1D.new()
	color_texture.gradient = color_ramp
	mat.color_ramp = color_texture

	confetti.process_material = mat
	confetti.amount = 40
	confetti.lifetime = 8.0
	confetti.visibility_aabb = AABB(Vector3(-65, -2, -65), Vector3(130, 18, 130))

	var draw_pass = BoxMesh.new()
	draw_pass.size = Vector3(0.1, 0.01, 0.08)
	var conf_mat = StandardMaterial3D.new()
	conf_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.7)
	conf_mat.emission_enabled = true
	conf_mat.emission = Color(1.0, 0.9, 0.95)
	conf_mat.emission_energy_multiplier = 1.0
	conf_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	conf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	conf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	draw_pass.surface_set_material(0, conf_mat)
	confetti.draw_pass_1 = draw_pass

	confetti.position = Vector3(0, 12.0, 0)
	add_child(confetti)

## ---- Iluminacao ambiente (15+ luzes, quente e alegre) ----

func _generate_ambient_lights() -> void:
	## Luzes rosa quentes
	for i in range(5):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		light.position = Vector3(x, rng.randf_range(2.0, 4.0), z)
		light.light_color = Color(1.0, 0.6, 0.75)
		light.light_energy = 0.6
		light.omni_range = 12.0
		light.omni_attenuation = 2.0
		add_child(light)

	## Luzes amarelo/dourado
	for i in range(4):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		light.position = Vector3(x, rng.randf_range(1.5, 3.5), z)
		light.light_color = Color(1.0, 0.9, 0.4)
		light.light_energy = 0.5
		light.omni_range = 10.0
		light.omni_attenuation = 2.0
		add_child(light)

	## Luzes verde menta
	for i in range(3):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		var z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		light.position = Vector3(x, rng.randf_range(2.0, 3.0), z)
		light.light_color = Color(0.5, 1.0, 0.6)
		light.light_energy = 0.4
		light.omni_range = 9.0
		light.omni_attenuation = 2.5
		add_child(light)

	## Uplights sob nuvens de algodao doce (posicionadas alto)
	for i in range(3):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		var z = rng.randf_range(-area_size * 0.5, area_size * 0.5)
		light.position = Vector3(x, rng.randf_range(4.0, 6.0), z)
		light.light_color = Color(0.9, 0.7, 1.0)
		light.light_energy = 0.35
		light.omni_range = 8.0
		light.omni_attenuation = 2.0
		add_child(light)
