extends Node

## AI that controls the player automatically during automated tests.
## Attaches to the Player node and overrides input with intelligent behavior.

var player: CharacterBody3D = null
var enabled: bool = false
var avoid_attacks: bool = false  # For pacifist achievement test — only flee, no weapons

# Timers
var _dodge_timer: float = 0.0
var _wander_change_timer: float = 0.0
var _center_pull_timer: float = 0.0
var _stuck_timer: float = 0.0

# Movement state
var _wander_dir: Vector3 = Vector3.ZERO
var _last_position: Vector3 = Vector3.ZERO
var _current_strategy: String = "wander"  # wander, flee, collect, center

# Config
var flee_radius: float = 15.0
var danger_radius: float = 8.0
var critical_radius: float = 3.0
var collect_radius: float = 25.0
var center_max_distance: float = 60.0
var stuck_threshold: float = 0.5
var stuck_timeout: float = 2.0

# Stats tracking
var total_distance_moved: float = 0.0
var dashes_used: int = 0
var strategy_time: Dictionary = {"wander": 0.0, "flee": 0.0, "collect": 0.0, "center": 0.0}

func setup(p: CharacterBody3D) -> void:
	player = p
	enabled = true
	_last_position = p.global_position
	_wander_dir = _random_wander_dir()

func _physics_process(delta: float) -> void:
	if not enabled or not player or not is_instance_valid(player):
		return
	if not player.is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var pos = player.global_position

	# Track distance
	total_distance_moved += pos.distance_to(_last_position)

	# Stuck detection
	if pos.distance_to(_last_position) < stuck_threshold * delta:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0
	_last_position = pos

	# Analyze environment
	var threat_analysis = _analyze_threats(pos)
	var collect_target = _find_best_collectible(pos, threat_analysis)

	# Choose strategy
	var prev_strategy = _current_strategy
	_current_strategy = _choose_strategy(pos, threat_analysis, collect_target)
	strategy_time[_current_strategy] += delta

	# Calculate movement direction
	var move_dir = _calculate_move_direction(pos, delta, threat_analysis, collect_target)

	# Anti-stuck: if stuck for too long, pick a random perpendicular direction
	if _stuck_timer > stuck_timeout:
		move_dir = _get_unstuck_direction(move_dir)
		_stuck_timer = 0.0

	move_dir.y = 0
	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()

	# Apply movement to player
	player.move_direction = move_dir
	var speed = player.base_speed * GameManager.speed_mult
	player.velocity = move_dir * speed

	# Auto-dash logic
	_dodge_timer -= delta
	if _should_dash(threat_analysis) and _dodge_timer <= 0 and player.dash_cooldown_timer <= 0:
		_perform_dash(move_dir)

func _analyze_threats(pos: Vector3) -> Dictionary:
	var enemies = GameManager.get_enemies()
	var result = {
		"flee_dir": Vector3.ZERO,
		"threat_count": 0,
		"closest_dist": INF,
		"closest_enemy": null,
		"danger_count": 0,   # enemies within danger_radius
		"critical_count": 0, # enemies within critical_radius
		"cluster_center": Vector3.ZERO,
		"total_nearby": 0,
	}

	var nearby_positions: Array[Vector3] = []

	for e in enemies:
		if not is_instance_valid(e) or not e.is_inside_tree():
			continue
		var dist = pos.distance_to(e.global_position)

		if dist < flee_radius:
			var weight = 1.0 / maxf(dist, 0.3)
			result["flee_dir"] += (pos - e.global_position).normalized() * weight
			result["threat_count"] += 1
			nearby_positions.append(e.global_position)

		if dist < danger_radius:
			result["danger_count"] += 1

		if dist < critical_radius:
			result["critical_count"] += 1

		if dist < result["closest_dist"]:
			result["closest_dist"] = dist
			result["closest_enemy"] = e

	# Calculate cluster center
	if not nearby_positions.is_empty():
		var center = Vector3.ZERO
		for p in nearby_positions:
			center += p
		center /= nearby_positions.size()
		result["cluster_center"] = center
		result["total_nearby"] = nearby_positions.size()

	return result

func _find_best_collectible(pos: Vector3, threats: Dictionary) -> Node3D:
	var gems = get_tree().get_nodes_in_group("xp_gems")
	var crystals = get_tree().get_nodes_in_group("crystals") if get_tree().has_group("crystals") else []

	var best: Node3D = null
	var best_score: float = -INF

	# Combine all collectibles
	var all_collectibles: Array = []
	all_collectibles.append_array(gems)
	all_collectibles.append_array(crystals)

	for item in all_collectibles:
		if not is_instance_valid(item) or not item.is_inside_tree():
			continue
		var dist = pos.distance_to(item.global_position)
		if dist > collect_radius:
			continue

		# Score: closer is better, but penalize if near enemies
		var score = 100.0 - dist * 3.0

		# Check if collectible is near enemy cluster
		if threats["total_nearby"] > 0:
			var dist_to_cluster = item.global_position.distance_to(threats["cluster_center"])
			if dist_to_cluster < danger_radius:
				score -= 50.0  # Penalize risky pickups

		if score > best_score:
			best_score = score
			best = item

	return best

