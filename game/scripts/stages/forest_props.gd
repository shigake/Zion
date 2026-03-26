extends Node3D

## Gera props aleatorios na Floresta Encantada: cogumelos, arvores, rio, flores, troncos, circulos de fadas.
## Estilo BotW — low-poly estilizado com iluminacao magica e atmosfera encantada.

@export var num_mushrooms: int = 40
@export var num_trees: int = 30
@export var num_river_segments: int = 15
@export var num_flower_patches: int = 20
@export var num_fallen_logs: int = 8
@export var num_fairy_circles: int = 5
@export var num_butterflies: int = 6
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var cap_colors: Array[Color] = [
	Color(0.8, 0.1, 0.1),   # Vermelho
	Color(0.2, 0.2, 0.9),   # Azul
	Color(0.6, 0.1, 0.7),   # Roxo
	Color(0.9, 0.2, 0.5),   # Rosa
	Color(0.1, 0.6, 0.8),   # Ciano
]

var buff_mushrooms: Array = []

func _ready() -> void:
	rng.randomize()
	_generate_mushrooms()
	_generate_trees()
	_generate_river()
	_generate_flower_patches()
	_generate_fallen_logs()
	_generate_fairy_circles()
	_generate_butterflies()
	_generate_sparkles()
	_generate_ambient_lights()

## -------------------------------------------------------
## Cogumelos com manchas brancas e clusters pequenos na base das arvores
## -------------------------------------------------------
func _generate_mushrooms() -> void:
	for i in range(num_mushrooms):
		var mushroom = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		mushroom.position = Vector3(x, 0, z)

		var scale_factor = rng.randf_range(0.6, 1.8)

		## Tronco do cogumelo
		var trunk_mesh = CylinderMesh.new()
		trunk_mesh.top_radius = 0.15 * scale_factor
		trunk_mesh.bottom_radius = 0.25 * scale_factor
		trunk_mesh.height = rng.randf_range(1.0, 2.5) * scale_factor
		var trunk_mat = StandardMaterial3D.new()
		trunk_mat.albedo_color = Color(0.85, 0.82, 0.7)
		trunk_mat.roughness = 0.8
		trunk_mesh.surface_set_material(0, trunk_mat)

		var trunk = MeshInstance3D.new()
		trunk.mesh = trunk_mesh
		trunk.position.y = trunk_mesh.height / 2.0
		mushroom.add_child(trunk)

		## Chapeu do cogumelo (esfera achatada)
		var cap_mesh = SphereMesh.new()
		cap_mesh.radius = 0.6 * scale_factor
		cap_mesh.height = 0.5 * scale_factor
		var cap_mat = StandardMaterial3D.new()
		var cap_color = cap_colors[rng.randi() % cap_colors.size()]
		cap_mat.albedo_color = cap_color
		cap_mat.roughness = 0.5
		cap_mat.emission_enabled = true
		cap_mat.emission = cap_color * 0.3
		cap_mat.emission_energy_multiplier = 0.5
		cap_mesh.surface_set_material(0, cap_mat)

		var cap = MeshInstance3D.new()
		cap.mesh = cap_mesh
		cap.position.y = trunk_mesh.height + 0.1 * scale_factor
		mushroom.add_child(cap)

		## Manchas brancas no chapeu (estilo amanita — bolinhas brancas)
		if cap_color.r > 0.5 or rng.randf() < 0.5:
			var spot_mat = StandardMaterial3D.new()
			spot_mat.albedo_color = Color(0.95, 0.95, 0.9)
			spot_mat.roughness = 0.6
			var num_spots = rng.randi_range(3, 7)
			for sp in range(num_spots):
				var spot_mesh = SphereMesh.new()
				var spot_r = rng.randf_range(0.03, 0.06) * scale_factor
				spot_mesh.radius = spot_r
				spot_mesh.height = spot_r * 1.5
				spot_mesh.surface_set_material(0, spot_mat)
				var spot = MeshInstance3D.new()
				spot.mesh = spot_mesh
				## Distribui as manchas no topo do chapeu
				var angle = rng.randf() * TAU
				var dist = rng.randf_range(0.1, 0.4) * scale_factor
				spot.position = Vector3(
					cos(angle) * dist,
					trunk_mesh.height + 0.2 * scale_factor,
					sin(angle) * dist
				)
				mushroom.add_child(spot)

		add_child(mushroom)

		## A cada 4 cogumelos, um eh interativo (da buff)
		if i % 4 == 0:
			var area = Area3D.new()
			area.name = "BuffArea"
			var col = CollisionShape3D.new()
			var shape = SphereShape3D.new()
			shape.radius = 1.5
			col.shape = shape
			area.add_child(col)
			area.collision_layer = 0
			area.collision_mask = 1  # Detect players
			mushroom.add_child(area)
			mushroom.add_to_group("buff_mushrooms")
			buff_mushrooms.append(mushroom)
			area.body_entered.connect(_on_buff_mushroom_entered.bind(mushroom))
			## Cogumelos de buff brilham mais
			cap.material_override = cap_mat
			cap_mat.emission_energy_multiplier = 2.0

		## Mini cluster de cogumelos na base (3-5 cogumelinhos)
		if rng.randf() < 0.3:
			_spawn_mini_mushroom_cluster(mushroom, Vector3(0, 0, 0), scale_factor * 0.3)

