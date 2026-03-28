# PRD: Leaderboard Online (Registro de Zion)

> Zion registra as proezas de cada Fragmentado — um memorial dos mais poderosos.

## Objetivo
Sistema de ranking global para Daily Challenge e modos de jogo. Narrativamente, e o proprio Zion catalogando os feitos dos Fragmentados que lutam para restaura-lo.

## Arquitetura

### Backend (server/)
O servidor de telemetria ja existe em `server/index.js` (Express + SQLite).
Expandir com endpoints de leaderboard:

```
POST /leaderboard/submit
  body: { player_name, score, kills, time, character, stage, mode, version, daily_seed }
  response: { rank, total_entries }

GET /leaderboard/top?mode=daily&date=2026-03-28&limit=50
  response: { entries: [{ rank, player_name, score, kills, time, character }] }

GET /leaderboard/top?mode=endless&limit=50
GET /leaderboard/top?mode=normal&stage=cemetery&limit=50

GET /leaderboard/rank?player_name=xxx&mode=daily&date=2026-03-28
  response: { rank, score, total_entries }
```

### Database Schema (SQLite)
```sql
CREATE TABLE leaderboard (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  player_name TEXT NOT NULL,
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

CREATE INDEX idx_leaderboard_mode ON leaderboard(game_mode, score DESC);
CREATE INDEX idx_leaderboard_daily ON leaderboard(daily_seed, score DESC);
```

### Client (Godot)
Expandir `Telemetry` singleton ou criar `LeaderboardClient` singleton:

```gdscript
func submit_score(data: Dictionary) -> void:
    _post("/leaderboard/submit", data)

func get_top_scores(mode: String, limit: int = 50, date: String = "") -> void:
    var url = "/leaderboard/top?mode=%s&limit=%d" % [mode, limit]
    if date != "":
        url += "&date=" + date
    _get(url, _on_top_scores_received)

signal top_scores_received(entries: Array)
signal score_submitted(rank: int)
```

## UI — Tela de Leaderboard

### Layout
```
┌─────────────────────────────────────────────┐
│  🏆 RANKING GLOBAL                          │
│  [Daily] [Endless] [Normal] [Boss Rush]     │
│─────────────────────────────────────────────│
│  #   Nome         Score   Kills  Tempo  Char│
│  1.  xXSlayerXx   15840   1234   25:30  🗡  │
│  2.  BrunoGamer   14200   1100   23:45  🧙  │
│  3.  Ana_BR       13900   1050   24:10  🏹  │
│  ...                                        │
│  47. VocêAqui ★   8500    680    18:20  ⚔   │
│─────────────────────────────────────────────│
│  Seu melhor: #47 — 8500 pts                 │
│  [Voltar]                                   │
└─────────────────────────────────────────────┘
```

### Features
- Tabs pra cada modo de jogo
- Daily Challenge: mostra leaderboard do dia
- Highlight na posicao do jogador (cor dourada)
- Scroll pra ver mais entries
- Refresh automatico ao abrir
- Cache local (nao faz request se <60s desde ultimo)
- Player name configuravel em Options (salvo no SaveManager)
- Anti-cheat basico: server valida version, rejeita scores impossíveis (>50000)

### Acessibilidade
- Botao "Ranking" no menu principal
- Botao "Ver Ranking" na tela de game over
- Botao "Ranking do Dia" na tela de Daily Challenge
- Auto-submit apos cada run (se online)

## Implementacao

### Server (Node.js)
1. Adicionar tabela leaderboard no SQLite
2. Endpoints POST/GET com validacao
3. Rate limiting (max 1 submit por 30s por IP)
4. Cleanup: deletar entries >30 dias (exceto top 100 all-time)

### Client (Godot)
1. Criar `LeaderboardClient` autoload ou expandir `Telemetry`
2. Criar `game/scripts/ui/leaderboard_screen.gd`
3. Criar `game/scenes/ui/leaderboard_screen.tscn`
4. Adicionar player_name no SaveManager + Options
5. Auto-submit no game_over_screen
6. Botoes de acesso no menu + game over + daily challenge

## Offline Fallback
- Se servidor indisponivel: salva score localmente
- Proximo login: tenta enviar scores pendentes
- Leaderboard mostra "Offline — mostrando local" com dados do SaveManager
