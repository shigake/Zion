# Zion - PRD (Product Requirements Document)

---

## Fase 0 — POC (Proof of Concept)

**Objetivo:** Validar que o jogo e divertido. So mecanica, sem arte, sem polish.

**Duracao estimada:** 2 semanas

**Criterio de sucesso:** Jogar 5 min e pensar "quero continuar jogando"

### O que entra

**Jogador**
- [x] Movimento WASD (top-down 3D com camera fixa)
- [x] Dash com cooldown (Space)
- [x] Barra de HP
- [x] Morte e tela de game over

**Armas (2 apenas)**
- [x] Espada Samurai — ataque automatico melee, corta em arco na frente
- [x] Staff — projetil magico homing que persegue o inimigo mais proximo

**Inimigos (2 tipos)**
- [x] Slime — lento, pouca vida, anda em direcao ao jogador
- [x] Bat — rapido, pouca vida, anda em direcao ao jogador

**Spawner**
- [x] Inimigos spawnam fora da tela
- [x] Quantidade aumenta com o tempo (scaling linear simples)

**XP e Level Up**
- [x] Inimigos dropam gema de XP ao morrer
- [x] Gemas sao atraidas ao jogador (magnetismo)
- [x] Barra de XP no HUD
- [x] Ao encher: jogo pausa, 3 opcoes aparecem
- [x] Opcoes possiveis: nova arma, upgrade de arma existente, item passivo

**Itens Passivos (3 apenas)**
- [x] Botas de Hermes — +15% velocidade
- [x] Luva de Velocidade — +20% attack speed
- [x] Coracao de Dragao — +20% HP maximo

**HUD**
- [x] Barra de HP
- [x] Barra de XP + nivel
- [x] Timer
- [x] Kill count

**Fase**
- [x] 1 arena unica (chao plano, sem decoracao, so ground + cor de fundo)
- [x] Sem boss
- [x] Sem eventos
- [x] Sem limite de tempo (endless ate morrer)

**Visual**
- [x] Primitivas 3D (capsulas, esferas, cubos) com cores solidas
- [x] Nada de arte. Jogador = capsula verde. Inimigo = cubo vermelho. Projetil = esfera azul.
- [x] Cel-shader basico so pra validar a estetica

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
- [x] Selecao de personagem (3 personagens: Ronin, Soldado, Mago)
- [x] Cada um com arma inicial e passiva diferentes
- [x] Animacoes basicas (idle, walk, hit, death) — procedural animator

**Armas (6 totais)**
- [x] Espada Samurai (melee, corte em arco)
- [x] Metralhadora (ranged, spray de projeteis)
- [x] Staff (ranged, homing)
- [x] Foice (melee, gira ao redor do jogador)
- [x] Bazuca (ranged, explosao em area)
- [x] Necromante (summon, invoca esqueletos)

**Armas — Level Up (1 a 8)**
- [x] Cada level melhora stats (dano, area, projeteis, velocidade)
- [x] Valores balanceados para 30 min de run

**Itens Passivos (6 totais)**
- [x] Botas de Hermes (+velocidade)
- [x] Luva de Velocidade (+attack speed)
- [x] Coracao de Dragao (+HP)
- [x] Cristal Arcano (+area de efeito)
- [x] Ima (+range de coleta)
- [x] Relogio Quebrado (-cooldown)

**Itens — Level Up (1 a 5)**
- [x] Cada level aumenta o efeito

**Evolucao de Arma (2 evolucoes para validar o sistema)**
- [x] Espada Samurai + Luva de Velocidade = Zangetsu
- [x] Staff + Cristal Arcano = Cajado do Apocalipse
- [x] Bau de evolucao aparece no mapa quando requisitos sao atendidos

**Fase: Cemiterio Assombrado**
- [x] Ambiente 3D: chao de terra, lapides, neblina, lua
- [x] Lapides destrutiveis que dropam power-ups
- [x] 30 minutos de duracao

**Inimigos (5 tipos)**
- [x] Slime (basico, lento)
- [x] Bat (rapido, voador)
- [x] Skeleton (medio, joga ossos)
- [x] Zombie Corredor (rapido, medio HP)
- [x] Ghost (atravessa obstaculos)

