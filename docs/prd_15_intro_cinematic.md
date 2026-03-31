# PRD 15 — Cinematica de intro

## Contexto
O jogo precisa de uma cinematica de abertura que apresente o mundo, o conflito e o papel do jogador. Atualmente existe um `story_intro.gd` que mostra texto simples na primeira vez. A cinematica deve substituir ou preceder esse texto com uma apresentacao visual mais impactante.

## Estado atual
- `story_intro.gd` (168 linhas): mostra texto com typewriter, skipavel, flag `story_seen`
- Texto atual eh apenas narrativo, sem visual
- Tutorial overlay existe separado (`tutorial_overlay.gd`)

## Sistemas reutilizaveis
| Sistema | Arquivo | Reuso |
|---------|---------|-------|
| Story intro (typewriter, skip, flag) | `scripts/ui/story_intro.gd` | Base — expandir |
| Screen effects (flash, shake) | `scripts/effects/screen_effects.gd` | Efeitos |
| Loading screen (tips, lore) | `scripts/autoload/loading_screen.gd` | Padrao visual |
| Locale (10 idiomas) | `scripts/autoload/locale_manager.gd` | Textos |

## Arquivos a modificar
| Arquivo | Mudanca |
|---------|---------|
| `scripts/ui/story_intro.gd` | Expandir com 4 atos visuais |
| `scripts/autoload/locale_manager.gd` | Adicionar keys da intro (pt/en/es) |

## Plano de implementacao

### Estrutura da cinematica (~45 segundos, skipavel a qualquer momento)

**Ato 1 — Zion existia (0-10s)**
```
Fundo: Gradiente azul/roxo escuro, estrelas (pontos brancos)
Visual: Forma cristalina no centro (hexagono dourado, pulsa suavemente)
Texto: "Zion... o santuario entre mundos."
       "Um lugar onde realidades convergiam em harmonia."
Efeito: Glow suave no cristal, particulas flutuando
```

**Ato 2 — O estilhacamento (10-20s)**
```
Fundo: Vermelho/preto, rachaduras
Visual: Cristal se fragmenta (varios pedacos se afastam do centro)
Texto: "Algo antigo despertou. O Coracao de Zion se estilhacou."
       "Dez fendas rasgaram a realidade."
Efeito: Flash branco forte, screen shake, fragmentos voam pra fora
Audio: SFX de quebra/explosao
```

**Ato 3 — Os Fragmentados (20-35s)**
```
Fundo: Volta ao escuro, mas com brilhos
Visual: Silhueta de um personagem emerge de um estilhaco brilhante
Texto: "Voce carrega um estilhaco de Zion dentro de si."
       "Voce eh um Fragmentado."
       "Cada morte te rebobina. Cada retorno te fortalece."
Efeito: Silhueta pulsa com luz, fade in gradual
```

**Ato 4 — A missao (35-45s)**
```
Fundo: 10 portais (circulos coloridos) dispostos em arco
Visual: Dentro de cada portal, uma sombra (Sentinela)
Texto: "Dez Sentinelas corrompidos guardam as fendas."
       "Nao os mate. Liberte-os."
       "Restaure Zion."
Efeito: Portais pulsam, texto final em destaque dourado
Audio: Musica sobe de intensidade
```

**Fim — Transicao (45-47s)**
```
Fade to black
Flag: SaveManager.data["intro_seen"] = true
Transicao para main menu
```

### Passo 1 — Expandir story_intro.gd para suportar multiplos atos

Adicionar sistema de "slides" com transicoes:

```gdscript
var _slides: Array[Dictionary] = []
var _current_slide: int = 0

func _build_slides() -> void:
    _slides = [
        {
            "bg_color": Color(0.05, 0.05, 0.15),
            "text_key": "intro_act1_line1",
            "text_key2": "intro_act1_line2",
            "duration": 10.0,
            "visual": "crystal",  # tipo de visual a criar
        },
        {
            "bg_color": Color(0.2, 0.02, 0.02),
            "text_key": "intro_act2_line1",
            "text_key2": "intro_act2_line2",
            "duration": 10.0,
            "visual": "shatter",
            "effects": ["flash", "shake"],
        },
        # ... etc
    ]

func _play_slide(index: int) -> void:
    # Fade out slide anterior
    # Montar visual do slide
    # Typewriter no texto
    # Aguardar duracao
    # Proximo slide
    pass
```

### Passo 2 — Visuais por ato (todos 2D, leve)

**Ato 1 — Cristal pulsante:**
```gdscript
# Hexagono dourado no centro usando ColorRect ou Polygon2D
var crystal = Polygon2D.new()
crystal.polygon = PackedVector2Array([...])  # Forma hexagonal
crystal.color = Color(1.0, 0.85, 0.2, 0.8)
# Tween de scale pulsante
var tw = create_tween().set_loops()
tw.tween_property(crystal, "scale", Vector2(1.05, 1.05), 1.0)
tw.tween_property(crystal, "scale", Vector2(0.95, 0.95), 1.0)
```

