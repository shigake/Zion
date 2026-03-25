extends Control

## Tela de selecao de personagem.

@onready var char_container: HBoxContainer = $VBox/Characters
@onready var info_label: Label = $VBox/InfoLabel
@onready var start_btn: Button = $VBox/StartButton
@onready var back_btn: Button = $VBox/BackButton

var selected_character: String = "ronin"

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)
	_build_character_list()

func _build_character_list() -> void:
	for child in char_container.get_children():
		child.queue_free()

	for char_id in CharacterDB.get_all_character_ids():
		var data = CharacterDB.get_character(char_id)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(150, 80)
		btn.text = "%s\n%s" % [data["name"], data["passive"]]

		if not SaveManager.is_character_unlocked(char_id):
			btn.text += "\n[LOCKED]"
			btn.disabled = true

		btn.pressed.connect(func(): _select_character(char_id, data))
		char_container.add_child(btn)

	_select_character("ronin", CharacterDB.get_character("ronin"))

func _select_character(char_id: String, data: Dictionary) -> void:
	selected_character = char_id
	info_label.text = "%s — Arma: %s\n%s" % [
		data["name"],
		WeaponDB.get_weapon(data["starting_weapon"])["name"],
		data["passive"]
	]

func _on_start() -> void:
	# Salva selecao no GameManager
	GameManager.selected_character = selected_character
	get_tree().change_scene_to_file("res://scenes/ui/relic_select.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
