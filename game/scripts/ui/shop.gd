extends Control

## Loja de upgrades permanentes entre runs.
## Layout grid com cards detalhados, descrições e botões de reset/fill.

@onready var back_btn: Button = $VBox/BackButton
@onready var reset_all_btn: Button = $VBox/ActionBar/ResetAllButton
@onready var max_all_btn: Button = $VBox/ActionBar/MaxAllButton

var _crystals_label: Label
var _grid: GridContainer
var _buy_buttons: Array[Button] = []

const GRID_COLS := 4
const CARD_SIZE := Vector2(200, 130)

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_texture_background()
	back_btn.pressed.connect(_on_back)
	reset_all_btn.pressed.connect(_on_reset_all)
	max_all_btn.pressed.connect(_on_fill_all)
	_style_action_buttons()
	_build_shop_ui()
	GamepadUI.notify_menu_opened()
	AudioManager.play_music("shop")

func _style_action_buttons() -> void:
	# Style Reset All button
	var reset_style = StyleBoxFlat.new()
	reset_style.bg_color = Color(0.4, 0.12, 0.12)
	reset_style.set_corner_radius_all(8)
	reset_style.set_border_width_all(1)
	reset_style.border_color = Color(0.8, 0.2, 0.2)
	reset_all_btn.add_theme_stylebox_override("normal", reset_style)
	var reset_hover = reset_style.duplicate()
	reset_hover.bg_color = Color(0.55, 0.15, 0.15)
	reset_all_btn.add_theme_stylebox_override("hover", reset_hover)
	reset_all_btn.focus_mode = Control.FOCUS_ALL

	# Style Max All button
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.12, 0.3, 0.12)
	fill_style.set_corner_radius_all(8)
	fill_style.set_border_width_all(1)
	fill_style.border_color = Color(0.2, 0.8, 0.3)
	max_all_btn.add_theme_stylebox_override("normal", fill_style)
	var fill_hover = fill_style.duplicate()
	fill_hover.bg_color = Color(0.15, 0.4, 0.15)
	max_all_btn.add_theme_stylebox_override("hover", fill_hover)
	max_all_btn.focus_mode = Control.FOCUS_ALL

func _setup_texture_background() -> void:
	var bg_tex_path := "res://assets/sprites/ui/shop_bg.png"
	if ResourceLoader.exists(bg_tex_path):
		var bg := TextureRect.new()
		bg.name = "ShopBgTexture"
		bg.texture = load(bg_tex_path)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		move_child(bg, 0)

func _build_shop_ui() -> void:
	# Limpa conteudo anterior
	var upgrades_container = $VBox/ScrollContainer/Upgrades
	for child in upgrades_container.get_children():
		child.queue_free()

	# Titulo
	var title = $VBox/Title
	title.text = LocaleManager.tr_key("shop_title").to_upper()
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	# Cristais
	_crystals_label = $VBox/CrystalsLabel
	_update_crystals()
	_crystals_label.add_theme_font_size_override("font_size", 18)
	_crystals_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))

	# Grid de cards
	_grid = GridContainer.new()
	_grid.columns = GRID_COLS
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_container.add_child(_grid)

	_buy_buttons.clear()

	for uid in ShopDB.get_all_upgrade_ids():
		_create_upgrade_card(uid)

	# Focus chain
	_setup_focus()

