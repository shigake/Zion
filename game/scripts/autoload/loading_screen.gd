extends CanvasLayer

## Tela de loading assincrona com pre-warming de sistemas pesados.
## Uso: LoadingScreen.load_stage("res://scenes/stages/stage_cemetery.tscn")
## Carrega a cena em background, pre-aquece pools, shaders, audio, e MultiMesh.

signal loading_finished

# — State —
var _target_scene_path: String = ""
var _progress: Array = []
var _is_loading: bool = false
var _load_complete: bool = false
var _waiting_for_input: bool = false
var _prewarm_done: bool = false
var _prewarm_step: int = 0
var _total_prewarm_steps: int = 7
var _fade_alpha: float = 0.0

# — UI refs (criados programaticamente) —
var _root: Control
var _bg_rect: TextureRect
var _bg_color: ColorRect
var _overlay: ColorRect
var _progress_bar: ProgressBar
var _progress_label: Label
var _tip_label: Label
var _press_label: Label
var _title_label: Label
var _fade_rect: ColorRect
var _spinner_dots: Array[ColorRect] = []

# — Stage metadata —
const STAGE_NAMES: Dictionary = {
	"cemetery": "Cemiterio assombrado",
	"forest": "Floresta sombria",
	"farm": "Fazenda abandonada",
	"tokyo": "Tokyo em chamas",
	"volcano": "Vulcao infernal",
	"ocean": "Oceano profundo",
	"arena": "Arena de combate",
	"space": "Estacao espacial",
	"castle": "Castelo maldito",
	"candy": "Mundo doce",
}

const STAGE_COLORS: Dictionary = {
	"cemetery": Color(0.3, 0.15, 0.5),
	"forest": Color(0.1, 0.35, 0.15),
	"farm": Color(0.5, 0.35, 0.1),
	"tokyo": Color(0.5, 0.1, 0.2),
	"volcano": Color(0.6, 0.15, 0.05),
	"ocean": Color(0.05, 0.2, 0.5),
	"arena": Color(0.4, 0.3, 0.1),
	"space": Color(0.05, 0.05, 0.25),
	"castle": Color(0.25, 0.1, 0.3),
	"candy": Color(0.5, 0.2, 0.4),
}

const TIPS: Array = [
	# Dicas de gameplay
	"Combine armas do mesmo elemento para ativar sinergias poderosas.",
	"Gemas de XP desaparecem depois de um tempo. Fique atento!",
	"Cada personagem tem um passivo unico que muda o estilo de jogo.",
	"Evolua uma arma ao nivel 8 com o item correto no nivel 5.",
	"Reliquias dao bonus permanentes para a run inteira.",
	"O modo Ascensao aumenta a dificuldade, mas tambem os cristais.",
	"Inimigos especiais como o Mimic soltam recompensas melhores.",
	"O dash tem invencibilidade nos primeiros frames. Use com sabedoria!",
	"Bosses tem 3 fases. Cada fase muda seus ataques e comportamento.",
	"No co-op, sinergias cruzadas entre jogadores sao ainda mais fortes.",
	"Cristais compram upgrades permanentes na loja entre as runs.",
	"Fique perto dos aliados caidos para revive-los no co-op.",
	# Lore / narrativa
	"Os cristais chamam uns pelos outros. Voce e apenas o veiculo.",
	"Os Sentinelas nao sao seus inimigos. Sao prisioneiros, como voce.",
	"Cada morte te rebobina. Cada retorno te fortalece. Zion trabalha atraves de voce.",
	"O Conde nao foi corrompido. Ele escolheu. E talvez esteja certo.",
	"Entre as fendas, algo observa. Algo espera.",
	"Zion nao e onde voce chega. E o que voce constroi no caminho.",
	"A loja entre runs e Zion tentando se reconstruir atraves de voce.",
	"Voce nao morre. O estilhaco te rebobina ao ponto de convergencia.",
	"Os Fragmentados foram arrancados de seus mundos. Ninguem escolheu lutar.",
	"Quando estilhacos ressoam juntos, sinergias elementais despertam.",
	"Cada cristal coletado e um pedaco de Zion tentando se reunir.",
	"Os bosses eram protetores. A corrupcao os transformou em prisoes vivas.",
	# Dicas de sinergias e armas
	"Combine fogo + veneno para Toxic Fire (DoT 2x)!",
	"Gelo + Dark cria Shadow Freeze (congela + drena vida)",
	"O Boomerang perfura inimigos na ida E na volta",
	"Blood Orb drena vida dos inimigos e te cura!",
	"Chain Whip chains entre ate 5 inimigos proximos",
	"Tornado puxa inimigos pro centro — otimo pra AoE",
	"Pressione TAB pra ver seu inventario durante a run",
	"Evolucoes precisam de arma nivel 8 + item nivel 5",
	"Inimigos Elite aparecem apos o minuto 7",
	"O boss aparece no minuto 12!",
	"Cada personagem tem uma passiva unica",
	"A Bruxa comeca com +2 invocacoes extras",
	"A Amazona tem bonus de velocidade e dano",
	"Cristais sao creditados mesmo se voce morrer",
	"Desafio Diario tem personagem e fase fixos por dia",
]

