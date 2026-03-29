# PRD — Menu Multiplayer (v1)

> *"Os estilhaços ressoam entre Fragmentados — mas antes de atravessar a fenda juntos, precisam se encontrar."*

## Objetivo

Reformular a tela de lobby multiplayer para oferecer uma experiência completa de pré-jogo: seleção de personagem, relíquia e fenda dentro do lobby, descoberta de servidores na LAN, indicadores de rede, chat rápido e feedback visual de reconexão. O jogador não precisa mais configurar nada antes de entrar no lobby.

## Estado Atual

### O que já existe
- **MultiplayerManager** (784 linhas) — host-client ENet, até 4 jogadores
- **Lobby Screen** (`lobby_screen.gd`, 184 linhas) — criar sala, entrar via IP, lista de jogadores, botão "Pronto"
- **Host Migration** — failover automático com snapshot de game state
- **Auto-Reconnection** — 3 tentativas a cada 2s (sinais emitidos, sem UI)
- **Ping System** — `get_ping()` + `get_ping_color()` (dados disponíveis, sem exibição)
- **Lobby State Sync** — `lobby_state[peer_id] = {char_id, relic_id, is_ready}` via RPC
- Seleção de personagem e relíquia acontece **antes** do lobby (telas separadas)
- Seleção de fenda **não existe** no lobby — usa `GameManager.selected_stage` (default: cemetery)

### O que falta
- Seleção de personagem/relíquia/fenda **dentro** do lobby
- Descoberta de servidores LAN
- Indicador de ping na lista de jogadores
- Badge de host na lista
- Chat rápido / emotes
- Feedback visual de reconexão
- Lista de servidores recentes
- Senha opcional para sala privada

---

## Escopo da Atualização

### M1 — Seleção In-Lobby (Prioridade Alta)

#### M1.1 — Seletor de Fragmentado no Lobby
**Problema:** Jogador escolhe personagem antes de entrar no lobby. Não pode mudar depois nem ver o que os outros escolheram.

**Solução:**
- Adicionar painel lateral esquerdo no lobby com grid de Fragmentados (sprites 64x64)
- Ao clicar, atualiza `lobby_state` via RPC com o novo `char_id`
- Preview do Fragmentado selecionado com nome + stats resumidos
- Na lista de jogadores, mostrar sprite atualizado em tempo real
- Fragmentados já escolhidos por outro jogador ficam com borda vermelha (sem bloqueio, apenas aviso visual)

**Dados sincronizados:** `char_id` já existe no `lobby_state`

#### M1.2 — Seletor de Relíquia no Lobby
**Problema:** `relic_id` é trackeado no `lobby_state` mas não tem UI para selecionar.

**Solução:**
- Dropdown ou grid abaixo do seletor de Fragmentado com as 7 relíquias disponíveis (desbloqueadas)
- Ícone + nome da relíquia
- Sync via `lobby_state.relic_id`
- Relíquias bloqueadas aparecem com cadeado

#### M1.3 — Seletor de Fenda (Host Only)
**Problema:** Fenda é hardcoded. Host não pode escolher onde jogar.

**Solução:**
- Painel direito do lobby com grid de fendas (7 campanha + 3 anomalias)
- Apenas o host pode selecionar (clientes veem a seleção, read-only)
- Mostrar nome, thumbnail e dificuldade estimada da fenda
- Fendas bloqueadas (não completou a anterior) aparecem com cadeado
- Adicionar `stage_id` ao `lobby_state` broadcast

**Novo campo no lobby_state:**
```gdscript
lobby_state[peer_id] = {char_id, relic_id, is_ready}
# Novo campo global (não por peer):
lobby_stage = "cemetery"  # Controlado apenas pelo host
```

---

### M2 — Descoberta e Conexão (Prioridade Alta)

#### M2.1 — LAN Server Discovery
**Problema:** Jogador precisa digitar IP manualmente. Ruim para jogo casual local.

