extends Node3D

## Metralhadora — spray de projeteis rapidos na direcao do inimigo mais proximo.

var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _ready() -> void:
	# --- 3D Model (priority) ---
	else:
		# Billboard sprite (fallback)
		var mesh = MeshInstance3D.new()
		add_child(mesh)
		var _sprite_path = "res://assets/sprites/weapons/machinegun.png"
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
			# Apply pixel art shader
			var _pa = get_node_or_null("/root/PixelArtShader")
			if _pa:
				var _wdata = WeaponDB.get_weapon("machinegun")
				var _elem = _wdata.get("element", "physical") if _wdata else "physical"
				var _ecols = {"fire": Color(1, 0.5, 0), "ice": Color(0.3, 0.5, 1), "electric": Color(0, 1, 1), "dark": Color(0.5, 0, 1), "poison": Color(0, 1, 0.3)}
				sprite.material_override = _pa.get_enemy_material(sprite.texture, _ecols.get(_elem, Color.WHITE))

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

	var level = GameManager.get_weapon_level("machinegun")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("machinegun", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

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
	# Muzzle flash — brighter, more vibrant
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.15), 6)
	ParticleFactory.spawn_weapon_sparks(player_pos + Vector3(0, 0.6, 0), Color(1.0, 0.9, 0.3), 3)
	AudioManager.play_sfx("gun_shot")
	ScreenEffects.shake(0.02)

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

	# Spread: mais projeteis em levels maiores
	var num_bullets = 1
	if level >= 4:
		num_bullets = 2
	if level >= 7:
		num_bullets = 3

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	for i in range(num_bullets):
		var bullet = ObjectPool.get_instance(projectile_scene)
		if not "direction" in bullet:
			bullet.queue_free()
			continue
		var pos = player_pos + Vector3(0, 0.8, 0)
		# Adiciona spread (reduced by accuracy)
		var spread = (randf() - 0.5) * 0.3 * GameManager.get_accuracy_spread()
		var spread_dir = direction.rotated(Vector3.UP, spread)
		bullet.direction = spread_dir.normalized()
		bullet.damage = int(WeaponDB.get_damage("machinegun", level))
		bullet.speed = 22.0
		bullet.lifetime = 2.0
		bullet.damage_type = "electric"
		bullet.weapon_id = "machinegun"
		scene_root.add_child(bullet)
		bullet.global_position = pos

## Client-only: spawns visual projectile without collision (no damage).
func _fire_visual_only(level: int) -> void:
	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(1.0, 0.8, 0.2))
	AudioManager.play_sfx("gun_shot")

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

	var num_bullets = 1
	if level >= 4:
		num_bullets = 2
	if level >= 7:
		num_bullets = 3

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	for i in range(num_bullets):
		var proj = projectile_scene.instantiate()
		var pos = player_pos + Vector3(0, 0.8, 0)
		var spread = (randf() - 0.5) * 0.3 * GameManager.get_accuracy_spread()
		var spread_dir = direction.rotated(Vector3.UP, spread)
		proj.direction = spread_dir.normalized()
		proj.damage = 0
		proj.speed = 22.0
		proj.lifetime = 2.0
		# Disable collision for visual-only projectile
		proj.collision_layer = 0
		proj.collision_mask = 0
		proj.set_deferred("monitorable", false)
		proj.set_deferred("monitoring", false)
		scene_root.add_child(proj)
		proj.global_position = pos
