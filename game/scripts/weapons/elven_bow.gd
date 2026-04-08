extends Node3D

## Arco Elfico — flecha que perfura todos os inimigos e ricocheta uma vez.

var attack_timer: float = 0.0
var arrow_scene: PackedScene = preload("res://scenes/weapons/elven_bow_arrow.tscn")

func _ready() -> void:
	# --- 3D Model (priority) ---
	var _model_path = "res://assets/models/elven_bow.glb"
	var _model_scene = EnemyBase3D._safe_load_model(_model_path)
	if _model_scene:
		var model: Node3D = _model_scene.instantiate()
		model.name = "WeaponModel"
		model.scale = Vector3(0.3, 0.3, 0.3)
		add_child(model)
	else:
		# Billboard sprite (fallback)
		var _sprite_path = "res://assets/sprites/weapons/elven_bow.png"
		if ResourceLoader.exists(_sprite_path):
			var sprite = Sprite3D.new()
			sprite.texture = load(_sprite_path)
			sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			sprite.pixel_size = 0.03
			sprite.shaded = false
			sprite.transparent = true
			sprite.name = "WeaponSprite"
			add_child(sprite)

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

	var level = GameManager.get_weapon_level("elven_bow")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("elven_bow", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

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

	# Extra arrows at higher levels + Quiver item bonus
	var num_arrows = 1
	if level >= 4:
		num_arrows = 2
	if level >= 7:
		num_arrows = 3
	num_arrows += GameManager.extra_projectiles

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	for i in range(num_arrows):
		var arrow = ObjectPool.get_instance(arrow_scene)
		if not "direction" in arrow:
			arrow.queue_free()
			continue
		var pos = player_pos + Vector3(0, 0.5, 0)
		var spread = (randf() - 0.5) * 0.2 * i
		var spread_dir = direction.rotated(Vector3.UP, spread)
		arrow.direction = spread_dir.normalized()
		arrow.damage = int(WeaponDB.get_damage("elven_bow", level))
		arrow.speed = 20.0
		arrow.lifetime = 4.0
		arrow.damage_type = "physical"
		arrow.pierce = true
		arrow.ricochet_distance = 15.0
		scene_root.add_child(arrow)
		arrow.global_position = pos

	AudioManager.play_sfx("bow_release")
	# Elven bow release flash — green nature energy
	var player = _get_player_node()
	if player:
		ParticleFactory.spawn_weapon_sparks(player.global_position + Vector3(0, 0.6, 0), Color(0.3, 0.9, 0.4), 4)
		ScreenEffects.shake(0.03)

## Client-only: spawns visual arrows without collision (no damage).
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

	var num_arrows = 1
	if level >= 4:
		num_arrows = 2
	if level >= 7:
		num_arrows = 3

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	for i in range(num_arrows):
		var arrow = arrow_scene.instantiate()
		var pos = player_pos + Vector3(0, 0.5, 0)
		var spread = (randf() - 0.5) * 0.2 * i
		var spread_dir = direction.rotated(Vector3.UP, spread)
		arrow.direction = spread_dir.normalized()
		arrow.damage = 0
		arrow.speed = 20.0
		arrow.lifetime = 4.0
		# Disable collision for visual-only projectile
		arrow.collision_layer = 0
		arrow.collision_mask = 0
		arrow.set_deferred("monitorable", false)
		arrow.set_deferred("monitoring", false)
		scene_root.add_child(arrow)
		arrow.global_position = pos

	AudioManager.play_sfx("bow_release")
