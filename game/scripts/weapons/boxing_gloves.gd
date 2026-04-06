extends Node3D

## Luvas de Boxe — combo rapido de 3 hits com knockback forte.

var attack_timer: float = 0.0
var is_attacking: bool = false
var combo_step: int = 0
var combo_timer: float = 0.0
var combo_interval: float = 0.1
var attack_duration: float = 0.08

@onready var punch_area: Area3D = $PunchArea
@onready var punch_mesh: MeshInstance3D = $PunchMesh

var hit_enemies_this_step: Array = []
var _slash_tex: Texture2D = null
var _trail: Node3D = null

func _ready() -> void:
	punch_mesh.visible = false
	punch_mesh.mesh = null  # Hide debug geometry; slash sprites provide visual feedback
	punch_area.body_entered.connect(_on_body_entered)
	# Load slash trail sprite
	var _slash_path2 = "res://assets/sprites/effects/slashes/boxing_punch.png"
	if ResourceLoader.exists(_slash_path2):
		_slash_tex = load(_slash_path2)
	# Billboard sprite
	var _sprite_path = "res://assets/sprites/weapons/boxing_gloves.png"
	if ResourceLoader.exists(_sprite_path):
		punch_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.03
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "WeaponSprite"
		punch_area.add_child(sprite)
	# Short punch trail
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(1.0, 0.3, 0.2, 0.7)
	_trail.max_points = 6
	_trail.trail_width = 0.12
	punch_mesh.add_child(_trail)

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

	var level = GameManager.get_weapon_level("boxing_gloves")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("boxing_gloves", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	if is_attacking:
		combo_timer -= delta
		if combo_timer <= 0:
			if combo_step < 3:
				_do_punch(level)
			else:
				is_attacking = false
				punch_mesh.visible = false
				punch_area.monitoring = false
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			_start_combo(level)
			attack_timer = cooldown

func _start_combo(level: int) -> void:
	if not is_inside_tree():
		return
	is_attacking = true
	combo_step = 0

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

	_do_punch(level)

func _do_punch(level: int) -> void:
	combo_step += 1
	combo_timer = combo_interval
	hit_enemies_this_step.clear()
	punch_mesh.visible = true
	punch_area.monitoring = true

	# Escala com level
	var area_scale = (1.0 + (level - 1) * 0.12) * GameManager.attack_size_mult * GameManager.area_mult
	punch_area.scale = Vector3.ONE * area_scale
	punch_mesh.scale = Vector3.ONE * area_scale

	# Alterna posicao esquerda/direita/centro
	var offsets = [Vector3(-0.5, 0.5, -1.0), Vector3(0.5, 0.5, -1.0), Vector3(0, 0.5, -1.2)]
	var idx = (combo_step - 1) % 3
	punch_area.position = offsets[idx]
	punch_mesh.position = offsets[idx]

	AudioManager.play_sfx("punch_hit")

	# Slash trail visual at punch position
	_spawn_slash_trail(punch_mesh.global_position)

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

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies_this_step:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("boxing_gloves")
		var dmg = int(WeaponDB.get_damage("boxing_gloves", level))
		GameManager._last_attacking_weapon = "boxing_gloves"
		body.call_deferred("take_damage", dmg, WeaponDB.get_element("boxing_gloves"))
		hit_enemies_this_step.append(body)
		# Punch impact sparks
		ParticleFactory.spawn_weapon_sparks(body.global_position + Vector3(0, 0.5, 0), Color(1.0, 0.5, 0.2), 3)
		ScreenEffects.shake(0.03)

		# Knockback forte
		var player = _get_player_node()
		if not player:
			return
		var player_pos = player.global_position
		var kb_dir = (body.global_position - player_pos).normalized()
		kb_dir.y = 0
		if body.has_method("apply_knockback"):
			body.call_deferred("apply_knockback", kb_dir * 25.0)
		elif "velocity" in body:
			body.velocity = kb_dir * 25.0
