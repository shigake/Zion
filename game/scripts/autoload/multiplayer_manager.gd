extends Node

## Gerencia multiplayer online: lobby, conexões, spawn de jogadores.
## Arquitetura: Host-Client (listen server) via ENet (fallback sem Steam).
## Para Steam: substituir ENet por Steam Networking Sockets via GodotSteam.

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal server_created()
signal connection_failed()
signal connection_succeeded()
signal all_players_loaded()

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

enum NetworkBackend { ENET, STEAM }

# peer_id -> {name, character, ready, loaded}
var players: Dictionary = {}
var local_player_id: int = 0
var is_online: bool = false
var backend: int = NetworkBackend.ENET

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _create_server_peer(port: int) -> Array:
	# Returns [peer, error]. Override for Steam networking when available.
	if backend == NetworkBackend.STEAM and SteamManager.is_available:
		# Steam Networking Sockets - requires GodotSteam plugin
		# var peer = SteamMultiplayerPeer.new()
		# var error = peer.create_host(0, [])
		# return [peer, error]
		pass
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)
	return [peer, error]

func _create_client_peer(address: String, port: int) -> Array:
	# Returns [peer, error]. Override for Steam networking when available.
	if backend == NetworkBackend.STEAM and SteamManager.is_available:
		# Steam Networking Sockets - requires GodotSteam plugin
		# var peer = SteamMultiplayerPeer.new()
		# var error = peer.create_client(steam_id, 0, [])
		# return [peer, error]
		pass
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	return [peer, error]

# ---- Host ----
func create_server(port: int = DEFAULT_PORT) -> Error:
	var result = _create_server_peer(port)
	var peer = result[0]
	var error = result[1]
	if error != OK:
		push_error("Failed to create server: %s" % error)
		return error
	multiplayer.multiplayer_peer = peer
	local_player_id = 1
	is_online = true
	_register_player(1, GameManager.selected_character)
	server_created.emit()
	print("[MP] Server created on port %d" % port)
	return OK

# ---- Client ----
func join_server(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> Error:
	var result = _create_client_peer(address, port)
	var peer = result[0]
	var error = result[1]
	if error != OK:
		push_error("Failed to connect: %s" % error)
		return error
	multiplayer.multiplayer_peer = peer
	is_online = true
	print("[MP] Connecting to %s:%d..." % [address, port])
	return OK

func disconnect_from_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	players.clear()
	local_player_id = 0
	is_online = false

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
	print("[MP] Peer connected: %d" % id)
	player_connected.emit(id)
	# Send our info to the new peer
	register_player_info.rpc_id(id, local_player_id, GameManager.selected_character)

func _on_peer_disconnected(id: int) -> void:
	print("[MP] Peer disconnected: %d" % id)
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	local_player_id = multiplayer.get_unique_id()
	is_online = true
	_register_player(local_player_id, GameManager.selected_character)
	# Tell everyone about us
	register_player_info.rpc(local_player_id, GameManager.selected_character)
	connection_succeeded.emit()
	print("[MP] Connected as %d" % local_player_id)

func _on_connection_failed() -> void:
	push_error("[MP] Connection failed!")
	is_online = false
	connection_failed.emit()

func _register_player(id: int, character_id: String) -> void:
	players[id] = {
		"character": character_id,
		"ready": false,
		"loaded": false,
	}

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
