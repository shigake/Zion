extends Node3D

## Staff Magico — dispara projeteis homing que perseguem inimigos.

var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/staff_projectile.tscn")

func _ready() -> void:
	# Billboard sprite
	var mesh = MeshInstance3D.new()
	add_child(mesh)
	var _sprite_path = "res://assets/sprites/weapons/staff.png"
	if ResourceLoader.exists(_sprite_path):
		mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.03
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "WeaponSprite"
		mesh.get_parent().add_child(sprite)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("staff")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("staff", level) / GameManager.attack_speed_mult

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

	var player_node = get_parent().get_parent() if get_parent() != null else null
	if not is_instance_valid(player_node):
		return

	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player_pos = player_node.global_position  # WeaponPivot -> Player

	# Numero de projeteis: +1 nos levels 3 e 6
	var num_projectiles = 1
	if level >= 3:
		num_projectiles = 2
	if level >= 6:
		num_projectiles = 3

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	AudioManager.play_sfx("magic_cast")

	if GameManager.manual_aim:
		# Manual aim: fire straight projectiles (no homing)
		for i in range(num_projectiles):
			var proj = ObjectPool.get_instance(projectile_scene)
			var pos = player_pos + Vector3(0, 0.5, 0)
			proj.target = null  # No homing target
			proj.direction = GameManager.aim_direction
			var spread = (randf() - 0.5) * 0.2 * i
			proj.direction = proj.direction.rotated(Vector3.UP, spread).normalized()
			proj.damage = int(WeaponDB.get_damage("staff", level))
			scene_root.add_child(proj)
			proj.global_position = pos
	else:
		# Auto-aim: homing projectiles
		var targets = _get_nearest_enemies(player_pos, num_projectiles)
		for t in targets:
			if not is_instance_valid(t):
				continue
			var proj = ObjectPool.get_instance(projectile_scene)
			var pos = player_pos + Vector3(0, 0.5, 0)
			proj.target = t
			proj.damage = int(WeaponDB.get_damage("staff", level))
			scene_root.add_child(proj)
			proj.global_position = pos

## Client-only: spawns visual projectile without collision (no damage).
func _fire_visual_only(level: int) -> void:
	var player_node = get_parent().get_parent() if get_parent() != null else null
	if not is_instance_valid(player_node):
		return

	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player_pos = player_node.global_position

	var num_projectiles = 1
	if level >= 3:
		num_projectiles = 2
	if level >= 6:
		num_projectiles = 3

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	if GameManager.manual_aim:
		for i in range(num_projectiles):
			var proj = ObjectPool.get_instance(projectile_scene)
			var pos = player_pos + Vector3(0, 0.5, 0)
			proj.target = null
			proj.direction = GameManager.aim_direction
			var spread = (randf() - 0.5) * 0.2 * i
			proj.direction = proj.direction.rotated(Vector3.UP, spread).normalized()
			proj.damage = 0
			proj.collision_layer = 0
			proj.collision_mask = 0
			proj.set_deferred("monitorable", false)
			proj.set_deferred("monitoring", false)
			scene_root.add_child(proj)
			proj.global_position = pos
	else:
		var targets = _get_nearest_enemies(player_pos, num_projectiles)
		for t in targets:
			if not is_instance_valid(t):
				continue
			var proj = ObjectPool.get_instance(projectile_scene)
			var pos = player_pos + Vector3(0, 0.5, 0)
			proj.target = t
			proj.damage = 0
			proj.collision_layer = 0
			proj.collision_mask = 0
			proj.set_deferred("monitorable", false)
			proj.set_deferred("monitoring", false)
			scene_root.add_child(proj)
			proj.global_position = pos

func _get_nearest_enemies(from: Vector3, count: int) -> Array:
	var enemies = GameManager.get_enemies()
	var sorted: Array = []
	for e in enemies:
		if is_instance_valid(e):
			sorted.append({"node": e, "dist": from.distance_squared_to(e.global_position)})
	sorted.sort_custom(func(a, b): return a["dist"] < b["dist"])
	var result: Array = []
	for i in range(mini(count, sorted.size())):
		result.append(sorted[i]["node"])
	return result
