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

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)
	left_arrow.pressed.connect(_prev_page)
	right_arrow.pressed.connect(_next_page)
	_load_items()
	_show_page(0)
	_select_character("ronin", CharacterDB.get_character("ronin"))

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

		btn.pressed.connect(func(): _select_character(char_id, data))
		grid.add_child(btn)

	# Preenche slots vazios para manter layout 4x3
	var filled = end_idx - start_idx
	for i in range(filled, PER_PAGE):
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(140, 70)
		grid.add_child(spacer)

	_update_arrows()

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

func _select_character(char_id: String, data: Dictionary) -> void:
	selected_character = char_id
	info_label.text = "%s — Arma: %s\n%s" % [
		data["name"],
		WeaponDB.get_weapon(data["starting_weapon"])["name"],
		data["passive"]
	]

func _on_start() -> void:
	GameManager.selected_character = selected_character
	get_tree().change_scene_to_file("res://scenes/ui/stage_select.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
