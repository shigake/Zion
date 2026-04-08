# PRD 39 — Progresso de achievements visivel no HUD

**Status**: concluido
**Tipo**: UX
**Prioridade**: alta
**Versao alvo**: 3.53.0

---

## Problema

O jogo tem 17 achievements, mas o jogador so descobre que desbloqueou um quando o popup aparece. Nao ha como:

1. Ver progresso parcial ("8.432/10.000 kills" para "genocide")
2. Saber quais achievements estao proximos de completar
3. Ter motivacao incremental durante a run
4. Acompanhar achievements que dependem de condicoes especificas da run atual

Jogos como Vampire Survivors mostram progresso de achievements porque isso gera o loop "so mais um pouquinho" que e essencial em roguelites.

## Objetivo

Criar um mini-tracker de achievements no HUD que mostra os 1-3 achievements mais proximos de serem completados, com barra de progresso em tempo real, e que se expande para uma lista completa ao pressionar um botao.

## Escopo

### Incluso
- Mini-tracker no HUD (1-3 achievements mais proximos)
- Barra de progresso em tempo real por achievement
- Expansao para lista completa (toggle com tecla/botao)
- Notificacao "quase la!" quando >= 90% do objetivo
- Celebracao visual ao completar (alem do popup existente)
- Persistencia: tracking salvo entre sessoes (SaveManager)

### Fora de escopo
- Novos achievements
- Recompensas por achievement (apenas tracking visual)
- Leaderboard de achievements

## Especificacao tecnica

### 1. Sistema de progresso

Adicionar ao `AchievementManager`:

```gdscript
func get_progress(id: String) -> Dictionary:
    # Retorna {current: int, target: int, percent: float, label: String}
    match id:
        "genocide":
            return {current: SaveManager.get_total_kills(), target: 10000, 
                    percent: min(1.0, kills / 10000.0), label: "kills"}
        "collector":
            var unlocked = CharacterDB.get_unlocked_count()
            return {current: unlocked, target: 15, 
                    percent: min(1.0, unlocked / 15.0), label: "personagens"}
        "completionist":
            var stages = SaveManager.get_completed_stages_count()
            return {current: stages, target: 10, 
                    percent: min(1.0, stages / 10.0), label: "fendas"}
        # ... para cada achievement com progresso rastreavel

func get_nearest_achievements(count: int = 3) -> Array[Dictionary]:
    # Retorna os N achievements nao-completados com maior % de progresso
    var incomplete = []
    for id in ACHIEVEMENTS:
        if is_unlocked(id):
            continue
        var progress = get_progress(id)
        if progress.percent > 0.0:  # Ignorar os com 0%
            incomplete.append({id: id, progress: progress, data: ACHIEVEMENTS[id]})
    incomplete.sort_custom(func(a, b): return a.progress.percent > b.progress.percent)
    return incomplete.slice(0, count)
```

### 2. Progresso por achievement

| Achievement | Metrica | Como rastrear |
|-------------|---------|---------------|
| genocide | kills totais | `SaveManager.get_total_kills()` |
| collector | personagens desbloqueados | `CharacterDB.get_unlocked_count()` |
| completionist | fendas completadas | `SaveManager.get_completed_stages_count()` |
| treasure_hunter | baus coletados (run) | `_run_chests_collected` |
| quest_master | quests completadas (run) | `_run_quests_completed` |
| boss_slayer | bosses derrotados (run) | `_run_bosses_killed` |
| matrix | esquivas (run) | `_run_dodges` |
| evolved_6 | armas evoluidas (run) | `EvolutionDB.evolved_weapons.size()` |
| storm | armas eletricas evoluidas (run) | filtrar evolved por electric |
| lucky_day | itens lendarios (run) | `_run_legendary_items` |
| first_walk | tempo sobrevivido (run) | `GameManager.elapsed_time >= 300` |
| speedrunner | derrotar boss < 15min | `GameManager.elapsed_time` ao matar boss |
| pacifist | 3min sem atacar | `GameManager.elapsed_time - _last_attack_time` |
| nobody_deserves | morrer < 10s | `GameManager.elapsed_time` ao morrer |
| cow_brejo | Farm sem dano de vaca | `_run_no_cow_damage` (bool) |
| sweet_revenge | completar Candy | progresso da fenda |
| one_punch | matar boss com 1 hit | condicional (nao rastreavel %) |

### 3. Mini-tracker no HUD

**Posicao:** Canto superior-esquerdo, abaixo do quest tracker (se houver)

**Layout compacto (1-3 items):**
```
┌───────────────────────────┐
│ 🏆 Genocida    8.4K/10K  │ ████████░░ 84%
│ 🏆 Coletor     12/15     │ ████████░░ 80%
│ 🏆 Caçador     7/10      │ ███████░░░ 70%
└───────────────────────────┘
```

**Especificacoes visuais:**
- Background: preto 60% alpha, rounded 6px
- Largura: 260px
- Cada item: 24px de altura
- Icone: 16x16 trofeu dourado
- Nome: branco 11px, truncado se necessario
- Progresso: cinza 10px ("8.4K/10K")
- Barra: 80x6px, fundo cinza escuro, preenchimento dourado
- Porcentagem: 10px dourada, alinhada a direita

