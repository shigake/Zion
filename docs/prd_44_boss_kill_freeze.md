# PRD 44 — Screen freeze no golpe final do boss

**Status:** Pendente  
**Prioridade:** Alta  
**Esforço estimado:** Pequeno (< 2h)  
**Tipo:** Polish / Game feel  

---

## Resumo

Quando um Sentinela chega a 0 HP, o tempo congela por 3–5 frames (~0.07s) antes da animação de morte começar. É uma técnica clássica de action games (Street Fighter, Hades, Dead Cells) que amplifica dramaticamente a sensação de impacto no golpe final — sem custo técnico significativo.

Narrativamente: o momento em que o cristal do Sentinela se rompe, libertando-o da corrupção, merece esse instante de silêncio dramático.

---

## Problema

Atualmente, quando o boss morre:

1. O último hit acerta normalmente
2. `take_damage()` detecta `hp <= 0` e chama `call_deferred("_die")`
3. A animação de morte começa imediatamente no próximo frame

Não há distinção visual entre matar um inimigo genérico e derrotar um Sentinela. O momento mais importante da run passa sem peso dramático.

O sistema de `hit_freeze` já existe (`ScreenEffects.hit_freeze()`) e é usado em hits normais com duração de 0.04s. O boss kill precisa de uma versão mais longa e dedicada, com um toque visual extra.

---

## Solução

### Novo fluxo ao boss morrer

```
Último hit → hp ≤ 0 → [BOSS KILL FREEZE] → _die() → animação de morte
                              ↓
                   time_scale = 0.0 por ~0.07s reais
                   + flash branco intenso (alpha 0.6)
                   + screen shake suave
```

O freeze usa `Engine.time_scale = 0.0` em vez de `0.1` — pausa total, mais dramático. O flash branco cobre a tela brevemente, como uma explosão de energia ao libertar o Sentinela.

---

## Implementação

### 1. `game/scripts/autoload/game_constants.gd`

Adicionar ao bloco de constantes de boss (próximo de `DAMAGE_FREEZE_THRESHOLD`):

```gdscript
const BOSS_KILL_FREEZE_DURATION   := 0.07   # Segundos reais de pausa total (≈4 frames a 60fps)
const BOSS_KILL_FLASH_ALPHA       := 0.55   # Opacidade do flash branco no kill
const BOSS_KILL_SHAKE_AMOUNT      := 18.0   # Intensidade do screen shake pós-freeze
```

### 2. `game/scripts/effects/screen_effects.gd`

Adicionar nova função `boss_kill_freeze()` logo após `hit_freeze()`:

```gdscript
func boss_kill_freeze() -> void:
	var duration: float = GameConstants.BOSS_KILL_FREEZE_DURATION
	# Accessibility: reduced motion → pula o freeze, mantém só o flash
	if AccessibilityManager.reduced_motion:
		flash(0.12, GameConstants.BOSS_KILL_FLASH_ALPHA * 0.4)
		return
	# Pausa total + flash branco intenso
	Engine.time_scale = 0.0
	flash(0.12, GameConstants.BOSS_KILL_FLASH_ALPHA)
	# Timer com process_always=true para rodar mesmo com time_scale=0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	# Screen shake suave após retomar
	screen_shake(GameConstants.BOSS_KILL_SHAKE_AMOUNT, 0.25)
```

> **Nota técnica:** `create_timer(duration, true, false, true)` — o quarto argumento `ignore_time_scale=true` garante que o timer corre em tempo real mesmo com `time_scale = 0.0`.

### 3. `game/scripts/enemies/enemy_base.gd`

Em `take_damage()`, antes de `call_deferred("_die")`, verificar se é boss:

```gdscript
# Trecho atual (linha ~717):
if hp <= 0:
    call_deferred("_die")

# Substituir por:
if hp <= 0:
    if is_in_group("boss"):
        ScreenEffects.boss_kill_freeze()
    call_deferred("_die")
```

Isso é tudo. O `call_deferred` garante que `_die()` executa no próximo frame, após o `await` do freeze terminar.

---

## Comportamento esperado

| Cenário | Resultado |
|---|---|
| Boss chega a 0 HP | Freeze total ~0.07s + flash branco + shake |
| Inimigo comum morre | Sem mudança (caminho existente) |
| Mini-boss morre | Sem mudança (não está no grupo `boss`) |
| `reduced_motion` ativo | Freeze pulado, só flash atenuado (alpha 0.22) |
| Multiplayer | Efeito puramente local — cada cliente roda o freeze no seu `Engine.time_scale` independentemente |
| Accessibility `hit_freeze` desativado | Freeze pulado (mesmo guard do `hit_freeze` normal) |

---

## O que está fora do escopo

- Animação de morte nova (asset work)
- Som especial no kill (seria PRD separado de audio)
- Freeze em mini-bosses
- Câmera zoom-in no boss morto
- Câmera lenta (slow motion) — diferente do freeze instantâneo

---

## Arquivos afetados

| Arquivo | Mudança |
|---|---|
| `game/scripts/autoload/game_constants.gd` | +3 constantes |
| `game/scripts/effects/screen_effects.gd` | +1 função `boss_kill_freeze()` |
| `game/scripts/enemies/enemy_base.gd` | +3 linhas em `take_damage()` |

**Total: ~10 linhas de código.**

---

## Critérios de aceite

- [ ] Matar qualquer um dos 10 Sentinelas congela a tela visivelmente por ~4 frames
- [ ] O flash branco aparece no momento do freeze
- [ ] O screen shake sutil ocorre imediatamente após o freeze
- [ ] Inimigos comuns NÃO têm o efeito
- [ ] Com `reduced_motion` ativo, o freeze é pulado mas o flash aparece (atenuado)
- [ ] Em multiplayer, o freeze ocorre localmente em cada cliente sem dessincronizar
- [ ] Nenhuma regressão nos testes smoke e combo

---

## Referências

- `ScreenEffects.hit_freeze()` — `game/scripts/effects/screen_effects.gd:129`
- `enemy_base._die()` — `game/scripts/enemies/enemy_base.gd:772`
- `GameConstants.DAMAGE_FREEZE_*` — `game/scripts/autoload/game_constants.gd:458`
- ADR-008 (acessibilidade) — `docs/adr/ADR-008.md`
