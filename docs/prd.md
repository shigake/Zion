# Zion - PRD (Product Requirements Document)

---

## Fase 0 — POC (Proof of Concept)

**Objetivo:** Validar que o jogo e divertido. So mecanica, sem arte, sem polish.

**Duracao estimada:** 2 semanas

**Criterio de sucesso:** Jogar 5 min e pensar "quero continuar jogando"

### O que entra

**Jogador**
- [ ] Movimento WASD (top-down 3D com camera fixa)
- [ ] Dash com cooldown (Space)
- [ ] Barra de HP
- [ ] Morte e tela de game over

**Armas (2 apenas)**
- [ ] Espada Samurai — ataque automatico melee, corta em arco na frente
- [ ] Staff — projetil magico homing que persegue o inimigo mais proximo

**Inimigos (2 tipos)**
- [ ] Slime — lento, pouca vida, anda em direcao ao jogador
- [ ] Bat — rapido, pouca vida, anda em direcao ao jogador

**Spawner**
- [ ] Inimigos spawnam fora da tela
- [ ] Quantidade aumenta com o tempo (scaling linear simples)

**XP e Level Up**
- [ ] Inimigos dropam gema de XP ao morrer
- [ ] Gemas sao atraidas ao jogador (magnetismo)
- [ ] Barra de XP no HUD
- [ ] Ao encher: jogo pausa, 3 opcoes aparecem
- [ ] Opcoes possiveis: nova arma, upgrade de arma existente, item passivo

**Itens Passivos (3 apenas)**
- [ ] Botas de Hermes — +15% velocidade
- [ ] Luva de Velocidade — +20% attack speed
- [ ] Coracao de Dragao — +20% HP maximo

**HUD**
- [ ] Barra de HP
- [ ] Barra de XP + nivel
- [ ] Timer
- [ ] Kill count

**Fase**
- [ ] 1 arena unica (chao plano, sem decoracao, so ground + cor de fundo)
- [ ] Sem boss
- [ ] Sem eventos
- [ ] Sem limite de tempo (endless ate morrer)

**Visual**
- [ ] Primitivas 3D (capsulas, esferas, cubos) com cores solidas
- [ ] Nada de arte. Jogador = capsula verde. Inimigo = cubo vermelho. Projetil = esfera azul.
- [ ] Cel-shader basico so pra validar a estetica

### O que NAO entra
- Multiplayer
- Loja / meta-progressao
- Boss
- Evolucao de armas
- Reliquias
- Eventos
- Audio
- Menu principal
- Save system
- Steam integration

---

## Fase 1 — Vertical Slice (Single Player Completo)

**Objetivo:** Uma run completa de 30 min que representa o jogo final. Uma fase, do inicio ao fim com boss.

**Duracao estimada:** 4 semanas

**Pre-requisito:** Fase 0 concluida e gameplay validado

### O que entra (alem de tudo da Fase 0)

**Jogador**
- [ ] Selecao de personagem (3 personagens: Ronin, Soldado, Mago)
- [ ] Cada um com arma inicial e passiva diferentes
- [ ] Animacoes basicas (idle, walk, hit, death) — pode ser simples

**Armas (6 totais)**
- [ ] Espada Samurai (melee, corte em arco)
- [ ] Metralhadora (ranged, spray de projeteis)
- [ ] Staff (ranged, homing)
- [ ] Foice (melee, gira ao redor do jogador)
- [ ] Bazuca (ranged, explosao em area)
- [ ] Necromante (summon, invoca esqueletos)

**Armas — Level Up (1 a 8)**
- [ ] Cada level melhora stats (dano, area, projeteis, velocidade)
- [ ] Valores balanceados para 30 min de run

**Itens Passivos (6 totais)**
- [ ] Botas de Hermes (+velocidade)
- [ ] Luva de Velocidade (+attack speed)
- [ ] Coracao de Dragao (+HP)
- [ ] Cristal Arcano (+area de efeito)
- [ ] Ima (+range de coleta)
- [ ] Relogio Quebrado (-cooldown)

**Itens — Level Up (1 a 5)**
- [ ] Cada level aumenta o efeito

**Evolucao de Arma (2 evolucoes para validar o sistema)**
- [ ] Espada Samurai + Luva de Velocidade = Zangetsu
- [ ] Staff + Cristal Arcano = Cajado do Apocalipse
- [ ] Bau de evolucao aparece no mapa quando requisitos sao atendidos

