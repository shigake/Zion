# Codebase Structure

**Analysis Date:** 2026-04-02

## Directory Layout

```
Zion/
├── CLAUDE.md                        # Dev guide (conventions, architecture summary, CLI commands)
├── README.md                        # Public project documentation
├── docs/                            # 32 design docs + ADRs
│   ├── gdd.md                       # Game Design Document
│   ├── story.md                     # Lore, narrative, narrative rules
│   ├── personagens.md               # 15 Fragmentados + backstories
│   ├── itens.md                     # Items, evolutions, relics
│   ├── mecanicas.md                 # Gameplay mechanics
│   ├── fases.md                     # 7 fendas + 3 anomalias
│   ├── progressao.md                # Shop, crystals, meta-progression
│   ├── prd_*.md                     # 29 PRDs (28 done, 1 pending)
│   └── adr/                         # 14 Architecture Decision Records (ADR-001–ADR-014)
├── server/                          # Node.js telemetry server
│   ├── index.js                     # Express + SQLite REST API + dashboard
│   ├── package.json
│   └── public/                      # Static dashboard web UI
├── .github/workflows/               # CI/CD
│   ├── ci.yml                       # Validation + balance tests
│   └── build.yml                    # Export .exe + GitHub Release on tags
└── game/                            # Godot 4 project root
    ├── project.godot                # Engine config: autoloads, physics layers, display, renderer
    ├── VERSION                      # Current version string (no "v" prefix)
    ├── scenes/                      # 124 .tscn scene files
    │   ├── enemies/                 # 46 scenes (16 generic + 10 main bosses + 20 alt bosses)
    │   ├── stages/                  # 10 stage scenes (7 campaign + 3 anomaly)
    │   ├── weapons/                 # 40 scenes (32 weapons + projectiles)
    │   ├── ui/                      # 21 UI screens
    │   └── player/                  # player.tscn
    ├── scripts/                     # 231 .gd files
    │   ├── autoload/                # 34 singletons (registered in project.godot)
    │   ├── player/                  # player.gd + tombstone.gd
    │   ├── enemies/                 # enemy_base.gd, spawner, bosses, specials
    │   ├── weapons/                 # 32 weapon scripts + projectile/behavior scripts
    │   ├── stages/                  # base_stage.gd + 10 stage scripts + props + camera
    │   ├── ui/                      # 36 UI scripts + debug_overlay.gd
    │   ├── effects/                 # 9 visual/particle/anim scripts
    │   ├── tools/                   # 49 sprite/asset generator scripts (editor-only)
    │   └── tests/                   # 5 test scripts (runner, balance, smoke, auto_player, report)
    └── assets/
        ├── audio/
        │   ├── music/               # 16 tracks (menu/, stages/, boss/)
        │   └── sfx/                 # 51 SFX (boss/, combat/, enemies/, environment/, pickup/, player/, ui/)
        ├── icons/                   # UI icons (achievements/, characters/, evolutions/, items/, relics/, stages/, ui/, upgrades/, weapons/)
        ├── materials/               # Godot StandardMaterial3D / ShaderMaterial resources
        ├── models/
        │   ├── bosses/              # Boss 3D models
        │   ├── characters/          # Character 3D models
        │   ├── enemies/             # Enemy 3D models
        │   ├── pickups/             # Pickup 3D models
        │   ├── props/               # Per-stage prop models (arena/, candy/, castle/, cemetery/, farm/, forest/, ocean/, space/, tokyo/, volcano/)
        │   ├── weapons/             # Weapon 3D models
        │   └── downloaded/          # Source asset packs (KayKit, Kenney, Quaternius — not used directly at runtime)
        └── sprites/                 # 453+ procedurally-generated PNG sprites
            ├── characters/          # 15 Fragmentado sprites (e.g. ronin.png, mago.png)
            ├── enemies/             # Per-stage enemy sprites (arena/, candy/, castle/, etc.)
            ├── bosses/              # Boss sprites
            ├── weapons/             # Weapon sprites
            ├── items/               # Item sprites
            ├── relics/              # Relic sprites
            ├── evolutions/          # Evolution sprites
            ├── effects/slashes/     # Melee slash sprites
            ├── projectiles/         # Projectile sprites
            ├── pickups/             # Health/magnet pickup sprites
            ├── props/               # Per-stage prop sprites
            ├── stages/              # Stage background/thumbnail sprites
            ├── synergies/           # Synergy icon sprites
            ├── ui/                  # UI element sprites
            └── upgrades/            # Shop upgrade sprites
```

