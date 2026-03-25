extends CanvasLayer

## Pause menu — ESC para pausar/despausar.

@onready var panel: PanelContainer = $Panel
@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var menu_btn: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	panel.visible = false
	resume_btn.pressed.connect(_on_resume)
	menu_btn.pressed.connect(_on_menu)

	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
		var event = InputEventKey.new()
		event.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", event)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not GameManager.is_game_over:
		if panel.visible:
			_on_resume()
		else:
			_pause()

func _pause() -> void:
	panel.visible = true
	GameManager.paused = true
	get_tree().paused = true

func _on_resume() -> void:
	panel.visible = false
	GameManager.paused = false
	get_tree().paused = false

func _on_menu() -> void:
	get_tree().paused = false
	GameManager.paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
