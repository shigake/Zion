# PRD 61 — Modo Endless (Fenda Infinita)

**Status**: pendente
**Prioridade**: media
**Tipo**: feature / retencao

---

## Problema

Atualmente, a run termina quando o jogador morre ou derrota o Sentinela do boss. Nao existe opcao de continuar jogando apos a vitoria. Jogadores que constroem builds poderosas querem testar os limites — "quanto tempo eu sobrevivo?". Modo endless e uma das features mais pedidas em todo survivors/roguelite.

## Solucao

Apos derrotar o Sentinela, o jogador pode escolher "Continuar na Fenda" para entrar no modo endless: dificuldade infinita, escala exponencial, leaderboard por tempo sobrevivido.

## Especificacao tecnica

### 1. Trigger de entrada

Apos o boss morrer (`GameManager.boss_died`):

**Tela de transicao**:
```
┌────────────────────────────────────────┐
│                                        │
│    ✨ Sentinela Libertado! ✨          │
│                                        │
│    A fenda se estabiliza...            │
│    mas a corrupcao ainda pulsa.        │
│                                        │
│    [Encerrar Run]  [Fenda Infinita]    │
│                                        │
│    ⚠ A dificuldade nao para de subir  │
│                                        │
└────────────────────────────────────────┘
```

- "Encerrar Run": vai para tela de game over normal com vitoria
- "Fenda Infinita": ativa modo endless

### 2. Mecanica de dificuldade infinita

**Escala apos boss**:

O timer continua rodando. A dificuldade agora escala mais rapido:

```gdscript
# Antes do boss (normal):
var difficulty_mult = 1.0 + (game_time / 60.0) * 0.15  # +15% por minuto

# Depois do boss (endless):
var base_time = boss_kill_time  # tempo quando matou o boss
var endless_time = game_time - base_time
var endless_mult = difficulty_mult_at_boss * (1.0 + (endless_time / 60.0) * 0.25)  # +25% por minuto
```

**Scaling por onda** (a cada 60s no endless):

| Onda | Buff |
|---|---|
| 1-3 | HP inimigos +20% por onda, dano +10% |
| 4-6 | Velocidade +15%, novos tipos de inimigos misturados de OUTRAS fendas |
| 7-9 | Mini-bosses a cada 45s, HP +30% por onda |
| 10+ | 2 mini-bosses por onda, HP exponencial, velocidade cap 2x |
| 15+ | "Corrida dimensional": inimigos de todas as fendas simultaneos |
| 20+ | Sentinela corrompido re-aparece (versao fortalecida, +50% stats) |

### 3. Ondas e marcadores

O endless e dividido em ondas de 60s cada. HUD mostra:
```
Onda 7 | 04:23 no endless | Dificuldade: 3.2x
```

A cada 5 ondas: evento especial (anomalia forcada)
A cada 10 ondas: mini-boss elite com afix especial

### 4. Recompensas do endless

**Cristais**: continuam dropando normalmente, mas com bonus:
```gdscript
var endless_crystal_bonus = 1.0 + (endless_wave * 0.1)  # +10% por onda
# Onda 10 = 2x cristais, Onda 20 = 3x cristais
```

**Conquistas de endless** (3 novas achievements):
- "Persistente": sobreviver 5 ondas no endless
- "Incansavel": sobreviver 10 ondas no endless
- "Eterno": sobreviver 20 ondas no endless

### 5. Inimigos cross-fenda

A partir da onda 4, inimigos tematicos de outras fendas comecam a aparecer:

```gdscript
func _get_endless_enemy_pool(wave: int) -> Array:
    var pool = current_stage.themed_enemies.duplicate()

    if wave >= 4:
        # Adicionar 1 tipo aleatorio de outra fenda
        var other_stages = ALL_STAGES.filter(func(s): return s != current_stage)
        var random_stage = other_stages[randi() % other_stages.size()]
        pool.append(random_stage.themed_enemies.pick_random())

    if wave >= 8:
        # Adicionar 2 tipos de outras fendas
        # ...

    if wave >= 15:
        # Todos os inimigos de todas as fendas
        for stage in ALL_STAGES:
            pool.append_array(stage.themed_enemies)

    return pool
```

### 6. Leaderboard de endless

Novo leaderboard separado:
- Ranking por **tempo total sobrevivido** (desde o inicio da run, nao so o endless)
- Filtro por fenda e por personagem
- Mostra: tempo, onda maxima, kills totais, build (armas + itens)
- Salvo localmente em `SaveManager` e enviado via `Telemetry`

