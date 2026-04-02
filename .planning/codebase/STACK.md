# Technology Stack

**Analysis Date:** 2026-04-02

## Languages

**Primary:**
- GDScript 4 - All game logic, autoloads, UI, enemies, weapons, stages (`game/scripts/`)
- JavaScript (CommonJS) - Telemetry server (`server/index.js`)

**Secondary:**
- GDShader - Visual effects and materials (`game/assets/materials/`, `game/assets/environments/`)
- Bash - CI/CD pipeline scripts (`.github/workflows/`)

## Runtime

**Game Engine:**
- Godot 4.6 (features declared in `game/project.godot`: `config/features=PackedStringArray("4.6", "Forward Plus")`)
- CI uses Godot 4.4.1 for validation, build pipeline targets Godot 4.6.1 (`build.yml` env `GODOT_VERSION`)

**Server Environment:**
- Node.js (version unspecified — no `.nvmrc` or `engines` field in `server/package.json`)

**Package Manager:**
- npm — `server/package-lock.json` present

## Frameworks

**Core (Game):**
- Godot 4 Engine - Rendering, physics, scene management, ENet networking
- GDScript autoload pattern — 34 singleton nodes registered in `game/project.godot`

**Server:**
- Express 4.18+ — REST API and static file serving (`server/index.js`)

**Build/Dev:**
- GitHub Actions — CI validation + export via Godot headless (`ubuntu-latest` runners)

## Key Dependencies

**Server — Critical:**
- `express` ^4.18.0 — HTTP server, routing, CORS, rate limiting
- `better-sqlite3` ^11.0.0 — Synchronous SQLite3 driver; stores runs, crashes, events, daily scores, leaderboard (`server/telemetry.db`)

**Game — External (optional/pending):**
- GodotSteam GDExtension — Steam platform integration (code complete in `game/scripts/autoload/steam_manager.gd`, plugin not yet installed). Falls back gracefully when `Engine.has_singleton("Steam")` is false.

**CI:**
- `actions/checkout@v4`
- `actions/cache@v4` — caches Godot binary and export templates
- `actions/upload-artifact@v4` / `actions/download-artifact@v4`
- `softprops/action-gh-release@v2` — creates GitHub Releases with changelog

## Configuration

**Environment (Server):**
- `.env.example` present at `server/.env.example`
- `PORT` — server listen port (default: `3456`)
- `DISCORD_WEBHOOK_URL` — optional; enables crash notifications to Discord
- `API_KEY` — optional; protects PATCH endpoints when set

**Game:**
- `game/project.godot` — engine config (autoloads, physics layers, display, renderer)
- `game/VERSION` — plain text, current version `3.47.0`; read at runtime by `game/scripts/autoload/telemetry.gd`
- `user://save_data.json` — runtime save file managed by `game/scripts/autoload/save_manager.gd`
- `user://daily_challenge.json` — daily challenge persistence (`game/scripts/autoload/daily_challenge.gd`)
- `user://logs/` — log files, crash JSON reports (`game/scripts/autoload/log_manager.gd`)

**Build:**
- `game/export_presets.cfg` — Godot export configuration (must exist for CI build job to succeed)
- `.github/workflows/ci.yml` — validation + balance tests on push to `main`/`develop`
- `.github/workflows/build.yml` — manual/tag-triggered export to Windows + Linux
- `.github/workflows/auto-release.yml` — auto-creates tags on minor version bumps or every 10 patches

## Platform Requirements

**Development:**
- Godot 4.6 editor in PATH (or `GODOT` env var)
- Blender 3.0+ for 3D model/asset pipeline
- Node.js + npm for telemetry server

**Production:**
- Windows 10/11 64-bit with Vulkan support (primary target)
- Linux 64-bit with Vulkan support (secondary target)
- Renderer: Forward Plus, MSAA 2x (configured in `game/project.godot`)
- Viewport: 1280x720 locked, stretch mode `canvas_items`, aspect `keep`

---

*Stack analysis: 2026-04-02*
