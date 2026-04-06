extends Node

## Database de reliquias (escolhidas antes da run).

var relics: Dictionary = {
	"hourglass": {
		"name": "Ampulheta",
		"description": "+10 min de duracao na run",
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
	"compass": {
		"name": "Bussola",
		"description": "Mostra direcao do proximo evento + 15% XP",
		"effect": "show_event_direction",
	},
	"scroll": {
		"name": "Pergaminho Antigo",
		"description": "Comeca com 1 arma extra aleatoria",
		"effect": "extra_weapon",
	},
	"veteran_medal": {
		"name": "Medalha de Veterano",
		"description": "+20% XP mas inimigos +15% rapidos",
		"effect": "veteran",
	},
	"master_key": {
		"name": "Chave Mestre",
		"description": "Baus dropam 2x itens",
		"effect": "double_chest",
	},
}

func get_relic(id: String) -> Dictionary:
	if id in relics:
		return relics[id]
	return {}

func get_all_relic_ids() -> Array:
	return relics.keys()
