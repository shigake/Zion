extends Node3D

## Cajado de Gelo — projetil lento que congela inimigos em area ao impactar.

var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _process(delta: float) -> void:
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
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var player_pos = get_parent().get_parent().global_position

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

	var direction = (nearest.global_position - player_pos).normalized()
	direction.y = 0

	# Ice particles at spawn
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.3, 0.7, 1.0))
	AudioManager.play_sfx("hit")

	var dmg = int(WeaponDB.get_damage("ice_staff", level))

	# Create ice projectile — uses bullet scene but with custom on-hit
	var bullet = projectile_scene.instantiate()
	bullet.global_position = player_pos + Vector3(0, 0.5, 0)
	bullet.direction = direction.normalized()
	bullet.damage = dmg
	bullet.speed = 10.0  # Slow projectile
	bullet.lifetime = 4.0
	bullet.damage_type = "ice"

	# Override behavior: on hit, freeze area
	bullet.body_entered.connect(func(body: Node3D) -> void:
		if body.has_method("take_damage") and body.is_in_group("enemies"):
			body.call_deferred("take_damage", dmg, "ice")
			_freeze_area(bullet.global_position, level)
			bullet.queue_free()
	, CONNECT_ONE_SHOT)

	get_tree().current_scene.call_deferred("add_child", bullet)

func _freeze_area(pos: Vector3, level: int) -> void:
	var freeze_radius = 3.0 + (level - 1) * 0.3
	var freeze_duration = 2.0 + (level - 1) * 0.15
	var dmg = int(WeaponDB.get_damage("ice_staff", level) * 0.5)

	# Ice explosion particles
	ParticleFactory.spawn_hit_particles(pos, Color(0.4, 0.8, 1.0))

	# Find all enemies in radius and slow them
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var dist = pos.distance_to(e.global_position)
		if dist <= freeze_radius:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", dmg, "ice")
			# Apply slow effect if enemy supports it
			if e.has_method("apply_slow"):
				e.call_deferred("apply_slow", 0.4, freeze_duration)
