# PRD 42 — Pickups corrompidos, erro de classe e performance

**Status:** concluido
**Prioridade:** Alta
**Escopo:** `scripts/xp_gem.gd`, `scripts/crystal_pickup.gd`, `scripts/enemies/boss_generic.gd`, `docs/`

---

## 1. Contexto

Três problemas distintos foram reportados após sessões longas de jogo — todos com impacto direto na experiência do jogador e na estabilidade do projeto.

---

## 2. Problema A — Sprites de XP e moedas corrompem após acumulação

### Descrição

Quando o jogador deixa gemas de XP e cristais acumularem no chão por um tempo prolongado sem coletá-los, os sprites dos pickups começam a apresentar corrupção visual: imagem some, pisca ou fica em branco.

### Causa raiz

Em `xp_gem.gd` e `crystal_pickup.gd`, a textura do sprite é carregada via `load()` em `_ready()` para cada pickup instanciado:

```gdscript
sprite.texture = load(sprite_path)  # ← chamado 200× com pickups no chão
```

O Godot pode descarregar recursos que não possuem referência forte quando há pressão de memória. Como a textura é atribuída diretamente ao `Sprite3D.texture` sem ser retida em uma variável estática ou constante, ela pode ser liberada pelo GC após tempo prolongado — deixando o sprite sem textura.

Além disso, quando `_enforce_pickup_cap()` chama `_collect()` → `queue_free()` em pickups antigos, o nó aguarda um frame para ser destruído. Nesse intervalo, o `_physics_process` ainda roda sobre o sprite em estado de destruição iminente, podendo gerar artifacts visuais.

### Critérios de aceitação

- [ ] Textura carregada com `preload()` estático (compilada em tempo de exportação), sem risco de descarregamento
- [ ] Sprite não executa `_physics_process` após `_collect()` ser chamado
- [ ] Teste manual: acumular 100+ pickups por 3 minutos sem corrupção visual
- [ ] Sem regressão no comportamento de atração e coleta

### Implementação sugerida

```gdscript
# xp_gem.gd
const _XP_TEXTURE := preload("res://assets/sprites/pickups/xp_gem.png")

# Em _ready():
sprite.texture = _XP_TEXTURE
```

```gdscript
# Ao chamar _collect(), interromper physics imediatamente:
func _collect() -> void:
    if _collected or not is_inside_tree():
        return
    _collected = true
    set_physics_process(false)   # ← para animação/movement imediatamente
    # ... resto do código
```

---

## 3. Problema B — Parser Error: membro `target` duplicado em `EnemyBase3D`

### Descrição

Durante a execução, o Godot emite o erro:

```
Parser Error: The member "target" already exists in parent class EnemyBase3D.
```

### Causa raiz

`boss_generic.gd` herda de `enemy_base.gd` e redeclara a variável `target` que já existe na classe pai:

| Arquivo | Linha | Declaração |
|---|---|---|
| `scripts/enemies/enemy_base.gd` | 16 | `var target: Node3D = null` |
| `scripts/enemies/boss_generic.gd` | 12 | `var target: Node3D = null` ← **duplicata** |

### Critérios de aceitação

- [ ] Declaração duplicada removida de `boss_generic.gd`
- [ ] Jogo abre sem Parser Error no console
- [ ] Bosses continuam funcionando normalmente (targeting, fases, ataques AoE)
- [ ] Teste com pelo menos 2 bosses distintos confirmado sem regressão

### Implementação sugerida

```gdscript
# boss_generic.gd — remover a linha:
var target: Node3D = null  # ← DELETE — já existe em enemy_base.gd
```

---

## 4. Problema C — Melhorias de performance nos pickups

### Descrição

Com 200 pickups simultâneos permitidos, o sistema atual apresenta dois gargalos:

**Gargalo 1 — `_enforce_pickup_cap()` é O(n²)**

Chamado no `_ready()` de cada novo pickup, ele faz `get_nodes_in_group("pickups")` que percorre toda a cena. Quando 200 pickups existem e inimigos morrem em rajadas, esse método é chamado dezenas de vezes por segundo.

**Gargalo 2 — `_physics_process` em todos os pickups a cada frame**

200 pickups rodando bob animation + attraction check a cada frame de física (60/s) resulta em **12.000 chamadas por segundo** mesmo com o throttle de `_frame_counter % 5`.

### Critérios de aceitação

- [ ] `_enforce_pickup_cap()` usa contagem O(1) via variável global em vez de `get_nodes_in_group`
- [ ] Bob animation usa `_frame_counter` também (não precisa rodar a 60fps — 20fps é imperceptível)
- [ ] Pickup sem `being_attracted` que está longe do jogador pode reduzir frequência de check para a cada 10 frames
- [ ] Framerate estável em +200 pickups simultâneos (sem queda visível no PerfMonitor)

### Implementação sugerida

```gdscript
# GameManager ou GameConstants — contador global de pickups
static var active_pickup_count: int = 0

# xp_gem.gd / crystal_pickup.gd
func _ready() -> void:
    GameManager.active_pickup_count += 1
    if GameManager.active_pickup_count > MAX_PICKUPS:
        _collect()  # auto-coleta a si mesmo se acima do limite
        return

func _exit_tree() -> void:
    GameManager.active_pickup_count -= 1

# _physics_process — bob só a cada 3 frames, attraction check a cada 5 ou 10:
_frame_counter += 1
if _frame_counter % 3 == 0:
    _update_bob()
if not being_attracted and _frame_counter % 10 == 0:
    _check_attraction()
```

---

## 5. Problema D — Documentação desatualizada

### Descrição

Com 42 PRDs criados e diversas features implementadas desde a última revisão do `CLAUDE.md`, vários campos estão desatualizados.

### Campos a atualizar

| Documento | Campo desatualizado | Atualização necessária |
|---|---|---|
| `CLAUDE.md` | Lista de PRDs (apenas até PRD 32 na seção `docs/`) | Adicionar PRDs 33–42 com status correto |
| `CLAUDE.md` | `Current Phase` — cita PRD 28 como último de polish | Atualizar para refletir estado atual |
| `CLAUDE.md` | Contagem de scripts (231 .gd) | Revalidar contagem real |

### Critérios de aceitação

- [ ] `CLAUDE.md` lista todos os PRDs de 01 a 42 com status (`concluido` / `pendente`)
- [ ] Seção `Current Phase` reflete o estado real do projeto
- [ ] Nenhuma informação estruturalmente errada permanece

---

## 6. Arquivos afetados

```
game/scripts/xp_gem.gd                    # Bug A + Performance
game/scripts/crystal_pickup.gd             # Bug A + Performance
game/scripts/enemies/boss_generic.gd       # Bug B
docs/CLAUDE.md                             # Documentação
```

---

## 7. Ordem de execução recomendada

1. **Bug B primeiro** — erro de parser bloqueia o jogo de abrir em alguns contextos
2. **Bug A** — corrupção visual afeta diretamente a percepção de qualidade
3. **Performance** — otimização incremental, sem risco de regressão
4. **Documentação** — últimas 30 minutos da tarefa