## -------------------------------------------------------
## Clusters de mini cogumelos auxiliar
## -------------------------------------------------------
func _spawn_mini_mushroom_cluster(parent: Node3D, offset: Vector3, cluster_scale: float) -> void:
	var mini_cap_mat = StandardMaterial3D.new()
	var mini_color = cap_colors[rng.randi() % cap_colors.size()]
	mini_cap_mat.albedo_color = mini_color
	mini_cap_mat.roughness = 0.5
	mini_cap_mat.emission_enabled = true
	mini_cap_mat.emission = mini_color * 0.2
	mini_cap_mat.emission_energy_multiplier = 0.3

	var mini_trunk_mat = StandardMaterial3D.new()
	mini_trunk_mat.albedo_color = Color(0.85, 0.82, 0.7)
	mini_trunk_mat.roughness = 0.8

	var num_minis = rng.randi_range(3, 5)
	for m in range(num_minis):
		var mini = Node3D.new()
		var angle = rng.randf() * TAU
		var dist = rng.randf_range(0.3, 0.8)
		mini.position = offset + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

		var ms = rng.randf_range(0.5, 1.0) * cluster_scale

		## Tronquinho
		var mt_mesh = CylinderMesh.new()
		mt_mesh.top_radius = 0.1 * ms
		mt_mesh.bottom_radius = 0.15 * ms
		mt_mesh.height = rng.randf_range(0.15, 0.35) * ms * 3.0
		mt_mesh.surface_set_material(0, mini_trunk_mat)
		var mt = MeshInstance3D.new()
		mt.mesh = mt_mesh
		mt.position.y = mt_mesh.height / 2.0
		mini.add_child(mt)

		## Chapeuzinho
		var mc_mesh = SphereMesh.new()
		mc_mesh.radius = 0.2 * ms
		mc_mesh.height = 0.15 * ms
		mc_mesh.surface_set_material(0, mini_cap_mat)
		var mc = MeshInstance3D.new()
		mc.mesh = mc_mesh
		mc.position.y = mt_mesh.height + 0.03 * ms
		mini.add_child(mc)

		parent.add_child(mini)

