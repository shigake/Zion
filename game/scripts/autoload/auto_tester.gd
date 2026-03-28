extends Node

## Main autoload that coordinates automated testing.
## Only activates when --test argument is present in command line.
##
## Usage:
##   godot --path game --run -- --test=smoke
##   godot --path game --run -- --test=weapons
##   godot --path game --run -- --test=evolution
##   godot --path game --run -- --test=full
##   godot --path game --run -- --test=balance
##   godot --path game --run -- --test=stress
##   godot --path game --run -- --test=achievements
##   godot --path game --run -- --test=events
##   godot --path game --run -- --test=all
##   godot --path game --run -- --test=menu_smoke
##   godot --path game --run -- --test=smoke --test-headless

var _active: bool = false
var _suite_name: String = ""
var _headless: bool = false

var _test_runner: Node = null
var _test_report: Node = null
var _menu_smoke: Node = null

var _error_count: int = 0
var _warning_count: int = 0
var _logged_errors: Array = []

func _ready() -> void:
	# Parse command line arguments
	var args = OS.get_cmdline_args()
	var user_args = OS.get_cmdline_user_args()

	# Check both regular and user args (after --)
	var all_args: Array = []
	all_args.append_array(args)
	all_args.append_array(user_args)

	for arg in all_args:
		if arg.begins_with("--test="):
			_suite_name = arg.split("=")[1]
			_active = true
		elif arg == "--test-headless":
			_headless = true

	if not _active:
		return

	print("\n")
	print("================================================")
	print("  ZION AUTO TESTER - Activating")
	print("  Suite: %s" % _suite_name)
	print("  Headless: %s" % str(_headless))
	print("  Time: %s" % Time.get_datetime_string_from_system())
	print("================================================\n")

	# Hook into error logging
	_setup_error_logging()

	# Wait for the scene tree to be ready, then start
	call_deferred("_start_testing")

func _start_testing() -> void:
	# Menu smoke test has its own flow (no TestRunner/TestReport needed)
	if _suite_name == "menu_smoke":
		_start_menu_smoke()
		return

	# Create TestRunner
	var runner_script = preload("res://scripts/tests/test_runner.gd")
	_test_runner = Node.new()
	_test_runner.set_script(runner_script)
	_test_runner.name = "TestRunner"
	add_child(_test_runner)

	# Create TestReport
	var report_script = preload("res://scripts/tests/test_report.gd")
	_test_report = Node.new()
	_test_report.set_script(report_script)
	_test_report.name = "TestReport"
	add_child(_test_report)

	# Connect suite completion
	_test_runner.suite_completed.connect(_on_suite_completed)

	# Small delay to let the current scene fully initialize
	await get_tree().create_timer(1.0).timeout

	# Start the test suite
	_test_runner.start_suite(_suite_name)


func _start_menu_smoke() -> void:
	var smoke_script = preload("res://scripts/tests/menu_smoke_test.gd")
	_menu_smoke = Node.new()
	_menu_smoke.set_script(smoke_script)
	_menu_smoke.name = "MenuSmokeTest"
	add_child(_menu_smoke)

	_menu_smoke.completed.connect(_on_menu_smoke_completed)

	# Wait for scene to initialize
	await get_tree().create_timer(1.0).timeout
	_menu_smoke.start()


func _on_menu_smoke_completed(results: Array) -> void:
	var passed := 0
	var failed := 0
	for r in results:
		if r["status"] == "PASS":
			passed += 1
		else:
			failed += 1

	# Save results
	_save_results(results)

	var status := "done" if failed == 0 else "warning"
	var message := "Menu Smoke Test: %d/%d menus OK (suite: menu_smoke)" % [passed, results.size()]
	if failed > 0:
		message += ". %d falharam." % failed

	# Notify Discord
	var output: Array = []
	OS.execute("curl", [
		"-s", "-X", "POST",
		"http://localhost:3123/notify",
		"-H", "Content-Type: application/json",
		"-d", JSON.stringify({
			"channel": "zion",
			"message": message,
			"status": status,
		})
	], output, true)

	print("\n[AutoTester] Menu smoke test complete. Exiting in 2 seconds...")
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()

