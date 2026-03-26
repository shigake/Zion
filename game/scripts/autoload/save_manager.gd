extends Node

## Gerencia save/load de dados persistentes (cristais, upgrades, desbloqueaveis).

const SAVE_PATH := "user://save_data.json"

var data: Dictionary = {
	"crystals": 0,
	"upgrades": {},  # upgrade_id -> level
	"unlocked_characters": ["ronin", "soldado", "mago"],
	"unlocked_stages": ["cemetery"],
	"total_runs": 0,
	"total_kills": 0,
	"best_time": 0.0,
	"achievements": [],
	"completed_stages": [],
	"leaderboard": [],  # Array of {time: float, kills: int, character: String, date: String}
	"bestiary": {},  # enemy_name -> {kills: int, first_seen: String}
	"codex": [],  # Array of weapon IDs the player has used
}

func _ready() -> void:
	load_game()
	_restore_settings()

func _restore_settings() -> void:
	# Restore window mode
	var wm = data.get("window_mode", -1)
	if wm == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif wm == 2:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	# Restore resolution
	var res_idx = data.get("resolution", -1)
	if res_idx >= 0:
		var resolutions = [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
		if res_idx < resolutions.size():
			DisplayServer.window_set_size(resolutions[res_idx])
	# Restore audio volumes (applied after AudioManager is ready)
	call_deferred("_restore_audio")

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	else:
		LogManager.error("Save", "Failed to write save file: %s" % SAVE_PATH)

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		LogManager.info("Save", "No save file found, using defaults")
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var result = json.parse(file.get_as_text())
		if result == OK:
			var loaded = json.data
			if loaded is Dictionary:
				for key in loaded:
					data[key] = loaded[key]
				LogManager.info("Save", "Save loaded: %d crystals, %d runs" % [data.get("crystals", 0), data.get("total_runs", 0)])
			else:
				LogManager.error("Save", "Save file has invalid format (not a Dictionary)")
		else:
			LogManager.error("Save", "Failed to parse save file: %s" % json.get_error_message())
		file.close()
	else:
		LogManager.error("Save", "Failed to open save file: %s" % SAVE_PATH)

func _restore_audio() -> void:
	var master = data.get("volume_master", 1.0)
	var music = data.get("volume_music", 0.8)
	var sfx = data.get("volume_sfx", 1.0)
	AudioManager.set_master_volume(master)
	AudioManager.set_music_volume(music)
	AudioManager.set_sfx_volume(sfx)

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
		var stage_order = ["cemetery", "forest", "farm", "tokyo", "volcano", "ocean", "arena", "space", "castle", "candy"]
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
