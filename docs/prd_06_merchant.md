# PRD 06 — Mercador dimensional (3 problemas)

## Problemas
1. Mercador nao vende nada — loja vazia
2. Mercador spawna em cima do jogador — impossivel sair, fica reabrindo
3. ESC mostra "ESC para fechar" mas abre menu de pausa em vez de fechar

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `scripts/stages/event_manager.gd` | Todo o sistema do mercador: spawn (~L395-462), UI (~L516-817), compra (~L835-849), input (~L851-859), proximity check (~L111-118) |
| `scripts/ui/pause_menu.gd` | `_unhandled_input()` (~L54-86) — escuta "pause" |
| `scripts/autoload/item_db.gd` | Items disponiveis — podem estar todos `disabled: true` |
| `scripts/autoload/game_constants.gd` | `EVENT_MERCHANT_DURATION = 30.0` |

---

## Problema 1: Mercador nao vende nada

### Causa raiz
Em `event_manager.gd` linhas 464-479, o mercador filtra itens do ItemDB:
```gdscript
for iid in all_items:
    var data = ItemDB.get_item(iid)
    if not data.get("disabled", false):  # Filtra disabled
        available_items.append(iid)
```
Se todos os itens estiverem marcados como `disabled: true` no ItemDB, a lista fica vazia e o mercador nao mostra nada.

### Plano
1. Verificar `item_db.gd` — quantos itens tem `disabled: true`
2. Se todos estiverem disabled, desabilitar o filtro ou habilitar itens que devem estar no jogo
3. Definir a estrategia do mercador:
   - **O que vende**: 3 itens aleatorios do pool de 19 itens
   - **Custo**: 5-15 cristais da run (ja implementado)
   - **Quando aparece**: Evento aleatorio durante a run
   - **Duracao**: 30 segundos (GameConstants)
4. Garantir que ao comprar, o item eh adicionado via `GameManager.add_item()`

---

## Problema 2: Mercador spawna em cima do jogador

### Causa raiz
Em `event_manager.gd` linha 400:
```gdscript
var offset = Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-3, 3))
```
Offset de apenas +-3 unidades — muito perto. O jogador ja esta dentro da area de interacao (3.0 unidades).

Alem disso, em `_process()` linhas 111-118, a cada frame:
```gdscript
if merchant_pos.distance_to(mp.global_position) < 3.0:
    _show_merchant_ui()  # Reabre a cada frame!
```
Nao ha flag para impedir reabertura.

### Plano
1. **Aumentar distancia de spawn**: offset de +-10 a +-15 unidades
2. **Garantir distancia minima**: spawn a pelo menos 8 unidades do jogador
3. **Adicionar cooldown de reabertura**: flag `_merchant_ui_cooldown` que impede reabrir por 2 segundos apos fechar
4. **Remover check de proximity no _process()**: usar apenas o Area3D `body_entered` signal

```gdscript
# Spawn com distancia minima garantida:
var angle = rng.randf() * TAU
var dist = rng.randf_range(10.0, 15.0)
var offset = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
```

---

## Problema 3: ESC abre menu em vez de fechar mercador

### Causa raiz
O `event_manager.gd` escuta `"ui_cancel"` (ESC) na `_unhandled_input()` linha 851:
```gdscript
if event.is_action_pressed("ui_cancel"):
    var ui = get_node_or_null("MerchantUI")
    if ui:
        get_viewport().set_input_as_handled()
        ui.queue_free()
```

Porem, o overlay do mercador tem `mouse_filter = Control.MOUSE_FILTER_STOP` (linha 533), que **bloqueia input** antes de chegar ao `_unhandled_input()`. O ESC eh engolido pelo overlay e nao propaga.

O pause menu escuta `"pause"` (que tambem eh ESC no Godot por padrao).

### Plano
1. **Mudar overlay para `MOUSE_FILTER_IGNORE`** — permite input passar
2. **OU adicionar `_gui_input()` no overlay** que captura ESC:
```gdscript
overlay.gui_input.connect(func(event):
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _close_merchant_ui()
)
```
3. **Remover o texto "ESC para fechar"** se decidir usar botao de fechar em vez de ESC
4. **Adicionar botao "Fechar" visivel** como alternativa ao ESC

---

## Estrategia do mercador no jogo
O mercador dimensional eh um evento temporal. Proposta de design:
- Aparece a cada ~2-3 minutos como evento aleatorio
- Fica 30 segundos no mapa
- Vende 3 itens aleatorios por cristais da run
- Precos: 5-15 cristais (proporcional a raridade)
- Jogador pode comprar 0, 1, 2 ou todos os 3
- Apos 30s ou ao fechar, mercador desaparece

## Validacao
- [ ] Mercador mostra 3 itens para venda com precos
- [ ] Comprar item funciona (desconta cristais, adiciona item)
- [ ] Mercador nao spawna em cima do jogador (min 8 unidades)
- [ ] Fechar o mercador nao reabre automaticamente
- [ ] ESC fecha o mercador (ou remover texto ESC e usar botao)
- [ ] Mercador desaparece apos 30 segundos
