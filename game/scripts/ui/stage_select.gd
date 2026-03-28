extends Control

## Stage selection screen — polished 5x2 grid with themed cards.

const COLUMNS := 5
const ROWS := 2
const PER_PAGE := COLUMNS * ROWS
const CARD_SIZE := Vector2(140, 70)
const THEME_BAR_HEIGHT := 3.0

# Theme colors per stage
const STAGE_COLORS := {
	"cemetery": Color(0.5, 0.4, 0.6),
	"forest": Color(0.2, 0.6, 0.2),
	"farm": Color(0.7, 0.5, 0.2),
	"tokyo": Color(0.9, 0.2, 0.5),
	"volcano": Color(0.9, 0.3, 0.1),
	"ocean": Color(0.2, 0.4, 0.8),
	"arena": Color(0.8, 0.7, 0.3),
	"space": Color(0.4, 0.5, 0.9),
	"castle": Color(0.4, 0.2, 0.5),
	"candy": Color(0.9, 0.5, 0.6),
}

@onready var grid: GridContainer = $VBox/GridRow/GridContainer
@onready var left_arrow: Button = $VBox/GridRow/LeftArrow
@onready var right_arrow: Button = $VBox/GridRow/RightArrow
@onready var page_label: Label = $VBox/PageLabel
@onready var info_name: Label = $VBox/InfoPanel/InfoVBox/InfoName
@onready var info_desc: Label = $VBox/InfoPanel/InfoVBox/InfoDesc
@onready var info_panel: PanelContainer = $VBox/InfoPanel
@onready var next_btn: Button = $VBox/ButtonRow/NextButton
@onready var back_btn: Button = $VBox/ButtonRow/BackButton

var selected_stage: String = "cemetery"
var current_page: int = 0
var total_pages: int = 1
var _selected_btn: Button = null
var _card_buttons: Array[Button] = []

var stage_ids: Array[String] = [
	"cemetery", "forest", "farm", "tokyo", "volcano",
	"ocean", "arena", "space", "castle", "candy",
]

func _get_stage_data(stage_id: String) -> Dictionary:
	return {
		"id": stage_id,
		"name": LocaleManager.tr_key("stage_" + stage_id),
		"description": LocaleManager.tr_key("stage_" + stage_id + "_desc"),
	}

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	next_btn.pressed.connect(_on_next)
	back_btn.pressed.connect(_on_back)
	left_arrow.pressed.connect(_prev_page)
	right_arrow.pressed.connect(_next_page)

	_style_info_panel()
	_style_buttons()
	_style_arrows()

	total_pages = maxi(1, ceili(float(stage_ids.size()) / PER_PAGE))
	_show_page(0)
	_select_stage(_get_stage_data(stage_ids[0]))
	GamepadUI.notify_menu_opened()

# ── Styling ──────────────────────────────────────────────────────────

func _style_info_panel() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.07, 0.1, 1.0)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	info_panel.add_theme_stylebox_override("panel", sb)

func _style_buttons() -> void:
	for btn in [next_btn, back_btn]:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.12, 0.12, 0.16, 1.0)
		normal.set_corner_radius_all(6)
		normal.set_border_width_all(1)
		normal.border_color = Color(0.25, 0.25, 0.3, 1.0)
		btn.add_theme_stylebox_override("normal", normal)

		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.16, 0.16, 0.22, 1.0)
		hover.set_corner_radius_all(6)
		hover.set_border_width_all(1)
		hover.border_color = Color(0.4, 0.4, 0.5, 1.0)
		btn.add_theme_stylebox_override("hover", hover)

		var pressed := StyleBoxFlat.new()
		pressed.bg_color = Color(0.1, 0.1, 0.14, 1.0)
		pressed.set_corner_radius_all(6)
		pressed.set_border_width_all(1)
		pressed.border_color = Color(0.3, 0.5, 0.8, 1.0)
		btn.add_theme_stylebox_override("pressed", pressed)

		var focus := StyleBoxFlat.new()
		focus.bg_color = Color(0.14, 0.14, 0.2, 1.0)
		focus.set_corner_radius_all(6)
		focus.set_border_width_all(2)
		focus.border_color = Color(0.3, 0.5, 0.9, 1.0)
		btn.add_theme_stylebox_override("focus", focus)

		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		btn.add_theme_font_size_override("font_size", 14)

func _style_arrows() -> void:
	for btn in [left_arrow, right_arrow]:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.08, 0.08, 0.12, 1.0)
		normal.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", normal)

		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.14, 0.14, 0.2, 1.0)
		hover.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("hover", hover)

		var disabled := StyleBoxFlat.new()
		disabled.bg_color = Color(0.06, 0.06, 0.08, 1.0)
		disabled.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("disabled", disabled)

		btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		btn.add_theme_color_override("font_disabled_color", Color(0.25, 0.25, 0.3))
		btn.add_theme_font_size_override("font_size", 16)

