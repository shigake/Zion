# PRD — Refatoracao, DRY, Performance e Qualidade de Codigo

> Auditoria completa do codebase com melhorias priorizadas por impacto e risco.

---

## Tarefa 1: Extrair UICardBuilder (DRY — UI)

**Objetivo:** Eliminar duplicacao de construcao de cards em 5+ telas de UI.

### Contexto

As telas `bestiary_screen.gd`, `codex_screen.gd`, `achievements_screen.gd`, `character_select.gd` e `stage_select.gd` repetem o mesmo padrao de construcao de cards:

```gdscript
var card_btn = Button.new()
card_btn.custom_minimum_size = CARD_SIZE
var card_style = StyleBoxFlat.new()
card_style.bg_color = Color(0.12, 0.12, 0.18)
card_style.set_corner_radius_all(6)
card_style.set_border_width_all(2)
card_style.border_color = type_color
card_btn.add_theme_stylebox_override("normal", card_style)
var hover_style = card_style.duplicate()
hover_style.bg_color = card_style.bg_color.lightened(0.1)
card_btn.add_theme_stylebox_override("hover", hover_style)
```

### Solucao

Criar `res://scripts/ui/ui_card_builder.gd` (classe estatica ou autoload leve):

```gdscript
class_name UICardBuilder

static func create_card(size: Vector2, border_color: Color, bg_color := Color(0.12, 0.12, 0.18)) -> Button:
    var btn = Button.new()
    btn.custom_minimum_size = size
    btn.focus_mode = Control.FOCUS_ALL
    btn.mouse_filter = Control.MOUSE_FILTER_STOP
    var normal = _make_style(bg_color, border_color)
    btn.add_theme_stylebox_override("normal", normal)
    btn.add_theme_stylebox_override("hover", _make_style(bg_color.lightened(0.15), border_color.lightened(0.3)))
    btn.add_theme_stylebox_override("pressed", _make_style(bg_color.lightened(0.15), border_color.lightened(0.3)))
    var focus = _make_style(bg_color.lightened(0.15), Color(1.0, 0.85, 0.2))
    focus.set_border_width_all(3)
    btn.add_theme_stylebox_override("focus", focus)
    return btn

static func create_card_vbox(parent: Button, separation: int = 3) -> VBoxContainer:
    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", separation)
    vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    parent.add_child(vbox)
    vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    return vbox

static func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
    var sb = StyleBoxFlat.new()
    sb.bg_color = bg
    sb.set_corner_radius_all(6)
    sb.set_border_width_all(2)
    sb.border_color = border
    return sb
```

### Arquivos impactados

| Arquivo | Acao |
|---|---|
| `scripts/ui/ui_card_builder.gd` | Criar (novo) |
| `scripts/ui/bestiary_screen.gd` | Refatorar `_populate_grid()` |
| `scripts/ui/codex_screen.gd` | Refatorar `_populate_grid()` |
| `scripts/ui/achievements_screen.gd` | Refatorar construcao de cards |
| `scripts/ui/character_select.gd` | Refatorar cards de personagem |
| `scripts/ui/stage_select.gd` | Refatorar cards de fenda |

### Impacto estimado

~200 linhas de codigo duplicado eliminadas.

### Criterios de aceite

- [ ] 5 telas usam UICardBuilder em vez de construcao manual
- [ ] Aparencia visual identica ao antes (sem regressao)
- [ ] Focus style dourado funciona em todas as telas com gamepad

---

## Tarefa 2: Extrair WeaponVFX (DRY — Armas)

**Objetivo:** Consolidar efeitos visuais de armas (slash trail, shockwave, sparks) num utilitario compartilhado.

### Contexto

10+ scripts de armas melee (`katana.gd`, `axe.gd`, `hammer.gd`, `dual_katana.gd`, `boxing_gloves.gd`, `cloud_sword.gd`, `lance.gd`, `nunchaku.gd`, `scythe.gd`, `whip.gd`) duplicam `_spawn_slash_trail()` com ~30 linhas quase identicas:

