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
	# Read the crash report JSON and send it
	var file = FileAccess.open(report_path, FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_post("/crash", json.data)
	file.close()

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
