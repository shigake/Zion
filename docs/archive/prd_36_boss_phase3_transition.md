# PRD 36 — Transicao visual epica na fase 3 dos bosses

**Status**: concluido
**Tipo**: polish
**Prioridade**: alta
**Versao alvo**: 3.53.0

---

## Problema

Quando um boss entra na fase 3 (25% HP), a transicao e sutil demais — apenas um signal `boss_phase_changed` e emitido, o sprite fica vermelho, e toca um SFX. O jogador muitas vezes nem percebe que o boss entrou em frenzy mode. Isso desperdia um momento dramatico que deveria ser o climax da boss fight.

Ja existe `boss_entrance_effect()` em `screen_effects.gd` com letterbox, slow-mo, zoom, shake e particles — mas nao ha equivalente para a transicao de fase 3.

## Objetivo

Criar uma sequencia cinematica automatica de ~1.5s quando qualquer boss entra na fase 3 (25% HP), usando os sistemas ja existentes (ScreenEffects, ParticleFactory, AudioManager, camera_follow) para maximizar o impacto dramatico sem implementar nada do zero.

## Escopo

### Incluso
- Sequencia cinematica de transicao fase 3 em todos os 10 bosses + 20 alt bosses
- Camera zoom-in no boss + slow-mo
- Flash + shake escalado
- Burst de particulas no boss (cor tematica)
- Letterbox cinematico rapido
- Ducking de audio + SFX dedicado
- Texto dramatico ("FURIA DESPERTA" / "FURY UNLEASHED")
- Vibração de gamepad intensa
- Respeitar AccessibilityManager (reduced_motion, reduced_flash)

### Fora de escopo
- Mudancas no comportamento dos bosses (apenas visual)
- Novas animacoes de sprite
- Cutscenes com dialogo (BossDialogue ja cuida disso separadamente)

## Especificacao tecnica

### 1. Nova funcao em `screen_effects.gd`

```gdscript
func boss_phase3_transition(boss_position: Vector3, boss_color: Color) -> void
```

**Sequencia (timeline ~1.5s):**

| Tempo | Efeito | Detalhes |
|-------|--------|----------|
| 0.00s | Slow-mo | `Engine.time_scale = 0.15` (mais lento que entrada) |
| 0.00s | Letterbox | Barras cinematicas rapidas (0.2s slide-in) |
| 0.05s | Camera zoom | FOV -= 20 (zoom mais agressivo que entrada) |
| 0.10s | Shake 1 | `shake(0.3)` — tremor medio |
| 0.20s | Flash 1 | Flash branco 0.15 alpha, 0.08s |
| 0.30s | Particulas | `ParticleFactory.spawn_death_particles(boss_pos, boss_color, 20)` |
| 0.40s | Shake 2 | `shake(0.5)` — tremor forte |
| 0.50s | Flash 2 | Flash com cor do boss, 0.2 alpha, 0.1s |
| 0.60s | Titulo | "FURIA DESPERTA" centralizado, vermelho pulsante |
| 0.60s | Vibração | Weak: 1.0, Strong: 1.0 por 0.4s |
| 0.80s | Shake 3 | `shake(0.7)` — tremor maximo |
| 0.90s | Particulas 2 | Segundo burst de particulas (30 count) |
| 1.00s | Camera snap | FOV volta com overshoot (+5, depois normal) |
| 1.20s | Letterbox out | Barras saem (0.2s) |
| 1.30s | Slow-mo end | `Engine.time_scale = 1.0` gradual (0.2s) |
| 1.50s | Completo | Tudo normal |

### 2. Integracao com bosses

Em cada `boss_*.gd`, no bloco que detecta `hp_ratio <= BOSS_PHASE_2_THRESHOLD` (fase 3):

```gdscript
# Apos emitir boss_phase_changed
if not _phase3_transition_done:
    _phase3_transition_done = true
    ScreenEffects.boss_phase3_transition(global_position, boss_color)
```

### 3. Texto dramatico

Usar o sistema existente de `boss_title_card()` como base, mas com estilo diferente:
- Texto: localizado via `LocaleManager.tr_key("boss_phase3_fury")`
- Cor: vermelho brilhante `Color(1.0, 0.15, 0.1)`
- Efeito: scale bounce 0.2 → 1.3 → 1.0
- Duracao: 1.5s display, 0.3s fade out
- Subtitulo: nome do boss em fonte menor

### 4. Constantes em `game_constants.gd`

```gdscript
# Boss Phase 3 Transition
const BOSS_P3_SLOW_MO_SCALE = 0.15
const BOSS_P3_SLOW_MO_DURATION = 1.3
const BOSS_P3_ZOOM_AMOUNT = 20.0
const BOSS_P3_SHAKE_1 = 0.3
const BOSS_P3_SHAKE_2 = 0.5
const BOSS_P3_SHAKE_3 = 0.7
const BOSS_P3_FLASH_ALPHA = 0.15
const BOSS_P3_PARTICLES_1 = 20
const BOSS_P3_PARTICLES_2 = 30
const BOSS_P3_TITLE_SCALE_OVERSHOOT = 1.3
const BOSS_P3_RUMBLE_WEAK = 1.0
const BOSS_P3_RUMBLE_STRONG = 1.0
const BOSS_P3_RUMBLE_DURATION = 0.4
```

### 5. Audio

- Ducking de musica para -20dB por 1.5s
- SFX: reusar "boss_phase" com pitch mais baixo (0.7x) para soar mais ameacador
- Opcional: burst de grave/bass hit se disponivel nos assets

### 6. Acessibilidade

- `reduced_motion`: pular slow-mo e zoom, manter apenas titulo + shake leve (0.15)
- `reduced_flash`: pular ambos os flashes, manter particulas reduzidas (30%)
- Sempre respeitar `AccessibilityManager.can_flash()`

## Criterios de aceite

1. [ ] Todos os 10 bosses + 20 alt bosses disparam a transicao ao entrar fase 3
2. [ ] Sequencia dura ~1.5s e nao interrompe gameplay alem disso
3. [ ] Camera volta ao normal apos a sequencia
4. [ ] Texto "FURIA DESPERTA" aparece localizado (PT/EN)
5. [ ] Gamepad vibra durante a transicao
6. [ ] Reduced motion desativa slow-mo e zoom
7. [ ] Reduced flash desativa flashes
8. [ ] Nao causa lag visivel (particulas dentro do budget de 35)
9. [ ] Transicao so acontece uma vez por boss fight (flag _phase3_transition_done)
10. [ ] Funciona em multiplayer (cada client roda a animacao localmente)

## Arquivos afetados

- `game/scripts/effects/screen_effects.gd` — nova funcao `boss_phase3_transition()`
- `game/scripts/autoload/game_constants.gd` — novas constantes BOSS_P3_*
- `game/scripts/enemies/boss_*.gd` — chamar transicao (10 + 20 arquivos)
- `game/scripts/enemies/boss_generic.gd` — template para alt bosses
- `game/assets/translations/*.csv` — texto "FURIA DESPERTA" / "FURY UNLEASHED"

## Estimativa

Complexidade: media
Tempo estimado: 2-3 horas
Impacto visual: muito alto
