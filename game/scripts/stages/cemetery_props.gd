extends Node3D

## Direcao de arte procedural do cemiterio:
## lapides estilizadas, mausoleus, lanternas espirituais, flora fria e neblina lunar.

@export var num_tombstones: int = 58
@export var num_trees: int = 18
@export var num_lights: int = 12
@export var num_mausoleums: int = 4
@export var num_flower_patches: int = 26
@export var area_size: float = 82.0

const GROUND_SHADER: Shader = preload("res://assets/materials/ground_shader.gdshader")

const STONE_COLORS = [
	Color(0.44, 0.48, 0.54),
	Color(0.50, 0.53, 0.59),
	Color(0.39, 0.44, 0.49),
]

const MOSS_COLORS = [
	Color(0.19, 0.28, 0.24),
	Color(0.16, 0.25, 0.23),
	Color(0.21, 0.22, 0.30),
]

const BLOSSOM_COLORS = [
	Color(0.72, 0.90, 0.95),
	Color(0.83, 0.76, 0.96),
	Color(0.94, 0.95, 0.90),
]

const SPIRIT_COLORS = [
	Color(0.34, 0.88, 0.99),
	Color(0.56, 0.76, 1.0),
	Color(0.52, 0.98, 0.90),
]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_apply_stage_art_direction()
	_generate_moon()
	_generate_mausoleums()
	_generate_tombstones()
	_generate_dead_trees()
	_generate_spirit_lanterns()
	_generate_flower_patches()
	_generate_ground_fog()
	_generate_spirit_wisps()

func _apply_stage_art_direction() -> void:
	var stage := get_parent()
	if not stage:
		return

	var ground := stage.get_node_or_null("Ground") as MeshInstance3D
	if ground:
		var ground_mat := ShaderMaterial.new()
		ground_mat.shader = GROUND_SHADER
		ground_mat.set_shader_parameter("color_a", Color(0.10, 0.17, 0.15, 1.0))
		ground_mat.set_shader_parameter("color_b", Color(0.16, 0.23, 0.30, 1.0))
		ground_mat.set_shader_parameter("accent_color", Color(0.30, 0.34, 0.37, 1.0))
		ground_mat.set_shader_parameter("tile_size", 2.2)
		ground_mat.set_shader_parameter("edge_blend", 0.09)
		ground.material_override = ground_mat

	var world_env := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env and world_env.environment:
		var env := world_env.environment
		env.background_color = Color(0.04, 0.07, 0.15, 1.0)
		env.ambient_light_color = Color(0.28, 0.34, 0.46, 1.0)
		env.ambient_light_energy = 1.05
		env.fog_enabled = true
		env.fog_density = 0.014
		env.fog_light_color = Color(0.17, 0.24, 0.34, 1.0)
		env.glow_enabled = true
		env.glow_intensity = 0.55
		env.glow_bloom = 0.18

	var moon_light := stage.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if moon_light:
		moon_light.light_color = Color(0.66, 0.75, 0.95, 1.0)
		moon_light.light_energy = 1.05
		moon_light.shadow_enabled = true

	var fill_light := stage.get_node_or_null("FillLight") as DirectionalLight3D
	if fill_light:
		fill_light.light_color = Color(0.21, 0.30, 0.46, 1.0)
		fill_light.light_energy = 0.45

func _generate_moon() -> void:
	var moon_root := Node3D.new()
	moon_root.position = Vector3(-54.0, 30.0, -72.0)
	add_child(moon_root)

	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 5.0
	moon_mesh.height = 10.0
	var moon := MeshInstance3D.new()
	moon.mesh = moon_mesh
	var moon_mat := StandardMaterial3D.new()
	moon_mat.albedo_color = Color(0.90, 0.94, 1.0)
	moon_mat.emission_enabled = true
	moon_mat.emission = Color(0.62, 0.82, 1.0)
	moon_mat.emission_energy_multiplier = 2.4
	moon.material_override = moon_mat
	moon_root.add_child(moon)

	var halo_mesh := SphereMesh.new()
	halo_mesh.radius = 6.2
	halo_mesh.height = 12.4
	var halo := MeshInstance3D.new()
	halo.mesh = halo_mesh
	var halo_mat := StandardMaterial3D.new()
	halo_mat.albedo_color = Color(0.38, 0.55, 0.98, 0.12)
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_mat.emission_enabled = true
	halo_mat.emission = Color(0.30, 0.48, 0.92)
	halo_mat.emission_energy_multiplier = 1.6
	halo.material_override = halo_mat
	moon_root.add_child(halo)

