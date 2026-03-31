extends Control

## Tela de creditos: herois dando volta na fogueira em carrossel,
## baloes de fala com frases engraçadas por personagem (um de cada vez).

const CREDITS := [
	"Erick Higaki",
	"Luiz Ihara",
	"Daniel Maruya",
	"Claudio Ant",
]

const EXTRA_CREDITS := [
	["Codigo", "Claude AI + Erick Higaki"],
	["Engine", "Godot 4.6"],
	["Musica", "Suno AI"],
	["Sprites", "Procedurally generated"],
	["Modelos 3D", "Quaternius (CC0), KayKit, Kenney"],
]

const STAR_COLORS := [
	Color(1.0, 0.85, 0.3),   # Amarelo dourado
	Color(0.4, 0.7, 1.0),    # Azul claro
	Color(1.0, 0.4, 0.5),    # Rosa
	Color(0.5, 1.0, 0.6),    # Verde claro
	Color(1.0, 0.6, 0.2),    # Laranja
	Color(0.7, 0.5, 1.0),    # Roxo
	Color(0.3, 0.9, 0.9),    # Ciano
	Color(1.0, 1.0, 1.0),    # Branco
]

## Frases engraçadas por personagem — devem ser curtas e em carater com o heroi
const CHARACTER_QUOTES := {
	"amazona": [
		"Minha lança não erra.\nAs piadas do Ronin é que deixam a desejar.",
		"Filha de Zion não recua.\nSó dá um passo estratégico pra trás.",
		"Atirei o pau no gato...\nNo sentido figurado. Ou não.",
	],
	"bruxa": [
		"Transformei o último inimigo em sapo.\nEle nem reclamou.",
		"Feitiço de amor? Não, obrigada.\nPrefiro feitiço de dano em área.",
		"A lua me dá poderes.\nE insônia. Principalmente insônia.",
	],
	"lealith": [
		"Velocidade é tudo.\nInclusive pra fugir do chef.",
		"Dodge 15%? Na teoria.\nNa prática é 100% estilo.",
		"Passei tão rápido que\nnem me vi passar.",
	],
	"ronin": [
		"Minha espada tem nome.\nNão vou dizer qual. É constrangedor.",
		"Bushido: o caminho do guerreiro.\nHoje o caminho vai ali no armazém.",
		"Silêncio é sabedoria.\nPelo menos é o que digo quando não sei a resposta.",
	],
	"soldado": [
		"TATATATATA!\nOpa. Desculpa. Reflexo.",
		"Protocolo de combate ativo.\nCafé também. Principalmente o café.",
		"Munição infinita seria ótimo.\nAlguém anota pra mim?",
	],
	"mago": [
		"Área de efeito?\nEu chamo de 'zona de respeito'.",
		"Estudei 40 anos de magia pra isso.\nValeu a pena. Acho.",
		"Meu cajado é decorativo.\nO dano não é.",
	],
	"berserker": [
		"O médico mandou relaxar.\nEle não trabalha mais aqui.",
		"Com 30% de HP fico mais forte.\nÉ motivação às avessas.",
		"Raiva? Isso se chama foco.\nIntenso. Muito intenso.",
	],
	"ninja": [
		"Você não me viu chegar?\nPerfeito. Funcionou.",
		"A sombra que te protege.\nOu assusta. Tanto faz.",
		"Invisível não é superpoder,\né modo de vida.",
	],
	"pirata": [
		"Cristais valem mais que ouro.\nNão conta pra ninguém.",
		"Tive um barco. Longa história.\nAlguém tem cristal sobrando?",
		"Mapa do tesouro? Esse aqui.\nGuarda segredo.",
	],
	"engenheiro": [
		"Meu drone faz tudo.\nInclusive me envergonhar em público.",
		"Cooldown 15% menor.\nBurocracia não tem cooldown infelizmente.",
		"Tecnologia resolve tudo.\nExceto esse bug. E aquele outro.",
	],
	"vampiro": [
		"Lifesteal não é vampirismo.\nÉ nutrição alternativa.",
		"Durmo de dia, acordo de noite.\nSou do turno da tarde, ok?",
		"Não mordo ninguém.\nHá décadas. Quase.",
	],
	"gladiador": [
		"Armadura +20%?\nÉ porque combina com os olhos.",
		"No arena, ou você vence ou...\ntambém vence, se for eu.",
		"Escudo não é pra se esconder.\nÉ pra bater na cabeça do inimigo.",
	],
	"chef": [
		"Avó tinha razão:\ncomida cura tudo.",
		"Receita secreta de cura: amor,\ncarinho e fungos dimensionais.",
		"Faca de cozinha também é arma.\nPergunta pro último Sentinela.",
	],
	"mystery": [
		"...",
		"Eu sei coisas.\nNão, não vou contar.",
		"???",
	],
	"fragmentado": [
		"Estou bem.\nSão só 10 fendas por dia.",
		"Tenho um estilhaço de Zion dentro de mim.\nArde um pouco.",
		"Comecei com 50% de HP.\nAinda assim cheguei aqui.",
	],
}

