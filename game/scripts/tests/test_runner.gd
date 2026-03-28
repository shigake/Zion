extends Node

## Manages test suites and individual test runs.
## Configures characters, stages, weapons, and collects metrics.

signal test_completed(result: Dictionary)
signal suite_completed(results: Array)

# Test configuration
var current_test: Dictionary = {}
var test_queue: Array = []
var test_results: Array = []
var is_running: bool = false

# Current run state
var _auto_player: Node = null
var _run_timer: float = 0.0
var _run_duration: float = 120.0  # seconds
var _snapshot_interval: float = 30.0
var _snapshot_timer: float = 0.0
var _timeline: Array = []
var _errors: Array = []
var _start_time_msec: int = 0
var _dps_tracker: Dictionary = {"damage_samples": [], "last_damage": 0, "last_sample_time": 0.0}
var _fps_samples: Array = []

# Level up interception
var _auto_choose_mode: String = "random"  # random, prioritize_weapons, prioritize_items, forced
var _forced_weapon: String = ""
var _level_up_screen: Node = null

# Stage scene paths
const STAGE_SCENES: Dictionary = {
	"cemetery": "res://scenes/stages/stage_cemetery.tscn",
	"forest": "res://scenes/stages/stage_forest.tscn",
	"farm": "res://scenes/stages/stage_farm.tscn",
	"tokyo": "res://scenes/stages/stage_tokyo.tscn",
	"volcano": "res://scenes/stages/stage_volcano.tscn",
	"ocean": "res://scenes/stages/stage_ocean.tscn",
	"arena": "res://scenes/stages/stage_arena.tscn",
	"space": "res://scenes/stages/stage_space.tscn",
	"castle": "res://scenes/stages/stage_castle.tscn",
	"candy": "res://scenes/stages/stage_candy.tscn",
}

# All characters
const ALL_CHARACTERS: Array = [
	"ronin", "soldado", "mago", "berserker", "ninja", "necro",
	"pirata", "engenheiro", "vampiro", "gladiador", "chef", "mystery"
]

func build_suite(suite_name: String) -> Array:
	var tests: Array = []

	match suite_name:
		"smoke":
			tests = _build_smoke_tests()
		"weapons":
			tests = _build_weapon_tests()
		"full":
			tests = _build_full_tests()
		"stress":
			tests = _build_stress_tests()
		"all":
			tests.append_array(_build_smoke_tests())
			tests.append_array(_build_weapon_tests())
			tests.append_array(_build_full_tests())
			tests.append_array(_build_stress_tests())
		_:
			print("[TestRunner] Unknown suite: %s" % suite_name)

	return tests

func _build_smoke_tests() -> Array:
	var tests: Array = []
	for char_id in ALL_CHARACTERS:
		tests.append({
			"name": "smoke_%s" % char_id,
			"suite": "smoke",
			"character": char_id,
			"stage": "cemetery",
			"duration": 120.0,  # 2 minutes
			"choose_mode": "random",
			"forced_weapon": "",
			"game_mode": "normal",
		})
	return tests

func _build_weapon_tests() -> Array:
	var tests: Array = []
	var all_weapons = WeaponDB.get_all_weapon_ids()
	for wid in all_weapons:
		tests.append({
			"name": "weapon_%s" % wid,
			"suite": "weapons",
			"character": "ronin",
			"stage": "cemetery",
			"duration": 180.0,  # 3 minutes to measure DPS
			"choose_mode": "forced",
			"forced_weapon": wid,
			"game_mode": "normal",
		})
	return tests

func _build_full_tests() -> Array:
	var tests: Array = []
	# Full 30-minute runs with 3 different characters
	for char_id in ["ronin", "soldado", "mago"]:
		tests.append({
			"name": "full_%s_cemetery" % char_id,
			"suite": "full",
			"character": char_id,
			"stage": "cemetery",
			"duration": 1800.0,  # 30 minutes
			"choose_mode": "random",
			"forced_weapon": "",
			"game_mode": "normal",
		})
	return tests

