extends Node

## Generates reports from test results.
## Compares DPS curves against expected values, flags outliers,
## prints formatted tables, and saves summary reports.

# Expected DPS ranges per weapon at level 8 (computed from weapon_db formulas)
# Format: { weapon_id: { "expected_dps": float, "tolerance_low": 0.5, "tolerance_high": 2.0 } }
var _expected_dps: Dictionary = {}

func _ready() -> void:
	_compute_expected_dps()

func _compute_expected_dps() -> void:
	# Calculate theoretical DPS for each weapon at level 8
	var all_weapons = WeaponDB.get_all_weapon_ids()
	for wid in all_weapons:
		var w = WeaponDB.get_weapon(wid)
		if w.is_empty():
			continue
		var dmg = w["base_damage"] + w.get("damage_per_level", 0) * 7  # level 8 = 7 upgrades
		var cd = maxf(0.05, w["base_cooldown"] + w.get("cooldown_per_level", 0) * 7)
		# For continuous weapons (cooldown 0), estimate hits per second
		if cd <= 0.05:
			cd = 0.3  # Estimate for orbiting/continuous weapons
		var theoretical_dps = dmg / cd

		# Adjust for multi-hit weapons
		var weapon_type = w.get("type", "melee")
		if weapon_type == "summon":
			theoretical_dps *= 0.7  # Summons don't always attack optimally
		if wid == "machinegun" or wid == "dual_pistol":
			theoretical_dps *= 0.8  # Not all shots hit

		_expected_dps[wid] = {
			"expected_dps": theoretical_dps,
			"tolerance_low": 0.3,   # actual can be as low as 30% of expected
			"tolerance_high": 3.0,  # actual can be up to 3x expected (AoE hitting multiples)
		}

func generate_report(results: Array) -> Dictionary:
	var report = {
		"timestamp": Time.get_datetime_string_from_system(),
		"total_tests": results.size(),
		"summary": {},
		"weapon_analysis": {},
		"character_analysis": {},
		"performance_analysis": {},
		"outliers": [],
		"warnings": [],
	}

	# Group results by suite
	var by_suite: Dictionary = {}
	for r in results:
		var suite = r.get("suite", "unknown")
		if suite not in by_suite:
			by_suite[suite] = []
		by_suite[suite].append(r)

	# Generate per-suite summaries
	for suite_name in by_suite:
		report["summary"][suite_name] = _summarize_suite(by_suite[suite_name])

	# Weapon DPS analysis (from weapon tests)
	if "weapons" in by_suite:
		report["weapon_analysis"] = _analyze_weapons(by_suite["weapons"])

	# Character analysis (from smoke tests)
	if "smoke" in by_suite:
		report["character_analysis"] = _analyze_characters(by_suite["smoke"])

	# Performance analysis (from all tests)
	report["performance_analysis"] = _analyze_performance(results)

	# Print report
	_print_report(report)

	return report

func _summarize_suite(results: Array) -> Dictionary:
	var total = results.size()
	var passed = 0
	var failed = 0
	var total_kills = 0
	var total_damage = 0
	var avg_level = 0.0
	var avg_fps = 0.0

	for r in results:
		if r["end_reason"] in ["timeout", "victory"]:
			passed += 1
		else:
			failed += 1
		total_kills += r["total_kills"]
		total_damage += r["total_damage"]
		avg_level += r["final_level"]
		avg_fps += r["fps_avg"]

	if total > 0:
		avg_level /= total
		avg_fps /= total

	return {
		"total": total,
		"passed": passed,
		"failed": failed,
		"total_kills": total_kills,
		"total_damage": total_damage,
		"avg_level": avg_level,
		"avg_fps": avg_fps,
	}

