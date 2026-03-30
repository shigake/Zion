extends Control

## Bestiario — catalogo de todos os monstros do jogo.
## Auto-popula inimigos tematicos lendo STAGE_ENEMY_SPRITES de enemy_base.gd.
## Sempre que um novo inimigo for adicionado em enemy_base, aparece aqui automaticamente.

const COLUMNS := 4
const CARD_SIZE := Vector2(155, 115)

# Referencia ao script base de inimigos para ler dados tematicos
const EnemyBase = preload("res://scripts/enemies/enemy_base.gd")

# Cores por fenda (usadas nos cards e filtros)
const STAGE_COLORS := {
	"cemetery": Color(0.4, 0.5, 0.3),
	"forest": Color(0.2, 0.7, 0.3),
	"farm": Color(0.7, 0.6, 0.3),
	"tokyo": Color(0.0, 0.7, 0.9),
	"volcano": Color(0.9, 0.3, 0.1),
	"ocean": Color(0.1, 0.4, 0.8),
	"arena": Color(0.8, 0.6, 0.1),
	"space": Color(0.5, 0.2, 0.7),
	"castle": Color(0.6, 0.1, 0.2),
	"candy": Color(1.0, 0.5, 0.7),
}

# Nomes de exibicao das fendas
const STAGE_DISPLAY_NAMES := {
	"all": "Todos",
	"cemetery": "Cemiterio",
	"forest": "Floresta",
	"farm": "Fazenda",
	"tokyo": "Tokyo",
	"volcano": "Vulcao",
	"ocean": "Oceano",
	"arena": "Arena",
	"space": "Espaco",
	"castle": "Castelo",
	"candy": "Candy",
	"generic": "Genericos",
	"boss": "Sentinelas",
}

# Boss por fenda
const BOSS_DATA := {
	"BossNecromancer": {"stage": "cemetery", "desc": "Sentinela do cemiterio. Invoca mortos e drena vida."},
	"BossFairyQueen": {"stage": "forest", "desc": "Sentinela da floresta. Magias de natureza devastadoras."},
	"BossAlienCow": {"stage": "farm", "desc": "Sentinela da fazenda. Abduz inimigos com tecnologia alienigena."},
	"BossAIOverlord": {"stage": "tokyo", "desc": "Sentinela de Tokyo. Lasers e drones autonomos."},
	"BossDemonLord": {"stage": "volcano", "desc": "Sentinela do vulcao. Fogo infernal sem piedade."},
	"BossLeviathan": {"stage": "ocean", "desc": "Sentinela do oceano. Monstro marinho ancestral."},
	"BossEmperor": {"stage": "arena", "desc": "Sentinela da arena. Combate honrado e brutal."},
	"BossSingularity": {"stage": "space", "desc": "Sentinela do espaco. Gravidade extrema que puxa tudo."},
	"BossDracula": {"stage": "castle", "desc": "Sentinela do castelo. Vampiro milenar, drena vida."},
	"BossSugarKing": {"stage": "candy", "desc": "Sentinela de Candy. Doce por fora, mortal por dentro."},
}

