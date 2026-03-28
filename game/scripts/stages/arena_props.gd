extends Node3D

## Arena Gladiadora — pixel art Roman arena with columns, torches,
## banners, statues, and battle decorations.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"column": 5,
	"broken_column": 4,
	"torch": 6,
	"shield_wall": 3,
	"banner": 5,
	"statue": 2,
	"gate": 2,
	"chain": 5,
	"skull_pike": 3,
}


## Stage mechanic: Crowd throws — every 30s, spawn a random pickup in a random zone
const CROWD_ZONE_COUNT: int = 4
const CROWD_ZONE_SIZE: float = 6.0
const CROWD_THROW_INTERVAL: float = 30.0
var _crowd_zones: Array[Area3D] = []
var _crowd_timer: float = 0.0
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

	var ground_tex_path = "res://assets/sprites/props/arena/ground_arena.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		# Fallback: sandy stone color if texture not found
		mat.albedo_color = Color(0.3, 0.25, 0.15)

	ground.material_override = mat
	ground.position.y = 0.02
	ground.name = "TexturedGround"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/arena/%s.png" % prop_name
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
			if prop_name == "column":
				base_y = 1.5
			elif prop_name == "broken_column":
				base_y = 0.7
			elif prop_name == "torch":
				base_y = 1.2
			elif prop_name == "shield_wall":
				base_y = 0.9
			elif prop_name == "banner":
				base_y = 1.4
			elif prop_name == "statue":
				base_y = 1.6
			elif prop_name == "gate":
				base_y = 1.5
			elif prop_name == "chain":
				base_y = 1.3
			elif prop_name == "skull_pike":
				base_y = 1.1

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)


## -------------------------------------------------------
## Mecanica do stage: Crowd throws
## 4 zonas na arena, a cada 30s a plateia joga um pickup aleatorio
## -------------------------------------------------------
func _create_stage_mechanics() -> void:
	for i in range(CROWD_ZONE_COUNT):
		var zone = Area3D.new()
		zone.name = "CrowdZone_%d" % i
		zone.collision_layer = 0
		zone.collision_mask = 1  # Players

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(CROWD_ZONE_SIZE, 2, CROWD_ZONE_SIZE)
		shape.shape = box
		zone.add_child(shape)

		# Place zones around the edges (crowd sits around the arena)
		var angle = (float(i) / CROWD_ZONE_COUNT) * TAU
		zone.position = Vector3(
			cos(angle) * area_size * 0.5,
			0,
			sin(angle) * area_size * 0.5
		)

		# Arena crowd zone visual: golden zone
		var visual = _create_zone_visual(Color(1.0, 0.85, 0.2, 0.2), CROWD_ZONE_SIZE)
		zone.add_child(visual)

		_crowd_zones.append(zone)
		add_child(zone)


func _process(delta: float) -> void:
	_anim_time += delta
	_anim_frame += 1
	if _anim_frame % 4 == 0:
		if _animated_props.is_empty():
			for child in get_children():
				if child is Sprite3D and (child.name.begins_with("torch") or child.name.begins_with("banner")):
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
			if n.begins_with("torch"):
				child.modulate.a = 0.7 + sin(_anim_time * 7.0 + child.position.x * 2.0) * 0.3
			elif n.begins_with("banner"):
				child.rotation.z = sin(_anim_time * 2.0 + child.position.z * 0.5) * 0.1

	_crowd_timer += delta
	if _crowd_timer < CROWD_THROW_INTERVAL:
		return
	_crowd_timer -= CROWD_THROW_INTERVAL
	_crowd_throw_pickup()


func _crowd_throw_pickup() -> void:
	if _crowd_zones.is_empty():
		return
	var zone = _crowd_zones[_mech_rng.randi_range(0, _crowd_zones.size() - 1)]
	if not is_instance_valid(zone):
		return

	# Random pickup type
	var pickup_type = _mech_rng.randi_range(0, 2)
	var scene_path: String
	match pickup_type:
		0:
			scene_path = "res://scenes/xp_gem.tscn"
		1:
			scene_path = "res://scenes/crystal_pickup.tscn"
		2:
			scene_path = "res://scenes/health_pickup.tscn"

	if not ResourceLoader.exists(scene_path):
		return

	var pickup_scene = load(scene_path)
	var pickup = pickup_scene.instantiate()
	# Spawn at zone center with small random offset
	pickup.global_position = zone.global_position + Vector3(
		_mech_rng.randf_range(-2.0, 2.0),
		0.5,
		_mech_rng.randf_range(-2.0, 2.0)
	)
	get_tree().current_scene.add_child(pickup)
	LogManager.info("Stage", "Arena crowd threw a pickup!")


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
