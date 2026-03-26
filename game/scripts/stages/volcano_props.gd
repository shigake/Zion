extends Node3D

## Gera props procedurais para Vulcao Infernal: rios de lava, rochas flutuantes,
## geisers, pilares de obsidiana. Lava causa 5 dano/seg.

@export var num_lava_rivers: int = 8
@export var num_floating_rocks: int = 25
@export var num_geysers: int = 10
@export var num_pillars: int = 30
@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var lava_zones: Array[Area3D] = []
var lava_damage_timer: float = 0.0

func _ready() -> void:
	rng.randomize()
	_generate_lava_rivers()
	_generate_floating_rocks()
	_generate_geysers()
	_generate_obsidian_pillars()
	_generate_ember_particles()
	_generate_ambient_lights()

func _process(delta: float) -> void:
	# Lava deals 5 damage per second
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

			# Visual da lava
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

			var lava_vis = MeshInstance3D.new()
			lava_vis.mesh = lava_mesh
			lava_vis.position = Vector3(seg_x, 0.02, seg_z)
			lava_vis.rotation.y = rng.randf_range(-0.4, 0.4)
			river.add_child(lava_vis)

			# Area3D de dano
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

func _generate_floating_rocks() -> void:
	for i in range(num_floating_rocks):
		var rock = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		var float_height = rng.randf_range(1.5, 5.0)
		rock.position = Vector3(x, float_height, z)

		var rock_mesh = BoxMesh.new()
		var rock_size = rng.randf_range(0.8, 2.5)
		rock_mesh.size = Vector3(rock_size, rock_size * 0.6, rock_size * 0.8)
		var rock_mat = StandardMaterial3D.new()
		rock_mat.albedo_color = Color(0.2, 0.15, 0.1)
		rock_mat.roughness = 0.9
		rock_mesh.surface_set_material(0, rock_mat)

		var rock_inst = MeshInstance3D.new()
		rock_inst.mesh = rock_mesh
		rock_inst.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0, TAU), rng.randf_range(-0.3, 0.3))
		rock.add_child(rock_inst)

		# Brilho embaixo da rocha (calor)
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

func _generate_geysers() -> void:
	for i in range(num_geysers):
		var geyser = Node3D.new()
		var x = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		var z = rng.randf_range(-area_size * 0.7, area_size * 0.7)
		if abs(x) < 5 and abs(z) < 5:
			x += 8.0
		geyser.position = Vector3(x, 0, z)

		# Buraco no chao
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

		# Particulas de vapor/lava subindo
		var steam = GPUParticles3D.new()
		var steam_mat = ParticleProcessMaterial.new()
		steam_mat.direction = Vector3(0, 1, 0)
		steam_mat.spread = 15.0
		steam_mat.initial_velocity_min = 5.0
		steam_mat.initial_velocity_max = 10.0
		steam_mat.gravity = Vector3(0, -1.0, 0)
		steam_mat.scale_min = 0.2
		steam_mat.scale_max = 0.6
		steam_mat.color = Color(1.0, 0.5, 0.1, 0.6)
		steam_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		steam_mat.emission_sphere_radius = 0.5

		steam.process_material = steam_mat
		steam.amount = 30
		steam.lifetime = 2.0
		steam.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 15, 6))

		var steam_draw = SphereMesh.new()
		steam_draw.radius = 0.15
		steam_draw.height = 0.15
		var steam_draw_mat = StandardMaterial3D.new()
		steam_draw_mat.albedo_color = Color(1.0, 0.6, 0.2, 0.5)
		steam_draw_mat.emission_enabled = true
		steam_draw_mat.emission = Color(1.0, 0.4, 0.0)
		steam_draw_mat.emission_energy_multiplier = 3.0
		steam_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		steam_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		steam_draw.surface_set_material(0, steam_draw_mat)
		steam.draw_pass_1 = steam_draw

		steam.position.y = 0.3
		geyser.add_child(steam)

		add_child(geyser)

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

func _generate_ember_particles() -> void:
	var embers = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 40.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 2.0
	mat.gravity = Vector3(0, 0.2, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.15
	mat.color = Color(1.0, 0.4, 0.0, 0.8)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(50, 0.5, 50)

	embers.process_material = mat
	embers.amount = 80
	embers.lifetime = 4.0
	embers.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 15, 120))

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

func _generate_ambient_lights() -> void:
	var light_colors: Array[Color] = [
		Color(1.0, 0.3, 0.0),
		Color(1.0, 0.5, 0.1),
		Color(0.8, 0.2, 0.0),
	]
	for i in range(12):
		var light = OmniLight3D.new()
		var x = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		var z = rng.randf_range(-area_size * 0.6, area_size * 0.6)
		light.position = Vector3(x, 1.5, z)
		light.light_color = light_colors[rng.randi() % light_colors.size()]
		light.light_energy = 0.6
		light.omni_range = 12.0
		light.omni_attenuation = 2.0
		add_child(light)
