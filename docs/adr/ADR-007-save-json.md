# ADR-007 — Save em JSON local (user://)

**Status:** Aceito
**Data:** 2024-01

---

## Contexto

Precisávamos de um sistema de persistência para: cristais acumulados, upgrades comprados, personagens e fases desbloqueados, conquistas, histórico de runs, leaderboard local, bestiário e codex.

## Decisão

Salvar tudo em **um único arquivo JSON** em `user://save_data.json`.

O `SaveManager` é um autoload que carrega o arquivo no `_ready()` e expõe `data: Dictionary` para leitura/escrita direta pelos outros sistemas.

```gdscript
SaveManager.data["crystals"] += 100
SaveManager.save_game()
```

## Justificativa

- **Simplicidade**: JSON é human-readable — fácil debugar, editar manualmente em desenvolvimento
- **`user://`**: caminho portátil do Godot que resolve para o diretório de dados do usuário no sistema operacional atual (Windows: `%APPDATA%/Zion/`, Linux: `~/.local/share/Zion/`)
- **Sem dependência externa**: não precisa de SQLite, LiteDB ou qualquer biblioteca
- **Tamanho pequeno**: os dados de save do Zion cabem em poucos KB — JSON é eficiente o suficiente
- **Steam Cloud**: `user://` é o diretório que o Steam sincroniza automaticamente — compatível com cloud saves sem configuração extra

## Estrutura do Save

```json
{
  "crystals": 0,
  "upgrades": {},
  "unlocked_characters": ["amazona", "bruxa", ...],
  "unlocked_stages": ["cemetery"],
  "total_runs": 0,
  "total_kills": 0,
  "best_time": 0.0,
  "achievements": [],
  "completed_stages": [],
  "leaderboard": [],
  "bestiary": {},
  "codex": [],
  "player_name": "Anonymous",
  "pending_leaderboard_scores": [],
  "best_run": {},
  "story_seen": false
}
```

## Consequências

- **Sem versionamento de schema**: se a estrutura mudar, saves antigos precisam de migração manual. Mitigar com `data.get("campo", valor_default)` em vez de acesso direto
- **Sem criptografia**: jogadores podem editar o save facilmente. Aceitável — é um roguelite, não há economy online competitiva
- **Scores offline**: `pending_leaderboard_scores` armazena runs realizadas offline para enviar ao servidor de telemetria quando conectar
- Scores do leaderboard online ficam no servidor Node.js, não no save local
