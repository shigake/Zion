# PRD — Atualizacao de Documentacao

> **Status: Pendente**
> Revisao completa de toda a documentacao do projeto para refletir o estado atual do codigo, features implementadas, e novos sistemas adicionados.

## Objetivo

Atualizar toda a documentacao em `docs/` e `CLAUDE.md` para refletir com precisao o estado atual do projeto. Muitas features foram implementadas desde a ultima revisao e a documentacao esta desatualizada.

## Escopo

### 1. CLAUDE.md (Guia de Desenvolvimento)
- [ ] Atualizar contadores (scripts, cenas, etc.) com numeros reais
- [ ] Atualizar lista de autoloads se novos foram adicionados
- [ ] Atualizar secao "Current Phase" com progresso real
- [ ] Atualizar secao "Remaining Work" com trabalho realmente faltante
- [ ] Verificar se todos os caminhos de arquivos mencionados existem
- [ ] Adicionar novos sistemas ao "Key Systems" (ex: mutacoes, cross-combo se implementados)

### 2. docs/gdd.md (Game Design Document)
- [ ] Atualizar visao geral do jogo com features atuais
- [ ] Adicionar mecanicas novas implementadas (eventos, reliquias, etc.)
- [ ] Atualizar loop de gameplay se mudou
- [ ] Revisar secao de multiplayer com mecanicas novas (cross-combo, revive)

### 3. docs/prd.md (Product Requirements / Roadmap)
- [ ] Marcar fases 0-2 como completas com detalhes
- [ ] Atualizar progresso das fases 3-6
- [ ] Adicionar novas tarefas planejadas (mutacoes, cross-combo, revive)
- [ ] Revisar prioridades baseado no estado atual

### 4. docs/spec.md (Especificacao Tecnica)
- [ ] Atualizar arquitetura com novos autoloads/singletons
- [ ] Documentar sistema de telemetria
- [ ] Documentar sistema de debug overlay (F3/F4)
- [ ] Atualizar diagramas de fluxo se existirem
- [ ] Adicionar especificacao dos novos sistemas (mutacoes, etc.)

### 5. docs/mecanicas.md
- [ ] Verificar todas as mecanicas listadas vs implementadas
- [ ] Marcar como implementadas as que ja foram feitas
- [ ] Adicionar mecanicas novas (sinergias cruzadas multiplayer, revive com sacrificio)
- [ ] Atualizar valores de balanceamento se mudaram

### 6. docs/personagens.md
- [ ] Verificar que todos os 12 personagens estao documentados
- [ ] Atualizar stats se balanceamento mudou
- [ ] Adicionar info sobre modelos 3D / concept art
- [ ] Revisar condicoes de desbloqueio

### 7. docs/fases.md
- [ ] Verificar que todas as 10 fases estao documentadas
- [ ] Atualizar detalhes de props/ambiente se mudaram
- [ ] Adicionar info sobre bosses e eventos por fase
- [ ] Revisar dificuldade e scaling

### 8. docs/itens.md
- [ ] Verificar lista de 19 itens, 12 evolucoes, 7 reliquias
- [ ] Atualizar descricoes e valores se mudaram
- [ ] Marcar itens implementados vs pendentes

### 9. docs/progressao.md
- [ ] Atualizar economia (cristais, upgrades, precos)
- [ ] Documentar sistema de mutacoes (se implementado)
- [ ] Revisar loja com upgrades atuais

### 10. PRDs Existentes
- [ ] `prd_missing_features.md` — atualizar checklist com status real
- [ ] `prd_balancing.md` — revisar valores de balanceamento
- [ ] `prd_visual_polish.md` — marcar itens concluidos
- [ ] `prd_ui_ux_fixes.md` — marcar itens concluidos
- [ ] `prd_3d_models.md` — atualizar com novos prompts/concepts
- [ ] `prd_telemetry.md` — verificar se tudo implementado esta marcado

### 11. README.md
- [ ] Atualizar descricao do projeto
- [ ] Atualizar screenshots se houver novos
- [ ] Atualizar instrucoes de build se mudaram
- [ ] Atualizar lista de features

## Criterios de Qualidade

- Toda feature implementada deve estar marcada como [x] nos PRDs
- Toda feature pendente deve estar marcada como [ ]
- Nenhum caminho de arquivo inexistente deve ser referenciado
- Contadores numericos (scripts, cenas, etc.) devem refletir a realidade
- Valores de balanceamento devem corresponder ao codigo atual
- Nenhum sistema "fantasma" (documentado mas nao existe) deve permanecer

## Processo

1. Fazer `git log` e listar todas as features adicionadas recentemente
2. Fazer inventario do codigo atual (contar scripts, cenas, autoloads)
3. Comparar documentacao vs codigo, identificar gaps
4. Atualizar cada documento sistematicamente
5. Commit unico com todas as atualizacoes de docs
