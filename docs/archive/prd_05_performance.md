## Status: CONCLUIDO

# PRD 05 — Performance cai drasticamente apos 2-3 minutos

## Problema
FPS cai muito apos 2-3 minutos de jogo. Problema critico e recorrente.

## Causas identificadas (por prioridade)

### 1. MultiMeshManager DESABILITADO
Em `multimesh_manager.gd`, o `_process()` retorna imediatamente:
```gdscript
func _process(delta: float) -> void:
    # MultiMesh disabled — sprites are lightweight enough without it.
    return
```
Com 100+ inimigos, sao 100+ draw calls individuais em vez de 1-2 com MultiMesh.

### 2. Enemy Culler nao agressivo o suficiente
Constantes atuais em `enemy_culler.gd`:
- `SLEEP_DIST_SQ = 2025.0` (45 unidades) — muito longe
- `DESPAWN_DIST_SQ = 4225.0` (65 unidades) — muito longe
- `BATCH_SIZE = 150` — processa 150 por frame a cada 0.4s

### 3. Spawn rate escala sem controle
Em `enemy_spawner.gd`, dificuldade escala linearmente:
- Minuto 2: multiplicador 1.7x
- Minuto 3: multiplicador 2.1x
- Minuto 5: multiplicador 2.75x

Caps existem mas sao altos demais:
- `MAX_ENEMIES = 500` — extremamente alto
- `ENEMIES_CAP_CRITICAL = 30` (so ativa com FPS < 20)
- `ENEMIES_CAP_LOW = 60` (so ativa com FPS < 30)

### 4. Elite auras (OmniLight3D) nao sao liberadas
Em `enemy_base.gd` linhas 393-398, elites recebem `OmniLight3D` que nunca eh explicitamente liberada. Cada luz eh cara para o renderer.

### 5. Damage numbers podem exceder o pool
Pool de 50, mas em cenarios de alto DPS com muitos inimigos, pode transbordar.

### 6. Inimigos mortos ficam no scene tree
`_die()` usa `queue_free()` com delay de 0.3-0.5s para animacao de morte. Com 10+ mortes/segundo, dezenas de corpos "mortos" ainda existem na scene tree.

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `scripts/autoload/multimesh_manager.gd` | DESABILITADO — precisa reativar |
| `scripts/enemies/enemy_culler.gd` | Distancias de sleep/despawn, batch size |
| `scripts/enemies/enemy_spawner.gd` | Spawn rate, caps de inimigos |
| `scripts/enemies/enemy_base.gd` | Elite auras (OmniLight3D), death delay |
| `scripts/effects/particle_factory.gd` | Pool de particulas e damage numbers |
| `scripts/autoload/game_constants.gd` | Todas as constantes de performance |
| `scripts/autoload/perf_monitor.gd` | Monitoramento reativo (nao preventivo) |
| `scripts/autoload/object_pool.gd` | Pool de objetos |

## Plano de implementacao

### Passo 1 — Reativar MultiMeshManager (IMPACTO ALTO)
Remover o `return` do `_process()` e implementar batching de sprites de inimigos. Com 200+ inimigos, reduz draw calls de 200+ para 1-2.

### Passo 2 — Tornar Enemy Culler mais agressivo (IMPACTO ALTO)
```gdscript
# Antes:
const SLEEP_DIST_SQ := 2025.0   # 45 unidades
const DESPAWN_DIST_SQ := 4225.0  # 65 unidades
const BATCH_SIZE := 150

# Depois:
const SLEEP_DIST_SQ := 1024.0    # 32 unidades
const DESPAWN_DIST_SQ := 2025.0   # 45 unidades
const BATCH_SIZE := 200
const CHECK_INTERVAL := 0.25      # era 0.4s
```

### Passo 3 — Reduzir cap maximo de inimigos (IMPACTO ALTO)
```gdscript
# Antes:
const MAX_ENEMIES := 500

# Depois:
const MAX_ENEMIES := 150  # Hard cap absoluto

# Adicionar cap dinamico baseado em FPS:
var dynamic_cap = 150
if fps < 45: dynamic_cap = 100
if fps < 35: dynamic_cap = 70
if fps < 25: dynamic_cap = 40
```

### Passo 4 — Substituir OmniLight3D de elites por sprite glow (IMPACTO MEDIO)
```gdscript
# Antes: OmniLight3D (caro — calcula iluminacao)
var aura = OmniLight3D.new()

# Depois: Sprite3D com emissao (barato — apenas textura)
var aura = Sprite3D.new()
aura.texture = preload("res://assets/sprites/effects/glow_circle.png")
aura.billboard = BaseMaterial3D.BILLBOARD_ENABLED
aura.modulate = Color(1.0, 0.85, 0.2, 0.4)
```

### Passo 5 — Reduzir delay de morte (IMPACTO MEDIO)
```gdscript
# Antes: 0.3-0.5s de animacao antes de queue_free
death_tween.chain().tween_callback(queue_free)

# Depois: Esconder imediatamente, queue_free mais rapido
visible = false
set_physics_process(false)
set_process(false)
death_tween.tween_callback(queue_free)
```

### Passo 6 — Cap em damage numbers (IMPACTO BAIXO)
Adicionar check em `ParticleFactory` para nao exceder pool quando FPS esta baixo:
```gdscript
if Engine.get_frames_per_second() < 35:
    # Skip damage numbers a cada 2 hits
    if _dmg_skip_counter % 2 != 0:
        return
```

### Passo 7 — Spawn-on-death enemies devem usar pool (IMPACTO BAIXO)
Crows (Scarecrow death) e slime splits (Gummy death) usam `add_child()` sem pool. Migrar para `ObjectPool`.

## Metricas alvo
- FPS > 50 ate minuto 5
- FPS > 40 ate minuto 10
- Maximo de 150 inimigos simultaneos
- Draw calls < 50 com MultiMesh ativo

## Validacao
- [ ] Jogar 5 minutos sem queda de FPS abaixo de 40
- [ ] Jogar 10 minutos sem queda abaixo de 30
- [ ] Verificar draw calls no debugger do Godot
- [ ] Testar em hardware low-end
- [ ] Verificar que gameplay nao fica vazio demais com caps menores