**Animacoes:**
- Barra de progresso: lerp suave quando valor muda (4x/s)
- Novo achievement entra: slide-down + fade-in (0.2s)
- Achievement completado: flash dourado + slide-up e sai (0.5s)

### 4. Notificacao "Quase la!"

Quando um achievement atinge >= 90%:

```
┌─────────────────────────────────┐
│ ⭐ QUASE LA!                    │
│ Genocida — 9.200/10.000 kills   │
│ ████████████████████░ 92%       │
└─────────────────────────────────┘
```

- Aparece no centro da tela por 2s
- Borda dourada pulsante
- SFX: tom suave de "quase" (reusar "quest_progress" com pitch +0.3)
- So dispara uma vez por achievement por sessao

### 5. Tela expandida (toggle)

**Trigger:** Tecla `Tab` ou botao `Select/Back` no gamepad

**Layout expandido:**
```
┌──────────────────────────────────────────┐
│              CONQUISTAS (12/17)           │
│──────────────────────────────────────────│
│ ✅ Primeiro passo     Sobreviva 5 min    │
│ ✅ Evolucao x6        6 armas evoluidas  │
│ ✅ Speedrunner        Boss < 15min       │
│                                          │
│ 🔒 Genocida           8.4K/10K kills     │
│    ████████████████░░░░ 84%              │
│ 🔒 Coletor            12/15 personagens  │
│    ████████████████░░░░ 80%              │
│ 🔒 Caçador de tesouros 7/10 baus         │
│    ██████████████░░░░░░ 70%              │
│ 🔒 Mestre de quests    3/5 quests        │
│    ████████████░░░░░░░░ 60%              │
│ 🔒 Matrix              45/100 esquivas   │
│    █████████░░░░░░░░░░░ 45%              │
│                                          │
│ 🔒 One Punch           ???               │
│ 🔒 Ninguem merece      ???               │
└──────────────────────────────────────────┘
```

- Desbloqueados no topo com checkmark verde
- Em progresso no meio com barra
- Secretos/sem progresso embaixo com "???"
- Overlay semi-transparente (preto 70%)
- Gameplay continua por baixo (nao pausa)
- ScrollContainer se necessario

### 6. Integracao com sistema existente

**Signals a escutar:**
- `AchievementManager.achievement_unlocked` → atualizar tracker, remover do mini-HUD
- `GameManager.enemy_killed` → atualizar kills
- `GameManager.chest_collected` → atualizar baus
- `QuestManager.quest_completed` → atualizar quests

**Update frequency:**
- Mini-tracker: a cada 1.0s (nao precisa ser frame-perfect)
- Tela expandida: ao abrir
- Barras: lerp visual a cada frame quando visivel

### 7. Constantes em `game_constants.gd`

```gdscript
# Achievement Tracker HUD
const ACH_TRACKER_MAX_VISIBLE = 3
const ACH_TRACKER_WIDTH = 260
const ACH_TRACKER_ITEM_HEIGHT = 24
const ACH_TRACKER_BAR_WIDTH = 80
const ACH_TRACKER_BAR_HEIGHT = 6
const ACH_TRACKER_UPDATE_INTERVAL = 1.0
const ACH_TRACKER_LERP_SPEED = 4.0
const ACH_ALMOST_THRESHOLD = 0.90
const ACH_ALMOST_NOTIFICATION_DURATION = 2.0
const ACH_TRACKER_BG_ALPHA = 0.6
const ACH_TRACKER_FONT_SIZE_NAME = 11
const ACH_TRACKER_FONT_SIZE_PROGRESS = 10
const ACH_EXPANDED_BG_ALPHA = 0.7
```

## Criterios de aceite

1. [ ] Mini-tracker mostra 1-3 achievements mais proximos no HUD
2. [ ] Barra de progresso atualiza em tempo real durante gameplay
3. [ ] Notificacao "Quase la!" ao atingir 90%
4. [ ] Tab/Select abre lista expandida com todos os achievements
5. [ ] Achievements completados saem do tracker com animacao
6. [ ] Achievements secretos mostram "???" ate serem completados
7. [ ] Tracker nao aparece se todos estao completos
8. [ ] Funciona com gamepad (navegacao na tela expandida)
9. [ ] Nao impacta performance (update a cada 1s)
10. [ ] Progresso persiste entre sessoes via SaveManager

## Arquivos afetados

- `game/scripts/autoload/achievement_manager.gd` — funcoes get_progress(), get_nearest()
- `game/scripts/ui/hud.gd` — mini-tracker widget
- `game/scripts/ui/achievement_tracker.gd` — novo script para tela expandida
- `game/scripts/autoload/game_constants.gd` — constantes ACH_*
- `game/assets/translations/*.csv` — textos "QUASE LA" / "ALMOST THERE"

## Estimativa

Complexidade: media
Tempo estimado: 3-4 horas
Impacto: alto (motivacao incremental, loop de "so mais um pouco")
