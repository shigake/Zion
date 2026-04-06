# PRD 56 — Mini-tutorial contextual (dicas de primeira vez)

**Status**: pendente
**Prioridade**: alta
**Tipo**: onboarding / UX

---

## Problema

O tutorial existente (`tutorial_overlay.gd`) cobre mecanicas basicas (mover, atacar, coletar XP, dash) e tem uma fase 2 avancada, mas muitos sistemas importantes nao tem explicacao contextual na primeira vez que aparecem. Novos jogadores nao sabem:

- Que baus aparecem a cada 45s e tem setas guiando
- Que imas coletam tudo na tela
- Que evolucoes precisam de arma nivel 8 + item especifico
- Que sinergias ativam com 2 armas do mesmo elemento
- Que o dash tem i-frames
- Que quests dao recompensas de cristais
- Que mutacoes aumentam cristais ganhos

## Solucao

Sistema de "dicas de primeira vez" (first-time hints) que aparecem como baloes flutuantes no HUD quando o jogador encontra um sistema pela primeira vez. Cada dica aparece UMA vez na vida do save.

## Especificacao tecnica

### 1. Script `first_time_hints.gd`

**Local**: `scripts/ui/first_time_hints.gd`
**Tipo**: Node adicionado ao HUD

### 2. Catalogo de dicas

Cada dica tem:
- `id`: string unica
- `trigger`: sinal ou condicao que dispara
- `message_pt`: texto em portugues
- `message_en`: texto em ingles
- `icon`: textura opcional (emoji ou icone do sistema)
- `position`: onde aparece na tela (top, bottom, center, near_element)
- `duration`: tempo de exibicao (padrao 4s)
- `delay`: delay apos trigger (padrao 0.5s)

**Dicas planejadas (15 hints)**:

| ID | Trigger | Mensagem |
|---|---|---|
| `hint_chest_spawn` | `ChestManager.chest_spawned` (1a vez) | "Um bau apareceu! Siga a seta dourada para encontra-lo." |
| `hint_magnet_pickup` | Jogador coleta 1o ima | "Ima coletado! Todos os itens no chao voam ate voce." |
| `hint_evolution_ready` | Arma atinge nivel 8 + tem item compativel | "Evolucao disponivel! Sua [arma] pode evoluir com [item]." |
| `hint_synergy_first` | `SynergySystem.synergy_activated` (1a vez) | "Sinergia ativada! Armas do mesmo elemento se potencializam." |
| `hint_dash_iframe` | Jogador toma dano 3x sem usar dash | "Use o dash (Espaco) para ficar invulneravel por um instante!" |
| `hint_quest_started` | `QuestManager.quest_started` (1a vez) | "Quest iniciada! Complete para ganhar cristais bonus." |
| `hint_mutation_available` | Jogador morre com 500+ cristais totais | "Provacoes de Zion desbloqueadas! Ative no menu para ganhar mais cristais." |
| `hint_shop_upgrade` | Jogador volta ao hub com cristais (1a vez) | "Visite a loja para melhorias permanentes com seus cristais." |
| `hint_relic_drop` | Jogador ganha 1a reliquia | "Reliquia encontrada! Artefato ancestral com poder unico." |
| `hint_event_first` | `EventManager.event_started` (1a vez) | "Anomalia dimensional! Sobreviva ao evento para uma recompensa." |
| `hint_boss_telegraph` | `GameManager.boss_spawned` (1a vez) | "Sentinela corrompido! Observe os circulos vermelhos — indicam ataques de area." |
| `hint_hp_pickup` | HP pickup spawna (1a vez) | "Coracao no chao! Colete para recuperar vida." |
| `hint_xp_level` | Jogador sobe para nivel 2 (1a vez) | "Nivel acima! Escolha uma melhoria para sua jornada." |
| `hint_weapon_slot` | Jogador pega 2a arma | "Nova arma equipada! Voce pode carregar ate 6 armas simultaneas." |
| `hint_daily_available` | Jogador abre menu com daily disponivel | "Desafio diario disponivel! Micro-fratura com cristais 1.5x." |

### 3. Persistencia

Salvar hints ja vistos em `SaveManager.data`:
```gdscript
# Em SaveManager
"hints_seen": ["hint_chest_spawn", "hint_magnet_pickup", ...]
```

Nunca mostrar a mesma hint duas vezes.

### 4. Visual do balao

**Layout**:
```
┌─────────────────────────────────────┐
│  [icone]  Texto da dica aqui        │
│           que pode ter 2 linhas     │
└─────────────────────────────────────┘
```

**Estilo**:
- Fundo: `Color(0.1, 0.1, 0.15, 0.85)` — escuro semi-transparente
- Borda: `Color(0.4, 0.7, 1.0, 0.6)` — azul cristalino (cor de Zion)
- Texto: branco, fonte do UITheme, tamanho 16
- Icone: 24x24 a esquerda
- Padding: 12px
- Corner radius: 8px

**Animacao**:
```
Entrada: slide de baixo (20px) + fade in 0.3s
Sustain: 3.5s (4s total - animacoes)
Saida: fade out 0.5s
```

**Posicao padrao**: parte superior central da tela, abaixo do timer/kills
**Fila**: se 2 hints trigam ao mesmo tempo, enfileirar com 1s de gap

### 5. Integracao com tutorial existente

- Hints so aparecem se o tutorial fase 1 ja foi concluido (`tutorial_overlay._phase >= 2` ou `tutorial_completed` no save)
- Nao conflitar com hints da fase 2 do tutorial — verificar overlap
- Hints da fase 2 do tutorial continuam funcionando normalmente

### 6. Localizacao

Todas as mensagens passam por `LocaleManager.tr()`:
```gdscript
var msg = LocaleManager.tr("hint_chest_spawn")
```

Adicionar as 15 strings em ambos locales (pt_BR e en).

### 7. Opcao de desligar

Toggle em opcoes: "Dicas contextuais" (padrao: ligado)
Salvo em `SaveManager.data.get("contextual_hints_enabled", true)`

### 8. Reset opcional

Botao nas opcoes: "Resetar dicas" — limpa `hints_seen` para ver todas novamente. Util para quem quer relembrar ou para testes.

## Criterios de aceite

- [ ] 15 dicas contextuais implementadas com triggers corretos
- [ ] Cada dica aparece apenas 1 vez por save
- [ ] Persistencia funciona entre sessoes
- [ ] Visual clean com animacao suave
- [ ] Nao conflita com tutorial existente
- [ ] Fila de dicas quando multiplas trigam simultaneamente
- [ ] Localizacao pt_BR e en
- [ ] Toggle para desligar nas opcoes
- [ ] Botao de reset funciona
- [ ] Nao aparece durante cutscenes ou telas de menu

## Narrativa

As dicas representam a "memoria fragmentada de Zion" — o cristal dentro do Fragmentado sussurrando conhecimento ancestral conforme novas situacoes surgem. E uma forma de Zion guiar seus restauradores.

## Estimativa

~4-5 horas. Sistema de hints e simples, o grosso do trabalho esta nas 15 mensagens, triggers e testes de timing.