## Velocidade de rotação do carrossel (radianos por segundo)
const CAROUSEL_SPEED := 0.10
## Quanto tempo cada balão fica visível
const BUBBLE_SHOW_DURATION := 3.8
## Pausa entre um balão e outro
const BUBBLE_COOLDOWN := 0.7

var _twinkling_stars: Array = []
var _name_labels: Array = []
## Cada entrada: {node, base_y, speed, phase, base_angle, radius, char_id, is_dancer}
var _char_roots: Array = []
var _time: float = 0.0
var _carousel_angle: float = 0.0
var _camera: Camera3D = null

# --- Sistema de balões de fala ---
var _bubble_timer: float = 1.5   # começa logo
var _in_cooldown: bool = false
var _bubble_overlay: Control = null
var _bubble_panel: PanelContainer = null
var _bubble_name_lbl: Label = null
var _bubble_text_lbl: Label = null
var _current_speaker_idx: int = -1
var _last_speaker_idx: int = -1

@onready var viewport_container: SubViewportContainer = $SubViewportContainer
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var star_overlay: Control = $StarOverlay
@onready var back_btn: Button = $BackButton

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.pressed.connect(_on_back)

	_setup_top_section()
	_setup_3d_scene()
	_setup_twinkling_stars()
	_setup_bubble_overlay()

func _process(delta: float) -> void:
	_time += delta
	_animate_twinkling_stars()
	_animate_name_labels()
	_animate_characters(delta)
	_animate_speech_bubbles(delta)

# ==================== SECAO SUPERIOR (nomes dos criadores) ====================

func _setup_top_section() -> void:
	var top_bg = PanelContainer.new()
	top_bg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bg.anchor_bottom = 0.35
	top_bg.offset_top = 0.0
	top_bg.offset_bottom = 0.0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.07, 0.92)
	style.set_border_width_all(0)
	top_bg.add_theme_stylebox_override("panel", style)
	add_child(top_bg)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	top_bg.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Creditos"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	var sep = HSeparator.new()
	sep.add_theme_color_override("color", Color(1.0, 0.85, 0.2, 0.4))
	vbox.add_child(sep)

	var names_hbox = HBoxContainer.new()
	names_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	names_hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(names_hbox)

	var star_chars = ["✦", "✧", "⭑", "✦"]
	for i in range(CREDITS.size()):
		var col = VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		names_hbox.add_child(col)

		var star_lbl = Label.new()
		star_lbl.text = star_chars[i % star_chars.size()]
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_lbl.add_theme_font_size_override("font_size", 20)
		star_lbl.add_theme_color_override("font_color", STAR_COLORS[i % STAR_COLORS.size()])
		col.add_child(star_lbl)

		var name_lbl = Label.new()
		name_lbl.text = CREDITS[i]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
		col.add_child(name_lbl)

		_name_labels.append({"label": name_lbl, "star": star_lbl, "phase": i * 1.2})

	var sep2 = HSeparator.new()
	sep2.add_theme_color_override("color", Color(1.0, 0.85, 0.2, 0.3))
	vbox.add_child(sep2)

	var extras_hbox = HBoxContainer.new()
	extras_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	extras_hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(extras_hbox)

	for entry in EXTRA_CREDITS:
		var ecol = VBoxContainer.new()
		ecol.alignment = BoxContainer.ALIGNMENT_CENTER
		ecol.add_theme_constant_override("separation", 1)
		extras_hbox.add_child(ecol)

		var cat_lbl = Label.new()
		cat_lbl.text = entry[0]
		cat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cat_lbl.add_theme_font_size_override("font_size", 9)
		cat_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.8))
		ecol.add_child(cat_lbl)

		var val_lbl = Label.new()
		val_lbl.text = entry[1]
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_lbl.add_theme_font_size_override("font_size", 11)
		val_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		ecol.add_child(val_lbl)

	var sep3 = HSeparator.new()
	sep3.add_theme_color_override("color", Color(1.0, 0.85, 0.2, 0.2))
	vbox.add_child(sep3)

	var heroes_lbl = Label.new()
	heroes_lbl.text = "Herois do jogo"
	heroes_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heroes_lbl.add_theme_font_size_override("font_size", 14)
	heroes_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.8))
	vbox.add_child(heroes_lbl)

