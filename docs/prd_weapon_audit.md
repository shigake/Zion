# PRD: Auditoria de Armas — Ícones e Efeitos Visuais

**Status**: ✅ Concluído
**Prioridade**: Alta
**Fase**: C (Polish)

## Contexto

O jogo possui 32 armas registradas no WeaponDB. Cada arma deve ter:
1. **Ícone SVG** em `game/assets/icons/weapons/{id}.svg` — exibido em menus e UI
2. **Sprite PNG** em `game/assets/sprites/weapons/{id}.png` — billboard in-game
3. **Efeito visual de ataque** — slash sprite, projetil, ou efeito procedural durante o gameplay

Foi identificado que algumas armas estão sem ícone SVG e/ou sem efeito de ataque dedicado, usando fallbacks genéricos.

## Auditoria Completa — 32 Armas

### Ícones SVG (`game/assets/icons/weapons/`)

| # | Arma | Ícone SVG | Status |
|---|------|-----------|--------|
| 1 | katana | katana.svg | ✅ |
| 2 | staff | staff.svg | ✅ |
| 3 | scythe | scythe.svg | ✅ |
| 4 | machinegun | machinegun.svg | ✅ |
| 5 | bazooka | bazooka.svg | ✅ |
| 6 | necro | necro.svg | ✅ |
| 7 | axe | axe.svg | ✅ |
| 8 | shadow_claw | shadow_claw.svg | ✅ |
| 9 | drone | drone.svg | ✅ |
| 10 | totem | totem.svg | ✅ |
| 11 | poison_bottle | poison_bottle.svg | ✅ |
| 12 | lightning_chain | lightning_chain.svg | ✅ |
| 13 | magic_book | magic_book.svg | ✅ |
| 14 | whip | whip.svg | ✅ |
| 15 | lance | lance.svg | ✅ |
| 16 | hammer | hammer.svg | ✅ |
| 17 | nunchaku | nunchaku.svg | ✅ |
| 18 | dual_katana | dual_katana.svg | ✅ |
| 19 | dual_pistol | dual_pistol.svg | ✅ |
| 20 | flamethrower | flamethrower.svg | ✅ |
| 21 | ice_staff | ice_staff.svg | ✅ |
| 22 | crossbow | crossbow.svg | ✅ |
| 23 | plasma_cannon | plasma_cannon.svg | ✅ |
| 24 | cloud_sword | cloud_sword.svg | ✅ |
| 25 | elven_bow | elven_bow.svg | ✅ |
| 26 | boxing_gloves | boxing_gloves.svg | ✅ |
| 27 | time_bomb | time_bomb.svg | ✅ |
| 28 | portal_weapon | portal_weapon.svg | ✅ |
| 29 | boomerang | boomerang.svg | ✅ |
| 30 | tornado | tornado.svg | ✅ |
| 31 | chain_whip | chain_whip.svg | ✅ |
| 32 | blood_orb | blood_orb.svg | ✅ |

### Sprites PNG (`game/assets/sprites/weapons/`)

| # | Arma | Sprite PNG | Status |
|---|------|-----------|--------|
| 1-32 | Todas | ✅ | 32/32 presentes |

### Efeitos Visuais de Ataque

#### Armas Melee — Slash Sprites (`game/assets/sprites/effects/slashes/`)

| # | Arma | Slash Sprite | Status |
|---|------|-------------|--------|
| 1 | katana | katana_slash.png | ✅ |
| 2 | scythe | scythe_slash.png | ✅ |
| 3 | axe | axe_slash.png | ✅ |
| 4 | whip | whip_crack.png | ✅ |
| 5 | lance | lance_thrust.png | ✅ |
| 6 | hammer | hammer_slam.png | ✅ |
| 7 | nunchaku | nunchaku_swing.png | ✅ |
| 8 | dual_katana | dual_katana_slash.png | ✅ |
| 9 | cloud_sword | cloud_sword_wave.png | ✅ |
| 10 | boxing_gloves | boxing_punch.png | ✅ |
| 11 | **shadow_claw** | shadow_claw_slash.png | ✅ |
| 12 | **chain_whip** | N/A (efeito procedural de chain) | ✅ Adequado |
| 13 | **magic_book** | N/A (orbitante + projetil) | ✅ Adequado |

