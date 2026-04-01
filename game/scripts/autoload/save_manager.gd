extends Node

## Gerencia save/load de dados persistentes (cristais, upgrades, desbloqueaveis).

const SAVE_PATH := "user://save_data.json"

var data: Dictionary = {
	"crystals": 0,
	"upgrades": {},  # upgrade_id -> level
	"unlocked_characters": ["amazona", "bruxa", "lealith", "ronin", "soldado", "mago"],
	"unlocked_stages": ["cemetery"],
	"total_runs": 0,
	"total_kills": 0,
	"best_time": 0.0,
	"achievements": [],
	"completed_stages": [],
	"leaderboard": [],  # Array of {time: float, kills: int, character: String, date: String}
	"bestiary": {},  # enemy_name -> {kills: int, first_seen: String}
	"codex": [],  # Array of weapon IDs the player has used
	"player_name": "Anonymous",  # Player name for online leaderboard
	"pending_leaderboard_scores": [],  # Offline fallback: scores to submit later
	"best_run": {},  # Best run stats for comparison {time, kills, dps, level, crystals, damage}
	"story_seen": false,  # Whether the story intro has been shown
	"audio_combat": 100,  # Combat SFX volume (0-100)
	"audio_ambient": 100,  # Ambient SFX volume (0-100)
	"audio_ducking": true,  # Auto-ducking music during voice/dialogue
}

func _ready() -> void:
	load_game()
	_ensure_default_unlocks()
	_restore_settings()

func _restore_settings() -> void:
	# Restore video: window mode
	var wm = data.get("video_window_mode", data.get("window_mode", -1))
	if wm == 1:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif wm == 2:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)

	# Restore video: resolution
	var res_idx = data.get("video_resolution", data.get("resolution", -1))
	if res_idx >= 0:
		var resolutions = GameConstants.RESOLUTIONS
		if res_idx < resolutions.size():
			DisplayServer.window_set_size(resolutions[res_idx])
			var ss = DisplayServer.screen_get_size()
			DisplayServer.window_set_position((ss - resolutions[res_idx]) / 2)

	# Restore video: V-Sync
	var vsync = data.get("video_vsync", true)
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	# Restore video: FPS limit
	var fps_idx = data.get("video_fps_limit", -1)
	if fps_idx >= 0:
		var fps_values = GameConstants.FPS_OPTIONS
		if fps_idx < fps_values.size():
			Engine.max_fps = fps_values[fps_idx]

	# Restore graphics: MSAA
	var msaa = data.get("gfx_msaa", -1)
	if msaa >= 0:
		call_deferred("_restore_msaa", msaa)

	# Restore audio volumes (applied after AudioManager is ready)
	call_deferred("_restore_audio")

