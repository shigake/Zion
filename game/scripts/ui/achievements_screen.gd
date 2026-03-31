extends Control

## Achievements screen — grid display of all 13 achievements.
## Unlocked: colored icon + name + description.
## Locked: gray icon + "???" + hint.
## Counter "X/13 conquistas" at top.

const COLUMNS := 3
const CARD_SIZE := Vector2(380, 100)
const COLOR_BG := Color(0.08, 0.08, 0.12, 1.0)
const COLOR_GOLD := Color(1.0, 0.85, 0.2)
const COLOR_GOLD_DIM := Color(0.7, 0.6, 0.2)
const COLOR_WHITE := Color(0.92, 0.92, 0.95)
const COLOR_GRAY := Color(0.45, 0.45, 0.5)
const COLOR_GRAY_LIGHT := Color(0.6, 0.6, 0.65)
const COLOR_CARD_BG := Color(0.12, 0.12, 0.16, 0.95)
const COLOR_CARD_UNLOCKED := Color(0.14, 0.13, 0.08, 0.95)
const COLOR_CARD_BORDER := Color(0.22, 0.21, 0.28)
const COLOR_CARD_BORDER_UNLOCKED := Color(0.6, 0.5, 0.15, 0.7)
const COLOR_PROGRESS_BG := Color(0.15, 0.15, 0.2)
const COLOR_PROGRESS_FILL := Color(0.85, 0.7, 0.2)

var grid: GridContainer
var back_btn: Button
var scroll: ScrollContainer
var counter_label: Label
var progress_bar: ProgressBar


func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_populate_grid()
	GamepadUI.notify_menu_opened()
	# Bug 12 fix — grab focus on back button for gamepad
	if GamepadUI.is_gamepad_mode:
		back_btn.call_deferred("grab_focus")

func _unhandled_input_scroll(event: InputEvent) -> void:
	# Bug 12 — D-pad scrolls achievement list
	if scroll and (event.is_action_pressed("ui_down") or event.is_action("ui_down")):
		scroll.scroll_vertical += 40
	elif scroll and (event.is_action_pressed("ui_up") or event.is_action("ui_up")):
		scroll.scroll_vertical -= 40


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left = 24
	main_vbox.offset_right = -24
	main_vbox.offset_top = 16
	main_vbox.offset_bottom = -16
	main_vbox.add_theme_constant_override("separation", 12)
	add_child(main_vbox)

	# Header row: back button + title + counter
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	main_vbox.add_child(header)

	back_btn = Button.new()
	back_btn.text = "< Voltar"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.focus_mode = Control.FOCUS_ALL
	back_btn.pressed.connect(_on_back)
	_style_button(back_btn)
	header.add_child(back_btn)

	var title := Label.new()
	title.text = "Conquistas"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)

	# Counter
	counter_label = Label.new()
	counter_label.add_theme_font_size_override("font_size", 16)
	counter_label.add_theme_color_override("font_color", COLOR_GRAY_LIGHT)
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	counter_label.custom_minimum_size = Vector2(180, 0)
	header.add_child(counter_label)

	# Global progress bar
	var progress_container := HBoxContainer.new()
	progress_container.add_theme_constant_override("separation", 12)
	main_vbox.add_child(progress_container)

	var progress_label := Label.new()
	progress_label.text = "Progresso geral"
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", COLOR_GRAY)
	progress_container.add_child(progress_label)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 14)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.show_percentage = false

	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = COLOR_PROGRESS_FILL
	fill_sb.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("fill", fill_sb)

	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = COLOR_PROGRESS_BG
	bg_sb.set_corner_radius_all(4)
	bg_sb.set_border_width_all(1)
	bg_sb.border_color = Color(0.25, 0.25, 0.3)
	progress_bar.add_theme_stylebox_override("background", bg_sb)

	progress_container.add_child(progress_bar)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", StyleBoxFlat.new())
	main_vbox.add_child(sep)

	# Scroll container with grid
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)


