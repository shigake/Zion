extends Control

## Main menu: professional dark theme with 3D rotating character model.
## Left side: title, crystals, buttons. Right side: 3D character in SubViewport.

@onready var crystals_label: Label = $LeftPanel/Content/CrystalsContainer/CrystalsLabel
@onready var crystal_icon: Label = $LeftPanel/Content/CrystalsContainer/CrystalIcon
@onready var play_btn: Button = $LeftPanel/Content/Buttons/PlayButton
@onready var multi_btn: Button = $LeftPanel/Content/Buttons/MultiButton
@onready var shop_btn: Button = $LeftPanel/Content/Buttons/ShopButton
@onready var quit_btn: Button = $LeftPanel/Content/Buttons/QuitButton
@onready var version_label: Label = $BottomRight/VersionLabel
@onready var credits_btn: Button = $BottomRight/CreditsButton
@onready var title_label: Label = $LeftPanel/Content/Title
@onready var subtitle_label: Label = $LeftPanel/Content/Subtitle
@onready var buttons_container: VBoxContainer = $LeftPanel/Content/Buttons
@onready var gradient_overlay: ColorRect = $GradientOverlay

var _model_node: Node3D = null
var _dance_tween: Tween = null
var _dance_base_pos: Vector3 = Vector3.ZERO
var _dance_time: float = 0.0

# Colors
const COLOR_BG := Color(0.04, 0.04, 0.06)
const COLOR_GOLD := Color(0.9, 0.8, 0.3)
const COLOR_GOLD_DIM := Color(0.7, 0.62, 0.22)
const COLOR_SUBTITLE := Color(0.55, 0.55, 0.65)
const COLOR_CRYSTAL := Color(0.45, 0.85, 0.95)
const COLOR_BTN_NORMAL := Color(0.12, 0.12, 0.16)
const COLOR_BTN_HOVER := Color(0.18, 0.17, 0.24)
const COLOR_BTN_PRESSED := Color(0.22, 0.20, 0.30)
const COLOR_BTN_TEXT := Color(0.88, 0.88, 0.92)
const COLOR_BTN_TEXT_HOVER := Color(1.0, 0.95, 0.7)
const COLOR_BORDER := Color(0.22, 0.21, 0.28)
const COLOR_BORDER_HOVER := Color(0.9, 0.8, 0.3, 0.6)
const COLOR_VERSION := Color(0.4, 0.4, 0.48)
const COLOR_CREDITS := Color(0.5, 0.5, 0.58)


func _ready() -> void:
	# Safety: garante que o jogo nao esta pausado ao entrar no menu principal
	get_tree().paused = false
	GameManager.paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	_style_background()
	_style_title()
	_style_crystals()
	_style_all_buttons()
	_style_bottom_right()
	_setup_3d_background()

	# Connect scene buttons
	play_btn.pressed.connect(_on_play)
	multi_btn.pressed.connect(_on_multiplayer)
	shop_btn.pressed.connect(_on_shop)
	quit_btn.pressed.connect(_on_quit)
	credits_btn.pressed.connect(_on_credits)

	# Localized text for scene buttons
	play_btn.text = LocaleManager.tr_key("menu_play_solo")
	multi_btn.text = LocaleManager.tr_key("menu_multiplayer")
	shop_btn.text = LocaleManager.tr_key("menu_shop")
	quit_btn.text = LocaleManager.tr_key("menu_quit")

	# Disable multiplayer on mobile
	if PlatformHelper.is_mobile():
		multi_btn.disabled = true
		multi_btn.modulate.a = 0.5

	# --- Programmatic buttons (inserted before QuitButton) ---
	# Daily Challenge
	var daily_btn := _create_menu_button("Desafio diario")
	daily_btn.pressed.connect(func():
		AudioManager.play_sfx("menu_click")
		get_tree().change_scene_to_file("res://scenes/ui/daily_challenge_screen.tscn")
	)
	buttons_container.add_child(daily_btn)

	# Leaderboard
	var leaderboard_btn := _create_menu_button(LocaleManager.tr_key("menu_leaderboard"))
	leaderboard_btn.pressed.connect(func():
		AudioManager.play_sfx("menu_click")
		get_tree().change_scene_to_file("res://scenes/ui/leaderboard_screen.tscn")
	)
	buttons_container.add_child(leaderboard_btn)

	# Bestiary
	var bestiary_btn := _create_menu_button(LocaleManager.tr_key("bestiary"))
	bestiary_btn.pressed.connect(func():
		AudioManager.play_sfx("menu_click")
		get_tree().change_scene_to_file("res://scenes/ui/bestiary_screen.tscn")
	)
	buttons_container.add_child(bestiary_btn)

	# Codex
	var codex_btn := _create_menu_button(LocaleManager.tr_key("codex"))
	codex_btn.pressed.connect(func():
		AudioManager.play_sfx("menu_click")
		get_tree().change_scene_to_file("res://scenes/ui/codex_screen.tscn")
	)
	buttons_container.add_child(codex_btn)

	# Options
	var options_btn := _create_menu_button(LocaleManager.tr_key("menu_options"))
	options_btn.pressed.connect(func():
		AudioManager.play_sfx("menu_click")
		get_tree().change_scene_to_file("res://scenes/ui/options_screen.tscn")
	)
	buttons_container.add_child(options_btn)

	# Reorder: options before quit, quit always last
	var btn_count := buttons_container.get_child_count()
	buttons_container.move_child(quit_btn, btn_count - 1)
	buttons_container.move_child(options_btn, btn_count - 2)

	# Apply consistent styling to programmatic buttons
	_style_button(daily_btn)
	_style_button(leaderboard_btn)
	_style_button(bestiary_btn)
	_style_button(codex_btn)
	_style_button(options_btn)

	_update_crystals()
	_update_version()
	AudioManager.play_music("menu")
	_setup_gamepad_focus()


