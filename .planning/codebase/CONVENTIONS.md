# Coding Conventions

**Analysis Date:** 2026-04-02

## Language and Runtime

All game logic is written in GDScript (Godot 4). No TypeScript, Python, or other languages in `game/`. The Node.js server in `server/` uses JavaScript (Express + SQLite) but is a separate telemetry concern.

## Naming Patterns

**Files:**
- `snake_case.gd` for all GDScript files: `enemy_base.gd`, `game_manager.gd`, `auto_tester.gd`
- Scene files match their script: `enemy_base.gd` → `enemy_base.tscn`
- Bosses prefixed: `boss_necromancer.gd`, `boss_dracula.gd`
- Autoloads named in PascalCase in project.godot: `GameManager`, `WeaponDB`, `LogManager`

**Functions:**
- Public functions: `snake_case` — `get_weapon_level()`, `add_xp()`, `check_synergies()`
- Private/internal functions: leading underscore — `_apply_sprite()`, `_flush()`, `_find_target()`
- Lifecycle methods follow Godot conventions: `_ready()`, `_process()`, `_physics_process()`
- Signal handlers: `_on_body_entered()`, `_on_level_up()`, `_on_timeline_boss_spawned()`
- Builder helpers in test code: `_build_smoke_tests()`, `_build_weapon_tests()`

**Variables:**
- Public state: `snake_case` — `game_time`, `player_level`, `is_dead`
- Private state: leading underscore `_snake_case` — `_log_file`, `_buffer`, `_flash_tween`
- Boolean vars: named as state, not questions — `is_dashing`, `is_dead`, `can_be_hurt`, `_active`
- Timers: `_something_timer: float` pattern — `_dodge_timer`, `_wander_change_timer`
- Cached lookups: `_cached_enemies`, `_cached_nearest_player`, `_sprite_cache`

**Constants:**
- `ALL_CAPS_SNAKE_CASE` for module-level const — `PLAYER_BASE_SPEED`, `BOSS_SPAWN_TIME`
- Grouped with `# ====` section headers in `game_constants.gd`
- Category prefixes for clarity: `PLAYER_`, `ENEMY_`, `BOSS_`, `SPAWN_`, `PICKUP_`, `FPS_`

**Types/Classes:**
- `class_name` in PascalCase when declared: `class_name EnemyBase3D`
- Export variables use type annotations: `@export var speed: float = 4.0`

## Type Annotations

Use static typing throughout. Return types are declared on all non-trivial functions:

```gdscript
func get_run_stats() -> Dictionary:
func add_xp(amount: int) -> void:
func get_difficulty_multiplier() -> float:
func get_enemies() -> Array:
func _generate_session_id() -> String:
```

Typed arrays used when possible:
```gdscript
var _entries: Array[Dictionary] = []
var _fps_samples: Array[float] = []
var _log_files: Array[String] = []
```

## Module Documentation

Every script file begins with a `##` docblock describing purpose:

```gdscript
## Estado global do jogo: XP, level, dificuldade, pause, stats.

## Constantes centralizadas do projeto. Fonte unica de verdade para
## listas, valores de balance e configuracoes de display.
## Todas as magic numbers do jogo devem viver aqui.
```

Public API functions get `##` inline docstrings:
```gdscript
## Retorna as ultimas N entradas do log
func get_recent_entries(count: int = 50, min_level: Level = Level.DEBUG) -> Array[Dictionary]:

## Gera um crash report manual (pode ser chamado de qualquer lugar)
func report_crash(module: String, description: String, extra_data: Dictionary = {}) -> String:
```

Internal sections use `# ====` separators:
```gdscript
# ==== PUBLIC API ====
# ==== INTERNAL ====
```

## Constants Pattern (game_constants.gd)

All magic numbers and configuration values live in `game/scripts/autoload/game_constants.gd` (690 lines, 29 categories). This is the single source of truth. Never hardcode magic numbers in individual scripts.

Structure:
```gdscript
# ==================================================================
# PLAYER
# ==================================================================
const PLAYER_BASE_SPEED := 8.0
const PLAYER_DASH_SPEED := 24.0

# ---- Walk Animation ----
const WALK_BOB_BASE_FREQ := 8.0
```

Categories: FENDAS, DISPLAY, BALANCE, PLAYER, ENEMY BASE, ENEMY ELITE, ENEMY SPAWNER, BOSS, DROPS, VISUAL, SCREEN EFFECTS, STAGE BEHAVIORS, DAMAGE COLORS, MULTIPLAYER, DIFFICULTY, EVENTS, CAMERA, and more.

Scripts reference constants as `GameConstants.PLAYER_BASE_SPEED`, never inline values.

## Import Organization

Godot 4 `@onready` declarations group node references at the top of a class body:
```gdscript
@onready var hp_bar: ProgressBar = $MarginContainer/VBox/HPBar
@onready var level_label: Label = $MarginContainer/VBox/LevelLabel
```

`@export` declarations come before `@onready`:
```gdscript
@export var base_speed: float = GameConstants.PLAYER_BASE_SPEED
@export var player_id: int = 1
```

