extends Node3D

## Gera props procedurais para Vulcao Infernal estilo BotW: rios de lava com pulso animado,
## rochas flutuantes com bob, cristais vulcanicos, pilhas de cinza, geisers dramaticos,
## bolhas de lava, arvores carbonizadas, brasas melhoradas, iluminacao atmosferica.
## Lava causa 5 dano/seg.

@export var num_lava_rivers: int = 8
@export var num_floating_rocks: int = 25
@export var num_geysers: int = 10
@export var num_pillars: int = 30
@export var num_crystals: int = 15
@export var num_ash_piles: int = 12
@export var num_charred_trees: int = 8
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var lava_zones: Array[Area3D] = []
var lava_damage_timer: float = 0.0

## Materiais de lava para animar pulso de emissao
var lava_materials: Array[StandardMaterial3D] = []

## Referencia dos billboards (flickering) - nao usado aqui mas mantido para consistencia
var billboard_panels: Array[MeshInstance3D] = []

func _ready() -> void:
	rng.randomize()
	_generate_lava_rivers()
	_generate_floating_rocks()
	_generate_geysers()
	_generate_obsidian_pillars()
	_generate_volcanic_crystals()
	_generate_ash_piles()
	_generate_charred_trees()
	_generate_lava_bubbles()
	_generate_ember_particles()
	_generate_ambient_lights()

func _process(delta: float) -> void:
	## Lava causa 5 de dano por segundo
	lava_damage_timer += delta
	if lava_damage_timer >= 1.0:
		lava_damage_timer = 0.0
		for lava_area in lava_zones:
			if not is_instance_valid(lava_area):
				continue
			var bodies = lava_area.get_overlapping_bodies()
			for body in bodies:
				if body.is_in_group("players") and body.has_method("take_damage"):
					body.take_damage(5)
				elif body.is_in_group("enemies") and body.has_method("take_damage"):
					body.take_damage(5)

## ===================== RIOS DE LAVA =====================

func _generate_lava_rivers() -> void:
	for i in range(num_lava_rivers):
		var river = Node3D.new()
		var start_x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var start_z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		river.position = Vector3(start_x, 0, start_z)

		var num_segments = rng.randi_range(4, 8)
		var seg_x = 0.0
		var seg_z = 0.0

		for s in range(num_segments):
			var seg_width = rng.randf_range(2.0, 4.0)
			var seg_length = rng.randf_range(5.0, 10.0)

			## Visual da lava
			var lava_mesh = BoxMesh.new()
			lava_mesh.size = Vector3(seg_width, 0.06, seg_length)
			var lava_mat = StandardMaterial3D.new()
			lava_mat.albedo_color = Color(1.0, 0.3, 0.0, 0.9)
			lava_mat.emission_enabled = true
			lava_mat.emission = Color(1.0, 0.2, 0.0)
			lava_mat.emission_energy_multiplier = 4.0
			lava_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			lava_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			lava_mesh.surface_set_material(0, lava_mat)
			lava_materials.append(lava_mat)

			var lava_vis = MeshInstance3D.new()
			lava_vis.mesh = lava_mesh
			lava_vis.position = Vector3(seg_x, 0.02, seg_z)
			lava_vis.rotation.y = rng.randf_range(-0.4, 0.4)
			river.add_child(lava_vis)

			## Crosta fina nas bordas da lava (lados esquerdo e direito)
			for side in [-1.0, 1.0]:
				var crust_mesh = BoxMesh.new()
				crust_mesh.size = Vector3(0.3, 0.08, seg_length + 0.2)
				var crust_mat = StandardMaterial3D.new()
				crust_mat.albedo_color = Color(0.12, 0.06, 0.02)
				crust_mat.roughness = 1.0
				crust_mat.emission_enabled = true
				crust_mat.emission = Color(0.3, 0.08, 0.0)
				crust_mat.emission_energy_multiplier = 0.5
				crust_mesh.surface_set_material(0, crust_mat)

				var crust_inst = MeshInstance3D.new()
				crust_inst.mesh = crust_mesh
				crust_inst.position = Vector3(seg_x + side * (seg_width / 2.0 + 0.1), 0.04, seg_z)
				crust_inst.rotation.y = lava_vis.rotation.y
				river.add_child(crust_inst)

			## Area3D de dano (identico ao original)
			var area = Area3D.new()
			area.collision_layer = 0
			area.collision_mask = 3
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = Vector3(seg_width, 1.0, seg_length)
			col.shape = shape
			col.position.y = 0.5
			area.add_child(col)
			area.position = lava_vis.position
			area.rotation = lava_vis.rotation
			river.add_child(area)
			lava_zones.append(area)

			seg_x += rng.randf_range(-3, 3)
			seg_z += seg_length * 0.8

		add_child(river)

	## Animar pulso de emissao em todos os materiais de lava
	_start_lava_pulse()