# ==================== 3D CAMPFIRE SCENE ====================

func _setup_3d_scene() -> void:
	var camera = Camera3D.new()
	camera.position = Vector3(0, 5.5, 7.0)
	camera.rotation.x = deg_to_rad(-32)
	camera.fov = 55
	sub_viewport.add_child(camera)
	_camera = camera  # guarda referência para projeção 3D→2D

	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.06)
	env.ambient_light_color = Color(0.08, 0.06, 0.12)
	env.ambient_light_energy = 0.3
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_ACES

	var world_env = WorldEnvironment.new()
	world_env.environment = env
	sub_viewport.add_child(world_env)

	var fire_light = OmniLight3D.new()
	fire_light.position = Vector3(0, 1.0, 0)
	fire_light.light_color = Color(1.0, 0.6, 0.15)
	fire_light.light_energy = 5.0
	fire_light.omni_range = 12.0
	fire_light.omni_attenuation = 1.5
	sub_viewport.add_child(fire_light)

	var moon_light = DirectionalLight3D.new()
	moon_light.rotation.x = deg_to_rad(-45)
	moon_light.rotation.y = deg_to_rad(30)
	moon_light.light_color = Color(0.3, 0.35, 0.5)
	moon_light.light_energy = 0.5
	sub_viewport.add_child(moon_light)

	_create_ground()
	_create_campfire()
	_create_characters_circle()

func _create_ground() -> void:
	var ground = MeshInstance3D.new()
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(20, 20)
	ground.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.12, 0.05)
	mat.roughness = 1.0
	ground.material_override = mat
	sub_viewport.add_child(ground)

func _create_campfire() -> void:
	var fire_root = Node3D.new()
	fire_root.name = "Campfire"

	for i in range(4):
		var log_mesh = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.06
		cyl.bottom_radius = 0.08
		cyl.height = 0.8
		log_mesh.mesh = cyl
		log_mesh.position = Vector3(0, 0.08, 0)
		log_mesh.rotation.z = deg_to_rad(75)
		log_mesh.rotation.y = deg_to_rad(i * 45)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.12, 0.05)
		mat.roughness = 1.0
		log_mesh.material_override = mat
		fire_root.add_child(log_mesh)

	for i in range(8):
		var stone = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.2
		stone.mesh = sphere
		var angle = i * TAU / 8.0
		stone.position = Vector3(cos(angle) * 0.45, 0.06, sin(angle) * 0.45)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.25, 0.28)
		mat.roughness = 1.0
		stone.material_override = mat
		fire_root.add_child(stone)

	for i in range(3):
		var flame = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.12 - i * 0.03
		sphere.height = (0.12 - i * 0.03) * 2
		flame.mesh = sphere
		flame.position = Vector3((i - 1) * 0.08, 0.2 + i * 0.12, 0)
		var mat = StandardMaterial3D.new()
		var t = float(i) / 2.0
		mat.albedo_color = Color(1.0, 0.4 + t * 0.3, 0.05)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.5 + t * 0.2, 0.1)
		mat.emission_energy_multiplier = 5.0 - i * 1.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.85
		flame.material_override = mat
		fire_root.add_child(flame)

	sub_viewport.add_child(fire_root)

