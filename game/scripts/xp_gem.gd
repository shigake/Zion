extends Area3D

## Gema de XP 3D. Atraida ao jogador quando proximo.
## Performance: bob every 3 frames, attraction check every 5 (attracted) or 10 (idle).
## Textures preloaded statically to prevent GC sprite corruption.

@export var xp_value: int = 1
@export var attract_speed: float = 15.0
@export var base_attract_range: float = 4.0

## Maximum number of pickups (xp_gems + crystals) allowed at once.
const MAX_PICKUPS := 200

## Preloaded texture - strong static reference prevents GC from unloading
const _XP_TEXTURE := preload("res://assets/sprites/pickups/xp_gem.png")

var being_attracted: bool = false
var attract_target: Node3D = null
var _frame_counter: int = 0

@onready var mesh: MeshInstance3D = $Mesh
var _pickup_sprite: Sprite3D = null

func _ready() -> void:
	add_to_group("xp_gems")
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	# Stagger frame offset so not all gems check on the same frame
	_frame_counter = randi() % 10
	# Apply glow shader to XP gem mesh
	if mesh:
		mesh.material_override = VisualSetup.create_glow_material(Color(0.2, 0.6, 1.0), 3.5)
	# Billboard sprite (hides mesh if sprite texture exists)
	if _XP_TEXTURE:
		if mesh:
			mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = _XP_TEXTURE
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.025
		sprite.shaded = false
		sprite.transparent = true
		sprite.modulate = Color(1.2, 1.2, 1.5)  # Slight blue-white boost
		sprite.name = "PickupSprite"
		add_child(sprite)
		_pickup_sprite = sprite
	# O(1) pickup cap via global counter
	GameManager.active_pickup_count += 1
	if GameManager.active_pickup_count > MAX_PICKUPS:
		_collect()
		return

func _exit_tree() -> void:
	GameManager.active_pickup_count -= 1

func _physics_process(delta: float) -> void:
	if GameManager.paused:
		return

	_frame_counter += 1

	# Bobbing animation - every 3 frames (20fps is visually smooth enough)
	if _frame_counter % 3 == 0:
		var bob = sin(GameManager.game_time * 4.0 + global_position.x) * 0.1
		if _pickup_sprite:
			_pickup_sprite.position.y = bob
		else:
			position.y = 0.3 + bob

	# Attraction check - every 5 frames if being attracted, every 10 if idle (distant)
	if not being_attracted and _frame_counter % 10 == 0:
		var players = GameManager.get_players()
		var range_sq = pow(base_attract_range * GameManager.magnet_mult, 2.0)
		for p in players:
			if is_instance_valid(p) and global_position.distance_squared_to(p.global_position) < range_sq:
				being_attracted = true
				attract_target = p
				break

	# Atrai em direcao ao jogador
	if being_attracted and attract_target and is_instance_valid(attract_target):
		var dir = (attract_target.global_position - global_position).normalized()
		global_position += dir * attract_speed * delta

		if global_position.distance_squared_to(attract_target.global_position) < 0.25:
			_collect()

var _collected := false

func _collect() -> void:
	if _collected or not is_inside_tree():
		return
	_collected = true
	set_physics_process(false)  # Stop immediately - no artifacts during queue_free frame
	ParticleFactory.spawn_collect_particles(global_position, Color(0.2, 0.6, 1.0))
	AudioManager.play_sfx("collect_xp")
	GameManager.add_xp(xp_value)
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		_collect()
