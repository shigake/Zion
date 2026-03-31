# ADR-010 — Regra narrativa: toda feature respeita a lore

**Status:** Aceito
**Data:** 2024-05 (formalizado)

---

## Contexto

À medida que o jogo crescia, features técnicas eram implementadas sem considerar a narrativa — o resultado eram inconsistências: "o jogador morre" em vez de "o Fragmentado é rebobinado", "moeda" em vez de "cristais de Zion", "boss morto" em vez de "Sentinela libertado".

## Decisão

**Toda feature nova DEVE respeitar a narrativa definida em `docs/story.md`.**

Terminologia obrigatória:

| Conceito técnico | Termo narrativo |
|------------------|----------------|
| Jogador | Fragmentado |
| Moeda / XP | Cristais (fragmentos de Zion) |
| Fase / mapa | Fenda dimensional |
| Boss | Sentinela Corrompido |
| Morrer | Ser rebobinado ao hub |
| Loja | Zion se reconstruindo |
| Upgrade de arma | Ressonância cristalina |
| Morte permanente do boss | Libertação do Sentinela |
| Dificuldade extra | Provação de Zion |

## Justificativa

- **Coerência**: jogadores que leem os diálogos e loading screens devem encontrar a mesma linguagem nas UIs e mecânicas
- **Diferenciação**: a narrativa é o que distingue Zion de outros clones de Vampire Survivors. Perder isso por preguiça de nomenclatura é perder identidade
- **Imersão**: quando a mecânica e a narrativa se alinham (ex: "sacrificar cristal para reviver aliado" = "ceder parte do estilhaço"), o jogo comunica suas regras sem tutorial explícito

## Implementação

- Loading screens exibem fragmentos de lore de `story.md`
- Diálogos dos Sentinelas (`BossDialogue`) revelam a história do guardião antes e durante o boss fight
- Tela de morte mostra "O estilhaço te rebobina..." em vez de "Game Over"
- Tela de vitória mostra "Sentinela libertado — mais um pedaço de Zion restaurado"
- Backstories dos 15 Fragmentados disponíveis em `docs/personagens.md`
- O personagem "???" (`mystery.gd`) é a thread narrativa principal — tem cutscene própria (`mystery_cutscene.gd`)

## Consequências

- PRDs de feature devem incluir seção de impacto narrativo
- Textos de UI em `sentence case` (primeira letra maiúscula) — nunca `TUDO MAIÚSCULO` estilo anos 90
- Novos bosses são "Sentinelas Corrompidos" com motivação de aprisionamento, não vilões genéricos
- A lore de cada fenda justifica sua mecânica única (ex: correntes no oceano = "vontade primitiva do mar")
