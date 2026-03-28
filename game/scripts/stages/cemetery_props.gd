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


## Stage mechanic: Destructible tombstones — 5 zones that drop a random buff on first touch
const TOMBSTONE_ZONE_COUNT: int = 5
const TOMBSTONE_ZONE_SIZE: float = 4.0
const TOMBSTONE_BUFF_DURATION: float = 10.0
var _tombstone_zones_used: Dictionary = {}  # zone -> bool (already triggered)
var _anim_time: float = 0.0


func _process(delta: float) -> void:
	_anim_time += delta
	for child in get_children():
		if not child is Sprite3D:
			continue
		var n: String = child.name
		if n.begins_with("lantern"):
			child.modulate.a = 0.7 + sin(_anim_time * 6.0 + child.position.x) * 0.3
		elif n.begins_with("pumpkin"):
			var glow = 0.8 + sin(_anim_time * 3.0 + child.position.z) * 0.2
			child.modulate = Color(1.0, 0.6 * glow, 0.1, glow)


func _ready() -> void:
	rng.randomize()
	# O ground ja esta definido na cena (.tscn) — nao criar outro aqui
	# para evitar Z-fighting (dois planos no mesmo Y=0 causam flickering).
	_scatter_props()
	_generate_holes()
	_generate_ground_fog()
	_create_stage_mechanics()


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


## -------------------------------------------------------
## Mecanica do stage: Tombstones destrutiveis
## Ao pisar, concede buff aleatorio (speed/damage/area +20% por 10s)
## -------------------------------------------------------
func _create_stage_mechanics() -> void:
	for i in range(TOMBSTONE_ZONE_COUNT):
		var zone = Area3D.new()
		zone.name = "TombstoneZone_%d" % i
		zone.collision_layer = 0
		zone.collision_mask = 1  # Players

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(TOMBSTONE_ZONE_SIZE, 2, TOMBSTONE_ZONE_SIZE)
		shape.shape = box
		zone.add_child(shape)

		zone.position = Vector3(
			rng.randf_range(-area_size * 0.6, area_size * 0.6),
			0,
			rng.randf_range(-area_size * 0.6, area_size * 0.6)
		)

		# Visual: glowing tombstone marker on ground
		var visual = _create_zone_visual(Color(0.6, 0.5, 0.8, 0.35), TOMBSTONE_ZONE_SIZE)
		zone.add_child(visual)

		# Tombstone prop on top
		var tomb_sprite = Sprite3D.new()
		tomb_sprite.name = "TombVisual"
		tomb_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tomb_sprite.pixel_size = 0.06
		tomb_sprite.shaded = false
		tomb_sprite.position.y = 1.0
		tomb_sprite.modulate = Color(0.8, 0.7, 1.0)
		var tomb_tex_path = "res://assets/sprites/props/cemetery/cross.png"
		if ResourceLoader.exists(tomb_tex_path):
			tomb_sprite.texture = load(tomb_tex_path)
		zone.add_child(tomb_sprite)

		_tombstone_zones_used[zone] = false
		zone.body_entered.connect(_on_tombstone_zone_entered.bind(zone))
		add_child(zone)


func _on_tombstone_zone_entered(body: Node3D, zone: Area3D) -> void:
	if _tombstone_zones_used.get(zone, true):
		return
	if not body.is_in_group("players") and not (body is CharacterBody3D and body.has_method("take_damage")):
		return
	_tombstone_zones_used[zone] = true

	# Visual feedback: fade out
	var tomb_visual = zone.get_node_or_null("TombVisual")
	if tomb_visual:
		var tw = create_tween()
		tw.tween_property(tomb_visual, "modulate:a", 0.0, 0.5)
		tw.tween_callback(tomb_visual.queue_free)

	# Random buff
	var buff_type = rng.randi_range(0, 2)
	var prev_value: float
	match buff_type:
		0:  # Speed
			prev_value = GameManager.speed_mult
			GameManager.speed_mult *= 1.2
			LogManager.info("Stage", "Tombstone buff: +20%% speed for %.0fs" % TOMBSTONE_BUFF_DURATION)
			get_tree().create_timer(TOMBSTONE_BUFF_DURATION).timeout.connect(func():
				GameManager.speed_mult = prev_value
			)
		1:  # Damage
			prev_value = GameManager.perm_damage_mult
			GameManager.perm_damage_mult *= 1.2
			LogManager.info("Stage", "Tombstone buff: +20%% damage for %.0fs" % TOMBSTONE_BUFF_DURATION)
			get_tree().create_timer(TOMBSTONE_BUFF_DURATION).timeout.connect(func():
				GameManager.perm_damage_mult = prev_value
			)
		2:  # Area
			prev_value = GameManager.area_mult
			GameManager.area_mult *= 1.2
			LogManager.info("Stage", "Tombstone buff: +20%% area for %.0fs" % TOMBSTONE_BUFF_DURATION)
			get_tree().create_timer(TOMBSTONE_BUFF_DURATION).timeout.connect(func():
				GameManager.area_mult = prev_value
			)


func _create_zone_visual(color: Color, zone_size: float) -> Sprite3D:
	var visual = Sprite3D.new()
	visual.name = "ZoneVisual"
	visual.pixel_size = 0.1
	visual.position.y = 0.05
	visual.rotation.x = deg_to_rad(-90)
	visual.modulate = color
	visual.shaded = false
	# Use a placeholder quad via a simple mesh approach — create a PlaceholderTexture2D
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex = ImageTexture.create_from_image(img)
	visual.texture = tex
	# Scale to match zone size (pixel_size 0.1 means 32px * 0.1 = 3.2 units, need zone_size)
	var desired_scale = zone_size / (32 * 0.1)
	visual.scale = Vector3(desired_scale, desired_scale, 1.0)
	return visual