# Genericos base (aparecem em todas as fendas)
const GENERIC_DATA := {
	"Slime": {"desc": "Basico e lento. Nao subestime em grupo.", "color": Color(0.2, 0.8, 0.2)},
	"Bat": {"desc": "Rapido e irritante. Mira ruim.", "color": Color(0.5, 0.3, 0.6)},
	"Skeleton": {"desc": "Guerreiro de ossos. Resiste a morte.", "color": Color(0.9, 0.9, 0.8)},
	"ZombieRunner": {"desc": "Corre mais rapido que parece. Cuidado.", "color": Color(0.4, 0.6, 0.3)},
	"Ghost": {"desc": "Fantasma transparente. Atravessa tudo.", "color": Color(0.6, 0.7, 0.9)},
	"SlimeBig": {"desc": "Versao gigante do slime. Tanque lento.", "color": Color(0.1, 0.6, 0.1)},
	"SkeletonArcher": {"desc": "Atira flechas de longe. Priorize.", "color": Color(0.8, 0.7, 0.6)},
	"Bomber": {"desc": "Explode perto de voce. Mantenha distancia.", "color": Color(0.9, 0.4, 0.1)},
	"Tank": {"desc": "Lento mas quase indestrutivel.", "color": Color(0.5, 0.5, 0.5)},
	"Swarm": {"desc": "Enxame de criaturas. Muitos, mas frageis.", "color": Color(0.7, 0.7, 0.2)},
	"Mimic": {"desc": "Parece um bau. Nao e um bau.", "color": Color(0.8, 0.6, 0.2)},
	"ToothFairy": {"desc": "Rara e traicoeira. 3% de chance apos minuto 5.", "color": Color(0.9, 0.7, 1.0)},
}

