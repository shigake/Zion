# Testing Patterns

**Analysis Date:** 2026-04-02

## Test Framework

**Runner:** Godot 4 built-in (GDScript, no external test framework). Tests are GDScript nodes that run inside the engine.

**Assertion style:** `print("PASS: ...")` / `print("WARN: ...")` / `print("FAIL: ...")` to stdout. No assertion library. Pass/fail determined by string matching in CI (`grep -q "PASS"`).

**Orchestrator:** `game/scripts/autoload/auto_tester.gd` — autoload activated only when `--test=<suite>` is passed on the command line.

**Run Commands:**
```bash
godot --path game --run -- --test=smoke          # 26 tests (chars + stages + modes)
godot --path game --run -- --test=combo          # 150 combos (15 chars x 10 stages)
godot --path game --run -- --test=weapons        # All 32 weapons
godot --path game --run -- --test=evolution      # 12 crystal resonances
godot --path game --run -- --test=events         # Full event timeline
godot --path game --run -- --test=stress         # Hyper, max enemies, endless
godot --path game --run -- --test=achievements   # 7 scenarios
godot --path game --run -- --test=balance        # XP, DPS, economy
godot --path game --run -- --test=menu_smoke     # Menu navigation
godot --path game --run -- --test=all            # All suites

# Standalone (no autoloads, headless):
godot --headless --script res://scripts/tests/balance_test.gd
```

## Test File Organization

**Location:** `game/scripts/tests/` — all test files co-located in one directory.

**Files:**
- `game/scripts/tests/auto_player.gd` — AI controller for automated runs
- `game/scripts/tests/balance_test.gd` — Standalone balance math (headless)
- `game/scripts/tests/menu_smoke_test.gd` — Menu navigation test
- `game/scripts/tests/test_report.gd` — Report generation and analysis
- `game/scripts/tests/test_runner.gd` — Suite builder and run coordinator

**Orchestrator:** `game/scripts/autoload/auto_tester.gd` — parses CLI args, spawns TestRunner/TestReport, starts the right suite.

**Naming:** `smoke_char_ronin`, `weapon_katana`, `combo_mago_tokyo`, `stress_hyper` — always `suite_subject` format.

## Test Structure

**Test cases are Dictionaries**, not class instances:
```gdscript
{
    "name": "combo_mago_tokyo",
    "suite": "combo",
    "character": "mago",
    "stage": "tokyo",
    "duration": 60.0,
    "choose_mode": "random",
    "forced_weapon": "",
    "game_mode": "normal",
}
```

**Suite builder pattern** — `TestRunner.build_suite(suite_name)` returns an `Array` of test dictionaries:
```gdscript
func build_suite(suite_name: String) -> Array:
    match suite_name:
        "smoke":  return _build_smoke_tests()
        "combo":  return _build_combo_tests()
        "all":
            tests.append_array(_build_smoke_tests())
            tests.append_array(_build_weapon_tests())
            # ...
```

**Smoke tests**: 15 characters on Cemetery (30s each) + 10 stages with Ronin (30s each) + 4 game modes = 26 tests.

**Combo tests**: Full 150-combo matrix — every character × every stage, 60s each. Total ~2.5 hours.

**Weapon tests**: Each weapon ID forced as primary weapon, 45s run, measures actual DPS.

**Balance test** (`balance_test.gd`) is standalone — extends `SceneTree`, runs without autoloads, exits with `quit()`. Used in CI headless:
```gdscript
extends SceneTree
func _init() -> void:
    _test_weapon_dps(weapons)
    _test_xp_curve()
    _test_spawn_rate()
    _test_difficulty_curve()
    quit()
```

## Test Execution Flow

1. `godot --run -- --test=smoke` launches the game normally with autoloads
2. `AutoTester._ready()` parses `--test=smoke` from `OS.get_cmdline_user_args()`
3. `AutoTester` defers `_start_testing()`, creates `TestRunner` and `TestReport` nodes
4. `TestRunner.build_suite("smoke")` returns test array
5. For each test: configure `GameManager` state, load stage scene, attach `AutoPlayer` to player
6. Run for `test.duration` seconds of in-game time
7. Collect metrics: kills, damage, DPS, FPS, level, HP, events triggered
8. On timeout: emit `test_completed(result)` signal
9. After all tests: `TestReport.generate_report(results)` prints formatted tables
10. Save JSON report to `user://test_results/report_<timestamp>.json`

## AutoPlayer (AI Controller)

`game/scripts/tests/auto_player.gd` — attaches to the `CharacterBody3D` player node and overrides input with intelligent behavior. Strategies:

- `wander` — random direction changes
- `flee` — escape from threats within `flee_radius: 15.0`
- `collect` — move toward XP gems and crystals within `collect_radius: 25.0`
- `center` — return to center if > `center_max_distance: 60.0` from origin

