extends Node

## Database de upgrades permanentes da loja.

var upgrades: Dictionary = {
	"max_hp": {
		"name": "HP Maximo",
		"description": "+10 HP por level",
		"base_cost": 50,
		"cost_per_level": 30,
		"max_level": 10,
		"stat": "max_hp",
		"value_per_level": 10,
	},
	"speed": {
		"name": "Velocidade",
		"description": "+5% velocidade por level",
		"base_cost": 40,
		"cost_per_level": 25,
		"max_level": 8,
		"stat": "speed",
		"value_per_level": 0.05,
	},
	"damage": {
		"name": "Dano Base",
		"description": "+5% dano por level",
		"base_cost": 60,
		"cost_per_level": 35,
		"max_level": 10,
		"stat": "damage",
		"value_per_level": 0.05,
	},
	"armor": {
		"name": "Armadura",
		"description": "Reduz dano recebido",
		"base_cost": 50,
		"cost_per_level": 30,
		"max_level": 8,
		"stat": "armor",
		"value_per_level": 2,
	},
	"xp_bonus": {
		"name": "XP Bonus",
		"description": "+10% XP por level",
		"base_cost": 40,
		"cost_per_level": 20,
		"max_level": 8,
		"stat": "xp_bonus",
		"value_per_level": 0.10,
	},
	"magnetism": {
		"name": "Magnetismo",
		"description": "+range de coleta por level",
		"base_cost": 30,
		"cost_per_level": 20,
		"max_level": 5,
		"stat": "magnet",
		"value_per_level": 0.20,
	},
}

func get_upgrade(id: String) -> Dictionary:
	if id in upgrades:
		return upgrades[id]
	return {}

func get_all_upgrade_ids() -> Array:
	return upgrades.keys()

func get_cost(id: String) -> int:
	var u = get_upgrade(id)
	if u.is_empty():
		return 0
	var current = SaveManager.get_upgrade_level(id)
	return u["base_cost"] + u["cost_per_level"] * current
