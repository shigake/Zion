# Architecture

**Analysis Date:** 2026-04-02

## Pattern Overview

**Overall:** Autoload-singleton data layer + scene-per-entity gameplay pattern (Godot 4 idiomatic)

**Key Characteristics:**
- All game state lives in autoload singletons (GameManager, WeaponDB, SaveManager, etc.) — never in scenes
- Scenes are stateless containers; scripts read from autoloads, write back via method calls or signals
- Signal-driven decoupling: GameManager emits `player_leveled_up`, `enemy_killed`, `boss_spawned`, etc.; listeners subscribe without direct references
- ObjectPool wraps all enemy and projectile instantiation to avoid runtime allocations
- GameConstants (`game/scripts/autoload/game_constants.gd`, 712 lines) is the single source of truth for all magic numbers — no inline constants in gameplay scripts

## Layers

**Autoload / Global State Layer:**
- Purpose: Persistent singletons that survive scene changes. Hold all run-state, databases, and cross-cutting services.
- Location: `game/scripts/autoload/`
- Contains: GameManager (run state), *DB singletons (data), AudioManager, SaveManager, MultiplayerManager, SynergySystem, ObjectPool, etc.
- Depends on: Nothing (no cross-autoload dependencies except GameManager reading from *DB singletons)
- Used by: All scene scripts

**Stage / World Layer:**
- Purpose: The active game world. Owns the Player node, EnemySpawner, and connects stage-specific props/atmosphere.
- Location: `game/scripts/stages/`, `game/scenes/stages/`
- Contains: `base_stage.gd` (parent class), 10 concrete stage scripts (`stage_cemetery.gd`, etc.), `camera_follow.gd`, `event_manager.gd`, `stage_atmosphere.gd`, per-stage props scripts
- Depends on: GameManager, CharacterDB, WeaponDB, AudioManager, EvolutionDB, SynergySystem
- Used by: Nothing (entry point loaded by GameManager scene change)

**Player Layer:**
- Purpose: Local/remote player input, movement, dash, HP tracking, weapon mounting.
- Location: `game/scripts/player/player.gd`, `game/scenes/player/player.tscn`
- Contains: `player.gd` (CharacterBody3D), `tombstone.gd` (death marker)
- Depends on: GameManager, CharacterDB, WeaponDB, MultiplayerManager, ParticleFactory, ScreenEffects
- Used by: BaseStage (owns the Player node as a child)

**Enemy Layer:**
- Purpose: Enemy AI, spawning, pooling, boss phases, and themed stage skins.
- Location: `game/scripts/enemies/`, `game/scenes/enemies/`
- Contains: `enemy_base.gd` (class_name EnemyBase3D), `enemy_spawner.gd`, 10 boss scripts (`boss_*.gd`), `boss_attack_patterns.gd`, `enemy_stage_behavior.gd`, special enemies (mimic, bomber, swarm, tooth_fairy, skeleton_archer)
- Depends on: GameManager, ObjectPool, ParticleFactory, SynergySystem, MutationManager
- Used by: EnemySpawner (instantiates via ObjectPool)

**Weapon Layer:**
- Purpose: Per-weapon attack logic. Each weapon is a Node3D child of `WeaponPivot` under the player.
- Location: `game/scripts/weapons/`, `game/scenes/weapons/`
- Contains: 32 weapon scripts + separate projectile/behavior scripts (e.g. `portal_behavior.gd`, `totem_behavior.gd`, `poison_pool_behavior.gd`)
- Depends on: GameManager (reads level via `get_weapon_level(id)`), WeaponDB (reads stats), SynergySystem, ParticleFactory
- Used by: Player (adds weapon nodes to WeaponPivot via `add_weapon_node(id)`)