Anti-stuck detection: if not moved `stuck_threshold: 0.5` units in `stuck_timeout: 2.0` seconds, picks a perpendicular direction.

Special mode `avoid_attacks: bool = true` for pacifist achievement test — only flees, no weapons active.

## Mocking

No dedicated mock framework. Tests rely on the real game systems running. State is controlled by:
- Setting `GameManager.selected_character`, `GameManager.selected_stage` before running
- Using `forced_weapon` in test config to force a specific weapon via `_forced_weapon` field
- Setting `_auto_choose_mode: String` to `"random"`, `"prioritize_weapons"`, `"prioritize_items"`, or `"forced"`

Level-up screens are intercepted by `TestRunner` watching for `LevelUpScreen` node and auto-selecting options.

## Metrics Collected Per Test

Result dictionaries contain:
```gdscript
{
    "test_name": "smoke_char_ronin",
    "suite": "smoke",
    "character": "ronin",
    "stage": "cemetery",
    "end_reason": "timeout",   # timeout | victory | death
    "total_kills": int,
    "total_damage": int,
    "avg_dps": float,
    "peak_dps": float,
    "final_level": int,
    "final_hp": int,
    "final_max_hp": int,
    "fps_avg": float,
    "fps_min": float,
    "duration_game": float,
    "duration_real_ms": int,
    "weapons": Array,          # [{id, level}]
    "items": Array,
    "events_triggered": Array,
    # Suite-specific:
    "evolution_triggered": bool,
    "achievement_unlocked": bool,
    "crystals_earned": int,
}
```

## Report Generation

`game/scripts/tests/test_report.gd` — generates analysis from collected results:

- **Weapon DPS table**: measures actual vs. theoretical DPS with `tolerance_low: 0.3` and `tolerance_high: 3.0`. Status: `OK`, `UNDERPERFORMING`, or `OVERPERFORMING`.
- **Character table**: survival, level, kills, damage, HP%, DPS per character.
- **Evolution table**: was evolution triggered, pre/post DPS, multiplier vs. expected.
- **Achievement table**: was achievement unlocked, end reason, duration.
- **Event table**: which events fired, which never appeared across all tests.
- **Balance analysis**: XP curve (levels/min), DPS curve, economy (crystals/min).
- **Performance**: average and minimum FPS across all tests, lists tests under 30 FPS.

Outliers are flagged: weapons performing below 30% or above 300% of expected DPS.

Report saved as JSON: `user://test_results/report_<YYYY-MM-DD_HH-MM-SS>.json`.

## CI Test Configuration

CI defined in `.github/workflows/ci.yml`. Two jobs:

**`validate` job** (runs on push to main/develop):
1. Installs Godot 4.4.1 headless on ubuntu-latest
2. Runs `godot --headless --import project.godot` to validate project structure
3. Checks for critical ERRORs/FATAL in import log
4. Verifies essential files exist: `project.godot`, `VERSION`, `scenes/`, `scripts/`, `assets/`
5. Prints counts: number of `.tscn` and `.gd` files, current version

**`balance-test` job** (needs validate):
1. Runs `godot --headless --script res://scripts/tests/balance_test.gd` with 120s timeout
2. Checks output for `PASS`/`FAIL` strings
3. Fails CI if any FAIL found, warns if inconclusive

The full interactive suites (smoke, combo, weapons) are **not run in CI** — they require a rendered scene tree and are run manually by developers. Only `balance_test.gd` runs headless in CI because it extends `SceneTree` directly.

## Coverage

**No coverage tool.** Coverage is assessed by which suites have been run manually.

**Suites not in CI:**
- `smoke` (26 tests, ~13 min)
- `combo` (150 tests, ~2.5 hours)
- `weapons` (32 tests, ~24 min)
- `evolution` (12 tests)
- `events` (full timeline)
- `stress` (hyper/max enemies)
- `achievements` (7 scenarios)
- `menu_smoke` (9 menus)

**In CI:** `balance_test.gd` only (XP curve, spawn rate, DPS math, difficulty analysis).

**Results location:** `user://test_results/` (platform-specific Godot user data dir).

## Menu Smoke Test

`game/scripts/tests/menu_smoke_test.gd` — separate flow from the main TestRunner. Opens each of 9 menus from `main_menu.tscn`, waits `WAIT_AFTER_LOAD: 1.0s`, presses ESC, waits `WAIT_AFTER_ESC: 1.0s`, verifies no crash. Uses `await` throughout:

```gdscript
for i in range(MENU_SCENES.size()):
    await _test_menu(MENU_SCENES[i])
completed.emit(_results)
```

Menus tested: Character Select, Lobby, Shop, Daily Challenge, Leaderboard, Bestiary, Codex, Options, Credits.

---

*Testing analysis: 2026-04-02*
