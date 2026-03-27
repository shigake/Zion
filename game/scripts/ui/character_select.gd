extends Control

## Tela de selecao de personagem — grid 4x3 com preview 3D do modelo.
## Layout: esquerda = grid de cards, direita = preview 3D + info.

const COLUMNS := 4
const ROWS := 3
const PER_PAGE := COLUMNS * ROWS

# Card dimensions
const CARD_MIN_SIZE := Vector2(150, 130)

# Colors
const COLOR_BG_CARD := Color(0.09, 0.09, 0.12, 0.95)
const COLOR_BG_CARD_SELECTED := Color(0.12, 0.12, 0.16, 1.0)
const COLOR_BG_CARD_LOCKED := Color(0.055, 0.055, 0.07, 0.9)
const COLOR_BORDER_LOCKED := Color(0.25, 0.25, 0.28)
const COLOR_LOCK_TEXT := Color(0.55, 0.4, 0.4)
const COLOR_WEAPON_TEXT := Color(0.55, 0.65, 0.78)
const COLOR_RIGHT_PANEL_BG := Color(0.05, 0.05, 0.07, 0.85)
const COLOR_ARROW_NORMAL := Color(0.35, 0.35, 0.4)
const COLOR_ARROW_HOVER := Color(0.7, 0.7, 0.8)

@onready var grid: GridContainer = $MarginContainer/MainVBox/ContentHBox/LeftPanel/GridRow/GridContainer
@onready var left_arrow: Button = $MarginContainer/MainVBox/ContentHBox/LeftPanel/GridRow/LeftArrow
@onready var right_arrow: Button = $MarginContainer/MainVBox/ContentHBox/LeftPanel/GridRow/RightArrow
@onready var page_label: Label = $MarginContainer/MainVBox/ContentHBox/LeftPanel/PageLabel
@onready var start_btn: Button = $MarginContainer/MainVBox/BottomHBox/StartButton
@onready var back_btn: Button = $MarginContainer/MainVBox/BottomHBox/BackButton
@onready var right_panel: PanelContainer = $MarginContainer/MainVBox/ContentHBox/RightPanel

@onready var char_name_label: Label = $MarginContainer/MainVBox/ContentHBox/RightPanel/PreviewVBox/InfoVBox/CharNameLabel
@onready var weapon_label: Label = $MarginContainer/MainVBox/ContentHBox/RightPanel/PreviewVBox/InfoVBox/WeaponLabel
@onready var passive_label: Label = $MarginContainer/MainVBox/ContentHBox/RightPanel/PreviewVBox/InfoVBox/PassiveLabel
@onready var model_root: Node3D = $MarginContainer/MainVBox/ContentHBox/RightPanel/PreviewVBox/SubViewportContainer/SubViewport/ModelRoot

var selected_character: String = "ronin"
var all_items: Array = []
var current_page: int = 0
var total_pages: int = 1
var _selected_card: PanelContainer = null
var _selected_style: StyleBoxFlat = null
var _selected_color: Color = Color.WHITE
var _preview_model: Node3D = null

# Keep references to card data for hover restore
var _card_data: Dictionary = {}  # card -> {style, color, char_id}


func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)
	left_arrow.pressed.connect(_prev_page)
	right_arrow.pressed.connect(_next_page)

	_style_right_panel()
	_style_buttons()
	_style_arrows()
	_load_items()
	_show_page(0)

	# Select ronin by default
	_select_first_unlocked()
	GamepadUI.notify_menu_opened()


func _style_right_panel() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_RIGHT_PANEL_BG
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.border_width_top = 1
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.12, 0.12, 0.16, 0.6)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	right_panel.add_theme_stylebox_override("panel", panel_style)


