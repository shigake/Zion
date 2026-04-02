extends CanvasLayer

## Interactive tutorial overlay for first run (PRD C1) + advanced Phase 2 (PRD 28 §6).
## Phase 1: 5-step basic tutorial on first run.
## Phase 2: contextual advanced tips triggered by game events (3rd+ run).
## Only displays if applicable tutorial phase is pending.

# ---- Nodes (built in _ready, no scene dependencies) ----
var _overlay: ColorRect = null
var _label: Label = null
var _skip_btn: Button = null
var _progress_label: Label = null
var _arrow_label: Label = null
var _arrow_tween: Tween = null

# ---- State ----
var tutorial_active: bool = false
var current_step: int = -1
var _start_position: Vector3 = Vector3.ZERO
var _xp_at_step_start: int = 0
var _gems_collected: int = 0
var _player_ref: WeakRef = WeakRef.new()
var _level_up_connected: bool = false
var _enemy_kill_connected: bool = false

# ---- Phase 2 (advanced) state ----
var _phase: int = 1  # 1 = basic, 2 = advanced
var _advanced_step: int = 0
var _advanced_completed: bool = false
var _advanced_dismiss_timer: SceneTreeTimer = null
var _event_manager_connected: bool = false

# Steps: each has an id, locale key, and condition type
const STEPS: Array = [
	{"id": "move", "key_pt": "Use WASD para mover", "key_en": "Use WASD to move", "condition": "move_distance"},
	{"id": "auto_attack", "key_pt": "Sua arma ataca automaticamente!", "key_en": "Your weapon attacks automatically!", "condition": "enemy_killed"},
	{"id": "collect_xp", "key_pt": "Colete as gemas azuis de XP!", "key_en": "Collect the blue XP gems!", "condition": "collect_xp"},
	{"id": "level_up", "key_pt": "Escolha um upgrade!", "key_en": "Choose an upgrade!", "condition": "level_up_choice"},
	{"id": "dash", "key_pt": "Use ESPACO para dar dash!", "key_en": "Use SPACE to dash!", "condition": "dash"},
]

# Phase 2 contextual steps — triggered by game events, not forced
var _advanced_steps: Array = [
	{
		"id": "chest",
		"signal_source": "ChestManager",
		"signal_name": "chest_spawned",
		"key_pt": "Siga a seta! Baus contem armas e itens.",
		"key_en": "Follow the arrow! Chests contain weapons and items.",
	},
	{
		"id": "item",
		"signal_source": "GameManager",
		"signal_name": "weapon_added",
		"key_pt": "Itens dao bonus passivos. Combine com armas certas para evolucoes!",
		"key_en": "Items give passive bonuses. Combine with the right weapons for evolutions!",
	},
	{
		"id": "synergy",
		"signal_source": "SynergySystem",
		"signal_name": "synergy_activated",
		"key_pt": "Ressonancia cristalina! Armas do mesmo elemento criam sinergias.",
		"key_en": "Crystal resonance! Weapons of the same element create synergies.",
	},
	{
		"id": "quest",
		"signal_source": "QuestManager",
		"signal_name": "quest_started",
		"key_pt": "Mini-objetivos aparecem durante a run. Complete para bonus!",
		"key_en": "Mini-objectives appear during the run. Complete them for bonuses!",
	},
	{
		"id": "event",
		"signal_source": "_event_manager",
		"signal_name": "event_started",
		"key_pt": "Anomalia dimensional! Eventos especiais alteram o campo de batalha.",
		"key_en": "Dimensional anomaly! Special events alter the battlefield.",
	},
	{
		"id": "synergy_element",
		"signal_source": "SynergySystem",
		"signal_name": "synergy_activated",
		"key_pt": "Sinergia elemental! Duas armas do mesmo elemento amplificam o dano.",
		"key_en": "Elemental synergy! Two weapons of the same element amplify damage.",
	},
	{
		"id": "evolution_hint",
		"signal_source": "GameManager",
		"signal_name": "weapon_upgraded",
		"key_pt": "Evolucao possivel! Combine arma nivel 8 com o item certo para evoluir.",
		"key_en": "Evolution possible! Combine a level 8 weapon with the right item to evolve.",
	},
	{
		"id": "dash_hint",
		"signal_source": "GameManager",
		"signal_name": "boss_spawned",
		"key_pt": "Boss se aproximando! Use o dash (ESPACO) para desviar de ataques.",
		"key_en": "Boss approaching! Use dash (SPACE) to dodge attacks.",
	},
]


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Check if basic tutorial already completed
	var basic_done = SaveManager.data.get("tutorial_completed", false) or SaveManager.data.get("tutorial_complete", false)

	if basic_done:
		# Check if advanced tutorial should start
		if not SaveManager.data.get("tutorial_advanced_completed", false):
			var total_runs = SaveManager.data.get("total_runs", 0)
			if total_runs >= 2:  # 3rd run onwards
				_phase = 2
				_build_ui()
				_overlay.visible = false
				_label.visible = false
				_skip_btn.visible = false
				_progress_label.visible = false
				_arrow_label.visible = false
				# Start advanced tutorial after a delay (let scene load)
				var t = get_tree().create_timer(2.0, false, true)
				t.timeout.connect(_start_advanced_tutorial)
				return
		# Nothing to show
		_disable()
		return

	# Phase 1: basic tutorial
	_phase = 1
	_build_ui()
	_overlay.visible = false
	_label.visible = false
	_skip_btn.visible = false
	_progress_label.visible = false
	_arrow_label.visible = false

	# Start tutorial after a short delay (let scene load)
	var t = get_tree().create_timer(1.0, false, true)
	t.timeout.connect(_start_tutorial)


