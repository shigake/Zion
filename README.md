# Zion

Survivors roguelite estilo Vampire Survivors / The Spell Brigade, feito com **Godot 4** (GDScript).

## Sobre

Zion e um survivors roguelite 3D com tematicas variadas, **12 personagens jogaveis**, **28 armas**, **10 fases** com bosses unicos e sistema de progressao entre runs. Suporta **co-op online ate 4 jogadores** via ENet.

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
│   ├── prd_*.md            # 8 PRDs (3d_models, art_direction, auto_tester, icons, etc.)
│   └── balance_analysis.md # Analise de balanceamento verificada
├── server/                 # Servidor de telemetria (Node.js)
│   ├── index.js            # Express + SQLite (API + dashboard)
│   ├── package.json        # Dependencias (express, better-sqlite3)
│   ├── .env.example        # Variaveis de ambiente (PORT, API_KEY, DISCORD_WEBHOOK_URL)
│   └── public/             # Dashboard web estatico
└── game/                   # Projeto Godot 4
    ├── project.godot       # Configuracao do projeto (autoloads, layers, display)
    ├── VERSION             # Versao atual do jogo (sem "v")
    ├── scenes/             # Cenas (.tscn) — 96 arquivos
    │   ├── enemies/        # 16 inimigos genericos + 10 bosses (26 total)
    │   ├── stages/         # 10 fases com ambientes procedurais
    │   ├── weapons/        # 35 cenas (28 armas + projeteis)
    │   ├── ui/             # HUD, menus, level up, shop, leaderboard, debug overlay
    │   └── player/         # Cena do jogador
    ├── scripts/            # GDScript (.gd) — 153 arquivos
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
| CharacterDB | 12 personagens, stats e armas iniciais |
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

### 12 Personagens
Ronin, Soldado, Mago, Berserker, Ninja, Necro, Pirata, Engenheiro, Vampiro, Gladiador, Chef, ???

### 28 Armas
| Tipo | Armas |
|------|-------|
| **Melee** (10) | Katana, Foice, Machado, Chicote, Lanca, Martelo, Nunchaku, Katana Dupla, Espada Cloud, Luvas de Boxe |
| **Ranged** (10) | Metralhadora, Staff, Bazuca, Shuriken, Pistola Dupla, Lanca-chamas, Cajado de Gelo, Besta, Canhao de Plasma, Arco Elfico |
| **Summon** (8) | Necromante, Drone, Totem, Garrafa de Veneno, Corrente Eletrica, Livro Magico, Bomba Relogio, Portal |

### 10 Fases
| Fase | Ambiente | Boss | Mecanica Unica |
|------|---------|------|----------------|
| Cemiterio | Neblina, lapides | Necromancer King | Lapides destrutiveis |
| Floresta | Cogumelos magicos | Rainha das Fadas | Cogumelos com buffs |
| Fazenda | Silos, milharal | Mega Vaca Alienigena | Milharal esconde inimigos |
| Toquio | Neon cyberpunk | AI Overlord | — |
| Vulcao | Lava, cavernas | Demon Lord | — |
| Oceano | Ruinas submarinas | Leviathan | — |
| Arena | Coliseu romano | Imperador Corrompido | — |
| Espaco | Estacao espacial | Singularidade | — |
| Castelo | Gotico, vampiros | Conde Dracula | — |
| Mundo Doce | Chocolate, sorvete | Rei Acucar | — |

### Sistemas
- **19 itens passivos** com efeitos funcionais
- **12 evolucoes** de armas (arma lv8 + item lv5)
- **7 reliquias** pre-run
- **10 eventos** especiais (Horda Dourada, Eclipse, Chuva de Meteoros, etc)
- **13 achievements**
- **12 upgrades** permanentes na loja
- **Leaderboard** local (modo Endless)
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
| [Personagens](docs/personagens.md) | 12 personagens e armas |
| [Progressao](docs/progressao.md) | Loja, cristais, meta-progressao |
| [Balance Analysis](docs/balance_analysis.md) | Analise de balanceamento verificada |
| [Art Prompts](docs/art_prompts.md) | Prompts de arte para geracao de assets |

### PRDs ativos
| Documento | Descricao |
|-----------|-----------|
| [3D Models](docs/prd_3d_models.md) | PRD de modelos 3D |
| [Auto Tester](docs/prd_auto_tester.md) | PRD de testes automatizados |
| [Art Direction](docs/prd_art_direction.md) | PRD de direcao artistica |
| [Docs Update](docs/prd_docs_update.md) | PRD de atualizacao de docs |
| [Icon/Projectile Polish](docs/prd_icon_projectile_polish.md) | PRD de polish de icones e projeteis |
| [Icons](docs/prd_icons.md) | PRD de icones |
| [Projectile Effects](docs/prd_projectiles_effects.md) | PRD de efeitos de projeteis |
| [Future](docs/prd_future.md) | Roadmap futuro |

## Configuracoes do Projeto

- **Resolucao**: 1280x720 (stretch mode: canvas_items, aspect: expand)
- **Renderer**: Forward Plus
- **MSAA**: 2x
- **Physics layers**: Players, Enemies, Pickups, PlayerAttacks, EnemyAttacks

## Plataforma

- Steam (PC Windows)

## Status

Em desenvolvimento ativo. Versao atual: **2.29.2**

Todas as 10 fases, 12 personagens, 28 armas e 10 bosses implementados. Sistema de telemetria e logging completo com dashboard web. Modo ascensao (mutacoes), cross-combos multiplayer, revive com sacrificio, desafio diario, sistema de performance (LOD/culling), drops de vida/ima, barras de HP tematicas por personagem, HUD multiplayer com ping e setas de aliados, modelos 3D Quaternius integrados, e selecao de personagem estilo Genshin.

### Trabalho Restante
- **Audio**: sistema implementado, faltam arquivos .ogg/.wav
- **Steam**: stub existe, falta plugin GodotSteam
- **3D Models**: modelos Quaternius integrados, falta polish e customizacao
- **Art Direction**: concept art de referencia (ver docs/prd_art_direction.md)
