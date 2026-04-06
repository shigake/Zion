extends Node

## Gerencia multiplayer online: lobby, conexões, spawn de jogadores.
## Arquitetura: Host-Client (listen server) via ENet (fallback sem Steam).
## Para Steam: substituir ENet por Steam Networking Sockets via GodotSteam.
## Host Migration: quando host desconecta, próximo peer assume com estado sincronizado.
## Inclui: ping RPC, interpolação de posição, reconexão automática.

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal server_created()
signal connection_failed()
signal connection_succeeded()
signal all_players_loaded()
signal host_migrated(new_host_id: int)
signal player_hp_updated(peer_id: int, hp: int, max_hp: int)
signal host_migration_started()
signal host_migration_completed(new_host_id: int)
signal reconnection_attempted(attempt: int, max_attempts: int)
signal reconnection_succeeded()
signal reconnection_failed()
signal ping_updated(ping_ms: int)
signal lobby_state_updated()
signal chat_message_received(sender_name: String, text: String, color: Color)
signal stage_selection_updated()
signal lan_server_found(server_info: Dictionary)
signal password_required()

const DEFAULT_PORT := 7777
const LAN_BROADCAST_PORT := 7778
const MAX_PLAYERS := 4
const PING_INTERVAL := 2.0          # Mede ping a cada 2 segundos
const MAX_RECONNECT_ATTEMPTS := 3   # Máximo de tentativas de reconexão
const RECONNECT_INTERVAL := 2.0     # Intervalo entre tentativas (segundos)
const LAN_BROADCAST_INTERVAL := 2.0 # Broadcast LAN a cada 2s

enum NetworkBackend { ENET, STEAM }

# peer_id -> {name, character, ready, loaded, hp, max_hp}
var players: Dictionary = {}
var local_player_id: int = 0
var is_online: bool = false
var backend: int = NetworkBackend.ENET
var current_host_id: int = 1  # Quem é o host atual

# --- Lobby stage (host-controlled) ---
var lobby_stage: String = "cemetery"

# --- Ping ---
var _ping_ms: int = 0               # Último ping medido em milissegundos
var _ping_timer: float = 0.0        # Timer para medir ping periodicamente
var _ping_send_time: int = 0        # Timestamp de envio do ping (usec)

# --- Reconexão ---
var _reconnect_attempts: int = 0
var _reconnect_timer: float = 0.0
var _reconnecting: bool = false
var _last_address: String = ""
var _last_port: int = DEFAULT_PORT

# --- LAN Discovery ---
var _lan_broadcast_peer: PacketPeerUDP = null
var _lan_discovery_peer: PacketPeerUDP = null
var _lan_broadcast_timer: float = 0.0
var _lan_broadcasting: bool = false
var _lan_discovering: bool = false

# --- Room Password ---
var _room_password_hash: String = ""   # Host's room password (SHA-256)
var _client_password_hash: String = "" # Client's password attempt

# --- Host Migration ---
var _migration_in_progress: bool = false
var _migration_game_state: Dictionary = {}  # Estado preservado durante migração
var _migration_players_backup: Dictionary = {}  # Backup dos players durante migração
var _new_host_address: String = ""  # Endereço do novo host para reconexão

# --- Interpolação de posição (Task 4) ---
# peer_id -> Array de {pos: Vector3, time: float} (últimas 3 posições)
var _remote_positions: Dictionary = {}
const MAX_POSITION_HISTORY := 3

# --- Lobby state sync (Tasks 1 & 2) ---
# peer_id -> {char_id: String, relic_id: String, is_ready: bool}
var lobby_state: Dictionary = {}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(delta: float) -> void:
	# --- LAN broadcast (host) ---
	if _lan_broadcasting and _lan_broadcast_peer:
		_lan_broadcast_timer += delta
		if _lan_broadcast_timer >= LAN_BROADCAST_INTERVAL:
			_lan_broadcast_timer = 0.0
			_send_lan_broadcast()

	# --- LAN discovery (client) ---
	if _lan_discovering and _lan_discovery_peer:
		_poll_lan_discovery()

	if not is_online:
		return

	# --- Ping periódico (clients medem RTT para o server) ---
	_ping_timer += delta
	if _ping_timer >= PING_INTERVAL:
		_ping_timer = 0.0
		_measure_ping()

	# --- Reconexão automática ---
	if _reconnecting:
		_reconnect_timer += delta
		if _reconnect_timer >= RECONNECT_INTERVAL:
			_reconnect_timer = 0.0
			_try_reconnect()

