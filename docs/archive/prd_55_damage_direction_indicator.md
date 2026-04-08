# PRD 55 — Indicador de dano direcional

**Status**: pendente
**Prioridade**: alta
**Tipo**: quality-of-life / feedback visual

---

## Problema

Em combates caoticos com muitos inimigos, o jogador toma dano sem saber de qual direcao veio. Isso causa mortes frustrantes e reduz a sensacao de controle. O sistema atual de feedback (flash vermelho, shake, ghost HP) indica **que** tomou dano, mas nao **de onde**.

O parametro `source_pos: Vector3` ja existe em `Player.take_damage()` mas nao e usado para feedback direcional.

## Solucao

Setas vermelhas semi-transparentes nas bordas da tela apontando na direcao da fonte de dano. Cada seta aparece por ~1s e faz fade out gradual.

## Especificacao tecnica

### 1. Novo node no HUD

Adicionar um `Control` node chamado `DamageDirectionLayer` como filho do HUD existente (`scripts/ui/hud.gd`).

### 2. Script `damage_direction_indicator.gd`

**Local**: `scripts/ui/damage_direction_indicator.gd`

**Logica principal**:
- Conectar ao sinal `GameManager.player_took_damage(amount, source_pos)` (novo sinal — ver item 5)
- Ao receber dano:
  1. Calcular angulo entre o jogador e `source_pos` no plano XZ
  2. Subtrair a rotacao da camera para obter direcao relativa a tela
  3. Posicionar uma seta na borda do viewport naquele angulo
  4. Escala da seta proporcional ao dano (dano alto = seta maior/mais opaca)

**Pool de setas**:
- Pre-instanciar 6 setas (maximo simultaneo razoavel)
- Cada seta: `TextureRect` com textura de seta vermelha (chevron/arrow)
- Rotacao: `atan2()` do vetor direcao
- Posicionamento: circulo inscrito no viewport (margem de ~40px das bordas)

**Animacao por seta**:
```
Aparece: alpha 0 → 0.7 em 0.1s (ease out)
Sustain: 0.5s
Fade: alpha 0.7 → 0 em 0.4s (ease in)
Total: ~1.0s
```

**Cor e estilo**:
- Cor base: `Color(1.0, 0.15, 0.15, 0.7)` — vermelho intenso
- Dano critico (>20% max HP): cor `Color(1.0, 0.0, 0.0, 0.9)` + seta 1.5x maior
- Borda glow sutil (shader opcional ou segunda textura levemente maior e mais opaca)

### 3. Textura da seta

Gerar proceduralmente via `_draw()` ou usar um chevron simples:
- Triangulo apontando para fora da tela
- Tamanho base: 32x48px
- Sem pixel art — forma geometrica limpa com gradiente de opacidade

### 4. Calculo de direcao

```gdscript
func _calculate_direction(source_pos: Vector3) -> float:
    var player_pos = GameManager.player_node.global_position
    var dir = (source_pos - player_pos)
    dir.y = 0  # projecao no plano XZ
    dir = dir.normalized()

    # Converter para angulo relativo a camera
    var cam = get_viewport().get_camera_3d()
    var cam_forward = -cam.global_basis.z
    cam_forward.y = 0
    cam_forward = cam_forward.normalized()

    var angle = atan2(dir.x, dir.z) - atan2(cam_forward.x, cam_forward.z)
    return angle
```

### 5. Novo sinal no GameManager

Adicionar em `game_manager.gd`:
```gdscript
signal player_took_damage_directional(amount: int, source_pos: Vector3)
```

Emitir dentro de `take_damage()` quando o dano efetivamente passar (apos dodge check, armor, etc):
```gdscript
# Apos calcular 'reduced' e aplicar ao HP
player_took_damage_directional.emit(reduced, _last_damage_source_pos)
```

No `player.gd`, salvar a posicao antes de chamar GameManager:
```gdscript
func take_damage(amount: int, source_pos: Vector3 = Vector3.ZERO):
    # ... checks existentes ...
    GameManager._last_damage_source_pos = source_pos
    GameManager.take_damage(amount)
```

### 6. Stacking de multiplas fontes

Se o jogador tomar dano de 3+ fontes simultaneas:
- Mostrar ate 6 setas simultaneas (pool)
- Setas proximas (<30 graus) se agrupam na direcao media
- Setas mais recentes tem prioridade visual (alpha maior)

### 7. Opcao de acessibilidade

Adicionar toggle em `AccessibilityManager`:
- `damage_direction_enabled: bool = true` (padrao: ligado)
- Opcao no menu de acessibilidade: "Indicador de direcao de dano"

### 8. Integracao com ScreenEffects

Disparar o indicador JUNTO com o feedback existente (`ScreenEffects.damage_feedback()`), nao substituindo. A seta complementa o shake/flash/vignette.

## Criterios de aceite

- [ ] Seta vermelha aparece na borda da tela na direcao correta do inimigo que causou dano
- [ ] Seta faz fade out em ~1s
- [ ] Dano alto gera seta maior/mais visivel
- [ ] Multiplos danos simultaneos mostram multiplas setas
- [ ] Funciona com camera isometrica do jogo
- [ ] Toggle de acessibilidade funciona
- [ ] Nao impacta performance (pool de 6 nodes leves)
- [ ] Nao aparece quando o dano vem de DoT sem posicao (source_pos == Vector3.ZERO)

## Narrativa

Os estilhacos de Zion dentro dos Fragmentados ressoam com as fontes de corrupcao. O indicador direcional representa essa "percepcao dimensional" — o cristal interno alertando sobre ameacas proximas.

## Estimativa

~2-3 horas. Implementacao simples com grande impacto na experiencia.
