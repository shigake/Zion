# ADR-004 — Mundo 3D com sprites billboard para personagens e inimigos

**Status:** Aceito
**Data:** 2024-02

---

## Contexto

Zion tem estilo visual "3D low-poly estilizado com cel-shading, inspiração Zelda BotW". Porém criar modelos 3D rigged + animados para 15 personagens, 56 inimigos e 30 bosses seria inviável para uma equipe de 3 pessoas.

## Decisão

**Mundo:** Totalmente 3D (câmera isométrica, terreno, props, efeitos de partículas, iluminação dinâmica).

**Personagens e inimigos:** Sprites 2D em **Sprite3D billboard** — sempre voltados para a câmera, com animações por troca de frames.

**Modelos 3D completos:** Apenas para itens de loja, relíquias e elementos de ambiente onde a silhueta 3D importa. Quando necessário, usar **Blender 3.0+** para renderizar e exportar.

## Justificativa

- **Produtividade**: gerar 453+ sprites por script Python/Godot é viável; modelar/rigar 56 personagens 3D seria meses de trabalho
- **Estética coerente**: o estilo sprite-em-mundo-3D é intencional — mesma estética de jogos como Octopath Traveler, Paper Mario, Eastward
- **Performance**: Sprite3D com `ALPHA_CUT_DISCARD` é muito mais leve que meshes skinned com animações
- **Ferramental**: scripts em `game/scripts/tools/` geram sprites proceduralmente com variações por fenda
- **Cel-shading no ambiente**: o shader de cel-shading é aplicado nos props 3D e no terreno, mantendo a coerência visual mesmo com sprites 2D nos personagens

## Detalhes Técnicos

- `Sprite3D` com `billboard = BILLBOARD_ENABLED` e `alpha_cut = ALPHA_CUT_DISCARD`
- `ALPHA_CUT_DISCARD` evita artefatos de z-fighting que ocorriam com `OPAQUE_PREPASS`
- Sprites organizados em spritesheets por personagem: idle, walk, attack, hurt, death
- Props do cenário usam `MeshInstance3D` normais (sem billboard)
- `MultiMeshManager` agrupa inimigos do mesmo tipo para renderização em batch quando há mais de 50 instâncias

## Consequências

- 453+ sprites gerados proceduralmente — volume gerenciável via scripts
- Animações são simples (troca de frame) — sem blend trees, sem IK
- Personagens não têm sombra volumétrica realista (aceitável no estilo adotado)
- Modelos 3D completos requerem Blender 3.0+ — documentado como dependência de dev
