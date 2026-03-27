extends Node3D

## Tombstone left when a player dies in multiplayer.
## Allies can stand nearby for 5 seconds to revive the dead player.
## The reviver gets a temporary debuff (-30% max HP for 30s).

signal player_revived(peer_id: int)

var dead_peer_id: int = 0
var despawn_timer: float = 60.0
var revive_progress: float = 0.0
var allies_in_range: Array[Node3D] = []
var is_reviving: bool = false
var _revived: bool = false

const REVIVE_TIME := 5.0
const REVIVE_HP_PERCENT := 0.5
const INVULN_DURATION := 2.0
const DEBUFF_HP_REDUCTION := 0.30
const DEBUFF_DURATION := 30.0
const INTERACT_RADIUS := 2.5

@onready var area: Area3D = $ReviveArea
@onready var progress_bar: MeshInstance3D = $ProgressBar
@onready var particles: GPUParticles3D = $SoulParticles

func _ready() -> void:
	_build_visual()
	_build_revive_area()
	_build_progress_bar()
	_build_soul_particles()

func _build_visual() -> void:
	# Tombstone mesh
	var stone = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.6, 1.0, 0.15)
	stone.mesh = mesh
	stone.position = Vector3(0, 0.5, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.35, 0.4)
	mat.roughness = 0.9
	stone.material_override = mat
	add_child(stone)

	# Cross on top
	var cross_v = MeshInstance3D.new()
	var cv_mesh = BoxMesh.new()
	cv_mesh.size = Vector3(0.08, 0.35, 0.08)
	cross_v.mesh = cv_mesh
	cross_v.position = Vector3(0, 1.15, 0)
	var cross_mat = StandardMaterial3D.new()
	cross_mat.albedo_color = Color(0.5, 0.5, 0.55)
	cross_v.material_override = cross_mat
	add_child(cross_v)

	var cross_h = MeshInstance3D.new()
	var ch_mesh = BoxMesh.new()
	ch_mesh.size = Vector3(0.25, 0.08, 0.08)
	cross_h.mesh = ch_mesh
	cross_h.position = Vector3(0, 1.22, 0)
	cross_h.material_override = cross_mat
	add_child(cross_h)

	# Ground circle indicator
	var circle = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = INTERACT_RADIUS
	disc.bottom_radius = INTERACT_RADIUS
	disc.height = 0.02
	circle.mesh = disc
	circle.position = Vector3(0, 0.01, 0)
	var circle_mat = StandardMaterial3D.new()
	circle_mat.albedo_color = Color(0.2, 0.6, 1.0, 0.2)
	circle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	circle_mat.emission_enabled = true
	circle_mat.emission = Color(0.2, 0.5, 1.0)
	circle_mat.emission_energy_multiplier = 0.5
	circle.material_override = circle_mat
	add_child(circle)

func _build_revive_area() -> void:
	var a = Area3D.new()
	a.name = "ReviveArea"
	a.collision_layer = 0
	a.collision_mask = 1  # Players
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = INTERACT_RADIUS
	col.shape = shape
	a.add_child(col)
	a.body_entered.connect(_on_ally_entered)
	a.body_exited.connect(_on_ally_exited)
	add_child(a)
	area = a

func _build_progress_bar() -> void:
	var bar = MeshInstance3D.new()
	bar.name = "ProgressBar"
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1.0, 0.08, 0.08)
	bar.mesh = mesh
	bar.position = Vector3(0, 1.6, 0)
	bar.visible = false
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.6, 1.0)
	mat.emission_energy_multiplier = 1.5
	bar.material_override = mat
	add_child(bar)
	progress_bar = bar

func _build_soul_particles() -> void:
	var p = GPUParticles3D.new()
	p.name = "SoulParticles"
	p.amount = 12
	p.lifetime = 2.0
	p.position = Vector3(0, 0.5, 0)
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.6
	mat.spread = 30.0
	mat.gravity = Vector3(0, 0.2, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.06
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.5
	var color_ramp = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_offset(0, 0.0)
	grad.set_color(0, Color(0.4, 0.7, 1.0, 0.8))
	grad.set_offset(1, 1.0)
	grad.set_color(1, Color(0.2, 0.4, 1.0, 0.0))
	color_ramp.gradient = grad
	mat.color_ramp = color_ramp
	p.process_material = mat
	var draw_mesh = SphereMesh.new()
	draw_mesh.radius = 0.03
	draw_mesh.height = 0.06
	var draw_mat = StandardMaterial3D.new()
	draw_mat.albedo_color = Color(0.5, 0.8, 1.0, 0.7)
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(0.3, 0.6, 1.0)
	draw_mat.emission_energy_multiplier = 2.0
	draw_mesh.material = draw_mat
	p.draw_pass_1 = draw_mesh
	add_child(p)
	particles = p

func _process(delta: float) -> void:
	if _revived or GameManager.paused:
		return

	# Despawn timer
	despawn_timer -= delta
	if despawn_timer <= 0:
		queue_free()
		return

	# Revive progress
	if allies_in_range.size() > 0:
		is_reviving = true
		revive_progress += delta
		# Update progress bar
		progress_bar.visible = true
		var pct = clampf(revive_progress / REVIVE_TIME, 0.0, 1.0)
		progress_bar.scale.x = pct
		progress_bar.position.x = (pct - 1.0) * 0.5
		if revive_progress >= REVIVE_TIME:
			_do_revive()
	else:
		is_reviving = false
		revive_progress = 0.0
		progress_bar.visible = false

func _on_ally_entered(body: Node3D) -> void:
	if body.is_in_group("players") and body not in allies_in_range:
		allies_in_range.append(body)

func _on_ally_exited(body: Node3D) -> void:
	allies_in_range.erase(body)

func _do_revive() -> void:
	if _revived:
		return
	_revived = true

	# Apply debuff to allies who helped
	for ally in allies_in_range:
		if is_instance_valid(ally):
			_apply_sacrifice_debuff()

	# Visual: revive explosion
	ParticleFactory.spawn_explosion_particles(global_position + Vector3(0, 0.5, 0), 2.0)
	ScreenEffects.shake(0.15)

	# Emit signal and notify multiplayer
	player_revived.emit(dead_peer_id)

	# Revive the player via GameManager
	if MultiplayerManager.is_host():
		_revive_on_host()

	# Remove tombstone
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(queue_free)

func _revive_on_host() -> void:
	# Restore player HP to 50%
	var max_hp = GameManager.get_effective_max_hp()
	GameManager.player_hp = int(max_hp * REVIVE_HP_PERCENT)
	GameManager.is_game_over = false

func _apply_sacrifice_debuff() -> void:
	## Reduce max HP by 30% for 30 seconds
	var original_mult = GameManager.max_hp_mult
	GameManager.max_hp_mult *= (1.0 - DEBUFF_HP_REDUCTION)
	# Cap current HP to new max
	var new_max = GameManager.get_effective_max_hp()
	GameManager.player_hp = mini(GameManager.player_hp, new_max)
	# Restore after duration
	get_tree().create_timer(DEBUFF_DURATION).timeout.connect(func():
		GameManager.max_hp_mult = original_mult
	)
	LogManager.info("Game", "Sacrifice debuff applied: -%.0f%% max HP for %.0fs" % [DEBUFF_HP_REDUCTION * 100, DEBUFF_DURATION])
