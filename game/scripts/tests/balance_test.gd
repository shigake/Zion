extends SceneTree

## Teste de balanceamento standalone — roda sem autoloads.
## Uso: godot --headless --path game --script res://scripts/tests/balance_test.gd

func _init() -> void:
	print("=== ZION BALANCE TEST ===\n")

	# Weapon data inline (mirror de weapon_db.gd)
	var weapons = {
		"katana": {"name": "Espada Samurai", "base_damage": 15, "base_cooldown": 0.8, "damage_per_level": 4, "cooldown_per_level": -0.08},
		"staff": {"name": "Staff Magico", "base_damage": 8, "base_cooldown": 1.5, "damage_per_level": 3, "cooldown_per_level": -0.1},
		"scythe": {"name": "Foice", "base_damage": 10, "base_cooldown": 0.3, "damage_per_level": 3, "cooldown_per_level": 0},
		"machinegun": {"name": "Metralhadora", "base_damage": 6, "base_cooldown": 0.15, "damage_per_level": 2, "cooldown_per_level": -0.01},
		"bazooka": {"name": "Bazuca", "base_damage": 30, "base_cooldown": 3.5, "damage_per_level": 10, "cooldown_per_level": -0.2},
		"necro": {"name": "Necromante", "base_damage": 6, "base_cooldown": 4.0, "damage_per_level": 2, "cooldown_per_level": -0.3},
	}

	_test_weapon_dps(weapons)
	_test_xp_curve()
	_test_spawn_rate()
	_test_difficulty_curve()
	print("\n=== ALL TESTS DONE ===")
	quit()

func _test_weapon_dps(weapons: Dictionary) -> void:
	print("--- WEAPON DPS BY LEVEL ---")
	for wid in weapons:
		var w = weapons[wid]
		print("  %s:" % w["name"])
		for level in range(1, 9):
			var dmg = w["base_damage"] + w["damage_per_level"] * (level - 1)
			var cd = maxf(0.05, w["base_cooldown"] + w["cooldown_per_level"] * (level - 1))
			var dps = dmg / cd
			print("    Lv%d: dmg=%d cd=%.2f dps=%.1f" % [level, dmg, cd, dps])
	print("")

func _test_xp_curve() -> void:
	print("--- XP CURVE (levels over 30 min) ---")
	var xp = 0
	var xp_to_next = 5
	var level = 1

	var kills_per_minute = [20, 30, 50, 70, 90, 110, 130, 150, 170, 190,
		200, 210, 220, 230, 240, 250, 260, 270, 280, 290,
		300, 310, 320, 330, 340, 350, 360, 370, 380, 390]

	for minute in range(30):
		var xp_this_minute = int(kills_per_minute[minute] * 2.0)  # avg 2 xp per kill now
		xp += xp_this_minute
		var levels_this_minute = 0
		while xp >= xp_to_next:
			xp -= xp_to_next
			level += 1
			xp_to_next = int(xp_to_next * 1.15) + 3
			levels_this_minute += 1
		if minute % 5 == 0 or minute == 29:
			print("  Min %02d: Level %d (xp_to_next=%d)" % [minute, level, xp_to_next])

	print("  Final level: %d" % level)
	if level >= 25 and level <= 50:
		print("  PASS: Level range OK (25-50 expected)")
	else:
		print("  WARN: Level %d outside expected 25-50" % level)
	print("")

func _test_spawn_rate() -> void:
	print("--- SPAWN RATE ---")
	var base_interval = 1.2
	var base_count = 2
	for minute in [0, 5, 10, 15, 20, 25, 30]:
		var time = minute * 60.0
		var mult = minf(8.0, 1.0 + (time / 60.0) * 0.35)
		var interval = maxf(0.15, base_interval / mult)
		var count = int(base_count * mult)
		var spawns_per_sec = count / interval
		var enemies_per_min = spawns_per_sec * 60
		print("  Min %02d: %.0f enemies/min (mult=%.1f)" % [minute, enemies_per_min, mult])
	print("")

func _test_difficulty_curve() -> void:
	print("--- DIFFICULTY ANALYSIS ---")
	var boss_hp = 2000.0

	# Katana Lv8 DPS
	var katana_dps = (15 + 4 * 7) / maxf(0.05, 0.8 + (-0.08) * 7)
	# Staff Lv8 DPS
	var staff_dps = (8 + 3 * 7) / maxf(0.05, 1.5 + (-0.1) * 7)
	# Machinegun Lv8 DPS
	var mg_dps = (6 + 2 * 7) / maxf(0.05, 0.15 + (-0.01) * 7)

	var total_dps = katana_dps + staff_dps + mg_dps
	print("  Estimated DPS at Lv8 (3 weapons): %.0f" % total_dps)
	print("    Katana: %.1f | Staff: %.1f | MG: %.1f" % [katana_dps, staff_dps, mg_dps])

	var boss_ttk = boss_hp / total_dps
	print("  Boss TTK: %.1fs" % boss_ttk)
	if boss_ttk >= 3.0 and boss_ttk <= 30.0:
		print("  PASS: Boss fight 3-30s range")
	else:
		print("  WARN: Boss TTK %.1fs outside 3-30s" % boss_ttk)

	# Player survival
	print("  Player HP 100 vs Slime (8 dmg): dies in ~12 hits")
	print("  Player HP 100 vs Boss (35 dmg): dies in ~3 hits")
	print("  With armor 16 (max shop): Boss hits for 19, dies in ~5 hits")
	print("")
