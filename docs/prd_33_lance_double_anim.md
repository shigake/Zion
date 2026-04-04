# PRD 33 — Lanca com animacao duplicada no ataque

**Status**: concluido
**Prioridade**: alta (bug visual que afeta gameplay)
**Tipo**: bugfix
**Impacto**: lanca (lance.gd) — arma do Gladiador

## Problema

Ao atacar com a lanca, **duas animacoes** aparecem simultaneamente:

1. **Sprite estatico** — a lanca fica parada em cima do personagem (WeaponSprite billboard)
2. **Thrust animado** — a lanca avanca em direcao ao inimigo (ThrustMesh + ThrustArea com lerp)

O resultado visual eh confuso: parece haver duas lancas. O jogador deveria ver apenas UMA animacao fluida de investida (thrust).

## Causa provavel

O script `lance.gd` cria um `WeaponSprite` (Sprite3D billboard) que fica visivel o tempo todo, inclusive durante o ataque. O `ThrustMesh` (mesh geometrica) tambem aparece durante o ataque. Ambos ficam visiveis ao mesmo tempo.

## Solucao

Manter apenas a animacao de thrust (a que vai em direcao ao inimigo), que eh a mais bonita e funcional:

1. **Esconder o WeaponSprite** durante o ataque (ou remover se nao for necessario fora do ataque)
2. **Garantir que o ThrustMesh** seja a unica representacao visual durante a investida
3. Se o WeaponSprite serve como visual "idle" (quando nao esta atacando), esconde-lo no inicio do ataque e mostra-lo novamente ao fim
4. Testar que a hitbox (ThrustArea) continua funcionando normalmente

## Criterios de aceitacao

- [ ] Ao atacar, apenas UMA animacao de lanca eh visivel
- [ ] A animacao de thrust (investida em direcao ao inimigo) eh a que permanece
- [ ] Hitbox de dano continua funcionando corretamente
- [ ] Visual idle (fora de ataque) continua coerente
- [ ] Auto-aim (PRD 30) continua funcionando
