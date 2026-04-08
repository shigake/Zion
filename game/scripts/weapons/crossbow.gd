extends Node3D

## Crossbow — tiro unico de alto dano que perfura todos os inimigos na linha.

var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _ready() -> void:
	# --- 3D Model (priority) ---
	var _model_path = "res://assets/models/crossbow.glb"
	var _model_scene = EnemyBase3D._safe_load_model(_model_path)
	if _model_scene:
		var model: Node3D = _model_scene.instantiate()
		model.name = "WeaponModel"
		model.scale = Vector3(0.25, 0.25, 0.25)
		add_child(model)
	else:
		# Billboard sprite (fallback)
		var _sprite_path = "res://assets/sprites/weapons/crossbow.png"
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
			# Apply pixel art shader
			var _pa = get_node_or_null("/root/PixelArtShader")
			if _pa:
				var _wdata = WeaponDB.get_weapon("crossbow")
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

	var level = GameManager.get_weapon_level("crossbow")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("crossbow", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

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
		# Find nearest enemy
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

	# Spawn effect — brighter muzzle flash
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.8, 0.6, 0.2), 7)
	ParticleFactory.spawn_weapon_sparks(player_pos + Vector3(0, 0.6, 0), Color(0.9, 0.7, 0.3), 3)
	AudioManager.play_sfx("bow_release")
	ScreenEffects.shake(0.04)

	var dmg = int(WeaponDB.get_damage("crossbow", level))

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	# Create piercing bolt — does NOT destroy on hit
	var bolt = ObjectPool.get_instance(projectile_scene)
	if not "direction" in bolt:
		bolt.queue_free()
		return
	var pos = player_pos + Vector3(0, 0.5, 0)
	bolt.direction = direction.normalized()
	bolt.damage = dmg
	bolt.speed = 28.0  # Fast bolt
	bolt.lifetime = 3.0
	bolt.damage_type = "physical"

	# Override the default on-hit to pierce instead of destroy
	# Disconnect default signal and reconnect with pierce behavior
	var hit_enemies: Array = []
	var _on_hit = func(body: Node3D) -> void:
		if body in hit_enemies:
			return
		if body.has_method("take_damage") and body.is_in_group("enemies"):
			GameManager._last_attacking_weapon = "crossbow"
			body.call_deferred("take_damage", dmg, "physical")
			hit_enemies.append(body)
			ParticleFactory.spawn_hit_particles(body.global_position + Vector3(0, 0.5, 0), Color(0.6, 0.4, 0.2))
	bolt.body_entered.connect(_on_hit)
	bolt.area_entered.connect(func(area: Area3D) -> void:
		var parent = area.get_parent()
		if parent and parent is Node3D:
			_on_hit.call(parent)
	)

	scene_root.add_child(bolt)
	bolt.global_position = pos

	# Extra projectiles from Quiver item
	for i in range(GameManager.extra_projectiles):
		var extra = ObjectPool.get_instance(projectile_scene)
		if not "direction" in extra:
			extra.queue_free()
			continue
		var spread_angle = (i + 1) * 0.15 * (1 if i % 2 == 0 else -1)
		extra.direction = direction.rotated(Vector3.UP, spread_angle).normalized()
		extra.damage = dmg
		extra.speed = 28.0
		extra.lifetime = 3.0
		extra.damage_type = "physical"
		var extra_hits: Array = []
		var _on_extra_hit = func(body: Node3D) -> void:
			if body in extra_hits:
				return
			if body.has_method("take_damage") and body.is_in_group("enemies"):
				GameManager._last_attacking_weapon = "crossbow"
				body.call_deferred("take_damage", dmg, "physical")
				extra_hits.append(body)
		extra.body_entered.connect(_on_extra_hit)
		scene_root.add_child(extra)
		extra.global_position = pos

## Client-only: spawns visual bolt without collision (no damage).
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

	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.6, 0.4, 0.2))
	AudioManager.play_sfx("bow_release")

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	var proj = projectile_scene.instantiate()
	var pos = player_pos + Vector3(0, 0.5, 0)
	proj.direction = direction.normalized()
	proj.damage = 0
	proj.speed = 28.0
	proj.lifetime = 3.0
	# Disable collision for visual-only projectile
	proj.collision_layer = 0
	proj.collision_mask = 0
	proj.set_deferred("monitorable", false)
	proj.set_deferred("monitoring", false)
	scene_root.add_child(proj)
	proj.global_position = pos
