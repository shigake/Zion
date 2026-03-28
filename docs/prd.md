# Zion — PRD Master (v2.60)

## Visao Geral

Survivors roguelite 3D com visual pixel art billboard. Co-op online ate 4 jogadores.
14 personagens, 28 armas, 10 fases, 10 bosses, 12 evolucoes, 19 itens, 7 reliquias, 13 achievements.

---

## Estado Atual (Implementado)

### Core Game
- [x] 14 personagens jogaveis (ronin, soldado, mago, berserker, ninja, necro, pirata, engenheiro, vampiro, gladiador, chef, mystery, amazona, bruxa)
- [x] 28 armas (10 melee, 10 ranged, 8 summon/special)
- [x] 19 itens passivos com 5 niveis cada
- [x] 12 evolucoes de arma (arma lv8 + item lv5)
- [x] 7 reliquias pre-run
- [x] 10 fases com props pixel art tematicos
- [x] 10 bosses com 3 fases cada
- [x] 40 monstros tematicos (4 por stage)
- [x] 12 upgrades permanentes na loja
- [x] 6 sinergias elementais
- [x] 10 eventos especiais
- [x] 13 achievements
- [x] Sistema de mutacoes/ascensao (6 modifiers)
- [x] Modo Endless, Boss Rush, Hyper, New Game+
- [x] Desafio Diario com leaderboard local

### Visual
- [x] 279+ sprites pixel art (personagens, inimigos, bosses, armas, pickups, props, UI)
- [x] Billboard Sprite3D com NEAREST filter
- [x] Themed HP bar por personagem
- [x] HUD com armas separadas de itens
- [x] Kill streak text (COMBO, MASSACRE, GODLIKE)
- [x] Death animation (flash + scale + fade)
- [x] Hit squash-stretch elastico
- [x] Screen flash no level up
- [x] Vignette vermelha no low HP
- [x] Boss entrance (shake + slowmo + flash)

### Audio
- [x] 12 musicas (Suno AI chiptune)
- [x] 10 SFX sintetizados (hit, kill, collect, level_up, dash, boss, menu, hurt, evolve, game_over)
- [x] AudioManager com crossfade, pool, cooldown

### Multiplayer
- [x] Co-op 2-4 jogadores via ENet
- [x] Host-client architecture
- [x] Scaling de dificuldade por numero de jogadores
- [x] Level up com pausa global + "Aguardando..."
- [x] Projeteis falsos nos clients
- [x] Host migration + reconnect
- [x] Lobby state sync com sprites
- [x] Revive com sacrificio (tombstone)

### Sistemas
- [x] Save system local (JSON)
- [x] Balanceamento matematico verificado (6 regras)
- [x] Object pooling (inimigos + projeteis)
- [x] MultiMesh para hordas 100+
- [x] Pickup cap (200) com auto-collect
- [x] Spatial grid O(1) neighbor queries
- [x] Auto-play mode (aleatorio + auto level up)

---

## FASE A — Visual Polish (Prioridade Alta)

### A1. Sprite Walk Animation
**Objetivo**: Todos os personagens e inimigos devem ter animacao de andar.

**Personagens (14 spritesheets)**:
- Formato: spritesheet horizontal 128x32 (4 frames de 32x32)
- Frame 0: idle (pe juntos)
- Frame 1: passo esquerdo
- Frame 2: idle (pe juntos)
- Frame 3: passo direito
- AnimatedSprite3D no player com 8 FPS

**Inimigos (16 + 40 tematicos = 56 spritesheets)**:
- Mesmo formato 128x32 (4 frames)
- Idle: 2 frames alternando (bob sutil)
- Walk: 4 frames completos
- Prioridade: inimigos genericos primeiro, tematicos depois

**Implementacao**:
- Criar sprite generator que gera spritesheets (4 frames lado a lado)
- Substituir Sprite3D por AnimatedSprite3D no enemy_base.gd e player.gd
- Detectar movimento via velocity.length() > 0.5 pra trocar idle/walk

### A2. Efeitos de Arma Melee
**Objetivo**: Armas melee devem mostrar visual de ataque.

**Slash trail sprite** (16x32, 3 frames):
- katana_slash.png — arco branco/azul
- scythe_slash.png — arco roxo circular
- axe_slash.png — arco vermelho pesado
- hammer_slam.png — impacto no chao
- whip_crack.png — linha ondulada
- lance_thrust.png — linha reta com ponta
- nunchaku_swing.png — arco duplo
- dual_katana_slash.png — X cruzado
- cloud_sword_wave.png — onda de energia azul
- boxing_punch.png — impacto de soco

