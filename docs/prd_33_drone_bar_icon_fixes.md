# PRD 33 — Drone invisível, barras de HP/XP bugadas e ícones cortados

**Status:** Concluído  
**Prioridade:** Alta — bugs visuais que afetam a legibilidade e jogabilidade  
**Escopo:** `scripts/weapons/drone.gd`, `scripts/player/player.gd`, `scenes/ui/hud.tscn`

---

## Problemas reportados

### 1. Drone invisível durante o jogo

**Sintoma:** Ao equipar o drone, ele dispara projeteis normalmente, mas não aparece nenhuma imagem durante o jogo — o sprite não está visível.

**Causa raiz:** Em `drone.gd`, o `Sprite3D` é criado no `_ready()` e adicionado como filho de `drone_mesh.get_parent()` (raiz do Node3D do drone), que fica fixo em `(0, 0, 0)`. O `_process()` atualiza `drone_area.position` e `drone_mesh.position` a cada frame para orbitar, mas o sprite nunca é movido — ele permanece estático na posição inicial.

**Correção:** Adicionar o sprite como filho de `drone_area` (em vez de `drone_mesh.get_parent()`). Como `drone_area.position` é atualizado a cada frame com a posição da órbita, o sprite passa a seguir automaticamente.

---

### 2. Barra de HP — barra preta crescendo ao lado da verde

**Sintoma:** Ao tomar dano, em vez da barra verde diminuir da direita para a esquerda, uma barra preta aparece grudada na verde e vai crescendo, tornando a barra total mais longa visualmente.

**Causa raiz:** A barra de preenchimento usa `scale.x` para encolher, mas é inicializada com `scale.x = 1.0` (padrão de qualquer nó). O `position.x` é ajustado a cada frame, mas o estado inicial (`position.x = 0` com `scale.x = 1.0`) pode gerar um frame de flash antes do lerp entrar em sincronia, revelando o fundo escuro de forma errada. Além disso, o highlight usa fator `0.75` em vez de `0.8`, desalinhando levemente.

**Correção:** Trocar a abordagem de `scale.x + position.x` por manipulação direta de `QuadMesh.size.x`. Isso é mais previsível — a borda esquerda da barra é sempre fixa, e a borda direita recua à medida que o HP cai. Sem artifacts de scale. O highlight recebe o mesmo tratamento.

---

### 3. Barra de XP — começa cheia (azul) em vez de vazia (preta)

**Sintoma:** Ao iniciar uma run, a barra de XP aparece completamente azul por um breve instante e depois colapsa para vazia. Deveria começar preta (vazia) e preencher com azul à medida que XP é ganho.

**Causa raiz:** A barra de fill do XP é criada com `scale.x = 1.0` (padrão do nó). O `_update_world_xp_bar()` leva alguns frames para lerpar até `0.0`. Nesse intervalo, a barra aparece completamente azul.

**Correção:** Inicializar `_world_xp_bar` com `mesh.size.x = 0` e `position.x = -bar_width/2` logo após criar o nó, para que a barra comece visualmente vazia.

---

### 4. Ícones de armas e itens cortados — só a metade superior aparece

**Sintoma:** Os ícones de armas (canto inferior esquerdo) e itens (canto inferior direito) aparecem cortados — só a metade de cima fica visível, e a metade de baixo cai fora da tela.

**Causa raiz:** Os painéis `WeaponPanel` e `ItemPanel` em `hud.tscn` têm `offset_top = -62`, o que dá apenas 62px de altura. Com ícone "large" (80px) + label (≈16px), o conteúdo tem ~96px — 34px a mais do que o painel comporta. Os ícones transbordam para baixo da viewport (720px) e ficam cortados.

**Correção:** Aumentar `offset_top` de `-62` para `-120` em ambos os painéis, dando 120px de espaço — suficiente para label + ícones grandes com margem.

---

## Arquivos alterados

| Arquivo | Mudança |
|---|---|
| `scripts/weapons/drone.gd` | Sprite adicionado como filho de `drone_area` |
| `scripts/player/player.gd` | HP bar: usa `mesh.size.x` em vez de `scale.x`; XP bar: inicializa vazia |
| `scenes/ui/hud.tscn` | `offset_top`: `-62` → `-120` em WeaponPanel e ItemPanel |

---

## Critérios de aceite

- [ ] Drone aparece orbitando o jogador durante o jogo
- [ ] Barra de HP começa cheia (verde) e encolhe da direita ao tomar dano, sem barra preta crescente
- [ ] Barra de XP começa preta (vazia) e preenche com azul da esquerda ao ganhar XP
- [ ] Ícones de armas e itens aparecem completamente visíveis nos cantos inferiores da tela