func _start_lava_pulse() -> void:
	## Tween infinito para pulsar energia de emissao da lava entre 3.0 e 5.0
	for mat in lava_materials:
		var tween = create_tween()
		tween.set_loops()
		var offset = rng.randf_range(0.0, 1.0)
		mat.emission_energy_multiplier = lerpf(3.0, 5.0, offset)
		tween.tween_property(mat, "emission_energy_multiplier", 5.0, rng.randf_range(1.5, 2.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(mat, "emission_energy_multiplier", 3.0, rng.randf_range(1.5, 2.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## ===================== ROCHAS FLUTUANTES =====================

func _generate_floating_rocks() -> void:
	for i in range(num_floating_rocks):
		var rock = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		var float_height = rng.randf_range(1.5, 5.0)
		rock.position = Vector3(x, float_height, z)

		## Mais variacao de tamanho
		var rock_mesh = BoxMesh.new()
		var rock_size = rng.randf_range(0.5, 3.5)
		rock_mesh.size = Vector3(rock_size, rock_size * rng.randf_range(0.4, 0.7), rock_size * rng.randf_range(0.6, 1.0))
		var rock_mat = StandardMaterial3D.new()
		rock_mat.albedo_color = Color(rng.randf_range(0.15, 0.25), rng.randf_range(0.1, 0.18), rng.randf_range(0.08, 0.14))
		rock_mat.roughness = 0.9
		rock_mesh.surface_set_material(0, rock_mat)

		var rock_inst = MeshInstance3D.new()
		rock_inst.mesh = rock_mesh
		rock_inst.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0, TAU), rng.randf_range(-0.3, 0.3))
		rock.add_child(rock_inst)

		## Rachaduras brilhantes em algumas rochas (linhas emissivas laranja)
		if rng.randf() < 0.4:
			var num_cracks = rng.randi_range(1, 3)
			for c in range(num_cracks):
				var crack_mesh = BoxMesh.new()
				crack_mesh.size = Vector3(rock_size * rng.randf_range(0.6, 0.9), 0.03, 0.04)
				var crack_mat = StandardMaterial3D.new()
				crack_mat.albedo_color = Color(1.0, 0.5, 0.0, 0.9)
				crack_mat.emission_enabled = true
				crack_mat.emission = Color(1.0, 0.35, 0.0)
				crack_mat.emission_energy_multiplier = 4.0
				crack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				crack_mesh.surface_set_material(0, crack_mat)

				var crack_inst = MeshInstance3D.new()
				crack_inst.mesh = crack_mesh
				crack_inst.position = Vector3(
					rng.randf_range(-rock_size * 0.2, rock_size * 0.2),
					rng.randf_range(-rock_size * 0.15, rock_size * 0.15),
					rock_size * 0.5 * (1.0 if c % 2 == 0 else -1.0)
				)
				crack_inst.rotation.z = rng.randf_range(-0.3, 0.3)
				rock_inst.add_child(crack_inst)

		## Brilho embaixo da rocha (calor)
		var glow_mesh = SphereMesh.new()
		glow_mesh.radius = rock_size * 0.4
		glow_mesh.height = rock_size * 0.3
		var glow_mat = StandardMaterial3D.new()
		glow_mat.albedo_color = Color(1.0, 0.4, 0.0, 0.4)
		glow_mat.emission_enabled = true
		glow_mat.emission = Color(1.0, 0.3, 0.0)
		glow_mat.emission_energy_multiplier = 2.0
		glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow_mesh.surface_set_material(0, glow_mat)

		var glow_inst = MeshInstance3D.new()
		glow_inst.mesh = glow_mesh
		glow_inst.position.y = -rock_size * 0.3
		rock.add_child(glow_inst)

		add_child(rock)

		## Animacao de bob (subir/descer lentamente)
		var bob_tween = create_tween()
		bob_tween.set_loops()
		var bob_amount = rng.randf_range(0.3, 0.8)
		var bob_speed = rng.randf_range(2.0, 4.0)
		bob_tween.tween_property(rock, "position:y", float_height + bob_amount, bob_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob_tween.tween_property(rock, "position:y", float_height - bob_amount, bob_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## ===================== GEISERS =====================

func _generate_geysers() -> void:
	for i in range(num_geysers):
		var geyser = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		geyser.position = Vector3(x, 0, z)

		## Buraco no chao (anel escuro ao redor)
		var hole_mesh = CylinderMesh.new()
		hole_mesh.top_radius = 0.8
		hole_mesh.bottom_radius = 1.0
		hole_mesh.height = 0.3
		var hole_mat = StandardMaterial3D.new()
		hole_mat.albedo_color = Color(0.15, 0.1, 0.08)
		hole_mat.roughness = 1.0
		hole_mesh.surface_set_material(0, hole_mat)

		var hole_inst = MeshInstance3D.new()
		hole_inst.mesh = hole_mesh
		hole_inst.position.y = 0.15
		geyser.add_child(hole_inst)

		## Anel externo do geyser (borda)
		var ring_mesh = CylinderMesh.new()
		ring_mesh.top_radius = 1.3
		ring_mesh.bottom_radius = 1.5
		ring_mesh.height = 0.15
		var ring_mat = StandardMaterial3D.new()
		ring_mat.albedo_color = Color(0.2, 0.12, 0.06)
		ring_mat.roughness = 0.95
		ring_mesh.surface_set_material(0, ring_mat)

		var ring_inst = MeshInstance3D.new()
		ring_inst.mesh = ring_mesh
		ring_inst.position.y = 0.08
		geyser.add_child(ring_inst)

		## Particulas de aviso (rumble antes da erupcao) - pequenas e lentas
		var warning = GPUParticles3D.new()
		var warn_mat = ParticleProcessMaterial.new()
		warn_mat.direction = Vector3(0, 1, 0)
		warn_mat.spread = 30.0
		warn_mat.initial_velocity_min = 0.5
		warn_mat.initial_velocity_max = 1.5
		warn_mat.gravity = Vector3(0, -0.5, 0)
		warn_mat.scale_min = 0.08
		warn_mat.scale_max = 0.2
		warn_mat.color = Color(0.8, 0.3, 0.0, 0.4)
		warn_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		warn_mat.emission_sphere_radius = 0.6

		warning.process_material = warn_mat
		warning.amount = 10
		warning.lifetime = 1.5
		warning.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))

		var warn_draw = SphereMesh.new()
		warn_draw.radius = 0.08
		warn_draw.height = 0.08
		var warn_draw_mat = StandardMaterial3D.new()
		warn_draw_mat.albedo_color = Color(1.0, 0.4, 0.1, 0.3)
		warn_draw_mat.emission_enabled = true
		warn_draw_mat.emission = Color(1.0, 0.3, 0.0)
		warn_draw_mat.emission_energy_multiplier = 2.0
		warn_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		warn_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		warn_draw.surface_set_material(0, warn_draw_mat)
		warning.draw_pass_1 = warn_draw

		warning.position.y = 0.2
		geyser.add_child(warning)

		## Particulas de erupcao principal (mais dramaticas)
		var steam = GPUParticles3D.new()
		var steam_mat = ParticleProcessMaterial.new()
		steam_mat.direction = Vector3(0, 1, 0)
		steam_mat.spread = 12.0
		steam_mat.initial_velocity_min = 7.0
		steam_mat.initial_velocity_max = 14.0
		steam_mat.gravity = Vector3(0, -1.5, 0)
		steam_mat.scale_min = 0.3
		steam_mat.scale_max = 0.8
		steam_mat.color = Color(1.0, 0.5, 0.1, 0.6)
		steam_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		steam_mat.emission_sphere_radius = 0.5

		steam.process_material = steam_mat
		steam.amount = 40
		steam.lifetime = 2.5
		steam.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 20, 6))

		var steam_draw = SphereMesh.new()
		steam_draw.radius = 0.2
		steam_draw.height = 0.2
		var steam_draw_mat = StandardMaterial3D.new()
		steam_draw_mat.albedo_color = Color(1.0, 0.6, 0.2, 0.5)
		steam_draw_mat.emission_enabled = true
		steam_draw_mat.emission = Color(1.0, 0.4, 0.0)
		steam_draw_mat.emission_energy_multiplier = 3.5
		steam_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		steam_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		steam_draw.surface_set_material(0, steam_draw_mat)
		steam.draw_pass_1 = steam_draw

		steam.position.y = 0.3
		geyser.add_child(steam)

		add_child(geyser)

