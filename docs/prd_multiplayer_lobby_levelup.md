# PRD — Multiplayer: Lobby Sync & Level Up Global

> Sincronizacao de lobby e pausa global no level up para co-op ate 4 jogadores.

---

## Tarefa 1: Estado do Lobby (Host)

**Objetivo:** O Host mantem um dicionario centralizado com o estado de cada jogador no lobby.

### Detalhes

- Criar `lobby_state: Dictionary` no Host (ex: dentro de `MultiplayerManager` ou cena de lobby).
  - Chave: `peer_id` (int)
  - Valor: `{ char_id: String, relic_id: String, is_ready: bool }`
- Quando um Client escolhe personagem ou clica "Pronto", envia RPC para o Host:

```gdscript
@rpc("any_peer", "call_remote", "reliable")
func update_player_state(char_id: String, relic_id: String, is_ready: bool):
    var sender = multiplayer.get_remote_sender_id()
    lobby_state[sender] = {
        "char_id": char_id,
        "relic_id": relic_id,
        "is_ready": is_ready
    }
    _broadcast_lobby_state()
```

### Criterios de aceite

- [ ] `lobby_state` existe e e atualizado a cada RPC recebido
- [ ] Apenas o Host processa `update_player_state`
- [ ] Jogadores que desconectam sao removidos do `lobby_state`

---

## Tarefa 2: Atualizacao Visual do Lobby

**Objetivo:** Todos os Clients veem o estado atualizado do lobby em tempo real.

### Detalhes

- O Host, ao receber `update_player_state`, faz broadcast de volta para todos:

```gdscript
@rpc("authority", "call_remote", "reliable")
func sync_lobby_state(state: Dictionary):
    # Cada client atualiza sua UI
    _update_lobby_ui(state)
```

- A UI exibe para cada jogador conectado:
  - Retrato do personagem (128x128)
  - Nome do jogador
  - Status: "Escolhendo..." ou "Pronto!"
- O botao "Iniciar partida" do Host so fica habilitado quando:

```gdscript
func _can_start() -> bool:
    if lobby_state.size() < 1:
        return false
    for peer in lobby_state.values():
        if not peer.is_ready:
            return false
    return true  # players_ready == players_connected
```

### Criterios de aceite

- [ ] Retratos 128x128 atualizados em tempo real para todos
- [ ] Host so pode iniciar quando todos estao prontos
- [ ] Desconexao de jogador atualiza a UI imediatamente

---

## Tarefa 3: Pausa Global no Level Up

**Objetivo:** Quando um jogador enche a barra de XP, o jogo pausa para todos ate a escolha ser feita.

### Detalhes

- Ao atingir level up, o Host ativa pausa global:

```gdscript
func _on_player_level_up(peer_id: int):
    get_tree().paused = true
    players_pending_choice.append(peer_id)
    _show_level_up_for.rpc_id(peer_id)
    _show_waiting_screen.rpc()  # outros veem "Aguardando..."
```

- **PROCESS_MODE_WHEN_PAUSED** deve estar ativado em:
  - UI de level up (selecao de upgrades)
  - UI de "Aguardando jogador..."
  - Qualquer node que precise processar durante pausa (input, animacoes de UI)
- O Host mantem `players_pending_choice: Array[int]` com os IDs dos jogadores que ainda nao escolheram.

### Criterios de aceite

- [ ] `get_tree().paused = true` e chamado pelo Host
- [ ] Apenas o jogador que subiu de nivel ve o menu de escolha
- [ ] Outros jogadores veem tela de "Aguardando..."
- [ ] UI funciona normalmente durante a pausa (PROCESS_MODE_WHEN_PAUSED)

---

## Tarefa 4: Escolhas e Retomada (Level Up)

**Objetivo:** Apos a escolha, o jogo retoma para todos de forma sincronizada.

### Detalhes

- O jogador escolhe um upgrade e envia ao Host:

```gdscript
# No Client
func _on_upgrade_selected(upgrade_id: String):
    submit_upgrade.rpc_id(1, upgrade_id)  # 1 = Host

# No Host
@rpc("any_peer", "call_remote", "reliable")
func submit_upgrade(upgrade_id: String):
    var sender = multiplayer.get_remote_sender_id()
    _apply_upgrade(sender, upgrade_id)
    players_pending_choice.erase(sender)
    _update_waiting_ui.rpc()  # atualiza "Aguardando X jogador(es)..."

    if players_pending_choice.is_empty():
        get_tree().paused = false
        _hide_level_up_ui.rpc()
```

- Se multiplos jogadores sobem de nivel ao mesmo tempo, todos sao adicionados ao `players_pending_choice` e o jogo so retoma quando **todos** escolherem.

### Criterios de aceite

- [ ] Upgrade e aplicado corretamente ao jogador que escolheu
- [ ] UI de espera mostra quantos jogadores faltam
- [ ] Jogo so despausa quando `players_pending_choice` esta vazio
- [ ] Level ups simultaneos sao tratados (multiplos IDs no array)

---

## Tarefa 5: Revisao de Game Design (Aviso)

> **Atencao — impacto no fluxo de jogo**

### Problema

Com 4 jogadores atingindo nivel 40, o sistema de pausa global pode gerar **~160 pausas em 30 minutos**. Isso fragmenta o fluxo de gameplay e pode frustrar jogadores.

### Calculo

| Jogadores | Niveis | Pausas totais | Em 30 min |
|---|---|---|---|
| 1 | 40 | 40 | ~1.3/min |
| 2 | 40 | 80 | ~2.7/min |
| 4 | 40 | 160 | ~5.3/min |

### Solucao futura recomendada

Migrar para **level up assincrono**:

- Jogador que sobe de nivel recebe **invulnerabilidade temporaria** (3-5s)
- Menu de escolha aparece **so pra ele**, sem pausar os outros
- Indicador visual sobre o personagem (aura brilhante / icone)
- Se o tempo esgotar sem escolha, seleciona automaticamente uma opcao aleatoria
- Beneficio: zero pausas, fluxo continuo, experiencia mais dinamica

### Decisao

Implementar primeiro a **pausa global** (Tarefas 1-4) por ser mais simples e segura. Migrar para assincrono em fase futura apos playtesting confirmar o problema de fluxo.

---

## Dependencias

- `MultiplayerManager` (autoload existente)
- Sistema de XP/Level Up existente
- `CharacterDB` para retratos
- `RelicDB` para selecao de reliquias

## Prioridade

Alta — necessario para co-op funcional.
