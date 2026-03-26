extends Node3D

## Arco Elfico — flecha que perfura todos os inimigos e ricocheta uma vez.

var attack_timer: float = 0.0
var arrow_scene: PackedScene = preload("res://scenes/weapons/elven_bow_arrow.tscn")

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("elven_bow")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("elven_bow", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

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

	# Extra arrows at higher levels
	var num_arrows = 1
	if level >= 4:
		num_arrows = 2
	if level >= 7:
		num_arrows = 3

	for i in range(num_arrows):
		var arrow = arrow_scene.instantiate()
		arrow.global_position = player_pos + Vector3(0, 0.5, 0)
		var spread = (randf() - 0.5) * 0.2 * i
		var spread_dir = direction.rotated(Vector3.UP, spread)
		arrow.direction = spread_dir.normalized()
		arrow.damage = int(WeaponDB.get_damage("elven_bow", level))
		arrow.speed = 20.0
		arrow.lifetime = 4.0
		arrow.damage_type = "physical"
		arrow.pierce = true
		arrow.ricochet_distance = 15.0
		get_tree().current_scene.call_deferred("add_child", arrow)

	AudioManager.play_sfx("hit")
