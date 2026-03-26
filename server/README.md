# Zion Telemetry Server

Servidor de telemetria para o jogo Zion. Recebe crash reports, metricas de gameplay e eventos dos jogadores. Dashboard web incluso.

## Setup

```bash
cd server
npm install
cp .env.example .env  # editar com suas configs
npm start
```

Acesse `http://localhost:3456` para o dashboard.

## Endpoints

### Recebimento (POST)
- `POST /telemetry` — dados de fim de run
- `POST /crash` — crash report completo (inclui game_state, scene_tree, session_stats, recent_log)
- `POST /event` — evento pontual (achievement, boss kill, etc)

### Consulta (GET)
- `GET /` — redireciona para dashboard
- `GET /dashboard` — dashboard web completo
- `GET /stats` — estatisticas agregadas (runs, crashes, win rate, FPS, versoes, OS)
- `GET /crashes` — lista de crashes com filtros (module, version, resolved, search, limit, offset)
- `GET /crashes/:id` — detalhe completo de um crash
- `GET /runs` — lista de runs com filtros (character, stage, version, victory, limit, offset)
- `GET /events` — lista de eventos (filtros: event_type, session_id, limit, offset)
- `GET /balance` — analytics de balanceamento (DPS por arma, win rate por personagem, dificuldade por fase)
- `GET /health` — health check

### Gerenciamento (PATCH)
- `PATCH /crashes/:id` — marcar como resolvido, adicionar notas

## Dashboard

O dashboard web mostra:
- **Overview**: total de runs, crashes abertos, win rate, FPS medio, personagens/fases populares
- **Crashes**: lista paginada com filtros, detalhe completo (game state, scene tree, log recente), marcar resolvido, notas
- **Runs**: todas as partidas com filtros por personagem, fase, resultado
- **Balance**: DPS por arma, win rate por personagem, dificuldade por fase
- **Events**: achievements e eventos do jogo

## Deploy

```bash
# Com PM2
npm install -g pm2
pm2 start index.js --name zion-telemetry
pm2 save
```

No jogo, configure `SaveManager.data["telemetry_url"]` com a URL do servidor.

## Variaveis de ambiente

| Variavel | Default | Descricao |
|----------|---------|-----------|
| PORT | 3456 | Porta do servidor |
| DISCORD_WEBHOOK_URL | (vazio) | Webhook do Discord para alertas de crash |
| API_KEY | (vazio) | Chave para proteger endpoints PATCH (vazio = aberto) |
