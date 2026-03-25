extends Node

## Database de evolucoes de arma.
## Arma nivel 8 + item passivo especifico = evolucao.

var evolutions: Dictionary = {
	"zangetsu": {
		"name": "Zangetsu",
		"description": "Cortes criam ondas de energia",
		"weapon_required": "katana",
		"item_required": "glove",
		"evolved_damage_mult": 2.5,
		"special": "energy_waves",
	},
	"apocalypse_staff": {
		"name": "Cajado do Apocalipse",
		"description": "Meteoros caem do ceu",
		"weapon_required": "staff",
		"item_required": "crystal",
		"evolved_damage_mult": 3.0,
		"special": "meteor_rain",
	},
	"death_scythe": {
		"name": "Death Scythe",
		"description": "Executa inimigos abaixo de 20% HP",
		"weapon_required": "scythe",
		"item_required": "clock",
		"evolved_damage_mult": 2.0,
		"special": "execute",
	},
	"nuke_launcher": {
		"name": "Nuke Launcher",
		"description": "Explosao gigante + mushroom cloud",
		"weapon_required": "bazooka",
		"item_required": "magnet",  # adapter: explosion pulls enemies
		"evolved_damage_mult": 3.5,
		"special": "nuke",
	},
}

# Armas ja evoluidas nesta run
var evolved_weapons: Array[String] = []

func get_evolution(id: String) -> Dictionary:
	if id in evolutions:
		return evolutions[id]
	return {}

func get_all_evolution_ids() -> Array:
	return evolutions.keys()

func check_evolution_available() -> String:
	## Retorna o ID da evolucao disponivel, ou "" se nenhuma.
	for evo_id in evolutions:
		if evo_id in evolved_weapons:
			continue
		var evo = evolutions[evo_id]
		var weapon_level = GameManager.get_weapon_level(evo["weapon_required"])
		var item_level = GameManager.get_item_level(evo["item_required"])
		if weapon_level >= 8 and item_level >= 5:
			return evo_id
	return ""

func evolve_weapon(evo_id: String) -> void:
	if evo_id in evolved_weapons:
		return
	evolved_weapons.append(evo_id)

func reset() -> void:
	evolved_weapons.clear()
