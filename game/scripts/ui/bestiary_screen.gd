extends Control

## Bestiario — catalogo de todos os monstros do jogo.
## Mostra todos os inimigos (genericos, variantes, especiais, raros e bosses).
## Ao clicar num card, exibe detalhes e visual do inimigo no painel direito.

const COLUMNS := 4
const CARD_SIZE := Vector2(155, 115)

# Mapping de nomes de inimigos para caminhos de modelos 3D
var enemy_models: Dictionary = {
	"Slime": "res://assets/models/enemies/slime.glb",
	"Bat": "res://assets/models/enemies/bat.glb",
	"Skeleton": "res://assets/models/enemies/skeleton.glb",
	"ZombieRunner": "res://assets/models/enemies/zombie.glb",
	"Ghost": "res://assets/models/enemies/ghost.glb",
	"SlimeBig": "res://assets/models/enemies/slime_big.glb",
	"GhostWhite": "res://assets/models/enemies/ghost_white.glb",
	"GhostGreen": "res://assets/models/enemies/ghost_green.glb",
	"GhostBlue": "res://assets/models/enemies/ghost_blue.glb",
	"GhostRed": "res://assets/models/enemies/ghost_red.glb",
	"SkeletonArcher": "res://assets/models/enemies/skeleton_archer.glb",
	"Bomber": "res://assets/models/enemies/bomber.glb",
	"Tank": "res://assets/models/enemies/tank.glb",
	"Swarm": "res://assets/models/enemies/swarm.glb",
	"Mimic": "res://assets/models/enemies/mimic.glb",
	"ToothFairy": "res://assets/models/enemies/tooth_fairy.glb",
	"BossNecromancer": "res://assets/models/bosses/boss_necromancer.glb",
	"BossFairyQueen": "res://assets/models/bosses/boss_fairy_queen.glb",
	"BossAlienCow": "res://assets/models/bosses/boss_alien_cow.glb",
	"BossAIOverlord": "res://assets/models/bosses/boss_ai_overlord.glb",
	"BossDemonLord": "res://assets/models/bosses/boss_demon_lord.glb",
	"BossLeviathan": "res://assets/models/bosses/boss_leviathan.glb",
	"BossEmperor": "res://assets/models/bosses/boss_emperor.glb",
	"BossSingularity": "res://assets/models/bosses/boss_singularity.glb",
	"BossDracula": "res://assets/models/bosses/boss_dracula.glb",
	"BossSugarKing": "res://assets/models/bosses/boss_sugar_king.glb",
}

