# ADR-013 — Resource Caching e ObjectPool Pre-warming

**Status:** Aceito
**Data:** 2024-12 (implementado no PRD-25)

---

## Contexto

Durante sessões de combate denso (minuto 4-6, 150+ inimigos), o jogo apresentava micro-stutters de 2-5ms causados por alocações de recursos a cada frame. A `ParticleFactory` criava `SphereMesh.new()` + `StandardMaterial3D.new()` repetidamente — 50+ vezes por segundo. O `ObjectPool` nascia vazio, causando stutter nos primeiros 3 segundos de toda run. Tweens eram criados e destruídos (30 por segundo), pressionando o GC do Godot.

Além disso, o `PerfMonitor` usava `remove_at(0)` numa array para manter média móvel — operação O(n) executada todo frame.

## Decisão

**Cachear recursos que eram realocados repetidamente; pre-warm o ObjectPool; substituir estruturas de dados O(n) por O(1).**

Decisões específicas tomadas:

### 1. Material Cache na ParticleFactory
- `_material_cache: Dictionary = {}` indexado por tipo de partícula
- Na primeira criação: aloca `SphereMesh` + `StandardMaterial3D`, guarda no cache
- Nas chamadas subsequentes: retorna o recurso já criado (zero alocação)
- Limite: cache ilimitado (tipos são finitos e conhecidos em compile time)

### 2. Tween Pool (sem Tween descartável)
- Pool estático de 30 Tweens criados no `_ready()` da `ParticleFactory`
- `acquire_tween()` / `release_tween()` em vez de `create_tween()` + auto-destroy
- Tweens são reiniciados (`stop()` + `kill()` dos steps anteriores) antes de reusar
- Se pool esgotado: fallback para `create_tween()` com log de warning

### 3. ObjectPool Pre-warming
- Ao entrar em qualquer stage: `ObjectPool.prewarm(count)` instancia N objetos antes do primeiro frame de gameplay
- Contagem por tipo definida em `GameConstants.POOL_PREWARM_COUNTS`
- Elimina o stutter nos primeiros 3s da run

### 4. Circular Buffer no PerfMonitor
- Substituição de `Array` com `remove_at(0)` por circular buffer de tamanho fixo
- `_ring: PackedFloat64Array` de tamanho `PERF_SAMPLE_WINDOW`
- `_head: int` avança mod N — sem alocação, sem cópia, sem GC
- Complexidade: O(1) insert, O(n) média (n = janela, ~60 amostras)

### 5. Limite LRU no Enemy Sprite Cache
- Cache de sprites de inimigos tinha crescimento ilimitado
- Substituído por LRU com máximo 60 entradas
- Entradas mais antigas descartadas ao atingir limite (raro em sessão normal)

## Justificativa

- **Micro-stutters são perceptíveis mesmo sem queda de FPS médio** — picos de 5ms a 60 FPS são 30% do frame budget. Cache elimina os picos mais que aumenta a média.
- **Godot GC não é generacional** — cada `new()` desnecessário pressiona o coletor global. Em combate denso isso é crítico.
- **Pre-warming é padrão do gênero** — Vampire Survivors, Brotato e similares pre-aquecem pools. A UX de "carregando..." é aceitável; o stutter em gameplay não é.
- **Circular buffer é solução clássica** para janelas deslizantes — nenhuma razão para usar Array com remoção frontal neste contexto.

## Alternativas Descartadas

- **`Node.duplicate()`** para materiais — não elimina a alocação, apenas muda quem faz
- **GPUParticles3D nativo** — muda o pipeline visual inteiro, fora de escopo do PRD-25
- **Pool de Tweens compartilhado via autoload** — overhead de chamada de método. Pool local na `ParticleFactory` é suficiente.

## Consequências

- `ParticleFactory` não pode mais ter materiais "únicos por instância" sem opt-out explícito do cache
- O pre-warming aumenta o tempo de carregamento inicial de stages em ~0.2s (aceito — está na tela de loading)
- Circular buffer requer que consumidores do `PerfMonitor` não assumam índice fixo das amostras
- Signal leaks entre runs (connects sem disconnect ao trocar de stage) foram corrigidos como parte do mesmo PRD — ver `stage_base.gd`, método `_exit_tree()`
