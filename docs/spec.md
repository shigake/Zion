# Zion - Spec Driven

Especificacao tecnica e funcional do jogo.

---

## 1. Visao do Produto

**O que e:** Um survivors game onde o jogador enfrenta hordas infinitas de inimigos em fases tematicas, coletando armas e itens que se combinam e evoluem.

**Publico alvo:** Jogadores casuais e mid-core que curtem runs curtas (20-30 min), progressao entre partidas, e builds criativos.

**Diferencial:** Tematicas variadas e absurdas (de cemiterio a mundo doce), sistema de evolucao de armas por combinacao, e eventos aleatorios que mudam cada run.

**Stack:** Godot 4 + GDScript + GodotSteam + Steam Networking Sockets

---

## 2. Core Loop

```
[Lobby/Loja] --> [Selecao] --> [Gameplay] --> [Resultado] --> [Lobby/Loja]
```

### 2.1 Lobby / Loja
- Jogador gasta Cristais em upgrades permanentes
- Seleciona personagem desbloqueado
- Seleciona fase desbloqueada
- Seleciona modo de jogo
- Ve achievements e colecao
- **Online:** Cria ou entra em lobby Steam (ate 4 jogadores)

### 2.2 Selecao Pre-Run
- Escolhe 1 Reliquia (modificador da run)
- **Online:** Host confirma inicio quando todos estao prontos
- Confirma e inicia

### 2.3 Gameplay (Run)
- Duracao: 30 minutos (modo normal)
- Camera: top-down 3D (~45-60 graus)
- Movimento: WASD ou analog stick
- Ataque: automatico (armas atacam sozinhas)
- Jogador foca em: posicionamento, coleta de XP/itens, escolha de upgrades
- **Online:** Cada jogador faz suas proprias escolhas de upgrade independentemente

### 2.4 Resultado
- Tela de stats: tempo sobrevivido, inimigos mortos, dano dealt, itens coletados
- Cristais ganhos na run sao creditados
- Achievements desbloqueados aparecem
- Opcao: voltar ao lobby ou replay

---

## 3. Especificacao de Sistemas

### 3.1 Sistema de Level Up

```
Inimigo morre → dropa gema de XP → jogador coleta → barra de XP enche → LEVEL UP
```

**Ao dar level up:**
- Jogo pausa **apenas para o jogador que levelou** (online: outros continuam jogando)
- 3 opcoes aparecem (arma nova, upgrade de arma existente, ou item passivo)
- Jogador escolhe 1
- Pode usar Reroll (se tiver) pra trocar as 3 opcoes
- Pode usar Banish pra remover 1 opcao permanentemente da pool

**Scaling de XP:**
- Level 1-10: rapido (30-60s por level)
- Level 11-20: medio (60-90s por level)
- Level 21+: lento (90-120s por level)

**Online:** XP e individual. Cada jogador coleta suas proprias gems. Gems sao atraidas ao jogador mais proximo.

### 3.2 Sistema de Armas

**Slots:** 4 iniciais, max 6 (upgrade na loja)

**Level de arma:** 1 a 8
- Level 1-7: upgrades normais (mais dano, mais projeteis, mais area, etc)
- Level 8: evolucao disponivel SE tiver o item passivo correto

**Evolucao:**
- Arma nivel 8 + item passivo correto = bau de evolucao aparece no mapa
- Jogador abre o bau = arma evolui pra versao final
- Arma evoluida nao sobe mais de level, ja e o maximo

### 3.3 Sistema de Itens Passivos

**Slots:** 6 slots de item passivo

**Level de item:** 1 a 5
- Cada level aumenta o efeito do item
- Item max level contribui pra evolucao de arma

### 3.4 Sistema de Inimigos

**Spawn:**
- Inimigos spawnam fora da tela em direcao ao jogador
- Quantidade e velocidade aumentam com o tempo
- Tipos de inimigos mudam conforme o minuto
- **Online:** Spawn deterministico (seed compartilhada). Host e autoridade de spawn. Clients recebem posicoes via sync.

**Tabela de Spawn (exemplo fase generica):**

| Minuto | Inimigos |
|---|---|
| 0-2 | Slimes basicos |
| 2-5 | Slimes + Bats |
| 5-8 | Skeletons + Bats + Slimes Grandes |
| 8-12 | Skeleton Archers + Ghosts + Bombers |
| 12-15 | Mini-boss + Tanks + Swarms |
| 15-20 | Mix de tudo, spawn rate alto |
| 20-25 | Spawn rate insano, inimigos elites (brilham, mais HP/dano) |
| 25-30 | Boss final + horda continua |

