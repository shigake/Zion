# PRD 14 — Cutscene do ??? (Zion desperta)

## Contexto narrativo
Quando o jogador desbloqueia todos os 13 personagens, o personagem misterioso "???" eh revelado. Isso simboliza que Zion — o santuario entre dimensoes — ganhou consciencia propria atraves do esforco coletivo dos Fragmentados. Os cristais coletados em cada run sao fragmentos de Zion se reunindo.

**Frase central:** "Voces nao me reconstruiram. Voces me reinventaram."

## Trigger
- `SaveManager.check_unlocks()` retorna `"mystery"` na lista de personagens desbloqueados
- Detectado em `game_over_screen.gd` linhas 207-213
- Atualmente so mostra texto: `LocaleManager.tr_key("lore_mystery_unlock")`
- **Precisa**: mostrar cutscene visual ANTES do texto

## Sistemas existentes reutilizaveis
| Sistema | Arquivo | Reuso |
|---------|---------|-------|
| Story intro (typewriter, fade, skip) | `scripts/ui/story_intro.gd` | 90% — copiar como base |
| Boss dialogue (styling, borders) | `scripts/ui/boss_dialogue.gd` | Estilo visual |
| Screen effects (flash, shake, slow-mo) | `scripts/effects/screen_effects.gd` | Efeitos dramaticos |
| Locale (10 idiomas) | `scripts/autoload/locale_manager.gd` | Textos traduzidos |

## Arquivos a criar
| Arquivo | Funcao |
|---------|--------|
| `scripts/ui/mystery_cutscene.gd` | Script da cutscene |
| `scenes/ui/mystery_cutscene.tscn` | Cena (CanvasLayer simples) |

## Arquivos a modificar
| Arquivo | Mudanca |
|---------|---------|
| `scripts/ui/game_over_screen.gd` | Chamar cutscene quando mystery eh desbloqueado |
| `scripts/autoload/locale_manager.gd` | Adicionar keys da cutscene (pt/en/es) |

## Plano de implementacao

### Passo 1 — Criar script da cutscene (mystery_cutscene.gd)
Baseado em `story_intro.gd`. CanvasLayer com layer alto (110+).

**Estrutura da cutscene (~15 segundos, skipavel):**

```
0.0s  — Fade in: tela escura
0.5s  — Texto: "Todos os estilhacos ressoam juntos..."
       (typewriter, cor dourada)

3.0s  — Fade pra preto breve
3.5s  — 13 icones dos personagens aparecem em circulo
       (Sprite2D ou TextureRect, fade in staggered)

5.5s  — Cristais sobem do centro
       (particulas douradas subindo com tween, ou ColorRects animados)

7.0s  — Flash branco forte (ScreenEffects.flash)
7.2s  — Screen shake medio
7.5s  — Silhueta brilhante no centro (sprite ou forma geometrica com glow)

8.5s  — Texto principal com typewriter:
       "Voces nao me reconstruiram. Voces me reinventaram."
       (fonte grande, cor branca/dourada, outline preta)

12.0s — Hold por 2 segundos

14.0s — Fade out para preto
15.0s — Emitir signal "cutscene_finished"
```

**Implementacao tecnica:**
```gdscript
extends CanvasLayer

signal cutscene_finished

func _ready() -> void:
    layer = 110
    process_mode = Node.PROCESS_MODE_ALWAYS
    _play_cutscene()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey or event is InputEventJoypadButton:
        _skip()

func _play_cutscene() -> void:
    # Sequencia de tweens encadeados
    # Usar create_tween() para cada fase
    # Carregar sprites dos personagens de assets/sprites/characters/
    # Particulas: usar MeshInstance2D ou ColorRect animados (leve)
    pass

func _skip() -> void:
    cutscene_finished.emit()
    queue_free()
```

### Passo 2 — Sprites dos 13 personagens em circulo
Carregar sprites existentes de `assets/sprites/characters/`:
```gdscript
var char_ids = ["ronin", "soldado", "mago", "berserker", "ninja",
    "necro", "pirata", "engenheiro", "vampiro", "gladiador",
    "chef", "amazona", "bruxa"]
for i in range(13):
    var angle = float(i) / 13.0 * TAU
    var pos = center + Vector2(cos(angle), sin(angle)) * radius
    var tex_rect = TextureRect.new()
    tex_rect.texture = load("res://assets/sprites/characters/%s.png" % char_ids[i])
    tex_rect.position = pos
    tex_rect.modulate.a = 0.0  # Fade in com tween
```

### Passo 3 — Efeito de cristais convergindo
Simples: 8-12 quadrados dourados pequenos que sobem de posicoes aleatorias ate o centro:
```gdscript
for i in range(10):
    var crystal = ColorRect.new()
    crystal.size = Vector2(6, 6)
    crystal.color = Color(1.0, 0.85, 0.2, 0.8)
    crystal.position = random_position_on_circle
    var tw = create_tween()
    tw.tween_property(crystal, "position", center, 1.5)
    tw.parallel().tween_property(crystal, "modulate:a", 0.0, 1.5)
```

### Passo 4 — Silhueta do ???
Sprite do personagem mystery (`assets/sprites/characters/mystery.png`) com modulate branco brilhante + scale animation:
```gdscript
var mystery_sprite = TextureRect.new()
mystery_sprite.texture = load("res://assets/sprites/characters/mystery.png")
mystery_sprite.modulate = Color(1.5, 1.5, 1.5, 0.0)  # Brilho alto
# Scale de 0.5 → 1.0 com bounce
var tw = create_tween()
tw.tween_property(mystery_sprite, "modulate:a", 1.0, 0.5)
tw.parallel().tween_property(mystery_sprite, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
```

### Passo 5 — Integrar no game_over_screen.gd
Quando `_unlocked_chars` contem `"mystery"`:
```gdscript
if "mystery" in _unlocked_chars:
    var cutscene = preload("res://scenes/ui/mystery_cutscene.tscn").instantiate()
    add_child(cutscene)
    await cutscene.cutscene_finished
    # Depois mostra o texto normal do lore_mystery_unlock
```

### Passo 6 — Adicionar textos ao LocaleManager
```gdscript
"cutscene_mystery_1": {
    "pt": "Todos os estilhacos ressoam juntos...",
    "en": "All shards resonate together...",
    "es": "Todos los fragmentos resuenan juntos...",
},
"cutscene_mystery_2": {
    "pt": "Voces nao me reconstruiram. Voces me reinventaram.",
    "en": "You didn't rebuild me. You reinvented me.",
    "es": "No me reconstruyeron. Me reinventaron.",
},
```

### Passo 7 — Audio
- Tocar SFX "achievement" no flash branco
- Musica: usar a musica de vitoria ou criar um SFX especifico de "awakening"
- Cristais subindo: SFX "collect_crystal" em loop suave

## Validacao
- [ ] Cutscene toca quando mystery eh desbloqueado
- [ ] 13 personagens aparecem em circulo
- [ ] Cristais convergem ao centro
- [ ] Flash branco + shake
- [ ] Silhueta do ??? aparece
- [ ] Texto "Voces nao me reconstruiram..." com typewriter
- [ ] Skipavel com qualquer input
- [ ] Traduzido em pt/en/es
- [ ] Apos cutscene, tela de game over continua normal
- [ ] Nao toca novamente se ja foi vista (flag no SaveManager)