**Spawn por tempo**
- [x] Min 0-5: Slimes
- [x] Min 5-10: Slimes + Bats
- [x] Min 10-15: Skeletons + Zombies + Mini-boss
- [x] Min 15-25: Mix de tudo, crescente
- [x] Min 25-30: Boss + horda

**Mini-boss**
- [x] Zombie Gigante (HP alto, agarra)
- [x] Barra de vida visivel
- [x] Dropa bau raro

**Boss Final**
- [x] Necromancer King
- [x] Barra de vida no topo da tela
- [x] 3 fases de comportamento (100-75%, 75-25%, 25-0%)
- [x] Invoca hordas + lanca magias
- [x] Derrotar = vitoria

**Tela de Level Up**
- [x] 3 opcoes (arma/item)
- [x] Reroll (1 gratis por run)
- [x] Visual limpo

**HUD Completo**
- [x] HP, XP, nivel, timer, kill count
- [x] Icones das armas equipadas
- [x] Icones dos itens equipados
- [x] Boss HP bar

**Tela de Resultado**
- [x] Stats da run (tempo, kills, dano, nivel)
- [x] Botao de replay

**Visual**
- [x] Modelos low-poly com cel-shader polido
- [x] Ambiente do Cemiterio com assets (procedurais)
- [x] Efeitos de particula basicos (hit, morte, coleta)

**Audio basico**
- [x] Sistema de audio com crossfade e SFX pool (AudioManager)
- [ ] Arquivos de audio reais (.ogg/.wav) — sistema pronto, faltam assets

### O que NAO entra
- ~~Multiplayer~~ (implementado na Fase 3)
- ~~Loja / meta-progressao~~ (implementado na Fase 2)
- ~~Reliquias~~ (implementado)
- ~~Eventos especiais~~ (implementado)
- ~~Outras fases~~ (10 fases implementadas)
- ~~Menu principal elaborado~~ (implementado)
- ~~Save system~~ (implementado)
- ~~Steam integration~~ (stub implementado)

---

## Fase 2 — Meta-progressao + Menu

**Objetivo:** Loop completo entre runs. Jogar, morrer, gastar moeda, jogar de novo mais forte.

**Duracao estimada:** 3 semanas

**Pre-requisito:** Fase 1 concluida

### O que entra

**Menu Principal**
- [x] Tela titulo
- [x] Jogar (selecao de personagem)
- [x] Loja
- [x] Opcoes (volume, resolucao, fullscreen)

**Moeda: Cristais**
- [x] Dropam dos inimigos durante a run
- [x] Quantidade varia por tipo de inimigo
- [x] Creditados ao final da run (mesmo se morrer)

**Loja — Upgrades Permanentes (6 iniciais)**
- [x] HP Maximo (+10 HP por level, max 10)
- [x] Velocidade (+5% por level, max 8)
- [x] Dano Base (+5% por level, max 10)
- [x] Armadura (reduz dano, max 8)
- [x] XP Bonus (+10% por level, max 8)
- [x] Magnetismo (+range coleta, max 5)

**Save System**
- [x] Save local: perfil, cristais, upgrades comprados, personagens desbloqueados
- [x] Auto-save ao voltar pro lobby

**Selecao de Personagem**
- [x] Tela de selecao com os 3 personagens (+ 9 desblocaveis)
- [x] Mostra arma inicial e passiva
- [x] Grid layout para 12 personagens

**Selecao de Reliquia (7 reliquias)**
- [x] Ampulheta (run de 40 min ao inves de 30)
- [x] Dados de Ouro (+1 reroll por level up)
- [x] Coracao Extra (+50% HP inicial)
- [x] Bussola (mostra direcao do proximo evento)
- [x] Pergaminho Antigo (comeca com 1 arma extra)
- [x] Medalha de Veterano (+20% XP mas inimigos +15% rapidos)
- [x] Chave Mestre (2x XP de todas as fontes)

**Evolucoes adicionais (12 totais)**
- [x] Zangetsu (Katana + Luva)
- [x] Cajado do Apocalipse (Staff + Cristal)
- [x] Death Scythe (Foice + Relogio)
- [x] Nuke Launcher (Bazuca + Ima)
- [x] Machado de Ragnarok (Axe + Polvora)
- [x] Estrela do Blizzard (Shuriken + Capa)
- [x] Minigun Infernal (Metralhadora + Mira Laser)
- [x] Senhor dos Mortos (Necro + Grimorio)
- [x] Inferno Walker (Lanca-chamas + Gasolina)
- [x] Vampire Whip (Chicote + Sangue de Vampiro)
- [x] Tempestade Eletrica (Corrente Eletrica + Bateria Tesla)
- [x] Tempestade de Flechas (Arco Elfico + Capa)

