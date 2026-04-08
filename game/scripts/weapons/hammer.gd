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
var _trail: Node3D = null

func _ready() -> void:
	slam_mesh.visible = false
	slam_mesh.mesh = null  # Hide debug geometry; shockwave ring + slash sprites provide visual feedback
	slam_area.body_entered.connect(_on_body_entered)
	# Load slash trail sprite
	var _slash_path2 = "res://assets/sprites/effects/slashes/hammer_slam.png"
	if ResourceLoader.exists(_slash_path2):
		_slash_tex = load(_slash_path2)
	# 3D model (preferred) or billboard sprite fallback
	var _model_path = "res://assets/models/hammer.glb"
	var _model_scene = EnemyBase3D._safe_load_model(_model_path)
	if _model_scene:
		var model = _model_scene.instantiate()
		model.name = "WeaponModel"
		model.scale = Vector3(0.25, 0.25, 0.25)
		slam_area.add_child(model)
	else:
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
			slam_area.add_child(sprite)
	# Brief slam trail
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(0.7, 0.45, 0.2, 0.7)
	_trail.trail_color_tip = Color(0.9, 0.6, 0.2, 0.8)
	_trail.max_points = 10
	_trail.trail_width = 0.2
	slam_mesh.add_child(_trail)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("hammer")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("hammer", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

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
	var area_scale = (1.0 + (level - 1) * 0.15) * GameManager.attack_size_mult * GameManager.area_mult
	slam_area.scale = Vector3.ONE * area_scale
	slam_mesh.scale = Vector3(0.3, 0.1, 0.3) * area_scale

	# Screen shake on impact
	ScreenEffects.shake(0.3)
	AudioManager.play_sfx("hammer_slam")

	# Slash trail visual (ground slam)
	_spawn_slash_trail()

	# Shockwave ring (TorusMesh expanding)
	_spawn_shockwave_ring(area_scale)
	# Debris particles
	ParticleFactory.spawn_hammer_debris(global_position, 12)
	# Dust cloud
	ParticleFactory.spawn_hammer_dust(global_position, 8)

func _spawn_slash_trail() -> void:
	WeaponVFX.spawn_slash_trail(self, _slash_tex, global_position + Vector3(0, 0.15, 0), 0.04, 1.5, 0.2)

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
	WeaponVFX.spawn_shockwave_ring(self, global_position, Color(0.7, 0.45, 0.2, 0.6), Color(0.8, 0.5, 0.2), area_scale)