## Directory Purposes

**`game/scripts/autoload/`:**
- Purpose: All 34 autoload singletons registered in `project.godot`. These are globally accessible by their class name (e.g. `GameManager`, `WeaponDB`).
- Key files: `game_constants.gd` (712-line constants), `game_manager.gd` (run state + signals), `save_manager.gd` (persistence), `object_pool.gd` (entity reuse), `multiplayer_manager.gd` (ENet networking), `synergy_system.gd` (elemental combos)
- Note: `lod_manager.gd` and `perf_monitor.gd` live here but are NOT registered as autoload — they are instantiated manually. `spatial_enemy_grid.gd` is loaded dynamically by `game_manager.gd` in `_ready()`.

**`game/scripts/enemies/`:**
- Purpose: All enemy logic. `enemy_base.gd` defines `class_name EnemyBase3D` which all enemies extend.
- Key files: `enemy_base.gd`, `enemy_spawner.gd`, `boss_generic.gd`, `boss_attack_patterns.gd`, `enemy_stage_behavior.gd`, `enemy_culler.gd`
- Boss scripts (10): `boss_necromancer.gd`, `boss_fairy_queen.gd`, `boss_alien_cow.gd`, `boss_ai_overlord.gd`, `boss_demon_lord.gd`, `boss_leviathan.gd`, `boss_dracula.gd`, `boss_emperor.gd`, `boss_singularity.gd`, `boss_sugar_king.gd`

**`game/scripts/weapons/`:**
- Purpose: One script per weapon, plus auxiliary scripts for complex behaviors.
- Pattern: Each weapon script is a Node3D that self-manages its attack timer, reads `GameManager.get_weapon_level(id)` and `WeaponDB.get_*()` every `_process()`.
- Auxiliary scripts: `weapon_vfx.gd` (shared VFX helpers), behavior scripts (`portal_behavior.gd`, `totem_behavior.gd`, `time_bomb_behavior.gd`, `poison_pool_behavior.gd`), projectile scripts (`bullet.gd`, `rocket.gd`, `staff_projectile.gd`, `ice_staff_projectile.gd`, `elven_bow_arrow.gd`, `enemy_projectile.gd`)

**`game/scripts/stages/`:**
- Purpose: Stage world logic. `base_stage.gd` is the parent for all 10 stage scripts.
- Pattern: Stage script only sets `music_track` and calls `super._ready()`. All setup lives in BaseStage.
- Props scripts: `cemetery_props.gd`, `forest_props.gd`, `farm_props.gd`, `tokyo_props.gd`, `volcano_props.gd`, `ocean_props.gd`, `arena_props.gd`, `space_props.gd`, `castle_props.gd`, `candy_props.gd` — each generates procedural environment geometry/lights/particles for its stage.

**`game/scripts/ui/`:**
- Purpose: All UI screens and overlays. Most extend CanvasLayer or Control.
- Key files: `hud.gd` (in-game HUD, boss HP, minimap, quest display), `level_up_screen.gd` (card selection, pauses tree), `shop.gd` (persistent upgrades between runs), `main_menu.gd`, `character_select.gd`, `game_over_screen.gd`
- Autoload UI scripts (registered globally): `debug_overlay.gd`, `achievement_popup.gd`, `boss_dialogue.gd`, `inventory_overlay.gd`

**`game/scripts/effects/`:**
- Purpose: Visual-only, no gameplay logic. All registered as autoloads except `damage_number.gd`, `player_aura.gd`, `fire_ground_effect.gd`, `weapon_trail.gd`, `procedural_animator.gd`.
- Key files: `particle_factory.gd` (pooled particles + damage numbers), `screen_effects.gd` (shake/flash), `visual_setup.gd` (renderer settings), `model_factory.gd` (procedural 3D geometry), `procedural_animator.gd` (idle bob, walk lean, hit squash-stretch)

**`game/scripts/tools/`:**
- Purpose: Editor-only sprite and asset generators. Not used at runtime. Run manually via Godot editor.
- Contains: 49 scripts for generating all 453+ sprites (characters, enemies, bosses, weapons, props, effects, UI art, SFX)

