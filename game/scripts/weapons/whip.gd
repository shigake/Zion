extends Node3D

## Chicote — ataque melee de longo alcance em arco de 180 graus, passa por todos os inimigos.

var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.3

@onready var slash_area: Area3D = $SlashArea
@onready var slash_mesh: MeshInstance3D = $SlashMesh

var _trail: Node3D = null
var _crack_flashed: bool = false

func _ready() -> void:
	slash_mesh.visible = false
	slash_area.body_entered.connect(_on_body_entered)
	# Weapon trail — more organic curve, red to dark red
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(0.4, 0.05, 0.05, 0.75)
	_trail.trail_color_tip = Color(0.9, 0.2, 0.15, 0.85)
	_trail.max_points = 22
	_trail.trail_width = 0.12
	slash_mesh.add_child(_trail)
	# Billboard sprite
	var _sprite_path = "res://assets/sprites/weapons/whip.png"
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
		slash_mesh.get_parent().add_child(sprite)

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("whip")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("whip", level) / GameManager.attack_speed_mult

	if is_attacking:
		attack_anim_timer -= delta
		# Sweep 180 degrees arc (wider than katana)
		var progress = 1.0 - (attack_anim_timer / attack_duration)
		var arc_angle = lerp(-PI / 2.0, PI / 2.0, progress)
		slash_area.rotation.y = arc_angle
		slash_mesh.rotation.y = arc_angle

		# Crack flash at the tip when swing reaches the end (last 20% of arc)
		if progress > 0.8 and not _crack_flashed:
			_crack_flashed = true
			_spawn_crack_flash()

		if attack_anim_timer <= 0:
			is_attacking = false
			slash_mesh.visible = false
			slash_area.monitoring = false
			_crack_flashed = false
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			_attack(level)
			attack_timer = cooldown

func _attack(level: int) -> void:
	is_attacking = true
	attack_anim_timer = attack_duration
	slash_mesh.visible = true
	slash_area.monitoring = true

	# Manual aim: rotate slash to face aim direction
	if GameManager.manual_aim:
		var aim_angle = atan2(-GameManager.aim_direction.x, -GameManager.aim_direction.z)
		rotation.y = aim_angle

	# Scale with level
	var area_scale = 1.0 + (level - 1) * 0.15
	slash_area.scale = Vector3.ONE * area_scale
	slash_mesh.scale = Vector3.ONE * area_scale

func _on_body_entered(body: Node3D) -> void:
	# No hit limit — passes through all enemies
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("whip")
		var dmg = int(WeaponDB.get_damage("whip", level))
		body.call_deferred("take_damage", dmg, "physical")
		# Small spark on each enemy hit
		ParticleFactory.spawn_whip_spark(body.global_position + Vector3(0, 0.5, 0))

func _spawn_crack_flash() -> void:
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if not scene:
		return
	var flash = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 1.0)
	mat.emission_energy_multiplier = 8.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.surface_set_material(0, mat)
	flash.mesh = sphere
	# Position at the tip of the whip (end of slash_mesh forward direction)
	flash.global_position = slash_mesh.global_position + slash_mesh.global_transform.basis.z * 1.5
	flash.scale = Vector3.ZERO
	scene.add_child(flash)
	# Scale up then down quickly
	var tween = create_tween()
	tween.tween_property(flash, "scale", Vector3(0.1, 0.1, 0.1), 0.05)
	tween.tween_property(flash, "scale", Vector3.ZERO, 0.05)
	tween.tween_callback(flash.queue_free)
