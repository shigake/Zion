extends CanvasLayer

## Pause menu — ESC para pausar/despausar.

@onready var panel: PanelContainer = $Panel
@onready var overlay: ColorRect = $Overlay
@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var menu_btn: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	panel.visible = false
	overlay.visible = false
	resume_btn.pressed.connect(_on_resume)
	menu_btn.pressed.connect(_on_menu)

	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
		var event = InputEventKey.new()
		event.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", event)

	# Options button
	var options_btn = Button.new()
	options_btn.text = "Opcoes"
	options_btn.custom_minimum_size = Vector2(0, 40)
	options_btn.pressed.connect(_on_options)
	$Panel/VBox.add_child(options_btn)
	$Panel/VBox.move_child(options_btn, 2)  # After Resume, before Menu

	# Quit button (fecha a aplicação)
	var quit_btn = Button.new()
	quit_btn.text = "Sair do Jogo"
	quit_btn.custom_minimum_size = Vector2(0, 40)
	quit_btn.pressed.connect(_on_quit)
	$Panel/VBox.add_child(quit_btn)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not GameManager.is_game_over:
		if panel.visible:
			_on_resume()
		else:
			_pause()

func _pause() -> void:
	panel.visible = true
	overlay.visible = true
	GameManager.paused = true
	get_tree().paused = true

func _on_resume() -> void:
	panel.visible = false
	overlay.visible = false
	GameManager.paused = false
	get_tree().paused = false

func _on_options() -> void:
	# Inline options panel
	var options_panel = PanelContainer.new()
	options_panel.name = "OptionsPanel"
	options_panel.set_anchors_preset(Control.PRESET_CENTER)
	options_panel.offset_left = -200
	options_panel.offset_top = -200
	options_panel.offset_right = 200
	options_panel.offset_bottom = 200

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	options_panel.add_child(vbox)

	var title = Label.new()
	title.text = "OPCOES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Fullscreen toggle
	var fs_hbox = HBoxContainer.new()
	var fs_label = Label.new()
	fs_label.text = "Tela Cheia"
	fs_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fs_hbox.add_child(fs_label)
	var fs_check = CheckButton.new()
	fs_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs_check.toggled.connect(func(pressed):
		if pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	fs_hbox.add_child(fs_check)
	vbox.add_child(fs_hbox)

	# Language toggle
	var lang_hbox = HBoxContainer.new()
	var lang_label = Label.new()
	lang_label.text = "Idioma"
	lang_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang_hbox.add_child(lang_label)
	var lang_btn = Button.new()
	lang_btn.text = LocaleManager.get_locale_name(LocaleManager.get_locale())
	lang_btn.pressed.connect(func():
		var locales = LocaleManager.get_available_locales()
		var idx = locales.find(LocaleManager.get_locale())
		idx = (idx + 1) % locales.size()
		LocaleManager.set_locale(locales[idx])
		lang_btn.text = LocaleManager.get_locale_name(locales[idx])
	)
	lang_hbox.add_child(lang_btn)
	vbox.add_child(lang_hbox)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(func(): options_panel.queue_free())
	vbox.add_child(close_btn)

	add_child(options_panel)

func _on_menu() -> void:
	get_tree().paused = false
	GameManager.paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_quit() -> void:
	get_tree().quit()
