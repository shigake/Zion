# PRD — UI Polish, Bugfixes e Cena de Créditos

> Melhorias de interface nos menus, correção de crash no GameManager e adição de animações procedurais na tela de créditos. Todas as referências apontam para cenas e scripts reais do projeto.

---

## Tarefa 1: Cena de Créditos (Animação e Escala)

**Objetivo:** Tornar os heróis da fogueira maiores e vivos, com movimento procedural de idle e uma dança aleatória.

### Contexto

A cena `res://scenes/ui/credits_screen.tscn` usa um `SubViewport` com uma câmera 3D para renderizar os 15 Fragmentados em círculo ao redor de uma fogueira. Os heróis são criados em `_create_characters_circle()` no script `res://scripts/ui/credits_screen.gd` (linha 283). Cada um é um `Sprite3D` billboard com `pixel_size = 0.012` e `position.y = 0.8`, sem qualquer animação procedural.

### Detalhes

1. **Escala**: Na função `_create_characters_circle()`, dobrar a escala visual dos sprites. Usar `sprite.pixel_size = 0.024` (ou aplicar `char_root.scale = Vector3(2, 2, 2)`) mantendo a flag `TEXTURE_FILTER_NEAREST` para não borrar o pixel art.

2. **Idle Bobbing**: Adicionar, no `_process()` da cena (que já existe na linha 51), um loop que percorre cada `char_root` no `SubViewport` e aplica um **bobbing vertical procedural** usando `sin()`:

```gdscript
# Cada herói recebe um offset randômico no _ready, armazenado em um Array
char_root.position.y = base_y + sin(Time.get_ticks_msec() * 0.001 * speed + phase_offset) * amplitude
```

- `amplitude`: ~0.08 (sutil, não exagerado)
- `speed`: randômico entre 1.0 e 2.0 por herói
- `phase_offset`: `randf() * TAU` por herói (evita sincronismo)

3. **Dança Aleatória**: Na `_ready()`, após criar os personagens, sortear **1 herói aleatório** e aplicar um Tween em loop de "dança":

```gdscript
var dancer_index = randi() % count
var dancer_root = sub_viewport.get_child(dancer_node_index)
var tween = create_tween().set_loops()
tween.tween_property(dancer_root, "rotation:y", deg_to_rad(15), 0.3).set_trans(Tween.TRANS_SINE)
tween.tween_property(dancer_root, "position:y", base_y + 0.3, 0.2).set_trans(Tween.TRANS_BACK)
tween.tween_property(dancer_root, "position:y", base_y, 0.2).set_trans(Tween.TRANS_BOUNCE)
tween.tween_property(dancer_root, "rotation:y", deg_to_rad(-15), 0.3).set_trans(Tween.TRANS_SINE)
tween.tween_property(dancer_root, "position:y", base_y + 0.3, 0.2).set_trans(Tween.TRANS_BACK)
tween.tween_property(dancer_root, "position:y", base_y, 0.2).set_trans(Tween.TRANS_BOUNCE)
```

### Arquivos impactados

| Arquivo | Ação |
|---|---|
| `scripts/ui/credits_screen.gd` | Modificar `_create_characters_circle()` e `_process()` |

### Critérios de aceite

- [ ] Sprites 2x maiores sem borrar a pixel art (filtro NEAREST mantido)
- [ ] Bobbing vertical suave com offset randômico por herói (sem sincronismo)
- [ ] 1 herói aleatório executa dança (Tween looping de rotação + pulo)
- [ ] Código modular (arrays de dados por herói, fácil de estender)

---

## Tarefa 2: Bugfix do GameManager (Crash de Cura)

**Objetivo:** Corrigir o crash `Invalid call. Nonexistent function 'heal_player'` causado pela sinergia Ice+Dark.

### Contexto da causa raiz

O crash ocorre em `res://scripts/autoload/synergy_system.gd`, linha 424:

```gdscript
GameManager.heal_player(heal_amount)
```

Porém, a função real no `res://scripts/autoload/game_manager.gd` (linha 429) se chama `heal(amount: int)`, **não** `heal_player()`. A sinergia Ice+Dark (Shadow Freeze) calcula 2% do dano como cura e chama a função inexistente.

### Solução

