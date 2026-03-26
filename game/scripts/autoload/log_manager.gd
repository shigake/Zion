extends Node

## Sistema centralizado de logging, crash reporting e diagnostico.
## Autoload: LogManager (deve ser o PRIMEIRO autoload para capturar tudo)
##
## Uso:
##   LogManager.info("Player", "Spawned at %s" % pos)
##   LogManager.warn("Audio", "File not found: %s" % path)
##   LogManager.error("MP", "Connection failed: %s" % err)
##   LogManager.debug("Weapon", "DPS calc: %s" % dps)
##   LogManager.fatal("Game", "Unrecoverable state")
##
## Logs salvos em: user://logs/
## Crash reports em: user://logs/crashes/

enum Level { DEBUG, INFO, WARNING, ERROR, FATAL }

const LEVEL_NAMES := ["DEBUG", "INFO", "WARN", "ERROR", "FATAL"]
const LEVEL_COLORS := {
	Level.DEBUG: "gray",
	Level.INFO: "white",
	Level.WARNING: "yellow",
	Level.ERROR: "red",
	Level.FATAL: "crimson",
}

# ---- Config ----
## Nivel minimo para gravar no arquivo (DEBUG grava tudo)
var file_log_level: Level = Level.DEBUG
## Nivel minimo para printar no console
var console_log_level: Level = Level.INFO
## Maximo de arquivos de log mantidos (rotacao)
var max_log_files: int = 10
## Maximo de linhas no buffer antes de flush forcado
var max_buffer_size: int = 50
## Maximo de crash reports mantidos
var max_crash_reports: int = 20

# ---- State ----
var _log_file: FileAccess = null
var _log_path: String = ""
var _buffer: PackedStringArray = PackedStringArray()
var _session_id: String = ""
var _session_start: String = ""
var _error_count: int = 0
var _warning_count: int = 0
var _fatal_count: int = 0
var _entries: Array[Dictionary] = []  # In-memory ring buffer (last 500)
var _max_memory_entries: int = 500
var _fps_samples: Array[float] = []
var _min_fps: float = 9999.0
var _frame_count: int = 0

# Signals
signal log_entry_added(entry: Dictionary)
signal error_logged(module: String, message: String)
signal crash_reported(report_path: String)


func _ready() -> void:
	_session_id = _generate_session_id()
	_session_start = _get_timestamp()

	_ensure_directories()
	_rotate_old_logs()
	_open_log_file()
	_write_session_header()

	# Conectar ao tree para capturar erros nao tratados
	get_tree().node_added.connect(_on_node_added)

	# Capture Godot's error output by reading the log file Godot writes
	# Note: in debug builds, errors show in console. We track them manually.
	if OS.is_debug_build():
		set_process_unhandled_input(true)

	# Log de inicio
	info("LogManager", "Session started: %s" % _session_id)
	info("LogManager", "Log file: %s" % _log_path)
	_log_system_info()


func _process(_delta: float) -> void:
	_frame_count += 1
	# Sample FPS a cada 60 frames
	if _frame_count % 60 == 0:
		var fps = Engine.get_frames_per_second()
		_fps_samples.append(fps)
		if _fps_samples.size() > 300:
			_fps_samples.remove_at(0)
		if fps < _min_fps:
			_min_fps = fps
		# Aviso se FPS muito baixo
		if fps < 20.0:
			warn("Performance", "Low FPS: %.0f" % fps)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		info("LogManager", "Game closing (window close request)")
		_write_session_footer()
		_flush()
		if _log_file:
			_log_file.close()
	elif what == NOTIFICATION_CRASH:
		_on_crash("NOTIFICATION_CRASH received")
	elif what == NOTIFICATION_PREDELETE:
		_flush()
		if _log_file:
			_log_file.close()


# ==== PUBLIC API ====

func debug(module: String, message: String) -> void:
	_log(Level.DEBUG, module, message)

func info(module: String, message: String) -> void:
	_log(Level.INFO, module, message)

func warn(module: String, message: String) -> void:
	_log(Level.WARNING, module, message)
	_warning_count += 1

func error(module: String, message: String) -> void:
	_log(Level.ERROR, module, message)
	_error_count += 1
	error_logged.emit(module, message)

func fatal(module: String, message: String) -> void:
	_log(Level.FATAL, module, message)
	_fatal_count += 1
	_generate_crash_report(module, message)


## Registra uma excecao capturada por outro script
func log_exception(module: String, error_text: String, stack: String = "") -> void:
	error(module, "EXCEPTION: %s" % error_text)
	if not stack.is_empty():
		error(module, "Stack: %s" % stack)
	_generate_crash_report(module, error_text, {"stack": stack})


## Gera um crash report manual (pode ser chamado de qualquer lugar)
func report_crash(module: String, description: String, extra_data: Dictionary = {}) -> String:
	error(module, "CRASH: %s" % description)
	return _generate_crash_report(module, description, extra_data)


## Retorna as ultimas N entradas do log
func get_recent_entries(count: int = 50, min_level: Level = Level.DEBUG) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start = maxi(0, _entries.size() - count)
	for i in range(start, _entries.size()):
		if _entries[i]["level"] >= min_level:
			result.append(_entries[i])
	return result


