# PRD 30 — Auto-aim para armas melee

**Status**: pendente
**Prioridade**: alta (afeta gameplay core de todos os personagens melee)
**Tipo**: fix/enhancement
**Impacto**: 8 armas melee × 15 personagens = 120 combinacoes afetadas

## Problema

Armas melee (lanca, katana, nunchaku, etc.) atacam numa **direcao fixa** em vez de mirar no inimigo mais proximo. O jogador espera que a arma ataque automaticamente o inimigo mais perto, como ja acontece com armas ranged (crossbow, staff, machinegun, etc.).

Exemplo: a lanca so ataca "pra frente" (rotation.y = 0) a menos que `manual_aim` esteja ativo. Se o inimigo esta atras do player, a lanca ataca o ar.

Duas armas melee **ja funcionam corretamente** — `shadow_claw.gd` e `chain_whip.gd` usam auto-aim. O padrao existe, so precisa ser replicado.

## Escopo

### Armas que PRECISAM de auto-aim (8)

| # | Arma | Script | Tipo de ataque | Comportamento atual |
|---|------|--------|----------------|---------------------|
| 1 | **Katana** | `katana.gd` | Arco 120° frontal | So rotaciona com manual_aim |
| 2 | **Lance** | `lance.gd` | Thrust linear | So rotaciona com manual_aim |
| 3 | **Hammer** | `hammer.gd` | Ground slam AoE | Sem direcao (AoE puro) |
| 4 | **Nunchaku** | `nunchaku.gd` | Cone 90° frontal | So rotaciona com manual_aim |
| 5 | **Dual Katana** | `dual_katana.gd` | X-slash frontal | So rotaciona com manual_aim |
| 6 | **Whip** | `whip.gd` | Arco 180° | So rotaciona com manual_aim |
| 7 | **Cloud Sword** | `cloud_sword.gd` | Arco 180° | So rotaciona com manual_aim |
| 8 | **Boxing Gloves** | `boxing_gloves.gd` | Combo 3 hits frontal | So rotaciona com manual_aim |

### Armas que JA tem auto-aim (2) — referencia

| Arma | Script | Como funciona |
|------|--------|---------------|
| **Shadow Claw** | `shadow_claw.gd` (linhas 107-124) | `GameManager.get_enemies()` → nearest → `atan2` → `rotation.y` |
| **Chain Whip** | `chain_whip.gd` | Nearest enemy + chain para vizinhos |

### Armas que NAO precisam de mudanca

| Arma | Motivo |
|------|--------|
| **Scythe** | Orbita ao redor do player (sem direcao) |
| **Magic Book** | Orbita + dispara projeteis (sem direcao fixa) |
| **Todas ranged** | Ja tem auto-aim implementado |
| **Todas summon** | Comportamento autonomo |

### Caso especial: Hammer

O Hammer faz AoE ao redor do player. Ele nao tem direcao — o slam atinge tudo ao redor. **Decisao**: adicionar auto-aim mesmo assim para que o efeito visual (mesh, trail) aponte pro inimigo mais proximo, dando feedback direcional ao jogador. Se o hammer for 360° puro sem visual direcional, pode ser ignorado.

## Especificacao tecnica

### Padrao de auto-aim (copiar de shadow_claw.gd)

Adicionar este bloco no inicio de `_attack()` de cada arma melee, **antes** do bloco de manual_aim:

```gdscript
# Auto-aim toward nearest enemy (quando manual_aim esta desligado)
if not GameManager.manual_aim:
    var enemies = GameManager.get_enemies()
    if not enemies.is_empty():
        var player = get_parent().get_parent() if get_parent() else null
        if player and is_instance_valid(player):
            var nearest: Node3D = null
            var min_dist = INF
            for e in enemies:
                if not is_instance_valid(e):
                    continue
                var d = player.global_position.distance_squared_to(e.global_position)
                if d < min_dist:
                    min_dist = d
                    nearest = e
            if nearest:
                var dir = (nearest.global_position - player.global_position).normalized()
                var aim_angle = atan2(-dir.x, -dir.z)
                rotation.y = aim_angle
```

### Regras

1. **Manual aim tem prioridade**: se `GameManager.manual_aim == true`, usa a direcao do stick/mouse (comportamento atual mantido)
2. **Sem inimigos**: se `get_enemies()` esta vazio, manter direcao atual (nao resetar)
3. **Performance**: `distance_squared_to` (sem sqrt) — ja e o padrao usado nos ranged
4. **Hammer**: avaliar se precisa. Se o slam e 360° sem visual direcional, pular

### Logica do `_attack()` apos mudanca

```
_attack(level):
    1. Se NAO manual_aim → buscar nearest enemy → rotation.y = aim_angle
    2. Se manual_aim → rotation.y = aim_direction (comportamento atual)
    3. Resto da logica de ataque (scale, anim, sfx, etc.)
```

## Validacao por personagem

Testar com todos os 15 Fragmentados, pois cada um tem arma inicial diferente:

| Personagem | Arma inicial | Precisa fix? |
|-----------|-------------|-------------|
| Ronin | Katana | ✅ Sim |
| Soldado | Machinegun | ❌ Ja ok |
| Mago | Staff | ❌ Ja ok |
| Berserker | Hammer | ⚠️ Avaliar |
| Ninja | Shuriken | ❌ Direcional fixo (design intencional) |
| Necro | Necro Summon | ❌ Ja ok |
| Pirata | Crossbow | ❌ Ja ok |
| Engenheiro | Drone | ❌ Ja ok |
| Vampiro | Blood Orb | ❌ Ja ok |
| Gladiador | Lance | ✅ Sim |
| Chef | Dual Katana | ✅ Sim |
| Mystery | Cloud Sword | ✅ Sim |
| Amazona | Whip | ✅ Sim |
| Bruxa | Ice Staff | ❌ Ja ok |
| Fragmentado | Boxing Gloves | ✅ Sim |

**6 personagens** comecam com armas afetadas pelo bug. Alem disso, qualquer personagem pode adquirir armas melee durante a run.

## Criterios de aceite

- [ ] Todas as 8 armas melee listadas atacam na direcao do inimigo mais proximo
- [ ] Manual aim (stick direito / mouse) continua funcionando e tem prioridade
- [ ] Sem inimigos na tela → arma mantem ultima direcao (nao reseta)
- [ ] Performance: nenhum impacto mensuravel (get_enemies() ja e usado por 10+ armas ranged)
- [ ] Testado com pelo menos os 6 personagens que comecam com arma melee

## Narrativa

Os estilhacos de Zion dentro de cada Fragmentado **ressoam** com a presenca dos corrompidos — as armas cristalinas sao guiadas instintivamente em direcao a ameaca mais proxima. Nao e pontaria — e **instinto dimensional**.