## -------------------------------------------------------
## Arvores com raizes expostas, folhas caindo, variacao de copa
## -------------------------------------------------------
func _generate_trees() -> void:
	## Cores variadas para copas — estilo BotW
	var canopy_colors: Array[Color] = [
		Color(0.05, 0.45, 0.1),   ## Verde padrao
		Color(0.15, 0.55, 0.08),  ## Verde amarelado
		Color(0.03, 0.35, 0.08),  ## Verde escuro
		Color(0.08, 0.5, 0.2),    ## Verde esmeralda
		Color(0.2, 0.5, 0.05),    ## Verde oliva
	]

	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.25, 0.18, 0.1)
	trunk_mat.roughness = 0.9

	var root_mat = StandardMaterial3D.new()
	root_mat.albedo_color = Color(0.22, 0.15, 0.08)
	root_mat.roughness = 0.95

	## Contador para gerar particulas de folhas a cada grupo de arvores
	var leaf_cluster_counter := 0

	for i in range(num_trees):
		var tree = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 8 and abs(z) < 8:
			x += 12.0
		tree.position = Vector3(x, 0, z)

		var height = rng.randf_range(4.0, 7.0)

		## Tronco alto
		var trunk_mesh = CylinderMesh.new()
		trunk_mesh.top_radius = 0.15
		trunk_mesh.bottom_radius = 0.35
		trunk_mesh.height = height
		trunk_mesh.surface_set_material(0, trunk_mat)

		var trunk_inst = MeshInstance3D.new()
		trunk_inst.mesh = trunk_mesh
		trunk_inst.position.y = height / 2.0
		tree.add_child(trunk_inst)

		## Raizes expostas na base (cilindros finos espalhados)
		var num_roots = rng.randi_range(3, 6)
		for r in range(num_roots):
			var root_mesh = CylinderMesh.new()
			root_mesh.top_radius = 0.02
			root_mesh.bottom_radius = rng.randf_range(0.06, 0.12)
			root_mesh.height = rng.randf_range(0.6, 1.2)
			root_mesh.surface_set_material(0, root_mat)
			var root_inst = MeshInstance3D.new()
			root_inst.mesh = root_mesh
			## Raiz se espalha quase horizontalmente desde a base
			var root_angle = rng.randf() * TAU
			root_inst.position = Vector3(
				cos(root_angle) * 0.3,
				0.15,
				sin(root_angle) * 0.3
			)
			root_inst.rotation.z = cos(root_angle) * rng.randf_range(0.8, 1.3)
			root_inst.rotation.x = sin(root_angle) * rng.randf_range(0.8, 1.3)
			tree.add_child(root_inst)

		## Copa verde com variacao de cor
		var canopy_mesh = SphereMesh.new()
		var canopy_radius = rng.randf_range(1.5, 3.0)
		canopy_mesh.radius = canopy_radius
		canopy_mesh.height = canopy_radius * 1.6
		var canopy_mat = StandardMaterial3D.new()
		canopy_mat.albedo_color = canopy_colors[rng.randi() % canopy_colors.size()]
		canopy_mat.roughness = 0.7
		canopy_mesh.surface_set_material(0, canopy_mat)

		var canopy = MeshInstance3D.new()
		canopy.mesh = canopy_mesh
		canopy.position.y = height + canopy_radius * 0.3
		tree.add_child(canopy)

		## Segunda camada de copa (mais escura ou mais clara, levemente deslocada)
		if rng.randf() < 0.6:
			var canopy2_mesh = SphereMesh.new()
			var r2 = canopy_radius * rng.randf_range(0.6, 0.9)
			canopy2_mesh.radius = r2
			canopy2_mesh.height = r2 * 1.4
			var canopy2_mat = StandardMaterial3D.new()
			canopy2_mat.albedo_color = canopy_colors[rng.randi() % canopy_colors.size()]
			canopy2_mat.roughness = 0.7
			canopy2_mesh.surface_set_material(0, canopy2_mat)
			var canopy2 = MeshInstance3D.new()
			canopy2.mesh = canopy2_mesh
			canopy2.position = Vector3(
				rng.randf_range(-0.5, 0.5),
				height + canopy_radius * 0.5 + rng.randf_range(-0.3, 0.5),
				rng.randf_range(-0.5, 0.5)
			)
			tree.add_child(canopy2)

		## Mini cogumelos na base da arvore
		if rng.randf() < 0.4:
			_spawn_mini_mushroom_cluster(tree, Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.5, 0.5)), 0.3)

		add_child(tree)

		## Particulas de folhas caindo a cada 5 arvores (performance)
		leaf_cluster_counter += 1
		if leaf_cluster_counter >= 5:
			leaf_cluster_counter = 0
			_spawn_falling_leaves(tree.position, canopy_radius)

## -------------------------------------------------------
## Particulas de folhas caindo de um cluster de arvores
## -------------------------------------------------------
func _spawn_falling_leaves(pos: Vector3, radius: float) -> void:
	var leaves = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0.2, -1, 0.1)
	mat.spread = 40.0
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.5
	mat.gravity = Vector3(0, -0.3, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.6
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(radius * 2, 0.5, radius * 2)

	## Cores outonais misturadas
	mat.color = Color(0.3, 0.6, 0.15, 0.85)

	leaves.process_material = mat
	leaves.amount = 12
	leaves.lifetime = 6.0
	leaves.visibility_aabb = AABB(Vector3(-10, -5, -10), Vector3(20, 15, 20))

	var draw_pass = BoxMesh.new()
	draw_pass.size = Vector3(0.06, 0.01, 0.04)
	var leaf_mat = StandardMaterial3D.new()
	## Verde-amarelado
	leaf_mat.albedo_color = Color(0.35, 0.55, 0.1, 0.9)
	leaf_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	leaf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, leaf_mat)
	leaves.draw_pass_1 = draw_pass

	leaves.position = Vector3(pos.x, 6.0, pos.z)
	add_child(leaves)

