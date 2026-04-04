extends Control

## Evolution tree screen — shows all 12 evolutions in a 4x3 grid.
## Accessible from main menu and InventoryOverlay (compact mode).
## Card states: locked (gray), discovered (colorful), available now (golden pulse), evolved (checkmark).

signal back_pressed

var _cards: Array[PanelContainer] = []
var _detail_panel: PanelContainer = null
var _selected_evo_id: String = ""
var _pulse_time: float = 0.0
var _pulse_cards: Array[PanelContainer] = []
var _compact_mode: bool = false

# Colors
const COLOR_BG := Color(0.04, 0.04, 0.07)
const COLOR_TITLE := Color(0.9, 0.8, 0.3)
const COLOR_SUBTITLE := Color(0.6, 0.6, 0.7)
const COLOR_CARD_BG := Color(0.1, 0.1, 0.14)
const COLOR_CARD_LOCKED := Color(0.3, 0.3, 0.3)
const COLOR_CARD_DISCOVERED := Color(0.15, 0.14, 0.2)
const COLOR_CARD_AVAILABLE := Color(0.25, 0.2, 0.05)
const COLOR_CARD_EVOLVED := Color(0.08, 0.18, 0.08)
const COLOR_BORDER_LOCKED := Color(0.2, 0.2, 0.2)
const COLOR_BORDER_DISCOVERED := Color(0.4, 0.35, 0.6)
const COLOR_BORDER_AVAILABLE := Color(0.9, 0.75, 0.2)
const COLOR_BORDER_EVOLVED := Color(0.3, 0.9, 0.3)
const COLOR_ARROW := Color(0.7, 0.6, 0.2)
const COLOR_PLUS := Color(0.5, 0.5, 0.6)
const COLOR_DETAIL_BG := Color(0.08, 0.08, 0.12)
const COLOR_DETAIL_BORDER := Color(0.3, 0.25, 0.5)
const COLOR_EVO_NAME := Color(0.9, 0.8, 0.3)
const COLOR_RECIPE_LABEL := Color(0.6, 0.85, 1.0)
const COLOR_EFFECT_LABEL := Color(0.85, 0.7, 1.0)
const COLOR_STAT_LABEL := Color(0.3, 1.0, 0.5)
const COLOR_DATE_LABEL := Color(0.5, 0.5, 0.6)
const COLOR_STATUS_LOCKED := Color(0.5, 0.5, 0.5)
const COLOR_STATUS_DISCOVERED := Color(0.6, 0.85, 1.0)
const COLOR_STATUS_AVAILABLE := Color(1.0, 0.85, 0.2)
const COLOR_STATUS_EVOLVED := Color(0.3, 1.0, 0.4)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _process(delta: float) -> void:
	_pulse_time += delta
	var alpha = lerp(
		GameConstants.EVO_TREE_AVAILABLE_PULSE_ALPHA_MIN,
		GameConstants.EVO_TREE_AVAILABLE_PULSE_ALPHA_MAX,
		(sin(_pulse_time * GameConstants.EVO_TREE_AVAILABLE_PULSE_SPEED * TAU) + 1.0) * 0.5
	)
	for card in _pulse_cards:
		if is_instance_valid(card):
			card.modulate.a = alpha


func setup_compact(compact: bool) -> void:
	_compact_mode = compact
	_build_ui()


func _build_ui() -> void:
	_cards.clear()
	_pulse_cards.clear()
	_detail_panel = null
	_selected_evo_id = ""

	for child in get_children():
		child.queue_free()

	if _compact_mode:
		_build_compact_ui()
	else:
		_build_full_ui()


