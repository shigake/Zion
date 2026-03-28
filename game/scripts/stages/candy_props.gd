extends Node3D

## Mundo Doce — pink/pastel candy floors with sweet props scattered around.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"candy_cane": 20,
	"lollipop": 18,
	"gummy_bear": 15,
	"cupcake": 12,
	"ice_cream": 10,
	"chocolate": 12,
	"cotton_candy": 10,
	"donut": 12,
	"cookie": 15,
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

	var ground_tex_path = "res://assets/sprites/props/candy/ground_candy.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		mat.albedo_color = Color(0.35, 0.2, 0.25)

	ground.material_override = mat
	ground.position.y = 0.01
	ground.name = "Ground"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/candy/%s.png" % prop_name
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

			var base_y := 0.8
			if prop_name == "candy_cane":
				base_y = 1.2
			elif prop_name == "lollipop":
				base_y = 1.3
			elif prop_name == "cotton_candy":
				base_y = 1.1
			elif prop_name == "ice_cream":
				base_y = 1.0
			elif prop_name == "gummy_bear":
				base_y = 0.6
			elif prop_name == "cookie":
				base_y = 0.4
			elif prop_name == "chocolate":
				base_y = 0.4

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)
