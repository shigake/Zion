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
	_cross_combo_cooldowns.clear()
	_elemental_zones.clear()

# ================================================================
# Cross-Combo (Multiplayer Synergies)
# ================================================================

## Registered elemental zones: Array of {position, element, owner_peer, expire_time}
var _elemental_zones: Array[Dictionary] = []
## Cooldown per peer pair to avoid spam
var _cross_combo_cooldowns: Dictionary = {}  # "peerA_peerB" -> expire_time

const CROSS_COMBO_MULTIPLIER := 1.5
const CROSS_COMBO_COOLDOWN := 2.0
const CROSS_COMBO_RADIUS := 4.0

## Cross-combo element combinations and their effects
const CROSS_COMBOS: Dictionary = {
	"fire_ice": {"name": "Steam Cloud", "color": Color(0.8, 0.8, 0.8)},
	"ice_fire": {"name": "Steam Cloud", "color": Color(0.8, 0.8, 0.8)},
	"electric_poison": {"name": "Toxic Shock", "color": Color(0.3, 1.0, 0.3)},
	"poison_electric": {"name": "Toxic Shock", "color": Color(0.3, 1.0, 0.3)},
	"fire_dark": {"name": "Shadow Flame", "color": Color(0.6, 0.1, 0.8)},
	"dark_fire": {"name": "Shadow Flame", "color": Color(0.6, 0.1, 0.8)},
	"ice_electric": {"name": "Cryo Conductor", "color": Color(0.3, 0.7, 1.0)},
	"electric_ice": {"name": "Cryo Conductor", "color": Color(0.3, 0.7, 1.0)},
	"fire_electric": {"name": "Plasma Burst", "color": Color(1.0, 0.8, 0.2)},
	"electric_fire": {"name": "Plasma Burst", "color": Color(1.0, 0.8, 0.2)},
	"dark_ice": {"name": "Frozen Abyss", "color": Color(0.2, 0.1, 0.5)},
	"ice_dark": {"name": "Frozen Abyss", "color": Color(0.2, 0.1, 0.5)},
}

func register_elemental_zone(pos: Vector3, element: String, owner_peer: int, duration: float = 3.0) -> void:
	## Called by weapons that create persistent AoE areas.
	if element == "physical":
		return
	_elemental_zones.append({
		"position": pos,
		"element": element,
		"owner_peer": owner_peer,
		"expire_time": Time.get_ticks_msec() / 1000.0 + duration,
	})

func try_cross_combo(hit_pos: Vector3, hit_element: String, hitter_peer: int, base_damage: int) -> void:
	## Called when a projectile/attack deals damage. Checks if it overlaps
	## an allied elemental zone to trigger a cross-combo.
	if not MultiplayerManager.is_online:
		return
	if hit_element == "physical":
		return

	var now = Time.get_ticks_msec() / 1000.0
	# Clean expired zones
	_elemental_zones = _elemental_zones.filter(func(z): return z["expire_time"] > now)

	for zone in _elemental_zones:
		if zone["owner_peer"] == hitter_peer:
			continue  # Same player, not a cross-combo
		if hit_pos.distance_to(zone["position"]) > CROSS_COMBO_RADIUS:
			continue
		var combo_key = hit_element + "_" + zone["element"]
		if combo_key not in CROSS_COMBOS:
			continue
		# Check cooldown between this peer pair
		var cd_key = "%d_%d" % [mini(hitter_peer, zone["owner_peer"]), maxi(hitter_peer, zone["owner_peer"])]
		if cd_key in _cross_combo_cooldowns and _cross_combo_cooldowns[cd_key] > now:
			continue
		# Trigger cross-combo!
		_cross_combo_cooldowns[cd_key] = now + CROSS_COMBO_COOLDOWN
		var combo = CROSS_COMBOS[combo_key]
		_execute_cross_combo(hit_pos, combo, base_damage)
		break

func _execute_cross_combo(pos: Vector3, combo: Dictionary, base_damage: int) -> void:
	var combo_damage = int(base_damage * CROSS_COMBO_MULTIPLIER)
	var combo_color: Color = combo.get("color", Color.WHITE)

	# AoE damage to enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) < 3.5:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", combo_damage, "fire")

	# Visual effects
	ParticleFactory.spawn_explosion_particles(pos, 3.0)
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.5, 0), combo_color, 15)
	ScreenEffects.shake(0.1)

	# Floating label "CROSS-COMBO!"
	var label = Label3D.new()
	label.text = "CROSS-COMBO!"
	label.font_size = 48
	label.outline_size = 8
	label.modulate = combo_color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.global_position = pos + Vector3(0, 2.0, 0)
	get_tree().current_scene.call_deferred("add_child", label)
	# Fade out and remove
	var tween = get_tree().create_tween()
	tween.tween_property(label, "global_position", pos + Vector3(0, 3.5, 0), 1.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(label.queue_free)
