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


## Stage mechanic: Water currents — 4 large zones that push all bodies in a direction
const CURRENT_ZONE_COUNT: int = 4
const CURRENT_ZONE_SIZE: float = 12.0
const CURRENT_PUSH_FORCE: float = 4.0
var _current_zones: Array[Dictionary] = []  # {zone: Area3D, direction: Vector3}
var _mech_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _anim_time: float = 0.0
var _anim_frame: int = 0
var _animated_props: Array = []
var _jellyfish_base_y: Dictionary = {}


func _process(delta: float) -> void:
	_anim_time += delta
	_anim_frame += 1
	if _anim_frame % 4 != 0:
		return
	if _animated_props.is_empty():
		for child in get_children():
			if child is Sprite3D and (child.name.begins_with("seaweed") or child.name.begins_with("jellyfish")):
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
		if n.begins_with("seaweed"):
			child.rotation.z = sin(_anim_time * 1.8 + child.position.x * 0.4) * 0.15
		elif n.begins_with("jellyfish"):
			var base_y: float = _jellyfish_base_y.get(child, child.position.y)
			child.position.y = base_y + sin(_anim_time * 1.2 + child.position.x) * 0.3


func _ready() -> void:
	_mech_rng.randomize()
	_create_ground()
	_scatter_props()
	_cache_jellyfish_positions()
	_create_stage_mechanics()


func _cache_jellyfish_positions() -> void:
	for child in get_children():
		if child is Sprite3D and child.name.begins_with("jellyfish"):
			_jellyfish_base_y[child] = child.position.y


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
	ground.position.y = 0.02
	ground.name = "TexturedGround"
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


## -------------------------------------------------------
## Mecanica do stage: Water currents
## 4 zonas grandes que empurram todos os corpos em uma direcao
## -------------------------------------------------------
func _create_stage_mechanics() -> void:
	var directions = [
		Vector3(1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, -1),
	]
	for i in range(CURRENT_ZONE_COUNT):
		var zone = Area3D.new()
		zone.name = "CurrentZone_%d" % i
		zone.collision_layer = 0
		zone.collision_mask = 1 | 2  # Players + Enemies

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(CURRENT_ZONE_SIZE, 2, CURRENT_ZONE_SIZE)
		shape.shape = box
		zone.add_child(shape)

		zone.position = Vector3(
			_mech_rng.randf_range(-area_size * 0.5, area_size * 0.5),
			0,
			_mech_rng.randf_range(-area_size * 0.5, area_size * 0.5)
		)

		# Water current visual: blue translucent zone
		var visual = _create_zone_visual(Color(0.1, 0.4, 0.9, 0.25), CURRENT_ZONE_SIZE)
		zone.add_child(visual)

		# Direction arrow indicator (rotated sprite)
		var arrow = Sprite3D.new()
		arrow.name = "ArrowIndicator"
		arrow.pixel_size = 0.15
		arrow.position.y = 0.1
		arrow.rotation.x = deg_to_rad(-90)
		arrow.modulate = Color(0.3, 0.6, 1.0, 0.5)
		arrow.shaded = false
		# Arrow points in the current direction — rotate around Y
		var dir = directions[i % directions.size()]
		arrow.rotation.z = atan2(dir.x, dir.z)
		zone.add_child(arrow)

		_current_zones.append({"zone": zone, "direction": dir})
		add_child(zone)


func _physics_process(delta: float) -> void:
	for entry in _current_zones:
		var zone: Area3D = entry["zone"]
		var dir: Vector3 = entry["direction"]
		if not is_instance_valid(zone):
			continue
		var bodies = zone.get_overlapping_bodies()
		for body in bodies:
			if body is CharacterBody3D:
				body.velocity += dir * CURRENT_PUSH_FORCE * delta * 60.0


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
