extends EnemyBase3D

## Fada dos Dentes: aparece raramente carregando uma sacola de ouro.
## Vai na direcao do jogador e recua, vai e recua. Nao ataca.
## Ao morrer, dropa muitos cristais.

@export var approach_speed: float = 5.0
@export var retreat_speed: float = 7.0
@export var approach_distance: float = 3.0  ## Distancia minima antes de recuar
@export var retreat_distance: float = 8.0   ## Distancia maxima antes de voltar
@export var crystal_drop_count: int = 12    ## Quantidade de cristais ao morrer

enum FairyState { APPROACHING, RETREATING }
var _state: FairyState = FairyState.APPROACHING
var _bob_time: float = 0.0
var _wing_time: float = 0.0
var _glow_mesh: MeshInstance3D = null

func _ready() -> void:
	speed = approach_speed
	max_hp = 40
	hp = max_hp
	damage = 0  # Nao ataca!
	xp_drop = 5
	enemy_color = Color(0.95, 0.85, 0.3)  # Dourado brilhante
	resistances = {
		"physical": 1.0,
		"fire": 1.5,
		"ice": 1.0,
		"electric": 0.5,  # Resistente a eletrico (magica)
	}
	super._ready()
	_create_glow_effect()

func _create_glow_effect() -> void:
	# Aura brilhante em volta da fada
	_glow_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 1.2
	_glow_mesh.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.3, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.2)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	_glow_mesh.material_override = mat
	_glow_mesh.position = Vector3(0, 0.5, 0)
	add_child(_glow_mesh)

func _physics_process(delta: float) -> void:
	if is_dead or GameManager.paused:
		return

	# Knockback decay (copiado do base)
	if knockback_velocity.length() > 0.1:
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, 8.0 * delta)
		velocity = knockback_velocity
		move_and_slide()
		return

	_find_target()
	if not target or not is_instance_valid(target):
		if _animator:
			_animator.set_walking(false)
		return

	var to_player = target.global_position - global_position
	to_player.y = 0
	var dist = to_player.length()
	var direction: Vector3

	match _state:
		FairyState.APPROACHING:
			direction = to_player.normalized()
			speed = approach_speed
			if dist <= approach_distance:
				_state = FairyState.RETREATING
		FairyState.RETREATING:
			direction = -to_player.normalized()
			speed = retreat_speed
			if dist >= retreat_distance:
				_state = FairyState.APPROACHING

	# Separacao de outros inimigos
	var separation = _get_separation_vector()
	var final_dir = (direction * speed + separation).normalized()
	velocity = final_dir * speed
	move_and_slide()

	# Flutuacao (bob) pra parecer que esta voando
	_bob_time += delta * 3.0
	var bob_offset = sin(_bob_time) * 0.3
	if mesh:
		mesh.position.y = 0.5 + bob_offset
	var proc_model = get_node_or_null("ProceduralModel")
	if proc_model:
		proc_model.position.y = bob_offset

	# Glow pulsa
	if _glow_mesh:
		_glow_mesh.position.y = 0.5 + bob_offset
		var pulse = 0.8 + sin(_bob_time * 1.5) * 0.2
		_glow_mesh.scale = Vector3(pulse, pulse, pulse)

	# Particulas de brilho periodicas
	_wing_time += delta
	if _wing_time >= 0.3:
		_wing_time = 0.0
		var sparkle_pos = global_position + Vector3(randf_range(-0.3, 0.3), 0.5 + bob_offset, randf_range(-0.3, 0.3))
		ParticleFactory.spawn_hit_particles(sparkle_pos, Color(1.0, 0.9, 0.4))

	if _animator:
		_animator.set_walking(true)

func _die() -> void:
	if is_dead:
		return
	# Spawna muitos cristais antes de morrer
	_spawn_crystal_shower()
	super._die()

func _spawn_crystal_shower() -> void:
	var crystal_scene = preload("res://scenes/crystal_pickup.tscn")
	for i in range(crystal_drop_count):
		var crystal = crystal_scene.instantiate()
		# Espalha os cristais em circulo
		var angle = (float(i) / crystal_drop_count) * TAU + randf_range(-0.3, 0.3)
		var dist = randf_range(0.5, 2.0)
		var offset = Vector3(cos(angle) * dist, 0.3, sin(angle) * dist)
		crystal.global_position = global_position + offset
		crystal.crystal_value = randi_range(2, 5)
		get_tree().current_scene.call_deferred("add_child", crystal)
	# Efeito visual de explosao dourada
	ParticleFactory.spawn_death_particles(global_position + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.2), 20)
	ParticleFactory.spawn_death_particles(global_position + Vector3(0, 0.8, 0), Color(1.0, 0.95, 0.5), 15)
	ScreenEffects.shake(0.12)
	AudioManager.play_sfx("level_up")
