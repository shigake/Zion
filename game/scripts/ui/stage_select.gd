extends Control

## Tela de selecao de fase.

@onready var stage_container: HBoxContainer = $VBox/Stages
@onready var info_label: Label = $VBox/InfoLabel
@onready var next_btn: Button = $VBox/NextButton
@onready var back_btn: Button = $VBox/BackButton

var selected_stage: String = "cemetery"

# Stage definitions
var stages: Array[Dictionary] = [
	{"id": "cemetery", "name": "Cemiterio", "description": "Um cemiterio sombrio cheio de mortos-vivos."},
	{"id": "forest", "name": "Floresta", "description": "Uma floresta densa com criaturas selvagens."},
	{"id": "farm", "name": "Fazenda", "description": "Uma fazenda abandonada infestada de monstros."},
]

func _ready() -> void:
	next_btn.pressed.connect(_on_next)
	back_btn.pressed.connect(_on_back)
	_build_stage_list()

func _build_stage_list() -> void:
	for child in stage_container.get_children():
		child.queue_free()

	for stage in stages:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(180, 80)

		var unlocked = SaveManager.is_stage_unlocked(stage["id"])
		if unlocked:
			btn.text = stage["name"]
		else:
			btn.text = stage["name"] + "\n[LOCKED]"
			btn.disabled = true

		btn.pressed.connect(func(): _select_stage(stage))
		stage_container.add_child(btn)

	# Select first stage by default
	_select_stage(stages[0])

func _select_stage(stage: Dictionary) -> void:
	selected_stage = stage["id"]
	info_label.text = "%s — %s" % [stage["name"], stage["description"]]

func _on_next() -> void:
	GameManager.selected_stage = selected_stage
	get_tree().change_scene_to_file("res://scenes/ui/relic_select.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
