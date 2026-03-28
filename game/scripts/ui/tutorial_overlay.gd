extends CanvasLayer

## Interactive tutorial overlay for first run (PRD C1).
## Shows step-by-step guidance with conditions, dark overlay, and skip button.
## Only displays if SaveManager.data["tutorial_completed"] == false.

# ---- Nodes (built in _ready, no scene dependencies) ----
var _overlay: ColorRect = null
var _label: Label = null
var _skip_btn: Button = null

# ---- State ----
var tutorial_active: bool = false
var current_step: int = -1
var _start_position: Vector3 = Vector3.ZERO
var _xp_at_step_start: int = 0
var _gems_collected: int = 0
var _player_ref: WeakRef = WeakRef.new()
var _level_up_connected: bool = false
var _enemy_kill_connected: bool = false

# Steps: each has an id, locale key, and condition type
const STEPS: Array = [
	{"id": "move", "key_pt": "Use WASD para mover", "key_en": "Use WASD to move", "condition": "move_distance"},
	{"id": "auto_attack", "key_pt": "Sua arma ataca automaticamente!", "key_en": "Your weapon attacks automatically!", "condition": "enemy_killed"},
	{"id": "collect_xp", "key_pt": "Colete as gemas azuis de XP!", "key_en": "Collect the blue XP gems!", "condition": "collect_xp"},
	{"id": "level_up", "key_pt": "Escolha um upgrade!", "key_en": "Choose an upgrade!", "condition": "level_up_choice"},
	{"id": "dash", "key_pt": "Use ESPACO para dar dash!", "key_en": "Use SPACE to dash!", "condition": "dash"},
]


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Check if tutorial already completed (support both old and new key)
	if SaveManager.data.get("tutorial_completed", false) or SaveManager.data.get("tutorial_complete", false):
		set_process(false)
		queue_free()
		return

	_build_ui()
	_overlay.visible = false
	_label.visible = false
	_skip_btn.visible = false

	# Start tutorial after a short delay (let scene load)
	var t = get_tree().create_timer(1.0, false, true)
	t.timeout.connect(_start_tutorial)


func _build_ui() -> void:
	# Dark overlay
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.color = Color(0, 0, 0, 0.3)
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# Center label
	_label = Label.new()
	_label.name = "InstructionLabel"
	_label.anchors_preset = Control.PRESET_CENTER
	_label.anchor_left = 0.5
	_label.anchor_top = 0.4
	_label.anchor_right = 0.5
	_label.anchor_bottom = 0.4
	_label.offset_left = -400
	_label.offset_right = 400
	_label.offset_top = -40
	_label.offset_bottom = 40
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)

	# Skip button (bottom-right corner, small, gray)
	_skip_btn = Button.new()
	_skip_btn.name = "SkipButton"
	_skip_btn.text = _get_text("Pular tutorial", "Skip tutorial")
	_skip_btn.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	_skip_btn.anchor_left = 1.0
	_skip_btn.anchor_top = 1.0
	_skip_btn.anchor_right = 1.0
	_skip_btn.anchor_bottom = 1.0
	_skip_btn.offset_left = -160
	_skip_btn.offset_top = -50
	_skip_btn.offset_right = -16
	_skip_btn.offset_bottom = -16
	_skip_btn.add_theme_font_size_override("font_size", 14)
	_skip_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_skip_btn.modulate = Color(0.7, 0.7, 0.7, 0.8)
	_skip_btn.pressed.connect(_skip_tutorial)
	add_child(_skip_btn)


func _start_tutorial() -> void:
	tutorial_active = true

	# Cache player start position
	var players = GameManager.get_players()
	if not players.is_empty():
		_start_position = players[0].global_position
		_player_ref = weakref(players[0])

	_advance_step()


func _advance_step() -> void:
	current_step += 1
	if current_step >= STEPS.size():
		_complete_tutorial()
		return

	var step = STEPS[current_step]
	_label.text = _get_step_text(step)
	_overlay.visible = true
	_label.visible = true
	_skip_btn.visible = true

	# Setup condition tracking for the new step
	_setup_condition(step["condition"])


func _setup_condition(condition: String) -> void:
	match condition:
		"move_distance":
			# Tracked in _process
			var players = GameManager.get_players()
			if not players.is_empty():
				_start_position = players[0].global_position
				_player_ref = weakref(players[0])
		"enemy_killed":
			if not _enemy_kill_connected:
				GameManager.enemy_killed.connect(_on_enemy_killed)
				_enemy_kill_connected = true
		"collect_xp":
			_xp_at_step_start = GameManager.player_xp
			_gems_collected = 0
		"level_up_choice":
			# Connect to level_up_screen choice_made signal
			_connect_level_up_signal()
		"dash":
			# Tracked in _process via Input
			pass