```gdscript
var sprite = Sprite3D.new()
sprite.texture = _slash_tex
sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
sprite.pixel_size = 0.03
sprite.shaded = false
sprite.transparent = true
sprite.no_depth_test = true
scene.add_child(sprite)
sprite.global_position = pos
var tween = create_tween()
tween.set_parallel(true)
tween.tween_property(sprite, "scale", Vector3(1.2, 1.2, 1.2), 0.18)
tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
tween.chain().tween_callback(sprite.queue_free)
```

Shockwave rings (`hammer.gd`) e weapon sparks tambem sao duplicados.

### Solucao

Criar `res://scripts/weapons/weapon_vfx.gd` (class_name, estatica):

```gdscript
class_name WeaponVFX

static func spawn_slash_trail(scene: Node, pos: Vector3, texture: Texture2D, pixel_size: float = 0.03, duration: float = 0.2) -> void:
    # ...implementacao unificada...

static func spawn_shockwave(scene: Node, pos: Vector3, color: Color, radius: float = 1.5, duration: float = 0.3) -> void:
    # ...ring mesh + tween...

static func spawn_sparks(scene: Node, pos: Vector3, color: Color, count: int = 4) -> void:
    # ...particle spawning...
```

### Arquivos impactados

| Arquivo | Acao |
|---|---|
| `scripts/weapons/weapon_vfx.gd` | Criar (novo) |
| `scripts/weapons/katana.gd` | Substituir `_spawn_slash_trail()` |
| `scripts/weapons/axe.gd` | Substituir `_spawn_slash_trail()` |
| `scripts/weapons/hammer.gd` | Substituir trail + shockwave |
| +7 armas melee | Mesma substituicao |

### Impacto estimado

~300+ linhas duplicadas eliminadas.

### Criterios de aceite

- [ ] Todos os 10 melee usam WeaponVFX
- [ ] Efeitos visuais identicos (pixel_size, timing, cores)
- [ ] Sem impacto em performance (Node creation igual)

---

## Tarefa 3: Consolidar Synergy Timers (DRY + Manutencao)

**Objetivo:** Substituir 12 variaveis de timer individuais no `synergy_system.gd` por um Dictionary unificado.

### Contexto

`synergy_system.gd` (585 linhas) declara 12 timers separados:

```gdscript
var _dark_aura_timer: float = 0.0
var _steam_cloud_timer: float = 0.0
var _conductor_timer: float = 0.0
var _tidal_wave_timer: float = 0.0
var _steam_explosion_timer: float = 0.0
var _absolute_zero_timer: float = 0.0
var _abyssal_depths_timer: float = 0.0
var _toxic_fire_timer: float = 0.0
var _shadow_freeze_timer: float = 0.0
var _toxic_shock_timer: float = 0.0
```

Cada tick function repete o mesmo padrao: incrementar timer, checar intervalo, resetar.

### Solucao

```gdscript
var _synergy_timers: Dictionary = {}

const SYNERGY_INTERVALS := {
    "dark_aura": 1.0,
    "steam_cloud": 1.5,
    "conductor": 2.0,
    "tidal_wave": 1.5,
    "steam_explosion": 1.5,
    "absolute_zero": 3.0,
    "abyssal_depths": 2.0,
    "toxic_fire": 1.0,
    "shadow_freeze": 1.5,
    "toxic_shock": 1.5,
}

func _tick_synergy(synergy_id: String, delta: float) -> bool:
    _synergy_timers[synergy_id] = _synergy_timers.get(synergy_id, 0.0) + delta
    if _synergy_timers[synergy_id] >= SYNERGY_INTERVALS.get(synergy_id, 1.0):
        _synergy_timers[synergy_id] = 0.0
        return true
    return false
```

Tambem extrair `_apply_speed_debuff()` (duplicado 4+ vezes):

