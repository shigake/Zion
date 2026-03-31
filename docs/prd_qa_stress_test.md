# PRD — QA Completo e Stress Test

> Plano de testes abrangente cobrindo todas as combinações de personagem × fenda, multiplayer LAN, stress test de performance e verificação de evoluções/eventos.

## Status: ~80% automatizado

O `AutoTester` suporta 9 suites de teste via linha de comando:

```bash
godot --path game --run -- --test=smoke          # 26 testes rapidos
godot --path game --run -- --test=combo           # 150 combos (15 chars × 10 stages)
godot --path game --run -- --test=weapons         # Todas as armas individuais
godot --path game --run -- --test=evolution        # 12 evolucoes
godot --path game --run -- --test=events           # Timeline de eventos
godot --path game --run -- --test=stress           # Stress test (hyper, endless)
godot --path game --run -- --test=achievements     # 7 cenarios de achievements
godot --path game --run -- --test=balance          # XP, DPS, economia
godot --path game --run -- --test=all              # Todos os acima
godot --path game --run -- --test=menu_smoke       # Navegacao de menus
```

---

## Tarefa 1: Teste Automatizado de Combinações (15 × 10)

**Status:** ✅ Implementado — suite `combo`

O `TestRunner` itera por todos os 15 Fragmentados × 10 fendas (150 combos), rodando 60s cada com auto_play. Relatório JSON gerado em `user://test_results/`.

### Critérios de aceite

- [x] Suite `combo` implementada com 150 testes
- [x] AutoPlayer move, coleta XP, escolhe level ups automaticamente
- [x] Relatório gerado com status, FPS médio e erros por combo
- [ ] Rodar a suite completa e verificar 150/150 sem crash (requer ~2.5h de execução)

---

## Tarefa 2: Teste Multiplayer LAN (2-4 Jogadores)

**Status:** ⏳ Manual — requer 2+ instâncias

Não é possível automatizar teste multiplayer com uma única instância. Requer teste manual.

### Cenários de teste

| Cenário | Jogadores | Duração | Validação |
|---|---|---|---|
| Basic co-op | 2 | 5 min | Sync básica |
| Full run | 2 | 15 min | Boss + victory |
| Stress | 4 | 10 min | Performance com 500 inimigos |
| Disconnect | 2 → 1 | Qualquer | Host reajusta dificuldade |
| Rejoin | 2 → 1 → 2 | Qualquer | Reconnect funciona |

### Critérios de aceite

- [ ] Co-op 2P completa uma run inteira sem dessync
- [ ] Desconexão de client não crasha o host
- [ ] Performance > 30 FPS com 4 jogadores + 300 inimigos

---

## Tarefa 3: Stress Test de Performance

**Status:** ✅ Implementado — suite `stress`

3 cenários automáticos: hyper mode, max enemies, endless 10min.

### Targets

| Métrica | Target | Crítico |
|---|---|---|
| FPS médio | ≥ 60 | < 30 |
| FPS mínimo | ≥ 45 | < 20 |
| Inimigos simultâneos | 500 | N/A |
| Draw calls | < 300 | > 500 |
| RAM | < 500 MB | > 1 GB |

### Critérios de aceite

- [x] Suite `stress` com 3 cenários automatizados
- [ ] Rodar stress e verificar FPS > 30 sustentado (requer execução)
- [ ] Sem memory leaks (RAM estável após warmup)

---

## Tarefa 4: Verificação de Evoluções (12)

**Status:** ✅ Implementado — suite `evolution`

O `TestRunner` configura weapon lv8 + item lv5, roda 60s, e verifica se a evolução foi triggered.

### Critérios de aceite

- [x] Suite `evolution` testa todas as 12 evoluções
- [x] Setup automático: weapon lv8 + item lv5
- [x] Detecta se evolução foi triggered
- [ ] Rodar e verificar 12/12 evoluções funcionam (requer execução)

---

## Tarefa 5: Verificação de Eventos (10)

**Status:** ✅ Implementado — suite `events`

Run de 23 min cobrindo todos os eventos timed + 3 stages adicionais.

### Critérios de aceite

- [x] Suite `events` com timeline completa (23 min)
- [x] Testes em 4 stages diferentes
- [ ] Rodar e verificar todos os 10 eventos ativam (requer execução)

---

## Resumo

| Tarefa | Automação | Status |
|--------|-----------|--------|
| 150 combos | ✅ suite `combo` | Falta rodar |
| Multiplayer LAN | ❌ Manual | Pendente |
| Stress test | ✅ suite `stress` | Falta rodar |
| Evoluções | ✅ suite `evolution` | Falta rodar |
| Eventos | ✅ suite `events` | Falta rodar |

## Prioridade

Alta — Sprint 3 do roadmap (pré-release). Automação pronta, falta executar.
