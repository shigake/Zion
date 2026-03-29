extends Control

## Main menu: clean professional design with 5 buttons only.
## Left side: title, crystals, buttons. Right side: character sprite at 4x scale.
## Removed clutter: daily, leaderboard, bestiary, codex, achievements moved elsewhere.

@onready var crystals_label: Label = $LeftPanel/Content/CrystalsContainer/CrystalsLabel
@onready var crystal_icon: Label = $LeftPanel/Content/CrystalsContainer/CrystalIcon
@onready var play_btn: Button = $LeftPanel/Content/Buttons/PlayButton
@onready var multi_btn: Button = $LeftPanel/Content/Buttons/MultiButton
@onready var shop_btn: Button = $LeftPanel/Content/Buttons/ShopButton
@onready var options_btn: Button = $LeftPanel/Content/Buttons/OptionsButton
@onready var quit_btn: Button = $LeftPanel/Content/Buttons/QuitButton
@onready var version_label: Label = $BottomRight/VersionLabel
@onready var credits_btn: Button = $BottomRight/CreditsButton
@onready var title_label: Label = $LeftPanel/Content/Title
@onready var subtitle_label: Label = $LeftPanel/Content/Subtitle
@onready var buttons_container: VBoxContainer = $LeftPanel/Content/Buttons
@onready var gradient_overlay: ColorRect = $GradientOverlay

var _char_sprite: TextureRect = null
var _title_base_y: float = 0.0
var _char_base_y: float = 0.0
var _title_time: float = 0.0
var _particles: Array[ColorRect] = []
var _particle_speeds: Array[float] = []
var _particle_base_x: Array[float] = []
var _glow_rect: ColorRect = null
var _glow_time: float = 0.0

# Colors
const COLOR_BG := Color(0.04, 0.04, 0.06)
const COLOR_GOLD := Color(0.9, 0.8, 0.3)
const COLOR_GOLD_DIM := Color(0.7, 0.62, 0.22)
const COLOR_GOLD_GLOW := Color(0.9, 0.75, 0.2, 0.12)
const COLOR_SUBTITLE := Color(0.55, 0.55, 0.65)
const COLOR_CRYSTAL := Color(0.45, 0.85, 0.95)
const COLOR_BTN_NORMAL := Color(0.10, 0.10, 0.14)
const COLOR_BTN_HOVER := Color(0.16, 0.15, 0.22)
const COLOR_BTN_PRESSED := Color(0.20, 0.18, 0.28)
const COLOR_BTN_TEXT := Color(0.82, 0.82, 0.88)
const COLOR_BTN_TEXT_HOVER := Color(1.0, 0.95, 0.7)
const COLOR_BORDER := Color(0.18, 0.17, 0.24)
const COLOR_BORDER_HOVER := Color(0.9, 0.8, 0.3, 0.6)
const COLOR_PLAY_BG := Color(0.14, 0.12, 0.08)
const COLOR_PLAY_HOVER := Color(0.20, 0.17, 0.10)
const COLOR_PLAY_PRESSED := Color(0.25, 0.22, 0.12)
const COLOR_PLAY_BORDER := Color(0.85, 0.72, 0.22, 0.7)
const COLOR_PLAY_BORDER_GLOW := Color(0.95, 0.82, 0.3, 0.9)
const COLOR_VERSION := Color(0.4, 0.4, 0.48)
const COLOR_CREDITS := Color(0.5, 0.5, 0.58)
const COLOR_QUIT_BG := Color(0.08, 0.08, 0.10)
const COLOR_QUIT_HOVER := Color(0.14, 0.10, 0.10)
const COLOR_QUIT_BORDER := Color(0.25, 0.20, 0.20)
const COLOR_QUIT_TEXT := Color(0.55, 0.50, 0.50)
const COLOR_QUIT_TEXT_HOVER := Color(0.85, 0.55, 0.50)


