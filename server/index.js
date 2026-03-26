const express = require("express");
const Database = require("better-sqlite3");
const path = require("path");

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const PORT = process.env.PORT || 3456;
const DISCORD_WEBHOOK_URL = process.env.DISCORD_WEBHOOK_URL || "";

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------
const dbPath = path.join(__dirname, "telemetry.db");
const db = new Database(dbPath);
db.pragma("journal_mode = WAL");

db.exec(`
  CREATE TABLE IF NOT EXISTS runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    version TEXT,
    character TEXT,
    stage TEXT,
    mode TEXT,
    survived_seconds REAL,
    victory INTEGER,
    total_kills INTEGER,
    total_damage INTEGER,
    level_reached INTEGER,
    weapons TEXT,
    items TEXT,
    evolutions TEXT,
    events TEXT,
    crystals_earned INTEGER,
    fps_avg REAL,
    fps_min REAL,
    peak_enemies INTEGER,
    os TEXT,
    renderer TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS crashes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    version TEXT,
    module TEXT,
    description TEXT,
    game_state TEXT,
    recent_log TEXT,
    system_info TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    event_type TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
`);

// ---------------------------------------------------------------------------
// Prepared statements
// ---------------------------------------------------------------------------
const insertRun = db.prepare(`
  INSERT INTO runs (session_id, version, character, stage, mode, survived_seconds,
    victory, total_kills, total_damage, level_reached, weapons, items, evolutions,
    events, crystals_earned, fps_avg, fps_min, peak_enemies, os, renderer)
  VALUES (@session_id, @version, @character, @stage, @mode, @survived_seconds,
    @victory, @total_kills, @total_damage, @level_reached, @weapons, @items,
    @evolutions, @events, @crystals_earned, @fps_avg, @fps_min, @peak_enemies,
    @os, @renderer)
`);

const insertCrash = db.prepare(`
  INSERT INTO crashes (session_id, version, module, description, game_state, recent_log, system_info)
  VALUES (@session_id, @version, @module, @description, @game_state, @recent_log, @system_info)
`);

const insertEvent = db.prepare(`
  INSERT INTO events (session_id, event_type, data)
  VALUES (@session_id, @event_type, @data)
`);

// ---------------------------------------------------------------------------
// Discord webhook helper
// ---------------------------------------------------------------------------
async function sendDiscordCrashNotification(crash) {
  if (!DISCORD_WEBHOOK_URL) return;

  const embed = {
    title: "Zion Crash Report",
    color: 0xff0000,
    fields: [
      { name: "Module", value: crash.module || "unknown", inline: true },
      { name: "Version", value: crash.version || "unknown", inline: true },
      { name: "Session", value: crash.session_id || "unknown", inline: true },
      { name: "Description", value: (crash.description || "No description").slice(0, 1024) },
    ],
    timestamp: new Date().toISOString(),
  };

  try {
    await fetch(DISCORD_WEBHOOK_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ embeds: [embed] }),
    });
  } catch (err) {
    console.error("Failed to send Discord webhook:", err.message);
  }
}

// ---------------------------------------------------------------------------
// Express app
// ---------------------------------------------------------------------------
const app = express();

app.use(express.json({ limit: "1mb" }));

// CORS
app.use((_req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  next();
});
app.options("*", (_req, res) => res.sendStatus(204));

// Request logging
app.use((req, _res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
  next();
});

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

