extends Node

## Sistema de Sinergias Elementais.
## Armas do mesmo elemento ou elementos complementares criam efeitos bonus.

# Mapa de arma -> elemento
var weapon_elements: Dictionary = {
	"katana": "physical",
	"staff": "arcane",
	"scythe": "dark",
	"machinegun": "physical",
	"bazooka": "fire",
	"necro": "dark",
}

# Sinergias ativas nesta run
var active_synergies: Array[String] = []

func check_synergies() -> void:
	active_synergies.clear()

	var element_count: Dictionary = {}
	for w in GameManager.player_weapons:
		var elem = weapon_elements.get(w["id"], "physical")
		if elem not in element_count:
			element_count[elem] = 0
		element_count[elem] += 1

	# Sinergias de elemento duplo
	for elem in element_count:
		if element_count[elem] >= 2:
			match elem:
				"fire":
					if "fire_fire" not in active_synergies:
						active_synergies.append("fire_fire")
				"dark":
					if "dark_dark" not in active_synergies:
						active_synergies.append("dark_dark")

	# Sinergias cruzadas
	if "fire" in element_count and "ice" in element_count:
		active_synergies.append("fire_ice")
	if "electric" in element_count and "water" in element_count:
		active_synergies.append("electric_water")

func has_synergy(synergy_id: String) -> bool:
	return synergy_id in active_synergies

func get_synergy_description(synergy_id: String) -> String:
	match synergy_id:
		"fire_fire":
			return "Fogo + Fogo: Chance de explosao ao matar"
		"dark_dark":
			return "Dark + Dark: Area de trevas passiva ao redor"
		"fire_ice":
			return "Fogo + Gelo: Steam cloud (dano + cegueira)"
		"electric_water":
			return "Eletrico + Agua: Condutor (dano em area massivo)"
	return ""

func apply_on_kill_synergies(kill_position: Vector3) -> void:
	if has_synergy("fire_fire"):
		# 20% chance de explosao ao matar
		if randf() < 0.2:
			_fire_explosion(kill_position)

func apply_passive_synergies(player_pos: Vector3, delta: float) -> void:
	if has_synergy("dark_dark"):
		# Dano passivo em area ao redor (a cada 1s)
		_dark_aura_tick(player_pos)

var _dark_aura_timer: float = 0.0

func _dark_aura_tick(pos: Vector3) -> void:
	_dark_aura_timer += get_process_delta_time()
	if _dark_aura_timer < 1.0:
		return
	_dark_aura_timer = 0.0

	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) < 4.0:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", 5)

func _fire_explosion(pos: Vector3) -> void:
	ParticleFactory.spawn_explosion_particles(pos, 2.0)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) < 2.5:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", 20)

func reset() -> void:
	active_synergies.clear()
	_dark_aura_timer = 0.0
