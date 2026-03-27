extends Control

## Tela de selecao de personagem — design moderno com cards e icones SVG.
## Grid de personagens na parte inferior, card grande no centro com detalhes.

var all_character_ids: Array[String] = []
var current_index: int = 0

# UI refs (created in _ready)
var _title: Label
var _char_grid: HBoxContainer
var _center_card: PanelContainer
var _card_icon: TextureRect
var _card_name: Label
var _card_passive: Label
var _card_weapon_icon: TextureRect
var _card_weapon_name: Label
var _card_lock: Label
var _start_btn: Button
var _back_btn: Button
var _char_buttons: Array[Button] = []
var _card_color_bar: ColorRect
var _stats_container: VBoxContainer

func _ready() -> void:
	_load_character_list()
	_find_first_unlocked()
	_build_ui()
	_update_selection()
	GamepadUI.notify_menu_opened()

func _load_character_list() -> void:
	all_character_ids.clear()
	for char_id in CharacterDB.get_all_character_ids():
		all_character_ids.append(char_id)

func _find_first_unlocked() -> void:
	for i in range(all_character_ids.size()):
		if SaveManager.is_character_unlocked(all_character_ids[i]):
			current_index = i
			return
	current_index = 0

func _build_ui() -> void:
	# Main layout
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# Title
	_title = Label.new()
	_title.text = "Escolha seu personagem"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.92))
	vbox.add_child(_title)

	# Center area (card + stats)
	var center_hbox = HBoxContainer.new()
	center_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_hbox.add_theme_constant_override("separation", 32)
	vbox.add_child(center_hbox)

	# Build center character card
	_build_center_card(center_hbox)

	# Build stats panel
	_build_stats_panel(center_hbox)

	# Character grid (bottom)
	var grid_scroll = ScrollContainer.new()
	grid_scroll.custom_minimum_size = Vector2(0, 100)
	grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	grid_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(grid_scroll)

	_char_grid = HBoxContainer.new()
	_char_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	_char_grid.add_theme_constant_override("separation", 8)
	grid_scroll.add_child(_char_grid)

	_build_character_grid()

	# Bottom buttons
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)

	_back_btn = _create_button("Voltar", Color(0.15, 0.12, 0.12))
	_back_btn.pressed.connect(_on_back)
	btn_hbox.add_child(_back_btn)

	_start_btn = _create_button("Jogar", Color(0.12, 0.2, 0.35))
	_start_btn.pressed.connect(_on_start)
	btn_hbox.add_child(_start_btn)

func _build_center_card(parent: Control) -> void:
	_center_card = PanelContainer.new()
	_center_card.custom_minimum_size = Vector2(280, 360)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.95)
	style.set_corner_radius_all(16)
	style.set_border_width_all(2)
	style.border_color = Color(0.2, 0.2, 0.3, 0.6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_center_card.add_theme_stylebox_override("panel", style)
	parent.add_child(_center_card)

	var card_vbox = VBoxContainer.new()
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_theme_constant_override("separation", 12)
	_center_card.add_child(card_vbox)

	# Color accent bar at top
	_card_color_bar = ColorRect.new()
	_card_color_bar.custom_minimum_size = Vector2(0, 4)
	_card_color_bar.color = Color.WHITE
	card_vbox.add_child(_card_color_bar)

	# Large character icon
	_card_icon = TextureRect.new()
	_card_icon.custom_minimum_size = Vector2(140, 140)
	_card_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_card_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card_vbox.add_child(_card_icon)

	# Character name
	_card_name = Label.new()
	_card_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_name.add_theme_font_size_override("font_size", 22)
	_card_name.add_theme_color_override("font_color", Color.WHITE)
	card_vbox.add_child(_card_name)

	# Passive ability
	_card_passive = Label.new()
	_card_passive.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_passive.autowrap_mode = TextServer.AUTOWRAP_WORD
	_card_passive.add_theme_font_size_override("font_size", 12)
	_card_passive.add_theme_color_override("font_color", Color(0.6, 0.8, 0.55))
	card_vbox.add_child(_card_passive)

	# Lock label
	_card_lock = Label.new()
	_card_lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_lock.autowrap_mode = TextServer.AUTOWRAP_WORD
	_card_lock.add_theme_font_size_override("font_size", 11)
	_card_lock.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	_card_lock.visible = false
	card_vbox.add_child(_card_lock)

func _build_stats_panel(parent: Control) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.8)
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	style.border_color = Color(0.15, 0.15, 0.2, 0.5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	_stats_container = VBoxContainer.new()
	_stats_container.add_theme_constant_override("separation", 14)
	panel.add_child(_stats_container)

	# Section title
	var title = Label.new()
	title.text = "Detalhes"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_stats_container.add_child(title)

	# Weapon row
	var weapon_row = HBoxContainer.new()
	weapon_row.add_theme_constant_override("separation", 8)
	_stats_container.add_child(weapon_row)

	_card_weapon_icon = TextureRect.new()
	_card_weapon_icon.custom_minimum_size = Vector2(32, 32)
	_card_weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_row.add_child(_card_weapon_icon)

	var weapon_vbox = VBoxContainer.new()
	weapon_vbox.add_theme_constant_override("separation", 0)
	weapon_row.add_child(weapon_vbox)

	var weapon_label_title = Label.new()
	weapon_label_title.text = "Arma inicial"
	weapon_label_title.add_theme_font_size_override("font_size", 10)
	weapon_label_title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	weapon_vbox.add_child(weapon_label_title)

	_card_weapon_name = Label.new()
	_card_weapon_name.add_theme_font_size_override("font_size", 14)
	_card_weapon_name.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	weapon_vbox.add_child(_card_weapon_name)

func _build_character_grid() -> void:
	for child in _char_grid.get_children():
		child.queue_free()
	_char_buttons.clear()

	for i in range(all_character_ids.size()):
		var char_id = all_character_ids[i]
		var data = CharacterDB.get_character(char_id)
		var is_locked = not SaveManager.is_character_unlocked(char_id)
		var char_color = data.get("color", Color(0.5, 0.5, 0.5))

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(72, 80)
		btn.tooltip_text = data.get("name", char_id)

		# Style
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0.08, 0.08, 0.12, 0.9)
		normal.set_corner_radius_all(10)
		normal.set_border_width_all(2)
		normal.border_color = Color(0.15, 0.15, 0.2) if is_locked else char_color.darkened(0.3)
		btn.add_theme_stylebox_override("normal", normal)

		var hover = normal.duplicate()
		hover.bg_color = Color(0.12, 0.12, 0.18, 0.95)
		hover.border_color = char_color if not is_locked else Color(0.25, 0.25, 0.3)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("focus", hover.duplicate())

		var pressed_style = normal.duplicate()
		pressed_style.bg_color = Color(0.15, 0.15, 0.22)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		# Content: icon + name
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(vbox)

		# Character icon
		var icon_path = "res://assets/icons/characters/%s.svg" % char_id
		if ResourceLoader.exists(icon_path):
			var tex = TextureRect.new()
			tex.texture = load(icon_path)
			tex.custom_minimum_size = Vector2(40, 40)
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if is_locked:
				tex.modulate = Color(0.3, 0.3, 0.3)
			vbox.add_child(tex)

		# Name label
		var name_lbl = Label.new()
		name_lbl.text = data.get("name", char_id).substr(0, 6)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7) if is_locked else Color(0.85, 0.85, 0.9))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(name_lbl)

		# Lock icon
		if is_locked:
			var lock = Label.new()
			lock.text = "🔒"
			lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock.add_theme_font_size_override("font_size", 8)
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(lock)

		var idx = i
		btn.pressed.connect(func(): _select_character(idx))
		_char_grid.add_child(btn)
		_char_buttons.append(btn)

