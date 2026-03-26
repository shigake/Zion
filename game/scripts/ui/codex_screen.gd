extends Control

## Codex de armas — catalogo de todas as armas com stats e info de evolucao.

const COLUMNS := 4
const CARD_SIZE := Vector2(200, 140)

var grid: GridContainer
var info_label: Label
var back_btn: Button
var scroll: ScrollContainer

func _ready() -> void:
	_build_ui()
	_populate_grid()
	GamepadUI.notify_menu_opened()

func _build_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 30
	vbox.offset_right = -30
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Codex de Armas"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	vbox.add_child(title)

	# Info label
	info_label = Label.new()
	info_label.text = "Todas as armas disponiveis no jogo."
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_label)

	# Scroll + Grid
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	# Back button
	back_btn = Button.new()
	back_btn.text = "Voltar"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(_on_back)
	back_btn.focus_mode = Control.FOCUS_ALL
	vbox.add_child(back_btn)

func _populate_grid() -> void:
	var codex = SaveManager.get_codex()
	var all_weapons = WeaponDB.weapons
	var type_colors := {
		"melee": Color(0.9, 0.3, 0.3),
		"ranged": Color(0.3, 0.5, 1.0),
		"summon": Color(0.3, 0.9, 0.4),
	}

	for weapon_id in all_weapons:
		var data = all_weapons[weapon_id]
		var is_unlocked = weapon_id in codex

		var card = PanelContainer.new()
		card.custom_minimum_size = CARD_SIZE

		var weapon_type: String = data.get("type", "melee")
		var type_color: Color = type_colors.get(weapon_type, Color.WHITE)

		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.12, 0.12, 0.18) if is_unlocked else Color(0.08, 0.08, 0.1)
		card_style.set_corner_radius_all(6)
		card_style.set_border_width_all(2)
		card_style.border_color = type_color if is_unlocked else Color(0.2, 0.2, 0.2)
		card.add_theme_stylebox_override("panel", card_style)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 3)
		card.add_child(vbox)

		# Type color swatch
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(0, 6)
		swatch.color = type_color if is_unlocked else Color(0.3, 0.3, 0.3)
		vbox.add_child(swatch)

		# Name
		var name_lbl = Label.new()
		name_lbl.text = data.get("name", weapon_id) if is_unlocked else "???"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8) if is_unlocked else Color(0.4, 0.4, 0.4))
		vbox.add_child(name_lbl)

		if is_unlocked:
			# Type + element
			var type_lbl = Label.new()
			type_lbl.text = "%s | %s" % [weapon_type.capitalize(), data.get("element", "physical").capitalize()]
			type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			type_lbl.add_theme_font_size_override("font_size", 11)
			type_lbl.add_theme_color_override("font_color", type_color)
			vbox.add_child(type_lbl)

			# Base damage
			var dmg_lbl = Label.new()
			dmg_lbl.text = "Dano: %d" % data.get("base_damage", 0)
			dmg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dmg_lbl.add_theme_font_size_override("font_size", 11)
			dmg_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			vbox.add_child(dmg_lbl)

			# Description
			var desc_lbl = Label.new()
			desc_lbl.text = data.get("description", "")
			desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			desc_lbl.add_theme_font_size_override("font_size", 10)
			desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(desc_lbl)

			# Evolution info
			var evo_text = _get_evolution_info(weapon_id)
			if not evo_text.is_empty():
				var evo_lbl = Label.new()
				evo_lbl.text = evo_text
				evo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				evo_lbl.add_theme_font_size_override("font_size", 10)
				evo_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
				evo_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				vbox.add_child(evo_lbl)
		else:
			var locked_lbl = Label.new()
			locked_lbl.text = "Use esta arma para desbloquear."
			locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			locked_lbl.add_theme_font_size_override("font_size", 11)
			locked_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			locked_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(locked_lbl)

		grid.add_child(card)

func _get_evolution_info(weapon_id: String) -> String:
	for evo_id in EvolutionDB.evolutions:
		var evo = EvolutionDB.evolutions[evo_id]
		if evo["weapon_required"] == weapon_id:
			var item_data = ItemDB.get_item(evo["item_required"])
			var item_name = item_data.get("name", evo["item_required"]) if not item_data.is_empty() else evo["item_required"]
			return "Evolui com %s -> %s" % [item_name, evo["name"]]
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
