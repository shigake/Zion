# PRD 07 — Armas melee sem sprite e sem efeito

## Problema
Todas as 12 armas melee estao invisiveis no jogo — sem sprite da arma e sem efeito visual de ataque.

## Causa raiz
**Os sprites sao placeholders minusculos** (~200-400 bytes cada). O codigo de carregamento funciona perfeitamente, mas as imagens sao stubs de 1-2 pixels — invisiveis no jogo.

Mesma situacao para os sprites de slash/efeito de ataque.

## Lista das 12 armas melee
| # | ID | Nome | Sprite atual | Slash sprite atual |
|---|-----|------|-------------|-------------------|
| 1 | `katana` | Espada Samurai | 203 bytes (stub) | `katana_slash.png` 229 bytes |
| 2 | `scythe` | Foice | 195 bytes (stub) | `scythe_slash.png` 324 bytes |
| 3 | `shadow_claw` | Shadow Claw | 196 bytes (stub) | `shadow_claw_slash.png` 318 bytes |
| 4 | `magic_book` | Livro Magico | 275 bytes (stub) | N/A (usa projeteis) |
| 5 | `whip` | Chicote | 204 bytes (stub) | `whip_crack.png` 224 bytes |
| 6 | `lance` | Lanca | 217 bytes (stub) | `lance_thrust.png` 205 bytes |
| 7 | `hammer` | Martelo | 197 bytes (stub) | `hammer_slam.png` 407 bytes |
| 8 | `nunchaku` | Nunchaku | 233 bytes (stub) | `nunchaku_swing.png` 206 bytes |
| 9 | `dual_katana` | Katana Dupla | 183 bytes (stub) | `dual_katana_slash.png` 258 bytes |
| 10 | `cloud_sword` | Espada Cloud | 270 bytes (stub) | `cloud_sword_wave.png` 235 bytes |
| 11 | `boxing_gloves` | Luvas de Boxe | 198 bytes (stub) | `boxing_punch.png` 272 bytes |
| 12 | `chain_whip` | Chicote Eletrico | 309 bytes (stub) | `chain_whip_slash.png` 365 bytes |

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `assets/sprites/weapons/*.png` | 12 sprites de arma (todos stubs) |
| `assets/sprites/effects/slashes/*.png` | 11 sprites de slash (todos stubs) |
| `scripts/weapons/*.gd` | Cada arma carrega sprite em `_ready()` via billboard Sprite3D |
| `scripts/weapons/weapon_vfx.gd` | `WeaponVFX.spawn_slash_trail()` — spawna sprite de slash |
| `scripts/autoload/weapon_db.gd` | Definicoes das armas |
| `scripts/tools/` | Geradores de sprites existentes |

## Como os sprites sao usados (codigo ja funciona)
Cada arma em `_ready()`:
```gdscript
var _sprite_path = "res://assets/sprites/weapons/{weapon_id}.png"
if ResourceLoader.exists(_sprite_path):
    var sprite = Sprite3D.new()
    sprite.texture = load(_sprite_path)
    sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    sprite.pixel_size = 0.03
    sprite.shaded = false
    sprite.transparent = true
```

Slash em ataque:
```gdscript
WeaponVFX.spawn_slash_trail(self, slash_texture, pos, 0.03, 1.2, 0.18)
```

## Plano de implementacao

### Passo 1 — Gerar sprites de arma (24 arquivos)
Usar os geradores existentes em `scripts/tools/` ou criar novos sprites pixel art.

**12 sprites de arma** (`assets/sprites/weapons/`):
- Formato: PNG com fundo transparente (RGBA)
- Tamanho: 64x64 ou 128x128 pixels
- Estilo: Pixel art top-down, silhueta clara e reconhecivel
- `pixel_size = 0.03` no codigo — 64px = ~1.9 unidades no mundo

Especificacoes por arma:
1. **katana.png** — Katana japonesa, lamina curva, guarda circular
2. **scythe.png** — Foice grande, lamina curvada, cabo longo
3. **shadow_claw.png** — Garra escura/roxa, 3 dedos afiados
4. **magic_book.png** — Livro aberto com brilho magico azul/roxo
5. **whip.png** — Chicote enrolado, marrom/vermelho
6. **lance.png** — Lanca longa, ponta metalica
7. **hammer.png** — Martelo de guerra pesado, cabeca grande
8. **nunchaku.png** — Nunchaku com corrente, dois bastoes
9. **dual_katana.png** — Duas katanas cruzadas
10. **cloud_sword.png** — Espadao enorme estilo Cloud/Buster Sword
11. **boxing_gloves.png** — Par de luvas de boxe vermelhas
12. **chain_whip.png** — Chicote com corrente eletrica, brilho azul

**11 sprites de slash** (`assets/sprites/effects/slashes/`):
- Formato: PNG com fundo transparente
- Tamanho: 64x64 ou 128x128 pixels
- Estilo: Efeito de ataque semi-transparente, cores do trail da arma

1. **katana_slash.png** — Arco branco/azul, meia-lua
2. **scythe_slash.png** — Arco verde/escuro, curvado
3. **shadow_claw_slash.png** — 3 linhas roxas/escuras paralelas
4. **whip_crack.png** — Linha ondulada marrom com ponta brilhante
5. **lance_thrust.png** — Linha reta com ponta afiada
6. **hammer_slam.png** — Circulo de impacto com rachaduras
7. **nunchaku_swing.png** — Arco laranja, cone
8. **dual_katana_slash.png** — X formado por dois cortes
9. **cloud_sword_wave.png** — Onda grande azul, 180 graus
10. **boxing_punch.png** — Estrela de impacto amarela/laranja
11. **chain_whip_slash.png** — Raio/corrente eletrica azul

### Passo 2 — Substituir arquivos
Substituir os 23 PNGs stub pelos novos sprites. **Nenhuma mudanca de codigo necessaria** — o pipeline visual inteiro ja esta pronto.

### Passo 3 — Ajustar pixel_size se necessario
Se os sprites ficarem grandes/pequenos demais, ajustar `pixel_size` nos scripts de cada arma (atualmente 0.03).

## O que JA funciona (nao precisa mudar)
- Billboard sprite creation e positioning
- Slash trail spawning durante ataques (WeaponVFX)
- Weapon trail animations (gradientes de cor)
- Particle effects (sparks, wisps, dust)
- Screen shake/flash feedback
- Chain linking e impact flashes
- Toda a mecanica de dano e gameplay

## Validacao
- [ ] Cada arma melee mostra seu sprite visivel no jogo
- [ ] Sprite acompanha o jogador (billboard)
- [ ] Ao atacar, efeito de slash aparece
- [ ] Sprites sao claros e reconheciveis a distancia de gameplay
- [ ] Tamanho proporcional (nao gigante nem minusculo)
