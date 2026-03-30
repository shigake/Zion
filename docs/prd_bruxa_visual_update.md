# PRD — Reajuste Visual: Bruxa (Representatividade)

> Alterar a cor da pele da Bruxa para pele negra, mantendo coerência visual com roupas, acessórios e lore.

---

## Objetivo

Atualizar a personagem **Bruxa** para ter pele negra, refletindo representatividade no elenco dos Fragmentados. A Bruxa é uma das 5 personagens iniciais desbloqueadas (conforme `save_manager.gd`, linha 80: `defaults = ["amazona", "bruxa", "ronin", "soldado", "mago"]`), então a mudança tem alta visibilidade.

## Contexto Narrativo

A Bruxa é descrita na `story.md` como: *"Fugiu da fogueira em Salem, 1692, e caiu direto na Floresta Encantada. Adaptou-se rápido."* A mudança de tom de pele é puramente cosmética e não conflita com a lore — Salem historicamente incluía pessoas de diversas origens, e o que define a Bruxa é sua magia, não sua aparência.

---

## Tarefa 1: Atualizar o Sprite Generator (`bruxa_sprite_gen.gd`)

### Contexto

O sprite 32×32 da Bruxa é gerado proceduralmente em `res://scripts/tools/bruxa_sprite_gen.gd`. A cor da pele é definida na **linha 5** e usada em 3 locais:

| Linha | Uso | Código atual |
|---|---|---|
| 5 | Definição da variável `skin` | `var skin = Color(0.85, 0.78, 0.72)` |
| 36 | Rosto (6×3 px) | `_fill(img, 12, 7, 6, 3, skin)` |
| 67-68 | Mãos (1×2 px cada) | `_fill(img, 9, 13, 1, 2, skin)` / `_fill(img, 20, 13, 1, 2, skin)` |

### Solução

Alterar a variável `skin` na **linha 5** de:

```gdscript
var skin = Color(0.85, 0.78, 0.72)    # ← Atual: bege claro
```

Para:

```gdscript
var skin = Color(0.45, 0.30, 0.22)    # ← Novo: pele negra (tom médio-escuro)
```

Tons sugeridos (paleta pixel art friendly):

| Tom | Color | Hex | Nota |
|---|---|---|---|
| Médio-escuro | `Color(0.45, 0.30, 0.22)` | `#734D38` | Recomendado — contrasta bem com o vestido roxo escuro |
| Escuro | `Color(0.35, 0.22, 0.15)` | `#593826` | Mais escuro — pode perder contraste com o outline preto |
| Médio | `Color(0.55, 0.38, 0.28)` | `#8C6147` | Mais claro — mais contraste com cabelo/chapéu |

> **Nota:** O outline da Bruxa é `Color(0.08, 0.04, 0.1)` (quase preto). Manter o `skin` acima de `0.30` de luminância para garantir que o rosto não se misture com o outline no sprite 32×32.

### Ajuste de cor dependente: lábios

A cor dos lábios/sorriso (linha 44-45) é atualmente `Color(0.6, 0.3, 0.35)`. Para combinar com pele mais escura, sugerir ajuste:

```gdscript
# Linha 44-45: Sorriso
img.set_pixel(14, 9, Color(0.75, 0.35, 0.38))   # Lábios ligeiramente mais claros
img.set_pixel(15, 9, Color(0.75, 0.35, 0.38))
```

### Arquivos impactados

| Arquivo | Ação |
|---|---|
| `scripts/tools/bruxa_sprite_gen.gd` | Alterar `skin` na linha 5 e opcionalmente lábios nas linhas 44-45 |

---

## Tarefa 2: Regenerar os Sprites

### Detalhes

Após alterar o script, regenerar os assets executando:

```bash
# 1. Regenerar o sprite estático
godot --headless --path game --script res://scripts/tools/bruxa_sprite_gen.gd

# 2. Regenerar o spritesheet de walk (usa o bruxa.png como input)
godot --headless --path game --script res://scripts/tools/walk_spritesheet_gen.gd
```

O `walk_spritesheet_gen.gd` (linha 18) inclui `"bruxa"` na lista `CHARACTERS` e lê diretamente de `res://assets/sprites/characters/bruxa.png` para gerar `bruxa_walk.png`. Portanto, basta rodar os dois scripts em sequência.

### Assets gerados

| Asset | Caminho | Gerado por |
|---|---|---|
| Sprite estático | `assets/sprites/characters/bruxa.png` | `bruxa_sprite_gen.gd` |
| Walk spritesheet | `assets/sprites/characters/bruxa_walk.png` | `walk_spritesheet_gen.gd` |

### Critérios de aceite

- [x] `bruxa.png` exibe pele negra no rosto e mãos
- [x] `bruxa_walk.png` (4 frames) reflete a nova cor
- [x] Contraste visual suficiente entre pele, outline, cabelo e vestido roxo
- [x] Sem pixels "fantasma" da cor antiga (regeneração completa)

---

## Tarefa 3: Verificar Referências Visuais

### Locais onde o sprite da Bruxa aparece

| Tela | Script | Como usa |
|---|---|---|
| Character Select | `character_select.gd` | Carrega `bruxa.png` como `TextureRect` |
| HUD in-game | `character_hp_bar.gd` | Mini-retrato do personagem |
| Créditos | `credits_screen.gd` | `Sprite3D` ao redor da fogueira |
| Menu principal | `main_menu.gd` | Silhueta aleatória (se sorteada) |
| Bestiário | — | Não aparece (só mostra inimigos) |

Todos usam o arquivo `bruxa.png` diretamente via path — não há cor hardcoded nesses scripts. Bastando regenerar o PNG, todos refletem automaticamente.

### Único hardcode a verificar

O `game_manager.gd` (linha 716) referencia `"bruxa"` para aplicar bônus de invocação. Isso **não afeta visual**, apenas gameplay — sem impacto.

### Critérios de aceite

- [x] Character Select mostra a Bruxa com pele negra
- [x] HUD in-game mostra o retrato atualizado
- [x] Cena de créditos mostra o sprite atualizado na fogueira
- [x] Nenhum script usa a cor de pele hardcoded (tudo lê do PNG)

---

## Dependências

| Sistema | Tarefas |
|---|---|
| `bruxa_sprite_gen.gd` | 1 |
| `walk_spritesheet_gen.gd` | 2 |
| `bruxa.png` + `bruxa_walk.png` | 2, 3 |

## Ordem de implementação

| Fase | Tarefas | Descrição |
|---|---|---|
| A | 1 | Alterar a cor no script gerador |
| B | 2 | Regenerar PNGs via headless |
| C | 3 | Verificação visual em todas as telas |

## Prioridade

Baixa (cosmético) — sem impacto em gameplay. Pode ser feito em qualquer momento e publicado como hotfix visual.
