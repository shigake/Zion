# PRD — Gamepad Controls: Auditoria Completa de Controle

> Correção de todos os bugs de navegação e jogabilidade com controle (gamepad) em todas as telas do jogo.

## Status: 🟢 Concluído

---

## Contexto

A jogabilidade com controle está comprometida em múltiplas telas. O PRD anterior (`prd_gamepad_ux.md`) corrigiu 4 bugs iniciais (character select, pause options, main options, string format), mas uma auditoria completa revelou **15 bugs adicionais** espalhados pela loja, codex, bestiário, lobby, inventário, mutações e outros. Este PRD cobre TUDO que resta.

### Escopo

- 15 bugs identificados (P0 a P2)
- 12 arquivos afetados
- Foco em: focus_mode, focus_neighbors, grab_focus, input actions para gamepad

---

## Bug 1 — Loja: botões de compra não navegáveis com controle (P0)

**Arquivo:** `game/scripts/ui/shop.gd`

### Problema

Os botões de compra criados dinamicamente em `_build_shop()` (linha 79-88) não têm `focus_mode` definido. O `back_btn` também não tem focus_mode. Resultado: gamepad não consegue navegar entre upgrades nem comprar nada.

Após comprar um item, `_build_shop()` reconstrói toda a lista (linha 97), perdendo o foco.

### Fix

```gdscript
# Em _build_shop(), após criar cada btn (linha 89):
btn.focus_mode = Control.FOCUS_ALL

# Após o loop de criação, configurar focus_neighbors:
var buttons: Array[Button] = []
# ... coletar todos os botões criados ...
for i in range(buttons.size()):
    if i > 0:
        buttons[i].focus_neighbor_top = buttons[i - 1].get_path()
    if i < buttons.size() - 1:
        buttons[i].focus_neighbor_bottom = buttons[i + 1].get_path()
# Conectar último botão ao back_btn
back_btn.focus_mode = Control.FOCUS_ALL

# Em _build_shop(), após reconstruir, restaurar foco:
if GamepadUI.is_gamepad_mode and not buttons.is_empty():
    buttons[0].call_deferred("grab_focus")
```

### Critérios de aceite

- [ ] D-pad cima/baixo navega entre upgrades na loja
- [ ] Botão A/X compra o upgrade em foco
- [ ] Botão "Voltar" é alcançável com controle
- [ ] Após comprar, foco volta para o primeiro item
- [ ] ui_cancel volta ao menu principal

---

## Bug 2 — Codex: cards de armas não navegáveis com controle (P0)

**Arquivo:** `game/scripts/ui/codex_screen.gd`

### Problema

Os card_btn criados em `_populate_grid()` (linha 214-250) via `UICardBuilder.create_card()` não têm `focus_mode` configurado. Os cards só funcionam com mouse (`.pressed.connect()`). O grid de 4 colunas × N linhas não tem focus_neighbors configurados.

O `back_btn` tem `focus_mode = Control.FOCUS_ALL` (linha 187), mas é o ÚNICO elemento focável.

### Fix

```gdscript
# Em _populate_grid(), após criar card_btn:
card_btn.focus_mode = Control.FOCUS_ALL

# Após popular o grid, configurar focus_neighbors em grid 4 colunas:
var cards = grid.get_children()
for i in range(cards.size()):
    var card = cards[i]
    var col = i % COLUMNS
    var row = i / COLUMNS
    # Esquerda/direita
    if col > 0:
        card.focus_neighbor_left = cards[i - 1].get_path()
    if col < COLUMNS - 1 and i + 1 < cards.size():
        card.focus_neighbor_right = cards[i + 1].get_path()
    # Cima/baixo
    if row > 0:
        card.focus_neighbor_top = cards[i - COLUMNS].get_path()
    if i + COLUMNS < cards.size():
        card.focus_neighbor_bottom = cards[i + COLUMNS].get_path()

# Última linha → back_btn
# back_btn → primeira linha
```

### Critérios de aceite

- [ ] D-pad navega entre cards de armas no grid (4 colunas)
- [ ] Botão A/X seleciona um card e mostra detalhes no painel direito
- [ ] D-pad desce do grid para o botão Voltar
- [ ] ui_cancel volta ao menu principal
- [ ] ScrollContainer acompanha o card focado (scroll automático)

---

