# PRD — Bugfix de Projéteis (Escala e Rotação)

> Corrigir o bug onde balas ficam gigantes após múltiplos disparos e implementar rotação correta do sprite para apontar na direção de viagem.

---

## Bug 1: Balas Crescendo de Tamanho (Escala Acumulada)

**Objetivo:** Impedir que os sprites de projéteis cresçam progressivamente a cada reuso do ObjectPool.

### Causa raiz identificada

O script `res://scripts/weapons/bullet.gd` tem uma função `_spawn_muzzle_flash()` (linha 55) que é chamada em dois momentos:

1. `_ready()` (linha 21) — quando a bala é criada pela primeira vez
2. `_reset_for_reuse()` (linha 123) — quando a bala é reciclada pelo ObjectPool

O problema está nessa função:

```gdscript
func _spawn_muzzle_flash() -> void:
    if not _sprite:
        return
    # Brief scale-up flash effect on spawn usando o sprite
    var original_scale = _sprite.scale        # ← AQUI: captura a escala ATUAL
    _sprite.scale = original_scale * 2.5      # ← Infla 2.5x
    var tween = create_tween()
    tween.tween_property(_sprite, "scale", original_scale, 0.1)  # ← Volta para o "original"
```

**O bug:** Se o Tween de 0.1s não completar antes da bala ser devolvida ao pool (ex: a bala acerta um inimigo em <0.1s), o `_sprite.scale` fica inflado em 2.5x. Na próxima reciclagem, `original_scale` captura `2.5x`, infla para `6.25x`, e assim por diante. A escala **acumula exponencialmente**:

```
Ciclo 1: scale = 1.0 → flash 2.5 → tween volta para 1.0 (se completar)
Ciclo 2: scale = 2.5 (tween não completou) → flash 6.25 → tween volta para 2.5
Ciclo 3: scale = 6.25 → flash 15.625 → ...
```

### Armas afetadas

7 armas usam `res://scenes/weapons/bullet.tscn` e herdam esse bug:

| Arma | Script | preload bullet.tscn |
|---|---|---|
| Metralhadora | `machinegun.gd:6` | ✅ |
| Pistola Dupla | `dual_pistol.gd:6` | ✅ |
| Shuriken | `shuriken.gd:7` | ✅ |
| Magic Book | `magic_book.gd:12` | ✅ |
| Drone | `drone.gd:10` | ✅ |
| Crossbow | `crossbow.gd:6` | ✅ |
| Boomerang | `boomerang.gd:6` | ✅ |

A Metralhadora e a Pistola Dupla são as mais afetadas por terem `cooldown < 0.2s`, produzindo centenas de balas que reciclam muito rápido — o Tween de 0.1s frequentemente não completa.

### Solução

Na `_reset_for_reuse()` (linha 114) e na `_spawn_muzzle_flash()`, **forçar a escala base antes de capturar o "original"**:

```gdscript
const BASE_SPRITE_SCALE := Vector3(1, 1, 1)

func _reset_for_reuse() -> void:
    _returning = false
    monitoring = true
    timer = 0.0
    _trail_counter = 0
    if not _sprite:
        _sprite = get_node_or_null("ProjectileSprite")
    # ← NOVO: Forçar escala base antes de qualquer efeito
    if _sprite:
        _sprite.scale = BASE_SPRITE_SCALE
    _update_sprite_rotation()
    _spawn_muzzle_flash()

func _spawn_muzzle_flash() -> void:
    if not _sprite:
        return
    # ← CORREÇÃO: Usar constante em vez da escala atual
    _sprite.scale = BASE_SPRITE_SCALE * 2.5
    var tween = create_tween()
    tween.tween_property(_sprite, "scale", BASE_SPRITE_SCALE, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
```

### Arquivos impactados

| Arquivo | Ação |
|---|---|
| `scripts/weapons/bullet.gd` | Corrigir `_spawn_muzzle_flash()` e `_reset_for_reuse()` |

