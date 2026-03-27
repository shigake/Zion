extends Control

## Bestiario — catalogo de inimigos encontrados pelo jogador.
## Ao clicar num card, exibe detalhes e visual do inimigo no painel direito.

const COLUMNS := 3
const CARD_SIZE := Vector2(180, 110)

# Mapping de nomes de inimigos para caminhos de modelos 3D
var enemy_models: Dictionary = {
	"Slime": "res://assets/models/enemies/slime.glb",
	"Bat": "res://assets/models/enemies/bat.glb",
	"Skeleton": "res://assets/models/enemies/skeleton.glb",
	"ZombieRunner": "res://assets/models/enemies/zombie.glb",
	"Ghost": "res://assets/models/enemies/ghost.glb",
	"SlimeBig": "res://assets/models/enemies/slime_big.glb",
	"SkeletonArcher": "res://assets/models/enemies/skeleton_archer.glb",
	"Bomber": "res://assets/models/enemies/bomber.glb",
	"Tank": "res://assets/models/enemies/tank.glb",
	"Swarm": "res://assets/models/enemies/swarm.glb",
	"Mimic": "res://assets/models/enemies/mimic.glb",
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

# All known enemies with descriptions
var enemy_data: Dictionary = {
	# Generic enemies
	"Slime": {"desc": "Basico e lento. Nao subestime em grupo.", "color": Color(0.2, 0.8, 0.2), "type": "Generico"},
	"Bat": {"desc": "Rapido e irritante. Mira ruim.", "color": Color(0.5, 0.3, 0.6), "type": "Generico"},
	"Skeleton": {"desc": "Guerreiro de ossos. Resiste a morte.", "color": Color(0.9, 0.9, 0.8), "type": "Generico"},
	"ZombieRunner": {"desc": "Corre mais rapido que parece. Cuidado.", "color": Color(0.4, 0.6, 0.3), "type": "Generico"},
	"Ghost": {"desc": "Fantasma transparente. Atravessa tudo.", "color": Color(0.6, 0.7, 0.9), "type": "Generico"},
	"SlimeBig": {"desc": "Versao gigante do slime. Tanque lento.", "color": Color(0.1, 0.6, 0.1), "type": "Generico"},
	"SkeletonArcher": {"desc": "Atira flechas de longe. Priorize.", "color": Color(0.8, 0.7, 0.6), "type": "Especial"},
	"Bomber": {"desc": "Explode perto de voce. Mantenha distancia.", "color": Color(0.9, 0.4, 0.1), "type": "Especial"},
	"Tank": {"desc": "Lento mas quase indestrutivel.", "color": Color(0.5, 0.5, 0.5), "type": "Especial"},
	"Swarm": {"desc": "Enxame de criaturas. Muitos, mas frageis.", "color": Color(0.7, 0.7, 0.2), "type": "Especial"},
	"Mimic": {"desc": "Parece um bau. Nao e um bau.", "color": Color(0.8, 0.6, 0.2), "type": "Especial"},
	# Bosses
	"BossNecromancer": {"desc": "Invoca mortos e drena vida. Boss do cemiterio.", "color": Color(0.3, 0.0, 0.5), "type": "Boss"},
	"BossFairyQueen": {"desc": "Rainha das fadas. Magias de natureza.", "color": Color(0.2, 0.8, 0.4), "type": "Boss"},
	"BossAlienCow": {"desc": "Vaca alienigena. Sim, e serio.", "color": Color(0.6, 0.9, 0.6), "type": "Boss"},
	"BossAIOverlord": {"desc": "Inteligencia artificial malvada. Lasers.", "color": Color(0.0, 0.8, 1.0), "type": "Boss"},
	"BossDemonLord": {"desc": "Senhor dos demonios. Fogo infernal.", "color": Color(0.9, 0.1, 0.0), "type": "Boss"},
	"BossLeviathan": {"desc": "Monstro marinho ancestral. Tentaculos.", "color": Color(0.1, 0.3, 0.7), "type": "Boss"},
	"BossEmperor": {"desc": "Imperador da arena. Combate honrado.", "color": Color(0.8, 0.6, 0.1), "type": "Boss"},
	"BossSingularity": {"desc": "Buraco negro vivo. Gravidade extrema.", "color": Color(0.4, 0.0, 0.6), "type": "Boss"},
	"BossDracula": {"desc": "Vampiro milenar. Drena vida sem parar.", "color": Color(0.5, 0.0, 0.1), "type": "Boss"},
	"BossSugarKing": {"desc": "Rei dos doces. Doce por fora, mortal por dentro.", "color": Color(1.0, 0.5, 0.7), "type": "Boss"},
}

var grid: GridContainer
var info_label: Label
var back_btn: Button
var scroll: ScrollContainer
var detail_panel: PanelContainer
var detail_portrait: ColorRect
var detail_name: Label
var detail_type: Label
var detail_kills: Label
var detail_desc: Label
var detail_viewport: SubViewport
var detail_model_root: Node3D
var current_model: Node3D = null

func _ready() -> void:
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

	# Title
	var title = Label.new()
	title.text = "Bestiario"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	main_vbox.add_child(title)

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
	detail_panel.custom_minimum_size = Vector2(260, 0)
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
	svc.custom_minimum_size = Vector2(220, 160)
	svc.stretch = true
	svc.visible = false
	svc.name = "DetailPortrait"
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dp_vbox.add_child(svc)
	detail_portrait = svc

	detail_viewport = SubViewport.new()
	detail_viewport.size = Vector2(220, 160)
	detail_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(detail_viewport)

	detail_model_root = Node3D.new()
	detail_viewport.add_child(detail_model_root)

	# Camera para visualizar o modelo
	var cam = Camera3D.new()
	cam.position = Vector3(0, 1.2, 2.5)
	cam.look_at(Vector3(0, 0.8, 0), Vector3.UP)
	detail_viewport.add_child(cam)
	detail_viewport.cameras.push_front(cam)

	# Luz ambiente
	var ambient = WorldEnvironment.new()
	var env = Environment.new()
	ambient.environment = env
	detail_viewport.add_child(ambient)

	# Luz direcional
	var light = DirectionalLight3D.new()
	light.position = Vector3(2, 3, 2)
	light.look_at(Vector3(0, 0, 0), Vector3.UP)
	light.energy_multiplier = 1.5
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

	for enemy_name in enemy_data:
		var data = enemy_data[enemy_name]
		var is_seen = _is_enemy_seen(enemy_name, bestiary)
		var kills = _get_enemy_kills(enemy_name, bestiary)

		var card_btn = Button.new()
		card_btn.custom_minimum_size = CARD_SIZE
		card_btn.flat = true
		card_btn.focus_mode = Control.FOCUS_ALL
		card_btn.mouse_filter = Control.MOUSE_FILTER_STOP

		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.12, 0.12, 0.18) if is_seen else Color(0.08, 0.08, 0.1)
		card_style.set_corner_radius_all(6)
		card_style.set_border_width_all(2)
		card_style.border_color = data["color"] if is_seen else Color(0.2, 0.2, 0.2)
		card_btn.add_theme_stylebox_override("normal", card_style)

		var hover_style = card_style.duplicate()
		hover_style.bg_color = card_style.bg_color.lightened(0.1)
		hover_style.border_color = data["color"].lightened(0.2) if is_seen else Color(0.35, 0.35, 0.35)
		card_btn.add_theme_stylebox_override("hover", hover_style)
		card_btn.add_theme_stylebox_override("pressed", hover_style)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 3)
		card_btn.add_child(vbox)

		# Color swatch
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(0, 7)
		swatch.color = data["color"] if is_seen else Color(0.3, 0.3, 0.3)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(swatch)

		# Name
		var name_lbl = Label.new()
		name_lbl.text = enemy_name if is_seen else "???"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8) if is_seen else Color(0.4, 0.4, 0.4))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(name_lbl)

		# Type badge
		var type_lbl = Label.new()
		type_lbl.text = data["type"] if is_seen else ""
		type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_lbl.add_theme_font_size_override("font_size", 10)
		type_lbl.add_theme_color_override("font_color", data["color"] if is_seen else Color(0.3, 0.3, 0.3))
		type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(type_lbl)

		# Kills
		var kills_lbl = Label.new()
		kills_lbl.text = "Kills: %d" % kills if is_seen else ""
		kills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kills_lbl.add_theme_font_size_override("font_size", 11)
		kills_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		kills_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(kills_lbl)

		# Clique: exibe detalhes no painel direito
		card_btn.pressed.connect(_show_enemy_details.bind(enemy_name, data, is_seen, kills))

		grid.add_child(card_btn)