## Bug 3 — Bestiário: cards de monstros não navegáveis com controle (P0)

**Arquivo:** `game/scripts/ui/bestiary_screen.gd`

### Problema

Mesmo padrão do Codex. Os filter_btn têm `focus_mode = Control.FOCUS_ALL` (linha 351), e `back_btn` também (linha 512). Porém os cards de monstros no grid provavelmente NÃO têm focus_neighbors configurados, e a navegação entre filtros e grid não está conectada.

### Fix

Mesma abordagem do Codex: `focus_mode = FOCUS_ALL` em todos os cards, focus_neighbors no grid, conexão filtros ↔ grid ↔ back_btn.

### Critérios de aceite

- [ ] D-pad navega entre filtros de fenda no topo
- [ ] D-pad desce dos filtros para o grid de monstros
- [ ] Navegação no grid funciona em 4 colunas
- [ ] Botão A/X seleciona monstro e mostra detalhes
- [ ] ui_cancel volta ao menu principal

---

## Bug 4 — Lobby: pre-lobby sem focus chain (P1)

**Arquivo:** `game/scripts/ui/lobby_screen.gd`

### Problema

No pre-lobby (linhas 114-197), os botões `_host_btn`, `_join_btn`, `_ip_input`, `_password_input`, `scan_btn`, `_back_btn` são criados sem `focus_mode` e sem focus_neighbors. O gamepad não consegue:
- Navegar entre Host/Join
- Focar no campo de IP para digitar
- Clicar em Atualizar (scan LAN)
- Voltar ao menu

### Fix

```gdscript
# Todos os botões e inputs do pre-lobby:
_host_btn.focus_mode = Control.FOCUS_ALL
_join_btn.focus_mode = Control.FOCUS_ALL
_ip_input.focus_mode = Control.FOCUS_ALL
_password_input.focus_mode = Control.FOCUS_ALL
scan_btn.focus_mode = Control.FOCUS_ALL
_back_btn.focus_mode = Control.FOCUS_ALL

# Focus chain vertical:
# host_btn ↔ join_btn → ip_input → password_input → scan_btn → back_btn
```

### Critérios de aceite

- [ ] D-pad navega entre todos os elementos do pre-lobby
- [ ] Botão A/X ativa Host/Join/Scan/Voltar
- [ ] Campo de IP é focável e editável
- [ ] ui_cancel volta ao menu principal

---

## Bug 5 — Lobby: botão Enviar do chat com FOCUS_NONE (P1)

**Arquivo:** `game/scripts/ui/lobby_screen.gd`, linha 315

### Problema

```gdscript
send_btn.focus_mode = Control.FOCUS_NONE  # ← BUG
```

O botão "Enviar" do chat foi explicitamente configurado como não-focável. Jogadores com controle não conseguem enviar mensagens no chat do lobby.

### Fix

```gdscript
send_btn.focus_mode = Control.FOCUS_ALL
```

### Critérios de aceite

- [ ] Botão Enviar é alcançável com D-pad
- [ ] Botão A/X envia a mensagem do chat
- [ ] Focus chain: chat_input ↔ send_btn

---

## Bug 6 — Lobby: lobby panel sem focus em grids e botões (P1)

**Arquivo:** `game/scripts/ui/lobby_screen.gd`

### Problema

No lobby panel (3 colunas):
- `_char_grid` (linha 246-250): botões de personagem sem focus_mode/neighbors
- `_relic_option` (linha 265-267): OptionButton sem focus_mode
- `_stage_grid` (linha 337-341): botões de fenda sem focus_mode/neighbors
- `_ready_btn`, `_start_btn`, `_lobby_back_btn` (linhas 360-377): sem focus_mode
- `_chat_input` (linha 305-310): sem focus_mode

### Fix

Adicionar `focus_mode = Control.FOCUS_ALL` em todos os controles interativos. Configurar focus_neighbors entre colunas (L1/R1 ou D-pad horizontal).

### Critérios de aceite

- [ ] Navegação completa no lobby com controle
- [ ] Seleção de personagem, relíquia e fenda via gamepad
- [ ] Botão Pronto/Iniciar/Sair acessíveis
- [ ] Chat input focável

---

## Bug 7 — Inventário: sem botão gamepad para abrir (P0)

**Arquivo:** `game/scripts/ui/inventory_overlay.gd`

### Problema

