# PRD — Gamepad UX: Navegação por Controle

> Correção de bugs e melhorias na navegação por controle (gamepad/joystick) nas telas de seleção de personagem, menu de opções e pause menu.

## Status: ⏳ Pendente

---

## Contexto

Ao jogar com controle (PS/Xbox), várias telas do jogo apresentam comportamentos incorretos: avanço de tela não intencional, foco inexistente em menus de opções e um erro de formatação de string na tela de seleção de personagem. Este PRD documenta todos os problemas identificados e define o comportamento correto esperado.

---

## Bug 1 — Seleção de personagem avança de tela ao primeiro toque em X

**Arquivo:** `game/scripts/ui/character_select.gd`

### Comportamento atual

No `_unhandled_input`, a ação `ui_accept` (botão X do PlayStation / A do Xbox) chama `_on_start()` diretamente (linha ~649). Isso faz com que, ao navegar no grid com o direcional e "confirmar" a seleção de um personagem, o jogo avance imediatamente para a próxima tela — sem dar ao jogador a chance de ler as informações do personagem.

O problema fica evidente com a **Amazona**: ao navegar até ela com o direcional e pressionar X para "selecionar", o jogo sai da tela de personagem imediatamente.

### Comportamento esperado

- **Primeira confirmação (X):** Seleciona o personagem e atualiza o painel de informações. Fica na tela.
- **Segunda confirmação (X) no mesmo personagem já selecionado:** Avança para a próxima tela (equivalente a clicar no botão "JOGAR").
- Pressionar X em um personagem diferente do atual apenas troca a seleção, sem avançar.

### Implementação sugerida

Em `character_select.gd`, adicionar uma variável `_confirmed_index: int = -1`. Na lógica de `ui_accept`:

```gdscript
elif event.is_action_pressed("ui_accept"):
    if current_index == _confirmed_index:
        # Segunda confirmação no mesmo personagem → jogar
        _on_start()
    else:
        # Primeira confirmação → apenas seleciona
        _confirmed_index = current_index
        _update_selection()
    get_viewport().set_input_as_handled()
```

Resetar `_confirmed_index = -1` sempre que o jogador navegar para outro personagem.

### Critérios de aceite

- [ ] Pressionar X uma vez em qualquer personagem apenas o seleciona (sem avançar de tela)
- [ ] Pressionar X duas vezes no mesmo personagem avança para seleção de fenda
- [ ] Navegar para outro personagem após a primeira confirmação reseta a lógica
- [ ] Teste com Amazona: navegar até ela + X não avança de tela imediatamente
- [ ] Botão "JOGAR" na tela continua funcionando normalmente com mouse/teclado

---

## Bug 2 — Foco não vai para "Opções" ao abrir pelo pause menu

**Arquivo:** `game/scripts/ui/pause_menu.gd`

### Comportamento atual

Ao pausar o jogo e clicar/pressionar "Opções", um `PanelContainer` dinâmico é criado em `_on_options()`. Os sliders e controles dentro desse painel **não recebem `focus_mode = FOCUS_ALL`** e não há nenhum nó com foco inicial definido. O resultado é que o controle não consegue interagir com nenhum elemento das opções do pause.

### Comportamento esperado

- Ao abrir as opções pelo pause, o foco deve ir automaticamente para o primeiro controle interativo (slider de volume master).
- Os sliders devem ser navegáveis com o direcional: cima/baixo para mudar de slider, esquerda/direita para ajustar o valor.
- O botão "Fechar" deve ser alcançável e funcional com o controle.
- Pressionar `ui_cancel` (botão O/B) fecha o painel de opções e retorna ao pause menu.

### Implementação sugerida

Em `_on_options()`, após criar o painel:

1. Iterar todos os `HSlider`, `CheckButton` e `OptionButton` criados e definir `focus_mode = Control.FOCUS_ALL`.
2. Conectar `focus_neighbor_top` e `focus_neighbor_bottom` entre os controles.
3. Após `add_child(options_panel)`, chamar `.grab_focus()` no primeiro slider.
4. No `_unhandled_input`, garantir que `ui_cancel` fecha o painel quando ele está aberto.

### Critérios de aceite

- [ ] Ao abrir opções pelo pause, o foco já está no primeiro slider
- [ ] D-pad cima/baixo navega entre os controles do painel
- [ ] D-pad esquerda/direita ajusta o valor do slider em foco
- [ ] Botão "Fechar" é alcançável e funcional com controle
- [ ] `ui_cancel` fecha o painel e volta ao pause menu
- [ ] O volume realmente muda ao ajustar com o controle

---

## Bug 3 — Tela de opções do menu principal não funciona com controle

**Arquivo:** `game/scripts/ui/options_screen.gd`

### Comportamento atual

