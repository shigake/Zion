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

## Ajustes Necessarios (baseado na analise atual)

1. **XP base muito baixo** — slime dropa 1 XP, precisa de 5 pra level 2. OK.
2. **Bat muito rapido** — speed 6.0 vs player 8.0. Bat deveria ser 4.5-5.0.
3. **Katana cooldown** — 1.2s e lento demais pro inicio. Reduzir pra 0.8s.
4. **Metralhadora dano** — 4 por bala e muito baixo. Aumentar pra 6.
5. **Boss HP** — 2000 pode ser baixo se jogador tem 6 armas evoluidas. OK pra fase 1.
6. **Ghost dano** — 15 e muito alto pra min 8-12. Reduzir pra 10.
7. **Cristal drop rate** — 30% e ok, mas valor deve escalar com tipo de inimigo.