## -------------------------------------------------------
## Rio sinuoso com pedras nas margens e particulas de respingo
## -------------------------------------------------------
func _generate_river() -> void:
	var river_x = rng.randf_range(-20, 20)
	var segment_length = 12.0

	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.35, 0.28, 0.2)
	rock_mat.roughness = 0.9

	for i in range(num_river_segments):
		var seg_mesh = BoxMesh.new()
		var seg_width = rng.randf_range(2.5, 4.0)
		seg_mesh.size = Vector3(seg_width, 0.05, segment_length)
		var seg_mat = StandardMaterial3D.new()
		seg_mat.albedo_color = Color(0.1, 0.3, 0.8, 0.7)
		seg_mat.emission_enabled = true
		seg_mat.emission = Color(0.05, 0.2, 0.6)
		seg_mat.emission_energy_multiplier = 1.5
		seg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		seg_mat.roughness = 0.1
		seg_mat.metallic = 0.3
		seg_mesh.surface_set_material(0, seg_mat)

		var seg = MeshInstance3D.new()
		seg.mesh = seg_mesh
		river_x += rng.randf_range(-5, 5)
		river_x = clampf(river_x, -40, 40)
		var z_pos = -area_size + i * segment_length
		seg.position = Vector3(river_x, 0.02, z_pos)
		seg.rotation.y = rng.randf_range(-0.3, 0.3)
		add_child(seg)

		## Pedras nas margens do rio
		var num_rocks = rng.randi_range(3, 6)
		for r in range(num_rocks):
			var rock_mesh: Mesh
			if rng.randf() < 0.5:
				var sm = SphereMesh.new()
				sm.radius = rng.randf_range(0.15, 0.35)
				sm.height = sm.radius * rng.randf_range(1.0, 1.6)
				sm.surface_set_material(0, rock_mat)
				rock_mesh = sm
			else:
				var bm = BoxMesh.new()
				bm.size = Vector3(
					rng.randf_range(0.2, 0.4),
					rng.randf_range(0.1, 0.25),
					rng.randf_range(0.2, 0.4)
				)
				bm.surface_set_material(0, rock_mat)
				rock_mesh = bm

			var rock = MeshInstance3D.new()
			rock.mesh = rock_mesh
			## Coloca na margem (esquerda ou direita)
			var side = -1.0 if rng.randf() < 0.5 else 1.0
			rock.position = Vector3(
				river_x + side * (seg_width / 2.0 + rng.randf_range(0.1, 0.5)),
				rng.randf_range(0.05, 0.15),
				z_pos + rng.randf_range(-segment_length * 0.4, segment_length * 0.4)
			)
			rock.rotation.y = rng.randf() * TAU
			add_child(rock)

	## Particulas de respingo ao longo do rio
	var splash = GPUParticles3D.new()
	var splash_mat = ParticleProcessMaterial.new()
	splash_mat.direction = Vector3(0, 1, 0)
	splash_mat.spread = 60.0
	splash_mat.initial_velocity_min = 0.3
	splash_mat.initial_velocity_max = 0.8
	splash_mat.gravity = Vector3(0, -1.0, 0)
	splash_mat.scale_min = 0.1
	splash_mat.scale_max = 0.25
	splash_mat.color = Color(0.5, 0.7, 1.0, 0.5)
	splash_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	splash_mat.emission_box_extents = Vector3(4, 0.1, area_size * 0.8)

	splash.process_material = splash_mat
	splash.amount = 25
	splash.lifetime = 2.0
	splash.visibility_aabb = AABB(Vector3(-10, -1, -area_size), Vector3(20, 5, area_size * 2))

	var splash_draw = SphereMesh.new()
	splash_draw.radius = 0.04
	splash_draw.height = 0.04
	var splash_draw_mat = StandardMaterial3D.new()
	splash_draw_mat.albedo_color = Color(0.6, 0.8, 1.0, 0.5)
	splash_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	splash_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	splash_draw_mat.emission_enabled = true
	splash_draw_mat.emission = Color(0.3, 0.5, 0.8)
	splash_draw_mat.emission_energy_multiplier = 1.0
	splash_draw.surface_set_material(0, splash_draw_mat)
	splash.draw_pass_1 = splash_draw

	splash.position = Vector3(river_x, 0.1, 0)
	add_child(splash)

