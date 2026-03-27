# Zion - Development Guide

## Project

Survivors roguelite 3D feito com Godot 4 (GDScript). Co-op online ate 4 jogadores.
12 personagens, 28 armas, 10 fases, 10 bosses, 12 evolucoes, 19 itens, 7 reliquias, 13 achievements.

## Quick Start

```bash
# Alias para o executavel do Godot (Windows, WinGet)
GODOT="/c/Users/shiga/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.1-stable_win64_console.exe"

# Rodar o jogo
"$GODOT" --path game --run

# Abrir no editor
"$GODOT" --editor --path game

# Verificar erros (headless)
"$GODOT" --headless --import game/project.godot

# Export para Windows (precisa preset configurado no editor)
"$GODOT" --headless --path game --export-release "Windows Desktop" ../build/zion.exe

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
│   ├── prd.md                   # Product Requirements (roadmap fases 0-6)
│   ├── spec.md                  # Especificacao tecnica
│   ├── fases.md                 # 10 fases detalhadas
│   ├── itens.md                 # Itens, evolucoes, reliquias
│   ├── mecanicas.md             # Mecanicas de gameplay
│   ├── personagens.md           # 12 personagens
│   ├── progressao.md            # Loja, cristais, meta-progressao
│   ├── prd_balancing.md         # PRD de balanceamento
│   ├── prd_missing_features.md  # Checklist de features faltantes
│   ├── prd_visual_polish.md     # PRD de polish visual
│   ├── prd_telemetry.md         # PRD do sistema de telemetria
│   ├── prd_3d_models.md         # PRD de modelos 3D
│   ├── prd_auto_tester.md       # PRD de testes automatizados
│   ├── prd_ui_ux_fixes.md       # PRD de correcoes UI/UX
│   └── prd_future.md            # Roadmap futuro
├── server/                      # Servidor de telemetria (Node.js)
│   ├── index.js                 # Express + SQLite (API REST + dashboard web)
│   ├── package.json             # Dependencias (express, better-sqlite3)
│   ├── .env.example             # PORT, API_KEY, DISCORD_WEBHOOK_URL
│   └── public/                  # Dashboard web estatico
└── game/                        # Projeto Godot 4
    ├── project.godot            # Config (autoloads, layers, display)
    ├── VERSION                  # Versao atual (sem "v")
    ├── scenes/ (82 .tscn)       # Cenas
    │   ├── enemies/             # 11 genericos + 10 bosses
    │   ├── stages/              # 10 stages com props procedurais
    │   ├── weapons/             # 28 armas
    │   ├── ui/                  # HUD, menus, shop, leaderboard, debug overlay
    │   └── player/              # Cena do jogador
    ├── scripts/ (120+ .gd)      # GDScript
    │   ├── autoload/            # 19 singletons (ver lista abaixo)
    │   ├── player/              # Player controller
    │   ├── enemies/             # Base + spawner + 10 bosses + especiais
    │   ├── weapons/             # 28 armas + projectiles + behaviors
    │   ├── ui/                  # 13 telas + debug overlay (F3/F4)
    │   ├── stages/              # 10 stages + 10 props + camera + events
    │   ├── effects/             # Particulas, shaders, procedural anims
    │   └── tests/               # Testes
    └── assets/                  # Materiais, shaders, audio
```

## Architecture

### Autoload Singletons (19 + 4 effects)
LogManager, GameManager, WeaponDB, ItemDB, SaveManager, ShopDB, CharacterDB, RelicDB, EvolutionDB, MultiplayerManager, SynergySystem, AudioManager, ObjectPool, AchievementManager, UITheme, KeybindingManager, LocaleManager, SteamManager, Telemetry

Adicionalmente registrados como autoload (mas ficam em scripts/effects/):
ScreenEffects, ParticleFactory, VisualSetup, ModelFactory

### Key Systems
- **Multiplayer**: Host-client via ENet (Steam Networking Sockets pronto via SteamManager stub)
- **Enemy spawning**: ObjectPool-backed, dificuldade escala com tempo, skins por stage
- **Weapons**: nivel 1-8, evolucao no 8 com item correspondente no 5
- **Procedural props**: cada stage gera ambiente (meshes, luzes, particulas)
- **Procedural anims**: idle bob, walk lean, hit squash-stretch, death tumble
- **Synergies**: 6 combinacoes elementais (Fogo, Gelo, Eletrico, Dark)
- **Logging**: LogManager (5 niveis, arquivo + console, crash reports JSON, rotacao)
- **Telemetria**: Telemetry client → servidor HTTP (runs, crashes, events, balance)
- **Debug overlay**: F3 (overlay tempo real), F4 (filtro de logs)

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

- **Characters**: 12 (ronin, soldado, mago, berserker, ninja, necro, pirata, engenheiro, vampiro, gladiador, chef, mystery)
- **Weapons**: 28 (10 melee, 10 ranged, 8 summon/special)
- **Stages**: 10 (cemetery, forest, farm, tokyo, volcano, ocean, arena, space, castle, candy)
- **Bosses**: 10 (one per stage, each with 3 phases)
- **Enemies**: 11 genericos + 4 especiais (skeleton_archer, mimic, bomber, swarm)
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

Fases 0-2 do PRD substancialmente implementadas. Fases 3-6 parcialmente (conteudo das 10 fases existe, multiplayer basico existe, mas falta polish).

Ver `docs/prd.md` para roadmap completo e `docs/prd_missing_features.md` para checklist detalhado.

## Remaining Work

- **Audio**: sistema (AudioManager) existe e carrega automaticamente, mas faltam arquivos .ogg/.wav em game/assets/audio/
- **Steam**: plugin GodotSteam necessario para multiplayer P2P
- **MultiMesh**: para renderizar hordas grandes com performance
- **Multiplayer HUD**: falta ping e setas direcionais dos aliados
