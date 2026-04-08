extends Node

## Factory for pixel art 3D shader materials.
## Caches materials to avoid creating duplicates.

var _shader: Shader = null
var _material_cache: Dictionary = {}  # cache_key -> ShaderMaterial

func _ready() -> void:
	_shader = load("res://assets/shaders/pixel_art_3d.gdshader")

## Get a pixel art material with specified parameters.
## Uses cache to avoid duplicate materials.
func get_material(
	texture: Texture2D,
	outline_color: Color = Color.BLACK,
	outline_width: float = 1.0,
	tint: Color = Color.WHITE,
	emission: Color = Color.BLACK,
	emission_strength: float = 0.0,
	cel_levels: int = 3
) -> ShaderMaterial:
	var cache_key = "%s_%s_%.1f_%s" % [texture.resource_path, outline_color.to_html(), outline_width, tint.to_html()]
	if _material_cache.has(cache_key):
		return _material_cache[cache_key]

	var mat = ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("albedo_texture", texture)
	mat.set_shader_parameter("outline_color", outline_color)
	mat.set_shader_parameter("outline_width", outline_width)
	mat.set_shader_parameter("tint_color", tint)
	mat.set_shader_parameter("cel_shading_enabled", true)
	mat.set_shader_parameter("cel_levels", cel_levels)
	mat.set_shader_parameter("emission_color", emission)
	mat.set_shader_parameter("emission_strength", emission_strength)

	_material_cache[cache_key] = mat
	return mat

## Quick material for enemies (black outline, no emission)
func get_enemy_material(texture: Texture2D, tint: Color = Color.WHITE) -> ShaderMaterial:
	return get_material(texture, Color.BLACK, 1.0, tint)

## Quick material for bosses (colored outline, slight emission)
func get_boss_material(texture: Texture2D, boss_color: Color) -> ShaderMaterial:
	return get_material(texture, boss_color.darkened(0.5), 1.5, Color.WHITE, boss_color, 0.3, 3)

## Quick material for player (black outline, colored tint)
func get_player_material(texture: Texture2D, char_color: Color) -> ShaderMaterial:
	return get_material(texture, Color.BLACK, 1.5, Color.WHITE, char_color, 0.15, 3)