**Elite enemies:**
- Versao mais forte de qualquer inimigo
- Brilham com aura colorida
- Dropam bau garantido ao morrer
- Aparecem a partir do minuto 15

### 3.5 Sistema de Boss

**Mini-boss:**
- Aparece no minuto 12-15
- Barra de vida visivel
- 1 por fase
- Dropa bau raro
- **Online:** HP escala com numero de jogadores (1.5x por jogador extra)

**Boss Final:**
- Aparece no minuto 25
- Barra de vida grande no topo da tela
- Padroes de ataque em fases (muda comportamento a cada 25% HP)
- Horda continua spawning durante a luta
- Derrotar = vitoria da run
- **Online:** HP escala com numero de jogadores. Ataques targetam jogadores diferentes.

### 3.6 Sistema de Dano

```
Dano Final = (Dano Base da Arma * Level Multiplier * Upgrade Permanente) * Sinergia Bonus
```

**Tipos de dano:**
- Fisico
- Fogo (burn DoT)
- Gelo (slow + freeze)
- Eletrico (chain)
- Dark (execute threshold)
- Poison (DoT que stacka)

**Resistencias:**
- Alguns inimigos tem resistencia a tipos especificos
- Boss tem resistencia parcial a todos os tipos
- Nenhum inimigo e imune (sempre toma pelo menos 1 de dano)

### 3.7 Sistema de Eventos

- Eventos sao trigados por tempo ou aleatorios
- So 1 evento ativo por vez
- Evento avisa com popup antes de comecar (3s de aviso)
- Eventos duram 15-30 segundos
- Drop/recompensa ao final do evento
- **Online:** Eventos sao sincronizados pelo host. Todos os jogadores participam.

### 3.8 Sistema de Networking (Online Co-op)

**Arquitetura:**
- Host-client (listen server)
- Host e autoridade para: spawn de inimigos, dano, drops, eventos, boss HP
- Clients enviam: inputs de movimento, escolhas de upgrade
- Sincronizacao: posicoes (unreliable), eventos criticos (reliable)

**Steam Integration:**
- GodotSteam GDExtension
- Steam Lobby para matchmaking (criar/listar/entrar em salas)
- Steam Networking Sockets para comunicacao (P2P com relay fallback)
- Steam Rich Presence (mostrar status no perfil)

**Fluxo de conexao:**
```
Host cria lobby Steam → Amigos veem e entram → Host inicia partida
→ Todos carregam fase → Host spawna jogadores → Jogo comeca sincronizado
```

**Tratamento de desconexao:**
- Se client desconecta: jogador dele desaparece, inimigos nao escalam mais pra ele
- Se host desconecta: host migration (proximo client vira host) OU run termina
- Reconnect: client pode reconectar ao lobby se run ainda estiver ativa

---

## 4. Controles

### Teclado + Mouse
| Input | Acao |
|---|---|
| WASD | Movimento |
| Mouse | Direcao (pra armas direcionais) |
| Space | Dash/Dodge (cooldown 3s) |
| E | Interagir (bau, merchant) |
| ESC | Pause menu |
| 1-6 | Info da arma no slot |

### Gamepad
| Input | Acao |
|---|---|
| Left Stick | Movimento |
| Right Stick | Direcao |
| A / X | Dash/Dodge |
| B / Circle | Interagir |
| Start | Pause |

---

## 5. UI / HUD

### Durante o Gameplay
```
[HP Bar]                              [Timer 00:00]
[XP Bar ████████░░░░ Lv.12]

                  [Personagem]

[Arma1][Arma2][Arma3][Arma4][Arma5][Arma6]
[Item1][Item2][Item3][Item4][Item5][Item6]

[Kill Count: 1234]    [Cristais: 567]
```

**Online adicional:**
- HP bars dos outros jogadores (compactas, no canto)
- Indicadores de direcao dos aliados quando fora da tela
- Ping/latencia no canto

### Tela de Level Up
```
┌─────────────────────────────────┐
│         LEVEL UP!               │
│                                 │
│  [Opcao 1]  [Opcao 2]  [Opcao 3] │
│   Arma X     Item Y     Arma Z  │
│   Lv.3→4     Novo!      Lv.1→2  │
│                                 │
│  [Reroll: 3]    [Banish: 2]     │
└─────────────────────────────────┘
```

