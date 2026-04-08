# PRD 59 — Tela de stats pos-run expandida

**Status**: pendente
**Prioridade**: media
**Tipo**: feedback / retencao

---

## Problema

A tela de game over ja tem 2 tabs (Resumo + Registro Dimensional) com stats basicos, mas faltam metricas que os jogadores de roguelite adoram comparar: DPS medio da run, arma que mais matou, maior combo de kills, pico de inimigos na tela, timeline de eventos, e graficos de performance ao longo do tempo.

A telemetria ja coleta muito (`get_run_stats()`), mas a tela nao mostra tudo. Alem disso, nao existe um historico de runs anteriores para comparacao.

## Solucao

Expandir a tela de game over com 2 novas tabs e adicionar historico de runs.

## Especificacao tecnica

### 1. Nova Tab 3: "Analise de combate"

**Layout**:
```
┌─── Analise de combate ──────────────────────────┐
│                                                   │
│  ⚔ DPS Medio: 245.3/s          ⏱ Tempo: 12:34  │
│  💥 Maior hit: 1,247 (Katana)  🎯 Precisao: 87% │
│  🔥 Combo maximo: 47 kills     📊 Pico DPS: 892  │
│                                                   │
│  ── Ranking de armas por kills ──                │
│  1. [icon] Katana ............ 423 kills (38%)   │
│  2. [icon] Cajado ............ 289 kills (26%)   │
│  3. [icon] Chicote ........... 198 kills (18%)   │
│  4. [icon] Totem ............. 112 kills (10%)   │
│  5. [icon] Arco .............. 89 kills  (8%)    │
│                                                   │
│  ── Sinergia MVP ──                              │
│  ⚡ Relampago em Cadeia: 34 procs, 4,521 dano    │
│  🔥 Combustao: 12 procs, 2,100 dano              │
│                                                   │
│  ── Ranking de dano por fonte ──                 │
│  ████████████████████░░░░ Armas: 78%             │
│  ██████░░░░░░░░░░░░░░░░░ Sinergias: 15%         │
│  ███░░░░░░░░░░░░░░░░░░░░ Outros: 7%             │
│                                                   │
└───────────────────────────────────────────────────┘
```

**Novas metricas a rastrear** (adicionar em `game_manager.gd`):

| Metrica | Variavel | Como calcular |
|---|---|---|
| DPS medio | `avg_dps` | `total_damage_dealt / game_time` |
| Pico DPS (janela 5s) | `dps_peak` | Ja existe! Max de `_dps_window` |
| Maior combo (kills sem pausa >2s) | `max_kill_combo` | Contador que reseta se >2s sem kill |
| Kill por minuto | `kills_per_minute` | `total_kills / (game_time / 60)` |
| Precisao (ranged) | `ranged_accuracy` | `hits / shots_fired` (so ranged) |
| Pico de inimigos simultaneos | `peak_enemies` | Ja existe! |
| Dano de sinergias total | `synergy_total_dmg` | `SynergySystem.synergy_total_damage` somatório |
| Tempo sem tomar dano | `longest_no_damage_streak` | Ja existe! |
| Dano por fonte (%) | calculado | armas vs sinergias vs thorns vs outros |

**Combo de kills**: novo sistema
```gdscript
var _kill_combo: int = 0
var _kill_combo_max: int = 0
var _last_kill_time: float = 0.0
const COMBO_TIMEOUT := 2.0

func _on_enemy_killed():
    var now = game_time
    if now - _last_kill_time < COMBO_TIMEOUT:
        _kill_combo += 1
    else:
        _kill_combo = 1
    _last_kill_time = now
    if _kill_combo > _kill_combo_max:
        _kill_combo_max = _kill_combo
```

### 2. Nova Tab 4: "Timeline"

**Layout**: grafico simplificado da run ao longo do tempo

```
┌─── Timeline da run ─────────────────────────────┐
│                                                   │
│  DPS ao longo do tempo                            │
│  ▁▂▃▅▆▇█▇▆▅▃▅▇████▇▆▅▃▂▁▂▃▅▇██████            │
│  0:00          5:00         10:00       12:34     │
│                                                   │
│  Marcos da run                                    │
│  ──●──────●────●──────●────●──────●───→          │
│  0:00   1:23  3:45   5:12  8:30  10:02 12:34     │
│  Start  Lv5   Boss1  Evo!  Quest  Lv15  Morte    │
│                                                   │
│  Eventos                                          │
│  [2:00] 🎲 Anomalia: Chuva de Meteoros            │
│  [4:30] 📦 Bau aberto: Cajado Arcano              │
│  [6:15] ⚡ Sinergia ativada: Relampago em Cadeia  │
│  [8:00] 👹 Sentinela Corrompido apareceu          │
│  [10:02] 🏆 Quest concluida: 100 kills            │
│                                                   │
└───────────────────────────────────────────────────┘
```

