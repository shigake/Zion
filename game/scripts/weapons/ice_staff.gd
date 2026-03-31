extends Node3D

## Cajado de Gelo — projetil lento que congela inimigos em area ao impactar.

var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/ice_staff_projectile.tscn")

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("ice_staff")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("ice_staff", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		_fire(level)

func _fire(level: int) -> void:
	if not is_inside_tree():
		return

	# In multiplayer, only host fires real projectiles
	if MultiplayerManager.is_online and not multiplayer.is_server():
		_fire_visual_only(level)
		return

	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	var direction: Vector3
	if GameManager.manual_aim:
		direction = GameManager.aim_direction
	else:
		# Find nearest enemy
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

		direction = (nearest.global_position - player_pos).normalized()
		direction.y = 0

	# Ice particles at spawn
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.3, 0.7, 1.0))
	AudioManager.play_sfx("magic_cast")

	var dmg = int(WeaponDB.get_damage("ice_staff", level))

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	# Create ice crystal projectile
	var bullet = ObjectPool.get_instance(projectile_scene)
	if not "direction" in bullet:
		bullet.queue_free()
		return
	var pos = player_pos + Vector3(0, 0.5, 0)
	bullet.direction = direction.normalized()
	bullet.damage = dmg
	bullet.speed = 10.0  # Slow projectile
	bullet.lifetime = 4.0
	bullet.damage_type = "ice"
	bullet.weapon_id = "ice_staff"

	# Override behavior: on hit, freeze area
	bullet.body_entered.connect(func(body: Node3D) -> void:
		if not is_instance_valid(bullet) or not bullet.is_inside_tree():
			return
		if body.has_method("take_damage") and body.is_in_group("enemies"):
			GameManager._last_attacking_weapon = "ice_staff"
			var hit_pos = bullet.global_position
			body.call_deferred("take_damage", dmg, "ice")
			_freeze_area(hit_pos, level)
			bullet.queue_free()
	, CONNECT_ONE_SHOT)

	scene_root.add_child(bullet)
	bullet.global_position = pos

## Client-only: spawns visual ice projectile without collision (no damage/freeze).
func _fire_visual_only(level: int) -> void:
	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	var direction: Vector3
	if GameManager.manual_aim:
		direction = GameManager.aim_direction
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
		direction = (nearest.global_position - player_pos).normalized()
		direction.y = 0

	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.3, 0.7, 1.0))
	AudioManager.play_sfx("magic_cast")

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	var proj = ObjectPool.get_instance(projectile_scene)
	if not "direction" in proj:
		proj.queue_free()
		return
	var pos = player_pos + Vector3(0, 0.5, 0)
	proj.direction = direction.normalized()
	proj.damage = 0
	proj.speed = 10.0
	proj.lifetime = 4.0
	# Disable collision for visual-only projectile
	proj.collision_layer = 0
	proj.collision_mask = 0
	proj.set_deferred("monitorable", false)
	proj.set_deferred("monitoring", false)
	scene_root.add_child(proj)
	proj.global_position = pos

func _freeze_area(pos: Vector3, level: int) -> void:
	var freeze_radius = 3.0 + (level - 1) * 0.3
	var freeze_duration = 2.0 + (level - 1) * 0.15
	var dmg = int(WeaponDB.get_damage("ice_staff", level) * 0.5)

	# Ice explosion particles
	ParticleFactory.spawn_hit_particles(pos, Color(0.4, 0.8, 1.0))

	# Spawn ice crystals growing from ground
	_spawn_freeze_crystals(pos, freeze_duration)

	# Spawn frost mist
	_spawn_frost_mist(pos, freeze_duration)

	# Find all enemies in radius and slow them (spatial grid: O(1) instead of O(n))
	var nearby = GameManager.get_enemies_in_radius(pos, freeze_radius)
	for e in nearby:
		if not is_instance_valid(e):
			continue
		if e.has_method("take_damage"):
			GameManager._last_attacking_weapon = "ice_staff"
			e.call_deferred("take_damage", dmg, "ice")
		# Apply slow effect if enemy supports it
		if e.has_method("apply_slow"):
			e.call_deferred("apply_slow", 0.4, freeze_duration)

