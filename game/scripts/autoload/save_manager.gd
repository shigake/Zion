extends Node

## Gerencia save/load de dados persistentes (cristais, upgrades, desbloqueaveis).

const SAVE_PATH := "user://save_data.json"

var data: Dictionary = {
	"crystals": 0,
	"upgrades": {},  # upgrade_id -> level
	"unlocked_characters": ["ronin", "soldado"],
	"unlocked_stages": ["cemetery"],
	"total_runs": 0,
	"total_kills": 0,
	"best_time": 0.0,
	"achievements": [],
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var result = json.parse(file.get_as_text())
		if result == OK:
			var loaded = json.data
			if loaded is Dictionary:
				# Merge para manter campos novos
				for key in loaded:
					data[key] = loaded[key]
		file.close()

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

func is_character_unlocked(char_id: String) -> bool:
	return char_id in data["unlocked_characters"]

func unlock_character(char_id: String) -> void:
	if char_id not in data["unlocked_characters"]:
		data["unlocked_characters"].append(char_id)
		save_game()

func is_stage_unlocked(stage_id: String) -> bool:
	return stage_id in data["unlocked_stages"]

func unlock_stage(stage_id: String) -> void:
	if stage_id not in data["unlocked_stages"]:
		data["unlocked_stages"].append(stage_id)
		save_game()
