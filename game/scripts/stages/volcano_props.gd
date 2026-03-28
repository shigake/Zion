extends Node3D

## Vulcao Infernal — pixel art volcanic landscape with scattered lava rocks,
## obsidian crystals, fire geysers, and bone piles.

@export var area_size: float = 80.0

# Prop definitions: name -> count
var _prop_defs: Dictionary = {
	"lava_rock": 8,
	"obsidian": 5,
	"fire_geyser": 3,
	"skull_rock": 2,
	"magma_pool": 3,
	"dead_bush": 5,
	"bone_pile": 3,
	"crystal_red": 4,
	"volcanic_vent": 3,
}


## Stage mechanic: Lava pools — 8 zones that deal 10 damage/s fire, fire enemies immune
const LAVA_ZONE_COUNT: int = 8
const LAVA_ZONE_SIZE: float = 4.5
const LAVA_DPS: int = 10
const LAVA_TICK_INTERVAL: float = 1.0
var _lava_zones: Array[Area3D] = []
var _lava_tick_timer: float = 0.0
var _anim_time: float = 0.0
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

	var ground_tex_path = "res://assets/sprites/props/volcano/ground_volcano.png"
	if ResourceLoader.exists(ground_tex_path):
		var tex = load(ground_tex_path)
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.uv1_scale = Vector3(20, 20, 1)
	else:
		# Fallback: dark volcanic color if texture not found
		mat.albedo_color = Color(0.2, 0.08, 0.03)

	ground.material_override = mat
	ground.position.y = 0.02
	ground.name = "TexturedGround"
	add_child(ground)


func _scatter_props() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for prop_name in _prop_defs:
		var count: int = _prop_defs[prop_name]
		var sprite_path = "res://assets/sprites/props/volcano/%s.png" % prop_name
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
			if prop_name == "fire_geyser":
				base_y = 1.2
			elif prop_name == "obsidian":
				base_y = 1.3
			elif prop_name == "crystal_red":
				base_y = 1.1
			elif prop_name == "skull_rock":
				base_y = 1.0
			elif prop_name == "magma_pool":
				base_y = 0.3
			elif prop_name == "dead_bush":
				base_y = 0.7
			elif prop_name == "bone_pile":
				base_y = 0.5
			elif prop_name == "volcanic_vent":
				base_y = 0.6

			sprite.position = Vector3(x, base_y, z)
			sprite.name = "%s_%d" % [prop_name, i]
			add_child(sprite)


## -------------------------------------------------------
## Mecanica do stage: Lava pools
## 8 zonas de lava, 10 dano/s fogo. Inimigos de fogo sao imunes.
## -------------------------------------------------------
func _create_stage_mechanics() -> void:
	for i in range(LAVA_ZONE_COUNT):
		var zone = Area3D.new()
		zone.name = "LavaZone_%d" % i
		zone.collision_layer = 0
		zone.collision_mask = 1 | 2  # Players + Enemies

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(LAVA_ZONE_SIZE, 2, LAVA_ZONE_SIZE)
		shape.shape = box
		zone.add_child(shape)

		zone.position = Vector3(
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6),
			0,
			_mech_rng.randf_range(-area_size * 0.6, area_size * 0.6)
		)

		# Lava visual: orange/red zone
		var visual = _create_zone_visual(Color(1.0, 0.3, 0.0, 0.4), LAVA_ZONE_SIZE)
		zone.add_child(visual)

		_lava_zones.append(zone)
		add_child(zone)


var _anim_frame: int = 0
var _animated_props: Array = []

func _process(delta: float) -> void:
	_anim_time += delta
	_anim_frame += 1
	if _anim_frame % 4 == 0:
		if _animated_props.is_empty():
			for child in get_children():
				if child is Sprite3D and (child.name.begins_with("fire_geyser") or child.name.begins_with("magma_pool")):
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
			if n.begins_with("fire_geyser"):
				var pulse = 1.0 + sin(_anim_time * 5.0 + child.position.x * 2.0) * 0.15
				child.scale = Vector3(pulse, pulse, pulse)
			elif n.begins_with("magma_pool"):
				var t = sin(_anim_time * 2.0 + child.position.z) * 0.5 + 0.5
				child.modulate = Color(1.0, 0.3 + t * 0.4, 0.0 + t * 0.1, 0.8 + t * 0.2)

	_lava_tick_timer += delta
	if _lava_tick_timer < LAVA_TICK_INTERVAL:
		return
	_lava_tick_timer -= LAVA_TICK_INTERVAL

	for zone in _lava_zones:
		if not is_instance_valid(zone):
			continue
		var bodies = zone.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("players") or (body is CharacterBody3D and body.has_method("take_damage") and body.get("is_local") != null):
				GameManager.take_damage(LAVA_DPS)
			elif body.has_method("take_damage"):
				# Fire enemies are immune (check resistance)
				var resistances = body.get("resistances")
				if resistances is Dictionary and resistances.get("fire", 1.0) < 0.5:
					continue  # Fire-resistant enemy, skip
				body.take_damage(LAVA_DPS, "fire")


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
