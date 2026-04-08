# PRD 38 — Audio ducking avancado e mix de 5 buses

**Status**: concluido
**Tipo**: polish
**Prioridade**: alta
**Versao alvo**: 3.53.0

---

## Problema

O sistema de audio ja possui 5 buses (Master, Music, SFX/Combat/UI_Audio/Pickup/Ambient, Voice) e ducking basico (musica baixa em level-up e boss spawn). Porem:

1. **Dialogos de boss** nao ativam ducking — SFX de combate abafa as falas
2. **4 players em co-op** geram cacofonia — sem limiter global, sons se empilham
3. **Transicoes de fase** nao tem duck — musica continua no mesmo volume durante momentos dramaticos
4. **Ambient** nao tem fade inteligente — corta seco entre fendas
5. **Combat bus** pode saturar com muitos inimigos (8 slots nem sempre bastam)

## Objetivo

Aprimorar o AudioManager com ducking contextual inteligente, limiter global para multiplayer, crossfade de ambient entre fendas, e prioridade de audio baseada em importancia.

## Escopo

### Incluso
- Ducking automatico durante dialogos de boss (Voice > tudo)
- Ducking durante transicao de fase 3 (PRD 36)
- Limiter global por bus para multiplayer (max simultaneous sounds)
- Crossfade de ambient ao trocar de fenda
- Prioridade de SFX (boss > player > enemy > pickup)
- Compressor suave no Master bus para evitar clipping
- Volume dinamico baseado em quantidade de inimigos vivos

### Fora de escopo
- Novos SFX ou musicas
- Mixagem 3D espacial (ja existe atenuacao por distancia)
- Sistema de reverb por ambiente

## Especificacao tecnica

### 1. Hierarquia de ducking contextual

```
Prioridade (maior ducks menor):
1. Voice (dialogos boss)     → duck Music -18dB, SFX -8dB
2. Cinematics (transicoes)   → duck Music -15dB, SFX -6dB  
3. Boss SFX                  → duck Ambient -10dB
4. Level-up (ja existe)      → duck Music -18dB
5. Normal gameplay           → sem ducking
```

**Implementacao:**

```gdscript
enum DuckPriority { NONE, LEVEL_UP, BOSS_SFX, CINEMATIC, VOICE }

var _current_duck_priority: DuckPriority = DuckPriority.NONE
var _duck_stack: Array[Dictionary] = []  # {priority, music_db, sfx_db, duration}

func push_duck(priority: DuckPriority, music_db: float, sfx_db: float, duration: float) -> void:
    # Adiciona ao stack, aplica se maior prioridade
    
func pop_duck(priority: DuckPriority) -> void:
    # Remove do stack, restaura anterior ou normal
```

### 2. Integracao com BossDialogue

Quando `BossDialogue._show_dialogue()` e chamado:

```gdscript
AudioManager.push_duck(DuckPriority.VOICE, -18.0, -8.0, dialogue_duration)
# Ao fechar dialogo:
AudioManager.pop_duck(DuckPriority.VOICE)
```

### 3. Limiter para multiplayer (4 players)

**Problema:** 4 jogadores = 4x ataques, 4x pickups, 4x dano = saturacao.

**Solucao — Budget por bus baseado em player count:**

| Bus | 1 player | 2 players | 3 players | 4 players |
|-----|----------|-----------|-----------|-----------|
| Combat | 8 | 6 | 5 | 4 |
| Pickup | 4 | 3 | 2 | 2 |
| Ambient | 2 | 2 | 2 | 2 |
| UI_Audio | 2 | 2 | 2 | 2 |
| Voice | 1 | 1 | 1 | 1 |

**Implementacao:**
```gdscript
func _get_bus_limit(bus_name: String) -> int:
    var player_count = MultiplayerManager.get_player_count()
    var base = BUS_LIMITS[bus_name]
    if player_count <= 1:
        return base
    return max(2, base - (player_count - 1))
```

### 4. Prioridade de SFX

Quando o bus Combat esta cheio, substituir o som de menor prioridade:

```gdscript
enum SFXPriority { PICKUP = 0, ENEMY_HIT = 1, ENEMY_DEATH = 2, PLAYER_ATTACK = 3, PLAYER_HIT = 4, BOSS_ATTACK = 5, BOSS_PHASE = 6 }

var _active_sfx: Array[Dictionary] = []  # {player, priority, time_started}

func play_sfx_prioritized(sfx_name: String, priority: SFXPriority, ...) -> void:
    if _active_sfx.size() >= bus_limit:
        # Encontrar som de menor prioridade e mais antigo
        var lowest = _find_lowest_priority()
        if lowest.priority < priority:
            lowest.player.stop()
            _active_sfx.erase(lowest)
        else:
            return  # Drop este som
    # Play normalmente
```

