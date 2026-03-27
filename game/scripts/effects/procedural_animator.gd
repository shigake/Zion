extends Node

## Procedural animator: IDLE bob, WALK bob+lean, HIT squash-stretch, DEATH tumble.
## Attach to any node with a child named "ProceduralModel" or a "Mesh" MeshInstance3D.
## Supports .glb models with AnimationPlayer — plays skeleton animations when available.

enum State { IDLE, WALK, HIT, DEATH }

var state: State = State.IDLE
var target_node: Node3D = null
var _time: float = 0.0
var _original_scale: Vector3 = Vector3.ONE
var _hit_active: bool = false
var _death_active: bool = false
var _is_glb_model: bool = false
var _anim_player: AnimationPlayer = null
var _anim_map: Dictionary = {}  # Maps "idle", "walk", "run", "attack" to actual animation names

func setup(node: Node3D) -> void:
	target_node = node
	if target_node:
		_original_scale = target_node.scale
		_is_glb_model = target_node.has_meta("glb_model")
		if _is_glb_model:
			_find_animation_player()
			if _anim_player:
				_play_anim("idle")
			else:
				# No AnimationPlayer found — start a gentle idle bob tween
				_start_idle_bob()

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

func _process(delta: float) -> void:
	if not target_node or not is_instance_valid(target_node):
		return
	if _death_active or _hit_active:
		return

	_time += delta

	if _is_glb_model:
		if _anim_player:
			# GLB models use skeleton animations — only add subtle bob on top
			match state:
				State.IDLE:
					target_node.position.y = sin(_time * 3.0) * 0.01
				State.WALK:
					target_node.position.y = sin(_time * 8.0) * 0.015
		# GLB without AnimationPlayer uses _bob_tween — no extra processing needed
		return

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
