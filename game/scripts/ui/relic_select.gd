extends Control

## Tela de selecao de reliquia — grid 4x3 com paginacao.

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

var selected_relic: String = ""
var selected_mode: String = "normal"
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

func _load_items() -> void:
	all_items.clear()
	# Opcao sem reliquia
	all_items.append({"id": "", "data": {"name": "Nenhuma", "description": "Sem bonus"}})
	for relic_id in RelicDB.get_all_relic_ids():
		var data = RelicDB.get_relic(relic_id)
		all_items.append({"id": relic_id, "data": data})
	total_pages = maxi(1, ceili(float(all_items.size()) / PER_PAGE))

func _show_page(page: int) -> void:
	current_page = clampi(page, 0, total_pages - 1)

	for child in grid.get_children():
		child.queue_free()

	var start_idx = current_page * PER_PAGE
	var end_idx = mini(start_idx + PER_PAGE, all_items.size())

	for i in range(start_idx, end_idx):
		var item = all_items[i]
		var relic_id = item["id"]
		var data = item["data"]

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(140, 70)
		btn.text = data["name"]

		btn.pressed.connect(func(): _select_relic(relic_id, data))
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

func _select_relic(relic_id: String, data: Dictionary) -> void:
	selected_relic = relic_id
	info_label.text = "%s — %s" % [data["name"], data["description"]]

func _on_mode_normal() -> void:
	selected_mode = "normal"
	info_label.text = "Modo Normal — 30 min, boss no final"

func _on_mode_endless() -> void:
	selected_mode = "endless"
	info_label.text = "Modo Endless — Sem limite, sobreviva o maximo"

func _on_start() -> void:
	GameManager.selected_relic = selected_relic
	GameManager.game_mode = selected_mode
	if selected_mode == "endless":
		GameManager.run_time_limit = 999999.0
	else:
		GameManager.run_time_limit = 1800.0
	var stage_scenes = {
		"cemetery": "res://scenes/stages/stage_cemetery.tscn",
		"forest": "res://scenes/stages/stage_forest.tscn",
		"farm": "res://scenes/stages/stage_farm.tscn",
		"tokyo": "res://scenes/stages/stage_tokyo.tscn",
		"volcano": "res://scenes/stages/stage_volcano.tscn",
		"ocean": "res://scenes/stages/stage_ocean.tscn",
		"arena": "res://scenes/stages/stage_arena.tscn",
		"space": "res://scenes/stages/stage_space.tscn",
		"castle": "res://scenes/stages/stage_castle.tscn",
		"candy": "res://scenes/stages/stage_candy.tscn",
	}
	var scene = stage_scenes.get(GameManager.selected_stage, "res://scenes/stages/stage_cemetery.tscn")
	get_tree().change_scene_to_file(scene)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
