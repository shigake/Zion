extends Area3D

## Gema de XP 3D. Atraida ao jogador quando proximo.
## Performance: bob every 3 frames, attraction check every 5 (attracted) or 10 (idle).
## Textures preloaded statically to prevent GC sprite corruption.

@export var xp_value: int = 1
@export var attract_speed: float = 15.0
@export var base_attract_range: float = 4.0

## Maximum number of pickups (xp_gems + crystals) allowed at once.
const MAX_PICKUPS := 200

## Preloaded 3D model
const _XP_MODEL := preload("res://assets/models/pickups/xp_gem.glb")

var being_attracted: bool = false
var attract_target: Node3D = null
var _frame_counter: int = 0

@onready var mesh: MeshInstance3D = $Mesh
var _model_instance: Node3D = null

func _ready() -> void:
	add_to_group("xp_gems")
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	# Stagger frame offset so not all gems check on the same frame
	_frame_counter = randi() % 10
	# Hide primitive mesh and load 3D model
	if mesh:
		mesh.visible = false
	if _XP_MODEL:
		var model = _XP_MODEL.instantiate()
		model.name = "XPModel"
		model.scale = Vector3(0.15, 0.15, 0.15)
		add_child(model)
		_model_instance = model
		# Apply glow to all mesh nodes in the model tree
		_apply_glow_recursive(model, Color(0.2, 0.6, 1.0), 3.5)

func _apply_glow_recursive(node: Node, color: Color, intensity: float) -> void:
	if node is MeshInstance3D:
		node.material_override = VisualSetup.create_glow_material(color, intensity)
	for child in node.get_children():
		_apply_glow_recursive(child, color, intensity)
	# O(1) pickup cap via global counter
	GameManager.active_pickup_count += 1
	if GameManager.active_pickup_count > MAX_PICKUPS:
		_collect()
		return

func _exit_tree() -> void:
	GameManager.active_pickup_count = maxi(0, GameManager.active_pickup_count - 1)

func _physics_process(delta: float) -> void:
	if GameManager.paused:
		return

	_frame_counter += 1

	# Bobbing + rotation - every 3 frames (20fps is visually smooth enough)
	if _frame_counter % 3 == 0:
		var bob = sin(GameManager.game_time * 4.0 + global_position.x) * 0.1
		if _model_instance:
			_model_instance.position.y = bob
			_model_instance.rotation.y += (1.0 / 20.0) * 3.0
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

## Throttle para coleta em massa (magnetica) — evita 200 SFX/particulas no mesmo frame
static var _collect_sfx_cooldown: float = 0.0
static var _collect_particles_cooldown: float = 0.0

func _collect() -> void:
	if _collected or not is_inside_tree():
		return
	_collected = true
	set_physics_process(false)  # Stop immediately - no artifacts during queue_free frame
	# Throttle: SFX a cada 60ms, particulas a cada 40ms durante coleta em massa
	var now = GameManager.game_time
	if now - _collect_particles_cooldown > 0.04:
		_collect_particles_cooldown = now
		ParticleFactory.spawn_collect_particles(global_position, Color(0.2, 0.6, 1.0))
	if now - _collect_sfx_cooldown > 0.06:
		_collect_sfx_cooldown = now
		AudioManager.play_sfx("collect_xp")
	GameManager.add_xp(xp_value)
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		_collect()
