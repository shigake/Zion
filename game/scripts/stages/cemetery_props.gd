extends Node3D

## Cemiterio — pixel art cemetery with scattered tombstones, dead trees,
## ground fog, and eerie lighting.

@export var area_size: float = 80.0
@export var num_holes: int = 12

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

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
	rng.randomize()
	# O ground ja esta definido na cena (.tscn) — nao criar outro aqui
	# para evitar Z-fighting (dois planos no mesmo Y=0 causam flickering).
	_scatter_props()
	_generate_holes()
	_generate_ground_fog()


func _scatter_props() -> void:
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


## -------------------------------------------------------
## Buracos no chao — cilindros escuros rasos com montinho de terra
## -------------------------------------------------------
func _generate_holes() -> void:
	var hole_mat = StandardMaterial3D.new()
	hole_mat.albedo_color = Color(0.05, 0.03, 0.02)
	hole_mat.roughness = 1.0

	var dirt_mat = StandardMaterial3D.new()
	dirt_mat.albedo_color = Color(0.25, 0.18, 0.1)
	dirt_mat.roughness = 0.95

	for i in range(num_holes):
		var hole = Node3D.new()
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < 6 and abs(z) < 6:
			x += 10.0
		hole.position = Vector3(x, 0, z)

		## Buraco escuro (cilindro raso)
		var hole_mesh = CylinderMesh.new()
		hole_mesh.top_radius = rng.randf_range(0.5, 0.8)
		hole_mesh.bottom_radius = hole_mesh.top_radius * 0.8
		hole_mesh.height = 0.05
		hole_mesh.surface_set_material(0, hole_mat)
		var hole_inst = MeshInstance3D.new()
		hole_inst.mesh = hole_mesh
		hole_inst.position.y = 0.01
		hole.add_child(hole_inst)

		## Montinho de terra ao lado
		var dirt_mesh = SphereMesh.new()
		dirt_mesh.radius = rng.randf_range(0.3, 0.5)
		dirt_mesh.height = dirt_mesh.radius * 0.8
		dirt_mesh.surface_set_material(0, dirt_mat)
		var dirt = MeshInstance3D.new()
		dirt.mesh = dirt_mesh
		dirt.position = Vector3(hole_mesh.top_radius + 0.3, dirt_mesh.height * 0.3, 0)
		dirt.scale = Vector3(1.0, 0.5, 1.0)
		hole.add_child(dirt)

		add_child(hole)


## -------------------------------------------------------
## Nevoa rasteira — particulas de fog no chao
## -------------------------------------------------------
func _generate_ground_fog() -> void:
	var fog1 = GPUParticles3D.new()
	var mat1 = ParticleProcessMaterial.new()
	mat1.direction = Vector3(1, 0, 0)
	mat1.spread = 180.0
	mat1.initial_velocity_min = 0.15
	mat1.initial_velocity_max = 0.4
	mat1.gravity = Vector3(0, 0, 0)
	mat1.scale_min = 2.5
	mat1.scale_max = 6.0
	mat1.color = Color(0.3, 0.35, 0.25, 0.15)
	mat1.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat1.emission_box_extents = Vector3(45, 0.1, 45)

	fog1.process_material = mat1
	fog1.amount = 60
	fog1.lifetime = 10.0
	fog1.visibility_aabb = AABB(Vector3(-60, -1, -60), Vector3(120, 3, 120))

	var draw_pass1 = SphereMesh.new()
	draw_pass1.radius = 1.2
	draw_pass1.height = 0.3
	var fog_mat1 = StandardMaterial3D.new()
	fog_mat1.albedo_color = Color(0.3, 0.35, 0.25, 0.1)
	fog_mat1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_mat1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_pass1.surface_set_material(0, fog_mat1)
	fog1.draw_pass_1 = draw_pass1

	fog1.position = Vector3(0, 0.2, 0)
	add_child(fog1)