func _generate_mausoleums() -> void:
	for i in range(num_mausoleums):
		var pos := _random_ground_position(22.0)
		var mausoleum := Node3D.new()
		mausoleum.position = pos
		mausoleum.rotation.y = rng.randf() * TAU
		add_child(mausoleum)

		var stone_color: Color = _pick_color(STONE_COLORS)
		var accent_color: Color = stone_color.lightened(0.10)
		var sigil_color: Color = _pick_color(SPIRIT_COLORS)

		var base := BoxMesh.new()
		base.size = Vector3(2.8, 0.28, 3.2)
		_add_cel_mesh(mausoleum, base, Vector3(0, 0.14, 0), stone_color, {
			"outline_width": 0.03,
			"shadow_color": stone_color.darkened(0.45),
		})

		var body := BoxMesh.new()
		body.size = Vector3(1.9, 1.95, 2.2)
		_add_cel_mesh(mausoleum, body, Vector3(0, 1.14, 0), accent_color, {
			"outline_width": 0.028,
			"shadow_color": accent_color.darkened(0.42),
		})

		var roof := BoxMesh.new()
		roof.size = Vector3(2.3, 0.24, 2.6)
		_add_cel_mesh(mausoleum, roof, Vector3(0, 2.12, 0), stone_color.lightened(0.08), {
			"outline_width": 0.026,
			"shadow_color": stone_color.darkened(0.40),
		})

		var crown := BoxMesh.new()
		crown.size = Vector3(1.2, 0.18, 1.4)
		_add_cel_mesh(mausoleum, crown, Vector3(0, 2.34, 0), stone_color.lightened(0.18), {
			"outline_width": 0.024,
			"shadow_color": stone_color.darkened(0.36),
		})

		var door := BoxMesh.new()
		door.size = Vector3(0.76, 1.32, 0.08)
		_add_cel_mesh(mausoleum, door, Vector3(0, 0.90, 1.10), stone_color.darkened(0.22), {
			"outline_width": 0.020,
			"shadow_color": stone_color.darkened(0.58),
		})

		for side in [-1.0, 1.0]:
			var column := BoxMesh.new()
			column.size = Vector3(0.22, 1.35, 0.18)
			_add_cel_mesh(mausoleum, column, Vector3(side * 0.78, 0.92, 1.08), stone_color, {
				"outline_width": 0.020,
				"shadow_color": stone_color.darkened(0.45),
			})

		var sigil := BoxMesh.new()
		sigil.size = Vector3(0.30, 0.30, 0.03)
		_add_emissive_mesh(mausoleum, sigil, Vector3(0, 1.20, 1.16), sigil_color, 2.2)

