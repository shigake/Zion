## Status: ✅ CONCLUIDO

# PRD 01 — Quest trava no 29/30

## Problema
A quest "Eliminar 30 inimigos" trava visualmente no 29/30 e o jogador nao ve a conclusao. A recompensa provavelmente eh dada, mas o HUD nao atualiza para 30/30 antes de mostrar "Quest completa!".

## Causa raiz
Em `quest_manager.gd`, funcao `_on_enemy_killed()` (~linha 133-143): quando o 30o kill acontece, o codigo pula direto para `_complete_quest()` **sem emitir o sinal `quest_progress`** antes. O HUD fica preso mostrando 29/30 porque nunca recebe o update final.

```
Fluxo atual (bugado):
  kill 29 → quest_progress.emit(29, 30) → HUD mostra 29/30
  kill 30 → _quest_progress = 30 → _complete_quest() → quest_completed.emit()
           ↑ NUNCA emite quest_progress(30, 30) ↑
```

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `scripts/autoload/quest_manager.gd` | `_on_enemy_killed()` (~L133-143), `_complete_quest()` (~L108-131) |
| `scripts/ui/hud.gd` | `_on_quest_progress()` (~L779-784) |
| `scripts/enemies/enemy_base.gd` | `_die()` (~L782-784) — emite `enemy_killed` |
| `scripts/autoload/game_constants.gd` | `QUEST_REWARD_CRYSTALS = 10`, `QUEST_REWARD_XP = 30` |

## Plano de implementacao

### Passo 1 — Emitir progress antes do completion check
Em `quest_manager.gd`, funcao `_on_enemy_killed()`:

**Antes:**
```gdscript
"kill":
    _quest_progress = GameManager.total_kills - _kill_count_at_start
    if _quest_progress >= current_quest["target"]:
        _complete_quest()
    else:
        quest_progress.emit(current_quest, _quest_progress, current_quest["target"])
```

**Depois:**
```gdscript
"kill":
    _quest_progress = GameManager.total_kills - _kill_count_at_start
    quest_progress.emit(current_quest, _quest_progress, current_quest["target"])
    if _quest_progress >= current_quest["target"]:
        _complete_quest()
```

### Passo 2 — Adicionar delay visual antes de completar
Em `_complete_quest()`, adicionar um pequeno delay (0.3s) antes de emitir `quest_completed` para que o HUD tenha tempo de mostrar "30/30" antes de mudar para "Quest completa!".

### Passo 3 — Verificar outros tipos de quest
Checar se quests do tipo `"survive"`, `"find_chest"`, e `"reach_level"` tem o mesmo problema de nao emitir progress no ultimo tick.

## Validacao
- [ ] Iniciar quest de kill 30
- [ ] Matar 30 inimigos e verificar que HUD mostra 30/30 brevemente
- [ ] Verificar que recompensa (10 cristais + 30 XP) eh aplicada
- [ ] Verificar que quest sai do HUD apos completar
- [ ] Testar com quests de survive e find_chest tambem
