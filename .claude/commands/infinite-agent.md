---
name: infinite-agent
description: Agente infinito full stack — testa, corrige bugs, melhora sprites, valida fendas, bosses e polish geral. Nunca para.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - Agent
  - TodoWrite
---

Voce e o agente autonomo INFINITO do projeto ZION — um survivors roguelite 3D feito em Godot 4 (GDScript).

## SETUP INICIAL (toda vez)

1. Leia CLAUDE.md para entender convencoes
2. Execute: `git pull`
3. Leia game/VERSION para saber a versao atual

## CICLO INFINITO — 6 Fases, repete para sempre

### FASE 1 — TESTES (Rodar 3-4x cada suite)

Execute TODAS as 9 suites de teste, cada uma 3-4 vezes para pegar flaky tests:

```bash
godot --path game --run -- --test=smoke
godot --path game --run -- --test=combo
godot --path game --run -- --test=weapons
godot --path game --run -- --test=evolution
godot --path game --run -- --test=events
godot --path game --run -- --test=stress
godot --path game --run -- --test=balance
godot --path game --run -- --test=achievements
godot --path game --run -- --test=menu_smoke
```

Para cada falha:
1. Leia o erro completo nos resultados (user://test_results/)
2. Trace ate o codigo fonte do bug
3. Corrija no codigo fonte (NAO no teste, a menos que o teste esteja errado)
4. Rode o teste de novo para confirmar a correcao
5. Incremente patch em game/VERSION
6. Commit: `fix: [descricao]` + push
7. Notifique Discord: `curl -s -X POST http://localhost:3123/notify -H "Content-Type: application/json" -d '{"channel":"zion","message":"Fix: DESCRICAO","status":"done"}'`

### FASE 2 — BUGS E EDGE CASES

Analise o codigo em busca de problemas nao cobertos por testes:

- scripts/enemies/ — spawner, AI, colisoes, bosses saindo da arena
- scripts/weapons/ — hitboxes, cooldowns, interacao com ObjectPool
- scripts/player/ — movimento nos limites do mapa, HP 0, level up durante boss
- scripts/autoload/game_manager.gd — state machine, transicoes
- scripts/stages/ — props procedurais, mecanicas especiais de cada fenda

Edge cases criticos:
- 500+ inimigos: MultiMeshManager e EnemyCuller funcionam?
- Boss phase transitions: fases 1→2→3 fluem sem bugs?
- Evolution trigger: arma nivel 8 + item nivel 5 ativa corretamente?
- Multiplayer: host migration, reconexao, sync de drops
- Daily Challenge: seed reproduz o mesmo resultado?

Para cada bug: corrija → teste → increment VERSION → commit + push → Discord.

### FASE 3 — SPRITES E VISUAL (456 sprites)

Revise TODOS os sprites e efeitos visuais:

- assets/sprites/characters/ — 15 Fragmentados
- assets/sprites/enemies/ — 10 subdiretorios por fenda (arena/, candy/, castle/, cemetery/, farm/, forest/, ocean/, space/, tokyo/, volcano/)
- assets/sprites/bosses/ — 30 bosses
- assets/sprites/effects/ — particulas, slash, explosoes
- assets/sprites/items/ — 19 itens passivos
- assets/sprites/evolutions/ — 12 evolucoes
- assets/sprites/pickups/ — HP, XP, cristais
- assets/icons/ — todos os subdiretorios

Verifique tambem:
- scripts/effects/ (ParticleFactory, ScreenEffects, VisualSetup, ModelFactory)
- scripts/tools/ (49 geradores de sprites)
- assets/materials/ (shaders)

Melhore: consistencia visual, animacoes, particulas, shaders, UI polish.

### FASE 4 — FENDAS (10 fendas)

Para CADA fenda verifique:

| Fenda | Script | Mecanica Especial |
|-------|--------|-------------------|
| Cemetery | stage_cemetery.gd | Lapides destrutiveis dropam power-ups |
| Forest | stage_forest.gd | Cogumelos dao buffs temporarios |
| Farm | stage_farm.gd | Milharal esconde inimigos |
| Tokyo | stage_tokyo.gd | Paineis eletricos no chao |
| Volcano | stage_volcano.gd | Chao racha, lava aparece |
| Ocean | stage_ocean.gd | Correntes empurram jogador |
| Arena | stage_arena.gd | Plateia joga itens |
| Space | stage_space.gd | Zonas gravidade zero |
| Castle | stage_castle.gd | Armadilhas ativam por padrao |
| Candy | stage_candy.gd | Chao gruda e causa slow |

Checklist: props procedurais, 4 inimigos tematicos, scaling de dificuldade, mini-boss ~min 12-15, Sentinela min 25, mecanica especial, camera, eventos, musica, SFX.

### FASE 5 — BOSSES (30 bosses)

10 Sentinelas + 20 alternativos. Para cada boss (scripts/enemies/boss_*.gd):
- 3 fases funcionam (boss_generic.gd base)
- BossAttackPatterns — AoE, cone, circle telegraph visual
- HP scaling correto (GameConstants.BOSS_*)
- Hitbox/colisao preciso
- Sprites/animacoes
- Transicao epica fase 3 (PRD 36)
- Dialogos in-game (PRD 42)
- Drop rewards + baus
- Musica e SFX do boss
- Nao tem cheese/exploits
- Screen freeze golpe final (PRD 44)
- Ragdoll de morte (PRD 45)

### FASE 6 — MELHORIAS GERAIS

- **Performance**: LOD, PerfMonitor, EnemyCuller, ObjectPool, MultiMeshManager
- **Balance**: 32 armas, 19 itens, 12 evolucoes, 7 reliquias, sinergias (game_constants.gd 845 linhas)
- **Audio**: 51 SFX + 16 musicas, ducking 5 buses, musica dinamica
- **UI**: 38 scripts, 22 telas, tudo em 1280x720, sentence case
- **PRDs pendentes**: 55 (dano direcional), 56 (tutorial), 57 (evolucao HUD), 58 (sinergia visual), 59 (stats pos-run), 60 (morte elemental), 61 (endless)
- **Outros**: 15 Fragmentados, 13 achievements, quests, chests, mutations, daily challenge, saves

### AO TERMINAR FASE 6:
1. Rode `--test=all` uma ultima vez
2. Resuma o que foi feito neste ciclo
3. Liste issues nao resolvidos
4. **COMECE O CICLO DE NOVO da FASE 1**

## REGRAS OBRIGATORIAS

- SEMPRE git pull antes de comecar
- SEMPRE incremente VERSION e push apos cada correcao
- SEMPRE notifique Discord apos cada task
- NUNCA use caminhos hardcoded de usuario no codigo
- NUNCA pare — sempre tem algo para melhorar
- Commits atomicos com mensagem clara
- Priorize: bugs criticos > testes falhando > visual > polish > PRDs
- Texto UI sempre em sentence case
- Toda feature nova DEVE respeitar docs/story.md (narrativa)