`preload()` is used inside functions for scene scripts to avoid load-time overhead:
```gdscript
_animator = preload("res://scripts/effects/procedural_animator.gd").new()
_trail = preload("res://scripts/effects/weapon_trail.gd").new()
```

## Error Handling

**No `push_error`/`push_warning` directly** — route all errors through `LogManager`:

```gdscript
LogManager.warn("BaseStage", "Personagem desconhecido: '%s'. Usando katana como fallback." % char_id)
LogManager.error("MP", "Connection failed: %s" % err)
LogManager.fatal("Game", "Unrecoverable state")
```

LogManager calls have two arguments: a module tag (string) and a message. Module tag is always a short PascalCase or abbreviated name: `"Audio"`, `"Game"`, `"Event"`, `"Chest"`, `"DailyChallenge"`.

Guard patterns for optional nodes:
```gdscript
if not _world_hp_bar or not _world_hp_bg:
    return
var gm = get_node_or_null("/root/GameManager")
if gm:
    # safe to use
```

File I/O always guards the result:
```gdscript
var file = FileAccess.open(file_path, FileAccess.WRITE)
if file:
    file.store_string(json_text)
    file.close()
else:
    LogManager.error("LogManager", "Failed to save: %s" % file_path)
```

Graceful fallbacks instead of crashes:
```gdscript
if not char_data.is_empty() and "starting_weapon" in char_data:
    start_weapon = char_data["starting_weapon"]
# Else keep default "katana"
```

## Logging

Use `LogManager` (autoload) with 5 levels: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `FATAL`.

```gdscript
LogManager.debug("Weapon", "DPS calc: %s" % dps)
LogManager.info("Player", "Spawned at %s" % pos)
LogManager.warn("Audio", "File not found: %s" % path)
LogManager.error("MP", "Connection failed: %s" % err)
LogManager.fatal("Game", "Unrecoverable state")
```

Logs are buffered (5-entry buffer) and flushed every 5 seconds. Ring buffer stores last 500 entries. Crash reports generated as JSON in `user://logs/crashes/`.

## Signal Usage

Signals declared at the top of each class with typed parameters:
```gdscript
signal player_leveled_up(new_level: int)
signal enemy_killed(position: Vector3, xp_value: int)
signal test_completed(result: Dictionary)
signal synergy_activated(synergy_name: String, synergy_data: Dictionary)
```

Connections made in `_ready()`:
```gdscript
hitbox.body_entered.connect(_on_body_entered)
GameManager.player_leveled_up.connect(_on_level_up)
```

## Performance Conventions

**Object pooling** via `ObjectPool` autoload — never `queue_free()` enemies mid-gameplay, return them instead:
```gdscript
ObjectPool.return_instance(instance, scene_file_path)
```

**Static caches** on enemy/weapon classes for shared resources:
```gdscript
static var _sprite_cache: Dictionary = {}
static var _shared_proj_mesh: SphereMesh = null
```

**Frame staggering** for expensive per-entity work:
```gdscript
var _frame_counter: int = 0
# update separation only every 3rd frame
```

**Cached group queries** — `GameManager` caches `get_nodes_in_group("enemies")` once per frame to avoid O(n) repeated calls.

**FPS-conditional effects**: skip particles, screen shake, and damage numbers below configurable FPS thresholds defined in `GameConstants.FPS_SKIP_PARTICLES`, `FPS_SKIP_SHAKE`, etc.

## Code Organization

**Autoloads** (`game/scripts/autoload/`): singletons for game-wide state and systems. 34 registered. Each has a single, clear responsibility.

**Separation of concerns**: database scripts (`WeaponDB`, `ItemDB`, `CharacterDB`) hold only data definitions and lookup functions. They do not mutate game state. Game state lives in `GameManager`.

**Database pattern** — all DBs define data as a `var` dictionary and expose typed getters:
```gdscript
var weapons: Dictionary = { "katana": { "base_damage": 15, ... } }

func get_weapon(id: String) -> Dictionary:
func get_all_weapon_ids() -> Array:
func get_cooldown(id: String, level: int) -> float:
```

**Property setters** used for reactive properties:
```gdscript
var combat_volume: float = 1.0:
    set(v):
        combat_volume = v
        _apply_bus_volume("Combat", v)
```

## UI Layout Rule

All UI screens must fit in 1280x720 without scroll. `ScrollContainer` only inside individual tabs. Text uses sentence case (first letter uppercase, rest lowercase). Proper nouns keep their capitalization.

## String Formatting

Use `%` formatting for all string interpolation:
```gdscript
"[%s] [%s] [%s] %s" % [entry["time"], entry["level_name"], entry["module"], entry["message"]]
"combo_%s_%s" % [char_id, stage_id]
"Lv%d: dmg=%d cd=%.2f dps=%.1f" % [level, dmg, cd, dps]
```

## Await Pattern

Use `await` for async frame delays and signal waits:
```gdscript
await get_tree().process_frame
await get_tree().process_frame
await get_tree().create_timer(WAIT_AFTER_LOAD).timeout
await tree.tree_changed
```

---

*Convention analysis: 2026-04-02*