### Critérios de aceite

- [ ] Balas permanecem no tamanho `pixel_size = 0.04` após centenas de reciclagens
- [ ] Muzzle flash visual ainda funciona (2.5x → 1x em 0.1s)
- [ ] Funciona com Metralhadora (cooldown 0.15s, cenário de pior caso)
- [ ] Sem regressão em Shuriken, Crossbow, Boomerang, etc.

---

## Bug 2: Sprite da Bala Não Aponta na Direção de Viagem

**Objetivo:** Garantir que a ponta do sprite da bala (desenhada apontando para a **direita** no PNG) aponte corretamente na direção do inimigo.

### Contexto

O sprite `res://assets/sprites/projectiles/bullet.png` foi desenhado na **horizontal**, com a **ponta para a direita** (eixo +X da imagem).

No `bullet.gd`, o setup do sprite (linha 23) faz:

```gdscript
sprite.rotation.x = -PI / 2.0    # Deita no plano XZ (correto para top-down)
```

E a rotação direcional (linha 64) faz:

```gdscript
func _update_sprite_rotation() -> void:
    var angle = atan2(direction.x, direction.z)    # ← Eixo errado?
    _sprite.rotation.z = angle
```

### Problema

A fórmula `atan2(direction.x, direction.z)` calcula o ângulo no plano XZ, mas a orientação inicial do sprite (ponta para a direita = +X da imagem) pode não corresponder ao ângulo 0 de `atan2`. Dependendo da convenção do Sprite3D depois do `rotation.x = -PI/2`:

- Se o sprite foi deitado com `rotation.x = -PI/2`, o eixo "frente" da imagem (+X) mapeia para um eixo diferente no mundo 3D
- O resultado é que a bala pode apontar 90° errado, ou apontar para trás

### Solução

A fórmula correta depende de como o Sprite3D foi rotacionado. Com `rotation.x = -PI/2`:
- O eixo +X da imagem (ponta da bala) mapeia para +X do mundo
- O eixo +Y da imagem mapeia para +Z do mundo

Portanto, o ângulo correto no plano XZ com a ponta (+X) como referência é:

```gdscript
func _update_sprite_rotation() -> void:
    if not _sprite:
        return
    # Com rotation.x = -PI/2, o eixo Z local do sprite é o "up" 
    # da imagem no plano XZ. A ponta está em +X da imagem.
    # atan2(z, x) dá o ângulo a partir do eixo +X no plano XZ.
    var angle = atan2(-direction.z, direction.x)
    _sprite.rotation.z = angle
```

> **NOTA:** A fórmula exata pode precisar de ajuste empírico (offset de ±PI/2) dependendo do resultado visual. Recomenda-se testar com a Metralhadora atirando em todas as direções (cima, baixo, esquerda, direita, diagonais) e verificar que a ponta do sprite aponta corretamente para cada uma.

### Verificação visual recomendada

Teste com 8 direções:

| Direção | direction | Sprite deve apontar |
|---|---|---|
| Direita (+X) | `(1, 0, 0)` | Ponta → direita |
| Esquerda (-X) | `(-1, 0, 0)` | Ponta → esquerda |
| Cima (-Z, em top-down) | `(0, 0, -1)` | Ponta → cima |
| Baixo (+Z) | `(0, 0, 1)` | Ponta → baixo |
| Diagonal NE | `(1, 0, -1)` | Ponta → 45° NE |
| Diagonal SE | `(1, 0, 1)` | Ponta → 45° SE |
| Diagonal NW | `(-1, 0, -1)` | Ponta → 45° NW |
| Diagonal SW | `(-1, 0, 1)` | Ponta → 45° SW |

### Outros projéteis que precisam da mesma correção