### Tela de Resultado
```
┌─────────────────────────────────┐
│       RUN COMPLETA!             │
│                                 │
│  Tempo: 28:34                   │
│  Inimigos: 8,432                │
│  Dano Total: 1,234,567          │
│  Nivel Final: 45                │
│  Cristais: +890                 │
│                                 │
│  [Achievement] A Vaca Foi Pro   │
│                Brejo!           │
│                                 │
│  [Lobby]  [Replay]  [Proxima]   │
└─────────────────────────────────┘
```

---

## 6. Progressao de Dificuldade

| Aspecto | Min 0 | Min 10 | Min 20 | Min 30 |
|---|---|---|---|---|
| Spawn Rate | 1x | 3x | 8x | 15x |
| HP dos Inimigos | 1x | 2x | 5x | 10x |
| Velocidade | 1x | 1.2x | 1.5x | 2x |
| Tipos de Inimigo | 2 | 5 | 8 | Todos |
| Elites | Nao | Nao | Sim | Sim (frequente) |

**Online scaling:**
| Jogadores | HP Inimigos | Spawn Rate | Boss HP |
|---|---|---|---|
| 1 | 1x | 1x | 1x |
| 2 | 1.3x | 1.2x | 1.5x |
| 3 | 1.6x | 1.4x | 2x |
| 4 | 2x | 1.6x | 2.5x |

---

## 7. Audio

### Musica
- Cada fase tem tema unico
- Musica intensifica conforme o tempo passa (layers adicionais)
- Boss tem tema proprio
- Lobby tem musica calma

### SFX
- Cada arma tem som unico de ataque
- Som de hit/dano
- Som de coleta de XP (satisfatorio, tipo "pling")
- Som de coleta de item
- Som de level up (fanfarra curta)
- Som de evolucao de arma (epico)
- Som de morte de inimigo (varia por tipo)
- Som de boss (rugido ao aparecer)

---

## 8. Requisitos Tecnicos

### Performance Target
- 60 FPS constante com 1000+ inimigos na tela
- Otimizacao de rendering pra sprites/modelos em massa
- Object pooling pra projeteis e inimigos
- MultiMeshInstance3D para rendering de hordas

### Networking Target
- Latencia aceitavel ate 150ms
- Tick rate: 20 updates/s para posicoes, 60 para inputs
- Bandwidth: <50KB/s por jogador

### Plataforma
- Steam (Windows)
- Resolucoes: 1920x1080 (base), 2560x1440, 3840x2160
- Fullscreen, windowed, borderless

### Save System
- Save local (perfil do jogador, upgrades, desbloqueaveis)
- Steam Cloud Sync
- Auto-save entre runs (nao salva durante run)

---

## 9. Milestones

### M1 - Prototipo Jogavel (Solo)
- [ ] Movimento 3D top-down com cel-shader basico
- [ ] 2 armas funcionais (1 melee, 1 ranged)
- [ ] Inimigos spawnam e morrem (object pooling)
- [ ] Sistema de XP e level up com 3 choices
- [ ] 1 fase (Cemiterio) com ambiente 3D
- [ ] HUD basico
- [ ] Dash/Dodge

### M2 - Online Co-op + Core Loop
- [ ] Steam Lobby (criar/entrar sala)
- [ ] Multiplayer funcional 2-4 jogadores
- [ ] Sincronizacao de inimigos e drops
- [ ] Loja entre runs (3-4 upgrades permanentes)
- [ ] 3 armas adicionais
- [ ] 3 itens passivos
- [ ] 1 boss funcional

### M3 - Conteudo Base
- [ ] 3 personagens jogaveis (Ronin, Soldado, Mago)
- [ ] 8 armas totais com evolucoes
- [ ] 3 fases completas (Cemiterio, Floresta, Fazenda)
- [ ] 8 itens passivos
- [ ] 3 reliquias
- [ ] Sistema de eventos (3 eventos)
- [ ] Tela de resultado com stats

### M4 - Polish + Early Access
- [ ] Balanceamento (solo e multiplayer)
- [ ] Audio (musica + SFX)
- [ ] UI final
- [ ] Tutorial / onboarding
- [ ] Steam page
- [ ] Achievements basicos
- [ ] Modo Endless

