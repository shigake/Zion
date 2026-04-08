# PRD 53 — Cajado de Gelo: projétil e cristais 3D (sem pixel art)

## Status
Pendente

## Problema

O Cajado de Gelo usa `Sprite3D` billboard para o projétil de gelo. O impacto já gera cristais 3D procedurais (bom), mas o projétil em si — a parte que o jogador vê voando pelo ar — é um sprite 2D. Isso é particularmente perceptível porque o projétil é lento (velocity 10.0) e fica visível por muito tempo em tela.

Causa raiz em `ice_staff_projectile.gd`:
- Sprite3D setup para o projétil (file não detalhado mas padrão do sistema)
- Cristais de congelamento já usam `BoxMesh` procedural — bom

## Solução

### Projétil de gelo (substituir sprite)
- `MeshInstance3D` com forma de cristal hexagonal:
  - Base: `CylinderMesh` `top_radius = 0.0`, `bottom_radius = 0.10`, `height = 0.3` (cone frontal)
  - Cauda: `CylinderMesh` `top_radius = 0.10`, `bottom_radius = 0.0`, `height = 0.15` (cone traseiro menor)
  - Posição relativa: `z = -0.075` (cauda) e `z = +0.075` (ponta) — forma de diamante/cristal
- Material: azul-gelo `(0.4, 0.75, 1.0)`, `transparency = ALPHA`, `alpha = 0.88`
- Emissão: `(0.3, 0.7, 1.0)` × 1.8
- `metallic = 0.4`, `roughness = 0.1` (aparência cristalina)
- Rotação Z: `+= 6.0 * delta` (gira no eixo de voo)

### Rastro de gelo (trail)
- Adicionar `GPUParticles3D` ao projétil, emissão contínua durante o voo:
  - 6 partículas, lifetime 0.4s
  - Mesh: `SphereMesh radius = 0.04`
  - Cor: gradiente `(0.5, 0.85, 1.0, 0.7)` → transparente
  - `emission_shape = POINT`, `initial_velocity = 0.3` para trás
  - `gravity = Vector3(0, 0.2, 0)` (rastro sobe levemente)

### Cristais de congelamento (manter + melhorar)
- Manter `BoxMesh` random existente para cristais
- Aumentar range de altura: `0.2 → 0.5` (era 0.15 → 0.35) — mais imponentes
- Aumentar range de largura: `0.04 → 0.10` (era 0.03 → 0.06)
- Adicionar emissão: `(0.4, 0.8, 1.0)` × 0.8 nos cristais

### Névoa de congelamento
- Manter `GPUParticles3D` frost mist
- Aumentar partículas de 12 → 16
- Aumentar raio de emissão de 1.5 → `freeze_radius * 0.8`

## Arquivos a modificar

| Arquivo | O que muda |
|---|---|
| `game/scripts/weapons/ice_staff_projectile.gd` | Remover Sprite3D; criar 2 cones MeshInstance3D + trail GPUParticles3D |
| `game/scripts/weapons/ice_staff.gd` | Ajustar criação do projétil se setup for feito no parent |
| `game/scenes/weapons/ice_staff.tscn` | Remover Sprite3D do projétil se no scene |

## Performance

| Aspecto | Antes | Depois |
|---|---|---|
| Sprites billboard (projétil) | 1 | 0 |
| Meshes projétil | 0 | 2 (dois cones = forma diamante) |
| Trail particles | Nenhum no projétil | 6 partículas (lifetime 0.4s) |
| Cristais freeze | BoxMesh random (count 5-8) | BoxMesh random (count 5-8, maior) |

- ObjectPool para projétil mantido — sem alocação por disparo
- Trail `one_shot = false`, `emitting = true` durante voo, `emitting = false` ao impactar
- `static var _shared_front_cone`, `_shared_back_cone` — compartilhados por projéteis simultâneos
- Max projéteis: controlado por cooldown do WeaponDB
- Slow effect (40% speed) continua inalterado

## Critérios de aceite

- [ ] Nenhum Sprite3D no projétil de gelo
- [ ] Projétil visível como cristal 3D girando em voo
- [ ] Rastro de partículas azul-gelo acompanhando o projétil
- [ ] Cristais de congelamento mais altos e visíveis ao impactar
- [ ] Raio de congelamento visual (névoa) correspondendo ao raio real
- [ ] Slow effect de 40% continua aplicado corretamente
- [ ] ObjectPool funcionando (sem crash em disparos rápidos)
