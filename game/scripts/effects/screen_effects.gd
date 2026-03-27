extends Node

## Screen shake, flash, slow motion, low-HP vignette, damage feedback.

var shake_amount: float = 0.0
var shake_decay: float = 8.0
var camera: Camera3D = null
var _vignette_canvas: CanvasLayer = null
var _vignette_rect: ColorRect = null
var _vignette_visible: bool = false

# Damage flash overlay (separate from vignette)
var _damage_flash_rect: ColorRect = null
var _damage_flash_timer: float = 0.0
var _damage_flash_duration: float = 0.0

# Directional damage indicator
var _damage_indicator_container: Control = null
var _damage_indicators: Array = []  # Array of {rect: ColorRect, timer: float, angle: float}

# Chromatic aberration / damage intensity
var _damage_intensity: float = 0.0  # 0-1, decays over time

signal player_took_damage  # Emitted so HUD can react

func _ready() -> void:
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()
	# Create vignette overlay
	_vignette_canvas = CanvasLayer.new()
	_vignette_canvas.layer = 9
	_vignette_rect = ColorRect.new()
	_vignette_rect.anchors_preset = Control.PRESET_FULL_RECT
	_vignette_rect.color = Color(0.5, 0.0, 0.0, 0.0)
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_canvas.add_child(_vignette_rect)

	# Damage flash overlay (bright red, separate layer)
	_damage_flash_rect = ColorRect.new()
	_damage_flash_rect.anchors_preset = Control.PRESET_FULL_RECT
	_damage_flash_rect.color = Color(0.8, 0.0, 0.0, 0.0)
	_damage_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_canvas.add_child(_damage_flash_rect)

	# Directional damage indicator container
	_damage_indicator_container = Control.new()
	_damage_indicator_container.anchors_preset = Control.PRESET_FULL_RECT
	_damage_indicator_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_canvas.add_child(_damage_indicator_container)

	add_child(_vignette_canvas)

func _process(delta: float) -> void:
	# Re-acquire camera if freed (after scene change)
	if not camera or not is_instance_valid(camera):
		camera = get_viewport().get_camera_3d()
	if shake_amount > 0.01 and camera:
		camera.h_offset = randf_range(-shake_amount, shake_amount)
		camera.v_offset = randf_range(-shake_amount, shake_amount)
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
	elif camera:
		camera.h_offset = 0
		camera.v_offset = 0

	# Low-HP vignette
	_update_vignette()

	# Damage flash decay
	_update_damage_flash(delta)

	# Damage intensity decay (for any post-process effects)
	if _damage_intensity > 0.0:
		_damage_intensity = maxf(0.0, _damage_intensity - delta * 3.0)

	# Directional damage indicators
	_update_damage_indicators(delta)

func _update_vignette() -> void:
	if not _vignette_rect:
		return
	var max_hp = GameManager.get_effective_max_hp()
	if max_hp <= 0:
		return
	var hp_pct = float(GameManager.player_hp) / float(max_hp)
	if hp_pct < 0.4:
		# Pulse intensity based on HP%
		var intensity = (0.4 - hp_pct) / 0.4  # 0 at 40%, 1 at 0%
		var pulse = (sin(GameManager.game_time * 4.0) * 0.5 + 0.5) * 0.15
		_vignette_rect.color.a = intensity * 0.3 + pulse
	else:
		_vignette_rect.color.a = 0.0

func _update_damage_flash(delta: float) -> void:
	if not _damage_flash_rect:
		return
	if _damage_flash_timer > 0.0:
		_damage_flash_timer -= delta
		# Quick fade: starts bright, fades out
		var t = clampf(_damage_flash_timer / _damage_flash_duration, 0.0, 1.0)
		_damage_flash_rect.color.a = t * 0.25
	else:
		_damage_flash_rect.color.a = 0.0

