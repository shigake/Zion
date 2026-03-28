extends Node3D

## Nunchaku — ataque rapido em cone na frente, velocidade aumenta com level.

var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.15

@onready var slash_area: Area3D = $SlashArea
@onready var slash_mesh: MeshInstance3D = $SlashMesh

var hit_enemies: Array = []
var _trail: Node3D = null

func _ready() -> void:
	slash_mesh.visible = false
	slash_area.body_entered.connect(_on_body_entered)
	# Weapon trail
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(1.0, 0.6, 0.2, 0.6)
	_trail.max_points = 8
	slash_mesh.add_child(_trail)
	# Billboard sprite
	var _sprite_path = "res://assets/sprites/weapons/nunchaku.png"
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

	var level = GameManager.get_weapon_level("nunchaku")
	if level <= 0:
		return

	# Attack speed scales more with level
	var cooldown = WeaponDB.get_cooldown("nunchaku", level) / GameManager.attack_speed_mult

	if is_attacking:
		attack_anim_timer -= delta
		# Cone attack in front (smaller arc than katana, ~90 degrees)
		var progress = 1.0 - (attack_anim_timer / attack_duration)
		var arc_angle = lerp(-0.78, 0.78, progress)  # ~45 degrees each side
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
	is_attacking = true
	# Animation gets faster with level
	attack_duration = maxf(0.08, 0.15 - (level - 1) * 0.008)
	attack_anim_timer = attack_duration
	slash_mesh.visible = true
	slash_area.monitoring = true
	hit_enemies.clear()

	# Manual aim: rotate slash to face aim direction
	if GameManager.manual_aim:
		var aim_angle = atan2(-GameManager.aim_direction.x, -GameManager.aim_direction.z)
		rotation.y = aim_angle

	# Scale with level
	var area_scale = 1.0 + (level - 1) * 0.1
	slash_area.scale = Vector3.ONE * area_scale
	slash_mesh.scale = Vector3.ONE * area_scale

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("nunchaku")
		var dmg = int(WeaponDB.get_damage("nunchaku", level))
		body.call_deferred("take_damage", dmg, "physical")
		hit_enemies.append(body)