func _create_server_peer(port: int) -> Array:
	# Steam Networking Sockets — NAT traversal sem servidor dedicado
	if backend == NetworkBackend.STEAM and SteamManager.is_available:
		if ClassDB.class_exists(&"SteamMultiplayerPeer"):
			var peer = ClassDB.instantiate(&"SteamMultiplayerPeer")
			var error = peer.create_host(0, [])
			if error == OK:
				SteamManager.create_lobby(MAX_PLAYERS)
				LogManager.info("MP", "Steam server created")
			return [peer, error]
		LogManager.warn("MP", "SteamMultiplayerPeer not found, falling back to ENet")
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)
	return [peer, error]

func _create_client_peer(address: String, port: int) -> Array:
	# Steam Networking Sockets — conecta via Steam ID do host
	if backend == NetworkBackend.STEAM and SteamManager.is_available:
		if ClassDB.class_exists(&"SteamMultiplayerPeer"):
			var host_steam_id = SteamManager.get_lobby_data("host_steam_id").to_int()
			if host_steam_id > 0:
				var peer = ClassDB.instantiate(&"SteamMultiplayerPeer")
				var error = peer.create_client(host_steam_id, 0, [])
				LogManager.info("MP", "Steam client connecting to host %d" % host_steam_id)
				return [peer, error]
		LogManager.warn("MP", "SteamMultiplayerPeer not found, falling back to ENet")
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	return [peer, error]

# ---- Host ----
func create_server(port: int = DEFAULT_PORT) -> Error:
	# Limpa peer anterior para permitir recriar servidor
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	var result = _create_server_peer(port)
	var peer = result[0]
	var error = result[1]
	if error != OK:
		LogManager.error("MP", "Failed to create server: %s" % error)
		return error
	multiplayer.multiplayer_peer = peer
	local_player_id = 1
	is_online = true
	_last_port = port
	_register_player(1, GameManager.selected_character)
	server_created.emit()
	LogManager.info("MP", "Server created on port %d" % port)
	return OK

