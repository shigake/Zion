# PRD — QA Completo e Stress Test

> Plano de testes abrangente cobrindo todas as combinações de personagem × fenda, multiplayer LAN, stress test de performance e verificação de evoluções/eventos.

---

## Tarefa 1: Teste Manual de Combinações (15 × 10)

**Objetivo:** Verificar que todas as 150 combinações de personagem + fenda são jogáveis sem crashes.

### Contexto

O projeto tem 15 Fragmentados (`CharacterDB`) e 10 fendas (7 campanha + 3 anomalias). O `prd.md` Sprint 3 exige teste de todas as 150 combinações.

### Detalhes

Usar o mode `auto_play` existente em `GameManager` (`auto_play = true`, linha 120) para automatizar level ups. Para cada combo:

1. Selecionar personagem + fenda
2. Ativar `auto_play = true`
3. Rodar por 5 minutos mínimo (ou até o boss spawnar)
4. Verificar: sem crashes, sem erros fatais no log, FPS > 30

### Matriz de teste (resumida)

| Fragmentado | Arma Inicial | Fendas a testar |
|---|---|---|
| Ronin | Katana | Todas 10 |
| Soldado | Machinegun | Todas 10 |
| Mago | Staff | Todas 10 |
| ... | ... | ... |
| ??? | Todas lv1 | Todas 10 |

### Automação sugerida

O `AutoTester` (`res://scripts/autoload/auto_tester.gd`) já existe — estender para iterar por todas as combos:

```gdscript
func run_full_matrix():
    var chars = CharacterDB.get_all_character_ids()
    var stages = ["cemetery","forest","farm","tokyo","volcano","ocean","arena","space","castle","candy"]
    for char_id in chars:
        for stage in stages:
            _test_combo(char_id, stage, 300.0)  # 5 min
```

### Critérios de aceite

- [ ] 150/150 combinações executam sem crash
- [ ] Relatório gerado com status, FPS médio e erros por combo
- [ ] Bugs encontrados documentados com reprodução

---

## Tarefa 2: Teste Multiplayer LAN (2-4 Jogadores)

**Objetivo:** Verificar que co-op local funciona com 2 instâncias mínimo.

### Detalhes

1. Abrir 2 instâncias do jogo na mesma máquina (ou 2 máquinas na mesma rede)
2. Host cria lobby, Client se conecta via IP
3. Verificar:
   - Sync de personagens no lobby (Tarefa 2 do PRD Multiplayer)
   - XP compartilhado (level up simultâneo)
   - Projéteis falsos (visual no client, lógica no host)
   - Death + tombstone + revive
   - Boss sync (todas as fases)
   - Game Over (quando todos morrem)
   - Desconexão graceful

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

**Objetivo:** Garantir 60 FPS com 500 inimigos na tela em hardware médio.

### Contexto

O `PerfMonitor` (`res://scripts/autoload/perf_monitor.gd`) e o `DebugOverlay` (F3) já existem para métricas. O cap de inimigos é 500 (`GameManager.max_enemies = 500`).

### Detalhes

1. Configurar cenário de stress: Modo Endless, Horda Infinita (mutação), minuto 20+
2. Métricas a coletar via `PerfMonitor`:
   - FPS médio, mínimo, P99
   - Enemy count (alvo: 400-500 simultâneos)
   - Draw calls
   - Memória RAM e VRAM
3. Ferramentas de profiling:
   - `F3` → DebugOverlay (já integrado)
   - Godot Profiler (Monitor tab)
   - `--verbose` mode para logs de performance

### Targets

| Métrica | Target | Crítico |
|---|---|---|
| FPS médio | ≥ 60 | < 30 |
| FPS mínimo | ≥ 45 | < 20 |
| Inimigos simultâneos | 500 | N/A |
| Draw calls | < 300 | > 500 |
| RAM | < 500 MB | > 1 GB |

### Critérios de aceite

- [ ] Run de 15 min no modo Endless com todas as mutações ativas
- [ ] FPS nunca cai abaixo de 30 por mais de 2 segundos
- [ ] Sem memory leaks (RAM estável após warmup)

