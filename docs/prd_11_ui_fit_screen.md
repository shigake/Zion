# PRD 11 — Todas as telas devem caber em 1 tela sem scroll

## Problema
Varias telas do jogo precisam de scroll para ver todo o conteudo. Todas as UIs devem caber em uma tela (1280x720 base).

## Telas afetadas
1. **Loja** — grid de upgrades com cards de 280x180px em 4 colunas + botoes
2. **Tela de morte** — lista vertical longa de stats (ver PRD 08)
3. **Opcoes** — tabs com muitas configuracoes
4. **Outras telas** — verificar caso a caso

## Resolucao base
Viewport: 1280x720 (stretch: canvas_items, aspect: expand). Todo conteudo deve caber nessa resolucao minima.

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `scripts/ui/shop.gd` | Cards 280x180, 4 colunas, ScrollContainer |
| `scenes/ui/shop.tscn` | ScrollContainer com EXPAND_FILL |
| `scripts/ui/game_over_screen.gd` | PanelContainer 540x640 com ScrollContainer |
| `scenes/ui/game_over_screen.tscn` | Layout do game over |
| `scripts/ui/options_screen.gd` | Tabs de configuracao |
| Todas as telas em `scenes/ui/` | Verificar cada uma |

## Plano de implementacao

### Passo 1 — Loja
Area disponivel: ~1280x720 - margens (80px cada lado) = 1120x640.

Opcao A — Reduzir cards:
```
Cards: 200x140 (era 280x180)
Colunas: 4
4 cards x 200px = 800px largura (cabe)
3 linhas x 140px = 420px altura (cabe com titulo + botoes)
```

Opcao B — Grid 3x4 (3 colunas, 4 linhas):
```
Cards: 240x120
3 x 240 = 720px + gaps
4 linhas x 120 = 480px
```

### Passo 2 — Tela de morte
Ver PRD 08 — simplificar conteudo elimina a necessidade de scroll.

### Passo 3 — Opcoes
Opcoes usam tabs (Video, Audio, Gameplay, Controles). Cada tab deve caber em:
- Area disponivel: ~1120x500 (descontando header + footer)
- Se nao couber: reduzir font size, usar 2 colunas de opcoes lado a lado

### Passo 4 — Auditoria geral
Verificar TODAS as telas em `scenes/ui/`:
- `main_menu.tscn`
- `character_select.tscn`
- `stage_select.tscn`
- `world_map.tscn`
- `leaderboard.tscn`
- `achievements.tscn`
- `tutorial.tscn`
- `credits.tscn`
- Qualquer outra

Para cada uma: abrir, verificar se cabe em 1280x720, ajustar se necessario.

### Passo 5 — Regra para futuras telas
Adicionar ao CLAUDE.md:
```
**Regra de UI**: Toda tela deve caber em 1280x720 sem scroll.
Se o conteudo nao cabe, simplificar ou usar tabs/paginas.
```

## Validacao
- [ ] Loja cabe em 1 tela sem scroll
- [ ] Tela de morte cabe em 1 tela
- [ ] Opcoes cabem em 1 tela por tab
- [ ] Todas as telas do `scenes/ui/` verificadas
- [ ] Nenhum ScrollContainer visivel para o jogador
