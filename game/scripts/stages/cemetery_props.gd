extends Node3D

## Cemiterio — pixel art cemetery with scattered tombstones, dead trees,
## ground fog, and eerie lighting.

@export var area_size: float = 80.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"tombstone1": 20,
	"tombstone2": 15,
	"tombstone3": 10,
	"dead_tree1": 8,
	"dead_tree2": 8,
	"iron_fence": 10,
	"cross": 8,
	"skull_pile": 5,
	"lantern": 4,
	"pumpkin": 3,
	"mushroom": 5,
}


## Stage mechanic: Destructible tombstones — 5 zones that drop a random buff on first touch
const TOMBSTONE_ZONE_COUNT: int = 5
const TOMBSTONE_ZONE_SIZE: float = 4.0
const TOMBSTONE_BUFF_DURATION: float = 10.0
var _tombstone_zones_used: Dictionary = {}  # zone -> bool (already triggered)
var _anim_time: float = 0.0
var _anim_frame: int = 0
var _animated_props: Array = []  # Cached list of props that need animation


func _process(delta: float) -> void:
	_anim_time += delta
	_anim_frame += 1
	# Ambient wind disabled — SFX too repetitive
	if _anim_frame % 4 != 0:
		return  # Only animate every 4th frame
	# Cache animated props on first pass
	if _animated_props.is_empty():
		for child in get_children():
			if child is Sprite3D and (child.name.begins_with("lantern") or child.name.begins_with("pumpkin")):
				_animated_props.append(child)
	# Animate only nearby props (within 30 units of any player)
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
		if n.begins_with("lantern"):
			child.modulate.a = 0.7 + sin(_anim_time * 6.0 + child.position.x) * 0.3
		elif n.begins_with("pumpkin"):
			var glow = 0.8 + sin(_anim_time * 3.0 + child.position.z) * 0.2
			child.modulate = Color(1.0, 0.6 * glow, 0.1, glow)


func _ready() -> void:
	rng.randomize()
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
	var tex_path = "res://assets/sprites/props/cemetery/ground_cemetery.png"
	if ResourceLoader.exists(tex_path):
		mat.albedo_texture = load(tex_path)
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		mat.albedo_color = Color(0.12, 0.15, 0.08)
	ground.material_override = mat
	ground.position.y = 0.02
	ground.name = "TexturedGround"
	add_child(ground)


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
