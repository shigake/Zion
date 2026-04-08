# PRD 43 — Crash ao spawnar baú: `!is_inside_tree()` em `chest_manager.gd`

**Status:** concluido  
**Prioridade:** Alta  
**Escopo:** `game/scripts/autoload/chest_manager.gd` (1 arquivo, ~5 linhas)  
**Tipo:** Bug — crash em runtime após ~2 minutos de jogo

---

## Descrição do Problema

Após alguns minutos de jogatina, o jogo lança o seguinte erro no log:

```
E 0:02:11:810   chest_manager.gd:37 @ _spawn_chest(): Condition "!is_inside_tree()" is true. Returning: Transform3D()
  <C++ Source>  scene/3d/node_3d.cpp:642 @ get_global_transform()
  <Stack Trace> chest_manager.gd:37 @ _spawn_chest()
                chest_manager.gd:92 @ _process()
```

O erro ocorre toda vez que o `ChestManager` tenta spawnar um baú de recompensa. A partir do momento em que o erro aparece, **nenhum baú novo é criado** — o sistema de recompensas para de funcionar completamente até o fim da run.

---

## Causa Raiz

### Bug primário — `global_position` antes do `add_child`

Em `_spawn_chest()`, a ordem das operações está errada:

```gdscript
# Ordem ATUAL (errada)
var chest = _create_chest_node()     # Nó criado, mas fora da árvore
chest.global_position = spawn_pos    # ← LINHA 37: CRASH aqui
get_tree().current_scene.add_child(chest)  # add_child só vem depois
```

`global_position` é uma propriedade que depende de `get_global_transform()`, que **exige que o nó esteja dentro da árvore de cena**. Como o chest acabou de ser criado com `Node3D.new()` e ainda não foi adicionado via `add_child`, o Godot lança a condição de erro e retorna `Transform3D()` vazio — o que faz o spawn falhar silenciosamente.

### Bug secundário — `get_tree().current_scene` sem guarda

Se uma transição de cena ocorrer exatamente no momento do spawn (ex: morte do jogador), `get_tree().current_scene` pode ser `null`, causando um segundo crash em cascata.

---

## Comportamento Esperado

- Baús de recompensa devem continuar spawnando a cada intervalo definido em `CHEST_SPAWN_INTERVAL`, sem erros
- O erro `!is_inside_tree()` não deve aparecer no log em nenhuma circunstância normal de jogatina
- Se a cena estiver em transição, o spawn deve ser ignorado silenciosamente (sem travar)

---

## Comportamento Atual

- Após ~2 minutos de jogo, o primeiro intervalo de spawn aciona o bug
- O erro é lançado continuamente a cada tentativa subsequente de spawn
- Nenhum baú aparece durante o restante da run
- O HUD mostra setas apontando para posições inválidas (baús que nunca foram adicionados à cena)

---

## Solução Proposta

### Fix primário — inverter a ordem de `add_child` e `global_position`

```gdscript
# Ordem CORRETA
var chest = _create_chest_node()
get_tree().current_scene.add_child(chest)  # Entra na árvore primeiro
chest.global_position = spawn_pos          # Só então seta a posição global
```

Essa inversão de duas linhas resolve o crash completamente. `global_position` só pode ser acessado depois que o nó pertence à árvore de cena.

### Fix secundário — guarda contra `current_scene` nulo

```gdscript
var scene = get_tree().current_scene
if not is_instance_valid(scene):
    return
scene.add_child(chest)
chest.global_position = spawn_pos
```

Isso previne o crash em cascata durante transições de fase ou tela de morte.

---

## Arquivos a Modificar

| Arquivo | Mudança |
|---|---|
| `game/scripts/autoload/chest_manager.gd` | Inverter `add_child` + `global_position`; adicionar guarda de `current_scene` |

---

## Critérios de Aceitação

- [ ] O erro `chest_manager.gd:37 @ _spawn_chest()` não aparece mais no log durante uma run completa
- [ ] Baús continuam spawnando corretamente após 2, 5 e 10 minutos de jogo
- [ ] Ao morrer ou trocar de fase durante o intervalo de spawn, nenhum crash secundário ocorre
- [ ] O comportamento de coleta, recompensa e HUD dos baús permanece idêntico ao atual

---

## Notas Técnicas

- O mesmo padrão de erro pode ocorrer em outros sistemas que criam nós dinamicamente (ex: drops, projéteis). Vale revisar `pickup_spawner.gd` e `projectile_base.gd` como verificação preventiva.
- O bug não afeta a build de release imediatamente (o Godot captura o erro e continua), mas **desativa todo o sistema de baús** — impacto direto na progressão de run e na economia de cristais.
