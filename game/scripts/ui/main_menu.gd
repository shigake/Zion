extends Control

## Main menu: professional dark theme with character sprite.
## Left side: title, crystals, buttons. Right side: character sprite at 4x scale.

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

var _char_sprite: TextureRect = null

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
# Character Sprite (right side of screen)
# ---------------------------------------------------------------------------

func _setup_3d_background() -> void:
	# Character sprite displayed on the right side of the screen
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
	# Place behind UI but in front of background (index 2 = after Background + GradientOverlay)
	move_child(container, 2)

	_char_sprite = TextureRect.new()
	_char_sprite.texture = load(sprite_path)
	_char_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_char_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 4x scale: position on the right half
	var tex_size: Vector2 = _char_sprite.texture.get_size()
	var display_size := tex_size * 4.0
	_char_sprite.custom_minimum_size = display_size
	_char_sprite.size = display_size
	# Center vertically, place on right side
	_char_sprite.position = Vector2(
		1280.0 * 0.65 - display_size.x * 0.5,
		720.0 * 0.5 - display_size.y * 0.5
	)
	container.add_child(_char_sprite)


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

func _process(_delta: float) -> void:
	pass


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
	dialog.exclusive = true
	dialog.unresizable = true
	dialog.dialog_close_on_escape = true
	dialog.dialog_hide_on_ok = true
	# Esconde o botao X do titulo
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


func _on_quit() -> void:
	AudioManager.play_sfx("menu_click")
	_show_quit_confirmation()
