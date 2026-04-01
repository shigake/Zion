## Status: PENDENTE

# PRD 25 — Otimização de Performance (Sem Alterar Visual ou Jogatina)

## Contexto

O jogo está tecnicamente completo e funcionando. Porém, com a adição progressiva de sistemas (boss AoE, quests, chests, daily challenge, cinematicas, cutscenes, XP bar world-space, popup de conquistas, overlay de inventário), a soma de pequenos gargalos agora resulta em quedas de FPS perceptíveis — especialmente após o minuto 5 de run, onde há 80–150 inimigos simultâneos, dezenas de partículas e múltiplos sistemas rodando em paralelo.

Este PRD documenta otimizações **exclusivamente de código e de lógica de gerenciamento de recursos** — nenhuma mudança de visual (tamanhos, cores, sprites, efeitos) ou de jogatina (dano, velocidade, cooldowns, caps de gameplay). O jogador não deve notar nenhuma diferença na tela ou no controle — apenas o jogo rodando mais suave.

---

## Problemas Identificados (auditoria técnica)

A auditoria leu os seguintes arquivos e encontrou gargalos em 4 camadas distintas:

| Camada | Arquivo Principal | Classificação |
|--------|------------------|---------------|
| Signals vazando entre runs | `stage_base.gd` | 🔴 Crítico |
| Alocação de Materials por partícula | `particle_factory.gd` | 🔴 Crítico |
| Tweens alocadas por emissão de partícula | `particle_factory.gd` | 🟠 Alto |
| ObjectPool nascendo vazio | `object_pool.gd` | 🟠 Alto |
| FPS checado múltiplas vezes por spawn | `enemy_spawner.gd` | 🟠 Alto |
| Moving average usa `remove_at(0)` O(n) | `perf_monitor.gd` | 🟡 Médio |
| Sprite cache de inimigos sem limite | `enemy_base.gd` | 🟡 Médio |
| MultiMesh possivelmente subutilizado | `multimesh_manager.gd` | 🟡 Médio |
| LOD batch pequeno (50 props por ciclo) | `lod_manager.gd` | 🟡 Médio |
| Constantes desalinhadas (pool vs max) | `particle_factory.gd` | 🟢 Baixo |

---

## Problema 1 — Signals de stage nunca desconectadas (Memory Leak Crítico)

### Diagnóstico

Em `scripts/stages/stage_base.gd`, as seguintes signals são conectadas no `_ready()` (ou equivalente de setup):

```gdscript
GameManager.weapon_added.connect(_on_weapon_changed)
GameManager.weapon_upgraded.connect(_on_weapon_upgraded_synergy)
GameManager.enemy_killed.connect(_on_enemy_killed_synergy)
```

O `GameManager` é um **autoload singleton** — ele persiste por toda a sessão. A `stage_base` (e suas subclasses), porém, é destruída e recriada a cada run. O resultado: a cada run completa (morte, vitória, NG+), o autoload acumula um listener "fantasma" apontando para um nó que já não existe. Na décima run o singleton está disparando cada signal para 10 callbacks, com 9 deles apontando para nós inválidos.

**Consequência prática**: no mínimo 2× a CPU gasta em signals a cada run NG+, podendo causar crashes silenciosos e comportamentos inesperados (callbacks executando com contexto de nodes destruídos).

### Solução

Adicionar `_exit_tree()` em todos os scripts de stage que conectam signals de autoloads:

```gdscript
func _exit_tree() -> void:
    if GameManager.weapon_added.is_connected(_on_weapon_changed):
        GameManager.weapon_added.disconnect(_on_weapon_changed)
    if GameManager.weapon_upgraded.is_connected(_on_weapon_upgraded_synergy):
        GameManager.weapon_upgraded.disconnect(_on_weapon_upgraded_synergy)
    if GameManager.enemy_killed.is_connected(_on_enemy_killed_synergy):
        GameManager.enemy_killed.disconnect(_on_enemy_killed_synergy)
```

