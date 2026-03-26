# Zion Telemetry Server

Backend server that receives gameplay telemetry, crash reports, and game events from Zion clients. Data is stored in a local SQLite database.

## Setup

```bash
cd server
npm install
```

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

- `PORT` — Server port (default: 3456)
- `DISCORD_WEBHOOK_URL` — Discord webhook for crash report notifications (optional)

## Running

```bash
npm start
```

The server creates `telemetry.db` (SQLite) automatically on first run.

## API Endpoints

### POST /telemetry

Submit end-of-run data. Body fields: `session_id`, `version`, `character`, `stage`, `mode`, `survived_seconds`, `victory`, `total_kills`, `total_damage`, `level_reached`, `weapons` (array), `items` (array), `evolutions` (array), `events` (array), `crystals_earned`, `fps_avg`, `fps_min`, `peak_enemies`, `os`, `renderer`.

### POST /crash

Submit a crash report. Body fields: `session_id`, `version`, `module`, `description`, `game_state` (object), `recent_log` (array), `system_info` (object). Sends a Discord notification if `DISCORD_WEBHOOK_URL` is set.

### POST /event

Submit a game event. Body fields: `session_id`, `event_type`, `data` (object).

### GET /stats

Returns aggregate statistics: total runs, average survival time, most popular character, top weapons, win rate, etc.

### GET /crashes

Returns the 50 most recent crash reports.

### GET /balance

Returns balance analytics: weapon DPS averages, character win rates, and stage difficulty metrics.