func _style_buttons() -> void:
	for btn in [start_btn, back_btn]:
		var normal = StyleBoxFlat.new()
		var hover = StyleBoxFlat.new()
		var pressed = StyleBoxFlat.new()

		var is_start = (btn == start_btn)
		var base_color = Color(0.18, 0.22, 0.35) if is_start else Color(0.12, 0.12, 0.15)

		for s in [normal, hover, pressed]:
			s.corner_radius_top_left = 6
			s.corner_radius_top_right = 6
			s.corner_radius_bottom_left = 6
			s.corner_radius_bottom_right = 6
			s.border_width_top = 1
			s.border_width_left = 1
			s.border_width_right = 1
			s.border_width_bottom = 1
			s.content_margin_left = 16
			s.content_margin_right = 16
			s.content_margin_top = 8
			s.content_margin_bottom = 8

		normal.bg_color = base_color
		normal.border_color = base_color.lightened(0.2)
		hover.bg_color = base_color.lightened(0.15)
		hover.border_color = base_color.lightened(0.35)
		pressed.bg_color = base_color.darkened(0.1)
		pressed.border_color = base_color.lightened(0.1)

		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("focus", hover.duplicate())
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		btn.add_theme_color_override("font_hover_color", Color.WHITE)


func _style_arrows() -> void:
	for btn in [left_arrow, right_arrow]:
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0.08, 0.08, 0.1, 0.8)
		normal.corner_radius_top_left = 4
		normal.corner_radius_top_right = 4
		normal.corner_radius_bottom_left = 4
		normal.corner_radius_bottom_right = 4
		normal.border_width_top = 1
		normal.border_width_left = 1
		normal.border_width_right = 1
		normal.border_width_bottom = 1
		normal.border_color = Color(0.2, 0.2, 0.25)

		var hover = normal.duplicate()
		hover.bg_color = Color(0.12, 0.12, 0.16, 0.9)
		hover.border_color = Color(0.35, 0.35, 0.45)

		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", hover.duplicate())
		btn.add_theme_stylebox_override("focus", hover.duplicate())
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", COLOR_ARROW_NORMAL)
		btn.add_theme_color_override("font_hover_color", COLOR_ARROW_HOVER)


func _load_items() -> void:
	all_items.clear()
	for char_id in CharacterDB.get_all_character_ids():
		var data = CharacterDB.get_character(char_id)
		all_items.append({"id": char_id, "data": data})
	total_pages = maxi(1, ceili(float(all_items.size()) / PER_PAGE))


func _show_page(page: int) -> void:
	current_page = clampi(page, 0, total_pages - 1)
	_card_data.clear()

	# Clear grid
	for child in grid.get_children():
		child.queue_free()

	var start_idx = current_page * PER_PAGE
	var end_idx = mini(start_idx + PER_PAGE, all_items.size())

	for i in range(start_idx, end_idx):
		var item = all_items[i]
		var char_id: String = item["id"]
		var data: Dictionary = item["data"]
		var is_locked: bool = not SaveManager.is_character_unlocked(char_id)
		var char_color: Color = data.get("color", Color(0.5, 0.5, 0.5))

		var card = _create_card(char_id, data, char_color, is_locked)
		grid.add_child(card)

	# Fill empty slots to maintain 4x3 grid
	var filled = end_idx - start_idx
	for i in range(filled, PER_PAGE):
		var spacer = Control.new()
		spacer.custom_minimum_size = CARD_MIN_SIZE
		grid.add_child(spacer)

	_update_arrows()
	_setup_grid_focus()


