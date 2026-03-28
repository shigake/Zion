extends Node3D

## Estacao Espacial — dark metal floors with sci-fi props scattered around.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"console": 15,
	"crate": 20,
	"pipe": 18,
	"antenna": 8,
	"pod": 10,
	"barrel_toxic": 15,
	"light_panel": 12,
	"debris": 14,
	"portal": 5,
}


## Stage mechanic: Zero-G zones — 6 zones, +50% speed but -30% control (inertia/slide)
const ZEROG_ZONE_COUNT: int = 6
const ZEROG_ZONE_SIZE: float = 6.0
const ZEROG_SPEED_BOOST: float = 1.5
var _zerog_zones: Array[Area3D] = []
var _anim_time: float = 0.0
var _anim_frame: int = 0
var _animated_props: Array = []
var _player_in_zerog: bool = false
var _zerog_count: int = 0  # Track overlapping zones
var _prev_speed_mult: float = 1.0
var _mech_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _process(delta: float) -> void:
	_anim_time += delta
	_anim_frame += 1
	if _anim_frame % 4 != 0:
		return
	if _animated_props.is_empty():
		for child in get_children():
			if child is Sprite3D and (child.name.begins_with("console") or child.name.begins_with("portal")):
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
		if n.begins_with("console"):
			child.modulate.a = 0.6 + sin(_anim_time * 4.0 + child.position.z * 2.0) * 0.4
		elif n.begins_with("portal"):
			child.rotation.y = _anim_time * 1.0 + child.position.x


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

	var ground_tex_path = "res://assets/sprites/props/space/ground_space.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		mat.albedo_color = Color(0.05, 0.03, 0.08)

	ground.material_override = mat
	ground.position.y = 0.02
	ground.name = "TexturedGround"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/space/%s.png" % prop_name
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
			if prop_name == "antenna":
				base_y = 1.5
			elif prop_name == "pipe":
				base_y = 1.2
			elif prop_name == "pod":
				base_y = 1.3
			elif prop_name == "light_panel":
				base_y = 1.8
			elif prop_name == "portal":
				base_y = 1.5
			elif prop_name == "debris":
				base_y = 1.0
			elif prop_name == "barrel_toxic":
				base_y = 0.6

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)


## -------------------------------------------------------
## Mecanica do stage: Zero-G zones
## 6 zonas com gravidade zero: +50% speed, -30% controle (slide effect)
## -------------------------------------------------------
func _create_stage_mechanics() -> void:
	for i in range(ZEROG_ZONE_COUNT):
		var zone = Area3D.new()
		zone.name = "ZeroGZone_%d" % i
		zone.collision_layer = 0
		zone.collision_mask = 1  # Players

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(ZEROG_ZONE_SIZE, 2, ZEROG_ZONE_SIZE)
		shape.shape = box
		zone.add_child(shape)

		zone.position = Vector3(
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6),
			0,
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6)
		)

		# Zero-G visual: purple/blue glow
		var visual = _create_zone_visual(Color(0.5, 0.2, 1.0, 0.25), ZEROG_ZONE_SIZE)
		zone.add_child(visual)

		_zerog_zones.append(zone)
		zone.body_entered.connect(_on_zerog_entered)
		zone.body_exited.connect(_on_zerog_exited)
		add_child(zone)


func _on_zerog_entered(body: Node3D) -> void:
	if not body.is_in_group("players") and not (body is CharacterBody3D and body.has_method("take_damage") and body.get("is_local") != null):
		return
	_zerog_count += 1
	if _zerog_count == 1:
		_prev_speed_mult = GameManager.speed_mult
		GameManager.speed_mult *= ZEROG_SPEED_BOOST
		_player_in_zerog = true
		LogManager.info("Stage", "Entered zero-G zone: +50%% speed, reduced control")


func _on_zerog_exited(body: Node3D) -> void:
	if not body.is_in_group("players") and not (body is CharacterBody3D and body.has_method("take_damage") and body.get("is_local") != null):
		return
	_zerog_count = maxi(0, _zerog_count - 1)
	if _zerog_count <= 0:
		GameManager.speed_mult = _prev_speed_mult
		_player_in_zerog = false
		LogManager.info("Stage", "Left zero-G zone")


func _physics_process(_delta: float) -> void:
	# Apply slide/inertia effect when in zero-G
	if not _player_in_zerog:
		return
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player is CharacterBody3D and player.get("is_local") == true:
			# Add inertia by blending previous velocity (reduces control by 30%)
			var current_vel = player.velocity
			if current_vel.length() > 0.5:
				# Dampen direction changes — keep 30% of previous velocity
				player.velocity = player.velocity.lerp(current_vel, 0.3)


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
