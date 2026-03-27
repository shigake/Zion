extends Node

## Procedural animator: IDLE bob, WALK bob+lean, HIT squash-stretch, DEATH tumble.
## Attach to any node with a child named "ProceduralModel" or a "Mesh" MeshInstance3D.
## Supports .glb models with AnimationPlayer — plays skeleton animations when available.

enum State { IDLE, WALK, HIT, DEATH }

var state: State = State.IDLE
var target_node: Node3D = null
var _time: float = 0.0
var _original_scale: Vector3 = Vector3.ONE
var _original_y: float = 0.0
var _hit_active: bool = false
var _death_active: bool = false
var _is_glb_model: bool = false
var _anim_player: AnimationPlayer = null
var _anim_map: Dictionary = {}  # Maps "idle", "walk", "run", "attack" to actual animation names
var _move_dir: Vector3 = Vector3.ZERO  # Current movement direction for rotation
var _skeleton: Skeleton3D = null
var _bone_ids: Dictionary = {}  # bone name -> bone index
var _bone_rest: Dictionary = {}  # bone index -> rest Transform3D

func setup(node: Node3D) -> void:
	target_node = node
	if target_node:
		_original_scale = target_node.scale
		_original_y = target_node.position.y
		_is_glb_model = target_node.has_meta("glb_model")
		if _is_glb_model:
			_find_skeleton()
			_find_animation_player()
			if _anim_player:
				_play_anim("idle")
			else:
				_start_idle_bob()

func _find_skeleton() -> void:
	## Find the Skeleton3D in the model and cache bone indices for procedural animation.
	if not target_node:
		return
	_skeleton = _find_child_by_type(target_node, "Skeleton3D") as Skeleton3D
	if not _skeleton:
		return
	# Cache bone indices by common names (KayKit uses: upperarm.l, lowerarm.l, etc)
	var bone_names_to_find := [
		"upperarm.l", "upperarm.r", "lowerarm.l", "lowerarm.r",
		"upperleg.l", "upperleg.r", "lowerleg.l", "lowerleg.r",
		"hips", "spine", "chest", "head",
	]
	for i in range(_skeleton.get_bone_count()):
		var bn = _skeleton.get_bone_name(i)
		if bn in bone_names_to_find:
			_bone_ids[bn] = i
			_bone_rest[i] = _skeleton.get_bone_rest(i)
	# Set arms down in rest pose (T-pose -> natural arms-down)
	_set_arms_down()

func _set_arms_down() -> void:
	## Rotate upper arms down from T-pose to a natural resting position.
	if not _skeleton:
		return
	if "upperarm.l" in _bone_ids:
		var idx = _bone_ids["upperarm.l"]
		var rest = _bone_rest[idx]
		_skeleton.set_bone_pose_rotation(idx, rest.basis.get_rotation_quaternion() * Quaternion(Vector3.FORWARD, deg_to_rad(70)))
	if "upperarm.r" in _bone_ids:
		var idx = _bone_ids["upperarm.r"]
		var rest = _bone_rest[idx]
		_skeleton.set_bone_pose_rotation(idx, rest.basis.get_rotation_quaternion() * Quaternion(Vector3.FORWARD, deg_to_rad(-70)))
	# Slight bend in lower arms
	if "lowerarm.l" in _bone_ids:
		var idx = _bone_ids["lowerarm.l"]
		var rest = _bone_rest[idx]
		_skeleton.set_bone_pose_rotation(idx, rest.basis.get_rotation_quaternion() * Quaternion(Vector3.RIGHT, deg_to_rad(15)))
	if "lowerarm.r" in _bone_ids:
		var idx = _bone_ids["lowerarm.r"]
		var rest = _bone_rest[idx]
		_skeleton.set_bone_pose_rotation(idx, rest.basis.get_rotation_quaternion() * Quaternion(Vector3.RIGHT, deg_to_rad(15)))