## Retorna estatisticas da sessao
func get_session_stats() -> Dictionary:
	var avg_fps := 0.0
	if not _fps_samples.is_empty():
		var total := 0.0
		for s in _fps_samples:
			total += s
		avg_fps = total / _fps_samples.size()

	return {
		"session_id": _session_id,
		"session_start": _session_start,
		"uptime_seconds": Time.get_ticks_msec() / 1000.0,
		"total_entries": _entries.size(),
		"error_count": _error_count,
		"warning_count": _warning_count,
		"fatal_count": _fatal_count,
		"avg_fps": avg_fps,
		"min_fps": _min_fps if _min_fps < 9999.0 else 0.0,
		"log_file": _log_path,
	}


## Retorna o caminho do diretorio de logs
func get_logs_dir() -> String:
	return "user://logs/"


## Retorna o caminho do diretorio de crash reports
func get_crashes_dir() -> String:
	return "user://logs/crashes/"


## Exporta o log completo da sessao como texto
func export_session_log() -> String:
	var text := "=== Zion Session Log ===\n"
	text += "Session: %s\n" % _session_id
	text += "Start: %s\n" % _session_start
	text += "Entries: %d (errors: %d, warnings: %d)\n" % [_entries.size(), _error_count, _warning_count]
	text += "========================\n\n"
	for entry in _entries:
		text += _format_entry(entry) + "\n"
	return text


## Forca o flush do buffer para disco
func flush() -> void:
	_flush()


# ==== INTERNAL ====

func _log(level: Level, module: String, message: String) -> void:
	var entry := {
		"time": _get_timestamp(),
		"tick": Time.get_ticks_msec(),
		"level": level,
		"level_name": LEVEL_NAMES[level],
		"module": module,
		"message": message,
	}

	# Ring buffer em memoria
	_entries.append(entry)
	if _entries.size() > _max_memory_entries:
		_entries.remove_at(0)

	# Console output
	if level >= console_log_level:
		var formatted = _format_entry(entry)
		match level:
			Level.WARNING:
				push_warning(formatted)
			Level.ERROR, Level.FATAL:
				push_error(formatted)
			_:
				print(formatted)

	# File output
	if level >= file_log_level:
		_buffer.append(_format_entry(entry))
		if _buffer.size() >= max_buffer_size:
			_flush()

	log_entry_added.emit(entry)


func _format_entry(entry: Dictionary) -> String:
	return "[%s] [%s] [%s] %s" % [
		entry["time"],
		entry["level_name"],
		entry["module"],
		entry["message"]
	]


func _flush() -> void:
	if _buffer.is_empty() or _log_file == null:
		return
	for line in _buffer:
		_log_file.store_line(line)
	_log_file.flush()
	_buffer.clear()


func _ensure_directories() -> void:
	DirAccess.make_dir_recursive_absolute("user://logs/crashes/")


func _open_log_file() -> void:
	var date = Time.get_date_string_from_system().replace("-", "")
	var time_str = Time.get_time_string_from_system().replace(":", "")
	_log_path = "user://logs/zion_%s_%s.log" % [date, time_str]
	_log_file = FileAccess.open(_log_path, FileAccess.WRITE)
	if _log_file == null:
		push_error("[LogManager] Failed to open log file: %s" % _log_path)


func _rotate_old_logs() -> void:
	var dir = DirAccess.open("user://logs/")
	if dir == null:
		return

	# Coletar logs existentes
	var log_files: Array[String] = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("zion_") and file_name.ends_with(".log"):
			log_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Ordenar por nome (data) e remover os mais antigos
	log_files.sort()
	while log_files.size() >= max_log_files:
		var oldest = log_files.pop_front()
		dir.remove("user://logs/%s" % oldest)

	# Mesma coisa para crash reports
	var crash_dir = DirAccess.open("user://logs/crashes/")
	if crash_dir == null:
		return
	var crash_files: Array[String] = []
	crash_dir.list_dir_begin()
	file_name = crash_dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			crash_files.append(file_name)
		file_name = crash_dir.get_next()
	crash_dir.list_dir_end()

	crash_files.sort()
	while crash_files.size() >= max_crash_reports:
		var oldest = crash_files.pop_front()
		crash_dir.remove("user://logs/crashes/%s" % oldest)


func _write_session_header() -> void:
	if _log_file == null:
		return
	_log_file.store_line("=" .repeat(70))
	_log_file.store_line("ZION SESSION LOG")
	_log_file.store_line("Session ID: %s" % _session_id)
	_log_file.store_line("Start: %s" % _session_start)
	_log_file.store_line("=" .repeat(70))
	_log_file.store_line("")
	_log_file.flush()


