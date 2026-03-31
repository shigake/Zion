# PRD 11 — Todas as telas devem caber em 1 tela sem scroll

## Status: CONCLUIDO

## Problema
Varias telas do jogo precisam de scroll para ver todo o conteudo. Todas as UIs devem caber em uma tela (1280x720 base).

## Telas afetadas
1. **Loja** — grid de upgrades com cards de 280x180px em 4 colunas + botoes
2. **Tela de morte** — lista vertical longa de stats (ver PRD 08)
3. **Opcoes** — tabs com muitas configuracoes
4. **Outras telas** — verificar caso a caso

## Resolucao base
Viewport: 1280x720 (stretch: canvas_items, aspect: expand). Todo conteudo deve caber nessa resolucao minima.

## Implementacao realizada

### Loja (shop.gd)
- Cards reduzidos de 240x150 para 200x130
- Margem interna reduzida de 10px para 6px
- Icone reduzido de 32x32 para 24x24
- Titulo do card de 16px para 13px
- Descricao de 12px/30px min para 10px/20px min
- Botao de compra de 32px para 26px altura
- Separacao interna de 4px para 2px
- Resultado: 4 colunas x 3 linhas = 12 cards cabem em 1280x720

### Conquistas (achievements_screen.gd)
- Cards reduzidos de 380x100 para 380x78
- Icone reduzido de 48x48 para 40x40
- Margem interna reduzida (10px -> 6px vertical)
- Resultado: 3 colunas x 5 linhas = 15 cards cabem com scroll interno

### Codex de armas (codex_screen.gd)
- Cards reduzidos de 175x130 para 145x100
- Colunas aumentadas de 4 para 5
- Titulo reduzido de 30px para 24px
- Resultado: 5 colunas cabem no painel esquerdo, scroll interno para navegacao

### Bestiario (bestiary_screen.gd)
- Cards reduzidos de 155x115 para 130x95
- Colunas aumentadas de 4 para 5
- Titulo reduzido de 30px para 24px
- Resultado: grid mais compacto com scroll interno apenas no grid

### Leaderboard (leaderboard_screen.gd)
- Removido ScrollContainer externo que envolvia toda a tela
- Layout fixo com VBoxContainer full-rect
- Adicionado ScrollContainer interno apenas na lista de entries
- Titulo reduzido de 32px para 26px
- Separacao reduzida de 12px para 8px
- Resultado: header + tabs + lista scrollavel + botoes cabem em 720px

### Desafio diario (daily_challenge_screen.gd)
- Removido ScrollContainer externo que envolvia toda a tela
- Layout fixo com VBoxContainer full-rect
- Botao play reduzido de 300x52 (20px) para 280x44 (18px)
- Titulo leaderboard reduzido de 22px para 18px
- Titulo principal reduzido de 36px para 26px
- Leaderboard local com ScrollContainer interno
- Separacao reduzida de 16px para 10px
- Resultado: info + botoes + leaderboard cabem em 720px

### Mutacoes (mutations_panel.gd)
- Cards reduzidos de 280x120 para 260x100

### Telas ja conformes (verificadas)
- **Character select**: 5x3 grid a 80x90 = cabe bem
- **Stage select**: mapa com nodes desenhados, sem scroll
- **Options**: usa TabContainer com scroll interno por aba (aceito)
- **Game over**: painel 400x480 centralizado, cabe
- **Relic select**: grid 4x3 com paginacao, cabe
- **Credits**: tela animada, sem overflow
- **Main menu**: layout simples, cabe

## Validacao
- [x] Loja cabe em 1 tela sem scroll
- [x] Tela de morte cabe em 1 tela
- [x] Opcoes cabem em 1 tela por tab
- [x] Todas as telas do `scenes/ui/` verificadas
- [x] ScrollContainer externo removido onde possivel; scroll interno aceito em listas longas