# Descricoes para inimigos tematicos (geradas automaticamente se nao existir aqui)
const THEMED_DESCRIPTIONS := {
	# Cemetery
	"cemetery_zombie": "Morto-vivo que rasteja do solo do cemiterio.",
	"cemetery_wraith": "Espectro rapido que flutua entre as lapides.",
	"cemetery_reaper": "Ceifador sombrio. Golpes de foice letais.",
	"cemetery_hand": "Mao cadaverica que emerge do chao.",
	"cemetery_banshee": "Espectro que grita e teleporta. Ensurdecedor.",
	"cemetery_ghoul": "Devorador de carne. Grande e faminto.",
	"cemetery_bone_knight": "Cavaleiro de ossos. Carrega como um touro.",
	"cemetery_gravedigger": "Coveiro explosivo. Joga dinamite.",
	"cemetery_rat_swarm": "Enxame de ratos de catacumba.",
	# Forest
	"forest_mushroom": "Cogumelo venenoso que libera esporos.",
	"forest_spider": "Aranha saltadora que tece teias.",
	"forest_treant": "Arvore corrompida. Embosca quem passa.",
	"forest_wolf": "Lobo furioso da floresta profunda.",
	"forest_wisp": "Fogo-fatuo que flutua e engana viajantes.",
	"forest_bear": "Urso gigante. Carga devastadora.",
	"forest_vine": "Trepadeira senciente. Agarra e esmaga.",
	"forest_owl": "Coruja explosiva. Mergulha em silencio.",
	"forest_fairy": "Enxame de fadas corrompidas.",
	# Farm
	"farm_chicken": "Galinha endemoniada. Bica com furia.",
	"farm_crow": "Corvo macabro que ataca em rasante.",
	"farm_scarecrow": "Espantalho vivo. Gera criaturas ao morrer.",
	"farm_pig": "Porco mutante. Rapido e pesado.",
	"farm_worm": "Minhoca gigante que surge do solo.",
	"farm_bull": "Touro furioso. Nao de as costas.",
	"farm_goat": "Bode explosivo. Cabeceada kamikaze.",
	"farm_rat": "Rato de celeiro. Explosivo ao morrer.",
	"farm_bee_swarm": "Enxame de abelhas africanas furiosas.",
	"farm_phantom_horse": "Cavalo fantasma. Carrega em alta velocidade.",
	"farm_dynamite_goat": "Bode com dinamite. Autodestruitivo.",
	# Tokyo
	"tokyo_robot": "Robo de seguranca. Resistente e forte.",
	"tokyo_drone": "Drone de ataque. Dispara a distancia.",
	"tokyo_hacker": "Hacker holografico. Ataques digitais.",
	"tokyo_mecha": "Mecha corrompido. Rapido e brutal.",
	"tokyo_hologram": "Holograma instavel. Fica invisivel.",
	"tokyo_cyborg": "Ciborgue pesado. Tanque de metal.",
	"tokyo_turret": "Torreta automatica. Atira sem parar.",
	"tokyo_virus": "Virus digital. Explode em pixels.",
	"tokyo_yakuza": "Yakuza digital. Ataque em grupo.",
	"tokyo_kamikaze_drone": "Drone kamikaze. Explode no impacto.",
	# Volcano
	"volcano_magma_slime": "Slime de magma. Deixa rastro de fogo.",
	"volcano_fire_bat": "Morcego de fogo. Rapido e ardente.",
	"volcano_golem": "Golem de lava. Explode ao morrer.",
	"volcano_hellhound": "Cao infernal. Corre como o vento.",
	"volcano_ash_ghost": "Fantasma de cinzas vulcanicas.",
	"volcano_lava_snake": "Serpente de lava. Tanque escorregadio.",
	"volcano_obsidian_golem": "Golem de obsidiana. Embosca sorrateiramente.",
	"volcano_phoenix": "Fenix explosiva. Mergulha em chamas.",
	"volcano_imp": "Diabrete travesso. Rapido e fraco.",
	"volcano_ash_wraith": "Espectro de cinzas. Teleporta entre chamas.",
	"volcano_obsidian_titan": "Tita de obsidiana. Embosca com furia.",
	# Ocean
	"ocean_crab": "Caranguejo gigante. Pincas afiadas.",
	"ocean_squid": "Lula rapida. Jatos de tinta.",
	"ocean_fish": "Peixe profundo. Ataque de mordida.",
	"ocean_urchin": "Ourico marinho. Espinhos venenosos.",
	"ocean_seahorse": "Cavalo marinho etereo. Fantasmagorico.",
	"ocean_pufferfish": "Baiacu toxico. Explode ao morrer.",
	"ocean_shark": "Tubarao imparavel. Quase indestrutivel.",
	"ocean_octopus": "Polvo de profundidade. Tentaculos explosivos.",
	"ocean_eel": "Enxame de enguias eletricas.",
	"ocean_piranha_swarm": "Piranhas em emboscada voraz.",
	# Arena
	"arena_gladiator": "Gladiador basico. Espada e escudo.",
	"arena_eagle": "Aguia imperial. Ataca do alto.",
	"arena_centurion": "Centuriao veterano. Lider tatico.",
	"arena_chariot": "Biga romana. Atropela tudo.",
	"arena_prisoner": "Prisioneiro desesperado. Imprevisivel.",
	"arena_tiger": "Tigre da arena. Felino mortal.",
	"arena_net_fighter": "Lutador com rede. Prende e golpeia.",
	"arena_archer": "Arqueiro romano. Flechas explosivas.",
	"arena_lion": "Leao da arena. Carga furiosa.",
	"arena_phantom_champion": "Campeao fantasma. Fica invisivel e dobra dano.",
	"arena_war_elephant": "Elefante de guerra. Carga devastadora.",
	# Space
	"space_alien": "Alienigena basico. Tecnologia desconhecida.",
	"space_drone_enemy": "Drone espacial. Patrulha e dispara.",
	"space_xenomorph": "Xenomorfo. Invisivel e dano dobrado.",
	"space_parasite": "Parasita estelar. Rapido e voraz.",
	"space_crystal": "Cristal vivo. Etereo e misterioso.",
	"space_tentacle": "Tentaculo cosmico. Tanque alienigena.",
	"space_sentinel": "Sentinela mecanico. Quase indestrutivel.",
	"space_robot": "Robo espacial. Explosivo ao morrer.",
	"space_worm": "Verme estelar. Enxame voraz.",
	"space_void_specter": "Espectro do vazio. Teleporta entre dimensoes.",
	"space_mine_layer": "Minador espacial. Dispara minas a distancia.",
	# Castle
	"castle_vampire": "Vampiro menor. Drena vida.",
	"castle_gargoyle": "Gargula voadora. Mergulha das torres.",
	"castle_knight": "Cavaleiro maldito. Espada sombria.",
	"castle_werewolf": "Lobisomem do castelo. Rapido e brutal.",
	"castle_ghost_maid": "Empregada fantasma. Assombra os corredores.",
	"castle_cursed_armor": "Armadura amaldicoada. Tanque sombrio.",
	"castle_skeleton_mage": "Mago esqueleto. Magia de ossos.",
	"castle_rat_king": "Rei dos ratos. Explosivo e nojento.",
	"castle_bat_swarm": "Enxame de morcegos vampiricos.",
	"castle_poltergeist": "Poltergeist. Objetos voadores mortais.",
	"castle_iron_golem": "Golem de ferro. Embosca nos corredores.",
	# Candy
	"candy_gummy": "Urso de goma. Se divide ao morrer.",
	"candy_cupcake": "Cupcake assassino. Cobertura venenosa.",
	"candy_jawbreaker": "Jawbreaker duro. Resistente como pedra.",
	"candy_licorice": "Alcacuz chicoteador. Rapido e flexivel.",
	"candy_cotton_candy_ghost": "Fantasma de algodao doce. Flutua e assombra.",
	"candy_chocolate_golem": "Golem de chocolate. Tanque derretido.",
	"candy_cake_mimic": "Bolo mimico. Parece inofensivo.",
	"candy_ice_cream_cone": "Sorvete explosivo. Granulado mortal.",
	"candy_sour_worm": "Enxame de minhocas azedas.",
	"candy_cotton_ghost": "Fantasma de algodao. Voa e persegue.",
	"candy_popcorn_bomber": "Pipoca explosiva. Estoura no impacto.",
}

