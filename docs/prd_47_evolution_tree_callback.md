# PRD 47 — Parser Error: `_on_evolution_tree` não declarado em `main_menu.gd`

**Status:** pendente  
**Prioridade:** Alta  
**Escopo:** `game/scripts/ui/main_menu.gd` (1 arquivo, 1 linha)  
**Tipo:** Bug — Parser Error em runtime (callback ausente)

---

## Descrição do Problema

Ao carregar o menu principal, o Godot emite:

```
Parser Error: Identifier "_on_evolution_tree" not declared in the current scope.
```

Isso impede o botão "Árvore de Evolução" de funcionar. Em Godot 4, conectar um sinal a um callable que não existe gera um erro em tempo de análise/execução, podendo causar comportamento indefinido no menu.

---

## Causa Raiz

**Arquivo:** `game/scripts/ui/main_menu.gd`, linha 133  
**Problema:** o sinal `pressed` do botão `evo_btn` é conectado a `_on_evolution_tree`, mas essa função **nunca foi declarada** no arquivo.

```gdscript
# Linha 133 — connect aponta para função inexistente
evo_btn.pressed.connect(_on_evolution_tree)  # ← _on_evolution_tree não existe!
```

Todas as outras ações de navegação do menu seguem o mesmo padrão e têm suas funções declaradas:

| Botão       | Linha | Função declarada |
|-------------|-------|-----------------|
| Jogar       | ~763  | `_on_play()`     |
| Multiplayer | ~768  | `_on_multiplayer()` |
| Loja        | ~773  | `_on_shop()`     |
| Opções      | ~778  | `_on_options()`  |
| Créditos    | ~783  | `_on_credits()`  |
| **Evo Tree**| 133   | **AUSENTE**      |

O arquivo de destino `res://scenes/ui/evolution_tree.tscn` **existe** e está funcional — o único problema é a função de callback que faz a transição de cena.

---

## Impacto

- **O botão de Árvore de Evolução não funciona** — clique não dispara nenhuma ação
- Parser Error no console a cada carregamento do menu principal
- Toda a tela de evolução (PRD 40, já implementada) fica inacessível pelo menu

---

## Solução

Adicionar a função `_on_evolution_tree()` em `main_menu.gd`, seguindo o padrão dos outros callbacks de navegação:

```gdscript
func _on_evolution_tree() -> void:
    AudioManager.play_sfx("menu_click")
    LoadingScreen.transition_to("res://scenes/ui/evolution_tree.tscn")
```

**Localização ideal:** após `_on_credits()` (linha ~785), junto com as demais funções de navegação.

---

## Arquivos Modificados

| Arquivo | Alteração |
|---------|-----------|
| `game/scripts/ui/main_menu.gd` | +4 linhas: função `_on_evolution_tree()` |

---

## Implementação

### Passo 1 — Adicionar função em `main_menu.gd`

Inserir após `_on_credits()`:

```gdscript
func _on_evolution_tree() -> void:
    AudioManager.play_sfx("menu_click")
    LoadingScreen.transition_to("res://scenes/ui/evolution_tree.tscn")
```

### Passo 2 — Verificação

- Abrir o menu principal sem erros no console
- Clicar no botão "Árvore de Evolução" → tela deve abrir normalmente
- Confirmar que o botão Voltar da tela de evolução retorna ao menu

---

## Critérios de Aceite

- [ ] Nenhum Parser Error ao carregar `main_menu.tscn`
- [ ] Botão "Árvore de Evolução" navega para `evolution_tree.tscn`
- [ ] Som `menu_click` toca ao clicar
- [ ] Retorno ao menu principal funciona normalmente

---

## Notas

- Fix trivial: **1 função, 4 linhas**
- Sem risco de regressão — não altera lógica existente, apenas adiciona o callback ausente
- A tela `evolution_tree.tscn` e `evolution_tree.gd` já estão 100% implementadas (PRD 40)
