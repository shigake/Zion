# PRD 40 — Arvore de evolucao visual

**Status**: concluido
**Tipo**: UX
**Prioridade**: media
**Versao alvo**: 3.54.0

---

## Problema

O sistema de evolucao (12 evolucoes) e um dos pilares do gameplay, mas o jogador nao tem como saber qual combinacao arma + item gera qual evolucao. Atualmente:

1. Nao ha tela mostrando as combinacoes possiveis
2. Jogador precisa decorar ou consultar docs externos
3. Nao da pra saber quais evolucoes ja foram desbloqueadas
4. Nao ha preview do que a evolucao faz

Em Vampire Survivors, a tela de evolucao e uma das mais consultadas — e um driver de replay enorme.

## Objetivo

Criar uma tela de arvore de evolucao acessivel pelo menu principal e pelo inventario in-game, mostrando todas as 12 evolucoes com suas receitas (arma + item), status de desbloqueio, e preview dos efeitos.

## Escopo

### Incluso
- Tela de arvore de evolucao no menu principal
- Versao compacta acessivel in-game (via InventoryOverlay)
- Conexoes visuais arma → item → evolucao
- Status: bloqueado / disponivel / ja evoluido
- Preview do efeito especial da evolucao
- Filtro por elemento/tipo
- Indicador "disponivel agora!" durante a run

### Fora de escopo
- Novas evolucoes
- Mudancas no sistema de evolucao
- Animacao de evolucao in-game (ja existe)

## Especificacao tecnica

### 1. Dados das 12 evolucoes (de `evolution_db.gd`)

| Evolucao | Arma (lv6+) | Item (lv3+) | Especial |
|----------|-------------|-------------|----------|
| Zangetsu | Katana | Luva | Energy waves |
| Apocalypse Staff | Cajado | Cristal | Meteor rain |
| Holy Lance | Lanca | Coroa | Holy explosion |
| Inferno Blade | Espada de fogo | Rubi | Fire trail |
| Thunder God | Raio | Anel | Chain lightning+ |
| Frost Nova | Gelo | Manto | Freeze nova |
| Shadow Reaper | Foice | Capa | Soul harvest |
| Phoenix Bow | Arco | Pena | Homing fire arrows |
| Mjolnir | Martelo | Cinto | Thunder slam |
| Void Staff | Staff escuro | Orbe | Black hole |
| Serpent Fang | Adaga | Veneno | Poison cloud |
| Divine Shield | Escudo | Amuleto | Reflect damage |

### 2. Layout da tela

**Grid 4x3 de cards:**
```
┌──────────────────────────────────────────────────┐
│             RESSONANCIAS CRISTALINAS              │
│          Combinacoes de evolucao (5/12)           │
│──────────────────────────────────────────────────│
│                                                  │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────┐│
│  │[KATANA] │  │[CAJADO] │  │[LANCA]  │  │[ESP]││
│  │   +     │  │   +     │  │   +     │  │  +  ││
│  │[LUVA]  │  │[CRISTAL]│  │[COROA]  │  │[RUB]││
│  │   ↓     │  │   ↓     │  │   ↓     │  │  ↓  ││
│  │ZANGETSU│  │APOCALYP.│  │HOLY     │  │INFER││
│  │  ✅     │  │  🔒     │  │  ✅     │  │ 🔒 ││
│  └─────────┘  └─────────┘  └─────────┘  └─────┘│
│                                                  │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────┐│
│  │ ...     │  │ ...     │  │ ...     │  │ ... ││
│  └─────────┘  └─────────┘  └─────────┘  └─────┘│
│                                                  │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────┐│
│  │ ...     │  │ ...     │  │ ...     │  │ ... ││
│  └─────────┘  └─────────┘  └─────────┘  └─────┘│
│                                                  │
│              [Voltar]                            │
└──────────────────────────────────────────────────┘
```

### 3. Card de evolucao (cada card)

**Tamanho:** 140x180px

**Layout interno:**
```
┌──────────────────┐
│  [Icone Arma]    │  32x32, sprite da arma
│      +           │  texto "+"
│  [Icone Item]    │  32x32, sprite do item
│      ↓           │  seta animada (pulse)
│  [Icone Evol.]   │  48x48, sprite da evolucao
│  "Zangetsu"      │  nome 12px, cor do elemento
│  ✅ Desbloqueada │  status badge
└──────────────────┘
```