# — Scenes to pre-warm in ObjectPool —
const PREWARM_ENEMIES: Array = [
	"res://scenes/enemies/slime.tscn",
	"res://scenes/enemies/bat.tscn",
	"res://scenes/enemies/skeleton.tscn",
	"res://scenes/enemies/ghost.tscn",
	"res://scenes/enemies/zombie_runner.tscn",
	"res://scenes/enemies/spider.tscn",
	"res://scenes/enemies/mushroom.tscn",
	"res://scenes/enemies/wolf.tscn",
]

const PREWARM_PICKUPS: Array = [
	"res://scenes/xp_gem.tscn",
	"res://scenes/crystal_pickup.tscn",
	"res://scenes/health_pickup.tscn",
	"res://scenes/magnet_pickup.tscn",
]

const PREWARM_COUNTS: Dictionary = {
	"enemy": 15,       # was 10 — more enemies pre-pooled
	"pickup": 25,      # was 15 — more pickups pre-pooled
	"projectile": 12,  # was 8 — more projectiles pre-pooled
}

func _ready() -> void:
	layer = 100  # Acima de tudo
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func load_stage(scene_path: String) -> void:
	if _is_loading:
		LogManager.warn("Loading", "Ja esta carregando, ignorando chamada duplicada")
		return

	_target_scene_path = scene_path
	_is_loading = true
	_load_complete = false
	_waiting_for_input = false
	_prewarm_done = false
	_prewarm_step = 0
	_fade_alpha = 0.0

	visible = true
	_build_ui()
	_update_stage_visuals()

	# Inicia carregamento assincrono
	var err = ResourceLoader.load_threaded_request(_target_scene_path, "PackedScene", true)
	if err != OK:
		LogManager.error("Loading", "Falha ao iniciar carregamento: %s (erro %d)" % [_target_scene_path, err])
		# Fallback: carregamento sincrono
		_force_sync_load()
		return

	LogManager.info("Loading", "Iniciando loading: %s" % _target_scene_path)

func _process(delta: float) -> void:
	if not _is_loading:
		return

	# Animacao do spinner
	_animate_spinner(delta)

	# Monitora progresso do ResourceLoader
	if not _load_complete:
		var status = ResourceLoader.load_threaded_get_status(_target_scene_path, _progress)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				var scene_progress = _progress[0] if not _progress.is_empty() else 0.0
				# Scene loading = 60% do total, prewarm = 40%
				var total = scene_progress * 0.6
				_update_progress(total, "Carregando fase...")
			ResourceLoader.THREAD_LOAD_LOADED:
				if not _prewarm_done:
					_start_prewarm()
				else:
					_on_all_complete()
			ResourceLoader.THREAD_LOAD_FAILED:
				LogManager.error("Loading", "Falha no carregamento: %s" % _target_scene_path)
				_force_sync_load()
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				LogManager.error("Loading", "Recurso invalido: %s" % _target_scene_path)
				_force_sync_load()
	elif _prewarm_done and not _waiting_for_input:
		_on_all_complete()

	# Aguarda input do jogador
	if _waiting_for_input:
		# Pisca o label "Pressione qualquer botao"
		if _press_label:
			var t = fmod(Time.get_ticks_msec() / 1000.0, 1.0)
			_press_label.modulate.a = 0.5 + 0.5 * sin(t * TAU)

