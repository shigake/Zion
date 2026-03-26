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

	# Visual — flat green disc
	var mesh_inst = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 2.0 + (level - 1) * 0.3
	disc.bottom_radius = 2.0 + (level - 1) * 0.3
	disc.height = 0.05
	mesh_inst.mesh = disc
	mesh_inst.position = Vector3(0, 0.03, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 0.1, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.6, 0.0, 1.0)
	mat.emission_energy_multiplier = 0.4
	mesh_inst.material_override = mat
	pool.add_child(mesh_inst)

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
