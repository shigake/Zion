# PRD 20 — Tamanho uniforme do ícone de arma na tela de seleção de personagem

**Status:** CONCLUIDO  
**Prioridade:** Média  
**Estimativa:** 20 min  
**Arquivo principal:** `game/scripts/ui/character_select.gd`  

---

## Problema

Na tela de seleção de personagem, ao clicar em qualquer herói, o painel inferior exibe nome, atributos e a arma inicial com um ícone. O tamanho desse ícone de arma **varia de herói para herói**: alguns aparecem com 20×20 px como esperado, outros crescem consideravelmente — chegando a distorcer o layout inteiro do mini-painel (deslocando o texto da arma, aumentando a altura da linha e quebrando o alinhamento com os demais elementos).

A raiz do problema é que o `TextureRect` do ícone tem apenas `custom_minimum_size = Vector2(20, 20)`, sem limite máximo de tamanho e sem `expand_mode` configurado. Quando um arquivo SVG de arma possui dimensões internas maiores que 20×20, o `TextureRect` expande para acomodar a textura em vez de mantê-la contida — desrespeitando o mínimo como se fosse o tamanho real.

---

## Comportamento esperado

```
[ Arma: [ícone 20×20 fixo] Nome da arma ]
```

Todos os ícones de arma devem ocupar exatamente **20×20 px**, independente das dimensões nativas do SVG. O texto ao lado deve se manter sempre no mesmo alinhamento vertical. O painel de informações não deve mudar de tamanho ao trocar de personagem.

---

## Causa raiz

Em `character_select.gd`, dentro de `_build_info_panel()`, o ícone de arma é criado assim:

```gdscript
_weapon_icon = TextureRect.new()
_weapon_icon.custom_minimum_size = Vector2(20, 20)
_weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
weapon_row.add_child(_weapon_icon)
```

Problemas presentes:
1. `custom_minimum_size` define apenas o **mínimo** — não impede que o nó cresça além disso dentro de um `HBoxContainer`.
2. `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED` escala o conteúdo, mas só funciona corretamente quando o nó tem um tamanho fixo. Sem isso, o nó adota o tamanho natural da textura.
3. `expand_mode` não está definido — o padrão `EXPAND_KEEP_SIZE` faz o nó crescer para preencher o espaço disponível quando o container permitir.

---

## Solução

### Mudança cirúrgica em `_build_info_panel()` — `character_select.gd`

Substituir a criação do `_weapon_icon` por uma versão com tamanho fixo garantido:

```gdscript
_weapon_icon = TextureRect.new()
_weapon_icon.custom_minimum_size = Vector2(20, 20)
_weapon_icon.size = Vector2(20, 20)
_weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
_weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
_weapon_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
_weapon_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
weapon_row.add_child(_weapon_icon)
```

**O que cada linha resolve:**
- `size = Vector2(20, 20)` — define o tamanho real do nó desde a criação, não apenas o mínimo.
- `expand_mode = EXPAND_IGNORE_SIZE` — faz a textura renderizar dentro dos bounds do nó, ignorando o tamanho nativo do SVG.
- `size_flags_horizontal/vertical = SIZE_SHRINK_CENTER` — impede que o `HBoxContainer` estique o nó além de 20×20.

---

## O que NÃO deve mudar

- O `stretch_mode` dos demais `TextureRect` na tela (grid de personagens, sprite grande do herói) — não são afetados.
- O comportamento de seleção de personagem — continua idêntico.
- O conteúdo dos SVGs de arma — nenhum asset é alterado.
- O loading screen antes da jogatina — não é afetado.

---

## Critérios de aceitação

- [ ] O ícone de arma ocupa exatamente **20×20 px** para todos os 15 heróis.
- [ ] O painel de informações **não muda de tamanho** ao alternar entre personagens.
- [ ] O texto do nome da arma permanece alinhado verticalmente com o ícone em todos os casos.
- [ ] Testado com pelo menos 5 heróis de armas diferentes (melee, ranged, summon).
- [ ] Testado em 1280×720 — sem overflow ou deslocamento do painel.
- [ ] Nenhuma outra tela é afetada pela mudança.