O inventário é registrado apenas com tecla TAB (linhas 22-27):
```gdscript
var event = InputEventKey.new()
event.physical_keycode = KEY_TAB
InputMap.action_add_event("inventory", event)
```

Nenhum botão de gamepad é mapeado. Jogadores com controle simplesmente **não conseguem abrir o inventário** durante gameplay.

### Fix

```gdscript
func _register_inventory_action() -> void:
    if not InputMap.has_action("inventory"):
        InputMap.add_action("inventory")
    # Teclado
    var key_event = InputEventKey.new()
    key_event.physical_keycode = KEY_TAB
    InputMap.action_add_event("inventory", key_event)
    # Gamepad — botão Select/Back
    var joy_event = InputEventJoypadButton.new()
    joy_event.button_index = JOY_BUTTON_BACK  # Select/Back button
    InputMap.action_add_event("inventory", joy_event)
```

### Critérios de aceite

- [ ] Botão Select/Back do controle abre o inventário
- [ ] Inventário fecha com o mesmo botão ou ui_cancel
- [ ] Funciona durante gameplay sem conflito com pause

---

## Bug 8 — Inventário: sem foco interno ao abrir (P1)

**Arquivo:** `game/scripts/ui/inventory_overlay.gd`

### Problema

Ao abrir o inventário, nenhum controle recebe foco. O botão "X" de fechar (linha 122-126) não tem `focus_mode` configurado. Jogadores com controle veem o overlay mas não podem interagir.

### Fix

```gdscript
# Em _rebuild_content(), no close_btn:
close_btn.focus_mode = Control.FOCUS_ALL

# Em _open(), após _rebuild_content():
if GamepadUI.is_gamepad_mode:
    close_btn.call_deferred("grab_focus")
```

### Critérios de aceite

- [ ] Ao abrir inventário com controle, botão X recebe foco
- [ ] ui_cancel fecha o inventário

---

## Bug 9 — Mutações: checkboxes sem focus chain (P1)

**Arquivo:** `game/scripts/ui/mutations_panel.gd`

### Problema

Os checkboxes de mutação criados dinamicamente em `_create_card()` (linha 93-98) não têm `focus_mode` configurado. Os botões `back_button` e `confirm_button` (cena) provavelmente têm foco via .tscn, mas os checkboxes dentro dos cards não.

Resultado: controle não consegue ativar/desativar mutações.

### Fix

```gdscript
# Em _create_card():
checkbox.focus_mode = Control.FOCUS_ALL

# Após _build_mutation_cards(), configurar focus_neighbors entre checkboxes
# e conectar ao confirm/back buttons
```

### Critérios de aceite

- [ ] D-pad navega entre checkboxes de mutação
- [ ] Botão A/X ativa/desativa mutação
- [ ] D-pad desce para Confirmar/Voltar
- [ ] ui_cancel volta à seleção de personagem

---

## Bug 10 — Daily Challenge: botões sem focus chain (P1)

**Arquivo:** `game/scripts/ui/daily_challenge_screen.gd`

### Problema

Os botões `_play_btn` e `_back_btn` têm `focus_mode = Control.FOCUS_ALL` (linhas 142, 168), mas **não têm focus_neighbors** configurados entre si. Se houver outros botões ou o leaderboard tiver elementos interativos, a navegação pode pular diretamente entre eles de forma imprevisível.

### Fix

```gdscript
_play_btn.focus_neighbor_bottom = _back_btn.get_path()
_back_btn.focus_neighbor_top = _play_btn.get_path()
# Wrapping
_play_btn.focus_neighbor_top = _back_btn.get_path()
_back_btn.focus_neighbor_bottom = _play_btn.get_path()
```

### Critérios de aceite

- [ ] D-pad navega entre Jogar e Voltar
- [ ] Focus wrap: último elemento → primeiro
- [ ] ui_cancel volta ao menu principal

---

## Bug 11 — Leaderboard: tabs e botões sem focus chain completa (P1)

**Arquivo:** `game/scripts/ui/leaderboard_screen.gd`

### Problema

Tab buttons e refresh/back buttons têm `focus_mode = FOCUS_ALL` (linhas 209, 240, 249), mas provavelmente não têm focus_neighbors conectando tabs ↔ botões de ação. Não há como navegar entre a seção de tabs e os botões na parte inferior.

### Fix

