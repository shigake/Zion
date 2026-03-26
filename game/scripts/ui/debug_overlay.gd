extends CanvasLayer

## In-game debug log viewer overlay, toggled with F3.
## Shows recent logs color-coded by level, FPS, game state, and session stats.
## F4 cycles filter: ALL -> INFO -> WARN -> ERROR

const MAX_VISIBLE_ENTRIES := 20
const FILTER_MODES := [
	LogManager.Level.DEBUG,
	LogManager.Level.INFO,
	LogManager.Level.WARNING,
	LogManager.Level.ERROR,
]
const FILTER_LABELS := ["ALL", "INFO+", "WARN+", "ERROR"]

var _visible := false
var _filter_index := 0
var _current_filter: LogManager.Level = LogManager.Level.DEBUG

var _panel: PanelContainer
var _header_label: RichTextLabel
var _log_label: RichTextLabel
var _scroll: ScrollContainer

func _ready() -> void:
	layer = 100
	_build_ui()
	_set_visible(false)

	# Register input actions
	_register_action("toggle_debug", KEY_F3)
	_register_action("cycle_log_filter", KEY_F4)

	# Connect to LogManager signal
	LogManager.log_entry_added.connect(_on_log_entry_added)


func _register_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event = InputEventKey.new()
	event.physical_keycode = key
	# Avoid duplicating events
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventKey and existing.physical_keycode == key:
			return
	InputMap.action_add_event(action_name, event)


func _build_ui() -> void:
	# Background panel
	_panel = PanelContainer.new()
	_panel.name = "DebugPanel"
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", style)

	# Anchor to fill right half of screen
	_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_panel.offset_left = -600
	_panel.offset_top = 10
	_panel.offset_bottom = -10
	_panel.offset_right = -10

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	_panel.add_child(vbox)

	# Header: stats line
	_header_label = RichTextLabel.new()
	_header_label.name = "Header"
	_header_label.bbcode_enabled = true
	_header_label.fit_content = true
	_header_label.scroll_active = false
	_header_label.custom_minimum_size = Vector2(0, 80)
	_header_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_header_label)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Scroll + log entries
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)

	_log_label = RichTextLabel.new()
	_log_label.name = "LogEntries"
	_log_label.bbcode_enabled = true
	_log_label.fit_content = true
	_log_label.scroll_active = false
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(_log_label)

	add_child(_panel)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_set_visible(not _visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cycle_log_filter") and _visible:
		_filter_index = (_filter_index + 1) % FILTER_MODES.size()
		_current_filter = FILTER_MODES[_filter_index]
		_rebuild_log()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _visible:
		return
	_update_header()


func _set_visible(show: bool) -> void:
	_visible = show
	_panel.visible = show
	if show:
		_rebuild_log()
		_update_header()


func _update_header() -> void:
	var fps := Engine.get_frames_per_second()
	var node_count := _count_all_nodes()
	var stats := LogManager.get_session_stats()

	# Game state info
	var game_time := 0.0
	var enemies := 0
	var player_hp := 0
	var weapons := 0
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		game_time = gm.game_time if "game_time" in gm else 0.0
		enemies = gm.enemies_alive if "enemies_alive" in gm else 0
		player_hp = gm.player_hp if "player_hp" in gm else 0
		weapons = gm.player_weapons.size() if "player_weapons" in gm else 0

	# Pool stats
	var pool_info := ""
	var pool = get_node_or_null("/root/ObjectPool")
	if pool and "_pools" in pool and "_active" in pool:
		var total_pooled := 0
		var total_active := 0
		for path in pool._pools:
			total_pooled += pool._pools[path].size()
		for path in pool._active:
			total_active += pool._active[path]
		pool_info = "Pool: %d active, %d cached" % [total_active, total_pooled]

	var uptime: float = float(stats.get("uptime_seconds", 0.0))
	var avg_fps: float = float(stats.get("avg_fps", 0.0))
	var min_fps: float = float(stats.get("min_fps", 0.0))

	var header := ""
	header += "[b][color=cyan]DEBUG OVERLAY[/color][/b]  Filter: [color=yellow]%s[/color]  (F3 toggle, F4 filter)\n" % FILTER_LABELS[_filter_index]
	header += "[color=lime]FPS:[/color] %d  [color=lime]Avg:[/color] %.0f  [color=lime]Min:[/color] %.0f  [color=lime]Nodes:[/color] %d\n" % [fps, avg_fps, min_fps, node_count]
	header += "[color=lime]Time:[/color] %.1fs  [color=lime]Enemies:[/color] %d  [color=lime]HP:[/color] %d  [color=lime]Weapons:[/color] %d\n" % [game_time, enemies, player_hp, weapons]
	header += "[color=lime]Uptime:[/color] %.0fs  [color=orange]Errors:[/color] %d  [color=yellow]Warns:[/color] %d  %s" % [
		uptime, stats.get("error_count", 0), stats.get("warning_count", 0), pool_info
	]

	_header_label.text = header


func _on_log_entry_added(entry: Dictionary) -> void:
	if not _visible:
		return
	if entry["level"] < _current_filter:
		return
	_append_entry(entry)
	# Auto-scroll to bottom
	await get_tree().process_frame
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _rebuild_log() -> void:
	_log_label.text = ""
	var entries := LogManager.get_recent_entries(MAX_VISIBLE_ENTRIES, _current_filter)
	for entry in entries:
		_append_entry(entry)
	# Auto-scroll
	await get_tree().process_frame
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _append_entry(entry: Dictionary) -> void:
	var color := _get_level_color(entry["level"])
	var time_str: String = entry.get("time", "")
	# Show only HH:MM:SS portion
	if time_str.length() > 8:
		time_str = time_str.substr(time_str.length() - 8)
	var line := "[color=%s][%s] [%s] [%s] %s[/color]\n" % [
		color, time_str, entry["level_name"], entry["module"], entry["message"]
	]
	_log_label.append_text(line)


func _get_level_color(level: LogManager.Level) -> String:
	match level:
		LogManager.Level.DEBUG:
			return "gray"
		LogManager.Level.INFO:
			return "white"
		LogManager.Level.WARNING:
			return "yellow"
		LogManager.Level.ERROR:
			return "red"
		LogManager.Level.FATAL:
			return "crimson"
	return "white"


func _count_all_nodes() -> int:
	var root = get_tree().root
	if root:
		return _count_recursive(root)
	return 0


func _count_recursive(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_recursive(child)
	return count