# All enemies — 26 total (6 genericos, 4 variantes, 5 especiais, 1 raro, 10 bosses)
var enemy_data: Dictionary = {
	# --- Genericos (6) ---
	"Slime": {"desc": "Basico e lento. Nao subestime em grupo.", "color": Color(0.2, 0.8, 0.2), "type": "Generico", "stage": "Todas"},
	"Bat": {"desc": "Rapido e irritante. Mira ruim.", "color": Color(0.5, 0.3, 0.6), "type": "Generico", "stage": "Todas"},
	"Skeleton": {"desc": "Guerreiro de ossos. Resiste a morte.", "color": Color(0.9, 0.9, 0.8), "type": "Generico", "stage": "Todas"},
	"ZombieRunner": {"desc": "Corre mais rapido que parece. Cuidado.", "color": Color(0.4, 0.6, 0.3), "type": "Generico", "stage": "Todas"},
	"Ghost": {"desc": "Fantasma transparente. Atravessa tudo.", "color": Color(0.6, 0.7, 0.9), "type": "Generico", "stage": "Todas"},
	"SlimeBig": {"desc": "Versao gigante do slime. Tanque lento.", "color": Color(0.1, 0.6, 0.1), "type": "Generico", "stage": "Todas"},
	# --- Variantes de Ghost — Cemiterio (4) ---
	"GhostWhite": {"desc": "Fantasma branco. Assombra o cemiterio silenciosamente.", "color": Color(0.9, 0.9, 0.95), "type": "Variante", "stage": "Cemiterio"},
	"GhostGreen": {"desc": "Fantasma toxico. Deixa rastro de veneno.", "color": Color(0.3, 0.9, 0.3), "type": "Variante", "stage": "Cemiterio"},
	"GhostBlue": {"desc": "Fantasma gelado. Congela ao toque.", "color": Color(0.3, 0.5, 1.0), "type": "Variante", "stage": "Cemiterio"},
	"GhostRed": {"desc": "Fantasma furioso. Mais rapido e agressivo.", "color": Color(1.0, 0.2, 0.2), "type": "Variante", "stage": "Cemiterio"},
	# --- Especiais (5) ---
	"SkeletonArcher": {"desc": "Atira flechas de longe. Priorize.", "color": Color(0.8, 0.7, 0.6), "type": "Especial", "stage": "Todas"},
	"Bomber": {"desc": "Explode perto de voce. Mantenha distancia.", "color": Color(0.9, 0.4, 0.1), "type": "Especial", "stage": "Todas"},
	"Tank": {"desc": "Lento mas quase indestrutivel.", "color": Color(0.5, 0.5, 0.5), "type": "Especial", "stage": "Todas"},
	"Swarm": {"desc": "Enxame de criaturas. Muitos, mas frageis.", "color": Color(0.7, 0.7, 0.2), "type": "Especial", "stage": "Todas"},
	"Mimic": {"desc": "Parece um bau. Nao e um bau.", "color": Color(0.8, 0.6, 0.2), "type": "Especial", "stage": "Todas"},
	# --- Raro (1) ---
	"ToothFairy": {"desc": "Rara e traicoeira. 3% de chance de aparecer apos o minuto 5.", "color": Color(0.9, 0.7, 1.0), "type": "Raro", "stage": "Todas (min 5+)"},
	# --- Bosses (10) ---
	"BossNecromancer": {"desc": "Invoca mortos e drena vida. Senhor do cemiterio.", "color": Color(0.3, 0.0, 0.5), "type": "Boss", "stage": "Cemiterio"},
	"BossFairyQueen": {"desc": "Rainha das fadas. Magias de natureza devastadoras.", "color": Color(0.2, 0.8, 0.4), "type": "Boss", "stage": "Floresta"},
	"BossAlienCow": {"desc": "Vaca alienigena. Sim, e serio. Abduz inimigos.", "color": Color(0.6, 0.9, 0.6), "type": "Boss", "stage": "Fazenda"},
	"BossAIOverlord": {"desc": "Inteligencia artificial malvada. Lasers e drones.", "color": Color(0.0, 0.8, 1.0), "type": "Boss", "stage": "Tokyo"},
	"BossDemonLord": {"desc": "Senhor dos demonios. Fogo infernal sem piedade.", "color": Color(0.9, 0.1, 0.0), "type": "Boss", "stage": "Vulcao"},
	"BossLeviathan": {"desc": "Monstro marinho ancestral. Tentaculos mortais.", "color": Color(0.1, 0.3, 0.7), "type": "Boss", "stage": "Oceano"},
	"BossEmperor": {"desc": "Imperador da arena. Combate honrado e brutal.", "color": Color(0.8, 0.6, 0.1), "type": "Boss", "stage": "Arena"},
	"BossSingularity": {"desc": "Buraco negro vivo. Gravidade extrema que puxa tudo.", "color": Color(0.4, 0.0, 0.6), "type": "Boss", "stage": "Espaco"},
	"BossDracula": {"desc": "Vampiro milenar. Drena vida sem parar.", "color": Color(0.5, 0.0, 0.1), "type": "Boss", "stage": "Castelo"},
	"BossSugarKing": {"desc": "Rei dos doces. Doce por fora, mortal por dentro.", "color": Color(1.0, 0.5, 0.7), "type": "Boss", "stage": "Candy"},
}

# Type colors for badges
var type_colors: Dictionary = {
	"Generico": Color(0.5, 0.7, 0.5),
	"Variante": Color(0.6, 0.7, 0.9),
	"Especial": Color(0.9, 0.6, 0.3),
	"Raro": Color(0.9, 0.7, 1.0),
	"Boss": Color(1.0, 0.3, 0.3),
}

var grid: GridContainer
var info_label: Label
var back_btn: Button
var scroll: ScrollContainer
var detail_panel: PanelContainer
var detail_portrait: SubViewportContainer
var detail_name: Label
var detail_type: Label
var detail_stage: Label
var detail_kills: Label
var detail_desc: Label
var detail_viewport: SubViewport
var detail_model_root: Node3D
var current_model: Node3D = null
var count_label: Label

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_populate_grid()
	GamepadUI.notify_menu_opened()

