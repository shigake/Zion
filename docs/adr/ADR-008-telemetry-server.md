# ADR-008 — Servidor de telemetria Node.js separado do jogo

**Status:** Aceito
**Data:** 2024-04

---

## Contexto

Precisávamos de visibilidade sobre como o jogo está sendo jogado: personagens mais escolhidos, fases mais jogadas, armas mais evoluídas, taxa de vitória por boss, tempo médio de run, crashes, etc.

## Decisão

Criar um **servidor de telemetria separado** em Node.js (`server/`) com:
- **API REST** para receber eventos do jogo
- **Banco SQLite** para persistência (`better-sqlite3`)
- **Dashboard web estático** em `server/public/` acessível em `http://localhost:3456`

O cliente no jogo é o autoload `Telemetry` que faz HTTP POST para o servidor.

## Justificativa

### Por que separado do jogo?

- O jogo (Godot) e o servidor têm ciclos de vida independentes — o servidor pode estar rodando enquanto o jogo não está
- Não polui o projeto Godot com lógica de servidor
- Node.js com Express + SQLite é o stack mais rápido de bootstrapar para um dashboard simples
- Múltiplos clientes (jogadores diferentes) podem enviar dados para o mesmo servidor

### Por que não um serviço externo (Mixpanel, Amplitude)?

- Custo zero com servidor próprio
- Privacidade dos dados dos jogadores
- Customização total do dashboard
- Sem dependência de terceiros para funcionar

### Notificações Discord

O servidor também serve como relay para notificações do desenvolvimento:
```bash
curl -X POST http://localhost:3123/notify -d '{"channel":"zion","message":"...","status":"done"}'
```

## Estrutura do Servidor

```
server/
├── index.js        # Express + SQLite (API REST + dashboard web)
├── package.json    # express, better-sqlite3
├── .env.example    # PORT, API_KEY, DISCORD_WEBHOOK_URL
└── public/         # Dashboard web estático
```

## Consequências

- O servidor é **opcional** — `Telemetry` falha silenciosamente se o servidor não estiver rodando
- Para desenvolvimento local: `cd server && npm install && npm start`
- Dashboard em `http://localhost:3456` — não exposto publicamente por padrão
- Em produção (pós-lançamento): hospedar em VPS barato ou Railway/Render
- Porta 3123 para notificações Discord (separada da 3456 do dashboard — verificar config atual)
