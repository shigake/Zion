## Status: CONCLUIDO

# PRD 02 — Bau nao desaparece e nao da feedback

## Problema
Ao pegar um bau de recompensa, ele nao desaparece do mapa e o jogador nao sabe se ganhou algo ou o que ganhou.

## Causa raiz
Duas causas identificadas:

### 1. Metodo `spawn_damage_number()` nao existe
Em `chest_manager.gd` linha 168, apos dar a recompensa, o codigo chama `ParticleFactory.spawn_damage_number()` para mostrar o texto do que foi ganho ("+10 cristais", "+20 XP", etc). Esse metodo **nao existe** no `ParticleFactory`. Isso causa um erro silencioso que pode interromper o resto da funcao `_collect_chest()`, incluindo o `queue_free()` do bau.

O mesmo metodo faltante eh chamado em `quest_manager.gd` linhas 123-127 para mostrar recompensas de quest.

### 2. Bau pode nao ser removido visualmente
O `queue_free()` do Godot eh deferred — o node so eh removido no fim do frame. Sem `chest.visible = false` imediato, o bau permanece visivel por 1+ frames.

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `scripts/autoload/chest_manager.gd` | `_collect_chest()` (~L129-172) — coleta + recompensa + queue_free |
| `scripts/effects/particle_factory.gd` | Falta `spawn_damage_number()`. Ja tem pool: `_dmg_pool`, `get_damage_number()`, `return_damage_number()` |
| `scripts/effects/damage_number.gd` | Script do Label3D poolavel — existe e funciona |
| `scripts/autoload/quest_manager.gd` | `_complete_quest()` (~L123-127) — tambem chama o metodo faltante |
| `scripts/autoload/game_constants.gd` | `CHEST_SPAWN_INTERVAL = 45.0`, `CHEST_DESPAWN_TIME = 20.0`, `CHEST_REWARD_*` |

## Plano de implementacao

### Passo 1 — Implementar `spawn_damage_number()` no ParticleFactory
Criar o metodo usando a infraestrutura de pool que ja existe:

```gdscript
func spawn_damage_number(text: String, pos: Vector3, color: Color = Color.WHITE) -> void:
    var label = get_damage_number()
    if not label:
        return
    label.text = text
    label.modulate = color
    label.global_position = pos + Vector3(0, 1.5, 0)
    label.visible = true
    if not label.is_inside_tree():
        get_tree().current_scene.add_child(label)
    # Anima subindo e fade out
    var tw = create_tween()
    tw.tween_property(label, "position:y", label.position.y + 1.0, 0.8)
    tw.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
    tw.tween_callback(func(): return_damage_number(label))
```

### Passo 2 — Esconder bau imediatamente ao coletar
Em `_collect_chest()`, antes do `queue_free()`:

```gdscript
chest.visible = false  # Feedback visual imediato
_active_chests.erase(chest)
chest.queue_free()
```

### Passo 3 — Cores por tipo de recompensa
Definir cores para cada tipo de recompensa no texto flutuante:
- Cristais: dourado `Color(1.0, 0.85, 0.2)`
- XP: azul claro `Color(0.4, 0.8, 1.0)`
- HP: verde `Color(0.3, 1.0, 0.4)`
- Reroll: roxo `Color(0.8, 0.5, 1.0)`

### Passo 4 — Testar quest_manager tambem
Verificar que `quest_manager.gd` linhas 123-127 agora funcionam com o novo `spawn_damage_number()`.

## Validacao
- [ ] Pegar um bau e verificar que desaparece imediatamente
- [ ] Ver texto flutuante com o que foi ganho ("+10 cristais", "+20 XP", etc)
- [ ] Verificar que cristais/XP/HP/reroll sao de fato aplicados
- [ ] Completar uma quest e verificar que texto de recompensa aparece
- [ ] Verificar que nao ha erros no console
