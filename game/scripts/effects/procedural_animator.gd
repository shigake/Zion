extends Node

## Procedural animator: IDLE bob, WALK bob+lean, HIT squash-stretch, DEATH tumble.
## Attach to any node with a child named "ProceduralModel" or a "Mesh" MeshInstance3D.

enum State { IDLE, WALK, HIT, DEATH }

var state: State = State.IDLE
var target_node: Node3D = null
var _time: float = 0.0
var _original_scale: Vector3 = Vector3.ONE
var _hit_active: bool = false
var _death_active: bool = false

func setup(node: Node3D) -> void:
	target_node = node
	if target_node:
		_original_scale = target_node.scale

func _process(delta: float) -> void:
	if not target_node or not is_instance_valid(target_node):
		return
	if _death_active or _hit_active:
		return

	_time += delta

	match state:
		State.IDLE:
			# Gentle vertical bob
			target_node.position.y = sin(_time * 3.0) * 0.03
			target_node.rotation.z = 0.0
		State.WALK:
			# Faster bob + slight lean
			target_node.position.y = sin(_time * 8.0) * 0.05
			target_node.rotation.z = sin(_time * 8.0) * 0.05

func play_hit() -> void:
	if not target_node or not is_instance_valid(target_node) or _death_active:
		return
	_hit_active = true
	# Squash-stretch: scale 1.2x/0.8y then back
	var tween = target_node.create_tween()
	tween.tween_property(target_node, "scale",
		Vector3(_original_scale.x * 1.2, _original_scale.y * 0.8, _original_scale.z * 1.2), 0.07)
	tween.tween_property(target_node, "scale", _original_scale, 0.08)
	tween.tween_callback(func(): _hit_active = false)

func play_death() -> void:
	if not target_node or not is_instance_valid(target_node):
		return
	_death_active = true
	# Tumble forward + shrink
	var tween = target_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(target_node, "rotation:x", deg_to_rad(90), 0.3)
	tween.tween_property(target_node, "scale", Vector3(0.1, 0.1, 0.1), 0.5)

func set_walking(is_walking: bool) -> void:
	if _death_active or _hit_active:
		return
	state = State.WALK if is_walking else State.IDLE
