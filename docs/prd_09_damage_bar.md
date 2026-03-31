## Status: CONCLUIDO

# PRD 09 — Barrinha vermelha de dano feia

## Problema
Ao tomar dano, aparece uma barra/flash vermelho em posicao aleatoria na tela. Visual ruim.

## Causa raiz
Em `screen_effects.gd`, existem DOIS efeitos vermelhos:

### 1. Damage Flash (full-screen) — ESTE EH O PROBLEMA
Criado em `_ready()` linhas 51-55:
```gdscript
_damage_flash_rect = ColorRect.new()
_damage_flash_rect.color = Color(0.8, 0.0, 0.0, 0.0)  # Vermelho brilhante
# Full screen overlay
```

Ativado por `damage_feedback()` linha 209 → `damage_flash()`:
- Alpha max: 0.25 (25% opacidade)
- Duracao: 0.15s base + escala com dano
- Faz a tela inteira piscar vermelho

### 2. Vignette de HP baixo — ESTE TA OK
- Bordas vermelhas quando HP < 30%
- Pulsa com intensidade proporcional ao HP
- Efeito sutil e util

### 3. Indicador direcional — ESTE PODE SER A "BARRINHA"
Em `damage_feedback()` linha 246, spawna um retangulo vermelho/laranja na borda da tela apontando para a direcao do dano:
```gdscript
Color(1.0, 0.1, 0.05, 0.8)  # Vermelho/laranja forte
```
Esse retangulo aparece em posicao "aleatoria" (na verdade eh direcional, mas se o jogador nao percebe a direcao, parece aleatorio).

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `scripts/effects/screen_effects.gd` | `damage_feedback()` (~L196-222), `damage_flash()` (~L225-227), `_update_damage_flash()` (~L138-147), indicador direcional (~L246) |
| `scripts/player/player.gd` | `take_damage()` (~L382) — chama `ScreenEffects.damage_feedback()` |
| `scripts/autoload/game_constants.gd` | `DAMAGE_FLASH_BASE = 0.15`, `DAMAGE_FLASH_SCALE = 0.1` |

## Plano de implementacao

### Passo 1 — Remover o damage flash full-screen
Em `screen_effects.gd`:
- Remover criacao do `_damage_flash_rect` em `_ready()` (linhas 51-55)
- Remover `_update_damage_flash()` call em `_process()` (linha 108)
- Remover funcao `damage_flash()` (linhas 225-227)
- Remover a chamada `damage_flash()` em `damage_feedback()` (linha 209)

### Passo 2 — Avaliar o indicador direcional
Duas opcoes:
- **Remover**: se o jogador acha que parece uma "barrinha aleatoria"
- **Melhorar**: tornar mais sutil (reduzir opacidade, diminuir tamanho, fade mais rapido)

Recomendacao: **remover o indicador direcional tambem**. O jogo ja tem:
- Screen shake no hit
- Player sprite squash animation
- Vignette de HP baixo
- Numeros de dano
Isso ja eh feedback suficiente.

### Passo 3 — Manter efeitos bons
Nao remover:
- Screen shake (bom feedback)
- Hit freeze (micro-pausa de impacto)
- Vignette de HP baixo (util)
- Player sprite squash (bom visual)
- Gamepad vibration (bom feedback)

## Validacao
- [ ] Tomar dano nao mostra mais flash vermelho full-screen
- [ ] Nao aparece mais "barrinha" aleatoria
- [ ] Screen shake ainda funciona no hit
- [ ] Vignette de HP baixo ainda funciona
- [ ] Feedback de dano ainda eh perceptivel (shake + squash)
