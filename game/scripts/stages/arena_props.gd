extends Node3D

## Arena Gladiadora — pixel art Roman arena with columns, torches,
## banners, statues, and battle decorations.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"column": 15,
	"broken_column": 12,
	"torch": 18,
	"shield_wall": 10,
	"banner": 14,
	"statue": 6,
	"gate": 4,
	"chain": 16,
	"skull_pike": 10,
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

	var ground_tex_path = "res://assets/sprites/props/arena/ground_arena.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		# Fallback: sandy stone color if texture not found
		mat.albedo_color = Color(0.3, 0.25, 0.15)

	ground.material_override = mat
	ground.position.y = 0.01
	ground.name = "Ground"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/arena/%s.png" % prop_name
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
			if prop_name == "column":
				base_y = 1.5
			elif prop_name == "broken_column":
				base_y = 0.7
			elif prop_name == "torch":
				base_y = 1.2
			elif prop_name == "shield_wall":
				base_y = 0.9
			elif prop_name == "banner":
				base_y = 1.4
			elif prop_name == "statue":
				base_y = 1.6
			elif prop_name == "gate":
				base_y = 1.5
			elif prop_name == "chain":
				base_y = 1.3
			elif prop_name == "skull_pike":
				base_y = 1.1

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)
