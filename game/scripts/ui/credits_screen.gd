extends Control

## Tela de creditos: herois sentados em volta de uma fogueira,
## nomes dos criadores no topo, personagens do jogo na parte inferior.

const CREDITS := [
	"Erick Higaki",
	"Luiz Ihara",
	"Daniel Maruya",
	"Claudio Ant",
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

var _twinkling_stars: Array = []
var _name_labels: Array = []
var _time: float = 0.0

@onready var viewport_container: SubViewportContainer = $SubViewportContainer
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var star_overlay: Control = $StarOverlay
@onready var back_btn: Button = $BackButton

func _ready() -> void:
	# Garante que o botao funciona mesmo se a tree estiver pausada
	back_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.pressed.connect(_on_back)
	# Permitir unhandled input globalmente
	self.set_process_unhandled_input(true)

	# --- Layout: viewport ocupa a parte inferior (65%) ---
	viewport_container.anchor_top = 0.35
	viewport_container.anchor_bottom = 1.0
	viewport_container.anchor_left = 0.0
	viewport_container.anchor_right = 1.0
	viewport_container.offset_top = 0.0
	viewport_container.offset_bottom = 0.0
	viewport_container.offset_left = 0.0
	viewport_container.offset_right = 0.0

	# StarOverlay cobre apenas o topo (35%) para as estrelas decorativas
	star_overlay.anchor_top = 0.0
	star_overlay.anchor_bottom = 0.35
	star_overlay.anchor_left = 0.0
	star_overlay.anchor_right = 1.0
	star_overlay.offset_top = 0.0
	star_overlay.offset_bottom = 0.0
	star_overlay.offset_left = 0.0
	star_overlay.offset_right = 0.0

	_setup_top_section()
	_setup_3d_scene()
	_setup_twinkling_stars()
	AudioManager.play_sfx("menu_click")

func _process(delta: float) -> void:
	_time += delta
	_animate_twinkling_stars()
	_animate_name_labels()

# ==================== SECAO SUPERIOR (nomes dos criadores) ====================

func _setup_top_section() -> void:
	var screen_size = get_viewport_rect().size
	var top_h = screen_size.y * 0.35

	# Painel escuro semi-transparente no topo
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

	# Titulo
	var title = Label.new()
	title.text = "Creditos"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	var sep = HSeparator.new()
	sep.add_theme_color_override("color", Color(1.0, 0.85, 0.2, 0.4))
	vbox.add_child(sep)

	# Nomes dos desenvolvedores em linha horizontal
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

	# Subtitulo dos herois
	var heroes_lbl = Label.new()
	heroes_lbl.text = "Herois do jogo"
	heroes_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heroes_lbl.add_theme_font_size_override("font_size", 14)
	heroes_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.8))
	vbox.add_child(heroes_lbl)

# ==================== 3D CAMPFIRE SCENE ====================

func _setup_3d_scene() -> void:
	# Camera mais alta para ver todos os personagens em circulo
	var camera = Camera3D.new()
	camera.position = Vector3(0, 5.5, 7.0)
	camera.rotation.x = deg_to_rad(-32)
	camera.fov = 55
	sub_viewport.add_child(camera)

	# Environment: noite estrelada
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

	# Luz da fogueira
	var fire_light = OmniLight3D.new()
	fire_light.position = Vector3(0, 1.0, 0)
	fire_light.light_color = Color(1.0, 0.6, 0.15)
	fire_light.light_energy = 3.0
	fire_light.omni_range = 8.0
	fire_light.omni_attenuation = 1.5
	sub_viewport.add_child(fire_light)

	# Moonlight
	var moon_light = DirectionalLight3D.new()
	moon_light.rotation.x = deg_to_rad(-45)
	moon_light.rotation.y = deg_to_rad(30)
	moon_light.light_color = Color(0.3, 0.35, 0.5)
	moon_light.light_energy = 0.15
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

	# Troncos cruzados
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

	# Pedras ao redor
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

	# Chamas
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

	for i in range(count):
		var char_id = char_ids[i]
		var char_data = CharacterDB.get_character(char_id)
		var angle = (float(i) / count) * TAU - PI / 2.0

		var char_root = Node3D.new()
		char_root.position = Vector3(cos(angle) * radius, 0, sin(angle) * radius)

		var look_target = Vector3(0, 0, 0)
		var dir = (look_target - char_root.position).normalized()
		char_root.rotation.y = atan2(dir.x, dir.z)

		var model = ModelFactory.get_model_for_character(char_id)
		model.scale = Vector3(0.8, 0.8, 0.8)
		model.position.y = -0.15
		model.rotation.x = deg_to_rad(8)

		var base_color = char_data.get("color", Color(0.5, 0.5, 0.5))
		ModelFactory.apply_model_materials(model, base_color)

		char_root.add_child(model)

		# Nome do personagem flutuando acima
		_add_character_name_3d(char_root, char_data.get("name", char_id))

		sub_viewport.add_child(char_root)

func _add_character_name_3d(parent: Node3D, char_name: String) -> void:
	var label = Label3D.new()
	label.text = char_name
	label.position = Vector3(0, 1.8, 0)
	label.font_size = 28
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.9, 0.7, 0.85)
	label.outline_size = 4
	label.outline_modulate = Color(0.2, 0.1, 0.05, 0.6)
	label.no_depth_test = true
	parent.add_child(label)

# ==================== TWINKLING STARS (decoracao no topo) ====================

func _setup_twinkling_stars() -> void:
	var screen_w = get_viewport_rect().size.x
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
			"label": star_label,
			"phase": randf() * TAU,
			"speed": randf_range(0.4, 1.2),
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
		# Estrela pisca com cor variada
		var t = sin(_time * 0.9 + data.phase) * 0.5 + 0.5
		var ci = int(data.phase) % STAR_COLORS.size()
		data.star.modulate = STAR_COLORS[ci].lerp(Color.WHITE, t * 0.3)

# ==================== NAVIGATION ====================

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