func _generate_tombstones() -> void:
	for i in range(num_tombstones):
		var tombstone := Node3D.new()
		tombstone.position = _random_ground_position(7.0)
		tombstone.rotation.y = rng.randf() * TAU
		add_child(tombstone)

		var stone_color: Color = _pick_color(STONE_COLORS)
		var mound_color: Color = _pick_color(MOSS_COLORS)
		var style := rng.randi_range(0, 3)

		var mound := CylinderMesh.new()
		mound.top_radius = 0.26
		mound.bottom_radius = 0.38
		mound.height = 0.12
		_add_cel_mesh(tombstone, mound, Vector3(0, 0.05, 0), mound_color, {
			"outline_width": 0.02,
			"shadow_color": mound_color.darkened(0.42),
		})

		match style:
			0:
				var slab := BoxMesh.new()
				slab.size = Vector3(0.40, 0.78, 0.16)
				_add_cel_mesh(tombstone, slab, Vector3(0, 0.44, 0), stone_color, {
					"outline_width": 0.02,
					"shadow_color": stone_color.darkened(0.42),
				})

				var cap := CylinderMesh.new()
				cap.top_radius = 0.20
				cap.bottom_radius = 0.20
				cap.height = 0.12
				_add_cel_mesh(tombstone, cap, Vector3(0, 0.84, 0), stone_color.lightened(0.08), {
					"outline_width": 0.018,
					"shadow_color": stone_color.darkened(0.40),
				})
			1:
				var stem := BoxMesh.new()
				stem.size = Vector3(0.18, 0.82, 0.16)
				_add_cel_mesh(tombstone, stem, Vector3(0, 0.46, 0), stone_color, {
					"outline_width": 0.02,
					"shadow_color": stone_color.darkened(0.42),
				})

				var arm := BoxMesh.new()
				arm.size = Vector3(0.52, 0.14, 0.18)
				_add_cel_mesh(tombstone, arm, Vector3(0, 0.68, 0), stone_color.lightened(0.05), {
					"outline_width": 0.018,
					"shadow_color": stone_color.darkened(0.40),
				})
			2:
				var base := BoxMesh.new()
				base.size = Vector3(0.38, 0.16, 0.34)
				_add_cel_mesh(tombstone, base, Vector3(0, 0.10, 0), stone_color.darkened(0.04), {
					"outline_width": 0.018,
					"shadow_color": stone_color.darkened(0.45),
				})

				var obelisk := CylinderMesh.new()
				obelisk.top_radius = 0.05
				obelisk.bottom_radius = 0.18
				obelisk.height = 0.94
				_add_cel_mesh(tombstone, obelisk, Vector3(0, 0.56, 0), stone_color, {
					"outline_width": 0.02,
					"shadow_color": stone_color.darkened(0.42),
				})
			_:
				var hero_slab := BoxMesh.new()
				hero_slab.size = Vector3(0.36, 0.74, 0.18)
				_add_cel_mesh(tombstone, hero_slab, Vector3(0.04, 0.42, 0), stone_color.lightened(0.02), {
					"outline_width": 0.02,
					"shadow_color": stone_color.darkened(0.40),
				}, Vector3(0, 0, deg_to_rad(6)))

				var brace := BoxMesh.new()
				brace.size = Vector3(0.28, 0.24, 0.18)
				_add_cel_mesh(tombstone, brace, Vector3(-0.08, 0.20, -0.03), stone_color.darkened(0.02), {
					"outline_width": 0.018,
					"shadow_color": stone_color.darkened(0.45),
				}, Vector3(0, 0, deg_to_rad(-8)))

		if rng.randf() < 0.38:
			var rune := BoxMesh.new()
			rune.size = Vector3(0.14, 0.22, 0.02)
			_add_emissive_mesh(tombstone, rune, Vector3(0, 0.48, 0.09), _pick_color(SPIRIT_COLORS), 1.8)

		if rng.randf() < 0.30:
			_add_flower_cluster(tombstone, Vector3(rng.randf_range(-0.14, 0.14), 0.02, 0.10), 3)

func _generate_dead_trees() -> void:
	for i in range(num_trees):
		var tree := Node3D.new()
		tree.position = _random_ground_position(10.0)
		tree.rotation.y = rng.randf() * TAU
		add_child(tree)

		var trunk_color := Color(0.18, 0.12, 0.09)
		var trunk_height := rng.randf_range(2.4, 4.1)

		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.08
		trunk.bottom_radius = 0.18
		trunk.height = trunk_height
		_add_cel_mesh(tree, trunk, Vector3(0, trunk_height * 0.50, 0), trunk_color, {
			"outline_width": 0.024,
			"shadow_color": Color(0.08, 0.04, 0.03),
		}, Vector3(0, 0, rng.randf_range(-0.12, 0.12)))

		var upper_trunk := CylinderMesh.new()
		upper_trunk.top_radius = 0.04
		upper_trunk.bottom_radius = 0.07
		upper_trunk.height = trunk_height * 0.45
		_add_cel_mesh(tree, upper_trunk, Vector3(0.05, trunk_height * 0.92, 0.02), trunk_color.lightened(0.06), {
			"outline_width": 0.02,
			"shadow_color": Color(0.08, 0.04, 0.03),
		}, Vector3(rng.randf_range(-0.18, 0.18), 0, rng.randf_range(-0.25, 0.25)))

		for j in range(rng.randi_range(3, 5)):
			var branch_height := rng.randf_range(trunk_height * 0.42, trunk_height * 0.92)
			var branch_len := rng.randf_range(0.8, 1.45)
			var branch := CylinderMesh.new()
			branch.top_radius = 0.02
			branch.bottom_radius = 0.05
			branch.height = branch_len
			var branch_rot := Vector3(
				rng.randf_range(-0.6, 0.6),
				rng.randf_range(-0.8, 0.8),
				rng.randf_range(-1.1, 1.1)
			)
			var branch_pos := Vector3(rng.randf_range(-0.10, 0.10), branch_height, rng.randf_range(-0.10, 0.10))
			_add_cel_mesh(tree, branch, branch_pos, trunk_color.lightened(0.04), {
				"outline_width": 0.018,
				"shadow_color": Color(0.08, 0.04, 0.03),
			}, branch_rot)

			if rng.randf() < 0.65:
				var leaf := SphereMesh.new()
				leaf.radius = rng.randf_range(0.14, 0.24)
				leaf.height = leaf.radius * 1.6
				_add_cel_mesh(tree, leaf, branch_pos + Vector3(
					rng.randf_range(0.18, 0.42),
					rng.randf_range(0.10, 0.26),
					rng.randf_range(-0.18, 0.18)
				), _pick_color(MOSS_COLORS).lightened(0.08), {
					"outline_width": 0.018,
					"shadow_color": Color(0.05, 0.10, 0.09),
				}, Vector3.ZERO, Vector3(1.0, 0.72, 1.0))

		if rng.randf() < 0.35:
			var fruit := SphereMesh.new()
			fruit.radius = 0.07
			fruit.height = 0.10
			_add_emissive_mesh(tree, fruit, Vector3(0.20, trunk_height * 0.72, -0.12), _pick_color(SPIRIT_COLORS), 1.6)