## ===================== PILARES DE OBSIDIANA =====================

func _generate_obsidian_pillars() -> void:
	for i in range(num_pillars):
		var pillar = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		pillar.position = Vector3(x, 0, z)

		var height = rng.randf_range(2.0, 6.0)
		var pillar_mesh = BoxMesh.new()
		pillar_mesh.size = Vector3(rng.randf_range(0.4, 1.0), height, rng.randf_range(0.4, 1.0))
		var pillar_mat = StandardMaterial3D.new()
		pillar_mat.albedo_color = Color(0.05, 0.05, 0.08)
		pillar_mat.roughness = 0.2
		pillar_mat.metallic = 0.4
		pillar_mesh.surface_set_material(0, pillar_mat)

		var pillar_inst = MeshInstance3D.new()
		pillar_inst.mesh = pillar_mesh
		pillar_inst.position.y = height / 2.0
		pillar_inst.rotation = Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(0, TAU), rng.randf_range(-0.15, 0.15))
		pillar.add_child(pillar_inst)

		add_child(pillar)

## ===================== CRISTAIS VULCANICOS =====================

func _generate_volcanic_crystals() -> void:
	for i in range(num_crystals):
		var formation = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		formation.position = Vector3(x, 0, z)

		## Cluster de 2-4 cristais por formacao
		var num_in_cluster = rng.randi_range(2, 4)
		for c in range(num_in_cluster):
			var crystal_height = rng.randf_range(1.2, 3.5)
			var crystal_mesh = CylinderMesh.new()
			crystal_mesh.top_radius = 0.0
			crystal_mesh.bottom_radius = rng.randf_range(0.15, 0.35)
			crystal_mesh.height = crystal_height

			## Cor vermelha/laranja brilhante
			var crystal_mat = StandardMaterial3D.new()
			var red_shift = rng.randf_range(0.7, 1.0)
			var green_shift = rng.randf_range(0.1, 0.35)
			crystal_mat.albedo_color = Color(red_shift, green_shift, 0.0, 0.85)
			crystal_mat.emission_enabled = true
			crystal_mat.emission = Color(red_shift, green_shift * 0.8, 0.0)
			crystal_mat.emission_energy_multiplier = 3.5
			crystal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			crystal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			crystal_mesh.surface_set_material(0, crystal_mat)

			var crystal_inst = MeshInstance3D.new()
			crystal_inst.mesh = crystal_mesh
			crystal_inst.position = Vector3(
				rng.randf_range(-0.6, 0.6),
				crystal_height / 2.0,
				rng.randf_range(-0.6, 0.6)
			)
			## Leve inclinacao para parecer natural
			crystal_inst.rotation = Vector3(
				rng.randf_range(-0.25, 0.25),
				rng.randf_range(0, TAU),
				rng.randf_range(-0.25, 0.25)
			)
			formation.add_child(crystal_inst)

		## Brilho na base da formacao
		var base_glow_mesh = SphereMesh.new()
		base_glow_mesh.radius = 0.6
		base_glow_mesh.height = 0.3
		var base_glow_mat = StandardMaterial3D.new()
		base_glow_mat.albedo_color = Color(1.0, 0.3, 0.0, 0.3)
		base_glow_mat.emission_enabled = true
		base_glow_mat.emission = Color(1.0, 0.25, 0.0)
		base_glow_mat.emission_energy_multiplier = 2.0
		base_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		base_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		base_glow_mesh.surface_set_material(0, base_glow_mat)

		var base_glow_inst = MeshInstance3D.new()
		base_glow_inst.mesh = base_glow_mesh
		base_glow_inst.position.y = 0.1
		formation.add_child(base_glow_inst)

		add_child(formation)

