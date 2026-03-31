# PRD — Build, Export e Distribuição

> Preparação do jogo para lançamento: export Windows/Linux, página Itch.io, trailer e GitHub Release.

## Status: ~60% completo (infra pronta, falta execução manual)

---

## Tarefa 1: Export Windows Funcional

**Status:** ✅ Infraestrutura pronta

- [x] Export preset "Windows Desktop" existe no `game/export_presets.cfg`
- [x] CI/CD `build.yml` exporta automaticamente via GitHub Actions
- [x] Verificação de tamanho (> 10 MB) no pipeline
- [ ] Testar o `.exe` em uma máquina limpa (sem Godot instalado)
- [ ] Verificar audio, gameplay básico, versão no menu

### Nota: Flamethrower e Gasoline

Mantidos desabilitados (`flamethrower.disabled = true`, `gasoline` removido do pool). Não aparecem no level up.

---

## Tarefa 2: Export Linux

**Status:** ✅ Infraestrutura pronta

- [x] Export preset "Linux" existe no `game/export_presets.cfg`
- [x] CI/CD `build.yml` exporta Linux em paralelo com Windows
- [ ] Testar no Linux (VM ou WSL com display forwarding)

---

## Tarefa 3: Página Itch.io

**Status:** ❌ Pendente (manual)

- [ ] Criar página com título, descrição, screenshots, tags
- [ ] Upload builds Windows + Linux
- [ ] Banner e ícone configurados

### Detalhes

- **Título:** Zion — Survivors Roguelite
- **Tagline:** *"Survive the horde. Ascend beyond."*
- **Tags:** Survivors, Roguelite, Co-op, Pixel Art, 3D, Top-down, Hack and Slash
- **Preço:** R$20-30 (definir)

---

## Tarefa 4: Trailer de 30 Segundos

**Status:** ❌ Pendente (manual)

| Segundo | Conteúdo |
|---|---|
| 0-3 | Logo ZION + partículas douradas |
| 3-8 | Fragmentado entrando na fenda |
| 8-15 | Horda de inimigos + combate + evoluções |
| 15-20 | Boss fight (Sentinela com aura) |
| 20-25 | Cross-combo multiplayer + level up |
| 25-28 | Vitória + tagline |
| 28-30 | Logo + link |

- [ ] Capturar gameplay com OBS Studio
- [ ] Editar trailer de 30s (1080p, 60 FPS)
- [ ] Publicar no YouTube

---

## Tarefa 5: GitHub Release v1.0.0

**Status:** ✅ Pipeline pronto

- [x] CI/CD `build.yml` cria tag, gera changelog, e publica release com binários
- [x] Pacotes zip Windows + Linux com LEIA-ME.txt
- [x] Verificação de incremento de versão
- [ ] Executar workflow `Build e Release` no GitHub Actions
- [ ] Criar changelog final completo

---

## Resumo

| Tarefa | Infra | Execução Manual |
|--------|-------|-----------------|
| Export Windows | ✅ Preset + CI/CD | Testar em máquina limpa |
| Export Linux | ✅ Preset + CI/CD | Testar em Linux |
| Itch.io | ❌ | Criar página + upload |
| Trailer | ❌ | Capturar + editar |
| GitHub Release | ✅ Pipeline completo | Disparar workflow |

## Prioridade

Alta — Sprint 4 do roadmap. Depende de QA (Sprint 3) estar satisfatório.
