# PRD 49 — Tornado: efeito 3D (sem pixel art)

## Status
Pendente

## Problema

O Tornado usa `Sprite3D "tornado.png"` billboard como visual principal, com um `CylinderMesh` cone como fallback. Mas o fallback é um cilindro simples sem qualquer impressão de rotação ou vórtice. Em um jogo 3D, um sprite 2D girando não transmite a profundidade de um vórtice real.

Causa raiz em `tornado.gd`:
- `Sprite3D "tornado.png"` (billboard, `pixel_size = 0.04`, `TEXTURE_FILTER_NEAREST`) como visual primário
- `CylinderMesh` cone como fallback inativo quando sprite carrega
- Partículas de vórtice e detritos existem mas são pontos muito pequenos (0.06 / 0.04 raio)

## Solução

Substituir o sprite por um vórtice 3D procedural com três camadas:

### Camada 1 — Cone de vórtice (geometria base)
- `CylinderMesh` já existente, mas com ajustes:
  - `top_radius = 0.08`, `bottom_radius = area_radius * 0.6`, `height = 2.2`
  - Material: `StandardMaterial3D`, cor azul-gelo `(0.5, 0.8, 1.0)`, `transparency = ALPHA`, `alpha = 0.28`
  - `cull_mode = CULL_DISABLED` (visível de dentro e fora)
  - Emissão fraca `(0.3, 0.6, 1.0)` × 0.4
- Animação: rotação Y += `12.0 * delta` (gira constantemente)

### Camada 2 — Faixa espiral (ribbon)
- Segundo `CylinderMesh`, metade da altura, `top_radius = 0.04`, `bottom_radius = area_radius * 0.4`
- Rotação Y oposta ao cone principal (`-8.0 * delta`) — contra-rotação cria ilusão de espiral
- Alpha 0.18, cor mais clara `(0.7, 0.9, 1.0)`

### Camada 3 — Partículas de detritos melhoradas
- Manter `GPUParticles3D` existente, mas:
  - Aumentar mesh de debris: `BoxMesh(0.08, 0.08, 0.08)` (era 0.04)
  - Aumentar mesh de vórtice: `SphereMesh radius = 0.10` (era 0.06)
  - Spawn rate: every 4 frames (mantido)
  - Adicionar `radial_velocity_min = 1.5`, `radial_velocity_max = 3.0` para órbita real

## Arquivos a modificar

| Arquivo | O que muda |
|---|---|
| `game/scripts/weapons/tornado.gd` | Remover Sprite3D; criar 2 CylinderMesh com rotações opostas; aumentar mesh das partículas |
| `game/scenes/weapons/tornado.tscn` | Limpar referência ao Sprite3D |

## Performance

| Aspecto | Antes | Depois |
|---|---|---|
| Sprites billboard | 1 | 0 |
| CylinderMesh | 1 (fallback) | 2 (cone + ribbon) |
| Debris mesh size | 0.04 | 0.08 (mais visível, mesmo count) |
| Shared mesh | Sim (_shared_box_mesh) | Expandir para os 2 novos meshes |

- `static var _shared_cone_mesh: CylinderMesh` e `_shared_ribbon_mesh: CylinderMesh` — compartilhados entre todos os tornados ativos
- FPS throttling mantido (35-40 FPS check para spawn de partículas)
- Rotação Y calculada em `_process` usando `delta` — zero custo de física

## Critérios de aceite

- [ ] Nenhum Sprite3D usado no visual do tornado
- [ ] Dois cilindros com rotações opostas visíveis e alinhados em y
- [ ] Detritos orbitando visivelmente ao redor do vórtice
- [ ] Giro contínuo fluido sem stuttering
- [ ] FPS estável com 2 tornados simultâneos
- [ ] Pull mechanic de inimigos continua funcionando normalmente
