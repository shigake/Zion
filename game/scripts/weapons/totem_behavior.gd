extends Node

## Comportamento do totem: causa dano periodico em area e se destroi apos lifetime.

var life_timer: float = 0.0
var damage_timer: float = 0.0
var damage_interval: float = 1.0
var anim_time: float = 0.0
var _arc_regen_counter: int = 0

func _ready() -> void:
	life_timer = get_meta("lifetime")
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

	var parent = get_parent()
	if not parent:
		return

	# Animate 3D electric arcs: orbit around totem
	for i in range(3):
		var arc = parent.get_node_or_null("ArcParent_%d" % i)
		if arc and is_instance_valid(arc):
			var area_node: Area3D = get_meta("area") if has_meta("area") else null
			var radius = 2.0
			if area_node and is_instance_valid(area_node):
				var shape = area_node.get_child(0) as CollisionShape3D
				if shape and shape.shape is SphereShape3D:
					radius = shape.shape.radius * 0.5
			var angle = anim_time * 2.0 + i * TAU / 3.0
			arc.position = Vector3(cos(angle) * radius, 0.3 + sin(anim_time * 5.0 + i) * 0.2, sin(angle) * radius)
			# Regenerate zigzag offsets every 3 frames for flickering electric effect
			_arc_regen_counter += 1
			if _arc_regen_counter % 3 == 0:
				for j in range(6):
					var seg = arc.get_node_or_null("ArcSeg_%d" % j)
					if seg and is_instance_valid(seg):
						seg.position.x = randf_range(-0.06, 0.06)
						seg.position.z = randf_range(-0.06, 0.06)
						seg.rotation.z = randf_range(-0.5, 0.5)

	# Pulse totem orb
	var orb = parent.get_node_or_null("TotemOrb")
	if orb and is_instance_valid(orb):
		var pulse = 1.0 + sin(anim_time * PI * 2.5) * 0.12
		orb.scale = Vector3(pulse, pulse, pulse)

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
	var hit_count := 0
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			GameManager._last_attacking_weapon = "totem"
			body.call_deferred("take_damage", dmg, "electric")
			hit_count += 1
	# Visual feedback: electric flash + particles when hitting enemies
	if hit_count > 0:
		ParticleFactory.spawn_hit_particles(get_parent().global_position + Vector3(0, 0.5, 0), Color(0.3, 0.7, 1.0))
		AudioManager.play_sfx("electric_zap")
		# Flash the orb bright on damage
		var orb = get_parent().get_node_or_null("TotemOrb")
		if orb and is_instance_valid(orb):
			var mat = orb.material_override as StandardMaterial3D
			if mat:
				var orig_emission = mat.emission_energy_multiplier
				mat.emission_energy_multiplier = 6.0
				var tw = create_tween()
				tw.tween_property(mat, "emission_energy_multiplier", orig_emission, 0.15)