func _ready() -> void:
	# Safety: ensure game is not paused when entering main menu
	get_tree().paused = false
	GameManager.paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	_style_background()
	_style_title()
	_style_crystals()
	_style_play_button()
	_style_secondary_buttons()
	_style_quit_button()
	_style_bottom_right()
	_setup_3d_background()
	_setup_floating_particles()

	# Connect buttons
	play_btn.pressed.connect(_on_play)
	multi_btn.pressed.connect(_on_multiplayer)
	shop_btn.pressed.connect(_on_shop)
	options_btn.pressed.connect(_on_options)
	quit_btn.pressed.connect(_on_quit)
	credits_btn.pressed.connect(_on_credits)

	# Localized text with icons
	play_btn.text = "⚔  " + LocaleManager.tr_key("menu_play_solo")
	multi_btn.text = "👥  " + LocaleManager.tr_key("menu_multiplayer")
	shop_btn.text = "🏪  " + LocaleManager.tr_key("menu_shop")
	options_btn.text = "⚙  " + LocaleManager.tr_key("menu_options")
	quit_btn.text = LocaleManager.tr_key("menu_quit")

	# Disable multiplayer on mobile
	if PlatformHelper.is_mobile():
		multi_btn.disabled = true
		multi_btn.modulate.a = 0.5

	_update_crystals()
	_update_version()
	AudioManager.play_music("menu")
	_setup_gamepad_focus()

	# Show story intro on first ever play
	if not SaveManager.data.get("story_seen", false):
		_show_story_intro()


# ---------------------------------------------------------------------------
# Styling
# ---------------------------------------------------------------------------

func _style_background() -> void:
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
	# Try to load logo sprite, fallback to text label
	var logo_path := "res://assets/sprites/ui/logo.png"
	if ResourceLoader.exists(logo_path):
		title_label.visible = false
		var logo_tex := TextureRect.new()
		logo_tex.texture = load(logo_path)
		logo_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		logo_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo_tex.custom_minimum_size = Vector2(384 * scale, 96 * scale)
		logo_tex.name = "LogoSprite"
		var parent = title_label.get_parent()
		var idx = title_label.get_index()
		parent.add_child(logo_tex)
		parent.move_child(logo_tex, idx)
	else:
		# Fallback: styled text title with gold + glow
		title_label.text = "ZION"
		title_label.add_theme_font_size_override("font_size", int(72 * scale))
		title_label.add_theme_color_override("font_color", COLOR_GOLD)
		title_label.add_theme_constant_override("shadow_offset_x", 0)
		title_label.add_theme_constant_override("shadow_offset_y", 6)
		title_label.add_theme_color_override("font_shadow_color", Color(0.5, 0.38, 0.0, 0.8))
		title_label.add_theme_constant_override("outline_size", int(5 * scale))
		title_label.add_theme_color_override("font_outline_color", Color(1.0, 0.85, 0.3, 0.5))
	# Store base position for floating animation
	_title_base_y = title_label.position.y
	# Subtitle
	subtitle_label.text = "Survive the horde. Ascend beyond."
	subtitle_label.add_theme_font_size_override("font_size", int(16 * scale))
	subtitle_label.add_theme_color_override("font_color", COLOR_SUBTITLE)
	subtitle_label.add_theme_constant_override("shadow_offset_x", 0)
	subtitle_label.add_theme_constant_override("shadow_offset_y", 2)
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))


func _style_crystals() -> void:
	var scale := PlatformHelper.get_ui_scale()
	crystal_icon.add_theme_font_size_override("font_size", int(15 * scale))
	crystal_icon.add_theme_color_override("font_color", COLOR_CRYSTAL)
	crystals_label.add_theme_font_size_override("font_size", int(13 * scale))
	crystals_label.add_theme_color_override("font_color", COLOR_CRYSTAL)


