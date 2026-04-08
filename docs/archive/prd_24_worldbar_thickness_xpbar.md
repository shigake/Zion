# PRD 24 — Barra de HP mais grossa + barra de XP abaixo (world-space)

**Status:** CONCLUIDO
**Prioridade:** média
**Escopo:** `game/scripts/player/player.gd`

---

## Problema

Durante a jogatina, a barra de HP que aparece abaixo do sprite do personagem (world-space 3D)
está com altura de `0.12` — muito fina para ser lida confortavelmente em resolução 1280×720,
especialmente com vários inimigos em tela.

Além disso, não existe nenhuma barra de XP visível no mundo. O jogador não tem feedback visual
imediato de quanto falta para o próximo nível sem olhar para o HUD 2D.

---

## Solução proposta

Duas mudanças cirúrgicas dentro de `_create_world_hp_bar()` em `player.gd`, mais a criação de
`_create_world_xp_bar()` chamada logo depois:

### 1. Barra de HP — 4× mais grossa

**Arquivo:** `game/scripts/player/player.gd`

Alterar somente a constante `bar_height`:

```gdscript
# ANTES
var bar_height = 0.12

# DEPOIS
var bar_height = 0.48   # 4× mais grossa (0.12 × 4)
```

O border e o background já usam `bar_height` como referência, portanto crescem
automaticamente junto com o fill — nenhuma outra linha precisa mudar.

### 2. Barra de XP — mesma grossura, logo abaixo

Adicionar no final de `_create_world_hp_bar()` (ou como função separada chamada em `_ready()`):

```gdscript
func _create_world_xp_bar() -> void:
    var bar_width  : float = 1.6
    var bar_height : float = 0.48   # Mesma grossura da barra de HP
    var gap        : float = 0.06   # Espaço entre HP bar e XP bar
    # bar_y da HP bar = 0.05; base da HP bar = bar_y + bar_height/2
    # Topo da XP bar deve ficar logo abaixo dessa base + gap
    var xp_y : float = 0.05 + bar_height + gap + bar_height / 2.0
    var bar_z : float = 0.5

    # Border (preto)
    var xp_border := MeshInstance3D.new()
    var border_mesh := QuadMesh.new()
    border_mesh.size = Vector2(bar_width + 0.16, bar_height + 0.08)
    xp_border.mesh = border_mesh
    var border_mat := StandardMaterial3D.new()
    border_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.95)
    border_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    border_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    border_mat.no_depth_test = true
    border_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
    border_mat.render_priority = 10
    xp_border.material_override = border_mat
    xp_border.position = Vector3(0, xp_y, bar_z - 0.002)
    add_child(xp_border)

    # Background (cinza escuro)
    _world_xp_bg = MeshInstance3D.new()
    var bg_mesh := QuadMesh.new()
    bg_mesh.size = Vector2(bar_width + 0.06, bar_height + 0.02)
    _world_xp_bg.mesh = bg_mesh
    var bg_mat := StandardMaterial3D.new()
    bg_mat.albedo_color = Color(0.12, 0.10, 0.18, 0.9)
    bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    bg_mat.no_depth_test = true
    bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
    bg_mat.render_priority = 11
    _world_xp_bg.material_override = bg_mat
    _world_xp_bg.position = Vector3(0, xp_y, bar_z - 0.001)
    add_child(_world_xp_bg)

    # Fill (azul/roxo — cor de cristal/XP, consistente com a narrativa)
    _world_xp_bar = MeshInstance3D.new()
    var fill_mesh := QuadMesh.new()
    fill_mesh.size = Vector2(bar_width, bar_height)
    _world_xp_bar.mesh = fill_mesh
    var fill_mat := StandardMaterial3D.new()
    fill_mat.albedo_color = Color(0.45, 0.25, 0.95)   # roxo cristalino
    fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    fill_mat.no_depth_test = true
    fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
    fill_mat.render_priority = 12
    _world_xp_bar.material_override = fill_mat
    _world_xp_bar.position = Vector3(0, xp_y, bar_z)
    add_child(_world_xp_bar)

    # Guardar xp_y para uso no update
    _world_xp_y = xp_y
```

Variáveis de instância a adicionar (perto das outras `_world_hp_*`):

```gdscript
var _world_xp_bar: MeshInstance3D = null
var _world_xp_bg: MeshInstance3D = null
var _world_xp_y: float = 0.0
```

Função de update (chamada em `_physics_process`, ao lado de `_update_world_hp_bar()`):

```gdscript
func _update_world_xp_bar() -> void:
    if not _world_xp_bar:
        return
    var ratio := clampf(
        float(GameManager.player_xp) / float(GameManager.player_xp_to_next),
        0.0, 1.0
    ) if GameManager.player_xp_to_next > 0 else 0.0

    _world_xp_bar.scale.x = ratio
    _world_xp_bar.position.x = -(1.0 - ratio) * 0.8   # Mesma lógica do HP bar
```

---

## Layout resultante (cross-section vertical, world-space)

```
┌─────────────────────────────┐  ← border HP (0.56 de altura)
│ ███████████████░░░░░░░░░░░░ │  ← fill HP (verde/amarelo/vermelho, 0.48)
└─────────────────────────────┘
           (gap 0.06)
┌─────────────────────────────┐  ← border XP (0.56 de altura)
│ ████░░░░░░░░░░░░░░░░░░░░░░ │  ← fill XP (roxo cristalino, 0.48)
└─────────────────────────────┘
```

---

## Cor da barra de XP — justificativa narrativa

A cor roxa (`Color(0.45, 0.25, 0.95)`) remete aos cristais de Zion se reunindo —
a mesma paleta usada na UI de level up, nas partículas de XP e no texto de progressão.
Consistente com o lore: XP = fragmentos de cristal absorvidos pelo Fragmentado.

---

## O que NÃO muda

| Elemento | Status |
|---|---|
| Hitbox e colisão do jogador | Intacto |
| Lógica de dano e cura | Intacto |
| Lógica de XP e level up | Intacto |
| HUD 2D (barra de HP 2D, barra de XP 2D) | Intacto |
| Barra de HP dos inimigos | Intacto |
| Barra de HP do boss | Intacto |
| Animações, dash, armas | Intacto |

---

## Acceptance Criteria

- [ ] Barra de HP world-space visivelmente 4× mais grossa que antes
- [ ] Barra de XP world-space aparece logo abaixo da HP, mesma grossura
- [ ] A barra de XP cresce proporcionalmente ao XP acumulado até o próximo nível
- [ ] Ao subir de nível, a barra de XP zera e começa a encher novamente
- [ ] As duas barras seguem o personagem (billboard FIXED_Y) sem tremer
- [ ] Funciona com todos os 15 Fragmentados
- [ ] Funciona em multiplayer (cada jogador vê suas próprias barras)
- [ ] Não há regressão de performance perceptível (2 MeshInstance3D extras por jogador)
