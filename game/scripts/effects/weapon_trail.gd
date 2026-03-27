extends Node3D

## Trail visual que segue uma arma ou projetil.

var points: Array[Vector3] = []
var max_points: int = 15
var trail_color: Color = Color(1, 1, 1, 0.6)
var trail_color_tip: Color = Color(-1, -1, -1)  # Set to override tip color for gradient; (-1,-1,-1) means same as trail_color
var trail_width: float = 0.15
var _mesh_instance: MeshInstance3D

func _ready() -> void:
	_mesh_instance = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = trail_color
	mat.emission_enabled = true
	mat.emission = trail_color
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

func _process(_delta: float) -> void:
	points.append(global_position)
	if points.size() > max_points:
		points.remove_at(0)
	_update_mesh()

func _update_mesh() -> void:
	if points.size() < 2:
		return

	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

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
		im.surface_set_color(c)

		var width = trail_width * t
		var up = Vector3.UP * width
		im.surface_add_vertex(points[i] + up)
		im.surface_add_vertex(points[i] - up)

	im.surface_end()
	_mesh_instance.mesh = im