```gdscript
func _apply_speed_debuff(enemy: Node3D, multiplier: float, duration: float) -> void:
    var original_speed = enemy.speed
    enemy.speed *= multiplier
    get_tree().create_timer(duration).timeout.connect(func():
        if is_instance_valid(enemy):
            enemy.speed = original_speed
    )
```

### Arquivos impactados

| Arquivo | Acao |
|---|---|
| `scripts/autoload/synergy_system.gd` | Refatorar timers e debuffs |

### Impacto estimado

~150 linhas reduzidas. Adicionar nova sinergia passa de ~40 linhas para ~10.

### Criterios de aceite

- [ ] Todas as 12 sinergias passivas funcionam identicamente
- [ ] Timer intervals sao constantes nomeadas
- [ ] Danos de sinergias sao constantes (nao magic numbers)
- [ ] Speed debuffs usam funcao compartilhada
- [ ] Reset limpa todo o dictionary

---

## Tarefa 4: Dividir GameManager (God Object)

**Objetivo:** Extrair subsistemas do `game_manager.gd` (812 linhas, 12+ responsabilidades) em modulos focados.

### Contexto

O GameManager acumula: estado de run, stats do jogador, grade espacial de inimigos, calculo de bonus de itens, timeline de run, registro de inputs, tracking de dano, revive/tombstone, adicao de armas/itens, bonus de reliquias/personagens, progressao de dificuldade.

### Solucao — Extrair 3 modulos prioritarios

**Modulo 1: ItemBonusCalculator** (~130 linhas)
- Extrair `_recalculate_item_bonuses()` (linhas 507-573)
- Mover todas as variaveis de bonus (`speed_mult`, `armor`, `pickup_range_mult`, etc.)
- GameManager chama `ItemBonusCalculator.recalculate()` quando item e adicionado

**Modulo 2: SpatialEnemyGrid** (~80 linhas)
- Extrair `_rebuild_spatial_grid()` e `get_enemies_in_radius()`
- Gerenciar grid internamente com cache por frame
- GameManager e armas consultam `SpatialEnemyGrid.get_enemies_in_radius()`

**Modulo 3: RunTimeline** (~50 linhas)
- Extrair `_add_timeline_event()` e lista de timeline
- Usado por telemetria e replay

### Arquivos impactados

| Arquivo | Acao |
|---|---|
| `scripts/autoload/item_bonus_calculator.gd` | Criar (novo autoload) |
| `scripts/autoload/spatial_enemy_grid.gd` | Criar (novo autoload) |
| `scripts/autoload/run_timeline.gd` | Criar (novo autoload) |
| `scripts/autoload/game_manager.gd` | Remover logica extraida, delegar |
| `project.godot` | Registrar novos autoloads |

### Criterios de aceite

- [ ] GameManager reduzido de 812 para ~550 linhas
- [ ] Nenhuma regressao funcional
- [ ] Autoloads novos registrados no project.godot
- [ ] Armas e inimigos usam SpatialEnemyGrid diretamente

---

## Tarefa 5: Cache de Sprites de Inimigos (Performance)

**Objetivo:** Pre-cachear caminhos de sprites de inimigos no startup em vez de chamar `ResourceLoader.exists()` e `load()` a cada spawn.

### Contexto

`enemy_base.gd` (1103 linhas) executa na `_ready()` de cada inimigo:
- `ResourceLoader.exists(sprite_path)` — acesso ao filesystem
- `load(sprite_path)` — carregamento de recurso
- `to_snake_case()` — conversao de string
- String formatting com `%` operator

Com 500 inimigos na tela reciclando via ObjectPool, isso gera centenas de lookups por minuto.

### Solucao

Criar cache estatico no `_ready()` do jogo:

