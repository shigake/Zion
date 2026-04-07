extends Control

## PRD 55 — Indicador de dano direcional.
## Mostra setas vermelhas na borda da tela apontando para a fonte de dano.

const MAX_ARROWS := 6
const ARROW_SIZE := Vector2(24, 36)
const EDGE_MARGIN := 0.42  # Fracao do viewport para posicionar setas
const FADE_IN := 0.1
const SUSTAIN := 0.5
const FADE_OUT := 0.4
const TOTAL_DURATION := FADE_IN + SUSTAIN + FADE_OUT
const BASE_COLOR := Color(1.0, 0.15, 0.15, 0.7)
const CRIT_COLOR := Color(1.0, 0.0, 0.0, 0.9)
const CRIT_THRESHOLD := 0.20  # 20% do max HP

var _arrows: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Pre-allocate arrow pool
	for i in range(MAX_ARROWS):
		_arrows.append({"active": false, "timer": 0.0, "angle": 0.0, "is_crit": false})
	GameManager.player_took_damage_directional.connect(_on_damage)

func _on_damage(amount: int, source_pos: Vector3) -> void:
	if source_pos == Vector3.ZERO:
		return
	if not AccessibilityManager.damage_direction_enabled:
		return

	var angle := _calculate_direction(source_pos)
	var is_crit := amount > int(GameManager.get_effective_max_hp() * CRIT_THRESHOLD)

	# Find free arrow or oldest
	var best_idx := 0
	var best_timer := 999.0
	for i in range(MAX_ARROWS):
		if not _arrows[i]["active"]:
			best_idx = i
			break
		if _arrows[i]["timer"] < best_timer:
			best_timer = _arrows[i]["timer"]
			best_idx = i

	# Check grouping: merge arrows within 30 degrees
	for i in range(MAX_ARROWS):
		if _arrows[i]["active"]:
			var diff := absf(_angle_diff(_arrows[i]["angle"], angle))
			if diff < deg_to_rad(30):
				# Refresh existing arrow with averaged angle
				_arrows[i]["angle"] = _lerp_angle(_arrows[i]["angle"], angle, 0.5)
				_arrows[i]["timer"] = TOTAL_DURATION
				_arrows[i]["is_crit"] = _arrows[i]["is_crit"] or is_crit
				queue_redraw()
				return

	_arrows[best_idx]["active"] = true
	_arrows[best_idx]["timer"] = TOTAL_DURATION
	_arrows[best_idx]["angle"] = angle
	_arrows[best_idx]["is_crit"] = is_crit
	queue_redraw()

func _process(delta: float) -> void:
	var any_active := false
	for arrow in _arrows:
		if arrow["active"]:
			arrow["timer"] -= delta
			if arrow["timer"] <= 0:
				arrow["active"] = false
			else:
				any_active = true
	if any_active:
		queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var radius_x := size.x * EDGE_MARGIN
	var radius_y := size.y * EDGE_MARGIN

	for arrow in _arrows:
		if not arrow["active"]:
			continue

		var angle: float = arrow["timer_not_used"] if false else arrow["angle"]
		angle = arrow["angle"]
		var t: float = arrow["timer"]

		# Calculate alpha based on phase
		var alpha := 0.0
		var elapsed := TOTAL_DURATION - t
		if elapsed < FADE_IN:
			alpha = elapsed / FADE_IN  # 0 → 1
		elif elapsed < FADE_IN + SUSTAIN:
			alpha = 1.0
		else:
			var fade_elapsed := elapsed - FADE_IN - SUSTAIN
			alpha = 1.0 - (fade_elapsed / FADE_OUT)  # 1 → 0
		alpha = clampf(alpha, 0.0, 1.0)

		var color: Color = CRIT_COLOR if arrow["is_crit"] else BASE_COLOR
		color.a *= alpha

		var scale_mult := 1.5 if arrow["is_crit"] else 1.0

		# Position on edge of ellipse
		var pos := Vector2(
			center.x + radius_x * sin(angle),
			center.y - radius_y * cos(angle)
		)

		# Draw arrow (triangle pointing outward)
		var half_w := ARROW_SIZE.x * 0.5 * scale_mult
		var half_h := ARROW_SIZE.y * 0.5 * scale_mult

		# Rotate triangle to point outward
		var rot := angle
		var tip := Vector2(0, -half_h)  # pointing up
		var left := Vector2(-half_w, half_h * 0.4)
		var right := Vector2(half_w, half_h * 0.4)

		# Apply rotation
		tip = tip.rotated(rot) + pos
		left = left.rotated(rot) + pos
		right = right.rotated(rot) + pos

		# Glow (larger, more transparent)
		var glow_color := Color(color.r, color.g, color.b, color.a * 0.3)
		var glow_scale := 1.4
		var g_tip := Vector2(0, -half_h * glow_scale).rotated(rot) + pos
		var g_left := Vector2(-half_w * glow_scale, half_h * 0.4 * glow_scale).rotated(rot) + pos
		var g_right := Vector2(half_w * glow_scale, half_h * 0.4 * glow_scale).rotated(rot) + pos
		draw_colored_polygon([g_tip, g_left, g_right], glow_color)

		# Main arrow
		draw_colored_polygon([tip, left, right], color)

		# Inner bright core
		var core_color := Color(1.0, 0.6, 0.5, color.a * 0.6)
		var core_scale := 0.5
		var c_tip := Vector2(0, -half_h * core_scale).rotated(rot) + pos
		var c_left := Vector2(-half_w * core_scale, half_h * 0.4 * core_scale).rotated(rot) + pos
		var c_right := Vector2(half_w * core_scale, half_h * 0.4 * core_scale).rotated(rot) + pos
		draw_colored_polygon([c_tip, c_left, c_right], core_color)

func _calculate_direction(source_pos: Vector3) -> float:
	var players := GameManager.get_players()
	if players.is_empty():
		return 0.0
	var player_pos: Vector3 = players[0].global_position
	var dir := source_pos - player_pos
	dir.y = 0
	if dir.length_squared() < 0.01:
		return 0.0
	dir = dir.normalized()

	# Convert to screen-space angle relative to camera
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return atan2(dir.x, dir.z)
	var cam_forward := -cam.global_basis.z
	cam_forward.y = 0
	if cam_forward.length_squared() < 0.01:
		return atan2(dir.x, dir.z)
	cam_forward = cam_forward.normalized()

	return atan2(dir.x, dir.z) - atan2(cam_forward.x, cam_forward.z)

func _angle_diff(a: float, b: float) -> float:
	var diff := fmod(b - a + PI, TAU) - PI
	return diff

func _lerp_angle(a: float, b: float, t: float) -> float:
	var diff := _angle_diff(a, b)
	return a + diff * t
