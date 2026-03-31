extends Node3D

## Garrafa de Veneno — arremessa garrafas que criam pocas de veneno no chao.

var attack_timer: float = 0.0
var active_pools: Array = []

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("poison_bottle")
	if level <= 0:
		return

	# Clean up expired pools
	active_pools = active_pools.filter(func(p): return is_instance_valid(p))

	var max_pools = 3 + int((level - 1) / 2)
	var cooldown = WeaponDB.get_cooldown("poison_bottle", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	attack_timer -= delta
	if attack_timer <= 0 and active_pools.size() < max_pools:
		attack_timer = cooldown
		_throw_bottle(level)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _throw_bottle(level: int) -> void:
	if not is_inside_tree():
		return
	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	var target_pos: Vector3
	if GameManager.manual_aim:
		# Throw in aim direction, 8 units away
		target_pos = player_pos + GameManager.aim_direction * 8.0
		target_pos.y = 0.05
	else:
		var nearest: Node3D = null
		var min_dist = INF
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var d = player_pos.distance_squared_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e

		if nearest == null:
			return

		target_pos = nearest.global_position
		target_pos.y = 0.05

	# Create poison pool
	var pool = Node3D.new()
	pool.name = "PoisonPool"
	pool.position = target_pos

	# Visual — billboard sprite or bubbling toxic slime pool fallback
	var pool_radius = 2.0 + (level - 1) * 0.3

	# Try billboard sprite for poison cloud
	var sprite_path = "res://assets/sprites/projectiles/poison_cloud.png"
	if ResourceLoader.exists(sprite_path):
		var sprite = Sprite3D.new()
		sprite.texture = load(sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.02
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "ProjectileSprite"
		sprite.position = Vector3(0, 0.5, 0)
		pool.add_child(sprite)

	# Base puddle layer — dark toxic pool
	var mesh_inst = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = pool_radius
	disc.bottom_radius = pool_radius
	disc.height = 0.08
	mesh_inst.mesh = disc
	mesh_inst.position = Vector3(0, 0.04, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.18, 0.01, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic = 0.3
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.7, 0.03)
	mat.emission_energy_multiplier = 1.5
	mesh_inst.material_override = mat
	pool.add_child(mesh_inst)

	# Inner swirl layer — brighter, smaller, rotates for movement illusion
	var swirl = MeshInstance3D.new()
	var swirl_disc = CylinderMesh.new()
	swirl_disc.top_radius = pool_radius * 0.7
	swirl_disc.bottom_radius = pool_radius * 0.65
	swirl_disc.height = 0.04
	swirl.mesh = swirl_disc
	swirl.position = Vector3(0, 0.07, 0)
	var swirl_mat = StandardMaterial3D.new()
	swirl_mat.albedo_color = Color(0.08, 0.45, 0.02, 0.6)
	swirl_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	swirl_mat.roughness = 0.0
	swirl_mat.metallic = 0.5
	swirl_mat.emission_enabled = true
	swirl_mat.emission = Color(0.2, 1.0, 0.1)
	swirl_mat.emission_energy_multiplier = 2.0
	swirl_mat.no_depth_test = true
	swirl.material_override = swirl_mat
	pool.add_child(swirl)

	# Toxic highlight spots — small bright discs at random offsets
	for _i in range(3):
		var spot = MeshInstance3D.new()
		var spot_disc = CylinderMesh.new()
		spot_disc.top_radius = pool_radius * 0.2
		spot_disc.bottom_radius = pool_radius * 0.15
		spot_disc.height = 0.03
		spot.mesh = spot_disc
		var spot_offset = Vector3(randf_range(-pool_radius * 0.5, pool_radius * 0.5), 0.09, randf_range(-pool_radius * 0.5, pool_radius * 0.5))
		spot.position = spot_offset
		var spot_mat = StandardMaterial3D.new()
		spot_mat.albedo_color = Color(0.15, 0.9, 0.05, 0.5)
		spot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		spot_mat.emission_enabled = true
		spot_mat.emission = Color(0.3, 1.0, 0.1)
		spot_mat.emission_energy_multiplier = 3.0
		spot_mat.no_depth_test = true
		spot.material_override = spot_mat
		pool.add_child(spot)

	# Pulsing scale animation on base pool surface
	var tween = pool.create_tween().set_loops()
	tween.tween_property(mesh_inst, "scale", Vector3(1.05, 1.0, 1.05), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(mesh_inst, "scale", Vector3(0.95, 1.0, 0.95), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Swirl rotation animation — spins to simulate liquid movement
	var swirl_tween = pool.create_tween().set_loops()
	swirl_tween.tween_property(swirl, "rotation:y", TAU, 4.0).from(0.0)

	# Spot pulsing — each spot glows independently
	for spot_node in pool.get_children():
		if spot_node is MeshInstance3D and spot_node != mesh_inst and spot_node != swirl:
			var spot_tw = pool.create_tween().set_loops()
			var delay = randf_range(0.0, 1.5)
			spot_tw.tween_property(spot_node, "scale", Vector3(1.3, 1.0, 1.3), 0.6).set_delay(delay).set_trans(Tween.TRANS_SINE)
			spot_tw.tween_property(spot_node, "scale", Vector3(0.7, 1.0, 0.7), 0.6).set_trans(Tween.TRANS_SINE)

	# Bubbles rising from pool surface
	var bubbles = GPUParticles3D.new()
	bubbles.name = "Bubbles"
	bubbles.amount = 20
	bubbles.lifetime = 1.2
	bubbles.position = Vector3(0, 0.08, 0)
	var bubble_mat = ParticleProcessMaterial.new()
	bubble_mat.direction = Vector3(0, 1, 0)
	bubble_mat.initial_velocity_min = 0.4
	bubble_mat.initial_velocity_max = 1.0
	bubble_mat.spread = 50.0
	bubble_mat.gravity = Vector3(0, -0.3, 0)
	bubble_mat.scale_min = 0.03
	bubble_mat.scale_max = 0.08
	bubble_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	bubble_mat.emission_sphere_radius = pool_radius * 0.85
	bubble_mat.damping_min = 0.5
	bubble_mat.damping_max = 1.5
	# Bubble scale curve — grow then pop
	var bubble_scale_curve = CurveTexture.new()
	var bcurve = Curve.new()
	bcurve.add_point(Vector2(0.0, 0.3))
	bcurve.add_point(Vector2(0.5, 1.0))
	bcurve.add_point(Vector2(0.85, 1.0))
	bcurve.add_point(Vector2(1.0, 0.0))
	bubble_scale_curve.curve = bcurve
	bubble_mat.scale_curve = bubble_scale_curve
	bubbles.process_material = bubble_mat
	var bubble_mesh = SphereMesh.new()
	bubble_mesh.radius = 0.5
	bubble_mesh.height = 1.0
	var bubble_mesh_mat = StandardMaterial3D.new()
	bubble_mesh_mat.albedo_color = Color(0.1, 0.85, 0.05, 0.55)
	bubble_mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubble_mesh_mat.roughness = 0.1
	bubble_mesh_mat.emission_enabled = true
	bubble_mesh_mat.emission = Color(0.15, 0.9, 0.05)
	bubble_mesh_mat.emission_energy_multiplier = 0.6
	bubble_mesh.material = bubble_mesh_mat
	bubbles.draw_pass_1 = bubble_mesh
	pool.add_child(bubbles)

	# Vapors — rising toxic mist
	var vapors = GPUParticles3D.new()
	vapors.name = "Vapors"
	vapors.amount = 14
	vapors.lifetime = 2.0
	vapors.position = Vector3(0, 0.1, 0)
	var vapor_mat = ParticleProcessMaterial.new()
	vapor_mat.direction = Vector3(0, 1, 0)
	vapor_mat.initial_velocity_min = 0.15
	vapor_mat.initial_velocity_max = 0.35
	vapor_mat.spread = 40.0
	vapor_mat.gravity = Vector3(0, -0.05, 0)
	vapor_mat.scale_min = 0.4
	vapor_mat.scale_max = 1.2
	vapor_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	vapor_mat.emission_sphere_radius = pool_radius * 0.7
	vapor_mat.damping_min = 0.3
	vapor_mat.damping_max = 0.8
	var vapor_scale_curve = CurveTexture.new()
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.15, 0.6))
	curve.add_point(Vector2(0.4, 1.0))
	curve.add_point(Vector2(0.7, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	vapor_scale_curve.curve = curve
	vapor_mat.scale_curve = vapor_scale_curve
	vapors.process_material = vapor_mat
	var vapor_mesh = SphereMesh.new()
	vapor_mesh.radius = 0.5
	vapor_mesh.height = 1.0
	var vapor_mesh_mat = StandardMaterial3D.new()
	vapor_mesh_mat.albedo_color = Color(0.08, 0.5, 0.03, 0.12)
	vapor_mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vapor_mesh_mat.emission_enabled = true
	vapor_mesh_mat.emission = Color(0.1, 0.6, 0.03)
	vapor_mesh_mat.emission_energy_multiplier = 0.4
	vapor_mesh.material = vapor_mesh_mat
	vapors.draw_pass_1 = vapor_mesh
	pool.add_child(vapors)

	# Damage area
	var area = Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 2
	area.monitoring = true
	var shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 2.0 + (level - 1) * 0.3
	shape.shape = sphere
	area.add_child(shape)
	pool.add_child(area)

	# Pool behavior
	var behavior = Node.new()
	behavior.set_script(preload("res://scripts/weapons/poison_pool_behavior.gd"))
	behavior.set_meta("damage", int(WeaponDB.get_damage("poison_bottle", level)))
	behavior.set_meta("lifetime", 5.0 + level * 0.5)
	behavior.set_meta("area", area)
	pool.add_child(behavior)

	active_pools.append(pool)
	get_tree().current_scene.call_deferred("add_child", pool)

	AudioManager.play_sfx("poison_splash")
	ParticleFactory.spawn_hit_particles(target_pos + Vector3(0, 0.5, 0), Color(0.2, 0.8, 0.1))