func _create_characters_circle() -> void:
	var char_ids = CharacterDB.get_all_character_ids()
	var count = char_ids.size()
	var radius = 2.8

	# Sorteia 1 índice para o dançarino
	var dancer_idx = randi() % max(count, 1)

	for i in range(count):
		var char_id = char_ids[i]
		var angle = (float(i) / count) * TAU - PI / 2.0
		var is_dancer = (i == dancer_idx)

		var char_root = Node3D.new()
		char_root.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

		var sprite = Sprite3D.new()
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.024
		sprite.position.y = 0.8

		var tex_path = "res://assets/sprites/characters/%s.png" % char_id
		var tex = load(tex_path)
		if tex:
			sprite.texture = tex
		else:
			var fallback = load("res://assets/sprites/characters/mystery.png")
			if fallback:
				sprite.texture = fallback

		sprite.modulate = Color(1.0, 0.95, 0.85)
		char_root.add_child(sprite)
		sub_viewport.add_child(char_root)

		var entry = {
			"node":       char_root,
			"base_y":     0.0,
			"speed":      randf_range(1.0, 2.0),
			"phase":      randf() * TAU,
			"base_angle": angle,
			"radius":     radius,
			"char_id":    char_id,
			"is_dancer":  is_dancer,
		}
		_char_roots.append(entry)

		# Dançarino tem tween próprio de animação vertical
		if is_dancer:
			var dancer_tween = create_tween().set_loops()
			dancer_tween.tween_property(char_root, "rotation:y", deg_to_rad(15), 0.3).set_trans(Tween.TRANS_SINE)
			dancer_tween.tween_property(char_root, "position:y", 0.3, 0.2).set_trans(Tween.TRANS_BACK)
			dancer_tween.tween_property(char_root, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_BOUNCE)
			dancer_tween.tween_property(char_root, "rotation:y", deg_to_rad(-15), 0.3).set_trans(Tween.TRANS_SINE)
			dancer_tween.tween_property(char_root, "position:y", 0.3, 0.2).set_trans(Tween.TRANS_BACK)
			dancer_tween.tween_property(char_root, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_BOUNCE)

func _animate_characters(delta: float) -> void:
	_carousel_angle += delta * CAROUSEL_SPEED
	for data in _char_roots:
		var node: Node3D      = data["node"]
		var speed: float      = data["speed"]
		var phase: float      = data["phase"]
		var base_angle: float = data["base_angle"]
		var radius: float     = data["radius"]
		var is_dancer: bool   = data["is_dancer"]

		var current_angle = base_angle + _carousel_angle
		node.position.x = cos(current_angle) * radius
		node.position.z = sin(current_angle) * radius

		# Vertical bob — dançarino tem seu próprio tween, não mexemos no y dele
		if not is_dancer:
			node.position.y = data["base_y"] + sin(_time * speed + phase) * 0.08

# ==================== BALOES DE FALA ====================

