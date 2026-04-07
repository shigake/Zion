# Status: EM ANDAMENTO

# PRD 63 - Performance Runtime Backlog (Passo Atual + Proxima Rodada)

## Contexto

O projeto ja teve pelo menos duas rodadas de performance (`prd_05`, `prd_25`, `prd_49`), e parte importante delas realmente entrou no codigo. Mesmo assim, a leitura do codigo atual mostra que o custo de runtime ainda fica concentrado em quatro zonas:

1. consultas de raio/AoE que ainda forcam rebuild repetido de estrutura espacial;
2. drops e summons em kill-path ainda fazendo `instantiate()` em massa;
3. armas/VFX pesadas ainda criando `GPUParticles3D`, `Tween`, `ImmediateMesh` e `load()` em runtime;
4. batching visual que existe, mas ainda entra tarde ou com qualidade visual insuficiente para ser usado mais cedo.

Este PRD registra:

- o que foi melhorado neste passe;
- o que ainda precisa ser implementado;
- a ordem recomendada de execucao;
- criterios concretos de validacao.

---

## O que entrou neste passe

### 1. `ObjectPool` deixou de crescer silenciosamente a cada run

Arquivo:
- `game/scripts/autoload/object_pool.gd`

Mudanca:
- `prewarm()` agora faz **top-up ate o target** em vez de adicionar novas instancias toda vez.

Impacto esperado:
- evita crescimento invisivel do pool entre runs;
- reduz memoria presa e stutter acumulado em sessoes longas/NG+;
- mantem o beneficio do prewarm sem inflar o autoload.

### 2. `ParticleFactory` ganhou budget coerente com o pool

Arquivo:
- `game/scripts/effects/particle_factory.gd`

Mudancas:
- `MAX_ACTIVE_PARTICLES` foi alinhado para ficar abaixo de `PARTICLE_POOL_SIZE`;
- os nos prewarmados nao criam mais um mesh/material default novo por particula do pool;
- particulas ativas agora entram no grupo `particles`, permitindo que o `PerfMonitor` e o auto-adjust atuem de verdade nelas.

Impacto esperado:
- menos alocacao de recursos no bootstrap do pool;
- menos burst allocation quando o jogo entra em combate denso;
- melhor integracao com o sistema de qualidade dinamica ja existente.

### 3. `MultiMeshManager` cortou custo quando pickups ainda nao precisam de batch

Arquivo:
- `game/scripts/autoload/multimesh_manager.gd`

Mudancas:
- textura fallback de inimigo e textura de pickup passaram a ser `preload`;
- material de pickup passou a ser compartilhado;
- quando o pickup multimesh esta desligado, a ativacao usa primeiro `GameManager.active_pickup_count` antes de fazer `get_nodes_in_group("pickups")`.

Impacto esperado:
- menos lookup/load em runtime;
- menos queries caras na arvore quando a contagem de pickups ainda esta baixa;
- ativacao de pickup batching continua igual, mas com menor overhead antes do threshold.

### 4. `EnemySpawner` passou a preaquecer os tipos que faltavam

Arquivo:
- `game/scripts/enemies/enemy_spawner.gd`

Mudancas:
- cobertura de prewarm adicionada para `archer`, `mimic` e `tooth_fairy`;
- remocao do prewarm duplicado de `skeleton`.

Impacto esperado:
- reduz stutter do primeiro spawn desses inimigos no meio da run.

### 5. Cache de sprite de inimigo agora tem limite

Arquivo:
- `game/scripts/enemies/enemy_base.gd`

Mudancas:
- `_sprite_cache` ganhou eviction simples por ordem de insercao;
- `_flash_white()` passou a reutilizar o sprite cacheado em vez de buscar o node toda hora.

Impacto esperado:
- evita cache estatico crescer indefinidamente numa sessao longa com muitas fendas/skins;
- reduz custo por hit em inimigos ja vivos.

### 6. Pickups raros ficaram mais baratos por instancia

Arquivos:
- `game/scripts/health_pickup.gd`
- `game/scripts/magnet_pickup.gd`

Mudancas:
- texturas passaram a ser `preload`;
- bob/heartbeat/rotacao foram escalonados por frame counter;
- attraction check passou para `distance_squared_to` e cadence reduzida quando idle.

Impacto esperado:
- menos custo por pickup vivo;
- menos `load()` por instancia;
- menor custo de attraction loop em mapas com muitos drops.

---

## Backlog real que ainda precisa ser feito

## P0 - Rebuild da grid espacial deve acontecer no maximo 1 vez por frame

Problema atual:

Em `game/scripts/autoload/game_manager.gd`, os metodos abaixo ainda fazem rebuild da grid a cada chamada:

- `get_nearby_enemies(pos, radius)`
- `get_enemies_in_radius(pos, radius)`

Isso custa caro porque eles sao usados em varios pontos de AoE/sinergia:

