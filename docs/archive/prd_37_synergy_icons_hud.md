# PRD 37 — Icones de sinergia no HUD com tooltip e banner

**Status**: concluido
**Tipo**: feature
**Prioridade**: alta
**Versao alvo**: 3.53.0

---

## Problema

O sistema de sinergias (31 sinergias) e um dos sistemas mais complexos e interessantes do jogo, mas o feedback visual e insuficiente. Atualmente o `synergy_hud.gd` mostra emojis Unicode (🔥, ❄, ⚡) com texto — mas:

1. Emojis Unicode renderizam diferente em cada SO/GPU
2. Nao ha icones desenhados dedicados
3. Nao ha tooltip explicando o efeito ao jogador
4. Nao ha banner epico na primeira ativacao (jogador pode nem notar)
5. Jogador nao entende o que a sinergia faz durante o gameplay

## Objetivo

Criar icones procedurais consistentes para todas as 31 sinergias, exibir tooltips informativos on-hover/on-focus, e mostrar um banner animado dramatico na primeira ativacao de cada sinergia durante a run.

## Escopo

### Incluso
- 31 icones procedurais de sinergia (gerados via codigo, sem assets externos)
- Tooltip com nome, efeito, e trigger da sinergia
- Banner animado de ativacao (primeira vez na run)
- Integracao com GamepadUI para navegacao por controle
- Contador de procs visivel no icone
- Indicador de cooldown circular quando aplicavel

### Fora de escopo
- Sprites desenhados a mao (usar icones procedurais)
- Mudancas no balanceamento das sinergias
- Novas sinergias

## Especificacao tecnica

### 1. Icones procedurais de sinergia

Gerar icones 48x48 via `Image` + `ImageTexture` no startup:

```gdscript
func _generate_synergy_icon(synergy_name: String, synergy_data: Dictionary) -> ImageTexture:
```

**Design de cada icone:**
- Fundo: circulo com gradiente radial na cor da sinergia
- Simbolo central: forma geometrica baseada no tipo:
  - `fire_*`: triangulo (chama)
  - `ice_*`: hexagono (cristal de gelo)
  - `electric_*`: zigzag (raio)
  - `dark_*`: lua crescente
  - `water_*`: gota
  - `poison_*`: 3 circulos (bolhas toxicas)
  - `light_*`: estrela 6 pontas
  - `physical_*`: punho (quadrado com linhas)
- Cross-synergies: icone dividido ao meio com ambos os simbolos
- Borda: 2px na cor mais clara da sinergia
- Glow: emission sutil ao redor quando ativa

### 2. Layout no HUD

**Posicao:** Canto inferior-esquerdo (onde ja fica o synergy_hud)

**Layout responsivo:**
| Sinergias ativas | Layout | Tamanho |
|-----------------|--------|---------|
| 1-3 | Horizontal | 48x48 + nome |
| 4-6 | Horizontal | 40x40 sem nome |
| 7+ | Grid 2 linhas | 36x36 compacto |

**Cada icone mostra:**
- Icone procedural com cor da sinergia
- Badge de procs no canto superior-direito (ex: "x23")
- Overlay de cooldown circular (arco que diminui, como em MOBAs)
- Brilho pulsante quando proc acontece (0.3s)

### 3. Tooltip

**Trigger:** hover com mouse OU foco com gamepad (D-pad navega entre icones)

**Conteudo:**
```
┌─────────────────────────────┐
│ 🔥 EXPLOSAO                │  ← nome em caps, cor da sinergia
│ Fogo + Fogo                │  ← trigger em cinza
│                             │
│ 20% chance de explodir ao   │  ← descricao do efeito
│ matar um inimigo            │
│                             │
│ Procs: 47  |  DPS: ~128    │  ← stats da run atual
└─────────────────────────────┘
```

**Visual:**
- Fundo: preto 90% alpha com borda na cor da sinergia
- Posicao: acima do icone, nunca sai da tela
- Animacao: fade-in 0.15s, fade-out 0.1s
- Max width: 280px
- Font: 12px corpo, 14px titulo

### 4. Banner de primeira ativacao

**Trigger:** `SynergySystem.synergy_activated` signal (primeira vez na run)

**Animacao (~2.5s):**