**Opção A (Recomendada):** Criar um alias `heal_player()` no `game_manager.gd` que delega para `heal()`, mantendo retrocompatibilidade se outros scripts usarem o nome antigo:

```gdscript
## Alias para heal() — mantém compatibilidade com chamadas externas
func heal_player(amount: float) -> void:
    heal(int(amount))
```

**Opção B (Alternativa):** Corrigir a chamada em `synergy_system.gd:424` de `GameManager.heal_player(heal_amount)` para `GameManager.heal(int(heal_amount))`.

### Observação sobre a função `heal()` existente

A função `heal()` já implementa:
- Bônus 2x para o Chef (`selected_character == "chef"`)
- Multiplicador de mutação (`MutationManager.get_heal_modifier()`)
- Clamp no `get_effective_max_hp()` (que já considera `max_hp_mult`)
- Sync multiplayer via `MultiplayerManager.notify_damage()`

Portanto, **não é necessário reimplementar**. Basta resolver o nome.

### Arquivos impactados

| Arquivo | Ação |
|---|---|
| `scripts/autoload/game_manager.gd` | Adicionar alias `heal_player()` (Opção A) |
| `scripts/autoload/synergy_system.gd` | OU corrigir chamada na linha 424 (Opção B) |

### Critérios de aceite

- [ ] Sinergia Ice+Dark (Shadow Freeze) não crasha mais ao curar
- [ ] Cura respeitada com clamp, bônus do Chef e multiplicador de mutação
- [ ] HUD atualiza HP via sync existente do `MultiplayerManager.notify_damage()`

---

## Tarefa 3: Ajuste de UI do Menu Principal (Sobreposição Logo/Subtítulo)

**Objetivo:** Garantir que o subtítulo *"Survive the horde. Ascend beyond."* fique visualmente separado do logo ZION.

### Contexto

A cena `res://scenes/ui/main_menu.tscn` organiza o layout assim:

```
LeftPanel (MarginContainer)
  └── Content (VBoxContainer, separation = 0)  ← raiz do problema
      ├── TopSpacer (40px)
      ├── Title (Label "ZION") ← substituído por LogoSprite no _ready()
      ├── Subtitle (Label "Survivors Roguelite") ← texto alterado no _ready()
      ├── CrystalsSpacer (16px)
      └── ...
```

O script `main_menu.gd` (linha 202) altera o subtítulo para *"Survive the horde. Ascend beyond."* e, na `_style_title()` (linha 172), substitui o Label Title por um `TextureRect` chamado `LogoSprite` (384×96 px). Com `separation = 0` no VBoxContainer pai, o subtítulo fica colado no logo.

### Solução

1. Na cena `.tscn`, alterar o `theme_override_constants/separation` do nó `Content` (VBoxContainer) de `0` para `12`.
2. No script `_style_title()`, após criar o `LogoSprite`, adicionar um `MarginContainer` ou `Control` spacer de `custom_minimum_size = Vector2(0, 8)` entre o logo e o subtítulo para respiro adicional.

### Arquivos impactados

| Arquivo | Ação |
|---|---|
| `scenes/ui/main_menu.tscn` | Alterar `separation` do VBoxContainer `Content` |
| `scripts/ui/main_menu.gd` | Inserir spacer após `LogoSprite` em `_style_title()` |

### Critérios de aceite

- [ ] Subtítulo visualmente separado do logo (mínimo ~12px de gap)
- [ ] Layout responsivo ao redimensionar a janela (anchors + VBox)
- [ ] Sem regressão nos botões e cristais abaixo

---

## Tarefa 4: Ajuste de UI do Bestiário (Centralização de Botões)

**Objetivo:** Padronizar o alinhamento textual nos cards de monstros do Bestiário.

### Contexto

A cena `res://scenes/ui/bestiary_screen.tscn` é um Control vazio; toda a UI é construída proceduralmente no script `res://scripts/ui/bestiary_screen.gd`. A função `_populate_grid()` (linha 543) cria `Button` + `VBoxContainer` interno para cada monstro e já define `horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER` nos Labels filhos (linhas 593, 603, 612).

### Problema identificado

Os Labels internos estão corretamente centralizados na sua tipografia (`HORIZONTAL_ALIGNMENT_CENTER`), **porém** o `VBoxContainer` filho do `Button` não tem `size_flags`, fazendo com que o conteúdo não acompanhe o tamanho total do botão. O VBox precisa preencher o botão completamente.

