# Zion - Spec Driven

Especificacao tecnica e funcional do jogo.

---

## 1. Visao do Produto

**O que e:** Um survivors game onde o jogador enfrenta hordas infinitas de inimigos em fases tematicas, coletando armas e itens que se combinam e evoluem.

**Publico alvo:** Jogadores casuais e mid-core que curtem runs curtas (20-30 min), progressao entre partidas, e builds criativos.

**Diferencial:** Tematicas variadas e absurdas (de cemiterio a mundo doce), sistema de evolucao de armas por combinacao, e eventos aleatorios que mudam cada run.

---

## 2. Core Loop

```
[Lobby/Loja] --> [Selecao] --> [Gameplay] --> [Resultado] --> [Lobby/Loja]
```

### 2.1 Lobby / Loja
- Jogador gasta Cristais em upgrades permanentes
- Seleciona personagem desbloqueado
- Seleciona fase desbloqueada
- Seleciona modo de jogo
- Ve achievements e colecao

### 2.2 Selecao Pre-Run
- Escolhe 1 Reliquia (modificador da run)
- Confirma e inicia

### 2.3 Gameplay (Run)
- Duracao: 30 minutos (modo normal)
- Camera: top-down
- Movimento: WASD ou analog stick
- Ataque: automatico (armas atacam sozinhas)
- Jogador foca em: posicionamento, coleta de XP/itens, escolha de upgrades

### 2.4 Resultado
- Tela de stats: tempo sobrevivido, inimigos mortos, dano dealt, itens coletados
- Cristais ganhos na run sao creditados
- Achievements desbloqueados aparecem
- Opcao: voltar ao lobby ou replay

---

## 3. Especificacao de Sistemas

### 3.1 Sistema de Level Up

```
Inimigo morre → dropa gema de XP → jogador coleta → barra de XP enche → LEVEL UP
```

**Ao dar level up:**
- Jogo pausa
- 3 opcoes aparecem (arma nova, upgrade de arma existente, ou item passivo)
- Jogador escolhe 1
- Pode usar Reroll (se tiver) pra trocar as 3 opcoes
- Pode usar Banish pra remover 1 opcao permanentemente da pool

**Scaling de XP:**
- Level 1-10: rapido (30-60s por level)
- Level 11-20: medio (60-90s por level)
- Level 21+: lento (90-120s por level)

### 3.2 Sistema de Armas

**Slots:** 4 iniciais, max 6 (upgrade na loja)

**Level de arma:** 1 a 8
- Level 1-7: upgrades normais (mais dano, mais projeteis, mais area, etc)
- Level 8: evolucao disponivel SE tiver o item passivo correto

**Evolucao:**
- Arma nivel 8 + item passivo correto = bau de evolucao aparece no mapa
- Jogador abre o bau = arma evolui pra versao final
- Arma evoluida nao sobe mais de level, ja e o maximo

### 3.3 Sistema de Itens Passivos

**Slots:** 6 slots de item passivo

**Level de item:** 1 a 5
- Cada level aumenta o efeito do item
- Item max level contribui pra evolucao de arma

### 3.4 Sistema de Inimigos

**Spawn:**
- Inimigos spawnam fora da tela em direcao ao jogador
- Quantidade e velocidade aumentam com o tempo
- Tipos de inimigos mudam conforme o minuto

**Tabela de Spawn (exemplo fase generica):**

| Minuto | Inimigos |
|---|---|
| 0-2 | Slimes basicos |
| 2-5 | Slimes + Bats |
| 5-8 | Skeletons + Bats + Slimes Grandes |
| 8-12 | Skeleton Archers + Ghosts + Bombers |
| 12-15 | Mini-boss + Tanks + Swarms |
| 15-20 | Mix de tudo, spawn rate alto |
| 20-25 | Spawn rate insano, inimigos elites (brilham, mais HP/dano) |
| 25-30 | Boss final + horda continua |

**Elite enemies:**
- Versao mais forte de qualquer inimigo
- Brilham com aura colorida
- Dropam bau garantido ao morrer
- Aparecem a partir do minuto 15

### 3.5 Sistema de Boss

**Mini-boss:**
- Aparece no minuto 12-15
- Barra de vida visivel
- 1 por fase
- Dropa bau raro

**Boss Final:**
- Aparece no minuto 25
- Barra de vida grande no topo da tela
- Padroes de ataque em fases (muda comportamento a cada 25% HP)
- Horda continua spawning durante a luta
- Derrotar = vitoria da run

### 3.6 Sistema de Dano

```
Dano Final = (Dano Base da Arma * Level Multiplier * Upgrade Permanente) * Sinergia Bonus
```

**Tipos de dano:**
- Fisico
- Fogo (burn DoT)
- Gelo (slow + freeze)
- Eletrico (chain)
- Dark (execute threshold)
- Poison (DoT que stacka)