## ===================== PILHAS DE CINZA =====================

func _generate_ash_piles() -> void:
	for i in range(num_ash_piles):
		var pile = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		pile.position = Vector3(x, 0, z)

		## Pilha de cinza (esfera achatada escura)
		var pile_mesh = SphereMesh.new()
		var pile_radius = rng.randf_range(0.8, 2.0)
		pile_mesh.radius = pile_radius
		pile_mesh.height = pile_radius * 0.3
		var pile_mat = StandardMaterial3D.new()
		pile_mat.albedo_color = Color(0.08, 0.07, 0.06)
		pile_mat.roughness = 1.0
		pile_mesh.surface_set_material(0, pile_mat)

		var pile_inst = MeshInstance3D.new()
		pile_inst.mesh = pile_mesh
		pile_inst.position.y = pile_radius * 0.1
		pile.add_child(pile_inst)

		## Particulas de fumaca subindo de algumas pilhas
		if rng.randf() < 0.6:
			var smoke = GPUParticles3D.new()
			var smoke_mat = ParticleProcessMaterial.new()
			smoke_mat.direction = Vector3(0, 1, 0)
			smoke_mat.spread = 20.0
			smoke_mat.initial_velocity_min = 0.3
			smoke_mat.initial_velocity_max = 0.8
			smoke_mat.gravity = Vector3(rng.randf_range(-0.2, 0.2), 0.1, rng.randf_range(-0.2, 0.2))
			smoke_mat.scale_min = 0.15
			smoke_mat.scale_max = 0.5
			smoke_mat.color = Color(0.3, 0.28, 0.25, 0.25)
			smoke_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			smoke_mat.emission_sphere_radius = pile_radius * 0.5

			smoke.process_material = smoke_mat
			smoke.amount = 8
			smoke.lifetime = 3.0
			smoke.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 8, 6))

			var smoke_draw = SphereMesh.new()
			smoke_draw.radius = 0.15
			smoke_draw.height = 0.15
			var smoke_draw_mat = StandardMaterial3D.new()
			smoke_draw_mat.albedo_color = Color(0.35, 0.3, 0.28, 0.2)
			smoke_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			smoke_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			smoke_draw.surface_set_material(0, smoke_draw_mat)
			smoke.draw_pass_1 = smoke_draw

			smoke.position.y = pile_radius * 0.15
			pile.add_child(smoke)

		add_child(pile)