func _animate_skeleton(delta: float) -> void:
	## Procedurally animate skeleton bones for walk/idle.
	if not _skeleton or _bone_ids.is_empty():
		return
	match state:
		State.IDLE:
			# Subtle arm sway
			var sway = sin(_time * 2.0) * deg_to_rad(3)
			_rotate_bone("upperarm.l", Vector3.FORWARD, 70 + rad_to_deg(sway))
			_rotate_bone("upperarm.r", Vector3.FORWARD, -70 - rad_to_deg(sway))
		State.WALK:
			# Arm swing (opposite to legs)
			var swing = sin(_time * 10.0)
			var arm_angle = swing * 30.0  # degrees of swing
			_rotate_bone("upperarm.l", Vector3.FORWARD, 70 + arm_angle)
			_rotate_bone("upperarm.r", Vector3.FORWARD, -70 - arm_angle)
			# Lower arm follows with slight delay
			var lower_swing = sin(_time * 10.0 - 0.5) * 15.0
			_rotate_bone("lowerarm.l", Vector3.RIGHT, 15 + maxf(0, lower_swing))
			_rotate_bone("lowerarm.r", Vector3.RIGHT, 15 + maxf(0, -lower_swing))
			# Leg swing
			_rotate_bone("upperleg.l", Vector3.RIGHT, swing * 25.0)
			_rotate_bone("upperleg.r", Vector3.RIGHT, -swing * 25.0)
			_rotate_bone("lowerleg.l", Vector3.RIGHT, maxf(0, -swing) * 30.0)
			_rotate_bone("lowerleg.r", Vector3.RIGHT, maxf(0, swing) * 30.0)
			# Torso twist
			_rotate_bone("spine", Vector3.UP, swing * 5.0)

func _rotate_bone(bone_name: String, axis: Vector3, degrees: float) -> void:
	if bone_name not in _bone_ids:
		return
	var idx = _bone_ids[bone_name]
	var rest = _bone_rest[idx]
	_skeleton.set_bone_pose_rotation(idx, rest.basis.get_rotation_quaternion() * Quaternion(axis, deg_to_rad(degrees)))

func _find_animation_player() -> void:
	## Searches the model tree for an AnimationPlayer and maps common animation names.
	if not target_node:
		return
	# Search recursively for AnimationPlayer
	_anim_player = _find_child_by_type(target_node, "AnimationPlayer") as AnimationPlayer
	if not _anim_player:
		return
	# Build animation name map (case-insensitive matching)
	var anim_list = _anim_player.get_animation_list()
	for anim_name in anim_list:
		var lower = anim_name.to_lower()
		if "idle" in lower and "idle" not in _anim_map:
			_anim_map["idle"] = anim_name
		elif "walk" in lower and "walk" not in _anim_map:
			_anim_map["walk"] = anim_name
		elif "run" in lower and "run" not in _anim_map:
			_anim_map["run"] = anim_name
		elif ("attack" in lower or "slash" in lower or "swing" in lower) and "attack" not in _anim_map:
			_anim_map["attack"] = anim_name
		elif "death" in lower or "die" in lower:
			if "death" not in _anim_map:
				_anim_map["death"] = anim_name
		elif "hit" in lower or "damage" in lower or "hurt" in lower:
			if "hit" not in _anim_map:
				_anim_map["hit"] = anim_name
	# If no idle found, use first animation as fallback
	if "idle" not in _anim_map and anim_list.size() > 0:
		_anim_map["idle"] = anim_list[0]

var _bob_tween: Tween = null

