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
var _selected_btn: Button = null

# Stage IDs — nomes e descrições vêm do LocaleManager
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
	next_btn.pressed.connect(_on_next)
	back_btn.pressed.connect(_on_back)
	left_arrow.pressed.connect(_prev_page)
	right_arrow.pressed.connect(_next_page)
	total_pages = maxi(1, ceili(float(stage_ids.size()) / PER_PAGE))
	_show_page(0)
	_select_stage(_get_stage_data(stage_ids[0]))
	GamepadUI.notify_menu_opened()

func _show_page(page: int) -> void:
	current_page = clampi(page, 0, total_pages - 1)

	for child in grid.get_children():
		child.queue_free()

	var start_idx = current_page * PER_PAGE
	var end_idx = mini(start_idx + PER_PAGE, stage_ids.size())

	for i in range(start_idx, end_idx):
		var stage = _get_stage_data(stage_ids[i])
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(140, 70)

		var unlocked = SaveManager.is_stage_unlocked(stage["id"])
		if unlocked:
			btn.text = stage["name"]
		else:
			btn.text = stage["name"] + "\n[" + LocaleManager.tr_key("locked") + "]"
			btn.disabled = true

		var b = btn  # capture for lambda
		b.pressed.connect(func(): _select_stage(stage, b))
		grid.add_child(btn)

	# Preenche slots vazios para manter layout 4x3
	var filled = end_idx - start_idx
	for i in range(filled, PER_PAGE):
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(140, 70)
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

func _select_stage(stage: Dictionary, btn: Button = null) -> void:
	selected_stage = stage["id"]
	info_label.text = "%s — %s" % [stage["name"], stage["description"]]
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
			btn.focus_neighbor_bottom = next_btn.get_path()
	next_btn.focus_mode = Control.FOCUS_ALL
	back_btn.focus_mode = Control.FOCUS_ALL
	next_btn.focus_neighbor_bottom = back_btn.get_path()
	back_btn.focus_neighbor_top = next_btn.get_path()
	if not buttons.is_empty():
		next_btn.focus_neighbor_top = buttons[mini(buttons.size() - 1, buttons.size() - 1)].get_path()
		back_btn.focus_neighbor_bottom = buttons[0].get_path()
		# Garante foco no primeiro botao apos o frame de layout
		buttons[0].call_deferred("grab_focus")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()

func _on_next() -> void:
	GameManager.selected_stage = selected_stage
	get_tree().change_scene_to_file("res://scenes/ui/relic_select.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