func _build_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left = 24
	main_vbox.offset_right = -24
	main_vbox.offset_top = 16
	main_vbox.offset_bottom = -16
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# Title bar
	var title_bar = HBoxContainer.new()
	title_bar.add_theme_constant_override("separation", 12)
	main_vbox.add_child(title_bar)

	var title = Label.new()
	title.text = "Bestiario"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(title)

	# Counter
	count_label = Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_font_size_override("font_size", 16)
	count_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	title_bar.add_child(count_label)

	# Conteudo: grid a esquerda + detalhe a direita
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 16)
	main_vbox.add_child(content_hbox)

	# --- Lado esquerdo: scroll com grid ---
	scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(scroll)

	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)

	# --- Lado direito: painel de detalhe ---
	detail_panel = PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(280, 0)
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var dp_style = StyleBoxFlat.new()
	dp_style.bg_color = Color(0.1, 0.1, 0.16)
	dp_style.set_corner_radius_all(8)
	dp_style.set_border_width_all(2)
	dp_style.border_color = Color(0.3, 0.3, 0.4)
	detail_panel.add_theme_stylebox_override("panel", dp_style)
	content_hbox.add_child(detail_panel)

	var dp_margin = MarginContainer.new()
	dp_margin.add_theme_constant_override("margin_left", 16)
	dp_margin.add_theme_constant_override("margin_right", 16)
	dp_margin.add_theme_constant_override("margin_top", 16)
	dp_margin.add_theme_constant_override("margin_bottom", 16)
	detail_panel.add_child(dp_margin)

	var dp_vbox = VBoxContainer.new()
	dp_vbox.add_theme_constant_override("separation", 10)
	dp_margin.add_child(dp_vbox)

	# Instrucao inicial
	var hint = Label.new()
	hint.text = "Clique num inimigo\npara ver detalhes."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.name = "Hint"
	dp_vbox.add_child(hint)

	# Portrait (SubViewport para modelo 3D do inimigo)
	var svc = SubViewportContainer.new()
	svc.custom_minimum_size = Vector2(240, 180)
	svc.stretch = true
	svc.visible = false
	svc.name = "DetailPortrait"
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dp_vbox.add_child(svc)
	detail_portrait = svc

	detail_viewport = SubViewport.new()
	detail_viewport.size = Vector2(240, 180)
	detail_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(detail_viewport)

	detail_model_root = Node3D.new()
	detail_viewport.add_child(detail_model_root)

	# Camera para visualizar o modelo
	var cam = Camera3D.new()
	cam.position = Vector3(0, 1.2, 2.5)
	cam.look_at(Vector3(0, 0.8, 0), Vector3.UP)
	detail_viewport.add_child(cam)
	cam.current = true

	# Luz ambiente
	var ambient = WorldEnvironment.new()
	var env = Environment.new()
	ambient.environment = env
	detail_viewport.add_child(ambient)

	# Luz direcional
	var light = DirectionalLight3D.new()
	light.position = Vector3(2, 3, 2)
	light.look_at(Vector3(0, 0, 0), Vector3.UP)
	light.light_energy = 1.5
	detail_viewport.add_child(light)

	detail_name = Label.new()
	detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_name.add_theme_font_size_override("font_size", 20)
	detail_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	detail_name.visible = false
	dp_vbox.add_child(detail_name)

	detail_type = Label.new()
	detail_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_type.add_theme_font_size_override("font_size", 13)
	detail_type.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	detail_type.visible = false
	dp_vbox.add_child(detail_type)

	detail_stage = Label.new()
	detail_stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_stage.add_theme_font_size_override("font_size", 12)
	detail_stage.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
	detail_stage.visible = false
	dp_vbox.add_child(detail_stage)

	detail_kills = Label.new()
	detail_kills.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_kills.add_theme_font_size_override("font_size", 14)
	detail_kills.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4))
	detail_kills.visible = false
	dp_vbox.add_child(detail_kills)

	detail_desc = Label.new()
	detail_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_desc.add_theme_font_size_override("font_size", 13)
	detail_desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc.visible = false
	dp_vbox.add_child(detail_desc)

	# Back button
	back_btn = Button.new()
	back_btn.text = "Voltar"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(_on_back)
	back_btn.focus_mode = Control.FOCUS_ALL
	main_vbox.add_child(back_btn)

