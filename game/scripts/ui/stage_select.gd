extends Control

## Tela de selecao de fase — grid 4x3 com paginacao.

const COLUMNS := 4
const ROWS := 3
const PER_PAGE := COLUMNS * ROWS

@onready var grid: GridContainer = $VBox/GridRow/GridContainer
@onready var left_arrow: Button = $VBox/GridRow/LeftArrow
@onready var right_arrow: Button = $VBox/GridRow/RightArrow
@onready var page_label: Label = $VBox/PageLabel
@onready var info_label: Label = $VBox/InfoLabel
@onready var next_btn: Button = $VBox/NextButton
@onready var back_btn: Button = $VBox/BackButton

var selected_stage: String = "cemetery"
var current_page: int = 0
var total_pages: int = 1

# Stage definitions
var stages: Array[Dictionary] = [
	{"id": "cemetery", "name": "Cemiterio", "description": "Um cemiterio sombrio cheio de mortos-vivos."},
	{"id": "forest", "name": "Floresta", "description": "Floresta magica com cogumelos e fadas."},
	{"id": "farm", "name": "Fazenda", "description": "Fazenda destruida com vacas zumbis."},
	{"id": "tokyo", "name": "Toquio", "description": "Cidade cyberpunk com robos e neon."},
	{"id": "volcano", "name": "Vulcao", "description": "Cavernas de lava com demonios."},
	{"id": "ocean", "name": "Oceano", "description": "Ruinas submarinas com tubaroes zumbis."},
	{"id": "arena", "name": "Arena", "description": "Coliseu gladiador com leoes e centurioes."},
	{"id": "space", "name": "Espaco", "description": "Estacao espacial com aliens e parasitas."},
	{"id": "castle", "name": "Castelo", "description": "Castelo gotico com vampiros e gargulas."},
	{"id": "candy", "name": "Mundo Doce", "description": "Terra de doces com gummy bears."},
]

func _ready() -> void:
	next_btn.pressed.connect(_on_next)
	back_btn.pressed.connect(_on_back)
	left_arrow.pressed.connect(_prev_page)
	right_arrow.pressed.connect(_next_page)
	total_pages = maxi(1, ceili(float(stages.size()) / PER_PAGE))
	_show_page(0)
	_select_stage(stages[0])

func _show_page(page: int) -> void:
	current_page = clampi(page, 0, total_pages - 1)

	for child in grid.get_children():
		child.queue_free()

	var start_idx = current_page * PER_PAGE
	var end_idx = mini(start_idx + PER_PAGE, stages.size())

	for i in range(start_idx, end_idx):
		var stage = stages[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(140, 70)

		var unlocked = SaveManager.is_stage_unlocked(stage["id"])
		if unlocked:
			btn.text = stage["name"]
		else:
			btn.text = stage["name"] + "\n[LOCKED]"
			btn.disabled = true

		btn.pressed.connect(func(): _select_stage(stage))
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

func _select_stage(stage: Dictionary) -> void:
	selected_stage = stage["id"]
	info_label.text = "%s — %s" % [stage["name"], stage["description"]]

func _on_next() -> void:
	GameManager.selected_stage = selected_stage
	get_tree().change_scene_to_file("res://scenes/ui/relic_select.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
