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
- Todos os 14 Fragmentados (incluindo ???)
- 28 armas e 12 evolucoes
- 10 fendas (7 campanha + 3 anomalias)
- Todos os modos de jogo
- Daily Challenge + Leaderboard global
- Historia completa (unlock do ???, cutscene final)
- Workshop support
