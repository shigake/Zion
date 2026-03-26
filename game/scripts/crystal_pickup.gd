extends Area3D

## Cristal (moeda) que dropa dos inimigos. Coletado pelo jogador.

@export var crystal_value: int = 1
@export var attract_speed: float = 12.0
@export var base_attract_range: float = 3.0

var being_attracted: bool = false
var attract_target: Node3D = null

@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	add_to_group("crystals")
	body_entered.connect(_on_body_entered)
	# Apply glow shader to crystal mesh
	if mesh:
		mesh.material_override = VisualSetup.create_glow_material(Color(1.0, 0.85, 0.2), 2.5)

func _physics_process(delta: float) -> void:
	if GameManager.paused:
		return

	# Bobbing e rotacao
	var bob = sin(GameManager.game_time * 3.0 + global_position.z) * 0.08
	position.y = 0.4 + bob
	if mesh:
		mesh.rotation.y += delta * 3.0

	if not being_attracted:
		var players = get_tree().get_nodes_in_group("players")
		for p in players:
			var range_val = base_attract_range * GameManager.magnet_mult
			if is_instance_valid(p) and global_position.distance_to(p.global_position) < range_val:
				being_attracted = true
				attract_target = p
				break

	if being_attracted and attract_target and is_instance_valid(attract_target):
		var dir = (attract_target.global_position - global_position).normalized()
		global_position += dir * attract_speed * delta
		if global_position.distance_to(attract_target.global_position) < 0.5:
			_collect()

func _collect() -> void:
	AudioManager.play_sfx("collect_crystal")
	ParticleFactory.spawn_collect_particles(global_position, Color(1.0, 0.85, 0.2))
	GameManager.crystals_this_run += crystal_value
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		_collect()
