# Changelog

Todas as mudancas notaveis do Zion sao documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/)
e o projeto adota [Versionamento Semantico](https://semver.org/lang/pt-BR/).

## [4.8.3]

### Adicionado
- Reliquia **Botas de Mercurio**: +15% de velocidade de movimento.
- Reliquia **Coracao de Vidro** (glass cannon): +30% de dano em troca de -30% de HP inicial.
- Achievement **Maratonista**: sobreviva 30 minutos numa run.
- Achievement **Dedicado**: complete 100 runs no total.

### Seguranca
- Removido `server/node_modules` do versionamento (risco de supply-chain e inchaco do repo).
- `.gitignore` ampliado para bloquear `.env`, chaves privadas (`*.pem`, `*.key`, `*.p12`),
  `id_rsa`, `credentials.json`, `service-account*.json` e `secrets.json`.
