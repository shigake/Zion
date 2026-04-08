# PRD 27 — Teste de Tamanho: Mundo Doce com Mapa pela Metade

**Status:** Implementado  
**Prioridade:** Teste / Experimental  
**Escopo:** Apenas a fenda Mundo Doce (candy)

---

## Objetivo

Reduzir o mapa do Mundo Doce pela metade para testar sensorialmente o tamanho do mapa durante o gameplay. O objetivo é comparar a sensação de 80×80 versus 40×40 unidades de chão e decidir qual tamanho é mais adequado para o ritmo do jogo.

---

## Contexto técnico

O mapa é definido por **duas variáveis independentes** que precisam ser ajustadas juntas:

| Variável | Onde | Padrão | Pós-teste |
|---|---|---|---|
| `area_size` | `candy_props.gd` | `80.0` | `40.0` |
| `GameManager.map_half_size` | `game_manager.gd` (global) | `95.0` | `47.5` (só no candy) |

### Por que dois valores?

- `area_size` controla o **chão visual** (PlaneMesh = `area_size × 2`) e o espalhamento dos props
- `map_half_size` é o **limite de movimento do jogador** + posição das barreiras invisíveis (shaders)
- Se só um for alterado, o chão encolhe mas o jogador sai do mapa (ou vice-versa)

### Ordem de execução no Godot (por que funciona)

```
Frame 0:  player._ready() registra callback → aguarda 2 frames
          stage_candy._ready() → super._ready() → GameManager.reset() → define map_half_size = 47.5
Frame 1:  (aguarda)
Frame 2:  (aguarda)
Frame 3:  _create_barrier_walls() lê map_half_size = 47.5 → barreiras no lugar certo ✓
```

`GameManager.reset()` não reseta `map_half_size`, então o valor definido em `stage_candy._ready()` persiste.

---

## Mudanças implementadas

### 1. `candy_props.gd` — área visual

```gdscript
# ANTES
@export var area_size: float = 80.0

# DEPOIS
@export var area_size: float = 40.0
```

Efeito cascata automático:
- Chão: `160×160` → `80×80`
- Props espalhados em `area_size * 0.8` → raio 32 (era 64)
- Zonas de caramelo em `area_size * 0.6` → raio 24 (era 48)

### 2. `stage_candy.gd` — limite de movimento e barreiras

```gdscript
func _ready() -> void:
    music_track = "candy"
    super._ready()
    # Teste PRD-27: mapa pela metade
    GameManager.map_half_size = 47.5
```

---

## O que NÃO muda

- Lógica de spawn de inimigos (spawner usa tempo, não área)
- Dano, velocidade, mecânica de caramelo pegajoso
- Qualquer outro estágio (mudança isolada ao candy)
- `map_half_size` padrão do `game_manager.gd` (permanece 95.0 para outros estágios)

---

## Como reverter

Para restaurar o tamanho original:
1. `candy_props.gd`: `area_size = 80.0`
2. `stage_candy.gd`: remover a linha `GameManager.map_half_size = 47.5`
