# Zion - Development Guide

## Project

Survivors roguelite game built with Godot 4 (GDScript). Online co-op up to 4 players.

## Structure

```
docs/           # Game design documents (GDD, PRD, spec)
game/           # Godot 4 project
  scenes/       # .tscn scene files
  scripts/      # .gd script files
    autoload/   # Singletons (GameManager, WeaponDB, ItemDB, etc)
    player/     # Player controller
    enemies/    # Enemy base + spawner
    weapons/    # All weapon scripts
    ui/         # HUD, menus, level up, shop
    stages/     # Stage logic, camera, events
  assets/       # Materials, shaders, models, audio
```

## Commands

```bash
# Run the game (from repo root)
"/c/Users/shiga/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.1-stable_win64_console.exe" --path game --run

# Import project
"/c/Users/shiga/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.1-stable_win64_console.exe" --headless --import game/project.godot
```

## Architecture

- **Host-client multiplayer** (Phase 3): one player hosts, others connect via Steam Networking Sockets
- **Autoload singletons**: GameManager (state), WeaponDB, ItemDB, SaveManager, ShopDB, CharacterDB, RelicDB, EvolutionDB
- **Enemy spawning**: deterministic seed for multiplayer sync, difficulty scales with time
- **Weapon system**: base weapons level 1-8, evolve at 8 with matching item at 5

## Current Phase

Phase 1-2 implemented. See docs/prd.md for full roadmap.
