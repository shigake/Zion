extends CanvasLayer

## Tela de Game Over com stats.

@onready var panel: PanelContainer = $Panel
@onready var time_label: Label = $Panel/VBox/TimeLabel
@onready var kills_label: Label = $Panel/VBox/KillsLabel
@onready var level_label: Label = $Panel/VBox/LevelLabel
@onready var retry_btn: Button = $Panel/VBox/RetryButton

func _ready() -> void:
	panel.visible = false
	GameManager.game_over.connect(_show)
	retry_btn.pressed.connect(_on_retry)

func _show() -> void:
	await get_tree().create_timer(1.0).timeout
	var t = int(GameManager.game_time)
	time_label.text = "Tempo: %02d:%02d" % [t / 60, t % 60]
	kills_label.text = "Kills: %d" % GameManager.total_kills
	level_label.text = "Level: %d" % GameManager.player_level
	panel.visible = true
	GameManager.paused = true

func _on_retry() -> void:
	GameManager.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()