O mesmo padrão deve ser aplicado em: `enemy_base.gd`, `chest_manager.gd`, `quest_manager.gd` — qualquer script que conecta signals de autoloads nos seus `_ready()`.

**O que NÃO muda**: lógica de sinergias, comportamento dos bosses, fluxo da run — apenas a limpeza de listeners ao sair da cena.

---

## Problema 2 — Alocação de Meshes e Materials por Emissão de Partícula

### Diagnóstico

Em `scripts/effects/particle_factory.gd`, os métodos `spawn_hit_particles()`, `spawn_death_particles()` e similares criam objetos novos em cada chamada:

```gdscript
# DENTRO do método spawn — chamado dezenas de vezes por segundo:
var mesh = SphereMesh.new()
mesh.radius = 0.08
var mat = StandardMaterial3D.new()
mat.emission_enabled = true
mat.albedo_color = color
particles.draw_pass_1 = mesh
```

Durante combate intenso (50+ inimigos tomando dano ao mesmo tempo), isso cria **50+ novos objetos por segundo** — SphereMeshes e StandardMaterials que são criados, usados por 0.3s e destruídos, forçando o garbage collector a trabalhar continuamente. Isso se manifesta como micro-stutters (travadas de 1–3 frames) a cada 5–10 segundos durante combate denso.

### Solução

Pré-alocar uma biblioteca de meshes e materials compartilhados no `_ready()`, reutilizando por referência:

```gdscript
# DECLARADOS UMA VEZ no _ready():
var _hit_mesh: SphereMesh
var _death_mesh: SphereMesh
var _shared_mat_cache: Dictionary = {}  # key: "r_g_b" → StandardMaterial3D

func _ready() -> void:
    _hit_mesh = SphereMesh.new()
    _hit_mesh.radius = 0.08
    _death_mesh = SphereMesh.new()
    _death_mesh.radius = 0.12
    # ... demais meshes fixas

func _get_shared_material(color: Color) -> StandardMaterial3D:
    var key := "%.2f_%.2f_%.2f" % [color.r, color.g, color.b]
    if key not in _shared_mat_cache:
        var mat := StandardMaterial3D.new()
        mat.emission_enabled = true
        mat.albedo_color = color
        _shared_mat_cache[key] = mat
    return _shared_mat_cache[key]

# NO MÉTODO spawn_hit_particles():
particles.draw_pass_1 = _hit_mesh          # reutiliza
particles.material_override = _get_shared_material(color)   # reutiliza ou cria 1x
```

**O que NÃO muda**: aparência visual das partículas, tamanhos, cores, efeitos visuais — nada que o jogador veja.

---

## Problema 3 — Tweens Alocados por Emissão de Partícula

### Diagnóstico

Em `scripts/effects/particle_factory.gd`, cada emissão de partícula cria um `Tween` para a limpeza automática:

```gdscript
func _setup_and_emit(particles, cleanup_time: float) -> void:
    # ...
    var tween = create_tween()
    tween.tween_callback(func(): _return_particle(particles)).set_delay(cleanup_time)
```

Com 30 partículas simultâneas ativas (limite do pool), há 30 Tweens vivos ao mesmo tempo. Como cada partícula tem vida útil de 0.3–1.5s, o sistema cria e destrói **20–60 Tweens por segundo** durante combate. Tweens são objetos C++ pesados — cada criação faz alocação de heap.

### Solução

Substituir Tweens por um timer interno simples:

```gdscript
# Rastrear tempo de expiração em vez de usar Tween:
var _active_particles: Dictionary = {}  # node → expiry_time

func _setup_and_emit(particles, cleanup_time: float) -> void:
    particles.emitting = true
    _active_particles[particles] = Time.get_ticks_msec() / 1000.0 + cleanup_time

func _process(delta: float) -> void:
    var now := Time.get_ticks_msec() / 1000.0
    for p in _active_particles.keys():
        if now >= _active_particles[p]:
            _active_particles.erase(p)
            _return_particle(p)
```

