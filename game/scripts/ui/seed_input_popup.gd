extends CanvasLayer

## Popup para inserir coordenada dimensional (seed) antes de iniciar uma run.

signal seed_confirmed(seed_text: String)
signal cancelled

var _panel: PanelContainer
var _input: LineEdit
var _preview_label: Label
var _start_btn: Button
var _random_btn: Button
var _cancel_btn: Button

func _ready():
	layer = 50
	_build_ui()
	visible = false

func show_popup():
	visible = true
	_input.text = ""
	_update_preview()
	_input.grab_focus()

func _build_ui():
	# Dark overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# Center panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(500, 300)
	_panel.position = Vector2(390, 210)  # Centered in 1280x720

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.3, 0.6, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = LocaleManager.tr_key("seed_coordinate")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = LocaleManager.tr_key("seed_enter")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(subtitle)

	# Input field
	_input = LineEdit.new()
	_input.placeholder_text = "ABC123..."
	_input.max_length = 20
	_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_input.add_theme_font_size_override("font_size", 20)
	_input.text_changed.connect(func(_t): _update_preview())
	# Gamepad: focusable
	_input.focus_mode = Control.FOCUS_ALL
	vbox.add_child(_input)

	# Preview
	_preview_label = Label.new()
	_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_label.add_theme_font_size_override("font_size", 13)
	_preview_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(_preview_label)

	# Button row
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	_random_btn = Button.new()
	_random_btn.text = LocaleManager.tr_key("seed_random")
	_random_btn.pressed.connect(_on_random)
	_random_btn.focus_mode = Control.FOCUS_ALL
	btn_row.add_child(_random_btn)

	_start_btn = Button.new()
	_start_btn.text = LocaleManager.tr_key("seed_start")
	_start_btn.pressed.connect(_on_confirm)
	_start_btn.focus_mode = Control.FOCUS_ALL
	btn_row.add_child(_start_btn)

	_cancel_btn = Button.new()
	_cancel_btn.text = LocaleManager.tr_key("seed_cancel")
	_cancel_btn.pressed.connect(_on_cancel)
	_cancel_btn.focus_mode = Control.FOCUS_ALL
	btn_row.add_child(_cancel_btn)

	# Gamepad focus neighbors (circular: random <-> start <-> cancel)
	_random_btn.focus_neighbor_right = _start_btn.get_path()
	_random_btn.focus_neighbor_left = _cancel_btn.get_path()
	_start_btn.focus_neighbor_right = _cancel_btn.get_path()
	_start_btn.focus_neighbor_left = _random_btn.get_path()
	_cancel_btn.focus_neighbor_right = _random_btn.get_path()
	_cancel_btn.focus_neighbor_left = _start_btn.get_path()
	# Vertical: input <-> buttons
	_input.focus_neighbor_bottom = _random_btn.get_path()
	_random_btn.focus_neighbor_top = _input.get_path()
	_start_btn.focus_neighbor_top = _input.get_path()
	_cancel_btn.focus_neighbor_top = _input.get_path()

func _update_preview():
	var seed_text = _input.text.strip_edges()
	if seed_text == "":
		_preview_label.text = LocaleManager.tr_key("seed_none")
	else:
		var h = hash(seed_text)
		# Coordinate ID (short hex)
		var coord_id = "%06X" % (absi(h) % 0xFFFFFF)
		# Difficulty modifier derived from seed (0-25%)
		var preview_rng = RandomNumberGenerator.new()
		preview_rng.seed = h
		var difficulty_mod = preview_rng.randi_range(0, 25)
		# Number of random events this seed will produce (2-5)
		var event_count = 10 + preview_rng.randi_range(0, 3)
		var lines = PackedStringArray()
		lines.append(LocaleManager.tr_key("seed_coordinate_short") + ": " + coord_id)
		lines.append(LocaleManager.tr_key("seed_preview_difficulty") % str(difficulty_mod))
		lines.append(LocaleManager.tr_key("seed_preview_events") % str(event_count))
		_preview_label.text = "\n".join(lines)

func _on_random():
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var result = ""
	for i in range(8):
		result += chars[randi() % chars.length()]
	_input.text = result
	_update_preview()

func _on_confirm():
	var seed_text = _input.text.strip_edges()
	seed_confirmed.emit(seed_text)
	visible = false

func _on_cancel():
	cancelled.emit()
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel()
		if get_viewport():
			get_viewport().set_input_as_handled()
