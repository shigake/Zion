# Zion - Game Design Document

## Visao Geral

**Nome:** Zion
**Genero:** Survivors / Roguelite
**Inspiracoes:** Vampire Survivors, The Spell Brigade, Ravenswatch
**Plataforma:** Steam (PC)
**Estilo Visual:** 3D low-poly estilizado com cel-shading (inspiracao Zelda BotW)
**Engine:** Godot 4 (GDScript)
**Multiplayer:** Online co-op ate 4 jogadores (Steam Networking Sockets)
**Equipe:** 3 devs, full-time vibe coding com Claude
**Narrativa:** Ver [story.md](story.md) para lore completo

## Premissa Narrativa

**Zion** era o ultimo santuario entre dimensoes — um ponto de convergencia mantido por um cristal primordial: o **Coracao de Zion**. Algo o estilhacou, criando **fendas dimensionais** que corrompem realidades inteiras.

Os jogadores sao **Fragmentados** — pessoas de diferentes realidades que carregam estilhacos microscopicos do cristal. Sao arrancados de seus mundos e jogados nas fendas. Sua missao: fechar as 7 fendas, libertar os **Sentinelas Corrompidos** (antigos guardioes de Zion presos pela corrupcao), e reconstruir Zion.

> *"Zion nao e onde voce chega. E o que voce constroi no caminho."*

## Conceito

O jogador controla um Fragmentado em uma arena vista de cima, enfrentando hordas de criaturas corrompidas pela energia dimensional. As armas atacam automaticamente e o jogador foca em posicionamento e escolha de upgrades. A cada level up, escolhe entre 3 opcoes de arma ou item passivo. O objetivo e sobreviver 30 minutos, derrotar o Sentinela Corrompido da fenda e restaurar mais um pedaco de Zion.

Os cristais coletados dos inimigos nao sao apenas moeda — sao **fragmentos de Zion tentando se reunir**. A loja entre runs e **Zion se reconstruindo atraves de voce**. A morte nao e game over — o estilhaco te **rebobina ao ponto de convergencia**, mais forte que antes.

## Pilares de Design

1. **Caos Divertido** - tela cheia de inimigos, efeitos e dano. A sensacao de poder cresce a cada minuto.
2. **Variedade** - muitas combinacoes de armas, itens e personagens pra cada run ser diferente.
3. **Progressao Satisfatoria** - tanto dentro da run (ficando mais forte) quanto entre runs (loja permanente). Narrativamente: cada upgrade e Zion se reconstruindo.
4. **Narrativa Ambiental** - cada fenda conta uma historia. Bosses sao Sentinelas prisioneiros, nao viloes. O jogador liberta, nao destroi.
5. **Descoberta** - a historia se revela aos poucos via loading screens, dialogos de boss, backstories de personagens e o misterio do ???.

## Loop de Gameplay (Narrativo)

```
Escolhe Fragmentado + Reliquia
        |
        v
    Entra na Fenda Dimensional
        |
        v
  Enfrenta criaturas corrompidas → Coleta fragmentos de Zion (XP)
        |                                      |
        v                                      v
  Level Up → Escolhe Upgrade           Armas evoluem (ressonancia)
        |
        v
  Eventos Dimensionais (hordas, portais, anomalias)
        |
        v
    Sentinela Corrompido aparece (min 25-30)
        |
        v
  Sentinela libertado → Fenda se fecha → Cristais se fundem ao estilhaco
        |
        v
  Hub de Zion → Loja (Zion se reconstruindo) → Proxima Fenda
```

**Morte:** O estilhaco rebobina o Fragmentado ao hub. Nao e game over — e Zion te puxando de volta.
**Vitoria:** O Sentinela e libertado, nao morto. A fenda se fecha. Mais um pedaco de Zion restaurado.

## Decisoes Tecnicas

### Multiplayer Online (4 players)
- **Arquitetura:** Host-client (listen server) — um jogador e o host
- **Networking:** Steam Networking Sockets (via GodotSteam GDExtension)
  - NAT traversal resolvido pelo Steam
  - Sem custo de servidor dedicado
  - Matchmaking via Steam Lobby
- **Sincronizacao:** Enemy spawns deterministicos (seed compartilhada), inputs dos clients enviados ao host, posicoes sincronizadas
- **Alternativa offline:** Solo mode funciona sem Steam (ENet local para testes)