func _disable() -> void:
	set_process(false)
	queue_free()


func _build_ui() -> void:
	# Dark overlay (starts hidden)
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.color = Color(0, 0, 0, 0.3)
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
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

	# Progress label (bottom-center)
	_progress_label = Label.new()
	_progress_label.name = "ProgressLabel"
	_progress_label.anchors_preset = Control.PRESET_BOTTOM_LEFT
	_progress_label.anchor_left = 0.5
	_progress_label.anchor_top = 1.0
	_progress_label.anchor_right = 0.5
	_progress_label.anchor_bottom = 1.0
	_progress_label.offset_left = -100
	_progress_label.offset_right = 100
	_progress_label.offset_top = -40
	_progress_label.offset_bottom = -16
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 12)
	_progress_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(_progress_label)

	# Arrow indicator (animated, gold colored)
	_arrow_label = Label.new()
	_arrow_label.name = "ArrowIndicator"
	_arrow_label.text = "▼"
	_arrow_label.anchors_preset = Control.PRESET_CENTER
	_arrow_label.anchor_left = 0.5
	_arrow_label.anchor_top = 0.32
	_arrow_label.anchor_right = 0.5
	_arrow_label.anchor_bottom = 0.32
	_arrow_label.offset_left = -16
	_arrow_label.offset_right = 16
	_arrow_label.offset_top = -20
	_arrow_label.offset_bottom = 20
	_arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arrow_label.add_theme_font_size_override("font_size", 32)
	_arrow_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))  # Gold
	_arrow_label.z_index = 100
	_arrow_label.visible = false
	add_child(_arrow_label)


# ===========================================================================
# Phase 1 — Basic Tutorial
# ===========================================================================

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
	_update_progress_indicator()

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
	if not tutorial_active:
		return

	# Phase 1 processing
	if _phase == 1:
		if current_step < 0 or current_step >= STEPS.size():
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
				if xp_gained >= 3:
					_on_condition_met()
				if GameManager.player_level > 1 and current_step == 2:
					_on_condition_met()
			"dash":
				if Input.is_action_just_pressed("dash"):
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
	_progress_label.visible = false
	# Small delay before next step
	var t = get_tree().create_timer(0.8, false, true)
	t.timeout.connect(_advance_step)


func _skip_tutorial() -> void:
	if _phase == 2:
		_complete_advanced()
	else:
		_complete_tutorial()


func _complete_tutorial() -> void:
	tutorial_active = false
	current_step = -1
	_overlay.visible = false
	_label.visible = false
	_skip_btn.visible = false
	_progress_label.visible = false
	_hide_tutorial_arrow()

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


# ===========================================================================
# Phase 2 — Advanced (Contextual) Tutorial
# ===========================================================================

func _start_advanced_tutorial() -> void:
	tutorial_active = true
	_advanced_step = 0
	LogManager.info("Tutorial", "Advanced tutorial started (Phase 2)")
	_connect_next_advanced_signal()


func _connect_next_advanced_signal() -> void:
	if _advanced_step >= _advanced_steps.size():
		_complete_advanced()
		return

	var step = _advanced_steps[_advanced_step]
	var source_name = step["signal_source"]
	var sig_name = step["signal_name"]

	var source: Object = null

	# Special handling for EventManager (not an autoload)
	if source_name == "_event_manager":
		# Wait a frame then try to find it in the scene
		await get_tree().process_frame
		var scene = get_tree().current_scene
		if scene:
			source = scene.get_node_or_null("EventManager")
		if source and source.has_signal(sig_name):
			if not source.is_connected(sig_name, _on_advanced_trigger):
				source.connect(sig_name, _on_advanced_trigger, CONNECT_ONE_SHOT)
				_event_manager_connected = true
		else:
			# EventManager not found — skip this step
			_advanced_step += 1
			_connect_next_advanced_signal()
		return

	# Autoload singletons
	source = get_node_or_null("/root/" + source_name)
	if source and source.has_signal(sig_name):
		if not source.is_connected(sig_name, _on_advanced_trigger):
			source.connect(sig_name, _on_advanced_trigger, CONNECT_ONE_SHOT)
	else:
		# Signal source not available — skip this step
		LogManager.debug("Tutorial", "Skipping advanced step '%s': source '%s' or signal '%s' not found" % [step["id"], source_name, sig_name])
		_advanced_step += 1
		_connect_next_advanced_signal()


