extends Node3D

## Crossbow — tiro unico de alto dano que perfura todos os inimigos na linha.

var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

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

	# Spawn effect
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.6, 0.4, 0.2))
	AudioManager.play_sfx("hit")

	var dmg = int(WeaponDB.get_damage("crossbow", level))

	# Create piercing bolt — does NOT destroy on hit
	var bolt = ObjectPool.get_instance(projectile_scene)
	bolt.global_position = player_pos + Vector3(0, 0.5, 0)
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
			body.call_deferred("take_damage", dmg, "physical")
			hit_enemies.append(body)
			ParticleFactory.spawn_hit_particles(body.global_position + Vector3(0, 0.5, 0), Color(0.6, 0.4, 0.2))
	)

	get_tree().current_scene.call_deferred("add_child", bolt)
