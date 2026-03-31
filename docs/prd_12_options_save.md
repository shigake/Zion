# PRD 12 — Opcoes: salva automaticamente, precisa de botao Salvar

## Problema
A tela de opcoes salva automaticamente ao mudar qualquer configuracao. O jogador quer poder testar sem comprometer. E ao salvar, precisa persistir de verdade (manter ao fechar e reabrir o jogo).

## Causa raiz
Em `options_screen.gd`, TODA mudanca chama `_save()` imediatamente:

```gdscript
# Exemplo (toggle):
btn.toggled.connect(func(pressed: bool) -> void:
    _save(key, pressed)  # Salva na hora!
    if callback.is_valid():
        callback.call(pressed)
)

func _save(key: String, value: Variant) -> void:
    SaveManager.data[key] = value
    SaveManager.save_game()  # Persiste no disco imediatamente
```

Botoes no footer:
- "Restaurar padrao" (reseta tab atual)
- "Voltar" (volta ao menu)
- **NAO existe botao "Salvar"**

## Sobre persistencia
O `SaveManager` ja tem infraestrutura completa:
- Salva em `user://save_data.json`
- `_restore_settings()` carrega tudo no `_ready()`
- Settings restauradas: window mode, resolucao, V-Sync, FPS limit, MSAA, audio volumes

A persistencia **funciona** se `save_game()` for chamado. O problema eh que mudancas sao salvas antes do jogador decidir.

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `scripts/ui/options_screen.gd` | Toda a tela de opcoes: controles, `_save()` (~L40-42), footer (~L229-245) |
| `scripts/autoload/save_manager.gd` | `save_game()` (~L72-82), `load_game()` (~L84-114), `_restore_settings()` (~L29) |

## Plano de implementacao

### Passo 1 — Criar armazenamento temporario
Em `options_screen.gd`, adicionar dicionario para mudancas pendentes:

```gdscript
var _pending_changes: Dictionary = {}
var _original_values: Dictionary = {}  # Valores ao abrir a tela
```

### Passo 2 — Capturar valores originais ao abrir
```gdscript
func _ready():
    # Salvar estado atual para poder reverter
    for key in ["video_window_mode", "video_resolution", "video_vsync", ...]:
        _original_values[key] = SaveManager.data.get(key)
```

### Passo 3 — Mudar controles para NAO salvar automaticamente
```gdscript
# Antes:
btn.toggled.connect(func(pressed: bool) -> void:
    _save(key, pressed)

# Depois:
btn.toggled.connect(func(pressed: bool) -> void:
    _pending_changes[key] = pressed
    # Aplicar preview (ex: mudar volume em tempo real)
    if callback.is_valid():
        callback.call(pressed)
)
```

O preview (ex: ajustar volume do slider em tempo real) continua funcionando, mas NAO salva no disco.

### Passo 4 — Adicionar botao "Salvar"
No footer, adicionar botao "Salvar" ao lado de "Restaurar padrao" e "Voltar":

```gdscript
var save_btn = Button.new()
save_btn.text = LocaleManager.tr_key("save")  # Traduzido
save_btn.pressed.connect(_on_save)
footer.add_child(save_btn)

func _on_save() -> void:
    for key in _pending_changes:
        SaveManager.data[key] = _pending_changes[key]
    SaveManager.save_game()
    _pending_changes.clear()
    _original_values = SaveManager.data.duplicate()
    AudioManager.play_sfx("menu_click")
    # Feedback visual: "Salvo!"
```

### Passo 5 — Reverter ao sair sem salvar
```gdscript
func _on_back() -> void:
    if not _pending_changes.is_empty():
        # Reverter previews ao estado original
        for key in _pending_changes:
            var original = _original_values.get(key)
            if original != null:
                _apply_setting(key, original)  # Reverte preview
    _pending_changes.clear()
    # Voltar ao menu
```

### Passo 6 — Indicador visual de mudancas nao salvas
Quando `_pending_changes` nao estiver vazio, mostrar asterisco (*) no titulo ou highlight no botao Salvar:
```gdscript
save_btn.text = "* Salvar *" if not _pending_changes.is_empty() else "Salvar"
```

## Validacao
- [ ] Mudar uma opcao NAO salva automaticamente
- [ ] Preview funciona (ex: volume muda em tempo real)
- [ ] Clicar "Salvar" persiste as mudancas
- [ ] Sair sem salvar reverte ao estado anterior
- [ ] Fechar e reabrir o jogo mantem configuracoes salvas
- [ ] Indicador visual mostra quando ha mudancas nao salvas
- [ ] "Restaurar padrao" funciona (reseta + marca como pending)
