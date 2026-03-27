extends Area3D

## Cristal (moeda) que dropa dos inimigos. Coletado pelo jogador.
## Performance: no per-crystal GPUParticles3D. Attraction check every 5 frames.

@export var crystal_value: int = 1
@export var attract_speed: float = 12.0
@export var base_attract_range: float = 3.0

## Maximum number of pickups (xp_gems + crystals) allowed at once.
const MAX_PICKUPS := 200

var being_attracted: bool = false
var attract_target: Node3D = null
var _frame_counter: int = 0

@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	add_to_group("crystals")
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	# Stagger frame offset so not all crystals check on the same frame
	_frame_counter = randi() % 5
	# Apply glow shader to crystal mesh (the glow replaces per-crystal particles)
	if mesh:
		mesh.material_override = VisualSetup.create_glow_material(Color(1.0, 0.85, 0.2), 2.5)
	# Enforce pickup cap — auto-collect oldest if over limit
	_enforce_pickup_cap()

func _enforce_pickup_cap() -> void:
	var all_pickups = get_tree().get_nodes_in_group("pickups")
	if all_pickups.size() > MAX_PICKUPS:
		var excess = all_pickups.size() - MAX_PICKUPS
		for i in range(excess):
			var old_pickup = all_pickups[i]
			if old_pickup != self and is_instance_valid(old_pickup) and old_pickup.has_method("_collect"):
				old_pickup._collect()

func _physics_process(delta: float) -> void:
	if GameManager.paused:
		return

	# Bobbing e rotacao — runs every frame for smooth visuals
	var bob = sin(GameManager.game_time * 3.0 + global_position.z) * 0.08
	position.y = 0.4 + bob
	if mesh:
		mesh.rotation.y += delta * 3.0

	# Attraction check — only every 5 physics frames for performance
	_frame_counter += 1
	if not being_attracted and _frame_counter % 5 == 0:
		var players = get_tree().get_nodes_in_group("players")
		var range_sq = (base_attract_range * GameManager.magnet_mult) ** 2
		for p in players:
			if is_instance_valid(p) and global_position.distance_squared_to(p.global_position) < range_sq:
				being_attracted = true
				attract_target = p
				break

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
	AudioManager.play_sfx("collect_crystal")
	ParticleFactory.spawn_collect_particles(global_position, Color(0.7, 0.3, 0.9))
	GameManager.crystals_this_run += crystal_value
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		_collect()
