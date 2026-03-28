extends Node3D

## Lanca — thrust linear que perfura multiplos inimigos em linha.

var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.25

@onready var thrust_area: Area3D = $ThrustArea
@onready var thrust_mesh: MeshInstance3D = $ThrustMesh

var _trail: Node3D = null

func _ready() -> void:
	thrust_mesh.visible = false
	thrust_area.body_entered.connect(_on_body_entered)
	# Weapon trail
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(0.8, 0.7, 0.2, 0.6)
	_trail.max_points = 8
	thrust_mesh.add_child(_trail)
	# Billboard sprite
	var _sprite_path = "res://assets/sprites/weapons/lance.png"
	if ResourceLoader.exists(_sprite_path):
		thrust_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.03
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "WeaponSprite"
		thrust_mesh.get_parent().add_child(sprite)

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("lance")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("lance", level) / GameManager.attack_speed_mult

	if is_attacking:
		attack_anim_timer -= delta
		# Thrust forward animation — extends outward
		var progress = 1.0 - (attack_anim_timer / attack_duration)
		var thrust_offset = lerp(0.0, -2.0, progress)
		thrust_area.position.z = thrust_offset
		thrust_mesh.position.z = thrust_offset

		if attack_anim_timer <= 0:
			is_attacking = false
			thrust_mesh.visible = false
			thrust_area.monitoring = false
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			_attack(level)
			attack_timer = cooldown

func _attack(level: int) -> void:
	is_attacking = true
	attack_anim_timer = attack_duration
	thrust_mesh.visible = true
	thrust_area.monitoring = true

	# Manual aim: rotate thrust to face aim direction
	if GameManager.manual_aim:
		var aim_angle = atan2(GameManager.aim_direction.x, GameManager.aim_direction.z)
		rotation.y = aim_angle

	# Scale with level — longer reach
	var area_scale = 1.0 + (level - 1) * 0.15
	thrust_area.scale = Vector3(1.0, 1.0, area_scale)
	thrust_mesh.scale = Vector3(1.0, 1.0, area_scale)

	# Reset position
	thrust_area.position.z = 0.0
	thrust_mesh.position.z = 0.0

func _on_body_entered(body: Node3D) -> void:
	# Pierces all enemies in the line — no hit limit
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("lance")
		var dmg = int(WeaponDB.get_damage("lance", level))
		body.call_deferred("take_damage", dmg, "physical")
