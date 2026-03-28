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
var _selected_btn: Button = null

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)
	left_arrow.pressed.connect(_prev_page)
	right_arrow.pressed.connect(_next_page)
	_load_items()
	_show_page(0)
	_create_mode_buttons()
	GamepadUI.notify_menu_opened()

func _load_items() -> void:
	all_items.clear()
	# Opcao sem reliquia
	all_items.append({"id": "", "data": {"name": LocaleManager.tr_key("no_relic"), "description": LocaleManager.tr_key("no_relic_desc")}})
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

		var card = HBoxContainer.new()
		card.custom_minimum_size = Vector2(140, 70)
		card.add_theme_constant_override("separation", 6)
		card.alignment = BoxContainer.ALIGNMENT_CENTER

		# Relic icon
		if relic_id != "":
			var icon_path = "res://assets/icons/relics/%s.svg" % relic_id
			var icon_tex = load(icon_path) if ResourceLoader.exists(icon_path) else null
			if icon_tex:
				var tex_rect = TextureRect.new()
				tex_rect.texture = icon_tex
				tex_rect.custom_minimum_size = Vector2(48, 48)
				tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				card.add_child(tex_rect)

		var btn = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 70)
		btn.text = data["name"]

		var b = btn  # capture for lambda
		b.pressed.connect(func(): _select_relic(relic_id, data, b))
		card.add_child(btn)
		grid.add_child(card)

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

func _setup_grid_focus() -> void:
	var buttons: Array[Button] = []
	for child in grid.get_children():
		# Buttons are now inside HBoxContainer cards
		if child is HBoxContainer:
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
	start_btn.focus_neighbor_bottom = back_btn.get_path()
	back_btn.focus_neighbor_top = start_btn.get_path()
	if not buttons.is_empty():
		start_btn.focus_neighbor_top = buttons[buttons.size() - 1].get_path()
		back_btn.focus_neighbor_bottom = buttons[0].get_path()
		# Garante foco no primeiro botao apos o frame de layout
		buttons[0].call_deferred("grab_focus")

func _select_relic(relic_id: String, data: Dictionary, btn: Button = null) -> void:
	selected_relic = relic_id
	info_label.text = "%s — %s" % [data["name"], data["description"]]
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

func _create_mode_buttons() -> void:
	var mode_hbox = HBoxContainer.new()
	mode_hbox.add_theme_constant_override("separation", 8)
	mode_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var modes = [
		{"id": "normal", "label": LocaleManager.tr_key("mode_normal"), "method": "_on_mode_normal"},
		{"id": "endless", "label": LocaleManager.tr_key("mode_endless"), "method": "_on_mode_endless"},
		{"id": "boss_rush", "label": LocaleManager.tr_key("mode_boss_rush"), "method": "_on_mode_boss_rush"},
		{"id": "hyper", "label": LocaleManager.tr_key("mode_hyper"), "method": "_on_mode_hyper"},
	]
	for mode in modes:
		var btn = Button.new()
		btn.text = mode["label"]
		btn.custom_minimum_size = Vector2(100, 35)
		btn.pressed.connect(Callable(self, mode["method"]))
		mode_hbox.add_child(btn)
	# New Game+ button (only if weapons available from a previous victory)
	if not GameManager.ng_plus_weapons.is_empty():
		var ng_btn = Button.new()
		ng_btn.text = "New Game+"
		ng_btn.custom_minimum_size = Vector2(100, 35)
		ng_btn.pressed.connect(_on_mode_new_game_plus)
		mode_hbox.add_child(ng_btn)
	# Insert before start button
	var vbox = start_btn.get_parent()
	vbox.add_child(mode_hbox)
	vbox.move_child(mode_hbox, start_btn.get_index())

func _on_mode_normal() -> void:
	selected_mode = "normal"
	info_label.text = LocaleManager.tr_key("mode_normal_desc")

func _on_mode_endless() -> void:
	selected_mode = "endless"
	info_label.text = LocaleManager.tr_key("mode_endless_desc")

func _on_mode_boss_rush() -> void:
	selected_mode = "boss_rush"
	info_label.text = LocaleManager.tr_key("mode_boss_rush_desc")

func _on_mode_hyper() -> void:
	selected_mode = "hyper"
	info_label.text = LocaleManager.tr_key("mode_hyper_desc")

func _on_mode_new_game_plus() -> void:
	selected_mode = "new_game_plus"
	var weapon_names: Array[String] = []
	for w in GameManager.ng_plus_weapons:
		var data = WeaponDB.weapons.get(w["id"], {})
		weapon_names.append(data.get("name", w["id"]))
	info_label.text = "New Game+: Comeca com armas da run anterior (cap lv3). Armas: " + ", ".join(weapon_names)

func _on_start() -> void:
	AudioManager.play_sfx("menu_click")
	GameManager.selected_relic = selected_relic
	GameManager.game_mode = selected_mode
	match selected_mode:
		"endless":
			GameManager.run_time_limit = 999999.0
		"boss_rush":
			GameManager.run_time_limit = 999999.0
		"hyper":
			GameManager.run_time_limit = 1800.0
		_:
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		if get_viewport(): get_viewport().set_input_as_handled()

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/stage_select.tscn")
