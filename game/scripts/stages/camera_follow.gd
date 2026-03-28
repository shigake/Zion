extends Camera3D

## Camera top-down que segue o jogador com offset fixo + look-ahead.

@export var offset: Vector3 = Vector3(0, 18, 12)
@export var smooth_speed: float = 5.0
@export var look_ahead_strength: float = 0.3

var target: Node3D = null

func _ready() -> void:
	# Encontra jogador
	await get_tree().process_frame
	var players = GameManager.get_players()
	if not players.is_empty():
		target = players[0]

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		# Look-ahead: camera antecipa na direcao do movimento
		var look_ahead = Vector3.ZERO
		if target is CharacterBody3D:
			var vel = target.velocity
			look_ahead = Vector3(vel.x, 0, vel.z) * look_ahead_strength
		var target_pos = target.global_position + offset + look_ahead
		global_position = global_position.lerp(target_pos, smooth_speed * delta)
