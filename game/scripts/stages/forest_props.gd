extends Node3D

## Floresta Encantada — pixel art forest with scattered trees, mushrooms,
## bushes, and fairy circles.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"tree1": 8,
	"tree2": 6,
	"mushroom_red": 5,
	"mushroom_cluster": 4,
	"bush": 7,
	"rock": 4,
	"flower": 5,
	"log": 3,
	"fairy_circle": 2,
}


## Stage mechanic: Buff mushrooms — 8 glowing zones, touch = random +20% speed/damage/area for 10s
const MUSHROOM_ZONE_COUNT: int = 8
const MUSHROOM_ZONE_SIZE: float = 3.0
const MUSHROOM_BUFF_DURATION: float = 10.0
var _mushroom_zones_used: Dictionary = {}  # zone -> bool
var _mech_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _anim_time: float = 0.0
var _anim_frame: int = 0
var _animated_props: Array = []


func _process(delta: float) -> void:
	_anim_time += delta
	_anim_frame += 1
	if _anim_frame % 4 != 0:
		return
	if _animated_props.is_empty():
		for child in get_children():
			if child is Sprite3D and (child.name.begins_with("mushroom") or child.name.begins_with("fairy_circle")):
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
		if n.begins_with("mushroom"):
			var pulse = 1.0 + sin(_anim_time * 2.0 + child.position.z) * 0.08
			child.scale = Vector3(pulse, pulse, pulse)
		elif n.begins_with("fairy_circle"):
			child.rotation.y = _anim_time * 0.5 + child.position.x


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
	ground.position.y = 0.02
	ground.name = "TexturedGround"
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


## -------------------------------------------------------
## Mecanica do stage: Buff mushrooms
## 8 zonas brilhantes, ao tocar = +20% speed/damage/area aleatorio por 10s
## Mushrooms respawnam apos 30s
## -------------------------------------------------------
func _create_stage_mechanics() -> void:
	for i in range(MUSHROOM_ZONE_COUNT):
		var zone = Area3D.new()
		zone.name = "MushroomZone_%d" % i
		zone.collision_layer = 0
		zone.collision_mask = 1  # Players

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(MUSHROOM_ZONE_SIZE, 2, MUSHROOM_ZONE_SIZE)
		shape.shape = box
		zone.add_child(shape)

		zone.position = Vector3(
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6),
			0,
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6)
		)

		# Glowing visual
		var visual = _create_zone_visual(Color(0.2, 1.0, 0.4, 0.3), MUSHROOM_ZONE_SIZE)
		zone.add_child(visual)

		_mushroom_zones_used[zone] = false
		zone.body_entered.connect(_on_mushroom_zone_entered.bind(zone))
		add_child(zone)


func _on_mushroom_zone_entered(body: Node3D, zone: Area3D) -> void:
	if _mushroom_zones_used.get(zone, true):
		return
	if not body.is_in_group("players") and not (body is CharacterBody3D and body.has_method("take_damage")):
		return
	_mushroom_zones_used[zone] = true

	# Random buff
	var buff_type = _mech_rng.randi_range(0, 2)
	var prev_value: float
	match buff_type:
		0:  # Speed
			prev_value = GameManager.speed_mult
			GameManager.speed_mult *= 1.2
			LogManager.info("Stage", "Mushroom buff: +20%% speed for %.0fs" % MUSHROOM_BUFF_DURATION)
			get_tree().create_timer(MUSHROOM_BUFF_DURATION).timeout.connect(func():
				GameManager.speed_mult = prev_value
			)
		1:  # Damage
			prev_value = GameManager.perm_damage_mult
			GameManager.perm_damage_mult *= 1.2
			LogManager.info("Stage", "Mushroom buff: +20%% damage for %.0fs" % MUSHROOM_BUFF_DURATION)
			get_tree().create_timer(MUSHROOM_BUFF_DURATION).timeout.connect(func():
				GameManager.perm_damage_mult = prev_value
			)
		2:  # Area
			prev_value = GameManager.area_mult
			GameManager.area_mult *= 1.2
			LogManager.info("Stage", "Mushroom buff: +20%% area for %.0fs" % MUSHROOM_BUFF_DURATION)
			get_tree().create_timer(MUSHROOM_BUFF_DURATION).timeout.connect(func():
				GameManager.area_mult = prev_value
			)

	# Respawn after 30s
	get_tree().create_timer(30.0).timeout.connect(func():
		_mushroom_zones_used[zone] = false
	)


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