func _generate_spirit_lanterns() -> void:
	for i in range(num_lights):
		var lantern := Node3D.new()
		lantern.position = _random_ground_position(9.0)
		lantern.rotation.y = rng.randf() * TAU
		add_child(lantern)

		var stone_color: Color = _pick_color(STONE_COLORS)
		var glow_color: Color = _pick_color(SPIRIT_COLORS)

		var base := CylinderMesh.new()
		base.top_radius = 0.22
		base.bottom_radius = 0.28
		base.height = 0.18
		_add_cel_mesh(lantern, base, Vector3(0, 0.09, 0), stone_color, {
			"outline_width": 0.022,
			"shadow_color": stone_color.darkened(0.45),
		})

		var post := BoxMesh.new()
		post.size = Vector3(0.14, 0.95, 0.14)
		_add_cel_mesh(lantern, post, Vector3(0, 0.58, 0), stone_color.lightened(0.04), {
			"outline_width": 0.02,
			"shadow_color": stone_color.darkened(0.42),
		})

		var roof := BoxMesh.new()
		roof.size = Vector3(0.52, 0.08, 0.52)
		_add_cel_mesh(lantern, roof, Vector3(0, 1.08, 0), stone_color.lightened(0.10), {
			"outline_width": 0.02,
			"shadow_color": stone_color.darkened(0.40),
		})

		var housing := BoxMesh.new()
		housing.size = Vector3(0.34, 0.12, 0.34)
		_add_cel_mesh(lantern, housing, Vector3(0, 0.92, 0), stone_color.darkened(0.04), {
			"outline_width": 0.018,
			"shadow_color": stone_color.darkened(0.48),
		})

		var flame := SphereMesh.new()
		flame.radius = 0.12
		flame.height = 0.18
		_add_emissive_mesh(lantern, flame, Vector3(0, 0.90, 0), glow_color, 2.5)

		var light := OmniLight3D.new()
		light.position = Vector3(0, 0.92, 0)
		light.light_color = glow_color
		light.light_energy = 0.72
		light.omni_range = 10.0
		light.omni_attenuation = 1.6
		light.shadow_enabled = false
		lantern.add_child(light)

func _generate_flower_patches() -> void:
	for i in range(num_flower_patches):
		var patch := Node3D.new()
		patch.position = _random_ground_position(6.0)
		add_child(patch)
		_add_flower_cluster(patch, Vector3.ZERO, rng.randi_range(4, 7))

