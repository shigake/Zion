extends Node3D

## Bazuca — dispara um projetil que explode em area.

var attack_timer: float = 0.0
var rocket_scene: PackedScene = preload("res://scenes/weapons/rocket.tscn")

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("bazooka")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("bazooka", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		_fire(level)

func _fire(level: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	# Mira no cluster mais denso de inimigos
	var player_pos = get_parent().get_parent().global_position
	var best_target: Vector3 = enemies[0].global_position
	var best_count: int = 0

	for e in enemies:
		if not is_instance_valid(e):
			continue
		var count = 0
		for e2 in enemies:
			if is_instance_valid(e2) and e.global_position.distance_to(e2.global_position) < 4.0:
				count += 1
		if count > best_count:
			best_count = count
			best_target = e.global_position

	var rocket = ObjectPool.get_instance(rocket_scene)
	rocket.global_position = player_pos + Vector3(0, 0.5, 0)
	rocket.target_pos = best_target
	rocket.damage = int(WeaponDB.get_damage("bazooka", level))
	rocket.explosion_radius = 3.0 + (level - 1) * 0.4
	rocket.explosion_radius *= GameManager.area_mult
	get_tree().current_scene.call_deferred("add_child", rocket)
