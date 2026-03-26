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

func _ready() -> void:
	axe_mesh.visible = false
	axe_area.monitoring = false
	axe_area.body_entered.connect(_on_body_entered)
	# 3D model
	ModelFactory.attach_weapon_model(axe_mesh, "axe")

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
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player_pos = get_parent().get_parent().global_position

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

func _update_flight(delta: float, level: int) -> void:
	fly_timer += delta
	var player_pos = get_parent().get_parent().global_position + Vector3(0, 0.5, 0)

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

	# Spin the axe mesh
	axe_mesh.rotation.y += delta * 20.0

func _end_flight() -> void:
	is_flying = false
	axe_mesh.visible = false
	axe_area.monitoring = false
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
	body.call_deferred("take_damage", dmg, "fire")