Zero Tweens alocados. O `_process` já roda no ParticleFactory, então não há custo adicional.

**O que NÃO muda**: timing de limpeza, comportamento das partículas, qualquer efeito visual.

---

## Problema 4 — ObjectPool Nasce Vazio (Stutter de Arranque)

### Diagnóstico

O `ObjectPool` (`scripts/autoload/object_pool.gd`) começa completamente vazio. Quando o spawner precisa de um inimigo — especialmente nos primeiros segundos de run — o pool não tem nenhum em cache e faz `scene.instantiate()` na hora, que envolve:
1. Parse da cena `.tscn`
2. Instanciação de todos os nós filhos
3. Chamadas `_ready()` encadeadas

Com 5–10 inimigos spawning nos primeiros 3 segundos, isso causa uma trava perceptível no inicio da run.

### Solução

Adicionar pré-alocação silenciosa no `_ready()` do ObjectPool:

```gdscript
const PREALLOC := {
    "enemy_base": 20,      # inimigos genéricos mais comuns
    "ranged_enemy": 10,    # inimigos de distância
    "projectile": 30,      # projéteis (alto giro)
    "pickup_hp": 15,       # drops de HP
    "pickup_magnet": 5,    # drops de ímã
}

func _ready() -> void:
    for type in PREALLOC:
        _pool[type] = []
        for _i in range(PREALLOC[type]):
            var scene = _get_scene_for_type(type)
            if scene:
                var inst = scene.instantiate()
                inst.set_process(false)
                inst.set_physics_process(false)
                _pool[type].append(inst)
```

A pré-alocação acontece durante o loading screen (antes da cena de gameplay entrar), então o jogador nunca vê o custo.

**O que NÃO muda**: comportamento de spawning, pool limit, lógica de reset — tudo idêntico.

---

## Problema 5 — FPS Verificado Múltiplas Vezes por Frame de Spawn

### Diagnóstico

Em `scripts/enemies/enemy_spawner.gd`, o método de spawn contém 5 verificações independentes de FPS dentro do mesmo bloco:

```gdscript
func _spawn_wave() -> void:
    var fps = Engine.get_frames_per_second()   # chamada 1
    var dynamic_cap = 150
    if fps < 45: dynamic_cap = 100             # check 1
    if fps < 35: dynamic_cap = 70              # check 2

    # ... mais abaixo no mesmo método:
    if Engine.get_frames_per_second() < 30:    # chamada 2 (redundante)
        spawn_mult *= 0.7

    # ... mais abaixo:
    if Engine.get_frames_per_second() < 25:    # chamada 3 (redundante)
        return
```

Além do custo de 3 chamadas duplicadas a `Engine.get_frames_per_second()`, as verificações podem se contradizer se o FPS mudar entre elas (raro, mas possível em frames de stutter). A lógica fica difícil de manter.

### Solução

Centralizar o estado de FPS em uma variável atualizada 2× por segundo:

```gdscript
var _cached_fps: float = 60.0
var _fps_timer: float = 0.0
const FPS_CACHE_INTERVAL := 0.5

func _process(delta: float) -> void:
    _fps_timer += delta
    if _fps_timer >= FPS_CACHE_INTERVAL:
        _fps_timer = 0.0
        _cached_fps = Engine.get_frames_per_second()

func _get_dynamic_cap() -> int:
    if _cached_fps < 25: return 40
    if _cached_fps < 35: return 70
    if _cached_fps < 45: return 100
    return 150

func _spawn_wave() -> void:
    var cap := _get_dynamic_cap()
    # ... usa `cap` em todo o método, sem mais chamadas a Engine.get_fps
```

**O que NÃO muda**: lógica de spawn, taxas de spawn, comportamento de inimigos, dificuldade.

---

## Problema 6 — Moving Average usa `remove_at(0)` (Operação O(n))

