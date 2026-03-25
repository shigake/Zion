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

## Conceito

O jogador controla um personagem em uma arena vista de cima, enfrentando hordas infinitas de inimigos. As armas atacam automaticamente e o jogador foca em posicionamento e escolha de upgrades. A cada level up, escolhe entre 3 opcoes de arma ou item passivo. O objetivo e sobreviver o maximo possivel (30 min no modo normal) e derrotar o boss final da fase.

## Pilares de Design

1. **Caos Divertido** - tela cheia de inimigos, efeitos e dano. A sensacao de poder cresce a cada minuto.
2. **Variedade** - muitas combinacoes de armas, itens e personagens pra cada run ser diferente.
3. **Progressao Satisfatoria** - tanto dentro da run (ficando mais forte) quanto entre runs (loja permanente).
4. **Tematicas Criativas** - fases que vao de cemiterio a mundo doce, sem se levar a serio demais.

## Loop de Gameplay

```
Escolhe Personagem + Reliquia
        |
        v
    Entra na Fase
        |
        v
  Mata inimigos → Ganha XP → Level Up → Escolhe Upgrade
        |                                      |
        v                                      v
  Coleta Cristais (moeda)          Armas evoluem e combinam
        |
        v
  Eventos Especiais (hordas, merchants, desafios)
        |
        v
    Boss Final (min 25-30)
        |
        v
  Fim da Run → Loja → Upgrades Permanentes → Proxima Run
```

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
| Modo | Descricao |
|---|---|
| **Boss Rush** | So bosses, um atras do outro |
| **Daily Challenge** | Seed fixa por dia, leaderboard global (requer backend) |
| **Hyper Mode** | Tudo 2x mais rapido (jogador e inimigos) |
| **Inverse** | Voce e o boss e os herois vem te atacar (DLC standalone) |

## Monetizacao

- Jogo base pago (~R$20-30)
- DLCs de conteudo (novas fases + personagens em packs tematicos)
- Sem microtransacoes / sem pay-to-win
- Workshop da Steam pra mods da comunidade
- Trading cards da Steam

## Scope por Release

### v1.0 - Early Access
- 3 personagens (Ronin, Soldado, Mago)
- 8 armas (4 melee, 3 ranged, 1 summon)
- 3 fases (Cemiterio, Floresta Encantada, Fazenda)
- 8 itens passivos
- 3 evolucoes de arma
- 3 reliquias
- Loja com upgrades permanentes
- Online co-op 2-4 players
- Modo Normal + Endless

### v1.1+ Updates
- Personagens e armas adicionais
- Fases 4-6
- Mais evolucoes e itens
- Eventos especiais
- Achievements

### v2.0 - Full Release
- Todos os 12 personagens
- Todas as 30 armas e evolucoes
- 10 fases
- Todos os modos de jogo
- Daily Challenge (backend)
- Workshop support