**`game/scripts/tests/`:**
- Purpose: Automated test suites. Run via CLI flags (`--test=smoke`, `--test=combo`, etc.).
- Key files: `test_runner.gd` (dispatches to suites), `auto_player.gd` (simulates player input for headless runs), `balance_test.gd`, `menu_smoke_test.gd`, `test_report.gd`

**`game/scenes/enemies/`:**
- Purpose: One `.tscn` per enemy type. Generic enemies (16): slime, bat, skeleton, zombie_runner, ghost (5 variants), slime_big, skeleton_archer, bomber, tank, swarm, mimic, tooth_fairy. Bosses (30): 10 main sentinels + 20 alternates named `boss_{stage}_{variant}.tscn`.

**`game/assets/sprites/`:**
- Purpose: All 453+ PNG sprites generated by `scripts/tools/`. Billboard Sprite3D at runtime.
- Convention: `characters/{character_id}.png`, `enemies/{stage}/{enemy_type}.png`, `weapons/{weapon_id}.png`, `items/{item_id}.png`

**`game/assets/models/downloaded/`:**
- Purpose: Source 3D asset packs from KayKit, Kenney, Quaternius. Used as reference/fallback models. Not required at runtime (billboard sprites take precedence).
- Generated: No. Committed: Yes (tracked in git).

## Key File Locations

**Entry Points:**
- `game/scenes/ui/main_menu.tscn`: Godot main_scene — first scene loaded
- `game/project.godot`: All autoload registrations and engine configuration
- `game/VERSION`: Version string (e.g. `3.47.0`)

**Configuration:**
- `game/scripts/autoload/game_constants.gd`: All balance constants, scene paths, stage/boss pools — edit here to change any numbers
- `game/scripts/autoload/save_manager.gd`: Persistent data schema + default values
- `game/project.godot`: Physics layer names, display resolution, renderer, autoload order

**Core Gameplay:**
- `game/scripts/stages/base_stage.gd`: Run initialization, character/weapon setup, event loop
- `game/scripts/autoload/game_manager.gd`: All live run state (level, HP, weapons, items, multipliers, flags)
- `game/scripts/enemies/enemy_spawner.gd`: Difficulty scaling, boss scheduling, ObjectPool usage
- `game/scripts/enemies/enemy_base.gd`: All enemy behavior (EnemyBase3D class)

**Data / Databases:**
- `game/scripts/autoload/weapon_db.gd`: 32 weapon definitions with per-level scaling
- `game/scripts/autoload/character_db.gd`: 15 Fragmentado definitions with passives and starting weapons
- `game/scripts/autoload/item_db.gd`: 19 item definitions with passive effects
- `game/scripts/autoload/evolution_db.gd`: 12 evolution definitions (weapon_required + item_required)
- `game/scripts/autoload/shop_db.gd`: 12 permanent upgrade definitions
- `game/scripts/autoload/relic_db.gd`: 7 relic definitions

**Testing:**
- `game/scripts/tests/test_runner.gd`: CLI test dispatcher
- `game/scripts/tests/balance_test.gd`: XP curve, DPS, economy validation
- `game/scripts/tests/menu_smoke_test.gd`: Menu navigation smoke test

## Naming Conventions

**Files:**
- Scripts: `snake_case.gd` (e.g. `enemy_base.gd`, `boss_fairy_queen.gd`)
- Scenes: `snake_case.tscn` matching the script name (e.g. `boss_fairy_queen.tscn`)
- Sprites: `snake_case.png` matching the game ID (e.g. `katana.png`, `slime.png`)
- Tool scripts: `{subject}_gen.gd` or `{subject}_sprite_gen.gd` or `{subject}_sprites.gd`

**Directories:**
- All lowercase snake_case at every level
- Stage-specific assets go in `{stage_id}/` subdirectory (e.g. `sprites/enemies/cemetery/`)

**GDScript Identifiers:**
- Classes: PascalCase (`EnemyBase3D`, `BaseStage`)
- Variables and functions: snake_case
- Constants: ALL_CAPS_SNAKE_CASE (defined in `game_constants.gd`)
- Signals: snake_case verb phrases (`player_leveled_up`, `boss_died`, `synergy_activated`)
- Node paths: PascalCase per Godot convention (`$WeaponPivot`, `$SlashArea`)