func _setup_bubble_overlay() -> void:
	_bubble_overlay = Control.new()
	_bubble_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bubble_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bubble_overlay)
	# Garante que o overlay fica acima de tudo
	move_child(_bubble_overlay, get_child_count() - 1)

	_bubble_panel = PanelContainer.new()
	_bubble_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.06, 0.18, 0.93)
	style.border_color = Color(1.0, 0.85, 0.3, 0.9)
	style.set_border_width_all(2)
	style.corner_radius_top_left    = 10
	style.corner_radius_top_right   = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left  = 4
	style.set_content_margin_all(10)
	_bubble_panel.add_theme_stylebox_override("panel", style)
	_bubble_overlay.add_child(_bubble_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_bubble_panel.add_child(vbox)

	_bubble_name_lbl = Label.new()
	_bubble_name_lbl.add_theme_font_size_override("font_size", 11)
	_bubble_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(_bubble_name_lbl)

	_bubble_text_lbl = Label.new()
	_bubble_text_lbl.add_theme_font_size_override("font_size", 13)
	_bubble_text_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_bubble_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_text_lbl.custom_minimum_size = Vector2(200, 0)
	vbox.add_child(_bubble_text_lbl)

func _animate_speech_bubbles(delta: float) -> void:
	if _char_roots.is_empty() or _camera == null:
		return

	_bubble_timer -= delta

	if _bubble_timer <= 0.0:
		if _in_cooldown:
			_in_cooldown = false
			_pick_next_speaker()
		else:
			_hide_bubble()
			_in_cooldown = true
			_bubble_timer = BUBBLE_COOLDOWN

	# Atualiza posição do balão enquanto o carrossel gira
	if _bubble_panel != null and _bubble_panel.visible and _current_speaker_idx >= 0:
		_reposition_bubble(_current_speaker_idx)

func _pick_next_speaker() -> void:
	if _char_roots.is_empty():
		return
	var idx = _last_speaker_idx
	var attempts = 0
	while idx == _last_speaker_idx and attempts < 15:
		idx = randi() % _char_roots.size()
		attempts += 1
	_current_speaker_idx = idx
	_last_speaker_idx = idx
	_show_bubble(idx)
	_bubble_timer = BUBBLE_SHOW_DURATION

func _show_bubble(idx: int) -> void:
	if idx < 0 or idx >= _char_roots.size():
		return
	if _camera == null or _bubble_panel == null:
		return

	var data    = _char_roots[idx]
	var char_id: String = data["char_id"]

	# Frase aleatória do personagem
	var quotes: Array = CHARACTER_QUOTES.get(char_id, ["..."])
	var quote: String = quotes[randi() % quotes.size()]

	# Nome display
	var display_name: String = char_id.capitalize()
	if CharacterDB.has_method("get_character"):
		var cdata = CharacterDB.get_character(char_id)
		if cdata is Dictionary and cdata.has("name"):
			display_name = cdata["name"]

	_bubble_name_lbl.text = "— " + display_name
	_bubble_text_lbl.text = quote

	_bubble_panel.visible = true
	_bubble_panel.modulate.a = 0.0
	_reposition_bubble(idx)

	var tw = create_tween()
	tw.tween_property(_bubble_panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)

func _reposition_bubble(idx: int) -> void:
	if idx < 0 or idx >= _char_roots.size():
		return
	var data     = _char_roots[idx]
	var char_node: Node3D = data["node"]

	# Ponto acima da cabeça do personagem (no mundo 3D)
	var world_pos = char_node.global_position + Vector3(0, 2.2, 0)

	# Projeta para coordenadas do SubViewport
	var vp_pos = _camera.unproject_position(world_pos)

	# Escala do SubViewport para o espaço do container na tela
	var vp_size       = Vector2(sub_viewport.size)
	var container_pos  = viewport_container.global_position
	var container_size = viewport_container.size
	if vp_size.x > 0.0 and vp_size.y > 0.0:
		vp_pos.x = vp_pos.x * (container_size.x / vp_size.x) + container_pos.x
		vp_pos.y = vp_pos.y * (container_size.y / vp_size.y) + container_pos.y

	# Centraliza o balão horizontalmente sobre o herói e evita sair da tela
	var screen      = get_viewport_rect().size
	var panel_size  = _bubble_panel.size if _bubble_panel.size.x > 0 else Vector2(230, 80)
	vp_pos.x = clamp(vp_pos.x - panel_size.x * 0.5, 10.0, screen.x - panel_size.x - 10.0)
	vp_pos.y = clamp(vp_pos.y - panel_size.y - 8.0,  10.0, screen.y - panel_size.y - 10.0)

	_bubble_panel.position = vp_pos

func _hide_bubble() -> void:
	if _bubble_panel == null or not _bubble_panel.visible:
		return
	var tw = create_tween()
	tw.tween_property(_bubble_panel, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): _bubble_panel.visible = false)

# ==================== TWINKLING STARS (decoracao no topo) ====================

func _setup_twinkling_stars() -> void:
	var screen_w  = get_viewport_rect().size.x
	var sky_height = get_viewport_rect().size.y * 0.35

	for i in range(40):
		var star_label = Label.new()
		star_label.text = "✦" if i % 3 == 0 else ("✧" if i % 3 == 1 else "⭑")

		var color = STAR_COLORS[i % STAR_COLORS.size()]
		star_label.add_theme_color_override("font_color", color)
		star_label.add_theme_font_size_override("font_size", randi_range(6, 14))

		var pos = Vector2(
			randf_range(20, screen_w - 20),
			randf_range(5, sky_height - 5)
		)
		star_label.position = pos
		star_label.modulate.a = randf_range(0.3, 1.0)
		star_overlay.add_child(star_label)

		_twinkling_stars.append({
			"label":     star_label,
			"phase":     randf() * TAU,
			"speed":     randf_range(0.4, 1.2),
			"min_alpha": randf_range(0.1, 0.3),
			"max_alpha": randf_range(0.7, 1.0),
		})

func _animate_twinkling_stars() -> void:
	for star in _twinkling_stars:
		var t = sin(_time * star.speed + star.phase) * 0.5 + 0.5
		star.label.modulate.a = lerp(star.min_alpha, star.max_alpha, t)

func _animate_name_labels() -> void:
	for data in _name_labels:
		var glow = sin(_time * 1.2 + data.phase) * 0.15 + 0.85
		data.label.modulate = Color(1.0, 1.0, 1.0, glow)
		var t  = sin(_time * 0.9 + data.phase) * 0.5 + 0.5
		var ci = int(data.phase) % STAR_COLORS.size()
		data.star.modulate = STAR_COLORS[ci].lerp(Color.WHITE, t * 0.3)

# ==================== NAVIGATION ====================

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_viewport(): get_viewport().set_input_as_handled()
		_on_back()
