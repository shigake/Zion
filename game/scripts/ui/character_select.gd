extends Control

## Tela de selecao de personagem — grid 4x3 com paginacao.

const COLUMNS := 4
const ROWS := 3
const PER_PAGE := COLUMNS * ROWS

@onready var grid: GridContainer = $VBox/GridRow/GridContainer
@onready var left_arrow: Button = $VBox/GridRow/LeftArrow
@onready var right_arrow: Button = $VBox/GridRow/RightArrow
@onready var page_label: Label = $VBox/PageLabel
@onready var info_label: Label = $VBox/InfoLabel
@onready var start_btn: Button = $VBox/StartButton
@onready var back_btn: Button = $VBox/BackButton

var selected_character: String = "ronin"
var all_items: Array = []
var current_page: int = 0
var total_pages: int = 1
var _selected_btn: Button = null
var _selected_card: PanelContainer = null

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)
	left_arrow.pressed.connect(_prev_page)
	right_arrow.pressed.connect(_next_page)
	_load_items()
	_show_page(0)
	# Seleciona ronin (primeiro)
	var ronin_data = CharacterDB.get_character("ronin")
	info_label.text = "%s — Arma: %s\n%s" % [
		ronin_data["name"],
		WeaponDB.get_weapon(ronin_data["starting_weapon"])["name"],
		ronin_data["passive"]
	]
	GamepadUI.notify_menu_opened()

func _load_items() -> void:
	all_items.clear()
	for char_id in CharacterDB.get_all_character_ids():
		var data = CharacterDB.get_character(char_id)
		all_items.append({"id": char_id, "data": data})
	total_pages = maxi(1, ceili(float(all_items.size()) / PER_PAGE))

