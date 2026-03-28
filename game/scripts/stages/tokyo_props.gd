extends Node3D

## Tokyo Cyberpunk — pixel art neon city with signs, vending machines,
## lampposts, and urban props.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"neon_sign1": 12,
	"neon_sign2": 10,
	"vending_machine": 8,
	"lamppost": 15,
	"car": 6,
	"trash_can": 12,
	"manhole": 8,
	"billboard": 5,
	"barrier": 15,
}


func _ready() -> void:
	_scatter_props()


func _create_ground() -> void:
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(area_size * 2, area_size * 2)
	ground.mesh = plane

	var mat = StandardMaterial3D.new()
	mat.roughness = 1.0

	var ground_tex_path = "res://assets/sprites/props/tokyo/ground_tokyo.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		# Fallback: dark gray asphalt if texture not found
		mat.albedo_color = Color(0.1, 0.1, 0.12)

	ground.material_override = mat
	ground.name = "Ground"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/tokyo/%s.png" % prop_name
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
			if prop_name.begins_with("neon_sign"):
				base_y = 1.4
			elif prop_name == "lamppost":
				base_y = 1.5
			elif prop_name == "billboard":
				base_y = 1.6
			elif prop_name == "vending_machine":
				base_y = 0.9
			elif prop_name == "car":
				base_y = 0.7
			elif prop_name == "trash_can":
				base_y = 0.5
			elif prop_name == "manhole":
				base_y = 0.15
			elif prop_name == "barrier":
				base_y = 0.6

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)
