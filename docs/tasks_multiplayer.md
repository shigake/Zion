# Tarefas Multiplayer — Implementacao Detalhada

## Lobby & Level Up

### Tarefa 1: Estado do Lobby (Host)
No Host, crie um dicionario `lobby_state` com os IDs dos jogadores. Quando um Client escolhe um personagem ou clica "Pronto", envia um `@rpc("any_peer", "call_remote", "reliable")` para o Host: `update_player_state(char_id, relic_id, is_ready)`.

### Tarefa 2: Atualizacao Visual do Lobby
O Host recebe o estado e faz um broadcast de volta. A UI de cada Client atualiza os retratos 128x128 e o status. O Host so libera iniciar a partida quando `players_ready == players_connected`, garantindo sincronia total.

### Tarefa 3: Pausa Global no Level Up
Ao encher a XP, o Host ativa `get_tree().paused = true` (garanta `PROCESS_MODE_WHEN_PAUSED` na UI). O Host envia um RPC `show_level_up()` aos afetados e guarda seus IDs num Array `players_pending_choice`.

### Tarefa 4: Escolhas e Retomada (Level Up)
O jogador escolhe as opcoes e envia `rpc_id(1, "submit_upgrade", id)`. O Host aplica o status, remove o ID do Array e atualiza a UI para "Aguardando...". Quando o Array esvaziar, o Host faz `get_tree().paused = false` para retomarem juntos.

### Tarefa 5: Revisao de Game Design (Aviso)
**Atencao**: Atingindo o nivel 40 com 4 jogadores, pausar para todos gerara ~160 pausas em 30 min. Isso pode destruir o fluxo. Discutam futuramente fazer o menu de level up assincrono (dando invulnerabilidade a quem esta escolhendo).

---

## Gameplay Multiplayer

### Tarefa 6: Scaling de Dificuldade (Host)
Ao iniciar, o Host ajusta a dificuldade: HP inimigo vai para 1.3x (2p), 1.6x (3p) ou 2x (4p). O Spawn Rate e o HP dos Bosses tambem aumentam. Se um jogador desconectar, o Host ajusta a matematica instantaneamente.

### Tarefa 7: Spawning Otimizado (MultiMesh)
Apenas o Host spawna inimigos (usando Object Pool) e calcula colisoes. Para suportar ate 500 inimigos sem lag, garantam o uso do Autoload `MultiMeshManager` renderizando hordas via `MultiMeshInstance3D`.

### Tarefa 8: Projeteis "Falsos" (Clients)
Nao sincronizem tiros pelo `MultiplayerSpawner`. O Host valida o disparo e emite um RPC. Os Clients usam o Object Pool para instanciar projeteis visuais locais, sem hitbox, apenas para feedback visual e zonas de Cross-Combo.

### Tarefa 9: Morte do Jogador (Sacrificio)
Se o HP de um jogador zerar, o Host esconde o modelo dele e desativa o colisor. Uma Lapide e instanciada na posicao exata da morte. A variavel global do Host `players_alive` e reduzida em 1.

### Tarefa 10: Reviver Aliados (Interacao)
Aliados precisam ficar 5 segundos perto da Lapide para reviver o amigo com 50% de HP. O Host aplica a penalidade: quem salvou perde 30% de HP maximo por 30s. Apos 60 segundos no chao, a Lapide some (morte permanente).

### Tarefa 11: Condicao de Game Over
O Host monitora ativamente a variavel `players_alive`. O Game Over so acontece se `players_alive == 0`. Neste caso, o Host emite o RPC global `trigger_game_over()`, parando a run e abrindo a tela de estatisticas para todos.

---

## Status de Implementacao

| Tarefa | Status | Arquivo principal |
|--------|--------|-------------------|
| 1. Estado do Lobby | Implementado | multiplayer_manager.gd, lobby_screen.gd |
| 2. Visual do Lobby | Implementado | lobby_screen.gd |
| 3. Pausa Level Up | Implementado | level_up_screen.gd, multiplayer_manager.gd |
| 4. Escolhas Level Up | Implementado | level_up_screen.gd, multiplayer_manager.gd |
| 5. Game Design Review | Pendente | — |
| 6. Scaling Dificuldade | Implementado | game_manager.gd |
| 7. MultiMesh Spawning | Parcial | multimesh_manager.gd, enemy_spawner.gd |
| 8. Projeteis Falsos | Pendente | weapons/*.gd |
| 9. Morte/Sacrificio | Implementado | tombstone.gd, player.gd |
| 10. Reviver Aliados | Implementado | tombstone.gd |
| 11. Game Over | Implementado | game_manager.gd |