## ===================== ARVORES CARBONIZADAS =====================

func _generate_charred_trees() -> void:
	for i in range(num_charred_trees):
		var tree = Node3D.new()
		var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		tree.position = Vector3(x, 0, z)

		## Tronco principal (cilindro escuro)
		var trunk_height = rng.randf_range(2.0, 4.5)
		var trunk_radius = rng.randf_range(0.2, 0.45)
		var trunk_mesh = CylinderMesh.new()
		trunk_mesh.top_radius = trunk_radius * 0.6
		trunk_mesh.bottom_radius = trunk_radius
		trunk_mesh.height = trunk_height
		var trunk_mat = StandardMaterial3D.new()
		trunk_mat.albedo_color = Color(0.06, 0.05, 0.04)
		trunk_mat.roughness = 1.0
		trunk_mesh.surface_set_material(0, trunk_mat)

		var trunk_inst = MeshInstance3D.new()
		trunk_inst.mesh = trunk_mesh
		trunk_inst.position.y = trunk_height / 2.0
		trunk_inst.rotation = Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(0, TAU), rng.randf_range(-0.1, 0.1))
		tree.add_child(trunk_inst)

		## Topo quebrado (ponta irregular)
		var top_mesh = CylinderMesh.new()
		top_mesh.top_radius = 0.0
		top_mesh.bottom_radius = trunk_radius * 0.5
		top_mesh.height = rng.randf_range(0.3, 0.8)
		var top_mat = StandardMaterial3D.new()
		top_mat.albedo_color = Color(0.08, 0.06, 0.04)
		top_mat.roughness = 1.0
		top_mesh.surface_set_material(0, top_mat)

		var top_inst = MeshInstance3D.new()
		top_inst.mesh = top_mesh
		top_inst.position.y = trunk_height + 0.2
		top_inst.rotation.x = rng.randf_range(-0.4, 0.4)
		top_inst.rotation.z = rng.randf_range(-0.4, 0.4)
		tree.add_child(top_inst)

		## Galhos quebrados (1-2 cilindros pequenos saindo do tronco)
		var num_branches = rng.randi_range(1, 2)
		for b in range(num_branches):
			var branch_mesh = CylinderMesh.new()
			branch_mesh.top_radius = 0.0
			branch_mesh.bottom_radius = rng.randf_range(0.06, 0.12)
			branch_mesh.height = rng.randf_range(0.5, 1.2)
			var branch_mat = StandardMaterial3D.new()
			branch_mat.albedo_color = Color(0.07, 0.05, 0.04)
			branch_mat.roughness = 1.0
			branch_mesh.surface_set_material(0, branch_mat)

			var branch_inst = MeshInstance3D.new()
			branch_inst.mesh = branch_mesh
			branch_inst.position.y = rng.randf_range(trunk_height * 0.4, trunk_height * 0.8)
			branch_inst.rotation.z = rng.randf_range(0.8, 1.4) * (1.0 if b % 2 == 0 else -1.0)
			branch_inst.rotation.y = rng.randf_range(0, TAU)
			tree.add_child(branch_inst)

		## Brasas pequenas em arvores que ainda fumegam
		if rng.randf() < 0.5:
			var embers = GPUParticles3D.new()
			var ember_mat = ParticleProcessMaterial.new()
			ember_mat.direction = Vector3(0, 1, 0)
			ember_mat.spread = 30.0
			ember_mat.initial_velocity_min = 0.2
			ember_mat.initial_velocity_max = 0.6
			ember_mat.gravity = Vector3(rng.randf_range(-0.1, 0.1), 0.05, rng.randf_range(-0.1, 0.1))
			ember_mat.scale_min = 0.03
			ember_mat.scale_max = 0.08
			ember_mat.color = Color(1.0, 0.4, 0.0, 0.7)
			ember_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			ember_mat.emission_sphere_radius = trunk_radius

			embers.process_material = ember_mat
			embers.amount = 6
			embers.lifetime = 2.5
			embers.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 6, 4))

			var ember_draw = SphereMesh.new()
			ember_draw.radius = 0.04
			ember_draw.height = 0.04
			var ember_draw_mat = StandardMaterial3D.new()
			ember_draw_mat.albedo_color = Color(1.0, 0.5, 0.1, 0.8)
			ember_draw_mat.emission_enabled = true
			ember_draw_mat.emission = Color(1.0, 0.3, 0.0)
			ember_draw_mat.emission_energy_multiplier = 3.0
			ember_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ember_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ember_draw.surface_set_material(0, ember_draw_mat)
			embers.draw_pass_1 = ember_draw

			embers.position.y = trunk_height * 0.7
			tree.add_child(embers)

		add_child(tree)