func _start_prewarm() -> void:
	# Executa pre-warming em etapas distribuidas ao longo de frames
	_do_prewarm_step()

func _do_prewarm_step() -> void:
	match _prewarm_step:
		0:
			_prewarm_object_pool()
			_prewarm_step += 1
			_update_progress(0.65, "Pre-aquecendo object pool...")
			call_deferred("_do_prewarm_step")
		1:
			_prewarm_projectiles()
			_prewarm_step += 1
			_update_progress(0.72, "Carregando projeteis...")
			call_deferred("_do_prewarm_step")
		2:
			_prewarm_shaders()
			_prewarm_step += 1
			_update_progress(0.80, "Compilando shaders...")
			call_deferred("_do_prewarm_step")
		3:
			_prewarm_multimesh()
			_prewarm_step += 1
			_update_progress(0.87, "Inicializando MultiMesh...")
			call_deferred("_do_prewarm_step")
		4:
			_prewarm_audio()
			_prewarm_step += 1
			_update_progress(0.90, "Carregando audio...")
			call_deferred("_do_prewarm_step")
		5:
			_prewarm_materials()
			_prewarm_step += 1
			_update_progress(0.96, "Compilando materiais...")
			call_deferred("_do_prewarm_step")
		6:
			_prewarm_step += 1
			_update_progress(1.0, "Pronto!")
			_prewarm_done = true

func _prewarm_object_pool() -> void:
	LogManager.info("Loading", "Pre-warming object pool...")
	# Pre-warm inimigos base
	for scene_path in PREWARM_ENEMIES:
		if not ResourceLoader.exists(scene_path):
			continue
		var scene = load(scene_path)
		if scene == null:
			continue
		var instances: Array = []
		for i in range(PREWARM_COUNTS["enemy"]):
			var inst = ObjectPool.get_instance(scene)
			instances.append(inst)
		# Devolve ao pool
		for inst in instances:
			ObjectPool.return_instance(inst, scene_path)

	# Pre-warm pickups
	for scene_path in PREWARM_PICKUPS:
		if not ResourceLoader.exists(scene_path):
			continue
		var scene = load(scene_path)
		if scene == null:
			continue
		var instances: Array = []
		for i in range(PREWARM_COUNTS["pickup"]):
			var inst = ObjectPool.get_instance(scene)
			instances.append(inst)
		for inst in instances:
			ObjectPool.return_instance(inst, scene_path)

func _prewarm_projectiles() -> void:
	LogManager.info("Loading", "Pre-warming projectiles...")
	# Pre-warm projeteis das armas comuns
	var projectile_scenes: Array = [
		"res://scenes/weapons/bullet.tscn",
		"res://scenes/weapons/staff_projectile.tscn",
		"res://scenes/weapons/elven_bow_arrow.tscn",
		"res://scenes/weapons/ice_staff_projectile.tscn",
		"res://scenes/weapons/rocket.tscn",
	]
	for scene_path in projectile_scenes:
		if not ResourceLoader.exists(scene_path):
			continue
		var scene = load(scene_path)
		if scene == null:
			continue
		var instances: Array = []
		for i in range(PREWARM_COUNTS["projectile"]):
			var inst = ObjectPool.get_instance(scene)
			instances.append(inst)
		for inst in instances:
			ObjectPool.return_instance(inst, scene_path)