### M5 - Full Release
- [ ] Fases 4-10
- [ ] Todos os personagens e armas
- [ ] Todos os itens e evolucoes
- [ ] Daily Challenge (backend)
- [ ] Workshop support
- [ ] QA e optimization final

---

## 10. Sistema de Logging e Diagnosticos

### 10.1 LogManager (Autoload)

Sistema centralizado de logging — **deve ser o primeiro autoload** para capturar logs de todos os outros sistemas.

**Niveis:** DEBUG, INFO, WARNING, ERROR, FATAL

**API:**
```gdscript
LogManager.debug("Module", "mensagem")
LogManager.info("Module", "mensagem")
LogManager.warn("Module", "mensagem")
LogManager.error("Module", "mensagem")        # incrementa contador de erros
LogManager.fatal("Module", "mensagem")        # gera crash report automatico
LogManager.log_exception("Module", error, stack)  # exception com stack trace
LogManager.report_crash("Module", "desc", extra)  # crash report manual
```

**Armazenamento:**
- Logs: `user://logs/zion_YYYYMMDD_HHMMSS.log`
- Crash reports: `user://logs/crashes/crash_YYYYMMDD_HHMMSS.json`
- Rotacao automatica (max 10 logs, 20 crash reports)

**Crash report inclui:** timestamp, session_id, system_info (Godot, OS, renderer, memoria), session_stats (uptime, FPS, contadores), game_state (tempo, nivel, HP, kills, armas), scene_tree, ultimas 100 entradas de log, extra_data.

**Sinais:**
- `log_entry_added(entry: Dictionary)`
- `error_logged(module, message)`
- `crash_reported(report_path)`

### 10.2 Debug Overlay

Overlay em tempo real ativado por teclas de atalho durante gameplay:

| Tecla | Funcao |
|-------|--------|
| F3 | Toggle overlay (FPS, enemies, HP, pool stats, logs coloridos) |
| F4 | Cicla filtro de logs (ALL → INFO+ → WARN+ → ERROR) |

Mostra ate 20 entradas de log simultaneas com cor por nivel. CanvasLayer 100 (sempre no topo), nao bloqueia input do jogo.

---

## 11. Sistema de Telemetria

### 11.1 Cliente (Telemetry autoload)

Analytics anonimo com opt-out (`SaveManager.data["telemetry_enabled"]`).

**Dados enviados automaticamente:**
- **Fim de run** (POST /telemetry): session_id, version, character, stage, mode, survived_seconds, victory, kills, damage, level, weapons, items, evolutions, events, crystals, FPS, peak_enemies, OS, renderer
- **Crash reports** (POST /crash): report completo do LogManager
- **Achievements** (POST /event): id, name, time

**Crash reports pendentes** de sessoes anteriores sao enviados 5s apos startup.

### 11.2 Servidor (`server/`)

Backend Node.js + Express + SQLite (better-sqlite3) com WAL mode.

**Rodar:** `cd server && npm install && npm start` → `http://localhost:3456`

**Variaveis de ambiente (.env):**
- `PORT` (default: 3456)
- `API_KEY` (opcional, protege PATCH endpoints)
- `DISCORD_WEBHOOK_URL` (opcional, alerta crashes no Discord)

**Endpoints:**

| Metodo | Rota | Rate Limit | Descricao |
|--------|------|-----------|-----------|
| POST | /telemetry | 30/min | Dados de fim de run |
| POST | /crash | 10/min | Crash reports |
| POST | /event | 60/min | Eventos (achievements, etc) |
| GET | /stats | — | Overview agregado |
| GET | /crashes | — | Lista paginada + filtros (module, version, resolved, search) |
| GET | /crashes/:id | — | Detalhe de crash |
| GET | /runs | — | Lista paginada + filtros (character, stage, version, victory) |
| GET | /events | — | Lista paginada + filtros (event_type, session_id) |
| GET | /balance | — | DPS por arma, win rate por char, dificuldade por stage |
| GET | /health | — | Health check |
| PATCH | /crashes/:id | — | Resolver crash / adicionar notas (API key) |

**Dashboard web** (`/dashboard`): Overview, Crashes, Runs, Balance, Events. Auto-refresh 30s.

### 11.3 Privacidade
- Sem dados pessoais (sem nome, email, IP armazenado)
- Session ID aleatorio e nao-identificavel
- Opt-out disponivel nas opcoes do jogo
- Dados usados exclusivamente para melhorar o jogo
