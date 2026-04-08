# PRD 16 — Balance Solo

## Status: concluido

## Problema
O balance do jogo solo tem vários problemas que tornam a experiência frustrante:
1. Dificuldade trava no minuto 20 (cap 8.0x)
2. Drop de HP muito baixo (2%) para solo
3. Boss spawn igual pra solo e co-op
4. Solo e 2-player têm mesmo multiplicador de spawn
5. Early game tedioso (2 min só de slimes)
6. XP escala muito rápido
7. Evolução de arma muito tardia (arma lv8 + item lv5)
8. Elites aparecem tarde demais (min 15)

## Solução — 8 ajustes

| # | Constante | Antes | Depois | Motivo |
|---|-----------|-------|--------|--------|
| 1 | DIFFICULTY_CAP | 8.0 | 12.0 | Late game desafiante |
| 2 | HEALTH_DROP_CHANCE | 0.02 | 0.04 | Sobrevivência solo |
| 3 | HEALTH_DROP_BONUS_CHANCE | 0.02 | 0.03 | Mais HP quando HP baixo |
| 4 | MP_SPAWN_MULT[0] | 1.0 | 0.85 | Solo mais justo |
| 5 | MP_BOSS_HP_MULT[0] | 1.0 | 0.85 | Boss solo menos opressivo |
| 6 | XP_SCALE_FACTOR / XP_LEVEL_SCALE | 1.15 | 1.12 | Mais levels = mais fun |
| 7 | Evolution req | arma lv8 + item lv5 | arma lv6 + item lv3 | Evolução acessível |
| 8 | SPAWN_PHASE_1_END | 2.0 min | 1.0 min | Early game menos tedioso |
| 9 | ELITE_MIN_MINUTE | 15.0 | 10.0 | Curva mais suave |

## Arquivos alterados
- `game/scripts/autoload/game_constants.gd`
- `game/scripts/autoload/evolution_db.gd`
- `game/scripts/ui/inventory_overlay.gd`

## Critério de aceite
- [x] Dificuldade escala até 12x
- [x] HP drop 4% base + 3% bonus
- [x] Solo tem spawn mult 0.85x
- [x] Boss solo tem 0.85x HP
- [x] XP escala com fator 1.12
- [x] Evolução requer arma lv6 + item lv3
- [x] Slimes só no primeiro minuto
- [x] Elites a partir do minuto 10
