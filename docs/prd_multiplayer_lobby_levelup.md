# PRD — Multiplayer: Lobby, Level Up, Dificuldade, Spawning & Morte

> Sincronizacao de lobby, pausa global no level up, scaling de dificuldade, spawning otimizado, projeteis falsos, morte/revive e game over para co-op ate 4 jogadores.

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

## Tarefa 6: Scaling de Dificuldade (Host)

**Objetivo:** O Host ajusta dinamicamente a dificuldade com base no numero de jogadores conectados.

### Detalhes

- Ao iniciar a partida, o Host calcula os multiplicadores:

```gdscript
const DIFFICULTY_SCALE = {
    1: { hp: 1.0, spawn_rate: 1.0, boss_hp: 1.0 },
    2: { hp: 1.3, spawn_rate: 1.2, boss_hp: 1.3 },
    3: { hp: 1.6, spawn_rate: 1.4, boss_hp: 1.6 },
    4: { hp: 2.0, spawn_rate: 1.6, boss_hp: 2.0 },
}

var current_scale: Dictionary

func _apply_difficulty_scale():
    var player_count = multiplayer.get_peers().size() + 1  # +1 para o Host
    current_scale = DIFFICULTY_SCALE[clampi(player_count, 1, 4)]
```

- Multiplicadores aplicados em:
  - **HP inimigo**: `base_hp * current_scale.hp`
  - **Spawn rate**: intervalo entre waves dividido por `current_scale.spawn_rate`
  - **HP dos bosses**: `boss_base_hp * current_scale.boss_hp`
- Se um jogador desconectar **durante a partida**, o Host recalcula instantaneamente:

```gdscript
func _on_peer_disconnected(peer_id: int):
    _apply_difficulty_scale()
    # Inimigos ja vivos mantem o HP atual, mas novos spawns usam o novo multiplicador
```

### Criterios de aceite

- [ ] Multiplicadores de HP e spawn rate corretos para 1-4 jogadores
- [ ] Desconexao mid-game recalcula a dificuldade instantaneamente
- [ ] Novos inimigos usam o multiplicador atualizado
- [ ] Bosses recebem HP escalado ao spawnar

---

## Tarefa 7: Spawning Otimizado (MultiMesh)

**Objetivo:** Suportar ate 500 inimigos simultaneos sem lag usando MultiMeshManager.

### Detalhes

- Apenas o **Host** spawna inimigos (via `ObjectPool`) e calcula colisoes/dano.
- O Autoload `MultiMeshManager` renderiza as hordas via `MultiMeshInstance3D`:

```gdscript
# MultiMeshManager ja existe como autoload
# Garante que inimigos usem multimesh para renderizacao em batch

func register_enemy_mesh(mesh: Mesh, max_instances: int = 500):
    var mmi = MultiMeshInstance3D.new()
    mmi.multimesh = MultiMesh.new()
    mmi.multimesh.mesh = mesh
    mmi.multimesh.instance_count = max_instances
    mmi.multimesh.visible_instance_count = 0
    add_child(mmi)
    return mmi

func update_enemy_transforms(mmi: MultiMeshInstance3D, transforms: Array[Transform3D]):
    mmi.multimesh.visible_instance_count = transforms.size()
    for i in transforms.size():
        mmi.multimesh.set_instance_transform(i, transforms[i])
```

- Fluxo:
  1. Host spawna inimigo logico (Object Pool) — sem mesh individual
  2. MultiMeshManager recebe array de transforms a cada frame
  3. Renderiza todos os inimigos do mesmo tipo em uma unica draw call
- Clients recebem apenas posicoes via RPC (sync leve):

```gdscript
@rpc("authority", "call_remote", "unreliable")
func sync_enemy_positions(data: PackedVector3Array):
    # Client atualiza transforms no MultiMeshManager
    _update_multimesh_from_positions(data)
```

### Criterios de aceite

- [ ] 500 inimigos renderizados sem queda de FPS abaixo de 30
- [ ] Apenas Host faz spawn e logica de colisao
- [ ] Clients renderizam via MultiMeshManager (visual only)
- [ ] Object Pool reutiliza instancias corretamente

---

## Tarefa 8: Projeteis "Falsos" (Clients)

**Objetivo:** Clients exibem projeteis visuais locais sem sincronizar pelo MultiplayerSpawner.

### Detalhes

- O Host valida o disparo (cooldown, municao, posicao) e emite RPC:

```gdscript
# No Host, ao validar disparo
@rpc("authority", "call_remote", "unreliable")
func spawn_visual_projectile(weapon_id: String, origin: Vector3, direction: Vector3, speed: float):
    # Clients instanciam projetil visual local
    var proj = ObjectPool.get_instance("projectile_visual_%s" % weapon_id)
    proj.global_position = origin
    proj.direction = direction
    proj.speed = speed
    proj.is_visual_only = true  # sem hitbox, sem colisao
```

- Projeteis falsos:
  - **Sem hitbox** — nao colidem com nada
  - **Sem dano** — o Host calcula hits separadamente
  - **Visual only** — mesh + particulas + trail
  - **Cross-Combo zones** — podem exibir indicadores visuais de zona elemental para feedback
- Object Pool gerencia o ciclo de vida (spawn → fly → timeout/recycle)

### Criterios de aceite

- [ ] Projeteis nao sao sincronizados via MultiplayerSpawner
- [ ] Clients veem projeteis com visual correto (mesh, cor, trail)
- [ ] Projeteis falsos nao tem hitbox nem causam dano
- [ ] Object Pool recicla projeteis corretamente
- [ ] Cross-Combo zones visuais funcionam nos clients

---

## Tarefa 9: Morte do Jogador (Sacrificio)