## -------------------------------------------------------
## Manchas de flores coloridas espalhadas pelo chao
## -------------------------------------------------------
func _generate_flower_patches() -> void:
	var flower_colors: Array[Color] = [
		Color(1.0, 0.9, 0.2),     ## Amarelo
		Color(1.0, 0.45, 0.6),    ## Rosa
		Color(0.95, 0.95, 0.9),   ## Branco
		Color(0.3, 0.5, 1.0),     ## Azul
		Color(0.6, 0.3, 0.8),     ## Roxo
	]

	var stem_mat = StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.15, 0.4, 0.1)
	stem_mat.roughness = 0.8

	for i in range(num_flower_patches):
		var patch = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 7.0
		patch.position = Vector3(x, 0, z)

		var patch_color = flower_colors[rng.randi() % flower_colors.size()]
		var petal_mat = StandardMaterial3D.new()
		petal_mat.albedo_color = patch_color
		petal_mat.roughness = 0.5
		petal_mat.emission_enabled = true
		petal_mat.emission = patch_color * 0.15
		petal_mat.emission_energy_multiplier = 0.3

		## 5-10 flores por mancha
		var num_flowers = rng.randi_range(5, 10)
		for f in range(num_flowers):
			var flower = Node3D.new()
			var fa = rng.randf() * TAU
			var fd = rng.randf_range(0.2, 1.5)
			flower.position = Vector3(cos(fa) * fd, 0, sin(fa) * fd)

			## Caule fino
			var stem_mesh = CylinderMesh.new()
			stem_mesh.top_radius = 0.01
			stem_mesh.bottom_radius = 0.015
			var stem_h = rng.randf_range(0.15, 0.35)
			stem_mesh.height = stem_h
			stem_mesh.surface_set_material(0, stem_mat)
			var stem = MeshInstance3D.new()
			stem.mesh = stem_mesh
			stem.position.y = stem_h / 2.0
			flower.add_child(stem)

			## Petala (esfera pequena colorida)
			var petal_mesh = SphereMesh.new()
			petal_mesh.radius = rng.randf_range(0.04, 0.08)
			petal_mesh.height = petal_mesh.radius * 1.5
			petal_mesh.surface_set_material(0, petal_mat)
			var petal = MeshInstance3D.new()
			petal.mesh = petal_mesh
			petal.position.y = stem_h + 0.02
			flower.add_child(petal)

			patch.add_child(flower)

		add_child(patch)

## -------------------------------------------------------
## Troncos caidos no chao, alguns com cogumelos crescendo
## -------------------------------------------------------
func _generate_fallen_logs() -> void:
	var log_mat = StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.22, 0.15, 0.08)
	log_mat.roughness = 0.95

	var moss_mat = StandardMaterial3D.new()
	moss_mat.albedo_color = Color(0.12, 0.3, 0.08)
	moss_mat.roughness = 1.0

	for i in range(num_fallen_logs):
		var log_node = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 8 and abs(z) < 8:
			x += 12.0
		log_node.position = Vector3(x, 0, z)
		log_node.rotation.y = rng.randf() * TAU

		## Tronco principal deitado
		var trunk_mesh = CylinderMesh.new()
		trunk_mesh.top_radius = rng.randf_range(0.15, 0.3)
		trunk_mesh.bottom_radius = rng.randf_range(0.2, 0.4)
		var log_length = rng.randf_range(2.0, 5.0)
		trunk_mesh.height = log_length
		trunk_mesh.surface_set_material(0, log_mat)
		var trunk_inst = MeshInstance3D.new()
		trunk_inst.mesh = trunk_mesh
		## Deitado no chao (rotaciona 90 graus)
		trunk_inst.rotation.x = deg_to_rad(90)
		trunk_inst.position.y = trunk_mesh.bottom_radius * 0.8
		log_node.add_child(trunk_inst)

		## Musgo no tronco
		if rng.randf() < 0.6:
			var num_moss = rng.randi_range(2, 4)
			for m in range(num_moss):
				var moss_mesh = BoxMesh.new()
				moss_mesh.size = Vector3(
					rng.randf_range(0.2, 0.5),
					0.03,
					rng.randf_range(0.15, 0.3)
				)
				moss_mesh.surface_set_material(0, moss_mat)
				var moss = MeshInstance3D.new()
				moss.mesh = moss_mesh
				moss.position = Vector3(
					rng.randf_range(-0.2, 0.2),
					trunk_mesh.bottom_radius * 1.3,
					rng.randf_range(-log_length * 0.3, log_length * 0.3)
				)
				log_node.add_child(moss)

		## Cogumelos crescendo no tronco
		if rng.randf() < 0.5:
			_spawn_mini_mushroom_cluster(
				log_node,
				Vector3(0, trunk_mesh.bottom_radius * 0.8, rng.randf_range(-log_length * 0.2, log_length * 0.2)),
				0.25
			)

		add_child(log_node)