```gdscript
# Em enemy_base.gd (ou novo EnemySpriteCache)
static var _sprite_cache: Dictionary = {}  # "type_stage" -> Texture2D

static func _get_cached_sprite(enemy_type: String, stage: String) -> Texture2D:
    var key = "%s_%s" % [enemy_type, stage]
    if key in _sprite_cache:
        return _sprite_cache[key]
    # Tenta carregar uma vez e cacheia
    var paths_to_try = [
        "res://assets/sprites/enemies/%s/%s.png" % [stage, enemy_type],
        "res://assets/sprites/enemies/%s.png" % enemy_type,
    ]
    for path in paths_to_try:
        if ResourceLoader.exists(path):
            _sprite_cache[key] = load(path)
            return _sprite_cache[key]
    _sprite_cache[key] = null
    return null
```

### Arquivos impactados

| Arquivo | Acao |
|---|---|
| `scripts/enemies/enemy_base.gd` | Substituir loads por cache lookup |

### Impacto estimado

Elimina ~500 chamadas/minuto ao filesystem em runs com muitos inimigos.

### Criterios de aceite

- [ ] Sprites carregam corretamente para todos os 57 tipos de inimigo
- [ ] Zero chamadas a `ResourceLoader.exists()` apos primeiro spawn de cada tipo
- [ ] Sem aumento de memoria significativo (sprites ja ficam em memoria)

---

## Tarefa 6: Constantes Centralizadas (Manutencao)

**Objetivo:** Extrair magic numbers e listas hardcoded repetidas para constantes nomeadas.

### Contexto

Valores repetidos em multiplos arquivos sem constantes nomeadas:

| Valor | Onde aparece | Quantas vezes |
|---|---|---|
| Lista de stages | game_manager, daily_challenge, save_manager, test_runner | 4+ |
| Cores de UI (`Color(0.12, 0.12, 0.18)`) | bestiary, codex, achievements, character_select | 5+ |
| XP formula (`xp * 1.15 + 3`) | game_manager | 1 (mas magic number) |
| Dificuldade (`game_time / 60.0 * 0.35`) | game_manager | 1 (magic number) |
| FPS values (`[30, 60, 120, 144, 240, 0]`) | save_manager | 1 (hardcoded array) |
| Resolutions | save_manager | 1 (hardcoded array) |
| Synergy damage values (12, 15, 20) | synergy_system | 10+ |
| Synergy radii (2.5, 3.0, 4.0) | synergy_system | 8+ |

### Solucao

Criar `res://scripts/autoload/game_constants.gd`:

```gdscript
class_name GameConstants

# Stages
const ALL_STAGES := ["cemetery", "forest", "farm", "tokyo", "volcano", "ocean", "arena", "space", "castle", "candy"]
const CAMPAIGN_STAGES := ["cemetery", "forest", "tokyo", "volcano", "ocean", "space", "castle"]
const ANOMALY_STAGES := ["farm", "arena", "candy"]

# UI
const COLOR_CARD_BG := Color(0.12, 0.12, 0.18)
const COLOR_CARD_BG_DARK := Color(0.08, 0.08, 0.12)
const COLOR_GOLD := Color(1.0, 0.85, 0.2)
const COLOR_SUBTITLE := Color(0.7, 0.7, 0.8, 0.9)

# Balance
const XP_SCALE_FACTOR := 1.15
const XP_FLAT_BONUS := 3
const DIFFICULTY_TIME_SCALE := 0.35

# Display
const FPS_OPTIONS := [30, 60, 120, 144, 240, 0]
const RESOLUTION_OPTIONS := [
    Vector2i(854, 480), Vector2i(1024, 576), Vector2i(1152, 648),
    Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900),
    Vector2i(1920, 1080), Vector2i(2560, 1440),
]
```

### Arquivos impactados