## ===================== BOLHAS DE LAVA =====================

func _generate_lava_bubbles() -> void:
	## Particulas de bolhas perto da superficie da lava (globais, espalhadas na area)
	var bubbles = GPUParticles3D.new()
	var bub_mat = ParticleProcessMaterial.new()
	bub_mat.direction = Vector3(0, 1, 0)
	bub_mat.spread = 10.0
	bub_mat.initial_velocity_min = 0.5
	bub_mat.initial_velocity_max = 1.5
	bub_mat.gravity = Vector3(0, -0.5, 0)
	bub_mat.scale_min = 0.1
	bub_mat.scale_max = 0.35
	bub_mat.color = Color(1.0, 0.4, 0.05, 0.7)
	bub_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	bub_mat.emission_box_extents = Vector3(area_size * 0.5, 0.1, area_size * 0.5)

	bubbles.process_material = bub_mat
	bubbles.amount = 25
	bubbles.lifetime = 1.2
	bubbles.visibility_aabb = AABB(Vector3(-50, -1, -50), Vector3(100, 5, 100))

	var bub_draw = SphereMesh.new()
	bub_draw.radius = 0.12
	bub_draw.height = 0.12
	var bub_draw_mat = StandardMaterial3D.new()
	bub_draw_mat.albedo_color = Color(1.0, 0.35, 0.0, 0.6)
	bub_draw_mat.emission_enabled = true
	bub_draw_mat.emission = Color(1.0, 0.25, 0.0)
	bub_draw_mat.emission_energy_multiplier = 4.0
	bub_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bub_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bub_draw.surface_set_material(0, bub_draw_mat)
	bubbles.draw_pass_1 = bub_draw

	bubbles.position = Vector3(0, 0.05, 0)
	add_child(bubbles)

