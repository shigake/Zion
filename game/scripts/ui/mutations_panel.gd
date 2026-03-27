extends Control

## Painel de mutacoes — permite ativar modificadores de dificuldade
## que aumentam o multiplicador de cristais ganhos.

@onready var back_button: Button = $MarginContainer/VBox/BottomHBox/BackButton
@onready var confirm_button: Button = $MarginContainer/VBox/BottomHBox/ConfirmButton
@onready var multiplier_label: Label = $MarginContainer/VBox/MultiplierLabel
@onready var mutation_grid: GridContainer = $MarginContainer/VBox/ScrollContainer/MutationGrid

func _ready() -> void:
	back_button.pressed.connect(_on_back)
	confirm_button.pressed.connect(_on_confirm)
	_style_button(back_button)
	_style_button(confirm_button)
	_build_mutation_cards()
	GamepadUI.notify_menu_opened()

func _style_button(btn: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16)
	style.border_color = Color(0.22, 0.21, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)
	var hover = style.duplicate()
	hover.bg_color = Color(0.16, 0.16, 0.22)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed = style.duplicate()
	pressed.bg_color = Color(0.1, 0.1, 0.14)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(0.88, 0.88, 0.92))

func _build_mutation_cards() -> void:
	for child in mutation_grid.get_children():
		child.queue_free()

	var mutations = MutationManager.get_all_mutations()
	for mutation in mutations:
		var card = _create_card(mutation)
		mutation_grid.add_child(card)

func _create_card(mutation: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 120)

	# Card style
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.08, 0.12)
	card_style.set_corner_radius_all(8)
	card_style.set_border_width_all(1)
	card_style.border_color = Color(0.2, 0.2, 0.25)
	card.add_theme_stylebox_override("panel", card_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	# Header row: icon + name
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)

	var icon_label = Label.new()
	icon_label.text = mutation.get("icon", "⚡")
	icon_label.add_theme_font_size_override("font_size", 20)
	header.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = mutation.get("name", "Mutacao")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	header.add_child(name_label)

	vbox.add_child(header)

	# Description
	var desc_label = Label.new()
	desc_label.text = mutation.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Bonus label
	var bonus_label = Label.new()
	bonus_label.text = "+%d%% cristais" % [int(mutation.get("crystal_bonus", 0.25) * 100)]
	bonus_label.add_theme_font_size_override("font_size", 13)
	bonus_label.add_theme_color_override("font_color", Color(0.45, 0.85, 0.95))
	vbox.add_child(bonus_label)

	# Toggle checkbox
	var checkbox = CheckBox.new()
	checkbox.text = "Ativar"
	checkbox.button_pressed = MutationManager.is_mutation_active(mutation["id"]) if mutation.has("id") else false
	var mutation_id = mutation.get("id", "")
	checkbox.toggled.connect(func(is_active: bool): _on_mutation_toggled(mutation_id, is_active))
	vbox.add_child(checkbox)

	card.add_child(vbox)
	return card

func _on_mutation_toggled(id: String, active: bool) -> void:
	MutationManager.toggle_mutation(id)
	_update_multiplier()

func _update_multiplier() -> void:
	var multiplier = MutationManager.get_crystal_multiplier()
	multiplier_label.text = "Multiplicador de cristais: x%.1f" % multiplier

	if multiplier >= 3.0:
		multiplier_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	elif multiplier >= 2.0:
		multiplier_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	elif multiplier > 1.0:
		multiplier_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	else:
		multiplier_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func _on_confirm() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/stage_select.tscn")

func _on_back() -> void:
	MutationManager.reset()
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()
