# Zion - Development Guide

## Project

Survivors roguelite game built with Godot 4 (GDScript). Online co-op up to 4 players.
12 characters, 28 weapons, 10 stages, 10 bosses, 12 evolutions.

## Structure

```
docs/           # Game design documents (GDD, PRD, spec)
game/           # Godot 4 project
  scenes/       # .tscn scene files
    enemies/    # 11 generic enemies + 10 bosses
    stages/     # 10 stages with procedural props
    weapons/    # 28 weapon scenes
    ui/         # HUD, menus, level up, shop, leaderboard
    player/     # Player scene
  scripts/      # .gd script files
    autoload/   # Singletons (GameManager, WeaponDB, ItemDB, etc)
    player/     # Player controller
    enemies/    # Enemy base + spawner + 10 boss scripts
    weapons/    # All weapon scripts (28)
    ui/         # HUD, menus, level up, shop
    stages/     # Stage logic + props (10 stages)
    effects/    # Particles, shaders, animations, procedural animator
  assets/       # Materials, shaders, audio
```

## Commands

```bash
# Run the game (from repo root)
"/c/Users/shiga/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.1-stable_win64_console.exe" --path game --run

# Import project (headless check for errors)
"/c/Users/shiga/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.1-stable_win64_console.exe" --headless --import game/project.godot

# Open in editor
"/c/Users/shiga/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.1-stable_win64_console.exe" --editor --path game
```

## Architecture

- **Host-client multiplayer**: one player hosts, others connect via ENet (Steam Networking Sockets ready via SteamManager stub)
- **Autoload singletons**: GameManager, WeaponDB, ItemDB, SaveManager, ShopDB, CharacterDB, RelicDB, EvolutionDB, MultiplayerManager, SynergySystem, AudioManager, ScreenEffects, ParticleFactory, ObjectPool, UITheme, KeybindingManager, LocaleManager, VisualSetup, ModelFactory, SteamManager, AchievementManager
- **Enemy spawning**: ObjectPool-backed, difficulty scales with time, stage-themed skins
- **Weapon system**: base weapons level 1-8, evolve at 8 with matching item at 5
- **Procedural props**: each stage generates its environment procedurally (meshes, lights, particles)
- **Procedural animations**: idle bob, walk lean, hit squash-stretch, death tumble

## Content Summary

- **Characters**: 12 (ronin, soldado, mago, berserker, ninja, necro, pirata, engenheiro, vampiro, gladiador, chef, mystery)
- **Weapons**: 28 (10 melee, 10 ranged, 8 summon/special)
- **Stages**: 10 (cemetery, forest, farm, tokyo, volcano, ocean, arena, space, castle, candy)
- **Bosses**: 10 (one per stage, each with 3 phases)
- **Items**: 19 passive items
- **Evolutions**: 12 weapon evolutions
- **Relics**: 7 pre-run relics
- **Events**: 10 special events
- **Achievements**: 13

## Notificacoes Discord

Quando terminar uma task, notifique o Discord automaticamente:

```bash
curl -s -X POST http://localhost:3123/notify -H "Content-Type: application/json" -d "{\"channel\": \"zion\", \"message\": \"DESCRICAO DO QUE FOI FEITO\", \"status\": \"done\"}"
```

Status disponiveis: `done` (concluido), `error` (falhou), `info` (informativo), `warning` (atencao).
Sempre notifique ao concluir ou falhar uma task. Escreva a mensagem em portugues.

## Current Phase

All 10 stages implemented with bosses, props, and mechanics. See docs/prd.md for full roadmap.

## Remaining Work

- Audio files (system exists, needs .ogg/.wav assets)
- Steam integration (GodotSteam plugin needed)
- MultiMesh for large hordes (performance optimization)