**UI Layer:**
- Purpose: All menus, HUD, overlays, screens. Extend CanvasLayer or Control.
- Location: `game/scripts/ui/`, `game/scenes/ui/`
- Contains: `hud.gd`, `main_menu.gd`, `shop.gd`, `level_up_screen.gd`, `game_over_screen.gd`, `pause_menu.gd`, `character_select.gd`, `stage_select.gd`, and 20+ other screens
- Depends on: GameManager, SaveManager, AudioManager, CharacterDB, WeaponDB, ItemDB, ShopDB, UITheme, LocaleManager
- Used by: Nothing (opened via `get_tree().change_scene_to_file()` or `add_child()`)

**Effects Layer:**
- Purpose: Visual-only systems: particles, screen effects, procedural animation, model/visual setup.
- Location: `game/scripts/effects/`
- Contains: `particle_factory.gd` (pooled GPUParticles3D + damage numbers), `screen_effects.gd` (shake, flash), `procedural_animator.gd`, `weapon_trail.gd`, `model_factory.gd`, `visual_setup.gd`, `damage_number.gd`, `player_aura.gd`, `fire_ground_effect.gd`
- Depends on: GameManager (reads `screen_shake_enabled`, `damage_numbers_enabled`)
- Used by: Player, enemies, weapons (call ParticleFactory/ScreenEffects directly)

## Data Flow

**Normal Gameplay Loop:**

1. `BaseStage._ready()` calls `GameManager.reset()`, loads CharacterDB data, instantiates starting weapon under player's `WeaponPivot`
2. `EnemySpawner._process()` reads `GameManager.game_time` + `get_difficulty_multiplier()`, spawns enemies via `ObjectPool.get_instance(scene)`
3. Weapon scripts run `_process()`, read `GameManager.get_weapon_level(id)` and `WeaponDB.get_*()` for stats, emit hits via Area3D `body_entered`
4. `EnemyBase3D.take_damage()` → emits `GameManager.enemy_killed` signal → `BaseStage._on_enemy_killed_synergy()` checks `SynergySystem.check_synergies()`
5. `GameManager.add_xp()` → emits `player_leveled_up` → `LevelUpScreen` shown (pauses tree)
6. Player chooses weapon/item → `GameManager.add_weapon()` or `GameManager.add_item()` → `SynergySystem.check_synergies()` rechecks
7. Run ends (death or victory) → `GameManager.game_over` signal → `GameOverScreen` shown → `SaveManager.save_game()`

**Weapon Leveling:**

1. Player picks weapon at level-up → `GameManager.add_weapon(id)` or `upgrade_weapon(id)`
2. At weapon level 8: `EvolutionDB.check_evolution(weapons, items)` returns evolution id
3. Evolution chest spawns in world → player collects → weapon replaced with evolved variant

**Multiplayer State Sync:**

1. `MultiplayerManager` creates/joins ENet peer
2. Player positions synced via `@rpc` on player.gd
3. Level-up choices can be async (each player chooses independently) or synced (all wait)
4. HP changes broadcast via `MultiplayerManager.player_hp_updated` signal to `HUDMultiplayer`

**Persistence Flow:**

1. `SaveManager._ready()` → loads `user://save_data.json` → restores window/audio settings
2. Between runs: crystals, upgrades, achievements, leaderboard entries saved
3. `ShopDB` reads `SaveManager.data.upgrades` to compute permanent bonuses applied to `GameManager`

## Key Abstractions

**EnemyBase3D (class_name):**
- Purpose: All enemies extend this. Provides HP, damage, knockback, sprite billboard, stage-themed skin, behavior system.
- Examples: `game/scripts/enemies/enemy_base.gd` (base), all `game/scenes/enemies/*.tscn`
- Pattern: `extends CharacterBody3D`, `class_name EnemyBase3D`. Bosses extend `EnemyBase3D` directly.

**BaseStage:**
- Purpose: All 10 stages extend this. Owns Player node, EnemySpawner, connects signals, applies character/weapon setup.
- Examples: `game/scripts/stages/base_stage.gd`, `game/scripts/stages/stage_cemetery.gd` (extends BaseStage, sets music_track and calls super._ready())
- Pattern: Stage subclasses only set `music_track` and call `super._ready()`.

