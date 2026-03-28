extends Node3D

## Fundo do Oceano — pixel art ocean floor with scattered corals,
## seaweed, shells, and sunken treasures.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"coral_pink": 20,
	"coral_blue": 18,
	"seaweed": 25,
	"shell": 15,
	"anchor": 4,
	"treasure_chest": 3,
	"jellyfish": 10,
	"starfish": 12,
	"bubble_column": 15,
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

	var ground_tex_path = "res://assets/sprites/props/ocean/ground_ocean.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		# Fallback: dark ocean blue if texture not found
		mat.albedo_color = Color(0.05, 0.12, 0.2)

	ground.material_override = mat
	ground.name = "Ground"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/ocean/%s.png" % prop_name
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
			if prop_name == "seaweed":
				base_y = 1.2
			elif prop_name == "coral_pink":
				base_y = 1.0
			elif prop_name == "coral_blue":
				base_y = 1.0
			elif prop_name == "jellyfish":
				base_y = 2.0
			elif prop_name == "shell":
				base_y = 0.3
			elif prop_name == "starfish":
				base_y = 0.3
			elif prop_name == "anchor":
				base_y = 0.8
			elif prop_name == "treasure_chest":
				base_y = 0.5
			elif prop_name == "bubble_column":
				base_y = 1.5

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)
