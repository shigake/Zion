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

func _ready() -> void:
	punch_mesh.visible = false
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
		punch_mesh.get_parent().add_child(sprite)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("boxing_gloves")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("boxing_gloves", level) / GameManager.attack_speed_mult

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
	is_attacking = true
	combo_step = 0

	# Manual aim: rotate punches to face aim direction
	if GameManager.manual_aim:
		var aim_angle = atan2(-GameManager.aim_direction.x, -GameManager.aim_direction.z)
		rotation.y = aim_angle

	_do_punch(level)

func _do_punch(level: int) -> void:
	combo_step += 1
	combo_timer = combo_interval
	hit_enemies_this_step.clear()
	punch_mesh.visible = true
	punch_area.monitoring = true

	# Escala com level
	var area_scale = 1.0 + (level - 1) * 0.12
	punch_area.scale = Vector3.ONE * area_scale
	punch_mesh.scale = Vector3.ONE * area_scale

	# Alterna posicao esquerda/direita/centro
	var offsets = [Vector3(-0.5, 0.5, -1.0), Vector3(0.5, 0.5, -1.0), Vector3(0, 0.5, -1.2)]
	var idx = (combo_step - 1) % 3
	punch_area.position = offsets[idx]
	punch_mesh.position = offsets[idx]

	AudioManager.play_sfx("hit")

	# Slash trail visual at punch position
	_spawn_slash_trail(punch_mesh.global_position)

func _spawn_slash_trail(pos: Vector3) -> void:
	if not _slash_tex:
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
	sprite.global_position = pos
	sprite.scale = Vector3(0.5, 0.5, 0.5)
	sprite.modulate = Color(1, 1, 1, 1)
	scene.add_child(sprite)
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
		body.call_deferred("take_damage", dmg, "physical")
		hit_enemies_this_step.append(body)

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
