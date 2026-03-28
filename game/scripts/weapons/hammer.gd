extends Node3D

## Martelo — slam no chao com shockwave em area ao redor do jogador.

var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.35

@onready var slam_area: Area3D = $SlamArea
@onready var slam_mesh: MeshInstance3D = $SlamMesh

var hit_enemies: Array = []
var _slash_tex: Texture2D = null

func _ready() -> void:
	slam_mesh.visible = false
	slam_area.body_entered.connect(_on_body_entered)
	# Load slash trail sprite
	var _slash_path2 = "res://assets/sprites/effects/slashes/hammer_slam.png"
	if ResourceLoader.exists(_slash_path2):
		_slash_tex = load(_slash_path2)
	# Billboard sprite
	var _sprite_path = "res://assets/sprites/weapons/hammer.png"
	if ResourceLoader.exists(_sprite_path):
		slam_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.03
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "WeaponSprite"
		slam_mesh.get_parent().add_child(sprite)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("hammer")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("hammer", level) / GameManager.attack_speed_mult

	if is_attacking:
		attack_anim_timer -= delta
		# Shockwave expand animation
		var progress = 1.0 - (attack_anim_timer / attack_duration)
		var expand = lerp(0.3, 1.0, progress)
		slam_mesh.scale = Vector3(expand, 0.1, expand) * (1.0 + (level - 1) * 0.15)

		if attack_anim_timer <= 0:
			is_attacking = false
			slam_mesh.visible = false
			slam_area.monitoring = false
			hit_enemies.clear()
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			_attack(level)
			attack_timer = cooldown

func _attack(level: int) -> void:
	if not is_inside_tree():
		return
	is_attacking = true
	attack_anim_timer = attack_duration
	slam_mesh.visible = true
	slam_area.monitoring = true
	hit_enemies.clear()

	# Scale area with level — radius 3.0 base
	var area_scale = 1.0 + (level - 1) * 0.15
	slam_area.scale = Vector3.ONE * area_scale
	slam_mesh.scale = Vector3(0.3, 0.1, 0.3) * area_scale

	# Screen shake on impact
	ScreenEffects.shake(0.3)
	AudioManager.play_sfx("hit")

	# Slash trail visual (ground slam)
	_spawn_slash_trail()

	# Shockwave ring (TorusMesh expanding)
	_spawn_shockwave_ring(area_scale)
	# Debris particles
	ParticleFactory.spawn_hammer_debris(global_position, 12)
	# Dust cloud
	ParticleFactory.spawn_hammer_dust(global_position, 8)

func _spawn_slash_trail() -> void:
	if not is_inside_tree():
		return
	if not _slash_tex:
		return
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if not scene:
		return
	var sprite = Sprite3D.new()
	sprite.texture = _slash_tex
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = 0.04
	sprite.shaded = false
	sprite.transparent = true
	sprite.no_depth_test = true
	sprite.global_position = global_position + Vector3(0, 0.15, 0)
	sprite.scale = Vector3(0.5, 0.5, 0.5)
	sprite.modulate = Color(1, 1, 1, 1)
	scene.add_child(sprite)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector3(1.5, 1.5, 1.5), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(sprite.queue_free)

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("hammer")
		var dmg = int(WeaponDB.get_damage("hammer", level))
		GameManager._last_attacking_weapon = "hammer"
		body.call_deferred("take_damage", dmg, "physical")
		hit_enemies.append(body)

func _spawn_shockwave_ring(area_scale: float) -> void:
	if not is_inside_tree():
		return
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if not scene:
		return
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.2
	torus.outer_radius = 0.35
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.45, 0.2, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.5, 0.2)
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	torus.surface_set_material(0, mat)
	ring.mesh = torus
	ring.global_position = global_position + Vector3(0, 0.05, 0)
	ring.rotation.x = 0  # Flat on ground
	scene.add_child(ring)
	# Expand from small to area_radius, then fade out
	ring.scale = Vector3(0.3, 0.1, 0.3)
	var target_scale = Vector3(area_scale, 0.1, area_scale)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", target_scale, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)
