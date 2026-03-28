extends Node3D

## Castelo do Vampiro — dark stone floors with gothic props scattered around.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"candelabra": 18,
	"coffin_vampire": 10,
	"pillar": 15,
	"stained_glass": 8,
	"armor_stand": 12,
	"painting": 10,
	"cobweb": 20,
	"gargoyle": 8,
	"throne": 5,
}


## Stage mechanic: Dark zones — 5 zones where enemies deal +30% damage
const DARK_ZONE_COUNT: int = 5
const DARK_ZONE_SIZE: float = 7.0
const DARK_DAMAGE_BONUS: float = 1.3
var _dark_zones: Array[Area3D] = []
var _anim_time: float = 0.0
var _player_in_dark: bool = false
var _dark_zone_count: int = 0
var _mech_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _process(delta: float) -> void:
	_anim_time += delta
	for child in get_children():
		if not child is Sprite3D:
			continue
		var n: String = child.name
		if n.begins_with("candelabra"):
			child.modulate.a = 0.65 + sin(_anim_time * 7.0 + child.position.x * 3.0) * 0.35
		elif n.begins_with("cobweb"):
			child.rotation.z = sin(_anim_time * 1.0 + child.position.z * 0.3) * 0.06


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

	var ground_tex_path = "res://assets/sprites/props/castle/ground_castle.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		mat.albedo_color = Color(0.1, 0.08, 0.08)

	ground.material_override = mat
	ground.position.y = 0.01
	ground.name = "Ground"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/castle/%s.png" % prop_name
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
			if prop_name == "pillar":
				base_y = 1.8
			elif prop_name == "candelabra":
				base_y = 1.2
			elif prop_name == "stained_glass":
				base_y = 1.6
			elif prop_name == "armor_stand":
				base_y = 1.3
			elif prop_name == "gargoyle":
				base_y = 1.0
			elif prop_name == "throne":
				base_y = 1.0
			elif prop_name == "cobweb":
				base_y = 1.8
			elif prop_name == "painting":
				base_y = 1.4

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)


## -------------------------------------------------------
## Mecanica do stage: Dark zones
## 5 zonas escuras onde inimigos causam +30% dano.
## Inimigos que entram recebem buff de dano; ao sair, restaura.
## -------------------------------------------------------
func _create_stage_mechanics() -> void:
	for i in range(DARK_ZONE_COUNT):
		var zone = Area3D.new()
		zone.name = "DarkZone_%d" % i
		zone.collision_layer = 0
		zone.collision_mask = 1 | 2  # Players + Enemies

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(DARK_ZONE_SIZE, 2, DARK_ZONE_SIZE)
		shape.shape = box
		zone.add_child(shape)

		zone.position = Vector3(
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6),
			0,
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6)
		)

		# Dark visual: very dark zone
		var visual = _create_zone_visual(Color(0.1, 0.0, 0.15, 0.5), DARK_ZONE_SIZE)
		zone.add_child(visual)

		_dark_zones.append(zone)
		zone.body_entered.connect(_on_dark_zone_body_entered.bind(zone))
		zone.body_exited.connect(_on_dark_zone_body_exited.bind(zone))
		add_child(zone)


var _buffed_enemies: Dictionary = {}  # enemy -> original_damage

func _on_dark_zone_body_entered(body: Node3D, _zone: Area3D) -> void:
	if body.is_in_group("players") or (body is CharacterBody3D and body.has_method("take_damage") and body.get("is_local") != null):
		_dark_zone_count += 1
		_player_in_dark = true
		LogManager.info("Stage", "Player entered dark zone — enemies deal +30%% damage")
		return
	# Buff enemy damage
	if body.is_in_group("enemies") and body.get("damage") != null:
		if not _buffed_enemies.has(body):
			_buffed_enemies[body] = body.damage
			body.damage = int(body.damage * DARK_DAMAGE_BONUS)


func _on_dark_zone_body_exited(body: Node3D, _zone: Area3D) -> void:
	if body.is_in_group("players") or (body is CharacterBody3D and body.has_method("take_damage") and body.get("is_local") != null):
		_dark_zone_count = maxi(0, _dark_zone_count - 1)
		if _dark_zone_count <= 0:
			_player_in_dark = false
			LogManager.info("Stage", "Player left dark zone")
		return
	# Restore enemy damage
	if _buffed_enemies.has(body):
		if is_instance_valid(body):
			body.damage = _buffed_enemies[body]
		_buffed_enemies.erase(body)


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