---

## Tarefa 4: Verificação de Evoluções (12)

**Objetivo:** Confirmar que todas as 12 evoluções de arma funcionam corretamente.

### Contexto

`EvolutionDB` (`res://scripts/autoload/evolution_db.gd`) define 12 evoluções. Condição: arma lv8 + item lv5 = baú dimensional aparece.

### Checklist

| Arma Base | Item Passivo | Evolução | Verificar |
|---|---|---|---|
| Katana | Luva de Velocidade | Zangetsu | Ondas de energia |
| Bazuca | Pólvora Extra | Nuke Launcher | Mushroom cloud |
| Machinegun | Mira Laser | Minigun Infernal | Balas de fogo |
| Staff | Cristal Arcano | Cajado do Apocalipse | Meteoros |
| Foice | Capa das Sombras | Death Scythe | Executa <20% HP |
| Arco Elfíco | Aljava Infinita | Tempestade de Flechas | Chuva de flechas |
| Chain Elétrica | Bateria Tesla | Tempestade Elétrica | Storm permanente |
| Necromante | Grimório Negro | Senhor dos Mortos | Boss esqueleto |
| Lança-chamas | Gasolina | Inferno Walker | Rastro de fogo |
| Chicote | Sangue de Vampiro | Vampire Whip | Lifesteal massivo |
| Boomerang | TBD | TBD | Verificar se existe |
| Tornado | TBD | TBD | Verificar se existe |

### Critérios de aceite

- [ ] Todas as 12 evoluções ativam quando as condições são atendidas
- [ ] Baú dimensional spawna e é interagível
- [ ] Efeito visual e mecânico da evolução funciona
- [ ] Flamethrower + Gasoline funciona (se habilitados) ou está corretamente bloqueado

---

## Tarefa 5: Verificação de Eventos (10)

**Objetivo:** Confirmar que todos os 10 eventos dimensionais ativam nos timers corretos.

### Contexto

`mecanicas.md` define 10 eventos com timers específicos (Horda Dourada min 5, Eclipse min 8, etc.).

### Checklist

| Evento | Timer | Verificar |
|---|---|---|
| Horda Dourada | min 5 | Inimigos dourados + XP extra |
| Eclipse | min 8 | Tela escurece 30s |
| Chuva de Meteoros | min 12 | Dano em tudo |
| Treasure Goblin | Aleatório | Foge + dropa baú épico |
| Desafio do Anjo | min 15 | 2x dano, 50% HP |
| Portal Dimensional | min 20 | Mini-dungeon |
| Fever Mode | XP rápido | 10s de buff |
| Merchant | Aleatório | NPC com 3 itens |
| Chest Mimic | Aleatório | Mini-boss |
| Roda da Fortuna | min 10 | Buff/debuff randômico |

### Critérios de aceite

- [ ] Cada evento ativa no minuto correto (±30s de tolerância)
- [ ] Efeitos visuais e mecânicos funcionam
- [ ] Sem crashes durante nenhum evento
- [ ] Eclipse Total funciona com escurecimento de tela real

---

## Dependências

| Sistema | Tarefas |
|---|---|
| `AutoTester` (autoload) | 1 |
| `PerfMonitor` (autoload) | 3 |
| `DebugOverlay` (autoload) | 3 |
| `EvolutionDB` (autoload) | 4 |
| `MultiplayerManager` (autoload) | 2 |
| Event system (`event_manager.gd`) | 5 |

## Ordem de implementação

| Fase | Tarefas | Descrição |
|---|---|---|
| A | 4, 5 | Verificações rápidas — evoluções e eventos |
| B | 1 | Matriz de 150 combos (pode rodar overnight) |
| C | 3 | Stress test focado com profiling |
| D | 2 | Multiplayer LAN (requer 2+ máquinas) |

## Prioridade

Alta — Sprint 3 do roadmap (pré-release). Sem QA → sem confiança para lançar.
