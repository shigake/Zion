extends Node3D

## Crossbow — tiro unico de alto dano que perfura todos os inimigos na linha.

var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

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

	var level = GameManager.get_weapon_level("crossbow")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("crossbow", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

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

	# Spawn effect
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.6, 0.4, 0.2))
	AudioManager.play_sfx("bow_release")

	var dmg = int(WeaponDB.get_damage("crossbow", level))

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	# Create piercing bolt — does NOT destroy on hit
	var bolt = ObjectPool.get_instance(projectile_scene)
	var pos = player_pos + Vector3(0, 0.5, 0)
	bolt.direction = direction.normalized()
	bolt.damage = dmg
	bolt.speed = 28.0  # Fast bolt
	bolt.lifetime = 3.0
	bolt.damage_type = "physical"

	# Override the default on-hit to pierce instead of destroy
	# Disconnect default signal and reconnect with pierce behavior
	var hit_enemies: Array = []
	bolt.body_entered.connect(func(body: Node3D) -> void:
		if body in hit_enemies:
			return
		if body.has_method("take_damage") and body.is_in_group("enemies"):
			GameManager._last_attacking_weapon = "crossbow"
			body.call_deferred("take_damage", dmg, "physical")
			hit_enemies.append(body)
			ParticleFactory.spawn_hit_particles(body.global_position + Vector3(0, 0.5, 0), Color(0.6, 0.4, 0.2))
	)

	scene_root.add_child(bolt)
	bolt.global_position = pos

## Client-only: spawns visual bolt without collision (no damage).
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

	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.6, 0.4, 0.2))
	AudioManager.play_sfx("bow_release")

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	var proj = projectile_scene.instantiate()
	var pos = player_pos + Vector3(0, 0.5, 0)
	proj.direction = direction.normalized()
	proj.damage = 0
	proj.speed = 28.0
	proj.lifetime = 3.0
	# Disable collision for visual-only projectile
	proj.collision_layer = 0
	proj.collision_mask = 0
	proj.set_deferred("monitorable", false)
	proj.set_deferred("monitoring", false)
	scene_root.add_child(proj)
	proj.global_position = pos