func _build_stress_tests() -> Array:
	var tests: Array = []
	# Hyper mode stress test
	tests.append({
		"name": "stress_hyper",
		"suite": "stress",
		"character": "berserker",
		"stage": "cemetery",
		"duration": 300.0,  # 5 minutes
		"choose_mode": "random",
		"forced_weapon": "",
		"game_mode": "hyper",
	})
	# Max enemies stress test
	tests.append({
		"name": "stress_max_enemies",
		"suite": "stress",
		"character": "mystery",
		"stage": "cemetery",
		"duration": 300.0,
		"choose_mode": "random",
		"forced_weapon": "",
		"game_mode": "hyper",
	})
	# Endless mode test
	tests.append({
		"name": "stress_endless",
		"suite": "stress",
		"character": "ronin",
		"stage": "cemetery",
		"duration": 600.0,  # 10 minutes
		"choose_mode": "random",
		"forced_weapon": "",
		"game_mode": "endless",
	})
	return tests

func start_suite(suite_name: String) -> void:
	test_queue = build_suite(suite_name)
	test_results.clear()
	is_running = true
	print("\n========================================")
	print("  ZION AUTOMATED TEST SUITE: %s" % suite_name.to_upper())
	print("  Tests to run: %d" % test_queue.size())
	print("========================================\n")
	_run_next_test()

func _run_next_test() -> void:
	if test_queue.is_empty():
		_on_suite_complete()
		return

	current_test = test_queue.pop_front()
	print("\n--- Starting test: %s ---" % current_test["name"])
	print("  Character: %s | Stage: %s | Duration: %ds | Mode: %s" % [
		current_test["character"],
		current_test["stage"],
		int(current_test["duration"]),
		current_test.get("game_mode", "normal"),
	])

	# Configure game state
	_run_timer = 0.0
	_run_duration = current_test["duration"]
	_snapshot_timer = 0.0
	_timeline.clear()
	_errors.clear()
	_fps_samples.clear()
	_dps_tracker = {"damage_samples": [], "last_damage": 0, "last_sample_time": 0.0}
	_auto_choose_mode = current_test.get("choose_mode", "random")
	_forced_weapon = current_test.get("forced_weapon", "")
	_start_time_msec = Time.get_ticks_msec()

	# Set game config
	GameManager.selected_character = current_test["character"]
	GameManager.selected_stage = current_test["stage"]
	GameManager.game_mode = current_test.get("game_mode", "normal")

	# Load stage scene
	var scene_path = STAGE_SCENES.get(current_test["stage"], STAGE_SCENES["cemetery"])
	get_tree().change_scene_to_file(scene_path)

	# Wait for scene to load then attach auto player
	await get_tree().create_timer(0.5).timeout
	_attach_auto_player()

func _attach_auto_player() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		# Retry after a short delay
		await get_tree().create_timer(0.5).timeout
		players = GameManager.get_players()
		if players.is_empty():
			_errors.append("ERROR: No player found in scene")
			print("  [ERROR] No player found in scene!")
			_end_current_test("error_no_player")
			return

	var player = players[0]

	# Create and attach AutoPlayer
	var auto_player_script = preload("res://scripts/tests/auto_player.gd")
	_auto_player = Node.new()
	_auto_player.set_script(auto_player_script)
	_auto_player.name = "AutoPlayer"
	add_child(_auto_player)
	_auto_player.setup(player)

	# Disable player input processing by marking as not local
	player.is_local = false

	# For forced weapon tests, give the weapon immediately
	if _forced_weapon != "" and _auto_choose_mode == "forced":
		if not GameManager.has_weapon(_forced_weapon):
			# Clear existing weapons and add the forced one
			# The stage script already adds the starting weapon, so we add forced alongside
			GameManager.add_weapon(_forced_weapon)
			player.add_weapon_node(_forced_weapon)

	# Find and hook into level up screen
	_find_level_up_screen()

	# Connect game over signal
	if not GameManager.game_over.is_connected(_on_game_over):
		GameManager.game_over.connect(_on_game_over)

	# Unpause if paused
	GameManager.paused = false

	# Take initial snapshot
	_take_snapshot("start")

	print("  AutoPlayer attached, test running...")

