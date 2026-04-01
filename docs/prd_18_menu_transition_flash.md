# PRD 18 — Remover mini-loading nas transições de menu

**Status:** pendente  
**Prioridade:** P1 — polimento visual  
**Estimativa:** 1–2h  

---

## Problema

Ao navegar entre telas de menu (ex.: menu principal → opções, menu principal → créditos, seleção de personagem → seleção de fase), aparece brevemente uma tela preta com o sprite do personagem selecionado, nome da fase e uma dica de gameplay — como se fosse um mini-loading.

O resultado é visualmente estranho: parece que uma imagem aleatória foi "jogada" entre as telas, sem contexto. Não há carregamento real acontecendo — são todas telas de UI leves que trocam instantaneamente.

**O que NÃO deve ser alterado:** o loading completo acionado por `load_stage()`, que carrega fases de jogo. Esse deve continuar intacto com sprite, dicas, barra de progresso e pre-warming dos sistemas.

---

## Causa raiz

Em `loading_screen.gd`, a função `transition_to(scene_path)` é usada tanto para navegação entre menus quanto como ponto de entrada para iniciar uma run. Ela sempre chama `_build_transition_info()`, que exibe:

- Sprite do personagem selecionado (`GameManager.selected_character`)
- Nome da fase selecionada (`GameManager.selected_stage`)
- Dica aleatória de gameplay
- Label "Carregando..."

Isso faz sentido **antes de carregar uma fase**, mas é completamente fora de contexto ao navegar entre telas de menu onde não há carregamento real.

**Chamadas afetadas** (navegação entre menus — devem suprimir o mini-loading):

| Arquivo | Chamada |
|---|---|
| `scripts/ui/main_menu.gd` | `LoadingScreen.transition_to("res://scenes/ui/character_select.tscn")` |
| `scripts/ui/main_menu.gd` | `LoadingScreen.transition_to("res://scenes/ui/lobby_screen.tscn")` |
| `scripts/ui/main_menu.gd` | `LoadingScreen.transition_to("res://scenes/ui/shop.tscn")` |
| `scripts/ui/main_menu.gd` | `LoadingScreen.transition_to("res://scenes/ui/options_screen.tscn")` |
| `scripts/ui/main_menu.gd` | `LoadingScreen.transition_to("res://scenes/ui/credits_screen.tscn")` |
| `scripts/ui/character_select.gd` | `LoadingScreen.transition_to("res://scenes/ui/stage_select.tscn")` |
| `scripts/ui/character_select.gd` | `LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")` |

**Chamadas que devem continuar inalteradas** (carregamento real de fase):

| Arquivo | Chamada |
|---|---|
| `scripts/ui/character_select.gd` | `LoadingScreen.load_stage(scene_path)` |
| `scripts/ui/stage_select.gd` | *(qualquer chamada a `load_stage`)* |

---

## Solução proposta

### Opção A — Parâmetro `show_info` em `transition_to` *(recomendada)*

Adicionar um parâmetro booleano opcional `show_info: bool = true` à função `transition_to`:

```gdscript
func transition_to(scene_path: String, show_info: bool = true) -> void:
    ...
    # Somente exibe sprite/dica se show_info for true
    if show_info and is_instance_valid(_transition_root):
        _build_transition_info()
```

Todas as chamadas de menu passam `false`:

```gdscript
# main_menu.gd, character_select.gd — navegação entre telas de UI
LoadingScreen.transition_to("res://scenes/ui/character_select.tscn", false)
```

`load_stage()` não é tocado — continua exibindo a tela completa normalmente.

**Vantagens:** mudança cirúrgica, sem quebrar a interface pública; fade-in/fade-out suave é preservado (o usuário ainda vê a tela escurecer e clarear); nenhum refactor necessário.

### Opção B — Trocar chamadas de menu por `change_scene_to_file` direto *(descartada)*

Substituiria `LoadingScreen.transition_to` por `get_tree().change_scene_to_file` nos menus. Eliminaria até o fade, deixando a troca abrupta — pior experiência visual. Descartada.

---

## Comportamento esperado após o fix

| Situação | Antes | Depois |
|---|---|---|
| Menu principal → Créditos | Tela preta + sprite + dica | Fade suave preto → nova tela |
| Menu principal → Opções | Tela preta + sprite + dica | Fade suave preto → nova tela |
| Seleção de personagem → Seleção de fase | Tela preta + sprite + dica | Fade suave preto → nova tela |
| Iniciar run (load_stage) | Tela preta + sprite + barra de progresso + dica | **Sem alteração** — comportamento completo mantido |

O fade de 0.4s em cada direção (preto ao trocar de tela) pode ser mantido ou reduzido para 0.25s nos menus para deixar a navegação mais ágil — decisão do desenvolvedor ao implementar.

---

## Arquivos a modificar

1. **`game/scripts/autoload/loading_screen.gd`**  
   - Adicionar parâmetro `show_info: bool = true` em `transition_to()`  
   - Condicionar chamada de `_build_transition_info()` ao valor de `show_info`

2. **`game/scripts/ui/main_menu.gd`**  
   - Passar `false` em todas as chamadas de `transition_to` para telas de UI

3. **`game/scripts/ui/character_select.gd`**  
   - Passar `false` nas chamadas de `transition_to` para `stage_select.tscn` e `main_menu.tscn`  
   - **Não tocar** na chamada de `load_stage()` — essa permanece intacta

---

## Critérios de aceitação

- [ ] Navegar entre qualquer tela de menu mostra apenas fade preto suave, sem sprite nem dica
- [ ] Iniciar uma run continua mostrando a tela de loading completa (sprite, dica, barra de progresso)
- [ ] Nenhum erro de null reference introduzido
- [ ] Sem regressão nas transições existentes (fade não trava, cena carrega corretamente)
