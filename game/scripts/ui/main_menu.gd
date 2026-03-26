extends Control

## Menu principal: Play, Loja, Opcoes.

@onready var crystals_label: Label = $VBox/CrystalsLabel
@onready var play_btn: Button = $VBox/Buttons/PlayButton
@onready var multi_btn: Button = $VBox/Buttons/MultiButton
@onready var shop_btn: Button = $VBox/Buttons/ShopButton
@onready var quit_btn: Button = $VBox/Buttons/QuitButton
@onready var version_label: Label = $BottomRight/VersionLabel
@onready var credits_btn: Button = $BottomRight/CreditsButton
@onready var credits_popup: PanelContainer = $CreditsPopup

func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	multi_btn.pressed.connect(_on_multiplayer)
	shop_btn.pressed.connect(_on_shop)
	quit_btn.pressed.connect(_on_quit)
	# Aplica texto localizado nos botoes da cena
	play_btn.text = LocaleManager.tr_key("menu_play_solo")
	multi_btn.text = LocaleManager.tr_key("menu_multiplayer")
	shop_btn.text = LocaleManager.tr_key("menu_shop")
	quit_btn.text = LocaleManager.tr_key("menu_quit")
	# Leaderboard button (added programmatically)
	var leaderboard_btn = Button.new()
	leaderboard_btn.text = LocaleManager.tr_key("menu_leaderboard")
	leaderboard_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/leaderboard_screen.tscn"))
	$VBox/Buttons.add_child(leaderboard_btn)
	# Options button
	var options_btn = Button.new()
	options_btn.text = LocaleManager.tr_key("menu_options")
	options_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/options_screen.tscn"))
	$VBox/Buttons.add_child(options_btn)
	# Reorder: Sair always last, Opcoes right above it
	# Order: Jogar Solo, Multiplayer, Loja, Leaderboard, Opcoes, Sair
	var btn_count = $VBox/Buttons.get_child_count()
	$VBox/Buttons.move_child(quit_btn, btn_count - 1)  # Sair last
	$VBox/Buttons.move_child(options_btn, btn_count - 2)  # Opcoes before Sair
	credits_btn.pressed.connect(_on_credits)
	credits_popup.get_node("VBox/CloseButton").pressed.connect(_on_credits_close)
	_update_crystals()
	_update_version()
	AudioManager.play_music("menu")
	# Gamepad: garante foco nos botoes
	_setup_gamepad_focus()

func _setup_gamepad_focus() -> void:
	# Garante que todos os botoes podem receber foco
	var buttons := []
	for child in $VBox/Buttons.get_children():
		if child is Button:
			child.focus_mode = Control.FOCUS_ALL
			buttons.append(child)
	# Configura vizinhos de foco verticais
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		if i > 0:
			btn.focus_neighbor_top = buttons[i - 1].get_path()
		else:
			btn.focus_neighbor_top = buttons[buttons.size() - 1].get_path()  # Wrap
		if i < buttons.size() - 1:
			btn.focus_neighbor_bottom = buttons[i + 1].get_path()
		else:
			btn.focus_neighbor_bottom = buttons[0].get_path()  # Wrap
	# Foca no primeiro botao se estiver no modo gamepad
	GamepadUI.notify_menu_opened()

func _update_version() -> void:
	var file = FileAccess.open("res://VERSION", FileAccess.READ)
	if file:
		version_label.text = "v" + file.get_as_text().strip_edges()
	else:
		version_label.text = "v1.0.0"

func _update_crystals() -> void:
	crystals_label.text = LocaleManager.tr_key("crystals") % SaveManager.get_crystals()

func _on_play() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")

func _on_multiplayer() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/lobby_screen.tscn")

func _on_shop() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")

func _on_credits() -> void:
	AudioManager.play_sfx("menu_click")
	credits_popup.visible = true

func _on_credits_close() -> void:
	AudioManager.play_sfx("menu_click")
	credits_popup.visible = false

func _on_quit() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().quit()
