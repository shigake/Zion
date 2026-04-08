# PRD 31 — Icones de armas e itens estourando a tela no HUD

**Status**: concluido
**Prioridade**: alta (afeta jogabilidade — jogador nao ve seus itens)
**Complexidade**: media

---

## Problema

Durante a jogatina, os icones de **armas** (canto inferior esquerdo) e **itens** (canto inferior direito) estao estourando para fora da tela quando o jogador acumula varios.

### Numeros atuais

| Propriedade | Valor |
|-------------|-------|
| Viewport | 1280 x 720 |
| Tamanho do icone (panel) | 128 x 128 px |
| Tamanho da textura | 112 x 112 px |
| Espacamento entre icones | 8 px |
| Max armas possiveis | 8 |
| Max itens possiveis | 19 |
| Largura total com 8 armas | 8 x 128 + 7 x 8 = **1080 px** |

Com 8 armas (1080px) + offset de 12px = 1092px ocupados so no lado esquerdo. Itens no lado direito com situacao similar. Os paineis se sobrepoem no centro e/ou vazam da tela.

### Evidencia

- WeaponPanel: `offset_left = 12`, `offset_right = 230` (fixo, nao escala)
- ItemPanel: `offset_left = -230`, ancorado no canto direito (fixo, nao escala)
- Icones sao criados dinamicamente em `_update_weapon_icons()` e `_update_item_icons()` em `hud.gd` (linhas 439-550)
- Tamanho hardcoded: `panel.custom_minimum_size = Vector2(128, 128)` e `tex_rect.custom_minimum_size = Vector2(112, 112)`
- Sem nenhuma logica de escala ou wrap

---

## Solucao

### Escala dinamica baseada na quantidade de icones

O tamanho dos icones deve se adaptar automaticamente a quantidade atual, mantendo tudo visivel dentro da metade da tela correspondente.

### Regras de tamanho

| Icones | Tamanho do panel | Tamanho da textura | Fonte do badge |
|--------|------------------|--------------------|----------------|
| 1-4    | 80 x 80 px      | 68 x 68 px         | 14             |
| 5-6    | 64 x 64 px      | 54 x 54 px         | 12             |
| 7+     | 52 x 52 px      | 44 x 44 px         | 10             |

**Espacamento**: 6px fixo (reduzido dos 8px atuais)

### Calculo de espaco maximo

Cada lado (armas/itens) tem no maximo **metade** do viewport: 640px, com 20px de margem = **620px uteis**.

- 4 icones a 80px: 4 x 80 + 3 x 6 = 338px ✅
- 6 icones a 64px: 6 x 64 + 5 x 6 = 414px ✅
- 8 icones a 52px: 8 x 52 + 7 x 6 = 458px ✅
- 19 itens a 52px: precisa **2 linhas** (10 + 9) = 530px + 528px ✅

### Duas linhas para 10+ icones

Quando houver mais de 9 icones (possivel com itens), dividir em 2 linhas usando um **GridContainer** ou VBox com 2 HBox. Primeira linha recebe ceil(n/2), segunda recebe o resto.

---

## Implementacao

### Arquivo: `game/scripts/ui/hud.gd`

1. **Criar funcao `_get_icon_size(count: int)`** que retorna o tamanho do panel e textura baseado na quantidade
2. **Modificar `_update_weapon_icons()`** para usar tamanho dinamico
3. **Modificar `_update_item_icons()`** para usar tamanho dinamico + grid de 2 linhas se necessario
4. **Ajustar offsets do WeaponPanel e ItemPanel** na cena `hud.tscn` para acomodar a nova altura maxima (2 linhas)

### Arquivo: `game/scenes/ui/hud.tscn`

1. **WeaponPanel**: manter ancora bottom-left, ajustar offset_top para comportar ate 2 linhas
2. **ItemPanel**: manter ancora bottom-right, ajustar offset_top para comportar ate 2 linhas
3. Garantir que os containers permitem shrink (sem minimum_size fixo no container pai)

### Arquivo: `game/scripts/autoload/game_constants.gd`

Adicionar constantes na categoria HUD:

```gdscript
# HUD Icon sizes
const HUD_ICON_SIZES = {
    "large": { "panel": Vector2(80, 80), "texture": Vector2(68, 68), "font": 14 },
    "medium": { "panel": Vector2(64, 64), "texture": Vector2(54, 54), "font": 12 },
    "small": { "panel": Vector2(52, 52), "texture": Vector2(44, 44), "font": 10 },
}
const HUD_ICON_LARGE_MAX = 4      # ate 4 icones: tamanho large
const HUD_ICON_MEDIUM_MAX = 6     # ate 6 icones: tamanho medium
const HUD_ICON_SEPARATION = 6     # espacamento entre icones
const HUD_ICON_MAX_PER_ROW = 9    # maximo por linha antes de quebrar
```

---

## Criterios de aceite

- [ ] Com 1-4 armas, icones sao visiveis e nao saem da tela (80x80)
- [ ] Com 5-6 armas, icones reduzem automaticamente (64x64)
- [ ] Com 7-8 armas, icones reduzem mais (52x52)
- [ ] Com 10+ itens, icones quebram em 2 linhas
- [ ] Nenhum icone sai da area visivel (1280x720) em nenhuma combinacao
- [ ] Armas e itens nunca se sobrepoem entre si
- [ ] Badge de nivel continua legivel em todos os tamanhos
- [ ] Icones manteem borda colorida por tipo (melee/ranged/summon)
- [ ] Gamepad e mouse continuam funcionando normalmente
- [ ] Transicao de tamanho ocorre sem flicker ao ganhar nova arma/item

---

## Fora de escopo

- Tooltip ao passar o mouse nos icones (feature separada)
- Animacao de entrada dos icones
- Reorganizar outros elementos do HUD