# ── Card creation ────────────────────────────────────────────────────

func _create_card_style(stage_id: String, is_locked: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	var theme_color: Color = STAGE_COLORS.get(stage_id, Color(0.4, 0.4, 0.5))

	if is_locked:
		sb.bg_color = Color(0.06, 0.06, 0.08, 1.0)
		sb.border_color = Color(0.15, 0.15, 0.18, 1.0)
		sb.border_width_top = int(THEME_BAR_HEIGHT)
		sb.set_border_width_all(1)
		sb.border_width_top = int(THEME_BAR_HEIGHT)
		# Desaturate the top bar for locked stages
		var gray_color := Color(0.2, 0.2, 0.22, 1.0)
		sb.border_color = gray_color
	else:
		sb.bg_color = Color(0.09, 0.09, 0.13, 1.0)
		sb.set_border_width_all(1)
		sb.border_width_top = int(THEME_BAR_HEIGHT)
		sb.border_color = Color(0.18, 0.18, 0.22, 1.0)
		# Override top border with theme color
		# We achieve the colored top bar via a custom draw on the button

	sb.set_corner_radius_all(5)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 6.0
	return sb

func _create_card_hover_style(stage_id: String) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.17, 1.0)
	sb.set_border_width_all(1)
	sb.border_width_top = int(THEME_BAR_HEIGHT)
	sb.border_color = Color(0.25, 0.25, 0.32, 1.0)
	sb.set_corner_radius_all(5)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 6.0
	return sb

func _create_card_selected_style(stage_id: String) -> StyleBoxFlat:
	var theme_color: Color = STAGE_COLORS.get(stage_id, Color(0.4, 0.4, 0.5))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.16, 1.0)
	sb.set_border_width_all(2)
	sb.border_width_top = int(THEME_BAR_HEIGHT)
	sb.border_color = theme_color.lerp(Color.WHITE, 0.2)
	sb.set_corner_radius_all(5)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 6.0
	return sb

func _create_stage_card(stage_id: String) -> Button:
	var stage := _get_stage_data(stage_id)
	var unlocked := SaveManager.is_stage_unlocked(stage_id)
	var theme_color: Color = STAGE_COLORS.get(stage_id, Color(0.4, 0.4, 0.5))

	var btn := Button.new()
	btn.custom_minimum_size = CARD_SIZE
	btn.clip_text = true

	# Style the card
	var normal_style := _create_card_style(stage_id, not unlocked)
	btn.add_theme_stylebox_override("normal", normal_style)

	if unlocked:
		btn.text = stage["name"]
		btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

		var hover_style := _create_card_hover_style(stage_id)
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style := _create_card_style(stage_id, false)
		pressed_style.bg_color = Color(0.08, 0.08, 0.11, 1.0)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		var focus_style := _create_card_hover_style(stage_id)
		focus_style.border_color = theme_color.lerp(Color.WHITE, 0.3)
		focus_style.set_border_width_all(2)
		focus_style.border_width_top = int(THEME_BAR_HEIGHT)
		btn.add_theme_stylebox_override("focus", focus_style)
	else:
		btn.text = stage["name"] + "\n" + LocaleManager.tr_key("locked")
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
		btn.add_theme_color_override("font_disabled_color", Color(0.3, 0.3, 0.35))

		var disabled_style := _create_card_style(stage_id, true)
		btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.add_theme_font_size_override("font_size", 12)

	# Stage icon
	var stage_icon_path := "res://assets/sprites/stages/%s.png" % stage_id
	var stage_icon_tex = load(stage_icon_path) if ResourceLoader.exists(stage_icon_path) else null
	if stage_icon_tex:
		btn.icon = stage_icon_tex
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.expand_icon = true
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Draw the colored top bar via the draw signal
	if unlocked:
		var color_ref := theme_color
		btn.draw.connect(func():
			var bar_rect := Rect2(0, 0, btn.size.x, THEME_BAR_HEIGHT)
			btn.draw_rect(bar_rect, color_ref)
		)
	else:
		btn.draw.connect(func():
			var bar_rect := Rect2(0, 0, btn.size.x, THEME_BAR_HEIGHT)
			btn.draw_rect(bar_rect, Color(0.2, 0.2, 0.22, 1.0))
		)

	if unlocked:
		var captured_btn := btn
		btn.pressed.connect(func(): _select_stage(stage, captured_btn))

	btn.set_meta("stage_id", stage_id)
	return btn

# ── Page management ──────────────────────────────────────────────────

