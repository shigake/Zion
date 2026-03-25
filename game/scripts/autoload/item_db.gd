extends Node

## Database de itens passivos.

var items: Dictionary = {
	"boots": {
		"name": "Botas de Hermes",
		"description": "+15% velocidade por level",
		"color": Color(0.2, 0.7, 1.0),
	},
	"glove": {
		"name": "Luva de Velocidade",
		"description": "+20% attack speed por level",
		"color": Color(1.0, 0.8, 0.2),
	},
	"heart": {
		"name": "Coracao de Dragao",
		"description": "+20% HP maximo por level",
		"color": Color(1.0, 0.2, 0.3),
	},
}

func get_item(id: String) -> Dictionary:
	if id in items:
		return items[id]
	return {}

func get_all_item_ids() -> Array:
	return items.keys()