**Tela de Resultado melhorada**
- [x] Mostra cristais ganhos
- [x] Mostra desbloqueaveis (se houver)
- [x] Mostra dano total
- [x] Botao: Lobby / Replay

---

## Fase 3 — Multiplayer Online

**Objetivo:** 2-4 jogadores jogando juntos online. O jogo funciona em co-op.

**Duracao estimada:** 5 semanas

**Pre-requisito:** Fase 2 concluida

### O que entra

**Steam Integration**
- [ ] GodotSteam GDExtension integrado
- [ ] Steam App ID
- [x] Inicializacao do Steam ao abrir o jogo (stub via SteamManager)

**Lobby System**
- [x] Criar sala (ENet)
- [ ] Listar salas disponiveis (requer Steam)
- [ ] Entrar em sala por convite Steam
- [x] Tela de lobby: mostra jogadores conectados, personagem escolhido, botao "pronto"
- [x] Host inicia quando todos estao prontos

**Networking**
- [x] ENet multiplayer (fallback, Steam Networking Sockets preparado)
- [x] Arquitetura host-client
- [x] Host e autoridade: spawn, dano, drops, boss HP
- [x] Clients enviam: inputs de movimento
- [x] Sync de posicoes (unreliable)
- [x] Sync de eventos criticos (reliable): level up, morte, boss, drops

**Gameplay Online**
- [x] Cada jogador controla seu personagem independentemente
- [x] Inimigos perseguem o jogador mais proximo

**Scaling de Dificuldade**
- [x] HP inimigos: 1x (solo), 1.3x (2p), 1.6x (3p), 2x (4p)
- [x] Spawn rate: 1x (solo), 1.2x (2p), 1.4x (3p), 1.6x (4p)
- [x] Boss HP: 1x (solo), 1.5x (2p), 2x (3p), 2.5x (4p)

**HUD Online**
- [x] HP bars dos aliados (compactas)
- [x] Setas indicando direcao dos aliados fora da tela
- [x] Ping/latencia

**Desconexao**
- [x] Client desconecta: personagem some, scaling ajusta
- [x] Host desconecta: run termina

**Camera**
- [x] Cada jogador tem sua propria camera
- [x] Camera segue o jogador local

---

## Fase 4 — Conteudo (10 Fases Completas)

**Objetivo:** Jogo tem variedade suficiente pra Early Access. 10 fases distintas, 28 armas, conteudo pra ~50h de gameplay.

**Duracao estimada:** 6 semanas

**Pre-requisito:** Fase 3 concluida

### O que entra

**Fase 2: Floresta Encantada**
- [x] Ambiente: floresta magica, cogumelos gigantes, rios brilhantes
- [x] Inimigos tematicos (Evil Pixie, Treant, Corrupted Unicorn, etc)
- [x] Mini-boss: Unicornio Negro
- [x] Boss: Rainha das Fadas (3 fases: teleport, clones, chuva de espinhos)
- [x] Mecanica: cogumelos dao buffs aleatorios ao destruir

**Fase 3: Fazenda do Apocalipse**
- [x] Ambiente: fazenda destruida, silos, milharal
- [x] Inimigos tematicos (Zombie Cow, Killer Chicken, Scarecrow, etc)
- [x] Mini-boss: Touro Mecanico
- [x] Boss: Mega Vaca Alienigena (3 fases: projeteis, abducao, vacas mutantes)
- [x] Mecanica: milharal esconde o jogador dos inimigos

**Fase 4: Toquio Cyberpunk**
- [x] Ambiente: neon, predios, chuva, paineis eletricos
- [x] Inimigos tematicos (Nano Slime, Drone, Robot Samurai, Android, etc)
- [x] Mini-boss: Mecha Ninja
- [x] Boss: AI Overlord (3 fases: drones, virus, system overload)
- [x] Mecanica: paineis eletricos no chao causam dano

