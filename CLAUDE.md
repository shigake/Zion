# Zion - Development Guide

## Project

Survivors roguelite 3D feito com Godot 4 (GDScript). Co-op online ate 4 jogadores.
14 personagens, 28 armas, 10 fases, 10 bosses, 12 evolucoes, 19 itens, 7 reliquias, 13 achievements.

## Quick Start

```bash
# Certifique-se de que "godot" esta no PATH, ou defina a variavel GODOT:
# GODOT="/caminho/para/godot"   (cada dev configura o seu)

# Rodar o jogo
godot --path game --run

# Abrir no editor
godot --editor --path game

# Verificar erros (headless)
godot --headless --import game/project.godot

# Export para Windows (precisa preset configurado no editor)
godot --headless --path game --export-release "Windows Desktop" ../build/zion.exe

# Servidor de telemetria (dashboard em http://localhost:3456)
cd server && npm install && npm start
```

**Nota**: Para desenvolvimento de modelos 3D, é obrigatório usar **Blender 3.0+** para renderizar e exportar assets.

## Structure

```
Zion/
├── CLAUDE.md                    # Este arquivo — guia de dev
├── README.md                    # Documentacao publica do projeto
├── docs/                        # Game design documents
│   ├── gdd.md                   # Game Design Document
│   ├── prd.md                   # Product Requirements (roadmap fases A-E)
│   ├── spec.md                  # Especificacao tecnica
│   ├── fases.md                 # 10 fases detalhadas
│   ├── itens.md                 # Itens, evolucoes, reliquias
│   ├── mecanicas.md             # Mecanicas de gameplay
│   ├── personagens.md           # 14 personagens
│   ├── progressao.md            # Loja, cristais, meta-progressao
│   ├── balance_analysis.md      # Analise de balanceamento verificada
│   ├── art_prompts.md           # Prompts de arte para assets
│   ├── prd_auto_tester.md       # PRD de testes automatizados (8 suites)
│   ├── prd_achievements_popup.md # PRD de popup de conquistas
│   ├── prd_leaderboard_online.md # PRD de leaderboard global
│   └── prd_cemetery_music.md    # PRD de musica dinamica do cemiterio
├── server/                      # Servidor de telemetria (Node.js)
│   ├── index.js                 # Express + SQLite (API REST + dashboard web)
│   ├── package.json             # Dependencias (express, better-sqlite3)
│   ├── .env.example             # PORT, API_KEY, DISCORD_WEBHOOK_URL
│   └── public/                  # Dashboard web estatico
└── game/                        # Projeto Godot 4
    ├── project.godot            # Config (autoloads, layers, display)
    ├── VERSION                  # Versao atual (sem "v")
    ├── scenes/ (98 .tscn)        # Cenas
    │   ├── enemies/             # 16 genericos + 10 bosses (26 total)
    │   ├── stages/              # 10 stages com props procedurais
    │   ├── weapons/             # 35 cenas (28 armas + projeteis)
    │   ├── ui/                  # HUD, menus, shop, leaderboard, debug overlay
    │   └── player/              # Cena do jogador
    ├── scripts/ (186 .gd)        # GDScript
    │   ├── autoload/            # Singletons (ver lista abaixo)
    │   ├── player/              # Player controller
    │   ├── enemies/             # Base + spawner + 10 bosses + especiais
    │   ├── weapons/             # 28 armas + projectiles + behaviors
    │   ├── ui/                  # 24 telas + debug overlay (F3/F4)
    │   ├── stages/              # 10 stages + 10 props + camera + events
    │   ├── effects/             # 9 scripts (particulas, shaders, procedural anims)
    │   └── tests/               # Testes
    └── assets/                  # Materiais, shaders, audio
```

## Architecture

### Autoload Singletons (30 total)
LogManager, PlatformHelper, GameManager, WeaponDB, ItemDB, SaveManager, ShopDB, CharacterDB, RelicDB, EvolutionDB, MultiplayerManager, SynergySystem, AudioManager, ObjectPool, AchievementManager, UITheme, KeybindingManager, LocaleManager, SteamManager, Telemetry, MultiMeshManager, AutoTester, GamepadUI, MutationManager, DailyChallenge

Adicionalmente registrados como autoload (mas ficam em scripts/effects/):
ScreenEffects, ParticleFactory, VisualSetup, ModelFactory

DebugOverlay fica em scripts/ui/ (registrado como autoload).

Nota: LodManager e PerfMonitor existem em scripts/autoload/ mas NAO estao registrados como autoload no project.godot (sao instanciados manualmente).

