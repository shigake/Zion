# PRD 45 — Ragdoll de morte dos inimigos

**Status:** pendente  
**Prioridade:** média  
**Escopo:** `enemy_base.gd`, `game_constants.gd`  
**Tipo:** game feel / feedback visual  

---

## Problema

Quando um inimigo morre, o sprite simplesmente pisca branco, encolhe e desaparece em ~0,3s. A animação atual comunica que o inimigo morreu, mas não comunica *força* — não há sensação de impacto, direção, ou peso. Em survivors de qualidade (Vampire Survivors, Brotato, Nova Drift), a morte de inimigos é visceralmente satisfatória. No Zion, é silenciosa demais.

Adicionalmente, o sistema atual ignora completamente a direção do golpe que matou o inimigo. O sprite simplesmente escala e faz fade no lugar onde estava — não há nenhum voo, nenhuma rotação caótica, nenhum senso de "fui atingido *de lá*".

---

## Objetivo

Adicionar uma animação de morte estilo ragdoll falsa (physics-free) onde o inimigo:

1. Voa na **direção oposta ao golpe final** com velocidade proporcional ao overkill
2. Roda em torno do eixo Z de forma caótica durante o voo
3. Faz fade-out gradual enquanto voa
4. Desaparece após ~0,35s (mesma duração atual — não atrasa gameplay)

Tudo implementado com **Tween** (sem RigidBody3D, sem física real) — zero impacto em performance.

---

## Causa raiz

### Problema 1 — Direção do golpe não é rastreada
Em `take_damage()` (linha ~708), o knockback é calculado com:
```gdscript
var kb_dir = (global_position - target.global_position).normalized()
knockback_velocity = kb_dir * 3.5
```
Essa direção existe no momento do hit, mas **não é armazenada** para uso em `_die()`. Quando `_die()` é chamado (possivelmente no frame seguinte via `call_deferred`), a informação de qual direção levou o golpe final está perdida.

### Problema 2 — Animação de morte ignora posição/direção
O código atual em `_die()` (linha ~844):
```gdscript
var death_tween = create_tween()
death_tween.set_parallel(true)
death_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.3)
death_tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.15)
death_tween.chain().tween_property(sprite, "scale", sprite.scale * 0.1, 0.15)
death_tween.chain().tween_callback(queue_free)
```
O sprite nunca se move de `position`. Não há translação, não há rotação. O efeito é genérico e não comunica impacto.

### Problema 3 — `visible = false` logo no início de `_die()`
Na linha 777, `visible = false` é chamado **antes** da animação de morte rodar. O sprite fica invisível antes de iniciar qualquer tween — exceto para o nó `EnemySprite` que tem seu próprio ramo de código. O código de animação roda, mas visualmente o inimigo já sumiu. Isso é inconsistente.

---

## Solução

### 1. Rastrear direção do último hit

Em `enemy_base.gd`, adicionar variável de instância:
```gdscript
var _last_hit_direction: Vector3 = Vector3.ZERO
```

Em `take_damage()`, logo após calcular `kb_dir`:
```gdscript
_last_hit_direction = kb_dir  # Guarda direção para ragdoll de morte
```

### 2. Nova função `_play_ragdoll_death(sprite)`

Extrair a lógica de animação de morte do sprite para uma função dedicada:

```gdscript
func _play_ragdoll_death(sprite: Node3D) -> void:
	# Direção de voo: oposta ao golpe (se não houve hit direction, usa Y+)
	var fly_dir := -_last_hit_direction if _last_hit_direction.length() > 0.01 else Vector3(randf_range(-1,1), 1, 0).normalized()
	fly_dir.y = absf(fly_dir.y) + 0.4  # Sempre tem componente para cima
	fly_dir = fly_dir.normalized()
	
	var fly_dist := randf_range(GameConstants.RAGDOLL_FLY_MIN, GameConstants.RAGDOLL_FLY_MAX)
	var target_pos := sprite.position + fly_dir * fly_dist
	
	# Rotação caótica no eixo Z (2D billboard — só Z faz sentido)
	var spin_sign := 1.0 if randf() > 0.5 else -1.0
	var spin_amount := spin_sign * randf_range(GameConstants.RAGDOLL_SPIN_MIN, GameConstants.RAGDOLL_SPIN_MAX)
	var target_rot := sprite.rotation + Vector3(0, 0, spin_amount)
	
	var duration := GameConstants.RAGDOLL_DURATION
	
	var tween := create_tween()
	tween.set_parallel(true)
	# Voo: ease out (desacelera no final como se a inercia fosse diminuindo)
	tween.tween_property(sprite, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Rotação: linear (não desacelera — o corpo continua girando)
	tween.tween_property(sprite, "rotation", target_rot, duration).set_trans(Tween.TRANS_LINEAR)
	# Fade: começa depois de 30% do tempo (voa um pouco antes de sumir)
	tween.tween_property(sprite, "modulate:a", 0.0, duration * 0.7).set_delay(duration * 0.3)
	# Escala: leve stretch na direção do voo (squash-stretch)
	tween.tween_property(sprite, "scale", sprite.scale * Vector3(0.7, 1.3, 1.0), duration * 0.1)
	tween.chain().tween_property(sprite, "scale", sprite.scale * Vector3(0.4, 0.4, 1.0), duration * 0.9)
	# Cleanup
	tween.chain().tween_callback(queue_free)
```

### 3. Remover `visible = false` prematuro