**Ato 2 — Fragmentacao:**
```gdscript
# 10 pedacos do hexagono voam pra fora
for i in range(10):
    var shard = ColorRect.new()
    shard.size = Vector2(8, 12)
    shard.color = Color(1.0, 0.85, 0.2)
    shard.position = center
    var angle = float(i) / 10.0 * TAU
    var target = center + Vector2(cos(angle), sin(angle)) * 400
    var tw = create_tween()
    tw.tween_property(shard, "position", target, 0.8).set_trans(Tween.TRANS_EXPO)
    tw.parallel().tween_property(shard, "modulate:a", 0.0, 1.2)
```

**Ato 3 — Silhueta do Fragmentado:**
```gdscript
# Sprite generico (ronin como default) com glow
var sprite = TextureRect.new()
sprite.texture = load("res://assets/sprites/characters/ronin.png")
sprite.modulate = Color(0.5, 0.8, 1.2, 0.0)  # Azul brilhante
var tw = create_tween()
tw.tween_property(sprite, "modulate:a", 1.0, 1.5)
```

**Ato 4 — 10 portais:**
```gdscript
# 10 circulos coloridos (1 por fenda) em arco
var stage_colors = {
    "cemetery": Color(0.4, 0.5, 0.3),
    "forest": Color(0.2, 0.6, 0.2),
    "tokyo": Color(0.9, 0.2, 0.3),
    # ...
}
for i in range(10):
    var portal = ColorRect.new()  # Ou CircleShape visual
    portal.size = Vector2(40, 40)
    portal.color = stage_colors.values()[i]
    # Posicionar em arco
```

### Passo 3 — Adicionar textos ao LocaleManager
```gdscript
"intro_act1_line1": {
    "pt": "Zion... o santuario entre mundos.",
    "en": "Zion... the sanctuary between worlds.",
    "es": "Zion... el santuario entre mundos.",
},
"intro_act1_line2": {
    "pt": "Um lugar onde realidades convergiam em harmonia.",
    "en": "A place where realities converged in harmony.",
    "es": "Un lugar donde las realidades convergian en armonia.",
},
"intro_act2_line1": {
    "pt": "Algo antigo despertou. O Coracao de Zion se estilhacou.",
    "en": "Something ancient awakened. The Heart of Zion shattered.",
    "es": "Algo antiguo desperto. El Corazon de Zion se hizo pedazos.",
},
"intro_act2_line2": {
    "pt": "Dez fendas rasgaram a realidade.",
    "en": "Ten rifts tore through reality.",
    "es": "Diez grietas desgarraron la realidad.",
},
"intro_act3_line1": {
    "pt": "Voce carrega um estilhaco de Zion dentro de si.",
    "en": "You carry a shard of Zion within you.",
    "es": "Llevas un fragmento de Zion dentro de ti.",
},
"intro_act3_line2": {
    "pt": "Voce eh um Fragmentado.\nCada morte te rebobina. Cada retorno te fortalece.",
    "en": "You are a Fragmented.\nEach death rewinds you. Each return strengthens you.",
    "es": "Eres un Fragmentado.\nCada muerte te rebobina. Cada regreso te fortalece.",
},
"intro_act4_line1": {
    "pt": "Dez Sentinelas corrompidos guardam as fendas.",
    "en": "Ten corrupted Sentinels guard the rifts.",
    "es": "Diez Centinelas corruptos custodian las grietas.",
},
"intro_act4_line2": {
    "pt": "Nao os mate. Liberte-os.\nRestaure Zion.",
    "en": "Don't kill them. Free them.\nRestore Zion.",
    "es": "No los mates. Liberalos.\nRestaura Zion.",
},
```

### Passo 4 — Audio
- Ato 1: musica ambient suave (usar musica do menu ou criar)
- Ato 2: SFX "boss_roar" ou explosao, musica para
- Ato 3: musica volta, mais intensa
- Ato 4: musica climax, fade out no final

### Passo 5 — Flag e fluxo
```gdscript
# No main_menu.gd ou onde a intro eh chamada:
if not SaveManager.data.get("intro_seen", false):
    var intro = preload("res://scenes/ui/intro_cinematic.tscn").instantiate()
    add_child(intro)
    await intro.intro_finished
    # Intro seta SaveManager.data["intro_seen"] = true
```

Substituir o flag antigo `story_seen` por `intro_seen`, ou manter ambos se quiser que o story_intro continue como fallback.

## Validacao
- [ ] Cinematica toca na primeira vez que abre o jogo
- [ ] 4 atos com transicoes visuais
- [ ] Typewriter nos textos
- [ ] Efeitos visuais por ato (cristal, fragmentacao, silhueta, portais)
- [ ] Flash + shake no ato 2
- [ ] Skipavel a qualquer momento com input
- [ ] Nao toca novamente (flag intro_seen)
- [ ] Traduzida em pt/en/es
- [ ] Transicao suave para main menu ao terminar
- [ ] Funciona em 1280x720 sem scroll
- [ ] Performance ok (sem particulas GPU, apenas tweens 2D)