**Implementacao**:
- Sprite3D temporario no ponto de ataque
- Dura 0.15-0.3s com fade out
- Segue a direcao do ataque

### A3. Props Animados
**Objetivo**: Cenarios mais vivos com props que se movem.

**Por stage**:
- Cemetery: lanternas piscam (modulate pulse), mao de esqueleto treme
- Forest: cogumelos pulsam (scale pulse), fairy circle roda
- Farm: espantalho balanca, milho ondula
- Tokyo: neon signs piscam cores, vending machines tem luz
- Volcano: geysers pulsam, lava borbulha
- Ocean: algas ondulam, bolhas sobem
- Arena: tochas piscam, bandeiras ondulam
- Space: consoles piscam LEDs, portal gira
- Castle: velas piscam, teias tremem
- Candy: pirulitos giram, cupcakes pulam

**Implementacao**:
- _process() nos stage props com sin() animations
- Modulate pulse pra luzes
- Scale pulse pra organicos
- Rotation pra objetos giratorios

### A4. Tela de Loading
**Objetivo**: Transicao suave entre telas.

- ColorRect preto com fade in/out (0.5s)
- Texto "Carregando..." com animacao de pontos
- Sprite do personagem selecionado no centro
- Tip de gameplay aleatorio embaixo
- Barra de progresso (fake, preenche em 1-2s)

### A5. Sprite de Boss no Stage
**Objetivo**: Bosses devem ter presenca visual maior.

- Boss sprites 64x64 ja existem
- Adicionar aura/glow pulsante ao redor do boss
- Boss name label flutuante acima do sprite
- Entrada dramatica: boss aparece com zoom + shake

---

## FASE B — Gameplay Depth (Prioridade Alta)

### B1. Mecanicas Unicas por Stage
**Objetivo**: Cada stage tem uma mecanica ambiental unica.

| Stage | Mecanica | Efeito |
|-------|----------|--------|
| Cemetery | Tumulos destrutiveis | Dropam power-ups aleatorios |
| Forest | Cogumelos de buff | Tocou = buff aleatorio 10s (speed/damage/area) |
| Farm | Milharal | Jogador fica invisivel pra inimigos dentro do milho |
| Tokyo | Paineis eletricos | Zonas no chao causam 5 dano/s eletrico |
| Volcano | Lava pools | Zonas causam 10 dano/s fogo, inimigos de fogo imunes |
| Ocean | Correntes | Empurram jogador e inimigos numa direcao |
| Arena | Plateia | Joga itens aleatorios (cura ou bomba) a cada 30s |
| Space | Zero-G zones | +50% speed, -30% controle dentro das zonas |
| Castle | Zonas escuras | Inimigos +30% dano, tochas criam zonas seguras |
| Candy | Caramelo | Zonas pegajosas -50% speed |

**Implementacao**:
- Cada stage_props.gd cria Area3D com CollisionShape3D
- body_entered/body_exited aplicam efeitos
- Visual: sprite de zona no chao (32x32, semi-transparente)

### B2. Enemy Behaviors por Stage
**Objetivo**: Inimigos tematicos com ataques unicos.

| Stage | Inimigo | Comportamento Especial |
|-------|---------|----------------------|
| Cemetery | Wraith | Teleporta a cada 5s, aparece perto do player |
| Forest | Treant | Parado ate player chegar perto, depois corre rapido |
| Farm | Scarecrow | Spawna corvos ao morrer (3 mini-enemies) |
| Tokyo | Drone | Atira laser a cada 3s (projetil lento) |
| Volcano | Golem | Imune a fogo, explode ao morrer (AoE) |
| Ocean | Jellyfish | Paralisa player por 1s ao tocar |
| Arena | Lion | Carga rapida em linha reta a cada 4s |
| Space | Xenomorph | Invisivel ate atacar, dano 2x |
| Castle | Gargoyle | Voa, ataca de cima, esquiva projeteis |
| Candy | Gummy | Divide em 2 menores ao morrer |

**Implementacao**:
- Scripts especificos por inimigo (ex: wraith_behavior.gd)
- Herda de enemy_base.gd, override _physics_process
- Ativado quando stage-themed sprite e carregado

### B3. Sinergias Avancadas
**Objetivo**: Mais combinacoes entre armas/itens.

