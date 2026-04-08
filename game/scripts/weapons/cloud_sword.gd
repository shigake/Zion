extends Node3D

## Espada Cloud (FF7) — golpe frontal massivo em arco de 180 graus.

var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.4

@onready var slash_area: Area3D = $SlashArea
@onready var slash_mesh: MeshInstance3D = $SlashMesh

var hit_enemies: Array = []
var _trail: Node3D = null
var _slash_tex: Texture2D = null

func _ready() -> void:
	slash_mesh.visible = false
	slash_mesh.mesh = null  # Hide debug geometry; trail + slash sprites provide visual feedback
	slash_area.body_entered.connect(_on_body_entered)
	# Load slash trail sprite
	var _slash_path2 = "res://assets/sprites/effects/slashes/cloud_sword_wave.png"
	if ResourceLoader.exists(_slash_path2):
		_slash_tex = load(_slash_path2)
	# Weapon trail — wider blue energy glow
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(0.3, 0.5, 1.0, 0.9)
	_trail.trail_color_tip = Color(0.6, 0.85, 1.0, 1.0)
	_trail.max_points = 27
	_trail.trail_width = 0.4
	slash_mesh.add_child(_trail)
	# 3D model (preferred) or billboard sprite fallback
	var _model_path = "res://assets/models/cloud_sword.glb"
	var _model_scene = EnemyBase3D._safe_load_model(_model_path)
	if _model_scene:
		var model = _model_scene.instantiate()
		model.name = "WeaponModel"
		model.scale = Vector3(0.25, 0.25, 0.25)
		slash_area.add_child(model)
	else:
		var _sprite_path = "res://assets/sprites/weapons/cloud_sword.png"
		if ResourceLoader.exists(_sprite_path):
			slash_mesh.visible = false
			var sprite = Sprite3D.new()
			sprite.texture = load(_sprite_path)
			sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			sprite.pixel_size = 0.03
			sprite.shaded = false
			sprite.transparent = true
			sprite.name = "WeaponSprite"
			slash_area.add_child(sprite)
			# Apply pixel art shader
			var _pa = get_node_or_null("/root/PixelArtShader")
			if _pa:
				var _wdata = WeaponDB.get_weapon("cloud_sword")
				var _elem = _wdata.get("element", "physical") if _wdata else "physical"
				var _ecols = {"fire": Color(1, 0.5, 0), "ice": Color(0.3, 0.5, 1), "electric": Color(0, 1, 1), "dark": Color(0.5, 0, 1), "poison": Color(0, 1, 0.3)}
				sprite.material_override = _pa.get_enemy_material(sprite.texture, _ecols.get(_elem, Color.WHITE))

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("cloud_sword")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("cloud_sword", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	if is_attacking:
		attack_anim_timer -= delta
		# Arco de 180 graus (PI radianos)
		var progress = 1.0 - (attack_anim_timer / attack_duration)
		var arc_angle = lerp(-PI / 2.0, PI / 2.0, progress)
		slash_area.rotation.y = arc_angle
		slash_mesh.rotation.y = arc_angle

		if attack_anim_timer <= 0:
			is_attacking = false
			slash_mesh.visible = false
			slash_area.monitoring = false
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
	slash_mesh.visible = true
	slash_area.monitoring = true
	hit_enemies.clear()

	# Auto-aim toward nearest enemy (instinto dimensional)
	var player = get_parent().get_parent() if get_parent() else null
	if player and is_instance_valid(player):
		var aimed = false
		if GameManager.manual_aim and GameManager.aim_direction.length_squared() > 0.01:
			var aim_angle = atan2(-GameManager.aim_direction.x, -GameManager.aim_direction.z)
			global_rotation.y = aim_angle
			aimed = true
		else:
			var enemies = GameManager.get_enemies()
			if not enemies.is_empty():
				var nearest: Node3D = null
				var min_dist = INF
				for e in enemies:
					if not is_instance_valid(e):
						continue
					var d = player.global_position.distance_squared_to(e.global_position)
					if d < min_dist:
						min_dist = d
						nearest = e
				if nearest:
					var dir = nearest.global_position - player.global_position
					dir.y = 0.0
					if dir.length_squared() > 0.01:
						dir = dir.normalized()
						global_rotation.y = atan2(-dir.x, -dir.z)
						aimed = true
		# Fallback: aim in player's movement direction
		if not aimed and player is CharacterBody3D:
			var vel = player.velocity
			vel.y = 0.0
			if vel.length_squared() > 0.1:
				global_rotation.y = atan2(-vel.x, -vel.z)

	# Escala com level
	var area_scale = (1.0 + (level - 1) * 0.15) * GameManager.attack_size_mult * GameManager.area_mult
	slash_area.scale = Vector3.ONE * area_scale
	slash_mesh.scale = Vector3.ONE * area_scale

	# Screen shake — golpe pesado, epic impact
	ScreenEffects.shake(0.5)
	ScreenEffects.flash(0.06, 0.15)
	AudioManager.play_sfx("sword_slash")

	# Ground dust at player position — more dramatic
	ParticleFactory.spawn_ground_dust(global_position, 12)
	# Ground shockwave ring for heavy sword impact
	if Engine.get_frames_per_second() > 40:
		WeaponVFX.spawn_shockwave_ring(self, global_position, Color(0.3, 0.5, 1.0, 0.5), Color(0.4, 0.6, 1.0), 1.2, 0.2)

	# Slash trail visual
	_spawn_slash_trail()

func _spawn_slash_trail() -> void:
	if not is_inside_tree():
		return
	if not _slash_tex:
		return
	if Engine.get_frames_per_second() < 40:
		return
	var pos = global_position
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
	scene.add_child(sprite)
	sprite.global_position = pos + Vector3(0, 0.6, 0)
	sprite.scale = Vector3(0.6, 0.6, 0.6)
	sprite.modulate = Color(0.7, 0.85, 1.0, 1.0)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector3(2.0, 2.0, 2.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(sprite.queue_free)

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("cloud_sword")
		var dmg = int(WeaponDB.get_damage("cloud_sword", level))
		GameManager._last_attacking_weapon = "cloud_sword"
		body.call_deferred("take_damage", dmg, "physical")
		hit_enemies.append(body)
		# Blue energy sparks — more vibrant
		ParticleFactory.spawn_weapon_sparks(body.global_position + Vector3(0, 0.5, 0), Color(0.3, 0.6, 1.0), 7)
		ParticleFactory.spawn_slash_sparks(body.global_position + Vector3(0, 0.5, 0), 3)