# ---------------------------------------------------------------------------
# Styling
# ---------------------------------------------------------------------------

func _style_background() -> void:
	# Create a subtle gradient shader on the overlay
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.06, 0.06, 0.10, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.02, 0.02, 0.03, 1.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 uv = UV;
	vec4 grad = mix(color_top, color_bottom, uv.y);
	// Subtle vignette
	float dist = distance(uv, vec2(0.5, 0.5));
	float vignette = smoothstep(0.4, 1.0, dist) * vignette_strength;
	grad.rgb -= vec3(vignette);
	COLOR = grad;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("color_top", Color(0.06, 0.06, 0.10, 1.0))
	mat.set_shader_parameter("color_bottom", Color(0.02, 0.02, 0.03, 1.0))
	mat.set_shader_parameter("vignette_strength", 0.35)
	gradient_overlay.material = mat


func _style_title() -> void:
	var scale := PlatformHelper.get_ui_scale()
	# Title
	title_label.add_theme_font_size_override("font_size", int(52 * scale))
	title_label.add_theme_color_override("font_color", COLOR_GOLD)
	title_label.add_theme_constant_override("shadow_offset_x", 0)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	title_label.add_theme_color_override("font_shadow_color", Color(0.3, 0.25, 0.0, 0.5))
	# Subtitle
	subtitle_label.add_theme_font_size_override("font_size", int(14 * scale))
	subtitle_label.add_theme_color_override("font_color", COLOR_SUBTITLE)


func _style_crystals() -> void:
	var scale := PlatformHelper.get_ui_scale()
	crystal_icon.add_theme_font_size_override("font_size", int(15 * scale))
	crystal_icon.add_theme_color_override("font_color", COLOR_CRYSTAL)
	crystals_label.add_theme_font_size_override("font_size", int(13 * scale))
	crystals_label.add_theme_color_override("font_color", COLOR_CRYSTAL)


func _style_all_buttons() -> void:
	for child in buttons_container.get_children():
		if child is Button:
			_style_button(child)


