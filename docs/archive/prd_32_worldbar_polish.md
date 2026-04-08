# PRD 32 — Barras de HP e XP world-space: cores fixas + polish visual

**Status:** concluido
**Prioridade:** média
**Escopo:** `game/scripts/player/player.gd`

---

## Contexto

O jogo já possui duas barras world-space exibidas abaixo do sprite do personagem durante o jogo:

| Barra | Arquivo | Situação atual |
|-------|---------|----------------|
| HP | `player.gd` → `_create_world_hp_bar()` | Verde, mas muda para amarelo (<50%) e vermelho (<25%) |
| XP | `player.gd` → `_create_world_xp_bar()` | **Roxo cristalino** (`Color(0.45, 0.25, 0.95)`) |

Ambas têm tamanho fixo de `1.6 × 0.48` unidades, borda preta e fundo escuro. O sistema funciona corretamente — este PRD é exclusivamente de **cor e polish visual**.

---

## Problema

1. **HP bar muda de cor conforme o HP** — o jogador vê a barra ficar amarela e vermelha, o que pode ser confuso ou indesejável do ponto de vista de design. O pedido é que ela seja **verde fixo**.
2. **XP bar é roxa** — a cor deve ser **azul** para diferenciar claramente das duas barras e facilitar a leitura rápida durante o jogo.
3. **Nenhuma barra tem polish visual** — são retângulos lisos sem glow, gradiente ou animação suave, o que as faz parecer placeholder.

---

## Solução

### 1. HP bar — Verde fixo

Remover a lógica de mudança de cor em `_update_world_hp_bar()`:

```gdscript
# REMOVER este bloco de _update_world_hp_bar():
var mat = _world_hp_bar.material_override
if mat:
    if ratio > 0.5:
        mat.albedo_color = Color(0.2, 0.85, 0.2)
    elif ratio > 0.25:
        mat.albedo_color = Color(0.9, 0.8, 0.1)
    else:
        mat.albedo_color = Color(0.9, 0.15, 0.1)
```

A cor do material já é definida em `_create_world_hp_bar()` como `Color(0.2, 0.85, 0.2)` (verde). Sem o bloco acima, ela permanece verde independente do HP.

### 2. XP bar — Azul

Alterar em `_create_world_xp_bar()`:

```gdscript
# ANTES
fill_mat.albedo_color = Color(0.45, 0.25, 0.95)   # roxo

# DEPOIS
fill_mat.albedo_color = Color(0.15, 0.55, 0.95)   # azul cristalino
```

O fundo escuro da XP bar (`Color(0.12, 0.10, 0.18)`) também deve mudar para combinar com o azul:

```gdscript
# ANTES
bg_mat.albedo_color = Color(0.12, 0.10, 0.18, 0.9)  # roxo escuro

# DEPOIS
bg_mat.albedo_color = Color(0.08, 0.12, 0.22, 0.9)  # azul muito escuro
```

---

## Polish visual — 4 melhorias

### 2.1 Glow/emission nas barras

Habilitar `emission_enabled` nos materiais de fill para que as barras brilhem levemente, destacando-se em cenários escuros:

```gdscript
# HP bar
fill_mat.emission_enabled = true
fill_mat.emission = Color(0.1, 0.6, 0.1)    # verde suave
fill_mat.emission_energy_multiplier = 0.6

# XP bar
fill_mat.emission_enabled = true
fill_mat.emission = Color(0.05, 0.3, 0.7)   # azul suave
fill_mat.emission_energy_multiplier = 0.5
```

### 2.2 Highlight interno (efeito glossy)

Adicionar uma faixa clara e fina no topo de cada barra para simular reflexo/brilho 3D. É um `MeshInstance3D` extra com altura ~20% da barra, posicionado no terço superior do fill, com material branco semi-transparente:

```gdscript
# Highlight HP bar
var hp_highlight := MeshInstance3D.new()
var hl_mesh := QuadMesh.new()
hl_mesh.size = Vector2(bar_width - 0.1, bar_height * 0.22)
hp_highlight.mesh = hl_mesh
var hl_mat := StandardMaterial3D.new()
hl_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.18)
hl_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
hl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
hl_mat.no_depth_test = true
hl_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
hl_mat.render_priority = 13
hp_highlight.position = Vector3(0, bar_y + bar_height * 0.28, bar_z + 0.001)
add_child(hp_highlight)
```