func _add_flower_cluster(parent: Node3D, center: Vector3, count: int) -> void:
	for i in range(count):
		var stem_height := rng.randf_range(0.10, 0.18)
		var flower_offset := Vector3(
			center.x + rng.randf_range(-0.18, 0.18),
			center.y,
			center.z + rng.randf_range(-0.18, 0.18)
		)

		var stem := CylinderMesh.new()
		stem.top_radius = 0.010
		stem.bottom_radius = 0.015
		stem.height = stem_height
		_add_cel_mesh(parent, stem, flower_offset + Vector3(0, stem_height * 0.50, 0), Color(0.20, 0.38, 0.30), {
			"outline_width": 0.012,
			"shadow_color": Color(0.06, 0.10, 0.08),
		})

		var blossom := SphereMesh.new()
		blossom.radius = rng.randf_range(0.035, 0.06)
		blossom.height = blossom.radius * 1.4
		_add_cel_mesh(parent, blossom, flower_offset + Vector3(0, stem_height + 0.02, 0), _pick_color(BLOSSOM_COLORS), {
			"outline_width": 0.014,
			"shadow_color": Color(0.22, 0.22, 0.28),
			"rim_color": Color(0.96, 0.98, 1.0, 0.28),
		}, Vector3.ZERO, Vector3(1.0, 0.8, 1.0))

func _generate_ground_fog() -> void:
	var fog := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 0.08
	mat.initial_velocity_max = 0.24
	mat.gravity = Vector3.ZERO
	mat.scale_min = 2.6
	mat.scale_max = 5.4
	mat.color = Color(0.42, 0.50, 0.62, 0.14)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(area_size * 0.62, 0.10, area_size * 0.62)

	fog.process_material = mat
	fog.amount = 54
	fog.lifetime = 10.0
	fog.visibility_aabb = AABB(
		Vector3(-area_size, -1.0, -area_size),
		Vector3(area_size * 2.0, 4.0, area_size * 2.0)
	)

	var draw_pass := SphereMesh.new()
	draw_pass.radius = 1.0
	draw_pass.height = 0.26
	var fog_mat := StandardMaterial3D.new()
	fog_mat.albedo_color = Color(0.40, 0.46, 0.58, 0.10)
	fog_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass.surface_set_material(0, fog_mat)
	fog.draw_pass_1 = draw_pass

	fog.position = Vector3(0, 0.24, 0)
	add_child(fog)

func _generate_spirit_wisps() -> void:
	var wisps := GPUParticles3D.new()
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0, 1, 0)
	process.spread = 42.0
	process.initial_velocity_min = 0.12
	process.initial_velocity_max = 0.34
	process.gravity = Vector3.ZERO
	process.scale_min = 0.14
	process.scale_max = 0.32
	process.color = Color(0.48, 0.90, 1.0, 0.85)
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(area_size * 0.72, 0.5, area_size * 0.72)

	wisps.process_material = process
	wisps.amount = 24
	wisps.lifetime = 7.0
	wisps.visibility_aabb = AABB(
		Vector3(-area_size, -1.0, -area_size),
		Vector3(area_size * 2.0, 10.0, area_size * 2.0)
	)

	var orb := SphereMesh.new()
	orb.radius = 0.16
	orb.height = 0.20
	orb.surface_set_material(0, VisualSetup.create_glow_material(Color(0.42, 0.90, 1.0, 0.85), 2.4))
	wisps.draw_pass_1 = orb
	wisps.position = Vector3(0, 0.9, 0)
	add_child(wisps)

func _add_cel_mesh(
	parent: Node3D,
	mesh: Mesh,
	pos: Vector3,
	color: Color,
	settings: Dictionary = {},
	rot: Vector3 = Vector3.ZERO,
	scl: Vector3 = Vector3.ONE
) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.rotation = rot
	mesh_inst.scale = scl
	parent.add_child(mesh_inst)
	VisualSetup.apply_cel_shader_to_mesh(mesh_inst, color, settings)
	return mesh_inst

func _add_emissive_mesh(
	parent: Node3D,
	mesh: Mesh,
	pos: Vector3,
	color: Color,
	intensity: float,
	rot: Vector3 = Vector3.ZERO,
	scl: Vector3 = Vector3.ONE
) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.rotation = rot
	mesh_inst.scale = scl
	parent.add_child(mesh_inst)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = intensity
	mesh_inst.material_override = mat
	return mesh_inst

func _random_ground_position(min_center_distance: float) -> Vector3:
	var fallback := Vector3(
		rng.randf_range(-area_size, area_size),
		0,
		rng.randf_range(-area_size, area_size)
	)
	for attempt in range(30):
		var x := rng.randf_range(-area_size, area_size)
		var z := rng.randf_range(-area_size, area_size)
		if Vector2(x, z).length() < min_center_distance:
			continue
		return Vector3(x, 0, z)
	return fallback

func _pick_color(palette: Array) -> Color:
	return palette[rng.randi_range(0, palette.size() - 1)]
