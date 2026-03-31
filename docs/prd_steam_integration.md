# PRD — Integração Steam (GodotSteam)

> Substituir ENet por Steam Networking Sockets, ativar Achievements Steam e Cloud Save.

## Status: Código 100% pronto, bloqueado na instalação do plugin GodotSteam

Todo o código de integração está implementado. Falta instalar o plugin GodotSteam (GDExtension) para ativar.

---

## Tarefa 1: Instalação e Inicialização do GodotSteam

**Status:** ⏳ Bloqueado — falta instalar plugin

- [ ] Instalar GodotSteam GDExtension (baixar de [GodotSteam Releases](https://github.com/GodotSteam/GodotSteam))
- [ ] Criar `steam_appid.txt` com App ID (usar `480` para testes)
- [x] `SteamManager.is_available` retorna `true` quando Steam detectado
- [x] Fallback gracioso para ENet quando Steam indisponível

---

## Tarefa 2: Steam Networking Sockets

**Status:** ⏳ Bloqueado — falta plugin

- [x] ENet local continua funcionando como fallback
- [x] Código de branch Steam vs. ENet no `MultiplayerManager`
- [ ] Testar co-op via Steam entre 2 máquinas (requer plugin)

---

## Tarefa 3: Steam Achievements

**Status:** ✅ Código pronto

- [x] 13 achievements mapeados para Steam API IDs
- [x] `AchievementManager` chama `Steam.setAchievement()` + `Steam.storeStats()` no unlock
- [x] Sem duplicação se achievement já desbloqueado
- [ ] Popup do Steam aparece junto com popup do jogo (requer plugin)

### Mapeamento

| Achievement Local | Steam API ID |
|---|---|
| Meu Primeiro Passeio | `ACH_FIRST_WALK` |
| Isso Escala | `ACH_SIX_EVOLUTIONS` |
| Pacifista | `ACH_PACIFIST` |
| Speedrunner | `ACH_SPEEDRUNNER` |
| Colecionador | `ACH_COLLECTOR` |
| Lucky Day | `ACH_LUCKY_DAY` |
| A Vaca Foi Pro Brejo | `ACH_COW_DODGE` |
| Matrix | `ACH_MATRIX` |
| One Punch | `ACH_ONE_PUNCH` |
| Ninguem Merece | `ACH_INSTANT_DEATH` |
| Genocidio | `ACH_GENOCIDE` |
| Doce Vinganca | `ACH_SWEET_REVENGE` |
| I Am The Storm | `ACH_STORM` |

---

## Tarefa 4: Steam Cloud Save

**Status:** ✅ Código pronto

- [x] Save sincroniza com Steam Cloud automaticamente
- [x] Conflito resolvido pelo timestamp mais recente
- [x] Fallback local se Steam Cloud offline

---

## Resumo

| Tarefa | Código | Plugin Necessário |
|--------|--------|-------------------|
| Inicialização | ✅ | Sim — GodotSteam GDExtension |
| Networking | ✅ | Sim |
| Achievements | ✅ | Sim (para popup Steam) |
| Cloud Save | ✅ | Sim |

## Próximo passo

Instalar GodotSteam GDExtension compatível com Godot 4.x e testar tudo.

## Prioridade

Média — pós-release no Itch.io, pré-release no Steam.
