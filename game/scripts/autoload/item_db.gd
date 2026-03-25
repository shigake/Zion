extends Node

## Database de itens passivos.

var items: Dictionary = {
	"boots": {
		"name": "Botas de Hermes",
		"description": "+15% velocidade por level",
		"color": Color(0.2, 0.7, 1.0),
		"stat": "speed",
		"value_per_level": 0.15,
	},
	"glove": {
		"name": "Luva de Velocidade",
		"description": "+20% attack speed por level",
		"color": Color(1.0, 0.8, 0.2),
		"stat": "attack_speed",
		"value_per_level": 0.20,
	},
	"heart": {
		"name": "Coracao de Dragao",
		"description": "+20% HP maximo por level",
		"color": Color(1.0, 0.2, 0.3),
		"stat": "max_hp",
		"value_per_level": 0.20,
	},
	"crystal": {
		"name": "Cristal Arcano",
		"description": "+25% area de efeito por level",
		"color": Color(0.7, 0.3, 1.0),
		"stat": "area",
		"value_per_level": 0.25,
	},
	"magnet": {
		"name": "Ima",
		"description": "+60% range de coleta por level",
		"color": Color(0.8, 0.8, 0.8),
		"stat": "magnet",
		"value_per_level": 0.60,
	},
	"clock": {
		"name": "Relogio Quebrado",
		"description": "-8% cooldown por level",
		"color": Color(0.4, 0.8, 0.4),
		"stat": "cooldown",
		"value_per_level": 0.08,
	},
}

func get_item(id: String) -> Dictionary:
	if id in items:
		return items[id]
	return {}

func get_all_item_ids() -> Array:
	return items.keys()