**Estrutura**:
```gdscript
"endless_leaderboard": [
    {
        "character": "ronin",
        "stage": "cemetery",
        "total_time": 1847.3,  # 30min+
        "endless_waves": 18,
        "total_kills": 4523,
        "weapons": [...],
        "items": [...],
        "evolutions": [...],
        "date": "2025-04-05",
        "seed": "ABC123"
    }
]
```

### 7. Visual do endless

**Efeitos progressivos** conforme as ondas avancam:
- Onda 1-3: ambiente normal
- Onda 4-6: ceu fica mais escuro, particulas de distorcao no ar
- Onda 7-9: bordas da tela pulsam vermelho sutilmente
- Onda 10+: shader de distorcao no fundo (como se a realidade rachasse)
- Onda 15+: cores do cenario comecam a shiftar (hue rotation lento)
- Onda 20+: tudo fica monocromatico com apenas a corrupcao em cor

**Musica**: apos o boss, transicionar para versao "intensificada" da musica da fenda (se existir) ou manter a musica de boss fight com pitch gradualmente subindo (+0.02 por onda, cap 1.4x).

### 8. Morte no endless

Quando morre no endless:
- Tela de game over mostra todas as stats normais + stats do endless
- Secao especial: "Registro da Fenda Infinita"
  - Onda maxima alcancada
  - Tempo no endless
  - Kills no endless
  - Inimigos cross-fenda enfrentados
- Classificacao de endless (bronze/prata/ouro/diamante/cristal)

| Classificacao | Criterio |
|---|---|
| Cristal | Onda 20+ |
| Diamante | Onda 15-19 |
| Ouro | Onda 10-14 |
| Prata | Onda 5-9 |
| Bronze | Onda 1-4 |

### 9. Balanceamento

Parametros ajustaveis em `GameConstants`:
```gdscript
# Endless mode
const ENDLESS_WAVE_DURATION := 60.0
const ENDLESS_HP_SCALE_PER_WAVE := 0.2  # +20% HP por onda
const ENDLESS_DMG_SCALE_PER_WAVE := 0.1  # +10% dano por onda
const ENDLESS_SPEED_SCALE_PER_WAVE := 0.05  # +5% velocidade por onda
const ENDLESS_SPEED_CAP := 2.0
const ENDLESS_MINIBOSS_WAVE := 7  # primeira onda com mini-boss
const ENDLESS_CROSS_FENDA_WAVE := 4
const ENDLESS_BOSS_RETURN_WAVE := 20
const ENDLESS_CRYSTAL_BONUS_PER_WAVE := 0.1
const ENDLESS_DIFFICULTY_SCALE := 0.25  # +25% por min (vs 15% normal)
```

### 10. Integracao com sistemas existentes

- **Mutacoes**: ativas no endless (cristal bonus acumula)
- **Daily Challenge**: pode ter dias com "endless obrigatorio" (meta: onda X)
- **Quests**: novas quests de endless ("Sobreviva 10 ondas", "Mate 1000 no endless")
- **Telemetria**: enviar dados de endless separados
- **Achievements**: 3 novas conquistas de endless
- **Seeds**: seed compartilhavel inclui info de endless

## Criterios de aceite

- [ ] Opcao "Fenda Infinita" aparece apos derrotar o boss
- [ ] Dificuldade escala continuamente (HP, dano, velocidade, spawn rate)
- [ ] Ondas de 60s com marcador no HUD
- [ ] Inimigos cross-fenda a partir da onda 4
- [ ] Mini-bosses a partir da onda 7
- [ ] Boss re-aparece fortalecido na onda 20
- [ ] Cristais bonus escalam com a onda
- [ ] Leaderboard de endless separado
- [ ] 3 achievements de endless
- [ ] Efeitos visuais progressivos (ceu, bordas, distorcao)
- [ ] Tela de morte com stats de endless + classificacao
- [ ] Funciona com todas as 10 fendas
- [ ] Funciona com mutacoes ativas
- [ ] Performance estavel mesmo em ondas altas (culler + pools)

## Narrativa

Apos libertar o Sentinela, a fenda nao se fecha imediatamente — a corrupcao residual se intensifica, atraindo fragmentos de OUTRAS realidades. O Fragmentado pode escolher permanecer para purificar a corrupcao mais profunda. Cada onda representa camadas mais densas de corrupcao dimensional. Na onda 15+, as realidades comecam a se misturar (inimigos de todas as fendas). Na onda 20, a corrupcao e tao intensa que o proprio Sentinela (agora livre) retorna para lutar AO LADO do Fragmentado (narrativamente — mecanicamente e um boss fortalecido, mas a tela de vitoria pos-onda 20 poderia ter dialogo do Sentinela agradecendo).

## Estimativa

~10-14 horas. Feature grande com scaling system, cross-fenda enemies, leaderboard, achievements, e efeitos visuais progressivos.