func _build_full_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Main layout: VBox centered
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 16)
	margin.add_child(main_hbox)

	# Left side: title + grid
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 8)
	main_hbox.add_child(left_vbox)

	# Title
	var title = Label.new()
	title.text = LocaleManager.tr_key("evo_tree_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	left_vbox.add_child(title)

	# Subtitle with count
	var discovered_count = _get_discovered_count()
	var total_count = EvolutionDB.evolutions.size()
	var subtitle = Label.new()
	subtitle.text = LocaleManager.tr_key("evo_tree_subtitle") % [discovered_count, total_count]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", COLOR_SUBTITLE)
	left_vbox.add_child(subtitle)

	left_vbox.add_child(HSeparator.new())

	# Grid of cards
	var grid = GridContainer.new()
	grid.columns = GameConstants.EVO_TREE_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	left_vbox.add_child(grid)

	var evo_ids = EvolutionDB.get_all_evolution_ids()
	for evo_id in evo_ids:
		var card = _create_card(evo_id)
		grid.add_child(card)
		_cards.append(card)

	# Back button
	var back_hbox = HBoxContainer.new()
	back_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	left_vbox.add_child(back_hbox)

	var back_btn = Button.new()
	back_btn.text = LocaleManager.tr_key("evo_tree_back")
	back_btn.custom_minimum_size = Vector2(120, 36)
	back_btn.focus_mode = Control.FOCUS_ALL
	back_btn.pressed.connect(func(): back_pressed.emit())
	back_hbox.add_child(back_btn)

	# Right side: detail panel
	_detail_panel = PanelContainer.new()
	_detail_panel.custom_minimum_size = Vector2(GameConstants.EVO_TREE_DETAIL_WIDTH, 0)
	_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = COLOR_DETAIL_BG
	detail_style.border_color = COLOR_DETAIL_BORDER
	detail_style.set_border_width_all(1)
	detail_style.set_corner_radius_all(4)
	detail_style.set_content_margin_all(12)
	_detail_panel.add_theme_stylebox_override("panel", detail_style)
	main_hbox.add_child(_detail_panel)

	# Default detail content
	_update_detail_panel("")

	# Gamepad focus
	if _cards.size() > 0:
		_cards[0].grab_focus()


func _build_compact_ui() -> void:
	# Compact version for inventory overlay: list format
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	var title = Label.new()
	title.text = LocaleManager.tr_key("evo_tree_title")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	vbox.add_child(title)

	var evo_ids = EvolutionDB.get_all_evolution_ids()
	for evo_id in evo_ids:
		var entry = _create_compact_entry(evo_id)
		vbox.add_child(entry)


func _create_card(evo_id: String) -> PanelContainer:
	var evo = EvolutionDB.get_evolution(evo_id)
	var state = _get_evo_state(evo_id)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(GameConstants.EVO_TREE_CARD_WIDTH, GameConstants.EVO_TREE_CARD_HEIGHT)
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set_meta("evo_id", evo_id)

	# Style based on state
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	style.set_border_width_all(2)

	match state:
		"locked":
			style.bg_color = COLOR_CARD_LOCKED
			style.border_color = COLOR_BORDER_LOCKED
		"discovered":
			style.bg_color = COLOR_CARD_DISCOVERED
			style.border_color = COLOR_BORDER_DISCOVERED
		"available":
			style.bg_color = COLOR_CARD_AVAILABLE
			style.border_color = COLOR_BORDER_AVAILABLE
			_pulse_cards.append(card)
		"evolved":
			style.bg_color = COLOR_CARD_EVOLVED
			style.border_color = COLOR_BORDER_EVOLVED

	card.add_theme_stylebox_override("panel", style)

	# Card content
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	# Weapon icon
	var weapon_id: String = evo.get("weapon_required", "")
	var weapon_data = WeaponDB.get_weapon(weapon_id)
	var weapon_name = weapon_data.get("name", weapon_id.capitalize()) if not weapon_data.is_empty() else weapon_id.capitalize()

	var weapon_hbox = HBoxContainer.new()
	weapon_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	weapon_hbox.add_theme_constant_override("separation", 4)
	vbox.add_child(weapon_hbox)

	var weapon_icon = _create_icon("res://assets/sprites/weapons/%s.png" % weapon_id, GameConstants.EVO_TREE_ICON_WEAPON_SIZE, state == "locked")
	weapon_hbox.add_child(weapon_icon)

	# Plus sign
	var plus_label = Label.new()
	plus_label.text = "+"
	plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus_label.add_theme_font_size_override("font_size", 14)
	plus_label.add_theme_color_override("font_color", COLOR_PLUS if state != "locked" else COLOR_CARD_LOCKED)
	vbox.add_child(plus_label)

	# Item icon
	var item_id: String = evo.get("item_required", "")
	var item_data = ItemDB.get_item(item_id)
	var item_name = item_data.get("name", item_id.capitalize()) if not item_data.is_empty() else item_id.capitalize()

	var item_hbox = HBoxContainer.new()
	item_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	item_hbox.add_theme_constant_override("separation", 4)
	vbox.add_child(item_hbox)

	var item_icon = _create_icon("res://assets/sprites/items/%s.png" % item_id, GameConstants.EVO_TREE_ICON_WEAPON_SIZE, state == "locked")
	item_hbox.add_child(item_icon)

	# Arrow down
	var arrow_label = Label.new()
	arrow_label.text = "v"
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.add_theme_font_size_override("font_size", 16)
	arrow_label.add_theme_color_override("font_color", COLOR_ARROW if state != "locked" else COLOR_CARD_LOCKED)
	vbox.add_child(arrow_label)

	# Evolution icon (larger)
	var evo_hbox = HBoxContainer.new()
	evo_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(evo_hbox)

	var evo_icon = _create_icon("res://assets/sprites/weapons/%s.png" % evo_id, GameConstants.EVO_TREE_ICON_EVOLUTION_SIZE, state == "locked")
	evo_hbox.add_child(evo_icon)

	# Evolution name
	var name_label = Label.new()
	if state == "locked":
		name_label.text = "???"
	else:
		name_label.text = evo.get("name", evo_id.capitalize())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", COLOR_EVO_NAME if state != "locked" else COLOR_STATUS_LOCKED)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	# Status badge
	var status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 10)
	match state:
		"locked":
			status_label.text = LocaleManager.tr_key("evo_status_locked")
			status_label.add_theme_color_override("font_color", COLOR_STATUS_LOCKED)
		"discovered":
			status_label.text = LocaleManager.tr_key("evo_status_discovered")
			status_label.add_theme_color_override("font_color", COLOR_STATUS_DISCOVERED)
		"available":
			status_label.text = LocaleManager.tr_key("evo_status_available")
			status_label.add_theme_color_override("font_color", COLOR_STATUS_AVAILABLE)
		"evolved":
			status_label.text = LocaleManager.tr_key("evo_status_evolved")
			status_label.add_theme_color_override("font_color", COLOR_STATUS_EVOLVED)
	vbox.add_child(status_label)

	# Input handling
	card.gui_input.connect(_on_card_input.bind(evo_id))
	card.focus_entered.connect(_on_card_focus.bind(evo_id))
	card.mouse_entered.connect(_on_card_focus.bind(evo_id))

	return card


