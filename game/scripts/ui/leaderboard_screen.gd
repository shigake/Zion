extends Control

## Leaderboard de Modo Endless - top 10 runs.

@onready var list_container: VBoxContainer = $VBox/ScrollContainer/ListContainer
@onready var back_btn: Button = $VBox/BackButton
@onready var title_label: Label = $VBox/TitleLabel

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.pressed.connect(_on_back)
	back_btn.focus_mode = Control.FOCUS_ALL
	title_label.text = LocaleManager.tr_key("leaderboard_title")
	_build_leaderboard()
	GamepadUI.notify_menu_opened()

func _build_leaderboard() -> void:
	for child in list_container.get_children():
		child.queue_free()

	var entries = SaveManager.get_leaderboard()
	if entries.is_empty():
		var empty_label = Label.new()
		empty_label.text = LocaleManager.tr_key("leaderboard_empty")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_container.add_child(empty_label)
		return

	# Header
	var header = Label.new()
	header.text = LocaleManager.tr_key("leaderboard_header")
	header.add_theme_font_size_override("font_size", 16)
	list_container.add_child(header)

	var sep = HSeparator.new()
	list_container.add_child(sep)

	for i in range(entries.size()):
		var entry = entries[i]
		var time_sec = int(entry.get("time", 0))
		var time_str = "%02d:%02d" % [time_sec / 60, time_sec % 60]
		var label = Label.new()
		label.text = "  %d   | %s    | %d   | %s | %s" % [
			i + 1,
			time_str,
			entry.get("kills", 0),
			entry.get("character", "???"),
			entry.get("date", ""),
		]
		if i == 0:
			label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		elif i == 1:
			label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		elif i == 2:
			label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
		list_container.add_child(label)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
