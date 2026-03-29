extends Node3D

## Arco Elfico — flecha que perfura todos os inimigos e ricocheta uma vez.

var attack_timer: float = 0.0
var arrow_scene: PackedScene = preload("res://scenes/weapons/elven_bow_arrow.tscn")

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

	var level = GameManager.get_weapon_level("elven_bow")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("elven_bow", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

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

	# Extra arrows at higher levels
	var num_arrows = 1
	if level >= 4:
		num_arrows = 2
	if level >= 7:
		num_arrows = 3

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	for i in range(num_arrows):
		var arrow = ObjectPool.get_instance(arrow_scene)
		var pos = player_pos + Vector3(0, 0.5, 0)
		var spread = (randf() - 0.5) * 0.2 * i
		var spread_dir = direction.rotated(Vector3.UP, spread)
		arrow.direction = spread_dir.normalized()
		arrow.damage = int(WeaponDB.get_damage("elven_bow", level))
		arrow.speed = 20.0
		arrow.lifetime = 4.0
		arrow.damage_type = "physical"
		arrow.pierce = true
		arrow.ricochet_distance = 15.0
		scene_root.add_child(arrow)
		arrow.global_position = pos

	AudioManager.play_sfx("bow_release")

## Client-only: spawns visual arrows without collision (no damage).
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

	var num_arrows = 1
	if level >= 4:
		num_arrows = 2
	if level >= 7:
		num_arrows = 3

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	for i in range(num_arrows):
		var arrow = arrow_scene.instantiate()
		var pos = player_pos + Vector3(0, 0.5, 0)
		var spread = (randf() - 0.5) * 0.2 * i
		var spread_dir = direction.rotated(Vector3.UP, spread)
		arrow.direction = spread_dir.normalized()
		arrow.damage = 0
		arrow.speed = 20.0
		arrow.lifetime = 4.0
		# Disable collision for visual-only projectile
		arrow.collision_layer = 0
		arrow.collision_mask = 0
		arrow.set_deferred("monitorable", false)
		arrow.set_deferred("monitoring", false)
		scene_root.add_child(arrow)
		arrow.global_position = pos

	AudioManager.play_sfx("bow_release")