Configurar focus_neighbors entre:
- Tab buttons (horizontal: esquerda/direita)
- Tab row ↔ refresh/back buttons (vertical: cima/baixo)

### Critérios de aceite

- [ ] D-pad esquerda/direita navega entre tabs de fendas
- [ ] D-pad baixo vai para Atualizar/Voltar
- [ ] ui_cancel volta ao menu principal

---

## Bug 12 — Achievements: cards não interativos com controle (P2)

**Arquivo:** `game/scripts/ui/achievements_screen.gd`

### Problema

Os cards de achievement são PanelContainers (não botões), então não são focáveis por natureza. O `back_btn` provavelmente tem focus_mode. Não é crítico porque os cards são apenas informativos, mas seria bom navegar o scroll com D-pad.

### Fix

Garantir que o ScrollContainer responde a D-pad para scroll vertical, e que `back_btn` tem focus e é alcançável.

### Critérios de aceite

- [ ] D-pad cima/baixo faz scroll na lista de achievements
- [ ] Botão Voltar é focável e funcional
- [ ] ui_cancel volta ao menu principal

---

## Bug 13 — KeybindingManager não aplica gamepad_button dos defaults (P1)

**Arquivo:** `game/scripts/autoload/keybinding_manager.gd`

### Problema

Os defaults definem `gamepad_button` para dash, interact, pause, level_up_reroll (linhas 8-21), mas `_apply_bindings()` (linhas 66-81) **só aplica InputEventKey**. Os gamepad_button definidos nos defaults nunca são registrados no InputMap.

Isso significa que se o `_apply_bindings()` rodar antes do GamepadUI registrar os botões, o gamepad perde funcionalidade. Ou pior: ao fazer rebind de teclado, o gamepad_button existente pode ser removido.

### Fix

```gdscript
func _apply_bindings() -> void:
    for action in bindings:
        if InputMap.has_action(action):
            var events = InputMap.action_get_events(action)
            for event in events:
                if event is InputEventKey:
                    InputMap.action_erase_event(action, event)
        else:
            InputMap.add_action(action)

        var bind = bindings[action]
        if "key" in bind:
            var event = InputEventKey.new()
            event.physical_keycode = bind["key"]
            InputMap.action_add_event(action, event)

        # NOVO: Aplica gamepad_button se definido
        if "gamepad_button" in bind:
            var joy_event = InputEventJoypadButton.new()
            joy_event.button_index = bind["gamepad_button"]
            # Só adiciona se não existir
            var exists = false
            for ev in InputMap.action_get_events(action):
                if ev is InputEventJoypadButton and ev.button_index == bind["gamepad_button"]:
                    exists = true
                    break
            if not exists:
                InputMap.action_add_event(action, joy_event)
```

### Critérios de aceite

- [ ] Dash funciona com botão A do gamepad após rebind de teclado
- [ ] Interact funciona com botão B
- [ ] Pause funciona com Start
- [ ] Reroll no level-up funciona com Y

---

## Bug 14 — Movimento: sem mapeamento de analog stick no InputMap (P0)

**Arquivo:** `game/scripts/autoload/keybinding_manager.gd`

### Problema

As ações `move_up`, `move_down`, `move_left`, `move_right` só têm teclas WASD nos defaults (linhas 9-12). Não há mapeamento de `gamepad_axis` para o analog stick esquerdo.

O `player.gd` usa `Input.get_axis("move_left", "move_right")` que funciona SE as ações tiverem o axis mapeado. O GamepadUI mapeia os axes para `ui_*` (navegação de menu), mas **não para `move_*`** (movimento do jogador).

Se o InputMap não tiver os axes configurados para move_*, o jogador não consegue se mover com o analog stick.

### Fix

```gdscript
# Em keybinding_manager.gd defaults:
"move_up": {"key": KEY_W, "gamepad_axis": {"axis": JOY_AXIS_LEFT_Y, "value": -1.0}},
"move_down": {"key": KEY_S, "gamepad_axis": {"axis": JOY_AXIS_LEFT_Y, "value": 1.0}},
"move_left": {"key": KEY_A, "gamepad_axis": {"axis": JOY_AXIS_LEFT_X, "value": -1.0}},
"move_right": {"key": KEY_D, "gamepad_axis": {"axis": JOY_AXIS_LEFT_X, "value": 1.0}},

# Em _apply_bindings(), adicionar:
if "gamepad_axis" in bind:
    var axis_data = bind["gamepad_axis"]
    var joy_axis = InputEventJoypadMotion.new()
    joy_axis.axis = axis_data["axis"]
    joy_axis.axis_value = axis_data["value"]
    var exists = false
    for ev in InputMap.action_get_events(action):
        if ev is InputEventJoypadMotion and ev.axis == axis_data["axis"] and signf(ev.axis_value) == signf(axis_data["value"]):
            exists = true
            break
    if not exists:
        InputMap.action_add_event(action, joy_axis)
```

