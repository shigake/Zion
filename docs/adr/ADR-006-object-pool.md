# ADR-006 — ObjectPool para inimigos e projéteis

**Status:** Aceito
**Data:** 2024-03

---

## Contexto

Zion pode ter 1000+ entidades simultâneas (inimigos, projéteis, pickups). Instanciar e destruir nodes a cada spawn/morte causa GC pressure e stutters visíveis, especialmente no pico de horda (minuto 20+).

## Decisão

Implementar um **ObjectPool genérico** (`scripts/autoload/object_pool.gd`) que reutiliza instâncias de nodes pelo `resource_path` da cena.

**API:**
```gdscript
# Pegar instância (da pool ou nova)
var enemy = ObjectPool.get_instance(enemy_scene)

# Devolver para a pool ao morrer
ObjectPool.return_instance(enemy, enemy_scene.resource_path)
```

Scripts que usam pool implementam `_reset_for_reuse()` para limpar estado antes de reutilizar.

## Justificativa

- **Zero alocações durante gameplay**: instâncias são criadas na fase de aquecimento e reutilizadas
- **Genérico por design**: funciona com qualquer `PackedScene` — inimigos, projéteis, partículas, pickups
- **Integração com LOD**: `LodManager` e `EnemyCuller` trabalham em conjunto com a pool para ocultar entidades distantes sem removê-las do pool
- **Métricas de debug**: `_active[path]` rastreia quantas instâncias de cada tipo estão ativas — visível no DebugOverlay (F3)

## Detalhes de Implementação

- Pool indexada por `scene.resource_path` (String) → `Array[Node]`
- `return_instance()` remove o node da árvore de cena antes de devolver ao pool
- Instância inválida (`is_instance_valid() == false`) é descartada silenciosamente
- Cap de pickups: 200 simultâneos (evita encher a pool com itens não coletados)

## Alternativas Descartadas

| Alternativa | Por que descartada |
|-------------|-------------------|
| `queue_free()` + `instantiate()` a cada vez | GC pressure; stutters com 1000+ entidades |
| Pool por tipo (EnemyPool, ProjectilePool) | Duplicação de código; mais difícil de manter |
| Visibility Notifier para gerenciar | Não resolve o problema de alocação; apenas otimiza render |

## Consequências

- Todo script de inimigo/projétil deve implementar `_reset_for_reuse()` para limpar HP, timers, estado de animação
- A pool não tem tamanho máximo — se uma cena vazar (não devolver ao pool), a pool cresce indefinidamente. Monitorar via F3.
- `MultiMeshManager` complementa a pool para renderizar grupos de inimigos idênticos em batch