### 5. Volume dinamico por densidade de inimigos

Quando ha muitos inimigos vivos, reduzir volume individual de hits:

```gdscript
func _get_enemy_volume_modifier() -> float:
    var enemy_count = GameManager.enemies_alive
    if enemy_count <= 20:
        return 0.0  # dB, sem reducao
    elif enemy_count <= 50:
        return -3.0  # dB
    elif enemy_count <= 100:
        return -6.0  # dB
    else:
        return -9.0  # dB
```

### 6. Crossfade de ambient

Ao trocar de fenda ou entrar em boss arena:

```gdscript
func crossfade_ambient(new_ambient: String, duration: float = 1.5) -> void:
    # Fade out ambient atual em duration/2
    # Fade in novo ambient em duration/2
    # Overlap no meio para transicao suave
```

### 7. Compressor no Master bus

Adicionar efeito AudioEffectCompressor ao Master bus via codigo no `_ready()`:

```gdscript
func _setup_master_compressor() -> void:
    var compressor = AudioEffectCompressor.new()
    compressor.threshold = -6.0      # dB — comeca a comprimir
    compressor.ratio = 4.0           # 4:1 compression
    compressor.attack_us = 20000.0   # 20ms attack
    compressor.release_ms = 200.0    # 200ms release
    compressor.gain = 0.0            # sem makeup gain
    var master_idx = AudioServer.get_bus_index("Master")
    AudioServer.add_bus_effect(master_idx, compressor)
```

### 8. Constantes em `game_constants.gd`

```gdscript
# Audio Ducking
const DUCK_VOICE_MUSIC_DB = -18.0
const DUCK_VOICE_SFX_DB = -8.0
const DUCK_CINEMATIC_MUSIC_DB = -15.0
const DUCK_CINEMATIC_SFX_DB = -6.0
const DUCK_BOSS_AMBIENT_DB = -10.0
const DUCK_TRANSITION_TIME = 0.3
const DUCK_RESTORE_TIME = 0.5

# Multiplayer Audio Limits
const AUDIO_BUS_LIMITS = {
    "Combat": 8, "Pickup": 4, "Ambient": 2, "UI_Audio": 2, "Voice": 1
}

# Dynamic Volume
const AUDIO_ENEMY_THRESHOLD_LOW = 20
const AUDIO_ENEMY_THRESHOLD_MED = 50
const AUDIO_ENEMY_THRESHOLD_HIGH = 100
const AUDIO_ENEMY_DUCK_LOW = -3.0
const AUDIO_ENEMY_DUCK_MED = -6.0
const AUDIO_ENEMY_DUCK_HIGH = -9.0

# Master Compressor
const MASTER_COMPRESSOR_THRESHOLD = -6.0
const MASTER_COMPRESSOR_RATIO = 4.0
const MASTER_COMPRESSOR_ATTACK_US = 20000.0
const MASTER_COMPRESSOR_RELEASE_MS = 200.0
```

## Criterios de aceite

1. [ ] Dialogos de boss ducam musica e SFX automaticamente
2. [ ] Transicao fase 3 ducka musica
3. [ ] 4 players nao causam clipping ou cacofonia
4. [ ] SFX de boss sempre toca (prioridade maxima)
5. [ ] Volume de hits reduz com 50+ inimigos na tela
6. [ ] Ambient faz crossfade suave entre fendas
7. [ ] Compressor no Master previne clipping
8. [ ] Stack de ducking funciona (voice > cinematic > level_up)
9. [ ] Nenhuma regressao em gameplay single-player

## Arquivos afetados

- `game/scripts/autoload/audio_manager.gd` — duck stack, priority system, compressor, crossfade
- `game/scripts/ui/boss_dialogue.gd` — chamar push_duck/pop_duck
- `game/scripts/effects/screen_effects.gd` — duck durante transicao fase 3
- `game/scripts/autoload/game_constants.gd` — constantes de audio

## Estimativa

Complexidade: media
Tempo estimado: 2-3 horas
Impacto: alto (audio profissional, multiplayer jogavel)