func _style_play_button() -> void:
	var scale := PlatformHelper.get_ui_scale()
	play_btn.custom_minimum_size = Vector2(300 * scale, 55 * scale)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	play_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Font — larger for primary button
	play_btn.add_theme_font_size_override("font_size", int(20 * scale))
	play_btn.add_theme_color_override("font_color", COLOR_GOLD)
	play_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.6))
	play_btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.4))
	play_btn.add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.6))

	# Normal — dark warm bg with gold border
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = COLOR_PLAY_BG
	sb_normal.border_color = COLOR_PLAY_BORDER
	sb_normal.set_border_width_all(2)
	sb_normal.set_corner_radius_all(8)
	sb_normal.content_margin_left = 24
	sb_normal.content_margin_right = 24
	sb_normal.content_margin_top = 12
	sb_normal.content_margin_bottom = 12
	# Subtle gold shadow glow
	sb_normal.shadow_color = Color(0.9, 0.75, 0.2, 0.08)
	sb_normal.shadow_size = 6
	play_btn.add_theme_stylebox_override("normal", sb_normal)

	# Hover — brighter
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = COLOR_PLAY_HOVER
	sb_hover.border_color = COLOR_PLAY_BORDER_GLOW
	sb_hover.set_border_width_all(2)
	sb_hover.set_corner_radius_all(8)
	sb_hover.content_margin_left = 24
	sb_hover.content_margin_right = 24
	sb_hover.content_margin_top = 12
	sb_hover.content_margin_bottom = 12
	sb_hover.shadow_color = Color(0.9, 0.75, 0.2, 0.15)
	sb_hover.shadow_size = 10
	play_btn.add_theme_stylebox_override("hover", sb_hover)

	# Pressed
	var sb_pressed := StyleBoxFlat.new()
	sb_pressed.bg_color = COLOR_PLAY_PRESSED
	sb_pressed.border_color = COLOR_GOLD
	sb_pressed.set_border_width_all(2)
	sb_pressed.set_corner_radius_all(8)
	sb_pressed.content_margin_left = 24
	sb_pressed.content_margin_right = 24
	sb_pressed.content_margin_top = 12
	sb_pressed.content_margin_bottom = 12
	sb_pressed.shadow_color = Color(0.9, 0.75, 0.2, 0.2)
	sb_pressed.shadow_size = 4
	play_btn.add_theme_stylebox_override("pressed", sb_pressed)

	# Focus (gamepad)
	var sb_focus := StyleBoxFlat.new()
	sb_focus.bg_color = COLOR_PLAY_HOVER
	sb_focus.border_color = COLOR_GOLD
	sb_focus.set_border_width_all(3)
	sb_focus.set_corner_radius_all(8)
	sb_focus.content_margin_left = 24
	sb_focus.content_margin_right = 24
	sb_focus.content_margin_top = 12
	sb_focus.content_margin_bottom = 12
	sb_focus.shadow_color = Color(0.9, 0.75, 0.2, 0.18)
	sb_focus.shadow_size = 10
	play_btn.add_theme_stylebox_override("focus", sb_focus)


func _style_secondary_buttons() -> void:
	for btn in [multi_btn, shop_btn, options_btn]:
		_style_secondary_button(btn)


