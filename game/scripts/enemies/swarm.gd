extends EnemyBase3D

## Enxame de insetos. Grupo de 20+ mini-inimigos representados como um unico node.
## Baixo dano individual mas ataca rapido. Morre rapido mas sao muitos.

@export var swarm_count: int = 20
@export var swarm_radius: float = 1.5

var _child_sprites: Array[Sprite3D] = []
var _swarm_tex: ImageTexture = null

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
	# Create a shared tiny dot texture for all swarm sprites
	var img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for x in range(4):
		for y in range(4):
			var dx = x - 2
			var dy = y - 2
			if dx * dx + dy * dy < 4:
				img.set_pixel(x, y, enemy_color)
	_swarm_tex = ImageTexture.create_from_image(img)

	# Cria mini-sprites representando cada inseto do enxame
	for i in range(swarm_count):
		var mini = Sprite3D.new()
		mini.texture = _swarm_tex
		mini.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mini.pixel_size = 0.04
		mini.shaded = false
		mini.transparent = true
		mini.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		# Posicao aleatoria dentro do raio
		var angle = randf() * TAU
		var dist = randf() * swarm_radius
		mini.position = Vector3(cos(angle) * dist, randf_range(0.2, 0.8), sin(angle) * dist)
		add_child(mini)
		_child_sprites.append(mini)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	# Anima os insetos do enxame se movendo
	for mini in _child_sprites:
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
	while _child_sprites.size() > target_count and not _child_sprites.is_empty():
		var mini = _child_sprites.pop_back()
		if is_instance_valid(mini):
			mini.queue_free()