# Type colors for badges
var type_colors: Dictionary = {
	"Generico": Color(0.5, 0.7, 0.5),
	"Tematico": Color(0.3, 0.7, 0.8),
	"Especial": Color(0.9, 0.6, 0.3),
	"Raro": Color(0.9, 0.7, 1.0),
	"Sentinela": Color(1.0, 0.3, 0.3),
}

# UI refs
var grid: GridContainer
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
var detail_sprite: TextureRect = null
var current_model: Node3D = null
var count_label: Label
var filter_container: HBoxContainer
var filter_buttons: Dictionary = {}

# Data gerada dinamicamente
var all_entries: Array[Dictionary] = []
var current_filter: String = "all"

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_all_entries()
	_build_ui()
	_populate_grid()
	GamepadUI.notify_menu_opened()

## Constroi a lista completa de entradas a partir dos dados de enemy_base.gd
func _build_all_entries() -> void:
	all_entries.clear()

	# 1) Inimigos tematicos por fenda (lidos de enemy_base.gd)
	var stage_sprites: Dictionary = EnemyBase.STAGE_ENEMY_SPRITES
	for stage_name in stage_sprites:
		var mapping: Dictionary = stage_sprites[stage_name]
		var seen_themed := {}  # Evita duplicatas no mesmo stage
		for _generic_key in mapping:
			var themed_name: String = mapping[_generic_key]
			if themed_name in seen_themed:
				continue
			seen_themed[themed_name] = true

			var display = _themed_display_name(themed_name)
			var desc = THEMED_DESCRIPTIONS.get(themed_name, "Criatura corrompida da fenda.")
			var color = STAGE_COLORS.get(stage_name, Color(0.5, 0.5, 0.5))
			all_entries.append({
				"id": themed_name,
				"name": display,
				"desc": desc,
				"color": color,
				"type": "Tematico",
				"stage": stage_name,
				"stage_display": STAGE_DISPLAY_NAMES.get(stage_name, stage_name.capitalize()),
			})

	# 2) Genericos
	for gen_name in GENERIC_DATA:
		var data = GENERIC_DATA[gen_name]
		all_entries.append({
			"id": gen_name,
			"name": _generic_display_name(gen_name),
			"desc": data["desc"],
			"color": data["color"],
			"type": "Generico" if gen_name not in ["SkeletonArcher", "Bomber", "Tank", "Swarm", "Mimic"] else "Especial",
			"stage": "generic",
			"stage_display": "Todas as fendas",
		})
		# Override: ToothFairy e raro
		if gen_name == "ToothFairy":
			all_entries[-1]["type"] = "Raro"

	# 3) Bosses (Sentinelas)
	for boss_name in BOSS_DATA:
		var data = BOSS_DATA[boss_name]
		all_entries.append({
			"id": boss_name,
			"name": _boss_display_name(boss_name),
			"desc": data["desc"],
			"color": STAGE_COLORS.get(data["stage"], Color(0.8, 0.2, 0.2)),
			"type": "Sentinela",
			"stage": data["stage"],
			"stage_display": STAGE_DISPLAY_NAMES.get(data["stage"], data["stage"].capitalize()),
		})

	# Ordena: por fenda, depois por tipo
	var stage_order = ["cemetery", "forest", "farm", "tokyo", "volcano", "ocean", "arena", "space", "castle", "candy", "generic"]
	var type_order = {"Tematico": 0, "Generico": 1, "Especial": 2, "Raro": 3, "Sentinela": 4}
	all_entries.sort_custom(func(a, b):
		var sa = stage_order.find(a["stage"])
		var sb = stage_order.find(b["stage"])
		if sa != sb: return sa < sb
		var ta = type_order.get(a["type"], 5)
		var tb = type_order.get(b["type"], 5)
		return ta < tb
	)

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
	main_vbox.add_theme_constant_override("separation", 8)
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

	count_label = Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_font_size_override("font_size", 16)
	count_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	title_bar.add_child(count_label)

	# Filter bar (tabs por fenda)
	var filter_scroll = ScrollContainer.new()
	filter_scroll.custom_minimum_size = Vector2(0, 38)
	filter_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(filter_scroll)

	filter_container = HBoxContainer.new()
	filter_container.add_theme_constant_override("separation", 4)
	filter_scroll.add_child(filter_container)

	var filter_order = ["all", "cemetery", "forest", "farm", "tokyo", "volcano", "ocean", "arena", "space", "castle", "candy", "generic", "boss"]
	for filter_key in filter_order:
		var btn = Button.new()
		btn.text = STAGE_DISPLAY_NAMES.get(filter_key, filter_key.capitalize())
		btn.custom_minimum_size = Vector2(80, 30)
		btn.focus_mode = Control.FOCUS_ALL

		var btn_style = StyleBoxFlat.new()
		btn_style.set_corner_radius_all(4)
		btn_style.set_content_margin_all(4)
		if filter_key == "all":
			btn_style.bg_color = Color(0.3, 0.3, 0.4)
		else:
			btn_style.bg_color = Color(0.15, 0.15, 0.22)
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_font_size_override("font_size", 12)

		var hover_style = btn_style.duplicate()
		hover_style.bg_color = btn_style.bg_color.lightened(0.15)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", hover_style)

		if filter_key != "all" and filter_key != "generic" and filter_key != "boss":
			var color = STAGE_COLORS.get(filter_key, Color.WHITE)
			btn.add_theme_color_override("font_color", color.lightened(0.3))

		btn.pressed.connect(_on_filter.bind(filter_key))
		filter_container.add_child(btn)
		filter_buttons[filter_key] = btn

	# Conteudo: grid + detalhe
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 16)
	main_vbox.add_child(content_hbox)

	scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(scroll)

	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)

	# Painel de detalhe
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

	var hint = Label.new()
	hint.text = "Selecione um inimigo\npara ver detalhes."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.name = "Hint"
	dp_vbox.add_child(hint)

	# Portrait (SubViewport)
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

	var cam = Camera3D.new()
	cam.position = Vector3(0, 1.2, 2.5)
	detail_viewport.add_child(cam)
	cam.look_at(Vector3(0, 0.8, 0), Vector3.UP)
	cam.current = true

	var ambient = WorldEnvironment.new()
	var env = Environment.new()
	ambient.environment = env
	detail_viewport.add_child(ambient)

	var light = DirectionalLight3D.new()
	light.position = Vector3(2, 3, 2)
	light.light_energy = 1.5
	detail_viewport.add_child(light)
	light.look_at(Vector3(0, 0, 0), Vector3.UP)

	# Sprite fallback (usado quando nao ha modelo 3D)
	detail_sprite = TextureRect.new()
	detail_sprite.custom_minimum_size = Vector2(240, 180)
	detail_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	detail_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail_sprite.visible = false
	detail_sprite.name = "DetailSprite"
	detail_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dp_vbox.add_child(detail_sprite)

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

	# Back
	back_btn = Button.new()
	back_btn.text = "Voltar"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(_on_back)
	back_btn.focus_mode = Control.FOCUS_ALL
	main_vbox.add_child(back_btn)