**Estados visuais:**

| Estado | Visual |
|--------|--------|
| Bloqueado | Cards cinza, icones com silhueta, cadeado |
| Descoberto (ja evoluiu antes) | Cards coloridos, detalhes visiveis |
| Disponivel AGORA (na run) | Borda brilhante dourada pulsante, "!" badge |
| Ja evoluido (nesta run) | Checkmark verde, glow completo |

### 4. Painel de detalhes (ao selecionar um card)

Ao clicar/focar um card, mostra painel lateral:

```
┌────────────────────────────┐
│ ZANGETSU                   │
│ "Lamina que corta entre    │
│  dimensoes"                │
│                            │
│ Receita:                   │
│ [Katana] nivel 6+          │
│ [Luva] nivel 3+            │
│                            │
│ Efeito especial:           │
│ Ondas de energia cortam    │
│ em arco a cada ataque      │
│                            │
│ Dano: 2.5x multiplicador   │
│                            │
│ Desbloqueada em: 15/03     │
│ Vezes evoluida: 7          │
└────────────────────────────┘
```

### 5. Versao in-game (InventoryOverlay)

Adicionar tab "Evolucoes" ao InventoryOverlay existente:

- Layout compacto: lista vertical com icones pequenos (24x24)
- Mostrar apenas: nome + receita + status
- Destacar com ⭐ as que estao disponiveis AGORA
- Indicar level atual da arma e item ("Katana lv4/6 + Luva lv2/3")

### 6. Indicador "Disponivel agora!" no HUD

Quando uma evolucao fica disponivel durante gameplay:

```gdscript
func _on_evolution_available(evo_id: String) -> void:
    # Mostrar notificacao no HUD
    # Icone pulsante da evolucao + texto "Evolucao disponivel!"
    # Duracao: 3s, fade out 0.5s
    # SFX: "evolve_ready" (reusar "level_up" com pitch -0.2)
```

### 7. Tracking de historico

Adicionar ao SaveManager:

```gdscript
# Em SaveManager.data
"evolution_history": {
    "zangetsu": {times: 7, first_date: "2024-03-15"},
    "apocalypse_staff": {times: 3, first_date: "2024-03-18"},
    # ...
}
```

### 8. Constantes em `game_constants.gd`

```gdscript
# Evolution Tree
const EVO_TREE_CARD_WIDTH = 140
const EVO_TREE_CARD_HEIGHT = 180
const EVO_TREE_COLUMNS = 4
const EVO_TREE_ICON_WEAPON_SIZE = 32
const EVO_TREE_ICON_EVOLUTION_SIZE = 48
const EVO_TREE_DETAIL_WIDTH = 280
const EVO_TREE_AVAILABLE_PULSE_SPEED = 2.0
const EVO_TREE_AVAILABLE_PULSE_ALPHA = Vector2(0.6, 1.0)
const EVO_AVAILABLE_NOTIFICATION_DURATION = 3.0
```

## Criterios de aceite

1. [ ] Tela mostra todas as 12 evolucoes em grid 4x3
2. [ ] Cards mostram arma + item + evolucao com icones
3. [ ] Estados visuais distintos (bloqueado/descoberto/disponivel/evoluido)
4. [ ] Painel de detalhes ao selecionar card
5. [ ] Tab "Evolucoes" funciona no InventoryOverlay in-game
6. [ ] Evolucoes disponiveis destacadas com borda pulsante
7. [ ] Notificacao no HUD quando evolucao fica disponivel
8. [ ] Historico de evolucoes salvo entre sessoes
9. [ ] Navegacao completa por gamepad
10. [ ] Tela cabe em 1280x720 sem scroll

## Arquivos afetados

- `game/scripts/ui/evolution_tree.gd` — novo script da tela
- `game/scenes/ui/evolution_tree.tscn` — nova cena
- `game/scripts/ui/inventory_overlay.gd` — nova tab "Evolucoes"
- `game/scripts/ui/main_menu.gd` — botao "Evolucoes"
- `game/scripts/autoload/evolution_db.gd` — historico
- `game/scripts/autoload/save_manager.gd` — persistencia evolution_history
- `game/scripts/autoload/game_constants.gd` — constantes EVO_*
- `game/assets/translations/*.csv` — textos da tela

## Estimativa

Complexidade: media
Tempo estimado: 3-4 horas
Impacto: alto (driver de replay, entendimento do sistema)
