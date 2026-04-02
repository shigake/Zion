# Codebase Concerns

**Analysis Date:** 2026-04-02

---

## Tech Debt

**Dynamic GDScript generation in weapon and boss systems:**
- Issue: Five scripts compile and execute GDScript source code strings at runtime using `GDScript.new()` + `source_code = "..."` + `script.reload()`. This is an unusual pattern that bypasses static typing, breaks tooling, and is difficult to debug.
- Files: `game/scripts/weapons/boomerang.gd:144`, `game/scripts/weapons/portal_weapon.gd:176`, `game/scripts/weapons/shuriken.gd:204`, `game/scripts/weapons/time_bomb.gd:127`, `game/scripts/enemies/boss_attack_patterns.gd:200`
- Impact: Any syntax error in the string silently produces a broken object at runtime; no autocomplete, no error highlighting. `script.reload()` is expensive and runs every time an instance of these behaviors is created.
- Fix approach: Extract each string into a dedicated `.gd` file and preload it. The generated script strings in each case are short and self-contained.

**Locale dictionary hardcoded inline in locale_manager.gd:**
- Issue: All 10 locales × all keys are stored in a 682-line GDScript dictionary. Adding a new translation key requires editing this single large file.
- Files: `game/scripts/autoload/locale_manager.gd`
- Impact: High merge conflict risk for parallel work; no external tool (e.g., PO files, CSV) can be used; locale data is not hot-reloadable.
- Fix approach: Move translations to CSV or JSON files per locale under `game/assets/locales/` and load at runtime. Godot's built-in CSV translation import supports this natively.

**`_cached_nearest_player` dictionary not cleared on `GameManager.reset()`:**
- Issue: `_cached_nearest_player` (maps enemy instance ID → nearest player node) is populated during a run and never cleared in `game/scripts/autoload/game_manager.gd:reset()`. After a run ends, stale instance IDs accumulate.
- Files: `game/scripts/autoload/game_manager.gd:39`, `game/scripts/autoload/game_manager.gd:620`
- Impact: Memory leak across runs. In long sessions with many runs, this dictionary retains freed node references via instance IDs; could cause incorrect nearest-player results if an ID is recycled.
- Fix approach: Add `_cached_nearest_player.clear()` and reset `_nearest_player_frame = -1` inside `reset()`.

**`GameManager.reset()` manually lists every stat variable (~70 lines):**
- Issue: The reset function is 80+ lines of manual variable assignments. When new stat variables are added (as happened repeatedly with PRD 28), they are easy to omit from reset.
- Files: `game/scripts/autoload/game_manager.gd:620`
- Impact: Risk of run bleed — stats carrying over between runs silently. Already seen with `_no_damage_streak` and `dps_peak` requiring separate tracking.
- Fix approach: Group all per-run stats into a nested struct or inner class and replace them atomically. Alternatively, add a CI test that runs two back-to-back runs and asserts stat independence.

**Spatial grid rebuilt on every `get_nearby_enemies` / `get_enemies_in_radius` call:**
- Issue: `_spatial_grid.rebuild(get_enemies())` is called unconditionally inside both query functions, not once per frame.
- Files: `game/scripts/autoload/game_manager.gd:362`, `game/scripts/autoload/game_manager.gd:366`
- Impact: If two weapons query nearby enemies in the same frame, the grid is rebuilt twice. With 200 enemies, this is O(N) × call count per frame.
- Fix approach: Cache the rebuild with a frame counter, matching the existing `_enemies_cache_frame` pattern used for `get_enemies()`.

**LAN rate limiter is a plain in-memory object, not per-IP per route:**
- Issue: The `rateLimiter` object in `server/index.js` keys on `req.ip + req.path`, which works for a single-process server but resets on every restart and is not shared across processes. Cleanup interval runs every 5 minutes but keys are only pruned for entries older than 60 seconds regardless of window.
- Files: `server/index.js:200`
- Impact: Rate limit state lost on server restart; memory leak from routes with infrequent traffic that accumulate entries between cleanups.
- Fix approach: Low priority for a telemetry server. Acceptable as-is until player numbers grow. For production, replace with `express-rate-limit` + an in-memory or Redis store.

