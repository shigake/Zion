extends Node

## Gerencia configuracoes de acessibilidade: daltonismo, reducao de movimento/flash,
## alto contraste, escala de UI e fontes.

# Signals
signal accessibility_changed(setting_name: String, value: Variant)

# Settings (loaded from SaveManager)
var colorblind_mode: int = 0  # 0=off, 1=protanopia, 2=deuteranopia, 3=tritanopia
var reduced_motion: bool = false
var reduced_flash: bool = false
var high_contrast: bool = false
var ui_scale: float = 1.0  # 0.8, 1.0, 1.2, 1.5
var font_scale: float = 1.0  # 0.8, 1.0, 1.2, 1.5

# Flash rate limiter
var _flash_count: int = 0
var _flash_timer: float = 0.0
const MAX_FLASHES_PER_SECOND = 3

# Scale lookup for dropdown index -> float value
const SCALE_VALUES: Array[float] = [0.8, 1.0, 1.2, 1.5]

func _ready():
	_load_settings()

func _process(delta):
	# Flash rate limiter
	_flash_timer += delta
	if _flash_timer >= 1.0:
		_flash_timer = 0.0
		_flash_count = 0

func _load_settings():
	var data = SaveManager.data
	colorblind_mode = data.get("access_colorblind", 0)
	reduced_motion = data.get("access_reduced_motion", false)
	reduced_flash = data.get("access_reduced_flash", false)
	high_contrast = data.get("access_high_contrast", false)
	# Convert dropdown index to scale float
	var ui_idx: int = data.get("access_ui_scale", 1)
	ui_scale = SCALE_VALUES[clampi(ui_idx, 0, SCALE_VALUES.size() - 1)]
	var font_idx: int = data.get("access_font_size", 1)
	font_scale = SCALE_VALUES[clampi(font_idx, 0, SCALE_VALUES.size() - 1)]
	_apply_all()

func set_colorblind_mode(mode: int):
	colorblind_mode = mode
	SaveManager.data["access_colorblind"] = mode
	_apply_colorblind()
	accessibility_changed.emit("colorblind_mode", mode)

func set_reduced_motion(enabled: bool):
	reduced_motion = enabled
	SaveManager.data["access_reduced_motion"] = enabled
	accessibility_changed.emit("reduced_motion", enabled)

func set_reduced_flash(enabled: bool):
	reduced_flash = enabled
	SaveManager.data["access_reduced_flash"] = enabled
	accessibility_changed.emit("reduced_flash", enabled)

func set_high_contrast(enabled: bool):
	high_contrast = enabled
	SaveManager.data["access_high_contrast"] = enabled
	_apply_high_contrast()
	accessibility_changed.emit("high_contrast", enabled)

func set_ui_scale(scale_index: int):
	ui_scale = SCALE_VALUES[clampi(scale_index, 0, SCALE_VALUES.size() - 1)]
	SaveManager.data["access_ui_scale"] = scale_index
	_apply_ui_scale()
	accessibility_changed.emit("ui_scale", ui_scale)

func set_font_scale(scale_index: int):
	font_scale = SCALE_VALUES[clampi(scale_index, 0, SCALE_VALUES.size() - 1)]
	SaveManager.data["access_font_size"] = scale_index
	_apply_font_scale()
	accessibility_changed.emit("font_scale", font_scale)

func can_flash() -> bool:
	if reduced_flash:
		if _flash_count >= MAX_FLASHES_PER_SECOND:
			return false
		_flash_count += 1
	return true

func _apply_all():
	_apply_colorblind()
	_apply_high_contrast()
	_apply_ui_scale()
	_apply_font_scale()

# ---------------------------------------------------------------------------
# Colorblind filter (full-screen shader overlay)
# ---------------------------------------------------------------------------
func _apply_colorblind():
	var canvas = _get_or_create_colorblind_layer()
	if colorblind_mode == 0:
		canvas.visible = false
		return
	canvas.visible = true
	var rect = canvas.get_node("ColorRect") as ColorRect
	if rect and rect.material:
		(rect.material as ShaderMaterial).set_shader_parameter("mode", colorblind_mode)

func _get_or_create_colorblind_layer() -> CanvasLayer:
	var existing = get_node_or_null("ColorblindLayer")
	if existing:
		return existing

	var layer = CanvasLayer.new()
	layer.name = "ColorblindLayer"
	layer.layer = 100  # On top of everything
	add_child(layer)

	var rect = ColorRect.new()
	rect.name = "ColorRect"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader = Shader.new()
	shader.code = _get_colorblind_shader_code()
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("mode", colorblind_mode)
	rect.material = mat

	layer.add_child(rect)
	return layer

func _get_colorblind_shader_code() -> String:
	return """
shader_type canvas_item;
render_mode unshaded;

uniform int mode : hint_range(0, 3) = 0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 c = texture(screen_texture, SCREEN_UV);
	vec3 rgb = c.rgb;

	if (mode == 1) {
		// Protanopia (red-blind)
		float r = 0.567 * rgb.r + 0.433 * rgb.g;
		float g = 0.558 * rgb.r + 0.442 * rgb.g;
		float b = 0.242 * rgb.g + 0.758 * rgb.b;
		rgb = vec3(r, g, b);
	} else if (mode == 2) {
		// Deuteranopia (green-blind)
		float r = 0.625 * rgb.r + 0.375 * rgb.g;
		float g = 0.7 * rgb.r + 0.3 * rgb.g;
		float b = 0.3 * rgb.g + 0.7 * rgb.b;
		rgb = vec3(r, g, b);
	} else if (mode == 3) {
		// Tritanopia (blue-blind)
		float r = 0.95 * rgb.r + 0.05 * rgb.g;
		float g = 0.433 * rgb.g + 0.567 * rgb.b;
		float b = 0.475 * rgb.g + 0.525 * rgb.b;
		rgb = vec3(r, g, b);
	}

	COLOR = vec4(rgb, c.a);
}
"""

# ---------------------------------------------------------------------------
# High contrast — flag-based; individual systems read this
# ---------------------------------------------------------------------------
func _apply_high_contrast():
	# High contrast is applied per-object via VisualSetup checks
	# This just sets the flag; individual systems read it
	pass

# ---------------------------------------------------------------------------
# UI scale — adjusts viewport content scale
# ---------------------------------------------------------------------------
func _apply_ui_scale():
	var viewport = get_viewport()
	if viewport:
		var base_size = Vector2(1280, 720)
		viewport.content_scale_size = base_size / ui_scale

# ---------------------------------------------------------------------------
# Font scale — adjusts default theme font size
# ---------------------------------------------------------------------------
func _apply_font_scale():
	var theme_node = get_node_or_null("/root/UITheme")
	if theme_node and theme_node.has_method("apply_font_scale"):
		theme_node.apply_font_scale(font_scale)