func _create_card(char_id: String, data: Dictionary, char_color: Color, is_locked: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = CARD_MIN_SIZE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Build card style
	var card_style = _make_card_style(char_color, is_locked, false)
	card.add_theme_stylebox_override("panel", card_style)

	# Store reference for hover/select logic
	_card_data[card] = {"style": card_style, "color": char_color, "id": char_id}

	# Content layout
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	# Color accent bar at top
	var color_bar = ColorRect.new()
	color_bar.custom_minimum_size = Vector2(0, 3)
	color_bar.color = char_color if not is_locked else Color(0.3, 0.3, 0.3)
	vbox.add_child(color_bar)

	# Character portrait icon
	var char_icon_path := "res://assets/icons/characters/%s.svg" % char_id
	var char_icon_tex = load(char_icon_path)
	if char_icon_tex:
		var icon_center = CenterContainer.new()
		var icon_rect = TextureRect.new()
		icon_rect.texture = char_icon_tex
		icon_rect.custom_minimum_size = Vector2(40, 40)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_center.add_child(icon_rect)
		vbox.add_child(icon_center)

	# Character name
	var name_lbl = Label.new()
	name_lbl.text = data["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	if is_locked:
		name_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.42))
	else:
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.93))
	vbox.add_child(name_lbl)

	# Weapon name with optional icon
	var weapon_id: String = data["starting_weapon"]
	var weapon_name = WeaponDB.get_weapon(weapon_id)["name"]
	var weapon_icon_path := "res://assets/icons/weapons/%s.svg" % weapon_id
	var weapon_icon_tex = load(weapon_icon_path)

	var weapon_hbox = HBoxContainer.new()
	weapon_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	weapon_hbox.add_theme_constant_override("separation", 4)

	if weapon_icon_tex:
		var wpn_icon = TextureRect.new()
		wpn_icon.texture = weapon_icon_tex
		wpn_icon.custom_minimum_size = Vector2(16, 16)
		wpn_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		weapon_hbox.add_child(wpn_icon)

	var weapon_lbl = Label.new()
	weapon_lbl.text = weapon_name
	weapon_lbl.add_theme_font_size_override("font_size", 10)
	if is_locked:
		weapon_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.38))
	else:
		weapon_lbl.add_theme_color_override("font_color", COLOR_WEAPON_TEXT)
	weapon_hbox.add_child(weapon_lbl)

	vbox.add_child(weapon_hbox)

	# Lock info for locked characters
	if is_locked:
		var lock_lbl = Label.new()
		var unlock_desc = data.get("unlock_description", "???")
		lock_lbl.text = "🔒 %s" % unlock_desc
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 9)
		lock_lbl.add_theme_color_override("font_color", COLOR_LOCK_TEXT)
		lock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lock_lbl)

	# Invisible clickable button overlay
	var btn = Button.new()
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.anchors_preset = Control.PRESET_FULL_RECT
	btn.anchor_right = 1.0
	btn.anchor_bottom = 1.0
	btn.disabled = is_locked
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	# Transparent stylebox so the button doesn't draw over the card
	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	btn.add_theme_stylebox_override("disabled", empty_style)

	if not is_locked:
		var cid = char_id
		var cdata = data
		var ccard = card
		btn.pressed.connect(func(): _select_character(cid, cdata, ccard))
		btn.mouse_entered.connect(func(): _on_card_hover(ccard, true))
		btn.mouse_exited.connect(func(): _on_card_hover(ccard, false))

	card.add_child(btn)
	return card


