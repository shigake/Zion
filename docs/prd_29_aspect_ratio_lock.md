# PRD 29 — Trava de Aspect Ratio 16:9 e Controle de Janela

**Status**: pendente  
**Prioridade**: alta  
**Categoria**: qualidade visual / UX

---

## Problema

O `project.godot` usa `window/stretch/aspect = "expand"`, o que faz o mecanismo de stretch do Godot esticar o conteúdo 2D (UI) para preencher todo o espaço disponível da janela. Quando o jogador redimensiona a janela de forma assimétrica (ex: apenas na horizontal), o resultado é:

1. **UI distorcida** — elementos do HUD, menus e textos ficam achatados ou esticados
2. **Viewport 3D sem letterboxing** — a câmera exibe mais ou menos conteúdo na horizontal sem compensação, quebrando a intenção artística da fenda
3. **FOV implicitamente variável** — sem `keep_aspect = KEEP_HEIGHT` na `Camera3D`, o FOV vertical muda conforme o aspect ratio da janela

### Configuração atual (problemática)
```ini
# project.godot
window/stretch/mode = "canvas_items"
window/stretch/aspect = "expand"   # ← distorce ao redimensionar assimetricamente
```

```gdscript
# camera_follow.gd — sem keep_aspect definido explicitamente
extends Camera3D
```

---

## Solução

### 1. `project.godot` — mudar `aspect` para `keep`

| Chave | Antes | Depois |
|---|---|---|
| `window/stretch/aspect` | `"expand"` | `"keep"` |

Com `keep`, o Godot mantém o aspect ratio 16:9 e adiciona **letterboxing** (barras pretas) nas bordas quando a janela não for 16:9. Isso é o comportamento padrão Steam/consoles.

`stretch/mode = "canvas_items"` permanece — garante UI nítida em qualquer resolução.

### 2. `camera_follow.gd` — definir `keep_aspect = KEEP_HEIGHT`

```gdscript
func _ready() -> void:
    keep_aspect = Camera3D.KEEP_HEIGHT  # mantém FOV vertical fixo
```

Com `KEEP_HEIGHT`, em telas mais largas que 16:9 (ultrawide) a câmera mostra mais conteúdo horizontal mas mantém o FOV vertical — comportamento desejado para top-down.

### 3. Sem novo autoload necessário

O sistema de vídeo já existe:
- **`options_screen.gd`**: dropdowns de modo de janela (windowed/fullscreen/borderless) e resolução
- **`save_manager.gd`**: restaura `video_window_mode`, `video_resolution`, `video_vsync`, `video_fps_limit`
- **`GameConstants.RESOLUTIONS`**: lista de resoluções 16:9 (854×480 até 3840×2160)

Não é necessário criar um `VideoSettingsManager` — o pipeline já está completo.

---

## Resoluções suportadas (todas 16:9)

| Label | Resolução |
|---|---|
| 480p | 854 × 480 |
| 576p | 1024 × 576 |
| 720p | 1280 × 720 |
| 768p | 1366 × 768 |
| 900p | 1600 × 900 |
| 1080p | 1920 × 1080 |
| 1440p | 2560 × 1440 |
| 4K | 3840 × 2160 |

---

## O que NÃO muda

- Lógica de resolução em `options_screen.gd` — já funciona corretamente
- Sistema de save/restore de configurações de vídeo
- Modos de janela (windowed, fullscreen, borderless)
- V-Sync e limite de FPS
- `stretch/mode = "canvas_items"` — garante UI nítida

---

## Arquivos afetados

| Arquivo | Mudança |
|---|---|
| `game/project.godot` | `stretch/aspect`: `"expand"` → `"keep"` |
| `game/scripts/stages/camera_follow.gd` | `keep_aspect = Camera3D.KEEP_HEIGHT` em `_ready()` |

---

## Critérios de aceitação

- [ ] Redimensionar a janela apenas na horizontal adiciona barras pretas (letterboxing) — UI não distorce
- [ ] Redimensionar na vertical adiciona barras pretas (pillarboxing) — UI não distorce
- [ ] FOV vertical da câmera top-down permanece constante independente do aspect ratio da janela
- [ ] Tela cheia em 16:9 funciona sem barras pretas
- [ ] Tela cheia em 16:10 ou 4:3 exibe barras pretas nas laterais
- [ ] Todas as opções de vídeo continuam funcionando normalmente