# ---- Client ----
func join_server(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> Error:
	# Limpa peer anterior para permitir reconectar
	if multiplayer.multiplayer_peer and not _reconnecting:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	var result = _create_client_peer(address, port)
	var peer = result[0]
	var error = result[1]
	if error != OK:
		LogManager.error("MP", "Failed to connect: %s" % error)
		return error
	multiplayer.multiplayer_peer = peer
	is_online = true
	_last_address = address
	_last_port = port
	LogManager.info("MP", "Connecting to %s:%d..." % [address, port])
	return OK

func disconnect_from_game() -> void:
	_reconnecting = false
	_reconnect_attempts = 0
	stop_lan_broadcast()
	stop_lan_discovery()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	players.clear()
	lobby_state.clear()
	_remote_positions.clear()
	local_player_id = 0
	is_online = false
	lobby_stage = "cemetery"
	_room_password_hash = ""
	_client_password_hash = ""

## Tenta reconectar a um servidor após desconexão.
## Usado após host migration ou perda de conexão.
func reconnect_to_game(address: String = "", port: int = 0) -> void:
	if address != "":
		_last_address = address
	if port > 0:
		_last_port = port
	_reconnecting = true
	_reconnect_attempts = 0
	_reconnect_timer = 0.0
	LogManager.info("MP", "Iniciando reconexão para %s:%d" % [_last_address, _last_port])
	_try_reconnect()

func _try_reconnect() -> void:
	_reconnect_attempts += 1
	LogManager.info("MP", "Tentativa de reconexão %d/%d" % [_reconnect_attempts, MAX_RECONNECT_ATTEMPTS])
	reconnection_attempted.emit(_reconnect_attempts, MAX_RECONNECT_ATTEMPTS)

	# Limpa peer anterior
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	var error = join_server(_last_address, _last_port)
	if error != OK:
		if _reconnect_attempts >= MAX_RECONNECT_ATTEMPTS:
			_reconnecting = false
			LogManager.error("MP", "Reconexão falhou após %d tentativas" % MAX_RECONNECT_ATTEMPTS)
			reconnection_failed.emit()
		# Senão, _process vai tentar novamente após RECONNECT_INTERVAL

# ---- RPCs ----
@rpc("any_peer", "reliable")
func register_player_info(peer_id: int, character_id: String) -> void:
	_register_player(peer_id, character_id)
	# Host broadcasts full player list to everyone
	if multiplayer.is_server():
		for pid in players:
			_sync_player_info.rpc(pid, players[pid]["character"])

@rpc("authority", "reliable")
func _sync_player_info(peer_id: int, character_id: String) -> void:
	_register_player(peer_id, character_id)

@rpc("any_peer", "reliable")
func player_loaded(peer_id: int) -> void:
	if peer_id in players:
		players[peer_id]["loaded"] = true
	# Check if all loaded
	var all_loaded = true
	for pid in players:
		if not players[pid]["loaded"]:
			all_loaded = false
			break
	if all_loaded:
		all_players_loaded.emit()

# ---- Callbacks ----
func _on_peer_connected(id: int) -> void:
	LogManager.info("MP", "Peer connected: %d" % id)
	player_connected.emit(id)
	# Send our info to the new peer
	register_player_info.rpc_id(id, local_player_id, GameManager.selected_character)
	# Se somos o server, enviar HP do host e estado completo (para reconexão pós-migração)
	if multiplayer.is_server():
		sync_player_hp.rpc_id(id, local_player_id, GameManager.player_hp, GameManager.get_effective_max_hp())
		# Envia estado completo do jogo para o peer (útil em reconexão pós-migração)
		_send_full_state_to_peer(id)

func _on_peer_disconnected(id: int) -> void:
	LogManager.info("MP", "Peer disconnected: %d" % id)
	players.erase(id)
	lobby_state.erase(id)
	clear_remote_position(id)
	player_disconnected.emit(id)

	# Host migration é tratado via _on_server_disconnected() para clients.
	# Aqui só tratamos o caso de o host detectar que um client saiu
	# (o host não recebe server_disconnected).

func _on_connected_to_server() -> void:
	local_player_id = multiplayer.get_unique_id()
	is_online = true
	_register_player(local_player_id, GameManager.selected_character)
	# Avisa todos sobre nós
	register_player_info.rpc(local_player_id, GameManager.selected_character)
	# Sync HP inicial
	sync_player_hp.rpc(local_player_id, GameManager.player_hp, GameManager.get_effective_max_hp())

	# Se estava reconectando (pós-migração ou perda de conexão)
	if _reconnecting:
		_reconnecting = false
		_reconnect_attempts = 0
		_migration_in_progress = false
		reconnection_succeeded.emit()
		# Se a migração estava em andamento, marca como concluída
		current_host_id = 1  # O novo server sempre é peer_id 1
		host_migration_completed.emit(1)
		LogManager.info("MP", "Reconexão bem-sucedida como %d (novo host: 1)" % local_player_id)
	else:
		connection_succeeded.emit()
		LogManager.info("MP", "Connected as %d" % local_player_id)

func _on_connection_failed() -> void:
	LogManager.error("MP", "Connection failed!")
	# Se estava reconectando, verifica se deve tentar novamente
	if _reconnecting:
		if _reconnect_attempts >= MAX_RECONNECT_ATTEMPTS:
			_reconnecting = false
			is_online = false
			reconnection_failed.emit()
			LogManager.error("MP", "Reconexão falhou após %d tentativas" % MAX_RECONNECT_ATTEMPTS)
		# Senão, _process vai tentar novamente
		return
	is_online = false
	connection_failed.emit()

func _register_player(id: int, character_id: String) -> void:
	players[id] = {
		"character": character_id,
		"ready": false,
		"loaded": false,
		"hp": 100,
		"max_hp": 100,
	}

# ---- Host Migration (com criação de servidor e reconexão de clients) ----

## Chamado quando o sinal server_disconnected é emitido (apenas em clients).
## Isso acontece quando o host desconecta — diferente de peer_disconnected.
func _on_server_disconnected() -> void:
	LogManager.info("MP", "Server disconnected signal received")
	# Salva estado antes de perder a conexão
	_snapshot_game_state()
	_migration_players_backup = players.duplicate(true)
	# Remove o host antigo (peer_id 1) do backup
	_migration_players_backup.erase(1)
	# Dispara migração
	_trigger_host_migration()

## Captura o estado atual do jogo para preservar durante migração.
func _snapshot_game_state() -> void:
	_migration_game_state = {
		"game_time": GameManager.game_time,
		"enemies_alive": GameManager.enemies_alive,
		"total_kills": GameManager.total_kills,
		"crystals_this_run": GameManager.crystals_this_run,
		"player_level": GameManager.player_level,
		"player_xp": GameManager.player_xp,
		"player_xp_to_next": GameManager.player_xp_to_next,
		"max_enemies": GameManager.max_enemies,
		"events_triggered": GameManager.events_triggered,
		"player_hp": GameManager.player_hp,
		"player_weapons": GameManager.player_weapons.duplicate(true),
	}

## Aplica o estado do jogo salvo durante migração.
func _apply_game_state(game_state: Dictionary) -> void:
	if "game_time" in game_state:
		GameManager.game_time = game_state["game_time"]
	if "enemies_alive" in game_state:
		GameManager.enemies_alive = game_state["enemies_alive"]
	if "total_kills" in game_state:
		GameManager.total_kills = game_state["total_kills"]
	if "crystals_this_run" in game_state:
		GameManager.crystals_this_run = game_state["crystals_this_run"]
	if "player_level" in game_state:
		GameManager.player_level = game_state["player_level"]
	if "player_xp" in game_state:
		GameManager.player_xp = game_state["player_xp"]
	if "player_xp_to_next" in game_state:
		GameManager.player_xp_to_next = game_state["player_xp_to_next"]
	if "max_enemies" in game_state:
		GameManager.max_enemies = game_state["max_enemies"]
	if "events_triggered" in game_state:
		GameManager.events_triggered = game_state["events_triggered"]
	if "player_hp" in game_state:
		GameManager.player_hp = game_state["player_hp"]
	if "player_weapons" in game_state:
		GameManager.player_weapons = game_state["player_weapons"]
		GameManager._weapon_level_cache.clear()
		for w in GameManager.player_weapons:
			GameManager._weapon_level_cache[w["id"]] = w["level"]

func _trigger_host_migration() -> void:
	if not is_online:
		return

	# Se somos o server, não fazer nada (o server não migra de si mesmo)
	if multiplayer.is_server():
		LogManager.info("MP", "Host still alive, no migration needed")
		return

	_migration_in_progress = true
	host_migration_started.emit()
	LogManager.info("MP", "Host migration em andamento...")

	# Salva estado se ainda não foi salvo (caso venha de _on_peer_disconnected)
	if _migration_game_state.is_empty():
		_snapshot_game_state()
		_migration_players_backup = players.duplicate(true)
		_migration_players_backup.erase(current_host_id)

	# Determina quem deve ser o novo host (menor peer_id entre os restantes)
	var remaining_peers: Array = []
	# Inclui nós mesmos e os peers do backup
	remaining_peers.append(local_player_id)
	for pid in _migration_players_backup:
		if pid != local_player_id and pid != current_host_id:
			remaining_peers.append(pid)
	remaining_peers.sort()

	if remaining_peers.is_empty():
		LogManager.error("MP", "Nenhum peer restante, jogo desconectado")
		_migration_in_progress = false
		_migration_game_state.clear()
		_migration_players_backup.clear()
		disconnect_from_game()
		reconnection_failed.emit()
		return

	var new_host_id = remaining_peers[0]
	LogManager.info("MP", "Host migration: peer %d será o novo host (local=%d)" % [new_host_id, local_player_id])

	# Fecha peer antigo (o server já caiu, mas cleanup é necessário)
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	if new_host_id == local_player_id:
		# Nós somos o novo host — cria servidor
		_become_new_host()
	else:
		# Outro peer será o host — aguarda e tenta reconectar
		# Usa _last_address pois o novo host está no mesmo endereço de rede
		# Em LAN, o novo host estará acessível pelo mesmo mecanismo
		_wait_and_reconnect_to_new_host()

func _become_new_host() -> void:
	## Cria um novo servidor ENet e assume o papel de host.
	## Preserva o estado do jogo e aguarda reconexão dos outros clients.
	LogManager.info("MP", "Criando novo servidor como host após migração")

	var error = create_server(_last_port)
	if error != OK:
		LogManager.error("MP", "Falha ao criar servidor durante migração: %s" % error)
		_migration_in_progress = false
		_migration_game_state.clear()
		_migration_players_backup.clear()
		reconnection_failed.emit()
		return

	current_host_id = local_player_id  # Agora é 1 (server sempre é 1)

	# Aplica estado preservado
	_apply_game_state(_migration_game_state)

	# Restaura informações dos outros players (eles vão reconectar em breve)
	# Não registra — eles se registram quando conectarem

	_migration_in_progress = false
	_migration_game_state.clear()
	_migration_players_backup.clear()
	host_migrated.emit(local_player_id)
	host_migration_completed.emit(local_player_id)
	LogManager.info("MP", "Novo host ativo na porta %d, aguardando reconexão dos clients" % _last_port)

func _wait_and_reconnect_to_new_host() -> void:
	## Client que NÃO é o novo host aguarda brevemente e tenta reconectar.
	## O novo host precisa de tempo para criar o servidor.
	LogManager.info("MP", "Aguardando novo host criar servidor antes de reconectar...")

	# Preserva o estado local
	_apply_game_state(_migration_game_state)

	# Usa um timer para dar tempo ao novo host de iniciar o servidor
	var timer = get_tree().create_timer(1.5)  # 1.5s de espera
	await timer.timeout

	# Tenta reconectar ao novo host (mesmo endereço, mesma porta)
	# Em jogos LAN, _last_address já aponta para a máquina correta
	# Para reconexão local (mesmo PC), usa localhost
	var reconnect_addr = _last_address if _last_address != "" else "127.0.0.1"
	LogManager.info("MP", "Tentando reconectar a %s:%d" % [reconnect_addr, _last_port])
	_migration_game_state.clear()
	_migration_players_backup.clear()
	reconnect_to_game(reconnect_addr, _last_port)

@rpc("any_peer", "reliable")
func _announce_new_host(new_host_id: int) -> void:
	current_host_id = new_host_id
	if new_host_id == local_player_id:
		_become_new_host()
	else:
		host_migrated.emit(new_host_id)
	LogManager.info("MP", "Novo host anunciado: %d" % new_host_id)

@rpc("any_peer", "reliable")
func _receive_host_migration(new_host_id: int, game_state: Dictionary) -> void:
	## Recebe estado do jogo do novo host durante migração.
	current_host_id = new_host_id
	_migration_in_progress = false

	_apply_game_state(game_state)

	LogManager.info("MP", "Estado do jogo sincronizado do novo host %d" % new_host_id)
	host_migrated.emit(new_host_id)
	host_migration_completed.emit(new_host_id)

## Verifica se há migração de host em andamento
func is_migrating() -> bool:
	return _migration_in_progress

# ---- State Sync para clients que reconectam ----

## Quando um client reconecta após migração, o novo host envia o estado completo.
func _send_full_state_to_peer(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var game_state := {
		"game_time": GameManager.game_time,
		"enemies_alive": GameManager.enemies_alive,
		"total_kills": GameManager.total_kills,
		"crystals_this_run": GameManager.crystals_this_run,
		"player_level": GameManager.player_level,
		"player_xp": GameManager.player_xp,
		"player_xp_to_next": GameManager.player_xp_to_next,
		"max_enemies": GameManager.max_enemies,
		"events_triggered": GameManager.events_triggered,
		"lobby_stage": lobby_stage,
	}
	_receive_full_state_sync.rpc_id(peer_id, game_state)

@rpc("authority", "reliable")
func _receive_full_state_sync(game_state: Dictionary) -> void:
	## Client recebe estado completo do host ao reconectar.
	_apply_game_state(game_state)
	if "lobby_stage" in game_state:
		lobby_stage = game_state["lobby_stage"]
	LogManager.info("MP", "Estado completo recebido do host após reconexão")

# ---- Lobby State Sync (Tasks 1 & 2) ----

## Called by any peer to update their lobby selection (character, relic, ready status).
## Host collects the state and broadcasts it back to all clients.
@rpc("any_peer", "call_remote", "reliable")
func update_player_state(char_id: String, relic_id: String, is_ready: bool) -> void:
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = multiplayer.get_unique_id()
	lobby_state[sender] = {"char_id": char_id, "relic_id": relic_id, "is_ready": is_ready}
	if multiplayer.is_server():
		_broadcast_lobby_state.rpc(lobby_state)
		# Also update locally on the host
		lobby_state_updated.emit()

## Sends the full lobby state from host to all clients.
@rpc("authority", "call_remote", "reliable")
func _broadcast_lobby_state(state: Dictionary) -> void:
	lobby_state = state
	lobby_state_updated.emit()

## Host calls this locally to set its own state and broadcast.
func set_local_player_state(char_id: String, relic_id: String, is_ready: bool) -> void:
	lobby_state[local_player_id] = {"char_id": char_id, "relic_id": relic_id, "is_ready": is_ready}
	if multiplayer.is_server():
		_broadcast_lobby_state.rpc(lobby_state)
		lobby_state_updated.emit()
	else:
		update_player_state.rpc_id(1, char_id, relic_id, is_ready)

## Returns true if all connected players are ready.
func all_players_ready() -> bool:
	if lobby_state.is_empty():
		return false
	for pid in players:
		if pid not in lobby_state:
			return false
		if not lobby_state[pid].get("is_ready", false):
			return false
	return true

# ---- HP Sync ----

@rpc("any_peer", "unreliable")
func sync_player_hp(peer_id: int, hp: int, max_hp: int) -> void:
	if peer_id in players:
		players[peer_id]["hp"] = hp
		players[peer_id]["max_hp"] = max_hp
		player_hp_updated.emit(peer_id, hp, max_hp)

# Chamado quando o jogador local toma dano
func notify_damage(hp: int, max_hp: int) -> void:
	if is_online:
		sync_player_hp.rpc(local_player_id, hp, max_hp)

# Obter HP de um aliado remoto
func get_player_hp(peer_id: int) -> int:
	if peer_id in players:
		return players[peer_id].get("hp", 100)
	return 100

func get_player_max_hp(peer_id: int) -> int:
	if peer_id in players:
		return players[peer_id].get("max_hp", 100)
	return 100

# ---- Helpers ----
func is_host() -> bool:
	return not is_online or multiplayer.is_server()

func get_player_count() -> int:
	if not is_online:
		return 1
	return players.size()

func get_player_ids() -> Array:
	if not is_online:
		return [1]
	return players.keys()

func get_player_colors() -> Dictionary:
	var colors = {
		0: Color(0.2, 0.85, 0.3),  # Verde
		1: Color(0.3, 0.5, 0.95),  # Azul
		2: Color(0.95, 0.4, 0.3),  # Vermelho
		3: Color(0.95, 0.85, 0.2), # Amarelo
	}
	var result = {}
	var i = 0
	for pid in players:
		result[pid] = colors[i % 4]
		i += 1
	return result

# ---- Ping RPC (mede latência via round-trip) ----

## Retorna o último ping medido em milissegundos.
func get_ping() -> int:
	return _ping_ms

## Retorna a cor correspondente ao nível de ping.
## Verde (<50ms), Amarelo (50-100ms), Vermelho (>100ms).
func get_ping_color() -> Color:
	if _ping_ms < 50:
		return Color(0.2, 0.9, 0.3)   # Verde — ótimo
	elif _ping_ms < 100:
		return Color(0.95, 0.85, 0.2)  # Amarelo — aceitável
	else:
		return Color(0.95, 0.2, 0.2)   # Vermelho — ruim

func _measure_ping() -> void:
	## Envia ping para o servidor e mede o tempo de resposta.
	if not is_online:
		return
	if multiplayer.is_server():
		_ping_ms = 0  # Host tem ping 0
		return
	_ping_send_time = Time.get_ticks_usec()
	_ping_request.rpc_id(1)  # Envia para o server (ID 1)

@rpc("any_peer", "unreliable")
func _ping_request() -> void:
	## Server recebe ping e responde imediatamente.
	var sender = multiplayer.get_remote_sender_id()
	_ping_response.rpc_id(sender)

@rpc("authority", "unreliable")
func _ping_response() -> void:
	## Client recebe resposta e calcula RTT.
	var now = Time.get_ticks_usec()
	_ping_ms = (now - _ping_send_time) / 1000  # Converte usec -> ms
	ping_updated.emit(_ping_ms)

# ---- Interpolação de posição para jogadores remotos (Task 4) ----

## Registra uma nova posição recebida de um peer remoto.
## Armazena histórico para interpolação suave.
func register_remote_position(peer_id: int, pos: Vector3) -> void:
	if peer_id not in _remote_positions:
		_remote_positions[peer_id] = []

	var history: Array = _remote_positions[peer_id]
	history.append({
		"pos": pos,
		"time": Time.get_ticks_msec() / 1000.0,
	})

	# Mantém apenas as últimas MAX_POSITION_HISTORY posições
	while history.size() > MAX_POSITION_HISTORY:
		history.pop_front()

## Retorna a posição interpolada de um peer remoto.
## Usa as últimas posições recebidas para suavizar movimento e reduzir jitter.
func get_interpolated_position(peer_id: int, current_pos: Vector3) -> Vector3:
	if peer_id not in _remote_positions:
		return current_pos

	var history: Array = _remote_positions[peer_id]
	if history.is_empty():
		return current_pos

	# Se temos apenas 1 posição, interpola direto
	if history.size() == 1:
		return current_pos.lerp(history[0]["pos"], 0.25)

	# Com 2+ posições, prediz o próximo ponto baseado na velocidade
	var latest = history[history.size() - 1]
	var previous = history[history.size() - 2]
	var dt = latest["time"] - previous["time"]

	if dt <= 0.0:
		return current_pos.lerp(latest["pos"], 0.25)

	# Calcula velocidade entre as últimas 2 posições
	var velocity = (latest["pos"] - previous["pos"]) / dt

	# Tempo desde a última posição recebida
	var now = Time.get_ticks_msec() / 1000.0
	var elapsed = now - latest["time"]

	# Posição prevista = última posição + velocidade * tempo decorrido
	var predicted = latest["pos"] + velocity * clampf(elapsed, 0.0, 0.2)

	# Interpola suavemente entre posição atual e prevista
	return current_pos.lerp(predicted, 0.3)

## Limpa dados de posição de um peer (chamado ao desconectar)
func clear_remote_position(peer_id: int) -> void:
	_remote_positions.erase(peer_id)

# ---- Level Up Pause System (Tasks 3 & 4) ----

## Host tracks which players still need to make a level-up choice.
var players_pending_choice: Array = []

signal level_up_show(peer_id: int)          # Emitted on the client that must choose
signal level_up_waiting()                    # Emitted on clients that should show "Aguardando..."
signal level_up_resumed()                    # Emitted on all clients when game unpauses

## Called by level_up_screen when local player levels up in multiplayer.
## Notifies the Host so it can pause globally and track pending choices.
func request_level_up_pause(peer_id: int) -> void:
	if not is_online:
		return
	if multiplayer.is_server():
		_handle_level_up_request(peer_id)
	else:
		_request_level_up_pause_rpc.rpc_id(1, peer_id)

@rpc("any_peer", "reliable")
func _request_level_up_pause_rpc(peer_id: int) -> void:
	# Only the Host processes this
	if not multiplayer.is_server():
		return
	_handle_level_up_request(peer_id)

## Host-side: pause the game, tell the affected player to show level-up UI,
## tell everyone else to show "Aguardando..." overlay.
func _handle_level_up_request(peer_id: int) -> void:
	if peer_id not in players_pending_choice:
		players_pending_choice.append(peer_id)

	# Pause the tree for everyone
	get_tree().paused = true
	_set_global_pause.rpc(true)

	# Tell the leveling-up player to show their choices
	if peer_id == 1:
		# Host is the one leveling up
		level_up_show.emit(peer_id)
	else:
		_show_level_up_rpc.rpc_id(peer_id)

	# Tell all OTHER players to show waiting overlay
	for pid in players:
		if pid != peer_id and pid != 1:
			_show_waiting_rpc.rpc_id(pid)
	# If host is not the one choosing, host shows waiting too
	if peer_id != 1:
		level_up_waiting.emit()
	# If host IS the one choosing, still notify other local signals
	# (waiting overlay for host handled by checking if host is in pending list)

@rpc("authority", "reliable")
func _show_level_up_rpc() -> void:
	level_up_show.emit(local_player_id)

@rpc("authority", "reliable")
func _show_waiting_rpc() -> void:
	level_up_waiting.emit()

@rpc("authority", "reliable")
func _set_global_pause(paused: bool) -> void:
	get_tree().paused = paused
	if not paused:
		level_up_resumed.emit()

## Called by level_up_screen when a player makes their choice.
## Sends the choice to the Host for application and tracking.
func submit_level_up_choice(peer_id: int, choice_data: Dictionary) -> void:
	if not is_online:
		return
	if multiplayer.is_server():
		_handle_level_up_choice(peer_id, choice_data)
	else:
		_submit_level_up_choice_rpc.rpc_id(1, peer_id, choice_data)

@rpc("any_peer", "reliable")
func _submit_level_up_choice_rpc(peer_id: int, choice_data: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	_handle_level_up_choice(peer_id, choice_data)

## Host-side: remove player from pending list. If list is empty, unpause.
func _handle_level_up_choice(peer_id: int, _choice_data: Dictionary) -> void:
	players_pending_choice.erase(peer_id)
	LogManager.info("MP", "Level up choice received from peer %d. Pending: %s" % [peer_id, str(players_pending_choice)])

	if players_pending_choice.is_empty():
		# Unpause for everyone
		get_tree().paused = false
		_set_global_pause.rpc(false)
		level_up_resumed.emit()
		LogManager.info("MP", "All level-up choices made, game resumed")

# ===========================================================
# LAN BROADCAST / DISCOVERY (Task 5)
# ===========================================================

## Host: start broadcasting server info on LAN via UDP.
func start_lan_broadcast() -> void:
	stop_lan_broadcast()
	_lan_broadcast_peer = PacketPeerUDP.new()
	_lan_broadcast_peer.set_broadcast_enabled(true)
	_lan_broadcast_peer.set_dest_address("255.255.255.255", LAN_BROADCAST_PORT)
	_lan_broadcasting = true
	_lan_broadcast_timer = 0.0
	LogManager.info("MP", "LAN broadcast started on port %d" % LAN_BROADCAST_PORT)

func stop_lan_broadcast() -> void:
	_lan_broadcasting = false
	if _lan_broadcast_peer:
		_lan_broadcast_peer.close()
		_lan_broadcast_peer = null

func _send_lan_broadcast() -> void:
	if not _lan_broadcast_peer:
		return
	var version_str = ""
	if FileAccess.file_exists("res://VERSION"):
		var f = FileAccess.open("res://VERSION", FileAccess.READ)
		if f:
			version_str = f.get_as_text().strip_edges()
	var payload = {
		"game": "zion",
		"version": version_str,
		"host_name": "Sala de %s" % SaveManager.data.get("player_name", "Jogador"),
		"players": get_player_count(),
		"max_players": MAX_PLAYERS,
		"stage": lobby_stage,
		"port": _last_port,
		"has_password": _room_password_hash != "",
	}
	var json = JSON.stringify(payload)
	_lan_broadcast_peer.put_packet(json.to_utf8_buffer())

## Client: start listening for LAN broadcasts.
func start_lan_discovery() -> void:
	stop_lan_discovery()
	_lan_discovery_peer = PacketPeerUDP.new()
	var err = _lan_discovery_peer.bind(LAN_BROADCAST_PORT)
	if err != OK:
		LogManager.error("MP", "Failed to bind LAN discovery port %d: %s" % [LAN_BROADCAST_PORT, err])
		_lan_discovery_peer = null
		return
	_lan_discovering = true
	LogManager.info("MP", "LAN discovery started on port %d" % LAN_BROADCAST_PORT)

func stop_lan_discovery() -> void:
	_lan_discovering = false
	if _lan_discovery_peer:
		_lan_discovery_peer.close()
		_lan_discovery_peer = null

func _poll_lan_discovery() -> void:
	if not _lan_discovery_peer:
		return
	while _lan_discovery_peer.get_available_packet_count() > 0:
		var packet = _lan_discovery_peer.get_packet()
		var ip = _lan_discovery_peer.get_packet_ip()
		var text = packet.get_string_from_utf8()
		var json = JSON.new()
		if json.parse(text) != OK:
			continue
		var data = json.data
		if not data is Dictionary:
			continue
		if data.get("game", "") != "zion":
			continue
		data["ip"] = ip
		lan_server_found.emit(data)

# ===========================================================
# STAGE SELECTION SYNC (Task 4)
# ===========================================================

## Host broadcasts stage selection to all clients.
func broadcast_stage_selection(stage_id: String) -> void:
	lobby_stage = stage_id
	GameManager.selected_stage = stage_id
	if multiplayer.is_server():
		_sync_stage_selection.rpc(stage_id)
		stage_selection_updated.emit()

@rpc("authority", "reliable")
func _sync_stage_selection(stage_id: String) -> void:
	lobby_stage = stage_id
	GameManager.selected_stage = stage_id
	stage_selection_updated.emit()

# ===========================================================
# CHAT SYSTEM (Task 8)
# ===========================================================

## Send a chat message from local player. Host retransmits to all.
func send_chat_message(text: String) -> void:
	var name = SaveManager.data.get("player_name", "Jogador")
	if multiplayer.is_server():
		# Host: broadcast directly
		var color = get_player_colors().get(local_player_id, Color.WHITE)
		_receive_chat_message.rpc(name, text, color.to_html(false))
		chat_message_received.emit(name, text, color)
	else:
		_send_chat_to_host.rpc_id(1, name, text)

@rpc("any_peer", "reliable")
func _send_chat_to_host(sender_name: String, text: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	var color = get_player_colors().get(sender_id, Color.WHITE)
	# Retransmit to all (including sender)
	_receive_chat_message.rpc(sender_name, text, color.to_html(false))
	chat_message_received.emit(sender_name, text, color)

@rpc("authority", "reliable")
func _receive_chat_message(sender_name: String, text: String, color_hex: String) -> void:
	var color = Color.from_string(color_hex, Color.WHITE)
	chat_message_received.emit(sender_name, text, color)

# ===========================================================
# ROOM PASSWORD (Task 10)
# ===========================================================

## Host sets room password (SHA-256 hash or empty string for no password).
func set_room_password(password_hash: String) -> void:
	_room_password_hash = password_hash

## Client sets password attempt for handshake.
func set_client_password(password_hash: String) -> void:
	_client_password_hash = password_hash

# ===========================================================
# EMOTE SYSTEM (Task 9)
# ===========================================================

const EMOTE_LIST: Array = ["Vamos!", "Cuidado!", "Ajuda!", "GG", "Aqui!", "Esperem", "Obrigado!", "LOL"]

signal emote_received(peer_id: int, emote_id: int)

## Broadcast an emote to all players.
func send_emote(emote_id: int) -> void:
	if not is_online:
		return
	if emote_id < 0 or emote_id >= EMOTE_LIST.size():
		return
	_broadcast_emote.rpc(local_player_id, emote_id)
	emote_received.emit(local_player_id, emote_id)

@rpc("any_peer", "unreliable")
func _broadcast_emote(peer_id: int, emote_id: int) -> void:
	emote_received.emit(peer_id, emote_id)