func _create_upgrade_card(uid: String) -> void:
	var data = ShopDB.get_upgrade(uid)
	var current = SaveManager.get_upgrade_level(uid)
	var cost = ShopDB.get_cost(uid)
	var maxed = current >= data["max_level"]

	# Card container
	var card = PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.14) if not maxed else Color(0.08, 0.12, 0.08)
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.25, 0.25, 0.35) if not maxed else Color(0.2, 0.5, 0.2)
	style.set_content_margin_all(6)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	# Header: icon + name + level
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var icon_path = "res://assets/sprites/upgrades/%s.png" % uid
	if ResourceLoader.exists(icon_path):
		var icon = TextureRect.new()
		icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(24, 24)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		header.add_child(icon)

	var name_vbox = VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.add_theme_constant_override("separation", 0)
	header.add_child(name_vbox)

	var name_lbl = Label.new()
	name_lbl.text = data["name"]
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8) if not maxed else Color(0.3, 0.9, 0.4))
	name_vbox.add_child(name_lbl)

	var level_lbl = Label.new()
	level_lbl.text = "Lv. %d / %d" % [current, data["max_level"]]
	level_lbl.add_theme_font_size_override("font_size", 11)
	level_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	name_vbox.add_child(level_lbl)

	# Level bar
	var level_bar = ProgressBar.new()
	level_bar.max_value = data["max_level"]
	level_bar.value = current
	level_bar.show_percentage = false
	level_bar.custom_minimum_size = Vector2(0, 10)
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.3, 0.7, 0.3) if not maxed else Color(0.2, 0.6, 0.2)
	bar_fill.set_corner_radius_all(3)
	level_bar.add_theme_stylebox_override("fill", bar_fill)
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.08, 0.08, 0.12)
	bar_bg.set_corner_radius_all(3)
	level_bar.add_theme_stylebox_override("background", bar_bg)
	vbox.add_child(level_bar)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = data["description"]
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(desc_lbl)

	# Current bonus display
	var bonus_lbl = Label.new()
	var bonus_val = data["value_per_level"] * current
	var bonus_text = ""
	match data["stat"]:
		"max_hp": bonus_text = "+%d HP" % int(bonus_val)
		"speed": bonus_text = "+%d%% speed" % int(bonus_val * 100)
		"damage": bonus_text = "+%d%% damage" % int(bonus_val * 100)
		"armor": bonus_text = "+%d armor" % int(bonus_val)
		"xp_bonus": bonus_text = "+%d%% XP" % int(bonus_val * 100)
		"magnet": bonus_text = "+%d%% range" % int(bonus_val * 100)
		"cooldown": bonus_text = "-%d%% cooldown" % int(bonus_val * 100)
		"luck": bonus_text = "+%d%% luck" % int(bonus_val * 100)
		"revive": bonus_text = "%d revive(s)" % int(bonus_val)
		"weapon_slots": bonus_text = "+%d slot(s)" % int(bonus_val)
		"reroll": bonus_text = "+%d reroll(s)" % int(bonus_val)
		"banish": bonus_text = "+%d banish(es)" % int(bonus_val)
	if current > 0:
		bonus_lbl.text = "Current: %s" % bonus_text
		bonus_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	else:
		bonus_lbl.text = "Not purchased"
		bonus_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	bonus_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(bonus_lbl)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Buy button
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 26)
	btn.focus_mode = Control.FOCUS_ALL
	if maxed:
		btn.text = "✓ MAX"
		btn.disabled = true
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.08, 0.15, 0.08)
		btn_style.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", btn_style)
	else:
		btn.text = "⬆ %s" % (LocaleManager.tr_key("buy") % cost)
		btn.disabled = SaveManager.get_crystals() < cost
		var captured_uid = uid
		btn.pressed.connect(func(): _buy(captured_uid))
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.12, 0.18, 0.3)
		btn_style.set_corner_radius_all(6)
		btn_style.set_border_width_all(1)
		btn_style.border_color = Color(0.3, 0.5, 0.8)
		btn.add_theme_stylebox_override("normal", btn_style)
		var hover = btn_style.duplicate()
		hover.bg_color = Color(0.18, 0.25, 0.4)
		btn.add_theme_stylebox_override("hover", hover)
	vbox.add_child(btn)
	_buy_buttons.append(btn)

	_grid.add_child(card)

func _setup_focus() -> void:
	back_btn.focus_mode = Control.FOCUS_ALL
	for i in range(_buy_buttons.size()):
		var btn = _buy_buttons[i]
		if i > 0:
			btn.focus_neighbor_top = _buy_buttons[i - 1].get_path()
		if i < _buy_buttons.size() - 1:
			btn.focus_neighbor_bottom = _buy_buttons[i + 1].get_path()
	if not _buy_buttons.is_empty():
		_buy_buttons[-1].focus_neighbor_bottom = back_btn.get_path()
		back_btn.focus_neighbor_top = _buy_buttons[-1].get_path()
		_buy_buttons[0].focus_neighbor_top = back_btn.get_path()
		back_btn.focus_neighbor_bottom = _buy_buttons[0].get_path()
		if GamepadUI.is_gamepad_mode:
			_buy_buttons[0].call_deferred("grab_focus")

func _buy(uid: String) -> void:
	var success = SaveManager.buy_upgrade(uid)
	if not success:
		AudioManager.play_sfx("error")
	_build_shop_ui()

func _on_reset_all() -> void:
	AudioManager.play_sfx("menu_click")
	# Devolve cristais e reseta upgrades
	var total_refund := 0
	for uid in ShopDB.get_all_upgrade_ids():
		var data = ShopDB.get_upgrade(uid)
		var current = SaveManager.get_upgrade_level(uid)
		for lv in range(current):
			total_refund += data["base_cost"] + data["cost_per_level"] * lv
		SaveManager.data["upgrade_" + uid] = 0
	SaveManager.data["crystals"] = SaveManager.data.get("crystals", 0) + total_refund
	SaveManager.save_game()
	_flash_button(reset_all_btn, Color(1.0, 0.3, 0.3))
	_build_shop_ui()

func _on_fill_all() -> void:
	AudioManager.play_sfx("menu_click")
	for uid in ShopDB.get_all_upgrade_ids():
		var data = ShopDB.get_upgrade(uid)
		var current = SaveManager.get_upgrade_level(uid)
		while current < data["max_level"]:
			var cost = ShopDB.get_cost(uid)
			if SaveManager.get_crystals() < cost:
				break
			SaveManager.buy_upgrade(uid)
			current += 1
	_flash_button(max_all_btn, Color(0.3, 1.0, 0.4))
	_build_shop_ui()

func _flash_button(btn: Button, flash_color: Color) -> void:
	var original_self_modulate = btn.self_modulate
	btn.self_modulate = flash_color
	var tw = create_tween()
	tw.tween_property(btn, "self_modulate", original_self_modulate, 0.3)

func _update_crystals() -> void:
	if _crystals_label:
		_crystals_label.text = LocaleManager.tr_key("crystals") % SaveManager.get_crystals()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_viewport(): get_viewport().set_input_as_handled()
		_on_back()

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")
