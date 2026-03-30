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
	# Water synergies
	if "water" in element_count and "fire" in element_count:
		active_synergies.append("water_fire")
	if "water" in element_count and "electric" in element_count:
		active_synergies.append("water_electric")
	if "water" in element_count and "ice" in element_count:
		active_synergies.append("water_ice")
	if "water" in element_count and "dark" in element_count:
		active_synergies.append("water_dark")
	# New synergies
	if "fire" in element_count and "poison" in element_count:
		active_synergies.append("fire_poison")
	if "ice" in element_count and "dark" in element_count:
		active_synergies.append("ice_dark")
	if "electric" in element_count and "poison" in element_count:
		active_synergies.append("electric_poison")

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
		"water_water":
			return "Agua + Agua: Onda de mare empurra inimigos a cada 4s"
		"fire_ice":
			return "Fogo + Gelo: Steam cloud (dano + slow)"
		"electric_ice":
			return "Eletrico + Gelo: Condutor (dano em area massivo)"
		"water_fire", "fire_water":
			return "Agua + Fogo: Explosao de vapor (12 de dano em area)"
		"water_electric", "electric_water":
			return "Agua + Eletrico: Eletrolise (inimigos em zona de agua tomam 2x dano eletrico)"
		"water_ice", "ice_water":
			return "Agua + Gelo: Zero absoluto (congela inimigos por 2s em raio de 4)"
		"water_dark", "dark_water":
			return "Agua + Dark: Profundezas abissais (inimigos 40% mais lentos)"
		"fire_poison", "poison_fire":
			return "Fogo + Veneno: Toxic fire (DoT de fogo dobrado)"
		"ice_dark", "dark_ice":
			return "Gelo + Dark: Shadow freeze (congela + drena vida para o jogador)"
		"electric_poison", "poison_electric":
			return "Eletrico + Veneno: Toxic shock (stun 0.5s + DoT de veneno)"
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

# Synergy intervals and damage constants
const SYNERGY_INTERVALS := {
	"dark_aura": 1.0, "steam_cloud": 1.5, "conductor": 3.0,
	"tidal_wave": 4.0, "steam_explosion": 1.5, "absolute_zero": 5.0,
	"abyssal_depths": 0.5, "toxic_fire": 1.0, "shadow_freeze": 2.0,
	"toxic_shock": 1.5,
}
const SYNERGY_DAMAGE := {
	"dark_aura": 5, "steam_cloud": 8, "conductor": 25,
	"tidal_wave": 5, "steam_explosion": 12, "absolute_zero": 8,
	"toxic_fire": 8, "shadow_freeze": 10, "toxic_shock": 6,
}
const SYNERGY_RADIUS := {
	"dark_aura": 4.0, "steam_cloud": 3.5, "conductor": 6.0,
	"tidal_wave": 5.0, "steam_explosion": 3.5, "absolute_zero": 4.0,
	"abyssal_depths": 6.0, "toxic_fire": 4.0, "shadow_freeze": 4.0,
	"toxic_shock": 4.0,
}

var _synergy_timers: Dictionary = {}  # synergy_id -> float
var _electrolysis_active: bool = false

func apply_passive_synergies(player_pos: Vector3, _delta: float) -> void:
	if has_synergy("dark_dark"):
		_dark_aura_tick(player_pos)
	if has_synergy("fire_ice"):
		_steam_cloud_tick(player_pos)
	if has_synergy("electric_ice"):
		_conductor_tick(player_pos)
	if has_synergy("water_water"):
		_tidal_wave_tick(player_pos)
	if has_synergy("water_fire"):
		_steam_explosion_tick(player_pos)
	_electrolysis_active = has_synergy("water_electric")
	if has_synergy("water_ice"):
		_absolute_zero_tick(player_pos)
	if has_synergy("water_dark"):
		_abyssal_depths_tick(player_pos)
	if has_synergy("fire_poison"):
		_toxic_fire_tick(player_pos)
	if has_synergy("ice_dark"):
		_shadow_freeze_tick(player_pos)
	if has_synergy("electric_poison"):
		_toxic_shock_tick(player_pos)

## Returns true when interval elapsed, resets timer. Used by all tick functions.
func _tick_synergy(synergy_id: String) -> bool:
	_synergy_timers[synergy_id] = _synergy_timers.get(synergy_id, 0.0) + get_process_delta_time()
	if _synergy_timers[synergy_id] < SYNERGY_INTERVALS[synergy_id]:
		return false
	_synergy_timers[synergy_id] = 0.0
	return true

## Applies temporary speed debuff to an enemy, restoring after duration.
func _apply_speed_debuff(enemy: Node3D, multiplier: float, duration: float) -> void:
	if not enemy is EnemyBase3D:
		return
	var original_speed = enemy.speed
	enemy.speed *= multiplier
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(enemy):
			enemy.speed = original_speed
	)