func _write_session_footer() -> void:
	var stats = get_session_stats()
	_log_file.store_line("")
	_log_file.store_line("=" .repeat(70))
	_log_file.store_line("SESSION END")
	_log_file.store_line("Uptime: %.1f seconds" % stats["uptime_seconds"])
	_log_file.store_line("Entries: %d | Errors: %d | Warnings: %d | Fatal: %d" % [
		stats["total_entries"], stats["error_count"], stats["warning_count"], stats["fatal_count"]
	])
	_log_file.store_line("Avg FPS: %.1f | Min FPS: %.1f" % [stats["avg_fps"], stats["min_fps"]])
	_log_file.store_line("=" .repeat(70))
	_log_file.flush()


func _log_system_info() -> void:
	var version_text := "unknown"
	var version_file = FileAccess.open("res://VERSION", FileAccess.READ)
	if version_file:
		version_text = version_file.get_as_text().strip_edges()
		version_file.close()

	info("System", "Zion v%s" % version_text)
	info("System", "Godot %s" % Engine.get_version_info()["string"])
	info("System", "OS: %s" % OS.get_name())
	info("System", "Renderer: %s" % RenderingServer.get_video_adapter_name())
	info("System", "Display: %dx%d" % [
		DisplayServer.screen_get_size().x,
		DisplayServer.screen_get_size().y
	])
	info("System", "Locale: %s" % OS.get_locale())
	info("System", "Debug build: %s" % str(OS.is_debug_build()))
	info("System", "Processors: %d" % OS.get_processor_count())

	# Memory info
	var mem_static = OS.get_static_memory_usage()
	info("System", "Static memory: %.1f MB" % (mem_static / 1048576.0))


func _generate_crash_report(module: String, description: String, extra_data: Dictionary = {}) -> String:
	var date = Time.get_date_string_from_system().replace("-", "")
	var time_str = Time.get_time_string_from_system().replace(":", "")
	var report_path = "user://logs/crashes/crash_%s_%s.json" % [date, time_str]

	var stats = get_session_stats()

	# Coletar ultimas entradas de log
	var recent_log: Array[String] = []
	var recent = get_recent_entries(100)
	for entry in recent:
		recent_log.append(_format_entry(entry))

	# Coletar info do game state (se GameManager existir)
	var game_state := {}
	if Engine.has_singleton("GameManager") or has_node("/root/GameManager"):
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			game_state = {
				"game_time": gm.game_time if "game_time" in gm else 0.0,
				"player_level": gm.player_level if "player_level" in gm else 0,
				"enemies_alive": gm.enemies_alive if "enemies_alive" in gm else 0,
				"is_game_over": gm.is_game_over if "is_game_over" in gm else false,
				"selected_character": gm.selected_character if "selected_character" in gm else "",
				"selected_stage": gm.selected_stage if "selected_stage" in gm else "",
				"player_hp": gm.player_hp if "player_hp" in gm else 0,
				"total_kills": gm.total_kills if "total_kills" in gm else 0,
				"weapon_count": gm.player_weapons.size() if "player_weapons" in gm else 0,
			}

	var report := {
		"crash_time": _get_timestamp(),
		"session_id": _session_id,
		"session_start": _session_start,
		"module": module,
		"description": description,
		"system": {
			"version": _get_game_version(),
			"godot": Engine.get_version_info()["string"],
			"os": OS.get_name(),
			"renderer": RenderingServer.get_video_adapter_name(),
			"locale": OS.get_locale(),
			"debug_build": OS.is_debug_build(),
			"memory_mb": OS.get_static_memory_usage() / 1048576.0,
		},
		"session_stats": stats,
		"game_state": game_state,
		"recent_log": recent_log,
		"extra_data": extra_data,
		"scene_tree": _get_scene_tree_summary(),
	}

	var json_text = JSON.stringify(report, "\t")
	var file = FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.close()
		info("LogManager", "Crash report saved: %s" % report_path)
		crash_reported.emit(report_path)
	else:
		push_error("[LogManager] Failed to save crash report: %s" % report_path)

	return report_path


func _get_scene_tree_summary() -> Dictionary:
	var summary := {}
	var root = get_tree().root
	if root:
		summary["current_scene"] = get_tree().current_scene.scene_file_path if get_tree().current_scene else "none"
		summary["node_count"] = _count_nodes(root)
		summary["group_counts"] = {}
		for group_name in ["players", "enemies", "projectiles", "pickups", "weapons"]:
			summary["group_counts"][group_name] = get_tree().get_nodes_in_group(group_name).size()
	return summary


func _count_nodes(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count


func _on_crash(reason: String) -> void:
	fatal("Crash", reason)


func _on_node_added(_node: Node) -> void:
	pass  # Placeholder para monitoramento futuro


func _get_timestamp() -> String:
	var dt = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		dt["year"], dt["month"], dt["day"],
		dt["hour"], dt["minute"], dt["second"]
	]


func _get_game_version() -> String:
	var file = FileAccess.open("res://VERSION", FileAccess.READ)
	if file:
		var v = file.get_as_text().strip_edges()
		file.close()
		return v
	return "unknown"


func _generate_session_id() -> String:
	var dt = Time.get_datetime_dict_from_system()
	var base = "%04d%02d%02d%02d%02d%02d" % [
		dt["year"], dt["month"], dt["day"],
		dt["hour"], dt["minute"], dt["second"]
	]
	return base + "_%04x" % (randi() % 0xFFFF)
