extends Node3D

## Metralhadora — spray de projeteis rapidos na direcao do inimigo mais proximo.

var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("machinegun")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("machinegun", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		_fire(level)

func _fire(level: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var player_pos = get_parent().get_parent().global_position
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

	# Spread: mais projeteis em levels maiores
	var num_bullets = 1
	if level >= 4:
		num_bullets = 2
	if level >= 7:
		num_bullets = 3

	for i in range(num_bullets):
		var bullet = projectile_scene.instantiate()
		bullet.global_position = player_pos + Vector3(0, 0.5, 0)
		# Adiciona spread
		var spread = (randf() - 0.5) * 0.3
		var spread_dir = direction.rotated(Vector3.UP, spread)
		bullet.direction = spread_dir.normalized()
		bullet.damage = int(WeaponDB.get_damage("machinegun", level))
		bullet.speed = 22.0
		bullet.lifetime = 2.0
		get_tree().current_scene.call_deferred("add_child", bullet)