### Estilo Visual
- **Referencia:** Zelda Breath of the Wild (cel-shading, cores suaves, mundo estilizado)
- **Implementacao realista:** 3D low-poly com cel-shader no Godot 4
- **Camera:** Top-down 3D com angulo leve (isometrico suave, ~45-60 graus)
- **Assets:** Low-poly estilizados com outline shader + toon shading
- **Considerar:** Assets do mercado (Kenney, Quaternius) como base para prototipar rapido

### Engine
- **Godot 4.x** com GDScript
- GodotSteam para Steam integration + networking
- Plugins: GodotSteam, possivelmente Phantom Camera para camera system

## Modos de Jogo

### Release 1 (M1-M4)
| Modo | Descricao |
|---|---|
| **Normal** | 30 min, dificuldade crescente, boss no final |
| **Endless** | Sem limite de tempo, leaderboard de tempo sobrevivido |
| **Co-op Online** | 2-4 players, normal ou endless |

### Pos-Release (Updates/DLC)
| Modo | Descricao | Justificativa Narrativa |
|---|---|---|
| **Boss Rush** | So bosses, um atras do outro | Revisitar memorias dos Sentinelas — treino, nao combate |
| **Daily Challenge** | Seed fixa por dia, leaderboard global | Micro-fraturas que surgem todo dia com configuracoes unicas |
| **Hyper Mode** | Tudo 2x mais rapido | A fenda esta instavel — tudo acelera |
| **Inverse** | Voce e o boss (DLC standalone) | Jogue como um Sentinela Corrompido |

## Stage Mechanics (Environmental Hazards)

Each stage has a unique environmental mechanic that affects gameplay:

| Stage | Hazard | Effect |
|-------|--------|--------|
| Cemiterio | Tumulos destrutiveis | Quebrar tumulos libera esqueletos extras mas tambem drops raros |
| Floresta | Cogumelos de buff/debuff | Pisar em cogumelos da buff aleatorio (velocidade, dano) ou debuff (slow, poison) |
| Fazenda | Plantacoes mutantes | Areas de milho bloqueiam visao; vacas mutantes aparecem em ondas |
| Toquio | Paineis eletricos | Zonas eletrificadas que dao dano continuo mas aumentam velocidade de ataque |
| Vulcao | Lava pools | Piscinas de lava surgem periodicamente; ficar perto da borda da dano de calor |
| Oceano | Correntes de agua | Correntes empurram jogadores e inimigos em direcoes fixas; mudancas de mare |
| Arena | Armadilhas gladiatorias | Espinhos retrativeis, paredes moveis, grades que prendem |
| Espaco | Zonas de gravidade zero | Certas areas eliminam gravidade — movimento mais lento, pulos mais altos |
| Castelo | Zonas de sombra | Areas escuras reduzem visao e aumentam dano de inimigos dark |
| Mundo Doce | Piso pegajoso | Certas areas de melado reduzem velocidade; areas de acucar aumentam dano |

## Sinergias Elementais

### 6 sinergias base
| Combo | Elementos | Efeito |
|-------|-----------|--------|
| Meltdown | Fogo + Gelo | Explosao de vapor que atordoa inimigos em area |
| Superconductor | Fogo + Eletrico | Raio de fogo que encadeia entre inimigos |
| Shadow Fire | Fogo + Dark | Chamas negras que drenam HP e reduzem defesa |
| Permafrost | Gelo + Eletrico | Congela e paralisa — inimigos congelados tomam dano eletrico |
| Void Ice | Gelo + Dark | Cristais de gelo negro que explodem apos delay |
| Dark Lightning | Eletrico + Dark | Relampago que cria zonas de escuridao com dano continuo |

### 3 sinergias novas (Agua)
| Combo | Elementos | Efeito |
|-------|-----------|--------|
| Tidal Wave | Agua + Fogo | Steam Explosion — onda de vapor que empurra e queima |
| Absolute Zero | Agua + Gelo | Congelamento em area massiva com slow de 80% |
| Abyssal Depths | Agua + Dark | Vortex que puxa inimigos para o centro e drena HP |