func _analyze_weapons(weapon_results: Array) -> Dictionary:
	var analysis: Dictionary = {}

	for r in weapon_results:
		var wid = r.get("forced_weapon", "")
		if wid.is_empty():
			continue

		var w_data = WeaponDB.get_weapon(wid)
		var w_name = w_data.get("name", wid) if not w_data.is_empty() else wid

		var entry = {
			"weapon_id": wid,
			"weapon_name": w_name,
			"measured_avg_dps": r["avg_dps"],
			"measured_peak_dps": r["peak_dps"],
			"total_damage": r["total_damage"],
			"total_kills": r["total_kills"],
			"duration": r["duration_game"],
			"status": "OK",
		}

		# Compare against expected
		if wid in _expected_dps:
			var expected = _expected_dps[wid]
			var expected_dps = expected["expected_dps"]
			entry["expected_dps"] = expected_dps
			entry["dps_ratio"] = r["avg_dps"] / maxf(expected_dps, 0.1)

			if r["avg_dps"] < expected_dps * expected["tolerance_low"]:
				entry["status"] = "UNDERPERFORMING"
			elif r["avg_dps"] > expected_dps * expected["tolerance_high"]:
				entry["status"] = "OVERPERFORMING"

		analysis[wid] = entry

	return analysis

func _analyze_characters(smoke_results: Array) -> Dictionary:
	var analysis: Dictionary = {}

	for r in smoke_results:
		var char_id = r["character"]
		analysis[char_id] = {
			"character": char_id,
			"survived": r["end_reason"] != "death",
			"survival_time": r["duration_game"],
			"final_level": r["final_level"],
			"total_kills": r["total_kills"],
			"total_damage": r["total_damage"],
			"avg_dps": r["avg_dps"],
			"final_hp_pct": (float(r["final_hp"]) / maxf(r["final_max_hp"], 1)) * 100.0,
			"weapons_acquired": r["weapons"].size(),
			"items_acquired": r["items"].size(),
		}

	return analysis

func _analyze_performance(results: Array) -> Dictionary:
	var fps_values: Array = []
	var min_fps = INF
	var low_fps_tests: Array = []

	for r in results:
		fps_values.append(r["fps_avg"])
		if r["fps_min"] < min_fps:
			min_fps = r["fps_min"]
		if r["fps_avg"] < 30.0:
			low_fps_tests.append(r["test_name"])

	var avg_fps = 0.0
	if not fps_values.is_empty():
		var total = 0.0
		for f in fps_values:
			total += f
		avg_fps = total / fps_values.size()
	else:
		min_fps = 0.0

	return {
		"avg_fps": avg_fps,
		"min_fps": min_fps,
		"low_fps_tests": low_fps_tests,
		"total_test_time_ms": _sum_real_time(results),
	}

func _sum_real_time(results: Array) -> int:
	var total = 0
	for r in results:
		total += r["duration_real_ms"]
	return total

func _print_report(report: Dictionary) -> void:
	print("\n")
	print("================================================================")
	print("              ZION AUTOMATED TEST REPORT")
	print("              %s" % report["timestamp"])
	print("================================================================\n")

	# Suite summaries
	for suite_name in report["summary"]:
		var s = report["summary"][suite_name]
		print("  [%s] %d/%d passed | Kills: %d | Avg Level: %.1f | Avg FPS: %.1f" % [
			suite_name.to_upper(), s["passed"], s["total"],
			s["total_kills"], s["avg_level"], s["avg_fps"]
		])
	print("")

	# Weapon DPS table
	if not report["weapon_analysis"].is_empty():
		_print_weapon_table(report["weapon_analysis"])

	# Character table
	if not report["character_analysis"].is_empty():
		_print_character_table(report["character_analysis"])

	# Performance
	var perf = report["performance_analysis"]
	print("  --- Performance ---")
	print("  Average FPS: %.1f | Minimum FPS: %.0f" % [perf["avg_fps"], perf["min_fps"]])
	print("  Total test time: %.1fs" % (perf["total_test_time_ms"] / 1000.0))
	if not perf["low_fps_tests"].is_empty():
		print("  WARNING: Low FPS (<30) in: %s" % ", ".join(perf["low_fps_tests"]))
	print("")

	# Outliers
	var outliers = _find_outliers(report["weapon_analysis"])
	if not outliers.is_empty():
		print("  --- OUTLIERS ---")
		for o in outliers:
			print("  %s" % o)
		print("")

	print("================================================================\n")

