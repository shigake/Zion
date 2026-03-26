extends Node

## Telemetry client — sends anonymous gameplay data to backend for analytics.
## Opt-out available in options. Data includes: run stats, crashes, events.

const DEFAULT_URL := "http://localhost:3456"

var enabled: bool = true
var server_url: String = DEFAULT_URL

func _ready() -> void:
	# Load opt-out preference
	enabled = SaveManager.data.get("telemetry_enabled", true)
	# Load server URL from config or use default
	server_url = SaveManager.data.get("telemetry_url", DEFAULT_URL)
	# Connect to signals
	GameManager.game_over.connect(_on_game_over)
	LogManager.crash_reported.connect(_on_crash_reported)
	AchievementManager.achievement_unlocked.connect(_on_achievement)
	# Enviar crash reports pendentes de sessoes anteriores (com delay pra nao bloquear startup)
	get_tree().create_timer(5.0).timeout.connect(_send_pending_crashes)

func _on_game_over() -> void:
	if not enabled:
		return
	# Wait a frame for end_run to populate stats
	await get_tree().process_frame
	_send_run_data()

func _send_run_data() -> void:
	var data = {
		"session_id": LogManager._session_id,
		"version": _get_version(),
		"character": GameManager.selected_character,
		"stage": GameManager.selected_stage,
		"mode": GameManager.game_mode,
		"survived_seconds": GameManager.game_time,
		"victory": GameManager.is_victory,
		"total_kills": GameManager.total_kills,
		"total_damage": GameManager.total_damage_dealt,
		"level_reached": GameManager.player_level,
		"weapons": _get_weapons_list(),
		"items": _get_items_list(),
		"evolutions": EvolutionDB.evolved_weapons.duplicate(),
		"events": GameManager.events_triggered.duplicate(),
		"crystals_earned": GameManager.crystals_this_run,
		"fps_avg": LogManager.get_session_stats().get("avg_fps", 0),
		"fps_min": LogManager.get_session_stats().get("min_fps", 0),
		"peak_enemies": GameManager.peak_enemies,
		"os": OS.get_name(),
		"renderer": RenderingServer.get_video_adapter_name(),
	}
	_post("/telemetry", data)

func _on_crash_reported(report_path: String) -> void:
	if not enabled:
		return
	# Read the full crash report JSON and send everything to the server
	var file = FileAccess.open(report_path, FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data: Dictionary = json.data
		# Ensure all fields exist for the server
		if not data.has("session_id"):
			data["session_id"] = LogManager._session_id
		if not data.has("version"):
			data["version"] = _get_version()
		_post("/crash", data)
	file.close()

## Envia crash reports pendentes que nao foram enviados (ex: crash antes de enviar)
func _send_pending_crashes() -> void:
	if not enabled:
		return
	var dir = DirAccess.open("user://logs/crashes/")
	if not dir:
		return
	var sent_file_path := "user://logs/crashes/.sent"
	var sent_ids: PackedStringArray = PackedStringArray()
	var sent_file = FileAccess.open(sent_file_path, FileAccess.READ)
	if sent_file:
		while not sent_file.eof_reached():
			var line = sent_file.get_line().strip_edges()
			if not line.is_empty():
				sent_ids.append(line)
		sent_file.close()

	dir.list_dir_begin()
	var file_name = dir.get_next()
	var new_sent: PackedStringArray = PackedStringArray()
	while file_name != "":
		if file_name.ends_with(".json") and not file_name in sent_ids:
			var full_path = "user://logs/crashes/" + file_name
			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var json = JSON.new()
				if json.parse(file.get_as_text()) == OK:
					_post("/crash", json.data)
					new_sent.append(file_name)
				file.close()
		file_name = dir.get_next()
	dir.list_dir_end()

	# Marcar como enviados
	if not new_sent.is_empty():
		var append_file = FileAccess.open(sent_file_path, FileAccess.READ_WRITE)
		if not append_file:
			append_file = FileAccess.open(sent_file_path, FileAccess.WRITE)
		if append_file:
			append_file.seek_end()
			for name in new_sent:
				append_file.store_line(name)
			append_file.close()

func _on_achievement(id: String, achievement_name: String) -> void:
	if not enabled:
		return
	_post("/event", {
		"session_id": LogManager._session_id,
		"event_type": "achievement_unlocked",
		"data": {"id": id, "name": achievement_name, "time": GameManager.game_time}
	})

func send_event(event_type: String, data: Dictionary) -> void:
	if not enabled:
		return
	var payload = {
		"session_id": LogManager._session_id,
		"event_type": event_type,
		"data": data,
	}
	_post("/event", payload)

func _post(endpoint: String, data: Dictionary) -> void:
	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	var url = server_url + endpoint
	# Use a new HTTPRequest for each call to avoid conflicts
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_result, _code, _headers, _body): http.queue_free())
	http.timeout = 5.0  # Don't block game
	var err = http.request(url, headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		# Silent fail - telemetry should never block gameplay
		http.queue_free()

func _get_version() -> String:
	var f = FileAccess.open("res://VERSION", FileAccess.READ)
	if f:
		var v = f.get_as_text().strip_edges()
		f.close()
		return v
	return "unknown"

func _get_weapons_list() -> Array:
	var list = []
	for w in GameManager.player_weapons:
		list.append("%s:%d" % [w["id"], w["level"]])
	return list

func _get_items_list() -> Array:
	var list = []
	for it in GameManager.player_items:
		list.append("%s:%d" % [it["id"], it["level"]])
	return list

func set_enabled(value: bool) -> void:
	enabled = value
	SaveManager.data["telemetry_enabled"] = value
	SaveManager.save_game()
