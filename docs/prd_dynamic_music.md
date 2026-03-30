# PRD — Música Dinâmica por Fenda

> Cada fenda deve tocar sua trilha sonora única ao iniciar a run, com transição dinâmica para a track de boss e intensificação por fase.

---

## Tarefa 1: Implementar Transição de Música no Início da Run

**Objetivo:** Ao entrar numa fenda, trocar a música do menu/lobby para a track específica daquela fase.

### Contexto

O `AudioManager` (`res://scripts/autoload/audio_manager.gd`) já suporta crossfade entre tracks (linhas 113-121) e já tem as 12 tracks registradas em `_valid_music` (linha 36):

```
"menu", "cemetery", "forest", "farm", "boss",
"tokyo", "volcano", "ocean", "arena", "space", "castle", "candy",
"victory", "shop", "lobby", "game_over_music"
```

O cenário atual: cada stage script deve chamar `AudioManager.play_music(stage_name)` no `_ready()`. Verificar se todos os 10 stage scripts fazem isso corretamente.

### Detalhes

1. Auditar os 10 scripts de stage em `scripts/stages/` para garantir que cada um chama `AudioManager.play_music()` com o ID correto.
2. Criar/adquirir arquivos de áudio em `res://assets/audio/music/` para cada fenda que ainda não tenha:

| Fenda | Arquivo esperado | Status |
|---|---|---|
| cemetery | `cemetery.ogg` | Verificar |
| forest | `forest.ogg` | Verificar |
| farm | `farm.ogg` | Verificar |
| tokyo | `tokyo.ogg` | Verificar |
| volcano | `volcano.ogg` | Verificar |
| ocean | `ocean.ogg` | Verificar |
| arena | `arena.ogg` | Verificar |
| space | `space.ogg` | Verificar |
| castle | `castle.ogg` | Verificar |
| candy | `candy.ogg` | Verificar |

3. Cada track deve ter estilo chiptune condizente com o tom narrativo da fenda (ex: Castle = gótico, Tokyo = synthwave, Candy = whimsical).

### Critérios de aceite

- [ ] Cada fenda toca uma música distinta ao entrar
- [ ] Crossfade suave de 1s entre menu → stage
- [ ] Sem interrupção abrupta de áudio

---

## Tarefa 2: Transição Automática para Música de Boss

**Objetivo:** Quando o boss spawna, trocar a trilha de stage para a track de boss com crossfade.

### Contexto

O `AudioManager` já escuta os sinais `boss_phase_changed` e `boss_died` do `GameManager` (linhas 78-79). A função `set_boss_phase_intensity()` (linha 251) ajusta pitch e volume por fase do boss.

### Detalhes

1. No `enemy_spawner.gd`, quando o boss spawna, emitir `GameManager.boss_spawned` (já existe) e adicionar `AudioManager.play_music("boss")`.
2. Quando o boss morre, restaurar a música da fenda: `AudioManager.play_music(GameManager.selected_stage)`.
3. A vitória deve tocar `AudioManager.play_music("victory")` (chamada já deve existir no fluxo de game over).

### Fluxo completo de música numa run

```
Menu → play_music("menu")
  → Lobby → play_music("lobby")
    → Stage start → play_music("cemetery") [crossfade 1s]
      → Boss spawn → play_music("boss") [crossfade 1s]
        → Boss fase 2 → pitch_scale = 1.08 [dinâmico]
        → Boss fase 3 → pitch_scale = 1.18 [dinâmico]
        → Boss fury → pitch_scale = 1.25 [dinâmico]
      → Boss killed → play_music("victory") [crossfade]
    → Game Over → play_music("game_over_music")
```

### Critérios de aceite

- [ ] Música troca automaticamente para "boss" quando o Sentinela spawna
- [ ] Intensificação de pitch funciona nas 3 fases + fury (já implementado)
- [ ] Ao derrotar o boss, toca "victory" com crossfade

---

## Tarefa 3: Variações de Intensidade por Tempo de Run

**Objetivo:** Escalar a música da fenda conforme o tempo avança e a dificuldade sobe.

### Detalhes

Adicionar ao `AudioManager` uma função que escala gradualmente o pitch da música da fenda conforme o `GameManager.game_time`:

```gdscript
func update_stage_music_intensity() -> void:
    if _current_music in ["menu", "lobby", "boss", "victory", "shop", "game_over_music"]:
        return  # Não escalar tracks de UI
    var time_factor = clampf(GameManager.game_time / 900.0, 0.0, 1.0)  # 0-15 min
    _music_player.pitch_scale = 1.0 + time_factor * 0.12  # Até +12% no minuto 15
```

Chamar essa função no `_process()` do `AudioManager`, após o bloco de crossfade.

### Critérios de aceite

- [ ] Música da fenda fica sutilmente mais rápida conforme a pressão aumenta
- [ ] Máximo de 12% de aceleração (quase imperceptível mas tensiona)
- [ ] Não aplica em tracks de menu/boss/victory

---

## Dependências

| Sistema | Tarefas |
|---|---|
| `AudioManager` (autoload) | 1, 2, 3 |
| `GameManager` (autoload) | 2, 3 |
| `enemy_spawner.gd` | 2 |
| Stage scripts (10x) | 1 |
| Arquivos `.ogg` em `assets/audio/music/` | 1 |

## Ordem de implementação

| Fase | Tarefas | Descrição |
|---|---|---|
| A | 1 | Auditoria de tracks + integração por fenda |
| B | 2 | Transição stage ↔ boss ↔ victory |
| C | 3 | Intensificação temporal (polish) |

## Prioridade

Média — Audio está ~70% completo (FASE D do roadmap). Música dinâmica é o diferencial.