**Resistencias:**
- Alguns inimigos tem resistencia a tipos especificos
- Boss tem resistencia parcial a todos os tipos
- Nenhum inimigo e imune (sempre toma pelo menos 1 de dano)

### 3.7 Sistema de Eventos

- Eventos sao trigados por tempo ou aleatorios
- So 1 evento ativo por vez
- Evento avisa com popup antes de comecar (3s de aviso)
- Eventos duram 15-30 segundos
- Drop/recompensa ao final do evento

---

## 4. Controles

### Teclado + Mouse
| Input | Acao |
|---|---|
| WASD | Movimento |
| Mouse | Direcao (pra armas direcionais) |
| Space | Dash/Dodge (cooldown 3s) |
| E | Interagir (bau, merchant) |
| ESC | Pause menu |
| 1-6 | Info da arma no slot |

### Gamepad
| Input | Acao |
|---|---|
| Left Stick | Movimento |
| Right Stick | Direcao |
| A / X | Dash/Dodge |
| B / Circle | Interagir |
| Start | Pause |

---

## 5. UI / HUD

### Durante o Gameplay
```
[HP Bar]                              [Timer 00:00]
[XP Bar ████████░░░░ Lv.12]

                  [Personagem]

[Arma1][Arma2][Arma3][Arma4][Arma5][Arma6]
[Item1][Item2][Item3][Item4][Item5][Item6]

[Kill Count: 1234]    [Cristais: 567]
```

### Tela de Level Up
```
┌─────────────────────────────────┐
│         LEVEL UP!               │
│                                 │
│  [Opcao 1]  [Opcao 2]  [Opcao 3] │
│   Arma X     Item Y     Arma Z  │
│   Lv.3→4     Novo!      Lv.1→2  │
│                                 │
│  [Reroll: 3]    [Banish: 2]     │
└─────────────────────────────────┘
```

### Tela de Resultado
```
┌─────────────────────────────────┐
│       RUN COMPLETA!             │
│                                 │
│  Tempo: 28:34                   │
│  Inimigos: 8,432                │
│  Dano Total: 1,234,567          │
│  Nivel Final: 45                │
│  Cristais: +890                 │
│                                 │
│  [Achievement] A Vaca Foi Pro   │
│                Brejo!           │
│                                 │
│  [Lobby]  [Replay]  [Proxima]   │
└─────────────────────────────────┘
```

---

## 6. Progressao de Dificuldade

| Aspecto | Min 0 | Min 10 | Min 20 | Min 30 |
|---|---|---|---|---|
| Spawn Rate | 1x | 3x | 8x | 15x |
| HP dos Inimigos | 1x | 2x | 5x | 10x |
| Velocidade | 1x | 1.2x | 1.5x | 2x |
| Tipos de Inimigo | 2 | 5 | 8 | Todos |
| Elites | Nao | Nao | Sim | Sim (frequente) |

---

## 7. Audio

### Musica
- Cada fase tem tema unico
- Musica intensifica conforme o tempo passa (layers adicionais)
- Boss tem tema proprio
- Lobby tem musica calma

### SFX
- Cada arma tem som unico de ataque
- Som de hit/dano
- Som de coleta de XP (satisfatorio, tipo "pling")
- Som de coleta de item
- Som de level up (fanfarra curta)
- Som de evolucao de arma (epico)
- Som de morte de inimigo (varia por tipo)
- Som de boss (rugido ao aparecer)

---

## 8. Requisitos Tecnicos

### Performance Target
- 60 FPS constante com 1000+ inimigos na tela
- Otimizacao de rendering pra sprites em massa
- Object pooling pra projeteis e inimigos

### Plataforma
- Steam (Windows)
- Resolucoes: 1920x1080 (base), 2560x1440, 3840x2160
- Fullscreen, windowed, borderless

### Save System
- Save local (perfil do jogador, upgrades, desbloqueaveis)
- Steam Cloud Sync
- Auto-save entre runs (nao salva durante run)

---

## 9. Milestones

### M1 - Prototipo Jogavel
- [ ] Personagem se move e ataca
- [ ] 1 arma funcional
- [ ] Inimigos spawnam e morrem
- [ ] Sistema de XP e level up basico
- [ ] 1 fase (cemiterio)

### M2 - Core Loop Completo
- [ ] 3 armas funcionais
- [ ] 3 itens passivos
- [ ] Sistema de evolucao
- [ ] Loja entre runs
- [ ] 1 boss funcional

### M3 - Conteudo Base
- [ ] Todos os personagens
- [ ] Todas as armas e evolucoes
- [ ] 5 fases completas
- [ ] Todos os itens passivos
- [ ] Sistema de eventos

### M4 - Polish
- [ ] Todas as 10 fases
- [ ] Balanceamento
- [ ] Audio completo
- [ ] UI final
- [ ] Achievements
- [ ] Steam integration

### M5 - Release
- [ ] QA e bug fixing
- [ ] Performance optimization
- [ ] Steam page e marketing
- [ ] Launch