func _populate_grid() -> void:
	# Clear old entries
	for child in grid.get_children():
		child.queue_free()

	var all_achievements := AchievementManager.get_all_achievements()
	var unlocked_list: Array = SaveManager.data.get("achievements", [])
	var total := all_achievements.size()
	var unlocked_count := 0

	# Sort achievement keys for consistent display
	var keys := all_achievements.keys()
	keys.sort()

	for id in keys:
		var ach: Dictionary = all_achievements[id]
		var is_unlocked: bool = unlocked_list.has(id)
		if is_unlocked:
			unlocked_count += 1
		var card := _create_card(id, ach, is_unlocked)
		grid.add_child(card)

	# Update counter
	counter_label.text = "%d/%d conquistas" % [unlocked_count, total]
	progress_bar.max_value = total
	progress_bar.value = unlocked_count


func _create_card(id: String, ach: Dictionary, is_unlocked: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE

	# Card stylebox
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_CARD_UNLOCKED if is_unlocked else COLOR_CARD_BG
	sb.border_color = COLOR_CARD_BORDER_UNLOCKED if is_unlocked else COLOR_CARD_BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)

	# Icon
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var icon_path := "res://assets/sprites/achievements/%s.png" % id
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	else:
		icon.texture = _create_placeholder_icon()

	if not is_unlocked:
		icon.modulate = Color(0.3, 0.3, 0.3)  # Gray out locked icons
	hbox.add_child(icon)

	# Text column
	var text_vbox := VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	if is_unlocked:
		name_label.text = ach.get("name", id)
		name_label.add_theme_color_override("font_color", COLOR_WHITE)
	else:
		name_label.text = "???"
		name_label.add_theme_color_override("font_color", COLOR_GRAY)
	name_label.add_theme_font_size_override("font_size", 14)
	text_vbox.add_child(name_label)

	var desc_label := Label.new()
	if is_unlocked:
		desc_label.text = ach.get("description", "")
		desc_label.add_theme_color_override("font_color", COLOR_GRAY_LIGHT)
	else:
		# Show hint (the description acts as a hint for locked achievements)
		desc_label.text = ach.get("description", "???")
		desc_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_vbox.add_child(desc_label)

	# Status indicator
	var status := Label.new()
	if is_unlocked:
		status.text = "Desbloqueada"
		status.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	else:
		status.text = "Bloqueada"
		status.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
	status.add_theme_font_size_override("font_size", 9)
	text_vbox.add_child(status)

	hbox.add_child(text_vbox)

	return card


func _style_button(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", COLOR_WHITE)
	btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
	btn.add_theme_color_override("font_pressed_color", COLOR_GOLD_DIM)

	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.12, 0.12, 0.16)
	sb_normal.border_color = Color(0.22, 0.21, 0.28)
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(6)
	sb_normal.content_margin_left = 16
	sb_normal.content_margin_right = 16
	sb_normal.content_margin_top = 6
	sb_normal.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", sb_normal)

	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.18, 0.17, 0.24)
	sb_hover.border_color = Color(0.9, 0.8, 0.3, 0.6)
	sb_hover.set_border_width_all(1)
	sb_hover.set_corner_radius_all(6)
	sb_hover.content_margin_left = 16
	sb_hover.content_margin_right = 16
	sb_hover.content_margin_top = 6
	sb_hover.content_margin_bottom = 6
	btn.add_theme_stylebox_override("hover", sb_hover)

	var sb_pressed := StyleBoxFlat.new()
	sb_pressed.bg_color = Color(0.22, 0.20, 0.30)
	sb_pressed.border_color = COLOR_GOLD
	sb_pressed.set_border_width_all(1)
	sb_pressed.set_corner_radius_all(6)
	sb_pressed.content_margin_left = 16
	sb_pressed.content_margin_right = 16
	sb_pressed.content_margin_top = 6
	sb_pressed.content_margin_bottom = 6
	btn.add_theme_stylebox_override("pressed", sb_pressed)

	var sb_focus := sb_hover.duplicate()
	sb_focus.border_color = COLOR_GOLD
	sb_focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("focus", sb_focus)


func _create_placeholder_icon() -> ImageTexture:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(24, 24)
	for x in range(48):
		for y in range(48):
			var dist := Vector2(x, y).distance_to(center)
			if dist < 18.0:
				var alpha := clampf(1.0 - (dist / 18.0) * 0.3, 0.0, 1.0)
				img.set_pixel(x, y, Color(0.9, 0.75, 0.2, alpha))
			elif dist < 19.0:
				img.set_pixel(x, y, Color(0.7, 0.55, 0.1, 0.8))
	return ImageTexture.create_from_image(img)


func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		if get_viewport():
			get_viewport().set_input_as_handled()