func _show_page(page: int) -> void:
	current_page = clampi(page, 0, total_pages - 1)
	_card_buttons.clear()

	for child in grid.get_children():
		child.queue_free()

	var start_idx := current_page * PER_PAGE
	var end_idx := mini(start_idx + PER_PAGE, stage_ids.size())

	for i in range(start_idx, end_idx):
		var btn := _create_stage_card(stage_ids[i])
		grid.add_child(btn)
		if not btn.disabled:
			_card_buttons.append(btn)

	# Fill empty slots to keep grid layout
	var filled := end_idx - start_idx
	for i in range(filled, PER_PAGE):
		var spacer := Control.new()
		spacer.custom_minimum_size = CARD_SIZE
		grid.add_child(spacer)

	_update_arrows()
	_setup_grid_focus()

func _update_arrows() -> void:
	left_arrow.visible = total_pages > 1
	right_arrow.visible = total_pages > 1
	left_arrow.disabled = current_page <= 0
	right_arrow.disabled = current_page >= total_pages - 1
	if total_pages > 1:
		page_label.text = "%d / %d" % [current_page + 1, total_pages]
		page_label.visible = true
	else:
		page_label.visible = false

func _prev_page() -> void:
	_show_page(current_page - 1)

func _next_page() -> void:
	_show_page(current_page + 1)

# ── Selection ────────────────────────────────────────────────────────

func _select_stage(stage: Dictionary, btn: Button = null) -> void:
	selected_stage = stage["id"]
	info_name.text = stage["name"]
	info_desc.text = stage["description"]

	# Update info panel border to match stage color
	var theme_color: Color = STAGE_COLORS.get(stage["id"], Color(0.4, 0.4, 0.5))
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.07, 0.07, 0.1, 1.0)
	panel_sb.set_corner_radius_all(6)
	panel_sb.set_border_width_all(1)
	panel_sb.border_color = theme_color.lerp(Color(0.07, 0.07, 0.1), 0.5)
	panel_sb.content_margin_left = 16.0
	panel_sb.content_margin_right = 16.0
	panel_sb.content_margin_top = 10.0
	panel_sb.content_margin_bottom = 10.0
	info_panel.add_theme_stylebox_override("panel", panel_sb)

	# Update name color to match stage
	info_name.add_theme_color_override("font_color", theme_color.lerp(Color.WHITE, 0.4))

	# Deselect previous card
	if _selected_btn and is_instance_valid(_selected_btn):
		var prev_id: String = _selected_btn.get_meta("stage_id", "")
		var normal_style := _create_card_style(prev_id, false)
		_selected_btn.add_theme_stylebox_override("normal", normal_style)

	# Highlight new selected card
	if btn:
		_selected_btn = btn
		var selected_style := _create_card_selected_style(stage["id"])
		_selected_btn.add_theme_stylebox_override("normal", selected_style)

# ── Focus / Gamepad ──────────────────────────────────────────────────

func _setup_grid_focus() -> void:
	var buttons: Array[Button] = []
	for child in grid.get_children():
		if child is Button and not child.disabled:
			child.focus_mode = Control.FOCUS_ALL
			buttons.append(child)

	for i in range(buttons.size()):
		var btn := buttons[i]
		if i % COLUMNS > 0 and i > 0:
			btn.focus_neighbor_left = buttons[i - 1].get_path()
		if i % COLUMNS < COLUMNS - 1 and i < buttons.size() - 1:
			btn.focus_neighbor_right = buttons[i + 1].get_path()
		if i >= COLUMNS:
			btn.focus_neighbor_top = buttons[i - COLUMNS].get_path()
		if i + COLUMNS < buttons.size():
			btn.focus_neighbor_bottom = buttons[i + COLUMNS].get_path()
		else:
			btn.focus_neighbor_bottom = next_btn.get_path()

	next_btn.focus_mode = Control.FOCUS_ALL
	back_btn.focus_mode = Control.FOCUS_ALL
	next_btn.focus_neighbor_left = back_btn.get_path()
	back_btn.focus_neighbor_right = next_btn.get_path()
	next_btn.focus_neighbor_bottom = back_btn.get_path()
	back_btn.focus_neighbor_top = next_btn.get_path()

	if not buttons.is_empty():
		next_btn.focus_neighbor_top = buttons[buttons.size() - 1].get_path()
		back_btn.focus_neighbor_bottom = buttons[0].get_path()
		buttons[0].call_deferred("grab_focus")

# ── Input ────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		if get_viewport(): get_viewport().set_input_as_handled()

func _on_next() -> void:
	AudioManager.play_sfx("menu_click")
	GameManager.selected_stage = selected_stage
	get_tree().change_scene_to_file("res://scenes/ui/relic_select.tscn")

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
