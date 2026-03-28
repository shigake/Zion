# Balance Analysis — Mathematical Report

> Os Sentinelas devem ser desafios significativos — sao guardioes de Zion, nao inimigos comuns. O balanceamento reflete a dificuldade narrativa de libertar cada Sentinela Corrompido.

## 1. Weapon DPS Table (Single Target)

Formula: `DPS = (base_dmg + dmg_per_lvl * (lvl-1)) / max(0.05, base_cd + cd_per_lvl * (lvl-1))`

| Weapon | Type | L1 DPS | L4 DPS | L8 DPS | Status |
|--------|------|--------|--------|--------|--------|
| Katana | melee | 18.8 | 39.3 | 113.2 | NERFED ✓ |
| Staff | ranged/homing | 8.0 | 20.0 | 50.0 | BUFFED ✓ |
| Scythe | passive/area | ~20 | ~41 | ~62 | OK |
| Machinegun | ranged/rapid | 40.0 | 100.0 | 250.0 | OK (single target) |
| Bazooka | ranged/AoE | 8.6 | 20.7 | 47.6 | OK (AoE) |
| Necro | summon | 3.0 | 19.4 | 94.7 | OK (summons) |
| Axe | melee/thrown | 9.0 | 21.3 | 55.8 | OK |
| Shuriken | ranged/multi | 8.0 | 19.7 | 65.9 | BUFFED ✓ |
| Drone | summon | 6.7 | 17.3 | 47.5 | BUFFED ✓ |
| Totem | summon/area | 2.8 | 7.1 | 14.5 | BUFFED ✓ |
| Poison Bottle | area/DoT | 3.2 | 7.8 | 20.0 | BUFFED ✓ |
| Lightning Chain | ranged/chain | 6.0 | 14.6 | 34.5 | OK (chains) |
| Magic Book | passive | ~16 | ~37 | ~58 | OK |
| Whip | melee/area | 13.3 | 34.8 | 97.6 | OK (wide area) |
| Lance | melee/long | 18.0 | 36.8 | 91.4 | NERFED ✓ |
| Hammer | melee/AoE | 12.5 | 29.9 | 69.8 | OK |
| Nunchaku | melee/fast | 16.0 | 44.7 | 131.8 | NERFED ✓ |
| Dual Katana | melee | 14.1 | 37.5 | 111.1 | OK |
| Dual Pistol | ranged/rapid | 27.8 | 73.3 | 172.7 | OK (single target) |
| Flamethrower | area/cont | 3.2 | 7.8 | 20.0 | BUFFED ✓ |
| Ice Staff | ranged/AoE | 7.0 | 16.5 | 36.2 | BUFFED ✓ |
| Crossbow | ranged/pierce | 12.2 | 28.7 | 64.5 | OK |
| Plasma Cannon | ranged/AoE | 8.0 | 18.5 | 42.8 | OK |
| Cloud Sword | melee/heavy | 17.5 | 39.6 | 90.5 | OK |
| Elven Bow | ranged/pierce | 11.7 | 27.1 | 65.6 | OK |
| Boxing Gloves | melee | 13.3 | 31.7 | 77.5 | OK |
| Time Bomb | area/AoE | 7.0 | 15.3 | 32.3 | OK (3 bombs) |
| Portal | special | 2.4 | 6.4 | 14.5 | BUFFED ✓ |
| Boomerang | ranged/pierce | 10.7 | 25.3 | 63.8 | NEW |
| Tornado | summon/area | 1.0 | 2.6 | 5.1/tick | NEW (area) |
| Chain Whip | melee/chain | 10.0 | 24.1 | 60.8 | NEW |
| Blood Orb | summon/area | 0.8 | 2.1 | 5.5/tick | NEW (area+lifesteal) |

## 2. Balance Issues Identified

### CRITICAL — DPS Outliers

| Weapon | L8 DPS | Problem | Target DPS |
|--------|--------|---------|------------|
| Nunchaku | 362.5 | cd_per_lvl -0.06 makes cd=0.08. 45x stronger than Portal | 100-120 |
| Katana | 179.2 | cd_per_lvl -0.08 makes cd=0.24 | 100-120 |
| Machinegun | 250.0 | Borderline OK for single-target rapid fire | 180-220 |
| Dual Pistol | 172.7 | High but reasonable for rapid fire | 140-170 |
| Lance | 120.5 | Slightly high for melee | 80-100 |

### CRITICAL — Underpowered Weapons

| Weapon | L8 DPS | Problem | Target DPS |
|--------|--------|---------|------------|
| Portal | 8.0 | Weakest by far, useless at all levels | 15-20 (area) |
| Totem | 10.0 | Area but still very weak | 18-25 (area) |
| Flamethrower | 12.4 | Continuous area but negligible damage | 22-30 (area) |
| Poison Bottle | 13.1 | Area DoT but barely tickles | 20-28 (area) |
| Staff | 36.3 | Weak for a primary weapon despite homing | 45-55 |
| Drone | 35.0 | Autonomous but low | 40-50 |
| Ice Staff | 26.7 | Low even with AoE + slow | 35-45 |

