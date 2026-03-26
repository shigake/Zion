extends Control

## Tela de creditos: herois sentados em volta de uma fogueira,
## nomes como estrelas no ceu noturno com estrelas coloridas piscando.

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
	back_btn.pressed.connect(_on_back)
	_setup_3d_scene()
	_setup_star_names()
	_setup_twinkling_stars()
	AudioManager.play_sfx("menu_click")

func _process(delta: float) -> void:
	_time += delta
	_animate_twinkling_stars()
	_animate_name_labels()

# ==================== 3D CAMPFIRE SCENE ====================

func _setup_3d_scene() -> void:
	# Camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 4.5, 6.5)
	camera.rotation.x = deg_to_rad(-30)
	camera.fov = 50
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
	env.tonemap_mode = Environment.TONE_MAP_ACES

	var world_env = WorldEnvironment.new()
	world_env.environment = env
	sub_viewport.add_child(world_env)

	# Luz da fogueira (ponto de luz quente)
	var fire_light = OmniLight3D.new()
	fire_light.position = Vector3(0, 1.0, 0)
	fire_light.light_color = Color(1.0, 0.6, 0.15)
	fire_light.light_energy = 3.0
	fire_light.omni_range = 8.0
	fire_light.omni_attenuation = 1.5
	sub_viewport.add_child(fire_light)

	# Luz secundaria fraca (moonlight)
	var moon_light = DirectionalLight3D.new()
	moon_light.rotation.x = deg_to_rad(-45)
	moon_light.rotation.y = deg_to_rad(30)
	moon_light.light_color = Color(0.3, 0.35, 0.5)
	moon_light.light_energy = 0.15
	sub_viewport.add_child(moon_light)

	# Chao
	_create_ground()

	# Fogueira no centro
	_create_campfire()

	# Personagens em circulo
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

	# Chamas (esferas com emission)
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
		var angle = (float(i) / count) * TAU - PI / 2.0  # Comeca de frente

		var char_root = Node3D.new()
		char_root.position = Vector3(cos(angle) * radius, 0, sin(angle) * radius)

		# Rotaciona para olhar pro centro (fogueira)
		var look_target = Vector3(0, 0, 0)
		var dir = (look_target - char_root.position).normalized()
		char_root.rotation.y = atan2(dir.x, dir.z)

		# Modelo procedural do personagem
		var model = ModelFactory.get_model_for_character(char_id)
		model.scale = Vector3(0.8, 0.8, 0.8)

		# "Sentar" — abaixa o modelo e inclina levemente
		model.position.y = -0.15
		model.rotation.x = deg_to_rad(8)  # Leve inclinacao pra frente

		# Aplica materiais com cor do personagem
		var base_color = char_data.get("color", Color(0.5, 0.5, 0.5))
		ModelFactory.apply_model_materials(model, base_color)

		char_root.add_child(model)

		# Label do nome flutuando acima
		_add_character_name_3d(char_root, char_data.get("name", char_id), i)

		sub_viewport.add_child(char_root)

func _add_character_name_3d(parent: Node3D, char_name: String, _index: int) -> void:
	var label = Label3D.new()
	label.text = char_name
	label.position = Vector3(0, 1.8, 0)
	label.font_size = 32
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.9, 0.7, 0.7)
	label.outline_size = 4
	label.outline_modulate = Color(0.3, 0.2, 0.1, 0.5)
	label.no_depth_test = true
	parent.add_child(label)

# ==================== STAR NAMES (2D OVERLAY) ====================

func _setup_star_names() -> void:
	var screen_w = get_viewport_rect().size.x
	var screen_h = get_viewport_rect().size.y

	# Posicoes dos nomes no "ceu" (parte superior da tela)
	var positions = [
		Vector2(screen_w * 0.3, screen_h * 0.08),
		Vector2(screen_w * 0.7, screen_h * 0.12),
		Vector2(screen_w * 0.5, screen_h * 0.18),
		Vector2(screen_w * 0.2, screen_h * 0.22),
	]

	for i in range(CREDITS.size()):
		var label = Label.new()
		label.text = CREDITS[i]
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
		label.add_theme_color_override("font_shadow_color", Color(1.0, 0.8, 0.4, 0.6))
		label.add_theme_constant_override("shadow_offset_x", 0)
		label.add_theme_constant_override("shadow_offset_y", 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = positions[i] - Vector2(60, 12)
		label.custom_minimum_size = Vector2(120, 24)
		star_overlay.add_child(label)
		_name_labels.append({"label": label, "base_pos": positions[i], "phase": i * 1.2})

# ==================== TWINKLING STARS ====================

func _setup_twinkling_stars() -> void:
	var screen_w = get_viewport_rect().size.x
	var screen_h = get_viewport_rect().size.y
	var sky_height = screen_h * 0.35  # Estrelas na parte superior

	# Estrelas decorativas ao redor dos nomes
	for i in range(60):
		var star_label = Label.new()
		star_label.text = "✦" if i % 3 == 0 else ("✧" if i % 3 == 1 else "⭑")

		var color = STAR_COLORS[i % STAR_COLORS.size()]
		star_label.add_theme_color_override("font_color", color)
		star_label.add_theme_font_size_override("font_size", randi_range(8, 18))

		var pos = Vector2(
			randf_range(20, screen_w - 20),
			randf_range(10, sky_height)
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
		# Leve flutuacao vertical como estrela brilhando
		var offset_y = sin(_time * 0.8 + data.phase) * 3.0
		var glow = sin(_time * 1.2 + data.phase) * 0.15 + 0.85
		data.label.position.y = data.base_pos.y - 12 + offset_y
		data.label.modulate = Color(1.0, 1.0, 1.0, glow)

# ==================== NAVIGATION ====================

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
