extends Area3D

## Cristal (moeda) que dropa dos inimigos. Coletado pelo jogador.

@export var crystal_value: int = 1
@export var attract_speed: float = 12.0
@export var base_attract_range: float = 3.0

var being_attracted: bool = false
var attract_target: Node3D = null

@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	add_to_group("crystals")
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	# Apply glow shader to crystal mesh
	if mesh:
		mesh.material_override = VisualSetup.create_glow_material(Color(1.0, 0.85, 0.2), 2.5)
	# Sparkle particles
	var sparkle = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 0.8
	mat.gravity = Vector3(0, 0.5, 0)
	mat.scale_min = 0.02
	mat.scale_max = 0.05
	mat.color = Color(1.0, 0.9, 0.3)
	sparkle.process_material = mat
	sparkle.amount = 3
	sparkle.lifetime = 1.0
	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.03
	draw_pass.height = 0.06
	var draw_mat = StandardMaterial3D.new()
	draw_mat.albedo_color = Color(1.0, 0.9, 0.3)
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(1.0, 0.85, 0.2)
	draw_mat.emission_energy_multiplier = 3.0
	draw_pass.surface_set_material(0, draw_mat)
	sparkle.draw_pass_1 = draw_pass
	add_child(sparkle)

func _physics_process(delta: float) -> void:
	if GameManager.paused:
		return

	# Bobbing e rotacao
	var bob = sin(GameManager.game_time * 3.0 + global_position.z) * 0.08
	position.y = 0.4 + bob
	if mesh:
		mesh.rotation.y += delta * 3.0

	if not being_attracted:
		var players = get_tree().get_nodes_in_group("players")
		for p in players:
			var range_val = base_attract_range * GameManager.magnet_mult
			if is_instance_valid(p) and global_position.distance_to(p.global_position) < range_val:
				being_attracted = true
				attract_target = p
				break

	if being_attracted and attract_target and is_instance_valid(attract_target):
		var dir = (attract_target.global_position - global_position).normalized()
		global_position += dir * attract_speed * delta
		if global_position.distance_to(attract_target.global_position) < 0.5:
			_collect()

var _collected := false

func _collect() -> void:
	if _collected or not is_inside_tree():
		return
	_collected = true
	AudioManager.play_sfx("collect_crystal")
	ParticleFactory.spawn_collect_particles(global_position, Color(0.7, 0.3, 0.9))
	GameManager.crystals_this_run += crystal_value
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		_collect()
