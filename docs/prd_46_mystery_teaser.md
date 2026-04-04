# PRD 46 — Teaser visual do Fragmentado ???

**Status:** concluido  
**Prioridade:** média  
**Escopo:** `character_select.gd`, `game_constants.gd`  
**Tipo:** UX / retenção / narrativa  

---

## Problema

Na tela de seleção de personagem, os personagens bloqueados (`mystery` e `fragmentado`) aparecem exatamente iguais a qualquer outro personagem bloqueado: sprite escurecido (modulate `0.2, 0.2, 0.25`) com um ícone de cadeado 🔒.

Isso é um **desperdício narrativo e de retenção**. O personagem `mystery` (`???`) e o `fragmentado` são os dois personagens secretos do jogo — os mais raros, os mais difíceis de desbloquear. Eles deveriam **gritar mistério** na tela, não sussurrá-lo discretamente.

Um jogador novo olha para a grade de 15 personagens e não tem razão para se perguntar o que está bloqueado — tudo parece igualmente inacessível. Com um efeito visual distinto nos slots secretos, o jogo comunica imediatamente: "isso aqui é *diferente*, tem algo especial esperando por você".

---

## Objetivo

Dar ao slot do `mystery` (e opcionalmente `fragmentado`) um efeito visual único que:

1. **Silhueta pulsante** — em vez do sprite escurecido padrão, mostrar apenas a silhueta do personagem (sprite totalmente preto, sem detalhes) com um contorno pulsante
2. **Glitch periódico** — a cada 2–4s, o sprite treme e exibe um fragmento do sprite real por 2–3 frames antes de voltar a se esconder (como se o personagem "escapasse" brevemente da névoa)
3. **Partículas de fragmento** — pequenas partículas roxas/cíclicas caem sobre o tile, reforçando a identidade cristalina de Zion
4. **Nome "???" animado** — o label pisca entre "???" e um caractere aleatório, reforçando a identidade enigmática

Tudo implementado **sem nós extras pesados** — apenas Tweens e código procedural dentro do tile existente.

---

## Causa raiz

### O código atual trata todos os personagens bloqueados igualmente

Em `_build_character_grid()` (linha 192), a lógica de bloqueio é binária:

```gdscript
var is_locked := not SaveManager.is_character_unlocked(char_id)
# ...
if is_locked:
    tex.modulate = Color(0.2, 0.2, 0.25)  # Mesmo escurecimento para todos
if is_locked:
    # Mesmo lock icon para todos
    lock_icon.text = "🔒"
```

Não há distinção entre "personagem comum bloqueado" e "personagem secreto bloqueado". A identidade dos personagens `mystery` e `fragmentado` — seus nomes (`???` e `Fragmentado`), suas cores de CharacterDB (`gray` e `cyan`) — é completamente apagada.

### Nenhum mecanismo de animação contínua nos tiles

A tela de seleção de personagem é construída em `_ready()` via `_build_ui()` e não tem `_process()` ou Tweens contínuos nos tiles. Adicionar comportamento animado requer introduzir Tweens com loop nos tiles especiais.

---

## Definição dos "personagens teaser"

Para este PRD, "personagem teaser" é qualquer personagem onde:
```gdscript
var is_teaser := is_locked and char_id in ["mystery", "fragmentado"]
```

A lógica de teaser é **adicional** à lógica de bloqueio normal — se um teaser for desbloqueado, ele se comporta normalmente. Se estiver bloqueado, recebe o tratamento especial.

---

## Solução

### 1. Silhueta em vez de sprite escurecido

Para personagens teaser, em vez de:
```gdscript
tex.modulate = Color(0.2, 0.2, 0.25)
```

Usar:
```gdscript
tex.modulate = Color(0, 0, 0, 0.85)  # Totalmente preto (silhueta)
```

Isso funciona porque a textura do sprite já tem alpha correto — `Color(0,0,0,0.85)` multiplica todos os canais RGB por zero, resultando em uma silhueta preta com o shape exato do personagem. Contraste com o fundo escuro do tile garante que a silhueta seja visível.

Adicionalmente, um `ColorRect` de contorno pulsante é adicionado ao fundo do tile:

```gdscript
if is_teaser:
    var glow := ColorRect.new()
    glow.name = "TeaserGlow"
    glow.set_anchors_preset(Control.PRESET_FULL_RECT)
    glow.color = Color(GameConstants.TEASER_GLOW_COLOR, 0.0)
    glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    btn.add_child(glow)
    btn.move_child(glow, 0)  # Atrás do sprite
    
    var pulse := create_tween()
    pulse.set_loops()
    pulse.tween_property(glow, "color:a", GameConstants.TEASER_GLOW_MAX_ALPHA, GameConstants.TEASER_PULSE_IN)
    pulse.tween_property(glow, "color:a", 0.0, GameConstants.TEASER_PULSE_OUT)
```

### 2. Glitch periódico — fragmento do sprite real

O glitch mostra o sprite real por 2–3 frames a cada 2–4s. Isso é implementado como um Tween com delay aleatório em loop:

```gdscript
func _start_teaser_glitch(sprite: TextureRect, char_id: String) -> void:
    var glitch_tween := create_tween()
    glitch_tween.set_loops()
    
    # Espera tempo aleatório entre glitches
    var wait_time := randf_range(GameConstants.TEASER_GLITCH_MIN_WAIT, GameConstants.TEASER_GLITCH_MAX_WAIT)
    glitch_tween.tween_interval(wait_time)
    
    # Revela o sprite real brevemente
    glitch_tween.tween_callback(func():
        # Deslocamento aleatório (tremor)
        var offset_x := randf_range(-3.0, 3.0)
        var offset_y := randf_range(-2.0, 2.0)
        sprite.position.x += offset_x
        sprite.position.y += offset_y
        # Mostra o sprite real por 2-3 frames
        sprite.modulate = Color(1, 1, 1, 0.6)  # Semi-transparente, não revela tudo
    )
    
    # Dura 2 frames (~33ms a 60fps)
    glitch_tween.tween_interval(GameConstants.TEASER_GLITCH_DURATION)
    
    # Volta à silhueta
    glitch_tween.tween_callback(func():
        sprite.modulate = Color(0, 0, 0, 0.85)
        sprite.position.x -= offset_x  # Nota: capturado no closure
        sprite.position.y -= offset_y
    )
```

**Nota de implementação:** o `offset_x/y` precisa ser capturado no closure corretamente — usar variáveis locais antes do lambda.

### 3. Label "???" com glitch de caractere

Para o personagem `mystery`, o label "???" pisca brevemente para um caractere aleatório durante o glitch:

```gdscript
# Executado junto com o glitch visual
var glitch_chars := ["▓", "░", "█", "◈", "⬡", "⟐"]
name_lbl.text = glitch_chars[randi() % glitch_chars.size()]
# ... após TEASER_GLITCH_DURATION frames ...
name_lbl.text = "???"
```

Para o `fragmentado`, o label exibe o nome real em vez de glitch — já que o misterio não é o nome, mas sim os stats.

### 4. Remoção do lock icon padrão para teasers

Para personagens teaser, o ícone de cadeado 🔒 é substituído por um ícone de fragmento cristalino:

```gdscript
if is_teaser:
    lock_icon.text = "◈"   # Cristal de Zion
    lock_icon.add_theme_color_override("font_color", Color(0.5, 0.3, 0.8, 0.7))  # Roxo cristalino
else:
    lock_icon.text = "🔒"
```

### 5. Painel de info para teasers

Quando o jogador seleciona um tile teaser (mesmo bloqueado), o painel inferior exibe informações especiais em vez da mensagem de desbloqueio genérica:

**Para `mystery`:**
```
Nome: ???
Passiva: [dados corrompidos]
Condição: Desperte todos os outros Fragmentados
```

**Para `fragmentado`:**
```
Nome: Fragmentado
Passiva: [dados corrompidos]  
Condição: Sele todas as 10 fendas dimensionais
```

A frase "[dados corrompidos]" em vez de exibir a passiva real aumenta o mistério. A condição de desbloqueio é mostrada normalmente — o jogador sabe *o que fazer*, mas não sabe *o que vai ganhar*.

Isso já ocorre parcialmente no código atual (linha ~550), mas o texto da passiva exibe o valor real. Para teasers, substituir a passiva por "[dados corrompidos]":

