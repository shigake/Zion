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
var _slash_tex: Texture2D = null

func _ready() -> void:
	slash_mesh.visible = false
	slash_mesh.mesh = null  # Hide debug geometry; trail + slash sprites provide visual feedback
	slash_area.body_entered.connect(_on_body_entered)
	# Load slash trail sprite
	var _slash_path2 = "res://assets/sprites/effects/slashes/whip_crack.png"
	if ResourceLoader.exists(_slash_path2):
		_slash_tex = load(_slash_path2)
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
	if not is_inside_tree():
		return
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
	if not is_inside_tree():
		return
	is_attacking = true
	attack_anim_timer = attack_duration
	slash_mesh.visible = true
	slash_area.monitoring = true

	# Auto-aim toward nearest enemy (instinto dimensional)
	if not GameManager.manual_aim:
		var enemies = GameManager.get_enemies()
		if not enemies.is_empty():
			var player = get_parent().get_parent() if get_parent() else null
			if player and is_instance_valid(player):
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
					var dir = (nearest.global_position - player.global_position).normalized()
					var aim_angle = atan2(-dir.x, -dir.z)
					rotation.y = aim_angle
	else:
		var aim_angle = atan2(-GameManager.aim_direction.x, -GameManager.aim_direction.z)
		rotation.y = aim_angle

	# Scale with level
	var area_scale = 1.0 + (level - 1) * 0.15
	slash_area.scale = Vector3.ONE * area_scale
	slash_mesh.scale = Vector3.ONE * area_scale

	AudioManager.play_sfx("whip_crack")

	# Slash trail visual
	_spawn_slash_trail()

func _spawn_slash_trail() -> void:
	WeaponVFX.spawn_slash_trail(self, _slash_tex, global_position + Vector3(0, 0.5, 0))

func _on_body_entered(body: Node3D) -> void:
	# No hit limit — passes through all enemies
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("whip")
		var dmg = int(WeaponDB.get_damage("whip", level))
		GameManager._last_attacking_weapon = "whip"
		body.call_deferred("take_damage", dmg, "physical")
		# Small spark on each enemy hit
		ParticleFactory.spawn_whip_spark(body.global_position + Vector3(0, 0.5, 0))

func _spawn_crack_flash() -> void:
	if not is_inside_tree():
		return
	var tip_pos = slash_mesh.global_position + slash_mesh.global_transform.basis.z * 1.5
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
	flash.scale = Vector3.ZERO
	scene.add_child(flash)
	# Position at the tip of the whip (end of slash_mesh forward direction)
	flash.global_position = tip_pos
	# Scale up then down quickly
	var tween = create_tween()
	tween.tween_property(flash, "scale", Vector3(0.1, 0.1, 0.1), 0.05)
	tween.tween_property(flash, "scale", Vector3.ZERO, 0.05)
	tween.tween_callback(flash.queue_free)
