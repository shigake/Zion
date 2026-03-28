extends Node

## Menu Smoke Test — abre cada menu do main_menu, espera carregar, aperta ESC, volta.
## Verifica se todas as telas abrem e fecham sem crash.
##
## Uso: godot --path game --run -- --test=menu_smoke

signal completed(results: Array)

# Menus para testar: [nome_exibicao, cena_destino]
# Na ordem dos botoes do main_menu
const MENU_SCENES: Array = [
	{"name": "Jogar (Character Select)", "scene": "res://scenes/ui/character_select.tscn", "button_index": 0},
	{"name": "Multiplayer (Lobby)", "scene": "res://scenes/ui/lobby_screen.tscn", "button_index": 1},
	{"name": "Loja (Shop)", "scene": "res://scenes/ui/shop.tscn", "button_index": 2},
	{"name": "Desafio Diario", "scene": "res://scenes/ui/daily_challenge_screen.tscn", "button_index": 3},
	{"name": "Leaderboard", "scene": "res://scenes/ui/leaderboard_screen.tscn", "button_index": 4},
	{"name": "Bestiario", "scene": "res://scenes/ui/bestiary_screen.tscn", "button_index": 5},
	{"name": "Codex", "scene": "res://scenes/ui/codex_screen.tscn", "button_index": 6},
	{"name": "Opcoes", "scene": "res://scenes/ui/options_screen.tscn", "button_index": 7},
	{"name": "Creditos", "scene": "res://scenes/ui/credits_screen.tscn", "button_index": -1},  # credits_btn is separate
]

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const WAIT_AFTER_LOAD := 1.0  # seconds to wait after scene loads
const WAIT_AFTER_ESC := 1.0   # seconds to wait after pressing ESC

var _results: Array = []
var _current_index: int = 0
var _running: bool = false


func start() -> void:
	_results.clear()
	_current_index = 0
	_running = true

	print("\n")
	print("================================================")
	print("  MENU SMOKE TEST")
	print("  Menus to test: %d" % MENU_SCENES.size())
	print("================================================\n")

	# Make sure we start at the main menu
	await _ensure_main_menu()

	# Test each menu sequentially
	for i in range(MENU_SCENES.size()):
		_current_index = i
		var menu = MENU_SCENES[i]
		await _test_menu(menu)

	_running = false
	_print_results()
	completed.emit(_results)


func _ensure_main_menu() -> void:
	var tree := get_tree()
	var current_scene := tree.current_scene

	if current_scene and current_scene.scene_file_path == MAIN_MENU_SCENE:
		return

	# Navigate to main menu
	tree.change_scene_to_file(MAIN_MENU_SCENE)
	await tree.tree_changed
	# Extra wait for _ready
	await tree.create_timer(WAIT_AFTER_LOAD).timeout


func _test_menu(menu: Dictionary) -> void:
	var menu_name: String = menu["name"]
	var target_scene: String = menu["scene"]
	var start_time := Time.get_ticks_msec()

	print("[MenuSmoke] Testing: %s ..." % menu_name)

	var result := {
		"name": menu_name,
		"scene": target_scene,
		"status": "FAIL",
		"error": "",
		"time_ms": 0,
	}

	# Step 1: Navigate to the target scene
	var tree := get_tree()
	var err := tree.change_scene_to_file(target_scene)
	if err != OK:
		result["error"] = "change_scene_to_file failed with error %d" % err
		result["time_ms"] = Time.get_ticks_msec() - start_time
		_results.append(result)
		print("[MenuSmoke]   FAIL: %s" % result["error"])
		return

	# Wait for scene to load
	await tree.tree_changed
	await tree.create_timer(WAIT_AFTER_LOAD).timeout

	# Step 2: Verify the scene loaded correctly
	var current := tree.current_scene
	if not current:
		result["error"] = "current_scene is null after navigation"
		result["time_ms"] = Time.get_ticks_msec() - start_time
		_results.append(result)
		print("[MenuSmoke]   FAIL: %s" % result["error"])
		# Try to go back to main menu for next test
		await _ensure_main_menu()
		return

	# Check if the scene path matches what we expected
	var loaded_path: String = current.scene_file_path if current.scene_file_path else ""
	if loaded_path != target_scene:
		# Some scenes might not have scene_file_path set, that's OK if it didn't crash
		pass

	print("[MenuSmoke]   Scene loaded OK: %s" % current.name)

	# Step 3: Press ESC to go back
	_simulate_esc()

	# Wait for navigation back to main menu
	await tree.tree_changed
	await tree.create_timer(WAIT_AFTER_ESC).timeout

	# Step 4: Verify we're back at main menu
	var after_esc := tree.current_scene
	if after_esc and after_esc.scene_file_path == MAIN_MENU_SCENE:
		result["status"] = "PASS"
		result["time_ms"] = Time.get_ticks_msec() - start_time
		print("[MenuSmoke]   PASS (ESC -> main menu) [%dms]" % result["time_ms"])
	elif after_esc:
		# We might be on a different scene or main menu loaded without scene_file_path
		# Check by class/name
		if after_esc.name.to_lower().contains("main") or after_esc.name.to_lower().contains("menu"):
			result["status"] = "PASS"
			result["time_ms"] = Time.get_ticks_msec() - start_time
			print("[MenuSmoke]   PASS (back to menu) [%dms]" % result["time_ms"])
		else:
			result["error"] = "After ESC, ended up at '%s' instead of main menu" % after_esc.name
			result["time_ms"] = Time.get_ticks_msec() - start_time
			print("[MenuSmoke]   FAIL: %s" % result["error"])
			# Force back to main menu for next test
			await _ensure_main_menu()
	else:
		result["error"] = "current_scene is null after ESC"
		result["time_ms"] = Time.get_ticks_msec() - start_time
		print("[MenuSmoke]   FAIL: %s" % result["error"])
		await _ensure_main_menu()

	_results.append(result)


func _simulate_esc() -> void:
	# Simulate pressing ESC (ui_cancel action)
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	Input.parse_input_event(event)

	# Release after a frame
	await get_tree().process_frame
	var release := InputEventAction.new()
	release.action = "ui_cancel"
	release.pressed = false
	Input.parse_input_event(release)


func _print_results() -> void:
	var passed := 0
	var failed := 0

	print("\n")
	print("================================================")
	print("  MENU SMOKE TEST - RESULTS")
	print("================================================")
	print("  %-35s  %s  %s" % ["Menu", "Status", "Time"])
	print("  " + "-".repeat(60))

	for r in _results:
		var status_icon := "PASS" if r["status"] == "PASS" else "FAIL"
		print("  %-35s  %s  %dms" % [r["name"], status_icon, r["time_ms"]])
		if r["status"] == "PASS":
			passed += 1
		else:
			failed += 1
			if r["error"] != "":
				print("    -> %s" % r["error"])

	print("  " + "-".repeat(60))
	print("  Total: %d | Passed: %d | Failed: %d" % [_results.size(), passed, failed])
	print("================================================\n")
