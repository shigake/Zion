extends CanvasLayer

## Pause menu — ESC para pausar/despausar.

@onready var panel: PanelContainer = $Panel
@onready var overlay: ColorRect = $Overlay
@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var menu_btn: Button = $Panel/VBox/MenuButton

var options_panel: PanelContainer = null
var waiting_for_key: String = ""
var keybind_buttons: Dictionary = {}
# Guarda se o jogo ja estava "pausado" antes do pause ser aberto
# (ex: levelup aberto). Ao retomar, restaura esse estado.
var _was_gm_paused_before: bool = false

func _ready() -> void:
	panel.visible = false
	overlay.visible = false
	resume_btn.pressed.connect(_on_resume)
	menu_btn.pressed.connect(_on_menu)

	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
	# Always ensure ESC is mapped (GameManager may have created the action with only gamepad)
	var already_has_key := false
	for ev in InputMap.action_get_events("pause"):
		if ev is InputEventKey and ev.physical_keycode == KEY_ESCAPE:
			already_has_key = true
			break
	if not already_has_key:
		var event = InputEventKey.new()
		event.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", event)

	# Aplica texto localizado nos botoes da cena
	resume_btn.text = LocaleManager.tr_key("resume")
	menu_btn.text = LocaleManager.tr_key("quit_to_menu")
	# Options button
	var options_btn = Button.new()
	options_btn.text = LocaleManager.tr_key("options")
	options_btn.custom_minimum_size = Vector2(0, 40)
	options_btn.pressed.connect(_on_options)
	$Panel/VBox.add_child(options_btn)
	$Panel/VBox.move_child(options_btn, 2)  # After Resume, before Menu

	# Quit button (fecha a aplicacao)
	var quit_btn = Button.new()
	quit_btn.text = LocaleManager.tr_key("quit_game")
	quit_btn.custom_minimum_size = Vector2(0, 40)
	quit_btn.pressed.connect(_on_quit)
	$Panel/VBox.add_child(quit_btn)

func _unhandled_input(event: InputEvent) -> void:
	# Handle keybinding rebind
	if not waiting_for_key.is_empty():
		if event is InputEventKey and event.pressed:
			KeybindingManager.rebind_action(waiting_for_key, event.physical_keycode)
			keybind_buttons[waiting_for_key].text = KeybindingManager.get_key_name(waiting_for_key)
			waiting_for_key = ""
			if get_viewport(): get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pause") and not GameManager.is_game_over:
		if options_panel and is_instance_valid(options_panel):
			options_panel.queue_free()
			options_panel = null
			return
		if panel.visible:
			_on_resume()
		else:
			_pause()

var stats_panel: PanelContainer = null

func _pause() -> void:
	# Salva se GameManager ja estava pausado (ex: levelup aberto)
	_was_gm_paused_before = GameManager.paused
	panel.visible = true
	overlay.visible = true
	GameManager.paused = true
	get_tree().paused = true
	# Show run stats
	_show_stats()
	# Gamepad: foco no Resume
	_setup_pause_focus()
	GamepadUI.notify_menu_opened()

func _setup_pause_focus() -> void:
	var buttons := []
	for child in $Panel/VBox.get_children():
		if child is Button:
			child.focus_mode = Control.FOCUS_ALL
			buttons.append(child)
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		if i > 0:
			btn.focus_neighbor_top = buttons[i - 1].get_path()
		else:
			btn.focus_neighbor_top = buttons[buttons.size() - 1].get_path()
		if i < buttons.size() - 1:
			btn.focus_neighbor_bottom = buttons[i + 1].get_path()
		else:
			btn.focus_neighbor_bottom = buttons[0].get_path()

func _on_resume() -> void:
	AudioManager.play_sfx("menu_click")
	if options_panel and is_instance_valid(options_panel):
		options_panel.queue_free()
		options_panel = null
	if stats_panel and is_instance_valid(stats_panel):
		stats_panel.queue_free()
		stats_panel = null
	panel.visible = false
	overlay.visible = false
	get_tree().paused = false
	# Restaura o estado de pausa anterior ao pause:
	# Se o levelup estava aberto antes, GameManager.paused deve continuar true
	# para que o jogo nao rode enquanto o levelup estiver na tela.
	GameManager.paused = _was_gm_paused_before

