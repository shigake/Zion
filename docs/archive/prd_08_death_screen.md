# PRD 08 — Tela de morte muito grande e poluida

## Status: CONCLUIDO

## Problema
A tela de Game Over mostra informacao demais, eh muito grande e confusa. Precisa simplificar.

## Estado atual
A tela usa um PanelContainer de 540x640px com ScrollContainer. Mostra:

| Secao | Necessaria? |
|-------|------------|
| "GAME OVER" titulo | SIM |
| Icone + nome do personagem | SIM |
| Tempo de sobrevivencia | SIM |
| Kills | SIM |
| Level | SIM |
| Cristais ganhos | SIM |
| DPS medio | NAO — metrica tecnica, confusa pra jogador |
| Peak enemies | NAO — metrica de debug |
| Lista de armas com dano | TALVEZ — so se compacta |
| Lista de itens | TALVEZ — so se compacta |
| Lista de evolucoes | TALVEZ — so se compacta |
| Eventos triggered | NAO — pouco relevante |
| Ranking DPS de armas (barras) | NAO — duplica info das armas |
| Comparacao com melhor run | NAO — ocupa muito espaco |
| Timeline de eventos | NAO — ocupa muito espaco, scroll horizontal |
| Leaderboard rank | SIM (modo endless) |
| Total damage dealt | NAO — redundante com DPS |
| Character unlock messages | SIM |
| Botao screenshot | SIM |
| Botao retry | SIM |
| Botao menu | SIM |

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `scripts/ui/game_over_screen.gd` | Constroi toda a UI dinamicamente (~L61-210 setup, ~L183-446 extras) |
| `scenes/ui/game_over_screen.tscn` | Layout base (PanelContainer 540x640) |

## Plano de implementacao

### Passo 1 — Definir layout simplificado
Nova tela de morte, compacta:

```
+----------------------------------+
|          GAME OVER               |
|     [icone] Nome Personagem      |
|                                  |
|   Tempo: 3:45    Nivel: 12      |
|   Kills: 247     Cristais: 85   |
|                                  |
|   [arma1 icon] [arma2] [arma3]  |  <- icones pequenos, sem texto
|   [item1 icon] [item2] [item3]  |  <- icones pequenos
|                                  |
|   "Novo personagem desbloqueado!"|  <- se aplicavel
|                                  |
|   [Retry]  [Screenshot]  [Menu] |
+----------------------------------+
```

### Passo 2 — Remover secoes excessivas
Em `game_over_screen.gd`, remover/comentar:
- DPS medio
- Peak enemies
- Ranking DPS com barras coloridas
- Comparacao com melhor run (5 linhas)
- Timeline de eventos
- Total damage dealt
- Eventos triggered

### Passo 3 — Compactar armas e itens
Em vez de lista vertical com nome + nivel + dano, usar grid horizontal de icones pequenos (32x32):
```gdscript
var grid = GridContainer.new()
grid.columns = 6  # Ate 6 por linha
for weapon in weapons:
    var icon = TextureRect.new()
    icon.texture = load(weapon_sprite_path)
    icon.custom_minimum_size = Vector2(32, 32)
    grid.add_child(icon)
```

### Passo 4 — Reduzir tamanho do painel
De 540x640 para algo que caiba confortavelmente:
- Largura: 400px
- Altura: auto (sem scroll)

### Passo 5 — Manter info detalhada em tooltip ou tela separada
Se o jogador quiser ver detalhes (DPS, timeline), adicionar um botao "Detalhes" que expande. Mas o padrao eh a versao limpa.

## Validacao
- [x] Tela de morte cabe sem scroll
- [x] Mostra apenas: titulo, personagem, tempo, kills, level, cristais, icones de armas/itens, botoes
- [x] Desbloqueio de personagem ainda aparece quando aplicavel
- [x] Botoes retry, screenshot e menu funcionam
- [x] Visual limpo e legivel
