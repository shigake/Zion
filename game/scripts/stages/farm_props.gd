extends Node3D

## Fazenda do Apocalipse — pixel art farm with hay bales, corn, fences,
## scarecrows, and rustic structures.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"hay_bale": 20,
	"corn": 25,
	"fence": 18,
	"scarecrow": 6,
	"silo": 4,
	"windmill": 3,
	"tractor": 3,
	"barrel": 12,
	"wheat": 20,
}


## Stage mechanic: Cornfield hide — 10 tall zones, player invisible to enemies inside
const CORNFIELD_ZONE_COUNT: int = 10
const CORNFIELD_ZONE_SIZE: float = 5.0
var _players_in_cornfield: int = 0  # Track how many players are in cornfield zones
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

	var ground_tex_path = "res://assets/sprites/props/farm/ground_farm.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		# Fallback: yellow/brown dirt if texture not found
		mat.albedo_color = Color(0.35, 0.3, 0.12)

	ground.material_override = mat
	ground.position.y = 0.01
	ground.name = "Ground"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/farm/%s.png" % prop_name
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
			if prop_name == "corn":
				base_y = 1.2
			elif prop_name == "scarecrow":
				base_y = 1.3
			elif prop_name == "silo":
				base_y = 1.5
			elif prop_name == "windmill":
				base_y = 1.4
			elif prop_name == "tractor":
				base_y = 0.9
			elif prop_name == "fence":
				base_y = 0.7
			elif prop_name == "hay_bale":
				base_y = 0.6
			elif prop_name == "barrel":
				base_y = 0.5
			elif prop_name == "wheat":
				base_y = 0.6

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)


## -------------------------------------------------------
## Mecanica do stage: Cornfield hide
## 10 zonas altas de milharal, jogador fica invisivel para inimigos dentro
## -------------------------------------------------------
func _create_stage_mechanics() -> void:
	for i in range(CORNFIELD_ZONE_COUNT):
		var zone = Area3D.new()
		zone.name = "CornfieldZone_%d" % i
		zone.collision_layer = 0
		zone.collision_mask = 1  # Players

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(CORNFIELD_ZONE_SIZE, 3, CORNFIELD_ZONE_SIZE)
		shape.shape = box
		zone.add_child(shape)

		zone.position = Vector3(
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6),
			0,
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6)
		)

		# Tall corn visual (green/yellow zone)
		var visual = _create_zone_visual(Color(0.4, 0.6, 0.1, 0.25), CORNFIELD_ZONE_SIZE)
		zone.add_child(visual)

		# Tall corn sprites inside the zone for visual density
		for j in range(4):
			var corn = Sprite3D.new()
			corn.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			corn.pixel_size = 0.05
			corn.shaded = false
			corn.transparent = true
			corn.modulate = Color(0.5, 0.7, 0.2, 0.6)
			corn.position = Vector3(
				_mech_rng.randf_range(-CORNFIELD_ZONE_SIZE * 0.3, CORNFIELD_ZONE_SIZE * 0.3),
				1.5,
				_mech_rng.randf_range(-CORNFIELD_ZONE_SIZE * 0.3, CORNFIELD_ZONE_SIZE * 0.3)
			)
			var corn_tex_path = "res://assets/sprites/props/farm/corn.png"
			if ResourceLoader.exists(corn_tex_path):
				corn.texture = load(corn_tex_path)
			zone.add_child(corn)

		zone.body_entered.connect(_on_cornfield_entered)
		zone.body_exited.connect(_on_cornfield_exited)
		add_child(zone)


func _on_cornfield_entered(body: Node3D) -> void:
	if not body.is_in_group("players") and not (body is CharacterBody3D and body.has_method("take_damage")):
		return
	_players_in_cornfield += 1
	if _players_in_cornfield > 0:
		GameManager.player_hidden = true
		LogManager.info("Stage", "Player hidden in cornfield")


func _on_cornfield_exited(body: Node3D) -> void:
	if not body.is_in_group("players") and not (body is CharacterBody3D and body.has_method("take_damage")):
		return
	_players_in_cornfield = maxi(0, _players_in_cornfield - 1)
	if _players_in_cornfield <= 0:
		GameManager.player_hidden = false
		LogManager.info("Stage", "Player visible again")


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