func _on_filter(filter_key: String) -> void:
	AudioManager.play_sfx("menu_click")
	current_filter = filter_key
	_update_filter_visuals()
	_populate_grid()

func _update_filter_visuals() -> void:
	for key in filter_buttons:
		var btn: Button = filter_buttons[key]
		var style = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		if key == current_filter:
			style.bg_color = Color(0.3, 0.3, 0.4)
			style.set_border_width_all(1)
			style.border_color = Color(1.0, 0.85, 0.2, 0.6)
		else:
			style.bg_color = Color(0.15, 0.15, 0.22)
			style.set_border_width_all(0)
		btn.add_theme_stylebox_override("normal", style)

func _get_filtered_entries() -> Array[Dictionary]:
	if current_filter == "all":
		return all_entries
	if current_filter == "boss":
		return all_entries.filter(func(e): return e["type"] == "Sentinela")
	if current_filter == "generic":
		return all_entries.filter(func(e): return e["stage"] == "generic")
	return all_entries.filter(func(e): return e["stage"] == current_filter)

func _populate_grid() -> void:
	# Limpa grid
	for child in grid.get_children():
		child.queue_free()

	var entries = _get_filtered_entries()
	var bestiary = SaveManager.get_bestiary()
	count_label.text = "%d criaturas" % entries.size()

	for entry in entries:
		var kills = _get_enemy_kills(entry["id"], bestiary)

		var card_btn = UICardBuilder.create_card(CARD_SIZE, entry["color"])
		var vbox = UICardBuilder.create_card_vbox(card_btn)

		UICardBuilder.add_color_swatch(vbox, entry["color"])
		var name_lbl = UICardBuilder.add_label(vbox, entry["name"], 12, Color(1.0, 0.95, 0.8))
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UICardBuilder.add_label(vbox, entry["type"], 10, type_colors.get(entry["type"], entry["color"]))
		UICardBuilder.add_label(vbox, "Kills: %d" % kills if kills > 0 else "", 11, Color(0.6, 0.6, 0.6))

		card_btn.pressed.connect(_show_enemy_details.bind(entry, kills))
		grid.add_child(card_btn)