**Objetivo:** Ao morrer, o jogador e substituido por uma lapide na posicao da morte.

### Detalhes

- Quando HP de um jogador chega a 0, o Host processa a morte:

```gdscript
func _on_player_death(peer_id: int):
    var player = _get_player_node(peer_id)
    var death_pos = player.global_position

    # Esconde modelo e desativa colisor
    player.visible = false
    player.get_node("CollisionShape3D").disabled = true
    player.is_dead = true

    # Instancia lapide
    var tombstone = tombstone_scene.instantiate()
    tombstone.global_position = death_pos
    tombstone.owner_peer_id = peer_id
    tombstone.time_remaining = 60.0  # 60s ate morte permanente
    add_child(tombstone)

    # Atualiza contagem global
    players_alive -= 1

    # Sincroniza com clients
    _sync_player_death.rpc(peer_id, death_pos)
```

- A variavel `players_alive` e mantida exclusivamente pelo Host
- A lapide e visivel para todos os jogadores

### Criterios de aceite

- [ ] Modelo do jogador fica invisivel ao morrer
- [ ] Colisor desativado — inimigos ignoram jogador morto
- [ ] Lapide aparece na posicao exata da morte
- [ ] `players_alive` decrementado corretamente
- [ ] Todos os clients veem a lapide

---

## Tarefa 10: Reviver Aliados (Interacao)

**Objetivo:** Aliados podem reviver jogadores mortos interagindo com a lapide.

### Detalhes

- Mecanica de revive:

```gdscript
# Na cena da Lapide
var revive_progress: float = 0.0
var revive_duration: float = 5.0  # 5 segundos perto da lapide
var time_remaining: float = 60.0  # tempo ate morte permanente
var owner_peer_id: int

func _physics_process(delta):
    if not multiplayer.is_server():
        return

    # Timer de morte permanente
    time_remaining -= delta
    if time_remaining <= 0:
        _permanent_death()
        return

    # Detecta aliados proximos (Area3D)
    var allies_nearby = _get_allies_in_range()
    if allies_nearby.size() > 0:
        revive_progress += delta
        if revive_progress >= revive_duration:
            _revive_player(allies_nearby[0])
    else:
        revive_progress = maxf(revive_progress - delta, 0.0)  # regride se sair

func _revive_player(savior_peer_id: int):
    var player = _get_player_node(owner_peer_id)
    player.hp = player.max_hp * 0.5  # revive com 50% HP
    player.visible = true
    player.get_node("CollisionShape3D").disabled = false
    player.is_dead = false
    players_alive += 1

    # Penalidade para quem salvou: -30% HP maximo por 30s
    _apply_sacrifice_debuff.rpc(savior_peer_id, 0.3, 30.0)

    # Remove lapide
    queue_free()
```

- **Penalidade de sacrificio**: quem revive perde 30% de HP maximo por 30 segundos
- **Barra de progresso**: UI mostra progresso do revive sobre a lapide
- **Timeout**: apos 60s sem revive, a lapide some (morte permanente na run)

### Criterios de aceite

- [ ] 5 segundos de proximidade para reviver
- [ ] Revive com 50% do HP maximo
- [ ] Penalidade de 30% HP max por 30s para o salvador
- [ ] Lapide some apos 60s (morte permanente)
- [ ] Barra de progresso visivel para todos
- [ ] Progresso regride se o aliado sair da area

---

## Tarefa 11: Condicao de Game Over

**Objetivo:** Game over acontece apenas quando todos os jogadores estao mortos.

### Detalhes

- O Host monitora `players_alive` continuamente:

```gdscript
func _check_game_over():
    if players_alive <= 0:
        _trigger_game_over()

func _trigger_game_over():
    # Para spawning e logica de jogo
    get_tree().paused = true

    # Coleta estatisticas da run
    var stats = _collect_run_stats()

    # Envia game over para todos
    _show_game_over.rpc(stats)

@rpc("authority", "call_remote", "reliable")
func _show_game_over(stats: Dictionary):
    # Abre tela de estatisticas
    # Mostra: tempo sobrevivido, inimigos mortos, dano total, revives, etc.
    UIManager.show_game_over_screen(stats)
```

- O game over **so** acontece quando `players_alive == 0`
- Mesmo com 3 de 4 jogadores mortos, o ultimo mantém a run viva
- Tela de estatisticas mostra dados de todos os jogadores

### Criterios de aceite

- [ ] Game over apenas quando `players_alive == 0`
- [ ] Um jogador vivo mantem a run ativa para todos
- [ ] RPC `trigger_game_over` enviado para todos os clients
- [ ] Tela de estatisticas abre para todos simultaneamente
- [ ] Estatisticas incluem dados de todos os jogadores (vivos e mortos)

---

## Dependencias

- `MultiplayerManager` (autoload existente)
- `MultiMeshManager` (autoload existente) — Tarefa 7
- `ObjectPool` (autoload existente) — Tarefas 7, 8
- `SynergySystem` (autoload existente) — Tarefa 8 (Cross-Combo zones)
- Sistema de XP/Level Up existente — Tarefas 3, 4
- `CharacterDB` para retratos — Tarefa 2
- `RelicDB` para selecao de reliquias — Tarefa 2
- Sistema de revive/tombstone existente — Tarefas 9, 10

## Ordem de implementacao

| Fase | Tarefas | Descricao |
|---|---|---|
| A | 1, 2 | Lobby sync — base para tudo |
| B | 6, 7 | Dificuldade + spawning — core gameplay |
| C | 3, 4, 5 | Level up global — UX multiplayer |
| D | 8 | Projeteis falsos — otimizacao de rede |
| E | 9, 10, 11 | Morte, revive, game over — ciclo completo |

## Prioridade

Alta — necessario para co-op funcional.
