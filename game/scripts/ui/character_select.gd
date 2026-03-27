extends Control

## Tela de selecao de personagem — carousel 3D com spotlight.
## Layout: esquerda (escuro) — centro (spotlight) — direita (escuro)
## Navegacao com setas esquerda/direita.

@onready var left_arrow: Button = $MarginContainer/MainVBox/CarouselContainer/LeftArrow
@onready var right_arrow: Button = $MarginContainer/MainVBox/CarouselContainer/RightArrow
@onready var start_btn: Button = $MarginContainer/MainVBox/BottomHBox/StartButton
@onready var back_btn: Button = $MarginContainer/MainVBox/BottomHBox/BackButton

@onready var char_name_label: Label = $MarginContainer/MainVBox/InfoPanel/InfoVBox/CharNameLabel
@onready var weapon_label: Label = $MarginContainer/MainVBox/InfoPanel/InfoVBox/WeaponLabel
@onready var passive_label: Label = $MarginContainer/MainVBox/InfoPanel/InfoVBox/PassiveLabel
@onready var lock_label: Label = $MarginContainer/MainVBox/InfoPanel/InfoVBox/LockLabel

@onready var left_model_root: Node3D = $MarginContainer/MainVBox/CarouselContainer/LeftCharContainer/LeftSubViewport/LeftModelRoot
@onready var center_model_root: Node3D = $MarginContainer/MainVBox/CarouselContainer/CenterCharContainer/CenterSubViewport/CenterModelRoot
@onready var right_model_root: Node3D = $MarginContainer/MainVBox/CarouselContainer/RightCharContainer/RightSubViewport/RightModelRoot

@onready var info_panel: PanelContainer = $MarginContainer/MainVBox/InfoPanel

var all_character_ids: Array[String] = []
var current_index: int = 0
var _preview_models: Dictionary = {}  # side -> model node

const PRISON_GRID_SCALE := 2.0

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)
	left_arrow.pressed.connect(_prev_character)
	right_arrow.pressed.connect(_next_character)

	_style_buttons()
	_style_arrows()
	_style_info_panel()
	_load_character_list()

	# Start with first unlocked character
	_find_first_unlocked()
	_update_carousel()

	GamepadUI.notify_menu_opened()


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
		normal.corner_radius_top_left = 6
		normal.corner_radius_top_right = 6
		normal.corner_radius_bottom_left = 6
		normal.corner_radius_bottom_right = 6
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
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		btn.add_theme_color_override("font_hover_color", Color(0.8, 0.8, 0.95))


func _style_info_panel() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.07, 0.85)
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
	info_panel.add_theme_stylebox_override("panel", panel_style)


func _load_character_list() -> void:
	all_character_ids.clear()
	for char_id in CharacterDB.get_all_character_ids():
		all_character_ids.append(char_id)


func _find_first_unlocked() -> void:
	for i in range(all_character_ids.size()):
		if SaveManager.is_character_unlocked(all_character_ids[i]):
			current_index = i
			return
	# Fallback to first character
	current_index = 0


func _update_carousel() -> void:
	# Clear old models
	for side in ["left", "center", "right"]:
		if side in _preview_models and _preview_models[side]:
			_preview_models[side].queue_free()
		_preview_models[side] = null

	# Get indices for left, center, right
	var left_idx = (current_index - 1) % all_character_ids.size()
	var center_idx = current_index
	var right_idx = (current_index + 1) % all_character_ids.size()

	var left_char_id = all_character_ids[left_idx]
	var center_char_id = all_character_ids[center_idx]
	var right_char_id = all_character_ids[right_idx]

	var left_locked = not SaveManager.is_character_unlocked(left_char_id)
	var center_locked = not SaveManager.is_character_unlocked(center_char_id)
	var right_locked = not SaveManager.is_character_unlocked(right_char_id)

	# Load models
	_load_character_preview(left_char_id, left_model_root, "left", left_locked)
	_load_character_preview(center_char_id, center_model_root, "center", center_locked)
	_load_character_preview(right_char_id, right_model_root, "right", right_locked)

	# Update info panel (center character)
	_update_info_panel(center_char_id, center_locked)


func _load_character_preview(char_id: String, parent: Node3D, side: String, is_locked: bool) -> void:
	var model = ModelFactory.get_model_for_character(char_id)
	if not model:
		return

	# Set position and scale
	model.position = Vector3(0, 0, 0)
	model.rotation = Vector3(0, 0, 0)  # Face camera directly (no rotation)

	if side == "center":
		model.scale = Vector3(0.5, 0.5, 0.5)  # Spotlight character
	else:
		model.scale = Vector3(0.35, 0.35, 0.35)  # Side characters smaller

	parent.add_child(model)
	_preview_models[side] = model

	# Apply materials
	var data = CharacterDB.get_character(char_id)
	var char_color = data.get("color", Color(0.5, 0.5, 0.5))
	ModelFactory.apply_model_materials(model, char_color)

	# Add prison grid overlay if locked
	if is_locked:
		_add_prison_grid(model)


func _add_prison_grid(model: Node3D) -> void:
	## Add a prison grid in front of the character
	var grid = MeshInstance3D.new()

	# Create grid mesh (simple plane with grid pattern)
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(2.0, 2.5) * PRISON_GRID_SCALE
	mesh.subdivide_depth = 10
	mesh.subdivide_width = 8

	grid.mesh = mesh
	grid.position.z = -0.1  # In front of character

	# Dark metal material for prison
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.12, 0.7)
	mat.metallic = 0.8
	mat.roughness = 0.3
	mat.emission = Color(0.08, 0.08, 0.1)
	mat.emission_energy = 0.5
	grid.set_surface_override_material(0, mat)

	model.add_child(grid)


func _update_info_panel(char_id: String, is_locked: bool) -> void:
	var data = CharacterDB.get_character(char_id)

	char_name_label.text = data.get("name", char_id).to_upper()

	var weapon_data = WeaponDB.get_weapon(data.get("starting_weapon", "katana"))
	weapon_label.text = "Arma: %s" % weapon_data.get("name", "???")

	passive_label.text = data.get("passive", "")

	if is_locked:
		lock_label.text = "🔒 %s" % data.get("unlock_description", "???")
		lock_label.visible = true
		start_btn.disabled = true
	else:
		lock_label.visible = false
		start_btn.disabled = false


func _prev_character() -> void:
	current_index = (current_index - 1) % all_character_ids.size()
	_update_carousel()


func _next_character() -> void:
	current_index = (current_index + 1) % all_character_ids.size()
	_update_carousel()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


func _on_start() -> void:
	var center_char_id = all_character_ids[current_index]
	if SaveManager.is_character_unlocked(center_char_id):
		GameManager.selected_character = center_char_id
		get_tree().change_scene_to_file("res://scenes/ui/stage_select.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