func _prewarm_shaders() -> void:
	LogManager.info("Loading", "Pre-warming shaders...")
	# Compila cel-shader criando uma mesh temporaria fora da camera
	var temp_viewport = SubViewport.new()
	temp_viewport.size = Vector2i(64, 64)
	temp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

	var temp_world = World3D.new()
	temp_viewport.world_3d = temp_world

	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(0, 2, 5)
	cam.rotation.x = deg_to_rad(-20)
	temp_viewport.add_child(cam)

	# Luz
	var light = DirectionalLight3D.new()
	light.position = Vector3(0, 5, 0)
	temp_viewport.add_child(light)

	# Mesh com cel-shader
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh_inst.mesh = sphere

	var shader_path = "res://assets/materials/cel_shader.gdshader"
	if ResourceLoader.exists(shader_path):
		var shader = load(shader_path)
		if shader:
			var mat = ShaderMaterial.new()
			mat.shader = shader
			mat.set_shader_parameter("albedo_color", Color(0.8, 0.2, 0.2))
			mat.set_shader_parameter("toon_steps", 3.0)
			mat.set_shader_parameter("shadow_color", Color(0.15, 0.1, 0.2))
			mat.set_shader_parameter("rim_amount", 0.4)
			mat.set_shader_parameter("rim_color", Color(1.0, 1.0, 1.0, 0.6))
			mat.set_shader_parameter("rim_threshold", 0.5)
			mesh_inst.material_override = mat
	temp_viewport.add_child(mesh_inst)

	# Adiciona temporariamente para forcar compilacao
	add_child(temp_viewport)

	# Remove no proximo frame (apos renderizar)
	temp_viewport.set_meta("_cleanup", true)
	get_tree().create_timer(0.1).timeout.connect(func():
		if is_instance_valid(temp_viewport):
			temp_viewport.queue_free()
	)

func _prewarm_materials() -> void:
	LogManager.info("Loading", "Pre-warming materials and common resources...")
	## Force-compile common materials used during gameplay to avoid stutters.
	## This creates a tiny SubViewport with various material types rendered once.
	var temp_vp = SubViewport.new()
	temp_vp.size = Vector2i(32, 32)
	temp_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var temp_world = World3D.new()
	temp_vp.world_3d = temp_world

	var cam = Camera3D.new()
	cam.position = Vector3(0, 1, 3)
	cam.rotation.x = deg_to_rad(-15)
	temp_vp.add_child(cam)

	# Compile billboard material (used by MultiMeshManager)
	var billboard_mesh = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	billboard_mesh.mesh = quad
	var bb_mat = StandardMaterial3D.new()
	bb_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bb_mat.vertex_color_use_as_albedo = true
	bb_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	bb_mat.alpha_scissor_threshold = 0.5
	billboard_mesh.material_override = bb_mat
	temp_vp.add_child(billboard_mesh)

	# Compile emission material (used by particles, damage numbers)
	var emit_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	emit_mesh.mesh = sphere
	var emit_mat = StandardMaterial3D.new()
	emit_mat.emission_enabled = true
	emit_mat.emission = Color.RED
	emit_mat.emission_energy_multiplier = 2.0
	emit_mesh.material_override = emit_mat
	emit_mesh.position = Vector3(1, 0, 0)
	temp_vp.add_child(emit_mesh)

	# Compile unshaded material (used by enemy projectiles, UI elements)
	var unshaded_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.2, 0.2, 0.2)
	unshaded_mesh.mesh = box
	var unshaded_mat = StandardMaterial3D.new()
	unshaded_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	unshaded_mat.albedo_color = Color.BLUE
	unshaded_mesh.material_override = unshaded_mat
	unshaded_mesh.position = Vector3(-1, 0, 0)
	temp_vp.add_child(unshaded_mesh)

	add_child(temp_vp)
	get_tree().create_timer(0.15).timeout.connect(func():
		if is_instance_valid(temp_vp):
			temp_vp.queue_free()
	)


func _prewarm_multimesh() -> void:
	LogManager.info("Loading", "Pre-warming MultiMeshManager...")
	# Garante que o MultiMeshManager esta resetado e pronto
	MultiMeshManager.on_scene_changed()

