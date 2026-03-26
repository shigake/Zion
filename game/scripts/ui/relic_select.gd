extends Control

## Tela de selecao de reliquia antes da run.

@onready var relic_container: HBoxContainer = $VBox/Relics
@onready var info_label: Label = $VBox/InfoLabel
@onready var start_btn: Button = $VBox/StartButton
@onready var back_btn: Button = $VBox/BackButton

var selected_relic: String = ""

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)
	_build_relic_list()

func _build_relic_list() -> void:
	for child in relic_container.get_children():
		child.queue_free()

	# Use GridContainer to prevent overflow
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)

	# Opcao sem reliquia
	var none_btn = Button.new()
	none_btn.custom_minimum_size = Vector2(140, 60)
	none_btn.text = "Nenhuma\nSem bonus"
	none_btn.pressed.connect(func(): _select_relic("", {"name": "Nenhuma", "description": "Sem bonus"}))
	grid.add_child(none_btn)

	for relic_id in RelicDB.get_all_relic_ids():
		var data = RelicDB.get_relic(relic_id)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(140, 60)
		btn.text = "%s" % data["name"]
		btn.pressed.connect(func(): _select_relic(relic_id, data))
		grid.add_child(btn)

	relic_container.add_child(grid)

func _select_relic(relic_id: String, data: Dictionary) -> void:
	selected_relic = relic_id
	info_label.text = "%s — %s" % [data["name"], data["description"]]

var selected_mode: String = "normal"

func _on_mode_normal() -> void:
	selected_mode = "normal"
	info_label.text = "Modo Normal — 30 min, boss no final"

func _on_mode_endless() -> void:
	selected_mode = "endless"
	info_label.text = "Modo Endless — Sem limite, sobreviva o maximo"

func _on_start() -> void:
	GameManager.selected_relic = selected_relic
	GameManager.game_mode = selected_mode
	if selected_mode == "endless":
		GameManager.run_time_limit = 999999.0
	else:
		GameManager.run_time_limit = 1800.0
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

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
