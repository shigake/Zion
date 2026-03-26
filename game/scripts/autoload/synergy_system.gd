extends Node

## Sistema de Sinergias Elementais.
## Armas do mesmo elemento ou elementos complementares criam efeitos bonus.

# Sinergias ativas nesta run
var active_synergies: Array[String] = []

func check_synergies() -> void:
	active_synergies.clear()

	var element_count: Dictionary = {}
	for w in GameManager.player_weapons:
		var elem = WeaponDB.get_element(w["id"])
		if elem not in element_count:
			element_count[elem] = 0
		element_count[elem] += 1

	# Sinergias de elemento duplo
	for elem in element_count:
		if element_count[elem] >= 2:
			var synergy_id = elem + "_" + elem
			if synergy_id not in active_synergies:
				active_synergies.append(synergy_id)

	# Sinergias cruzadas
	if "fire" in element_count and "ice" in element_count:
		active_synergies.append("fire_ice")
	if "electric" in element_count and "ice" in element_count:
		active_synergies.append("electric_ice")

func has_synergy(synergy_id: String) -> bool:
	return synergy_id in active_synergies

func get_synergy_description(synergy_id: String) -> String:
	match synergy_id:
		"fire_fire":
			return "Fogo + Fogo: 20% chance de explosao ao matar"
		"ice_ice":
			return "Gelo + Gelo: Inimigos congelados explodem em estilhacos"
		"electric_electric":
			return "Eletrico + Eletrico: Chain lightning ao matar"
		"dark_dark":
			return "Dark + Dark: Area de trevas passiva ao redor"
		"fire_ice":
			return "Fogo + Gelo: Steam cloud (dano + slow)"
		"electric_ice":
			return "Eletrico + Gelo: Condutor (dano em area massivo)"
	return ""

# ---- On Kill Synergies ----

func apply_on_kill_synergies(kill_position: Vector3) -> void:
	if has_synergy("fire_fire"):
		if randf() < 0.2:
			_fire_explosion(kill_position)
	if has_synergy("ice_ice"):
		if randf() < 0.25:
			_ice_shatter(kill_position)
	if has_synergy("electric_electric"):
		if randf() < 0.3:
			_chain_lightning(kill_position)

# ---- Passive Synergies (called from player/stage every frame) ----

var _dark_aura_timer: float = 0.0
var _steam_cloud_timer: float = 0.0
var _conductor_timer: float = 0.0

func apply_passive_synergies(player_pos: Vector3, _delta: float) -> void:
	if has_synergy("dark_dark"):
		_dark_aura_tick(player_pos)
	if has_synergy("fire_ice"):
		_steam_cloud_tick(player_pos)
	if has_synergy("electric_ice"):
		_conductor_tick(player_pos)

# ---- Fire + Fire: Explosion on kill ----

func _fire_explosion(pos: Vector3) -> void:
	ParticleFactory.spawn_explosion_particles(pos, 2.0)
	ScreenEffects.shake(0.08)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) < 2.5:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", 20, "fire")

# ---- Ice + Ice: Shatter frozen enemies ----

func _ice_shatter(pos: Vector3) -> void:
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.5, 0), Color(0.4, 0.85, 1.0), 10)
	ScreenEffects.shake(0.06)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) < 3.0:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", 15, "ice")
			# Slow nearby enemies
			if e is EnemyBase3D:
				var original_speed = e.speed
				e.speed *= 0.4
				# Restore after 2s
				get_tree().create_timer(2.0).timeout.connect(func():
					if is_instance_valid(e):
						e.speed = original_speed
				)

# ---- Electric + Electric: Chain Lightning ----

func _chain_lightning(start_pos: Vector3) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_enemies: Array = []
	var current_pos = start_pos
	var chain_range = 5.0
	var chain_count = 5
	var chain_damage = 12

	for _i in range(chain_count):
		var closest: Node3D = null
		var closest_dist: float = chain_range
		for e in enemies:
			if not is_instance_valid(e) or e in hit_enemies:
				continue
			var dist = current_pos.distance_to(e.global_position)
			if dist < closest_dist:
				closest = e
				closest_dist = dist
		if closest == null:
			break
		hit_enemies.append(closest)
		# Visual lightning spark
		ParticleFactory.spawn_hit_particles(closest.global_position + Vector3(0, 0.5, 0), Color(1.0, 1.0, 0.3), 4)
		if closest.has_method("take_damage"):
			closest.call_deferred("take_damage", chain_damage, "electric")
		current_pos = closest.global_position

	if not hit_enemies.is_empty():
		ScreenEffects.shake(0.05)

# ---- Dark + Dark: Passive aura damage ----

func _dark_aura_tick(pos: Vector3) -> void:
	_dark_aura_timer += get_process_delta_time()
	if _dark_aura_timer < 1.0:
		return
	_dark_aura_timer = 0.0

	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) < 4.0:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", 5, "dark")

# ---- Fire + Ice: Steam Cloud (slow + damage) ----

func _steam_cloud_tick(pos: Vector3) -> void:
	_steam_cloud_timer += get_process_delta_time()
	if _steam_cloud_timer < 1.5:
		return
	_steam_cloud_timer = 0.0

	# Spawn steam particles
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.3, 0), Color(0.8, 0.8, 0.8, 0.6), 8)

	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) < 3.5:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", 8, "fire")
			# Slow
			if e is EnemyBase3D:
				var original_speed = e.speed
				e.speed *= 0.6
				get_tree().create_timer(1.5).timeout.connect(func():
					if is_instance_valid(e):
						e.speed = original_speed
				)

# ---- Electric + Ice: Conductor (massive AoE) ----

func _conductor_tick(pos: Vector3) -> void:
	_conductor_timer += get_process_delta_time()
	if _conductor_timer < 3.0:
		return
	_conductor_timer = 0.0

	ParticleFactory.spawn_explosion_particles(pos, 5.0)
	ScreenEffects.shake(0.12)

	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) < 6.0:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", 25, "electric")

func reset() -> void:
	active_synergies.clear()
	_dark_aura_timer = 0.0
	_steam_cloud_timer = 0.0
	_conductor_timer = 0.0
