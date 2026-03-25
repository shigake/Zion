extends Node

## Database de armas. Define stats base e scaling por level.

var weapons: Dictionary = {
	"katana": {
		"name": "Espada Samurai",
		"type": "melee",
		"description": "Corte rapido em arco na frente",
		"base_damage": 12,
		"base_cooldown": 1.2,
		"base_area": 2.0,
		"damage_per_level": 4,
		"cooldown_per_level": -0.08,
		"area_per_level": 0.2,
	},
	"staff": {
		"name": "Staff Magico",
		"type": "ranged",
		"description": "Projetil homing que persegue inimigos",
		"base_damage": 8,
		"base_cooldown": 1.5,
		"base_speed": 12.0,
		"damage_per_level": 3,
		"cooldown_per_level": -0.1,
		"projectiles_per_level": 0,
	},
	"scythe": {
		"name": "Foice",
		"type": "melee",
		"description": "Gira ao redor do jogador, drena vida",
		"base_damage": 10,
		"base_cooldown": 0.0,
		"base_area": 2.5,
		"damage_per_level": 3,
		"cooldown_per_level": 0,
		"area_per_level": 0.3,
		"lifesteal": 0.02,
	},
	"machinegun": {
		"name": "Metralhadora",
		"type": "ranged",
		"description": "Spray de projeteis rapidos",
		"base_damage": 4,
		"base_cooldown": 0.15,
		"base_speed": 20.0,
		"damage_per_level": 2,
		"cooldown_per_level": -0.01,
		"spread": 0.3,
	},
	"bazooka": {
		"name": "Bazuca",
		"type": "ranged",
		"description": "Explosao em area, cooldown longo",
		"base_damage": 30,
		"base_cooldown": 3.5,
		"base_speed": 10.0,
		"base_area": 3.0,
		"damage_per_level": 10,
		"cooldown_per_level": -0.2,
		"area_per_level": 0.4,
	},
	"necro": {
		"name": "Necromante",
		"type": "summon",
		"description": "Invoca esqueletos que lutam por voce",
		"base_damage": 6,
		"base_cooldown": 4.0,
		"max_summons": 2,
		"damage_per_level": 2,
		"cooldown_per_level": -0.3,
		"summons_per_level": 1,
	},
}

func get_weapon(id: String) -> Dictionary:
	if id in weapons:
		return weapons[id]
	return {}

func get_damage(id: String, level: int) -> float:
	var w = get_weapon(id)
	if w.is_empty():
		return 0
	return w["base_damage"] + w["damage_per_level"] * (level - 1)

func get_cooldown(id: String, level: int) -> float:
	var w = get_weapon(id)
	if w.is_empty():
		return 1.0
	return maxf(0.05, w["base_cooldown"] + w["cooldown_per_level"] * (level - 1))

func get_all_weapon_ids() -> Array:
	return weapons.keys()
