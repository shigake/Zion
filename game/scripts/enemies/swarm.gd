extends EnemyBase3D

## Enxame de insetos. Grupo de 20+ mini-inimigos representados como um unico node.
## Baixo dano individual mas ataca rapido. Morre rapido mas sao muitos.

@export var swarm_count: int = 20
@export var swarm_radius: float = 1.5

var _child_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	speed = 5.0
	max_hp = 60
	hp = max_hp
	damage = 3
	xp_drop = 8
	enemy_color = Color(0.3, 0.25, 0.1)
	resistances = {
		"fire": 1.5,       # Fraco a fogo
		"ice": 1.3,        # Fraco a gelo
		"electric": 0.5,   # Resistente a eletrico (insetos)
	}
	super._ready()
	_spawn_swarm_visuals()

func _spawn_swarm_visuals() -> void:
	# Cria mini-meshes representando cada inseto do enxame
	for i in range(swarm_count):
		var mini = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		mini.mesh = sphere
		var mat = StandardMaterial3D.new()
		mat.albedo_color = enemy_color
		mini.material_override = mat
		# Posicao aleatoria dentro do raio
		var angle = randf() * TAU
		var dist = randf() * swarm_radius
		mini.position = Vector3(cos(angle) * dist, randf_range(0.2, 0.8), sin(angle) * dist)
		add_child(mini)
		_child_meshes.append(mini)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	# Anima os insetos do enxame se movendo
	for mini in _child_meshes:
		if is_instance_valid(mini):
			mini.position += Vector3(
				randf_range(-0.5, 0.5) * delta,
				randf_range(-0.3, 0.3) * delta,
				randf_range(-0.5, 0.5) * delta
			)
			# Mantém dentro do raio
			if mini.position.length() > swarm_radius:
				mini.position = mini.position.normalized() * swarm_radius

func take_damage(amount: int, damage_type: String = "physical") -> void:
	super.take_damage(amount, damage_type)
	# Remove visual de insetos proporcionalmente ao HP
	var alive_ratio = float(hp) / float(max_hp)
	var target_count = int(swarm_count * alive_ratio)
	while _child_meshes.size() > target_count and not _child_meshes.is_empty():
		var mini = _child_meshes.pop_back()
		if is_instance_valid(mini):
			mini.queue_free()
