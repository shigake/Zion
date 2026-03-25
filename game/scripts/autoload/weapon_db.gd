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
		"projectiles_per_level": 0,  # +1 projetil nos levels 3 e 6
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
	return maxf(0.2, w["base_cooldown"] + w["cooldown_per_level"] * (level - 1))

func get_all_weapon_ids() -> Array:
	return weapons.keys()
