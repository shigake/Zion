# PRD 26 — Ícones de HUD maiores (4×) e hit numbers maiores (10×)

**Status:** pendente  
**Prioridade:** alta  
**Impacto:** visual (zero impacto em gameplay, balance ou rede)

---

## Problema

Dois elementos visuais críticos do feedback de gameplay estão pequenos demais para serem lidos com conforto durante o combate:

1. **Ícones de armas e itens no HUD** — atualmente `32×32 px`. Em telas 1280×720 com movimento e partículas, o jogador mal consegue identificar qual arma/item está equipado.

2. **Números de dano (hit numbers)** — `font_size 48` (normal) e `64` (crítico) em `Label3D`. Durante combates densos com múltiplos inimigos, os números somem visualmente no ruído de tela. O feedback de dano é fundamental para o loop de satisfação do roguelite.

---

## Objetivo

- Aumentar os ícones de HUD em **4×** para facilitar leitura instantânea do loadout.
- Aumentar os hit numbers em **10×** para que o dano seja legível, impactante e satisfatório — como em Vampire Survivors, Hades e outros roguelites de referência.
- **Nenhuma alteração** em gameplay, hitbox, balance, rede ou lógica de dano.

---

## Diagnóstico técnico

### HUD Icons

**Arquivo:** `game/scripts/ui/hud.gd`  
Funções: `_update_weapon_icons()` (linhas 436–497) e `_update_item_icons()` (linhas 501–555)

Ambas as funções criam `PanelContainer` + `TextureRect` + `Label` (badge de nível) por ícone.
Não há constante central — os valores estão hardcoded nas duas funções.

| Propriedade | Valor atual | Valor alvo (4×) |
|---|---|---|
| `PanelContainer.custom_minimum_size` | `Vector2(32, 32)` | `Vector2(128, 128)` |
| `TextureRect.custom_minimum_size` | `Vector2(28, 28)` | `Vector2(112, 112)` |
| `Border width` | `1 px` | `2 px` |
| `Corner radius` | `4 px` | `8 px` |
| `Level badge font_size` | `9` | `18` |
| `Level badge offset_left` | `-12` | `-24` |
| `Level badge offset_top` | `-14` | `-24` |
| `HBox separation` | `4 px` | `8 px` |

O refresh de 5×/seg com hash check permanece intacto — só os valores numéricos mudam.

### Hit Numbers

**Arquivo principal:** `game/scripts/enemies/enemy_base.gd` (linhas 661–687)  
**Arquivo de classe:** `game/scripts/effects/damage_number.gd`  
**Pool:** `game/scripts/effects/particle_factory.gd`

Os valores reais em gameplay vêm de `enemy_base.gd`, que sobrescreve os defaults de `damage_number.gd`.
Para aumentar 10×, há duas alavancas disponíveis:

**Opção A — aumentar `font_size` (impacto direto):**

| Propriedade | Valor atual | Valor alvo (10×) |
|---|---|---|
| `font_size` (normal) | `48` | `480` |
| `font_size` (crítico) | `64` | `640` |
| `outline_size` | `10` | `30` |

> ⚠️ **Nota de implementação:** `Label3D` usa `pixel_size` (padrão `0.01`) para converter pixels de fonte em metros no mundo 3D. Com `font_size 480` e `pixel_size 0.01`, o número terá `480 × 0.01 = 4.8 m` de altura — o que pode cobrir boa parte da tela dependendo da distância da câmera. Se o resultado visual for excessivo, ajustar também `pixel_size` para `0.02–0.04` e usar `font_size` menor para chegar ao mesmo tamanho visual sem degradar a qualidade de renderização do texto.

**Opção B — aumentar `pixel_size` do Label3D (recomendada como ajuste fino):**  
Se `font_size 480` gerar texto pixelado ou cobrir demais, usar `font_size 120` + `pixel_size 0.04` produz resultado idêntico com fonte mais nítida.

**Decisão de implementação:** testar Opção A primeiro. Se cobrir demais ou pixelar, ajustar com Opção B. O PRD aceita ambas, desde que o resultado visual seja ~10× maior que o atual.

**Velocidade e lifetime** — crescem proporcionalmente para o número não sair de quadro muito rápido:

| Propriedade | Valor atual | Valor alvo |
|---|---|---|
| `velocity.y` (dano) | `3.0 m/s` | `5.0 m/s` |
| `lifetime` (dano) | `0.8 s` | `1.2 s` |
| `position offset Y` | `1.2` | `1.8` (spawn mais alto p/ não colidir com a barra HP) |