func _find_level_up_screen() -> void:
	# Find the LevelUpScreen node in the scene tree
	_level_up_screen = null
	var level_up_nodes = get_tree().get_nodes_in_group("level_up_screen")
	if not level_up_nodes.is_empty():
		_level_up_screen = level_up_nodes[0]
		return

	# Search by name/type
	var root = get_tree().current_scene
	if root:
		_level_up_screen = _find_node_recursive(root, "LevelUpScreen")

func _find_node_recursive(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result = _find_node_recursive(child, target_name)
		if result:
			return result
	return null

func _process(delta: float) -> void:
	if not is_running or current_test.is_empty():
		return

	if GameManager.is_game_over:
		return

	_run_timer += delta

	# FPS tracking
	_fps_samples.append(Engine.get_frames_per_second())

	# DPS tracking
	_track_dps()

	# Auto-choose level up options when screen is visible
	_auto_level_up()

	# Periodic snapshots
	_snapshot_timer += delta
	if _snapshot_timer >= _snapshot_interval:
		_snapshot_timer = 0.0
		_take_snapshot("periodic")

	# Check if test duration elapsed
	if _run_timer >= _run_duration:
		_end_current_test("timeout")

func _track_dps() -> void:
	var current_damage = GameManager.total_damage_dealt
	var current_time = GameManager.game_time

	if current_time - _dps_tracker["last_sample_time"] >= 5.0:
		var damage_delta = current_damage - _dps_tracker["last_damage"]
		var time_delta = current_time - _dps_tracker["last_sample_time"]
		if time_delta > 0:
			var dps = damage_delta / time_delta
			_dps_tracker["damage_samples"].append({
				"time": current_time,
				"dps": dps,
				"total_damage": current_damage,
			})
		_dps_tracker["last_damage"] = current_damage
		_dps_tracker["last_sample_time"] = current_time

func _auto_level_up() -> void:
	if not GameManager.paused:
		return

	# Re-find level up screen if needed
	if not _level_up_screen or not is_instance_valid(_level_up_screen):
		_find_level_up_screen()

	if not _level_up_screen or not is_instance_valid(_level_up_screen):
		# Fallback: if game is paused but we can't find the screen, try to unpause
		# This handles game over screen pause too
		if not GameManager.is_game_over:
			# Check if the panel is visible by looking for any visible Panel
			var found_panel = false
			var root = get_tree().current_scene
			if root:
				var panels = _find_all_visible_panels(root)
				for panel_node in panels:
					# Try to click the first button in any visible panel
					var buttons = _find_all_buttons(panel_node)
					if not buttons.is_empty():
						found_panel = true
						buttons[0].pressed.emit()
						break
			if not found_panel:
				GameManager.paused = false
		return

	# Check if level up panel is visible
	var panel = _level_up_screen.get_node_or_null("Panel")
	if not panel or not panel.visible:
		return

	# Get available options
	var options = _level_up_screen.options
	if options.is_empty():
		return

	# Choose based on mode
	var choice_index = _select_level_up_option(options)
	if choice_index >= 0 and choice_index < options.size():
		# Small delay to simulate decision making
		_level_up_screen._choose(choice_index)

func _select_level_up_option(options: Array) -> int:
	match _auto_choose_mode:
		"forced":
			# Prioritize the forced weapon, then upgrades to it
			for i in range(options.size()):
				if options[i]["id"] == _forced_weapon:
					return i
			# If forced weapon not in options, pick randomly
			return randi() % options.size()

		"prioritize_weapons":
			# Prefer weapon upgrades, then new weapons, then items
			var weapon_upgrades: Array = []
			var new_weapons: Array = []
			var items: Array = []
			for i in range(options.size()):
				if options[i]["type"] == "weapon":
					if GameManager.has_weapon(options[i]["id"]):
						weapon_upgrades.append(i)
					else:
						new_weapons.append(i)
				else:
					items.append(i)
			if not weapon_upgrades.is_empty():
				return weapon_upgrades[randi() % weapon_upgrades.size()]
			if not new_weapons.is_empty():
				return new_weapons[randi() % new_weapons.size()]
			if not items.is_empty():
				return items[randi() % items.size()]
			return 0

		"prioritize_items":
			for i in range(options.size()):
				if options[i]["type"] == "item":
					return i
			return 0

		_:  # "random"
			return randi() % options.size()

func _find_all_visible_panels(node: Node) -> Array:
	var result: Array = []
	if node is PanelContainer and node.visible:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_visible_panels(child))
	return result