func _style_button(btn: Button) -> void:
	var scale := PlatformHelper.get_ui_scale()
	var base_h := 44.0
	btn.custom_minimum_size = Vector2(280 * scale, base_h * scale)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Font
	btn.add_theme_font_size_override("font_size", int(16 * scale))
	btn.add_theme_color_override("font_color", COLOR_BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", COLOR_BTN_TEXT_HOVER)
	btn.add_theme_color_override("font_pressed_color", COLOR_GOLD)
	btn.add_theme_color_override("font_focus_color", COLOR_BTN_TEXT_HOVER)

	# StyleBox normal
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = COLOR_BTN_NORMAL
	sb_normal.border_color = COLOR_BORDER
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(6)
	sb_normal.content_margin_left = 20
	sb_normal.content_margin_right = 20
	sb_normal.content_margin_top = 8
	sb_normal.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", sb_normal)

	# StyleBox hover
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = COLOR_BTN_HOVER
	sb_hover.border_color = COLOR_BORDER_HOVER
	sb_hover.set_border_width_all(1)
	sb_hover.set_corner_radius_all(6)
	sb_hover.content_margin_left = 20
	sb_hover.content_margin_right = 20
	sb_hover.content_margin_top = 8
	sb_hover.content_margin_bottom = 8
	btn.add_theme_stylebox_override("hover", sb_hover)

	# StyleBox pressed
	var sb_pressed := StyleBoxFlat.new()
	sb_pressed.bg_color = COLOR_BTN_PRESSED
	sb_pressed.border_color = COLOR_GOLD
	sb_pressed.set_border_width_all(1)
	sb_pressed.set_corner_radius_all(6)
	sb_pressed.content_margin_left = 20
	sb_pressed.content_margin_right = 20
	sb_pressed.content_margin_top = 8
	sb_pressed.content_margin_bottom = 8
	btn.add_theme_stylebox_override("pressed", sb_pressed)

	# StyleBox focus (gamepad)
	var sb_focus := StyleBoxFlat.new()
	sb_focus.bg_color = COLOR_BTN_HOVER
	sb_focus.border_color = COLOR_GOLD
	sb_focus.set_border_width_all(2)
	sb_focus.set_corner_radius_all(6)
	sb_focus.content_margin_left = 20
	sb_focus.content_margin_right = 20
	sb_focus.content_margin_top = 8
	sb_focus.content_margin_bottom = 8
	btn.add_theme_stylebox_override("focus", sb_focus)

	# StyleBox disabled
	var sb_disabled := StyleBoxFlat.new()
	sb_disabled.bg_color = Color(0.08, 0.08, 0.10)
	sb_disabled.border_color = Color(0.15, 0.15, 0.18)
	sb_disabled.set_border_width_all(1)
	sb_disabled.set_corner_radius_all(6)
	sb_disabled.content_margin_left = 20
	sb_disabled.content_margin_right = 20
	sb_disabled.content_margin_top = 8
	sb_disabled.content_margin_bottom = 8
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	btn.add_theme_color_override("font_disabled_color", Color(0.35, 0.35, 0.40))


func _style_bottom_right() -> void:
	var scale := PlatformHelper.get_ui_scale()
	# Version label
	version_label.add_theme_font_size_override("font_size", int(11 * scale))
	version_label.add_theme_color_override("font_color", COLOR_VERSION)
	# Credits button
	credits_btn.add_theme_font_size_override("font_size", int(12 * scale))
	credits_btn.add_theme_color_override("font_color", COLOR_CREDITS)
	credits_btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
	credits_btn.add_theme_color_override("font_pressed_color", COLOR_GOLD_DIM)
	# Flat stylebox so it blends with background
	var sb_empty := StyleBoxEmpty.new()
	credits_btn.add_theme_stylebox_override("normal", sb_empty)
	credits_btn.add_theme_stylebox_override("hover", sb_empty)
	credits_btn.add_theme_stylebox_override("pressed", sb_empty)
	credits_btn.add_theme_stylebox_override("focus", sb_empty)
	credits_btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _create_menu_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(280, 44)
	return btn


# ---------------------------------------------------------------------------
# 3D Background (right side of screen)
# ---------------------------------------------------------------------------

func _setup_3d_background() -> void:
	var svc := SubViewportContainer.new()
	svc.name = "ModelViewport"
	# Position on the right half of the screen
	svc.anchors_preset = Control.PRESET_FULL_RECT
	svc.anchor_right = 1.0
	svc.anchor_bottom = 1.0
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)
	# Place behind UI but in front of background (index 2 = after Background + GradientOverlay)
	move_child(svc, 2)

	var sv := SubViewport.new()
	sv.size = Vector2i(1280, 720)
	sv.transparent_bg = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(sv)

	var world := Node3D.new()
	sv.add_child(world)

	# Camera positioned to the right side
	var cam := Camera3D.new()
	cam.position = Vector3(3.0, 1.2, 3.2)
	cam.fov = 38
	world.add_child(cam)
	cam.look_at(Vector3(1.5, 0.6, 0))

	# Key light (warm directional)
	var key_light := DirectionalLight3D.new()
	key_light.rotation = Vector3(deg_to_rad(-35), deg_to_rad(20), 0)
	key_light.light_energy = 1.4
	key_light.light_color = Color(1.0, 0.95, 0.85)
	world.add_child(key_light)

	# Rim / fill light from behind-left (cool tone)
	var rim_light := DirectionalLight3D.new()
	rim_light.rotation = Vector3(deg_to_rad(-20), deg_to_rad(-150), 0)
	rim_light.light_energy = 0.6
	rim_light.light_color = Color(0.6, 0.7, 1.0)
	world.add_child(rim_light)

	# Environment
	var env := Environment.new()
	env.ambient_light_color = Color(0.25, 0.27, 0.4)
	env.ambient_light_energy = 0.4
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0, 0.0)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.1
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	world.add_child(world_env)

	# Random character model placed on the right
	var chars := CharacterDB.get_all_character_ids()
	var random_char: String = chars[randi() % chars.size()]
	_model_node = ModelFactory.get_model_for_character(random_char)
	if _model_node:
		_model_node.position = Vector3(1.5, 0, 0)
		_model_node.scale = Vector3(0.5, 0.5, 0.5)
		_dance_base_pos = _model_node.position
		world.add_child(_model_node)


