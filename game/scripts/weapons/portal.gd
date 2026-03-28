extends Node3D

## Portal — cria dois portais, teleportando inimigos para longe do jogador.

var attack_timer: float = 0.0
var active_portal: Node3D = null

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("portal")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("portal", level) / GameManager.attack_speed_mult

	# Clean up freed portal
	if active_portal and not is_instance_valid(active_portal):
		active_portal = null

	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		if active_portal == null:
			_create_portal(level)

func _create_portal(level: int) -> void:
	var enemies = GameManager.get_enemies()
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

	var portal = Node3D.new()
	portal.set_script(preload("res://scripts/weapons/portal_behavior.gd"))
	portal.entry_position = nearest.global_position
	portal.player_position = player_pos
	portal.portal_lifetime = 5.0 + (level - 1) * 0.5
	portal.teleport_distance = 20.0 + (level - 1) * 2.0
	portal.portal_radius = 2.0 + (level - 1) * 0.2

	get_tree().current_scene.call_deferred("add_child", portal)
	active_portal = portal
	AudioManager.play_sfx("hit")
