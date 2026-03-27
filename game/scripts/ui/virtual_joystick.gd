## VirtualJoystick: reusable touch joystick for mobile controls.
## Shows where the finger touches (dynamic position), within its touch zone.
## Outputs a normalized Vector2 direction via get_direction().
extends Control

## Normalized direction output (-1..1 per axis)
var direction: Vector2 = Vector2.ZERO

## Dead zone as fraction of joystick radius (0..1)
@export var dead_zone: float = 0.15

## Outer ring diameter in pixels
@export var outer_size: float = 150.0

## Inner knob diameter in pixels
@export var knob_size: float = 60.0

## Touch index currently tracked (-1 = none)
var _touch_index: int = -1

## Center of the joystick in screen coordinates (set on first touch)
var _joy_center: Vector2 = Vector2.ZERO

## Current knob offset from center
var _knob_offset: Vector2 = Vector2.ZERO

## Whether the joystick is currently active (visible)
var _active: bool = false

## Outer ring and knob colors
var _outer_color: Color = Color(1.0, 1.0, 1.0, 0.15)
var _outer_border_color: Color = Color(1.0, 1.0, 1.0, 0.3)
var _knob_color: Color = Color(1.0, 1.0, 1.0, 0.35)
var _knob_border_color: Color = Color(1.0, 1.0, 1.0, 0.5)


func _ready() -> void:
	# This control covers the left half of the screen as a touch zone
	# but draws nothing when inactive
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _draw() -> void:
	if not _active:
		return

	var radius := outer_size * 0.5
	var knob_radius := knob_size * 0.5

	# Convert screen-space center to local coordinates
	var local_center := _joy_center - global_position

	# Outer ring background
	draw_circle(local_center, radius, _outer_color)
	# Outer ring border
	draw_arc(local_center, radius, 0.0, TAU, 64, _outer_border_color, 2.0)

	# Inner knob
	var knob_pos := local_center + _knob_offset
	draw_circle(knob_pos, knob_radius, _knob_color)
	draw_arc(knob_pos, knob_radius, 0.0, TAU, 32, _knob_border_color, 2.0)


func handle_touch_input(event: InputEvent) -> bool:
	## Process InputEventScreenTouch and InputEventScreenDrag.
	## Returns true if the event was consumed by this joystick.
	if event is InputEventScreenTouch:
		if event.pressed:
			# Only accept if no finger tracked yet and touch is within our rect
			if _touch_index == -1 and _is_in_touch_zone(event.position):
				_touch_index = event.index
				_joy_center = event.position
				_knob_offset = Vector2.ZERO
				direction = Vector2.ZERO
				_active = true
				queue_redraw()
				return true
		else:
			# Released
			if event.index == _touch_index:
				_release()
				return true

	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_knob(event.position)
			return true

	return false


func _release() -> void:
	_touch_index = -1
	_knob_offset = Vector2.ZERO
	direction = Vector2.ZERO
	_active = false
	queue_redraw()


func _update_knob(touch_pos: Vector2) -> void:
	var radius := outer_size * 0.5
	var delta := touch_pos - _joy_center
	var dist := delta.length()

	# Clamp knob to outer ring
	if dist > radius:
		delta = delta.normalized() * radius
		dist = radius

	_knob_offset = delta

	# Calculate normalized direction with dead zone
	var normalized := dist / radius
	if normalized < dead_zone:
		direction = Vector2.ZERO
	else:
		# Remap from [dead_zone..1] to [0..1]
		var strength := (normalized - dead_zone) / (1.0 - dead_zone)
		direction = delta.normalized() * strength

	queue_redraw()


func _is_in_touch_zone(pos: Vector2) -> bool:
	## Check if the screen position is within this control's rect
	var rect := get_global_rect()
	return rect.has_point(pos)


func get_direction() -> Vector2:
	return direction
