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

func _ready() -> void:
	slash_mesh.visible = false
	slash_area.body_entered.connect(_on_body_entered)
	# Weapon trail
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(0.4, 0.6, 1.0, 0.7)
	_trail.max_points = 14
	slash_mesh.add_child(_trail)
	# 3D model
	ModelFactory.attach_weapon_model(slash_mesh, "cloud_sword", Vector3(0.5, 0.5, 0.5))

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("cloud_sword")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("cloud_sword", level) / GameManager.attack_speed_mult

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
	is_attacking = true
	attack_anim_timer = attack_duration
	slash_mesh.visible = true
	slash_area.monitoring = true
	hit_enemies.clear()

	# Manual aim: rotate slash to face aim direction
	if GameManager.manual_aim:
		var aim_angle = atan2(GameManager.aim_direction.x, GameManager.aim_direction.z)
		rotation.y = aim_angle

	# Escala com level
	var area_scale = 1.0 + (level - 1) * 0.15
	slash_area.scale = Vector3.ONE * area_scale
	slash_mesh.scale = Vector3.ONE * area_scale

	# Screen shake — golpe pesado
	ScreenEffects.shake(0.4)
	AudioManager.play_sfx("hit")

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("cloud_sword")
		var dmg = int(WeaponDB.get_damage("cloud_sword", level))
		body.call_deferred("take_damage", dmg, "physical")
		hit_enemies.append(body)
