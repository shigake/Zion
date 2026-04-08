# PRD 19 — Tagline do menu principal abaixo do título

**Status:** CONCLUIDO  
**Prioridade:** Baixa  
**Estimativa:** 30 min  
**Arquivo principal:** `game/scripts/ui/main_menu.gd`  

---

## Problema

No menu principal, a tagline **"Survive the horde. Ascend beyond."** aparece visualmente **sobre o título ZION** — sobreposta ou imediatamente acima dele — em vez de aparecer abaixo. O resultado é que as duas peças de texto ficam empilhadas de forma errada, com a frase "engolindo" o título e prejudicando a hierarquia visual da tela.

---

## Comportamento esperado

```
[ Logo / ZION ]
[ Survive the horde. Ascend beyond. ]   ← abaixo do título, com respiro visual
[ Play solo ]
[ Multiplayer ]
[ ... ]
```

---

## Causa raiz

Em `main_menu.gd`, a função `_style_title()` controla dois caminhos:

1. **Com `logo.png`**: insere um `TextureRect` (LogoSprite) + spacer dinamicamente no VBoxContainer, reposicionando nós por índice. A lógica de `move_child` pode colocar o `Subtitle` no índice errado dependendo da ordem de inserção.

2. **Fallback (sem logo)**: o `Title` (Label "ZION") e o `Subtitle` ficam no VBoxContainer na ordem definida pelo `.tscn`. O `.tscn` declara `Subtitle` logo após `Title`, mas a animação de float (`_title_base_y`) e possíveis ajustes de posição absoluta podem fazer o nó sair do fluxo normal e se sobrepor ao subtítulo.

Em ambos os casos, o `Subtitle` deve sempre estar **abaixo** do título/logo, com um pequeno espaçamento de respiro.

---

## Solução

### Passo 1 — Garantir a ordem no `.tscn`

Em `game/scenes/ui/main_menu.tscn`, confirmar que a hierarquia dentro de `LeftPanel/Content` (VBoxContainer) segue esta ordem:

```
TopSpacer
Title          ← Label "ZION" (fallback)
Subtitle       ← Label tagline — DEVE vir depois de Title
CrystalsSpacer
CrystalsContainer
...botões...
```

Se `Subtitle` estiver antes de `Title` no `.tscn`, corrigir a ordem dos nós.

### Passo 2 — Corrigir `_style_title()` no modo logo

Quando `logo.png` existe, o código atual insere `LogoSprite` no índice `idx` (posição original de `Title`) e move o `logo_spacer` para `idx + 1`. O `Subtitle` precisa ficar em `idx + 2` (depois do spacer). Verificar se `move_child` está deslocando o `Subtitle` para antes do `LogoSprite`.

Correção segura: após inserir `LogoSprite` e `logo_spacer`, mover explicitamente o `Subtitle` para a última posição desejada:

```gdscript
# Após inserir LogoSprite e logo_spacer:
parent.move_child(subtitle_label, idx + 2)
```

Isso garante a ordem: `LogoSprite → logo_spacer → Subtitle`, independente da ordem original no `.tscn`.

### Passo 3 — Adicionar espaçamento entre título e tagline

A tagline precisa de respiro em relação ao título. Garantir que o `logo_spacer` (já existente, `12px`) seja suficiente, ou ajustar para `16px` para mais clareza visual.

---

## O que NÃO deve mudar

- O loading screen antes de iniciar a jogatina — não é afetado por esta mudança.  
- A animação de float do título (bob suave) — continua intacta.  
- Os sparkles dourados ao redor do título — continuam intactos.  
- O conteúdo da tagline — continua "Survive the horde. Ascend beyond."

---

## Critérios de aceitação

- [ ] A tagline aparece **abaixo** do título ZION em todas as situações: com logo.png e sem (fallback texto).  
- [ ] Há pelo menos `12px` de espaçamento entre o título e a tagline.  
- [ ] A hierarquia visual fica: título → tagline → cristais → botões.  
- [ ] Testado em 1280×720 e em resoluções maiores (sem sobreposição).  
- [ ] Nenhuma outra tela do menu é afetada.