func _make_card_style(char_color: Color, is_locked: bool, is_selected: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()

	# Corner radius
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	# Borders
	style.border_width_top = 3
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_bottom = 1

	if is_locked:
		style.bg_color = COLOR_BG_CARD_LOCKED
		style.border_color = COLOR_BORDER_LOCKED
	elif is_selected:
		style.bg_color = char_color.darkened(0.72)
		style.border_color = char_color
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
	else:
		style.bg_color = COLOR_BG_CARD
		style.border_color = char_color.darkened(0.4)

	return style


func _on_card_hover(card: PanelContainer, entered: bool) -> void:
	if card == _selected_card:
		return
	if not card in _card_data:
		return

	var info = _card_data[card]
	var char_color: Color = info["color"]

	if entered:
		var hover_style = _make_card_style(char_color, false, false)
		hover_style.border_color = char_color.lightened(0.1)
		hover_style.bg_color = COLOR_BG_CARD.lightened(0.03)
		card.add_theme_stylebox_override("panel", hover_style)
		_card_data[card]["style"] = hover_style
	else:
		var normal_style = _make_card_style(char_color, false, false)
		card.add_theme_stylebox_override("panel", normal_style)
		_card_data[card]["style"] = normal_style


func _select_character(char_id: String, data: Dictionary, card: PanelContainer) -> void:
	selected_character = char_id

	if not card in _card_data:
		return

	var char_color: Color = _card_data[card]["color"]

	# Deselect previous card
	if _selected_card and is_instance_valid(_selected_card) and _selected_card != card:
		if _selected_card in _card_data:
			var old_color: Color = _card_data[_selected_card]["color"]
			var old_style = _make_card_style(old_color, false, false)
			_selected_card.add_theme_stylebox_override("panel", old_style)
			_card_data[_selected_card]["style"] = old_style

	# Select new card
	_selected_card = card
	_selected_color = char_color
	var sel_style = _make_card_style(char_color, false, true)
	card.add_theme_stylebox_override("panel", sel_style)
	_card_data[card]["style"] = sel_style

	_update_preview(char_id, data)


func _select_first_unlocked() -> void:
	for item in all_items:
		if SaveManager.is_character_unlocked(item["id"]):
			var data = item["data"]
			var char_id = item["id"]
			# Find card in grid
			for child in grid.get_children():
				if child is PanelContainer and child in _card_data:
					if _card_data[child]["id"] == char_id:
						_select_character(char_id, data, child)
						return
			# Fallback: just update preview without card highlight
			selected_character = char_id
			_update_preview(char_id, data)
			return


func _update_preview(char_id: String, data: Dictionary) -> void:
	# Remove previous model
	if _preview_model and is_instance_valid(_preview_model):
		_preview_model.queue_free()
		_preview_model = null

	# Load new model
	var model = ModelFactory.get_model_for_character(char_id)
	if model:
		model.position = Vector3(0, 0, 0)
		model.rotation = Vector3(0, PI, 0)  # Facing camera
		model_root.add_child(model)
		_preview_model = model

		# Apply materials for non-glb models
		var char_color = data.get("color", Color(0.5, 0.5, 0.5))
		ModelFactory.apply_model_materials(model, char_color)

	# Update info labels
	char_name_label.text = data.get("name", char_id).to_upper()
	var weapon_data = WeaponDB.get_weapon(data.get("starting_weapon", "katana"))
	weapon_label.text = "Arma: %s" % weapon_data.get("name", "???")
	passive_label.text = data.get("passive", "")


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


func _setup_grid_focus() -> void:
	var buttons: Array[Button] = []
	for child in grid.get_children():
		if child is PanelContainer:
			for sub in child.get_children():
				if sub is Button and not sub.disabled:
					sub.focus_mode = Control.FOCUS_ALL
					buttons.append(sub)
		elif child is Button and not child.disabled:
			child.focus_mode = Control.FOCUS_ALL
			buttons.append(child)

	for i in range(buttons.size()):
		var btn = buttons[i]
		if i % COLUMNS > 0 and i > 0:
			btn.focus_neighbor_left = buttons[i - 1].get_path()
		if i % COLUMNS < COLUMNS - 1 and i < buttons.size() - 1:
			btn.focus_neighbor_right = buttons[i + 1].get_path()
		if i >= COLUMNS:
			btn.focus_neighbor_top = buttons[i - COLUMNS].get_path()
		if i + COLUMNS < buttons.size():
			btn.focus_neighbor_bottom = buttons[i + COLUMNS].get_path()
		else:
			btn.focus_neighbor_bottom = start_btn.get_path()

	start_btn.focus_mode = Control.FOCUS_ALL
	back_btn.focus_mode = Control.FOCUS_ALL
	start_btn.focus_neighbor_left = back_btn.get_path()
	back_btn.focus_neighbor_right = start_btn.get_path()
	start_btn.focus_neighbor_bottom = back_btn.get_path()
	back_btn.focus_neighbor_top = start_btn.get_path()

	if not buttons.is_empty():
		var last_row_start = (buttons.size() - 1) / COLUMNS * COLUMNS
		start_btn.focus_neighbor_top = buttons[mini(buttons.size() - 1, last_row_start)].get_path()
		back_btn.focus_neighbor_bottom = buttons[0].get_path()
		buttons[0].call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


func _on_start() -> void:
	GameManager.selected_character = selected_character
	get_tree().change_scene_to_file("res://scenes/ui/stage_select.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
