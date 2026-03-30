# PRD — Integração Steam (GodotSteam)

> Substituir ENet por Steam Networking Sockets, ativar Achievements Steam e Cloud Save para distribuição no Steam.

---

## Tarefa 1: Instalação e Inicialização do GodotSteam

**Objetivo:** Substituir o stub `steam_manager.gd` por uma integração real com a SDK do Steam.

### Contexto

O autoload `res://scripts/autoload/steam_manager.gd` (27 linhas) é um stub que verifica `Engine.has_singleton("Steam")` mas não faz nada além de logar se está disponível. O `MultiplayerManager` atual usa ENet puro. O GDD define Steam Networking Sockets como transporte primário.

### Detalhes

1. **Instalar GodotSteam** como GDExtension no projeto (baixar binários do [GodotSteam Releases](https://github.com/GodotSteam/GodotSteam) compatíveis com Godot 4.x).
2. Criar `steam_appid.txt` na raiz do `game/` com o App ID do Steamworks (usar `480` para testes — Space War).
3. Expandir `steam_manager.gd` com:
   - `steamInit()` + validação de status
   - `run_callbacks()` no `_process()` (já existe)
   - Getters: `getSteamID()`, `getPersonaName()`, `getFriendsList()`
   - Sinal `steam_initialized` para outros sistemas reagirem

### Critérios de aceite

- [ ] GodotSteam inicializa sem crash no editor e no export
- [ ] `SteamManager.is_available` retorna `true` quando Steam está rodando
- [ ] Fallback gracioso para ENet quando Steam não está disponível (sem regressão)

---

## Tarefa 2: Steam Networking Sockets (Substituir ENet)

**Objetivo:** Migrar o transporte de rede do `MultiplayerManager` de ENet para Steam Networking Sockets.

### Contexto

`res://scripts/autoload/multiplayer_manager.gd` (35KB, ~1000 linhas) usa `ENetMultiplayerPeer` para criar host/client. O GDD especifica Steam Networking Sockets para NAT traversal sem servidor dedicado.

### Detalhes

1. No `MultiplayerManager`, criar branch de inicialização:
   - Se `SteamManager.is_available` → usar `SteamMultiplayerPeer` do GodotSteam
   - Senão → manter `ENetMultiplayerPeer` como fallback local
2. Lobby Steam: Host chama `Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 4)`
3. Convites: ativar Overlay com `Steam.activateGameOverlayInviteDialog(lobby_id)`
4. Conexão: Client extrai o Steam ID do Host via lobby metadata e chama `connectPeer(host_steam_id)`

### Arquivos impactados

| Arquivo | Ação |
|---|---|
| `scripts/autoload/steam_manager.gd` | Expandir com lobby + invite API |
| `scripts/autoload/multiplayer_manager.gd` | Adicionar branch Steam vs. ENet |
| `scripts/ui/lobby_screen.gd` | Adicionar botão "Convidar via Steam" |

### Critérios de aceite

- [ ] Co-op funciona via Steam entre 2 máquinas na mesma rede
- [ ] Co-op funciona via Steam entre 2 máquinas em redes diferentes (NAT traversal)
- [ ] ENet local continua funcionando para testes offline

---

## Tarefa 3: Steam Achievements

**Objetivo:** Sincronizar os 13 achievements existentes com os Steam Achievements.

### Contexto

`res://scripts/autoload/achievement_manager.gd` gerencia 13 achievements locais (`progressao.md`). No Steam, achievements requerem: (1) registro no Steamworks Dashboard, (2) chamada de `Steam.setAchievement(id)` e `Steam.storeStats()`.

### Detalhes

Mapear cada achievement para um `stat_name` Steam:

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

No `AchievementManager`, após o `unlock()` local, chamar:

```gdscript
if SteamManager.is_available:
    var steam = Engine.get_singleton("Steam")
    steam.setAchievement(steam_id)
    steam.storeStats()
```

### Critérios de aceite

- [ ] Achievements desbloqueiam simultaneamente no jogo e no Steam
- [ ] Popup do Steam aparece junto com o popup dourado do jogo
- [ ] Sem duplicação se o achievement já estava desbloqueado no Steam

---

## Tarefa 4: Steam Cloud Save

**Objetivo:** Sincronizar o save local com o Steam Cloud para persistência cross-device.

### Contexto

`res://scripts/autoload/save_manager.gd` salva em JSON local via `FileAccess`. O Steam Cloud permite armazenar até 1GB por app.

### Detalhes

1. Ativar Steam Cloud no painel do Steamworks (File size limit, Max files)
2. Após cada `SaveManager.save_game()`, copiar o JSON para Steam Cloud:

```gdscript
Steam.fileWrite("zion_save.json", save_json_bytes)
```

3. No `_ready()` do SaveManager, verificar se existe save no Cloud mais recente que o local:

```gdscript
if SteamManager.is_available and Steam.fileExists("zion_save.json"):
    var cloud_data = Steam.fileRead("zion_save.json", Steam.getFileSize("zion_save.json"))
    # Comparar timestamps e usar o mais recente
```

### Critérios de aceite

- [ ] Save sincroniza com Steam Cloud automaticamente
- [ ] Conflito de versões resolvido pelo timestamp mais recente
- [ ] Sem perda de dados se Steam Cloud estiver offline (fallback local)

---

## Dependências

| Sistema | Tarefas |
|---|---|
| `SteamManager` (autoload) | 1, 2, 3, 4 |
| `MultiplayerManager` (autoload) | 2 |
| `AchievementManager` (autoload) | 3 |
| `SaveManager` (autoload) | 4 |
| `lobby_screen.gd` | 2 |
| GodotSteam GDExtension | Todas |

## Ordem de implementação

| Fase | Tarefas | Descrição |
|---|---|---|
| A | 1 | Instalação do plugin + inicialização robusta |
| B | 2 | Migração de rede para Steam Sockets |
| C | 3, 4 | Achievements + Cloud Save (paralelo) |

## Prioridade

Alta — bloqueante para lançamento no Steam (FASE E do roadmap principal).