// POST /telemetry — end-of-run data
app.post("/telemetry", (req, res) => {
  try {
    const b = req.body;
    insertRun.run({
      session_id: b.session_id || null,
      version: b.version || null,
      character: b.character || null,
      stage: b.stage || null,
      mode: b.mode || null,
      survived_seconds: b.survived_seconds ?? null,
      victory: b.victory ? 1 : 0,
      total_kills: b.total_kills ?? null,
      total_damage: b.total_damage ?? null,
      level_reached: b.level_reached ?? null,
      weapons: JSON.stringify(b.weapons || []),
      items: JSON.stringify(b.items || []),
      evolutions: JSON.stringify(b.evolutions || []),
      events: JSON.stringify(b.events || []),
      crystals_earned: b.crystals_earned ?? null,
      fps_avg: b.fps_avg ?? null,
      fps_min: b.fps_min ?? null,
      peak_enemies: b.peak_enemies ?? null,
      os: b.os || null,
      renderer: b.renderer || null,
    });
    res.json({ ok: true });
  } catch (err) {
    console.error("Error inserting run:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST /crash — crash report
app.post("/crash", async (req, res) => {
  try {
    const b = req.body;
    insertCrash.run({
      session_id: b.session_id || null,
      version: b.version || null,
      module: b.module || null,
      description: b.description || null,
      game_state: JSON.stringify(b.game_state || {}),
      recent_log: JSON.stringify(b.recent_log || []),
      system_info: JSON.stringify(b.system_info || {}),
    });
    res.json({ ok: true });

    // Fire-and-forget Discord notification
    sendDiscordCrashNotification(b);
  } catch (err) {
    console.error("Error inserting crash:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST /event — game event
app.post("/event", (req, res) => {
  try {
    const b = req.body;
    insertEvent.run({
      session_id: b.session_id || null,
      event_type: b.event_type || null,
      data: JSON.stringify(b.data || {}),
    });
    res.json({ ok: true });
  } catch (err) {
    console.error("Error inserting event:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// GET /stats — aggregate statistics
app.get("/stats", (_req, res) => {
  try {
    const totalRuns = db.prepare("SELECT COUNT(*) AS count FROM runs").get().count;
    const avgSurvival = db.prepare("SELECT AVG(survived_seconds) AS avg FROM runs").get().avg || 0;
    const avgKills = db.prepare("SELECT AVG(total_kills) AS avg FROM runs").get().avg || 0;
    const winRate = db.prepare("SELECT AVG(victory) AS rate FROM runs").get().rate || 0;

    const popularCharacter = db.prepare(`
      SELECT character, COUNT(*) AS picks FROM runs
      WHERE character IS NOT NULL
      GROUP BY character ORDER BY picks DESC LIMIT 5
    `).all();

    const popularWeapons = db.prepare(`
      SELECT value AS weapon, COUNT(*) AS picks FROM runs, json_each(runs.weapons)
      GROUP BY value ORDER BY picks DESC LIMIT 10
    `).all();

    const popularStages = db.prepare(`
      SELECT stage, COUNT(*) AS plays FROM runs
      WHERE stage IS NOT NULL
      GROUP BY stage ORDER BY plays DESC LIMIT 5
    `).all();

    const avgFps = db.prepare("SELECT AVG(fps_avg) AS avg FROM runs WHERE fps_avg IS NOT NULL").get().avg || 0;
    const avgLevel = db.prepare("SELECT AVG(level_reached) AS avg FROM runs WHERE level_reached IS NOT NULL").get().avg || 0;

    res.json({
      total_runs: totalRuns,
      avg_survival_seconds: Math.round(avgSurvival * 100) / 100,
      avg_kills: Math.round(avgKills * 100) / 100,
      win_rate: Math.round(winRate * 10000) / 100, // percentage
      avg_level: Math.round(avgLevel * 100) / 100,
      avg_fps: Math.round(avgFps * 100) / 100,
      popular_characters: popularCharacter,
      popular_weapons: popularWeapons,
      popular_stages: popularStages,
    });
  } catch (err) {
    console.error("Error fetching stats:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// GET /crashes — recent crash reports
app.get("/crashes", (_req, res) => {
  try {
    const rows = db.prepare(`
      SELECT id, session_id, version, module, description, game_state, recent_log, system_info, created_at
      FROM crashes ORDER BY created_at DESC LIMIT 50
    `).all();

    const crashes = rows.map((r) => ({
      ...r,
      game_state: JSON.parse(r.game_state || "{}"),
      recent_log: JSON.parse(r.recent_log || "[]"),
      system_info: JSON.parse(r.system_info || "{}"),
    }));

    res.json({ crashes });
  } catch (err) {
    console.error("Error fetching crashes:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// GET /balance — balance analytics
app.get("/balance", (_req, res) => {
  try {
    // Weapon DPS averages (approx: total_damage / survived_seconds per weapon)
    const weaponDps = db.prepare(`
      SELECT value AS weapon,
        AVG(total_damage * 1.0 / CASE WHEN survived_seconds > 0 THEN survived_seconds ELSE 1 END) AS avg_dps,
        COUNT(*) AS sample_size
      FROM runs, json_each(runs.weapons)
      WHERE total_damage IS NOT NULL AND survived_seconds IS NOT NULL
      GROUP BY value
      ORDER BY avg_dps DESC
    `).all().map((r) => ({
      weapon: r.weapon,
      avg_dps: Math.round(r.avg_dps * 100) / 100,
      sample_size: r.sample_size,
    }));

    // Character win rates
    const characterWinRates = db.prepare(`
      SELECT character,
        COUNT(*) AS total,
        SUM(victory) AS wins,
        AVG(victory) * 100 AS win_rate,
        AVG(survived_seconds) AS avg_survival
      FROM runs
      WHERE character IS NOT NULL
      GROUP BY character
      ORDER BY win_rate DESC
    `).all().map((r) => ({
      character: r.character,
      total: r.total,
      wins: r.wins,
      win_rate: Math.round(r.win_rate * 100) / 100,
      avg_survival: Math.round(r.avg_survival * 100) / 100,
    }));

    // Stage difficulty (lower win rate = harder)
    const stageDifficulty = db.prepare(`
      SELECT stage,
        COUNT(*) AS total,
        SUM(victory) AS wins,
        AVG(victory) * 100 AS win_rate,
        AVG(survived_seconds) AS avg_survival,
        AVG(total_kills) AS avg_kills
      FROM runs
      WHERE stage IS NOT NULL
      GROUP BY stage
      ORDER BY win_rate ASC
    `).all().map((r) => ({
      stage: r.stage,
      total: r.total,
      wins: r.wins,
      win_rate: Math.round(r.win_rate * 100) / 100,
      avg_survival: Math.round(r.avg_survival * 100) / 100,
      avg_kills: Math.round(r.avg_kills * 100) / 100,
    }));

    res.json({
      weapon_dps: weaponDps,
      character_win_rates: characterWinRates,
      stage_difficulty: stageDifficulty,
    });
  } catch (err) {
    console.error("Error fetching balance:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------
app.listen(PORT, () => {
  console.log(`Zion telemetry server listening on port ${PORT}`);
  console.log(`Database: ${dbPath}`);
  if (DISCORD_WEBHOOK_URL) {
    console.log("Discord crash notifications: enabled");
  } else {
    console.log("Discord crash notifications: disabled (set DISCORD_WEBHOOK_URL to enable)");
  }
});
