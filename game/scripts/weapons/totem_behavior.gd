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

	# Animate zap sprites: orbit around totem + pulse
	var parent = get_parent()
	if parent:
		for i in range(3):
			var zap = parent.get_node_or_null("ZapSprite_%d" % i)
			if zap and is_instance_valid(zap):
				var angle = anim_time * 2.0 + i * TAU / 3.0
				var area_node: Area3D = get_meta("area") if has_meta("area") else null
				var radius = 2.0
				if area_node and is_instance_valid(area_node):
					var shape = area_node.get_child(0) as CollisionShape3D
					if shape and shape.shape is SphereShape3D:
						radius = shape.shape.radius * 0.5
				zap.position = Vector3(cos(angle) * radius, 0.3 + sin(anim_time * 5.0 + i) * 0.2, sin(angle) * radius)
				zap.modulate.a = 0.4 + sin(anim_time * 6.0 + i * 2.0) * 0.3
		# Pulse totem sprite on damage tick
		var totem_sprite = parent.get_node_or_null("TotemSprite")
		if totem_sprite and is_instance_valid(totem_sprite):
			var pulse = 1.0 + sin(anim_time * 3.0) * 0.05
			totem_sprite.modulate = Color(0.8 + sin(anim_time * 4.0) * 0.2, 0.9, 1.2)

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
		# Flash the totem sprite bright on damage
		var totem_sprite = get_parent().get_node_or_null("TotemSprite")
		if totem_sprite and is_instance_valid(totem_sprite):
			totem_sprite.modulate = Color(3, 3, 5)
			var tw = create_tween()
			tw.tween_property(totem_sprite, "modulate", Color(0.8, 0.9, 1.2), 0.15)