func _show_stats() -> void:
	if stats_panel and is_instance_valid(stats_panel):
		stats_panel.queue_free()
		stats_panel = null

	stats_panel = PanelContainer.new()
	stats_panel.name = "StatsPanel"
	stats_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	stats_panel.offset_left = -280
	stats_panel.offset_top = -200
	stats_panel.offset_right = -20
	stats_panel.offset_bottom = 200

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	stats_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Run Stats"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# DPS
	var dps = GameManager.total_damage_dealt / maxf(1.0, GameManager.game_time)
	_add_stat_line(vbox, "DPS", "%.1f" % dps)

	# Total kills
	_add_stat_line(vbox, "Kills", str(GameManager.total_kills))

	# Game time
	var t = int(GameManager.game_time)
	_add_stat_line(vbox, "Time", "%02d:%02d" % [t / 60, t % 60])

	# Total damage
	_add_stat_line(vbox, "Total DMG", str(GameManager.total_damage_dealt))

	vbox.add_child(HSeparator.new())

	# Current weapons and levels
	var weapons_title = Label.new()
	weapons_title.text = "Weapons"
	weapons_title.add_theme_font_size_override("font_size", 16)
	weapons_title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	vbox.add_child(weapons_title)

	for w in GameManager.player_weapons:
		var data = WeaponDB.weapons.get(w.id, {})
		var wname = data.get("name", w.id.capitalize())
		var whbox = HBoxContainer.new()
		var wicon_path = "res://assets/sprites/weapons/%s.png" % w.id
		var wicon_tex = load(wicon_path) if ResourceLoader.exists(wicon_path) else null
		if wicon_tex:
			var wicon = TextureRect.new()
			wicon.texture = wicon_tex
			wicon.custom_minimum_size = Vector2(20, 20)
			wicon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			wicon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			whbox.add_child(wicon)
		var wlbl = Label.new()
		wlbl.text = wname
		wlbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wlbl.add_theme_font_size_override("font_size", 14)
		whbox.add_child(wlbl)
		var wval = Label.new()
		wval.text = "Lv.%d" % w.level
		wval.add_theme_font_size_override("font_size", 14)
		wval.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
		whbox.add_child(wval)
		vbox.add_child(whbox)

	# Active synergies
	var synergies = SynergySystem.active_synergies
	if not synergies.is_empty():
		vbox.add_child(HSeparator.new())
		var syn_title = Label.new()
		syn_title.text = "Synergies"
		syn_title.add_theme_font_size_override("font_size", 16)
		syn_title.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
		vbox.add_child(syn_title)

		for syn_id in synergies:
			var desc = SynergySystem.get_synergy_description(syn_id)
			if desc != "":
				var syn_lbl = Label.new()
				syn_lbl.text = desc
				syn_lbl.add_theme_font_size_override("font_size", 12)
				syn_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
				vbox.add_child(syn_lbl)

	add_child(stats_panel)

func _add_stat_line(parent: Control, label_text: String, value_text: String) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(lbl)
	var val = Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 14)
	val.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
	hbox.add_child(val)
	parent.add_child(hbox)