```gdscript
if is_teaser and is_locked:
    _passive_label.text = "[dados corrompidos]"
    _passive_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.55))
```

### 6. Constantes em `game_constants.gd`

```gdscript
# --- Mystery Teaser ---
const TEASER_GLOW_COLOR := Color(0.35, 0.15, 0.6)       # Roxo cristal de Zion
const TEASER_GLOW_MAX_ALPHA := 0.18                      # Brilho máximo do pulso (sutil)
const TEASER_PULSE_IN := 1.2                             # Segundos para atingir máximo
const TEASER_PULSE_OUT := 1.8                            # Segundos para voltar a 0
const TEASER_GLITCH_MIN_WAIT := 2.0                      # Mínimo entre glitches (s)
const TEASER_GLITCH_MAX_WAIT := 5.0                      # Máximo entre glitches (s)
const TEASER_GLITCH_DURATION := 0.05                     # Duração do glitch (~3 frames)
```

---

## Comportamento por estado

| Estado | `mystery` | `fragmentado` |
|---|---|---|
| **Bloqueado** | Silhueta preta + pulso roxo + glitch + ◈ + "???" glitchando | Silhueta preta + pulso roxo + glitch + ◈ |
| **Desbloqueado** | Sprite normal, sem nenhum efeito especial | Sprite normal com borda cyan (cor da CharacterDB) |
| **Selecionado (bloqueado)** | Info panel: nome "???", passiva "[dados corrompidos]", condição real | Info panel: nome "Fragmentado", passiva "[dados corrompidos]", condição real |

---

## Narrativa

O efeito de glitch é narrativamente coerente com o universo de Zion. O `mystery` é um Fragmentado cujos dados foram **corrompidos** quando o Coração de Zion estilhaçou — a memória de quem ele é sobrevive apenas em fragmentos instáveis. O glitch visual é literalmente o personagem tentando se manifestar através da névoa de corrupção.

O `fragmentado` é o personagem que carrega mais estilhaços do cristal dentro de si — sua presença distorce a realidade ao redor. O pulso roxo e a silhueta tremula refletem essa instabilidade dimensional.

---

## Performance

| Aspecto | Impacto |
|---|---|
| Tweens ativos | +2 por personagem teaser bloqueado (pulse + glitch) → máximo +4 tweens na tela |
| ColorRect extra | +1 por teaser → máximo +2 nós extras na grade |
| `_process()` | Nenhum — tudo baseado em Tween, sem polling por frame |
| Memória | Negligível — 4 Tweens + 2 ColorRects |

A tela de seleção não é uma tela crítica de performance (sem gameplay acontecendo). O impacto é indetectável.

---

## Arquivos afetados

| Arquivo | Mudança |
|---|---|
| `game/scripts/ui/character_select.gd` | Modificar `_build_character_grid()`, adicionar `_start_teaser_glitch()`, modificar `_update_selection()` |
| `game/scripts/autoload/game_constants.gd` | +7 constantes (seção MYSTERY TEASER) |

**Fora do escopo:**
- Sprites novos — o efeito usa o sprite existente com manipulação de modulate
- Cenas `.tscn` — nenhuma alteração
- Lógica de desbloqueio — nenhuma alteração (condições permanecem iguais)
- Outros menus (hub, loading) — nenhuma alteração

---

## Critérios de aceitação

- [ ] Personagem `mystery` bloqueado exibe silhueta preta (não sprite escurecido cinza)
- [ ] Pulso roxo sutil visível no fundo do tile a cada ~3s
- [ ] Glitch ocorre entre 2–5s de intervalo, dura menos de 0.1s
- [ ] Durante glitch: sprite tremeu, exibiu semi-transparência do sprite real, voltou a silhueta
- [ ] Label "???" pisca para caractere aleatório durante glitch e volta
- [ ] Ícone ◈ aparece no lugar do 🔒 para teasers
- [ ] Painel info exibe "[dados corrompidos]" no lugar da passiva real
- [ ] Personagem desbloqueado: nenhum efeito de teaser — comportamento 100% normal
- [ ] Nenhum Tween vivo após o personagem ser desbloqueado mid-session
- [ ] Com `reduced_motion` ativo: pulso removido, glitch removido, silhueta estática permanece
