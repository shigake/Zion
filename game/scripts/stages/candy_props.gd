extends Node3D

## Mundo Doce — pink/pastel candy floors with sweet props scattered around.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"candy_cane": 20,
	"lollipop": 18,
	"gummy_bear": 15,
	"cupcake": 12,
	"ice_cream": 10,
	"chocolate": 12,
	"cotton_candy": 10,
	"donut": 12,
	"cookie": 15,
}


## Stage mechanic: Sticky caramel — 8 zones that slow anyone inside by 50%
const CARAMEL_ZONE_COUNT: int = 8
const CARAMEL_ZONE_SIZE: float = 4.0
const CARAMEL_SLOW_FACTOR: float = 0.5  # 50% speed reduction
var _caramel_zones: Array[Area3D] = []
var _anim_time: float = 0.0
var _gummy_base_y: Dictionary = {}
var _player_caramel_count: int = 0
var _prev_speed_mult: float = 1.0
var _slowed_enemies: Dictionary = {}  # enemy -> original_speed
var _mech_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _process(delta: float) -> void:
	_anim_time += delta
	for child in get_children():
		if not child is Sprite3D:
			continue
		var n: String = child.name
		if n.begins_with("lollipop"):
			child.rotation.y = _anim_time * 1.5 + child.position.x
		elif n.begins_with("gummy_bear"):
			var base_y: float = _gummy_base_y.get(child, child.position.y)
			child.position.y = base_y + abs(sin(_anim_time * 3.0 + child.position.z)) * 0.25


func _ready() -> void:
	_mech_rng.randomize()
	_create_ground()
	_scatter_props()
	_cache_gummy_positions()
	_create_stage_mechanics()


func _cache_gummy_positions() -> void:
	for child in get_children():
		if child is Sprite3D and child.name.begins_with("gummy_bear"):
			_gummy_base_y[child] = child.position.y


func _create_ground() -> void:
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(area_size * 2, area_size * 2)
	ground.mesh = plane

	var mat = StandardMaterial3D.new()
	mat.roughness = 1.0

	var ground_tex_path = "res://assets/sprites/props/candy/ground_candy.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		mat.albedo_color = Color(0.35, 0.2, 0.25)

	ground.material_override = mat
	ground.position.y = 0.02
	ground.name = "TexturedGround"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/candy/%s.png" % prop_name
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
			if prop_name == "candy_cane":
				base_y = 1.2
			elif prop_name == "lollipop":
				base_y = 1.3
			elif prop_name == "cotton_candy":
				base_y = 1.1
			elif prop_name == "ice_cream":
				base_y = 1.0
			elif prop_name == "gummy_bear":
				base_y = 0.6
			elif prop_name == "cookie":
				base_y = 0.4
			elif prop_name == "chocolate":
				base_y = 0.4

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)


## -------------------------------------------------------
## Mecanica do stage: Sticky caramel
## 8 zonas pegajosas, -50% velocidade para qualquer corpo dentro
## -------------------------------------------------------
func _create_stage_mechanics() -> void:
	for i in range(CARAMEL_ZONE_COUNT):
		var zone = Area3D.new()
		zone.name = "CaramelZone_%d" % i
		zone.collision_layer = 0
		zone.collision_mask = 1 | 2  # Players + Enemies

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(CARAMEL_ZONE_SIZE, 2, CARAMEL_ZONE_SIZE)
		shape.shape = box
		zone.add_child(shape)

		zone.position = Vector3(
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6),
			0,
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6)
		)

		# Caramel visual: brown/amber sticky zone
		var visual = _create_zone_visual(Color(0.7, 0.45, 0.1, 0.35), CARAMEL_ZONE_SIZE)
		zone.add_child(visual)

		_caramel_zones.append(zone)
		zone.body_entered.connect(_on_caramel_entered.bind(zone))
		zone.body_exited.connect(_on_caramel_exited.bind(zone))
		add_child(zone)


func _on_caramel_entered(body: Node3D, _zone: Area3D) -> void:
	if body.is_in_group("players") or (body is CharacterBody3D and body.has_method("take_damage") and body.get("is_local") != null):
		_player_caramel_count += 1
		if _player_caramel_count == 1:
			_prev_speed_mult = GameManager.speed_mult
			GameManager.speed_mult *= CARAMEL_SLOW_FACTOR
			LogManager.info("Stage", "Player stuck in caramel — -50%% speed")
		return
	# Slow enemies
	if body.is_in_group("enemies") and body.get("speed") != null:
		if not _slowed_enemies.has(body):
			_slowed_enemies[body] = body.speed
			body.speed *= CARAMEL_SLOW_FACTOR


func _on_caramel_exited(body: Node3D, _zone: Area3D) -> void:
	if body.is_in_group("players") or (body is CharacterBody3D and body.has_method("take_damage") and body.get("is_local") != null):
		_player_caramel_count = maxi(0, _player_caramel_count - 1)
		if _player_caramel_count <= 0:
			GameManager.speed_mult = _prev_speed_mult
			LogManager.info("Stage", "Player free from caramel")
		return
	# Restore enemy speed
	if _slowed_enemies.has(body):
		if is_instance_valid(body):
			body.speed = _slowed_enemies[body]
		_slowed_enemies.erase(body)


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
