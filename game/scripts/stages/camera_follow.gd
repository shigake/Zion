extends Camera3D

## Camera top-down que segue o jogador com offset fixo.

@export var offset: Vector3 = Vector3(0, 18, 12)
@export var smooth_speed: float = 5.0

var target: Node3D = null

func _ready() -> void:
	# Encontra jogador
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("players")
	if not players.is_empty():
		target = players[0]

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		var target_pos = target.global_position + offset
		global_position = global_position.lerp(target_pos, smooth_speed * delta)
