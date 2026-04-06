extends Node3D

## Lanca — thrust linear que perfura multiplos inimigos em linha.

var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.25

@onready var thrust_area: Area3D = $ThrustArea
@onready var thrust_mesh: MeshInstance3D = $ThrustMesh

var _trail: Node3D = null
var _slash_tex: Texture2D = null
var _lance_model: Node3D = null

func _ready() -> void:
	thrust_mesh.visible = false
	thrust_area.body_entered.connect(_on_body_entered)
	# Load slash trail sprite
	var _slash_path2 = "res://assets/sprites/effects/slashes/lance_thrust.png"
	if ResourceLoader.exists(_slash_path2):
		_slash_tex = load(_slash_path2)
	# Weapon trail
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(1.0, 0.9, 0.35, 0.95)
	_trail.max_points = 20
	_trail.trail_width = 0.35
	thrust_mesh.add_child(_trail)
	# Build 3D procedural lance model (no Sprite3D)
	_setup_lance_mesh()

func _setup_lance_mesh() -> void:
	_lance_model = Node3D.new()
	_lance_model.name = "LanceModel"
	_lance_model.visible = false

	# Gold metallic material (blade + cross-guard)
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.85, 0.75, 0.2)
	gold_mat.metallic = 0.9
	gold_mat.roughness = 0.15
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(1.0, 0.9, 0.35)
	gold_mat.emission_energy_multiplier = 0.8

	# Dark wood material (shaft)
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.3, 0.18, 0.08)
	wood_mat.roughness = 0.9
	wood_mat.metallic = 0.0

	# --- Shaft (long wood pole) ---
	var shaft_mi = MeshInstance3D.new()
	var shaft_mesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.025
	shaft_mesh.bottom_radius = 0.025
	shaft_mesh.height = 1.6
	shaft_mesh.radial_segments = 6
	shaft_mi.mesh = shaft_mesh
	shaft_mi.material_override = wood_mat
	shaft_mi.rotation.x = PI / 2.0  # Align along Z axis
	shaft_mi.position = Vector3(0, 0, -0.5)
	_lance_model.add_child(shaft_mi)

	# --- Blade (pointed cone tip) ---
	var blade_mi = MeshInstance3D.new()
	var blade_mesh = CylinderMesh.new()
	blade_mesh.top_radius = 0.0
	blade_mesh.bottom_radius = 0.07
	blade_mesh.height = 0.45
	blade_mesh.radial_segments = 6
	blade_mi.mesh = blade_mesh
	blade_mi.material_override = gold_mat
	blade_mi.rotation.x = -PI / 2.0  # Point forward (negative Z)
	blade_mi.position = Vector3(0, 0, -1.45)
	_lance_model.add_child(blade_mi)

	# --- Cross-guard ---
	var guard_mi = MeshInstance3D.new()
	var guard_mesh = BoxMesh.new()
	guard_mesh.size = Vector3(0.35, 0.04, 0.04)
	guard_mi.mesh = guard_mesh
	guard_mi.material_override = gold_mat
	guard_mi.position = Vector3(0, 0, -0.15)
	_lance_model.add_child(guard_mi)

	thrust_area.add_child(_lance_model)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("lance")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("lance", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	if is_attacking:
		attack_anim_timer -= delta
		# Thrust forward animation — extends outward
		var progress = 1.0 - (attack_anim_timer / attack_duration)
		var thrust_offset = lerp(0.0, -2.0, progress)
		thrust_area.position.z = thrust_offset
		thrust_mesh.position.z = thrust_offset

		if attack_anim_timer <= 0:
			is_attacking = false
			thrust_mesh.visible = false
			thrust_area.monitoring = false
			if _lance_model:
				_lance_model.visible = false
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			_attack(level)
			attack_timer = cooldown

func _attack(level: int) -> void:
	if not is_inside_tree():
		return
	is_attacking = true
	attack_anim_timer = attack_duration
	# Show 3D lance model; thrust_mesh is fallback only if model fails
	if _lance_model:
		_lance_model.visible = true
		thrust_mesh.visible = false
	else:
		thrust_mesh.visible = true
	thrust_area.monitoring = true

	# Auto-aim toward nearest enemy (instinto dimensional)
	var player = get_parent().get_parent() if get_parent() else null
	if player and is_instance_valid(player):
		var aimed = false
		if GameManager.manual_aim and GameManager.aim_direction.length_squared() > 0.01:
			var aim_angle = atan2(-GameManager.aim_direction.x, -GameManager.aim_direction.z)
			global_rotation.y = aim_angle
			aimed = true
		else:
			var enemies = GameManager.get_enemies()
			if not enemies.is_empty():
				var nearest: Node3D = null
				var min_dist = INF
				for e in enemies:
					if not is_instance_valid(e):
						continue
					var d = player.global_position.distance_squared_to(e.global_position)
					if d < min_dist:
						min_dist = d
						nearest = e
				if nearest:
					var dir = nearest.global_position - player.global_position
					dir.y = 0.0
					if dir.length_squared() > 0.01:
						dir = dir.normalized()
						global_rotation.y = atan2(-dir.x, -dir.z)
						aimed = true
		# Fallback: aim in player's movement direction
		if not aimed and player is CharacterBody3D:
			var vel = player.velocity
			vel.y = 0.0
			if vel.length_squared() > 0.1:
				global_rotation.y = atan2(-vel.x, -vel.z)

	# Scale with level — longer reach
	var area_scale = (1.0 + (level - 1) * 0.15) * GameManager.attack_size_mult * GameManager.area_mult
	thrust_area.scale = Vector3(1.0, 1.0, area_scale)
	thrust_mesh.scale = Vector3(1.0, 1.0, area_scale)

	# Reset position
	thrust_area.position.z = 0.0
	thrust_mesh.position.z = 0.0

	AudioManager.play_sfx("lance_thrust")

	# Slash trail visual
	_spawn_slash_trail()

func _spawn_slash_trail() -> void:
	WeaponVFX.spawn_slash_trail(self, _slash_tex, global_position + Vector3(0, 0.5, 0), 0.050, 2.8, 0.28, Vector3(1.0, 1.0, 1.0))

func _on_body_entered(body: Node3D) -> void:
	# Pierces all enemies in the line — no hit limit
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("lance")
		var dmg = int(WeaponDB.get_damage("lance", level))
		GameManager._last_attacking_weapon = "lance"
		body.call_deferred("take_damage", dmg, "physical")
		# Golden thrust sparks (7 particles)
		ParticleFactory.spawn_weapon_sparks(body.global_position + Vector3(0, 0.5, 0), Color(1.0, 0.9, 0.35), 7)
		ScreenEffects.shake(0.05)