func _update_selection() -> void:
	var char_id = all_character_ids[current_index]
	var data = CharacterDB.get_character(char_id)
	var is_locked = not SaveManager.is_character_unlocked(char_id)
	var char_color = data.get("color", Color(0.5, 0.5, 0.5))

	# Update center card
	_card_name.text = data.get("name", char_id).to_upper()
	_card_passive.text = data.get("passive", "")
	_card_color_bar.color = char_color

	# Character icon
	var icon_path = "res://assets/icons/characters/%s.svg" % char_id
	if ResourceLoader.exists(icon_path):
		_card_icon.texture = load(icon_path)
		_card_icon.modulate = Color(0.35, 0.35, 0.35) if is_locked else Color.WHITE
	else:
		_card_icon.texture = null

	# Weapon info
	var weapon_id = data.get("starting_weapon", "katana")
	var weapon_data = WeaponDB.get_weapon(weapon_id)
	_card_weapon_name.text = weapon_data.get("name", "???")
	var weapon_icon_path = "res://assets/icons/weapons/%s.svg" % weapon_id
	if ResourceLoader.exists(weapon_icon_path):
		_card_weapon_icon.texture = load(weapon_icon_path)
	else:
		_card_weapon_icon.texture = null

	# Lock state
	if is_locked:
		_card_lock.text = "🔒 %s" % data.get("unlock_description", "???")
		_card_lock.visible = true
		_start_btn.disabled = true
		_start_btn.text = "Bloqueado"
	else:
		_card_lock.visible = false
		_start_btn.disabled = false
		_start_btn.text = "Jogar"

	# Update card border to character color
	var card_style = _center_card.get_theme_stylebox("panel") as StyleBoxFlat
	if card_style:
		card_style.border_color = char_color.darkened(0.2) if not is_locked else Color(0.2, 0.2, 0.3, 0.6)

	# Highlight selected button in grid
	for i in range(_char_buttons.size()):
		var btn = _char_buttons[i]
		var btn_style = btn.get_theme_stylebox("normal") as StyleBoxFlat
		if btn_style:
			if i == current_index:
				btn_style.border_color = char_color
				btn_style.bg_color = Color(0.12, 0.12, 0.2, 0.95)
			else:
				var cid = all_character_ids[i]
				var cdata = CharacterDB.get_character(cid)
				var clocked = not SaveManager.is_character_unlocked(cid)
				var ccolor = cdata.get("color", Color(0.5, 0.5, 0.5))
				btn_style.border_color = Color(0.15, 0.15, 0.2) if clocked else ccolor.darkened(0.3)
				btn_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)

func _select_character(idx: int) -> void:
	current_index = idx
	_update_selection()

func _create_button(text: String, base_color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(140, 44)

	var normal = StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(8)
	normal.set_border_width_all(1)
	normal.border_color = base_color.lightened(0.2)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", normal)

	var hover = normal.duplicate()
	hover.bg_color = base_color.lightened(0.15)
	hover.border_color = base_color.lightened(0.4)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover.duplicate())
	btn.add_theme_stylebox_override("pressed", normal.duplicate())

	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.92))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

	return btn

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		current_index = (current_index - 1) % all_character_ids.size()
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		current_index = (current_index + 1) % all_character_ids.size()
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_start()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()

func _on_start() -> void:
	var char_id = all_character_ids[current_index]
	if SaveManager.is_character_unlocked(char_id):
		GameManager.selected_character = char_id
		get_tree().change_scene_to_file("res://scenes/ui/mutations_panel.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
