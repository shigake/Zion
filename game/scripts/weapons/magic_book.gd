extends Node3D

## Livro Magico — orbita o jogador, causa dano de contato e dispara paginas.

@export var orbit_radius: float = 1.5
@export var rotation_speed: float = 3.0
@export var hit_cooldown: float = 0.3

var angle: float = 0.0
var hit_timers: Dictionary = {}
var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

@onready var book_area: Area3D = $BookArea
@onready var book_mesh: MeshInstance3D = $BookMesh

func _ready() -> void:
	book_area.body_entered.connect(_on_body_entered)
	# 3D model (preferred) or billboard sprite fallback
	var _model_path = "res://assets/models/magic_book.glb"
	var _model_scene = EnemyBase3D._safe_load_model(_model_path)
	if _model_scene:
		var model = _model_scene.instantiate()
		model.name = "WeaponModel"
		model.scale = Vector3(0.25, 0.25, 0.25)
		book_area.add_child(model)
	else:
		var _sprite_path = "res://assets/sprites/weapons/magic_book.png"
		if ResourceLoader.exists(_sprite_path):
			book_mesh.visible = false
			var sprite = Sprite3D.new()
			sprite.texture = load(_sprite_path)
			sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			sprite.pixel_size = 0.05
			sprite.shaded = false
			sprite.transparent = true
			sprite.name = "WeaponSprite"
			sprite.render_priority = 1  # Render on top of player
			add_child(sprite)
			# Apply pixel art shader
			var _pa = get_node_or_null("/root/PixelArtShader")
			if _pa:
				var _wdata = WeaponDB.get_weapon("magic_book")
				var _elem = _wdata.get("element", "physical") if _wdata else "physical"
				var _ecols = {"fire": Color(1, 0.5, 0), "ice": Color(0.3, 0.5, 1), "electric": Color(0, 1, 1), "dark": Color(0.5, 0, 1), "poison": Color(0, 1, 0.3)}
				sprite.material_override = _pa.get_enemy_material(sprite.texture, _ecols.get(_elem, Color.WHITE))
			# Sprite segue a posicao do book_mesh no _process
			sprite.set_meta("follows_book", true)
	_setup_billboard_sprite()

func _setup_billboard_sprite() -> void:
	var sprite_path = "res://assets/sprites/projectiles/magic_orb.png"
	if ResourceLoader.exists(sprite_path):
		var existing_mesh = book_mesh.get_node_or_null("Mesh")
		if not existing_mesh:
			existing_mesh = book_mesh.get_node_or_null("MeshInstance3D")
		if existing_mesh:
			existing_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.04
		sprite.shaded = false
		sprite.transparent = true
		sprite.render_priority = 1
		sprite.name = "ProjectileSprite"
		book_mesh.add_child(sprite)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("magic_book")
	if level <= 0:
		return

	# Orbit rotation
	var speed = rotation_speed + (level - 1) * 0.2
	angle += speed * delta

	var radius = orbit_radius + (level - 1) * 0.1
	var pos = Vector3(cos(angle) * radius, 0.5, sin(angle) * radius)
	book_area.position = pos
	book_mesh.position = pos
	# Atualiza sprite que segue o livro (float above player for visibility)
	var ws = get_node_or_null("WeaponSprite")
	if ws:
		ws.position = Vector3(pos.x, maxf(pos.y, 0.8), pos.z)
	book_area.rotation.y = angle + PI / 2
	book_mesh.rotation.y = angle + PI / 2

	# Scale with area_mult
	var s = GameManager.area_mult
	book_mesh.scale = Vector3(s, s, s)

	# Decrement hit timers
	var to_remove: Array = []
	for key in hit_timers:
		hit_timers[key] -= delta
		if hit_timers[key] <= 0:
			to_remove.append(key)
	for key in to_remove:
		hit_timers.erase(key)

	# Fire page projectile at nearest enemy
	var fire_cooldown = 2.0 - (level - 1) * 0.15
	fire_cooldown = maxf(0.5, fire_cooldown) / GameManager.attack_speed_mult * GameManager.cooldown_mult
	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = fire_cooldown
		_fire_page(level)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("enemies"):
		return
	if not body.has_method("take_damage"):
		return

	var eid = body.get_instance_id()
	if eid in hit_timers:
		return

	var level = GameManager.get_weapon_level("magic_book")
	var dmg = int(WeaponDB.get_damage("magic_book", level))
	GameManager._last_attacking_weapon = "magic_book"
	body.call_deferred("take_damage", dmg, "physical")
	hit_timers[eid] = hit_cooldown
	# Arcane impact sparks
	ParticleFactory.spawn_weapon_sparks(body.global_position + Vector3(0, 0.5, 0), Color(0.5, 0.3, 1.0), 4)
	ScreenEffects.shake(0.02)

func _fire_page(level: int) -> void:
	if not is_inside_tree():
		return
	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var book_global_pos = book_mesh.global_position

	var direction: Vector3
	if GameManager.manual_aim:
		direction = GameManager.aim_direction
	else:
		var nearest: Node3D = null
		var min_dist = INF
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var d = book_global_pos.distance_squared_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e

		if nearest == null:
			return

		direction = (nearest.global_position - book_global_pos).normalized()
		direction.y = 0

	var num_pages = 1
	if level >= 6:
		num_pages = 2

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return
	for i in range(num_pages):
		var page = ObjectPool.get_instance(projectile_scene)
		if not "direction" in page:
			page.queue_free()
			continue
		var spread = (randf() - 0.5) * 0.2
		var spread_dir = direction.rotated(Vector3.UP, spread)
		page.direction = spread_dir.normalized()
		page.damage = int(WeaponDB.get_damage("magic_book", level) * 0.8)
		page.speed = 16.0
		page.lifetime = 2.0
		page.damage_type = "physical"
		scene_root.add_child(page)
		page.global_position = book_global_pos

	AudioManager.play_sfx("magic_cast")
