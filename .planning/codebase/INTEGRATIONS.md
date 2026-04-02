# External Integrations

**Analysis Date:** 2026-04-02

## APIs & External Services

**Telemetry Backend (self-hosted):**
- Custom REST server (`server/index.js`) running at `http://localhost:3456` by default
  - SDK/Client: Godot `HTTPRequest` node — `game/scripts/autoload/telemetry.gd`
  - Auth: optional `X-API-Key` header; game clients send without key (POST endpoints open), PATCH endpoints require key
  - Configurable URL stored in save data key `telemetry_url`; default `http://localhost:3456`

**Discord Webhooks:**
- Crash notifications sent by server when `DISCORD_WEBHOOK_URL` is set
  - Triggered by: `POST /crash` to server — server calls `sendDiscordCrashNotification()` in `server/index.js`
  - Payload: embed with module, version, session, description, OS, renderer
  - Developer notification also used via curl to `http://localhost:3123/notify` (separate local notification proxy defined in `CLAUDE.md`)

**Steam (pending plugin install):**
- GodotSteam GDExtension — not yet installed; all code is ready in `game/scripts/autoload/steam_manager.gd`
  - Detected via: `Engine.has_singleton("Steam")` — falls back gracefully to ENet when absent
  - Handles: achievements sync, Steam Cloud save, lobby creation/join/invite, friend overlay
  - Achievement mapping: 17 local IDs → Steam API IDs (e.g. `"first_walk"` → `"ACH_FIRST_WALK"`)
  - Cloud save file name: `"zion_save.json"` written via `steam.fileWrite()`

## Data Storage

**Databases:**
- SQLite3 — `server/telemetry.db` (WAL mode)
  - Client: `better-sqlite3` ^11.0.0 (synchronous)
  - Tables: `runs`, `crashes`, `events`, `daily_scores`, `leaderboard`
  - Schema migrations done inline via `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` pattern in `server/index.js`

**Local Save (Game):**
- JSON flat file — `user://save_data.json`
  - Manager: `game/scripts/autoload/save_manager.gd`
  - Stores: crystals, upgrades, unlocked characters/stages, achievements, leaderboard cache, pending offline scores, best run, audio settings, accessibility toggles

**Daily Challenge Persistence:**
- JSON flat file — `user://daily_challenge.json`
  - Manager: `game/scripts/autoload/daily_challenge.gd`
  - Stores: daily scores by date, streak, last played date, best streak

**Log Files:**
- `user://logs/` — plain text session logs with rotation (max 10 files, `game/scripts/autoload/log_manager.gd`)
- `user://logs/crashes/` — JSON crash reports (max 20 files); unsent reports queued and retried on next session start

**File Storage:**
- Local filesystem only (Godot `user://` path); no cloud blob storage unless Steam Cloud is enabled

**Caching:**
- In-memory only (no Redis or external cache); object pool in `game/scripts/autoload/object_pool.gd`; server uses in-memory rate limiter map

## Authentication & Identity

**Auth Provider:**
- None for anonymous telemetry (no user accounts)
- Steam identity (SteamID + persona name) when GodotSteam plugin is active; used for leaderboard `player_name` and lobby metadata
- Player name defaults to `"Anonymous"` stored in `user://save_data.json` key `player_name`

## Networking (Multiplayer)

**Protocol:**
- ENet (Godot built-in) — host-client listen server, default port `7777`
  - Manager: `game/scripts/autoload/multiplayer_manager.gd`
  - Max players: 4
  - LAN broadcast: UDP port `7778`, interval 2s
  - Features: ping RPC, host migration, auto-reconnect (3 attempts, 2s interval), password protection, lobby chat

**Future:**
- Steam Networking Sockets (via GodotSteam) — documented as fallback path in `multiplayer_manager.gd` comments; `NetworkBackend` enum has `ENET` and `STEAM` values

## Monitoring & Observability

**Error Tracking:**
- Custom crash reporter — `game/scripts/autoload/log_manager.gd` captures FATAL-level events and writes JSON crash reports to `user://logs/crashes/`; `game/scripts/autoload/telemetry.gd` sends them to `POST /crash` on the telemetry server
- Server forwards crash embeds to Discord webhook (`server/index.js`)

**Logs:**
- Game: `LogManager` (5 levels: DEBUG/INFO/WARN/ERROR/FATAL), file + console output, 500-entry in-memory ring buffer
- Server: `console.log()` per request with timestamp, IP, method, path

**Telemetry Endpoints (server):**
- `POST /telemetry` — end-of-run stats (rate: 30/min per IP)
- `POST /crash` — crash report (rate: 10/min per IP)
- `POST /event` — generic game event (rate: 60/min per IP)
- `GET /stats` — aggregate analytics dashboard
- `GET /balance` — weapon DPS, character win rates, stage difficulty
- `GET /runs`, `GET /crashes`, `GET /events` — paginated data
- `PATCH /crashes/:id` — mark crash resolved, add notes (requires API key)

**Leaderboard Endpoints (server):**
- `POST /leaderboard/submit` — submit score (rate: 1 per 10s per IP); returns rank
- `GET /leaderboard/top` — top scores by mode/stage/date
- `GET /leaderboard/rank` — single player rank lookup

**Daily Challenge Endpoints (server):**
- `POST /daily-score` — submit daily challenge result (rate: 10/min per IP)
- `GET /daily-leaderboard?date=YYYY-MM-DD` — leaderboard for a date
- `GET /daily-stats` — aggregate daily challenge analytics

**Dashboard:**
- Static HTML at `server/public/`; served at `http://localhost:3456/dashboard`
- Root `/` redirects to `/dashboard`

## CI/CD & Deployment

**Hosting:**
- Game: Windows `.exe` + Linux `.x86_64` binaries; distributed via GitHub Releases
- Server: Self-hosted (no containerization or deployment config detected)

**CI Pipeline:**
- GitHub Actions — `.github/workflows/ci.yml`
  - Triggers: push to `main`/`develop`, PR to `main`
  - Jobs: project import validation + balance test (`game/scripts/tests/balance_test.gd`)
  - Godot version: 4.4.1

**Build Pipeline:**
- `.github/workflows/build.yml` — manual trigger or tag
  - Exports Windows + Linux in parallel
  - Packages as zip files with readme
  - Creates GitHub Release with auto-generated changelog from conventional commits

**Auto-Release:**
- `.github/workflows/auto-release.yml` — triggers on push to `main`
  - Creates tag + triggers build when: minor version changes, patch is multiple of 10, or patch is 0

## Webhooks & Callbacks

**Incoming:**
- None detected (server has no incoming webhook endpoints)

**Outgoing:**
- Discord webhook (crash alerts) — from `server/index.js` via Node.js `fetch()`
- Telemetry HTTP calls — from game client via `HTTPRequest` node (`game/scripts/autoload/telemetry.gd`); fire-and-forget with 5s timeout, silent fail

## Offline Fallback

**Leaderboard scores:**
- When server is unreachable, `game/scripts/autoload/telemetry.gd` saves scores to `SaveManager.data["pending_leaderboard_scores"]`; retried 8s after next game startup via `_send_pending_leaderboard_scores()`

**Crash reports:**
- Unsent reports tracked via `user://logs/crashes/.sent` sentinel file; retried 5s after startup

---

*Integration audit: 2026-04-02*
