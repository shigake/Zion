class_name UICardBuilder

## Utilitario para construcao padronizada de cards de UI.
## Usado por bestiary, codex, achievements, character select, etc.

static func create_card(size: Vector2, border_color: Color, bg_color := UITheme.BG_PANEL) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = size
	btn.focus_mode = Control.FOCUS_ALL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_stylebox_override("normal", _make_style(bg_color, border_color))
	btn.add_theme_stylebox_override("hover", _make_style(bg_color.lightened(0.15), border_color.lightened(0.3)))
	btn.add_theme_stylebox_override("pressed", _make_style(bg_color.lightened(0.15), border_color.lightened(0.3)))
	var focus = _make_style(bg_color.lightened(0.15), UITheme.ACCENT_GOLD)
	focus.set_border_width_all(3)
	btn.add_theme_stylebox_override("focus", focus)
	return btn

static func create_card_vbox(parent: Button, separation: int = 3) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", separation)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return vbox

static func add_color_swatch(vbox: VBoxContainer, color: Color, height: float = 5.0) -> ColorRect:
	var swatch = ColorRect.new()
	swatch.custom_minimum_size = Vector2(0, height)
	swatch.color = color
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(swatch)
	return swatch

static func add_label(vbox: VBoxContainer, text: String, font_size: int, color: Color, center := true) -> Label:
	var lbl = Label.new()
	lbl.text = text
	if center:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)
	return lbl

static func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(2)
	sb.border_color = border
	return sb
