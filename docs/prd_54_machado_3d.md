# PRD 54 — Machado Viking: modelo 3D completo (sem sprite fallback)

## Status
Pendente

## Problema

O Machado Viking tem um mesh 3D procedural (`BoxMesh` lâmina + `CylinderMesh` cabo) mas também mantém um `Sprite3D "axe_thrown.png"` como fallback. O problema é que o mesh procedural tem proporções incorretas — a lâmina `BoxMesh(0.02 x 0.2 x 0.15)` é fina demais e não parece um machado viking robusto. Isso faz o fallback ser preferido quando o sprite carrega.

Causa raiz em `axe.gd`:
- `BoxMesh blade: 0.02 × 0.2 × 0.15` — muito fino no eixo X
- `CylinderMesh handle` existe mas proporcional errado
- Sprite3D fallback `"axe_thrown.png"` ainda carregado como backup

## Solução

Redesenhar o mesh 3D do machado para ser robusto e remover o sprite completamente.

### 1. Lâmina (blade) — redesenhada
- Substituir `BoxMesh` por `PrismMesh` (forma triangular mais agressiva):
  - `size = Vector3(0.18, 0.42, 0.06)` — larga, alta, com espessura
  - Posição: `y = 0.05`, `z = 0.0` (centralizado no cabo)
- Material: aço com patina de combate:
  - Albedo: `(0.55, 0.52, 0.50)` — metal frio
  - `metallic = 0.85`, `roughness = 0.35`
  - Emissão fraca `(0.9, 0.45, 0.1)` × 0.4 (reflexo de fogo — fire damage type)

### 2. Cabo (handle) — melhorado
- `CylinderMesh`: `top_radius = 0.025`, `bottom_radius = 0.03`, `height = 0.65`
- Posição: `y = -0.28` (abaixo da lâmina)
- Material: madeira nórdica `(0.28, 0.16, 0.06)`, `roughness = 0.9`
- Adorno no topo: `SphereMesh radius = 0.04`, mesmo material da lâmina (enfeite de metal)

### 3. Entalhe rúnico (detail)
- `BoxMesh size = Vector3(0.03, 0.12, 0.08)` sobre a lâmina
- Posição levemente à frente `z = 0.04`
- Material: emissão laranja `(1.0, 0.4, 0.05)` × 0.8 (runa brilhando)
- Cria o detalhe visual que diferencia o machado de outros melee

### Animação de voo
- Rotação Z: `+= 15.0 * delta` (mantido — gira no voo)
- No return (boomerang), inverter: `-= 15.0 * delta`
- Todo o mesh pai gira, as 4 partes como filhos

### Fire trail
- Manter trail existente `(1.0, 0.5, 0.1)` orange com 16 pontos
- Aumentar `width = 0.20` (era 0.15) para combinar com o machado maior

## Arquivos a modificar

| Arquivo | O que muda |
|---|---|
| `game/scripts/weapons/axe.gd` | Remover Sprite3D setup; redesenhar `_create_axe_mesh()` com PrismMesh + CylinderMesh + BoxMesh + SphereMesh |
| `game/scenes/weapons/axe.tscn` | Remover Sprite3D node |

## Performance

| Aspecto | Antes | Depois |
|---|---|---|
| Sprites billboard | 1 (fallback) | 0 |
| Meshes | 2 (blade box + handle cyl) | 4 (blade prism + handle + cap + rune) |
| Vértices estimados | ~40 | ~180 (ainda muito baixo) |
| Static meshes | Não | `static var` para cada parte |

- `static var _shared_blade_mesh`, `_shared_handle_mesh`, `_shared_cap_mesh`, `_shared_rune_mesh`
- `PrismMesh` é um primitive nativo do Godot 4 — sem custo adicional vs BoxMesh
- Trail width levemente maior: impacto mínimo (já existia)
- Hit tracking (2 arrays: outward + return) mantidos
- Boomerang flight 0.6s out + 0.6s return mantido

## Critérios de aceite

- [ ] Nenhum Sprite3D no machado viking
- [ ] Lâmina larga e robusta visível de todos os ângulos
- [ ] Cabo e adorno de metal visíveis
- [ ] Runa laranja brilhando na lâmina
- [ ] Giro contínuo durante o voo (ida e volta)
- [ ] Boomerang mechanic funcionando (acerta na ida e na volta)
- [ ] Trail de fogo com largura aumentada
- [ ] Fire damage type mantido nas colisões
