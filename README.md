# ZION

[![Latest Release](https://img.shields.io/github/v/release/shigake/Zion?label=version&style=flat-square)](https://github.com/shigake/Zion/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/shigake/Zion/total?style=flat-square)](https://github.com/shigake/Zion/releases/latest)

> *"Zion nao e onde voce chega. E o que voce constroi no caminho."*

**ZION** is a **Survivors Roguelite** built with **Godot 4** (GDScript) featuring pixel art sprites and chiptune audio. Fight through dimensional rifts with up to 4 players in online co-op.

## Download & Play

**[Download latest release](https://github.com/shigake/Zion/releases/latest)**

### How to install (Windows)
1. Go to the [latest release](https://github.com/shigake/Zion/releases/latest)
2. Download the `Zion-v*-windows.zip` file
3. Extract the zip to any folder
4. Run `zion.exe`

### FAQ

**Windows Defender shows a warning?**
The executable is not digitally signed. Click **"More info"** then **"Run anyway"**. This is normal for indie games distributed outside Steam.

**What are the minimum requirements?**
- Windows 10/11 (64-bit)
- GPU with Vulkan support
- 4GB RAM recommended

**Found a bug?**
Report it at [GitHub Issues](https://github.com/shigake/Zion/issues). Include your game version (shown in the bottom-right corner of the main menu).

## Features

- **15 playable characters** (Fragmentados) with unique abilities and backstories
- **32 weapons** across melee, ranged, and summoner categories with evolution system
- **10 stages** with unique environmental hazards and procedural props
- **10 bosses** with 3-phase fights (Corrupted Sentinels)
- **Online co-op** up to 4 players via ENet (Steam Networking Sockets ready)
- **12 weapon evolutions** via crystalline resonance
- **19 passive items** and **7 relics**
- **Ascension mode** with 6 difficulty mutations
- **Daily challenges** with global leaderboard
- **Elemental synergies** (fire, ice, electric, dark, water) with cross-player combos
- **Pixel art billboard sprites** with procedural animations
- **Chiptune soundtrack** with dynamic per-stage music
- **Telemetry dashboard** for balance analytics

## Screenshots

> Screenshots coming soon. The game uses a top-down 3D perspective with pixel art billboard sprites and procedural particle effects.

## Requirements

- [Godot Engine 4.6+](https://godotengine.org/download) (console version recommended for debug)
- [Blender 3.0+](https://www.blender.org/download/) (required for rendering and exporting 3D models)
- Windows 10/11 (64-bit)
- Git

## Quick start

```bash
# 1. Clone the repository
git clone <repo-url>
cd Zion

# 2. Open in Godot Editor (one of the options below)

# Option A: If godot is in your PATH
godot --editor --path game

# Option B: Set the GODOT variable with your executable path
GODOT="/path/to/godot"
"$GODOT" --editor --path game

# Option C: Open Godot Editor manually and import game/project.godot
```

On first run, Godot imports all assets automatically.

## How to play

### From the editor
- Open the project in Godot Editor
- Press **F5** or click **Play**

### From the command line
```bash
godot --path game --run
```

### Headless error check
```bash
godot --headless --import game/project.godot
```

## How to build (export)

### From the editor
1. Open the project in Godot Editor
2. Go to **Project > Export**
3. Add a preset (e.g., Windows Desktop)
4. Configure the output path
5. Click **Export Project**

### From the command line
```bash
# Requires export preset configured in editor first
godot --headless --path game --export-release "Windows Desktop" ../build/zion.exe
```

## Project structure

```
Zion/
├── CLAUDE.md               # Development guide (AI/dev instructions)
├── README.md               # This file
├── docs/                   # Game design documents (15 files)
│   ├── gdd.md              # Game Design Document
│   ├── prd.md              # Product Requirements Document (roadmap)
│   ├── spec.md             # Technical specification
│   ├── fases.md            # 10 stages detailed
│   ├── itens.md            # Items, evolutions, relics
│   ├── mecanicas.md        # Gameplay mechanics
│   ├── personagens.md      # 15 characters and weapons
│   ├── progressao.md       # Shop, crystals, meta-progression
│   └── prd_*.md            # Various PRDs (telemetry, auto-tester, etc.)
├── server/                 # Telemetry server (Node.js)
│   ├── index.js            # Express + SQLite (API + dashboard)
│   ├── package.json        # Dependencies (express, better-sqlite3)
│   └── public/             # Static web dashboard
└── game/                   # Godot 4 project
    ├── project.godot       # Project configuration
    ├── VERSION             # Current version (no "v" prefix)
    ├── scenes/             # Scenes (.tscn)
    ├── scripts/            # GDScript (.gd)
    └── assets/             # Sprites, shaders, audio
```

## Tech stack

| Component | Technology |
|-----------|-----------|
| Engine | Godot 4.6 (GDScript) |
| Visual style | Pixel art billboard sprites (32x32) + 3D environments |
| Audio | Chiptune / synthesized (procedural generation) |
| Multiplayer | ENet (Steam Networking Sockets ready) |
| Telemetry | Node.js + Express + SQLite |
| CI/CD | GitHub Actions (CI + build/release automatico) |

## Content summary

| Category | Count |
|----------|-------|
| Characters | 15 (including mystery unlock) |
| Weapons | 32 (11 melee, 11 ranged, 10 summon/special) |
| Stages | 10 (7 campaign + 3 anomalies) |
| Bosses | 10 (one per stage, 3 phases each) |
| Items | 19 passive items |
| Evolutions | 12 weapon evolutions |
| Relics | 7 pre-run relics |
| Achievements | 13 |
| Synergies | 18 elemental combinations |
| Mutations | 6 ascension modifiers |

## Controls

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | WASD | Left Stick |
| Dash | Space | A / X |
| Interact | E | B / Circle |
| Pause | ESC | Start |
| Debug overlay | F3 | - |
| Log filter | F4 | - |

## Telemetry server

The game includes an optional telemetry backend for balance analytics:

```bash
cd server && npm install && npm start
# Dashboard at http://localhost:3456
```

Features: run statistics, crash reports, balance analytics, Discord webhook notifications.

## Credits

- **Code**: Developed with assistance from [Claude AI](https://claude.ai) (Anthropic)
- **Music**: Generated with [Suno AI](https://suno.ai)
- **3D assets base**: [Quaternius](https://quaternius.com) (CC0 licensed low-poly models)
- **Engine**: [Godot Engine](https://godotengine.org) (MIT license)

## License

- Game code and original assets: All rights reserved
- Quaternius 3D model bases: **CC0** (Creative Commons Zero) - free to use for any purpose
- Godot Engine: MIT License
- See individual asset licenses for third-party content

## Status

In active development. Current version: see `game/VERSION`.

All 10 stages, 15 characters, 32 weapons, and 10 bosses implemented. 415+ sprites, 43 SFX, 16 music tracks. Full narrative layer (lore, backstories, boss dialogues). Telemetry dashboard. CI/CD pipeline. Ascension mode, cross-combos, daily challenges, achievement system, global leaderboard, tutorial, world map, inventory overlay, bestiary, codex.