func _prewarm_audio() -> void:
	LogManager.info("Loading", "Pre-warming audio...")
	var stage_id = _get_stage_id()
	# Pre-carrega musica da fase
	AudioManager._load_audio("res://assets/audio/music/" + stage_id, [".ogg", ".mp3", ".wav"])
	# Pre-carrega SFX principais
	var sfx_to_load: Array = ["hit", "kill", "collect_xp", "level_up", "player_hurt", "dash"]
	for sfx_name in sfx_to_load:
		AudioManager._load_audio("res://assets/audio/sfx/" + sfx_name, [".wav", ".ogg", ".mp3"])

func _on_all_complete() -> void:
	_load_complete = true
	_waiting_for_input = true
	if _press_label:
		_press_label.visible = true
	if _progress_label:
		_progress_label.text = "Pronto!"
	LogManager.info("Loading", "Carregamento completo, aguardando input")

func _unhandled_input(event: InputEvent) -> void:
	if not _waiting_for_input:
		return

	# Aceita qualquer input (tecla, mouse, gamepad)
	var is_valid_input = false
	if event is InputEventKey and event.pressed and not event.echo:
		is_valid_input = true
	elif event is InputEventJoypadButton and event.pressed:
		is_valid_input = true
	elif event is InputEventMouseButton and event.pressed:
		is_valid_input = true

	if is_valid_input:
		_waiting_for_input = false
		if get_viewport():
			get_viewport().set_input_as_handled()
		_transition_to_scene()

func _transition_to_scene() -> void:
	# Fade out
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if _fade_rect:
		_fade_rect.visible = true
		_fade_rect.modulate.a = 0.0
		tween.tween_property(_fade_rect, "modulate:a", 1.0, 0.4)
	tween.tween_callback(_do_scene_change)

func _do_scene_change() -> void:
	var tree = get_tree()
	if not tree:
		LogManager.error("Loading", "get_tree() null em _do_scene_change")
		_cleanup()
		return

	var packed_scene = ResourceLoader.load_threaded_get(_target_scene_path)
	if packed_scene:
		tree.change_scene_to_packed(packed_scene)
	else:
		LogManager.error("Loading", "Cena nao carregou: %s" % _target_scene_path)
		tree.change_scene_to_file(_target_scene_path)

	# Cleanup
	_cleanup()
	loading_finished.emit()

func _force_sync_load() -> void:
	LogManager.warn("Loading", "Fallback para carregamento sincrono")
	var tree = get_tree()
	if not tree:
		LogManager.error("Loading", "get_tree() null em _force_sync_load")
		_cleanup()
		return
	tree.change_scene_to_file(_target_scene_path)
	_cleanup()

func _cleanup() -> void:
	_is_loading = false
	_load_complete = false
	_waiting_for_input = false
	_prewarm_done = false
	visible = false
	# Remove UI criada
	if _root and is_instance_valid(_root):
		_root.queue_free()
		_root = null
	_spinner_dots.clear()

# ==================== UI ====================

