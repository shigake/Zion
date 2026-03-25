extends Node

## Database de personagens jogaveis.

var characters: Dictionary = {
	"ronin": {
		"name": "Ronin",
		"starting_weapon": "katana",
		"passive": "+20% critical hit",
		"color": Color(0.2, 0.85, 0.3),
		"speed_bonus": 0.0,
		"damage_bonus": 0.0,
	},
	"soldado": {
		"name": "Soldado",
		"starting_weapon": "machinegun",
		"passive": "+15% attack speed",
		"color": Color(0.3, 0.5, 0.9),
		"speed_bonus": 0.0,
		"damage_bonus": 0.0,
		"attack_speed_bonus": 0.15,
	},
	"mago": {
		"name": "Mago",
		"starting_weapon": "staff",
		"passive": "+25% area de efeito",
		"color": Color(0.7, 0.3, 0.9),
		"speed_bonus": 0.0,
		"damage_bonus": 0.0,
		"area_bonus": 0.25,
	},
}

func get_character(id: String) -> Dictionary:
	if id in characters:
		return characters[id]
	return {}

func get_all_character_ids() -> Array:
	return characters.keys()