## ===================== BRASAS MELHORADAS =====================

func _generate_ember_particles() -> void:
	## Camada principal de brasas (mais quantidade, variacao de tamanho)
	var embers = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 2.5
	mat.gravity = Vector3(rng.randf_range(-0.3, 0.3), 0.15, rng.randf_range(-0.3, 0.3))
	mat.scale_min = 0.03
	mat.scale_max = 0.18
	mat.color = Color(1.0, 0.4, 0.0, 0.8)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(55, 0.5, 55)

	embers.process_material = mat
	embers.amount = 80
	embers.lifetime = 4.5
	embers.visibility_aabb = AABB(Vector3(-65, -1, -65), Vector3(130, 18, 130))

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.06
	draw_pass.height = 0.06
	var ember_mat = StandardMaterial3D.new()
	ember_mat.albedo_color = Color(1.0, 0.5, 0.1, 0.9)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.3, 0.0)
	ember_mat.emission_energy_multiplier = 4.0
	ember_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ember_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, ember_mat)
	embers.draw_pass_1 = draw_pass

	embers.position = Vector3(0, 0.5, 0)
	add_child(embers)

	## Segunda camada de brasas com cor amarela/laranja e drift horizontal
	var embers2 = GPUParticles3D.new()
	var mat2 = ParticleProcessMaterial.new()
	mat2.direction = Vector3(0.3, 1, 0.2)
	mat2.spread = 50.0
	mat2.initial_velocity_min = 0.8
	mat2.initial_velocity_max = 2.0
	mat2.gravity = Vector3(0.4, 0.1, 0.2)
	mat2.scale_min = 0.04
	mat2.scale_max = 0.12
	mat2.color = Color(1.0, 0.7, 0.1, 0.7)
	mat2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat2.emission_box_extents = Vector3(50, 0.5, 50)

	embers2.process_material = mat2
	embers2.amount = 40
	embers2.lifetime = 5.0
	embers2.visibility_aabb = AABB(Vector3(-65, -1, -65), Vector3(130, 18, 130))

	var draw_pass2 = SphereMesh.new()
	draw_pass2.radius = 0.05
	draw_pass2.height = 0.05
	var ember_mat2 = StandardMaterial3D.new()
	ember_mat2.albedo_color = Color(1.0, 0.7, 0.2, 0.85)
	ember_mat2.emission_enabled = true
	ember_mat2.emission = Color(1.0, 0.6, 0.1)
	ember_mat2.emission_energy_multiplier = 3.5
	ember_mat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ember_mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass2.surface_set_material(0, ember_mat2)
	embers2.draw_pass_1 = draw_pass2

	embers2.position = Vector3(0, 1.0, 0)
	add_child(embers2)

## ===================== ILUMINACAO ATMOSFERICA =====================

func _generate_ambient_lights() -> void:
	var light_colors: Array[Color] = [
		Color(1.0, 0.3, 0.0),   ## Laranja quente
		Color(1.0, 0.5, 0.1),   ## Laranja claro
		Color(0.8, 0.2, 0.0),   ## Vermelho escuro
		Color(1.0, 0.15, 0.0),  ## Vermelho fogo
		Color(1.0, 0.6, 0.0),   ## Amarelo quente
		Color(0.9, 0.1, 0.05),  ## Vermelho intenso
	]

	for i in range(16):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)

		## Algumas luzes perto do chao para uplighting dramatico, outras mais altas
		var y_pos: float
		if i < 6:
			y_pos = rng.randf_range(0.3, 1.0)  ## Perto da lava
		else:
			y_pos = rng.randf_range(1.5, 4.0)

		light.position = Vector3(x, y_pos, z)
		light.light_color = light_colors[rng.randi() % light_colors.size()]
		light.light_energy = rng.randf_range(0.4, 0.9)
		light.omni_range = rng.randf_range(10.0, 16.0)
		light.omni_attenuation = 2.0
		add_child(light)
