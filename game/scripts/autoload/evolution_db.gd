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
		"evolved_damage_mult": 2.5,
		"special": "nuke",
	},
	"ragnarok_axe": {
		"name": "Machado de Ragnarok",
		"description": "Machado cria trilha de fogo ao voar",
		"weapon_required": "axe",
		"item_required": "gunpowder",
		"evolved_damage_mult": 2.5,
		"special": "fire_trail",
	},
	"phantom_fang": {
		"name": "Phantom Fang",
		"description": "Garras fantasmagoricas que drenam vida dos inimigos",
		"weapon_required": "shadow_claw",
		"item_required": "cape",
		"evolved_damage_mult": 2.0,
		"special": "lifesteal_claw",
	},
	"minigun_infernal": {
		"name": "Minigun Infernal",
		"description": "Projeteis explosivos + fire rate insano",
		"weapon_required": "machinegun",
		"item_required": "laser_sight",
		"evolved_damage_mult": 2.5,
		"special": "explosive_bullets",
	},
	"lord_of_dead": {
		"name": "Senhor dos Mortos",
		"description": "Invocacoes ganham aura de morte",
		"weapon_required": "necro",
		"item_required": "grimoire",
		"evolved_damage_mult": 2.5,
		"special": "death_aura",
	},
	"inferno_walker": {
		"name": "Inferno Walker",
		"description": "Chamas deixam rastro de fogo no chao",
		"weapon_required": "flamethrower",
		"item_required": "gasoline",
		"evolved_damage_mult": 2.5,
		"special": "fire_ground",
	},
	"vampire_whip": {
		"name": "Vampire Whip",
		"description": "Chicote drena vida e explode em area",
		"weapon_required": "whip",
		"item_required": "vampire_blood",
		"evolved_damage_mult": 2.5,
		"special": "lifedrain_explosion",
	},
	"electric_storm": {
		"name": "Tempestade Eletrica",
		"description": "Raios atingem todos os inimigos na tela",
		"weapon_required": "lightning_chain",
		"item_required": "tesla",
		"evolved_damage_mult": 2.5,
		"special": "chain_storm",
	},
	"arrow_storm": {
		"name": "Tempestade de Flechas",
		"description": "Chuva de flechas cai do ceu na area ao redor",
		"weapon_required": "elven_bow",
		"item_required": "cape",
		"evolved_damage_mult": 2.5,
		"special": "arrow_rain",
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
	if not MutationManager.can_evolve():
		return ""
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
