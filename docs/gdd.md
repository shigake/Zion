# Zion - Game Design Document

## Visao Geral

**Nome:** Zion
**Genero:** Survivors / Roguelite
**Inspiracoes:** Vampire Survivors, The Spell Brigade, Ravenswatch
**Plataforma:** Steam (PC)
**Estilo Visual:** A definir (opcoes: 8-bit, estilo Zelda/Genshin)

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

## Modos de Jogo

| Modo | Descricao |
|---|---|
| **Normal** | 30 min, dificuldade crescente, boss no final |
| **Endless** | Sem limite de tempo, leaderboard de tempo sobrevivido |
| **Boss Rush** | So bosses, um atras do outro |
| **Daily Challenge** | Seed fixa por dia, leaderboard global |
| **Co-op Local** | 2-4 players, mesma tela |
| **Hyper Mode** | Tudo 2x mais rapido (jogador e inimigos) |
| **Inverse** | Voce e o boss e os herois vem te atacar |

## Monetizacao

- Jogo base pago (~R$20-30)
- DLCs de conteudo (novas fases + personagens em packs tematicos)
- Sem microtransacoes / sem pay-to-win
- Workshop da Steam pra mods da comunidade
- Trading cards da Steam