func _build_ui() -> void:
	# Remove UI anterior se existir
	if _root and is_instance_valid(_root):
		_root.queue_free()

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_root)

	# Background escuro base
	_bg_color = ColorRect.new()
	_bg_color.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_color.color = Color(0.05, 0.05, 0.08)
	_root.add_child(_bg_color)

	# Background art da fase
	_bg_rect = TextureRect.new()
	_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.modulate = Color(0.4, 0.4, 0.4, 0.8)  # Escurecido para legibilidade
	_bg_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_root.add_child(_bg_rect)

	# Overlay gradiente escuro (bottom)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0)  # Transparent, replaced by gradient below
	_root.add_child(_overlay)

	# Vignette / gradient overlay via shader-like approach (simple dark bottom)
	var gradient_bottom = ColorRect.new()
	gradient_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	gradient_bottom.custom_minimum_size = Vector2(0, 300)
	gradient_bottom.anchor_top = 0.55
	gradient_bottom.color = Color(0.0, 0.0, 0.0, 0.7)
	_root.add_child(gradient_bottom)

	# VBox central
	var center_vbox = VBoxContainer.new()
	center_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_vbox.anchor_top = 0.1
	center_vbox.anchor_bottom = 0.95
	center_vbox.anchor_left = 0.1
	center_vbox.anchor_right = 0.9
	center_vbox.alignment = BoxContainer.ALIGNMENT_END
	center_vbox.add_theme_constant_override("separation", 16)
	_root.add_child(center_vbox)

	# Spacer para empurrar conteudo para baixo
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_vbox.add_child(spacer)

	# Titulo da fase
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 42)
	_title_label.add_theme_color_override("font_color", Color.WHITE)
	center_vbox.add_child(_title_label)

	# Spinner animado (3 dots)
	var spinner_hbox = HBoxContainer.new()
	spinner_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	spinner_hbox.add_theme_constant_override("separation", 8)
	_spinner_dots.clear()
	for i in range(3):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(10, 10)
		dot.color = UITheme.ACCENT_BLUE
		spinner_hbox.add_child(dot)
		_spinner_dots.append(dot)
	center_vbox.add_child(spinner_hbox)

	# Label de progresso
	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 18)
	_progress_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	_progress_label.text = "Carregando..."
	center_vbox.add_child(_progress_label)

	# Progress bar
	var bar_container = CenterContainer.new()
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(500, 14)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false

	# Estilo da barra
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	bar_bg.set_corner_radius_all(7)
	bar_bg.set_border_width_all(1)
	bar_bg.border_color = UITheme.BORDER_COLOR
	_progress_bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = UITheme.ACCENT_BLUE
	bar_fill.set_corner_radius_all(7)
	_progress_bar.add_theme_stylebox_override("fill", bar_fill)

	bar_container.add_child(_progress_bar)
	center_vbox.add_child(bar_container)

	# Separador
	var sep = Control.new()
	sep.custom_minimum_size = Vector2(0, 20)
	center_vbox.add_child(sep)

	# Fragment intro text (narrative, larger)
	var _intro_label = Label.new()
	_intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro_label.add_theme_font_size_override("font_size", 18)
	_intro_label.add_theme_color_override("font_color", Color(0.9, 0.82, 0.55, 0.95))
	_intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var stage_id = _get_stage_id()
	var intro_key = "stage_intro_" + stage_id
	var intro_text = LocaleManager.tr_key(intro_key)
	if intro_text != intro_key:
		_intro_label.text = intro_text
	else:
		_intro_label.text = ""
	center_vbox.add_child(_intro_label)

	# Frase de lore da fase (curta, italica, abaixo do intro)
	var _lore_label = Label.new()
	_lore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lore_label.add_theme_font_size_override("font_size", 14)
	_lore_label.add_theme_color_override("font_color", Color(0.65, 0.6, 0.8, 0.9))
	_lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lore_key = "stage_" + stage_id + "_lore"
	var lore_text = LocaleManager.tr_key(lore_key)
	if lore_text != lore_key:
		_lore_label.text = "\"%s\"" % lore_text
	else:
		_lore_label.text = ""
	center_vbox.add_child(_lore_label)

	# Dica de gameplay
	_tip_label = Label.new()
	_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip_label.add_theme_font_size_override("font_size", 16)
	_tip_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.text = TIPS[randi() % TIPS.size()]
	center_vbox.add_child(_tip_label)

	# "Pressione qualquer botao"
	_press_label = Label.new()
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.add_theme_font_size_override("font_size", 22)
	_press_label.add_theme_color_override("font_color", Color.WHITE)
	_press_label.text = "Clique ou pressione qualquer botao para iniciar"
	_press_label.visible = false
	center_vbox.add_child(_press_label)

	# Fade rect (para transicao final)
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.visible = false
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fade_rect)