**Novas sinergias**:
- Fogo + Veneno = Toxic Fire (DoT 2x, area verde-laranja)
- Gelo + Dark = Shadow Freeze (congela + drena vida)
- Eletrico + Veneno = Toxic Shock (paralisa + DoT)
- Fisico + Fisico = Berserker Rage (velocidade de ataque +50% por 5s apos 10 hits)
- Summon + Summon = Horde Master (summons +1, dano +20%)
- Qualquer 3 elementos = Prism Burst (explosao prismatica AoE)

**Implementacao**:
- Expandir SynergySystem com novas combinacoes
- Visual: particulas coloridas na cor da sinergia
- Texto flutuante com nome da sinergia

### B4. Boss Patterns Elaborados
**Objetivo**: Cada boss tem ataques mais variados e telegrafados.

**Melhorias por boss**:
- Indicador visual antes de atacar (circulo vermelho no chao, 0.5s warning)
- Padroes de projeteis mais complexos (espiral, shotgun, grid)
- Fase de furia (HP < 10%): velocidade +50%, ataques +30%
- Minions tematicos do stage (nao genericos)
- Drop de loot unico ao morrer (item raro garantido)

### B5. Novas Armas (4 adicionais)
**Objetivo**: Expandir opcoes de build.

| Arma | Tipo | Elemento | Descricao |
|------|------|----------|-----------|
| Boomerang | ranged | physical | Vai e volta, perfura na ida |
| Tornado | summon | ice | Vortex giratorio que puxa inimigos |
| Chain Whip | melee | electric | Chicote que chains entre inimigos |
| Blood Orb | summon | dark | Orbe que drena vida dos inimigos proximos |

---

## FASE C — Polish & UX (Prioridade Media)

### C1. Tutorial Interativo
**Objetivo**: Primeiro run guiada sem frustrar.

- Overlay semi-transparente com setas indicativas
- Passo 1: "Use WASD para mover" (espera player mover)
- Passo 2: "Sua arma ataca automaticamente!" (espera primeiro kill)
- Passo 3: "Colete as gemas azuis!" (espera coletar XP)
- Passo 4: "Escolha um upgrade!" (espera level up)
- Passo 5: "Use ESPACO para dash!" (espera dash)
- Desativa apos completar (salva no SaveManager)
- Botao "Pular tutorial" visivel

### C2. Dialogos de Boss
**Objetivo**: Bosses tem personalidade.

- Antes do boss aparecer: balao de dialogo com fala do boss (2-3 linhas)
- Ao derrotar: fala de derrota
- Texto pixel art em balao, auto-skip em 3s
- Exemplos:
  - Necromancer: "Vocês ousam invadir meu domínio? Meus mortos vão festejar!"
  - Demon Lord: "Bem-vindos ao inferno. Não há saída."
  - Sugar King: "Quem quer doces? HAHAHAHA!"

### C3. Achievement Popup Bonito
**Objetivo**: Conquistas devem sentir-se recompensadoras.

- Slide-in do lado direito da tela
- Icone do achievement (sprite 16x16) + nome + descricao
- Fundo dourado com brilho
- Som especial de achievement (novo SFX)
- Permanece 3s, depois slide-out
- Queue: se varias conquistas ao mesmo tempo, mostra uma por vez

### C4. Tela de Estatisticas Pos-Run
**Objetivo**: Expandir a tela de game over.

