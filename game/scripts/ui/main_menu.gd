extends Control

## Menu principal: Play, Loja, Opcoes + modelo 3D rotativo de fundo.

@onready var crystals_label: Label = $VBox/CrystalsLabel
@onready var play_btn: Button = $VBox/Buttons/PlayButton
@onready var multi_btn: Button = $VBox/Buttons/MultiButton
@onready var shop_btn: Button = $VBox/Buttons/ShopButton
@onready var quit_btn: Button = $VBox/Buttons/QuitButton
@onready var version_label: Label = $BottomRight/VersionLabel
@onready var credits_btn: Button = $BottomRight/CreditsButton

var _model_node: Node3D = null

func _ready() -> void:
	_setup_3d_background()
	_style_title()
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
	# Bestiary button
	var bestiary_btn = Button.new()
	bestiary_btn.text = LocaleManager.tr_key("bestiary")
	bestiary_btn.pressed.connect(func():
		AudioManager.play_sfx("menu_click")
		get_tree().change_scene_to_file("res://scenes/ui/bestiary_screen.tscn")
	)
	$VBox/Buttons.add_child(bestiary_btn)
	# Codex button
	var codex_btn = Button.new()
	codex_btn.text = LocaleManager.tr_key("codex")
	codex_btn.pressed.connect(func():
		AudioManager.play_sfx("menu_click")
		get_tree().change_scene_to_file("res://scenes/ui/codex_screen.tscn")
	)
	$VBox/Buttons.add_child(codex_btn)
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

func _setup_3d_background() -> void:
	# SubViewportContainer para o modelo 3D rotativo
	var svc = SubViewportContainer.new()
	svc.anchors_preset = Control.PRESET_FULL_RECT
	svc.anchor_right = 1.0
	svc.anchor_bottom = 1.0
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)
	move_child(svc, 1)  # Atras do Background mas atras de VBox

	var sv = SubViewport.new()
	sv.size = Vector2i(1280, 720)
	sv.transparent_bg = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(sv)

	# World3D para o modelo
	var world = Node3D.new()
	sv.add_child(world)

	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(2.5, 1.5, 3.5)
	cam.look_at(Vector3(0, 0.5, 0))
	cam.fov = 40
	world.add_child(cam)

	# Luz
	var light = DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-40), deg_to_rad(30), 0)
	light.light_energy = 1.2
	world.add_child(light)

	# Ambient light
	var env = Environment.new()
	env.ambient_light_color = Color(0.3, 0.35, 0.5)
	env.ambient_light_energy = 0.5
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.05)
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	world.add_child(world_env)

	# Modelo do personagem (aleatorio)
	var chars = CharacterDB.get_all_character_ids()
	var random_char = chars[randi() % chars.size()]
	_model_node = ModelFactory.get_model_for_character(random_char)
	if _model_node:
		_model_node.position = Vector3(0, 0, 0)
		world.add_child(_model_node)

func _style_title() -> void:
	var title = $VBox/Title
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
	var subtitle = $VBox/Subtitle
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))

func _process(delta: float) -> void:
	if _model_node and is_instance_valid(_model_node):
		_model_node.rotation.y += delta * 0.5

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
	get_tree().change_scene_to_file("res://scenes/ui/credits_screen.tscn")

func _on_quit() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().quit()
