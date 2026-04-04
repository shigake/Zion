# PRD 48 — Boss Necromancer invisível no cemitério

## Problema
O boss Necromancer na fase do cemitério aparece apenas como uma sombra — o jogador não consegue ver o boss. Relatado pelo tropeco durante jogatina.

## Causa raiz
O sprite do Necromancer usa cores extremamente escuras (robe: `0.22, 0.08, 0.30`, robe_dark: `0.12, 0.04, 0.18`) que se confundem com o fundo escuro do cemitério. O outline é ainda mais escuro (`0.08, 0.02, 0.12`).

## Solução
1. **Clarear as cores do robe** — manter estética sombria mas com contraste suficiente contra fundo escuro
2. **Aumentar brilho dos highlights** — robe_light mais visível
3. **Outline com mais contraste** — usar tom arroxeado em vez de quase-preto
4. **Aura mais visível** — aumentar opacidade da aura fantasmagórica verde
5. **Regenerar o sprite PNG**

## Critério de aceite
- Boss Necromancer claramente visível contra o fundo do cemitério
- Estética sombria/necromante mantida (não pode parecer colorido demais)
- Olhos verdes brilhantes continuam sendo destaque visual

## Status: concluído
