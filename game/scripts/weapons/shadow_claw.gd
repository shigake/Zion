extends Node3D

## Shadow Claw — garras sombrias que cortam em arco rapido ao redor do Lealith.
## Dois swipes consecutivos (duplo ataque), dano sombrio.

var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.15  # Faster than katana
var _second_swipe: bool = false
var _swipe_delay: float = 0.0

@onready var slash_area: Area3D = $SlashArea
@onready var slash_mesh: MeshInstance3D = $SlashMesh

var hit_enemies: Array = []
var _slash_tex: Texture2D = null

func _ready() -> void:
	# Cria mesh visual para o ataque (arco roxo brilhante)
	var arc_mesh = BoxMesh.new()
	arc_mesh.size = Vector3(1.5, 0.1, 0.4)
	slash_mesh.mesh = arc_mesh
	var arc_mat = StandardMaterial3D.new()
	arc_mat.albedo_color = Color(0.5, 0.15, 0.9, 0.7)
	arc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc_mat.emission_enabled = true
	arc_mat.emission = Color(0.6, 0.2, 1.0)
	arc_mat.emission_energy_multiplier = 2.0
	arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc_mat.no_depth_test = true
	slash_mesh.material_override = arc_mat
	slash_mesh.visible = false
	slash_area.body_entered.connect(_on_body_entered)
	var _slash_path = "res://assets/sprites/effects/slashes/shadow_claw_slash.png"
	if not ResourceLoader.exists(_slash_path):
		_slash_path = "res://assets/sprites/effects/slashes/katana_slash.png"
	if ResourceLoader.exists(_slash_path):
		_slash_tex = load(_slash_path)
	# Weapon sprite
	var _sprite_path = "res://assets/sprites/weapons/shadow_claw.png"
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

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("shadow_claw")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("shadow_claw", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	# Second swipe delay
	if _swipe_delay > 0:
		_swipe_delay -= delta
		if _swipe_delay <= 0:
			_second_swipe = true
			_attack(level, true)

	if is_attacking:
		attack_anim_timer -= delta
		var progress = 1.0 - (attack_anim_timer / attack_duration)
		# Alternate swipe direction for second hit
		if _second_swipe:
			var arc_angle = lerp(1.2, -1.2, progress)
			slash_area.rotation.y = arc_angle
			slash_mesh.rotation.y = arc_angle
		else:
			var arc_angle = lerp(-1.2, 1.2, progress)
			slash_area.rotation.y = arc_angle
			slash_mesh.rotation.y = arc_angle

		if attack_anim_timer <= 0:
			is_attacking = false
			_second_swipe = false
			slash_mesh.visible = false
			slash_area.monitoring = false
			hit_enemies.clear()
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			_attack(level, false)
			attack_timer = cooldown

func _attack(level: int, is_second: bool = false) -> void:
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

	var area_scale = 1.0 + (level - 1) * 0.18
	slash_area.scale = Vector3.ONE * area_scale
	slash_mesh.scale = Vector3.ONE * area_scale

	AudioManager.play_sfx("sword_slash")
	_spawn_claw_trail(is_second)

	# Trigger second swipe after brief delay (level 3+)
	if not is_second and level >= 3:
		_swipe_delay = 0.12

func _spawn_claw_trail(is_second: bool) -> void:
	if not is_inside_tree() or not _slash_tex:
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
	sprite.pixel_size = 0.03
	sprite.shaded = false
	sprite.transparent = true
	sprite.no_depth_test = true
	scene.add_child(sprite)
	sprite.global_position = pos + Vector3(0, 0.5, 0)
	sprite.scale = Vector3(0.4, 0.4, 0.4)
	# Purple shadow color for claw trails
	var claw_color = Color(0.6, 0.2, 1.0, 1.0) if not is_second else Color(0.3, 0.1, 0.8, 1.0)
	sprite.modulate = claw_color
	if is_second:
		sprite.rotation.z = PI  # Flip second swipe
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector3(1.3, 1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.15).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(sprite.queue_free)

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("shadow_claw")
		var dmg = int(WeaponDB.get_damage("shadow_claw", level))
		GameManager._last_attacking_weapon = "shadow_claw"
		body.call_deferred("take_damage", dmg, "shadow")
		hit_enemies.append(body)
		ParticleFactory.spawn_slash_sparks(body.global_position + Vector3(0, 0.5, 0), 4)
		ScreenEffects.shake(0.03)