func _create_compact_entry(evo_id: String) -> HBoxContainer:
	var evo = EvolutionDB.get_evolution(evo_id)
	var state = _get_evo_state(evo_id)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	# Available indicator
	if state == "available":
		var star = Label.new()
		star.text = "!"
		star.add_theme_font_size_override("font_size", 14)
		star.add_theme_color_override("font_color", COLOR_STATUS_AVAILABLE)
		hbox.add_child(star)

	# Evolution name
	var name_lbl = Label.new()
	if state == "locked":
		name_lbl.text = "???"
		name_lbl.add_theme_color_override("font_color", COLOR_STATUS_LOCKED)
	else:
		name_lbl.text = evo.get("name", evo_id.capitalize())
		match state:
			"discovered":
				name_lbl.add_theme_color_override("font_color", COLOR_STATUS_DISCOVERED)
			"available":
				name_lbl.add_theme_color_override("font_color", COLOR_STATUS_AVAILABLE)
			"evolved":
				name_lbl.add_theme_color_override("font_color", COLOR_STATUS_EVOLVED)
	name_lbl.add_theme_font_size_override("font_size", 13)
	hbox.add_child(name_lbl)

	# Recipe (if not locked)
	if state != "locked":
		var weapon_id = evo.get("weapon_required", "")
		var item_id = evo.get("item_required", "")
		var weapon_data = WeaponDB.get_weapon(weapon_id)
		var item_data = ItemDB.get_item(item_id)
		var weapon_name = weapon_data.get("name", weapon_id.capitalize()) if not weapon_data.is_empty() else weapon_id.capitalize()
		var item_name = item_data.get("name", item_id.capitalize()) if not item_data.is_empty() else item_id.capitalize()

		# Show current levels during gameplay
		var weapon_level = GameManager.get_weapon_level(weapon_id)
		var item_level = GameManager.get_item_level(item_id)

		var recipe_lbl = Label.new()
		recipe_lbl.text = "(%s %d/6 + %s %d/3)" % [weapon_name, weapon_level, item_name, item_level]
		recipe_lbl.add_theme_font_size_override("font_size", 11)
		recipe_lbl.add_theme_color_override("font_color", COLOR_SUBTITLE)
		hbox.add_child(recipe_lbl)

	# Status
	if state == "evolved":
		var check = Label.new()
		check.text = "[OK]"
		check.add_theme_font_size_override("font_size", 11)
		check.add_theme_color_override("font_color", COLOR_STATUS_EVOLVED)
		hbox.add_child(check)

	return hbox