func _find_all_buttons(node: Node) -> Array:
	var result: Array = []
	if node is Button and node.visible:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_buttons(child))
	return result

func _take_snapshot(reason: String) -> void:
	var snapshot: Dictionary = {
		"reason": reason,
		"game_time": GameManager.game_time,
		"real_time_ms": Time.get_ticks_msec() - _start_time_msec,
		"player_level": GameManager.player_level,
		"player_hp": GameManager.player_hp,
		"player_max_hp": GameManager.get_effective_max_hp(),
		"total_kills": GameManager.total_kills,
		"total_damage": GameManager.total_damage_dealt,
		"enemies_alive": GameManager.enemies_alive,
		"xp": GameManager.player_xp,
		"xp_to_next": GameManager.player_xp_to_next,
		"weapons": [],
		"items": [],
		"fps_avg": _get_avg_fps(),
		"fps_min": _get_min_fps(),
	}

	for w in GameManager.player_weapons:
		snapshot["weapons"].append({"id": w["id"], "level": w["level"]})
	for it in GameManager.player_items:
		snapshot["items"].append({"id": it["id"], "level": it["level"]})

	# AutoPlayer stats
	if _auto_player and is_instance_valid(_auto_player):
		snapshot["auto_player"] = _auto_player.get_stats()

	_timeline.append(snapshot)

	# Print progress
	var t = int(GameManager.game_time)
	print("  [%02d:%02d] Lv%d | HP:%d/%d | Kills:%d | Enemies:%d | FPS:%.0f | %s" % [
		t / 60, t % 60,
		GameManager.player_level,
		GameManager.player_hp,
		GameManager.get_effective_max_hp(),
		GameManager.total_kills,
		GameManager.enemies_alive,
		_get_avg_fps(),
		reason,
	])

func _get_avg_fps() -> float:
	if _fps_samples.is_empty():
		return 0.0
	var total = 0.0
	# Use last 60 samples for recent average
	var start = maxi(0, _fps_samples.size() - 60)
	var count = 0
	for i in range(start, _fps_samples.size()):
		total += _fps_samples[i]
		count += 1
	return total / maxf(count, 1)

func _get_min_fps() -> float:
	if _fps_samples.is_empty():
		return 0.0
	var min_val = INF
	# Check last 60 samples
	var start = maxi(0, _fps_samples.size() - 60)
	for i in range(start, _fps_samples.size()):
		if _fps_samples[i] < min_val:
			min_val = _fps_samples[i]
	return min_val

func _on_game_over() -> void:
	if current_test.is_empty():
		return
	var end_reason = "victory" if GameManager.is_victory else "death"
	_end_current_test(end_reason)

func _end_current_test(reason: String) -> void:
	# Take final snapshot
	_take_snapshot("end_%s" % reason)

	# Compile result
	var result = _compile_result(reason)
	test_results.append(result)
	test_completed.emit(result)

	# Print test summary
	_print_test_summary(result)

	# Cleanup
	if _auto_player and is_instance_valid(_auto_player):
		_auto_player.enabled = false
		_auto_player.queue_free()
		_auto_player = null

	if GameManager.game_over.is_connected(_on_game_over):
		GameManager.game_over.disconnect(_on_game_over)

	# Reset for next test
	current_test = {}
	GameManager.paused = false
	GameManager.is_game_over = false

	# Short delay then next test
	await get_tree().create_timer(1.0).timeout
	_run_next_test()