func _update_damage_indicators(delta: float) -> void:
	var to_remove := []
	for i in range(_damage_indicators.size()):
		var ind = _damage_indicators[i]
		ind["timer"] -= delta
		if ind["timer"] <= 0.0:
			to_remove.append(i)
			if is_instance_valid(ind["rect"]):
				ind["rect"].queue_free()
		else:
			# Fade out
			var alpha = clampf(ind["timer"] / 0.5, 0.0, 0.8)
			if is_instance_valid(ind["rect"]):
				ind["rect"].modulate.a = alpha
	# Remove expired (reverse order)
	for i in range(to_remove.size() - 1, -1, -1):
		_damage_indicators.remove_at(to_remove[i])

func shake(amount: float = 0.15) -> void:
	shake_amount = maxf(shake_amount, amount)

func hit_freeze(duration: float = 0.05) -> void:
	Engine.time_scale = 0.1
	await get_tree().create_timer(duration * 0.1).timeout
	Engine.time_scale = 1.0

func slow_motion(duration: float = 0.5, scale: float = 0.3) -> void:
	Engine.time_scale = scale
	await get_tree().create_timer(duration * scale).timeout
	Engine.time_scale = 1.0

## Brief white flash overlay (e.g. on heavy swing)
func flash(duration: float = 0.05, alpha: float = 0.1) -> void:
	if not _vignette_rect:
		return
	var original_color = _vignette_rect.color
	_vignette_rect.color = Color(1.0, 1.0, 1.0, alpha)
	await get_tree().create_timer(duration).timeout
	_vignette_rect.color = original_color

## Full damage feedback package — call this when player takes damage
func damage_feedback(damage_amount: int, damage_source_pos: Vector3 = Vector3.ZERO) -> void:
	var max_hp = GameManager.get_effective_max_hp()
	var damage_ratio = float(damage_amount) / float(maxi(max_hp, 1))

	# 1. Screen shake (scales with damage)
	var shake_str = clampf(0.08 + damage_ratio * 0.3, 0.08, 0.25)
	shake(shake_str)

	# 2. Hit freeze (micro-pause for impact feel)
	if damage_ratio > 0.15:
		hit_freeze(0.04)

	# 3. Red screen flash
	damage_flash(0.15 + damage_ratio * 0.1)

	# 4. Damage intensity for post-processing
	_damage_intensity = clampf(damage_ratio * 2.0, 0.3, 1.0)

	# 5. Directional damage indicator
	if damage_source_pos != Vector3.ZERO:
		_spawn_damage_indicator(damage_source_pos)

	# 6. Gamepad vibration
	_vibrate_gamepad(damage_ratio)

	# 7. Signal for HUD
	player_took_damage.emit()

## Red flash overlay on damage
func damage_flash(duration: float = 0.15) -> void:
	_damage_flash_timer = duration
	_damage_flash_duration = duration

## Directional damage indicator (red arc on screen edge toward damage source)
func _spawn_damage_indicator(source_pos: Vector3) -> void:
	if not _damage_indicator_container:
		return
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var player_pos = players[0].global_position
	var dir = (source_pos - player_pos).normalized()
	# Convert 3D direction to 2D angle (top-down: x,z plane)
	var angle = atan2(dir.x, -dir.z)  # -z is forward in Godot

	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2.0

	# Create directional arc indicator
	var indicator = ColorRect.new()
	indicator.color = Color(1.0, 0.1, 0.05, 0.8)
	indicator.custom_minimum_size = Vector2(60, 8)
	indicator.size = Vector2(60, 8)
	indicator.pivot_offset = Vector2(30, 4)
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Position on screen edge in direction of damage
	var edge_dist = minf(viewport_size.x, viewport_size.y) * 0.42
	var pos = center + Vector2(sin(angle), -cos(angle)) * edge_dist
	indicator.position = pos - indicator.pivot_offset
	indicator.rotation = angle

	_damage_indicator_container.add_child(indicator)
	_damage_indicators.append({"rect": indicator, "timer": 0.6, "angle": angle})

## Gamepad vibration on damage
func _vibrate_gamepad(intensity: float) -> void:
	var strong = clampf(intensity * 0.6, 0.1, 0.5)
	var weak = clampf(intensity * 0.8, 0.2, 0.7)
	Input.start_joy_vibration(0, weak, strong, 0.2)
