# PRD — Features Faltantes (Baseado na Documentacao)

## Da spec/mecanicas que NAO estao implementadas

### Sistema de Dano por Tipo
- [x] Cada arma tem tipo de dano (Fisico, Fogo, Gelo, Eletrico, Dark)
- [x] Inimigos tem resistencias
- [x] Boss tem resistencia parcial a todos
- [x] Nenhum inimigo imune (minimo 1 dano)

### Sinergias Elementais
- [x] Fogo + Fogo = explosao ao matar
- [x] Gelo + Gelo = estilhacos ao congelar
- [x] Eletrico + Eletrico = chain lightning mais longo
- [x] Dark + Dark = area de trevas passiva
- [x] Fogo + Gelo = steam cloud
- [x] Eletrico + Gelo = condutor massivo

### Eventos Faltantes (da mecanicas.md)
- [x] Eclipse (min 8): tela escurece, inimigos invisiveis
- [x] Chuva de Meteoros (min 12): dano aleatorio em tudo
- [x] Desafio do Anjo (min 15): dobrar dano mas metade HP
- [x] Portal Dimensional (min 20): mini-dungeon
- [x] Fever Mode: ao coletar muita XP rapido
- [x] Chest Mimic: bau que e mini-boss

### Reliquias Faltantes (da mecanicas.md)
- [x] Bussola: mostra direcao do proximo evento
- [x] Pergaminho Antigo: comeca com 1 arma extra
- [x] Medalha de Veterano: +20% XP mas inimigos +15% rapidos
- [x] Chave Mestre: baus dropam 2x

### Itens Faltantes (dos 19 no itens.md, temos 19)
- [x] Todos os 19 itens implementados

### Upgrades da Loja Faltantes (da progressao.md)
- [x] Sorte (drops raros)
- [x] Cooldown Reduction
- [x] Revive (1x por run)
- [x] Slots de Arma (+2 max)
- [x] Reroll (comprar rerolls extras)
- [x] Banish

### Inimigos Faltantes (dos genericos)
- [x] Slime Grande (split em 2 ao morrer)
- [x] Skeleton Archer (fica parado, atira)
- [x] Mimic (parece bau, ataca)
- [x] Bomber (corre e explode)
- [x] Tank (gigante, lento, muito HP)
- [x] Swarm (grupo de 20+ insetos)

### Boss Behavior (fases de comportamento)
- [x] Boss muda pattern a cada 25% HP
- [x] Boss barra de HP no topo
- [x] Boss invoca hordas
- [x] Boss ataques especiais em cada fase

### Modo Endless
- [x] Sem boss, sem timer
- [x] Dificuldade continua escalando sem limite
- [x] Leaderboard local

### Gamepad Support
- [x] Left stick: movimento
- [x] Right stick: direcao
- [x] A/X: dash
- [x] B/Circle: interagir

### Pause Menu
- [x] ESC pausa
- [x] Resume, Options, Quit to Menu

### Merchant Event
- [x] NPC visual com area de interacao
- [x] UI de compra com 3 itens aleatorios por cristais

### Mutacoes / Modo Ascensao
- [x] MutationManager singleton com 6 mutacoes
- [x] UI de mutacoes (painel entre character select e stage select)
- [x] Inimigos Explosivos (AoE na morte)
- [x] Chefes Furiosos (comecam na fase 2)
- [x] Cura Enfraquecida (-50% heal)
- [x] Speed Demons (+30% velocidade inimigos)
- [x] Horda Infinita (+50% spawn rate)
- [x] Sem Evolucao (bloqueia evolucoes)
- [x] Multiplicador de cristais na tela de resultado
- [x] Telemetria com mutations_active

### Cross-Combo Multiplayer
- [x] Sistema de zonas elementais registradas por armas
- [x] Detecao de cross-combo quando projetil de um jogador atinge zona de outro
- [x] 12 combinacoes elementais com efeitos visuais
- [x] Cooldown de 2s por par de jogadores
- [x] Label flutuante "CROSS-COMBO!" com fade out
- [x] Integrado no enemy_base.take_damage

### Reviver com Sacrificio
- [x] Tombstone spawna na posicao de morte no multiplayer
- [x] Area3D de interacao (raio 2.5 unidades)
- [x] Timer de revive (5 segundos continuo)
- [x] Progress bar visual
- [x] Revive com 50% HP
- [x] Debuff no sacrificador (-30% max HP por 30s)
- [x] Despawn da lapide apos 60 segundos
- [x] Integrado com sistema de revive existente (upgrade da loja)
