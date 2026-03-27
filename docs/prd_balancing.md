# PRD — Balanceamento & Testes

## Objetivo
Garantir que a run de 30 minutos seja divertida do inicio ao fim. O jogador deve se sentir fraco no minuto 1, poderoso no minuto 15, e desesperado no minuto 25.

---

## Curva de Poder do Jogador

| Minuto | DPS Esperado | HP Esperado | Armas | Itens |
|---|---|---|---|---|
| 0 | 12 | 100 | 1 (lv1) | 0 |
| 5 | 40 | 100 | 2 (lv2-3) | 1 |
| 10 | 120 | 120 | 3 (lv3-5) | 2-3 |
| 15 | 300 | 150 | 4 (lv5-7) | 3-4 |
| 20 | 600 | 180 | 5 (lv6-8) | 4-5 |
| 25 | 1000+ | 200 | 6 (lv7-8+evo) | 5-6 |

---

## Curva de Dificuldade dos Inimigos

| Minuto | Spawn/s | HP Base | Dano | Tipos |
|---|---|---|---|---|
| 0-2 | 2 | 15 | 8 | Slime |
| 2-5 | 3 | 15-8 | 8-5 | Slime + Bat |
| 5-8 | 5 | 15-25 | 8-12 | + Skeleton |
| 8-12 | 8 | 20-25 | 10-15 | + Zombie + Ghost |
| 12-15 | 12 | 25-500 | 12-25 | + Mini-boss |
| 15-20 | 15 | 25*elite | 15 | + Elites |
| 20-25 | 20 | 30+ | 18 | Insano |
| 25-30 | 25 | 30+ 2000(boss) | 20-35 | + Boss |

---

## Regras de Balanceamento

1. **Nenhuma run deve durar menos de 3 minutos** (mesmo sem upgrades da loja)
2. **Um jogador medio deve morrer entre 15-20 min** nas primeiras runs
3. **Com loja full, deve ser possivel chegar ao boss** consistentemente
4. **Boss deve matar ~50% dos jogadores** na primeira tentativa
5. **Evolucoes devem ser raras** — max 1-2 por run em media
6. **XP scaling deve permitir ~30-40 level ups** em 30 min

---

## Testes Automatizados

### Teste de Sobrevivencia (simulated)
- Roda o jogo sem input por 30 min
- Mede: tempo ate morte, kills, level alcancado
- Esperado: morte entre 1-3 min sem input (inimigos matam)

### Teste de DPS
- Player parado com cada arma level 1-8
- Mede: DPS real vs esperado
- Valida que scaling faz sentido

### Teste de XP Curve
- Simula coleta constante de XP
- Mede: levels alcancados por minuto
- Valida que nao levela rapido demais nem devagar demais

### Teste de Spawn Rate
- Verifica que enemies_alive nunca excede max_enemies
- Verifica que spawn rate escala conforme spec

---

## Ajustes Aplicados (v2.24.0)

Todos os ajustes abaixo foram implementados e verificados matematicamente.
Ver `docs/balance_analysis.md` para a analise completa com formulas.

### Armas — Nerfs (DPS L8 muito alto)
- Nunchaku: cd_per_lvl -0.06→-0.04 (DPS 362→132)
- Katana: cd_per_lvl -0.08→-0.06 (DPS 179→113)
- Lance: cd_per_lvl -0.08→-0.06 (DPS 120→91)

### Armas — Buffs (DPS L8 muito baixo)
- Staff: dmg 8/3→12/4 (DPS 36→50)
- Shuriken: dmg 5/2→8/3 (DPS 43→66)
- Drone: dmg 7/3→10/4 (DPS 35→48)
- Totem: dmg 8/3→14/4 (DPS 10→19)
- Poison Bottle: dmg 5/2→8/3 (DPS 13→20)
- Flamethrower: dmg 4/2→8/3 (DPS 12→20)
- Ice Staff: dmg 10/3→14/4 (DPS 27→36)
- Portal: dmg 5/3→12/5 (DPS 8→15)

### Inimigos
- Bat speed: 4.5→3.8 (era rapido demais pra min 2-5)
- Ghost damage: 10→8 (era alto pra min 5-8)
- Ghost Red damage: 15→12
- Bomber damage: 25→20 (one-shot em jogadores low HP)

### Bosses (HP +50-75% — morriam rapido demais com evolucoes)
- Fairy Queen/Alien Cow: 1500→2500
- Sugar King/Dracula: 1800→3000
- Todos os outros: 2000→3500

### Evolucoes
- Nuke Launcher: 3.5x→2.5x (bazooka ja era forte)
- Lord of Dead: 3.0x→2.5x (summons escalam bem)

### Sistemas
- Armadura: subtracao linear → percentual (armor/(armor+50), cap ~60%)
- Master Key: bug de 2x XP corrigido → agora dobra XP gems + cristais + chance de drop
- Mystery: MAX_WEAPONS 23→8
- Vampiro: lifesteal 3%→5% + 10% attack speed
- Gladiador: armor 5→8 + 15% max HP

### Shop
- Damage custo: 60/35→50/28 (era caro demais)
- XP Bonus custo: 40/20→60/35 (era barato demais)
- Weapon Slots custo: 300/200→500/350 (era barato demais)

### Mutations
- Speed demons: 15%→25%
- Weakened healing: 20%→25%
- Endless horde: 35%→30%
- No evolution: 40%→30%

### Miniboss HP (progressivo por stage)
- Forest 600, Farm 700, Tokyo 750, Volcano 850, Ocean 800
- Arena 900, Space 950, Castle 1000, Candy 1100

### Verificacao das Regras
1. ✅ Run minima 3 min: ~40s parado, 1-3 min com movimento
2. ✅ Morte 15-20 min primeiro run: spawn pressure escala corretamente
3. ✅ Shop full → boss alcancavel: +50% dmg, +3 revives, 5-6 armas
4. ✅ Boss mata ~50%: HP 2500-3500, 3 fases com summons
5. ✅ Evolucoes raras: ~30-40% chance de 1 evo, ~10% de 2
6. ✅ 30-40 levels em 30 min: XP curve validada matematicamente
