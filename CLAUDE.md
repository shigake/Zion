# Zion - Development Guide

## Project

Survivors roguelite 3D feito com Godot 4 (GDScript). Co-op online ate 4 jogadores.
15 Fragmentados, 32 armas, 7 fendas + 3 anomalias, 30 Bosses (10 Sentinelas + 20 alternativos), 30 Mini-bosses, 12 evolucoes, 19 itens, 7 reliquias, 17 achievements. 453+ sprites, 51 SFX, 16 musicas. Baus de recompensa, sistema de quests, boss AoE attacks.

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
├── docs/ (22 arquivos + adr/)      # Game design documents
│   ├── gdd.md                   # Game Design Document
│   ├── story.md                 # Historia, lore, narrativa completa
│   ├── fases.md                 # 7 fendas campanha + 3 anomalias
│   ├── itens.md                 # Itens, evolucoes, reliquias
│   ├── mecanicas.md             # Mecanicas de gameplay
│   ├── personagens.md           # 15 Fragmentados + backstories
│   ├── progressao.md            # Loja, cristais, meta-progressao
│   ├── prd_01_quest_stuck.md    # PRD 01: quest travada — concluido
│   ├── prd_02_chest_broken.md   # PRD 02: bau quebrado — concluido
│   ├── prd_03_hp_bar.md         # PRD 03: HP bar world-space — concluido
│   ├── prd_04_hp_drop_rate.md   # PRD 04: taxa de drop de HP — concluido
│   ├── prd_05_performance.md    # PRD 05: performance MultiMesh — concluido
│   ├── prd_06_merchant.md       # PRD 06: mercante inventario — concluido
│   ├── prd_07_melee_sprites.md  # PRD 07: sprites melee — concluido
│   ├── prd_08_death_screen.md   # PRD 08: tela de morte — concluido
│   ├── prd_09_damage_bar.md     # PRD 09: barra de dano — concluido
│   ├── prd_10_shop_fixes.md     # PRD 10: fixes da loja — concluido
│   ├── prd_11_ui_fit_screen.md  # PRD 11: UI cabe em 1280x720 — concluido
│   ├── prd_12_options_save.md   # PRD 12: salvar opcoes — concluido
│   ├── prd_13_translation.md    # PRD 13: traducao/localizacao — concluido
│   ├── prd_14_cutscene_mystery.md # PRD 14: cutscene ??? — concluido
│   ├── prd_15_intro_cinematic.md  # PRD 15: cinematica intro — concluido
│   ├── prd_16_solo_balance.md     # PRD 16: balance solo — concluido
│   ├── prd_17_credits_quotes.md  # PRD 17: creditos falas bilíngues + balao posicional — pendente
│   └── adr/                     # 12 Architecture Decision Records (ADR-001 a ADR-012)
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
    ├── scenes/ (124 .tscn)       # Cenas
    │   ├── enemies/             # 46 (16 genericos + 10 bosses + 20 alt bosses)
    │   ├── stages/              # 10 fendas com props procedurais
    │   ├── weapons/             # 40 cenas (32 armas + projeteis)
    │   ├── ui/                  # 20 telas (HUD, menus, shop, leaderboard, etc)
    │   └── player/              # Cena do jogador
    ├── scripts/ (225 .gd)       # GDScript
    │   ├── autoload/            # 33 singletons (ver lista abaixo)
    │   ├── player/              # 2 player controller
    │   ├── enemies/             # 22 (base + spawner + 10 bosses + especiais)
    │   ├── weapons/             # 45 scripts (32 armas + projectiles + behaviors)
    │   ├── ui/                  # 32 telas + debug overlay (F3/F4)
    │   ├── stages/              # 23 (10 fendas + props + camera + events)
    │   ├── effects/             # 9 (particulas, shaders, procedural anims)
    │   ├── tools/               # 43 geradores de sprites e assets
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
- **GameConstants**: 712 linhas de constantes centralizadas (29 categorias: balance, spawner, boss, drops, visual, camera, events, etc.)
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

**Regra obrigatoria — ANTES de comecar QUALQUER tarefa:**
1. Executar `git pull` para garantir que o código está atualizado

**Regra obrigatoria — ao terminar QUALQUER tarefa:**
1. Incrementar a **patch** version em `game/VERSION` (ex: 1.1.0 → 1.1.1)
2. Fazer `git add` + `git commit` + `git push` automaticamente
3. Notificar o Discord

Se a tarefa for grande (feature nova), incrementar a **minor** (ex: 1.1.0 → 1.2.0).
Se for fix/ajuste pequeno, incrementar o **patch** (ex: 1.1.0 → 1.1.1).

## Text Style

All UI text uses sentence case (primeira letra maiuscula, resto minusculo). Proper nouns keep their capitalization.

## UI Layout Rule

**Regra de UI**: Toda tela deve caber em 1280x720 sem scroll. Se o conteudo nao cabe, simplificar ou usar tabs/paginas. ScrollContainer so eh aceito dentro de tabs individuais (ex: opcoes).

## Current Phase

Core game completo com camada narrativa implementada. 15 Fragmentados, 32 armas, 453+ sprites, 51 SFX, 16 musicas. FASE A (visual) ~95%. FASE B (gameplay) ~96%. FASE C (polish) ~99%. FASE D (audio) ~95% — 51 SFX, 16 musicas chiptune, musica dinamica por fenda + boss + intensificacao temporal. FASE E (infra) ~85% — CI/CD dual-platform (Windows+Linux), Steam integration (codigo pronto, falta plugin), refatoracao concluida (GameConstants 712 linhas), 9 suites de testes automatizados (150 combos, stress, evolution, events, etc.), 16 PRDs todos concluidos, 12 ADRs documentados. Credits: carrossel de herois com baloes de fala.

Ver `docs/story.md` para narrativa e `docs/adr/` para decisoes arquiteturais.

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
- **Pos-lancamento**: matchmaking online, workshop de mods, localizacao EN/ES/JP, replays

## Regras Importantes

### Proibido caminhos hardcoded
**NUNCA** use caminhos absolutos de usuario no codigo ou na documentacao (ex: `/c/Users/shiga/...`, `C:\Users\fulano\...`).
Mais de uma pessoa trabalha neste projeto — caminhos hardcoded quebram na maquina dos outros.

Use sempre:
- Caminhos relativos ao projeto (ex: `os.path.join(__file__, "..", "game", ...)`)
- Variaveis de ambiente (ex: `$GODOT`, `$HOME`)
- Instrucoes genericas na documentacao (ex: "configure o caminho do seu Godot")
