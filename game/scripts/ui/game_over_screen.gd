extends CanvasLayer

## Tela de Game Over com stats e cristais ganhos.

@onready var panel: PanelContainer = $Panel
@onready var time_label: Label = $Panel/VBox/TimeLabel
@onready var kills_label: Label = $Panel/VBox/KillsLabel
@onready var level_label: Label = $Panel/VBox/LevelLabel
@onready var crystals_label: Label = $Panel/VBox/CrystalsLabel
@onready var retry_btn: Button = $Panel/VBox/RetryButton
@onready var menu_btn: Button = $Panel/VBox/MenuButton

@onready var overlay: ColorRect = $Overlay

func _ready() -> void:
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	GameManager.game_over.connect(_show)
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_menu)

func _show() -> void:
	GameManager.end_run()
	AchievementManager.check_achievements()
	await get_tree().create_timer(1.0).timeout
	var t = int(GameManager.game_time)
	if GameManager.is_victory:
		time_label.text = "VITORIA! Tempo: %02d:%02d" % [t / 60, t % 60]
	else:
		time_label.text = "Tempo: %02d:%02d" % [t / 60, t % 60]
	kills_label.text = "Kills: %d" % GameManager.total_kills
	level_label.text = "Level: %d" % GameManager.player_level
	crystals_label.text = "Cristais ganhos: +%d" % GameManager.crystals_this_run
	# Leaderboard rank para endless mode
	if GameManager.game_mode == "endless":
		var leaderboard = SaveManager.get_leaderboard()
		for i in range(leaderboard.size()):
			if absf(leaderboard[i].get("time", 0) - GameManager.game_time) < 1.0:
				crystals_label.text += "\nLeaderboard: #%d!" % (i + 1)
				break
	# Stage completion check
	if GameManager.game_mode == "normal":
		var stage_name = GameManager.selected_stage.capitalize()
		crystals_label.text += "\nFase %s completa!" % stage_name
	# Show total damage dealt
	crystals_label.text += "\nDano total: %d" % GameManager.total_damage_dealt
	# Unlocks
	var unlocked = SaveManager.check_unlocks()
	if not unlocked.is_empty():
		for char_id in unlocked:
			var char_data = CharacterDB.get_character(char_id)
			crystals_label.text += "\nDESBLOQUEADO: %s!" % char_data["name"]
	overlay.visible = true
	panel.visible = true
	GameManager.paused = true
	# Gamepad: foca no Retry
	retry_btn.focus_mode = Control.FOCUS_ALL
	menu_btn.focus_mode = Control.FOCUS_ALL
	retry_btn.focus_neighbor_bottom = menu_btn.get_path()
	retry_btn.focus_neighbor_top = menu_btn.get_path()
	menu_btn.focus_neighbor_top = retry_btn.get_path()
	menu_btn.focus_neighbor_bottom = retry_btn.get_path()
	GamepadUI.notify_menu_opened()

func _on_retry() -> void:
	get_tree().paused = false
	var stage_scenes = {
		"cemetery": "res://scenes/stages/stage_cemetery.tscn",
		"forest": "res://scenes/stages/stage_forest.tscn",
		"farm": "res://scenes/stages/stage_farm.tscn",
		"tokyo": "res://scenes/stages/stage_tokyo.tscn",
		"volcano": "res://scenes/stages/stage_volcano.tscn",
		"ocean": "res://scenes/stages/stage_ocean.tscn",
		"arena": "res://scenes/stages/stage_arena.tscn",
		"space": "res://scenes/stages/stage_space.tscn",
		"castle": "res://scenes/stages/stage_castle.tscn",
		"candy": "res://scenes/stages/stage_candy.tscn",
	}
	var scene = stage_scenes.get(GameManager.selected_stage, "res://scenes/stages/stage_cemetery.tscn")
	get_tree().change_scene_to_file(scene)

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
