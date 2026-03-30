# PRD — Build, Export e Distribuição

> Preparação do jogo para lançamento: export Windows/Linux, página Itch.io, trailer e GitHub Release.

---

## Tarefa 1: Export Windows Funcional

**Objetivo:** Gerar um `.exe` funcional testado em máquina limpa.

### Contexto

O `CLAUDE.md` documenta o comando de export: `godot --headless --path game --export-release "Windows Desktop" ../build/zion.exe`. O CI/CD (`build.yml`) já tem um workflow de export por tags.

### Detalhes

1. Verificar que o export preset "Windows Desktop" existe no `game/export_presets.cfg`
2. Executar export local: `godot --headless --path game --export-release "Windows Desktop" ../build/zion.exe`
3. Testar o `.exe` em uma máquina limpa (sem Godot instalado):
   - Verifica se abre sem crash
   - Verifica se a versão do `game/VERSION` aparece no menu
   - Verifica se o audio toca (música + SFX)
   - Verifica se o gameplay básico funciona (1 run completa)
4. Verificar tamanho do build (~71 MB conforme `prd.md`)

### Atenção: Flamethrower e Gasoline

O `weapon_db.gd` marca `flamethrower` com `"disabled": true` (linha 250). Decisão pendente: reabilitar ou manter desabilitado. Se manter, garantir que não aparece no pool de level up. Se reabilitar, implementar mira manual (cone direction) ou converter para auto-aim.

### Critérios de aceite

- [ ] Build exporta sem erros
- [ ] `.exe` roda em máquina sem Godot
- [ ] Run completa de 15 min funciona no build exportado
- [ ] Tamanho do bundle < 100 MB

---

## Tarefa 2: Export Linux

**Objetivo:** Adicionar preset de Linux e verificar compatibilidade.

### Detalhes

1. Criar export preset "Linux/X11" no editor do Godot
2. Export: `godot --headless --path game --export-release "Linux/X11" ../build/zion.x86_64`
3. Testar no Linux (VM ou WSL com display forwarding) ou pedir teste da equipe

### Critérios de aceite

- [ ] Build Linux gera binário executável
- [ ] Gameplay básico funciona
- [ ] Audio e gráficos renderizam corretamente

---

## Tarefa 3: Página Itch.io

**Objetivo:** Criar a página de distribuição do jogo no Itch.io com assets visuais.

### Detalhes

1. **Título:** Zion — Survivors Roguelite
2. **Descrição curta:** *"Survive the horde. Ascend beyond."*
3. **Descrição longa:** Converter o README.md para linguagem de marketing (features, screenshots, lore)
4. **Screenshots:**
   - Menu principal (com logo + partículas douradas)
   - Gameplay mid-run (horda de inimigos, skills ativas)
   - Boss fight (Sentinela com aura + letterbox)
   - Level up screen (3 cards)
   - Co-op (2+ jogadores)
5. **Tags:** Survivors, Roguelite, Co-op, Pixel Art, 3D, Top-down, Hack and Slash
6. **Preço:** Definir (GDD sugere R$20-30)
7. **Upload:** Builds Windows + Linux

### Critérios de aceite

- [ ] Página acessível com descrição e screenshots
- [ ] Download funcional (Windows no mínimo)
- [ ] Banner e ícone do jogo configurados

---

## Tarefa 4: Trailer de 30 Segundos

**Objetivo:** Capturar gameplay para um trailer curto e impactante.

### Detalhes

Estrutura sugerida (30s):

| Segundo | Conteúdo |
|---|---|
| 0-3 | Logo ZION + partículas douradas (menu) |
| 3-8 | Fragmentado entrando na fenda (gameplay start) |
| 8-15 | Horda de inimigos + combate intenso + evoluções |
| 15-20 | Boss fight (Sentinela com aura) |
| 20-25 | Cross-combo multiplayer + level up |
| 25-28 | Vitória + "Survive the horde. Ascend beyond." |
| 28-30 | Logo + link itch.io |

Captura com OBS Studio ou ferramenta interna de recording do Godot.

### Critérios de aceite

- [ ] Trailer de 30s com gameplay real
- [ ] Resolução mínima 1080p, 60 FPS
- [ ] Publicado no YouTube e embeddado na página Itch.io

---

## Tarefa 5: GitHub Release v1.0.0

**Objetivo:** Criar release formal no GitHub com binários e changelog.

### Detalhes

1. Atualizar `game/VERSION` para `1.0.0`
2. Criar tag `v1.0.0`
3. O CI/CD `build.yml` deve gerar o release automaticamente ao detectar a tag
4. Changelog incluindo todas as features:
   - 15 Fragmentados, 32 armas, 12 evoluções
   - 10 fendas, 10 Sentinelas, 90 monstros
   - Co-op 2-4 jogadores
   - 6 modos de jogo
   - Leaderboard online + Daily Challenge

### Critérios de aceite

- [ ] Release v1.0.0 no GitHub com binários Windows
- [ ] Changelog completo
- [ ] CI/CD build pipeline verde

---

## Dependências

| Sistema | Tarefas |
|---|---|
| Export presets Godot | 1, 2 |
| CI/CD (`build.yml`) | 5 |
| Screenshots/OBS | 3, 4 |
| `game/VERSION` | 5 |
| Build final da `prd_qa_stress_test.md` | Todas (QA antes de release) |

## Ordem de implementação

| Fase | Tarefas | Descrição |
|---|---|---|
| A | 1, 2 | Exports funcionais (bloqueante para tudo) |
| B | 3 | Página Itch.io com screenshots |
| C | 4 | Trailer (depende de gameplay estável) |
| D | 5 | GitHub Release (último passo) |

## Prioridade

Alta — Sprint 4 do roadmap principal. O objectif final antes do Early Access.