**Game IDs:**
- Characters: lowercase no spaces (`ronin`, `soldado`, `mago`, `berserker`)
- Stages: lowercase single word (`cemetery`, `forest`, `tokyo`, `candy`)
- Weapons: snake_case (`dual_katana`, `ice_staff`, `chain_whip`)
- Items, relics, evolutions: snake_case

## Where to Add New Code

**New weapon:**
- Script: `game/scripts/weapons/{weapon_id}.gd` (extends Node3D)
- Scene: `game/scenes/weapons/{weapon_id}.tscn`
- Data: Add entry to `game/scripts/autoload/weapon_db.gd` → `weapons` dictionary
- Sprite: `game/assets/sprites/weapons/{weapon_id}.png`
- Registration: No autoload needed; `BaseStage` adds via `player.add_weapon_node(id)`

**New character (Fragmentado):**
- Data: Add entry to `game/scripts/autoload/character_db.gd` → `characters` dictionary
- Sprite: `game/assets/sprites/characters/{char_id}.png`
- Icon: `game/assets/icons/characters/{char_id}.png`
- Unlock: Add to `SaveManager.data.unlocked_characters` default array

**New enemy:**
- Script: `game/scripts/enemies/{enemy_id}.gd` (extends EnemyBase3D)
- Scene: `game/scenes/enemies/{enemy_id}.tscn`
- Sprite: `game/assets/sprites/enemies/{stage}/{enemy_id}.png`
- Spawn: Register in `game/scripts/enemies/enemy_spawner.gd` preload vars + spawn pool logic

**New boss (Sentinela):**
- Script: `game/scripts/enemies/boss_{stage}.gd` (extends EnemyBase3D)
- Scene: `game/scenes/enemies/boss_{stage}.tscn`
- Register in `GameConstants.BOSS_POOLS` under the appropriate stage key (first entry = original Sentinel)

**New stage (fenda):**
- Script: `game/scripts/stages/stage_{id}.gd` (extends BaseStage, sets music_track, calls super._ready())
- Props script: `game/scripts/stages/{id}_props.gd`
- Scene: `game/scenes/stages/stage_{id}.tscn`
- Register in `GameConstants.ALL_STAGES`, `STAGE_SCENE_PATHS`, `BOSS_POOLS`
- Enemy sprites: `game/assets/sprites/enemies/{id}/`

**New item:**
- Data: Add entry to `game/scripts/autoload/item_db.gd`
- Effect: Apply bonus in `GameManager` item modifier recalculation (see `recalculate_item_bonuses()`)
- Sprite: `game/assets/sprites/items/{item_id}.png`

**New UI screen:**
- Script: `game/scripts/ui/{screen_name}.gd` (extends CanvasLayer or Control)
- Scene: `game/scenes/ui/{screen_name}.tscn`
- Do NOT register as autoload unless it must persist across all scene changes
- Rule: Screen must fit 1280x720 without scroll; use tabs/pages if content is large

**New autoload singleton:**
- Script: `game/scripts/autoload/{name}.gd` (extends Node)
- Register in `game/project.godot` under `[autoload]` section
- Use `LogManager` as first autoload model — must be ordered after LogManager in project.godot

**Utilities / Helpers:**
- Shared gameplay helpers: `game/scripts/autoload/game_constants.gd` (constants) or new autoload
- Visual helpers: `game/scripts/effects/`
- Editor-only tools (sprite gen, etc.): `game/scripts/tools/`

## Special Directories

**`game/scripts/tools/`:**
- Purpose: 49 procedural sprite and SFX generator scripts. Run from Godot editor, not at runtime.
- Generated: No. Committed: Yes.

**`game/assets/models/downloaded/`:**
- Purpose: Raw source asset packs (KayKit, Kenney, Quaternius). Reference for 3D geometry.
- Generated: No. Committed: Yes. Not imported into Godot at runtime (billboard sprites used instead).

**`game/.godot/`:**
- Purpose: Godot-generated import cache, UID database, shader cache.
- Generated: Yes. Not committed (in .gitignore).

**`server/`:**
- Purpose: Node.js telemetry server. Runs separately (`npm start`). Not part of the Godot build.
- Generated: No. Committed: Yes.

---

*Structure analysis: 2026-04-02*