---

## Known Bugs

**Pickup groups iterated at full tree-scan cost on magnet collect:**
- Symptoms: When a magnet pickup is collected, `get_tree().get_nodes_in_group("xp_gems")`, `get_tree().get_nodes_in_group("crystals")`, and `get_tree().get_nodes_in_group("health_pickups")` are all called in sequence. With 200 pickups capped, this is three O(N) full-group walks in a single frame.
- Files: `game/scripts/magnet_pickup.gd:99-114`
- Trigger: Player collects a magnet pickup.
- Workaround: None. Effect is a single-frame spike, not ongoing.

**Enemies pooled without `_reset_for_reuse()` on `EnemyBase3D`:**
- Symptoms: The `ObjectPool` calls `_reset_for_reuse()` if the method exists. `EnemyBase3D` does not implement it. Regular enemies returned to the pool via `EnemyCuller` carry stale state: `is_dead = true`, stale `_sprite_path_cache` entries on the class-level static dict, `_hit_count`, `_behavior` variables, and tweens.
- Files: `game/scripts/enemies/enemy_base.gd`, `game/scripts/enemies/enemy_culler.gd:252`, `game/scripts/autoload/object_pool.gd:39`
- Trigger: Enemies culled and re-pooled by `EnemyCuller`, then re-spawned in the same run. The `EnemyCuller` returns instances via `ObjectPool.return_instance()` but enemies rely on `_ready()` which does not re-run on reuse.
- Workaround: `EnemyCuller` currently culls via pool and adds enemies back to the scene; the pool's `get_instance` will reset processing flags but not game state.

**`spawn_on_death` behavior instantiates directly, bypasses object pool:**
- Symptoms: When a Scarecrow (farm stage) dies, it spawns 3 `bat.tscn` instances via `preload().instantiate()`, not through `ObjectPool.get_instance()`. Spawned bats are added via `call_deferred("add_child", crow)` which delays their addition — the `GameManager.enemies_alive` counter increments immediately at line 860, before the child is actually in the tree.
- Files: `game/scripts/enemies/enemy_base.gd:851-860`
- Trigger: Scarecrow killed in farm stage.
- Workaround: None currently.

---

## Security Considerations

**Telemetry server POST endpoints accept unauthenticated writes by design:**
- Risk: Any actor knowing the server URL can submit arbitrary telemetry runs, crash reports, or leaderboard scores (with only soft rate limiting as defense).
- Files: `server/index.js:179` — `if (!API_KEY) return next();` skips auth for all POST routes when `API_KEY` env var is unset (which is the default per `.env.example`).
- Current mitigation: Per-IP rate limiting (30 runs/min for telemetry, 1 leaderboard submit/10s). Leaderboard score is capped at 0–100,000 range. Player name trimmed to 32 characters.
- Recommendations: Set `API_KEY` in production. Add content-type validation to reject non-JSON bodies without relying on Express's default `400` behavior. Consider adding a simple shared secret header from the game client.

**No input sanitization beyond string truncation for `player_name`:**
- Risk: `player_name` values are stored directly and returned in leaderboard queries. XSS is not applicable to the dashboard if it escapes HTML, but log injection and data integrity issues are possible.
- Files: `server/index.js:677`
- Current mitigation: `better-sqlite3` uses parameterized queries throughout — SQL injection is not a risk. Name is sliced to 32 chars.
- Recommendations: Strip non-printable characters from `player_name`. Document that the dashboard HTML template must escape output.

**CORS allows all origins (`*`) on all routes:**
- Risk: In a deployed context, this allows any web page to read leaderboard data and submit scores on behalf of a browser visitor.
- Files: `server/index.js:170`
- Current mitigation: The server is intended for internal/LAN use. Leaderboard abuse is rate-limited.
- Recommendations: Lock CORS origin to the game client's domain or remove wildcard before public deployment.

