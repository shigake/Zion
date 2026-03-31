extends Node

## Steam integration via GodotSteam plugin.
## Handles init, achievements, cloud save, and lobby management.
## Falls back gracefully when GodotSteam is not installed.

signal steam_initialized
signal lobby_created(lobby_id: int)
signal lobby_joined(lobby_id: int)
signal lobby_invite_received(lobby_id: int)

var is_available: bool = false
var steam_id: int = 0
var steam_name: String = ""
var current_lobby_id: int = 0

# Achievement mapping: local ID -> Steam API ID
const ACHIEVEMENT_MAP := {
	"first_walk": "ACH_FIRST_WALK",
	"evolved_6": "ACH_SIX_EVOLUTIONS",
	"pacifist": "ACH_PACIFIST",
	"speedrunner": "ACH_SPEEDRUNNER",
	"collector": "ACH_COLLECTOR",
	"lucky_day": "ACH_LUCKY_DAY",
	"cow_brejo": "ACH_COW_DODGE",
	"matrix": "ACH_MATRIX",
	"one_punch": "ACH_ONE_PUNCH",
	"nobody_deserves": "ACH_INSTANT_DEATH",
	"genocide": "ACH_GENOCIDE",
	"sweet_revenge": "ACH_SWEET_REVENGE",
	"storm": "ACH_STORM",
	"treasure_hunter": "ACH_TREASURE_HUNTER",
	"quest_master": "ACH_QUEST_MASTER",
	"boss_slayer": "ACH_BOSS_SLAYER",
	"completionist": "ACH_COMPLETIONIST",
}

func _ready() -> void:
	if Engine.has_singleton("Steam"):
		var steam = Engine.get_singleton("Steam")
		var init_result = steam.steamInit()
		if init_result["status"] == 1:
			is_available = true
			steam_id = steam.getSteamID()
			steam_name = steam.getPersonaName()
			LogManager.info("Steam", "Initialized: %s (ID: %d)" % [steam_name, steam_id])
			# Connect lobby signals
			steam.lobby_created.connect(_on_lobby_created)
			steam.lobby_joined.connect(_on_lobby_joined)
			steam.lobby_invite.connect(_on_lobby_invite)
			steam_initialized.emit()
		else:
			LogManager.warn("Steam", "Init failed: %s" % init_result)
	else:
		LogManager.info("Steam", "GodotSteam not available, using ENet fallback")

func _process(_delta: float) -> void:
	if is_available:
		Engine.get_singleton("Steam").run_callbacks()

# ---- Achievements ----

func set_achievement(local_id: String) -> void:
	if not is_available:
		return
	var steam_id_str = ACHIEVEMENT_MAP.get(local_id, "")
	if steam_id_str.is_empty():
		return
	var steam = Engine.get_singleton("Steam")
	steam.setAchievement(steam_id_str)
	steam.storeStats()
	LogManager.info("Steam", "Achievement synced: %s -> %s" % [local_id, steam_id_str])

func clear_achievement(local_id: String) -> void:
	if not is_available:
		return
	var steam_id_str = ACHIEVEMENT_MAP.get(local_id, "")
	if steam_id_str.is_empty():
		return
	var steam = Engine.get_singleton("Steam")
	steam.clearAchievement(steam_id_str)
	steam.storeStats()

# ---- Cloud Save ----

const CLOUD_SAVE_FILE := "zion_save.json"

func cloud_save(save_json: String) -> void:
	if not is_available:
		return
	var steam = Engine.get_singleton("Steam")
	var data = save_json.to_utf8_buffer()
	steam.fileWrite(CLOUD_SAVE_FILE, data)
	LogManager.info("Steam", "Cloud save written (%d bytes)" % data.size())

func cloud_load() -> String:
	if not is_available:
		return ""
	var steam = Engine.get_singleton("Steam")
	if not steam.fileExists(CLOUD_SAVE_FILE):
		return ""
	var size = steam.getFileSize(CLOUD_SAVE_FILE)
	if size <= 0:
		return ""
	var data = steam.fileRead(CLOUD_SAVE_FILE, size)
	LogManager.info("Steam", "Cloud save loaded (%d bytes)" % size)
	return data.get_string_from_utf8()

# ---- Lobby ----

func create_lobby(max_players: int = 4) -> void:
	if not is_available:
		return
	var steam = Engine.get_singleton("Steam")
	steam.createLobby(steam.LOBBY_TYPE_FRIENDS_ONLY, max_players)

func join_lobby(lobby_id: int) -> void:
	if not is_available:
		return
	Engine.get_singleton("Steam").joinLobby(lobby_id)

func leave_lobby() -> void:
	if not is_available or current_lobby_id == 0:
		return
	Engine.get_singleton("Steam").leaveLobby(current_lobby_id)
	current_lobby_id = 0

func invite_friends() -> void:
	if not is_available or current_lobby_id == 0:
		return
	Engine.get_singleton("Steam").activateGameOverlayInviteDialog(current_lobby_id)

func get_lobby_members() -> Array:
	if not is_available or current_lobby_id == 0:
		return []
	var steam = Engine.get_singleton("Steam")
	var count = steam.getNumLobbyMembers(current_lobby_id)
	var members := []
	for i in range(count):
		var member_id = steam.getLobbyMemberByIndex(current_lobby_id, i)
		members.append({
			"steam_id": member_id,
			"name": steam.getFriendPersonaName(member_id),
		})
	return members

func set_lobby_data(key: String, value: String) -> void:
	if not is_available or current_lobby_id == 0:
		return
	Engine.get_singleton("Steam").setLobbyData(current_lobby_id, key, value)

func get_lobby_data(key: String) -> String:
	if not is_available or current_lobby_id == 0:
		return ""
	return Engine.get_singleton("Steam").getLobbyData(current_lobby_id, key)

# ---- Signal callbacks ----

func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result == 1:  # k_EResultOK
		current_lobby_id = lobby_id
		set_lobby_data("game", "zion")
		set_lobby_data("host_steam_id", str(steam_id))
		lobby_created.emit(lobby_id)
		LogManager.info("Steam", "Lobby created: %d" % lobby_id)
	else:
		LogManager.error("Steam", "Lobby creation failed: %d" % result)

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, result: int) -> void:
	if result == 1:
		current_lobby_id = lobby_id
		lobby_joined.emit(lobby_id)
		LogManager.info("Steam", "Joined lobby: %d" % lobby_id)
	else:
		LogManager.error("Steam", "Join lobby failed: %d" % result)

func _on_lobby_invite(_inviter: int, lobby_id: int, _game_id: int) -> void:
	lobby_invite_received.emit(lobby_id)