A tela de opções completa (acessada pelo menu principal) tem 7 abas construídas dinamicamente. Embora `GamepadUI.notify_menu_opened()` seja chamado no `_ready()`, os controles dentro de cada aba (sliders, dropdowns, checkboxes) não têm `focus_mode` configurado, e não há um nó inicial de foco definido ao entrar na tela. O controle fica "perdido" e não consegue navegar pelos elementos.

### Comportamento esperado

- Ao entrar na tela de opções via menu principal, o foco começa no primeiro controle da aba ativa.
- L1/R1 já funciona para trocar de aba (há código para isso), mas os controles dentro das abas precisam ser acessíveis.
- D-pad cima/baixo navega entre as linhas de configuração da aba atual.
- D-pad esquerda/direita ajusta sliders ou muda seleção de dropdowns.
- `ui_cancel` ou o botão "Voltar" retorna ao menu principal.

### Implementação sugerida

Em `_make_tab_content()` e nos helpers `_add_slider`, `_add_toggle`, `_add_dropdown`: garantir `focus_mode = Control.FOCUS_ALL` nos nós interativos.

Após `_build_ui()`, no final do `_ready()`:

```gdscript
# Foco inicial no primeiro controle da primeira aba
call_deferred("_set_initial_focus")

func _set_initial_focus() -> void:
    # Encontra o primeiro controle focalizável na aba atual
    var tab_content = tab_container.get_current_tab_control()
    if tab_content:
        var focusable = _find_first_focusable(tab_content)
        if focusable:
            focusable.grab_focus()
```

### Critérios de aceite

- [ ] Ao entrar nas opções pelo menu principal, há um elemento em foco imediatamente
- [ ] D-pad cima/baixo navega entre as configurações da aba ativa
- [ ] Trocar de aba com L1/R1 move o foco para o primeiro controle da nova aba
- [ ] Sliders respondem ao D-pad esquerda/direita
- [ ] Dropdowns abrem com `ui_accept` e fecham com `ui_cancel`
- [ ] Botão "Voltar" é alcançável e funcional com controle

---

## Bug 4 — Erro de formatação de string na tela de seleção de personagem

**Arquivo:** `game/scripts/ui/character_select.gd`

### Comportamento atual

Ao ficar parado na tela de seleção de personagem sem interagir, o console exibe o erro:

```
not all arguments converted during string formatting in operator '%'
```

### Causa provável

O erro de `%` no GDScript ocorre quando se usa `"texto %s" % valor` mas o número de especificadores (`%s`, `%d`, etc.) não bate com o número de argumentos fornecidos. Exemplos suspeitos no código:

- Linha 233: `"res://assets/sprites/characters/%s.png" % char_id` — se `char_id` for vazio ou inválido
- Linha 546: `"🔒 %s" % data.get("unlock_description", "???")` — se o dado retornado for um Array em vez de String

O erro aparece periodicamente (não só ao interagir), sugerindo que algum processo em `_process` ou `_update_selection` está tentando formatar uma string com dado inválido.

### Comportamento esperado

Sem erros no console. A tela funciona normalmente para todos os 15 Fragmentados, incluindo os bloqueados.

### Implementação sugerida

Garantir que todos os usos de `%` na tela usem `str()` para converter o valor antes:

```gdscript
# Antes
"🔒 %s" % data.get("unlock_description", "???")

# Depois
"🔒 %s" % str(data.get("unlock_description", "???"))
```

Além disso, adicionar checagem de tipo antes de usar `%`:

```gdscript
var unlock_desc = data.get("unlock_description", "???")
if typeof(unlock_desc) != TYPE_STRING:
    unlock_desc = "???"
_lock_label.text = "🔒 %s" % unlock_desc
```

### Critérios de aceite

- [ ] Nenhum erro de `%` no console ao navegar pela tela de seleção
- [ ] Nenhum erro ao ficar parado por 30+ segundos na tela
- [ ] Todos os 15 Fragmentados (incluindo bloqueados) exibem informações corretamente

---

## Ordem de implementação recomendada

| Prioridade | Bug | Impacto |
|---|---|---|
| P0 | Bug 4 — erro de string `%` | Ruído no console, pode mascarar outros erros |
| P0 | Bug 1 — X avança de tela | Quebra usabilidade básica do controle |
| P1 | Bug 2 — opções no pause | Opções inacessíveis durante gameplay |
| P1 | Bug 3 — opções no menu principal | Opções inacessíveis no menu |

---

## Arquivos afetados

- `game/scripts/ui/character_select.gd`
- `game/scripts/ui/pause_menu.gd`
- `game/scripts/ui/options_screen.gd`

## Teste manual necessário

- Controle PS4/PS5 conectado via USB ou Bluetooth
- Navegar em todas as telas descritas sem usar mouse/teclado
- Verificar console para erros residuais