#### Armas Ranged — Efeitos de Projétil

| # | Arma | Efeito Visual | Status |
|---|------|--------------|--------|
| 1 | staff | Projétil homing azul | ✅ |
| 2 | machinegun | Balas rápidas | ✅ |
| 3 | bazooka | Foguete + explosão AoE | ✅ |
| 4 | dual_pistol | Balas alternadas | ✅ |
| 5 | flamethrower | Cone de chamas (DESABILITADA) | ⚠️ Desabilitada |
| 6 | ice_staff | Projétil + freeze AoE | ✅ |
| 7 | crossbow | Flechas perfurantes | ✅ |
| 8 | plasma_cannon | Raio de plasma carregado | ✅ |
| 9 | elven_bow | Flechas ricochete | ✅ |
| 10 | poison_bottle | Garrafa + poça de veneno | ✅ |
| 11 | boomerang | Projétil retornante | ✅ |

#### Armas Summon/Special — Efeitos de Invocação

| # | Arma | Efeito Visual | Status |
|---|------|--------------|--------|
| 1 | necro | Esqueletos invocados | ✅ |
| 2 | drone | Drone orbitante | ✅ |
| 3 | totem | Torre estacionária + raios | ✅ |
| 4 | lightning_chain | Corrente elétrica entre inimigos | ✅ |
| 5 | time_bomb | Bomba temporizada + explosão | ✅ |
| 6 | portal_weapon | Portal teleport | ✅ |
| 7 | tornado | Vórtice puxando inimigos | ✅ |
| 8 | blood_orb | Orbe lifesteal | ✅ |

## Critérios de Aceitação

- [x] 1. Auditoria completa de 32 armas documentada neste PRD
- [x] 2. `shadow_claw_slash.png` criado — sprite de garras sombrias roxas 16x32
- [x] 3. `shadow_claw.svg` criado — ícone SVG de garras sombrias
- [x] 4. `boomerang.svg` criado — ícone SVG de boomerang
- [x] 5. `tornado.svg` criado — ícone SVG de tornado
- [x] 6. `chain_whip.svg` criado — ícone SVG de chicote elétrico
- [x] 7. `blood_orb.svg` criado — ícone SVG de orbe de sangue
- [x] 8. `slash_sprite_gen.gd` atualizado com `_gen_shadow_claw_slash()`
- [x] 9. `weapon_sprite_generator.gd` atualizado com armas faltantes (shadow_claw, chain_whip, boomerang, tornado, blood_orb)
- [x] 10. Todas 32 armas com ícone SVG (32/32)
- [x] 11. Todas armas melee com efeito de ataque dedicado (13/13)
- [x] 12. Verificação: shadow_claw.gd carrega `shadow_claw_slash.png` sem fallback

## Notas Técnicas

- Ícones SVG são 32x32 vetoriais, gerados manualmente ou via tool script
- Slash sprites são 16x32 pixel art, gerados via `slash_sprite_gen.gd`
- Weapon sprites são 16x16 pixel art, gerados via `weapon_sprite_generator.gd`
- O sistema de fallback em armas melee usa `katana_slash.png` quando o sprite próprio não existe
- `chain_whip` e `magic_book` não precisam de slash sprite — têm efeitos procedurais adequados
- `flamethrower` está desabilitada (requer mira manual não suportada pelo auto-aim)

## Anomalia: Shuriken

`shuriken.png` e `shuriken.svg` existem nos assets, mas `shuriken` **não está registrada** no `weapon_db.gd`. O script `shuriken.gd` existe. Decisão pendente: adicionar ao DB ou remover assets órfãos.
