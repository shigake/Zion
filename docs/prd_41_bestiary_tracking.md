# PRD 41 — Bestiario com tracking de kills e lore desbloqueavel

**Status**: concluido
**Tipo**: feature
**Prioridade**: media
**Versao alvo**: 3.54.0

---

## Problema

O bestiario (`bestiary_screen.gd`) ja existe e mostra inimigos organizados por fenda com contagem de kills. Porem:

1. **Sem milestones de kills** — matar 100 slimes nao da nada, nao ha progressao
2. **Sem lore** — cada inimigo deveria ter uma descricao narrativa (sao criaturas corrompidas de Zion)
3. **Sem recompensas** — nao ha incentivo para cacar tipos especificos
4. **Cards basicos** — sem detalhes de stats, comportamento, ou dicas de combate
5. **Sem tracking de "primeiro encontro"** — jogador nao sabe quando descobriu cada inimigo

## Objetivo

Expandir o bestiario existente com sistema de milestones de kills que desbloqueiam lore narrativo, dicas de combate, e recompensas de cristais. Transformar o bestiario num colecionavel que incentiva replay.

## Escopo

### Incluso
- Milestones de kills por inimigo (10, 50, 100, 500, 1000)
- Lore narrativo desbloqueavel por milestone
- Dicas de combate desbloqueadas na primeira morte
- Stats do inimigo (HP, dano, velocidade) desbloqueaveis
- Recompensa de cristais por milestone
- Barra de progresso ate proximo milestone
- Contador de inimigos unicos descobertos (X/total)
- Redesign dos cards com mais informacao

### Fora de escopo
- Novos inimigos
- Modelo 3D dos inimigos no bestiario
- Bestiario multiplayer compartilhado

## Especificacao tecnica

### 1. Sistema de milestones

```gdscript
const BESTIARY_MILESTONES = [
    {kills: 10, reward: "nome", crystals: 5, label: "Identificado"},
    {kills: 50, reward: "stats", crystals: 15, label: "Estudado"},
    {kills: 100, reward: "lore_1", crystals: 30, label: "Compreendido"},
    {kills: 500, reward: "lore_2", crystals: 75, label: "Dominado"},
    {kills: 1000, reward: "lore_3", crystals: 150, label: "Exterminado"},
]
```

**Desbloqueios por milestone:**

| Kills | Desbloqueia | Exemplo |
|-------|-------------|---------|
| 1 | Silhueta + "???" | Card cinza com forma |
| 10 | Nome + tipo + sprite colorido | "Slime — Generico" |
| 50 | Stats (HP, dano, velocidade, resistencias) | "HP: 15, Dano: 3" |
| 100 | Lore parte 1 (origem na narrativa) | "Restos de materia primordial..." |
| 500 | Lore parte 2 (comportamento) | "Atacam em grupos quando..." |
| 1000 | Lore parte 3 (segredo) + titulo dourado | "Os ancioes dizem que..." |

### 2. Lore narrativo (exemplos)

Cada inimigo tem 3 paragrafos de lore alinhados com `docs/story.md`:

**Slime:**
- Lore 1: "Restos de materia primordial de Zion. Quando o Coracao se estilhacou, a energia crua se condensou nestas formas instáveis."
- Lore 2: "Slimes sao atraidos por fragmentos cristalinos. Quanto mais perto de um Fragmentado, mais agressivos ficam — como se tentassem reabsorver os estilhacos."
- Lore 3: "Os Sentinelas mais antigos lembram de quando Slimes eram os guardioes das fontes de energia. A corrupcao os reduziu a isso."

**Boss Necromancer:**
- Lore 1: "Sentinela do Cemiterio Eterno. Antes da corrupcao, era o Guardiao das Memorias — protegia as almas dos que descansavam em Zion."
- Lore 2: "Seus poderes de invocacao sao um eco distorcido de sua funcao original: chamar as memorias dos caidos para reconfortar os vivos."
- Lore 3: "Se libertado da corrupcao, o Necromancer poderia restaurar as memorias perdidas de Zion. Alguns fragmentos que ele invoca carregam ecos do passado."

### 3. Redesign dos cards

**Card expandido (ao selecionar):**
```
┌──────────────────────────────────────┐
│ [SPRITE]   SLIME                     │
│  64x64     Tipo: Generico            │
│            Fenda: Todas              │
│            Kills: 847/1000           │
│            ████████████████░░ 85%    │
│                                      │
│ Stats:                               │
│  ❤ HP: 15   ⚔ Dano: 3              │
│  💨 Velocidade: Media                │
│  🛡 Resistencia: Nenhuma             │
│                                      │
│ Lore:                                │
│ "Restos de materia primordial de     │
│  Zion. Quando o Coracao se           │
│  estilhacou..."                      │
│                                      │
│ Dica: Slimes sao lentos. Mantenha   │
│ distancia e use armas de area.       │
│                                      │
│ 🏆 Proximo: Exterminado (1000 kills) │
│    Recompensa: 150 cristais          │
└──────────────────────────────────────┘
```

