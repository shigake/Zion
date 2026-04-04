# PRD 48 — Garrafa de Veneno: efeito 3D (sem pixel art)

## Status
Pendente

## Problema

A Garrafa de Veneno usa dois sprites pixel art (`poison_cloud.png`, `poison_puddle.png`) como visuais principais da poça de veneno. Em um jogo 3D, sprites billboard quebram a imersão — especialmente um efeito que fica parado no chão por até 8s.

Causa raiz em `poison_bottle.gd`:
- `Sprite3D "poison_cloud.png"` (billboard y=0.5) — nuvem flutuante
- `Sprite3D "poison_puddle.png"` (flat no ground, rotação x=-PI/2) — poça
- `CylinderMesh` fallback existe mas nunca é visível quando sprites carregam

## Solução

Substituir os dois sprites por geometria 3D pura, mantendo o custo de vértices baixo.

### Poça (ground puddle)
- `CylinderMesh` `top_radius = area_radius`, `height = 0.04` (disco fino)
- Material: `StandardMaterial3D`, cor verde-tóxico `(0.1, 0.6, 0.15)`, `transparency = ALPHA`, `alpha_scissor_threshold = 0.1`
- Emissão fraca `(0.05, 0.4, 0.1)` × 0.6
- Textura procedural: `NoiseTexture2D` (FastNoiseLite, tamanho 64×64) no canal ROUGHNESS para dar aparência de líquido borbulhante sem custo de shader custom

### Nuvem tóxica (volumetric)
- `GPUParticles3D` estacionário, `emission_shape = SPHERE` raio = `area_radius * 0.7`
- 18 partículas, lifetime 2.0s, `local_coords = false`
- Mesh: `SphereMesh` radius 0.12, subdivisions 2
- Cor: gradiente verde `(0.2, 0.8, 0.2, 0.6)` → transparente
- `gravity = Vector3(0, 0.15, 0)` — partículas sobem lentamente
- `initial_velocity_min = 0.05`, `initial_velocity_max = 0.2`

### Bolhas (mantidas, melhoradas)
- Manter `GPUParticles3D` bolhas existentes
- Reduzir de 20 → 12 partículas
- Aumentar `SphereMesh` radius de 0.05 → 0.08 (mais visível)

## Arquivos a modificar

| Arquivo | O que muda |
|---|---|
| `game/scripts/weapons/poison_bottle.gd` | Remover setup dos 2 Sprite3D; criar CylinderMesh disco + ajustar GPUParticles3D cloud |
| `game/scripts/weapons/poison_pool_behavior.gd` | Remover referências a `sprite_cloud` e `sprite_puddle`; atualizar animação de pulsação para o disco |
| `game/assets/` | Remover referências a `poison_cloud.png` e `poison_puddle.png` (manter arquivos, apenas não usar) |

## Performance

| Aspecto | Antes | Depois |
|---|---|---|
| Draw calls por poça | 3 (2 sprites + disco) | 2 (disco + cloud particles) |
| Partículas cloud | 14 | 18 → mas com SphereMesh menor |
| Bolhas | 20 | 12 |
| Sprites billboard | 2 | 0 |

- Máximo de poças simultâneas: `3 + int((level-1)/2)` — mantido
- Disco CylinderMesh: compartilhar instância via `static var _shared_puddle_mesh` se `level` igual

## Critérios de aceite

- [ ] Nenhum Sprite3D usado no efeito da poça de veneno
- [ ] Disco no chão visível e alinhado com o raio real de dano (Area3D SphereShape3D)
- [ ] Nuvem tóxica visível acima da poça com movimento vertical suave
- [ ] Sem queda de FPS com 3+ poças simultâneas no mapa
- [ ] Pulsação de escala (0.95–1.08) continua funcionando no CylinderMesh
- [ ] Sistema de sinergia elemental continua registrando a zona corretamente