---

## Escopo — o que muda

### `game/scripts/ui/hud.gd`

Em `_update_weapon_icons()` e `_update_item_icons()`:

```gdscript
# ANTES (ambas as funções, weapon e item)
panel.custom_minimum_size = Vector2(32, 32)
tex_rect.custom_minimum_size = Vector2(28, 28)
style.set_border_width_all(1)
style.set_corner_radius_all(4)
lbl.add_theme_font_size_override("font_size", 9)
lbl.offset_left = -12
lbl.offset_top = -14

# DEPOIS
panel.custom_minimum_size = Vector2(128, 128)
tex_rect.custom_minimum_size = Vector2(112, 112)
style.set_border_width_all(2)
style.set_corner_radius_all(8)
lbl.add_theme_font_size_override("font_size", 18)
lbl.offset_left = -24
lbl.offset_top = -24
```

Em `_ready()` ou onde o `HBoxContainer` de separação é configurado:

```gdscript
# ANTES
weapon_container.add_theme_constant_override("separation", 4)
item_container.add_theme_constant_override("separation", 4)

# DEPOIS
weapon_container.add_theme_constant_override("separation", 8)
item_container.add_theme_constant_override("separation", 8)
```

### `game/scripts/enemies/enemy_base.gd`

Na seção de spawn de damage number (linhas ~677–680):

```gdscript
# ANTES
dmg_label.font_size = 64 if is_crit else 48
dmg_label.outline_size = 10

# DEPOIS
dmg_label.font_size = 640 if is_crit else 480
dmg_label.outline_size = 30
```

E no posicionamento:

```gdscript
# ANTES
dmg_label.position = global_position + Vector3(randf_range(-0.3, 0.3), 1.2, 0)

# DEPOIS
dmg_label.position = global_position + Vector3(randf_range(-0.5, 0.5), 1.8, 0)
```

### `game/scripts/effects/damage_number.gd`

Na função `setup()`:

```gdscript
# ANTES
velocity = Vector3(0, 3, 0)
lifetime = 0.8

# DEPOIS
velocity = Vector3(0, 5, 0)
lifetime = 1.2
```

E nos defaults de `font_size` dentro de `setup()` (secondary path, caso chamado diretamente):

```gdscript
# ANTES
font_size = 48 if not is_crit else 64

# DEPOIS  
font_size = 480 if not is_crit else 640
```

---

## Escopo — o que NÃO muda

- Hitbox, dano, cooldown, balance — nenhum toque
- Lógica de throttle de FPS (`< 25 FPS` só crits, `< 35 FPS` 30% chance) — intacta
- Pool de 50 damage numbers — intacto
- Cores por tipo de dano — intactas
- `setup_text()` / texto flutuante de baú e quest — fora do escopo
- Sistema de partículas, shaders, áudio
- Cenas `.tscn` — nenhuma alteração necessária (tudo por código)
- HUD de multiplayer (`hud_multiplayer.gd`) — fora do escopo deste PRD

---

## Testes de aceitação

| # | Cenário | Critério |
|---|---|---|
| 1 | Iniciar run com qualquer Fragmentado | Ícones de arma e item visíveis e legíveis em 1280×720 |
| 2 | Equipar 3+ armas e 3+ itens | Painéis não transbordam a borda da tela (caber em 1280×720) |
| 3 | Atacar inimigo | Número de dano ocupa espaço ~10× maior que antes, cor e tipo preservados |
| 4 | Acertar CRIT | Número crit claramente maior/dourado e distinto do dano normal |
| 5 | Combate denso (20+ inimigos) | Throttle de FPS funciona, sem crash de pool |
| 6 | FPS < 25 | Só crits aparecem — comportamento preservado |
| 7 | Multiplayer 2 jogadores | Ícones e hit numbers de ambos visíveis sem sobreposição crítica |

---

## Estimativa

| Arquivo | Mudanças | Esforço |
|---|---|---|
| `hud.gd` | ~12 linhas alteradas em 2 funções | 15 min |
| `enemy_base.gd` | ~3 linhas | 5 min |
| `damage_number.gd` | ~4 linhas | 5 min |
| Teste visual | Verificar UI em 1280×720 | 15 min |
| **Total** | | **~40 min** |
