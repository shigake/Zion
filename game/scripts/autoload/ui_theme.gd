extends Node

## Sistema de tema visual. Aplica estilo consistente a todo UI do jogo.

var theme: Theme

# Color palette
const BG_DARK := Color(0.08, 0.08, 0.12)
const BG_PANEL := Color(0.12, 0.12, 0.18)
const BG_BUTTON := Color(0.15, 0.15, 0.22)
const BG_BUTTON_HOVER := Color(0.2, 0.2, 0.3)
const BG_BUTTON_PRESSED := Color(0.1, 0.3, 0.5)
const BG_BUTTON_DISABLED := Color(0.1, 0.1, 0.13)
const TEXT_PRIMARY := Color(0.95, 0.95, 0.95)
const TEXT_SECONDARY := Color(0.7, 0.7, 0.75)
const TEXT_DISABLED := Color(0.4, 0.4, 0.45)
const ACCENT_BLUE := Color(0.3, 0.6, 1.0)
const ACCENT_GOLD := Color(1.0, 0.85, 0.2)
const ACCENT_RED := Color(1.0, 0.3, 0.3)
const ACCENT_GREEN := Color(0.3, 0.9, 0.4)
const BORDER_COLOR := Color(0.25, 0.25, 0.35)

func _ready() -> void:
	theme = Theme.new()
	_setup_default_font()
	_setup_button_style()
	_setup_panel_style()
	_setup_label_style()
	_setup_progress_bar_style()
	_setup_separator_style()
	_setup_scroll_style()
	_setup_check_button_style()
	_setup_option_button_style()
	_setup_slider_style()

	# Apply to all future UI
	get_tree().root.theme = theme

func _setup_default_font() -> void:
	# Use default font but set size
	theme.set_default_font_size(18)

func _setup_button_style() -> void:
	# Normal
	var normal = StyleBoxFlat.new()
	normal.bg_color = BG_BUTTON
	normal.border_color = BORDER_COLOR
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(12)
	theme.set_stylebox("normal", "Button", normal)

	# Hover
	var hover = normal.duplicate()
	hover.bg_color = BG_BUTTON_HOVER
	hover.border_color = ACCENT_BLUE
	theme.set_stylebox("hover", "Button", hover)

	# Pressed
	var pressed = normal.duplicate()
	pressed.bg_color = BG_BUTTON_PRESSED
	pressed.border_color = ACCENT_BLUE
	theme.set_stylebox("pressed", "Button", pressed)

	# Disabled
	var disabled = normal.duplicate()
	disabled.bg_color = BG_BUTTON_DISABLED
	disabled.border_color = Color(0.15, 0.15, 0.2)
	theme.set_stylebox("disabled", "Button", disabled)

	# Colors
	theme.set_color("font_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", ACCENT_BLUE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", TEXT_DISABLED)

func _setup_panel_style() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = BG_PANEL
	panel_style.border_color = BORDER_COLOR
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(16)
	theme.set_stylebox("panel", "PanelContainer", panel_style)

func _setup_label_style() -> void:
	theme.set_color("font_color", "Label", TEXT_PRIMARY)
	theme.set_font_size("font_size", "Label", 18)

func _setup_progress_bar_style() -> void:
	# Background
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.15)
	bg.set_corner_radius_all(4)
	bg.set_border_width_all(1)
	bg.border_color = BORDER_COLOR
	theme.set_stylebox("background", "ProgressBar", bg)

	# Fill
	var fill = StyleBoxFlat.new()
	fill.bg_color = ACCENT_BLUE
	fill.set_corner_radius_all(4)
	theme.set_stylebox("fill", "ProgressBar", fill)

func _setup_separator_style() -> void:
	var sep = StyleBoxFlat.new()
	sep.bg_color = BORDER_COLOR
	sep.set_content_margin_all(0)
	sep.content_margin_top = 4
	sep.content_margin_bottom = 4
	theme.set_stylebox("separator", "HSeparator", sep)
	theme.set_constant("separation", "HSeparator", 8)

func _setup_scroll_style() -> void:
	var scroll_bg = StyleBoxFlat.new()
	scroll_bg.bg_color = Color(0.1, 0.1, 0.15)
	scroll_bg.set_corner_radius_all(3)
	theme.set_stylebox("scroll", "VScrollBar", scroll_bg)

	var grabber = StyleBoxFlat.new()
	grabber.bg_color = Color(0.25, 0.25, 0.35)
	grabber.set_corner_radius_all(3)
	theme.set_stylebox("grabber", "VScrollBar", grabber)

func _setup_check_button_style() -> void:
	theme.set_color("font_color", "CheckButton", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "CheckButton", ACCENT_BLUE)

func _setup_option_button_style() -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = BG_BUTTON
	normal.border_color = BORDER_COLOR
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(8)
	theme.set_stylebox("normal", "OptionButton", normal)
	theme.set_color("font_color", "OptionButton", TEXT_PRIMARY)

func _setup_slider_style() -> void:
	# Track (slider background)
	var slider_bg = StyleBoxFlat.new()
	slider_bg.bg_color = Color(0.1, 0.1, 0.15)
	slider_bg.set_corner_radius_all(4)
	slider_bg.set_content_margin_all(0)
	slider_bg.content_margin_top = 2
	slider_bg.content_margin_bottom = 2
	theme.set_stylebox("slider", "HSlider", slider_bg)

	# Grabber area (filled portion)
	var grabber_area = StyleBoxFlat.new()
	grabber_area.bg_color = ACCENT_BLUE
	grabber_area.set_corner_radius_all(4)
	grabber_area.set_content_margin_all(0)
	grabber_area.content_margin_top = 2
	grabber_area.content_margin_bottom = 2
	theme.set_stylebox("grabber_area", "HSlider", grabber_area)

	# Grabber area highlight (when hovered/dragged)
	var grabber_area_hl = grabber_area.duplicate()
	grabber_area_hl.bg_color = ACCENT_BLUE.lightened(0.15)
	theme.set_stylebox("grabber_area_highlight", "HSlider", grabber_area_hl)

	# Grabber (the handle)
	var grabber = StyleBoxFlat.new()
	grabber.bg_color = TEXT_PRIMARY
	grabber.set_corner_radius_all(10)
	grabber.set_content_margin_all(0)
	theme.set_stylebox("grabber", "HSlider", grabber)

	# Grabber highlight
	var grabber_hl = grabber.duplicate()
	grabber_hl.bg_color = ACCENT_BLUE
	theme.set_stylebox("grabber_highlight", "HSlider", grabber_hl)

	# Grabber disabled
	var grabber_dis = grabber.duplicate()
	grabber_dis.bg_color = TEXT_DISABLED
	theme.set_stylebox("grabber_disabled", "HSlider", grabber_dis)

	# Sizes
	theme.set_constant("grabber_offset", "HSlider", 1)
	theme.set_constant("center_grabber", "HSlider", 1)
