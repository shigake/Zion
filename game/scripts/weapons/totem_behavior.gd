extends Node

## Comportamento do totem: causa dano periodico em area e se destroi apos lifetime.

var life_timer: float = 0.0
var damage_timer: float = 0.0
var damage_interval: float = 1.0
var anim_time: float = 0.0
var arc_timer: float = 0.0
var arc_interval: float = 1.5

func _ready() -> void:
	life_timer = get_meta("lifetime")
	arc_timer = randf_range(0.5, 1.5)
	# Register as elemental zone for cross-combo
	var area: Area3D = get_meta("area")
	if is_instance_valid(area):
		var owner_peer = MultiplayerManager.local_player_id if MultiplayerManager.is_online else 1
		SynergySystem.register_elemental_zone(area.global_position, "electric", owner_peer, life_timer)

func _process(delta: float) -> void:
	if GameManager.paused:
		return

	life_timer -= delta
	if life_timer <= 0:
		get_parent().queue_free()
		return

	anim_time += delta

	# Animate aura ring: pulse scale and alpha
	var aura_ring = get_meta("aura_ring") if has_meta("aura_ring") else null
	if aura_ring and is_instance_valid(aura_ring):
		var aura_pulse = 1.0 + sin(anim_time * 2.5) * 0.05
		aura_ring.scale = Vector3(aura_pulse, 1.0, aura_pulse)
		var mat = aura_ring.material_override
		if mat:
			var alpha = 0.3 + sin(anim_time * 3.0) * 0.1
			mat.albedo_color.a = alpha

	# Animate energy orb: pulsing glow
	var energy_orb = get_meta("energy_orb") if has_meta("energy_orb") else null
	if energy_orb and is_instance_valid(energy_orb):
		var orb_mat = energy_orb.material_override
		if orb_mat:
			orb_mat.emission_energy_multiplier = 2.0 + sin(anim_time * 4.0) * 1.0

	# Intermittent electric arc particles
	arc_timer -= delta
	if arc_timer <= 0:
		arc_timer = randf_range(1.0, 2.0)
		var arc_particles = get_meta("arc_particles") if has_meta("arc_particles") else null
		if arc_particles and is_instance_valid(arc_particles):
			arc_particles.emitting = true

	damage_timer -= delta
	if damage_timer <= 0:
		damage_timer = damage_interval
		_deal_damage()

func _deal_damage() -> void:
	var area: Area3D = get_meta("area")
	if not is_instance_valid(area):
		return
	var dmg: int = get_meta("damage")
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.call_deferred("take_damage", dmg, "electric")
	ParticleFactory.spawn_hit_particles(get_parent().global_position + Vector3(0, 0.5, 0), Color(0.3, 0.7, 1.0))
