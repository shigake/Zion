extends Node3D

## Katana Dupla — dois cortes simultaneos em X (um da esquerda-direita, outro direita-esquerda).

var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.22

@onready var slash_area_l: Area3D = $SlashAreaL
@onready var slash_area_r: Area3D = $SlashAreaR
@onready var slash_mesh_l: MeshInstance3D = $SlashMeshL
@onready var slash_mesh_r: MeshInstance3D = $SlashMeshR

var hit_enemies: Array = []
var _trail_l: Node3D = null
var _trail_r: Node3D = null

func _ready() -> void:
	slash_mesh_l.visible = false
	slash_mesh_r.visible = false
	slash_area_l.body_entered.connect(_on_body_entered)
	slash_area_r.body_entered.connect(_on_body_entered)
	# Weapon trails
	_trail_l = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail_l.trail_color = Color(0.8, 0.9, 1.0, 0.6)
	_trail_l.max_points = 10
	slash_mesh_l.add_child(_trail_l)
	_trail_r = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail_r.trail_color = Color(0.8, 0.9, 1.0, 0.6)
	_trail_r.max_points = 10
	slash_mesh_r.add_child(_trail_r)
	# Billboard sprites
	var _sprite_path = "res://assets/sprites/weapons/dual_katana.png"
	if ResourceLoader.exists(_sprite_path):
		slash_mesh_l.visible = false
		var sprite_l = Sprite3D.new()
		sprite_l.texture = load(_sprite_path)
		sprite_l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite_l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite_l.pixel_size = 0.03
		sprite_l.shaded = false
		sprite_l.transparent = true
		sprite_l.name = "WeaponSprite"
		slash_mesh_l.get_parent().add_child(sprite_l)
		slash_mesh_r.visible = false
		var sprite_r = Sprite3D.new()
		sprite_r.texture = load(_sprite_path)
		sprite_r.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite_r.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite_r.pixel_size = 0.03
		sprite_r.shaded = false
		sprite_r.transparent = true
		sprite_r.name = "WeaponSprite"
		slash_mesh_r.get_parent().add_child(sprite_r)

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("dual_katana")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("dual_katana", level) / GameManager.attack_speed_mult

	if is_attacking:
		attack_anim_timer -= delta
		var progress = 1.0 - (attack_anim_timer / attack_duration)
		# Left blade sweeps left-to-right
		var arc_l = lerp(-1.05, 1.05, progress)
		# Right blade sweeps right-to-left
		var arc_r = lerp(1.05, -1.05, progress)
		slash_area_l.rotation.y = arc_l
		slash_mesh_l.rotation.y = arc_l
		slash_area_r.rotation.y = arc_r
		slash_mesh_r.rotation.y = arc_r

		if attack_anim_timer <= 0:
			is_attacking = false
			slash_mesh_l.visible = false
			slash_mesh_r.visible = false
			slash_area_l.monitoring = false
			slash_area_r.monitoring = false
			hit_enemies.clear()
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			_attack(level)
			attack_timer = cooldown

func _attack(level: int) -> void:
	is_attacking = true
	attack_anim_timer = attack_duration
	slash_mesh_l.visible = true
	slash_mesh_r.visible = true
	slash_area_l.monitoring = true
	slash_area_r.monitoring = true
	hit_enemies.clear()

	# Manual aim: rotate slash to face aim direction
	if GameManager.manual_aim:
		var aim_angle = atan2(GameManager.aim_direction.x, GameManager.aim_direction.z)
		rotation.y = aim_angle

	# Scale with level
	var area_scale = 1.0 + (level - 1) * 0.15
	slash_area_l.scale = Vector3.ONE * area_scale
	slash_area_r.scale = Vector3.ONE * area_scale
	slash_mesh_l.scale = Vector3.ONE * area_scale
	slash_mesh_r.scale = Vector3.ONE * area_scale

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("dual_katana")
		var dmg = int(WeaponDB.get_damage("dual_katana", level))
		body.call_deferred("take_damage", dmg, "physical")
		hit_enemies.append(body)