| Script | Tem rotação direcional? | Ação |
|---|---|---|
| `staff_projectile.gd` | Verificar | Aplicar mesma fórmula se tiver sprite direcional |
| `rocket.gd` | Verificar | Foguete da Bazuca — sprite horizontal |
| `elven_bow_arrow.gd` | Verificar | Flecha do arco élfico — definitivamente direcional |
| `ice_staff_projectile.gd` | Verificar | Projétil de gelo |
| `crossbow.gd` | Usa `bullet.tscn` | Herda a correção do bullet.gd |

### Arquivos impactados

| Arquivo | Ação |
|---|---|
| `scripts/weapons/bullet.gd` | Corrigir `_update_sprite_rotation()` |
| `scripts/weapons/elven_bow_arrow.gd` | Verificar e aplicar mesma fórmula |
| `scripts/weapons/rocket.gd` | Verificar e aplicar mesma fórmula |
| `scripts/weapons/staff_projectile.gd` | Verificar e aplicar mesma fórmula |
| `scripts/weapons/ice_staff_projectile.gd` | Verificar e aplicar mesma fórmula |

### Critérios de aceite

- [ ] Ponta da bala aponta na direção de viagem em todas as 8 direções
- [ ] Funciona com Metralhadora, Pistola Dupla, Crossbow, Shuriken
- [ ] Flecha do Arco Élfico e Foguete da Bazuca também apontam corretamente
- [ ] Sem rotação "jittery" durante o voo (ângulo estável se `direction` não muda)

---

## Bug 3: Sprite Duplicado a Cada Reciclagem

**Objetivo:** Evitar que novos nós `ProjectileSprite` sejam criados a cada reciclagem do pool.

### Contexto

A função `_setup_billboard_sprite()` (linha 23 do `bullet.gd`) é chamada em `_ready()` — que roda tanto na primeira instanciação quanto em cada reuso do pool (Godot emite `_ready()` novamente quando o nó é re-added à árvore). Ela **sempre cria um novo Sprite3D** sem verificar se já existe um:

```gdscript
func _setup_billboard_sprite() -> void:
    var sprite_path = "res://assets/sprites/projectiles/bullet.png"
    if ResourceLoader.exists(sprite_path):
        # ...
        var sprite = Sprite3D.new()        # ← Cria novo a cada _ready()
        # ...
        add_child(sprite)                   # ← Acumula sprites filhos
```

Após N reciclagens, a bala terá N+1 sprites empilhados, causando:
- Overheads de draw calls
- Visual incorreto (sprites sobrepostos = mais opaco/brilhante)

### Solução

Adicionar guard no início de `_setup_billboard_sprite()`:

```gdscript
func _setup_billboard_sprite() -> void:
    # Não recria se já tem sprite do pool
    if _sprite and is_instance_valid(_sprite):
        _update_sprite_rotation()
        return
    # Tenta encontrar sprite existente do pool
    _sprite = get_node_or_null("ProjectileSprite")
    if _sprite:
        _update_sprite_rotation()
        return
    # ...cria novo apenas se realmente não existe...
```

### Critérios de aceite

- [ ] Após 100 reciclagens, a bala continua com exatamente 1 Sprite3D filho
- [ ] Sem aumento progressivo de draw calls ou memória

---

## Dependências

| Sistema | Bugs |
|---|---|
| `bullet.gd` (projétil genérico) | 1, 2, 3 |
| `ObjectPool` (autoload) | 1, 3 (ciclo de reciclagem) |
| Armas ranged (7 scripts) | 1, 2 (usam bullet.tscn) |
| Armas com projéteis próprios (4 scripts) | 2 (rotação direcional) |

## Ordem de implementação

| Fase | Bugs | Descrição |
|---|---|---|
| A | 1 + 3 | Escala + duplicação (ambos no mesmo arquivo, mesmas funções) |
| B | 2 | Rotação direcional (requer teste visual em 8 direções) |

## Prioridade

**Alta** — A escala acumulada é visualmente óbvio e afeta 7 armas ranged. Piora com armas rápidas (Metralhadora, Pistola Dupla) que são as mais populares. O bug de rotação é cosmético mas contribui para o polimento geral.
