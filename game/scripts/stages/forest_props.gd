extends Node3D

## Floresta Encantada — pixel art forest with scattered trees, mushrooms,
## bushes, and fairy circles.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"tree1": 18,
	"tree2": 15,
	"mushroom_red": 12,
	"mushroom_cluster": 10,
	"bush": 20,
	"rock": 10,
	"flower": 15,
	"log": 8,
	"fairy_circle": 5,
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

	var ground_tex_path = "res://assets/sprites/props/forest/ground_forest.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		# Fallback: bright green if texture not found
		mat.albedo_color = Color(0.15, 0.3, 0.1)

	ground.material_override = mat
	ground.position.y = 0.01
	ground.name = "Ground"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/forest/%s.png" % prop_name
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
			if prop_name.begins_with("tree"):
				base_y = 1.5
			elif prop_name.begins_with("mushroom"):
				base_y = 0.3
			elif prop_name == "bush":
				base_y = 0.5
			elif prop_name == "rock":
				base_y = 0.4
			elif prop_name == "flower":
				base_y = 0.3
			elif prop_name == "log":
				base_y = 0.35
			elif prop_name == "fairy_circle":
				base_y = 0.25

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)