| Tempo | Efeito |
|-------|--------|
| 0.0s | Banner desliza da esquerda (EASE_OUT_BACK) |
| 0.0s | Flash na cor da sinergia (0.1 alpha, 0.15s) |
| 0.0s | SFX: "synergy_activate" (reusar "evolve" com pitch +0.2) |
| 0.1s | Icone da sinergia aparece com scale bounce (0.3 → 1.2 → 1.0) |
| 0.3s | Texto do nome aparece (typewriter, 20ms/char) |
| 0.5s | Subtexto do efeito aparece (fade-in 0.2s) |
| 0.8s | Particulas na cor da sinergia (8 particulas) |
| 2.0s | Banner comeca fade-out (0.5s) |
| 2.5s | Banner removido |

**Visual:**
```
┌──────────────────────────────────────┐
│  [ICONE]   SINERGIA ATIVADA!        │
│            Steam Cloud               │
│            Fogo + Gelo = Nuvem       │
└──────────────────────────────────────┘
```

- Largura: 400px, altura: 80px
- Posicao: centro-esquerda da tela (y = 40%)
- Fundo: gradiente horizontal (cor da sinergia → transparente)
- Queue: se multiplas ativam simultaneamente, mostrar em sequencia com 0.3s delay

### 5. Tracking de procs

Adicionar ao SynergySystem:

```gdscript
var synergy_proc_counts: Dictionary = {}  # synergy_name → int
var synergy_total_damage: Dictionary = {}  # synergy_name → float

func _on_synergy_procced(synergy_name: String, damage: float) -> void:
    synergy_proc_counts[synergy_name] = synergy_proc_counts.get(synergy_name, 0) + 1
    synergy_total_damage[synergy_name] = synergy_total_damage.get(synergy_name, 0.0) + damage
```

### 6. Constantes em `game_constants.gd`

```gdscript
# Synergy HUD Icons
const SYNERGY_ICON_SIZE_LARGE = 48
const SYNERGY_ICON_SIZE_MEDIUM = 40
const SYNERGY_ICON_SIZE_SMALL = 36
const SYNERGY_ICON_LARGE_MAX = 3
const SYNERGY_ICON_MEDIUM_MAX = 6
const SYNERGY_TOOLTIP_WIDTH = 280
const SYNERGY_TOOLTIP_FADE_IN = 0.15
const SYNERGY_TOOLTIP_FADE_OUT = 0.1
const SYNERGY_BANNER_WIDTH = 400
const SYNERGY_BANNER_HEIGHT = 80
const SYNERGY_BANNER_DURATION = 2.5
const SYNERGY_BANNER_SLIDE_TIME = 0.3
const SYNERGY_PROC_FLASH_DURATION = 0.3
const SYNERGY_COOLDOWN_ARC_COLOR = Color(1, 1, 1, 0.4)
```

### 7. Acessibilidade

- `high_contrast`: bordas mais grossas (3px), cores saturadas
- `reduced_motion`: sem banner slide, aparece instantaneo
- `reduced_flash`: sem flash na ativacao
- Tooltip acessivel por gamepad (foco navegavel)
- Font scale respeitado no tooltip

## Criterios de aceite

1. [ ] 31 icones procedurais gerados sem assets externos
2. [ ] Icones distinguiveis entre si (forma + cor unicas)
3. [ ] Tooltip aparece no hover/foco com nome, efeito e stats
4. [ ] Banner animado na primeira ativacao de cada sinergia
5. [ ] Badge de contagem de procs visivel e atualizado
6. [ ] Cooldown circular visivel quando aplicavel
7. [ ] Flash no icone quando sinergia procca
8. [ ] Layout responsivo (3 tamanhos conforme quantidade)
9. [ ] Navegavel por gamepad
10. [ ] Acessibilidade respeitada (motion, flash, contrast)
11. [ ] Funciona em multiplayer (cada client local)

## Arquivos afetados

- `game/scripts/ui/synergy_hud.gd` — reescrever com icones procedurais + tooltip + banner
- `game/scripts/autoload/synergy_system.gd` — adicionar tracking de procs/damage
- `game/scripts/autoload/game_constants.gd` — constantes SYNERGY_*
- `game/assets/translations/*.csv` — texto "SINERGIA ATIVADA" / "SYNERGY ACTIVATED"

## Estimativa

Complexidade: media-alta
Tempo estimado: 3-4 horas
Impacto na experiencia: muito alto (jogador finalmente entende sinergias)