func _update_stage_visuals() -> void:
	var stage_id = _get_stage_id()

	# Nome da fase
	var stage_name = STAGE_NAMES.get(stage_id, stage_id.capitalize())
	if _title_label:
		_title_label.text = stage_name

	# Art da fase como background
	var art_path = "res://assets/sprites/stages/%s.png" % stage_id
	if ResourceLoader.exists(art_path):
		var tex = load(art_path)
		if tex and _bg_rect:
			_bg_rect.texture = tex

	# Cor do gradiente
	var stage_color = STAGE_COLORS.get(stage_id, Color(0.1, 0.1, 0.2))
	if _bg_color:
		_bg_color.color = stage_color.darkened(0.7)

	# Cor da barra de progresso baseada na fase
	if _progress_bar:
		var bar_fill = StyleBoxFlat.new()
		bar_fill.bg_color = stage_color.lightened(0.3)
		bar_fill.set_corner_radius_all(7)
		_progress_bar.add_theme_stylebox_override("fill", bar_fill)

func _update_progress(value: float, text: String) -> void:
	if _progress_bar:
		# Smooth interpolation
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(_progress_bar, "value", value, 0.15)
	if _progress_label:
		_progress_label.text = text

func _animate_spinner(delta: float) -> void:
	if _spinner_dots.is_empty():
		return
	var t = fmod(Time.get_ticks_msec() / 1000.0, 1.5)
	for i in range(_spinner_dots.size()):
		var dot = _spinner_dots[i]
		if not is_instance_valid(dot):
			continue
		var phase = t - (i * 0.2)
		var scale_val = 0.6 + 0.4 * maxf(0.0, sin(phase * TAU))
		dot.custom_minimum_size = Vector2(10 * scale_val, 10 * scale_val)
		dot.modulate.a = 0.4 + 0.6 * maxf(0.0, sin(phase * TAU))

func _get_stage_id() -> String:
	# Extrai stage id do path: "res://scenes/stages/stage_cemetery.tscn" -> "cemetery"
	var filename = _target_scene_path.get_file().get_basename()  # "stage_cemetery"
	if filename.begins_with("stage_"):
		return filename.substr(6)  # "cemetery"
	return GameManager.selected_stage

# ==================== Transition (menu-to-menu) ====================

## Transicao simples com fade para cenas de menu.
## Exibe sprite do personagem selecionado, nome da fase e dica aleatoria.
## Uso: LoadingScreen.transition_to("res://scenes/ui/stage_select.tscn")

var _transition_overlay: ColorRect
var _transition_root: Control
var _transition_char_sprite: TextureRect
var _transition_stage_label: Label
var _transition_tip_label: Label
var _transition_loading_label: Label
var _is_transitioning: bool = false
var _dots_timer: float = 0.0

const TRANSITION_TIPS: Array = [
	"Evolua armas no nivel 8 com o item correspondente!",
	"Dash (ESPACO) te da invulnerabilidade momentanea",
	"Inimigos Elite aparecem apos o minuto 15",
	"Combine elementos para sinergias poderosas",
	"O boss aparece no minuto 25",
	"Cogumelos na floresta dao buffs aleatorios",
	"Cuidado com a lava no vulcao!",
	"O milharal na fazenda te esconde dos inimigos",
	"Zonas escuras no castelo fortalecem inimigos",
	"Caramelo no mundo doce reduz sua velocidade",
	"Os Sentinelas eram protetores de Zion antes da corrupcao.",
	"Voce e um Fragmentado — um estilhaco de Zion vive dentro de voce.",
	"A loja e Zion tentando se reconstruir atraves de voce.",
	"Cada boss derrotado e um guardiao libertado.",
]

