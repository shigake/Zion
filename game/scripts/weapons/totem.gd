extends Node3D

## Totem — planta uma torreta estacionaria que causa dano em area.

var place_timer: float = 0.0
var active_totems: Array = []

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
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

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _place_totem(level: int) -> void:
	if not is_inside_tree():
		return
	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	var totem = Node3D.new()
	totem.name = "Totem"
	totem.global_position = player_pos

	# Visual mesh - 3D model or fallback pillar
	var model = ModelFactory.get_weapon_model("totem")
	if model:
		model.position = Vector3(0, 0, 0)
		totem.add_child(model)
	else:
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
	var area_radius = 4.0 + (level - 1) * 0.5
	sphere.radius = area_radius
	shape.shape = sphere
	area.add_child(shape)
	totem.add_child(area)

	# -- Aura ring at ground level --
	var aura_ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = area_radius
	torus.rings = 32
	torus.ring_segments = 24
	aura_ring.mesh = torus
	aura_ring.position = Vector3(0, 0.05, 0)
	var aura_mat = StandardMaterial3D.new()
	aura_mat.albedo_color = Color(0.2, 0.6, 1.0, 0.3)
	aura_mat.emission_enabled = true
	aura_mat.emission = Color(0.2, 0.6, 1.0)
	aura_mat.emission_energy_multiplier = 1.0
	aura_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aura_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aura_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	aura_ring.material_override = aura_mat
	totem.add_child(aura_ring)

	# -- Energy orb on top of totem --
	var energy_orb = MeshInstance3D.new()
	var orb_sphere = SphereMesh.new()
	orb_sphere.radius = 0.15
	orb_sphere.height = 0.3
	energy_orb.mesh = orb_sphere
	energy_orb.position = Vector3(0, 1.4, 0)
	var orb_mat = StandardMaterial3D.new()
	orb_mat.albedo_color = Color(0.3, 0.8, 1.0, 0.9)
	orb_mat.emission_enabled = true
	orb_mat.emission = Color(0.3, 0.8, 1.0)
	orb_mat.emission_energy_multiplier = 2.0
	orb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	orb_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	energy_orb.material_override = orb_mat
	totem.add_child(energy_orb)

	# -- Small electric arc particles (intermittent) --
	var arc_particles = GPUParticles3D.new()
	arc_particles.amount = 4
	arc_particles.lifetime = 0.3
	arc_particles.emitting = false
	arc_particles.position = Vector3(0, 0.5, 0)

	var arc_mat = ParticleProcessMaterial.new()
	arc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	arc_mat.emission_sphere_radius = area_radius * 0.8
	arc_mat.direction = Vector3(0, 1, 0)
	arc_mat.spread = 90.0
	arc_mat.initial_velocity_min = 0.5
	arc_mat.initial_velocity_max = 1.5
	arc_mat.gravity = Vector3(0, -2, 0)
	arc_mat.scale_min = 0.5
	arc_mat.scale_max = 1.5
	arc_mat.color = Color(0.5, 0.8, 1.0)
	arc_particles.process_material = arc_mat

	var arc_draw = SphereMesh.new()
	arc_draw.radius = 0.03
	arc_draw.height = 0.06
	var arc_draw_mat = StandardMaterial3D.new()
	arc_draw_mat.albedo_color = Color(0.6, 0.9, 1.0)
	arc_draw_mat.emission_enabled = true
	arc_draw_mat.emission = Color(0.5, 0.85, 1.0)
	arc_draw_mat.emission_energy_multiplier = 3.0
	arc_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc_draw.material = arc_draw_mat
	arc_particles.draw_pass_1 = arc_draw
	totem.add_child(arc_particles)

	# Attach damage script behavior via timer
	var damage = int(WeaponDB.get_damage("totem", level))
	var lifetime = 15.0 + level * 2.0

	var script_node = Node.new()
	script_node.set_script(_TotemBehavior)
	script_node.set_meta("damage", damage)
	script_node.set_meta("lifetime", lifetime)
	script_node.set_meta("area", area)
	script_node.set_meta("aura_ring", aura_ring)
	script_node.set_meta("energy_orb", energy_orb)
	script_node.set_meta("arc_particles", arc_particles)
	totem.add_child(script_node)

	active_totems.append(totem)
	get_tree().current_scene.call_deferred("add_child", totem)

	AudioManager.play_sfx("hit")
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.2, 0.6, 1.0))

# Inner class for totem behavior
var _TotemBehavior: GDScript = preload("res://scripts/weapons/totem_behavior.gd")