### Critérios de aceite

- [ ] Analog stick esquerdo move o jogador em todas as direções
- [ ] Movimento é analógico (não binário) — andar devagar ao inclinar pouco
- [ ] Funciona mesmo após rebind de teclado
- [ ] Sem conflito com navegação de menus (ui_* é separado de move_*)

---

## Bug 15 — Hint de texto "Clique numa arma" assume mouse (P2)

**Arquivo:** `game/scripts/ui/codex_screen.gd`, linha 100

### Problema

```gdscript
hint.text = "Clique numa arma\npara ver detalhes."
```

Texto assume mouse. Com controle deveria dizer "Selecione uma arma".

### Fix

```gdscript
hint.text = "Selecione uma arma\npara ver detalhes."
```

### Critérios de aceite

- [ ] Texto genérico que funciona para mouse e controle

---

## Ordem de implementação

| Prioridade | Bug | Impacto |
|---|---|---|
| **P0** | Bug 14 — Movimento sem analog stick | Jogo injogável com controle |
| **P0** | Bug 7 — Inventário sem botão gamepad | Feature inacessível |
| **P0** | Bug 1 — Loja sem navegação | Progressão bloqueada |
| **P0** | Bug 2 — Codex sem navegação | Feature inacessível |
| **P0** | Bug 3 — Bestiário sem navegação | Feature inacessível |
| **P1** | Bug 13 — KeybindingManager ignora gamepad | Dash/interact podem falhar |
| **P1** | Bug 4 — Lobby pre-lobby sem focus | Multiplayer inacessível |
| **P1** | Bug 5 — Chat send FOCUS_NONE | Chat quebrado |
| **P1** | Bug 6 — Lobby panel sem focus | Lobby inutilizável |
| **P1** | Bug 8 — Inventário sem foco interno | UX ruim |
| **P1** | Bug 9 — Mutações sem focus chain | Feature parcialmente inacessível |
| **P1** | Bug 10 — Daily Challenge sem chain | Navegação imprevisível |
| **P1** | Bug 11 — Leaderboard sem chain | Navegação incompleta |
| **P2** | Bug 12 — Achievements scroll | Polish |
| **P2** | Bug 15 — Hint assume mouse | Texto incorreto |

---

## Arquivos afetados (12)

| Arquivo | Bugs |
|---|---|
| `game/scripts/autoload/keybinding_manager.gd` | Bug 13, Bug 14 |
| `game/scripts/ui/shop.gd` | Bug 1 |
| `game/scripts/ui/codex_screen.gd` | Bug 2, Bug 15 |
| `game/scripts/ui/bestiary_screen.gd` | Bug 3 |
| `game/scripts/ui/lobby_screen.gd` | Bug 4, Bug 5, Bug 6 |
| `game/scripts/ui/inventory_overlay.gd` | Bug 7, Bug 8 |
| `game/scripts/ui/mutations_panel.gd` | Bug 9 |
| `game/scripts/ui/daily_challenge_screen.gd` | Bug 10 |
| `game/scripts/ui/leaderboard_screen.gd` | Bug 11 |
| `game/scripts/ui/achievements_screen.gd` | Bug 12 |

---

## Teste manual necessário

- Controle PS4/PS5/Xbox conectado via USB ou Bluetooth
- Navegar em TODAS as telas do jogo sem usar mouse/teclado
- Verificar que analog stick move o jogador no gameplay
- Abrir inventário com Select/Back durante gameplay
- Comprar upgrade na loja com controle
- Navegar codex e bestiário
- Criar/entrar lobby multiplayer com controle
- Enviar mensagem no chat do lobby
- Ativar mutações com controle
- Jogar daily challenge com controle
- Verificar leaderboard com controle
- Console sem erros de focus/input
