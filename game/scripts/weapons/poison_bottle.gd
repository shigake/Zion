extends Node3D

## Garrafa de Veneno — arremessa garrafas que criam pocas de veneno no chao.

var attack_timer: float = 0.0
var active_pools: Array = []

func _process(delta: float) -> void:
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

func _throw_bottle(level: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player_pos = get_parent().get_parent().global_position

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
	pool.global_position = target_pos

	# Visual — bubbling toxic slime pool
	var pool_radius = 2.0 + (level - 1) * 0.3
	var mesh_inst = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = pool_radius
	disc.bottom_radius = pool_radius
	disc.height = 0.08
	mesh_inst.mesh = disc
	mesh_inst.position = Vector3(0, 0.04, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.45, 0.05, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 0.1)
	mat.emission_energy_multiplier = 0.5
	mesh_inst.material_override = mat
	pool.add_child(mesh_inst)

	# Bubbles rising from pool surface
	var bubbles = GPUParticles3D.new()
	bubbles.name = "Bubbles"
	bubbles.amount = 12
	bubbles.lifetime = 1.0
	bubbles.position = Vector3(0, 0.08, 0)
	var bubble_mat = ParticleProcessMaterial.new()
	bubble_mat.direction = Vector3(0, 1, 0)
	bubble_mat.initial_velocity_min = 0.3
	bubble_mat.initial_velocity_max = 0.8
	bubble_mat.spread = 45.0
	bubble_mat.gravity = Vector3(0, -0.2, 0)
	bubble_mat.scale_min = 0.02
	bubble_mat.scale_max = 0.06
	bubble_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	bubble_mat.emission_sphere_radius = pool_radius * 0.8
	bubbles.process_material = bubble_mat
	var bubble_mesh = SphereMesh.new()
	bubble_mesh.radius = 0.5
	bubble_mesh.height = 1.0
	var bubble_mesh_mat = StandardMaterial3D.new()
	bubble_mesh_mat.albedo_color = Color(0.2, 0.9, 0.1, 0.5)
	bubble_mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubble_mesh_mat.emission_enabled = true
	bubble_mesh_mat.emission = Color(0.2, 0.8, 0.1)
	bubble_mesh_mat.emission_energy_multiplier = 0.3
	bubble_mesh.material = bubble_mesh_mat
	bubbles.draw_pass_1 = bubble_mesh
	pool.add_child(bubbles)

	# Vapors — rising toxic mist
	var vapors = GPUParticles3D.new()
	vapors.name = "Vapors"
	vapors.amount = 8
	vapors.lifetime = 1.5
	vapors.position = Vector3(0, 0.08, 0)
	var vapor_mat = ParticleProcessMaterial.new()
	vapor_mat.direction = Vector3(0, 1, 0)
	vapor_mat.initial_velocity_min = 0.2
	vapor_mat.initial_velocity_max = 0.2
	vapor_mat.spread = 30.0
	vapor_mat.gravity = Vector3(0, -0.1, 0)
	vapor_mat.scale_min = 0.3
	vapor_mat.scale_max = 0.8
	vapor_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	vapor_mat.emission_sphere_radius = pool_radius * 0.6
	var vapor_scale_curve = CurveTexture.new()
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(0.7, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	vapor_scale_curve.curve = curve
	vapor_mat.scale_curve = vapor_scale_curve
	vapors.process_material = vapor_mat
	var vapor_mesh = SphereMesh.new()
	vapor_mesh.radius = 0.5
	vapor_mesh.height = 1.0
	var vapor_mesh_mat = StandardMaterial3D.new()
	vapor_mesh_mat.albedo_color = Color(0.1, 0.6, 0.05, 0.15)
	vapor_mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vapor_mesh_mat.emission_enabled = true
	vapor_mesh_mat.emission = Color(0.1, 0.5, 0.05)
	vapor_mesh_mat.emission_energy_multiplier = 0.2
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

	AudioManager.play_sfx("hit")
	ParticleFactory.spawn_hit_particles(target_pos + Vector3(0, 0.5, 0), Color(0.2, 0.8, 0.1))