- `game/scripts/autoload/synergy_system.gd`
- `game/scripts/weapons/bazooka.gd`
- `game/scripts/weapons/flamethrower.gd`
- `game/scripts/weapons/ice_staff.gd`
- `game/scripts/weapons/portal_behavior.gd`
- `game/scripts/weapons/rocket.gd`
- `game/scripts/weapons/time_bomb.gd`
- `game/scripts/weapons/time_bomb_behavior.gd`
- `game/scripts/enemies/enemy_base.gd`

Risco:
- dezenas de rebuilds por frame quando varias armas AoE e sinergias proccam juntas.

Implementacao proposta:

1. adicionar cache por frame no `GameManager`:
   - `_spatial_grid_frame: int`
   - `_spatial_grid_enemy_count: int`
2. rebuildar a grid apenas quando:
   - mudou o frame de processo; ou
   - mudou o numero de inimigos cached; ou
   - forcado por evento relevante.
3. expor helper interno:

```gdscript
func _ensure_spatial_grid_current() -> void:
	var frame = Engine.get_process_frames()
	var enemies = get_enemies()
	if frame == _spatial_grid_frame and enemies.size() == _spatial_grid_enemy_count:
		return
	_spatial_grid.rebuild(enemies)
	_spatial_grid_frame = frame
	_spatial_grid_enemy_count = enemies.size()
```

4. ambos os metodos publicos passam a chamar apenas `_ensure_spatial_grid_current()`.

Arquivos:
- `game/scripts/autoload/game_manager.gd`
- `game/scripts/autoload/spatial_enemy_grid.gd` (se precisar ajuste interno)

Criterio de aceite:
- no profiler, `SpatialEnemyGrid.rebuild()` nao pode aparecer mais de 1 vez por frame em combate denso.

---

## P0 - Matar `instantiate()` do kill-path comum

Problema atual:

`game/scripts/enemies/enemy_base.gd` ainda instancia direto no caminho mais quente do jogo:

- `_spawn_xp_gem()`
- `_spawn_crystal()`
- `_spawn_health_pickup()`
- `_spawn_magnet_pickup()`
- `_apply_death_behavior()` em `spawn_on_death` e `split`

Hoje isso significa que cada morte pode gerar:

- 1 a 4 pickups;
- inimigos extras em split/spawn-on-death;
- alocacao de cena + `_ready()` encadeado no meio do caos de combate.

Implementacao proposta:

1. criar pool dedicado para pickups e summons leves:
   - `xp_gem`
   - `crystal_pickup`
   - `health_pickup`
   - `magnet_pickup`
   - `bat` de spawn-on-death
   - `slime` de split
2. adicionar `_reset_for_reuse()` nos pickups;
3. padronizar retorno ao pool em vez de `queue_free()` para os tipos elegiveis;
4. preaquecer esses pools no loading screen ou no stage bootstrap.

Arquivos:
- `game/scripts/enemies/enemy_base.gd`
- `game/scripts/xp_gem.gd`
- `game/scripts/crystal_pickup.gd`
- `game/scripts/health_pickup.gd`
- `game/scripts/magnet_pickup.gd`
- `game/scripts/autoload/object_pool.gd`

Criterio de aceite:
- kill-path comum nao pode mais chamar `instantiate()` para pickups;
- profiler deve mostrar reducao clara de stutter em momentos com 30+ mortes simultaneas.

---

## P1 - Passo pesado de VFX/armas AoE ainda precisa de pooling de verdade

Problema atual:

As armas abaixo ainda concentram criacao de VFX em runtime com `GPUParticles3D.new()`, `ImmediateMesh.new()`, `create_tween()` ou `load()`:

- `game/scripts/weapons/blood_orb.gd`
- `game/scripts/weapons/ice_staff.gd`
- `game/scripts/weapons/plasma_cannon.gd`
- `game/scripts/weapons/poison_bottle.gd`
- `game/scripts/weapons/portal_behavior.gd`
- `game/scripts/weapons/portal_weapon.gd`
- `game/scripts/weapons/rocket.gd`
- `game/scripts/weapons/time_bomb.gd`
- `game/scripts/weapons/time_bomb_behavior.gd`
- `game/scripts/weapons/tornado.gd`
- `game/scripts/weapons/totem.gd`
- `game/scripts/weapons/lightning_chain.gd`

Observacao:
- esse grupo coincide com as familias de arma mais espetaculares e tambem com as mais caras de render/runtime;
- boa parte delas tambem entra no PRD visual 3D das AoE, entao a proxima rodada precisa alinhar performance e visual, nao fazer retrabalho.

Implementacao proposta:

1. criar mini-pools por arma para VFX recorrente:
   - aneis de explosao
   - sparks
   - smoke
   - mist
   - pulse rings
2. substituir `load()` em runtime por `preload` ou cache lazy estatico;
3. mover `ImmediateMesh.new()` recorrente para recursos compartilhados ou geradores persistentes;
4. trocar tweens decorativas em loop por update manual quando o efeito for extremamente frequente;
5. consolidar VFX secundario dessas armas no `ParticleFactory` quando fizer sentido.

Arquivos:
- armas listadas acima
- possivel novo helper em `game/scripts/weapons/weapon_vfx.gd`
- possivel extensao de `game/scripts/effects/particle_factory.gd`