func _start_idle_bob() -> void:
	## GLB model without AnimationPlayer — use a looping bob tween for idle feel
	if not target_node or not is_instance_valid(target_node):
		return
	_bob_tween = target_node.create_tween().set_loops()
	_bob_tween.tween_property(target_node, "position:y", 0.06, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bob_tween.tween_property(target_node, "position:y", 0.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _find_child_by_type(node: Node, type_name: String) -> Node:
	## Recursively finds the first child node of the given type.
	for child in node.get_children():
		if child.get_class() == type_name:
			return child
		var found = _find_child_by_type(child, type_name)
		if found:
			return found
	return null

func _play_anim(action: String) -> void:
	## Plays the animation mapped to the given action, if available.
	if not _anim_player or not is_instance_valid(_anim_player):
		return
	var anim_name = _anim_map.get(action, "")
	if anim_name == "" or anim_name == null:
		return
	if _anim_player.current_animation == anim_name:
		return
	_anim_player.play(anim_name)

func set_move_direction(dir: Vector3) -> void:
	_move_dir = dir

func _process(delta: float) -> void:
	if not target_node or not is_instance_valid(target_node):
		return
	if _death_active or _hit_active:
		return

	_time += delta

	if _is_glb_model:
		match state:
			State.IDLE:
				target_node.position.y = _original_y + sin(_time * 3.0) * 0.01
			State.WALK:
				target_node.position.y = _original_y + abs(sin(_time * 10.0)) * 0.02
		# Animate skeleton bones (arms, legs, torso)
		_animate_skeleton(delta)
		# Rotate GLB model to face movement direction
		if state == State.WALK and _move_dir.length() > 0.1:
			var target_angle = atan2(_move_dir.x, _move_dir.z)
			target_node.rotation.y = lerp_angle(target_node.rotation.y, target_angle, delta * 12.0)
		return

	match state:
		State.IDLE:
			# Gentle breathing: vertical bob + subtle scale pulse
			var breath = sin(_time * 3.0)
			target_node.position.y = _original_y + breath * 0.03
			target_node.scale = _original_scale * (1.0 + breath * 0.01)
			target_node.rotation.x = lerp(target_node.rotation.x, 0.0, delta * 8.0)
			target_node.rotation.z = lerp(target_node.rotation.z, 0.0, delta * 8.0)
		State.WALK:
			# Energetic walk: faster bob + lean into movement + arm swing
			var walk_cycle = sin(_time * 10.0)
			target_node.position.y = _original_y + abs(walk_cycle) * 0.07
			# Lean forward slightly
			target_node.rotation.x = lerp(target_node.rotation.x, deg_to_rad(-8.0), delta * 6.0)
			# Side-to-side sway
			target_node.rotation.z = walk_cycle * 0.08
			# Squash on landing, stretch on jump
			var squash = 1.0 - abs(walk_cycle) * 0.04
			target_node.scale = Vector3(
				_original_scale.x * (1.0 + abs(walk_cycle) * 0.03),
				_original_scale.y * squash,
				_original_scale.z
			)
			# Rotate to face movement direction
			if _move_dir.length() > 0.1:
				var target_angle = atan2(_move_dir.x, _move_dir.z)
				target_node.rotation.y = lerp_angle(target_node.rotation.y, target_angle, delta * 12.0)

func play_hit() -> void:
	if not target_node or not is_instance_valid(target_node) or _death_active:
		return
	_hit_active = true
	# GLB models: play hit animation if available, otherwise squash-stretch
	if _is_glb_model and _anim_player and "hit" in _anim_map:
		_play_anim("hit")
		var duration = _anim_player.get_animation(_anim_map["hit"]).length
		var tween = target_node.create_tween()
		tween.tween_callback(func():
			_hit_active = false
			# Resume previous animation
			if state == State.WALK:
				_play_anim("walk")
			else:
				_play_anim("idle")
		).set_delay(duration)
		return
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
	# GLB models: play death animation if available
	if _is_glb_model and _anim_player and "death" in _anim_map:
		_play_anim("death")
		# Also shrink as visual feedback
		var tween = target_node.create_tween()
		tween.tween_property(target_node, "scale", Vector3(0.1, 0.1, 0.1), 0.5).set_delay(0.3)
		return
	# Tumble forward + shrink
	var tween = target_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(target_node, "rotation:x", deg_to_rad(90), 0.3)
	tween.tween_property(target_node, "scale", Vector3(0.1, 0.1, 0.1), 0.5)

func set_walking(is_walking: bool) -> void:
	if _death_active or _hit_active:
		return
	var prev_state = state
	state = State.WALK if is_walking else State.IDLE
	# GLB models: switch skeleton animation when state changes
	if _is_glb_model and _anim_player and state != prev_state:
		if is_walking:
			# Prefer walk, fallback to run
			if "walk" in _anim_map:
				_play_anim("walk")
			elif "run" in _anim_map:
				_play_anim("run")
		else:
			_play_anim("idle")
