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
	"cape": {
		"name": "Capa das Sombras",
		"description": "6% chance de dodge por level",
		"color": Color(0.3, 0.2, 0.4),
		"stat": "dodge",
		"value_per_level": 0.06,
	},
	"xp_amulet": {
		"name": "Amuleto de XP",
		"description": "+25% experiencia por level",
		"color": Color(0.2, 0.8, 0.2),
		"stat": "xp_bonus",
		"value_per_level": 0.25,
	},
	"gunpowder": {
		"name": "Polvora Extra",
		"description": "+25% dano de explosao por level",
		"color": Color(0.9, 0.4, 0.1),
		"stat": "explosion_damage",
		"value_per_level": 0.25,
	},
	"tesla": {
		"name": "Bateria Tesla",
		"description": "+20% dano eletrico por level",
		"color": Color(0.3, 0.7, 1.0),
		"stat": "electric_damage",
		"value_per_level": 0.20,
	},
	"vampire_blood": {
		"name": "Sangue de Vampiro",
		"description": "+5% lifesteal por level",
		"color": Color(0.6, 0.0, 0.1),
		"stat": "lifesteal",
		"value_per_level": 0.05,
	},
	"thorn_shield": {
		"name": "Escudo de Espinhos",
		"description": "Reflete 20% dano por level",
		"color": Color(0.5, 0.5, 0.3),
		"stat": "thorns",
		"value_per_level": 0.20,
	},
	"lucky_coin": {
		"name": "Moeda da Sorte",
		"description": "+30% chance drop raro por level",
		"color": Color(1.0, 0.85, 0.0),
		"stat": "luck",
		"value_per_level": 0.30,
	},
	"quiver": {
		"name": "Aljava Infinita",
		"description": "+1 projetil por level",
		"color": Color(0.6, 0.4, 0.2),
		"stat": "extra_projectiles",
		"value_per_level": 1.0,
	},
	"grimoire": {
		"name": "Grimorio Negro",
		"description": "+30% dano invocacoes por level",
		"color": Color(0.2, 0.0, 0.3),
		"stat": "summon_damage",
		"value_per_level": 0.30,
	},
	"giant_elixir": {
		"name": "Elixir de Gigante",
		"description": "+25% tamanho ataques por level",
		"color": Color(0.4, 0.7, 0.3),
		"stat": "attack_size",
		"value_per_level": 0.25,
	},
	"gasoline": {
		"name": "Gasolina",
		"description": "Inimigos mortos deixam chao em fogo",
		"color": Color(0.9, 0.3, 0.0),
		"stat": "fire_ground",
		"value_per_level": 1.0,
		"disabled": true,
	},
	"crown": {
		"name": "Coroa",
		"description": "+1 level em todas as armas",
		"color": Color(1.0, 0.85, 0.2),
		"stat": "weapon_level_bonus",
		"value_per_level": 1.0,
	},
	"laser_sight": {
		"name": "Mira Laser",
		"description": "+20% precisao por level",
		"color": Color(1.0, 0.1, 0.1),
		"stat": "accuracy",
		"value_per_level": 0.20,
	},
}

func get_item(id: String) -> Dictionary:
	if id in items:
		return items[id]
	return {}

func get_all_item_ids() -> Array:
	return items.keys()
