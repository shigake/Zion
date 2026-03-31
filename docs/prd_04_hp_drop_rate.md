# PRD 04 — Diminuir porcentagem de drop de vida

## Problema
Drops de vida estao caindo com frequencia alta demais, reduzindo a dificuldade do jogo.

## Valores atuais
Definidos em `game_constants.gd` linhas 368-370:

```gdscript
const HEALTH_DROP_CHANCE := 0.05          # 5% base por inimigo morto
const HEALTH_DROP_BONUS_THRESHOLD := 0.4  # Quando HP < 40%
const HEALTH_DROP_BONUS_CHANCE := 0.03    # +3% extra com HP baixo
```

**Chance efetiva atual:**
- HP normal: 5% por kill
- HP < 40%: 8% por kill (5% + 3%)
- Com luck_mult: multiplicado pelo multiplicador de sorte do jogador

**Para comparacao:**
- Crystal drop: 30% (50% com Master Key)
- Magnet drop: 1% (2% com Master Key)

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `scripts/autoload/game_constants.gd` | Linhas 368-370 — constantes de drop |
| `scripts/enemies/enemy_base.gd` | `_spawn_health_pickup()` (~L911-930) — logica de drop |

## Logica de drop (enemy_base.gd)
```gdscript
func _spawn_health_pickup():
    var base_chance = GameConstants.HEALTH_DROP_CHANCE  # 0.05
    var hp_ratio = float(GameManager.current_hp) / float(GameManager.max_hp)
    if hp_ratio < GameConstants.HEALTH_DROP_BONUS_THRESHOLD:  # < 0.4
        base_chance += GameConstants.HEALTH_DROP_BONUS_CHANCE  # + 0.03
    var drop_chance = base_chance * GameManager.luck_mult
    if randf() > drop_chance:
        return
    # ... spawn pickup ...
```

## Plano de implementacao

### Passo 1 — Reduzir constantes em game_constants.gd
```gdscript
# Antes:
const HEALTH_DROP_CHANCE := 0.05
const HEALTH_DROP_BONUS_THRESHOLD := 0.4
const HEALTH_DROP_BONUS_CHANCE := 0.03

# Depois:
const HEALTH_DROP_CHANCE := 0.02          # 2% base (era 5%)
const HEALTH_DROP_BONUS_THRESHOLD := 0.3  # Bonus so com HP < 30% (era 40%)
const HEALTH_DROP_BONUS_CHANCE := 0.02    # +2% extra (era 3%)
```

**Nova chance efetiva:**
- HP normal: 2% por kill (era 5%)
- HP < 30%: 4% por kill (era 8%)

### Passo 2 — Verificar heal amount
Em `enemy_base.gd`, verificar quanto cada pickup cura (8% do max HP). Se necessario, ajustar tambem.

## Validacao
- [ ] Drop de vida notavelmente mais raro durante gameplay
- [ ] Ainda possivel receber cura com HP critico
- [ ] Dificuldade do jogo aumenta sensivelmente
- [ ] Testar com personagens de alta e baixa sorte
