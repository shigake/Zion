# ADR-011 — Armas com ataque automático (sem input do jogador)

**Status:** Aceito
**Data:** 2024-01

---

## Contexto

Zion é um survivors roguelite — o gênero define que o jogador foca em posicionamento e escolha de upgrades, não em acionar ataques manualmente. Precisávamos decidir o modelo de input para o combate.

## Decisão

**Todas as 32 armas atacam automaticamente**, sem necessidade de input do jogador.

- Armas melee: giram ou atacam em área ao redor do personagem
- Armas ranged: miram no inimigo mais próximo (ou no cluster mais denso) e disparam
- Armas summon/especiais: invocam entidades que persistem e atacam autonomamente

O jogador **apenas se move**. A profundidade vem da **escolha de qual arma pegar** e **qual combinação evoluir**.

## Justificativa

### Por que auto-attack?

- **Definição do gênero**: Vampire Survivors, Brotato, 20 Minutes Till Dawn — todos usam auto-attack. Jogadores do gênero esperam isso
- **Acessibilidade**: funciona perfeitamente com gamepad (só analog stick para mover)
- **Foco no posicionamento**: sem auto-attack, o jogo vira um twin-stick shooter — mecânica completamente diferente
- **Co-op**: 4 jogadores com auto-attack são gerenciáveis; 4 jogadores atirando manualmente é caos de UX

### Sistema de evolução

- Armas têm nível 1-8
- No nível 8, com o item correspondente no inventário (nível 5+), a arma **evolui** — "ressonância cristalina" narrativamente
- 12 evoluções disponíveis, cada uma mudando fundamentalmente o comportamento da arma

## Detalhes de Implementação

Cada arma (`scripts/weapons/`) herda de `WeaponBase` e implementa:
- `_find_target()` — lógica de seleção de alvo
- `_attack()` — lógica de ataque
- `_get_cooldown()` — intervalo base (modificado por upgrades de velocidade de ataque)

Projéteis são instanciados via `ObjectPool` (ver ADR-006).

## Consequências

- Jogadores não podem "errar" um ataque — a habilidade está na build, não na execução
- Armas podem se "pisar" visualmente — aceito; o caos visual é parte da identidade do gênero
- Balanceamento é crítico: armas muito fortes eliminam o incentivo de diversificar (ver `docs/balance_analysis.md`)
- Futuro: modo "manual aim" poderia ser um modificador de dificuldade opcional
