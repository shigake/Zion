extends Node3D

## Comportamento de uma bomba individual — espera o fuse_time e explode em area.

var damage: int = 20
var explosion_radius: float = 3.0
var fuse_time: float = 3.0
var timer: float = 0.0
var has_exploded: bool = false

var bomb_mesh: MeshInstance3D = null
var blink_timer: float = 0.0

func _ready() -> void:
	# Create bomb visual
	bomb_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.6
	bomb_mesh.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2, 1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.0, 1)
	mat.emission_energy_multiplier = 0.5
	bomb_mesh.surface_material_override.append(mat)
	bomb_mesh.position.y = 0.3
	add_child(bomb_mesh)

func _process(delta: float) -> void:
	if GameManager.paused:
		return

	timer += delta

	# Blink faster as fuse runs out
	if bomb_mesh:
		blink_timer += delta
		var blink_rate = lerp(0.5, 0.1, timer / fuse_time)
		if fmod(blink_timer, blink_rate) < blink_rate * 0.5:
			bomb_mesh.visible = true
		else:
			bomb_mesh.visible = false

	if timer >= fuse_time and not has_exploded:
		_explode()

func _explode() -> void:
	has_exploded = true

	# Visual feedback
	ParticleFactory.spawn_hit_particles(global_position, Color(1.0, 0.4, 0.0))
	ScreenEffects.shake(0.3)
	AudioManager.play_sfx("hit")

	# Damage all enemies in radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= explosion_radius:
			if enemy.has_method("take_damage"):
				# Damage falloff based on distance
				var falloff = 1.0 - (dist / explosion_radius) * 0.5
				var final_damage = int(damage * falloff)
				enemy.call_deferred("take_damage", final_damage, "fire")

	queue_free()