**Fase: Cemiterio Assombrado**
- [ ] Ambiente 3D: chao de terra, lapides, neblina, lua
- [ ] Lapides destrutiveis que dropam power-ups
- [ ] 30 minutos de duracao

**Inimigos (5 tipos)**
- [ ] Slime (basico, lento)
- [ ] Bat (rapido, voador)
- [ ] Skeleton (medio, joga ossos)
- [ ] Zombie Corredor (rapido, medio HP)
- [ ] Ghost (atravessa obstaculos)

**Spawn por tempo**
- [ ] Min 0-5: Slimes
- [ ] Min 5-10: Slimes + Bats
- [ ] Min 10-15: Skeletons + Zombies + Mini-boss
- [ ] Min 15-25: Mix de tudo, crescente
- [ ] Min 25-30: Boss + horda

**Mini-boss**
- [ ] Zombie Gigante (HP alto, agarra)
- [ ] Barra de vida visivel
- [ ] Dropa bau raro

**Boss Final**
- [ ] Necromancer King
- [ ] Barra de vida no topo da tela
- [ ] 3 fases de comportamento (100-75%, 75-25%, 25-0%)
- [ ] Invoca hordas + lanca magias
- [ ] Derrotar = vitoria

**Tela de Level Up**
- [ ] 3 opcoes (arma/item)
- [ ] Reroll (1 gratis por run)
- [ ] Visual limpo

**HUD Completo**
- [ ] HP, XP, nivel, timer, kill count
- [ ] Icones das armas equipadas
- [ ] Icones dos itens equipados
- [ ] Boss HP bar

**Tela de Resultado**
- [ ] Stats da run (tempo, kills, dano, nivel)
- [ ] Botao de replay

**Visual**
- [ ] Modelos low-poly com cel-shader
- [ ] Ambiente do Cemiterio com assets (podem ser de marketplace)
- [ ] Efeitos de particula basicos (hit, morte, coleta)

**Audio basico**
- [ ] 1 musica de gameplay (pode ser placeholder/royalty free)
- [ ] SFX: hit, coleta, level up, morte

### O que NAO entra
- Multiplayer
- Loja / meta-progressao
- Reliquias
- Eventos especiais
- Outras fases
- Menu principal elaborado
- Save system
- Steam integration

---

## Fase 2 — Meta-progressao + Menu

**Objetivo:** Loop completo entre runs. Jogar, morrer, gastar moeda, jogar de novo mais forte.

**Duracao estimada:** 3 semanas

**Pre-requisito:** Fase 1 concluida

### O que entra

**Menu Principal**
- [ ] Tela titulo
- [ ] Jogar (selecao de personagem)
- [ ] Loja
- [ ] Opcoes (volume, resolucao, fullscreen)

**Moeda: Cristais**
- [ ] Dropam dos inimigos durante a run
- [ ] Quantidade varia por tipo de inimigo
- [ ] Creditados ao final da run (mesmo se morrer)

**Loja — Upgrades Permanentes (6 iniciais)**
- [ ] HP Maximo (+10 HP por level, max 10)
- [ ] Velocidade (+5% por level, max 8)
- [ ] Dano Base (+5% por level, max 10)
- [ ] Armadura (reduz dano, max 8)
- [ ] XP Bonus (+10% por level, max 8)
- [ ] Magnetismo (+range coleta, max 5)

**Save System**
- [ ] Save local: perfil, cristais, upgrades comprados, personagens desbloqueados
- [ ] Auto-save ao voltar pro lobby

**Selecao de Personagem**
- [ ] Tela de selecao com os 3 personagens
- [ ] Mostra arma inicial e passiva
- [ ] Preview visual

**Selecao de Reliquia (3 iniciais)**
- [ ] Ampulheta (run de 40 min ao inves de 30)
- [ ] Dados de Ouro (+1 reroll por level up)
- [ ] Coracao Extra (+50% HP inicial)

**Evolucoes adicionais (4 totais)**
- [ ] + Metralhadora + Ima = Minigun Infernal (placeholder, sem item correto original — adaptar)
- [ ] + Foice + Relogio Quebrado = Death Scythe (placeholder)