**Weapon Scripts (Node3D children):**
- Purpose: Self-contained attack logic. Mounted as children of `WeaponPivot` under player.
- Examples: `game/scripts/weapons/katana.gd`, `game/scripts/weapons/staff.gd`
- Pattern: `extends Node3D`, reads level via `GameManager.get_weapon_level("id")`, reads stats from `WeaponDB`, uses `_last_attacking_weapon` on `GameManager` before applying damage.

**DB Singletons:**
- Purpose: In-memory dictionaries of static game data. No file I/O after load.
- Examples: `WeaponDB`, `ItemDB`, `CharacterDB`, `RelicDB`, `EvolutionDB`, `ShopDB`
- Pattern: `extends Node`, `var data: Dictionary = { ... }` defined inline. Methods like `get_cooldown(id, level)` compute derived values.

**ObjectPool:**
- Purpose: Reuse enemy/projectile nodes to avoid GC pressure with 500+ entities.
- Examples: `game/scripts/autoload/object_pool.gd`
- Pattern: `ObjectPool.get_instance(scene)` → use → `ObjectPool.return_instance(node)`. Nodes implement `_reset_for_reuse()` to clear state.

## Entry Points

**Main Menu:**
- Location: `game/scenes/ui/main_menu.tscn` + `game/scripts/ui/main_menu.gd`
- Triggers: Godot run/main_scene in project.godot
- Responsibilities: Character select, stage select, multiplayer lobby, shop, options, credits

**Stage Scenes:**
- Location: `game/scenes/stages/stage_*.tscn` (10 files)
- Triggers: `get_tree().change_scene_to_file(GameConstants.STAGE_SCENE_PATHS[stage_id])`
- Responsibilities: Instantiate player, spawner, props; run the gameplay loop

**AutoTester (CLI):**
- Location: `game/scripts/autoload/auto_tester.gd`
- Triggers: `godot --path game --run -- --test=<suite>`
- Responsibilities: Runs headless test suites (smoke, combo, balance, etc.), writes results to `user://test_results/`

## Error Handling

**Strategy:** LogManager-first with graceful fallbacks. No crashes from missing assets.

**Patterns:**
- `LogManager.warn("Context", "message")` for missing optional assets (sprites, audio files)
- `LogManager.error("Context", "message")` for unexpected states
- Resource existence checked with `ResourceLoader.exists(path)` before loading; fallback to procedural mesh/color if sprite missing
- Multiplayer: signals for `connection_failed`, `reconnection_failed`; `MAX_RECONNECT_ATTEMPTS = 3`
- BaseStage: fallback to `katana` weapon if `CharacterDB.get_character()` returns empty dict

## Cross-Cutting Concerns

**Logging:** `LogManager` autoload. Five levels (DEBUG/INFO/WARN/ERROR/FATAL). Writes to `user://logs/`. Must be first autoload. Usage: `LogManager.info("System", "message %s" % value)`.

**Validation:** No dedicated validation layer. DB singletons return empty dict `{}` for unknown IDs; callers check `if not data.is_empty()`.

**Authentication:** None. Multiplayer uses ENet (peer-to-peer listen server). Steam backend stubbed in `SteamManager` pending GodotSteam plugin installation.

**Performance:** Frame-staggered work in `EnemyBase3D` (`_frame_counter`), per-frame caching in `GameManager` (`_cached_enemies`, `_cached_nearest_player`), `SpatialEnemyGrid` for O(1) neighbor lookups, `ObjectPool` for entity reuse, `ParticleFactory` pool (30 GPUParticles3D), `MultiMeshManager` for prop rendering.

**Accessibility:** `AccessibilityManager` autoload + `SaveManager` flags: `screen_shake_enabled`, `damage_numbers_enabled`, `manual_aim`. Read into `GameManager` at run start.

---

*Architecture analysis: 2026-04-02*
