extends Node

## Screen shake, flash, slow motion, low-HP vignette.

var shake_amount: float = 0.0
var shake_decay: float = 8.0
var camera: Camera3D = null
var _vignette_canvas: CanvasLayer = null
var _vignette_rect: ColorRect = null
var _vignette_visible: bool = false

func _ready() -> void:
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()
	# Create vignette overlay
	_vignette_canvas = CanvasLayer.new()
	_vignette_canvas.layer = 9
	_vignette_rect = ColorRect.new()
	_vignette_rect.anchors_preset = Control.PRESET_FULL_RECT
	_vignette_rect.color = Color(0.5, 0.0, 0.0, 0.0)
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_canvas.add_child(_vignette_rect)
	add_child(_vignette_canvas)

func _process(delta: float) -> void:
	# Re-acquire camera if freed (after scene change)
	if not camera or not is_instance_valid(camera):
		camera = get_viewport().get_camera_3d()
	if shake_amount > 0.01 and camera:
		camera.h_offset = randf_range(-shake_amount, shake_amount)
		camera.v_offset = randf_range(-shake_amount, shake_amount)
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
	elif camera:
		camera.h_offset = 0
		camera.v_offset = 0

	# Low-HP vignette
	_update_vignette()

func _update_vignette() -> void:
	if not _vignette_rect:
		return
	var max_hp = GameManager.get_effective_max_hp()
	if max_hp <= 0:
		return
	var hp_pct = float(GameManager.player_hp) / float(max_hp)
	if hp_pct < 0.4:
		# Pulse intensity based on HP%
		var intensity = (0.4 - hp_pct) / 0.4  # 0 at 40%, 1 at 0%
		var pulse = (sin(GameManager.game_time * 4.0) * 0.5 + 0.5) * 0.15
		_vignette_rect.color.a = intensity * 0.3 + pulse
	else:
		_vignette_rect.color.a = 0.0

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