| Arquivo | Acao |
|---|---|
| `scripts/autoload/game_constants.gd` | Criar (class_name, sem autoload) |
| `scripts/autoload/game_manager.gd` | Usar `GameConstants.ALL_STAGES` etc |
| `scripts/autoload/save_manager.gd` | Usar constantes de display |
| `scripts/autoload/daily_challenge.gd` | Usar `GameConstants.ALL_STAGES` |
| `scripts/autoload/synergy_system.gd` | Usar constantes de dano/raio |
| `scripts/tests/test_runner.gd` | Usar `GameConstants.ALL_STAGES` |

### Criterios de aceite

- [ ] Nenhuma lista de stages hardcoded fora de GameConstants
- [ ] Cores de UI centralizadas
- [ ] Magic numbers de balance nomeados

---

## Tarefa 7: Dividir enemy_base.gd (God Object)

**Objetivo:** Reduzir `enemy_base.gd` (1103 linhas) extraindo subsistemas visuais e comportamentais.

### Contexto

O script acumula: carregamento de sprites, comportamento por fenda, modelo 3D procedural fallback, state machine de comportamento, dano/knockback, death FX, spawn visuals.

### Solucao — Extrair 2 modulos

**Modulo 1: EnemyVisuals** (~200 linhas)
- `_setup_billboard_sprite()` e toda logica de sprite/modelo
- Referenciado por `enemy_base.gd` como child ou composicao

**Modulo 2: EnemyStageBehavior** (~150 linhas)
- Comportamentos especificos de fenda (ocean swimming, volcano fire trail, etc.)
- Mapa de behaviors por stage

### Arquivos impactados

| Arquivo | Acao |
|---|---|
| `scripts/enemies/enemy_visuals.gd` | Criar (novo) |
| `scripts/enemies/enemy_stage_behavior.gd` | Criar (novo) |
| `scripts/enemies/enemy_base.gd` | Delegar para modulos |

### Criterios de aceite

- [ ] enemy_base.gd reduzido de 1103 para ~750 linhas
- [ ] 57 tipos de inimigos funcionam identicamente
- [ ] ObjectPool `_reset_for_reuse()` funciona com composicao

---

## Tarefa 8: Pool para Slash Trail Sprites (Performance)

**Objetivo:** Reutilizar Sprite3D de slash trails via ObjectPool em vez de `Sprite3D.new()` + `queue_free()` a cada ataque.

### Contexto

Armas melee com cooldown < 0.3s criam e destroem dezenas de Sprite3D por segundo para efeitos de slash trail. Cada `Sprite3D.new()` aloca memoria e cada `queue_free()` agenda destruicao.

### Solucao

No `WeaponVFX` (Tarefa 2), implementar pool interno:

```gdscript
static var _slash_pool: Array[Sprite3D] = []
const SLASH_POOL_SIZE := 20

static func _get_slash_sprite() -> Sprite3D:
    for sprite in _slash_pool:
        if not sprite.visible:
            sprite.visible = true
            return sprite
    if _slash_pool.size() < SLASH_POOL_SIZE:
        var sprite = Sprite3D.new()
        # ...setup...
        _slash_pool.append(sprite)
        return sprite
    return _slash_pool[0]  # Reutiliza o mais antigo
```

### Impacto estimado

Elimina ~60 alocacoes/segundo com Katana (cooldown 0.2s, 2 trails por ataque).

### Criterios de aceite

- [ ] Zero alocacoes de Sprite3D durante combate (apos warmup)
- [ ] Pool limitado a 20 sprites (sem memory leak)
- [ ] Efeito visual identico

---

## Tarefa 9: Cache de Nivel de Arma por Sinal (Performance)

**Objetivo:** Substituir lookup de `GameManager.get_weapon_level()` a cada frame por cache atualizado via sinal.

### Contexto

Armas chamam `GameManager.get_weapon_level("katana")` no `_process()` de cada frame. Isso faz um loop O(n) na lista `player_weapons` (Array de Dictionaries) a cada frame, para cada arma ativa.

### Solucao

1. No GameManager, emitir sinal `weapon_level_changed(weapon_id, new_level)` quando arma sobe de nivel
2. Em cada arma, conectar ao sinal e cachear o nivel local:

```gdscript
var _cached_level: int = 1

func _ready():
    GameManager.weapon_level_changed.connect(_on_weapon_level_changed)

func _on_weapon_level_changed(weapon_id: String, new_level: int) -> void:
    if weapon_id == "katana":
        _cached_level = new_level
```

Alternativa mais simples: converter `player_weapons` de `Array[Dictionary]` para `Dictionary[String, int]` para O(1) lookup.

### Impacto estimado

Elimina ~300 iteracoes/segundo (5 armas × 60 FPS × O(n) lookup).

### Criterios de aceite

- [ ] Nivel de arma correto apos level up
- [ ] Sem lookup de Array no `_process()`
- [ ] Funciona com multiplayer (sync de nivel)

---

## Tarefa 10: Dividir HUD e LevelUpScreen (Manutencao)

**Objetivo:** Reduzir `hud.gd` (978 linhas) e `level_up_screen.gd` (875 linhas).

### Contexto

O HUD gerencia: barra de HP do boss, icones de armas, icones de itens, display de sinergias, HP de aliados, minimapa, kill counter, timer, cristais. Tudo num unico script.

### Solucao

**HUD** — extrair:
- `BossHPBarHUD` (barra de HP do boss + nome + fase)
- `WeaponItemHUD` (icones de armas e itens ativos)

**LevelUpScreen** — extrair:
- `UpgradeCardUI` (construcao visual de cada card)
- Manter LevelUpScreen como controlador de selecao

### Arquivos impactados

| Arquivo | Acao |
|---|---|
| `scripts/ui/boss_hp_bar_hud.gd` | Criar (novo) |
| `scripts/ui/weapon_item_hud.gd` | Criar (novo) |
| `scripts/ui/upgrade_card_ui.gd` | Criar (novo) |
| `scripts/ui/hud.gd` | Delegar para sub-componentes |
| `scripts/ui/level_up_screen.gd` | Delegar para UpgradeCardUI |

### Criterios de aceite

- [ ] HUD reduzido para ~500 linhas
- [ ] LevelUpScreen reduzido para ~400 linhas
- [ ] Aparencia e comportamento identicos

---

## Resumo e Priorizacao

| Fase | Tarefas | Tipo | Impacto | Risco |
|---|---|---|---|---|
| **A** | 6, 3 | Constantes + Synergy timers | Alto (manutencao) | Baixo |
| **B** | 1, 2 | UICardBuilder + WeaponVFX | Alto (DRY) | Baixo |
| **C** | 5, 8, 9 | Cache sprites + Pool trails + Cache nivel | Alto (performance) | Medio |
| **D** | 4, 7 | Split GameManager + enemy_base | Alto (arquitetura) | Alto |
| **E** | 10 | Split HUD + LevelUpScreen | Medio (manutencao) | Medio |

### Metricas de sucesso

- [ ] Codigo duplicado reduzido em ~40% (medido por linhas identicas)
- [ ] Nenhum arquivo > 800 linhas (exceto tools de geracao)
- [ ] Zero magic numbers em hot paths
- [ ] Zero `ResourceLoader.exists()` em runtime (apos warmup)
- [ ] Slash trail allocations = 0 durante combate

---

## Dependencias

| Tarefa | Depende de |
|---|---|
| 1 (UICardBuilder) | Nenhuma |
| 2 (WeaponVFX) | Nenhuma |
| 3 (Synergy timers) | Nenhuma |
| 4 (Split GameManager) | 6 (Constantes) |
| 5 (Cache sprites) | Nenhuma |
| 6 (Constantes) | Nenhuma |
| 7 (Split enemy_base) | 5 (Cache sprites) |
| 8 (Pool slash) | 2 (WeaponVFX) |
| 9 (Cache nivel) | Nenhuma |
| 10 (Split HUD) | 1 (UICardBuilder) |
