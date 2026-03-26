extends Node3D

## Plasma Cannon — carrega por 1s e dispara um feixe largo de dano em linha.

var attack_timer: float = 0.0
var is_charging: bool = false
var is_firing: bool = false
var charge_timer: float = 0.0
var charge_duration: float = 1.0
var fire_timer: float = 0.0
var fire_duration: float = 0.4
var beam_direction: Vector3 = Vector3.FORWARD

@onready var beam_area: Area3D = $BeamArea
@onready var beam_mesh: MeshInstance3D = $BeamMesh
@onready var charge_mesh: MeshInstance3D = $ChargeMesh

var hit_enemies: Array = []

func _ready() -> void:
	beam_mesh.visible = false
	charge_mesh.visible = false
	beam_area.monitoring = false
	beam_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("plasma_cannon")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("plasma_cannon", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	if is_charging:
		charge_timer -= delta
		# Pulsing charge effect
		var progress = 1.0 - (charge_timer / charge_duration)
		var pulse = 0.3 + progress * 0.7
		charge_mesh.scale = Vector3(pulse, pulse, pulse)

		if charge_timer <= 0:
			is_charging = false
			charge_mesh.visible = false
			_fire_beam(level)
	elif is_firing:
		fire_timer -= delta

		if fire_timer <= 0:
			is_firing = false
			beam_mesh.visible = false
			beam_area.monitoring = false
			hit_enemies.clear()
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			attack_timer = cooldown
			_start_charge(level)

func _start_charge(level: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player_pos = get_parent().get_parent().global_position

	if GameManager.manual_aim:
		beam_direction = GameManager.aim_direction
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

		beam_direction = (nearest.global_position - player_pos).normalized()
		beam_direction.y = 0

	is_charging = true
	charge_duration = maxf(0.5, 1.0 - (level - 1) * 0.05)
	charge_timer = charge_duration
	charge_mesh.visible = true
	charge_mesh.scale = Vector3(0.3, 0.3, 0.3)

	# Charge particles
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.3, 0.8, 1.0))

func _fire_beam(level: int) -> void:
	is_firing = true
	fire_timer = fire_duration
	hit_enemies.clear()

	beam_mesh.visible = true
	beam_area.monitoring = true

	# Aim beam
	if beam_direction.length() > 0.01:
		var angle = atan2(beam_direction.x, beam_direction.z)
		beam_area.rotation.y = -angle
		beam_mesh.rotation.y = -angle

	# Scale beam with level
	var area_scale = 1.0 + (level - 1) * 0.12
	beam_area.scale = Vector3(area_scale, 1.0, area_scale)
	beam_mesh.scale = Vector3(area_scale, 1.0, area_scale)

	# Screen shake and SFX
	ScreenEffects.shake(0.4, 10.0)
	AudioManager.play_sfx("hit")

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("plasma_cannon")
		var dmg = int(WeaponDB.get_damage("plasma_cannon", level))
		body.call_deferred("take_damage", dmg, "electric")
		hit_enemies.append(body)
		ParticleFactory.spawn_hit_particles(body.global_position + Vector3(0, 0.5, 0), Color(0.3, 0.8, 1.0))
