# PRD 35 — Bazuca nao esta funcionando

**Status**: concluido
**Prioridade**: alta (arma completamente quebrada)
**Tipo**: bugfix
**Impacto**: bazooka.gd + rocket.gd — arma do Engenheiro

## Problema

A bazuca nao esta funcionando durante o jogo. Ao atirar, os projeteis (rockets) nao atingem os inimigos e/ou nao explodem corretamente. A arma deveria:

1. Disparar um foguete em direcao ao inimigo/cluster mais denso
2. O foguete viaja ate o alvo
3. Ao chegar, explode com dano em area (AoE fogo)
4. Explosao com efeitos visuais (flash, fireball, shockwave, smoke, sparks)

## Investigacao necessaria

O sistema envolve dois scripts:
- **bazooka.gd**: disparo, selecao de alvo, cooldown
- **rocket.gd**: movimento do projetil, detecao de chegada, explosao

Possiveis causas:
- Rocket nao detecta chegada ao alvo (distancia check no plano XZ)
- Collision layers incorretas (layer 8, mask 2)
- ObjectPool retornando instancias em estado invalido
- `GameManager.get_enemies_in_radius()` nao encontrando inimigos na explosao
- Rocket sendo liberado/reciclado antes de explodir
- Problema com o target_pos sendo calculado incorretamente

## Solucao

1. Debugar o fluxo completo: disparo → viagem → chegada → explosao → dano
2. Corrigir o ponto de falha identificado
3. Garantir que a explosao aplica dano a todos inimigos no raio
4. Verificar efeitos visuais da explosao

## Criterios de aceitacao

- [ ] Bazuca dispara foguetes corretamente
- [ ] Foguetes viajam ate o alvo
- [ ] Explosao ocorre ao chegar no alvo
- [ ] Dano em area aplicado aos inimigos no raio
- [ ] Efeitos visuais de explosao funcionando (flash, fogo, shockwave)
- [ ] Funciona em single-player e multiplayer
