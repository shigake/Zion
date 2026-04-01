# ADR-014 — Stage-Scoped Parameter Override no GameManager

**Status:** Aceito
**Data:** 2025-01 (implementado no PRD-27)

---

## Contexto

O Mundo Doce (`candy`) é uma anomalia dimensional cujo design exigia testar diferentes tamanhos de mapa sem afetar os outros 9 stages. O parâmetro `GameManager.map_half_size` é global e usado por todos os stages para definir os limites de movimento e a barreira invisível.

Precisávamos de um mecanismo para que um stage específico sobrescreva parâmetros globais do `GameManager` durante sua sessão e os restaure ao sair — sem criar uma configuração por-stage hardcoded no `GameManager`.

## Decisão

**Stages podem sobrescrever parâmetros globais do GameManager no `_ready()` e restaurá-los no `_exit_tree()`.** O stage é responsável por salvar o valor original e restaurá-lo.

```gdscript
# stage_candy.gd
const CANDY_MAP_HALF_SIZE = 47.5   # mapa reduzido para teste
var _original_map_half_size: float

func _ready() -> void:
    _original_map_half_size = GameManager.map_half_size
    GameManager.map_half_size = CANDY_MAP_HALF_SIZE

func _exit_tree() -> void:
    GameManager.map_half_size = _original_map_half_size
```

O valor `47.5` corresponde a `area_size * 2 / 2 + margem` — mantém a barreira 7.5 unidades além da borda visível do plano de chão (consistente com o padrão dos outros stages).

## Justificativa

- **Sem acoplamento no GameManager**: adicionar um `if stage == "candy"` no `GameManager` seria um smell. O stage conhece suas próprias necessidades; o `GameManager` não precisa conhecer cada stage.
- **Reversibilidade garantida**: `_exit_tree()` é chamado mesmo em casos de crash de script — mais confiável que signals ou callbacks manuais.
- **Padrão reutilizável**: qualquer stage futuro pode sobrescrever qualquer parâmetro global com este pattern. Documentado como padrão oficial do projeto.
- **Testabilidade**: o teste de tamanho de mapa é isolado ao Mundo Doce — nenhum outro stage é afetado.

## Parâmetros Que Podem Ser Sobrescritos

Atualmente o pattern é usado para:
- `GameManager.map_half_size` — tamanho do mapa / posição da barreira

Candidatos futuros (não implementados ainda):
- `GameManager.max_enemies` — para stages de arena com regras especiais
- `GameManager.time_scale` — para eventos de anomalia temporal

## Alternativas Descartadas

- **`@export` no script de props** — `area_size` já é `@export` nos props, mas o limite de movimento do jogador (`map_half_size`) fica no `GameManager`. Mudar apenas o plano visual sem mover a barreira causaria o jogador a andar no vazio.
- **Enum de configuração por stage no GameManager** — violaria o princípio Open/Closed. Adicionar cada novo stage exigiria editar o `GameManager`.
- **Signal `stage_changed`** — adicionaria latência de um frame entre troca de stage e aplicação do parâmetro.

## Consequências

- O stage DEVE restaurar todos os parâmetros sobrescritos — bug potencial se `_exit_tree()` não for implementado. Adicionar ao checklist de code review de novos stages.
- Parâmetros sobrescritos não são visíveis no `GameManager` como "override de stage" — um desenvolvedor inspecionando o GameManager em runtime verá o valor alterado sem contexto. Mitigação: adicionar comentário no código do override.
- O tamanho reduzido do Mundo Doce (80×80 vs 160×160 dos outros stages) é intencional para testes de densidade de inimigos e escopo narrativo (anomalia = realidade distorcida).
