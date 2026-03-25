extends Node

## Database de reliquias (escolhidas antes da run).

var relics: Dictionary = {
	"hourglass": {
		"name": "Ampulheta",
		"description": "Run dura 40 min ao inves de 30",
		"effect": "extend_time",
	},
	"golden_dice": {
		"name": "Dados de Ouro",
		"description": "+1 reroll por level up",
		"effect": "extra_reroll",
	},
	"extra_heart": {
		"name": "Coracao Extra",
		"description": "+50% HP inicial",
		"effect": "bonus_hp",
	},
}

func get_relic(id: String) -> Dictionary:
	if id in relics:
		return relics[id]
	return {}

func get_all_relic_ids() -> Array:
	return relics.keys()
