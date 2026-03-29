extends Node

## Gerencia keybindings customizaveis. Salva/carrega do save file.

const SAVE_PATH := "user://keybindings.json"

# Default keybindings: action_name -> {key: KEY_*, gamepad_button: JOY_BUTTON_*, gamepad_axis: {axis, value}}
var defaults: Dictionary = {
	"move_up": {"key": KEY_W},
	"move_down": {"key": KEY_S},
	"move_left": {"key": KEY_A},
	"move_right": {"key": KEY_D},
	"dash": {"key": KEY_SPACE, "gamepad_button": JOY_BUTTON_A},
	"interact": {"key": KEY_E, "gamepad_button": JOY_BUTTON_B},
	"pause": {"key": KEY_ESCAPE, "gamepad_button": JOY_BUTTON_START},
	"level_up_choice_1": {"key": KEY_1},
	"level_up_choice_2": {"key": KEY_2},
	"level_up_choice_3": {"key": KEY_3},
	"level_up_reroll": {"key": KEY_SPACE, "gamepad_button": JOY_BUTTON_Y},
	"emote": {"key": KEY_T},
}

var bindings: Dictionary = {}

# Display names for actions
var action_names: Dictionary = {
	"move_up": "Mover Cima",
	"move_down": "Mover Baixo",
	"move_left": "Mover Esquerda",
	"move_right": "Mover Direita",
	"dash": "Dash",
	"interact": "Interagir",
	"pause": "Pausar",
	"level_up_choice_1": "Level Up - Escolha 1",
	"level_up_choice_2": "Level Up - Escolha 2",
	"level_up_choice_3": "Level Up - Escolha 3",
	"level_up_reroll": "Level Up - Reroll",
	"emote": "Emotes",
}

func _ready() -> void:
	bindings = defaults.duplicate(true)
	load_bindings()

func get_action_display_name(action: String) -> String:
	return action_names.get(action, action)

func get_key_name(action: String) -> String:
	var bind = bindings.get(action, {})
	if "key" in bind:
		return OS.get_keycode_string(bind["key"])
	return "???"

func rebind_action(action: String, new_key: Key) -> void:
	if action not in bindings:
		return
	bindings[action]["key"] = new_key
	_apply_bindings()
	save_bindings()

func reset_defaults() -> void:
	bindings = defaults.duplicate(true)
	_apply_bindings()
	save_bindings()

func _apply_bindings() -> void:
	for action in bindings:
		if InputMap.has_action(action):
			# Remove existing key events (keep joypad)
			var events = InputMap.action_get_events(action)
			for event in events:
				if event is InputEventKey:
					InputMap.action_erase_event(action, event)
		else:
			InputMap.add_action(action)

		var bind = bindings[action]
		if "key" in bind:
			var event = InputEventKey.new()
			event.physical_keycode = bind["key"]
			InputMap.action_add_event(action, event)

func save_bindings() -> void:
	var save_data: Dictionary = {}
	for action in bindings:
		if "key" in bindings[action]:
			save_data[action] = bindings[action]["key"]
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

func load_bindings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var result = json.parse(file.get_as_text())
		if result == OK and json.data is Dictionary:
			for action in json.data:
				if action in bindings:
					bindings[action]["key"] = int(json.data[action])
		file.close()
	_apply_bindings()

func get_rebindable_actions() -> Array:
	return bindings.keys()