func _show_enemy_details(entry: Dictionary, kills: int) -> void:
	AudioManager.play_sfx("menu_click")

	# Esconde hint
	var dp_margin = detail_panel.get_child(0)
	if dp_margin:
		var dp_vbox = dp_margin.get_child(0) if dp_margin.get_child_count() > 0 else null
		if dp_vbox:
			var hint = dp_vbox.get_node_or_null("Hint")
			if hint:
				hint.visible = false

	_load_enemy_model(entry["id"])

	detail_name.text = entry["name"]
	detail_name.add_theme_color_override("font_color", entry["color"].lightened(0.2))
	detail_type.text = entry["type"]
	detail_type.add_theme_color_override("font_color", type_colors.get(entry["type"], entry["color"]))
	detail_stage.text = "Fenda: %s" % entry["stage_display"]
	detail_kills.text = "Kills: %d" % kills
	detail_desc.text = entry["desc"]

	detail_name.visible = true
	detail_type.visible = true
	detail_stage.visible = true
	detail_kills.visible = true
	detail_desc.visible = true

func _load_enemy_model(enemy_id: String) -> void:
	if current_model:
		current_model.queue_free()
		current_model = null
	detail_sprite.visible = false
	detail_portrait.visible = false

	# 1) Tenta carregar sprite 2D (cobre a maioria dos monstros)
	var sprite_path := _resolve_sprite_path(enemy_id)
	if sprite_path != "":
		var tex = load(sprite_path) as Texture2D
		if tex:
			detail_sprite.texture = tex
			detail_sprite.visible = true
			return

	# 2) Fallback: modelo 3D (.glb)
	var model_paths := [
		"res://assets/models/enemies/%s.glb" % enemy_id,
		"res://assets/models/bosses/%s.glb" % enemy_id,
		"res://assets/models/enemies/%s.glb" % enemy_id.to_lower(),
		"res://assets/models/bosses/%s.glb" % enemy_id.to_lower(),
	]
	for path in model_paths:
		if ResourceLoader.exists(path):
			var scene = load(path)
			if scene:
				current_model = scene.instantiate()
				detail_model_root.add_child(current_model)
				if current_model is Node3D:
					current_model.rotation.y = 0.5
					current_model.scale = Vector3.ONE * 1.2
				detail_portrait.visible = true
				return