**Dados a gravar durante a run** (sampling a cada 5s):
```gdscript
var _timeline_samples: Array = []  # [{time, dps, kills, hp_pct, enemies_alive}]
var _timeline_events: Array = []   # [{time, type, description}]

func _sample_timeline():
    _timeline_samples.append({
        "time": game_time,
        "dps": _current_dps,
        "kills": total_kills,
        "hp_pct": float(player_hp) / float(player_max_hp),
        "enemies": _enemies_alive_count
    })
```

**Eventos a logar**:
- Level ups (nivel 5, 10, 15, etc.)
- Arma adquirida
- Item adquirido
- Evolucao
- Sinergia ativada (1a vez)
- Boss spawn / boss kill
- Quest iniciada / concluida
- Evento/anomalia
- Bau aberto
- Near-death (<10% HP)
- Morte / vitoria

**Grafico DPS**: renderizado com `_draw()` como barras verticais (sparkline), cor gradiente verde→amarelo→vermelho baseado no valor relativo ao pico.

### 3. Historico de runs

**Salvar em SaveManager**:
```gdscript
"run_history": [
    {
        "date": "2025-04-05",
        "character": "ronin",
        "stage": "cemetery",
        "time": 734.5,
        "kills": 1234,
        "level": 15,
        "victory": false,
        "crystals": 450,
        "dps_avg": 245.3,
        "max_combo": 47,
        "weapons": ["katana", "staff", "whip"],
        "evolutions": ["zangetsu"],
        "synergies_active": ["ice_ice", "fire_ice"]
    },
    ...
]
```

**Limite**: ultimas 50 runs (FIFO)

**Exibicao**: botao "Historico" na tela de game over ou no menu principal, mostrando tabela scrollavel com as runs anteriores. Clicar numa run mostra o resumo salvo.

### 4. Medals/classificacao da run

Baseado na performance, dar uma classificacao:

| Classificacao | Criterio |
|---|---|
| S | Vitoria + DPS > 500 + Combo > 30 |
| A | Vitoria OU (DPS > 300 + Combo > 20) |
| B | Tempo > 10min + Kills > 500 |
| C | Tempo > 5min + Kills > 200 |
| D | Qualquer outra run |

Exibir a classificacao em dourado grande na tab de Resumo. Incentiva replays para melhorar a nota.

### 5. Compartilhamento

Botao "Copiar resumo" que gera texto formatado para clipboard:
```
🎮 Zion — Run Report
━━━━━━━━━━━━━━━━━━
🏆 Rank: A
⚔️ Ronin | Cemiterio Dimensional
⏱ 12:34 | Lv.15 | 1,234 kills
💥 DPS: 245/s | Combo: 47x
⚡ Sinergias: Relampago em Cadeia, Combustao
🌟 Evolucoes: Zangetsu
💎 Cristais: 450
```

## Criterios de aceite

- [ ] Tab "Analise de combate" com DPS medio, maior combo, ranking de armas, sinergias
- [ ] Tab "Timeline" com grafico DPS e log de eventos cronologico
- [ ] Combo de kills rastreado durante gameplay
- [ ] Historico de ultimas 50 runs salvo e acessivel
- [ ] Classificacao S/A/B/C/D exibida no resumo
- [ ] Botao "Copiar resumo" funciona
- [ ] Todas as metricas novas coletadas sem impacto de performance
- [ ] Sampling de timeline a cada 5s (max ~180 pontos em run de 15min)
- [ ] Cabe em 1280x720 (tabs com scroll se necessario dentro de cada tab)
- [ ] Localizado (pt_BR e en)

## Narrativa

O "Registro Dimensional" e mantido pelo estilhaco de Zion — ele grava automaticamente as ressonancias de combate do Fragmentado. A classificacao representa o nivel de restauracao que aquela run contribuiu para Zion. Rank S = restauracao perfeita.

## Estimativa

~6-8 horas. Duas tabs novas com graficos, novo tracking de combo/timeline, historico persistente, sistema de ranks.