func _choose_strategy(pos: Vector3, threats: Dictionary, collect_target: Node3D) -> String:
	# Critical danger: flee immediately
	if threats["critical_count"] >= 2 or (threats["closest_dist"] < critical_radius and threats["danger_count"] >= 3):
		return "flee"

	# Too far from center: pull back
	if pos.length() > center_max_distance:
		return "center"

	# Moderate danger: flee
	if threats["danger_count"] >= 4 and threats["closest_dist"] < danger_radius:
		return "flee"

	# Safe enough to collect
	if collect_target and threats["closest_dist"] > danger_radius * 0.7:
		return "collect"

	# Light threat: kite (flee but controlled)
	if threats["threat_count"] >= 2 and threats["closest_dist"] < flee_radius:
		return "flee"

	return "wander"

func _calculate_move_direction(pos: Vector3, delta: float, threats: Dictionary, collect_target: Node3D) -> Vector3:
	var move_dir = Vector3.ZERO

	match _current_strategy:
		"flee":
			move_dir = _calculate_flee_direction(pos, threats, delta)
		"collect":
			if collect_target and is_instance_valid(collect_target) and collect_target.is_inside_tree():
				move_dir = (collect_target.global_position - pos).normalized()
			else:
				move_dir = _get_wander_direction(delta)
		"center":
			# Move toward world origin with some randomness
			var to_center = -pos.normalized()
			to_center.y = 0
			# Add slight perpendicular drift to avoid monotony
			var perp = Vector3(-to_center.z, 0, to_center.x)
			move_dir = (to_center * 0.8 + perp * sin(GameManager.game_time * 1.5) * 0.3).normalized()
		"wander":
			move_dir = _get_wander_direction(delta)

	return move_dir

func _calculate_flee_direction(pos: Vector3, threats: Dictionary, _delta: float) -> Vector3:
	var flee_dir = threats["flee_dir"]
	if flee_dir.length() < 0.01:
		flee_dir = _random_wander_dir()

	flee_dir = flee_dir.normalized()
	flee_dir.y = 0

	# If we would flee too far from center, curve the flee direction
	var future_pos = pos + flee_dir * 10.0
	if future_pos.length() > center_max_distance * 0.8:
		# Curve toward center
		var to_center = -pos.normalized()
		to_center.y = 0
		flee_dir = (flee_dir * 0.6 + to_center * 0.4).normalized()

	# Add slight perpendicular oscillation to avoid getting cornered
	var perp = Vector3(-flee_dir.z, 0, flee_dir.x)
	var oscillation = sin(GameManager.game_time * 3.0) * 0.3
	flee_dir = (flee_dir + perp * oscillation).normalized()

	return flee_dir

func _get_wander_direction(delta: float) -> Vector3:
	_wander_change_timer -= delta
	if _wander_change_timer <= 0:
		_wander_dir = _random_wander_dir()
		_wander_change_timer = randf_range(1.5, 4.0)

	# Slightly bias toward center if far out
	if player and is_instance_valid(player):
		var dist_from_center = player.global_position.length()
		if dist_from_center > center_max_distance * 0.5:
			var to_center = -player.global_position.normalized()
			to_center.y = 0
			var bias = clampf((dist_from_center - center_max_distance * 0.5) / center_max_distance, 0, 0.5)
			_wander_dir = (_wander_dir * (1.0 - bias) + to_center * bias).normalized()

	return _wander_dir

func _random_wander_dir() -> Vector3:
	var angle = randf() * TAU
	return Vector3(cos(angle), 0, sin(angle))

func _should_dash(threats: Dictionary) -> bool:
	# Dash when critically surrounded
	if threats["critical_count"] >= 3 and threats["closest_dist"] < critical_radius:
		return true
	# Dash when many enemies very close
	if threats["danger_count"] >= 5 and threats["closest_dist"] < danger_radius * 0.5:
		return true
	# Dash away from boss attacks
	if threats["closest_dist"] < 2.0:
		return true
	return false

func _perform_dash(move_dir: Vector3) -> void:
	if move_dir.length() < 0.1:
		move_dir = _random_wander_dir()
	player.is_dashing = true
	player.dash_timer = player.dash_duration
	player.dash_cooldown_timer = player.dash_cooldown
	player.dash_direction = move_dir.normalized()
	_dodge_timer = 0.8
	dashes_used += 1
	AudioManager.play_sfx("dash")

func _get_unstuck_direction(current_dir: Vector3) -> Vector3:
	# Pick a perpendicular direction with some randomness
	var perp = Vector3(-current_dir.z, 0, current_dir.x)
	if randf() > 0.5:
		perp = -perp
	# Mix with a random direction
	var random_dir = _random_wander_dir()
	return (perp * 0.6 + random_dir * 0.4).normalized()

func get_stats() -> Dictionary:
	return {
		"total_distance": total_distance_moved,
		"dashes_used": dashes_used,
		"strategy_time": strategy_time.duplicate(),
		"current_strategy": _current_strategy,
	}