## Freezes enemy (speed = 0) for duration, then restores.
func _freeze_enemy(enemy: Node3D, duration: float) -> void:
	if not enemy is EnemyBase3D:
		return
	var original_speed = enemy.speed
	enemy.speed = 0.0
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(enemy):
			enemy.speed = original_speed
	)

# ---- Fire + Fire: Explosion on kill ----

func _fire_explosion(pos: Vector3) -> void:
	ParticleFactory.spawn_explosion_particles(pos, 2.0)
	ScreenEffects.shake(0.08)
	var enemies = GameManager.get_enemies()
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) < 2.5:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", 20, "fire")

# ---- Ice + Ice: Shatter frozen enemies ----

func _ice_shatter(pos: Vector3) -> void:
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.5, 0), Color(0.4, 0.85, 1.0), 10)
	ScreenEffects.shake(0.06)
	var enemies = GameManager.get_enemies()
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
	var enemies = GameManager.get_enemies()
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
	if not _tick_synergy("dark_aura"):
		return
	var radius = SYNERGY_RADIUS["dark_aura"]
	var dmg = SYNERGY_DAMAGE["dark_aura"]
	for e in GameManager.get_enemies():
		if is_instance_valid(e) and pos.distance_to(e.global_position) < radius:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", dmg, "dark")

# ---- Fire + Ice: Steam Cloud (slow + damage) ----

func _steam_cloud_tick(pos: Vector3) -> void:
	if not _tick_synergy("steam_cloud"):
		return
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.3, 0), Color(0.8, 0.8, 0.8, 0.6), 8)
	var radius = SYNERGY_RADIUS["steam_cloud"]
	var dmg = SYNERGY_DAMAGE["steam_cloud"]
	for e in GameManager.get_enemies():
		if is_instance_valid(e) and pos.distance_to(e.global_position) < radius:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", dmg, "fire")
			_apply_speed_debuff(e, 0.6, 1.5)

# ---- Electric + Ice: Conductor (massive AoE) ----

func _conductor_tick(pos: Vector3) -> void:
	if not _tick_synergy("conductor"):
		return
	ParticleFactory.spawn_explosion_particles(pos, 5.0)
	ScreenEffects.shake(0.12)
	var radius = SYNERGY_RADIUS["conductor"]
	var dmg = SYNERGY_DAMAGE["conductor"]
	for e in GameManager.get_enemies():
		if is_instance_valid(e) and pos.distance_to(e.global_position) < radius:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", dmg, "electric")

# ---- Water + Water: Tidal Wave (knockback every 4s) ----

func _tidal_wave_tick(pos: Vector3) -> void:
	if not _tick_synergy("tidal_wave"):
		return
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.3, 0), Color(0.2, 0.5, 1.0, 0.8), 12)
	ScreenEffects.shake(0.06)
	var radius = SYNERGY_RADIUS["tidal_wave"]
	var dmg = SYNERGY_DAMAGE["tidal_wave"]
	for e in GameManager.get_enemies():
		if is_instance_valid(e) and pos.distance_to(e.global_position) < radius:
			var push_dir = (e.global_position - pos).normalized()
			if push_dir.length() < 0.01:
				push_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
			push_dir.y = 0.0
			e.global_position += push_dir * 3.0
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", dmg, "water")

# ---- Water + Fire: Steam Explosion (12 damage AoE, like fire_ice but stronger) ----

func _steam_explosion_tick(pos: Vector3) -> void:
	if not _tick_synergy("steam_explosion"):
		return
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.3, 0), Color(1.0, 0.9, 0.8, 0.7), 10)
	ParticleFactory.spawn_explosion_particles(pos, 2.0)
	ScreenEffects.shake(0.08)
	var radius = SYNERGY_RADIUS["steam_explosion"]
	var dmg = SYNERGY_DAMAGE["steam_explosion"]
	for e in GameManager.get_enemies():
		if is_instance_valid(e) and pos.distance_to(e.global_position) < radius:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", dmg, "fire")
			_apply_speed_debuff(e, 0.5, 1.5)

# ---- Water + Electric: Electrolysis (2x electric damage in water zones) ----
# This synergy is passive — it modifies electric damage via get_electrolysis_multiplier()

func get_electrolysis_multiplier() -> float:
	## Call this from damage calculations when dealing electric damage.
	## Returns 2.0 if water+electric synergy is active, 1.0 otherwise.
	if _electrolysis_active:
		return 2.0
	return 1.0

# ---- Water + Ice: Absolute Zero (freeze enemies solid for 2s every 5s) ----

func _absolute_zero_tick(pos: Vector3) -> void:
	if not _tick_synergy("absolute_zero"):
		return
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.5, 0), Color(0.3, 0.7, 1.0), 15)
	ParticleFactory.spawn_explosion_particles(pos, 3.0)
	ScreenEffects.shake(0.1)
	var radius = SYNERGY_RADIUS["absolute_zero"]
	var dmg = SYNERGY_DAMAGE["absolute_zero"]
	for e in GameManager.get_enemies():
		if is_instance_valid(e) and pos.distance_to(e.global_position) < radius:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", dmg, "ice")
			_freeze_enemy(e, 2.0)

