# ADR-005 — GameConstants: fonte única de verdade para magic numbers

**Status:** Aceito
**Data:** 2024-03

---

## Contexto

O jogo tem centenas de valores de balance espalhados: velocidade de inimigos, cooldown de armas, taxa de drop, escala de dificuldade, caminhos de cenas, etc. Esses valores estavam sendo duplicados entre scripts, causando inconsistências e dificultando ajustes de balance.

## Decisão

Criar um autoload **`GameConstants`** (`scripts/autoload/game_constants.gd`) como **única fonte de verdade** para todas as magic numbers e configurações do jogo.

- 712 linhas, 29 categorias organizadas por comentário de seção
- Registrado como o **primeiro autoload** no `project.godot` — disponível antes de qualquer outro singleton
- Todos os scripts referenciam `GameConstants.ALGUMA_CONSTANTE` em vez de valores literais

**Categorias cobertas:** fendas, bosses, personagens, armas, spawner, dificuldade, drops, visual, câmera, eventos, balance, UI, audio, performance, multiplayer, save, achievements, quests, baús, mutações, daily challenge, loja, relíquias, evoluções, sinergias, física e debug.

## Justificativa

- **Balance centralizado**: ajustar um número muda o comportamento em todos os lugares que o usam
- **Sem duplicação**: se `ENEMY_SPEED_BASE = 3.0` está em `GameConstants`, nenhum script precisa de `var speed = 3.0`
- **Discoverability**: novos devs encontram todos os valores configuráveis num só lugar
- **CI-friendly**: o balance test suite (`--test=balance`) lê de `GameConstants` para validar invariantes

## Alternativas Descartadas

| Alternativa | Por que descartada |
|-------------|-------------------|
| Arquivo JSON de configuração | Não tem tipagem; não pode conter expressões; precisa de parser |
| Constantes espalhadas por script | Duplicação; difícil encontrar para ajustar |
| Resource (.tres) de configuração | Mais verboso; editor-only; não funciona bem em headless |
| Export vars no Inspector | Não funciona para autoloads sem cena associada |

## Consequências

- `GameConstants` cresce conforme o jogo cresce — 712 linhas é gerenciável com seções bem comentadas
- Scripts não devem ter magic numbers — todo número hardcoded deve virar uma constante nomeada
- Constante de performance (`LOD_CULL_DISTANCE`, `MAX_PICKUPS`, etc.) ficam aqui — fácil tunar em diferentes plataformas