**Fase 5: Vulcao Infernal**
- [x] Ambiente: rios de lava, rochas flutuantes, geysers
- [x] Inimigos tematicos (Magma Slime, Fire Imp, Lava Golem, Demon, etc)
- [x] Mini-boss: Cerberus
- [x] Boss: Demon Lord (3 fases: chamas, ground slam, golems de lava)
- [x] Mecanica: zonas de lava causam dano continuo

**Fase 6: Fundo do Oceano**
- [x] Ambiente: corais, bolhas, ruinas submarinas
- [x] Inimigos tematicos (Jellyfish, Flying Fish, Crab, Zombie Shark, etc)
- [x] Mini-boss: Kraken Bebe
- [x] Boss: Leviathan (3 fases: tentaculos, vortex, nuvem de tinta)
- [x] Mecanica: correntes de agua empurram o jogador

**Fase 7: Arena Gladiadora**
- [x] Ambiente: coliseu, pilares, portoes de ferro, tochas
- [x] Inimigos tematicos (Slime Gladiator, Eagle, Centurion, Lion, etc)
- [x] Mini-boss: Gladiador Campeao
- [x] Boss: Imperador Corrompido (3 fases: gladiadores, sword sweep, pilares de fogo)
- [x] Mecanica: plateia joga itens (cura ou dano)

**Fase 8: Estacao Espacial**
- [x] Ambiente: corredores metalicos, janelas com estrelas
- [x] Inimigos tematicos (Alien Parasite, Space Drone, Xenomorph, Mutant, etc)
- [x] Mini-boss: Alien Queen
- [x] Boss: Singularidade (3 fases: gravidade, buraco negro, pull player)
- [x] Mecanica: zonas de gravidade zero (+50% speed)

**Fase 9: Castelo do Vampiro**
- [x] Ambiente: gotico, candelabros, vitrais, caixoes
- [x] Inimigos tematicos (Blood Slime, Vampire Bat, Armor, Gargoyle, etc)
- [x] Mini-boss: Vampiresa
- [x] Boss: Conde Dracula (3 fases: bat form, life drain, blood rain)
- [x] Mecanica: zonas escuras fortalecem inimigos, tochas criam zonas seguras

**Fase 10: Mundo Doce**
- [x] Ambiente: chocolate, sorvete, candy canes, gummy bears
- [x] Inimigos tematicos (Gummy Bear, Candy Bat, Cookie Ninja, Cupcake, etc)
- [x] Mini-boss: Bolo de 3 Andares
- [x] Boss: Rei Acucar (3 fases: candy army, star projectiles, regen)
- [x] Mecanica: zonas de caramelo reduzem velocidade

**Armas (28 totais)**
- [x] 10 melee: Katana, Foice, Machado, Chicote, Lanca, Martelo, Nunchaku, Katana Dupla, Espada Cloud, Luvas de Boxe
- [x] 10 ranged: Metralhadora, Staff, Bazuca, Shuriken, Pistola Dupla, Lanca-chamas, Cajado de Gelo, Besta, Canhao de Plasma, Arco Elfico
- [x] 8 summon: Necromante, Drone, Totem, Garrafa de Veneno, Corrente Eletrica, Livro Magico, Bomba Relogio, Portal

**Itens (19 totais)**
- [x] Todos os 19 itens implementados com efeitos funcionais

**Personagens (12 totais)**
- [x] Ronin, Soldado, Mago, Berserker, Ninja
- [x] Necro, Pirata, Engenheiro, Vampiro, Gladiador, Chef
- [x] ??? (personagem secreto, todas as armas nivel 1)
- [x] Desbloqueio por conquista (matar X inimigos, completar fases, desbloquear todos)

**Sistema de Eventos (10 eventos)**
- [x] Horda Dourada, Treasure Goblin, Merchant
- [x] Eclipse, Chuva de Meteoros, Desafio do Anjo
- [x] Portal Dimensional, Fever Mode, Chest Mimic
- [x] Roulette

**Modo Endless**
- [x] Sem boss, sem limite de tempo
- [x] Dificuldade continua escalando
- [x] Leaderboard local (tempo sobrevivido)

**Upgrades de Loja (12 totais)**
- [x] HP, Velocidade, Dano, Armadura, XP, Magnetismo
- [x] Cooldown Reduction, Sorte, Reroll, Banish, Revive, Slots de Arma

