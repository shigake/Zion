extends Node

## Steam integration stub. Checks for GodotSteam plugin availability.
## When GodotSteam is installed, this will handle Steam init, auth, and networking.

var is_available: bool = false
var steam_id: int = 0
var steam_name: String = ""

func _ready() -> void:
	if Engine.has_singleton("Steam"):
		var steam = Engine.get_singleton("Steam")
		var init_result = steam.steamInit()
		if init_result["status"] == 1:
			is_available = true
			steam_id = steam.getSteamID()
			steam_name = steam.getPersonaName()
			print("[Steam] Initialized: %s (ID: %d)" % [steam_name, steam_id])
		else:
			push_warning("[Steam] Init failed: %s" % init_result)
	else:
		print("[Steam] GodotSteam not available, using ENet fallback")

func _process(_delta: float) -> void:
	if is_available:
		Engine.get_singleton("Steam").run_callbacks()
