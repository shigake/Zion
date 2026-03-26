extends Node3D

## Chicote — ataque melee de longo alcance em arco de 180 graus, passa por todos os inimigos.

var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.3

@onready var slash_area: Area3D = $SlashArea
@onready var slash_mesh: MeshInstance3D = $SlashMesh

var _trail: Node3D = null

func _ready() -> void:
	slash_mesh.visible = false
	slash_area.body_entered.connect(_on_body_entered)
	# Weapon trail
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(0.9, 0.2, 0.2, 0.6)
	_trail.max_points = 15
	slash_mesh.add_child(_trail)

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

		if attack_anim_timer <= 0:
			is_attacking = false
			slash_mesh.visible = false
			slash_area.monitoring = false
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
