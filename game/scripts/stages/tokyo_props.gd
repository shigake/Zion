extends Node3D

## Tokyo Cyberpunk — pixel art neon city with signs, vending machines,
## lampposts, and urban props.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"neon_sign1": 12,
	"neon_sign2": 10,
	"vending_machine": 8,
	"lamppost": 15,
	"car": 6,
	"trash_can": 12,
	"manhole": 8,
	"billboard": 5,
	"barrier": 15,
}


## Stage mechanic: Electric panels — 6 zones that deal 5 damage/s to anyone inside
const ELECTRIC_ZONE_COUNT: int = 6
const ELECTRIC_ZONE_SIZE: float = 5.0
const ELECTRIC_DPS: int = 5
const ELECTRIC_TICK_INTERVAL: float = 1.0
var _electric_zones: Array[Area3D] = []
var _electric_tick_timer: float = 0.0
var _anim_time: float = 0.0
var _anim_frame: int = 0
var _animated_props: Array = []
var _mech_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_mech_rng.randomize()
	_create_ground()
	_scatter_props()
	_create_stage_mechanics()


func _create_ground() -> void:
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(area_size * 2, area_size * 2)
	ground.mesh = plane

	var mat = StandardMaterial3D.new()
	mat.roughness = 1.0

	var ground_tex_path = "res://assets/sprites/props/tokyo/ground_tokyo.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		# Fallback: dark gray asphalt if texture not found
		mat.albedo_color = Color(0.1, 0.1, 0.12)

	ground.material_override = mat
	ground.position.y = 0.02
	ground.name = "TexturedGround"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/tokyo/%s.png" % prop_name
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
			if prop_name.begins_with("neon_sign"):
				base_y = 1.4
			elif prop_name == "lamppost":
				base_y = 1.5
			elif prop_name == "billboard":
				base_y = 1.6
			elif prop_name == "vending_machine":
				base_y = 0.9
			elif prop_name == "car":
				base_y = 0.7
			elif prop_name == "trash_can":
				base_y = 0.5
			elif prop_name == "manhole":
				base_y = 0.15
			elif prop_name == "barrier":
				base_y = 0.6

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)


## -------------------------------------------------------
## Mecanica do stage: Electric panels
## 6 zonas eletrificadas, 5 dano/s para qualquer corpo dentro
## -------------------------------------------------------
func _create_stage_mechanics() -> void:
	for i in range(ELECTRIC_ZONE_COUNT):
		var zone = Area3D.new()
		zone.name = "ElectricZone_%d" % i
		zone.collision_layer = 0
		zone.collision_mask = 1 | 2  # Players + Enemies

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(ELECTRIC_ZONE_SIZE, 2, ELECTRIC_ZONE_SIZE)
		shape.shape = box
		zone.add_child(shape)

		zone.position = Vector3(
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6),
			0,
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6)
		)

		# Electric visual: cyan/blue zone
		var visual = _create_zone_visual(Color(0.2, 0.8, 1.0, 0.3), ELECTRIC_ZONE_SIZE)
		zone.add_child(visual)

		_electric_zones.append(zone)
		add_child(zone)


func _process(delta: float) -> void:
	_anim_time += delta
	_anim_frame += 1
	# Prop animations every 4th frame with distance culling
	if _anim_frame % 4 == 0:
		if _animated_props.is_empty():
			for child in get_children():
				if child is Sprite3D and (child.name.begins_with("neon_sign") or child.name.begins_with("vending_machine")):
					_animated_props.append(child)
		var players = GameManager.get_players()
		for child in _animated_props:
			if not is_instance_valid(child):
				continue
			var close_enough = false
			for p in players:
				if is_instance_valid(p) and child.position.distance_squared_to(p.global_position) < 900.0:
					close_enough = true
					break
			if not close_enough:
				continue
			var n: String = child.name
			if n.begins_with("neon_sign"):
				var hue = fmod(_anim_time * 0.3 + child.position.x * 0.1, 1.0)
				child.modulate = Color.from_hsv(hue, 0.8, 1.0)
			elif n.begins_with("vending_machine"):
				child.modulate.a = 0.8 + sin(_anim_time * 8.0 + child.position.z * 3.0) * 0.2

	_electric_tick_timer += delta
	if _electric_tick_timer < ELECTRIC_TICK_INTERVAL:
		return
	_electric_tick_timer -= ELECTRIC_TICK_INTERVAL

	for zone in _electric_zones:
		if not is_instance_valid(zone):
			continue
		var bodies = zone.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("players") or (body is CharacterBody3D and body.has_method("take_damage") and body.get("is_local") != null):
				GameManager.take_damage(ELECTRIC_DPS)
			elif body.has_method("take_damage"):
				body.take_damage(ELECTRIC_DPS, "electric")


func _create_zone_visual(color: Color, zone_size: float) -> Sprite3D:
	var visual = Sprite3D.new()
	visual.name = "ZoneVisual"
	visual.pixel_size = 0.1
	visual.position.y = 0.05
	visual.rotation.x = deg_to_rad(-90)
	visual.modulate = color
	visual.shaded = false
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex = ImageTexture.create_from_image(img)
	visual.texture = tex
	var desired_scale = zone_size / (32 * 0.1)
	visual.scale = Vector3(desired_scale, desired_scale, 1.0)
	return visual