func _process(_delta: float) -> void:
	if not tutorial_active or current_step < 0 or current_step >= STEPS.size():
		return

	var step = STEPS[current_step]

	match step["condition"]:
		"move_distance":
			var player = _player_ref.get_ref()
			if player and is_instance_valid(player):
				var dist = _start_position.distance_to(player.global_position)
				if dist >= 3.0:
					_on_condition_met()
		"collect_xp":
			# Track XP changes as proxy for gem collection
			var xp_gained = GameManager.player_xp - _xp_at_step_start
			# Each gem gives ~1 XP, so 3 XP gained means ~3 gems
			if xp_gained >= 3:
				_on_condition_met()
			# Also check if level changed (XP resets on level up)
			if GameManager.player_level > 1 and current_step == 2:
				_on_condition_met()
		"dash":
			if Input.is_action_just_pressed("dash"):
				var player = _player_ref.get_ref()
				if player and is_instance_valid(player):
					# Only count if player actually dashed (has move direction)
					if player.move_direction.length() > 0.1:
						_on_condition_met()


func _on_enemy_killed(_position: Vector3, _xp_value: int) -> void:
	if current_step >= 0 and current_step < STEPS.size():
		if STEPS[current_step]["condition"] == "enemy_killed":
			_on_condition_met()


func _on_level_up_choice() -> void:
	if current_step >= 0 and current_step < STEPS.size():
		if STEPS[current_step]["condition"] == "level_up_choice":
			_on_condition_met()


func _connect_level_up_signal() -> void:
	if _level_up_connected:
		return
	# Find level_up_screen in the scene tree
	var lus_nodes = get_tree().get_nodes_in_group("level_up_screen")
	if not lus_nodes.is_empty():
		var lus = lus_nodes[0]
		if lus.has_signal("choice_made"):
			lus.choice_made.connect(_on_level_up_choice)
			_level_up_connected = true
			return
	# Fallback: search by node name
	var root = get_tree().current_scene
	if root:
		var lus = _find_node_by_name(root, "LevelUpScreen")
		if lus and lus.has_signal("choice_made"):
			lus.choice_made.connect(_on_level_up_choice)
			_level_up_connected = true
			return
	# If not found yet, connect via player_leveled_up as fallback
	# (the player leveling up implies they will make a choice)
	if not _level_up_connected:
		GameManager.player_leveled_up.connect(_on_level_up_from_signal)
		_level_up_connected = true


func _on_level_up_from_signal(_new_level: int) -> void:
	# Delay slightly to let the level up screen appear and be dismissed
	var t = get_tree().create_timer(0.5, false, true)
	t.timeout.connect(func():
		if current_step >= 0 and current_step < STEPS.size():
			if STEPS[current_step]["condition"] == "level_up_choice":
				_on_condition_met()
	)


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found = _find_node_by_name(child, target_name)
		if found:
			return found
	return null


func _on_condition_met() -> void:
	if not tutorial_active:
		return
	# Brief flash to acknowledge completion
	_overlay.visible = false
	_label.visible = false
	# Small delay before next step
	var t = get_tree().create_timer(0.8, false, true)
	t.timeout.connect(_advance_step)


func _skip_tutorial() -> void:
	_complete_tutorial()


func _complete_tutorial() -> void:
	tutorial_active = false
	current_step = -1
	_overlay.visible = false
	_label.visible = false
	_skip_btn.visible = false

	# Disconnect signals
	if _enemy_kill_connected:
		if GameManager.enemy_killed.is_connected(_on_enemy_killed):
			GameManager.enemy_killed.disconnect(_on_enemy_killed)
		_enemy_kill_connected = false
	if _level_up_connected:
		if GameManager.player_leveled_up.is_connected(_on_level_up_from_signal):
			GameManager.player_leveled_up.disconnect(_on_level_up_from_signal)
		_level_up_connected = false

	# Save completion
	SaveManager.data["tutorial_completed"] = true
	SaveManager.save_game()

	set_process(false)
	LogManager.info("Tutorial", "Tutorial completed")


func _get_step_text(step: Dictionary) -> String:
	var locale = LocaleManager.get_locale()
	if locale == "en":
		return step["key_en"]
	return step["key_pt"]


func _get_text(pt: String, en: String) -> String:
	if LocaleManager.get_locale() == "en":
		return en
	return pt


## External API: can be called to show evolution step (backward compat)
func show_evolution_step() -> void:
	pass  # No longer used in interactive tutorial