- Grafico de DPS ao longo do tempo (linha simples)
- Ranking de armas por dano total
- Mapa de calor de mortes de inimigos (simplificado)
- Comparacao com run anterior
- Botao "Compartilhar" (screenshot salva em user://)

### C5. Mapa de Selecao de Fases
**Objetivo**: Substituir grid por mapa visual.

- Mapa estilo Super Mario World (nodes conectados por caminhos)
- Cada node e o sprite do stage (32x32)
- Caminho dourado entre stages desbloqueados
- Animacao de andar entre nodes
- Preview do boss ao hover

### C6. Inventario Visual
**Objetivo**: Ver todos os itens/armas durante a run.

- Tecla TAB abre inventario overlay
- Grid de armas com nivel e DPS
- Grid de itens com efeito
- Barra de progresso pra evolucoes (arma lv? + item lv?)
- Mostra sinergias ativas

---

## FASE D — Audio Completo

### D1. SFX Faltantes

**Combate (15 SFX)**:
| SFX | Descricao | Uso |
|-----|-----------|-----|
| sword_slash.wav | Corte rapido de espada | Katana, dual katana, cloud sword |
| axe_chop.wav | Impacto pesado de machado | Axe |
| scythe_swoosh.wav | Swoosh circular | Scythe |
| whip_crack.wav | Estalo de chicote | Whip |
| hammer_slam.wav | Impacto no chao | Hammer |
| lance_thrust.wav | Investida rapida | Lance |
| punch_hit.wav | Soco | Boxing gloves, nunchaku |
| gun_shot.wav | Tiro de arma | Machinegun, dual pistol |
| bow_release.wav | Flecha sendo solta | Elven bow, crossbow |
| magic_cast.wav | Conjuracao magica | Staff, ice staff, magic book |
| explosion.wav | Explosao | Bazooka, time bomb |
| electric_zap.wav | Choque eletrico | Lightning chain, totem |
| poison_splash.wav | Liquido toxico | Poison bottle |
| fire_whoosh.wav | Rajada de fogo | Flamethrower |
| summon_pop.wav | Invocacao | Necro, drone, totem |

**UI (8 SFX)**:
| SFX | Descricao | Uso |
|-----|-----------|-----|
| collect_crystal.wav | Coleta de cristal | Crystal pickup |
| heal.wav | Cura | Health pickup |
| achievement.wav | Conquista desbloqueada | Achievement popup |
| reroll.wav | Reroll no level up | Reroll button |
| banish.wav | Banish no level up | Banish button |
| select.wav | Selecao de opcao | Level up choice |
| equip.wav | Equipar arma/item | Level up confirm |
| error.wav | Acao invalida | Locked character, insufficient crystals |

**Ambiente (6 SFX)**:
| SFX | Descricao | Uso |
|-----|-----------|-----|
| footstep.wav | Passo do jogador | A cada frame de walk |
| enemy_growl.wav | Grunhido de inimigo | Spawn de inimigo especial |
| chest_open.wav | Abrir bau | Evolution chest, event chest |
| portal_hum.wav | Zumbido de portal | Portal weapon, dimensional portal event |
| lava_bubble.wav | Borbulho de lava | Volcano stage ambient |
| wind.wav | Vento | Space stage, cemetery ambient |

**Boss (4 SFX)**:
| SFX | Descricao | Uso |
|-----|-----------|-----|
| boss_roar.wav | Rugido do boss | Boss entrance |
| boss_attack.wav | Ataque do boss | Boss special attacks |
| boss_phase.wav | Transicao de fase | Boss HP threshold |
| boss_death.wav | Morte do boss | Boss defeated |

**Total SFX necessarios: 33 novos (temos 10, faltam 33)**

### D2. Musica Adicional
- victory.mp3 — musica de vitoria (boss derrotado)
- shop.mp3 — musica da loja (calma, coins)
- lobby.mp3 — musica do lobby multiplayer
- game_over.mp3 — musica de derrota (triste, curta)

---

## FASE E — Infraestrutura

### E1. Steam Integration
- [ ] GodotSteam GDExtension
- [ ] Steam App ID
- [ ] Steam Achievements (13)
- [ ] Steam Cloud Save
- [ ] Steam Rich Presence
- [ ] Steam Networking Sockets (substituir ENet)
- [ ] Steam Leaderboards (daily challenge)

### E2. Build Pipeline
- [ ] Export preset Windows Desktop
- [ ] Export preset Linux
- [ ] GitHub Actions CI/CD
- [ ] Auto-versioning from VERSION file
- [ ] Itch.io deploy script

### E3. Quality Assurance
- [ ] Auto-tester expandido (todas 10 fases)
- [ ] Balance test automatico (DPS curves)
- [ ] Performance profiling (target 60fps com 500 inimigos)
- [ ] Multiplayer stress test (4 jogadores, 30 min)
- [ ] Crash report collection via Telemetry

---

## Cronograma Estimado

| Fase | Escopo | Prioridade |
|------|--------|-----------|
| A (Visual) | Walk anims, slash trails, props animados, loading | Alta |
| B (Gameplay) | Stage mechanics, enemy AI, sinergias, boss patterns | Alta |
| C (Polish) | Tutorial, dialogos, achievements, stats, mapa | Media |
| D (Audio) | 33 SFX + 4 musicas | Media |
| E (Infra) | Steam, build, QA | Baixa (pre-launch) |

---

## Metricas de Sucesso

- Run media de 15-20 min pra jogador novo
- 30-40 level ups em 30 min
- Boss mata ~50% na primeira tentativa
- 60 FPS com 500 inimigos
- 0 crashes em 10 runs consecutivas
- Multiplayer funcional com <100ms de latencia
