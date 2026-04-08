# PRD 50 — Totem Elétrico: modelo 3D (sem pixel art)

## Status
Pendente

## Problema

O Totem Elétrico é a arma com **maior dependência de pixel art** entre todas as AoE:
- `Sprite3D "totem.png"` — corpo do totem inteiro é um sprite billboard
- 3× `Sprite3D "lightning_bolt.png"` — raios orbitando são sprites billboard

Resultado: em 3D, o totem parece um papel grudado no chão que sempre olha para a câmera. A falta de volumetria o faz parecer um placeholder.

Causa raiz em `totem.gd`: sem nenhuma geometria 3D para o corpo — 100% sprite.

## Solução

Construir o totem inteiramente em 3D procedural, em 4 partes:

### 1. Base (estaca no chão)
- `CylinderMesh`: `top_radius = 0.06`, `bottom_radius = 0.10`, `height = 0.6`
- Posição: `y = 0.3`
- Material: marrom madeira `(0.35, 0.2, 0.08)`, `roughness = 0.85`, `metallic = 0.0`

### 2. Orbe central (cristal elétrico)
- `SphereMesh`: `radius = 0.22`, `radial_segments = 8`, `rings = 4` (low-poly intencional)
- Posição: `y = 0.85`
- Material: `StandardMaterial3D`, cor azul-elétrico `(0.3, 0.7, 1.0)`, `transparency = ALPHA`, `alpha = 0.85`
- Emissão: `(0.4, 0.8, 1.0)` × 2.0
- Animação: `scale` pulsa via Tween loop `1.0 → 1.12 → 1.0` em 0.8s (heartbeat elétrico)

### 3. Arco elétrico (substituir sprites de raio)
- 3× `MeshInstance3D` com `ImmediateMesh` (linha procedural zigzag)
- Cada arco: raio de órbita `orbit_radius = damage_radius * 0.5`, height bob `sin(3.0*t)` (mantido)
- Zigzag: 6 pontos com offset aleatório `±0.06` por frame (relâmpago vivo)
- Material: `SHADING_UNSHADED`, `no_depth_test = true`, cor `(0.6, 0.9, 1.0)`
- Regenerar a geometria do zigzag a **cada 3 frames** (não todo frame)

### 4. Anel de área visual
- `TorusMesh`: `inner_radius = damage_radius - 0.05`, `outer_radius = damage_radius`, `ring_sections = 6`
- Material: `alpha = 0.12`, emissão azul fraca `(0.2, 0.5, 1.0)` × 0.3
- Posição: `y = 0.02` (quase no chão)
- Indica visualmente o raio de dano

## Arquivos a modificar

| Arquivo | O que muda |
|---|---|
| `game/scripts/weapons/totem.gd` | Remover todos os 4 Sprite3D; criar base + orbe + 3 arcos ImmediateMesh + torus de área |
| `game/scripts/weapons/totem_behavior.gd` | Atualizar referências de modulate para emissão no material do orbe |
| `game/scenes/weapons/totem.tscn` | Remover nodes Sprite3D |

## Performance

| Aspecto | Antes | Depois |
|---|---|---|
| Sprites billboard | 4 (1 corpo + 3 raios) | 0 |
| Draw calls | 4 sprites | 4 meshes (base + orbe + torus + arcos batch) |
| Atualização por frame | sin/cos modulate 3 sprites | ImmediateMesh rebuild a cada 3 frames |
| Max totens simultâneos | 2 (level ≥ 5) | 2 — mantido |

- `ImmediateMesh` para arcos: zero alocação de texture, apenas vértices
- Tween loop no orbe: custo zero por frame após criado
- Anel `TorusMesh`: estático — criado uma vez, nunca atualizado
- `ring_sections = 6` mantém polígonos mínimos

## Narrativa

O Totem é um artefato de Zion plantado no chão — um cristal de energia dimensional preso numa estaca de madeira antiga. O orbe pulsante é o fragmento de cristal emanando ressonância elétrica. Cada raio que orbita é energia se dissipando na realidade corrompida da fenda.

## Critérios de aceite

- [ ] Nenhum Sprite3D usado no totem
- [ ] Corpo do totem visível de qualquer ângulo de câmera (não billboard)
- [ ] Orbe central pulsando continuamente
- [ ] 3 arcos elétricos orbitando com movimento zigzag
- [ ] Anel de área indicando o raio de dano
- [ ] Dano por tick continua correto (Area3D SphereShape3D)
- [ ] FPS estável com 2 totens ativos
