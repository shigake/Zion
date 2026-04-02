const express = require("express");
const Database = require("better-sqlite3");
const path = require("path");

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const PORT = process.env.PORT || 3456;
const DISCORD_WEBHOOK_URL = process.env.DISCORD_WEBHOOK_URL || "";
const API_KEY = process.env.API_KEY || ""; // Optional: protect POST endpoints

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
    scene_tree TEXT,
    session_stats TEXT,
    extra_data TEXT,
    resolved INTEGER DEFAULT 0,
    notes TEXT DEFAULT '',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    event_type TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS daily_scores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    character TEXT,
    stage TEXT,
    survived_seconds REAL,
    total_kills INTEGER,
    victory INTEGER DEFAULT 0,
    mutations TEXT DEFAULT '[]',
    version TEXT,
    ip TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
  CREATE INDEX IF NOT EXISTS idx_daily_scores_date ON daily_scores(date);

  CREATE TABLE IF NOT EXISTS leaderboard (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_name TEXT NOT NULL DEFAULT 'Anonymous',
    score INTEGER NOT NULL,
    kills INTEGER DEFAULT 0,
    survived_seconds REAL DEFAULT 0,
    character_id TEXT,
    stage_id TEXT,
    game_mode TEXT DEFAULT 'normal',
    daily_seed INTEGER DEFAULT 0,
    version TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
  CREATE INDEX IF NOT EXISTS idx_leaderboard_mode ON leaderboard(game_mode, score DESC);
  CREATE INDEX IF NOT EXISTS idx_leaderboard_daily ON leaderboard(daily_seed, score DESC);
`);

// Add new columns if missing (migration-safe)
const crashCols = db.prepare("PRAGMA table_info(crashes)").all().map(c => c.name);
if (!crashCols.includes("scene_tree")) db.exec("ALTER TABLE crashes ADD COLUMN scene_tree TEXT DEFAULT '{}'");
if (!crashCols.includes("session_stats")) db.exec("ALTER TABLE crashes ADD COLUMN session_stats TEXT DEFAULT '{}'");
if (!crashCols.includes("extra_data")) db.exec("ALTER TABLE crashes ADD COLUMN extra_data TEXT DEFAULT '{}'");
if (!crashCols.includes("resolved")) db.exec("ALTER TABLE crashes ADD COLUMN resolved INTEGER DEFAULT 0");
if (!crashCols.includes("notes")) db.exec("ALTER TABLE crashes ADD COLUMN notes TEXT DEFAULT ''");

// ---------------------------------------------------------------------------
// Helper: safely stringify JSON (avoids double-encoding when value is already a string)
// ---------------------------------------------------------------------------
function safeStringify(val, fallback) {
  if (val === undefined || val === null) return JSON.stringify(fallback);
  if (typeof val === "string") return val;
  return JSON.stringify(val);
}

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
  INSERT INTO crashes (session_id, version, module, description, game_state, recent_log, system_info, scene_tree, session_stats, extra_data)
  VALUES (@session_id, @version, @module, @description, @game_state, @recent_log, @system_info, @scene_tree, @session_stats, @extra_data)
`);

const insertEvent = db.prepare(`
  INSERT INTO events (session_id, event_type, data)
  VALUES (@session_id, @event_type, @data)
`);

