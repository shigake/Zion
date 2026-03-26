extends Node3D

## Totem — planta uma torreta estacionaria que causa dano em area.

var place_timer: float = 0.0
var active_totems: Array = []

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("totem")
	if level <= 0:
		return

	# Clean up destroyed totems
	active_totems = active_totems.filter(func(t): return is_instance_valid(t))

	var max_totems = 1
	if level >= 5:
		max_totems = 2

	var cooldown = WeaponDB.get_cooldown("totem", level) * GameManager.cooldown_mult
	place_timer -= delta
	if place_timer <= 0 and active_totems.size() < max_totems:
		place_timer = cooldown
		_place_totem(level)

func _place_totem(level: int) -> void:
	var player_pos = get_parent().get_parent().global_position

	var totem = Node3D.new()
	totem.name = "Totem"
	totem.global_position = player_pos

	# Visual mesh - pillar
	var mesh_inst = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.2
	cylinder.bottom_radius = 0.35
	cylinder.height = 1.2
	mesh_inst.mesh = cylinder
	mesh_inst.position = Vector3(0, 0.6, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.4, 0.9, 1.0)
	mat.emission_energy_multiplier = 0.6
	mesh_inst.material_override = mat
	totem.add_child(mesh_inst)

	# Damage area
	var area = Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 2
	area.monitoring = true
	var shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 4.0 + (level - 1) * 0.5
	shape.shape = sphere
	area.add_child(shape)
	totem.add_child(area)

	# Attach damage script behavior via timer
	var damage = int(WeaponDB.get_damage("totem", level))
	var lifetime = 15.0 + level * 2.0

	var script_node = Node.new()
	script_node.set_script(_TotemBehavior)
	script_node.set_meta("damage", damage)
	script_node.set_meta("lifetime", lifetime)
	script_node.set_meta("area", area)
	totem.add_child(script_node)

	active_totems.append(totem)
	get_tree().current_scene.call_deferred("add_child", totem)

	AudioManager.play_sfx("hit")
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.2, 0.6, 1.0))

# Inner class for totem behavior
var _TotemBehavior: GDScript = preload("res://scripts/weapons/totem_behavior.gd")