### Solução

Na `_populate_grid()`, após `card_btn.add_child(vbox)` (linha 581), adicionar as flags de expansão ao VBox e alinhamento ao botão:

```gdscript
vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
vbox.alignment = BoxContainer.ALIGNMENT_CENTER
```

### Arquivos impactados

| Arquivo | Ação |
|---|---|
| `scripts/ui/bestiary_screen.gd` | Adicionar flags no VBox em `_populate_grid()` |

### Critérios de aceite

- [ ] VBox interno do card ocupa 100% da área do botão
- [ ] Texto dos 90+ monstros centralizado horizontal e verticalmente
- [ ] Alinhamento mantido ao redimensionar/scrollar

---

## Tarefa 5: Ajuste de UI do Codex de Armas (Centralização e Proteção de Texto)

**Objetivo:** Padronizar a centralização textual no Codex de Armas e proteger nomes longos de armas evoluídas.

### Contexto

O script `res://scripts/ui/codex_screen.gd` constrói a grid proceduralmente em `_populate_grid()` (linha 190). Assim como o Bestiário, usa `Button` + `VBoxContainer` com Labels. O VBox já tem `alignment = BoxContainer.ALIGNMENT_CENTER` (linha 232), e os Labels usam `HORIZONTAL_ALIGNMENT_CENTER` (linhas 262, 271, 279, 287).

### Problemas identificados

1. O VBox não tem `PRESET_FULL_RECT` nem flags de expand, causando desalinhamento similar ao Bestiário.
2. Armas com nomes longos (ex: "⚔ Tempestade de Flechas", "✨ Tempestade Eletrica") podem ultrapassar os limites do card (175×130 px). Os Labels `name_lbl` não têm `autowrap_mode` nem `clip_text`.

### Solução

1. Aplicar no VBox do card as mesmas flags da Tarefa 4:

```gdscript
vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
```

2. No `name_lbl` (linha 260), adicionar proteção contra overflow:

```gdscript
name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
name_lbl.clip_text = true
name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
```

### Arquivos impactados

| Arquivo | Ação |
|---|---|
| `scripts/ui/codex_screen.gd` | Adicionar flags no VBox + proteção no Label de nome |

### Critérios de aceite

- [ ] VBox do card preenche o botão inteiro
- [ ] Nomes longos de armas truncados com ellipsis ("Tempest...") sem vazar
- [ ] Padronização estética entre Codex e Bestiário confirmada
- [ ] Informação de evolução legível (`autowrap` já existe no `detail_evo`)

---

## Tarefa 6: Navegação de Abas com R1/L1 na Tela de Opções

**Objetivo:** Permitir que o jogador troque entre as 7 abas da tela de Opções usando os bumpers (R1/L1) do controle.

### Contexto

O script `res://scripts/ui/options_screen.gd` constrói a tela com um `TabContainer` (linha 184) contendo 7 abas criadas sequencialmente (linhas 190-196):

| Índice | Aba | Build Function |
|---|---|---|
| 0 | Video | `_build_tab_video()` |
| 1 | Gráficos | `_build_tab_graficos()` |
| 2 | Áudio | `_build_tab_audio()` |
| 3 | Gameplay | `_build_tab_gameplay()` |
| 4 | Controles | `_build_tab_controles()` |
| 5 | Acessibilidade | `_build_tab_acessibilidade()` |
| 6 | Idioma | `_build_tab_idioma()` |

Atualmente, a `_unhandled_input()` (linha 560) só processa `ui_cancel` (voltar) e rebind de tecla. **Não existe nenhum suporte para trocar abas via gamepad.** As abas só são clicáveis via mouse ou D-pad, o que é ruim para UX de controle.

### Solução

**Passo 1:** Registrar input actions para os bumpers no `project.godot` (ou via código no `_ready()`):

```gdscript
# No _ready() do options_screen.gd, registrar as actions se não existirem
if not InputMap.has_action("ui_tab_next"):
    InputMap.add_action("ui_tab_next")
    var ev_r1 = InputEventJoypadButton.new()
    ev_r1.button_index = JOY_BUTTON_RIGHT_SHOULDER
    InputMap.action_add_event("ui_tab_next", ev_r1)

if not InputMap.has_action("ui_tab_prev"):
    InputMap.add_action("ui_tab_prev")
    var ev_l1 = InputEventJoypadButton.new()
    ev_l1.button_index = JOY_BUTTON_LEFT_SHOULDER
    InputMap.action_add_event("ui_tab_prev", ev_l1)
```

