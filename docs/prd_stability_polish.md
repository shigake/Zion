# PRD — Estabilidade, Polish e Pré-lançamento

> Tarefas que podem ser implementadas sem rodar o jogo ou depender de ação externa. Foco em corrigir erros conhecidos, conectar sistemas novos, e preparar para lançamento.

---

## Tarefa 1: Conectar sprites dos alt bosses no boss_generic.gd

**Objetivo:** Garantir que os 20 novos bosses carreguem seus sprites corretos em vez do fallback procedural.

### Detalhes

O `boss_generic.gd` herda de `enemy_base.gd` que carrega sprites por `enemy_type`. Os novos bosses têm sprites em `res://assets/sprites/bosses/cemetery_lich.png` etc, mas o `_apply_sprite()` procura por tipo de inimigo, não por `boss_name`.

Adicionar lógica no `boss_generic._ready()` para carregar sprite pelo nome do boss.

### Critérios de aceite

- [ ] 20 alt bosses mostram sprite pixel art correto
- [ ] Fallback para mesh procedural se sprite não existir

---

## Tarefa 2: Dialogos de boss para os 20 novos bosses

**Objetivo:** Cada novo boss tem frase de intro e morte no BossDialogue.

### Detalhes

O `BossDialogue` já funciona para os 10 originais. Adicionar entradas para os 20 novos.

### Critérios de aceite

- [ ] 20 novos bosses têm frase de intro
- [ ] 20 novos bosses têm frase de morte
- [ ] Dialogos aparecem no typewriter com cor tematica

---

## Tarefa 3: Fix guard para todos os weapon scripts que usam ObjectPool

**Objetivo:** Prevenir erros "Invalid assignment of property" quando ObjectPool retorna node sem script.

### Detalhes

Adicionar guard em TODOS os weapon scripts que fazem `bullet.direction = ...` ou similar, não só shuriken. Verificar: machinegun, dual_pistol, crossbow, magic_book, drone, boomerang.

### Critérios de aceite

- [ ] Nenhum weapon script crasha se bullet.gd falhar parse
- [ ] Guard pattern consistente em todos os ranged weapons

---

## Tarefa 4: Fix necro.gd "not inside tree" errors

**Objetivo:** Prevenir erros quando necro tenta usar global_position fora da tree.

### Detalhes

`necro.gd` chama `_spawn_summon_circle()` que acessa `global_position` de nodes que podem não estar na tree. Adicionar guards.

### Critérios de aceite

- [ ] Zero erros "!is_inside_tree()" do necro.gd

---

## Tarefa 5: Fix loading_screen chamada duplicada e erro de cena

**Objetivo:** Corrigir "Ja esta carregando" warning e "Cena nao carregou" error.

### Detalhes

O log mostra que `load_stage` é chamado 2x seguidas (do relic_select). Adicionar debounce. Também investigar por que a cena falha ao carregar na primeira vez.

### Critérios de aceite

- [ ] Sem chamada duplicada de load_stage
- [ ] Cena carrega na primeira tentativa

---

## Tarefa 6: Novos achievements para os novos sistemas

**Objetivo:** Adicionar achievements para chests, quests e alt bosses.

### Detalhes

Achievements novos:
- "Treasure Hunter" — coletar 10 baús numa run
- "Quest Master" — completar 5 quests numa run
- "Boss Slayer" — derrotar 2 bosses numa run
- "Variety Show" — enfrentar um boss alternativo
- "Speed Chest" — coletar baú em menos de 5s após spawn
- "Perfect Quest" — completar quest "survive" sem tomar dano
- "Completionist" — completar todas as 10 fendas

### Critérios de aceite

- [ ] 7 novos achievements registrados
- [ ] Cada um desbloqueia corretamente
- [ ] Sync com Steam via SteamManager

---

## Tarefa 7: Atualizar event_manager para runs de 10 min

**Objetivo:** Reajustar timeline de eventos para partidas de 10 min (era 15).

### Detalhes

Eventos atuais estão distribuídos em 22 min. Com runs de 10 min, muitos eventos nunca acontecem. Redistribuir:
- Min 1.5: golden_horde
- Min 3: elite_horde
- Min 4: eclipse
- Min 5: (boss spawn)
- Min 6: meteor_shower ou roulette
- Min 7: miniboss
- Min 8: massive_horde
- Min 9: portal_dimensional ou miniboss_strong
- Min 10: (boss final)

### Critérios de aceite

- [ ] Todos os 9 tipos de evento podem ocorrer em 10 min
- [ ] Eventos não sobrepõem boss spawns
- [ ] Pacing mais intenso e dinâmico

---

## Tarefa 8: Atualizar contadores no CLAUDE.md e prd.md

**Objetivo:** Refletir o estado real do projeto (30 bosses, quests, chests, etc).

### Critérios de aceite

- [ ] CLAUDE.md atualizado com contadores corretos
- [ ] prd.md atualizado com features novas listadas

---

## Tarefa 9: Limpar imports e .uid files não trackeados

**Objetivo:** Adicionar .uid files ao .gitignore e limpar o working tree.

### Critérios de aceite

- [ ] .uid no .gitignore
- [ ] Working tree limpo (git status sem untracked)

---

## Ordem de implementação

| Fase | Tarefas | Descrição |
|---|---|---|
| A | 3, 4, 5 | Fixes de erros conhecidos |
| B | 1, 2 | Conectar novos bosses (sprites + dialogos) |
| C | 6, 7 | Novos achievements + reajuste de eventos |
| D | 8, 9 | Docs + cleanup |