# ---- Water + Dark: Abyssal Depths (40% slow aura, refreshed continuously) ----

var _abyssal_slowed_enemies: Dictionary = {}  # enemy instance_id -> true

func _abyssal_depths_tick(pos: Vector3) -> void:
	if not _tick_synergy("abyssal_depths"):
		return
	var radius = SYNERGY_RADIUS["abyssal_depths"]
	for e in GameManager.get_enemies():
		if not is_instance_valid(e):
			continue
		var in_range = pos.distance_to(e.global_position) < radius
		var eid = e.get_instance_id()
		if in_range and e is EnemyBase3D and eid not in _abyssal_slowed_enemies:
			_abyssal_slowed_enemies[eid] = e.speed
			e.speed *= 0.6
		elif not in_range and eid in _abyssal_slowed_enemies:
			if is_instance_valid(e):
				e.speed = _abyssal_slowed_enemies[eid]
			_abyssal_slowed_enemies.erase(eid)
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.1, 0), Color(0.1, 0.15, 0.3, 0.4), 3)

# ---- Fire + Poison: Toxic Fire (double fire DoT) ----

func _toxic_fire_tick(pos: Vector3) -> void:
	if not _tick_synergy("toxic_fire"):
		return
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.3, 0), Color(0.8, 0.5, 0.1, 0.7), 6)
	var radius = SYNERGY_RADIUS["toxic_fire"]
	var dmg = SYNERGY_DAMAGE["toxic_fire"]
	for e in GameManager.get_enemies():
		if is_instance_valid(e) and pos.distance_to(e.global_position) < radius:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", dmg, "fire")
				e.call_deferred("take_damage", dmg, "fire")

# ---- Ice + Dark: Shadow Freeze (freeze + life drain to player) ----

func _shadow_freeze_tick(pos: Vector3) -> void:
	if not _tick_synergy("shadow_freeze"):
		return
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.5, 0), Color(0.3, 0.1, 0.5), 10)
	var radius = SYNERGY_RADIUS["shadow_freeze"]
	var dmg = SYNERGY_DAMAGE["shadow_freeze"]
	var total_damage_dealt: float = 0.0
	for e in GameManager.get_enemies():
		if is_instance_valid(e) and pos.distance_to(e.global_position) < radius:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", dmg, "ice")
				total_damage_dealt += dmg
			_freeze_enemy(e, 1.5)
	if total_damage_dealt > 0.0:
		var heal_amount = total_damage_dealt * 0.02
		if heal_amount < 1.0:
			heal_amount = 1.0
		GameManager.heal(int(heal_amount))

# ---- Electric + Poison: Toxic Shock (stun 0.5s + poison DoT) ----

func _toxic_shock_tick(pos: Vector3) -> void:
	if not _tick_synergy("toxic_shock"):
		return
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.3, 0), Color(0.3, 1.0, 0.3, 0.8), 8)
	var radius = SYNERGY_RADIUS["toxic_shock"]
	var dmg = SYNERGY_DAMAGE["toxic_shock"]
	for e in GameManager.get_enemies():
		if is_instance_valid(e) and pos.distance_to(e.global_position) < radius:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", dmg, "poison")
			_freeze_enemy(e, 0.5)

func reset() -> void:
	active_synergies.clear()
	_synergy_timers.clear()
	_electrolysis_active = false
	# Restore speeds of abyssal-slowed enemies
	for eid in _abyssal_slowed_enemies:
		var e = instance_from_id(eid)
		if is_instance_valid(e):
			e.speed = _abyssal_slowed_enemies[eid]
	_abyssal_slowed_enemies.clear()
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
	"dark_ice": {"name": "Shadow Freeze", "color": Color(0.3, 0.1, 0.5)},
	"ice_dark": {"name": "Shadow Freeze", "color": Color(0.3, 0.1, 0.5)},
	# Water cross-combos
	"water_fire": {"name": "Steam Explosion", "color": Color(1.0, 0.9, 0.8)},
	"fire_water": {"name": "Steam Explosion", "color": Color(1.0, 0.9, 0.8)},
	"water_electric": {"name": "Electrolysis", "color": Color(0.3, 0.6, 1.0)},
	"electric_water": {"name": "Electrolysis", "color": Color(0.3, 0.6, 1.0)},
	"water_ice": {"name": "Absolute Zero", "color": Color(0.6, 0.9, 1.0)},
	"ice_water": {"name": "Absolute Zero", "color": Color(0.6, 0.9, 1.0)},
	"water_dark": {"name": "Abyssal Depths", "color": Color(0.1, 0.15, 0.4)},
	"dark_water": {"name": "Abyssal Depths", "color": Color(0.1, 0.15, 0.4)},
	# New cross-combos
	"fire_poison": {"name": "Toxic Fire", "color": Color(0.8, 0.5, 0.1)},
	"poison_fire": {"name": "Toxic Fire", "color": Color(0.8, 0.5, 0.1)},
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
	var enemies = GameManager.get_enemies()
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