### Diagnóstico

Em `scripts/autoload/perf_monitor.gd`, o histórico de FPS usa array dinâmico com remoção no início:

```gdscript
_fps_history.push_back(current_fps)
if _fps_history.size() > MOVING_AVG_WINDOW:
    _fps_history.remove_at(0)   # O(n) — reshift de todos os elementos
```

`remove_at(0)` em Godot Array faz um `memmove` de todos os elementos uma posição à esquerda. Para um histórico de 60 frames isso é 60 operações de 4 bytes = aceitável em isolamento, mas roda a cada frame junto com 8 outros arrays similares (draw calls, memory, etc.). O custo acumulado é desnecessário.

### Solução

Substituir por circular buffer (custo O(1) para inserção e remoção):

```gdscript
const MOVING_AVG_WINDOW := 60
var _fps_history: Array[float]
var _history_index: int = 0
var _history_filled: bool = false

func _ready() -> void:
    _fps_history.resize(MOVING_AVG_WINDOW)
    _fps_history.fill(60.0)

func _update_fps_history(fps: float) -> void:
    _fps_history[_history_index] = fps
    _history_index = (_history_index + 1) % MOVING_AVG_WINDOW

func _get_fps_average() -> float:
    var sum := 0.0
    for v in _fps_history:
        sum += v
    return sum / MOVING_AVG_WINDOW
```

Aplicar o mesmo padrão para os demais arrays de histórico (draw calls, memória).

**O que NÃO muda**: valores reportados, métricas exibidas no debug overlay (F3/F4).

---

## Problema 7 — Cache de Sprites de Inimigos Cresce Indefinidamente

### Diagnóstico

Em `scripts/enemies/enemy_base.gd`:

```gdscript
static var _sprite_cache: Dictionary = {}
```

Esse cache é `static` — persiste enquanto o jogo estiver rodando, em toda a vida da aplicação. A cada inimigo com skin de fase diferente que carrega seu sprite pela primeira vez, uma entrada é adicionada ao cache. Em uma run completa (7 fendas, 40 tipos tematicos de inimigos), o cache pode acumular 80–100 entradas de textura, totalizando 2–5 MB de VRAM presa desnecessariamente.

### Solução

Implementar LRU cache com limite de entradas:

```gdscript
static var _sprite_cache: Dictionary = {}
const _SPRITE_CACHE_MAX := 60

static func _cache_sprite(key: String, tex: Texture2D) -> void:
    if _sprite_cache.size() >= _SPRITE_CACHE_MAX:
        # Remove a entrada mais antiga (primeira chave)
        _sprite_cache.erase(_sprite_cache.keys()[0])
    _sprite_cache[key] = tex
```

**O que NÃO muda**: aparência dos sprites, loading de texturas, skinning por fase.

---

## Problema 8 — MultiMesh Subutilizado com 50+ Inimigos

### Diagnóstico

O `MultiMeshManager` foi projetado para batcher sprites de inimigos em um único draw call quando há 50+ inimigos na tela. Internamente, há um threshold e lógica de histerese. Porém, durante testes, o sistema pode falhar em ativar o batching se:

1. Os inimigos não estiverem no grupo correto ao spawnar
2. O update tick do manager não coincidir com o pico de inimigos
3. A recontagem do `instance_count` estiver sendo realocada frame a frame

Em cenários com 100–150 inimigos, cada sprite é um draw call individual → **150 draw calls** em vez de **1–2**. Isso pesa diretamente na GPU, especialmente em hardware integrado.

### Solução

1. Garantir que `_multimesh.instance_count` seja pré-alocado para o máximo uma única vez:

```gdscript
func _initialize_multimesh() -> void:
    _multimesh.instance_count = GameConstants.MAX_ENEMIES  # pré-aloca 150 slots fixos
    # Nunca mais realoca durante gameplay
```

