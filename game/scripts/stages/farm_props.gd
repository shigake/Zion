extends Node3D

## Fazenda do Apocalipse — pixel art farm with hay bales, corn, fences,
## scarecrows, and rustic structures.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"hay_bale": 20,
	"corn": 25,
	"fence": 18,
	"scarecrow": 6,
	"silo": 4,
	"windmill": 3,
	"tractor": 3,
	"barrel": 12,
	"wheat": 20,
}


func _ready() -> void:
	_create_ground()
	_scatter_props()


func _create_ground() -> void:
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(area_size * 2, area_size * 2)
	ground.mesh = plane

	var mat = StandardMaterial3D.new()
	mat.roughness = 1.0

	var ground_tex_path = "res://assets/sprites/props/farm/ground_farm.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		# Fallback: yellow/brown dirt if texture not found
		mat.albedo_color = Color(0.35, 0.3, 0.12)

	ground.material_override = mat
	ground.name = "Ground"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/farm/%s.png" % prop_name
		if not ResourceLoader.exists(sprite_path):
			continue

		var tex = load(sprite_path)

		for i in range(count):
			var sprite = Sprite3D.new()
			sprite.texture = tex
			sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			sprite.pixel_size = 0.05
			sprite.shaded = false
			sprite.transparent = true
			sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS

			var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
			var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)

			# Vary height per prop type for visual depth
			var base_y := 0.8
			if prop_name == "corn":
				base_y = 1.2
			elif prop_name == "scarecrow":
				base_y = 1.3
			elif prop_name == "silo":
				base_y = 1.5
			elif prop_name == "windmill":
				base_y = 1.4
			elif prop_name == "tractor":
				base_y = 0.9
			elif prop_name == "fence":
				base_y = 0.7
			elif prop_name == "hay_bale":
				base_y = 0.6
			elif prop_name == "barrel":
				base_y = 0.5
			elif prop_name == "wheat":
				base_y = 0.6

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)