func _on_options() -> void:
	AudioManager.play_sfx("menu_click")
	if options_panel and is_instance_valid(options_panel):
		options_panel.queue_free()
		options_panel = null
		return

	options_panel = PanelContainer.new()
	options_panel.name = "OptionsPanel"
	options_panel.set_anchors_preset(Control.PRESET_CENTER)
	options_panel.offset_left = -250
	options_panel.offset_top = -280
	options_panel.offset_right = 250
	options_panel.offset_bottom = 280

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	options_panel.add_child(scroll)

	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = LocaleManager.tr_key("options")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# ---- Volume ----
	_add_slider(vbox, LocaleManager.tr_key("volume_master"), "master", 1.0)
	_add_slider(vbox, LocaleManager.tr_key("volume_music"), "music", 0.8)
	_add_slider(vbox, LocaleManager.tr_key("volume_sfx"), "sfx", 1.0)

	vbox.add_child(HSeparator.new())

	# ---- Fullscreen ----
	var fs_hbox = HBoxContainer.new()
	var fs_label = Label.new()
	fs_label.text = LocaleManager.tr_key("fullscreen")
	fs_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fs_hbox.add_child(fs_label)
	var fs_check = CheckButton.new()
	fs_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs_check.toggled.connect(func(pressed):
		if pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		SaveManager.data["fullscreen"] = pressed
		SaveManager.save_game()
	)
	fs_hbox.add_child(fs_check)
	vbox.add_child(fs_hbox)

	# ---- Window Mode ----
	var wm_hbox = HBoxContainer.new()
	var wm_label = Label.new()
	wm_label.text = LocaleManager.tr_key("window_mode")
	wm_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wm_hbox.add_child(wm_label)
	var wm_option = OptionButton.new()
	wm_option.add_item(LocaleManager.tr_key("window_windowed"), 0)
	wm_option.add_item(LocaleManager.tr_key("window_fullscreen"), 1)
	wm_option.add_item(LocaleManager.tr_key("window_borderless"), 2)
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		wm_option.selected = 1
	elif current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		wm_option.selected = 2
	else:
		wm_option.selected = 0
	wm_option.item_selected.connect(func(idx):
		match idx:
			0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			2:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		SaveManager.data["window_mode"] = idx
		SaveManager.save_game()
	)
	wm_hbox.add_child(wm_option)
	vbox.add_child(wm_hbox)

	# ---- Resolution ----
	var res_hbox = HBoxContainer.new()
	var res_label = Label.new()
	res_label.text = LocaleManager.tr_key("resolution")
	res_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	res_hbox.add_child(res_label)
	var res_option = OptionButton.new()
	var resolutions = [
		Vector2i(1280, 720),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3840, 2160),
	]
	var current_res = DisplayServer.window_get_size()
	for i in range(resolutions.size()):
		var r = resolutions[i]
		res_option.add_item("%dx%d" % [r.x, r.y], i)
		if current_res.x == r.x and current_res.y == r.y:
			res_option.selected = i
	res_option.item_selected.connect(func(idx):
		var r = resolutions[idx]
		DisplayServer.window_set_size(r)
		var screen_size = DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size - r) / 2)
		SaveManager.data["resolution"] = idx
		SaveManager.save_game()
	)
	res_hbox.add_child(res_option)
	vbox.add_child(res_hbox)

	vbox.add_child(HSeparator.new())

	# ---- Language ----
	var lang_hbox = HBoxContainer.new()
	var lang_label = Label.new()
	lang_label.text = LocaleManager.tr_key("language")
	lang_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang_hbox.add_child(lang_label)
	var lang_btn = OptionButton.new()
	var locales = LocaleManager.get_available_locales()
	for i in range(locales.size()):
		lang_btn.add_item(LocaleManager.get_locale_name(locales[i]), i)
		if locales[i] == LocaleManager.get_locale():
			lang_btn.selected = i
	lang_btn.item_selected.connect(func(idx):
		LocaleManager.set_locale(locales[idx])
	)
	lang_hbox.add_child(lang_btn)
	vbox.add_child(lang_hbox)

	vbox.add_child(HSeparator.new())

	# ---- Keybindings ----
	var kb_title = Label.new()
	kb_title.text = LocaleManager.tr_key("controls_title")
	kb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(kb_title)

	keybind_buttons.clear()
	for action in KeybindingManager.get_rebindable_actions():
		var hbox = HBoxContainer.new()
		var action_label = Label.new()
		action_label.text = KeybindingManager.get_action_display_name(action)
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(action_label)

		var key_btn = Button.new()
		key_btn.text = KeybindingManager.get_key_name(action)
		key_btn.custom_minimum_size = Vector2(120, 30)
		key_btn.pressed.connect(_start_rebind.bind(action, key_btn))
		hbox.add_child(key_btn)
		keybind_buttons[action] = key_btn
		vbox.add_child(hbox)

	var reset_btn = Button.new()
	reset_btn.text = LocaleManager.tr_key("reset_keybindings")
	reset_btn.pressed.connect(func():
		KeybindingManager.reset_defaults()
		for act in keybind_buttons:
			keybind_buttons[act].text = KeybindingManager.get_key_name(act)
	)
	vbox.add_child(reset_btn)

	vbox.add_child(HSeparator.new())

	# Close button
	var close_btn = Button.new()
	close_btn.text = LocaleManager.tr_key("close")
	close_btn.pressed.connect(func():
		options_panel.queue_free()
		options_panel = null
	)
	vbox.add_child(close_btn)

	add_child(options_panel)

func _add_slider(parent: Control, label_text: String, bus_name: String, default_val: float) -> void:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var slider = HSlider.new()
	slider.custom_minimum_size = Vector2(180, 0)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = SaveManager.data.get("volume_" + bus_name, default_val)
	slider.value_changed.connect(func(val):
		var bus_idx = AudioServer.get_bus_index(bus_name.capitalize())
		if bus_idx >= 0:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val))
		SaveManager.data["volume_" + bus_name] = val
		SaveManager.save_game()
	)
	hbox.add_child(slider)
	parent.add_child(hbox)

func _start_rebind(action: String, btn: Button) -> void:
	waiting_for_key = action
	btn.text = "..."

func _on_menu() -> void:
	AudioManager.play_sfx("menu_click")
	if options_panel and is_instance_valid(options_panel):
		options_panel.queue_free()
		options_panel = null
	if stats_panel and is_instance_valid(stats_panel):
		stats_panel.queue_free()
		stats_panel = null
	get_tree().paused = false
	GameManager.paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_quit() -> void:
	get_tree().quit()