func _style_secondary_button(btn: Button) -> void:
	var scale := PlatformHelper.get_ui_scale()
	btn.custom_minimum_size = Vector2(250 * scale, 45 * scale)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Font
	btn.add_theme_font_size_override("font_size", int(16 * scale))
	btn.add_theme_color_override("font_color", COLOR_BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", COLOR_BTN_TEXT_HOVER)
	btn.add_theme_color_override("font_pressed_color", COLOR_GOLD)
	btn.add_theme_color_override("font_focus_color", COLOR_BTN_TEXT_HOVER)

	# Normal
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

	# Hover
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

	# Pressed
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

	# Focus (gamepad)
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

	# Disabled
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


func _style_quit_button() -> void:
	var scale := PlatformHelper.get_ui_scale()
	quit_btn.custom_minimum_size = Vector2(180 * scale, 36 * scale)
	quit_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	quit_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Smaller, muted font
	quit_btn.add_theme_font_size_override("font_size", int(13 * scale))
	quit_btn.add_theme_color_override("font_color", COLOR_QUIT_TEXT)
	quit_btn.add_theme_color_override("font_hover_color", COLOR_QUIT_TEXT_HOVER)
	quit_btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.4, 0.4))
	quit_btn.add_theme_color_override("font_focus_color", COLOR_QUIT_TEXT_HOVER)

	# Normal — very subtle
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = COLOR_QUIT_BG
	sb_normal.border_color = COLOR_QUIT_BORDER
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(4)
	sb_normal.content_margin_left = 16
	sb_normal.content_margin_right = 16
	sb_normal.content_margin_top = 6
	sb_normal.content_margin_bottom = 6
	quit_btn.add_theme_stylebox_override("normal", sb_normal)

	# Hover
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = COLOR_QUIT_HOVER
	sb_hover.border_color = Color(0.45, 0.30, 0.30)
	sb_hover.set_border_width_all(1)
	sb_hover.set_corner_radius_all(4)
	sb_hover.content_margin_left = 16
	sb_hover.content_margin_right = 16
	sb_hover.content_margin_top = 6
	sb_hover.content_margin_bottom = 6
	quit_btn.add_theme_stylebox_override("hover", sb_hover)

	# Pressed
	var sb_pressed := StyleBoxFlat.new()
	sb_pressed.bg_color = Color(0.18, 0.10, 0.10)
	sb_pressed.border_color = Color(0.5, 0.3, 0.3)
	sb_pressed.set_border_width_all(1)
	sb_pressed.set_corner_radius_all(4)
	sb_pressed.content_margin_left = 16
	sb_pressed.content_margin_right = 16
	sb_pressed.content_margin_top = 6
	sb_pressed.content_margin_bottom = 6
	quit_btn.add_theme_stylebox_override("pressed", sb_pressed)

	# Focus
	var sb_focus := StyleBoxFlat.new()
	sb_focus.bg_color = COLOR_QUIT_HOVER
	sb_focus.border_color = Color(0.5, 0.35, 0.35)
	sb_focus.set_border_width_all(2)
	sb_focus.set_corner_radius_all(4)
	sb_focus.content_margin_left = 16
	sb_focus.content_margin_right = 16
	sb_focus.content_margin_top = 6
	sb_focus.content_margin_bottom = 6
	quit_btn.add_theme_stylebox_override("focus", sb_focus)


func _style_bottom_right() -> void:
	var scale := PlatformHelper.get_ui_scale()
	version_label.add_theme_font_size_override("font_size", int(11 * scale))
	version_label.add_theme_color_override("font_color", COLOR_VERSION)
	credits_btn.add_theme_font_size_override("font_size", int(12 * scale))
	credits_btn.add_theme_color_override("font_color", COLOR_CREDITS)
	credits_btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
	credits_btn.add_theme_color_override("font_pressed_color", COLOR_GOLD_DIM)
	var sb_empty := StyleBoxEmpty.new()
	credits_btn.add_theme_stylebox_override("normal", sb_empty)
	credits_btn.add_theme_stylebox_override("hover", sb_empty)
	credits_btn.add_theme_stylebox_override("pressed", sb_empty)
	credits_btn.add_theme_stylebox_override("focus", sb_empty)
	credits_btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT


# ---------------------------------------------------------------------------
# Character Sprite (right side of screen)
# ---------------------------------------------------------------------------