### Cross-Combos (Multiplayer)
No multiplayer, quando dois jogadores diferentes aplicam elementos complementares no mesmo inimigo, ocorre um **Cross-Combo** com efeito amplificado (1.5x dano da sinergia normal). Sao 12 combinacoes possiveis entre os 4 elementos + agua.

## Mutations / Ascension Mode (Provacoes de Zion)

Apos completar a campanha, o jogador desbloqueia o **Modo Ascensao** com 6 mutacoes que modificam a dificuldade:

| Mutacao | Efeito | Multiplicador de Cristais |
|---------|--------|---------------------------|
| Furia dos Sentinelas | Inimigos +30% velocidade | +15% cristais |
| Corrupcao Profunda | Inimigos +40% HP | +20% cristais |
| Fendas Instaveis | Eventos ocorrem 50% mais frequentes | +15% cristais |
| Estilhaco Fraco | Player -20% HP maximo | +25% cristais |
| Silencio Arcano | Cooldowns +30% | +20% cristais |
| Horda Infinita | Spawn rate +50% | +25% cristais |

O jogador pode ativar 1 a 6 mutacoes simultaneamente. Os multiplicadores de cristais sao cumulativos. Ativar todas as 6 da um bonus adicional de +30% (total ~150% bonus).

## Daily Challenge

Todos os dias uma **seed fixa** e gerada baseada na data. Todos os jogadores enfrentam a mesma configuracao:
- Stage aleatorio (fixo pela seed)
- Personagem aleatorio (fixo pela seed)
- Mutacoes pre-definidas (1-3 aleatorias)
- Leaderboard global separado (tempo sobrevivido + kills)
- Uma tentativa por dia

## Enemy Behaviors per Stage

Cada stage tem inimigos com comportamentos unicos alem dos genericos:

| Stage | Inimigos Especiais | Comportamento |
|-------|-------------------|---------------|
| Cemiterio | Esqueletos, Fantasmas | Fantasmas atravessam paredes; esqueletos ressurgem de tumulos |
| Floresta | Treants, Fadas | Treants sao lentos mas tanky; fadas curam outros inimigos |
| Fazenda | Vacas mutantes, Espantalhos | Vacas carregam em linha reta; espantalhos invocam corvos |
| Toquio | Drones, Androides | Drones atiram a distancia; androides se teleportam |
| Vulcao | Imps de fogo, Golem de lava | Imps explodem ao morrer; golems deixam rastro de lava |
| Oceano | Peixes-espada, Medusas | Peixes-espada fazem dash rapido; medusas paralisam |
| Arena | Gladiadores, Leoes | Gladiadores bloqueiam; leoes atacam em grupo |
| Espaco | Aliens, Meteoritos | Aliens atiram lasers; meteoritos caem do ceu |
| Castelo | Morcegos, Cavaleiros | Morcegos vem em enxame; cavaleiros tem armadura |
| Mundo Doce | Gummy bears, Doces vivos | Gummy bears dividem ao morrer; doces vivos grudam no player |

## Monetizacao

- Jogo base pago (~R$20-30)
- DLCs de conteudo (novas fases + personagens em packs tematicos)
- Sem microtransacoes / sem pay-to-win
- Workshop da Steam pra mods da comunidade
- Trading cards da Steam

## Scope por Release

### v1.0 - Early Access
- 3 Fragmentados iniciais (Ronin, Soldado, Mago)
- 8 armas (4 melee, 3 ranged, 1 summon)
- 3 fendas (Cemiterio, Floresta, Fazenda)
- 8 itens passivos, 3 evolucoes, 3 reliquias
- Loja (Zion se reconstruindo)
- Co-op 2-4 Fragmentados
- Modo Normal + Endless

### v1.1+ Updates
- Mais Fragmentados e armas
- Fendas 4-6 (Toquio, Vulcao, Oceano)
- Mais evolucoes, itens, eventos
- Achievements
- Camada narrativa (dialogos de boss, loading screens com lore)

### v2.0 - Full Release
- Todos os 15 Fragmentados (incluindo ??? e Fragmentado)
- 28 armas e 12 evolucoes
- 10 fendas (7 campanha + 3 anomalias)
- Todos os modos de jogo
- Daily Challenge + Leaderboard global
- Historia completa (unlock do ???, cutscene final)
- Workshop support