func _compile_result(end_reason: String) -> Dictionary:
	var avg_dps = 0.0
	var peak_dps = 0.0
	if not _dps_tracker["damage_samples"].is_empty():
		var total_dps = 0.0
		for s in _dps_tracker["damage_samples"]:
			total_dps += s["dps"]
			if s["dps"] > peak_dps:
				peak_dps = s["dps"]
		avg_dps = total_dps / _dps_tracker["damage_samples"].size()

	var all_fps: Array = _fps_samples.duplicate()
	var fps_avg = 0.0
	var fps_min = INF
	if not all_fps.is_empty():
		var total = 0.0
		for f in all_fps:
			total += f
			if f < fps_min:
				fps_min = f
		fps_avg = total / all_fps.size()
	else:
		fps_min = 0.0

	return {
		"test_name": current_test["name"],
		"suite": current_test["suite"],
		"character": current_test["character"],
		"stage": current_test["stage"],
		"game_mode": current_test.get("game_mode", "normal"),
		"end_reason": end_reason,
		"duration_game": GameManager.game_time,
		"duration_real_ms": Time.get_ticks_msec() - _start_time_msec,
		"final_level": GameManager.player_level,
		"total_kills": GameManager.total_kills,
		"total_damage": GameManager.total_damage_dealt,
		"final_hp": GameManager.player_hp,
		"final_max_hp": GameManager.get_effective_max_hp(),
		"weapons": GameManager.player_weapons.duplicate(true),
		"items": GameManager.player_items.duplicate(true),
		"avg_dps": avg_dps,
		"peak_dps": peak_dps,
		"dps_timeline": _dps_tracker["damage_samples"].duplicate(true),
		"fps_avg": fps_avg,
		"fps_min": fps_min,
		"timeline": _timeline.duplicate(true),
		"errors": _errors.duplicate(),
		"forced_weapon": current_test.get("forced_weapon", ""),
	}

func _print_test_summary(result: Dictionary) -> void:
	print("\n  --- Test Complete: %s ---" % result["test_name"])
	print("  Result: %s" % result["end_reason"])
	print("  Duration: %.0fs game / %.1fs real" % [result["duration_game"], result["duration_real_ms"] / 1000.0])
	print("  Level: %d | Kills: %d | Damage: %d" % [result["final_level"], result["total_kills"], result["total_damage"]])
	print("  HP: %d/%d" % [result["final_hp"], result["final_max_hp"]])
	print("  DPS avg: %.1f | peak: %.1f" % [result["avg_dps"], result["peak_dps"]])
	print("  FPS avg: %.1f | min: %.0f" % [result["fps_avg"], result["fps_min"]])

	# Weapons summary
	var weapon_str = ""
	for w in result["weapons"]:
		weapon_str += "%s(Lv%d) " % [w["id"], w["level"]]
	print("  Weapons: %s" % weapon_str.strip_edges())

	# Items summary
	var item_str = ""
	for it in result["items"]:
		item_str += "%s(Lv%d) " % [it["id"], it["level"]]
	if not item_str.is_empty():
		print("  Items: %s" % item_str.strip_edges())

	if not result["errors"].is_empty():
		print("  ERRORS: %d" % result["errors"].size())
		for e in result["errors"]:
			print("    - %s" % e)

func _on_suite_complete() -> void:
	is_running = false
	print("\n========================================")
	print("  SUITE COMPLETE")
	print("  Total tests: %d" % test_results.size())

	var passed = 0
	var failed = 0
	var errors = 0
	for r in test_results:
		match r["end_reason"]:
			"timeout", "victory":
				passed += 1
			"death":
				failed += 1
			_:
				errors += 1

	print("  Passed: %d | Died: %d | Errors: %d" % [passed, failed, errors])
	print("========================================\n")

	suite_completed.emit(test_results)
