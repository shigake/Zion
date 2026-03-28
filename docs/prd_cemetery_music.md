# PRD — Musica Dinamica da Fase Cemiterio

## Objetivo

Substituir a track unica `cemetery` por um sistema de musica dinamica com 5 faixas que mudam conforme o progresso da fase, criando uma experiencia sonora que acompanha a escalada de dificuldade — do inicio misterioso ate o boss final epico.

## Estado Atual

- `AudioManager` toca uma unica musica por fase via `play_music(stream_name)`
- `stage_cemetery.gd` define `music_track = "cemetery"` e chama `AudioManager.play_music()` no `_ready()`
- O sistema ja suporta crossfade entre musicas (`_crossfade_duration = 1.0s`)
- Musicas sao carregadas de `res://assets/audio/music/` (aceita `.ogg`, `.mp3`, `.wav`)
- Subdiretorios suportados: `stages/`, `menu/`, `boss/`

## Faixas de Audio

### 1. Musica de Inicio (Minutos 0 a 10) — `cemetery_intro`

**Contexto gameplay:** O jogador acabou de chegar. Neblina, lua amarela, primeiros slimes e morcegos aparecem. Poucos inimigos, fase de aquecimento.

**Direcao musical:** Assustadora mas com ritmo constante para iniciar a acao. Tom misterioso e gotico.

**Prompt para geracao por IA:**
> "16-bit retro video game music, spooky haunted graveyard theme, classic Castlevania style, chiptune with gothic pipe organ, moderate upbeat tempo, eerie but energetic, halloween pixel art game soundtrack, driving bassline, instrumental"

**Arquivo:** `res://assets/audio/music/stages/cemetery_intro.ogg`
**Duracao ideal:** 2-3 minutos (loop)
**BPM sugerido:** 120-130

---

### 2. Escalada da Horda (Minutos 10 a 20) — `cemetery_horde`

**Contexto gameplay:** Cemiterio lotado. Zombies corredores, esqueletos e fantasmas cercando o jogador. Intensidade maxima antes do boss.

**Direcao musical:** Mais rapida e intensa, com camadas de urgencia. Energia de bullet hell.

**Prompt para geracao por IA:**
> "Fast-paced 16-bit chiptune, action horde survival soundtrack, spooky retro synthwave, fast driving bassline, arcade action, eerie melodies mixed with high energy drums, FM synthesis Sega Genesis style, instrumental bullet hell music"

**Arquivo:** `res://assets/audio/music/stages/cemetery_horde.ogg`
**Duracao ideal:** 2-3 minutos (loop)
**BPM sugerido:** 150-160

---

### 3. Tema do Mini-Boss — `cemetery_miniboss`

**Contexto gameplay:** O Zombie Gigante aparece (agarra e esmaga). Momento de tensao maxima com inimigo pesado.

**Direcao musical:** Pesada, lenta e intimidadora. Passos pesados de monstro gigante em 16-bits.

**Prompt para geracao por IA:**
> "Heavy 16-bit boss battle theme, slow and stomping chiptune beat, menacing spooky dark organ, retro SNES style, heavy bass, dark and oppressive atmosphere, giant monster approaching, pixel art boss fight instrumental"

**Arquivo:** `res://assets/audio/music/stages/cemetery_miniboss.ogg`
**Duracao ideal:** 1.5-2 minutos (loop)
**BPM sugerido:** 90-100

---

### 4. Climax de Sobrevivencia (Minutos 20 a 25) — `cemetery_climax`

**Contexto gameplay:** Apice do caos antes do boss final. Tela atinge o limite de 500 inimigos simultaneos. Magias voando para todo lado, jogador desviando de tudo. Puro caos.

**Direcao musical:** Adrenalina pura. BPM altissimo, arpeggios freneticos, sensacao de overwhelm total.

**Prompt para geracao por IA:**
> "Intense high BPM chiptune, frantic 16-bit arpeggios, extreme arcade action soundtrack, spooky gothic undertones, retro adrenaline rush, overwhelming horde survival, fast synthesizer solos, pixel art bullet hell instrumental"

**Arquivo:** `res://assets/audio/music/stages/cemetery_climax.ogg`
**Duracao ideal:** 2-3 minutos (loop)
**BPM sugerido:** 170-180

---

### 5. Tema do Boss Final — Necromancer King — `cemetery_boss`

**Contexto gameplay:** O Rei Necromante aparece. 4 metros de altura, invoca hordas de mortos e lanca magias roxas. Batalha final epica.

**Direcao musical:** Epica, misturando o som gotico do cemiterio com a velocidade de uma batalha final. Pipe organ dramatico com bateria rapida.

**Prompt para geracao por IA:**
> "Epic 16-bit final boss theme, dark gothic chiptune, very fast-paced drums, dramatic classical pipe organ solos, Castlevania Symphony of the Night retro style, dark magic atmosphere, high stakes pixel art battle music, instrumental masterpiece"

**Arquivo:** `res://assets/audio/music/stages/cemetery_boss.ogg`
**Duracao ideal:** 2-3 minutos (loop)
**BPM sugerido:** 160-170

---

## Implementacao Tecnica

### Task 1 — Registrar novas tracks no AudioManager

**Arquivo:** `scripts/autoload/audio_manager.gd`

Adicionar as 5 novas tracks na lista `_valid_music`:
```
cemetery_intro, cemetery_horde, cemetery_miniboss, cemetery_climax, cemetery_boss
```

Manter `cemetery` como fallback (compatibilidade).

**Estimativa:** 5 min

---

### Task 2 — Sistema de musica dinamica no BaseStage

**Arquivo:** `scripts/stages/base_stage.gd`

Adicionar suporte opcional a troca de musica baseada no tempo de jogo:

```gdscript
# Configuracao de musica dinamica (subclasses preenchem)
var dynamic_music: Array[Dictionary] = []
# Formato: [{ "time": 0.0, "track": "cemetery_intro" }, { "time": 600.0, "track": "cemetery_horde" }]

var _current_dynamic_index: int = -1
```

No `_process()`, checar se o tempo de jogo (`GameManager.elapsed_time`) atingiu o proximo threshold e chamar `AudioManager.play_music()` com crossfade.

**Estimativa:** 20 min

---

### Task 3 — Configurar musica dinamica no stage_cemetery.gd

**Arquivo:** `scripts/stages/stage_cemetery.gd`

```gdscript
func _ready() -> void:
    music_track = "cemetery_intro"  # Track inicial
    dynamic_music = [
        { "time": 0.0, "track": "cemetery_intro" },
        { "time": 600.0, "track": "cemetery_horde" },    # 10 minutos
        { "time": 1200.0, "track": "cemetery_climax" },   # 20 minutos
    ]
    super._ready()
```

**Estimativa:** 5 min

---

### Task 4 — Trigger de musica do mini-boss e boss final

**Arquivo:** `scripts/stages/base_stage.gd` ou via signal

**Mini-boss:** Quando o mini-boss spawnar, trocar para `cemetery_miniboss`. Quando morrer, voltar para a track do tempo atual.

Opcoes de implementacao:
- **Signal:** `GameManager.miniboss_spawned` / `GameManager.miniboss_killed`
- **Direto:** O script do mini-boss chama `AudioManager.play_music("cemetery_miniboss")` no `_ready()` e emite signal ao morrer

Ao voltar da musica do mini-boss, retomar a track correta baseada no tempo decorrido.

**Boss final (Necromancer King):** Quando o boss final spawnar (minuto 25), trocar para `cemetery_boss`. Esta track toca ate o boss morrer ou o jogador morrer — nao retorna para outra track.

**Estimativa:** 20 min

---

### Task 5 — Gerar e adicionar arquivos de audio

Gerar as 5 faixas usando IA (Suno, Udio, ou similar) com os prompts acima.

Exportar como `.ogg` (Vorbis), qualidade 6-8, stereo.

Colocar em:
```
game/assets/audio/music/stages/cemetery_intro.ogg
game/assets/audio/music/stages/cemetery_horde.ogg
game/assets/audio/music/stages/cemetery_miniboss.ogg
game/assets/audio/music/stages/cemetery_climax.ogg
game/assets/audio/music/stages/cemetery_boss.ogg
```

**Estimativa:** 45 min (geracao + selecao + export)

---

### Task 6 — Crossfade mais longo para transicoes musicais

**Arquivo:** `scripts/autoload/audio_manager.gd`

Adicionar parametro opcional de duracao no `play_music()`:

```gdscript
func play_music(stream_name: String, fade_duration: float = 1.0) -> void:
```

Transicoes de fase devem usar `fade_duration = 3.0` para suavizar a mudanca.

**Estimativa:** 10 min

---

## Estrutura de Arquivos

```
game/assets/audio/music/stages/
├── cemetery_intro.ogg      # 0-10 min, 120-130 BPM, gotico misterioso
├── cemetery_horde.ogg      # 10-20 min, 150-160 BPM, acao intensa
├── cemetery_miniboss.ogg   # Mini-boss, 90-100 BPM, pesado intimidador
├── cemetery_climax.ogg     # 20-25 min, 170-180 BPM, caos total
└── cemetery_boss.ogg       # Boss final, 160-170 BPM, epico gotico
```

## Timeline Musical Completa

```
 0:00 ──── cemetery_intro (misterioso, 120-130 BPM)
            │
10:00 ──── cemetery_horde (intenso, 150-160 BPM)
            │
            ├── [Mini-boss spawna] → cemetery_miniboss (pesado, 90-100 BPM)
            │   └── [Mini-boss morre] → volta pra track do tempo atual
            │
20:00 ──── cemetery_climax (frenetico, 170-180 BPM)
            │
25:00 ──── cemetery_boss / Necromancer King (epico, 160-170 BPM)
            └── Toca ate o fim da fase
```

## Criterios de Aceitacao

- [ ] As 5 tracks tocam nos momentos corretos durante a fase cemiterio
- [ ] Crossfade suave (3s) entre transicoes de musica
- [ ] Mini-boss override funciona e retorna a track correta ao morrer
- [ ] Boss final override funciona e toca ate o fim
- [ ] Sem crash se arquivos de audio nao existirem (fallback graceful)
- [ ] Tracks fazem loop seamless (sem click/pop na transicao)
- [ ] Funciona em multiplayer (host controla a musica)
- [ ] Escalada de BPM perceptivel (120 → 150 → 170 → 160)

## Ordem de Execucao

1. Task 1 (registrar tracks) — pre-requisito pra tudo
2. Task 6 (crossfade parametrizavel) — melhora a experiencia
3. Task 2 (sistema dinamico no BaseStage) — infraestrutura
4. Task 3 (configurar cemetery) — usa a infraestrutura
5. Task 4 (trigger mini-boss) — depende do sistema dinamico
6. Task 5 (gerar audio) — pode ser feito em paralelo com 2-4

## Notas

- Este sistema de musica dinamica fica generico no `BaseStage`, permitindo que outras fases usem o mesmo padrao no futuro
- A track `cemetery_boss` substitui a track `boss` generica para o Necromancer King — mais tematica e epica
- Se nenhum arquivo `.ogg` existir, o jogo continua sem crash (comportamento atual do AudioManager)
- A escalada de BPM (120 → 150 → 170) cria uma sensacao natural de urgencia crescente
- O boss final tem BPM ligeiramente menor (160) que o climax (170) porque o foco muda de "caos" pra "epico"