func _on_suite_completed(results: Array) -> void:
	print("\n[AutoTester] Suite completed with %d results" % results.size())

	# Generate report
	var report = _test_report.generate_report(results)

	# Add error log to report
	report["error_log"] = _logged_errors.duplicate()
	report["total_errors"] = _error_count
	report["total_warnings"] = _warning_count

	# Save results
	_save_results(results)

	# Save report
	_test_report.save_report(report, results)

	# Print final summary
	_print_final_summary(results, report)

	# Notify Discord
	_notify_discord(results, report)

	# Exit after testing
	print("\n[AutoTester] Testing complete. Exiting in 2 seconds...")
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()

func _save_results(results: Array) -> void:
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("test_results"):
		dir.make_dir("test_results")

	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var file_path = "user://test_results/results_%s.json" % timestamp

	# Convert results to JSON-safe format
	var json_results = []
	for r in results:
		json_results.append(_make_json_safe(r))

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(json_results, "\t"))
		file.close()
		print("[AutoTester] Results saved to: %s" % file_path)
	else:
		print("[AutoTester] ERROR: Could not save results")

func _make_json_safe(data) -> Variant:
	if data is Dictionary:
		var safe = {}
		for key in data:
			safe[str(key)] = _make_json_safe(data[key])
		return safe
	elif data is Array:
		var safe = []
		for item in data:
			safe.append(_make_json_safe(item))
		return safe
	elif data is Color:
		return {"r": data.r, "g": data.g, "b": data.b, "a": data.a}
	elif data is Vector3:
		return {"x": data.x, "y": data.y, "z": data.z}
	elif data is Vector2:
		return {"x": data.x, "y": data.y}
	else:
		return data

func _setup_error_logging() -> void:
	# GDScript doesn't have a built-in error hook, but we can track
	# push_error/push_warning calls via a custom logger
	# We'll check for errors periodically via the debugger
	pass

func _process(_delta: float) -> void:
	if not _active:
		return

	# Periodically check for stuck states
	if _test_runner and _test_runner.is_running:
		# If game is paused for too long without level up screen, force unpause
		if GameManager.paused and not GameManager.is_game_over:
			# The test runner handles auto level-up, but as a safety net:
			pass

func _print_final_summary(results: Array, report: Dictionary) -> void:
	var passed = 0
	var failed = 0
	var total_kills = 0
	var total_damage = 0

	for r in results:
		if r["end_reason"] in ["timeout", "victory"]:
			passed += 1
		else:
			failed += 1
		total_kills += r["total_kills"]
		total_damage += r["total_damage"]

	print("\n")
	print("================================================")
	print("  FINAL SUMMARY")
	print("================================================")
	print("  Tests: %d total | %d passed | %d failed" % [results.size(), passed, failed])
	print("  Total kills across all tests: %d" % total_kills)
	print("  Total damage across all tests: %d" % total_damage)
	print("  Errors logged: %d | Warnings: %d" % [_error_count, _warning_count])

	# Performance
	var perf = report.get("performance_analysis", {})
	if not perf.is_empty():
		print("  Avg FPS: %.1f | Min FPS: %.0f" % [perf.get("avg_fps", 0), perf.get("min_fps", 0)])

	# Weapon outliers
	var weapon_analysis = report.get("weapon_analysis", {})
	var outlier_count = 0
	for wid in weapon_analysis:
		if weapon_analysis[wid]["status"] != "OK":
			outlier_count += 1
	if outlier_count > 0:
		print("  Weapon balance outliers: %d" % outlier_count)

	# Failed tests
	if failed > 0:
		print("\n  FAILED TESTS:")
		for r in results:
			if r["end_reason"] not in ["timeout", "victory"]:
				print("    - %s (%s)" % [r["test_name"], r["end_reason"]])

	print("================================================\n")

func _notify_discord(results: Array, _report: Dictionary) -> void:
	var passed = 0
	var failed = 0
	for r in results:
		if r["end_reason"] in ["timeout", "victory"]:
			passed += 1
		else:
			failed += 1

	var status = "done" if failed == 0 else "warning"
	var message = "Testes automatizados concluidos: %d/%d passaram (suite: %s)" % [
		passed, results.size(), _suite_name
	]

	if failed > 0:
		message += ". %d testes falharam." % failed

	# Use curl to notify (non-blocking)
	var output: Array = []
	OS.execute("curl", [
		"-s", "-X", "POST",
		"http://localhost:3123/notify",
		"-H", "Content-Type: application/json",
		"-d", JSON.stringify({
			"channel": "zion",
			"message": message,
			"status": status,
		})
	], output, true)
