# PRD 34 — Katana (espada de samurai) maior e mais visivel durante ataque

**Status**: concluido
**Prioridade**: media (afeta feedback visual do Ronin)
**Tipo**: enhancement
**Impacto**: katana.gd — arma principal do Ronin

## Problema

Durante o jogo, a katana eh dificil de ver atacando. O sprite e mesh sao muito pequenos, e a animacao de arco (120 graus em 0.2s) passa rapido demais para perceber.

Valores atuais:
- **Sprite pixel_size**: 0.03
- **Mesh visual**: 0.15 x 0.1 x 2.0 unidades
- **Collision shape**: 0.3 x 0.5 x 2.5 unidades
- **Trail width**: 0.2 unidades, 14 pontos
- **Slash sprite**: 64x64 px

## Solucao

Aumentar a presenca visual da katana sem alterar o balanceamento:

1. **Aumentar o sprite** (pixel_size de 0.03 para ~0.045)
2. **Aumentar o mesh visual** (de 0.15x0.1x2.0 para ~0.2x0.12x2.5)
3. **Aumentar a trail** (width de 0.2 para ~0.35, mais visivel)
4. **Aumentar o slash sprite** se necessario para acompanhar
5. **NAO alterar** a collision shape nem o dano — balanceamento intacto

## Criterios de aceitacao

- [ ] Katana visivelmente maior durante ataque
- [ ] Trail de ataque mais grossa e perceptivel
- [ ] Collision shape e dano NAO alterados
- [ ] Visual proporcional ao personagem (nao exagerado)
- [ ] Dual katana tambem ajustada proporcionalmente