## -------------------------------------------------------
## Circulos de fadas — cogumelos em circulo com centro brilhante
## -------------------------------------------------------
func _generate_fairy_circles() -> void:
	var disc_mat = StandardMaterial3D.new()
	disc_mat.albedo_color = Color(0.5, 0.9, 0.4, 0.4)
	disc_mat.emission_enabled = true
	disc_mat.emission = Color(0.3, 0.8, 0.3)
	disc_mat.emission_energy_multiplier = 2.5
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var tiny_cap_mat = StandardMaterial3D.new()
	tiny_cap_mat.albedo_color = Color(0.9, 0.85, 0.7)
	tiny_cap_mat.roughness = 0.6
	tiny_cap_mat.emission_enabled = true
	tiny_cap_mat.emission = Color(0.8, 0.75, 0.5)
	tiny_cap_mat.emission_energy_multiplier = 0.5

	var tiny_trunk_mat = StandardMaterial3D.new()
	tiny_trunk_mat.albedo_color = Color(0.85, 0.8, 0.7)
	tiny_trunk_mat.roughness = 0.8

	for i in range(num_fairy_circles):
		var circle = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		circle.position = Vector3(x, 0, z)

		var circle_radius = rng.randf_range(1.5, 3.0)

		## Disco brilhante no centro
		var disc_mesh = CylinderMesh.new()
		disc_mesh.top_radius = circle_radius * 0.4
		disc_mesh.bottom_radius = circle_radius * 0.4
		disc_mesh.height = 0.02
		disc_mesh.surface_set_material(0, disc_mat)
		var disc = MeshInstance3D.new()
		disc.mesh = disc_mesh
		disc.position.y = 0.02
		circle.add_child(disc)

		## Luz no centro
		var fairy_light = OmniLight3D.new()
		fairy_light.light_color = Color(0.4, 0.9, 0.4)
		fairy_light.light_energy = rng.randf_range(1.0, 2.0)
		fairy_light.omni_range = circle_radius * 2.5
		fairy_light.omni_attenuation = 1.5
		fairy_light.position.y = 0.5
		circle.add_child(fairy_light)

		## Cogumelos pequenos formando o circulo (8-14)
		var num_shrooms = rng.randi_range(8, 14)
		for s in range(num_shrooms):
			var angle = (float(s) / float(num_shrooms)) * TAU
			var sx = cos(angle) * circle_radius
			var sz = sin(angle) * circle_radius

			var shroom = Node3D.new()
			shroom.position = Vector3(sx, 0, sz)

			## Tronquinho minusculo
			var st_mesh = CylinderMesh.new()
			st_mesh.top_radius = 0.03
			st_mesh.bottom_radius = 0.04
			st_mesh.height = rng.randf_range(0.08, 0.18)
			st_mesh.surface_set_material(0, tiny_trunk_mat)
			var st = MeshInstance3D.new()
			st.mesh = st_mesh
			st.position.y = st_mesh.height / 2.0
			shroom.add_child(st)

			## Chapeuzinho
			var sc_mesh = SphereMesh.new()
			sc_mesh.radius = rng.randf_range(0.05, 0.1)
			sc_mesh.height = sc_mesh.radius * 0.8
			sc_mesh.surface_set_material(0, tiny_cap_mat)
			var sc = MeshInstance3D.new()
			sc.mesh = sc_mesh
			sc.position.y = st_mesh.height + 0.01
			shroom.add_child(sc)

			circle.add_child(shroom)

		add_child(circle)