func _setup_3d_background() -> void:
	var chars := CharacterDB.get_all_character_ids()
	var random_char: String = chars[randi() % chars.size()]
	var sprite_path := "res://assets/sprites/characters/%s.png" % random_char

	if not ResourceLoader.exists(sprite_path):
		return

	var container := Control.new()
	container.name = "CharacterSpriteContainer"
	container.anchors_preset = Control.PRESET_FULL_RECT
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	move_child(container, 2)

	_char_sprite = TextureRect.new()
	_char_sprite.texture = load(sprite_path)
	_char_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_char_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex_size: Vector2 = _char_sprite.texture.get_size()
	var display_size := tex_size * 4.0
	_char_sprite.custom_minimum_size = display_size
	_char_sprite.size = display_size
	_char_sprite.position = Vector2(
		1280.0 * 0.65 - display_size.x * 0.5,
		720.0 * 0.5 - display_size.y * 0.5
	)
	_char_base_y = _char_sprite.position.y
	# Subtle transparency so it doesn't overpower the menu
	_char_sprite.modulate.a = 0.85
	container.add_child(_char_sprite)


# ---------------------------------------------------------------------------
# Floating Particles (atmospheric golden dots)
# ---------------------------------------------------------------------------

func _setup_floating_particles() -> void:
	var container := Control.new()
	container.name = "ParticlesContainer"
	container.anchors_preset = Control.PRESET_FULL_RECT
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	move_child(container, 2)

	var particle_count := 35
	for i in range(particle_count):
		var dot := ColorRect.new()
		var dot_size := randf_range(1.5, 4.0)
		dot.size = Vector2(dot_size, dot_size)
		dot.color = Color(0.9, 0.8, 0.4, randf_range(0.05, 0.2))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var px := randf_range(0.0, 1280.0)
		var py := randf_range(0.0, 740.0)
		dot.position = Vector2(px, py)
		container.add_child(dot)
		_particles.append(dot)
		_particle_speeds.append(randf_range(10.0, 28.0))
		_particle_base_x.append(px)


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
	# Default focus on play button
	play_btn.grab_focus()
	GamepadUI.notify_menu_opened()


# ---------------------------------------------------------------------------
# Updates
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_title_time += delta
	# Title floating bob (subtle, ~3px amplitude)
	title_label.position.y = _title_base_y + sin(_title_time * 1.8) * 3.0
	# Character sprite bob (slower, ~5px amplitude)
	if _char_sprite:
		_char_sprite.position.y = _char_base_y + sin(_title_time * 1.2) * 5.0
	# Update floating particles
	for i in range(_particles.size()):
		var p: ColorRect = _particles[i]
		p.position.y -= _particle_speeds[i] * delta
		p.position.x = _particle_base_x[i] + sin(_title_time * 0.6 + float(i)) * 12.0
		if p.position.y < -10.0:
			p.position.y = 740.0
			_particle_base_x[i] = randf_range(0.0, 1280.0)
			p.position.x = _particle_base_x[i]


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
# Navigation
# ---------------------------------------------------------------------------

func _on_play() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/character_select.tscn")


func _on_multiplayer() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/lobby_screen.tscn")


func _on_shop() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/shop.tscn")


func _on_options() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/options_screen.tscn")


func _on_credits() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/credits_screen.tscn")


func _on_quit() -> void:
	AudioManager.play_sfx("menu_click")
	_show_quit_confirmation()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_show_quit_confirmation()
		if get_viewport(): get_viewport().set_input_as_handled()


func _show_quit_confirmation() -> void:
	if has_node("QuitDialog"):
		return
	var dialog := AcceptDialog.new()
	dialog.name = "QuitDialog"
	dialog.title = "Sair"
	dialog.exclusive = true
	dialog.unresizable = true
	dialog.dialog_close_on_escape = true
	dialog.dialog_hide_on_ok = true
	var _img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	var _tex := ImageTexture.create_from_image(_img)
	dialog.add_theme_icon_override("close", _tex)
	dialog.add_theme_icon_override("close_pressed", _tex)
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


func _show_story_intro() -> void:
	var story_intro_script = load("res://scripts/ui/story_intro.gd")
	if story_intro_script:
		var intro = CanvasLayer.new()
		intro.set_script(story_intro_script)
		add_child(intro)