Em `_die()`, mover `visible = false` para **depois** do branch de verificação de sprite. O body node (com colisão) continua com `monitoring = false`, mas o visual fica ativo até o tween terminar.

```gdscript
# ANTES (linha 777):
visible = false  # ← remove daqui

# DEPOIS — apenas o hitbox e física são desativados de imediato:
set_physics_process(false)
set_process(false)
if hitbox:
    hitbox.set_deferred("monitoring", false)
    hitbox.set_deferred("monitorable", false)
collision_layer = 0
collision_mask = 0
# visible permanece true até o tween de ragdoll terminar
```

### 4. Chamar `_play_ragdoll_death` no lugar da animação antiga

```gdscript
var sprite = get_node_or_null("EnemySprite")
if sprite:
    sprite.modulate = Color(10, 10, 10)  # Flash branco mantido
    await get_tree().process_frame       # 1 frame com flash
    await get_tree().process_frame
    sprite.modulate = Color(1, 1, 1, 1)  # Volta ao normal antes de voar
    _play_ragdoll_death(sprite)
    return
```

### 5. Constantes em `game_constants.gd`

```gdscript
# --- Ragdoll Death ---
const RAGDOLL_DURATION := 0.35          # Duração total da animação (s)
const RAGDOLL_FLY_MIN := 0.4            # Distância mínima de voo (unidades 3D)
const RAGDOLL_FLY_MAX := 1.2            # Distância máxima de voo
const RAGDOLL_SPIN_MIN := 1.2           # Rotação mínima em radianos (~70°)
const RAGDOLL_SPIN_MAX := 3.5           # Rotação máxima em radianos (~200°)
const RAGDOLL_BOSS_SCALE := 1.5         # Multiplica fly_dist e spin para bosses
```

---

## Casos especiais

### Bosses
Bosses têm seu próprio SFX de morte (`boss_death`) e bloom spike — esses permanecem intactos. O ragdoll é aplicado normalmente, mas com `RAGDOLL_BOSS_SCALE` multiplicando a distância de voo e o spin. Resultado: quando o boss morre, o sprite voa mais longe e roda mais — coerente com o peso narrativo do momento.

O freeze de morte de boss (PRD 44) ocorre **antes** do ragdoll — quando o freeze termina, `_die()` é chamado normalmente e o ragdoll se inicia.

### Elite enemies (escala > 1.2)
Inimigos elite já têm escala maior. O `fly_dir` é calculado sobre a `position` local do sprite, então o voo escala proporcionalmente — nenhum ajuste necessário.

### Inimigos sem EnemySprite (path alternativo)
O branch `if _animator:` permanece intacto. Se o inimigo usa `_animator` em vez de `EnemySprite`, a animação de morte do animator é executada normalmente. O ragdoll é exclusivo para sprites billboard.

### Reduced motion (acessibilidade)
Se `AccessibilityManager.reduced_motion` estiver ativo:
- `fly_dist` é reduzido para 0.15 (movimento mínimo)
- `spin_amount` é zerado (sem rotação)
- A animação ainda ocorre (fade normal), mas sem movimento brusco

```gdscript
if AccessibilityManager.reduced_motion:
    fly_dist *= 0.12
    spin_amount = 0.0
```

### Pool de ObjectPool
Inimigos reciclados via ObjectPool têm `_last_hit_direction` resetado em `_reset()` (se existir essa função na subclasse). Adicionar `_last_hit_direction = Vector3.ZERO` ao reset padrão.

---

## Performance

| Aspecto | Impacto |
|---|---|
| Tween por morte | Idêntico ao atual — já havia 1 Tween por morte |
| Propriedades animadas | +2 (`position`, `rotation`) vs atual (+0) |
| RigidBody / física | Nenhuma — tudo é interpolação matemática |
| Nós extras | Nenhum — usa o `EnemySprite` existente |
| FPS | Negligível — Tweens são processados em lote pelo motor |

O ragdoll **não aumenta** o custo em relação à animação atual. Apenas adiciona propriedades ao Tween existente.

**Throttle existente permanece:** se FPS < 25, já há `randf() < 0.4` para partículas. O ragdoll sempre roda (é visual direto, não partícula) — mas sua duração de 0.35s garante que mesmo com lag o sprite desapareça antes de causar confusão.

---

## Arquivos afetados

| Arquivo | Mudança |
|---|---|
| `game/scripts/enemies/enemy_base.gd` | +1 variável, modificar `take_damage()`, modificar `_die()`, +1 função `_play_ragdoll_death()` |
| `game/scripts/autoload/game_constants.gd` | +5 constantes (seção RAGDOLL DEATH) |

**Fora do escopo:**
- Cenas `.tscn` — nenhuma alteração
- Bosses específicos (`boss_generic.gd`, etc.) — herdam automaticamente
- Sprites ou assets — nenhum novo asset necessário
- Balanceamento de dano/HP — sem alteração

---

## Critérios de aceitação

- [ ] Inimigo ao morrer voa na direção oposta ao jogador que deu o golpe final
- [ ] Sprite roda entre 70° e 200° durante o voo
- [ ] Fade ocorre nos últimos 70% da animação (não imediatamente)
- [ ] Duração total ≤ 0.4s (não atrapalha ritmo do jogo)
- [ ] Com `reduced_motion` ativo: sem rotação, deslocamento < 0.2 unidades
- [ ] Bosses voam mais longe e giram mais que inimigos comuns
- [ ] Sem erros de `is_inside_tree()` após `queue_free`
- [ ] FPS estável em stress test com 200 inimigos morrendo simultaneamente
