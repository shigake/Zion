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

	AudioManager.play_sfx("boomerang")

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	var pos = player_pos + Vector3(0, 0.5, 0)
	var num_boomerangs = 1 + GameManager.extra_projectiles

	for i in range(num_boomerangs):
		var bullet = ObjectPool.get_instance(projectile_scene)
		if not "direction" in bullet:
			bullet.queue_free()
			continue
		var spread_angle = i * 0.25 * (1 if i % 2 == 0 else -1)
		bullet.direction = aim_dir.rotated(Vector3.UP, spread_angle).normalized()
		bullet.damage = dmg
		bullet.speed = speed
		bullet.lifetime = 10.0
		bullet.damage_type = WeaponDB.get_element("boomerang")
		bullet.weapon_id = "boomerang"
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
	var existing_mesh = bullet.get_node_or_null("Mesh")
	if not existing_mesh:
		existing_mesh = bullet.get_node_or_null("MeshInstance3D")
	if existing_mesh:
		existing_mesh.visible = false

	# --- 3D Model (priority) ---
	var _model_path = "res://assets/models/boomerang.glb"
	var _model_scene = EnemyBase3D._safe_load_model(_model_path)
	if _model_scene:
		# Check if already has model (reused from pool)
		var existing_model = bullet.get_node_or_null("BoomerangModel")
		if existing_model:
			existing_model.visible = true
			return
		var model: Node3D = _model_scene.instantiate()
		model.name = "BoomerangModel"
		model.scale = Vector3(0.25, 0.25, 0.25)
		bullet.add_child(model)
	else:
		# Billboard sprite (fallback)
		var sprite_path = "res://assets/sprites/weapons/boomerang.png"
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
			# Visual burst when reversing direction
			if Engine.get_frames_per_second() > 30:
				var scene2 = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
				if scene2:
					for k in range(5):
						var burst = MeshInstance3D.new()
						var bs = SphereMesh.new()
						bs.radius = 0.035
						bs.height = 0.07
						var bm = StandardMaterial3D.new()
						bm.albedo_color = Color(1.0, 0.9, 0.3, 0.7)
						bm.emission_enabled = true
						bm.emission = Color(1.0, 0.85, 0.4)
						bm.emission_energy_multiplier = 6.0
						bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
						bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
						bs.surface_set_material(0, bm)
						burst.mesh = bs
						scene2.add_child(burst)
						burst.global_position = bullet.global_position
						var bdir = Vector3(randf_range(-1, 1), randf_range(0, 0.5), randf_range(-1, 1)).normalized()
						var btw = burst.create_tween()
						btw.set_parallel(true)
						btw.tween_property(burst, "global_position", bullet.global_position + bdir * 0.6, 0.3)
						btw.tween_property(burst, "scale", Vector3(0.01, 0.01, 0.01), 0.3)
						btw.chain().tween_callback(burst.queue_free)
	else:
		# Returning to player — accelerates as it gets closer
		var to_player = (player.global_position + Vector3(0, 0.5, 0) - bullet.global_position).normalized()
		var dist_to_player = bullet.global_position.distance_to(player.global_position + Vector3(0, 0.5, 0))
		var return_speed = data["speed"] * (1.0 + (1.0 / max(dist_to_player, 0.5)) * 2.0)
		bullet.direction = to_player
		bullet.global_position += to_player * return_speed * delta
		bullet.speed = 0.0

		if dist_to_player < 1.0:
			bullet.queue_free()
			return

	# Spin visual — faster on return
	var spin_speed = 15.0 if data["going_out"] else 25.0
	var sprite = bullet.get_node_or_null("BoomerangSprite")
	if sprite:
		sprite.rotation.y += spin_speed * delta
		# Afterimage glow: phase-based brightness + spin glow on return
		var spin_glow = 0.8 + sin(bullet.get_meta("boomerang_data")["speed"] * 0.5 + Engine.get_process_frames() * 0.15) * 0.2
		if not data["going_out"]:
			sprite.modulate = Color(1.2, 1.1, spin_glow)
		else:
			sprite.modulate = Color(1.0, 1.0, spin_glow, 1.0)
	var model3d = bullet.get_node_or_null("BoomerangModel")
	if model3d:
		model3d.rotation.y += spin_speed * delta

	# Trail particle (every 3 frames — denser trail)
	if Engine.get_process_frames() % 3 == 0 and Engine.get_frames_per_second() > 35:
		var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
		if scene:
			var trail = MeshInstance3D.new()
			var s = SphereMesh.new()
			s.radius = 0.03
			s.height = 0.06
			var m = StandardMaterial3D.new()
			var trail_color = Color(0.9, 0.8, 0.4, 0.6) if data["going_out"] else Color(1.0, 0.6, 0.2, 0.7)
			m.albedo_color = trail_color
			m.emission_enabled = true
			m.emission = Color(trail_color.r, trail_color.g, trail_color.b)
			m.emission_energy_multiplier = 5.0
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			s.surface_set_material(0, m)
			trail.mesh = s
			scene.add_child(trail)
			trail.global_position = bullet.global_position
			var fade_time = 0.3 if data["going_out"] else 0.2
			var tw = trail.create_tween()
			tw.tween_property(trail, "scale", Vector3(0.01, 0.01, 0.01), fade_time)
			tw.tween_callback(trail.queue_free)
"""
	_boomerang_ctrl_script.reload()
