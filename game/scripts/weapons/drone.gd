extends Node3D

## Drone — orbita o jogador e dispara projeteis no inimigo mais proximo.

@export var orbit_radius: float = 2.0
@export var rotation_speed: float = 4.0

var angle: float = 0.0
var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

@onready var drone_area: Area3D = $DroneArea
@onready var drone_mesh: MeshInstance3D = $DroneMesh

func _ready() -> void:
	# Billboard sprite
	var _sprite_path = "res://assets/sprites/weapons/drone.png"
	if ResourceLoader.exists(_sprite_path):
		drone_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.03
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "WeaponSprite"
		drone_mesh.get_parent().add_child(sprite)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("drone")
	if level <= 0:
		return

	# Orbit around player
	var speed = rotation_speed + (level - 1) * 0.2
	angle += speed * delta

	var radius = orbit_radius + (level - 1) * 0.1
	var pos = Vector3(cos(angle) * radius, 0.8, sin(angle) * radius)
	drone_area.position = pos
	drone_mesh.position = pos
	drone_area.rotation.y = angle

	# Fire at nearest enemy
	var cooldown = WeaponDB.get_cooldown("drone", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult
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

	var drone_global_pos = drone_mesh.global_position

	var direction: Vector3
	if GameManager.manual_aim:
		direction = GameManager.aim_direction
	else:
		var nearest: Node3D = null
		var min_dist = INF
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var d = drone_global_pos.distance_squared_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e

		if nearest == null:
			return

		direction = (nearest.global_position - drone_global_pos).normalized()
		direction.y = 0

	# More bullets at higher levels
	var num_bullets = 1
	if level >= 5:
		num_bullets = 2
	if level >= 8:
		num_bullets = 3

	for i in range(num_bullets):
		var bullet = ObjectPool.get_instance(projectile_scene)
		bullet.global_position = drone_global_pos
		var spread = (randf() - 0.5) * 0.15
		var spread_dir = direction.rotated(Vector3.UP, spread)
		bullet.direction = spread_dir.normalized()
		bullet.damage = int(WeaponDB.get_damage("drone", level))
		bullet.speed = 20.0
		bullet.lifetime = 2.5
		bullet.damage_type = "electric"
		get_tree().current_scene.call_deferred("add_child", bullet)

	AudioManager.play_sfx("hit")
	ParticleFactory.spawn_hit_particles(drone_global_pos, Color(0.3, 0.7, 1.0))

## Client-only: spawns visual projectiles without collision (no damage).
func _fire_visual_only(level: int) -> void:
	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var drone_global_pos = drone_mesh.global_position

	var direction: Vector3
	if GameManager.manual_aim:
		direction = GameManager.aim_direction
	else:
		var nearest: Node3D = null
		var min_dist = INF
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var d = drone_global_pos.distance_squared_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e
		if nearest == null:
			return
		direction = (nearest.global_position - drone_global_pos).normalized()
		direction.y = 0

	var num_bullets = 1
	if level >= 5:
		num_bullets = 2
	if level >= 8:
		num_bullets = 3

	for i in range(num_bullets):
		var proj = projectile_scene.instantiate()
		proj.global_position = drone_global_pos
		var spread = (randf() - 0.5) * 0.15
		var spread_dir = direction.rotated(Vector3.UP, spread)
		proj.direction = spread_dir.normalized()
		proj.damage = 0
		proj.speed = 20.0
		proj.lifetime = 2.5
		# Disable collision for visual-only projectile
		proj.collision_layer = 0
		proj.collision_mask = 0
		proj.set_deferred("monitorable", false)
		proj.set_deferred("monitoring", false)
		get_tree().current_scene.call_deferred("add_child", proj)

	AudioManager.play_sfx("hit")
	ParticleFactory.spawn_hit_particles(drone_global_pos, Color(0.3, 0.7, 1.0))