func _on_advanced_trigger(_arg1 = null, _arg2 = null, _arg3 = null) -> void:
	if not tutorial_active or _phase != 2:
		return

	var step = _advanced_steps[_advanced_step]
	var is_pt = LocaleManager.get_locale() != "en"
	var text = step["key_pt"] if is_pt else step["key_en"]
	_show_advanced_message(text)


func _show_advanced_message(text: String) -> void:
	_label.text = text
	_overlay.visible = true
	_label.visible = true
	_skip_btn.visible = true
	_skip_btn.text = _get_text("Pular tutorial", "Skip tutorial")
	_update_progress_indicator()
	_show_tutorial_arrow()

	# Auto-dismiss after 5 seconds or on click/button
	_advanced_dismiss_timer = get_tree().create_timer(5.0, false, true)
	_advanced_dismiss_timer.timeout.connect(_advance_to_next_step)


func _advance_to_next_step() -> void:
	_advanced_dismiss_timer = null
	_advanced_step += 1
	_hide_tutorial_arrow()
	_overlay.visible = false
	_label.visible = false
	_progress_label.visible = false

	# Small delay before connecting next signal
	var t = get_tree().create_timer(0.5, false, true)
	t.timeout.connect(_connect_next_advanced_signal)


func _complete_advanced() -> void:
	_advanced_completed = true
	tutorial_active = false
	_overlay.visible = false
	_label.visible = false
	_skip_btn.visible = false
	_progress_label.visible = false
	_hide_tutorial_arrow()

	# Disconnect any pending signal connections
	_disconnect_advanced_signals()

	SaveManager.data["tutorial_advanced_completed"] = true
	SaveManager.save_game()

	set_process(false)
	LogManager.info("Tutorial", "Advanced tutorial completed (Phase 2)")


func _disconnect_advanced_signals() -> void:
	for step in _advanced_steps:
		var source_name = step["signal_source"]
		var sig_name = step["signal_name"]
		var source: Object = null

		if source_name == "_event_manager":
			var scene = get_tree().current_scene if get_tree() else null
			if scene:
				source = scene.get_node_or_null("EventManager")
		else:
			source = get_node_or_null("/root/" + source_name)

		if source and source.has_signal(sig_name):
			if source.is_connected(sig_name, _on_advanced_trigger):
				source.disconnect(sig_name, _on_advanced_trigger)


# ===========================================================================
# Arrow Animation
# ===========================================================================

func _show_tutorial_arrow() -> void:
	if not _arrow_label:
		return
	_arrow_label.visible = true
	# Kill any existing tween
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
	# Bounce animation
	var base_top = _arrow_label.offset_top
	_arrow_tween = create_tween().set_loops()
	_arrow_tween.tween_property(_arrow_label, "offset_top", base_top - 10, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_arrow_tween.tween_property(_arrow_label, "offset_top", base_top, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _hide_tutorial_arrow() -> void:
	if not _arrow_label:
		return
	_arrow_label.visible = false
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
		_arrow_tween = null


# ===========================================================================
# Progress Indicator
# ===========================================================================

func _update_progress_indicator() -> void:
	if not _progress_label:
		return
	var total: int
	var current: int
	if _phase == 2:
		total = _advanced_steps.size()
		current = _advanced_step + 1
	else:
		total = STEPS.size()
		current = current_step + 1
	var is_pt = LocaleManager.get_locale() != "en"
	_progress_label.text = "Passo %d de %d" % [current, total] if is_pt else "Step %d of %d" % [current, total]
	_progress_label.visible = true


# ===========================================================================
# Input — dismiss Phase 2 on any input (keyboard, mouse, gamepad)
# ===========================================================================

func _unhandled_input(event: InputEvent) -> void:
	if not tutorial_active:
		return

	# ESC or ui_cancel skips tutorial in any phase
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_skip_tutorial()
		return

	# Space/dash advances Phase 1 steps instantly
	if _phase == 1 and event.is_action_pressed("dash"):
		get_viewport().set_input_as_handled()
		_on_condition_met()
		return

	# Phase 2: dismiss current message on any button/key press
	if _phase == 2 and _overlay.visible:
		var is_press = false
		if event is InputEventKey and event.is_pressed() and not event.is_echo():
			is_press = true
		elif event is InputEventMouseButton and event.is_pressed():
			is_press = true
		elif event is InputEventJoypadButton and event.is_pressed():
			is_press = true
		if is_press:
			get_viewport().set_input_as_handled()
			if _advanced_dismiss_timer:
				# Cancel the auto-dismiss timer by advancing now
				_advanced_dismiss_timer = null
			_advance_to_next_step()


# ===========================================================================
# Helpers
# ===========================================================================

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
