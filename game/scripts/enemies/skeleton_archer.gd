extends EnemyBase3D

## Skeleton Archer - ranged enemy that stops and fires projectiles at the player.

var shoot_timer: float = 0.0
var shoot_cooldown: float = 2.0
var projectile_speed: float = 10.0
var attack_range: float = 12.0

var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

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

		# Stop moving when within attack range
		if dist > attack_range:
			var direction = (target.global_position - global_position).normalized()
			direction.y = 0
			velocity = direction * speed
			move_and_slide()
		else:
			velocity = Vector3.ZERO
			move_and_slide()

		# Fire projectile on cooldown
		shoot_timer += delta
		if shoot_timer >= shoot_cooldown and dist <= attack_range:
			_fire_projectile()
			shoot_timer = 0.0

func _fire_projectile() -> void:
	if not target or not is_instance_valid(target):
		return
	if not is_inside_tree():
		return

	var spawn_pos = global_position + Vector3(0, 0.5, 0)
	var target_pos = target.global_position + Vector3(0, 0.5, 0)
	var dir = (target_pos - spawn_pos).normalized()

	var bullet = bullet_scene.instantiate()
	bullet.position = spawn_pos
	bullet.direction = dir
	bullet.speed = projectile_speed
	bullet.damage = damage

	# Override collision so bullet hits players instead of enemies
	bullet.collision_layer = 4
	bullet.collision_mask = 1

	get_tree().current_scene.call_deferred("add_child", bullet)