## -------------------------------------------------------
## Borboletas brilhantes — efeito de particulas espalhado
## -------------------------------------------------------
func _generate_butterflies() -> void:
	var butterfly_colors: Array[Color] = [
		Color(0.3, 0.8, 1.0),   ## Azul celeste
		Color(1.0, 0.8, 0.2),   ## Dourado
		Color(0.8, 0.3, 0.9),   ## Roxo
		Color(0.2, 1.0, 0.5),   ## Verde
		Color(1.0, 0.5, 0.7),   ## Rosa
		Color(0.9, 0.9, 0.3),   ## Amarelo
	]

	for i in range(num_butterflies):
		var bx = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var bz = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var color = butterfly_colors[rng.randi() % butterfly_colors.size()]

		var butterflies = GPUParticles3D.new()
		var mat = ParticleProcessMaterial.new()
		mat.direction = Vector3(0.3, 0.5, 0.2)
		mat.spread = 120.0
		mat.initial_velocity_min = 0.3
		mat.initial_velocity_max = 0.8
		mat.gravity = Vector3(0, -0.05, 0)
		mat.scale_min = 0.3
		mat.scale_max = 0.6
		mat.color = Color(color.r, color.g, color.b, 0.9)
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		mat.emission_box_extents = Vector3(5, 2, 5)

		butterflies.process_material = mat
		butterflies.amount = 4
		butterflies.lifetime = 5.0
		butterflies.visibility_aabb = AABB(Vector3(-8, -2, -8), Vector3(16, 8, 16))

		var draw_pass = BoxMesh.new()
		draw_pass.size = Vector3(0.12, 0.01, 0.08)
		var fly_mat = StandardMaterial3D.new()
		fly_mat.albedo_color = color
		fly_mat.emission_enabled = true
		fly_mat.emission = color
		fly_mat.emission_energy_multiplier = 3.0
		fly_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fly_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		draw_pass.surface_set_material(0, fly_mat)
		butterflies.draw_pass_1 = draw_pass

		butterflies.position = Vector3(bx, rng.randf_range(1.0, 3.0), bz)
		add_child(butterflies)

