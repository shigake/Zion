## TouchControls: virtual joystick + dash button for mobile.
## Only visible on mobile platforms (PlatformHelper.is_mobile()).
## Feeds input into the existing action system (move_left/right/up/down, dash).
extends CanvasLayer

var joystick: Control = null
var dash_button: Button = null

# Track which move actions are currently pressed by the joystick
var _move_actions_pressed: Dictionary = {
	"move_left": false,
	"move_right": false,
	"move_up": false,
	"move_down": false,
}


func _ready() -> void:
	layer = 10  # Above HUD
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not PlatformHelper.is_mobile():
		visible = false
		set_process(false)
		set_process_input(false)
		return

	_create_joystick()
	_create_dash_button()


func _create_joystick() -> void:
	# Touch zone covers the left half of the screen
	var joystick_script = preload("res://scripts/ui/virtual_joystick.gd")
	joystick = Control.new()
	joystick.set_script(joystick_script)
	joystick.name = "VirtualJoystick"

	# Left half of screen
	joystick.anchor_left = 0.0
	joystick.anchor_top = 0.0
	joystick.anchor_right = 0.5
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 0.0
	joystick.offset_top = 0.0
	joystick.offset_right = 0.0
	joystick.offset_bottom = 0.0

	# Allow touch input to pass through when not on joystick
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(joystick)


func _create_dash_button() -> void:
	dash_button = Button.new()
	dash_button.name = "DashButton"
	dash_button.text = "DASH"
	dash_button.custom_minimum_size = Vector2(80, 80)

	# Bottom-right corner, offset 20px from edges
	dash_button.anchor_left = 1.0
	dash_button.anchor_top = 1.0
	dash_button.anchor_right = 1.0
	dash_button.anchor_bottom = 1.0
	dash_button.offset_left = -100.0   # 80 + 20
	dash_button.offset_top = -100.0    # 80 + 20
	dash_button.offset_right = -20.0
	dash_button.offset_bottom = -20.0

	# Semi-transparent styling
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.85, 1.0, 0.25)
	normal_style.set_corner_radius_all(12)
	normal_style.set_border_width_all(2)
	normal_style.border_color = Color(0.2, 0.85, 1.0, 0.5)
	dash_button.add_theme_stylebox_override("normal", normal_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.2, 0.85, 1.0, 0.5)
	pressed_style.set_corner_radius_all(12)
	pressed_style.set_border_width_all(2)
	pressed_style.border_color = Color(0.2, 0.85, 1.0, 0.8)
	dash_button.add_theme_stylebox_override("pressed", pressed_style)

	var hover_style = normal_style.duplicate()
	dash_button.add_theme_stylebox_override("hover", hover_style)

	var focus_style = StyleBoxEmpty.new()
	dash_button.add_theme_stylebox_override("focus", focus_style)

	dash_button.add_theme_font_size_override("font_size", 16)
	dash_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.8))

	# Connect press/release signals
	dash_button.button_down.connect(_on_dash_pressed)
	dash_button.button_up.connect(_on_dash_released)

	add_child(dash_button)


func _input(event: InputEvent) -> void:
	if not PlatformHelper.is_mobile():
		return
	if joystick and joystick.has_method("handle_touch_input"):
		if joystick.handle_touch_input(event):
			if get_viewport(): get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not PlatformHelper.is_mobile() or joystick == null:
		return

	var dir: Vector2 = joystick.get_direction()

	# Horizontal movement
	_update_action("move_left", dir.x < -0.01)
	_update_action("move_right", dir.x > 0.01)

	# Vertical movement
	_update_action("move_up", dir.y < -0.01)
	_update_action("move_down", dir.y > 0.01)

	# Set action strengths for analog feel
	if dir.x < -0.01:
		Input.action_press("move_left", absf(dir.x))
	if dir.x > 0.01:
		Input.action_press("move_right", absf(dir.x))
	if dir.y < -0.01:
		Input.action_press("move_up", absf(dir.y))
	if dir.y > 0.01:
		Input.action_press("move_down", absf(dir.y))


func _update_action(action: String, should_be_pressed: bool) -> void:
	if should_be_pressed:
		if not _move_actions_pressed[action]:
			Input.action_press(action)
			_move_actions_pressed[action] = true
	else:
		if _move_actions_pressed[action]:
			Input.action_release(action)
			_move_actions_pressed[action] = false


func _on_dash_pressed() -> void:
	Input.action_press("dash")


func _on_dash_released() -> void:
	Input.action_release("dash")