// ---------------------------------------------------------------------------
// Discord webhook helper
// ---------------------------------------------------------------------------
async function sendDiscordNotification(title, color, fields) {
  if (!DISCORD_WEBHOOK_URL) return;
  const embed = { title, color, fields, timestamp: new Date().toISOString() };
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

async function sendDiscordCrashNotification(crash) {
  await sendDiscordNotification("🔴 Zion Crash Report", 0xff0000, [
    { name: "Module", value: crash.module || "unknown", inline: true },
    { name: "Version", value: crash.version || "unknown", inline: true },
    { name: "Session", value: (crash.session_id || "unknown").slice(0, 20), inline: true },
    { name: "Description", value: (crash.description || "No description").slice(0, 1024) },
    { name: "OS", value: crash.system?.os || crash.system_info?.os || "?", inline: true },
    { name: "Renderer", value: (crash.system?.renderer || crash.system_info?.renderer || "?").slice(0, 100), inline: true },
  ]);
}

// ---------------------------------------------------------------------------
// Express app
// ---------------------------------------------------------------------------
const app = express();

app.use(express.json({ limit: "2mb" }));

// CORS
app.use((_req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, PATCH, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, X-API-Key");
  next();
});
app.options("*", (_req, res) => res.sendStatus(204));

// Optional API key check for POST/PATCH
function checkApiKey(req, res, next) {
  if (!API_KEY) return next(); // no key configured = open
  if (req.headers["x-api-key"] === API_KEY) return next();
  // Game clients send without key — allow POST from game
  // Only block dashboard PATCH endpoints if key is set
  if (req.method === "PATCH") {
    return res.status(401).json({ error: "Invalid API key" });
  }
  next();
}
app.use(checkApiKey);

// Request logging
app.use((req, _res, next) => {
  const now = new Date().toISOString();
  if (req.method !== "OPTIONS") {
    console.log(`${now} ${req.method} ${req.path} ${req.ip}`);
  }
  next();
});

// Rate limiting (simple in-memory)
const rateLimiter = {};
function rateLimit(windowMs, maxRequests) {
  return (req, res, next) => {
    const key = req.ip + req.path;
    const now = Date.now();
    if (!rateLimiter[key]) rateLimiter[key] = [];
    rateLimiter[key] = rateLimiter[key].filter(t => now - t < windowMs);
    if (rateLimiter[key].length >= maxRequests) {
      return res.status(429).json({ error: "Too many requests" });
    }
    rateLimiter[key].push(now);
    next();
  };
}

// Clean rate limiter every 5 min
setInterval(() => {
  const now = Date.now();
  for (const key of Object.keys(rateLimiter)) {
    rateLimiter[key] = rateLimiter[key].filter(t => now - t < 60000);
    if (rateLimiter[key].length === 0) delete rateLimiter[key];
  }
}, 300000);

// ---------------------------------------------------------------------------
// API Routes
// ---------------------------------------------------------------------------

// POST /telemetry — end-of-run data
app.post("/telemetry", rateLimit(60000, 30), (req, res) => {
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
      weapons: safeStringify(b.weapons, []),
      items: safeStringify(b.items, []),
      evolutions: safeStringify(b.evolutions, []),
      events: safeStringify(b.events, []),
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

// POST /crash — crash report (full data from LogManager)
app.post("/crash", rateLimit(60000, 10), async (req, res) => {
  try {
    const b = req.body;
    insertCrash.run({
      session_id: b.session_id || null,
      version: b.version || b.system?.version || null,
      module: b.module || null,
      description: b.description || null,
      game_state: safeStringify(b.game_state, {}),
      recent_log: safeStringify(b.recent_log, []),
      system_info: safeStringify(b.system || b.system_info, {}),
      scene_tree: safeStringify(b.scene_tree, {}),
      session_stats: safeStringify(b.session_stats, {}),
      extra_data: safeStringify(b.extra_data, {}),
    });
    res.json({ ok: true });

    // Discord notification
    sendDiscordCrashNotification(b);
  } catch (err) {
    console.error("Error inserting crash:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST /event — game event
app.post("/event", rateLimit(60000, 60), (req, res) => {
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

// PATCH /crashes/:id — mark resolved, add notes
app.patch("/crashes/:id", (req, res) => {
  try {
    const { resolved, notes } = req.body;
    const updates = [];
    const params = { id: req.params.id };
    if (resolved !== undefined) { updates.push("resolved = @resolved"); params.resolved = resolved ? 1 : 0; }
    if (notes !== undefined) { updates.push("notes = @notes"); params.notes = notes; }
    if (updates.length === 0) return res.status(400).json({ error: "Nothing to update" });
    db.prepare(`UPDATE crashes SET ${updates.join(", ")} WHERE id = @id`).run(params);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /stats — aggregate statistics
app.get("/stats", (_req, res) => {
  try {
    const totalRuns = db.prepare("SELECT COUNT(*) AS count FROM runs").get().count;
    const totalCrashes = db.prepare("SELECT COUNT(*) AS count FROM crashes").get().count;
    const unresolvedCrashes = db.prepare("SELECT COUNT(*) AS count FROM crashes WHERE resolved = 0").get().count;
    const avgSurvival = db.prepare("SELECT AVG(survived_seconds) AS avg FROM runs").get().avg || 0;
    const avgKills = db.prepare("SELECT AVG(total_kills) AS avg FROM runs").get().avg || 0;
    const winRate = db.prepare("SELECT AVG(victory) AS rate FROM runs").get().rate || 0;

    const popularCharacter = db.prepare(`
      SELECT character, COUNT(*) AS picks FROM runs
      WHERE character IS NOT NULL GROUP BY character ORDER BY picks DESC LIMIT 5
    `).all();

    const popularWeapons = db.prepare(`
      SELECT value AS weapon, COUNT(*) AS picks FROM runs, json_each(runs.weapons)
      GROUP BY value ORDER BY picks DESC LIMIT 10
    `).all();

    const popularStages = db.prepare(`
      SELECT stage, COUNT(*) AS plays FROM runs
      WHERE stage IS NOT NULL GROUP BY stage ORDER BY plays DESC LIMIT 5
    `).all();

    const avgFps = db.prepare("SELECT AVG(fps_avg) AS avg FROM runs WHERE fps_avg IS NOT NULL").get().avg || 0;
    const avgLevel = db.prepare("SELECT AVG(level_reached) AS avg FROM runs WHERE level_reached IS NOT NULL").get().avg || 0;

    // Recent activity (last 24h)
    const recentRuns = db.prepare("SELECT COUNT(*) AS count FROM runs WHERE created_at > datetime('now', '-1 day')").get().count;
    const recentCrashes = db.prepare("SELECT COUNT(*) AS count FROM crashes WHERE created_at > datetime('now', '-1 day')").get().count;

    // Version distribution
    const versions = db.prepare(`
      SELECT version, COUNT(*) AS count FROM runs WHERE version IS NOT NULL
      GROUP BY version ORDER BY count DESC LIMIT 10
    `).all();

    // OS distribution
    const osDistribution = db.prepare(`
      SELECT os, COUNT(*) AS count FROM runs WHERE os IS NOT NULL
      GROUP BY os ORDER BY count DESC
    `).all();

    res.json({
      total_runs: totalRuns,
      total_crashes: totalCrashes,
      unresolved_crashes: unresolvedCrashes,
      recent_runs_24h: recentRuns,
      recent_crashes_24h: recentCrashes,
      avg_survival_seconds: Math.round(avgSurvival * 100) / 100,
      avg_kills: Math.round(avgKills * 100) / 100,
      win_rate: Math.round(winRate * 10000) / 100,
      avg_level: Math.round(avgLevel * 100) / 100,
      avg_fps: Math.round(avgFps * 100) / 100,
      popular_characters: popularCharacter,
      popular_weapons: popularWeapons,
      popular_stages: popularStages,
      versions: versions,
      os_distribution: osDistribution,
    });
  } catch (err) {
    console.error("Error fetching stats:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// GET /crashes — crash reports with filters
app.get("/crashes", (req, res) => {
  try {
    const { module, version, resolved, limit: lim, offset: off, search } = req.query;
    let where = [];
    let params = {};
    if (module) { where.push("module = @module"); params.module = module; }
    if (version) { where.push("version = @version"); params.version = version; }
    if (resolved !== undefined) { where.push("resolved = @resolved"); params.resolved = resolved === "true" ? 1 : 0; }
    if (search) { where.push("(description LIKE @search OR module LIKE @search)"); params.search = `%${search}%`; }

    const whereClause = where.length ? "WHERE " + where.join(" AND ") : "";
    const limit = Math.min(parseInt(lim) || 50, 200);
    const offset = parseInt(off) || 0;

    const total = db.prepare(`SELECT COUNT(*) AS count FROM crashes ${whereClause}`).get(params).count;
    const rows = db.prepare(`
      SELECT * FROM crashes ${whereClause} ORDER BY created_at DESC LIMIT ${limit} OFFSET ${offset}
    `).all(params);

    const crashes = rows.map((r) => ({
      ...r,
      game_state: JSON.parse(r.game_state || "{}"),
      recent_log: JSON.parse(r.recent_log || "[]"),
      system_info: JSON.parse(r.system_info || "{}"),
      scene_tree: JSON.parse(r.scene_tree || "{}"),
      session_stats: JSON.parse(r.session_stats || "{}"),
      extra_data: JSON.parse(r.extra_data || "{}"),
    }));

    res.json({ total, limit, offset, crashes });
  } catch (err) {
    console.error("Error fetching crashes:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// GET /crashes/:id — single crash detail
app.get("/crashes/:id", (req, res) => {
  try {
    const row = db.prepare("SELECT * FROM crashes WHERE id = @id").get({ id: req.params.id });
    if (!row) return res.status(404).json({ error: "Not found" });
    res.json({
      ...row,
      game_state: JSON.parse(row.game_state || "{}"),
      recent_log: JSON.parse(row.recent_log || "[]"),
      system_info: JSON.parse(row.system_info || "{}"),
      scene_tree: JSON.parse(row.scene_tree || "{}"),
      session_stats: JSON.parse(row.session_stats || "{}"),
      extra_data: JSON.parse(row.extra_data || "{}"),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /runs — paginated run list
app.get("/runs", (req, res) => {
  try {
    const { character, stage, version, victory, limit: lim, offset: off } = req.query;
    let where = [];
    let params = {};
    if (character) { where.push("character = @character"); params.character = character; }
    if (stage) { where.push("stage = @stage"); params.stage = stage; }
    if (version) { where.push("version = @version"); params.version = version; }
    if (victory !== undefined) { where.push("victory = @victory"); params.victory = victory === "true" ? 1 : 0; }

    const whereClause = where.length ? "WHERE " + where.join(" AND ") : "";
    const limit = Math.min(parseInt(lim) || 50, 200);
    const offset = parseInt(off) || 0;

    const total = db.prepare(`SELECT COUNT(*) AS count FROM runs ${whereClause}`).get(params).count;
    const rows = db.prepare(`
      SELECT * FROM runs ${whereClause} ORDER BY created_at DESC LIMIT ${limit} OFFSET ${offset}
    `).all(params);

    const runs = rows.map(r => ({
      ...r,
      weapons: JSON.parse(r.weapons || "[]"),
      items: JSON.parse(r.items || "[]"),
      evolutions: JSON.parse(r.evolutions || "[]"),
      events: JSON.parse(r.events || "[]"),
    }));

    res.json({ total, limit, offset, runs });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /events — paginated events
app.get("/events", (req, res) => {
  try {
    const { event_type, session_id, limit: lim, offset: off } = req.query;
    let where = [];
    let params = {};
    if (event_type) { where.push("event_type = @event_type"); params.event_type = event_type; }
    if (session_id) { where.push("session_id = @session_id"); params.session_id = session_id; }

    const whereClause = where.length ? "WHERE " + where.join(" AND ") : "";
    const limit = Math.min(parseInt(lim) || 50, 200);
    const offset = parseInt(off) || 0;

    const total = db.prepare(`SELECT COUNT(*) AS count FROM events ${whereClause}`).get(params).count;
    const rows = db.prepare(`
      SELECT * FROM events ${whereClause} ORDER BY created_at DESC LIMIT ${limit} OFFSET ${offset}
    `).all(params);

    const events = rows.map(r => ({ ...r, data: JSON.parse(r.data || "{}") }));
    res.json({ total, limit, offset, events });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /balance — balance analytics
app.get("/balance", (_req, res) => {
  try {
    const weaponDps = db.prepare(`
      SELECT value AS weapon,
        AVG(total_damage * 1.0 / CASE WHEN survived_seconds > 0 THEN survived_seconds ELSE 1 END) AS avg_dps,
        COUNT(*) AS sample_size
      FROM runs, json_each(runs.weapons)
      WHERE total_damage IS NOT NULL AND survived_seconds IS NOT NULL
      GROUP BY value ORDER BY avg_dps DESC
    `).all().map(r => ({
      weapon: r.weapon, avg_dps: Math.round(r.avg_dps * 100) / 100, sample_size: r.sample_size,
    }));

    const characterWinRates = db.prepare(`
      SELECT character, COUNT(*) AS total, SUM(victory) AS wins,
        AVG(victory) * 100 AS win_rate, AVG(survived_seconds) AS avg_survival
      FROM runs WHERE character IS NOT NULL GROUP BY character ORDER BY win_rate DESC
    `).all().map(r => ({
      character: r.character, total: r.total, wins: r.wins,
      win_rate: Math.round(r.win_rate * 100) / 100,
      avg_survival: Math.round(r.avg_survival * 100) / 100,
    }));

    const stageDifficulty = db.prepare(`
      SELECT stage, COUNT(*) AS total, SUM(victory) AS wins,
        AVG(victory) * 100 AS win_rate, AVG(survived_seconds) AS avg_survival,
        AVG(total_kills) AS avg_kills
      FROM runs WHERE stage IS NOT NULL GROUP BY stage ORDER BY win_rate ASC
    `).all().map(r => ({
      stage: r.stage, total: r.total, wins: r.wins,
      win_rate: Math.round(r.win_rate * 100) / 100,
      avg_survival: Math.round(r.avg_survival * 100) / 100,
      avg_kills: Math.round(r.avg_kills * 100) / 100,
    }));

    res.json({ weapon_dps: weaponDps, character_win_rates: characterWinRates, stage_difficulty: stageDifficulty });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------------------------------------------------------------------
// Daily Challenge endpoints
// ---------------------------------------------------------------------------

const insertDailyScore = db.prepare(`
  INSERT INTO daily_scores (date, character, stage, survived_seconds, total_kills, victory, mutations, version, ip)
  VALUES (@date, @character, @stage, @survived_seconds, @total_kills, @victory, @mutations, @version, @ip)
`);

// POST /daily-score — submit a daily challenge score
app.post("/daily-score", rateLimit(60000, 10), (req, res) => {
  try {
    const b = req.body;
    if (!b.date) return res.status(400).json({ error: "date is required" });
    insertDailyScore.run({
      date: b.date,
      character: b.character || null,
      stage: b.stage || null,
      survived_seconds: b.survived_seconds ?? 0,
      total_kills: b.total_kills ?? 0,
      victory: b.victory ? 1 : 0,
      mutations: JSON.stringify(b.mutations || []),
      version: b.version || null,
      ip: req.ip || null,
    });
    res.json({ ok: true });
  } catch (err) {
    console.error("Error inserting daily score:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// GET /daily-leaderboard — leaderboard for a specific date
app.get("/daily-leaderboard", (req, res) => {
  try {
    const date = req.query.date;
    if (!date) return res.status(400).json({ error: "date query param required (YYYY-MM-DD)" });

    const scores = db.prepare(`
      SELECT character, stage, survived_seconds, total_kills, victory, mutations, version, created_at
      FROM daily_scores
      WHERE date = @date
      ORDER BY total_kills DESC, survived_seconds DESC
      LIMIT 50
    `).all({ date });

    const parsed = scores.map(s => ({
      ...s,
      mutations: JSON.parse(s.mutations || "[]"),
    }));

    // Stats
    const stats = db.prepare(`
      SELECT COUNT(*) AS total_runs,
        AVG(survived_seconds) AS avg_time,
        AVG(total_kills) AS avg_kills,
        MAX(total_kills) AS max_kills,
        MAX(survived_seconds) AS max_time,
        SUM(victory) AS total_victories
      FROM daily_scores WHERE date = @date
    `).get({ date });

    res.json({
      date,
      total_entries: stats?.total_runs || 0,
      stats: {
        avg_time: Math.round((stats?.avg_time || 0) * 100) / 100,
        avg_kills: Math.round((stats?.avg_kills || 0) * 100) / 100,
        max_kills: stats?.max_kills || 0,
        max_time: Math.round((stats?.max_time || 0) * 100) / 100,
        total_victories: stats?.total_victories || 0,
      },
      scores: parsed,
    });
  } catch (err) {
    console.error("Error fetching daily leaderboard:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// GET /daily-stats — aggregate daily challenge stats (streak data, popular stages, etc.)
app.get("/daily-stats", (_req, res) => {
  try {
    const totalDays = db.prepare("SELECT COUNT(DISTINCT date) AS count FROM daily_scores").get().count;
    const totalRuns = db.prepare("SELECT COUNT(*) AS count FROM daily_scores").get().count;
    const avgKills = db.prepare("SELECT AVG(total_kills) AS avg FROM daily_scores").get().avg || 0;
    const winRate = db.prepare("SELECT AVG(victory) AS rate FROM daily_scores").get().rate || 0;

    const popularCharacters = db.prepare(`
      SELECT character, COUNT(*) AS picks FROM daily_scores
      WHERE character IS NOT NULL GROUP BY character ORDER BY picks DESC LIMIT 5
    `).all();

    const recentDays = db.prepare(`
      SELECT date, COUNT(*) AS runs, AVG(total_kills) AS avg_kills, SUM(victory) AS victories
      FROM daily_scores GROUP BY date ORDER BY date DESC LIMIT 7
    `).all().map(r => ({
      ...r,
      avg_kills: Math.round(r.avg_kills * 100) / 100,
    }));

    res.json({
      total_days: totalDays,
      total_runs: totalRuns,
      avg_kills: Math.round(avgKills * 100) / 100,
      win_rate: Math.round(winRate * 10000) / 100,
      popular_characters: popularCharacters,
      recent_days: recentDays,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------------------------------------------------------------------
// Leaderboard endpoints
// ---------------------------------------------------------------------------

const insertLeaderboard = db.prepare(`
  INSERT INTO leaderboard (player_name, score, kills, survived_seconds, character_id, stage_id, game_mode, daily_seed, version)
  VALUES (@player_name, @score, @kills, @survived_seconds, @character_id, @stage_id, @game_mode, @daily_seed, @version)
`);

// POST /leaderboard/submit — submit a leaderboard score (rate limited: 1 per 10s per IP)
app.post("/leaderboard/submit", rateLimit(10000, 1), (req, res) => {
  try {
    const b = req.body;
    const score = parseInt(b.score) || 0;
    if (score < 0 || score > 100000) {
      return res.status(400).json({ error: "Invalid score (must be 0-100000)" });
    }
    if (!b.player_name || typeof b.player_name !== "string" || b.player_name.trim().length === 0) {
      return res.status(400).json({ error: "player_name is required" });
    }
    const playerName = b.player_name.trim().slice(0, 32);
    const mode = b.game_mode || b.mode || "normal";

    insertLeaderboard.run({
      player_name: playerName,
      score: score,
      kills: parseInt(b.kills) || 0,
      survived_seconds: parseFloat(b.survived_seconds) || 0,
      character_id: b.character_id || b.character || null,
      stage_id: b.stage_id || b.stage || null,
      game_mode: mode,
      daily_seed: parseInt(b.daily_seed) || 0,
      version: b.version || null,
    });

    // Calculate rank
    let rankParams = { score: score };
    let rankQuery;
    if (mode === "daily" && b.daily_seed) {
      rankQuery = "SELECT COUNT(*) AS rank FROM leaderboard WHERE game_mode = 'daily' AND daily_seed = @daily_seed AND score > @score";
      rankParams.daily_seed = parseInt(b.daily_seed) || 0;
    } else {
      rankQuery = "SELECT COUNT(*) AS rank FROM leaderboard WHERE game_mode = @game_mode AND score > @score";
      rankParams.game_mode = mode;
    }
    const rankResult = db.prepare(rankQuery).get(rankParams);
    const rank = (rankResult?.rank || 0) + 1;

    const totalQuery = mode === "daily" && b.daily_seed
      ? "SELECT COUNT(*) AS count FROM leaderboard WHERE game_mode = 'daily' AND daily_seed = @daily_seed"
      : "SELECT COUNT(*) AS count FROM leaderboard WHERE game_mode = @game_mode";
    const totalParams = mode === "daily" && b.daily_seed
      ? { daily_seed: parseInt(b.daily_seed) || 0 }
      : { game_mode: mode };
    const totalEntries = db.prepare(totalQuery).get(totalParams);

    res.json({ ok: true, rank, total_entries: totalEntries?.count || 0 });
  } catch (err) {
    console.error("Error inserting leaderboard score:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// GET /leaderboard/top — get top scores
// Query params: mode (default: normal), date (for daily, YYYY-MM-DD), stage, limit (default: 50)
app.get("/leaderboard/top", (req, res) => {
  try {
    const { mode, date, stage, limit: lim } = req.query;
    const gameMode = mode || "normal";
    const limit = Math.min(parseInt(lim) || 50, 200);

    let where = ["game_mode = @game_mode"];
    let params = { game_mode: gameMode };

    if (stage) {
      where.push("stage_id = @stage_id");
      params.stage_id = stage;
    }

    if (gameMode === "daily" && date) {
      const parts = date.split("-");
      if (parts.length === 3) {
        const dailySeed = parseInt(parts[0]) * 10000 + parseInt(parts[1]) * 100 + parseInt(parts[2]);
        where.push("daily_seed = @daily_seed");
        params.daily_seed = dailySeed;
      }
    }

    const whereClause = "WHERE " + where.join(" AND ");
    const rows = db.prepare(`
      SELECT player_name, score, kills, survived_seconds, character_id, stage_id, game_mode, created_at
      FROM leaderboard ${whereClause}
      ORDER BY score DESC
      LIMIT ${limit}
    `).all(params);

    const entries = rows.map((r, i) => ({
      rank: i + 1,
      player_name: r.player_name,
      score: r.score,
      kills: r.kills,
      survived_seconds: r.survived_seconds,
      character: r.character_id,
      stage: r.stage_id,
      mode: r.game_mode,
      created_at: r.created_at,
    }));

    res.json({ mode: gameMode, total: entries.length, entries });
  } catch (err) {
    console.error("Error fetching leaderboard:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// GET /leaderboard/rank — get a specific player's rank
// Query params: player_name (required), mode (default: normal), date (for daily)
app.get("/leaderboard/rank", (req, res) => {
  try {
    const { player_name, mode, date } = req.query;
    if (!player_name) return res.status(400).json({ error: "player_name is required" });
    const gameMode = mode || "normal";

    let where = ["game_mode = @game_mode"];
    let params = { game_mode: gameMode };

    if (gameMode === "daily" && date) {
      const parts = date.split("-");
      if (parts.length === 3) {
        const dailySeed = parseInt(parts[0]) * 10000 + parseInt(parts[1]) * 100 + parseInt(parts[2]);
        where.push("daily_seed = @daily_seed");
        params.daily_seed = dailySeed;
      }
    }

    const whereClause = "WHERE " + where.join(" AND ");

    // Get the player's best score
    const bestScore = db.prepare(`
      SELECT score, kills, survived_seconds, character_id FROM leaderboard
      ${whereClause} AND player_name = @player_name
      ORDER BY score DESC LIMIT 1
    `).get({ ...params, player_name });

    if (!bestScore) {
      const totalResult = db.prepare(`SELECT COUNT(*) AS count FROM leaderboard ${whereClause}`).get(params);
      return res.json({ rank: -1, score: 0, total_entries: totalResult?.count || 0 });
    }

    // Count how many scores are higher
    const rankResult = db.prepare(`
      SELECT COUNT(*) AS rank FROM leaderboard ${whereClause} AND score > @best_score
    `).get({ ...params, best_score: bestScore.score });

    const totalResult = db.prepare(`SELECT COUNT(*) AS count FROM leaderboard ${whereClause}`).get(params);

    res.json({
      rank: (rankResult?.rank || 0) + 1,
      score: bestScore.score,
      kills: bestScore.kills,
      survived_seconds: bestScore.survived_seconds,
      character: bestScore.character_id,
      total_entries: totalResult?.count || 0,
    });
  } catch (err) {
    console.error("Error fetching player rank:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// GET /health — health check
app.get("/health", (_req, res) => {
  res.json({ status: "ok", uptime: process.uptime(), timestamp: new Date().toISOString() });
});

// ---------------------------------------------------------------------------
// Dashboard (served as static HTML)
// ---------------------------------------------------------------------------
app.use("/dashboard", express.static(path.join(__dirname, "public")));

// Redirect root to dashboard
app.get("/", (_req, res) => res.redirect("/dashboard"));

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Zion telemetry server listening on http://0.0.0.0:${PORT}`);
  console.log(`Dashboard: http://localhost:${PORT}/dashboard`);
  console.log(`Database: ${dbPath}`);
  if (DISCORD_WEBHOOK_URL) {
    console.log("Discord crash notifications: enabled");
  } else {
    console.log("Discord crash notifications: disabled (set DISCORD_WEBHOOK_URL)");
  }
  if (API_KEY) {
    console.log("API key protection: enabled");
  }
});