**Solução:**
- Host envia broadcast UDP na porta 7778 a cada 2s com payload:
  ```gdscript
  {
      "game": "zion",
      "version": VERSION,
      "host_name": "Sala de [nome]",
      "players": 2,
      "max_players": 4,
      "stage": "cemetery",
      "port": 7777
  }
  ```
- Cliente escuta broadcasts e popula lista de servidores encontrados
- Lista mostra: nome da sala, jogadores (2/4), fenda, ping
- Clicar numa sala conecta automaticamente
- Botão "Atualizar" para re-scan
- Fallback: campo de IP manual continua disponível

**Arquivo:** `game/scripts/autoload/multiplayer_manager.gd` (adicionar `_start_lan_broadcast()` e `_start_lan_discovery()`)

#### M2.2 — Lista de Servidores Recentes
**Problema:** Se reconectar ao mesmo amigo, precisa digitar IP de novo.

**Solução:**
- Salvar últimos 5 servidores conectados em `SaveManager`
- Formato: `{ip, port, host_name, last_connected_timestamp}`
- Mostrar lista abaixo do campo de IP com botão de conectar rápido
- Limpar entradas com mais de 30 dias

#### M2.3 — Senha de Sala (Opcional)
**Problema:** Qualquer pessoa na LAN pode entrar na sala.

**Solução:**
- Campo opcional "Senha" ao criar sala
- Se definida, cliente precisa digitar antes de conectar
- Hash SHA-256 da senha enviado no handshake
- Sem senha = sala aberta (padrão atual)

---

### M3 — Feedback Visual (Prioridade Média)

#### M3.1 — Indicador de Ping
**Problema:** `get_ping()` e `get_ping_color()` existem mas não aparecem na UI.

**Solução:**
- Ícone de sinal (3 barras) ao lado de cada jogador na lista
- Cor dinâmica: verde (<50ms), amarelo (50-100ms), vermelho (>100ms)
- Tooltip com ping exato em ms
- Atualiza a cada 2s (já implementado no manager)

#### M3.2 — Badge de Host
**Problema:** Não dá pra saber quem é o host na lista.

**Solução:**
- Ícone de coroa dourada ao lado do nome do host
- Se host migrar, coroa move para o novo host automaticamente
- Texto "(Host)" em dourado após o nome

#### M3.3 — Feedback de Reconexão
**Problema:** Sinais de reconexão existem (`reconnection_attempted`, `reconnection_succeeded`, `reconnection_failed`) mas lobby não conecta neles.

**Solução:**
- Popup central semi-transparente: "Reconectando... (tentativa 1/3)"
- Barra de progresso animada
- Se falhar: "Conexão perdida. Voltando ao menu..." com countdown de 3s
- Se sucesso: "Reconectado!" por 2s e fecha popup
- Conectar sinais no `lobby_screen.gd` e criar overlay reutilizável para in-game também

#### M3.4 — Status de Carregamento por Jogador
**Problema:** Quando host inicia partida, não há feedback de quem já carregou a fase.

**Solução:**
- Barra de loading individual por jogador na transição
- "Carregando..." → "Pronto!" com checkmark
- Host só inicia quando `all_players_loaded` (já existe o sinal)

---

### M4 — Chat e Comunicação (Prioridade Média)

#### M4.1 — Chat Rápido no Lobby
**Problema:** Sem comunicação entre jogadores no lobby.

**Solução:**
- Área de chat na parte inferior do lobby (últimas 8 mensagens visíveis)
- Campo de input com Enter para enviar
- Formato: `[Cor do jogador] Nome: mensagem`
- RPC `_chat_message.rpc(text)` — host retransmite para todos
- Limite: 140 caracteres por mensagem
- Filtro básico de flood (max 3 msgs por 5s)

#### M4.2 — Emotes Rápidos (In-Game)
**Problema:** Durante gameplay não dá pra digitar.

