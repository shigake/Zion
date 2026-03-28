# Zion

> *"Zion nao e onde voce chega. E o que voce constroi no caminho."*

Survivors roguelite 3D feito com **Godot 4** (GDScript).

## Sobre

**Zion** era o ultimo santuario entre dimensoes, mantido por um cristal primordial. Algo o estilhacou. Voce e um **Fragmentado** — arrancado de outra realidade, com um estilhaco do cristal dentro de si. Sua missao: fechar as **7 fendas dimensionais**, libertar os **Sentinelas Corrompidos**, e reconstruir Zion.

**14 Fragmentados jogaveis**, **28 armas**, **7 fendas + 3 anomalias**, **10 Sentinelas** e co-op online ate 4 jogadores via ENet.

## Requisitos

- [Godot Engine 4.6+](https://godotengine.org/download) (versao com console recomendada para debug)
- [Blender 3.0+](https://www.blender.org/download/) (obrigatorio para renderizar e exportar modelos 3D)
- Windows 10/11 (64-bit)
- Git

## Setup Rapido

```bash
# 1. Clone o repositorio
git clone <url-do-repo>
cd Zion

# 2. Abra no editor do Godot (uma das opcoes abaixo)

# Opcao A: Se godot esta no PATH
godot --editor --path game

# Opcao B: Defina a variavel GODOT com o caminho do seu executavel
GODOT="/caminho/para/godot"
"$GODOT" --editor --path game

# Opcao C: Abra o Godot Editor manualmente e importe game/project.godot
```

Na primeira vez o Godot importa todos os assets automaticamente.

## Como Rodar

### Pelo Editor
- Abra o projeto no Godot Editor
- Pressione **F5** ou clique no botao **Play**

### Pela Linha de Comando
```bash
# Se godot esta no PATH
godot --path game --run

# Se godot NAO esta no PATH, use o caminho completo do seu executavel
# Exemplo: "/caminho/para/godot" --path game --run
```

### Verificar Erros (Headless)
```bash
godot --headless --import game/project.godot
```

## Como Compilar (Export)

### Pelo Editor
1. Abra o projeto no Godot Editor
2. Va em **Project > Export**
3. Adicione um preset (ex: Windows Desktop)
4. Configure o caminho de saida
5. Clique em **Export Project**

### Pela Linha de Comando
```bash
# Precisa configurar export preset antes no editor
godot --headless --path game --export-release "Windows Desktop" ../build/zion.exe
```

## Estrutura do Projeto

```
Zion/
├── CLAUDE.md               # Guia de desenvolvimento (instrucoes para AI/devs)
├── README.md               # Este arquivo
├── docs/                   # Documentacao de game design (18 arquivos)
│   ├── gdd.md              # Game Design Document
│   ├── prd.md              # Product Requirements Document (roadmap)
│   ├── spec.md             # Especificacao tecnica
│   ├── fases.md            # Detalhes das 10 fases
│   ├── itens.md            # Itens, evolucoes, reliquias
│   ├── mecanicas.md        # Mecanicas de gameplay
│   ├── personagens.md      # 12 personagens e armas
│   ├── progressao.md       # Loja, cristais, meta-progressao
│   ├── prd_*.md            # PRDs (auto_tester, achievements_popup, leaderboard_online, cemetery_music, etc.)
│   └── balance_analysis.md # Analise de balanceamento verificada
├── server/                 # Servidor de telemetria (Node.js)
│   ├── index.js            # Express + SQLite (API + dashboard)
│   ├── package.json        # Dependencias (express, better-sqlite3)
│   ├── .env.example        # Variaveis de ambiente (PORT, API_KEY, DISCORD_WEBHOOK_URL)
│   └── public/             # Dashboard web estatico
└── game/                   # Projeto Godot 4
    ├── project.godot       # Configuracao do projeto (autoloads, layers, display)
    ├── VERSION             # Versao atual do jogo (sem "v")
    ├── scenes/             # Cenas (.tscn) — 98 arquivos
    │   ├── enemies/        # 16 inimigos genericos + 10 bosses (26 total)
    │   ├── stages/         # 10 fases com ambientes procedurais
    │   ├── weapons/        # 35 cenas (28 armas + projeteis)
    │   ├── ui/             # HUD, menus, level up, shop, leaderboard, debug overlay
    │   └── player/         # Cena do jogador
    ├── scripts/            # GDScript (.gd) — 186 arquivos
    │   ├── autoload/       # 27 singletons globais (ver tabela abaixo)
    │   ├── player/         # Controlador do jogador
    │   ├── enemies/        # Base + spawner + 10 bosses + 6 especiais
    │   ├── weapons/        # 28 armas + projectiles/behaviors
    │   ├── ui/             # 24 telas + debug overlay (F3/F4)
    │   ├── stages/         # 10 stages + 10 props procedurais + camera + events
    │   ├── effects/        # 9 scripts (particulas, shaders, animacoes procedurais)
    │   └── tests/          # Testes
    └── assets/             # Materiais, shaders, audio
```

## Arquitetura

### Autoload Singletons (30)

| Singleton | Responsabilidade |
|-----------|-----------------|
| LogManager | Logging centralizado, crash reports, diagnosticos (primeiro autoload) |
| PlatformHelper | Deteccao de plataforma e helpers |
| GameManager | Estado global, loop do jogo, timers |
| WeaponDB | Catalogo de 28 armas e stats por level |
| ItemDB | 19 itens passivos e seus efeitos |
| CharacterDB | 14 Fragmentados, stats e armas iniciais |
| EvolutionDB | 12 evolucoes (arma lv8 + item lv5) |
| RelicDB | 7 reliquias pre-run |
| ShopDB | 12 upgrades permanentes |
| SaveManager | Save/load local (perfil, cristais, progresso) |
| MultiplayerManager | ENet host-client, lobby, sync, reconexao, host migration |
| SynergySystem | 6 sinergias base + 4 agua + 8 cross-combos |
| AudioManager | Musica + SFX com crossfade |
| ScreenEffects | Efeitos de tela (shake, flash, fade) |
| ParticleFactory | Factory de particulas procedurais |
| ObjectPool | Pool de objetos (inimigos, projeteis) |
| UITheme | Tema visual global |
| KeybindingManager | Rebind de teclas |
| LocaleManager | i18n (PT-BR / EN) |
| VisualSetup | Setup visual global (luzes, ambiente) |
| ModelFactory | Factory de modelos 3D procedurais |
| SteamManager | Stub para integracao Steam |
| AchievementManager | 13 achievements |
| MultiMeshManager | Renderizacao otimizada de hordas |
| AutoTester | Testes automatizados in-game |
| GamepadUI | Navegacao de UI por gamepad |
| Telemetry | Analytics anonimo + envio de crash reports ao servidor |
| MutationManager | 6 mutacoes do modo ascensao |
| DailyChallenge | Desafio diario com leaderboard online |

### Multiplayer
- **Host-client**: um jogador hospeda, outros conectam via ENet
- **Steam Networking Sockets**: preparado via SteamManager stub
- **Sync**: posicoes unreliable (20 tick/s), eventos criticos reliable

### Sistemas de Gameplay
- **Armas**: nivel 1-8, evoluem no 8 com item correspondente no 5
- **Spawner**: dificuldade escala com tempo, skins por stage
- **Props procedurais**: cada stage gera seu ambiente (meshes, luzes, particulas)
- **Animacoes procedurais**: idle bob, walk lean, hit squash-stretch, death tumble
- **Sinergias**: 6 base + 4 agua (Tidal Wave, Steam Explosion, Absolute Zero, Abyssal Depths) + 8 cross-combos multiplayer
- **Mutacoes/Ascensao**: 6 modificadores de dificuldade que aumentam recompensa de cristais
- **Cross-Combo**: Sinergias elementais entre jogadores no multiplayer (12 combinacoes)
- **Revive**: Sistema de lapide no multiplayer com sacrificio (debuff -30% HP)
- **Daily Challenge**: Desafio diario com seed fixa e leaderboard online
- **Performance**: LOD system, PerfMonitor, EnemyCuller, cap de pickups
- **Drops**: Coracoes (5% chance, cura 8% HP) e imas (1% chance, atrai todos pickups)
- **HP Tematica**: Barra de HP unica por personagem (katana, calice, cristal, etc.)

## Conteudo Implementado

### 14 Fragmentados
Ronin, Soldado, Mago, Berserker, Ninja, Necro, Pirata, Engenheiro, Vampiro, Gladiador, Chef, Amazona, Bruxa, ???

### 28 Armas
| Tipo | Armas |
|------|-------|
| **Melee** (10) | Katana, Foice, Machado, Chicote, Lanca, Martelo, Nunchaku, Katana Dupla, Espada Cloud, Luvas de Boxe |
| **Ranged** (10) | Metralhadora, Staff, Bazuca, Shuriken, Pistola Dupla, Lanca-chamas, Cajado de Gelo, Besta, Canhao de Plasma, Arco Elfico |
| **Summon** (8) | Necromante, Drone, Totem, Garrafa de Veneno, Corrente Eletrica, Livro Magico, Bomba Relogio, Portal |

### 7 Fendas da Campanha + 3 Anomalias

**Campanha** (arco narrativo — cada fenda e mais profunda na corrupcao):

| Fenda | Ambiente | Sentinela Corrompido | Mecanica |
|------|---------|------|----------------|
| 1. Cemiterio | Neblina, lua cheia | Necromancer King | Tumulos destrutiveis |
| 2. Floresta | Magia selvagem | Rainha das Fadas | Cogumelos de buff |
| 3. Toquio | Neon cyberpunk | AI Overlord | Paineis eletricos |
| 4. Vulcao | Lava, furia | Demon Lord | Lava pools |
| 5. Oceano | Ruinas submarinas | Leviathan | Correntes |
| 6. Espaco | Estacao orbital | Singularidade | Zero-G zones |
| 7. Castelo | Gotico, elegante | Conde Dracula | Zonas de sombra |

**Anomalias** (desbloceaveis — realidades instaveis fora das regras):

| Anomalia | Ambiente | Boss | Desbloquear |
|------|---------|------|-------------|
| α Fazenda | Rural apocaliptico | Mega Vaca Alienigena | Fendas 1-3 |
| β Arena | Coliseu romano | Imperador Corrompido | 3 bosses |
| γ Mundo Doce | Sonho corrompido | Rei Acucar | Campanha completa |

### Sistemas
- **19 itens passivos** com efeitos funcionais
- **12 evolucoes** de armas (arma lv8 + item lv5)
- **7 reliquias** pre-run
- **10 eventos** especiais (Horda Dourada, Eclipse, Chuva de Meteoros, etc)
- **13 achievements**
- **12 upgrades** permanentes na loja
- **Leaderboard** global com tabs (modo Endless)
- **Multiplayer** co-op ate 4 jogadores (ENet)
- **18 sinergias** elementais (6 base + 4 agua + 8 cross-combos)
- **11 inimigos** genericos + 6 especiais (Skeleton Archer, Mimic, Bomber, Swarm, Tank, Tooth Fairy)
- **6 mutacoes** do modo ascensao
- **Desafio diario** com leaderboard online
- **Drops** de vida e ima de inimigos
- **HP tematica** por personagem

## Telemetria e Logging

### Sistema de Logging (LogManager)
Sistema centralizado de logging com 5 niveis (DEBUG, INFO, WARNING, ERROR, FATAL):
- **Logs em arquivo** com rotacao automatica (ultimos 10 arquivos em `user://logs/`)
- **Crash reports JSON** automaticos com game state, scene tree e ultimas 100 entradas
- **Buffer em memoria** com as ultimas 500 entradas
- **Monitoramento de FPS** (alerta se cair abaixo de 20)
- **Sinais**: `log_entry_added`, `error_logged`, `crash_reported`

### Debug overlay (em jogo)
- **F3**: Ativa/desativa overlay com FPS, HP, enemies, pool stats e logs em tempo real
- **F4**: Filtra logs (ALL → INFO+ → WARN+ → ERROR)

### Telemetria (Telemetry)
Cliente anonimo de analytics com opt-out:
- Envia **estatisticas de run** ao fim de cada partida (kills, dano, armas, FPS, etc)
- Envia **crash reports** automaticamente (incluindo pendentes de sessoes anteriores)
- Envia **eventos** (achievements, etc)
- Servidor configuravel, sem dados pessoais

### Servidor de telemetria (`server/`)
Backend Node.js + Express + SQLite que recebe e analisa os dados:

```bash
cd server && npm install && npm start
# Dashboard em http://localhost:3456
```

**API endpoints:**
| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| POST | `/telemetry` | Estatisticas de fim de run |
| POST | `/crash` | Crash reports |
| POST | `/event` | Eventos (achievements, etc) |
| GET | `/stats` | Overview agregado |
| GET | `/crashes` | Lista de crashes (paginado, filtros) |
| GET | `/crashes/:id` | Detalhe de um crash |
| GET | `/runs` | Lista de runs (paginado, filtros) |
| GET | `/events` | Lista de eventos |
| GET | `/balance` | Analytics de balanceamento |
| GET | `/health` | Health check |
| PATCH | `/crashes/:id` | Marcar crash como resolvido |

**Dashboard web** (`http://localhost:3456`):
- **Overview**: total runs, crashes, win rate, FPS medio, personagens/fases populares
- **Crashes**: lista com filtros, detalhe com game state e scene tree, marcar como resolvido
- **Runs**: historico de partidas com filtros por personagem, fase, versao
- **Balance**: DPS por arma, win rate por personagem, dificuldade por fase
- **Events**: achievements e eventos do jogo

**Recursos**: rate limiting, API key opcional, Discord webhook para crashes, auto-refresh 30s.

## Controles

| Acao | Teclado | Gamepad |
|------|---------|---------|
| Mover | WASD | Left Stick |
| Dash | Space | A / X |
| Interagir | E | B / Circle |
| Pause | ESC | Start |

## Documentacao de Design

### Documentos base
| Documento | Descricao |
|-----------|-----------|
| [GDD](docs/gdd.md) | Game Design Document completo |
| [PRD](docs/prd.md) | Roadmap por fases (0-6) |
| [Spec](docs/spec.md) | Especificacao tecnica |
| [Fases](docs/fases.md) | Detalhes das 10 fases e bosses |
| [Itens](docs/itens.md) | Itens, evolucoes, reliquias |
| [Mecanicas](docs/mecanicas.md) | Gameplay e sistemas |
| [Historia](docs/story.md) | Lore completo, backstories, narrativa |
| [Personagens](docs/personagens.md) | 14 Fragmentados e armas |
| [Progressao](docs/progressao.md) | Loja, cristais, meta-progressao |
| [Balance Analysis](docs/balance_analysis.md) | Analise de balanceamento verificada |
| [Art Prompts](docs/art_prompts.md) | Prompts de arte para geracao de assets |

### PRDs ativos
| Documento | Descricao |
|-----------|-----------|
| [Auto Tester](docs/prd_auto_tester.md) | PRD de testes automatizados (8 suites) |
| [Achievements Popup](docs/prd_achievements_popup.md) | PRD de popup de conquistas |
| [Leaderboard Online](docs/prd_leaderboard_online.md) | PRD de leaderboard global |
| [Cemetery Music](docs/prd_cemetery_music.md) | PRD de musica dinamica do cemiterio (5 faixas) |

## Configuracoes do Projeto

- **Resolucao**: 1280x720 (stretch mode: canvas_items, aspect: expand)
- **Renderer**: Forward Plus
- **MSAA**: 2x
- **Physics layers**: Players, Enemies, Pickups, PlayerAttacks, EnemyAttacks

## Plataforma

- Steam (PC Windows)

## Status

Em desenvolvimento ativo. Versao atual: **2.79.0**

Todas as 7 fendas + 3 anomalias, 14 Fragmentados, 28 armas e 10 Sentinelas implementados. Camada narrativa completa (lore, backstories, dialogos de boss, loading screens com frases de lore). Sistema de telemetria com dashboard web. Modo ascensao (provacoes de Zion), cross-combos multiplayer (ressonancia entre Fragmentados), revive com sacrificio (estilhaco compartilhado), desafio diario, sistema de performance (LOD/culling), sprites pixel art billboard, 13 achievements com popup, leaderboard global, 50 SFX + 15 musicas, auto-tester com 8 suites.

### Trabalho Restante
- **Audio**: 50 SFX + 15 musicas implementados; falta musica dinamica por fenda
- **Visual Polish**: walk animations, slash trails melee, props animados
- **Steam**: stub existe, falta plugin GodotSteam
- **Narrativa**: cutscene do ???, cinematica de intro