# ---------------------------------------------------------------------------
# Gamepad focus
# ---------------------------------------------------------------------------

func _setup_gamepad_focus() -> void:
	var buttons: Array[Button] = []
	for child in buttons_container.get_children():
		if child is Button:
			child.focus_mode = Control.FOCUS_ALL
			buttons.append(child)
	# Vertical focus neighbors with wrapping
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		if i > 0:
			btn.focus_neighbor_top = buttons[i - 1].get_path()
		else:
			btn.focus_neighbor_top = buttons[buttons.size() - 1].get_path()
		if i < buttons.size() - 1:
			btn.focus_neighbor_bottom = buttons[i + 1].get_path()
		else:
			btn.focus_neighbor_bottom = buttons[0].get_path()
	GamepadUI.notify_menu_opened()


# ---------------------------------------------------------------------------
# Updates
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _model_node:
		return
	_dance_time += delta
	_animate_piseiro()


func _update_version() -> void:
	var file := FileAccess.open("res://VERSION", FileAccess.READ)
	if file:
		version_label.text = "v" + file.get_as_text().strip_edges()
	else:
		version_label.text = "v1.0.0"


func _update_crystals() -> void:
	var count: int = SaveManager.get_crystals()
	crystals_label.text = LocaleManager.tr_key("crystals") % count


# ---------------------------------------------------------------------------
# Piseiro Dance Animation
# ---------------------------------------------------------------------------

func _animate_piseiro() -> void:
	## Piseiro dance: bouncy rhythmic steps with hip sway (~130 BPM).
	## Two-step pattern: quick-quick with a bounce on each beat.
	var bpm := 130.0
	var beat := _dance_time * bpm / 60.0  # current beat number

	# Bounce: double-time bounce (2x per beat), sharp down + smooth up
	var bounce_phase := fmod(beat * 2.0, 1.0)
	var bounce_y: float = abs(sin(bounce_phase * PI)) * 0.06

	# Side-to-side stepping: shifts weight left/right each beat
	var step_phase := sin(beat * PI)
	var step_x := step_phase * 0.04

	# Hip rotation: sway synced with steps
	var hip_rot_z := sin(beat * PI) * deg_to_rad(6.0)

	# Slight forward/back sway (the "gingado")
	var sway_z := sin(beat * PI * 0.5) * 0.02

	# Upper body counter-rotation for natural feel
	var upper_rot_y := sin(beat * PI) * deg_to_rad(10.0)

	# Foot shuffle: quick alternating lean
	var shuffle_rot_x := sin(beat * 2.0 * PI) * deg_to_rad(3.0)

	# Apply to model
	_model_node.position = _dance_base_pos + Vector3(step_x, bounce_y, sway_z)
	_model_node.rotation = Vector3(shuffle_rot_x, upper_rot_y, hip_rot_z)


# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------

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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_show_quit_confirmation()
		if get_viewport(): get_viewport().set_input_as_handled()


func _show_quit_confirmation() -> void:
	# Verifica se ja existe um dialogo aberto
	if has_node("QuitDialog"):
		return
	var dialog := AcceptDialog.new()
	dialog.name = "QuitDialog"
	dialog.title = "Sair"
	dialog.dialog_text = "Deseja sair do jogo?"
	dialog.ok_button_text = "Sair"
	dialog.add_cancel_button("Cancelar")
	dialog.confirmed.connect(func():
		get_tree().quit()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered()


func _on_quit() -> void:
	AudioManager.play_sfx("menu_click")
	_show_quit_confirmation()