**Solução:**
- Roda de emotes (8 opções) ativada por tecla (default: T)
- Emotes: "Vamos!", "Cuidado!", "Ajuda!", "GG", "Aqui!", "Esperem", "Obrigado!", "LOL"
- Balão sobre o personagem por 3s
- RPC unreliable para broadcast

---

### M5 — Layout do Lobby Reformulado

```
┌─────────────────────────────────────────────────────────────┐
│                    ⚔️ MULTIPLAYER                           │
├──────────────┬──────────────────────┬───────────────────────┤
│  FRAGMENTADO │    JOGADORES         │   FENDA               │
│              │                      │                       │
│  [Grid 5x3  │  👑 Host     ✅ 🟢   │  [Grid 2x5 thumbnails]│
│   sprites]   │  🗡️ Player2  ✅ 🟡   │                       │
│              │  🏹 Player3  ⏳ 🟢   │  Selecionada:         │
│  Selecionado:│  (vazio)             │  🏚️ Cemitério         │
│  ⚔️ Ronin    │                      │  Dificuldade: ★★☆☆☆  │
│              │                      │                       │
│  RELÍQUIA    │                      │  [Apenas host pode    │
│  [Dropdown]  │                      │   alterar]            │
│  🔮 Cristal  │                      │                       │
├──────────────┴──────────────────────┴───────────────────────┤
│  💬 Chat: [Player2]: vamos de vulcão!                       │
│           [Host]: ok troquei                                │
│  [__________________ Enviar ___]     [Pronto] [Voltar]      │
├─────────────────────────────────────────────────────────────┤
│  🔍 Servidores LAN          │  📋 Recentes                  │
│  Sala do João (2/4) 🟢 23ms │  192.168.1.10 - ontem        │
│  Sala do Pedro (1/4) 🟡 67ms│  192.168.1.15 - 3 dias atrás │
└─────────────────────────────────────────────────────────────┘
```

**Nota:** Seção de servidores LAN/recentes aparece apenas na tela de **conexão** (antes de entrar no lobby). Após conectar, o layout principal mostra as 3 colunas.

---

## Implementação Técnica

### Task 1 — Refatorar layout do lobby_screen.tscn
**Arquivo:** `game/scenes/ui/lobby_screen.tscn` + `game/scripts/ui/lobby_screen.gd`
- Reestruturar para layout 3 colunas (HSplitContainer ou HBoxContainer)
- Coluna esquerda: seletor de personagem + relíquia
- Coluna central: lista de jogadores + chat
- Coluna direita: seletor de fenda
- Manter responsivo para resoluções menores (1280x720 mínimo)
**Estimativa:** 40 min

### Task 2 — Seletor de Fragmentado in-lobby
**Arquivo:** `game/scripts/ui/lobby_screen.gd`
- Grid de sprites usando TextureRect (mesma lógica do character_select.gd)
- Ao selecionar, chamar `MultiplayerManager.update_player_state(char_id, relic_id, is_ready)`
- Atualizar preview com stats do CharacterDB
**Estimativa:** 30 min

### Task 3 — Seletor de Relíquia in-lobby
**Arquivo:** `game/scripts/ui/lobby_screen.gd`
- Dropdown com ícones das relíquias desbloqueadas via RelicDB
- Sync via `update_player_state()`
**Estimativa:** 20 min

### Task 4 — Seletor de Fenda (host-only)
**Arquivo:** `game/scripts/ui/lobby_screen.gd` + `game/scripts/autoload/multiplayer_manager.gd`
- Grid de thumbnails das fendas
- Novo campo `lobby_stage` no MultiplayerManager
- Novo RPC `_broadcast_stage_selection(stage_id)` (host → all)
- Clientes recebem e atualizam display (read-only)
**Estimativa:** 30 min