func _spawn_freeze_crystals(pos: Vector3, duration: float) -> void:
	var crystal_mat = StandardMaterial3D.new()
	crystal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crystal_mat.albedo_color = Color(0.4, 0.75, 1.0, 0.5)
	crystal_mat.emission_enabled = true
	crystal_mat.emission = Color(0.3, 0.7, 1.0)
	crystal_mat.emission_energy_multiplier = 1.2

	var num_crystals = randi_range(5, 8)
	var container = Node3D.new()
	container.global_position = pos
	get_tree().current_scene.call_deferred("add_child", container)

	for i in range(num_crystals):
		var crystal = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		var h = randf_range(0.15, 0.35)
		var w = randf_range(0.03, 0.06)
		mesh.size = Vector3(w, h, w)
		crystal.mesh = mesh
		crystal.material_override = crystal_mat

		# Random position around impact point
		var angle = randf() * TAU
		var dist = randf_range(0.2, 1.2)
		crystal.position = Vector3(cos(angle) * dist, h * 0.5, sin(angle) * dist)

		# Slight random rotation for irregular look
		crystal.rotation.x = randf_range(-0.3, 0.3)
		crystal.rotation.z = randf_range(-0.3, 0.3)

		# Start at zero scale, animate growing
		crystal.scale = Vector3.ZERO
		container.add_child(crystal)

		var tween = crystal.create_tween()
		var target_scale = Vector3(1.0, 1.0, 1.0) * randf_range(0.7, 1.3)
		tween.tween_property(crystal, "scale", target_scale, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_interval(duration - 0.6)
		tween.tween_property(crystal, "scale", Vector3.ZERO, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

	# Remove container after duration
	var cleanup_tween = container.create_tween()
	cleanup_tween.tween_interval(duration + 0.1)
	cleanup_tween.tween_callback(container.queue_free)

func _spawn_frost_mist(pos: Vector3, duration: float) -> void:
	var mist = GPUParticles3D.new()
	mist.global_position = pos
	mist.amount = 12
	mist.lifetime = 1.0
	mist.one_shot = false
	mist.emitting = true

	# Mist draw pass — white/blue transparent spheres
	var mist_mesh = SphereMesh.new()
	mist_mesh.radius = 0.08
	mist_mesh.height = 0.16
	mist.draw_pass_1 = mist_mesh

	var mist_mat_override = StandardMaterial3D.new()
	mist_mat_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist_mat_override.albedo_color = Color(0.7, 0.85, 1.0, 0.15)
	mist_mat_override.emission_enabled = true
	mist_mat_override.emission = Color(0.5, 0.7, 1.0)
	mist_mat_override.emission_energy_multiplier = 0.3
	mist.material_override = mist_mat_override

	var proc_mat = ParticleProcessMaterial.new()
	proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc_mat.emission_sphere_radius = 1.5
	proc_mat.direction = Vector3(0, 0.1, 0)
	proc_mat.spread = 180.0
	proc_mat.initial_velocity_min = 0.1
	proc_mat.initial_velocity_max = 0.3
	proc_mat.gravity = Vector3(0, -0.1, 0)
	proc_mat.scale_min = 0.5
	proc_mat.scale_max = 1.5
	mist.process_material = proc_mat

	get_tree().current_scene.call_deferred("add_child", mist)

	# Stop emitting after duration, then free
	var tween = mist.create_tween()
	tween.tween_interval(duration - 1.0)
	tween.tween_callback(func(): mist.emitting = false)
	tween.tween_interval(1.5)
	tween.tween_callback(mist.queue_free)
