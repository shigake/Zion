# Zion - Development Guide

## Project

Survivors roguelite 3D feito com Godot 4 (GDScript). Co-op online ate 4 jogadores.
15 Fragmentados, 32 armas, 7 fendas + 3 anomalias, 10 Sentinelas, 12 evolucoes, 19 itens, 7 reliquias, 13 achievements. 333+ sprites, 43 SFX, 16 musicas.

### Narrativa
**Zion** era o ultimo santuario entre dimensoes, mantido pelo Coracao de Zion. Algo o estilhacou. Os jogadores sao **Fragmentados** — pessoas com estilhacos do cristal dentro de si. Cada fenda e uma realidade corrompida, cada boss e um **Sentinela Corrompido** a ser libertado (nao morto). A morte rebobina o Fragmentado ao hub. A loja e Zion se reconstruindo. Cristais sao fragmentos de Zion se reunindo. Ver `docs/story.md` para lore completo.

**Regra narrativa**: toda feature nova DEVE respeitar a narrativa do story.md. Bosses sao Sentinelas prisioneiros. Fases sao fendas dimensionais. Jogadores sao Fragmentados. Cristais sao partes de Zion.

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
│   ├── story.md                 # Historia, lore, narrativa completa
│   ├── fases.md                 # 7 fendas campanha + 3 anomalias
│   ├── itens.md                 # Itens, evolucoes, reliquias
│   ├── mecanicas.md             # Mecanicas de gameplay
│   ├── personagens.md           # 15 Fragmentados + backstories
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
    │   ├── stages/              # 10 fendas com props procedurais
    │   ├── weapons/             # 35 cenas (28 armas + projeteis)
    │   ├── ui/                  # HUD, menus, shop, leaderboard, debug overlay
    │   └── player/              # Cena do jogador
    ├── scripts/ (186 .gd)        # GDScript
    │   ├── autoload/            # Singletons (ver lista abaixo)
    │   ├── player/              # Player controller
    │   ├── enemies/             # Base + spawner + 10 bosses + especiais
    │   ├── weapons/             # 28 armas + projectiles + behaviors
    │   ├── ui/                  # 24 telas + debug overlay (F3/F4)
    │   ├── stages/              # 10 fendas + 10 props + camera + events
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
- **Multiplayer**: Host-client via ENet, ping RPC, reconexao, host migration. Narrativa: estilhacos ressoam entre Fragmentados
- **Enemy spawning**: ObjectPool-backed, dificuldade escala com tempo, skins por fenda
- **Weapons**: nivel 1-8, evolucao no 8 com item no 5 (ressonancia cristalina)
- **Procedural props**: cada fenda gera ambiente (meshes, luzes, particulas)
- **Procedural anims**: idle bob, walk lean, hit squash-stretch, death tumble
- **Synergies**: 6 base + 4 agua + 8 cross-combos. Narrativa: ressonancia entre cristais
- **Logging**: LogManager (5 niveis, arquivo + console, crash reports JSON)
- **Telemetria**: Telemetry client → servidor HTTP
- **Debug overlay**: F3 (overlay tempo real), F4 (filtro de logs)
- **Mutations/Ascension**: MutationManager — 6 provacoes de Zion que aumentam recompensa de cristais
- **Cross-Combo**: Ressonancia elemental entre Fragmentados (multiplayer)
- **Revive System**: Estilhaco compartilhado — sacrificio de cristal pra impedir rebobinamento
- **Daily Challenge**: DailyChallenge — micro-fraturas diarias com leaderboard
- **Performance**: LOD system, PerfMonitor, EnemyCuller, pickup cap (200)
- **Damage Feedback**: Screen shake, damage numbers, player hurt flash
- **Drops**: Health pickups (5%) e magnet pickups (1%) de inimigos
- **Themed HP Bar**: Barra de HP unica por Fragmentado
- **Narrativa**: Loading screens com lore, dialogos de Sentinelas, backstories, telas de morte/vitoria narrativas
- **Billboard Sprites**: Sistema de sprites 2D em billboard para personagens e inimigos no mundo 3D
- **Themed Enemies**: 4 inimigos tematicos por fenda, com aparencia e comportamento unicos
- **Daily Challenge**: Micro-fraturas diarias com modificadores e leaderboard dedicado
- **Leaderboard**: Rankings globais por fenda e modo de jogo
- **Achievement Popup**: Notificacao visual in-game ao desbloquear conquistas
- **Inventory Overlay**: Overlay de inventario acessivel durante gameplay (itens e armas ativas)
- **World Map**: Selecao de fendas via mapa do mundo com progressao visual
- **Tutorial**: Sequencia de tutorial narrativo para novos Fragmentados
- **Boss Dialogues**: Dialogos dos Sentinelas antes e durante boss fights

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

- **Fragmentados**: 15 (ronin, soldado, mago, berserker, ninja, necro, pirata, engenheiro, vampiro, gladiador, chef, mystery, amazona, bruxa, fragmentado)
- **Weapons**: 32 (11 melee, 11 ranged, 10 summon/special)
- **Fendas**: 7 campanha (cemetery, forest, tokyo, volcano, ocean, space, castle) + 3 anomalias (farm, arena, candy)
- **Sentinelas**: 10 (1 por fenda, 3 fases cada — guardioes corrompidos, nao viloes)
- **Enemies**: 11 genericos + 6 especiais + 40 tematicos (4 por fenda)
- **Items**: 19 artefatos dimensionais
- **Evolutions**: 12 ressonancias cristalinas
- **Relics**: 7 artefatos ancestrais de Zion
- **Events**: 10 anomalias dimensionais
- **Achievements**: 13 marcos da restauracao
- **Shop upgrades**: 12 restauracoes permanentes

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

Core game completo com camada narrativa implementada. 15 Fragmentados, 32 armas, 333+ sprites, 43 SFX, 16 musicas. FASE A (visual) parcial — sprites billboard, efeitos de tela, feedback de dano, bullet trails, slash trails melee (10 armas com trails + sparks). FASE B (gameplay) parcial — 10 mecanicas de fenda, 40 monstros tematicos. FASE C (polish) parcial — achievements popup, leaderboard global, dialogos de Sentinelas com typewriter + fases + cores tematicas + i18n. FASE D (audio) quase completa — 43 SFX, 16 musicas chiptune, falta musica dinamica por fenda. FASE E (infra) pendente.

Ver `docs/prd.md` para roadmap e `docs/story.md` para narrativa.

## Remaining Work

- **Sprites**: 333+ pixel art sprites implementados (personagens, inimigos, armas, itens, UI)
- **Audio**: 16 musicas + 43 SFX implementados; falta musica dinamica por fenda
- **Visual Polish**: walk animations, slash trails melee, props animados
- **Steam**: plugin GodotSteam necessario para multiplayer P2P
- **Narrativa**: cutscene do ??? (Zion despertando), cinematica de intro, tutorial narrativo

## Regras Importantes

### Proibido caminhos hardcoded
**NUNCA** use caminhos absolutos de usuario no codigo ou na documentacao (ex: `/c/Users/shiga/...`, `C:\Users\fulano\...`).
Mais de uma pessoa trabalha neste projeto — caminhos hardcoded quebram na maquina dos outros.

Use sempre:
- Caminhos relativos ao projeto (ex: `os.path.join(__file__, "..", "game", ...)`)
- Variaveis de ambiente (ex: `$GODOT`, `$HOME`)
- Instrucoes genericas na documentacao (ex: "configure o caminho do seu Godot")