---

## Performance Bottlenecks

**`get_tree().get_nodes_in_group()` called outside `GameManager` cache:**
- Problem: Several scripts call `get_nodes_in_group` directly without going through `GameManager.get_enemies()` or `GameManager.get_players()`, bypassing the per-frame cache.
- Files: `game/scripts/autoload/multimesh_manager.gd:187`, `game/scripts/autoload/multimesh_manager.gd:269`, `game/scripts/crystal_pickup.gd:48`, `game/scripts/magnet_pickup.gd:99-111`, `game/scripts/enemies/enemy_spawner.gd:357`
- Cause: These callers predate or are outside the scope of the centralized enemy cache.
- Improvement path: Route all group queries through `GameManager.get_enemies()` / `GameManager.get_players()` to benefit from frame-level caching.

**`enemy_base.gd` calls `Engine.get_frames_per_second()` inline in `_die()`:**
- Problem: `_die()` captures FPS inline at `game/scripts/enemies/enemy_base.gd:796`. During mass-death frames (horde explosions), this is called many times per frame.
- Files: `game/scripts/enemies/enemy_base.gd:796`
- Cause: Optimization artifact — the FPS value should use the cached `_cached_fps` from `enemy_spawner` or `GameManager`.
- Improvement path: Read from a shared cached FPS value updated once per frame. Low priority.

**`locale_manager.gd` is a 682-line dictionary parsed at startup:**
- Problem: The entire 10-language translation table is parsed at engine startup as a GDScript dictionary literal. On lower-end hardware this contributes to script parse time.
- Files: `game/scripts/autoload/locale_manager.gd`
- Cause: See Tech Debt section above.
- Improvement path: External CSV/JSON loaded asynchronously, or lazy-loaded per locale.

---

## Fragile Areas

**`GameManager` singleton — 878 lines, central god-object:**
- Files: `game/scripts/autoload/game_manager.gd`
- Why fragile: Holds all run-time state (HP, weapons, items, stats, accessibility flags, multiplayer mode, NG+, aim direction, difficulty), all item modifier floats, the spatial grid, per-frame caches, and all signal dispatching. Any modification to item modifiers or per-run stats affects this file.
- Safe modification: Add new per-run stat variables near line 51 (PRD 28 block). Always add corresponding `clear`/`reset` call in `reset()` at line 620. Never call `get_enemies()` or `get_players()` from within the same frame more than once — use the cached result.
- Test coverage: Partially covered by `balance_test.gd` and `test_runner.gd`, but no unit tests isolate `GameManager.reset()`.

**Multiplayer state sync — host migration relies on partial snapshot:**
- Files: `game/scripts/autoload/multiplayer_manager.gd:520`
- Why fragile: `_send_full_state_to_peer` syncs only 8 fields (`game_time`, `enemies_alive`, `total_kills`, `crystals_this_run`, `player_level`, `player_xp`, `player_xp_to_next`, `max_enemies`, `events_triggered`). It does not sync player weapon lists, item lists, or stat modifiers. A client that reconnects after host migration will have correct progression counters but wrong loadout.
- Safe modification: Treat host migration as a last-resort recovery path, not a seamless handoff. Any multiplayer features that modify the loadout mid-run must also update the migration snapshot.
- Test coverage: No automated test for host migration path.

**Dynamic script strings in weapon behaviors — no compile-time safety:**
- Files: `game/scripts/weapons/boomerang.gd`, `game/scripts/weapons/portal_weapon.gd`, `game/scripts/weapons/shuriken.gd`, `game/scripts/weapons/time_bomb.gd`, `game/scripts/enemies/boss_attack_patterns.gd`
- Why fragile: Any typo in the string body produces a runtime error that only appears when the weapon/boss is actually used. The shuriken spin script at `shuriken.gd:204` is reused across all shuriken instances (shared `_ShurikenSpinScript`) — modifying it affects all active shurikens.
- Safe modification: Do not edit the string body without testing the weapon's full lifecycle (create → fire → hit → pool return). Keep each string minimal.
- Test coverage: Covered indirectly by `test_runner.gd` weapon tests.

