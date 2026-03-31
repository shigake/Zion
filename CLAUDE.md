# Zion - Development Guide

## Project

Survivors roguelite 3D feito com Godot 4 (GDScript). Co-op online ate 4 jogadores.
15 Fragmentados, 32 armas, 7 fendas + 3 anomalias, 10 Sentinelas, 12 evolucoes, 19 itens, 7 reliquias, 13 achievements. 428+ sprites, 51 SFX, 16 musicas.

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
├── docs/ (12 arquivos)          # Game design documents
│   ├── gdd.md                   # Game Design Document
│   ├── prd.md                   # Product Requirements (roadmap, status real)
│   ├── story.md                 # Historia, lore, narrativa completa
│   ├── fases.md                 # 7 fendas campanha + 3 anomalias
│   ├── itens.md                 # Itens, evolucoes, reliquias
│   ├── mecanicas.md             # Mecanicas de gameplay
│   ├── personagens.md           # 15 Fragmentados + backstories
│   ├── progressao.md            # Loja, cristais, meta-progressao
│   ├── balance_analysis.md      # Analise de balanceamento verificada
│   ├── prd_qa_stress_test.md    # PRD de QA e stress test (~80% automatizado)
│   ├── prd_build_distribution.md # PRD de build e distribuicao (~60% pronto)
│   └── prd_steam_integration.md # PRD de integracao Steam (codigo pronto, falta plugin)
├── server/                      # Servidor de telemetria (Node.js)
│   ├── index.js                 # Express + SQLite (API REST + dashboard web)
│   ├── package.json             # Dependencias (express, better-sqlite3)
│   ├── .env.example             # PORT, API_KEY, DISCORD_WEBHOOK_URL
│   └── public/                  # Dashboard web estatico
├── .github/workflows/           # CI/CD
│   ├── ci.yml                   # CI: validacao, estrutura, testes de balance
│   └── build.yml                # Build: export .exe + GitHub Release (em tags)
└── game/                        # Projeto Godot 4
    ├── project.godot            # Config (autoloads, layers, display)
    ├── VERSION                  # Versao atual (sem "v")
    ├── scenes/ (103 .tscn)       # Cenas
    │   ├── enemies/             # 16 genericos + 10 bosses (26 total)
    │   ├── stages/              # 10 fendas com props procedurais
    │   ├── weapons/             # 40 cenas (32 armas + projeteis)
    │   ├── ui/                  # 20 telas (HUD, menus, shop, leaderboard, etc)
    │   └── player/              # Cena do jogador
    ├── scripts/ (216 .gd)       # GDScript
    │   ├── autoload/            # Singletons (ver lista abaixo)
    │   ├── player/              # Player controller
    │   ├── enemies/             # Base + spawner + 10 bosses + especiais
    │   ├── weapons/             # 43 scripts (32 armas + projectiles + behaviors)
    │   ├── ui/                  # 24+ telas + debug overlay (F3/F4)
    │   ├── stages/              # 10 fendas + 10 props + camera + events
    │   ├── effects/             # Particulas, shaders, procedural anims
    │   ├── tools/               # 20+ geradores de sprites e assets
    │   └── tests/               # 5 testes (balance, smoke, auto_player, runner, report)
    └── assets/                  # Materiais, shaders, audio
```

## Architecture

### Autoload Singletons (34 registrados no project.godot)
LogManager, PlatformHelper, GameManager, WeaponDB, ItemDB, SaveManager, ShopDB, CharacterDB, RelicDB, EvolutionDB, MultiplayerManager, SynergySystem, AudioManager, ObjectPool, AchievementManager, UITheme, KeybindingManager, LocaleManager, SteamManager, Telemetry, MultiMeshManager, AutoTester, GamepadUI, MutationManager, DailyChallenge, LoadingScreen, AchievementPopup, BossDialogue, InventoryOverlay, ChestManager, QuestManager

Registrados como autoload (mas ficam em scripts/effects/):
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
- **Reward Chests**: ChestManager — baus de recompensa a cada 45s com setas no HUD
- **Quest System**: QuestManager — mini-objetivos durante a run (kill, survive, find chest, reach level)
- **Boss AoE**: BossAttackPatterns — ataques de area (circulo, cone) com telegraph visual em todos 10 bosses
- **GameConstants**: 561 linhas de constantes centralizadas (29 categorias: balance, spawner, boss, drops, visual, camera, events, etc.)
- **Performance**: LOD system, PerfMonitor, EnemyCuller, pickup cap (200), sprite cache, O(1) weapon lookups, slash trail pool
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

Core game completo com camada narrativa implementada. 15 Fragmentados, 32 armas, 428+ sprites, 51 SFX, 16 musicas. FASE A (visual) ~95%. FASE B (gameplay) ~95%. FASE C (polish) ~98%. FASE D (audio) ~95% — 51 SFX, 16 musicas chiptune, musica dinamica por fenda + boss + intensificacao temporal. FASE E (infra) ~80% — CI/CD dual-platform (Windows+Linux), Steam integration (codigo pronto, falta plugin), refatoracao concluida (GameConstants 561 linhas), 9 suites de testes automatizados (150 combos, stress, evolution, events, etc.), 7 PRDs concluidos e arquivados, 3 PRDs ativos (QA, build, Steam).

Ver `docs/prd.md` para roadmap e `docs/story.md` para narrativa.

## Automated Testing

9 suites de teste via CLI:

```bash
godot --path game --run -- --test=smoke          # 26 testes rapidos
godot --path game --run -- --test=combo           # 150 combos (15 chars × 10 stages)
godot --path game --run -- --test=weapons         # Todas as armas
godot --path game --run -- --test=evolution        # 12 evolucoes
godot --path game --run -- --test=events           # Timeline completa de eventos
godot --path game --run -- --test=stress           # Hyper, max enemies, endless
godot --path game --run -- --test=achievements     # 7 cenarios
godot --path game --run -- --test=balance          # XP, DPS, economia
godot --path game --run -- --test=menu_smoke       # Navegacao de menus
godot --path game --run -- --test=all              # Todos os acima
```

Resultados salvos em `user://test_results/`. Notificacao automatica no Discord.

## Remaining Work

- **QA**: rodar suite `combo` (150 combos, ~2.5h), teste multiplayer LAN manual
- **Steam**: instalar plugin GodotSteam GDExtension (codigo 100% pronto)
- **Distribuicao**: testar .exe em maquina limpa, pagina Itch.io, trailer 30s, GitHub Release
- **Narrativa**: cutscene do ??? (Zion despertando), cinematica de intro
- **Pos-lancamento**: matchmaking online, workshop de mods, localizacao EN/ES/JP, replays

## Regras Importantes

### Proibido caminhos hardcoded
**NUNCA** use caminhos absolutos de usuario no codigo ou na documentacao (ex: `/c/Users/shiga/...`, `C:\Users\fulano\...`).
Mais de uma pessoa trabalha neste projeto — caminhos hardcoded quebram na maquina dos outros.

Use sempre:
- Caminhos relativos ao projeto (ex: `os.path.join(__file__, "..", "game", ...)`)
- Variaveis de ambiente (ex: `$GODOT`, `$HOME`)
- Instrucoes genericas na documentacao (ex: "configure o caminho do seu Godot")
