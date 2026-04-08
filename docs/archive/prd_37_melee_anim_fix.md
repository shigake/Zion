# PRD 37 — Foice invisível + revisão de animações melee

**Status:** concluido  
**Prioridade:** alta  
**Escopo:** `game/scripts/weapons/scythe.gd` + revisão de todos os 11 scripts melee  

---

## Problema

Durante a jogatina, a **foice não aparece visualmente** — o jogador vê apenas os efeitos de impacto (partículas, números de dano) sem a arma em si. A impressão é de dano "invisível", o que quebra o feedback e a legibilidade do combate.

Além disso, o padrão de código que causa o bug na foice pode existir (com variações) nas outras 10 armas melee, tornando necessária uma revisão completa.

---

## Causa raiz — foice

O `scythe.gd` possui três estágios no `_ready()`:

1. **Trail** é adicionado como filho de `scythe_mesh` ✅ (correto — move com o mesh)
2. `scythe_mesh.visible = false` — o mesh de debug fica oculto ✅ (intencional)
3. **Sprite3D** é criado e adicionado com `scythe_mesh.get_parent().add_child(sprite)` ❌

O passo 3 é o bug: `get_parent()` retorna o nó raiz da cena (`Scythe`), que está **preso na posição do jogador**. A posição de órbita é aplicada apenas em `scythe_area` e `scythe_mesh` a cada frame — o sprite fica parado no centro, debaixo do personagem, nunca orbitando.

Resultado: o trail também fica invisível (é filho de `scythe_mesh` que está oculto) e o sprite fica na posição errada. Nada aparece.

### Solução correta para a foice

O sprite deve ser filho de `scythe_area` (o nó que realmente orbita):

```gdscript
# Antes (bugado)
scythe_mesh.get_parent().add_child(sprite)

# Depois (correto)
scythe_area.add_child(sprite)
```

Com isso, o sprite orbita junto com a área de colisão, mantendo sincronia visual e física.

O trail (`weapon_trail.gd`) também precisa ser filho de `scythe_area` ou de um nó filho dela, não de `scythe_mesh`.

---

## Revisão das outras armas melee

As 10 armas restantes usam o mesmo padrão `mesh.get_parent().add_child(sprite)`. Para armas de ataque (katana, martelo, etc.), o sprite fica no nó raiz — que não se move durante o ataque. O slash trail é o feedback visual principal nesses casos, então a ausência de animação do sprite pode ser aceitável — mas deve ser verificada arma por arma.

### Critérios de revisão por arma

| Arma | Tipo de animação | Verificar |
|---|---|---|
| **Foice** | Órbita contínua | Sprite e trail devem orbitar — bug confirmado |
| **Katana** | Arco durante ataque | Sprite deve acompanhar o arco de `slash_area` |
| **Katana dupla** | Arco duplo | Dois sprites devem acompanhar as duas áreas |
| **Martelo** | Expand/shockwave | Sprite deve pulsar com o slam |
| **Machado** | Boomerang (vai e volta) | Sprite deve seguir o projétil |
| **Chicote** | Arco 180° | Sprite deve acompanhar o arco |
| **Nunchaku** | Cone rápido | Sprite deve piscar no cone |
| **Lança** | Thrust linear | Sprite deve avançar com `lance_area` |
| **Luvas de boxe** | Combo 3 hits | Sprites dos dois punhos devem animar |
| **Cloud sword** | Arco 180° massivo | Sprite deve cobrir o arco visível |
| **Shadow claw** | Garras duplas | Sprites das duas garras devem animar |

---

## Comportamento esperado após a correção

### Foice
- A foice orbita visivelmente ao redor do jogador desde o início
- O sprite acompanha a rotação (`rotation.y = angle + PI/2`) — a lâmina aponta na direção do movimento
- O trail roxo aparece atrás da lâmina enquanto orbita
- Ao drenar vida, os wisps verdes partem da posição correta da foice (não do centro)
- Em todos os níveis (1–8), o raio e a velocidade crescem e permanecem visíveis

### Outras armas melee
- Cada arma tem pelo menos **um elemento visual claro** durante a animação de ataque
- Slash trails e sprites não ficam presos na posição 0,0,0 relativa ao jogador
- Armas de arco mostram o sprite percorrendo o arco visualmente
- Não há arma que cause dano "invisível" sem nenhum feedback visual de arma

---

## Arquivos a editar

| Arquivo | Mudança |
|---|---|
| `game/scripts/weapons/scythe.gd` | Sprite e trail como filhos de `scythe_area` |
| `game/scripts/weapons/katana.gd` | Verificar e corrigir posicionamento do sprite |
| `game/scripts/weapons/dual_katana.gd` | Verificar e corrigir |
| `game/scripts/weapons/hammer.gd` | Verificar e corrigir |
| `game/scripts/weapons/axe.gd` | Verificar e corrigir |
| `game/scripts/weapons/whip.gd` | Verificar e corrigir |
| `game/scripts/weapons/nunchaku.gd` | Verificar e corrigir |
| `game/scripts/weapons/lance.gd` | Verificar e corrigir |
| `game/scripts/weapons/boxing_gloves.gd` | Verificar e corrigir |
| `game/scripts/weapons/cloud_sword.gd` | Verificar e corrigir |
| `game/scripts/weapons/shadow_claw.gd` | Verificar e corrigir |

---

## Fora do escopo

- Criar novos sprites de armas (usam os existentes em `assets/sprites/weapons/`)
- Alterar dano, cooldown ou balanceamento de qualquer arma
- Modificar cenas `.tscn` (apenas scripts `.gd`)
- Criar novos efeitos de partícula

---

## Notas de implementação

- A foice é a única arma com animação **contínua e sempre ativa** (sem estado de ataque/idle). As demais são ativas apenas durante o swing.
- Para armas com dois meshes/áreas (dual_katana, boxing_gloves, shadow_claw), cada sprite deve seguir seu respectivo nó de área.
- Manter compatibilidade com o fallback: se o sprite não existir (`ResourceLoader.exists` retorna false), a arma continua funcional sem sprite — sem erros.
