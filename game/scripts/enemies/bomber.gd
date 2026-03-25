extends EnemyBase3D

## Bomber - fast enemy that rushes toward the player and explodes on contact.

var explode_range: float = 1.5
var explosion_radius: float = 3.0
var has_exploded: bool = false

func _physics_process(delta: float) -> void:
	if is_dead or GameManager.paused:
		return

	# Knockback decay
	if knockback_velocity.length() > 0.1:
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, 8.0 * delta)
		velocity = knockback_velocity
		move_and_slide()
		return

	_find_target()
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)

		# Explode when close enough
		if dist <= explode_range:
			_explode()
			return

		# Rush toward player
		var direction = (target.global_position - global_position).normalized()
		direction.y = 0
		velocity = direction * speed
		move_and_slide()

func _explode() -> void:
	if has_exploded:
		return
	has_exploded = true

	# Deal damage to all players in explosion radius
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if not is_instance_valid(player):
			continue
		var dist = global_position.distance_to(player.global_position)
		if dist <= explosion_radius and player.has_method("take_damage"):
			player.take_damage(damage)

	# Spawn explosion particles
	ParticleFactory.spawn_explosion_particles(global_position + Vector3(0, 0.3, 0))

	# Screen shake for explosion
	ScreenEffects.shake(0.1)

	queue_free()