**Tela de Resultado melhorada**
- [ ] Mostra cristais ganhos
- [ ] Mostra desbloqueaveis (se houver)
- [ ] Botao: Lobby / Replay

### O que NAO entra
- Multiplayer
- Outras fases
- Eventos especiais
- Achievements
- Steam integration

---

## Fase 3 — Multiplayer Online

**Objetivo:** 2-4 jogadores jogando juntos online. O jogo funciona em co-op.

**Duracao estimada:** 5 semanas

**Pre-requisito:** Fase 2 concluida

### O que entra

**Steam Integration**
- [ ] GodotSteam GDExtension integrado
- [ ] Steam App ID (pode ser teste/dev inicialmente)
- [ ] Inicializacao do Steam ao abrir o jogo

**Lobby System**
- [ ] Criar sala (publica ou amigos)
- [ ] Listar salas disponiveis
- [ ] Entrar em sala por convite Steam
- [ ] Tela de lobby: mostra jogadores conectados, personagem escolhido, botao "pronto"
- [ ] Host inicia quando todos estao prontos

**Networking**
- [ ] Steam Networking Sockets (P2P com relay)
- [ ] Arquitetura host-client
- [ ] Host e autoridade: spawn, dano, drops, boss HP
- [ ] Clients enviam: inputs de movimento
- [ ] Sync de posicoes (unreliable, 20 tick/s)
- [ ] Sync de eventos criticos (reliable): level up, morte, boss, drops

**Gameplay Online**
- [ ] Cada jogador controla seu personagem independentemente
- [ ] Cada jogador faz seu proprio level up (jogo pausa so pra ele)
- [ ] XP gems sao atraidas ao jogador mais proximo
- [ ] Inimigos perseguem o jogador mais proximo

**Scaling de Dificuldade**
- [ ] HP inimigos: 1x (solo), 1.3x (2p), 1.6x (3p), 2x (4p)
- [ ] Spawn rate: 1x (solo), 1.2x (2p), 1.4x (3p), 1.6x (4p)
- [ ] Boss HP: 1x (solo), 1.5x (2p), 2x (3p), 2.5x (4p)

**HUD Online**
- [ ] HP bars dos aliados (compactas)
- [ ] Setas indicando direcao dos aliados fora da tela
- [ ] Ping/latencia

**Desconexao**
- [ ] Client desconecta: personagem some, scaling ajusta
- [ ] Host desconecta: run termina (host migration e complexo — deixar pra depois)

**Camera**
- [ ] Cada jogador tem sua propria camera (nao e tela dividida)
- [ ] Camera segue o jogador local

### O que NAO entra
- Host migration
- Reconnect
- Matchmaking com ranking
- Voice chat (usar Discord)

---

## Fase 4 — Conteudo (3 Fases Completas)

**Objetivo:** Jogo tem variedade suficiente pra Early Access. 3 fases distintas, 8 armas, conteudo pra ~20h de gameplay.

**Duracao estimada:** 6 semanas

**Pre-requisito:** Fase 3 concluida

### O que entra

**Fase 2: Floresta Encantada**
- [ ] Ambiente: floresta magica, cogumelos gigantes, rios brilhantes
- [ ] Inimigos: fadas malignas, unicornios corrompidos, treants, pixies explosivas
- [ ] Mini-boss: Unicornio Negro
- [ ] Boss: Rainha das Fadas
- [ ] Mecanica: cogumelos dao buffs aleatorios ao destruir

**Fase 3: Fazenda do Apocalipse**
- [ ] Ambiente: fazenda destruida, silos, milharal
- [ ] Inimigos: vacas zumbis, galinhas explosivas, porcos mutantes, espantalhos
- [ ] Mini-boss: Touro Mecanico
- [ ] Boss: Mega Vaca Alienigena
- [ ] Mecanica: milharal esconde inimigos

**Armas adicionais (8 totais)**
- [ ] + Machado Viking (boomerang)
- [ ] + Shuriken (4 direcoes)

**Itens adicionais (8 totais)**
- [ ] + Capa das Sombras (dodge chance)
- [ ] + Aljava Infinita (+projeteis)

**Evolucoes adicionais (4 totais no jogo)**
- [ ] Todas as 4 evolucoes funcionando e balanceadas

**Personagens adicionais**
- [ ] + Berserker (machado, +dano quando HP baixo)
- [ ] + Ninja (shuriken, +velocidade)
- [ ] Desbloqueio por conquista (matar X inimigos, completar fase)

