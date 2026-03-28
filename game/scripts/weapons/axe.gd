extends Node3D

## Machado Viking — machado boomerang que voa ate o inimigo e volta.

var attack_timer: float = 0.0
var is_flying: bool = false
var fly_timer: float = 0.0
var fly_duration: float = 0.6
var return_duration: float = 0.6
var returning: bool = false
var fly_direction: Vector3 = Vector3.FORWARD
var start_pos: Vector3 = Vector3.ZERO
var max_distance: float = 8.0
var current_distance: float = 0.0

@onready var axe_area: Area3D = $AxeArea
@onready var axe_mesh: MeshInstance3D = $AxeMesh

var hit_enemies_out: Array = []
var hit_enemies_back: Array = []
var _slash_tex: Texture2D = null

func _ready() -> void:
	axe_mesh.visible = false
	axe_area.monitoring = false
	axe_area.body_entered.connect(_on_body_entered)
	# Load slash trail sprite
	var _slash_path2 = "res://assets/sprites/effects/slashes/axe_slash.png"
	if ResourceLoader.exists(_slash_path2):
		_slash_tex = load(_slash_path2)
	# Build procedural axe model (blade + handle)
	_build_axe_model()
	_setup_billboard_sprite()

var _axe_sprite: Sprite3D = null

func _setup_billboard_sprite() -> void:
	var sprite_path = "res://assets/sprites/projectiles/axe_thrown.png"
	if ResourceLoader.exists(sprite_path):
		_axe_sprite = Sprite3D.new()
		_axe_sprite.texture = load(sprite_path)
		_axe_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_axe_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_axe_sprite.pixel_size = 0.02
		_axe_sprite.shaded = false
		_axe_sprite.transparent = true
		_axe_sprite.name = "ProjectileSprite"
		_axe_sprite.visible = false
		add_child(_axe_sprite)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("axe")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("axe", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	if is_flying:
		_update_flight(delta, level)
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			attack_timer = cooldown
			_throw(level)

func _throw(level: int) -> void:
	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	if GameManager.manual_aim:
		fly_direction = GameManager.aim_direction
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

		fly_direction = (nearest.global_position - player_pos).normalized()
		fly_direction.y = 0
		fly_direction = fly_direction.normalized()

	start_pos = player_pos + Vector3(0, 0.5, 0)
	axe_area.global_position = start_pos
	axe_mesh.global_position = start_pos

	# Scale area with level
	var area_scale = 1.0 + (level - 1) * 0.12
	axe_area.scale = Vector3.ONE * area_scale
	axe_mesh.scale = Vector3.ONE * area_scale

	# Speed scales with level
	var speed_mult = 1.0 + (level - 1) * 0.08
	fly_duration = 0.6 / speed_mult
	return_duration = 0.6 / speed_mult
	max_distance = 8.0 + (level - 1) * 0.5

	is_flying = true
	returning = false
	fly_timer = 0.0
	current_distance = 0.0
	hit_enemies_out.clear()
	hit_enemies_back.clear()

	axe_mesh.visible = true
	axe_area.monitoring = true
	if _axe_sprite:
		_axe_sprite.visible = true
		axe_mesh.visible = false

func _update_flight(delta: float, level: int) -> void:
	fly_timer += delta
	var player = _get_player_node()
	if not player:
		_end_flight()
		return
	var player_pos = player.global_position + Vector3(0, 0.5, 0)

	if not returning:
		# Flying outward
		var progress = fly_timer / fly_duration
		if progress >= 1.0:
			progress = 1.0
			returning = true
			fly_timer = 0.0
			hit_enemies_back.clear()

		# Ease out for deceleration
		var eased = 1.0 - pow(1.0 - progress, 2)
		var target_pos = start_pos + fly_direction * max_distance * eased
		axe_area.global_position = target_pos
		axe_mesh.global_position = target_pos
	else:
		# Returning to player
		var progress = fly_timer / return_duration
		if progress >= 1.0:
			_end_flight()
			return

		# Ease in for acceleration on return
		var eased = pow(progress, 2)
		var return_start = start_pos + fly_direction * max_distance
		var target_pos = return_start.lerp(player_pos, eased)
		axe_area.global_position = target_pos
		axe_mesh.global_position = target_pos

	# Spin the axe mesh (tumbling throw on Z axis)
	axe_mesh.rotation.z += delta * 15.0
	# Keep sprite position in sync with axe mesh
	if _axe_sprite:
		_axe_sprite.global_position = axe_mesh.global_position

func _end_flight() -> void:
	is_flying = false
	axe_mesh.visible = false
	axe_area.monitoring = false
	if _axe_sprite:
		_axe_sprite.visible = false
	hit_enemies_out.clear()
	hit_enemies_back.clear()

func _on_body_entered(body: Node3D) -> void:
	if not body.has_method("take_damage") or not body.is_in_group("enemies"):
		return

	# Allow hitting on both outward and return trips
	if not returning:
		if body in hit_enemies_out:
			return
		hit_enemies_out.append(body)
	else:
		if body in hit_enemies_back:
			return
		hit_enemies_back.append(body)

	var level = GameManager.get_weapon_level("axe")
	var dmg = int(WeaponDB.get_damage("axe", level))
	GameManager._last_attacking_weapon = "axe"
	body.call_deferred("take_damage", dmg, "fire")

	# Slash trail visual at hit position
	_spawn_slash_trail(body.global_position + Vector3(0, 0.5, 0))

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
	tween.tween_property(sprite, "scale", Vector3(1.2, 1.2, 1.2), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.18).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(sprite.queue_free)

func _build_axe_model() -> void:
	## Procedural axe: metal blade + wood handle with fire glow on blade.
	axe_mesh.mesh = null  # Clear any default mesh

	# -- Blade material (metal + orange fire emission) --
	var blade_mat = StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.7, 0.7, 0.75)
	blade_mat.metallic = 0.8
	blade_mat.roughness = 0.3
	blade_mat.emission_enabled = true
	blade_mat.emission = Color(1.0, 0.5, 0.1)
	blade_mat.emission_energy_multiplier = 0.8

	# -- Handle material (wood brown) --
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.45, 0.3, 0.15)
	handle_mat.metallic = 0.0
	handle_mat.roughness = 0.8

	# Blade mesh
	var blade_mesh = BoxMesh.new()
	blade_mesh.size = Vector3(0.02, 0.2, 0.15)
	var blade_mi = MeshInstance3D.new()
	blade_mi.mesh = blade_mesh
	blade_mi.material_override = blade_mat
	blade_mi.position = Vector3(0, 0.1, 0)  # Offset blade above center
	axe_mesh.add_child(blade_mi)

	# Handle mesh
	var handle_mesh = CylinderMesh.new()
	handle_mesh.top_radius = 0.02
	handle_mesh.bottom_radius = 0.02
	handle_mesh.height = 0.25
	var handle_mi = MeshInstance3D.new()
	handle_mi.mesh = handle_mesh
	handle_mi.material_override = handle_mat
	handle_mi.position = Vector3(0, -0.05, 0)  # Handle below blade
	axe_mesh.add_child(handle_mi)
