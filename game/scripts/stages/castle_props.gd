extends Node3D

## Castelo do Vampiro — dark stone floors with gothic props scattered around.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"candelabra": 18,
	"coffin_vampire": 10,
	"pillar": 15,
	"stained_glass": 8,
	"armor_stand": 12,
	"painting": 10,
	"cobweb": 20,
	"gargoyle": 8,
	"throne": 5,
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

	var ground_tex_path = "res://assets/sprites/props/castle/ground_castle.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		mat.albedo_color = Color(0.1, 0.08, 0.08)

	ground.material_override = mat
	ground.name = "Ground"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/castle/%s.png" % prop_name
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
			if prop_name == "pillar":
				base_y = 1.8
			elif prop_name == "candelabra":
				base_y = 1.2
			elif prop_name == "stained_glass":
				base_y = 1.6
			elif prop_name == "armor_stand":
				base_y = 1.3
			elif prop_name == "gargoyle":
				base_y = 1.0
			elif prop_name == "throne":
				base_y = 1.0
			elif prop_name == "cobweb":
				base_y = 1.8
			elif prop_name == "painting":
				base_y = 1.4

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)
