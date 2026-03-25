extends Node

## Screen shake, flash, slow motion.

var shake_amount: float = 0.0
var shake_decay: float = 8.0
var camera: Camera3D = null

func _ready() -> void:
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()

func _process(delta: float) -> void:
	if shake_amount > 0.01 and camera:
		camera.h_offset = randf_range(-shake_amount, shake_amount)
		camera.v_offset = randf_range(-shake_amount, shake_amount)
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
	elif camera:
		camera.h_offset = 0
		camera.v_offset = 0

func shake(amount: float = 0.15) -> void:
	shake_amount = maxf(shake_amount, amount)

func hit_freeze(duration: float = 0.05) -> void:
	Engine.time_scale = 0.1
	await get_tree().create_timer(duration * 0.1).timeout
	Engine.time_scale = 1.0

func slow_motion(duration: float = 0.5, scale: float = 0.3) -> void:
	Engine.time_scale = scale
	await get_tree().create_timer(duration * scale).timeout
	Engine.time_scale = 1.0
