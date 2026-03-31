## Status: CONCLUIDO

# PRD 10 — Loja: Reset All e Max All nao funcionam

## Problema
Botoes "Reset all" e "Max all" na loja nao funcionam.

## Causa raiz
Apos investigacao, os botoes **estao implementados e conectados**:
- `_on_reset_all()` (linhas 267-279): refunde cristais e reseta upgrades
- `_on_fill_all()` (linhas 281-292): compra upgrades ate max ou sem cristais

O problema provavel eh que os **botoes estao fora da area visivel** devido ao layout com scroll. O jogador nao consegue clicar neles, ou estao atras do ScrollContainer.

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `scripts/ui/shop.gd` | Botoes criados em linhas 76-102, handlers em linhas 267-292 |
| `scenes/ui/shop.tscn` | Layout: ScrollContainer com size_flags_vertical = EXPAND_FILL |

## Plano de implementacao

### Passo 1 — Verificar se botoes estao visiveis
Adicionar debug temporario para confirmar que os botoes existem e estao na tela:
```gdscript
print("Reset btn visible: ", reset_btn.visible, " pos: ", reset_btn.global_position)
print("Max btn visible: ", fill_btn.visible, " pos: ", fill_btn.global_position)
```

### Passo 2 — Mover botoes para FORA do ScrollContainer
Os botoes Reset/Max devem ficar no VBox principal, NAO dentro do ScrollContainer:

```
VBox (principal)
├── Title
├── CrystalsLabel
├── HBox (Reset All | Max All)    ← AQUI, antes do scroll
├── ScrollContainer
│   └── Grid de upgrades
└── BackButton
```

### Passo 3 — Testar funcionalidade
Apos mover, verificar:
- Reset All: todos upgrades voltam a 0, cristais sao reembolsados
- Max All: todos upgrades vao ao maximo, cristais descontados
- Ambos chamam `_build_shop_ui()` para atualizar visual
- Ambos chamam `SaveManager.save_game()` para persistir

### Passo 4 — Feedback visual
Adicionar feedback ao clicar:
- Flash no botao
- Som de confirmacao
- Atualizar label de cristais imediatamente

## Validacao
- [ ] Botao "Reset all" visivel e clicavel
- [ ] Botao "Max all" visivel e clicavel
- [ ] Reset all reembolsa cristais corretamente
- [ ] Max all compra tudo que pode
- [ ] Mudancas persistem (SaveManager)
- [ ] Visual atualiza imediatamente apos clicar
