extends Node
## Manages the mutation/ascension system.
## Mutations are optional difficulty modifiers that increase crystal rewards.

const MUTATIONS: Dictionary = {
	"explosive_enemies": {
		"id": "explosive_enemies",
		"name": "Explosive enemies",
		"description": "Enemies explode on death, dealing area damage",
		"icon": "💥",
		"crystal_bonus": 0.25,
		"max_level": 1,
	},
	"furious_bosses": {
		"id": "furious_bosses",
		"name": "Furious bosses",
		"description": "Bosses start at phase 2 (75% HP)",
		"icon": "😡",
		"crystal_bonus": 0.30,
		"max_level": 1,
	},
	"weakened_healing": {
		"id": "weakened_healing",
		"name": "Weakened healing",
		"description": "All healing reduced by 50%",
		"icon": "💔",
		"crystal_bonus": 0.25,
		"max_level": 1,
	},
	"speed_demons": {
		"id": "speed_demons",
		"name": "Speed demons",
		"description": "Enemies move 30% faster",
		"icon": "⚡",
		"crystal_bonus": 0.25,
		"max_level": 1,
	},
	"endless_horde": {
		"id": "endless_horde",
		"name": "Endless horde",
		"description": "Enemy spawn rate increased by 50%",
		"icon": "💀",
		"crystal_bonus": 0.30,
		"max_level": 1,
	},
	"no_evolution": {
		"id": "no_evolution",
		"name": "No evolution",
		"description": "Weapons cannot evolve past their base form",
		"icon": "🚫",
		"crystal_bonus": 0.30,
		"max_level": 1,
	},
}

var active_mutations: Dictionary = {}


func toggle_mutation(id: String) -> void:
	if not MUTATIONS.has(id):
		return
	if active_mutations.has(id):
		active_mutations.erase(id)
	else:
		active_mutations[id] = 1


func is_active(id: String) -> bool:
	return active_mutations.has(id)


func get_crystal_multiplier() -> float:
	var multiplier: float = 1.0
	for id in active_mutations:
		if MUTATIONS.has(id):
			multiplier += MUTATIONS[id]["crystal_bonus"]
	return multiplier


func get_heal_modifier() -> float:
	if is_active("weakened_healing"):
		return 0.5
	return 1.0


func get_spawn_modifier() -> float:
	if is_active("endless_horde"):
		return 1.5
	return 1.0


func get_enemy_speed_modifier() -> float:
	if is_active("speed_demons"):
		return 1.3
	return 1.0


func can_evolve() -> bool:
	return not is_active("no_evolution")


func get_active_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in active_mutations:
		ids.append(id)
	return ids


func get_all_mutations() -> Dictionary:
	return MUTATIONS


func reset() -> void:
	active_mutations.clear()
