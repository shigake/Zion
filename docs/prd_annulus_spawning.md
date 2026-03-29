# PRD — Annulus Spawning (Spawn Seguro)

## Objetivo
Impedir que inimigos surjam "do nada" dentro do campo de visão do jogador. Todo spawn deve ocorrer em um anel (annulus/donut) invisível logo fora da câmera, para que inimigos sempre "entrem andando" na tela.

## Contexto Narrativo
Os inimigos são manifestações da corrupção dimensional — eles emergem das fissuras no tecido da realidade ao redor do Fragmentado. Faz sentido narrativo que apareçam nas bordas da percepção, não no centro.

## Especificação Técnica

### Constantes
```gdscript
const MIN_SPAWN_RADIUS: float = 15.0  # Logo fora da visão da câmera top-down
const MAX_SPAWN_RADIUS: float = 20.0  # Limite máximo do anel
```

### Fórmula (coordenadas polares → XZ)
```gdscript
func _get_annulus_spawn_position(center: Vector3) -> Vector3:
    var angle = randf() * TAU
    var distance = randf_range(MIN_SPAWN_RADIUS, MAX_SPAWN_RADIUS)
    var offset = Vector3(cos(angle), 0, sin(angle)) * distance
    return center + offset
```

### Pontos de spawn afetados

| Arquivo | Função | Raio atual | Novo comportamento |
|---------|--------|------------|-------------------|
| `enemy_spawner.gd` | `_spawn_wave()` | fixo 25.0 | annulus 15-20 |
| `enemy_spawner.gd` | `_spawn_miniboss()` | fixo 15.0 | annulus 15-20 |
| `enemy_spawner.gd` | `_spawn_boss()` | fixo -15Z | annulus 18-22 (bosses mais longe) |
| `enemy_spawner.gd` | `_process_boss_rush()` | fixo -15Z | annulus 18-22 |
| `event_manager.gd` | `_spawn_event_miniboss()` | fixo 15.0 | annulus 15-20 |
| `event_manager.gd` | hordas (golden, elite, massive) | fixo 12-15 | annulus 15-20 |
| `event_manager.gd` | treasure goblin, merchant, etc | fixo 15 | annulus 15-20 |

### Nota de Level Design
O `MIN_SPAWN_RADIUS` deve ser ajustado conforme a altura e FOV da câmera top-down. O objetivo é que o inimigo apareça ~1-2 unidades fora da borda visível.

## Critérios de Aceite
- [ ] Nenhum inimigo surge repentinamente dentro do campo de visão do jogador
- [ ] Inimigos surgem em todas as direções (360°) de forma fluida
- [ ] O cálculo é leve e não afeta a meta de 60 FPS mesmo com 500 inimigos
- [ ] Bosses e mini-bosses também usam annulus spawning
- [ ] Código centralizado — uma única função utilitária reutilizada por todos os spawners

## Implementação
1. Criar função `_get_annulus_position(center, min_r, max_r)` no `enemy_spawner.gd`
2. Substituir todos os cálculos de posição de spawn por chamadas a essa função
3. Fazer o mesmo no `event_manager.gd`
4. Remover a variável `@export spawn_distance` (substituída pelas constantes do annulus)

## Prioridade
Alta — afeta diretamente a sensação de jogo (game feel).
