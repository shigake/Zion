# PRD 21 — Loading screen: clique em qualquer lugar para iniciar

**Status:** CONCLUIDO  
**Prioridade:** alta (UX, primeira impressão do jogo)  
**Arquivo principal:** `game/scripts/autoload/loading_screen.gd`  
**Estimativa:** 30 min

---

## Problema

Após o carregamento terminar, o jogo exibe a mensagem:

> *"Clique ou pressione qualquer botão para iniciar"*

O jogador lê a instrução e tenta clicar — mas o clique do mouse só funciona **se o cursor estiver exatamente em cima da Label de texto**. Qualquer clique fora do texto não faz nada. Controle e teclado funcionam em qualquer lugar; o mouse não.

**Impacto:** quebra a primeira impressão do jogo. O jogador clica várias vezes no fundo escuro sem resposta e não entende por quê. A mensagem pede "clique em qualquer lugar" mas só aceita em um ponto específico.

---

## Causa raiz

O input de mouse é tratado em `_unhandled_input()`, que no Godot 4 só recebe eventos que **não foram consumidos pela GUI**. O problema está na árvore de nós do loading screen:

- `_root` tem `mouse_filter = MOUSE_FILTER_PASS` — correto, repassa o evento
- `_press_label` (Label) tem `mouse_filter = MOUSE_FILTER_PASS` por padrão de Label
- Porém, um `ColorRect`, `TextureRect` ou outro nó pai na hierarquia com `MOUSE_FILTER_STOP` está **consumindo o clique antes que ele chegue** ao `_unhandled_input()` — exceto quando o cursor está diretamente sobre a Label, que fica por cima na ordem de render

Em outras palavras: clicar no fundo escuro "acerta" um nó que engole o `InputEventMouseButton` sem repassá-lo. A Label fica sobreposta a esse nó, por isso clicar nela funciona.

---

## Solução

Adicionar um `Control` transparente **full-screen** com `MOUSE_FILTER_STOP` **por cima de toda a UI** assim que o estado "aguardando input" for ativado. Esse painel invisível:

1. Cobre a tela inteira (âncoras `PRESET_FULL_RECT`)
2. Recebe **qualquer** `gui_input` de mouse, em qualquer ponto da tela
3. Chama o mesmo handler de `_unhandled_input` (ou diretamente `_transition_to_scene()`)
4. É removido/ocultado após o input ser recebido

Isso garante que o clique do mouse seja capturado independente de qual nó esteja abaixo do cursor.

### Mudanças em `loading_screen.gd`

**1. Nova variável:**
```gdscript
var _click_catcher: Control  # painel full-screen que captura clique em qualquer ponto
```

**2. Criar o `_click_catcher` dentro de `_build_ui()`, como último filho de `_root`:**
```gdscript
_click_catcher = Control.new()
_click_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
_click_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
_click_catcher.visible = false
_click_catcher.gui_input.connect(_on_click_catcher_input)
_root.add_child(_click_catcher)
```
> Por ser o último filho, fica na frente de todos os outros nós — garante que captura o mouse antes de qualquer elemento de UI.

**3. Ativar junto com `_press_label` (função `_show_press_any_key()` ou equivalente, linha ~426):**
```gdscript
_waiting_for_input = true
if _press_label:
    _press_label.visible = true
if _click_catcher:
    _click_catcher.visible = true  # ativa captura full-screen
```

**4. Novo handler do painel:**
```gdscript
func _on_click_catcher_input(event: InputEvent) -> void:
    if not _waiting_for_input:
        return
    if event is InputEventMouseButton and event.pressed:
        _waiting_for_input = false
        if _click_catcher:
            _click_catcher.visible = false
        get_viewport().set_input_as_handled()
        _transition_to_scene()
```

**5. Desativar ao usar teclado/controle (no bloco existente de `_unhandled_input`, após `_waiting_for_input = false`):**
```gdscript
if _click_catcher:
    _click_catcher.visible = false
```

### O que NÃO muda
- `_unhandled_input()` continua funcionando para teclado e gamepad — sem alteração
- Todo o resto do loading screen (arte da fase, barra de progresso, lore, dicas, fade) — intacto
- O loading antes da jogatina — intacto
- A transição entre menus (PRD 18) — intacto

---

## Critérios de aceite

- [ ] Clicar em qualquer ponto da tela (fundo, centro, cantos) durante o estado "aguardando input" inicia a transição
- [ ] Pressionar qualquer tecla do teclado continua funcionando
- [ ] Pressionar qualquer botão do controle/gamepad continua funcionando
- [ ] Apenas **um** input é aceito (sem duplo disparo de `_transition_to_scene()`)
- [ ] O painel `_click_catcher` é invisível durante o carregamento — não interfere na interação antes de o loading terminar
- [ ] Teste: clicar no canto superior esquerdo → transição. Clicar no centro do fundo → transição. Pressionar Enter → transição.

---

## Arquivos modificados

| Arquivo | Mudança |
|---------|---------|
| `game/scripts/autoload/loading_screen.gd` | Adicionar `_click_catcher` (Control full-screen), ativar ao exibir prompt, handler `_on_click_catcher_input`, desativar após input |
