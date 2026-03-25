extends Control

## Menu principal: Play, Loja, Opcoes.

@onready var crystals_label: Label = $VBox/CrystalsLabel
@onready var play_btn: Button = $VBox/Buttons/PlayButton
@onready var shop_btn: Button = $VBox/Buttons/ShopButton
@onready var quit_btn: Button = $VBox/Buttons/QuitButton

func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	shop_btn.pressed.connect(_on_shop)
	quit_btn.pressed.connect(_on_quit)
	_update_crystals()

func _update_crystals() -> void:
	crystals_label.text = "Cristais: %d" % SaveManager.get_crystals()

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")

func _on_shop() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")

func _on_quit() -> void:
	get_tree().quit()