2. Verificar que todo inimigo spawado via `ObjectPool` entra no grupo `"enemies_multimesh"` antes de ficar visível.

3. Adicionar log de diagnóstico (F3) mostrando `"MultiMesh: ON/OFF | Batch: X inimigos"` para facilitar validação.

**O que NÃO muda**: aparência dos sprites, comportamento dos inimigos.

---

## Problema 9 — LOD Batch Pequeno Atrasa Transição de Qualidade

### Diagnóstico

Em `scripts/autoload/lod_manager.gd`:

```gdscript
const BATCH_SIZE := 50
const CHECK_INTERVAL := 0.5
```

Com 200+ props em cena (árvores, pedras, luzes decorativas das fendas), o LOD Manager leva `(200 / 50) × 0.5 = 2.0 segundos` para revisar todos os props uma vez. Isso significa que um prop que saiu completamente do campo de visão pode continuar renderizando em qualidade máxima por até 2 segundos.

### Solução

Aumentar o `BATCH_SIZE` sem diminuir o `CHECK_INTERVAL`:

```gdscript
const BATCH_SIZE := 150    # era 50 — 3× mais props por ciclo
const CHECK_INTERVAL := 0.5  # mantido
```

Com 200 props: `(200 / 150) × 0.5 = 0.67 segundos` para revisar tudo — 3× mais rápido. O custo por frame aumenta levemente mas fica dentro do budget de 2ms por tick.

Também separar o cleanup de entradas inválidas para um ciclo próprio, rodando a cada 2s em vez de junto com cada batch:

```gdscript
var _cleanup_timer: float = 0.0

func _process(delta: float) -> void:
    _cleanup_timer += delta
    if _cleanup_timer >= 2.0:
        _cleanup_timer = 0.0
        _cleanup_invalid_entries()
    # ... resto do LOD check normal
```

**O que NÃO muda**: distâncias de LOD, qualidade visual de nenhum nível.

---

## Problema 10 — Constantes Desalinhadas no Pool de Partículas

### Diagnóstico

```gdscript
# particle_factory.gd:
const PARTICLE_POOL_SIZE := 30
const MAX_ACTIVE_PARTICLES := 35
```

`MAX_ACTIVE_PARTICLES > PARTICLE_POOL_SIZE` significa que quando 31–35 partículas estão ativas simultameamente (cenário de combate denso), o sistema **ultrapassou o pool** e começa a instanciar partículas fora do pool — exatamente o gargalo que o pool foi criado para evitar.

### Solução

```gdscript
const PARTICLE_POOL_SIZE := 30
const MAX_ACTIVE_PARTICLES := 25   # margem de segurança: 83% do pool
```

Ao limitar em 25 simultâneas, garante-se que sempre há 5 slots livres no pool mesmo no pior caso.

**O que NÃO muda**: aparência, frequência ou intensidade de partículas durante gameplay normal.

---

## Arquivos Envolvidos

| Arquivo | Problema(s) | Prioridade |
|---------|-------------|-----------|
| `scripts/stages/stage_base.gd` | Signal disconnect em _exit_tree | 🔴 Crítico |
| `scripts/enemies/enemy_base.gd` | Signal disconnect + LRU cache sprites | 🔴 Crítico |
| `scripts/effects/particle_factory.gd` | Shared materials + Tween removal + constante | 🔴 Crítico |
| `scripts/autoload/object_pool.gd` | Pré-alocação no _ready | 🟠 Alto |
| `scripts/enemies/enemy_spawner.gd` | FPS cache centralizado | 🟠 Alto |
| `scripts/autoload/perf_monitor.gd` | Circular buffer | 🟡 Médio |
| `scripts/autoload/multimesh_manager.gd` | instance_count fixo + diagnóstico | 🟡 Médio |
| `scripts/autoload/lod_manager.gd` | Batch size + cleanup separado | 🟡 Médio |
| `scripts/autoload/game_constants.gd` | Alinhamento de constantes de particle | 🟢 Baixo |

