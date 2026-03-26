extends Control

## Menu principal: Play, Loja, Opcoes.

@onready var crystals_label: Label = $VBox/CrystalsLabel
@onready var play_btn: Button = $VBox/Buttons/PlayButton
@onready var multi_btn: Button = $VBox/Buttons/MultiButton
@onready var shop_btn: Button = $VBox/Buttons/ShopButton
@onready var quit_btn: Button = $VBox/Buttons/QuitButton
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	multi_btn.pressed.connect(_on_multiplayer)
	shop_btn.pressed.connect(_on_shop)
	quit_btn.pressed.connect(_on_quit)
	# Leaderboard button (added programmatically)
	var leaderboard_btn = Button.new()
	leaderboard_btn.text = "Leaderboard"
	leaderboard_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/leaderboard_screen.tscn"))
	$VBox/Buttons.add_child(leaderboard_btn)
	$VBox/Buttons.move_child(leaderboard_btn, $VBox/Buttons.get_child_count() - 1)
	# Options button
	var options_btn = Button.new()
	options_btn.text = "Opcoes"
	options_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/options_screen.tscn"))
	$VBox/Buttons.add_child(options_btn)
	$VBox/Buttons.move_child(options_btn, $VBox/Buttons.get_child_count() - 1)
	_update_crystals()
	_update_version()
	AudioManager.play_music("menu")

func _update_version() -> void:
	var file = FileAccess.open("res://VERSION", FileAccess.READ)
	if file:
		version_label.text = "v" + file.get_as_text().strip_edges()
	else:
		version_label.text = "v1.0.0"

func _update_crystals() -> void:
	crystals_label.text = "Cristais: %d" % SaveManager.get_crystals()

func _on_play() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")

func _on_multiplayer() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/lobby_screen.tscn")

func _on_shop() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")

func _on_quit() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().quit()