func _show_enemy_details(enemy_name: String, data: Dictionary, is_seen: bool, kills: int) -> void:
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

	if is_seen:
		# Carrega modelo 3D
		_load_enemy_model(enemy_name)

		detail_name.text = enemy_name
		detail_name.add_theme_color_override("font_color", data["color"].lightened(0.2))
		detail_type.text = data["type"]
		detail_kills.text = "Kills: %d" % kills
		detail_desc.text = data["desc"]
	else:
		# Remove modelo anterior
		if current_model:
			current_model.queue_free()
			current_model = null

		detail_name.text = "???"
		detail_name.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		detail_type.text = ""
		detail_kills.text = ""
		detail_desc.text = "Encontre este inimigo para desbloquear as informacoes."

	detail_name.visible = true
	detail_type.visible = is_seen
	detail_kills.visible = is_seen
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

		# Rotaciona o modelo para visualização melhor
		if current_model is Node3D:
			current_model.rotation.y = 0.5
			current_model.scale = Vector3.ONE * 1.2

func _is_enemy_seen(enemy_name: String, bestiary: Dictionary) -> bool:
	if enemy_name in bestiary:
		return true
	return false

func _get_enemy_kills(enemy_name: String, bestiary: Dictionary) -> int:
	if enemy_name in bestiary:
		return bestiary[enemy_name].get("kills", 0)
	return 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