func _show_page(page: int) -> void:
	current_page = clampi(page, 0, total_pages - 1)

	# Limpa grid
	for child in grid.get_children():
		child.queue_free()

	var start_idx = current_page * PER_PAGE
	var end_idx = mini(start_idx + PER_PAGE, all_items.size())

	for i in range(start_idx, end_idx):
		var item = all_items[i]
		var char_id = item["id"]
		var data = item["data"]

		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(150, 90)

		# Card style with character color
		var char_color = data.get("color", Color(0.5, 0.5, 0.5))
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.1, 0.1, 0.14, 0.95)
		card_style.corner_radius_top_left = 8
		card_style.corner_radius_top_right = 8
		card_style.corner_radius_bottom_left = 8
		card_style.corner_radius_bottom_right = 8
		card_style.border_width_top = 3
		card_style.border_width_left = 1
		card_style.border_width_right = 1
		card_style.border_width_bottom = 1
		card_style.border_color = char_color.darkened(0.3)
		card_style.content_margin_left = 6
		card_style.content_margin_right = 6
		card_style.content_margin_top = 6
		card_style.content_margin_bottom = 6
		card.add_theme_stylebox_override("panel", card_style)

		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)
		card.add_child(vbox)

		# Color indicator bar
		var color_bar = ColorRect.new()
		color_bar.custom_minimum_size = Vector2(0, 4)
		color_bar.color = char_color
		vbox.add_child(color_bar)

		# Character name
		var name_lbl = Label.new()
		name_lbl.text = data["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		vbox.add_child(name_lbl)

		# Starting weapon
		var weapon_name = WeaponDB.get_weapon(data["starting_weapon"])["name"]
		var weapon_lbl = Label.new()
		weapon_lbl.text = "⚔ %s" % weapon_name
		weapon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		weapon_lbl.add_theme_font_size_override("font_size", 10)
		weapon_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
		vbox.add_child(weapon_lbl)

		# Passive
		var passive_lbl = Label.new()
		passive_lbl.text = data["passive"]
		passive_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		passive_lbl.add_theme_font_size_override("font_size", 10)
		passive_lbl.add_theme_color_override("font_color", char_color.lightened(0.3))
		passive_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(passive_lbl)

		# Locked overlay
		var is_locked = not SaveManager.is_character_unlocked(char_id)
		if is_locked:
			var lock_lbl = Label.new()
			var unlock_desc = data.get("unlock_description", "???")
			lock_lbl.text = "🔒 %s" % unlock_desc
			lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_lbl.add_theme_font_size_override("font_size", 9)
			lock_lbl.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
			lock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(lock_lbl)
			card_style.bg_color = Color(0.06, 0.06, 0.08, 0.95)
			card_style.border_color = Color(0.3, 0.3, 0.3)

		# Clickable button overlay
		var btn = Button.new()
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.anchors_preset = Control.PRESET_FULL_RECT
		btn.anchor_right = 1.0
		btn.anchor_bottom = 1.0
		btn.disabled = is_locked

		if not is_locked:
			var b = btn
			var cid = char_id
			var cdata = data
			var ccard = card
			var cstyle = card_style
			var ccolor = char_color
			b.pressed.connect(func(): _select_character(cid, cdata, ccard, cstyle, ccolor))
			b.mouse_entered.connect(func(): cstyle.border_color = ccolor; ccard.add_theme_stylebox_override("panel", cstyle))
			b.mouse_exited.connect(func():
				if ccard != _selected_card:
					cstyle.border_color = ccolor.darkened(0.3)
					ccard.add_theme_stylebox_override("panel", cstyle)
			)
		card.add_child(btn)
		grid.add_child(card)

	# Preenche slots vazios para manter layout 4x3
	var filled = end_idx - start_idx
	for i in range(filled, PER_PAGE):
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(150, 90)
		grid.add_child(spacer)

	_update_arrows()
	# Gamepad: configura foco nos botoes do grid
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

func _select_character(char_id: String, data: Dictionary, card: PanelContainer = null, card_style: StyleBoxFlat = null, char_color: Color = Color.WHITE) -> void:
	selected_character = char_id
	info_label.text = "%s — Arma: %s\n%s" % [
		data["name"],
		WeaponDB.get_weapon(data["starting_weapon"])["name"],
		data["passive"]
	]
	# Highlight selected card
	if card and card_style:
		# Reset previous selection
		if _selected_card and is_instance_valid(_selected_card) and _selected_card != card:
			_selected_card.remove_theme_stylebox_override("panel")
		_selected_card = card
		card_style.border_color = char_color
		card_style.border_width_left = 2
		card_style.border_width_right = 2
		card_style.border_width_bottom = 2
		card_style.bg_color = char_color.darkened(0.75)
		card.add_theme_stylebox_override("panel", card_style)

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
	# Grid focus: cima/baixo pula COLUMNS, esquerda/direita pula 1
	for i in range(buttons.size()):
		var btn = buttons[i]
		# Esquerda
		if i % COLUMNS > 0 and i > 0:
			btn.focus_neighbor_left = buttons[i - 1].get_path()
		# Direita
		if i % COLUMNS < COLUMNS - 1 and i < buttons.size() - 1:
			btn.focus_neighbor_right = buttons[i + 1].get_path()
		# Cima
		if i >= COLUMNS:
			btn.focus_neighbor_top = buttons[i - COLUMNS].get_path()
		# Baixo
		if i + COLUMNS < buttons.size():
			btn.focus_neighbor_bottom = buttons[i + COLUMNS].get_path()
		else:
			# Ultimo row: baixo vai para Start
			btn.focus_neighbor_bottom = start_btn.get_path()
	# Start e Back
	start_btn.focus_mode = Control.FOCUS_ALL
	back_btn.focus_mode = Control.FOCUS_ALL
	start_btn.focus_neighbor_bottom = back_btn.get_path()
	back_btn.focus_neighbor_top = start_btn.get_path()
	if not buttons.is_empty():
		start_btn.focus_neighbor_top = buttons[mini(buttons.size() - 1, buttons.size() - 1)].get_path()
		back_btn.focus_neighbor_bottom = buttons[0].get_path()
		# Garante foco no primeiro botao apos o frame de layout
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
