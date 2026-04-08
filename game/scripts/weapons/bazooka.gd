extends Node3D

## Bazuca — dispara um projetil que explode em area.

var attack_timer: float = 0.0
var rocket_scene: PackedScene = preload("res://scenes/weapons/rocket.tscn")

func _ready() -> void:
	# --- 3D Model (priority) ---
	var _model_path = "res://assets/models/bazooka.glb"
	var _model_scene = EnemyBase3D._safe_load_model(_model_path)
	if _model_scene:
		var model: Node3D = _model_scene.instantiate()
		model.name = "WeaponModel"
		model.scale = Vector3(0.3, 0.3, 0.3)
		add_child(model)
	else:
		# Billboard sprite (fallback)
		var _sprite_path = "res://assets/sprites/weapons/bazooka.png"
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

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("bazooka")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("bazooka", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

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

	var player_pos = player_node.global_position
	var best_target: Vector3

	if GameManager.manual_aim:
		# Fire in aim direction, target a point 12 units away
		best_target = player_pos + GameManager.aim_direction * 12.0
	else:
		# Mira no cluster mais denso de inimigos (sampled for performance)
		var found_initial := false
		for e in enemies:
			if is_instance_valid(e):
				best_target = e.global_position
				found_initial = true
				break
		if not found_initial:
			return

		var best_count: int = 0
		# Sample up to 20 enemies instead of checking all (O(n*20) instead of O(n²))
		var sample_count = mini(enemies.size(), 20)
		var step = maxi(1, enemies.size() / sample_count)
		var idx := 0
		while idx < enemies.size():
			var e = enemies[idx]
			idx += step
			if not is_instance_valid(e):
				continue
			# Use spatial grid for neighbor count instead of iterating all enemies
			var nearby = GameManager.get_enemies_in_radius(e.global_position, 4.0)
			var count = nearby.size()
			if count > best_count:
				best_count = count
				best_target = e.global_position

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	var dmg = int(WeaponDB.get_damage("bazooka", level))
	var radius = (3.0 + (level - 1) * 0.4) * GameManager.area_mult
	var num_rockets = 1 + GameManager.extra_projectiles

	# Launch flash and smoke
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(1.0, 0.6, 0.1), 8)
	ScreenEffects.shake(0.08)
	for i in range(num_rockets):
		var rocket = ObjectPool.get_instance(rocket_scene)
		var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)) * i * 0.5
		rocket.target_pos = best_target + offset
		rocket.damage = dmg
		rocket.explosion_radius = radius
		scene_root.add_child(rocket)
		rocket.global_position = player_pos + Vector3(0, 0.5, 0)
		rocket.initialize()

## Client-only: spawns visual rocket without collision (no damage/explosion).
func _fire_visual_only(level: int) -> void:
	var player_node = get_parent().get_parent() if get_parent() != null else null
	if not is_instance_valid(player_node):
		return

	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player_pos = player_node.global_position
	var best_target: Vector3

	if GameManager.manual_aim:
		best_target = player_pos + GameManager.aim_direction * 12.0
	else:
		var found_initial := false
		for e in enemies:
			if is_instance_valid(e):
				best_target = e.global_position
				found_initial = true
				break
		if not found_initial:
			return

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	var rocket = rocket_scene.instantiate()
	rocket.target_pos = best_target
	rocket.damage = 0
	rocket.explosion_radius = 0.0
	# Disable collision for visual-only projectile
	rocket.collision_layer = 0
	rocket.collision_mask = 0
	rocket.set_deferred("monitorable", false)
	rocket.set_deferred("monitoring", false)
	scene_root.add_child(rocket)
	rocket.global_position = player_pos + Vector3(0, 0.5, 0)
	rocket.initialize()