## -------------------------------------------------------
## Particulas brilhantes multicoloridas — duas camadas
## -------------------------------------------------------
func _generate_sparkles() -> void:
	## Camada 1 — sparkles pequenos multicoloridos
	var sparkles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 0.8
	mat.gravity = Vector3(0, -0.05, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.35
	mat.color = Color(0.5, 0.9, 0.4, 0.8)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(50, 0.5, 50)

	sparkles.process_material = mat
	sparkles.amount = 80
	sparkles.lifetime = 5.0
	sparkles.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 15, 120))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.06
	draw_pass.height = 0.06
	var sparkle_mat = StandardMaterial3D.new()
	sparkle_mat.albedo_color = Color(0.6, 1.0, 0.4, 0.9)
	sparkle_mat.emission_enabled = true
	sparkle_mat.emission = Color(0.4, 0.9, 0.3)
	sparkle_mat.emission_energy_multiplier = 3.0
	sparkle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sparkle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, sparkle_mat)
	sparkles.draw_pass_1 = draw_pass

	sparkles.position = Vector3(0, 1.0, 0)
	add_child(sparkles)

	## Camada 2 — orbes dourados maiores flutuando suavemente
	var orbs = GPUParticles3D.new()
	var orb_mat = ParticleProcessMaterial.new()
	orb_mat.direction = Vector3(0.1, 0.5, 0.1)
	orb_mat.spread = 60.0
	orb_mat.initial_velocity_min = 0.1
	orb_mat.initial_velocity_max = 0.3
	orb_mat.gravity = Vector3(0, 0, 0)
	orb_mat.scale_min = 0.5
	orb_mat.scale_max = 1.0
	orb_mat.color = Color(1.0, 0.85, 0.3, 0.5)
	orb_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	orb_mat.emission_box_extents = Vector3(40, 1, 40)

	orbs.process_material = orb_mat
	orbs.amount = 20
	orbs.lifetime = 8.0
	orbs.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 15, 120))

	var orb_draw = SphereMesh.new()
	orb_draw.radius = 0.12
	orb_draw.height = 0.12
	var orb_draw_mat = StandardMaterial3D.new()
	orb_draw_mat.albedo_color = Color(1.0, 0.9, 0.4, 0.4)
	orb_draw_mat.emission_enabled = true
	orb_draw_mat.emission = Color(0.9, 0.75, 0.2)
	orb_draw_mat.emission_energy_multiplier = 2.5
	orb_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	orb_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	orb_draw.surface_set_material(0, orb_draw_mat)
	orbs.draw_pass_1 = orb_draw

	orbs.position = Vector3(0, 2.0, 0)
	add_child(orbs)

	## Camada 3 — sparkles azuis
	var blue_sparkles = GPUParticles3D.new()
	var blue_mat = ParticleProcessMaterial.new()
	blue_mat.direction = Vector3(0, 1, 0)
	blue_mat.spread = 45.0
	blue_mat.initial_velocity_min = 0.2
	blue_mat.initial_velocity_max = 0.6
	blue_mat.gravity = Vector3(0, -0.02, 0)
	blue_mat.scale_min = 0.15
	blue_mat.scale_max = 0.3
	blue_mat.color = Color(0.3, 0.6, 1.0, 0.7)
	blue_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	blue_mat.emission_box_extents = Vector3(45, 0.5, 45)

	blue_sparkles.process_material = blue_mat
	blue_sparkles.amount = 40
	blue_sparkles.lifetime = 6.0
	blue_sparkles.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 15, 120))

	var blue_draw = SphereMesh.new()
	blue_draw.radius = 0.05
	blue_draw.height = 0.05
	var blue_draw_mat = StandardMaterial3D.new()
	blue_draw_mat.albedo_color = Color(0.3, 0.6, 1.0, 0.8)
	blue_draw_mat.emission_enabled = true
	blue_draw_mat.emission = Color(0.2, 0.5, 0.9)
	blue_draw_mat.emission_energy_multiplier = 2.5
	blue_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blue_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blue_draw.surface_set_material(0, blue_draw_mat)
	blue_sparkles.draw_pass_1 = blue_draw

	blue_sparkles.position = Vector3(0, 1.5, 0)
	add_child(blue_sparkles)

## -------------------------------------------------------
## Sistema de buff dos cogumelos interativos (preservado intacto)
## -------------------------------------------------------
func _on_buff_mushroom_entered(body: Node3D, mushroom: Node3D) -> void:
	if not body.is_in_group("players"):
		return
	if not is_instance_valid(mushroom) or not mushroom.is_inside_tree():
		return

	# Pick random buff
	var buff = rng.randi() % 3
	match buff:
		0:  # Speed boost +30% for 10s
			GameManager.speed_mult += 0.3
			get_tree().create_timer(10.0).timeout.connect(func():
				GameManager.speed_mult -= 0.3
			)
		1:  # Damage boost +20% for 10s
			GameManager.perm_damage_mult += 0.2
			get_tree().create_timer(10.0).timeout.connect(func():
				GameManager.perm_damage_mult -= 0.2
			)
		2:  # Heal 20 HP
			GameManager.heal(20)

	AudioManager.play_sfx("collect_xp")
	# Shrink and disappear
	var tween = create_tween()
	tween.tween_property(mushroom, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(mushroom.queue_free)

## -------------------------------------------------------
## Luzes ambiente com tons magicos — mais luzes, cores variadas
## -------------------------------------------------------
func _generate_ambient_lights() -> void:
	var light_colors: Array[Color] = [
		Color(0.2, 0.8, 0.3),     ## Verde floresta
		Color(0.3, 0.3, 0.9),     ## Azul
		Color(0.6, 0.2, 0.8),     ## Roxo
		Color(0.8, 0.7, 0.2),     ## Dourado
		Color(0.1, 0.7, 0.5),     ## Ciano
		Color(0.4, 0.9, 0.4),     ## Verde claro
	]

	for i in range(15):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		light.position = Vector3(x, rng.randf_range(1.5, 3.5), z)
		light.light_color = light_colors[rng.randi() % light_colors.size()]
		light.light_energy = rng.randf_range(0.4, 1.2)
		light.omni_range = rng.randf_range(8.0, 18.0)
		light.omni_attenuation = rng.randf_range(1.5, 2.5)
		add_child(light)