**Sistema de Eventos (3 eventos)**
- [ ] Horda Dourada (min 5): inimigos dourados, muito gold
- [ ] Treasure Goblin (aleatorio): inimigo que foge, dropa bau
- [ ] Merchant (aleatorio): NPC vendendo 3 itens por gold

**Modo Endless**
- [ ] Sem boss, sem limite de tempo
- [ ] Dificuldade continua escalando
- [ ] Leaderboard local (tempo sobrevivido)

**Upgrades de Loja adicionais**
- [ ] + Cooldown Reduction
- [ ] + Sorte (drops raros)
- [ ] + Reroll
- [ ] + Banish
- [ ] + Revive (1x por run)

**Sinergias Elementais (basico)**
- [ ] Fogo + Fogo = explosao ao matar
- [ ] Gelo + Gelo = estilhacos ao congelar

**Selecao de Fase**
- [ ] Tela de selecao de fase no lobby
- [ ] Fases desbloqueiam progressivamente

### O que NAO entra
- Fases 4-10
- Daily Challenge
- Achievements Steam
- Workshop
- Traducao/localizacao

---

## Fase 5 — Polish + Early Access Launch

**Objetivo:** Jogo pronto pra vender no Steam Early Access.

**Duracao estimada:** 4 semanas

**Pre-requisito:** Fase 4 concluida

### O que entra

**Visual Final**
- [ ] Modelos low-poly finais com cel-shader polido
- [ ] Ambientes das 3 fases com assets finais
- [ ] Efeitos de particula (hit, morte, coleta, level up, evolucao, boss)
- [ ] Animacoes dos personagens (idle, walk, dash, hit, death)
- [ ] Animacoes dos inimigos
- [ ] UI arte finalizada

**Audio Completo**
- [ ] 3 musicas de fase (1 por fase)
- [ ] 1 musica de boss
- [ ] 1 musica de lobby/menu
- [ ] SFX completos (armas, hits, coleta, UI, boss)
- [ ] Musica intensifica com o tempo (layers)

**Tutorial / Onboarding**
- [ ] Primeira run e guiada (tooltips explicando controles, XP, level up)
- [ ] Nao e uma fase separada — e a fase do Cemiterio com overlay de instrucoes
- [ ] Desativa apos primeira run

**Performance**
- [ ] Object pooling para inimigos e projeteis
- [ ] MultiMeshInstance3D para renderizar hordas
- [ ] 60 FPS com 1000+ inimigos
- [ ] Profiling e otimizacao

**Steam Integration Final**
- [ ] Steam Achievements (10-15 basicos)
- [ ] Steam Cloud Save
- [ ] Steam Rich Presence
- [ ] Steam Store page (capsulas, screenshots, trailer)

**QA**
- [ ] Teste de balanceamento (solo e co-op)
- [ ] Teste de networking (latencia, desync, desconexao)
- [ ] Teste de performance em hardware variado
- [ ] Bug fixing geral

**Opcoes**
- [ ] Volume (musica, SFX, master)
- [ ] Resolucao e modo de tela
- [ ] Keybindings customizaveis
- [ ] Gamepad support

**Localizacao**
- [ ] Portugues (BR) — idioma principal
- [ ] Ingles — necessario pra Steam global

---

## Fase 6+ — Pos Early Access (Roadmap)

**Objetivo:** Expandir o jogo com base no feedback dos jogadores.

**Sem prazo fixo — priorizar pelo feedback da comunidade.**

### Possibilidades
- [ ] Fases 4-10 (Toquio, Vulcao, Oceano, Arena, Espaco, Castelo, Mundo Doce)
- [ ] Personagens restantes (Pirata, Engenheiro, Vampiro, Gladiador, Chef, ???)
- [ ] Armas restantes (20+ armas do GDD)
- [ ] Todos os itens e evolucoes
- [ ] Daily Challenge (requer backend + leaderboard)
- [ ] Boss Rush mode
- [ ] Hyper Mode
- [ ] Host migration no multiplayer
- [ ] Reconnect ao multiplayer
- [ ] Workshop da Steam (mods)
- [ ] DLC packs tematicos
- [ ] Modo Inverse (DLC standalone)
- [ ] Ranking online
- [ ] Replays
