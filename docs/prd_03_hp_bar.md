# PRD 03 — Barra de HP nao aparece

## Problema
A barra de HP do jogador nao esta visivel. Deveria ficar embaixo do personagem no mundo 3D.

## Causa raiz
Existem DOIS sistemas de HP bar no projeto, ambos com problemas:

### Sistema 1: World-space HP bar (player.gd)
Em `player.gd` linhas 133-180, uma barra 3D eh criada usando BoxMesh. Problemas:
- **Muito pequena**: `bar_height = 0.06` unidades (quase invisivel)
- **Posicao muito baixa**: `Y = 0.15` — pode estar escondida pelo sprite do jogador ou pelo chao
- Atualizada em `_physics_process()` via `_update_world_hp_bar()` — logica funciona

### Sistema 2: HUD Character HP bar (character_hp_bar.gd)
Em `hud.gd` linha 103: `character_hp_bar.visible = false` — **explicitamente desabilitada**.
Comentario no codigo: "HP bar do HUD escondida — player tem barra world-space agora".
Esse sistema tem visual tematico por personagem (espada pro Ronin, cristal pro Mago, etc) mas nao eh usado.

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `scripts/player/player.gd` | `_setup_world_hp_bar()` (~L133-180) — cria a barra 3D |
| `scripts/player/player.gd` | `_update_world_hp_bar()` — atualiza fill + cor |
| `scripts/ui/hud.gd` | Linha 103 — `character_hp_bar.visible = false` |
| `scripts/ui/character_hp_bar.gd` | Barra tematica por personagem (280+ linhas, nao usada) |
| `scripts/ui/themed_hp_bar.gd` | Versao alternativa (303 linhas, nao usada) |

## Plano de implementacao

### Passo 1 — Corrigir a barra world-space no player.gd
Aumentar tamanho e reposicionar para ficar visivel embaixo do sprite:

```gdscript
# Antes:
var bar_width = 1.0
var bar_height = 0.06
_world_hp_bg.position = Vector3(0, 0.15, 0)

# Depois:
var bar_width = 1.6
var bar_height = 0.12
_world_hp_bg.position = Vector3(0, 0.05, 0.5)  # Mais baixo, levemente a frente
```

Valores exatos devem ser ajustados visualmente, mas a barra precisa:
- Largura ~1.6 unidades (proporcional ao sprite)
- Altura ~0.12 unidades (visivel mas nao exagerada)
- Posicao Y baixa o suficiente pra ficar ABAIXO do sprite
- Posicao Z levemente positiva para nao ficar atras do personagem

### Passo 2 — Adicionar billboard ao HP bar
A barra precisa sempre encarar a camera (o jogo eh 3D isometrico):

```gdscript
# Usar SpriteBase3D.BILLBOARD_FIXED_Y ou implementar manual
# Ou manter como mesh mas garantir que a rotacao acompanha a camera
```

### Passo 3 — Adicionar borda/outline para visibilidade
A barra de fundo (cinza escuro) precisa de uma borda preta fina para se destacar do cenario.

### Passo 4 — Transicao de cor
Manter a logica existente de cor:
- Verde (>50% HP)
- Amarelo (25-50% HP)
- Vermelho (<25% HP)

### Passo 5 — Testar com diferentes personagens
Verificar que a barra fica correta com todos os 15 Fragmentados, ja que sprites podem ter tamanhos diferentes.

## Nota sobre o sistema tematico
O `character_hp_bar.gd` tem 280+ linhas de codigo com visual unico por personagem. Pode ser habilitado futuramente no HUD se desejado (`hud.gd` linha 103 → `visible = true` + chamar `set_character()`). Por ora, foco na barra world-space abaixo do personagem.

## Validacao
- [ ] Barra de HP visivel embaixo do personagem
- [ ] Tamanho proporcional e legivel
- [ ] Cor muda verde → amarelo → vermelho conforme HP
- [ ] Funciona com todos os 15 personagens
- [ ] Nao obstrui a visao do personagem ou gameplay
- [ ] Visivel em todas as fendas (fundos claros e escuros)
