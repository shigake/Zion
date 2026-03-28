extends Node3D

## Cemiterio — pixel art cemetery with scattered tombstones, dead trees,
## ground fog, and eerie lighting.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"tombstone1": 45,
	"tombstone2": 35,
	"tombstone3": 25,
	"dead_tree1": 12,
	"dead_tree2": 15,
	"iron_fence": 20,
	"cross": 15,
	"skull_pile": 8,
	"lantern": 6,
	"pumpkin": 5,
	"mushroom": 10,
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
	var ground_tex_path = "res://assets/sprites/props/cemetery/ground_cemetery.png"
	if ResourceLoader.exists(ground_tex_path):
		mat.albedo_texture = load(ground_tex_path)
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		mat.albedo_color = Color(0.12, 0.15, 0.08)
	ground.material_override = mat
	ground.position.y = 0.01
	ground.name = "Ground"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/cemetery/%s.png" % prop_name
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
			sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD

			var x = rng.randf_range(-area_size * 0.8, area_size * 0.8)
			var z = rng.randf_range(-area_size * 0.8, area_size * 0.8)

			# Vary height slightly per prop type for visual depth
			var base_y := 0.8
			if prop_name.begins_with("dead_tree"):
				base_y = 1.5
			elif prop_name == "mushroom":
				base_y = 0.3
			elif prop_name == "skull_pile":
				base_y = 0.4
			elif prop_name == "lantern":
				base_y = 1.0

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)