Repetir para a XP bar com o `xp_y` correspondente.

### 2.3 Animação suave de preenchimento (lerp)

Em vez de setar `scale.x` instantaneamente, interpolar suavemente usando `lerp` a cada frame. Adicionar variáveis de instância para o valor alvo:

```gdscript
# Novas variáveis de instância
var _hp_bar_target_ratio: float = 1.0
var _xp_bar_target_ratio: float = 0.0
const BAR_LERP_SPEED: float = 8.0   # unidades/segundo — rápido mas suave
```

Em `_update_world_hp_bar()`:
```gdscript
_hp_bar_target_ratio = ratio
var current := _world_hp_bar.scale.x
var new_scale := lerpf(current, _hp_bar_target_ratio, BAR_LERP_SPEED * delta)
_world_hp_bar.scale.x = new_scale
_world_hp_bar.position.x = -(1.0 - new_scale) * 0.8
```

Em `_update_world_xp_bar()`, mesma lógica com `_xp_bar_target_ratio`.

**Atenção:** passar `delta` para ambos os métodos — atualmente `_physics_process(delta)` chama sem delta. Corrigir a assinatura:

```gdscript
func _update_world_hp_bar(delta: float) -> void: ...
func _update_world_xp_bar(delta: float) -> void: ...

func _physics_process(delta: float) -> void:
    _update_world_hp_bar(delta)
    _update_world_xp_bar(delta)
```

### 2.4 Borda colorida (em vez de preta pura)

Substituir a borda preta opaca por uma borda colorida com alpha para integrar melhor visualmente:

```gdscript
# HP border
border_mat.albedo_color = Color(0.05, 0.35, 0.05, 0.95)  # verde muito escuro

# XP border
border_mat.albedo_color = Color(0.03, 0.10, 0.30, 0.95)  # azul muito escuro
```

---

## Layout resultante

```
Sprite do jogador
       │
       ▼
┌─────────────────────────────┐  ← border verde-escuro
│▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░│  ← fill HP verde (#33D933) + glow
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │  ← highlight glossy branco (faixa topo)
└─────────────────────────────┘
        (gap 0.06)
┌─────────────────────────────┐  ← border azul-escuro
│▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░│  ← fill XP azul (#268CF2) + glow
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │  ← highlight glossy branco (faixa topo)
└─────────────────────────────┘
```

---

## Arquivos envolvidos

| Arquivo | Mudança |
|---------|---------|
| `game/scripts/player/player.gd` | Remover mudança de cor do HP; alterar cor XP para azul; adicionar emission, highlight e lerp |

**Apenas 1 arquivo.** Nenhuma cena `.tscn`, nenhum autoload, nenhum HUD 2D precisam ser tocados.

---

## O que NÃO muda

| Elemento | Status |
|----------|--------|
| Tamanho das barras (1.6 × 0.48) | Intacto |
| Posição das barras (abaixo do sprite) | Intacto |
| Billboard FIXED_Y | Intacto |
| Lógica de HP e XP | Intacto |
| Barra de HP dos inimigos | Intacto |
| Barra de HP do boss | Intacto |
| HUD 2D | Intacto |
| Multiplayer (cada jogador tem suas barras) | Intacto |

---

## Critérios de aceite

- [ ] HP bar permanece **verde** independente do HP atual (sem amarelo, sem vermelho)
- [ ] XP bar é **azul** (não roxa)
- [ ] Ambas as barras têm brilho/glow visível — destacam-se em cenários escuros
- [ ] Faixa de highlight glossy visível no topo de cada barra
- [ ] Preenchimento das barras anima suavemente (sem saltos bruscos)
- [ ] Barras ficam bonitas e legíveis em todos os 10 estágios (fundos claros e escuros)
- [ ] Funciona com todos os 15 Fragmentados
- [ ] Sem regressão de performance (cada jogador tem 2 MeshInstance3D extras de highlight)
- [ ] Multiplayer: cada jogador mantém suas próprias barras sem interferência

---

## Fora de escopo

- Ícone de coração/estrela ao lado das barras (feature separada)
- Barra de HP mantendo indicador de dano recente (damage ghost — feature separada)
- Animação de pulse quando XP está próximo de encher (feature separada)
- Mudança de cor do HP quando crítico — intencionalmente removida neste PRD
