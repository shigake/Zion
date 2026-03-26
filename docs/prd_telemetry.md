# PRD — Telemetria e Analytics

> **Status: ✅ IMPLEMENTADO (v1.8.0)**
> Cliente Godot (LogManager + Telemetry), servidor Node.js com dashboard web, crash reports com game state completo.

## Objetivo

Receber logs, crash reports e metricas de gameplay dos jogadores em tempo real para:
1. Detectar e corrigir bugs rapidamente
2. Balancear armas, inimigos e dificuldade com dados reais
3. Entender como os jogadores jogam (armas preferidas, stages dificeis, etc)
4. Monitorar performance (FPS, picos de entidades)

## Arquitetura

```
Jogador (Godot) → HTTP POST → Backend (servidor) → SQLite/PostgreSQL
                                    ↓
                              Dashboard web (opcional)
                              Discord webhook (alertas)
```

## Backend Simples (Node.js/Express)

Um servidor HTTP minimo que:
- Recebe POST /telemetry com JSON de metricas
- Recebe POST /crash com JSON de crash reports
- Recebe POST /event com eventos pontuais (achievement, boss kill, etc)
- Salva em SQLite para consulta
- Envia alerta no Discord para crashes e erros criticos

## Dados Enviados

### A cada fim de run (POST /telemetry)
```json
{
  "session_id": "20260326011425_a3f2",
  "version": "1.6.1",
  "character": "ronin",
  "stage": "cemetery",
  "mode": "normal",
  "survived_seconds": 1234.5,
  "victory": false,
  "total_kills": 5678,
  "total_damage": 123456,
  "level_reached": 35,
  "weapons": ["katana:8", "staff:6"],
  "items": ["boots:3", "glove:2"],
  "evolutions": ["zangetsu"],
  "events": ["golden_horde", "eclipse"],
  "crystals_earned": 234,
  "fps_avg": 58,
  "fps_min": 32,
  "peak_enemies": 487,
  "os": "Windows",
  "renderer": "NVIDIA GeForce RTX 3080 Ti"
}
```

### Em crash (POST /crash)
```json
{
  "session_id": "...",
  "version": "1.6.1",
  "crash_time": "2026-03-26 01:14:25",
  "module": "EnemyBase",
  "description": "Null reference in take_damage",
  "game_state": { ... },
  "recent_log": ["...last 50 entries..."],
  "system": { "os": "...", "renderer": "...", "memory_mb": 4096 }
}
```

### Eventos pontuais (POST /event)
```json
{
  "session_id": "...",
  "event": "achievement_unlocked",
  "data": { "id": "genocide", "time": 1200.5 }
}
```

## Privacidade
- Sem dados pessoais (sem nome, email, IP armazenado)
- Session ID e aleatorio, nao identificavel
- Opt-out disponivel nas opcoes (toggle "Enviar dados anonimos")
- Dados usados apenas para melhorar o jogo

---

## Implementacao (v1.8.0)

### O que foi entregue

**Cliente Godot:**
- `LogManager` (autoload): logging centralizado com 5 niveis, crash reports JSON, rotacao de arquivos, buffer em memoria (500 entries), monitoramento de FPS
- `Telemetry` (autoload): envia runs, crashes e events ao servidor; reenvio automatico de crashes pendentes; opt-out
- `DebugOverlay` (UI): F3 toggle overlay (FPS, enemies, HP, pool stats, logs coloridos), F4 filtro de niveis

**Servidor (`server/`):**
- Node.js + Express + SQLite (better-sqlite3, WAL mode)
- 7 endpoints GET (stats, crashes, runs, events, balance, health, crash detail)
- 3 endpoints POST (telemetry, crash, event) com rate limiting
- 1 endpoint PATCH (resolver crash, adicionar notas)
- Dashboard web com 5 abas: Overview, Crashes, Runs, Balance, Events
- Discord webhook para alertas de crash
- API key opcional para endpoints de gerenciamento

### Como usar

```bash
# Iniciar servidor
cd server && npm install && npm start
# Dashboard: http://localhost:3456

# Variaveis de ambiente (opcional)
PORT=3456
API_KEY=minha-chave-secreta
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
```

### Teclas de debug (em jogo)
| Tecla | Funcao |
|-------|--------|
| F3 | Toggle debug overlay |
| F4 | Cicla filtro: ALL → INFO+ → WARN+ → ERROR |