## 3. Target DPS Ranges by Weapon Category

| Category | L1 Target | L4 Target | L8 Target | Rationale |
|----------|-----------|-----------|-----------|-----------|
| Fast Melee (Katana, DualKatana, Nunchaku) | 15-20 | 40-55 | 90-120 | High risk, high reward |
| Heavy Melee (CloudSword, Hammer, Lance) | 15-20 | 30-45 | 70-100 | Slower but harder hits |
| Rapid Ranged (Machinegun, DualPistol) | 25-40 | 60-90 | 150-220 | Single target only |
| Burst Ranged (Bazooka, Crossbow, Plasma) | 8-15 | 20-35 | 40-70 | AoE/pierce compensates |
| Homing (Staff, IceStaff, ElvenBow) | 8-15 | 20-35 | 40-65 | Auto-aim advantage |
| Area/DoT (Whip, Flame, Poison, Scythe) | 10-20 | 25-40 | 50-100 | Hits many enemies |
| Summon (Necro, Drone, Totem) | 3-8 | 12-25 | 30-60 | Autonomous, scales with summon count |
| Special (Shuriken, Lightning, TimeBomb) | 5-10 | 15-30 | 35-60 | Multi-target/utility |
| Utility (Portal) | 1-5 | 5-12 | 15-25 | Teleport/utility value |

## 4. Proposed Weapon Changes

### Nerfs

| Weapon | Stat | Old | New | Effect |
|--------|------|-----|-----|--------|
| Nunchaku | cooldown_per_level | -0.06 | -0.04 | L8 cd: 0.08→0.22, DPS: 362→132 |
| Katana | cooldown_per_level | -0.08 | -0.06 | L8 cd: 0.24→0.38, DPS: 179→113 |
| Lance | cooldown_per_level | -0.08 | -0.06 | L8 cd: 0.44→0.58, DPS: 120→91 |

### Buffs

| Weapon | Stat | Old | New | Effect |
|--------|------|-----|-----|--------|
| Staff | base_damage | 8 | 12 | L8 DPS: 36→50 |
| Staff | damage_per_level | 3 | 4 | ^ combined |
| Flamethrower | base_damage | 4 | 8 | L8 DPS: 12→23 (area multi-hit) |
| Flamethrower | damage_per_level | 2 | 3 | ^ combined |
| Poison Bottle | base_damage | 5 | 8 | L8 DPS: 13→22 (area DoT) |
| Poison Bottle | damage_per_level | 2 | 3 | ^ combined |
| Totem | base_damage | 8 | 14 | L8 DPS: 10→19 (area continuous) |
| Totem | damage_per_level | 3 | 4 | ^ combined |
| Portal | base_damage | 5 | 12 | L8 DPS: 8→17 (utility + area) |
| Portal | damage_per_level | 3 | 5 | ^ combined |
| Drone | base_damage | 7 | 10 | L8 DPS: 35→48 |
| Drone | damage_per_level | 3 | 4 | ^ combined |
| Ice Staff | base_damage | 10 | 14 | L8 DPS: 27→41 (AoE + slow) |
| Ice Staff | damage_per_level | 3 | 4 | ^ combined |
| Shuriken | base_damage | 5 | 8 | L8 DPS: 43→57 (multi-dir) |

## 5. XP Curve Analysis

Formula: `xp_to_next = int(prev * 1.15) + 3`

| Level | XP Needed | Cumulative | Kills@1XP |
|-------|-----------|------------|-----------|
| 2 | 5 | 5 | 5 |
| 3 | 8 | 13 | 13 |
| 5 | 16 | 41 | 41 |
| 10 | 51 | 277 | 277 |
| 15 | 103 | 661 | 661 |
| 20 | 194 | 1,389 | 1,389 |
| 25 | 361 | 2,734 | 2,734 |
| 30 | 663 | 5,211 | 5,211 |
| 35 | 1,213 | 9,771 | 9,771 |
| 40 | 2,216 | 18,240 | 18,240 |

**Kill rate estimate by minute:**
- Min 0-5: ~2-5 kills/sec = 600-1,500 total
- Min 5-10: ~5-10 kills/sec = 1,500-3,000 more
- Min 10-15: ~10-20 kills/sec = 3,000-6,000 more
- Min 15-20: ~15-25 kills/sec = 4,500-7,500 more

**Expected level by minute:**
- Min 5: ~Level 12-15 (reasonable)
- Min 10: ~Level 20-25 (good)
- Min 15: ~Level 28-32 (good)
- Min 20: ~Level 33-37 (matches PRD target of 30-40 levels in 30 min)

**Verdict**: XP curve is well-balanced. No changes needed.

## 6. Enemy Kill Time Analysis

Kill time = enemy_HP / player_DPS (single weapon, no items)

**With Katana at different levels:**

