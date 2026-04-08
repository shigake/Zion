extends Camera3D

## Camera top-down que segue o jogador com offset fixo + look-ahead.

@export var offset: Vector3 = Vector3(0, 16, 14)
@export var smooth_speed: float = 5.0
@export var look_ahead_strength: float = 0.3

var target: Node3D = null

func _ready() -> void:
	# Mantém FOV vertical fixo independente do aspect ratio da janela (PRD-29)
	keep_aspect = Camera3D.KEEP_HEIGHT
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
		# Clamp look-ahead target to map boundaries (prevents showing off-map)
		var base_pos = target.global_position + look_ahead
		var half = GameManager.map_half_size
		base_pos.x = clampf(base_pos.x, -half, half)
		base_pos.z = clampf(base_pos.z, -half, half)
		var target_pos = base_pos + offset
		global_position = global_position.lerp(target_pos, smooth_speed * delta)
