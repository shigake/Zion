extends Node3D

## Boomerang — dispara projetil que vai e volta, perfurando inimigos no caminho.

var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("boomerang")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("boomerang", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		_fire(level)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _fire(level: int) -> void:
	if not is_inside_tree():
		return

	# In multiplayer, only host fires real projectiles
	if MultiplayerManager.is_online and not multiplayer.is_server():
		return

	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	# Find nearest enemy for aim direction
	var aim_dir := Vector3.FORWARD
	if GameManager.manual_aim:
		aim_dir = GameManager.aim_direction
	else:
		var enemies = GameManager.get_enemies()
		var min_dist = INF
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var d = player_pos.distance_squared_to(e.global_position)
			if d < min_dist:
				min_dist = d
				aim_dir = (e.global_position - player_pos).normalized()
				aim_dir.y = 0
	if aim_dir.length_squared() < 0.01:
		aim_dir = Vector3.FORWARD

	var dmg = int(WeaponDB.get_damage("boomerang", level))
	var speed = WeaponDB.get_weapon("boomerang").get("base_speed", 15.0) + (level - 1) * 1.0
	var max_distance = 15.0 + level * 1.0

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	var bullet = ObjectPool.get_instance(projectile_scene)
	var pos = player_pos + Vector3(0, 0.5, 0)
	bullet.direction = aim_dir.normalized()
	bullet.damage = dmg
	bullet.speed = speed
	bullet.lifetime = 10.0  # Long lifetime; return logic handles removal
	bullet.damage_type = "physical"
	bullet.weapon_id = "boomerang"
	# Attach boomerang behavior script
	_attach_boomerang_behavior(bullet, player, max_distance, speed)
	_apply_boomerang_visual(bullet)
	scene_root.add_child(bullet)
	bullet.global_position = pos

func _attach_boomerang_behavior(bullet: Node, player: Node3D, max_dist: float, spd: float) -> void:
	# Remove existing boomerang meta if reused from pool
	if bullet.has_meta("boomerang_data"):
		bullet.remove_meta("boomerang_data")

	var data = {
		"going_out": true,
		"start_pos": bullet.position,
		"max_distance": max_dist,
		"speed": spd,
		"player": player,
		"original_direction": bullet.direction,
	}
	bullet.set_meta("boomerang_data", data)

	# Override _physics_process via a child node
	var existing_ctrl = bullet.get_node_or_null("BoomerangCtrl")
	if existing_ctrl:
		existing_ctrl.queue_free()

	var ctrl = Node.new()
	ctrl.name = "BoomerangCtrl"
	ctrl.set_script(_boomerang_ctrl_script)
	bullet.add_child(ctrl)

func _apply_boomerang_visual(bullet: Node) -> void:
	# Billboard sprite
	var sprite_path = "res://assets/sprites/weapons/boomerang.png"
	var existing_mesh = bullet.get_node_or_null("Mesh")
	if not existing_mesh:
		existing_mesh = bullet.get_node_or_null("MeshInstance3D")
	if existing_mesh:
		existing_mesh.visible = false

	# Check if already has sprite (reused from pool)
	var existing_sprite = bullet.get_node_or_null("BoomerangSprite")
	if existing_sprite:
		existing_sprite.visible = true
		return

	var sprite = Sprite3D.new()
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = 0.03
	sprite.shaded = false
	sprite.transparent = true
	sprite.name = "BoomerangSprite"
	bullet.add_child(sprite)

# Inline boomerang control script
var _boomerang_ctrl_script: GDScript = null

func _init() -> void:
	_boomerang_ctrl_script = GDScript.new()
	_boomerang_ctrl_script.source_code = """extends Node

func _physics_process(delta: float) -> void:
	var bullet = get_parent()
	if not bullet or not is_instance_valid(bullet):
		return
	if not bullet.is_inside_tree():
		return
	if not bullet.has_meta("boomerang_data"):
		return

	var data = bullet.get_meta("boomerang_data")
	var player = data["player"]
	if not is_instance_valid(player):
		bullet.queue_free()
		return

	if data["going_out"]:
		# Flying outward with slight arc
		var traveled = bullet.global_position.distance_to(data["start_pos"])
		var arc_t = traveled / data["max_distance"]
		var arc_offset = sin(arc_t * PI) * 2.0
		var right_dir = data["original_direction"].cross(Vector3.UP).normalized()
		bullet.global_position += right_dir * arc_offset * delta
		if traveled >= data["max_distance"]:
			data["going_out"] = false
			bullet.set_meta("boomerang_data", data)
	else:
		# Returning to player
		var to_player = (player.global_position + Vector3(0, 0.5, 0) - bullet.global_position).normalized()
		bullet.direction = to_player
		bullet.global_position += to_player * data["speed"] * delta
		# Override bullet's own movement by zeroing its speed temporarily
		bullet.speed = 0.0

		# Check if close enough to player to despawn
		if bullet.global_position.distance_to(player.global_position + Vector3(0, 0.5, 0)) < 1.0:
			bullet.queue_free()
			return

	# Spin visual
	var sprite = bullet.get_node_or_null("BoomerangSprite")
	if sprite:
		sprite.rotation.y += 15.0 * delta
"""
	_boomerang_ctrl_script.reload()
