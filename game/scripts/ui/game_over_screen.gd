extends CanvasLayer

## Tela de Game Over com stats e cristais ganhos.

@onready var panel: PanelContainer = $Panel
@onready var time_label: Label = $Panel/VBox/TimeLabel
@onready var kills_label: Label = $Panel/VBox/KillsLabel
@onready var level_label: Label = $Panel/VBox/LevelLabel
@onready var crystals_label: Label = $Panel/VBox/CrystalsLabel
@onready var retry_btn: Button = $Panel/VBox/RetryButton
@onready var menu_btn: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	panel.visible = false
	GameManager.game_over.connect(_show)
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_menu)

func _show() -> void:
	GameManager.end_run()
	await get_tree().create_timer(1.0).timeout
	var t = int(GameManager.game_time)
	time_label.text = "Tempo: %02d:%02d" % [t / 60, t % 60]
	kills_label.text = "Kills: %d" % GameManager.total_kills
	level_label.text = "Level: %d" % GameManager.player_level
	crystals_label.text = "Cristais ganhos: +%d" % GameManager.crystals_this_run
	panel.visible = true
	GameManager.paused = true

func _on_retry() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/stages/stage_cemetery.tscn")

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