func _populate_grid() -> void:
	var bestiary = SaveManager.get_bestiary()
	count_label.text = "%d monstros" % enemy_data.size()

	for enemy_name in enemy_data:
		var data = enemy_data[enemy_name]
		var kills = _get_enemy_kills(enemy_name, bestiary)

		var card_btn = Button.new()
		card_btn.custom_minimum_size = CARD_SIZE
		card_btn.focus_mode = Control.FOCUS_ALL
		card_btn.mouse_filter = Control.MOUSE_FILTER_STOP

		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.12, 0.12, 0.18)
		card_style.set_corner_radius_all(6)
		card_style.set_border_width_all(2)
		card_style.border_color = data["color"]
		card_btn.add_theme_stylebox_override("normal", card_style)

		var hover_style = card_style.duplicate()
		hover_style.bg_color = card_style.bg_color.lightened(0.15)
		hover_style.border_color = data["color"].lightened(0.3)
		card_btn.add_theme_stylebox_override("hover", hover_style)
		card_btn.add_theme_stylebox_override("pressed", hover_style)

		# Focus style (gamepad navigation)
		var focus_style = hover_style.duplicate()
		focus_style.border_color = Color(1.0, 0.85, 0.2)
		focus_style.set_border_width_all(3)
		card_btn.add_theme_stylebox_override("focus", focus_style)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 3)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_btn.add_child(vbox)

		# Color swatch
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(0, 5)
		swatch.color = data["color"]
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(swatch)

		# Name
		var name_lbl = Label.new()
		name_lbl.text = _display_name(enemy_name)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(name_lbl)

		# Type badge
		var type_lbl = Label.new()
		type_lbl.text = data["type"]
		type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_lbl.add_theme_font_size_override("font_size", 10)
		type_lbl.add_theme_color_override("font_color", type_colors.get(data["type"], data["color"]))
		type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(type_lbl)

		# Kills
		var kills_lbl = Label.new()
		kills_lbl.text = "Kills: %d" % kills if kills > 0 else ""
		kills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kills_lbl.add_theme_font_size_override("font_size", 11)
		kills_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		kills_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(kills_lbl)

		# Clique: exibe detalhes no painel direito
		card_btn.pressed.connect(_show_enemy_details.bind(enemy_name, data, kills))

		grid.add_child(card_btn)

func _display_name(enemy_name: String) -> String:
	# Formata nomes compostos para exibicao mais bonita
	match enemy_name:
		"ZombieRunner": return "Zombie Runner"
		"SlimeBig": return "Slime Big"
		"GhostWhite": return "Ghost White"
		"GhostGreen": return "Ghost Green"
		"GhostBlue": return "Ghost Blue"
		"GhostRed": return "Ghost Red"
		"SkeletonArcher": return "Skeleton Archer"
		"ToothFairy": return "Tooth Fairy"
		"BossNecromancer": return "Necromancer"
		"BossFairyQueen": return "Fairy Queen"
		"BossAlienCow": return "Alien Cow"
		"BossAIOverlord": return "AI Overlord"
		"BossDemonLord": return "Demon Lord"
		"BossLeviathan": return "Leviathan"
		"BossEmperor": return "Emperor"
		"BossSingularity": return "Singularity"
		"BossDracula": return "Dracula"
		"BossSugarKing": return "Sugar King"
		_: return enemy_name

func _show_enemy_details(enemy_name: String, data: Dictionary, kills: int) -> void:
	AudioManager.play_sfx("menu_click")

	# Esconde hint se existir
	for child in detail_panel.get_children():
		if child.name == "MarginContainer":
			for mc in child.get_children():
				if mc.name == "VBoxContainer":
					var hint = mc.get_node_or_null("Hint")
					if hint:
						hint.visible = false

	# Atualiza portrait
	detail_portrait.visible = true

	# Carrega modelo 3D
	_load_enemy_model(enemy_name)

	detail_name.text = _display_name(enemy_name)
	detail_name.add_theme_color_override("font_color", data["color"].lightened(0.2))
	detail_type.text = data["type"]
	detail_type.add_theme_color_override("font_color", type_colors.get(data["type"], data["color"]))
	detail_stage.text = "Fase: %s" % data.get("stage", "Todas")
	detail_kills.text = "Kills: %d" % kills
	detail_desc.text = data["desc"]

	detail_name.visible = true
	detail_type.visible = true
	detail_stage.visible = true
	detail_kills.visible = true
	detail_desc.visible = true

func _load_enemy_model(enemy_name: String) -> void:
	# Remove modelo anterior
	if current_model:
		current_model.queue_free()
		current_model = null

	# Procura pelo modelo do inimigo
	if enemy_name not in enemy_models:
		return

	var model_path = enemy_models[enemy_name]
	if not ResourceLoader.exists(model_path):
		return

	var scene = load(model_path)
	if scene:
		current_model = scene.instantiate()
		detail_model_root.add_child(current_model)

		# Rotaciona o modelo para visualizacao melhor
		if current_model is Node3D:
			current_model.rotation.y = 0.5
			current_model.scale = Vector3.ONE * 1.2

func _get_enemy_kills(enemy_name: String, bestiary: Dictionary) -> int:
	if enemy_name in bestiary:
		return bestiary[enemy_name].get("kills", 0)
	return 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_viewport(): get_viewport().set_input_as_handled()
		_on_back()

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")
