extends Control

## Tela de opcoes: Volume, Fullscreen, Idioma, Keybindings.

var waiting_for_key: String = ""  # Action being rebound
var keybind_buttons: Dictionary = {}  # action -> Button

func _ready() -> void:
	_build_ui()
	GamepadUI.notify_menu_opened()

func _build_ui() -> void:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	scroll.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = LocaleManager.tr_key("options")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
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
		# Center window
		var screen_size = DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size - r) / 2)
		SaveManager.data["resolution"] = idx
		SaveManager.save_game()
	)
	res_hbox.add_child(res_option)
	vbox.add_child(res_hbox)

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

	# ---- Telemetry ----
	var tele_hbox = HBoxContainer.new()
	var tele_label = Label.new()
	tele_label.text = LocaleManager.tr_key("telemetry_toggle")
	tele_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tele_hbox.add_child(tele_label)
	var tele_check = CheckButton.new()
	tele_check.button_pressed = SaveManager.data.get("telemetry_enabled", true)
	tele_check.toggled.connect(func(pressed):
		Telemetry.set_enabled(pressed)
	)
	tele_hbox.add_child(tele_check)
	vbox.add_child(tele_hbox)

	vbox.add_child(HSeparator.new())

	# ---- Keybindings ----
	var kb_title = Label.new()
	kb_title.text = LocaleManager.tr_key("keybindings")
	kb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(kb_title)

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

	# Reset keybindings button
	var reset_btn = Button.new()
	reset_btn.text = LocaleManager.tr_key("reset_keybindings")
	reset_btn.pressed.connect(func():
		KeybindingManager.reset_defaults()
		for act in keybind_buttons:
			keybind_buttons[act].text = KeybindingManager.get_key_name(act)
	)
	vbox.add_child(reset_btn)

	vbox.add_child(HSeparator.new())

	# Back button
	var back_btn = Button.new()
	back_btn.text = LocaleManager.tr_key("back")
	back_btn.pressed.connect(_on_back)
	vbox.add_child(back_btn)

func _add_slider(parent: Control, label_text: String, bus_name: String, default_val: float) -> void:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var slider = HSlider.new()
	slider.custom_minimum_size = Vector2(200, 0)
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

func _unhandled_input(event: InputEvent) -> void:
	if waiting_for_key.is_empty():
		if event.is_action_pressed("ui_cancel"):
			_on_back()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed:
		KeybindingManager.rebind_action(waiting_for_key, event.physical_keycode)
		keybind_buttons[waiting_for_key].text = KeybindingManager.get_key_name(waiting_for_key)
		waiting_for_key = ""
		get_viewport().set_input_as_handled()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