func _create_icon(path: String, icon_size: int, is_locked: bool) -> TextureRect:
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if ResourceLoader.exists(path):
		icon.texture = load(path)
	else:
		# Placeholder colored rect
		icon.custom_minimum_size = Vector2(icon_size, icon_size)

	if is_locked:
		icon.modulate = Color(0.2, 0.2, 0.2)
	return icon


func _get_evo_state(evo_id: String) -> String:
	# Check if evolved in current run
	if evo_id in EvolutionDB.evolved_weapons:
		return "evolved"

	# Check if available now (during gameplay)
	var evo = EvolutionDB.get_evolution(evo_id)
	if not evo.is_empty():
		var weapon_level = GameManager.get_weapon_level(evo["weapon_required"])
		var item_level = GameManager.get_item_level(evo["item_required"])
		if weapon_level >= 6 and item_level >= 3:
			return "available"

	# Check if discovered (ever evolved before — saved in evolution_history)
	var history = SaveManager.data.get("evolution_history", {})
	if evo_id in history:
		return "discovered"

	return "locked"


func _get_discovered_count() -> int:
	var history = SaveManager.data.get("evolution_history", {})
	return history.size()


func _on_card_input(event: InputEvent, evo_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_card(evo_id)
	elif event.is_action_pressed("ui_accept"):
		_select_card(evo_id)


func _on_card_focus(evo_id: String) -> void:
	_update_detail_panel(evo_id)


func _select_card(evo_id: String) -> void:
	_selected_evo_id = evo_id
	_update_detail_panel(evo_id)


func _update_detail_panel(evo_id: String) -> void:
	if _detail_panel == null:
		return

	# Clear previous content
	for child in _detail_panel.get_children():
		child.queue_free()

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	_detail_panel.add_child(vbox)

	if evo_id.is_empty():
		var hint = Label.new()
		hint.text = LocaleManager.tr_key("evo_tree_select_hint")
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", COLOR_SUBTITLE)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(hint)
		return

	var evo = EvolutionDB.get_evolution(evo_id)
	if evo.is_empty():
		return

	var state = _get_evo_state(evo_id)

	# Evolution name
	var name_lbl = Label.new()
	if state == "locked":
		name_lbl.text = "???"
	else:
		name_lbl.text = evo.get("name", evo_id.capitalize())
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", COLOR_EVO_NAME)
	vbox.add_child(name_lbl)

	# Description (lore flavor)
	if state != "locked":
		var desc_lbl = Label.new()
		desc_lbl.text = "\"%s\"" % evo.get("description", "")
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", COLOR_SUBTITLE)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(desc_lbl)

	vbox.add_child(HSeparator.new())

	# Recipe
	var recipe_title = Label.new()
	recipe_title.text = LocaleManager.tr_key("evo_tree_recipe")
	recipe_title.add_theme_font_size_override("font_size", 14)
	recipe_title.add_theme_color_override("font_color", COLOR_RECIPE_LABEL)
	vbox.add_child(recipe_title)

	var weapon_id = evo.get("weapon_required", "")
	var item_id = evo.get("item_required", "")
	var weapon_data = WeaponDB.get_weapon(weapon_id)
	var item_data = ItemDB.get_item(item_id)

	if state == "locked":
		var wpn_lbl = Label.new()
		wpn_lbl.text = "??? " + LocaleManager.tr_key("evo_tree_level_req") % 6
		wpn_lbl.add_theme_font_size_override("font_size", 13)
		wpn_lbl.add_theme_color_override("font_color", COLOR_STATUS_LOCKED)
		vbox.add_child(wpn_lbl)

		var item_lbl = Label.new()
		item_lbl.text = "??? " + LocaleManager.tr_key("evo_tree_level_req") % 3
		item_lbl.add_theme_font_size_override("font_size", 13)
		item_lbl.add_theme_color_override("font_color", COLOR_STATUS_LOCKED)
		vbox.add_child(item_lbl)
	else:
		var weapon_name = weapon_data.get("name", weapon_id.capitalize()) if not weapon_data.is_empty() else weapon_id.capitalize()
		var item_name = item_data.get("name", item_id.capitalize()) if not item_data.is_empty() else item_id.capitalize()

		var wpn_lbl = Label.new()
		wpn_lbl.text = "%s " % weapon_name + LocaleManager.tr_key("evo_tree_level_req") % 6
		wpn_lbl.add_theme_font_size_override("font_size", 13)
		vbox.add_child(wpn_lbl)

		var item_lbl = Label.new()
		item_lbl.text = "%s " % item_name + LocaleManager.tr_key("evo_tree_level_req") % 3
		item_lbl.add_theme_font_size_override("font_size", 13)
		vbox.add_child(item_lbl)

	vbox.add_child(HSeparator.new())

	# Special effect
	if state != "locked":
		var effect_title = Label.new()
		effect_title.text = LocaleManager.tr_key("evo_tree_effect")
		effect_title.add_theme_font_size_override("font_size", 14)
		effect_title.add_theme_color_override("font_color", COLOR_EFFECT_LABEL)
		vbox.add_child(effect_title)

		var effect_lbl = Label.new()
		effect_lbl.text = evo.get("description", "")
		effect_lbl.add_theme_font_size_override("font_size", 13)
		effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(effect_lbl)

		# Damage multiplier
		var mult_lbl = Label.new()
		mult_lbl.text = LocaleManager.tr_key("evo_tree_damage_mult") % evo.get("evolved_damage_mult", 1.0)
		mult_lbl.add_theme_font_size_override("font_size", 14)
		mult_lbl.add_theme_color_override("font_color", COLOR_STAT_LABEL)
		vbox.add_child(mult_lbl)

	# History info
	var history = SaveManager.data.get("evolution_history", {})
	if evo_id in history:
		vbox.add_child(HSeparator.new())

		var hist = history[evo_id]
		var date_lbl = Label.new()
		date_lbl.text = LocaleManager.tr_key("evo_tree_first_date") % hist.get("first_date", "---")
		date_lbl.add_theme_font_size_override("font_size", 12)
		date_lbl.add_theme_color_override("font_color", COLOR_DATE_LABEL)
		vbox.add_child(date_lbl)

		var times_lbl = Label.new()
		times_lbl.text = LocaleManager.tr_key("evo_tree_times_evolved") % hist.get("times", 0)
		times_lbl.add_theme_font_size_override("font_size", 12)
		times_lbl.add_theme_color_override("font_color", COLOR_DATE_LABEL)
		vbox.add_child(times_lbl)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_pressed.emit()
		get_viewport().set_input_as_handled()
