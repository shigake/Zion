# Zion — PRD: Distribuição via GitHub Releases (v1.0)

## Objetivo

Estabelecer um pipeline automatizado e seguro para distribuir builds do jogo Zion para testers e jogadores via **GitHub Releases**, aproveitando o CI/CD já existente (`build.yml`).

## Contexto

O projeto já possui um workflow GitHub Actions (`build.yml`) que:
- Faz export do jogo para Windows via Godot 4
- Gera `.zip` com o executável + LEIA-ME.txt
- Cria uma GitHub Release automaticamente ao push de tag `v*`
- Suporta disparo manual via `workflow_dispatch`

Este PRD formaliza o processo completo de distribuição, desde a geração do build até a notificação dos testers.

## Público-alvo

- **Testers internos** (amigos) — acesso direto ao link do Release
- **Comunidade** — futuro acesso via página pública do repositório

## Requisitos

### Sprint 1 — Processo de Release (2 tasks)

#### Task 1: Script de Release Automatizado
**Objetivo**: Criar um script que automatize todo o fluxo de release.
**Tempo estimado**: 30min

O script deve:
1. Ler a versão atual de `game/VERSION`
2. Criar a tag `v{VERSION}` localmente
3. Fazer push da tag para o remote
4. Aguardar o workflow `build.yml` iniciar
5. Exibir o link do Release quando pronto

```bash
# Uso esperado:
./release.sh
# ou
./release.sh 3.2.0  # versão manual
```

**Critérios de aceite**:
- [ ] Script `release.sh` na raiz do projeto
- [ ] Lê versão de `game/VERSION` se não fornecida como argumento
- [ ] Cria tag git e faz push
- [ ] Exibe URL da release: `https://github.com/shigake/Zion/releases/tag/v{VERSION}`
- [ ] Validação: impede criar tag se já existir

#### Task 2: Release Notes Automáticas
**Objetivo**: Gerar changelog automático na descrição da Release.
**Tempo estimado**: 30min

Melhorar o `build.yml` para incluir changelog automático baseado nos commits desde a última tag:

**Critérios de aceite**:
- [ ] Body da Release inclui lista de commits desde a última tag
- [ ] Commits agrupados por tipo (feat, fix, docs, chore, perf)
- [ ] Inclui instruções de instalação para Windows
- [ ] Inclui aviso sobre Windows Defender (executável não assinado)
- [ ] Link para reportar bugs (GitHub Issues)

### Sprint 2 — Qualidade do Build (2 tasks)

#### Task 3: Checklist Pré-Release no Workflow
**Objetivo**: Garantir qualidade mínima antes de publicar.
**Tempo estimado**: 20min

Adicionar steps de validação ao `build.yml`:

**Critérios de aceite**:
- [ ] Step de `--headless --import` valida que o projeto não tem erros de parse
- [ ] Verificar que o `game/VERSION` foi incrementado em relação à última tag
- [ ] Verificar que o arquivo `.exe` gerado tem tamanho > 10MB (sanity check)
- [ ] Falha no workflow impede criação da Release

#### Task 4: Build Multi-plataforma (Linux)
**Objetivo**: Gerar build para Linux além de Windows.
**Tempo estimado**: 40min

**Critérios de aceite**:
- [ ] Export preset "Linux" configurado no `export_presets.cfg`
- [ ] Workflow gera `Zion-v{VERSION}-linux.zip` além do Windows
- [ ] Ambos os zips são anexados à Release
- [ ] LEIA-ME.txt atualizado com instruções Linux (`chmod +x`)

### Sprint 3 — Experiência do Tester (2 tasks)

#### Task 5: Página de Download Amigável
**Objetivo**: README com instruções claras para testers.
**Tempo estimado**: 20min

**Critérios de aceite**:
- [ ] Seção "Download & Play" no README.md com link direto para latest release
- [ ] Badge de versão no topo do README (shields.io)
- [ ] Instruções passo-a-passo: baixar → descompactar → executar
- [ ] FAQ: Windows Defender, requisitos mínimos, como reportar bugs
- [ ] Screenshot ou GIF do jogo no README

#### Task 6: Notificação Discord de Nova Release
**Objetivo**: Avisar testers automaticamente quando sair build novo.
**Tempo estimado**: 30min

Adicionar step ao `build.yml` que notifica o Discord:

**Critérios de aceite**:
- [ ] Webhook Discord disparado após Release ser criada com sucesso
- [ ] Mensagem inclui: versão, link de download, changelog resumido
- [ ] Usa secret `DISCORD_WEBHOOK_URL` do repositório
- [ ] Formato embed bonito com thumbnail do jogo

## Fluxo Completo de Release

```
Dev termina feature
    ↓
Incrementa game/VERSION
    ↓
git commit + git push
    ↓
./release.sh (cria tag + push)
    ↓
GitHub Actions (build.yml)
    ├── Import + validação
    ├── Export Windows (.exe)
    ├── Export Linux (futuro)
    ├── Empacota .zip + LEIA-ME
    ├── Cria GitHub Release com changelog
    └── Notifica Discord
    ↓
Testers baixam de:
https://github.com/shigake/Zion/releases/latest
```

## Segurança

- **Executável não assinado**: Windows Defender vai alertar. Instruções de bypass no LEIA-ME.
- **Repositório público**: Qualquer pessoa pode baixar. Se quiser restringir, tornar repo privado.
- **Sem dados sensíveis**: O build não inclui código-fonte, apenas o executável compilado.
- **Integridade**: GitHub gera hash SHA256 automático para cada asset da Release.

## Métricas de Sucesso

- Testers conseguem baixar e jogar em < 5 minutos
- Zero perguntas sobre "como instalar"
- Release criada em < 10 minutos após push da tag
- 100% dos builds passam pela validação pré-release

## Resumo de Tasks

| # | Task | Sprint | Tempo | Prioridade |
|---|------|--------|-------|------------|
| 1 | Script de release automatizado | 1 | 30min | 🔴 Alta |
| 2 | Release notes automáticas | 1 | 30min | 🔴 Alta |
| 3 | Checklist pré-release no workflow | 2 | 20min | 🟡 Média |
| 4 | Build multi-plataforma (Linux) | 2 | 40min | 🟡 Média |
| 5 | Página de download amigável | 3 | 20min | 🟡 Média |
| 6 | Notificação Discord de nova release | 3 | 30min | 🟡 Média |

**Tempo total estimado**: ~2h50min