func transition_to(scene_path: String) -> void:
	if _is_transitioning or _is_loading:
		LogManager.warn("Loading", "Transicao ignorada: ja em andamento")
		return

	# Validacao do path da cena
	if scene_path.is_empty():
		LogManager.error("Loading", "transition_to chamado com path vazio")
		return
	if not ResourceLoader.exists(scene_path):
		LogManager.error("Loading", "Cena nao encontrada: %s" % scene_path)
		# Tenta trocar direto como fallback
		var tree = get_tree()
		if tree:
			tree.change_scene_to_file(scene_path)
		return

	_is_transitioning = true
	visible = true

	# Build fade overlay
	_transition_root = Control.new()
	_transition_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_transition_root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_transition_root)

	_transition_overlay = ColorRect.new()
	_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_overlay.color = Color(0, 0, 0, 0)
	_transition_root.add_child(_transition_overlay)

	# Fade in (black)
	var tween = create_tween()
	if not tween:
		LogManager.error("Loading", "Falha ao criar tween para fade-in")
		_force_transition_fallback(scene_path)
		return
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_transition_overlay, "color:a", 1.0, 0.4)
	await tween.finished

	# Verifica se ainda estamos em transicao (pode ter sido cancelada)
	if not _is_transitioning:
		return

	# Show loading info (character, stage, tip)
	if is_instance_valid(_transition_root):
		_build_transition_info()

	# Change scene
	var tree = get_tree()
	if not tree:
		LogManager.error("Loading", "get_tree() retornou null durante transicao")
		_cleanup_transition()
		return
	tree.change_scene_to_file(scene_path)

	# Wait frames for scene to settle
	tree = get_tree()
	if not tree:
		_cleanup_transition()
		return
	await tree.process_frame

	tree = get_tree()
	if not tree:
		_cleanup_transition()
		return
	await tree.process_frame

	# Verifica se overlay ainda existe apos awaits
	if not _is_transitioning or not is_instance_valid(_transition_overlay):
		_cleanup_transition()
		return

	# Fade out
	var tween2 = create_tween()
	if not tween2:
		LogManager.error("Loading", "Falha ao criar tween para fade-out")
		_cleanup_transition()
		return
	tween2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween2.tween_property(_transition_overlay, "color:a", 0.0, 0.4)
	await tween2.finished

	# Cleanup
	_cleanup_transition()

## Fallback direto quando a transicao animada falha.
func _force_transition_fallback(scene_path: String) -> void:
	LogManager.warn("Loading", "Fallback direto para: %s" % scene_path)
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file(scene_path)
	_cleanup_transition()

func _build_transition_info() -> void:
	if not is_instance_valid(_transition_root):
		LogManager.warn("Loading", "_build_transition_info: _transition_root invalido")
		return

	# Center content container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.anchor_left = 0.15
	vbox.anchor_right = 0.85
	vbox.anchor_top = 0.15
	vbox.anchor_bottom = 0.85
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	_transition_root.add_child(vbox)

	# Character sprite (from GameManager.selected_character)
	var char_id = GameManager.selected_character if GameManager.selected_character else "ronin"
	var sprite_path = "res://assets/sprites/characters/%s.png" % char_id
	_transition_char_sprite = TextureRect.new()
	_transition_char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_transition_char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_transition_char_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_transition_char_sprite.custom_minimum_size = Vector2(192, 192)  # ~3x scale for 64px sprites
	_transition_char_sprite.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if ResourceLoader.exists(sprite_path):
		_transition_char_sprite.texture = load(sprite_path)
	vbox.add_child(_transition_char_sprite)

	# Stage name
	var stage_id = GameManager.selected_stage if GameManager.selected_stage else "cemetery"
	var stage_name = STAGE_NAMES.get(stage_id, stage_id.capitalize())
	_transition_stage_label = Label.new()
	_transition_stage_label.text = stage_name
	_transition_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_stage_label.add_theme_font_size_override("font_size", 28)
	_transition_stage_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_transition_stage_label)

	# Random tip (gray italic)
	_transition_tip_label = Label.new()
	_transition_tip_label.text = TRANSITION_TIPS[randi() % TRANSITION_TIPS.size()]
	_transition_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_transition_tip_label.add_theme_font_size_override("font_size", 14)
	_transition_tip_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(_transition_tip_label)

	# "Carregando..." with animated dots
	_transition_loading_label = Label.new()
	_transition_loading_label.text = "Carregando..."
	_transition_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_loading_label.add_theme_font_size_override("font_size", 18)
	_transition_loading_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	vbox.add_child(_transition_loading_label)

func _cleanup_transition() -> void:
	_is_transitioning = false
	if _transition_root and is_instance_valid(_transition_root):
		_transition_root.queue_free()
		_transition_root = null
	_transition_overlay = null
	_transition_char_sprite = null
	_transition_stage_label = null
	_transition_tip_label = null
	_transition_loading_label = null
	visible = false
