# PRD 52 — Lança: modelo 3D (sem pixel art)

## Status
Pendente

## Problema

A Lança usa `Sprite3D "lance.png"` como corpo visual da arma — um sprite 2D dourado que rotaciona com o jogador. Sendo uma arma melee de thrust linear, o sprite pode funcionar de frente mas fica claramente 2D ao olhar de ângulo.

Causa raiz em `lance.gd`:
- `Sprite3D "lance.png"` (`pixel_size = 0.050`, BILLBOARD_Y_AXIS)
- `BoxMesh ThrustMesh` existe mas é só a hitbox visual de debug (não o visual da arma)
- Trail usa cor dourada `(1.0, 0.9, 0.35)` — manter paleta

## Solução

Substituir o sprite por um mesh procedural de lança em 3 partes:

### 1. Cabo (shaft)
- `CylinderMesh`: `top_radius = 0.025`, `bottom_radius = 0.025`, `height = 1.6`
- Material: madeira escura `(0.3, 0.18, 0.08)`, `roughness = 0.9`, `metallic = 0.0`
- Posição: `z = -0.5` (metade atrás do player)

### 2. Ponta (blade)
- `CylinderMesh`: `top_radius = 0.0`, `bottom_radius = 0.07`, `height = 0.45`
- Posição: `z = -1.45` (ponto mais distante)
- Material: ouro metálico `(0.85, 0.75, 0.2)`, `metallic = 0.9`, `roughness = 0.15`
- Emissão `(1.0, 0.9, 0.35)` × 0.8 (assinatura dourada da lança)
- Rotação X: `PI` (ponta apontando para frente)

### 3. Protetor de mão (cross-guard)
- `BoxMesh`: `size = Vector3(0.35, 0.04, 0.04)` (barra horizontal)
- Posição: `z = -0.15`
- Material: ouro metálico igual à ponta
- Emissão moderada `(1.0, 0.9, 0.35)` × 0.5

### Animação de thrust
- Manter o `Tween` existente de `z: 0.0 → -2.0 em 0.25s`
- O mesh completo (cabo + ponta + cross-guard como nó pai) executa o thrust
- Sparks dourados no impacto: manter (7 particles por hit)

## Arquivos a modificar

| Arquivo | O que muda |
|---|---|
| `game/scripts/weapons/lance.gd` | Remover Sprite3D setup; criar `_setup_lance_mesh()` com 3 MeshInstance3D |
| `game/scenes/weapons/lance.tscn` | Remover Sprite3D node |

## Performance

| Aspecto | Antes | Depois |
|---|---|---|
| Sprites billboard | 1 | 0 |
| Meshes | 1 (hitbox) | 3 (cabo + ponta + cross-guard) |
| Vértices estimados | 0 (sprite) | ~120 (3 meshes low-poly) |
| Static meshes | Não | `static var` para cada parte |

- `static var _shared_shaft_mesh`, `_shared_blade_mesh`, `_shared_guard_mesh` — compartilhados por todas as lances
- Trail (20 pontos, width 0.35) mantido — maior custo visual, já otimizado
- Slash trail texture `lance_thrust.png` mantida (é o rastro do golpe, não o modelo)
- Attack duration 0.25s mantido

## Narrativa

A Lança do Ronin é um fragmento de cristal de Zion moldado em arma — a ponta dourada é o próprio cristal comprimido, emanando ressonância dimensional. O cabo de madeira vem do Santuário Florestal, a primeira fenda a ser restaurada.

## Critérios de aceite

- [ ] Nenhum Sprite3D usado como corpo da lança
- [ ] Mesh 3D de lança visível de todos os ângulos
- [ ] Thrust animation (avanço z) funcionando no mesh
- [ ] Ponta dourada com emissão correspondendo à paleta da arma
- [ ] Trail dourado continua funcionando normalmente
- [ ] Hitbox Area3D (BoxShape3D) sem alteração no tamanho
- [ ] Auto-aim para nearest enemy continua funcionando