### Task 5 — LAN Discovery (broadcast UDP)
**Arquivo:** `game/scripts/autoload/multiplayer_manager.gd`
- `PacketPeerUDP` para broadcast na porta 7778
- Host: `_start_lan_broadcast()` envia JSON a cada 2s
- Cliente: `_start_lan_discovery()` escuta e popula lista
- Adicionar UI de lista de servidores no lobby_screen
**Estimativa:** 45 min

### Task 6 — Lista de Servidores Recentes
**Arquivo:** `game/scripts/autoload/save_manager.gd` + `game/scripts/ui/lobby_screen.gd`
- Salvar/carregar array de servidores recentes no save file
- UI de lista com botão de connect rápido
**Estimativa:** 20 min

### Task 7 — Indicadores visuais (ping, host badge, reconexão)
**Arquivo:** `game/scripts/ui/lobby_screen.gd`
- Ícone de ping colorido por jogador
- Coroa no host
- Conectar sinais de reconexão + criar overlay
**Estimativa:** 30 min

### Task 8 — Chat no Lobby
**Arquivo:** `game/scripts/ui/lobby_screen.gd` + `game/scripts/autoload/multiplayer_manager.gd`
- UI de chat (RichTextLabel + LineEdit)
- RPC `_send_chat_message(text)` com retransmissão pelo host
- Filtro anti-flood
**Estimativa:** 25 min

### Task 9 — Emotes rápidos (in-game)
**Arquivo:** `game/scripts/player/player.gd` + `game/scripts/autoload/multiplayer_manager.gd`
- Roda radial de emotes (nova cena)
- RPC unreliable para broadcast
- Label3D temporário sobre o jogador
**Estimativa:** 35 min

### Task 10 — Senha de Sala
**Arquivo:** `game/scripts/autoload/multiplayer_manager.gd` + `game/scripts/ui/lobby_screen.gd`
- Campo de senha na criação
- Validação no handshake
- UI de input de senha ao conectar em sala protegida
**Estimativa:** 20 min

---

## Ordem de Execução Recomendada

| Fase | Tasks | Estimativa |
|------|-------|-----------|
| **Sprint 1** — Core Lobby | Task 1, 2, 3, 4 | ~2h |
| **Sprint 2** — Rede | Task 5, 6, 10 | ~1.5h |
| **Sprint 3** — Feedback | Task 7, 8 | ~1h |
| **Sprint 4** — Emotes | Task 9 | ~35min |
| **Total** | | **~5h** |

---

## Critérios de Aceitação

- [ ] Jogador pode selecionar Fragmentado, relíquia e ver a fenda dentro do lobby
- [ ] Host pode selecionar fenda; clientes veem a seleção em tempo real
- [ ] Lista de jogadores mostra: sprite, nome, relíquia, status pronto, ping, badge host
- [ ] Servidores LAN aparecem automaticamente na lista (< 3s de delay)
- [ ] Servidores recentes são salvos e permitem reconexão rápida
- [ ] Chat funciona no lobby com anti-flood
- [ ] Emotes funcionam in-game via roda radial
- [ ] Feedback visual de reconexão aparece ao perder conexão
- [ ] Sala com senha exige input antes de conectar
- [ ] Layout responsivo funciona em 1280x720
- [ ] Toda a UI usa sentence case conforme padrão do projeto
- [ ] Narrativa respeitada: terminologia usa "Fragmentados", "fendas", "relíquias", "estilhaços"

## Métricas de Sucesso

- Tempo médio para iniciar partida multiplayer: < 30s (vs atual ~60s com troca de telas)
- 0 crashes em host migration durante lobby
- Players conseguem encontrar servidor LAN sem digitar IP em < 5s
- Chat funcional sem flood em sessões de 4 jogadores

## Compatibilidade

- **Retrocompatível**: protocolo de rede adiciona campos opcionais ao lobby_state
- **Versão mínima**: clientes v3.0.5+ podem conectar em hosts v3.0.6+
- **Steam**: LAN discovery funciona independente do Steam; quando GodotSteam for integrado, adicionar Steam Lobby como alternativa
