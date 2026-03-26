extends Node3D

## Lancachamas — dano continuo em cone de fogo na direcao do inimigo mais proximo.

var tick_timer: float = 0.0
var tick_interval: float = 0.2
var is_firing: bool = false
var fire_timer: float = 0.0
var fire_duration: float = 1.5
var cooldown_timer: float = 0.0
var fire_direction: Vector3 = Vector3.FORWARD

@onready var flame_area: Area3D = $FlameArea
@onready var flame_mesh: MeshInstance3D = $FlameMesh

var burning_enemies: Dictionary = {}  # enemy_id -> burn_timer

func _ready() -> void:
	flame_mesh.visible = false
	flame_area.monitoring = false

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("flamethrower")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("flamethrower", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	# Update burn timers
	var to_remove: Array = []
	for key in burning_enemies:
		burning_enemies[key] -= delta
		if burning_enemies[key] <= 0:
			to_remove.append(key)
	for key in to_remove:
		burning_enemies.erase(key)

	if is_firing:
		fire_timer -= delta
		tick_timer -= delta

		# Aim toward nearest enemy
		_update_aim()

		# Tick damage
		if tick_timer <= 0:
			tick_timer = tick_interval
			_deal_damage(level)

		if fire_timer <= 0:
			is_firing = false
			flame_mesh.visible = false
			flame_area.monitoring = false
			cooldown_timer = cooldown
	else:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			_start_fire(level)

func _start_fire(level: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	is_firing = true
	fire_duration = 1.5 + (level - 1) * 0.15
	fire_timer = fire_duration
	tick_timer = 0.0
	flame_mesh.visible = true
	flame_area.monitoring = true

	# Scale cone with level
	var area_scale = 1.0 + (level - 1) * 0.12
	flame_area.scale = Vector3(area_scale, 1.0, area_scale)
	flame_mesh.scale = Vector3(area_scale, 1.0, area_scale)

	_update_aim()

func _update_aim() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var player_pos = get_parent().get_parent().global_position

	var nearest: Node3D = null
	var min_dist = INF
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d = player_pos.distance_squared_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e

	if nearest:
		fire_direction = (nearest.global_position - player_pos).normalized()
		fire_direction.y = 0
		if fire_direction.length() > 0.01:
			var angle = atan2(fire_direction.x, fire_direction.z)
			flame_area.rotation.y = -angle
			flame_mesh.rotation.y = -angle

func _deal_damage(level: int) -> void:
	var bodies = flame_area.get_overlapping_bodies()
	var dmg = int(WeaponDB.get_damage("flamethrower", level))

	for body in bodies:
		if not is_instance_valid(body):
			continue
		if body.has_method("take_damage") and body.is_in_group("enemies"):
			body.call_deferred("take_damage", dmg, "fire")
			# Apply burn effect (track by id to prevent stacking)
			burning_enemies[body.get_instance_id()] = 2.0

	# Fire particles
	if not bodies.is_empty():
		var player_pos = get_parent().get_parent().global_position
		var fx_pos = player_pos + fire_direction * 2.0 + Vector3(0, 0.5, 0)
		ParticleFactory.spawn_hit_particles(fx_pos, Color(1.0, 0.4, 0.1))