### Key Systems
- **Multiplayer**: Host-client via ENet (Steam Networking Sockets pronto via SteamManager stub), ping RPC, reconexao automatica, host migration
- **Enemy spawning**: ObjectPool-backed, dificuldade escala com tempo, skins por stage
- **Weapons**: nivel 1-8, evolucao no 8 com item correspondente no 5
- **Procedural props**: cada stage gera ambiente (meshes, luzes, particulas)
- **Procedural anims**: idle bob, walk lean, hit squash-stretch, death tumble
- **Synergies**: 6 sinergias base + 4 sinergias de agua + 8 cross-combos (Fogo, Gelo, Eletrico, Dark, Agua)
- **Logging**: LogManager (5 niveis, arquivo + console, crash reports JSON, rotacao)
- **Telemetria**: Telemetry client → servidor HTTP (runs, crashes, events, balance)
- **Debug overlay**: F3 (overlay tempo real), F4 (filtro de logs)
- **Mutations/Ascension**: MutationManager — 6 difficulty modifiers that increase crystal rewards
- **Cross-Combo**: Multiplayer cross-player elemental synergies via SynergySystem
- **Revive System**: Tombstone-based revival in multiplayer with sacrifice debuff
- **Daily Challenge**: DailyChallenge singleton — desafio diario com leaderboard online
- **Performance**: LOD system, PerfMonitor, EnemyCuller, pickup cap (200)
- **Damage Feedback**: Screen shake, damage numbers, player hurt flash
- **Drops**: Health pickups (5% chance) e magnet pickups (1% chance) de inimigos
- **Themed HP Bar**: Barra de HP unica por personagem (katana/ronin, calice/vampiro, cristal/mago, etc.)

### Physics Layers
1. Players
2. Enemies
3. Pickups
4. PlayerAttacks
5. EnemyAttacks

### Display
- Viewport: 1280x720 (stretch: canvas_items, aspect: expand)
- Renderer: Forward Plus, MSAA 2x
- Main scene: `res://scenes/ui/main_menu.tscn`

## Content Summary

- **Characters**: 14 (ronin, soldado, mago, berserker, ninja, necro, pirata, engenheiro, vampiro, gladiador, chef, mystery, amazona, bruxa)
- **Weapons**: 28 (10 melee, 10 ranged, 8 summon/special)
- **Stages**: 10 (cemetery, forest, farm, tokyo, volcano, ocean, arena, space, castle, candy)
- **Bosses**: 10 (one per stage, each with 3 phases)
- **Enemies**: 11 genericos + 6 especiais + 40 tematicos (4 por stage)
- **Items**: 19 passive items
- **Evolutions**: 12 weapon evolutions
- **Relics**: 7 pre-run relics
- **Events**: 10 special events
- **Achievements**: 13
- **Shop upgrades**: 12 permanent upgrades

## Notificacoes Discord

Quando terminar uma task, notifique o Discord automaticamente:

```bash
curl -s -X POST http://localhost:3123/notify -H "Content-Type: application/json" -d "{\"channel\": \"zion\", \"message\": \"DESCRICAO DO QUE FOI FEITO\", \"status\": \"done\"}"
```

Status disponiveis: `done` (concluido), `error` (falhou), `info` (informativo), `warning` (atencao).
Sempre notifique ao concluir ou falhar uma task. Escreva a mensagem em portugues.

## Versionamento

Arquivo `game/VERSION` contem a versao atual (sem o "v"). Começa em 1.0.0.
O label de versão aparece no canto inferior direito do menu principal.

**Regra obrigatoria — ao terminar QUALQUER tarefa:**
1. Incrementar a **patch** version em `game/VERSION` (ex: 1.1.0 → 1.1.1)
2. Fazer `git add` + `git commit` + `git push` automaticamente
3. Notificar o Discord

Se a tarefa for grande (feature nova), incrementar a **minor** (ex: 1.1.0 → 1.2.0).
Se for fix/ajuste pequeno, incrementar o **patch** (ex: 1.1.0 → 1.1.1).

## Text Style

All UI text uses sentence case (primeira letra maiuscula, resto minusculo). Proper nouns keep their capitalization.

## Current Phase

Core game completo. FASE A (visual) parcial — sprites billboard, efeitos de tela, feedback de dano. FASE B (gameplay) parcial — 10 mecanicas de stage, 40 monstros tematicos. FASE C (polish) parcial — achievements popup, leaderboard global. FASE D (audio) quase completa — 50 SFX, 15 musicas chiptune, falta musica dinamica por fase. FASE E (infra) pendente.

Ver `docs/prd.md` para roadmap completo.

## Remaining Work

- **Audio**: 50 SFX + 15 musicas implementados; falta musica dinamica por fase (ver docs/prd_cemetery_music.md)
- **Visual Polish**: walk animations, slash trails melee, props animados, tela de loading (ver FASE A do prd.md)
- **Steam**: plugin GodotSteam necessario para multiplayer P2P
- **Tutorial**: tutorial interativo para novos jogadores (ver FASE C do prd.md)

## Regras Importantes

### Proibido caminhos hardcoded
**NUNCA** use caminhos absolutos de usuario no codigo ou na documentacao (ex: `/c/Users/shiga/...`, `C:\Users\fulano\...`).
Mais de uma pessoa trabalha neste projeto — caminhos hardcoded quebram na maquina dos outros.

Use sempre:
- Caminhos relativos ao projeto (ex: `os.path.join(__file__, "..", "game", ...)`)
- Variaveis de ambiente (ex: `$GODOT`, `$HOME`)
- Instrucoes genericas na documentacao (ex: "configure o caminho do seu Godot")