Criterio de aceite:
- nenhum hot-path dessas armas deve continuar com `load()` por ativacao;
- `GPUParticles3D.new()` deve ficar restrito a bootstrap/pool;
- profiler com 3+ armas AoE simultaneas nao pode gerar spike de alocacao por segundo.

Dependencia:
- alinhar com [docs/prd_62_armas_aoe_visual_3d.md](C:\Users\luizinho\Documents\GitHub\Zion\docs\prd_62_armas_aoe_visual_3d.md) para nao refazer VFX duas vezes.

---

## P1 - MultiMesh de inimigos precisa de versao visualmente aceitavel

Problema atual:

O sistema existe em `game/scripts/autoload/multimesh_manager.gd`, mas o threshold continua em `300` porque o fallback visual usa uma textura compartilhada simples. Na pratica:

- ele entra tarde demais para ajudar a run normal;
- se entrar cedo demais, degrada demais a aparencia dos inimigos.

Implementacao proposta:

1. criar uma estrategia de atlas/indices de textura para inimigos comuns;
2. manter cor por instancia, mas recuperar variedade minima de sprite;
3. so depois disso reduzir o threshold para faixa realmente util (`140-180`, a validar no profiler).

Arquivos:
- `game/scripts/autoload/multimesh_manager.gd`
- `game/scripts/enemies/enemy_base.gd`
- assets/atlas ou shader/material auxiliar

Criterio de aceite:
- draw calls caem em hordas grandes sem transformar a tela inteira em "slime billboard";
- threshold pode baixar sem regressao visual forte.

Dependencia:
- requer apoio de tech art para atlas/material/shader.

---

## P1 - Projectiles ainda estao sem rollout completo de pool

Problema atual:

Varios ranged continuam instanciando projeteis diretamente:

- `crossbow.gd`
- `dual_pistol.gd`
- `machinegun.gd`
- `drone.gd`
- `elven_bow.gd`
- `bazooka.gd`

Implementacao proposta:

1. padronizar interface de projectile pool;
2. adicionar `_reset_for_reuse()` em `bullet`, `rocket`, `elven_bow_arrow`, `ice_staff_projectile` e equivalentes;
3. migrar armas ranged mais frequentes primeiro:
   - `machinegun`
   - `dual_pistol`
   - `crossbow`

Criterio de aceite:
- armas hitscan/projeteis basicos nao podem mais `instantiate()` por disparo em combate continuo.

---

## P2 - `event_manager.gd` ainda bypassa o pool

Problema atual:

Os eventos de stage continuam criando inimigos diretamente em varios pontos de `game/scripts/stages/event_manager.gd`.

Impacto:
- nao pesa tanto quanto o loop normal da run;
- mas concentra spikes em eventos grandes e summon waves.

Implementacao proposta:

1. trocar `instantiate()` por `ObjectPool.get_instance()` nos spawns elegiveis;
2. manter boss/event spawns especiais fora do pool apenas quando houver estado muito custom.

Arquivos:
- `game/scripts/stages/event_manager.gd`

Criterio de aceite:
- eventos de wave nao geram stutter isolado maior que a wave normal do spawner principal.

---

## Ordem recomendada

1. grid espacial 1x por frame;
2. pooling de pickups e summons de morte;
3. pooling/caching das armas AoE pesadas;
4. pooling dos projeteis ranged de maior frequencia;
5. MultiMesh de inimigos com atlas visualmente aceitavel;
6. migracao do `event_manager`.

---

## Metricas de sucesso

| Metrica | Estado Atual | Alvo desta rodada |
|--------|--------------|-------------------|
| Rebuild da grid espacial | muitas vezes por frame | max 1 por frame |
| `instantiate()` no kill-path comum | alto | zero para pickups |
| `load()` em hot-path de armas AoE | presente | zero |
| Spikes de alocacao em combate denso | perceptiveis | raros ou ausentes |
| Draw calls em horda grande | altos | queda mensuravel com batching util |
| Sessao longa / varias runs | risco de inflar caches/pools | memoria mais estavel |

---

## Validacao

- [ ] Rodar 10 minutos no stage mais pesado com build de debug e confirmar melhoria no profiler
- [ ] Confirmar que `SpatialEnemyGrid.rebuild()` nao aparece mais de 1x por frame
- [ ] Confirmar que matar 30+ inimigos simultaneamente nao gera burst forte de `instantiate()`
- [ ] Testar `bazooka`, `ice_staff`, `poison_bottle`, `portal_weapon`, `tornado`, `totem`, `blood_orb` juntos e medir alocacoes/s
- [ ] Testar 3 runs seguidas e confirmar estabilidade de pool/cache
- [ ] Medir draw calls antes/depois em horda alta

---

## Restricao importante

As proximas otimizações precisam preservar:

- dano, area e cadence de gameplay;
- leitura visual minima das armas AoE;
- integracao com o PRD visual 3D das AoE;
- acessibilidade (`reduced_motion`, throttles de FPS, damage numbers toggle).

Se uma otimizacao exigir sacrificar leitura visual de uma arma AoE, ela deve voltar como decisao de produto/arte, nao entrar silenciosamente como "ajuste tecnico".
