# PRD 51 — Orbe de Sangue: modelo 3D (sem pixel art)

## Status
Pendente

## Problema

O Orbe de Sangue usa `Sprite3D "blood_orb.png"` billboard como visual principal. O orbe é um dos efeitos mais marcantes narrativamente (vampirismo — drena vida e cura o Fragmentado), mas visualmente parece um adesivo 2D flutuando.

Causa raiz em `blood_orb.gd`:
- `Sprite3D "blood_orb.png"` (billboard, `pixel_size = 0.03`) — corpo principal
- `SphereMesh` fallback (0.4 raio) existe mas nunca é ativado quando sprite carrega

## Solução

Substituir o sprite por geometria 3D em 3 camadas concêntricas, mais wisps e efeitos de drenagem melhorados.

### Camada 1 — Esfera de sangue (núcleo)
- `SphereMesh`: `radius = 0.32`, `radial_segments = 10`, `rings = 5`
- Material: vermelho-sangue profundo `(0.55, 0.04, 0.08)`, `metallic = 0.3`, `roughness = 0.2`
- Emissão: `(0.9, 0.05, 0.1)` × 1.5
- Animação heartbeat: `scale` `1.0 → 1.15 → 1.0` com `abs(sin(5.0*t)) * 0.15` (mantido do código atual)

### Camada 2 — Casca translúcida (aura de sangue)
- `SphereMesh`: `radius = 0.44`, `radial_segments = 8`, `rings = 4`
- Material: vermelho mais suave `(0.7, 0.1, 0.15)`, `transparency = ALPHA`, `alpha = 0.22`
- `cull_mode = CULL_DISABLED` (visível de dentro)
- Emissão `(0.8, 0.1, 0.1)` × 0.5
- Rotação Y lenta: `+= 0.8 * delta`

### Camada 3 — Gotas de sangue orbitando (substituir trail particles)
- 4× `MeshInstance3D` com `SphereMesh radius = 0.05`
- Cada gota orbita em plano inclinado diferente (`sin/cos` com offset de fase)
- Raio de órbita: `0.55 + sin(t * 2.0) * 0.1` (órbita elíptica dinâmica)
- Material: mesmo do núcleo, emissão × 2.0
- Spawn via `static var _shared_droplet_mesh` compartilhado

### Drain line melhorada
- Manter sistema de droplets animados existente (max 5 por call)
- Aumentar `SphereMesh` dos wisps de drenagem de `0.03` → `0.06` raio
- Cor dos wisps de cura: manter verde `(0.2, 1.0, 0.3)` — bom contraste

## Arquivos a modificar

| Arquivo | O que muda |
|---|---|
| `game/scripts/weapons/blood_orb.gd` | Remover Sprite3D; criar núcleo + casca + 4 gotas orbitantes |
| `game/scenes/weapons/blood_orb.tscn` | Remover node Sprite3D |

## Performance

| Aspecto | Antes | Depois |
|---|---|---|
| Sprites billboard | 1 | 0 |
| Meshes por orbe | 1 (fallback) | 3 (núcleo + casca + 4 gotas = 6 nodes) |
| Trail particles | SphereMesh 0.04 cada | SphereMesh 0.05, compartilhado |
| Drain wisps | 2-3 por call | 2-3 por call (mantido) |

- `_shared_droplet_mesh` evita alocação por instância de gota
- Wisps throttle `0.15s` mantido
- `_drain_line_throttle` 0.3s mantido
- Rotação da casca: apenas Y, zero custo
- Orbe lifetime `8.0 + level * 2.0` — sem mudança

## Narrativa

O Orbe de Sangue é um fragmento de cristal de Zion corrompido pelo vampirismo do Fragmentado Vampiro. Em vez de ressoar luz pura, ressoa com a força vital dos Sentinelas corrompidos — drenando sua essência dimensional para reparar o Fragmentado.

## Critérios de aceite

- [ ] Nenhum Sprite3D usado no orbe
- [ ] Núcleo esférico vermelho visível de todos os ângulos
- [ ] Casca translúcida girando lentamente
- [ ] 4 gotas de sangue orbitando o orbe
- [ ] Heartbeat animation (`abs(sin)`) contínua no núcleo
- [ ] Drain lines e wisps de cura funcionando normalmente
- [ ] Lifesteal calculado corretamente (dano × 0.05 × level)
