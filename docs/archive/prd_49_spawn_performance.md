# PRD 49 — Performance: Preload de sprites e otimização de spawn

**Status**: concluído
**Versão**: 3.54.9

## Problema

O jogo travava brevemente quando inimigos (especialmente slimes) spawnam. A causa raiz:
1. Texturas de sprites carregadas com `load()` síncrono no primeiro spawn de cada tipo
2. Lista de prewarm com cenas erradas (spider, mushroom, wolf que não existem no spawner)
3. Apenas 3 tipos de inimigos pré-aquecidos no ObjectPool (slime, bat, skeleton)
4. `ResourceLoader.exists()` chamado 2-4x por spawn para resolver paths
5. Sprite3D criado individualmente mesmo quando MultiMesh estava ativo (desperdiçando CPU)

## Soluções

### 1. Preload de texturas na loading screen (eliminação de stutters)
- Novo step `_prewarm_sprite_textures()` durante loading screen
- Carrega TODAS as texturas de inimigos da fase atual no cache estático `EnemyBase3D._sprite_cache`
- Resolve e cacheia paths em `_sprite_path_cache` — zero `ResourceLoader.exists()` em runtime
- Inclui sprites temáticos da fase (cemetery_zombie, forest_mushroom, etc.)
- Inclui sprites de bosses

### 2. Lista de prewarm corrigida e expandida
- Removidas cenas inexistentes (spider, mushroom, wolf)
- Adicionados TODOS os 16 tipos de inimigos reais
- Contagem por tipo: slime=20, bat=15, skeleton=12, ghost=10, etc.
- Ghost variants incluídos (white, green, blue, red)

### 3. Spawner com prewarm expandido
- De 3 tipos → 12 tipos pré-aquecidos
- Ghost variants extras no cemitério
- Contagens maiores para tipos comuns

### 4. Skip de sprite durante MultiMesh
- Quando MultiMesh está ativo (50+ inimigos), `_apply_sprite()` pula criação de Sprite3D
- Economiza `load()` + `Sprite3D.new()` + `add_child()` por inimigo
- Restauração lazy quando MultiMesh desativa (texturas já cacheadas = sem I/O)

### 5. Path resolution refatorado
- `_resolve_sprite_path()` estático com prioridade clara
- Máximo 3 `ResourceLoader.exists()` (temático → genérico → boss → fallback)
- Resultado cacheado permanentemente em `_sprite_path_cache`

## Impacto estimado
- Eliminação de 72-120ms de stutter por wave de spawn
- Zero disk I/O durante gameplay (tudo cacheado na loading screen)
- Menos nós criados quando 50+ inimigos ativos
