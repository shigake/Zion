extends Node3D

## Cemiterio — pixel art cemetery with scattered tombstones, dead trees,
## ground fog, and eerie lighting.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"tombstone1": 25,
	"tombstone2": 20,
	"tombstone3": 10,
	"dead_tree1": 12,
	"dead_tree2": 15,
	"iron_fence": 20,
	"cross": 10,
	"skull_pile": 8,
	"lantern": 6,
	"pumpkin": 5,
	"mushroom": 10,
}


func _ready() -> void:
	_create_ground()
	_scatter_props()
	_create_ground_fog()
	_create_atmosphere_light()


func _create_ground() -> void:
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(area_size * 2, area_size * 2)
	ground.mesh = plane

	var mat = StandardMaterial3D.new()
	mat.roughness = 1.0

	var ground_tex_path = "res://assets/sprites/props/cemetery/ground_cemetery.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		# Fallback: dark earthy color if texture not found
		mat.albedo_color = Color(0.12, 0.15, 0.08)

	ground.material_override = mat
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
			sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS

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


func _create_ground_fog() -> void:
	var fog = MeshInstance3D.new()
	var fog_mesh = PlaneMesh.new()
	fog_mesh.size = Vector2(area_size * 1.5, area_size * 1.5)
	fog.mesh = fog_mesh
	fog.position.y = 0.3

	var fog_mat = StandardMaterial3D.new()
	fog_mat.albedo_color = Color(0.3, 0.35, 0.4, 0.12)
	fog_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fog.material_override = fog_mat
	fog.name = "GroundFog"
	add_child(fog)


func _create_atmosphere_light() -> void:
	# Eerie blue-green point light for ghostly atmosphere
	var light = OmniLight3D.new()
	light.light_color = Color(0.4, 0.55, 0.8)
	light.light_energy = 0.3
	light.omni_range = area_size * 0.6
	light.omni_attenuation = 2.0
	light.position = Vector3(0, 15, 0)
	light.name = "AtmosphereLight"
	add_child(light)