**Save file format — no versioning or migration:**
- Files: `game/scripts/autoload/save_manager.gd:91`
- Why fragile: `_apply_save_json` merges loaded keys directly into `data` with `data[key] = loaded[key]`. New keys added in future updates are silently ignored by old saves; removed keys from old saves are silently loaded as unexpected keys. No schema version field exists.
- Safe modification: Always add new save keys with a default value in the `data` dictionary definition (line 7) so they are populated when missing. Never remove a key name that was previously serialized — rename instead.
- Test coverage: None.

**`enemy_base.gd` static sprite and path caches are class-level:**
- Files: `game/scripts/enemies/enemy_base.gd:40-41` — `static var _sprite_cache`, `static var _sprite_path_cache`
- Why fragile: These are `static var` on the class, meaning they persist across scene changes and runs. If a sprite file changes on disk during development, the cache returns the stale texture. In production this is safe, but the caches are never cleared.
- Safe modification: Acceptable for release builds. During development, restart the editor or clear caches manually if sprite assets are regenerated.

---

## Uncommitted Changes (git status at analysis time)

The following files have modifications not yet committed:

- `game/assets/sprites/characters/mago.png.import` — modified import metadata
- `game/assets/sprites/characters/ronin.png.import` — modified import metadata
- `game/assets/sprites/characters/soldado.png.import` — modified import metadata
- `game/assets/sprites/enemies/slime.png.import` — modified import metadata
- `game/scripts/health_pickup.gd` — modified (stats tracking added: `health_pickups_used`)
- `game/scripts/magnet_pickup.gd` — modified (stats tracking added: `magnets_collected`)
- `game/scripts/player/player.gd` — modified

Untracked files:
- `game/scripts/tools/melee_sprite_gen_v2.gd` — new tool script, not yet staged
- `game/scripts/ui/stats_detail_tab.gd` — new UI script for PRD 28 §4 stats panel, not yet staged

---

## Test Coverage Gaps

**`GameManager.reset()` not unit-tested:**
- What's not tested: That all per-run stat variables return to their default values after a reset. New variables added without a corresponding reset assignment go undetected.
- Files: `game/scripts/autoload/game_manager.gd:620`
- Risk: Silent stat bleed between consecutive runs.
- Priority: High

**Host migration / reconnect flow not automated:**
- What's not tested: Client state after host migration (weapons, items, modifiers intact); reconnect after 3 failed attempts; lobby state sync after stage selection.
- Files: `game/scripts/autoload/multiplayer_manager.gd:490`
- Risk: Loadout desync in co-op. Untestable headlessly with current test framework.
- Priority: Medium

**No test for seeded run determinism:**
- What's not tested: That two runs with the same seed produce the same event timeline, spawn pattern, and chest positions.
- Files: `game/scripts/stages/event_manager.gd:_ready`, `game/scripts/autoload/daily_challenge.gd`
- Risk: Daily challenge leaderboard unfairness if seed behavior is platform-dependent.
- Priority: Medium

**Pool reuse correctness not tested:**
- What's not tested: That an enemy returned to the pool via `EnemyCuller` and re-acquired via `ObjectPool.get_instance()` begins the new spawn with clean state (e.g., `is_dead = false`, correct HP, no stale behavior).
- Files: `game/scripts/autoload/object_pool.gd`, `game/scripts/enemies/enemy_base.gd`
- Risk: Invisible dead enemies or enemies with wrong HP from recycled instances.
- Priority: Medium

**Steam integration not tested in CI:**
- What's not tested: Achievement unlock, cloud save/load, lobby creation when GodotSteam plugin is absent (fallback path).
- Files: `game/scripts/autoload/steam_manager.gd`
- Risk: Silent failures on platforms without GodotSteam installed; achievement state mismatch.
- Priority: Low (plugin not yet installed per CLAUDE.md)

---

*Concerns audit: 2026-04-02*