**Card na grid (compacto):**
```
┌──────────────┐
│   [SPRITE]   │  64x64 (ou silhueta se < 10 kills)
│   Slime      │  nome (ou "???" se < 10)
│   ★★★★☆     │  milestone stars (4/5)
│   847 kills  │  total kills
│   ████░ 85%  │  progresso ao proximo
└──────────────┘
```

### 4. Notificacao de milestone

Quando o jogador atinge um milestone durante gameplay:

```
┌─────────────────────────────────┐
│ 📖 BESTIARIO ATUALIZADO!        │
│ Slime — "Compreendido" (100)    │
│ +30 cristais | Novo lore!       │
└─────────────────────────────────┘
```

- Posicao: lado esquerdo, abaixo do achievement tracker
- Duracao: 2.5s
- Animacao: slide-in da esquerda + fade-out
- SFX: "bestiary_milestone" (reusar "chest_open" com pitch +0.2)

### 5. Contador global

No topo do bestiario:

```
Criaturas descobertas: 87/112 (78%)
Milestones completos: 234/560 (42%)
Cristais ganhos: 4.350
```

### 6. Persistencia (SaveManager)

```gdscript
# Expandir bestiary data existente
"bestiary": {
    "slime": {
        kills: 847,
        first_seen: "2024-03-15",
        milestones_claimed: [10, 50, 100, 500],  # quais ja deram reward
    },
    # ...
}
```

### 7. Dicas de combate

Cada inimigo tem 1 dica desbloqueada na primeira morte:

```gdscript
const COMBAT_TIPS = {
    "slime": "Slimes sao lentos. Mantenha distancia e use armas de area.",
    "bat": "Morcegos sao rapidos mas frageis. Um unico golpe forte os elimina.",
    "skeleton": "Esqueletos recuam apos atacar. Avance quando recuarem.",
    "boss_necromancer": "Foque nos minions primeiro. O Necromancer fica vulneravel sem exercito.",
    # ... para cada inimigo
}
```

### 8. Constantes em `game_constants.gd`

```gdscript
# Bestiary Milestones
const BESTIARY_MILESTONE_KILLS = [10, 50, 100, 500, 1000]
const BESTIARY_MILESTONE_CRYSTALS = [5, 15, 30, 75, 150]
const BESTIARY_MILESTONE_LABELS = ["Identificado", "Estudado", "Compreendido", "Dominado", "Exterminado"]
const BESTIARY_CARD_SIZE = Vector2(130, 160)
const BESTIARY_CARD_EXPANDED_WIDTH = 380
const BESTIARY_SPRITE_SIZE = 64
const BESTIARY_NOTIFICATION_DURATION = 2.5
const BESTIARY_STAR_SIZE = 12
```

## Criterios de aceite

1. [ ] 5 milestones de kills por inimigo com recompensas de cristais
2. [ ] Lore de 3 partes desbloqueavel em milestones 100/500/1000
3. [ ] Cards mostram estrelas de progresso e barra ate proximo milestone
4. [ ] Card expandido mostra stats, lore, e dica de combate
5. [ ] Notificacao in-game ao atingir milestone
6. [ ] Cristais recompensados automaticamente e salvos
7. [ ] Contador global de criaturas/milestones no topo
8. [ ] Inimigos nao-encontrados aparecem como silhueta + "???"
9. [ ] Navegacao por gamepad funcional
10. [ ] Persistencia completa entre sessoes
11. [ ] Lore respeita narrativa de story.md (Sentinelas, corrupcao, Zion)

## Arquivos afetados

- `game/scripts/ui/bestiary_screen.gd` — redesign com milestones, lore, cards expandidos
- `game/scripts/autoload/save_manager.gd` — expandir bestiary data com milestones
- `game/scripts/autoload/game_constants.gd` — constantes BESTIARY_*
- `game/scripts/enemies/enemy_base.gd` — emitir signal de kill com nome para tracking
- `game/scripts/ui/hud.gd` — notificacao de milestone
- `game/assets/translations/*.csv` — lore e dicas de combate (PT/EN)

## Estimativa

Complexidade: media-alta (muito conteudo textual)
Tempo estimado: 4-5 horas
Impacto: alto (colecionavel, replay value, profundidade narrativa)
