extends Node3D

## Pistola Dupla — tiros alternados rapidos (esquerda-direita) no inimigo mais proximo.

var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")
var alternate_side: bool = false  # Alterna esquerda/direita

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("dual_pistol")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("dual_pistol", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		_fire(level)

func _fire(level: int) -> void:
	if not is_inside_tree():
		return
	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player_pos = get_parent().get_parent().global_position

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

	# Offset left/right alternating
	var side_offset = 0.4 if alternate_side else -0.4
	alternate_side = not alternate_side
	var right = direction.cross(Vector3.UP).normalized()
	var spawn_pos = player_pos + Vector3(0, 0.5, 0) + right * side_offset

	# Muzzle flash
	ParticleFactory.spawn_hit_particles(spawn_pos, Color(1.0, 0.9, 0.3))
	AudioManager.play_sfx("hit")

	var dmg = int(WeaponDB.get_damage("dual_pistol", level))

	var bullet = ObjectPool.get_instance(projectile_scene)
	bullet.global_position = spawn_pos
	# Small spread
	var spread = (randf() - 0.5) * 0.15
	var spread_dir = direction.rotated(Vector3.UP, spread)
	bullet.direction = spread_dir.normalized()
	bullet.damage = dmg
	bullet.speed = 24.0
	bullet.lifetime = 2.0
	bullet.damage_type = "physical"
	get_tree().current_scene.call_deferred("add_child", bullet)
