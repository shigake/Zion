extends Node

## Aplica materiais visuais a entidades do jogo.
## Chame apply_cel_shader() no _ready() de qualquer entidade com Mesh.

var cel_shader: Shader = preload("res://assets/materials/cel_shader.gdshader")
var outline_shader: Shader = preload("res://assets/materials/outline_shader.gdshader")
var pickup_shader: Shader = preload("res://assets/materials/pickup_glow.gdshader")

func create_cel_material(color: Color, rim_color: Color = Color(1, 1, 1, 0.5)) -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = cel_shader
	mat.set_shader_parameter("albedo_color", color)
	mat.set_shader_parameter("rim_color", rim_color)
	mat.set_shader_parameter("rim_amount", 0.4)
	mat.set_shader_parameter("toon_steps", 3.0)
	mat.set_shader_parameter("shadow_color", Color(color.r * 0.3, color.g * 0.3, color.b * 0.4))
	return mat

func create_outline_material(color: Color = Color(0.05, 0.05, 0.08), width: float = 0.025) -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = outline_shader
	mat.set_shader_parameter("outline_color", color)
	mat.set_shader_parameter("outline_width", width)
	return mat

func create_glow_material(color: Color, intensity: float = 2.0) -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = pickup_shader
	mat.set_shader_parameter("glow_color", color)
	mat.set_shader_parameter("glow_intensity", intensity)
	mat.set_shader_parameter("pulse_speed", 2.0)
	return mat

func apply_cel_shader_to_mesh(mesh_instance: MeshInstance3D, color: Color) -> void:
	## Applies cel-shader + outline to a MeshInstance3D
	mesh_instance.material_override = create_cel_material(color)

	# Add outline pass as next pass
	var outline_mat = create_outline_material(Color(color.r * 0.2, color.g * 0.2, color.b * 0.2))
	mesh_instance.material_override.next_pass = outline_mat
