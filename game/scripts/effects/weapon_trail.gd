extends Node3D

## Trail visual que segue uma arma ou projetil.

var points: Array[Vector3] = []
var max_points: int = 15
var trail_color: Color = Color(1, 1, 1, 0.6)
var trail_color_tip: Color = Color(-1, -1, -1)  # Set to override tip color for gradient; (-1,-1,-1) means same as trail_color
var trail_width: float = 0.15
var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh

func _ready() -> void:
	_mesh_instance = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = trail_color
	mat.emission_enabled = true
	mat.emission = trail_color
	mat.emission_energy_multiplier = 3.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	_mesh_instance.material_override = mat
	_immediate_mesh = ImmediateMesh.new()
	_mesh_instance.mesh = _immediate_mesh
	add_child(_mesh_instance)

func _process(_delta: float) -> void:
	if not is_inside_tree():
		return
	points.append(global_position)
	if points.size() > max_points:
		points.remove_at(0)
	_update_mesh()

func _update_mesh() -> void:
	if points.size() < 2:
		return

	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	var use_gradient = trail_color_tip.r >= 0.0
	for i in range(points.size()):
		var t = float(i) / float(points.size() - 1)
		var alpha = t * trail_color.a
		var c: Color
		if use_gradient:
			c = trail_color.lerp(trail_color_tip, t)
			c.a = alpha
		else:
			c = Color(trail_color.r, trail_color.g, trail_color.b, alpha)
		_immediate_mesh.surface_set_color(c)

		var width = trail_width * t
		var up = Vector3.UP * width
		_immediate_mesh.surface_add_vertex(points[i] + up)
		_immediate_mesh.surface_add_vertex(points[i] - up)

	_immediate_mesh.surface_end()
