extends Node3D

## Shuriken — dispara projeteis em 4 (ou 8) direcoes simultaneamente.

var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

var directions_4: Array[Vector3] = [
	Vector3(0, 0, -1),   # up (north)
	Vector3(0, 0, 1),    # down (south)
	Vector3(-1, 0, 0),   # left (west)
	Vector3(1, 0, 0),    # right (east)
]

var directions_8: Array[Vector3] = [
	Vector3(0, 0, -1),          # up
	Vector3(0, 0, 1),           # down
	Vector3(-1, 0, 0),          # left
	Vector3(1, 0, 0),           # right
	Vector3(-0.707, 0, -0.707), # up-left
	Vector3(0.707, 0, -0.707),  # up-right
	Vector3(-0.707, 0, 0.707),  # down-left
	Vector3(0.707, 0, 0.707),   # down-right
]

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("shuriken")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("shuriken", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		_fire(level)

func _fire(level: int) -> void:
	var player_pos = get_parent().get_parent().global_position

	# At level 4+, fire in 8 directions instead of 4
	var dirs: Array[Vector3] = directions_4 if level < 4 else directions_8

	var dmg = int(WeaponDB.get_damage("shuriken", level))
	var speed = 18.0 + (level - 1) * 1.0

	for dir in dirs:
		var bullet = ObjectPool.get_instance(projectile_scene)
		bullet.global_position = player_pos + Vector3(0, 0.5, 0)
		bullet.direction = dir.normalized()
		bullet.damage = dmg
		bullet.speed = speed
		bullet.lifetime = 2.5
		bullet.damage_type = "ice"
		get_tree().current_scene.call_deferred("add_child", bullet)