**Passo 2:** Na `_unhandled_input()` (linha 560), **antes** do bloco de `waiting_for_key`, adicionar a lógica de troca de aba:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    # --- NOVO: Navegação de abas com R1/L1 ---
    if event.is_action_pressed("ui_tab_next"):
        var next = (tab_container.current_tab + 1) % tab_container.get_tab_count()
        tab_container.current_tab = next
        AudioManager.play_sfx("menu_click")
        if get_viewport(): get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("ui_tab_prev"):
        var prev = (tab_container.current_tab - 1 + tab_container.get_tab_count()) % tab_container.get_tab_count()
        tab_container.current_tab = prev
        AudioManager.play_sfx("menu_click")
        if get_viewport(): get_viewport().set_input_as_handled()
        return

    # --- Código existente de rebind e ui_cancel ---
    if waiting_for_key.is_empty():
        if event.is_action_pressed("ui_cancel"):
            _on_back()
            # ...
```

**Passo 3 (Opcional — Indicador visual):** Adicionar um hint visual no header das abas mostrando os ícones `[L1]` e `[R1]` quando um gamepad for detectado:

```gdscript
# No _build_ui(), após criar o tab_container
var tab_hint = Label.new()
tab_hint.text = "[L1] ◄  ► [R1]"
tab_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
tab_hint.add_theme_font_size_override("font_size", 12)
tab_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
tab_hint.visible = Input.get_connected_joypads().size() > 0
root_vbox.add_child(tab_hint)
root_vbox.move_child(tab_hint, tab_container.get_index())  # Acima do TabContainer
```

### Observação: Conflito com Rebind

Quando `waiting_for_key` não está vazio (o jogador está rebindando uma tecla, linha 566), a lógica de R1/L1 **não deve capturar os bumpers**. A order do `return` no código acima cuida disso: se `waiting_for_key` não estiver vazio, o fluxo cai no bloco de rebind original.

Porém, se o design permitir rebind de **botões de gamepad** no futuro, será necessário filtrar `InputEventJoypadButton` no bloco de rebind e ignorar R1/L1 explicitamente.

### Arquivos impactados

| Arquivo | Ação |
|---|---|
| `scripts/ui/options_screen.gd` | Adicionar input handling de R1/L1 em `_unhandled_input()` |
| `project.godot` (ou via código) | Registrar `ui_tab_next` e `ui_tab_prev` |

### Critérios de aceite

- [ ] R1 avança para a próxima aba (Video → Gráficos → Audio → ... → Idioma → Video)
- [ ] L1 volta para a aba anterior (com wrapping circular)
- [ ] SFX `menu_click` toca ao trocar de aba
- [ ] Não conflita com rebind de tecla (R1/L1 ignorados durante rebind)
- [ ] Hint visual `[L1] ◄  ► [R1]` aparece quando gamepad está conectado

---

## Dependências

| Sistema | Tarefas |
|---|---|
| `GameManager` (autoload) | Tarefa 2 |
| `SynergySystem` (autoload) | Tarefa 2 |
| `credits_screen.gd` + `.tscn` | Tarefa 1 |
| `main_menu.gd` + `.tscn` | Tarefa 3 |
| `bestiary_screen.gd` | Tarefa 4 |
| `codex_screen.gd` | Tarefa 5 |
| `options_screen.gd` | Tarefa 6 |

## Ordem de implementação

| Fase | Tarefas | Descrição |
|---|---|---|
| A | 2 | Bugfix crítico — resolve crash da sinergia Ice+Dark |
| B | 3, 6 | Menu principal + Opções (UI de navegação) |
| C | 4, 5 | Padronização de UI — Bestiário + Codex em paralelo |
| D | 1 | Polish — animação procedural na tela de créditos |

## Prioridade

Média-alta — o bugfix (Tarefa 2) é bloqueante para gameplay com sinergia Ice+Dark. A Tarefa 6 é essencial para UX com gamepad. As UIs restantes são cosméticas mas afetam percepção de qualidade.
