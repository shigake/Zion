extends Node3D

## Foice — gira ao redor do jogador continuamente, causa dano e drena vida.

@export var orbit_radius: float = 2.5
@export var rotation_speed: float = 3.5
@export var hit_cooldown: float = 0.3

var angle: float = 0.0
var hit_timers: Dictionary = {}  # enemy_id -> timer

@onready var scythe_area: Area3D = $ScytheArea
@onready var scythe_mesh: MeshInstance3D = $ScytheMesh

var _trail: Node3D = null
var _slash_tex: Texture2D = null

func _ready() -> void:
	scythe_area.body_entered.connect(_on_body_entered)
	# Load slash trail sprite
	var _slash_path2 = "res://assets/sprites/effects/slashes/scythe_slash.png"
	if ResourceLoader.exists(_slash_path2):
		_slash_tex = load(_slash_path2)
	# Weapon trail — darker purple with ghostly wisps, slower fade
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(0.45, 0.1, 0.65, 0.7)
	_trail.max_points = 25
	_trail.trail_width = 0.18
	scythe_mesh.add_child(_trail)
	# Billboard sprite
	var _sprite_path = "res://assets/sprites/weapons/scythe.png"
	if ResourceLoader.exists(_sprite_path):
		scythe_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.03
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "WeaponSprite"
		scythe_mesh.get_parent().add_child(sprite)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("scythe")
	if level <= 0:
		return

	# Rotacao
	var speed = rotation_speed + (level - 1) * 0.3
	angle += speed * delta

	var radius = orbit_radius + (level - 1) * 0.2
	var pos = Vector3(cos(angle) * radius, 0.5, sin(angle) * radius)
	scythe_area.position = pos
	scythe_mesh.position = pos
	scythe_area.rotation.y = angle + PI / 2
	scythe_mesh.rotation.y = angle + PI / 2

	# Escala com area_mult
	var s = GameManager.area_mult
	scythe_mesh.scale = Vector3(s, s, s)

	# Decrementa hit timers
	var to_remove: Array = []
	for key in hit_timers:
		hit_timers[key] -= delta
		if hit_timers[key] <= 0:
			to_remove.append(key)
	for key in to_remove:
		hit_timers.erase(key)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("enemies"):
		return
	if not body.has_method("take_damage"):
		return

	var eid = body.get_instance_id()
	if eid in hit_timers:
		return

	var level = GameManager.get_weapon_level("scythe")
	var dmg = int(WeaponDB.get_damage("scythe", level))
	GameManager._last_attacking_weapon = "scythe"
	body.call_deferred("take_damage", dmg, "dark")
	hit_timers[eid] = hit_cooldown
	AudioManager.play_sfx("scythe_swoosh")

	# Slash trail visual at hit position
	_spawn_slash_trail(body.global_position + Vector3(0, 0.5, 0))

	# Lifesteal
	var lifesteal = 0.02 * level
	var heal_amount = int(dmg * lifesteal)
	if heal_amount > 0:
		GameManager.heal(heal_amount)
		# Soul wisps: green dots travel from enemy to player
		_spawn_soul_wisps(body.global_position)

func _spawn_slash_trail(pos: Vector3) -> void:
	if not is_inside_tree():
		return
	if not _slash_tex:
		return
	if Engine.get_frames_per_second() < 40:
		return
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if not scene:
		return
	var sprite = Sprite3D.new()
	sprite.texture = _slash_tex
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = 0.03
	sprite.shaded = false
	sprite.transparent = true
	sprite.no_depth_test = true
	scene.add_child(sprite)
	sprite.global_position = pos
	sprite.scale = Vector3(0.5, 0.5, 0.5)
	sprite.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector3(1.2, 1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.15).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(sprite.queue_free)

func _spawn_soul_wisps(from_pos: Vector3) -> void:
	if not is_inside_tree():
		return
	var pos = global_position
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if not scene:
		return
	var player_pos = pos + Vector3(0, 0.5, 0)
	for i in range(3):
		var wisp = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.04
		sphere.height = 0.08
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 1.0, 0.3, 0.8)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 1.0, 0.3)
		mat.emission_energy_multiplier = 3.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sphere.surface_set_material(0, mat)
		wisp.mesh = sphere
		# Offset each wisp slightly
		var offset = Vector3(randf_range(-0.3, 0.3), randf_range(0.2, 0.7), randf_range(-0.3, 0.3))
		scene.add_child(wisp)
		wisp.global_position = from_pos + offset
		# Tween from enemy to player
		var tween = create_tween()
		tween.tween_property(wisp, "global_position", player_pos, 0.4 + i * 0.08).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(wisp.queue_free)