**Sinergias Elementais (6 combinacoes)**
- [x] Fogo + Fogo = explosao ao matar
- [x] Gelo + Gelo = estilhacos ao congelar
- [x] Eletrico + Eletrico = chain lightning
- [x] Dark + Dark = area de trevas passiva
- [x] Fogo + Gelo = steam cloud
- [x] Eletrico + Gelo = condutor massivo

**Selecao de Fase**
- [x] Tela de selecao de fase (grid 5 colunas)
- [x] Fases desbloqueiam progressivamente

---

## Fase 5 — Polish + Early Access Launch

**Objetivo:** Jogo pronto pra vender no Steam Early Access.

**Duracao estimada:** 4 semanas

**Pre-requisito:** Fase 4 concluida

### O que entra

**Visual Final**
- [x] Modelos low-poly com cel-shader polido
- [x] Ambientes das 10 fases com props procedurais
- [x] Efeitos de particula (hit, morte, coleta, level up, evolucao, boss)
- [x] Animacoes procedurais (idle, walk, dash, hit, death)
- [x] Weapon trails (katana, foice, staff, bazuca)
- [x] Vignette de HP baixo

**Audio Completo**
- [x] Sistema de audio com crossfade, SFX pool, auto-load
- [x] 12 musicas suportadas (menu, 10 stages, boss)
- [x] 10 SFX suportados (hit, kill, collect, level_up, etc)
- [ ] Arquivos de audio reais (.ogg/.wav)

**Tutorial / Onboarding**
- [x] Primeira run guiada (tutorial overlay com instrucoes)
- [x] Desativa apos primeira run

**Performance**
- [x] Object pooling para inimigos (11 tipos via ObjectPool)
- [x] Object pooling para projeteis (bullets, rockets, arrows)
- [x] MultiMeshInstance3D para renderizar hordas (MultiMeshManager autoload)
- [x] 60 FPS target

**Steam Integration**
- [x] SteamManager stub (auto-detect GodotSteam)
- [x] NetworkBackend enum (ENET/STEAM) em MultiplayerManager
- [ ] Steam Achievements
- [ ] Steam Cloud Save
- [ ] Steam Rich Presence
- [ ] Steam Store page

**Achievements (13)**
- [x] Meu Primeiro Passeio (sobreviva 5 min)
- [x] Isso Escala (6 armas evoluidas)
- [x] Speedrunner (boss em < 15 min)
- [x] Colecionador (todos os personagens)
- [x] A Vaca Foi Pro Brejo (Farm sem dano de vaca)
- [x] Ninguem Merece (morra em 10s)
- [x] Genocidio (10k kills numa run)
- [x] Doce Vinganca (complete Candy)
- [x] I Am The Storm (3 armas eletricas evoluidas)
- [x] Pacifista (3 min sem atacar)
- [x] Matrix (dodge 100 projeteis)
- [x] One Punch (boss com 1 hit)
- [x] Lucky Day (5 itens lendarios)

**QA**
- [x] Teste de balanceamento (balance_test.gd)
- [x] Bug fixing geral

**Opcoes**
- [x] Volume (musica, SFX, master)
- [x] Resolucao e modo de tela (janela, fullscreen, borderless)
- [x] Keybindings customizaveis
- [x] Gamepad support

**Localizacao**
- [x] Portugues (BR) — idioma principal
- [x] Sistema i18n (LocaleManager)

---

## Fase 6+ — Pos Early Access (Roadmap)

**Objetivo:** Expandir o jogo com base no feedback dos jogadores.

**Sem prazo fixo — priorizar pelo feedback da comunidade.**

### Implementado
- [x] Fases 4-10 (Toquio, Vulcao, Oceano, Arena, Espaco, Castelo, Mundo Doce)
- [x] Personagens restantes (Pirata, Engenheiro, Vampiro, Gladiador, Chef, ???)
- [x] Armas restantes (28 armas totais)
- [x] Todos os itens e evolucoes (19 itens, 12 evolucoes)

### Pendente
- [ ] Daily Challenge (requer backend + leaderboard online)
- [x] Boss Rush mode (10 bosses sequenciais)
- [x] Hyper Mode (2x velocidade, 2x spawns, 2x XP)
- [ ] Host migration no multiplayer
- [ ] Reconnect ao multiplayer
- [ ] Workshop da Steam (mods)
- [ ] DLC packs tematicos
- [ ] Modo Inverse (DLC standalone)
- [ ] Ranking online
- [ ] Replays