## Resolve o caminho do sprite para qualquer tipo de inimigo
func _resolve_sprite_path(enemy_id: String) -> String:
	# Tematicos: "cemetery_zombie" → res://assets/sprites/enemies/cemetery/cemetery_zombie.png
	var stage_sprites: Dictionary = EnemyBase.STAGE_ENEMY_SPRITES
	for stage_name in stage_sprites:
		var mapping: Dictionary = stage_sprites[stage_name]
		for _key in mapping:
			if mapping[_key] == enemy_id:
				var path = "res://assets/sprites/enemies/%s/%s.png" % [stage_name, enemy_id]
				if ResourceLoader.exists(path):
					return path

	# Bosses: "BossNecromancer" → res://assets/sprites/bosses/boss_necromancer.png
	if enemy_id.begins_with("Boss"):
		var boss_path = "res://assets/sprites/bosses/%s.png" % enemy_id.to_snake_case()
		if ResourceLoader.exists(boss_path):
			return boss_path

	# Genericos: "Slime" → res://assets/sprites/enemies/slime.png
	var generic_snake = enemy_id.to_snake_case()
	var generic_paths := [
		"res://assets/sprites/enemies/%s.png" % generic_snake,
		"res://assets/sprites/enemies/%s.png" % enemy_id.to_lower(),
	]
	for path in generic_paths:
		if ResourceLoader.exists(path):
			return path

	return ""

func _get_enemy_kills(enemy_id: String, bestiary: Dictionary) -> int:
	if enemy_id in bestiary:
		return bestiary[enemy_id].get("kills", 0)
	return 0

## Converte nome tematico snake_case para display: "cemetery_bone_knight" -> "Bone Knight"
func _themed_display_name(themed_name: String) -> String:
	var parts = themed_name.split("_")
	if parts.size() <= 1:
		return themed_name.capitalize()
	# Remove o prefixo do stage (primeira parte)
	parts.remove_at(0)
	var result = ""
	for part in parts:
		if result != "":
			result += " "
		result += part.capitalize()
	return result

func _generic_display_name(gen_name: String) -> String:
	match gen_name:
		"ZombieRunner": return "Zombie Runner"
		"SlimeBig": return "Slime Big"
		"SkeletonArcher": return "Skeleton Archer"
		"ToothFairy": return "Tooth Fairy"
		_: return gen_name

func _boss_display_name(boss_name: String) -> String:
	match boss_name:
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
		_: return boss_name.replace("Boss", "")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_viewport(): get_viewport().set_input_as_handled()
		_on_back()

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")