| Enemy | HP | L1 (18.8) | L4 (48.2) | L8 (113*) |
|-------|----|----|----|----|
| Bat | 8 | 0.43s | 0.17s | instant |
| Ghost (phys 0.5x) | 12 | 1.28s | 0.50s | 0.21s |
| Slime | 15 | 0.80s | 0.31s | 0.13s |
| Skeleton | 25 | 1.33s | 0.52s | 0.22s |
| Zombie | ~30 | 1.60s | 0.62s | 0.27s |
| Tank | ~100 | 5.32s | 2.07s | 0.88s |
| Mimic | 150 | 7.98s | 3.11s | 1.33s |
| Miniboss | 500 | 26.6s | 10.4s | 4.42s |
| Boss | 2000 | 106.4s | 41.5s | 17.7s |

*After proposed nerf

**Verdict**: Kill times are reasonable. Early enemies die in 1-2 hits, late enemies need sustained DPS. Boss fight ~18s with maxed weapon is fine since player has 4-6 weapons.

## 7. Spawn Pressure Analysis

Difficulty mult: `min(8.0, 1.0 + (time/60) * 0.35)`
Spawn interval: `max(0.15, 1.2 / mult)`
Enemies per wave: `2 * mult`

| Minute | Diff Mult | Interval | Per Wave | Spawns/Min | Cumulative Alive |
|--------|-----------|----------|----------|------------|------------------|
| 0 | 1.0 | 1.20s | 2 | 100 | ~100 |
| 5 | 2.75 | 0.44s | 5 | 682 | ~200 |
| 10 | 4.50 | 0.27s | 9 | 2000 | ~350 |
| 15 | 6.25 | 0.19s | 12 | 3789 | ~450 |
| 20 | 8.00 | 0.15s | 16 | 6400 | 500 (cap) |
| 25 | 8.00 | 0.15s | 16 | 6400 | 500 (cap) |

**Verdict**: Spawn pressure ramps well. Cap of 500 enemies is reached around minute 18-20. Player must kill fast enough to prevent overflow.

## 8. Enemy Stat Issues (from PRD notes)

| Enemy | Stat | Current | Issue | Proposed |
|-------|------|---------|-------|----------|
| Bat | speed | 4.5 | Too fast for minute 2-5 | 3.8 |
| Ghost | damage | 10 | High for minute 5-8 | 8 |
| Ghost Red | damage | 15 | Very high + fire resist | 12 |
| Bomber | damage | 25 | Instant death for low-HP players | 20 |
| Skeleton Archer | speed | 1.0 | Already slow, OK | 1.0 |

## 9. Sentinela Balance

Os Sentinelas sao guardioes de Zion corrompidos pelo cristal — devem ser desafios dignos, nao punching bags. Suas 3 fases representam camadas de corrupcao (guardiao → possuido → forma final).

With 4-6 weapons averaging 60-80 DPS each at L6-8:
- Total player DPS: 300-500
- Sentinela HP: 1500-2000
- Kill time: 3-7 seconds

**Issue**: Sentinelas caiam rapido demais com armas evoluidas (ressonancia cristalina 2.5-3.5x).
- Evolved DPS: 750-1750
- Kill time com evolucao: 1-3 seconds = trivial

**Proposed fix**: Increase Sentinela HP by 50% (a corrupcao os protege)

| Sentinela | Fenda | Old HP | New HP | Kill Time (400 DPS) |
|------|------|--------|--------|---------------------|
| Rainha das Fadas | Floresta | 1500 | 2500 | 6.3s |
| Mega Vaca Alienigena | Fazenda (anomalia) | 1500 | 2500 | 6.3s |
| Rei Acucar | Mundo Doce (anomalia) | 1800 | 3000 | 7.5s |
| Conde Dracula | Castelo | 1800 | 3000 | 7.5s |
| Necromancer King | Cemiterio | 2000 | 3500 | 8.8s |
| AI Overlord | Toquio | 2000 | 3500 | 8.8s |
| Demon Lord | Vulcao | 2000 | 3500 | 8.8s |
| Imperador Corrompido | Arena (anomalia) | 2000 | 3500 | 8.8s |
| Leviathan | Oceano | 2000 | 3500 | 8.8s |
| Singularidade | Espaco | 2000 | 3500 | 8.8s |

All Sentinelas APPLIED ✓

## 10. Evolution Damage Multipliers

Current range: 2.0x - 3.5x

| Evolution | Current | Issue | Proposed |
|-----------|---------|-------|----------|
| Nuke Launcher | 3.5x | Too high, bazooka already strong | 2.5x |
| Apocalypse Staff | 3.0x | Staff needs help, keep | 3.0x |
| Lord of Dead | 3.0x | Necro summons scale well, reduce | 2.5x |
| Death Scythe | 2.0x | Has execute mechanic, OK | 2.0x |
| All others | 2.5x | Reasonable | 2.5x |

## Summary of All Changes

1. **3 weapon nerfs** (Nunchaku, Katana, Lance cooldown scaling)
2. **8 weapon buffs** (Staff, Flamethrower, Poison, Totem, Portal, Drone, Ice Staff, Shuriken)
3. **4 enemy stat adjustments** (Bat speed, Ghost/GhostRed/Bomber damage)
4. **10 boss HP increases** (+50-75%)
5. **2 evolution mult adjustments** (Nuke Launcher, Lord of Dead)
6. **XP curve**: No changes needed
7. **Spawn scaling**: No changes needed
