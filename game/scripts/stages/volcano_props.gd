extends Node3D

## Vulcao Infernal — pixel art volcanic landscape with scattered lava rocks,
## obsidian crystals, fire geysers, and bone piles.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"lava_rock": 25,
	"obsidian": 15,
	"fire_geyser": 8,
	"skull_rock": 6,
	"magma_pool": 10,
	"dead_bush": 15,
	"bone_pile": 10,
	"crystal_red": 12,
	"volcanic_vent": 8,
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

	var ground_tex_path = "res://assets/sprites/props/volcano/ground_volcano.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		# Fallback: dark volcanic color if texture not found
		mat.albedo_color = Color(0.2, 0.08, 0.03)

	ground.material_override = mat
	ground.name = "Ground"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/volcano/%s.png" % prop_name
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
			if prop_name == "fire_geyser":
				base_y = 1.2
			elif prop_name == "obsidian":
				base_y = 1.3
			elif prop_name == "crystal_red":
				base_y = 1.1
			elif prop_name == "skull_rock":
				base_y = 1.0
			elif prop_name == "magma_pool":
				base_y = 0.3
			elif prop_name == "dead_bush":
				base_y = 0.7
			elif prop_name == "bone_pile":
				base_y = 0.5
			elif prop_name == "volcanic_vent":
				base_y = 0.6

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)