func _print_weapon_table(analysis: Dictionary) -> void:
	print("  --- Weapon DPS Analysis ---")
	print("  %-20s | %8s | %8s | %8s | %6s | %s" % [
		"Weapon", "Avg DPS", "Peak DPS", "Expected", "Ratio", "Status"
	])
	print("  %s" % ("-".repeat(78)))

	# Sort by weapon name
	var keys = analysis.keys()
	keys.sort()

	for wid in keys:
		var w = analysis[wid]
		var expected_str = "%.1f" % w.get("expected_dps", 0.0) if "expected_dps" in w else "N/A"
		var ratio_str = "%.2fx" % w.get("dps_ratio", 0.0) if "dps_ratio" in w else "N/A"
		var status_marker = ""
		if w["status"] == "UNDERPERFORMING":
			status_marker = "LOW"
		elif w["status"] == "OVERPERFORMING":
			status_marker = "HIGH"
		else:
			status_marker = "OK"

		print("  %-20s | %8.1f | %8.1f | %8s | %6s | %s" % [
			w["weapon_name"].left(20),
			w["measured_avg_dps"],
			w["measured_peak_dps"],
			expected_str,
			ratio_str,
			status_marker,
		])
	print("")

func _print_character_table(analysis: Dictionary) -> void:
	print("  --- Character Smoke Test ---")
	print("  %-12s | %8s | %5s | %6s | %8s | %7s | %s" % [
		"Character", "Survived", "Level", "Kills", "Damage", "HP%", "DPS"
	])
	print("  %s" % ("-".repeat(72)))

	var keys = analysis.keys()
	keys.sort()

	for char_id in keys:
		var c = analysis[char_id]
		print("  %-12s | %8s | %5d | %6d | %8d | %6.1f%% | %.1f" % [
			char_id.left(12),
			"YES" if c["survived"] else "DIED",
			c["final_level"],
			c["total_kills"],
			c["total_damage"],
			c["final_hp_pct"],
			c["avg_dps"],
		])
	print("")

func _find_outliers(weapon_analysis: Dictionary) -> Array:
	var outliers: Array = []

	for wid in weapon_analysis:
		var w = weapon_analysis[wid]
		if w["status"] == "UNDERPERFORMING":
			outliers.append("UNDERPERFORMING: %s - DPS %.1f is %.2fx of expected %.1f" % [
				w["weapon_name"], w["measured_avg_dps"],
				w.get("dps_ratio", 0), w.get("expected_dps", 0)
			])
		elif w["status"] == "OVERPERFORMING":
			outliers.append("OVERPERFORMING: %s - DPS %.1f is %.2fx of expected %.1f" % [
				w["weapon_name"], w["measured_avg_dps"],
				w.get("dps_ratio", 0), w.get("expected_dps", 0)
			])

	return outliers

func save_report(report: Dictionary, results: Array) -> String:
	var dir_path = "user://test_results"
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("test_results"):
		dir.make_dir("test_results")

	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var file_path = "%s/report_%s.json" % [dir_path, timestamp]

	var save_data = {
		"report": report,
		"results": results,
	}

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("  Report saved to: %s" % file_path)
		return file_path
	else:
		print("  ERROR: Could not save report to %s" % file_path)
		return ""

func load_and_print_report(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open %s" % file_path)
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		print("ERROR: Failed to parse JSON: %s" % json.get_error_message())
		return

	var data = json.data
	if data is Dictionary and "report" in data:
		_print_report(data["report"])
	else:
		print("ERROR: Invalid report format")