func save_game() -> void:
	data["last_save_timestamp"] = int(Time.get_unix_time_from_system())
	var json_str = JSON.stringify(data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
	else:
		LogManager.error("Save", "Failed to write save file: %s" % SAVE_PATH)
	# Sync to Steam Cloud
	SteamManager.cloud_save(json_str)

func load_game() -> void:
	# Try Steam Cloud first (may be more recent than local)
	var cloud_json = SteamManager.cloud_load()
	var local_exists = FileAccess.file_exists(SAVE_PATH)

	if not cloud_json.is_empty() and not local_exists:
		# Only cloud save exists — use it
		_apply_save_json(cloud_json, "cloud")
		return

	if local_exists:
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var local_json = file.get_as_text()
			file.close()
			_apply_save_json(local_json, "local")

			# If cloud has data, compare timestamps and use the newer one
			if not cloud_json.is_empty():
				var cloud_data = _parse_json(cloud_json)
				if cloud_data is Dictionary:
					var cloud_ts = cloud_data.get("last_save_timestamp", 0)
					var local_ts = data.get("last_save_timestamp", 0)
					if cloud_ts > local_ts:
						LogManager.info("Save", "Cloud save is newer, using cloud data")
						_apply_save_json(cloud_json, "cloud")
		else:
			LogManager.error("Save", "Failed to open save file: %s" % SAVE_PATH)
		return

	LogManager.info("Save", "No save file found, using defaults")

func _apply_save_json(json_str: String, source: String) -> void:
	var loaded = _parse_json(json_str)
	if loaded is Dictionary:
		for key in loaded:
			data[key] = loaded[key]
		LogManager.info("Save", "Save loaded from %s: %d crystals, %d runs" % [source, data.get("crystals", 0), data.get("total_runs", 0)])
	else:
		LogManager.error("Save", "Save from %s has invalid format" % source)

func _parse_json(json_str: String) -> Variant:
	var json = JSON.new()
	var result = json.parse(json_str)
	if result == OK:
		return json.data
	LogManager.error("Save", "Failed to parse JSON: %s" % json.get_error_message())
	return null

func _ensure_default_unlocks() -> void:
	## Ensure starter characters are always unlocked (handles existing saves)
	var defaults = ["amazona", "bruxa", "lealith", "ronin", "soldado", "mago"]
	for char_id in defaults:
		if char_id not in data["unlocked_characters"]:
			data["unlocked_characters"].append(char_id)
			save_game()

func _restore_audio() -> void:
	# Keys match options_screen.gd: audio_master, audio_music, audio_sfx, audio_ui (0-100 scale)
	var master = data.get("audio_master", data.get("volume_master", 100.0))
	var music = data.get("audio_music", data.get("volume_music", 80.0))
	var sfx = data.get("audio_sfx", data.get("volume_sfx", 100.0))
	var ui = data.get("audio_ui", 100.0)
	# Apply to AudioManager (expects 0.0-1.0)
	AudioManager.set_master_volume(master / 100.0 if master > 1.0 else master)
	AudioManager.set_music_volume(music / 100.0 if music > 1.0 else music)
	AudioManager.set_sfx_volume(sfx / 100.0 if sfx > 1.0 else sfx)
	# Apply to audio buses directly (for options that use AudioServer)
	_apply_audio_bus("Master", master / 100.0 if master > 1.0 else master)
	_apply_audio_bus("Music", music / 100.0 if music > 1.0 else music)
	_apply_audio_bus("SFX", sfx / 100.0 if sfx > 1.0 else sfx)
	_apply_audio_bus("UI", ui / 100.0 if ui > 1.0 else ui)
	# Restore new audio settings (PRD 28 §2)
	var combat = data.get("audio_combat", 100)
	var ambient = data.get("audio_ambient", 100)
	var ducking = data.get("audio_ducking", true)
	AudioManager.combat_volume = combat / 100.0 if combat > 1.0 else combat
	AudioManager.ambient_volume = ambient / 100.0 if ambient > 1.0 else ambient
	AudioManager._ducking_enabled = ducking

func _apply_audio_bus(bus_name: String, linear: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(maxf(linear, 0.0001)))

func _restore_msaa(msaa_idx: int) -> void:
	var viewport = get_viewport()
	if viewport:
		match msaa_idx:
			0: viewport.msaa_3d = Viewport.MSAA_DISABLED
			1: viewport.msaa_3d = Viewport.MSAA_2X
			2: viewport.msaa_3d = Viewport.MSAA_4X
			3: viewport.msaa_3d = Viewport.MSAA_8X

func add_crystals(amount: int) -> void:
	data["crystals"] += amount
	save_game()

func get_crystals() -> int:
	return data["crystals"]

func spend_crystals(amount: int) -> bool:
	if data["crystals"] >= amount:
		data["crystals"] -= amount
		save_game()
		return true
	return false

func get_upgrade_level(upgrade_id: String) -> int:
	if upgrade_id in data["upgrades"]:
		return data["upgrades"][upgrade_id]
	return 0

func buy_upgrade(upgrade_id: String) -> bool:
	var shop = ShopDB.get_upgrade(upgrade_id)
	if shop.is_empty():
		return false
	var current_level = get_upgrade_level(upgrade_id)
	if current_level >= shop["max_level"]:
		return false
	var cost = shop["base_cost"] + shop["cost_per_level"] * current_level
	if spend_crystals(cost):
		data["upgrades"][upgrade_id] = current_level + 1
		save_game()
		return true
	return false

func end_run(crystals_earned: int, time_survived: float, kills: int) -> void:
	data["crystals"] += crystals_earned
	data["total_runs"] += 1
	data["total_kills"] += kills
	if time_survived > data["best_time"]:
		data["best_time"] = time_survived
	save_game()
	# Auto-add to leaderboard if endless mode
	if GameManager.game_mode == "endless":
		add_leaderboard_entry(time_survived, kills, CharacterDB.get_character(GameManager.selected_character).get("name", "???"))

func complete_stage(stage_id: String) -> void:
	if stage_id not in data.get("completed_stages", []):
		if "completed_stages" not in data:
			data["completed_stages"] = []
		data["completed_stages"].append(stage_id)
		# Desbloqueia proxima fase
		var stage_order = GameConstants.ALL_STAGES
		var idx = stage_order.find(stage_id)
		if idx >= 0 and idx + 1 < stage_order.size():
			unlock_stage(stage_order[idx + 1])
		save_game()

func check_unlocks() -> Array[String]:
	## Checks if any characters should be unlocked based on stats. Returns newly unlocked ids.
	var newly_unlocked: Array[String] = []
	for char_id in CharacterDB.get_all_character_ids():
		if is_character_unlocked(char_id):
			continue
		var char_data = CharacterDB.get_character(char_id)
		if "unlock_condition" not in char_data:
			continue
		var unlocked = false
		match char_data["unlock_condition"]:
			"total_kills":
				if data["total_kills"] >= char_data["unlock_value"]:
					unlocked = true
			"complete_stage":
				if char_data["unlock_value"] in data.get("completed_stages", []):
					unlocked = true
			"all_characters":
				# Unlock when all OTHER characters are unlocked
				var all_others = true
				for other_id in CharacterDB.get_all_character_ids():
					if other_id == char_id:
						continue
					if not is_character_unlocked(other_id):
						all_others = false
						break
				if all_others:
					unlocked = true
			"all_stages":
				var all_complete = true
				for stage in GameConstants.ALL_STAGES:
					if stage not in data.get("completed_stages", []):
						all_complete = false
						break
				if all_complete:
					unlocked = true
		if unlocked:
			unlock_character(char_id)
			newly_unlocked.append(char_id)
	return newly_unlocked

func is_character_unlocked(char_id: String) -> bool:
	return char_id in data["unlocked_characters"]

func unlock_character(char_id: String) -> void:
	if char_id not in data["unlocked_characters"]:
		data["unlocked_characters"].append(char_id)
		save_game()

func add_leaderboard_entry(time: float, kills: int, character: String) -> int:
	## Adds an entry to the leaderboard. Returns the rank (0-based, -1 if not in top 10).
	var entry = {
		"time": time,
		"kills": kills,
		"character": character,
		"date": Time.get_date_string_from_system(),
	}
	if "leaderboard" not in data:
		data["leaderboard"] = []
	data["leaderboard"].append(entry)
	# Sort by time descending (longest survival first)
	data["leaderboard"].sort_custom(func(a, b): return a["time"] > b["time"])
	# Keep top 10
	if data["leaderboard"].size() > 10:
		data["leaderboard"].resize(10)
	save_game()
	# Return rank
	for i in range(data["leaderboard"].size()):
		if data["leaderboard"][i] == entry:
			return i
	return -1

func get_leaderboard() -> Array:
	return data.get("leaderboard", [])

func is_stage_unlocked(stage_id: String) -> bool:
	return stage_id in data["unlocked_stages"]

func unlock_stage(stage_id: String) -> void:
	if stage_id not in data["unlocked_stages"]:
		data["unlocked_stages"].append(stage_id)
		save_game()

# ---- Bestiary ----
func track_bestiary(enemy_name: String) -> void:
	if "bestiary" not in data:
		data["bestiary"] = {}
	if enemy_name in data["bestiary"]:
		data["bestiary"][enemy_name]["kills"] += 1
	else:
		data["bestiary"][enemy_name] = {
			"kills": 1,
			"first_seen": Time.get_date_string_from_system(),
		}
	save_game()

func get_bestiary() -> Dictionary:
	return data.get("bestiary", {})

# ---- Codex ----
func track_codex(weapon_id: String) -> void:
	if "codex" not in data:
		data["codex"] = []
	if weapon_id not in data["codex"]:
		data["codex"].append(weapon_id)
		save_game()

func get_codex() -> Array:
	return data.get("codex", [])

# ---- Best Run ----
func save_best_run(run_stats: Dictionary) -> void:
	## Save current run stats if it beats the best run (by score = kills*10 + time + crystals).
	var current_best = data.get("best_run", {})
	var current_score = current_best.get("kills", 0) * 10 + int(current_best.get("time", 0.0)) + current_best.get("crystals", 0)
	var new_score = run_stats.get("kills", 0) * 10 + int(run_stats.get("time", 0.0)) + run_stats.get("crystals", 0)
	if new_score > current_score:
		data["best_run"] = run_stats
		save_game()

func get_best_run() -> Dictionary:
	return data.get("best_run", {})
