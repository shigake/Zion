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

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)
	left_arrow.pressed.connect(_prev_page)
	right_arrow.pressed.connect(_next_page)
	_load_items()
	_show_page(0)
	_select_character("ronin", CharacterDB.get_character("ronin"))
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

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(140, 70)
		btn.text = "%s\n%s" % [data["name"], data["passive"]]

		if not SaveManager.is_character_unlocked(char_id):
			var unlock_desc = data.get("unlock_description", "???")
			btn.text += "\n[%s]" % unlock_desc
			btn.disabled = true

		var b = btn  # capture for lambda
		b.pressed.connect(func(): _select_character(char_id, data, b))
		grid.add_child(btn)

	# Preenche slots vazios para manter layout 4x3
	var filled = end_idx - start_idx
	for i in range(filled, PER_PAGE):
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(140, 70)
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

func _select_character(char_id: String, data: Dictionary, btn: Button = null) -> void:
	selected_character = char_id
	info_label.text = "%s — Arma: %s\n%s" % [
		data["name"],
		WeaponDB.get_weapon(data["starting_weapon"])["name"],
		data["passive"]
	]
	# Highlight selected button
	if btn:
		if _selected_btn and is_instance_valid(_selected_btn):
			_selected_btn.remove_theme_stylebox_override("normal")
		_selected_btn = btn
		var highlight = StyleBoxFlat.new()
		highlight.bg_color = Color(0.15, 0.3, 0.55)
		highlight.set_corner_radius_all(4)
		highlight.set_border_width_all(2)
		highlight.border_color = Color(0.3, 0.6, 1.0)
		_selected_btn.add_theme_stylebox_override("normal", highlight)

func _setup_grid_focus() -> void:
	var buttons: Array[Button] = []
	for child in grid.get_children():
		if child is Button and not child.disabled:
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()

func _on_start() -> void:
	GameManager.selected_character = selected_character
	get_tree().change_scene_to_file("res://scenes/ui/stage_select.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