Scripts que também devem ganhar `_exit_tree()` com disconnect (varredura necessária):
- `scripts/autoload/chest_manager.gd`
- `scripts/autoload/quest_manager.gd`
- `scripts/ui/hud.gd`
- `scripts/weapons/weapon_base.gd`

---

## Plano de Implementação

### Fase 1 — Correções Críticas (zero risco visual)

1. **Signal disconnects**: Adicionar `_exit_tree()` em `stage_base.gd`, `enemy_base.gd` e nos scripts de UI/weapons que conectam autoloads. Varredura com `grep` para encontrar todos os `.connect(` sem `.disconnect(` correspondente.

2. **Shared materials**: Refatorar `particle_factory.gd` — pré-alocar meshes e materials compartilhados no `_ready()`, usar cache por cor na emissão de partículas.

3. **Remover Tweens**: Substituir todos os `create_tween()` dentro de `particle_factory.gd` por tracking via Dictionary + `_process()`.

### Fase 2 — Otimizações de CPU

4. **ObjectPool prealloc**: Adicionar pré-alocação dos tipos mais usados (enemy_base, projectile, pickup_hp).

5. **FPS cache**: Centralizar `Engine.get_frames_per_second()` em variável com update a cada 0.5s no spawner.

6. **Circular buffer**: Substituir `remove_at(0)` por buffer circular no perf_monitor.

### Fase 3 — Renderização e LOD

7. **MultiMesh**: Fixar `instance_count = MAX_ENEMIES` na inicialização, nunca realocar; adicionar indicador no debug F3.

8. **LOD batch**: Aumentar `BATCH_SIZE` de 50 para 150; separar cleanup para timer próprio.

9. **Constante de partícula**: Ajustar `MAX_ACTIVE_PARTICLES := 25`.

---

## Métricas de Sucesso

| Métrica | Antes | Alvo |
|---------|-------|------|
| FPS médio no minuto 5 (100 inimigos) | ~40 FPS | ≥ 50 FPS |
| FPS médio no minuto 10 (150 inimigos) | ~28 FPS | ≥ 38 FPS |
| Micro-stutters visíveis em combate denso | 1–3 por minuto | 0 |
| Draw calls com 100+ inimigos | 110+ | ≤ 15 (com MultiMesh) |
| Alocações por segundo (Godot Monitor) | ~80/s | ≤ 20/s |
| Memória após 20 min de run | Crescendo | Estável |
| Comportamento em NG+ (3ª run) | Degradação notável | Igual à 1ª run |

---

## Validação

- [ ] Jogar 10 minutos no Cemetery (fenda mais pesada de inimigos) sem queda abaixo de 38 FPS
- [ ] Verificar draw calls no Godot Debugger → Remote → Monitors com 100+ inimigos (target: ≤ 15)
- [ ] Fazer 3 runs completas seguidas (NG+) e confirmar que FPS da 3ª run é igual à 1ª (sem degradação por signal leak)
- [ ] Confirmar no F3 debug overlay que MultiMesh está ativo quando há 50+ inimigos
- [ ] Confirmar que alocações/segundo no Godot Monitor caíram (seção Memory → Objects por frame)
- [ ] Testar em hardware low-end (Intel HD Graphics) — target: 30 FPS no minuto 5

---

## Restrições Absolutas

> Nenhuma das mudanças deste PRD deve alterar:
> - Qualquer valor visual: tamanhos, cores, opacidades, animações, sprites
> - Qualquer valor de gameplay: dano, velocidade, cooldown, área de hitbox, drop rates
> - Qualquer comportamento de IA de inimigos ou bosses
> - Qualquer fluxo de UI visível ao jogador
> - O número máximo de inimigos em tela (MAX_ENEMIES = 150) — apenas o custo de processá-los

Se durante a implementação houver dúvida se uma mudança afeta visual ou gameplay, **não fazer** e documentar para revisão.
