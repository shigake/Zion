extends Area3D

## Pickup de ima. Ao coletar, atrai TODOS os pickups do mapa para o jogador.

@export var attract_speed: float = 10.0
@export var base_attract_range: float = 3.5

var being_attracted: bool = false
var attract_target: Node3D = null
var _collected := false
var _spawn_time: float = 0.0

@onready var mesh: MeshInstance3D = $Mesh
var _pickup_sprite: Sprite3D = null

func _ready() -> void:
	add_to_group("pickups")
	add_to_group("magnet_pickups")
	body_entered.connect(_on_body_entered)
	_spawn_time = GameManager.game_time
	# Glow cinza/branco magnetico
	if mesh:
		mesh.material_override = VisualSetup.create_glow_material(Color(0.7, 0.8, 1.0), 3.0)
	# Billboard sprite (hides mesh if sprite texture exists)
	var sprite_path = "res://assets/sprites/pickups/magnet.png"
	if ResourceLoader.exists(sprite_path):
		if mesh:
			mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.025
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "PickupSprite"
		add_child(sprite)
		_pickup_sprite = sprite

func _physics_process(delta: float) -> void:
	if GameManager.paused:
		return

	# Bobbing + rotacao
	var t = GameManager.game_time
	var bob = sin(t * 4.0 + global_position.z * 2.0) * 0.1
	if _pickup_sprite:
		_pickup_sprite.position.y = bob
	else:
		position.y = 0.35 + bob
		if mesh:
			mesh.rotation.y += delta * 5.0

	# Atracao ao jogador
	if not being_attracted:
		var players = GameManager.get_players()
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

	# Despawn apos 30 segundos
	if GameManager.game_time - _spawn_time > 30.0:
		queue_free()

func _collect() -> void:
	if _collected or not is_inside_tree():
		return
	_collected = true
	GameManager.magnets_collected += 1
	AudioManager.play_sfx("collect_xp")
	# Flash branco na tela
	ScreenEffects.flash(0.15, 0.2)
	ParticleFactory.spawn_collect_particles(global_position, Color(0.7, 0.8, 1.0))

	# Encontra o jogador mais proximo pra ser o alvo de atracao
	var collector = attract_target
	if not collector or not is_instance_valid(collector):
		var players = GameManager.get_players()
		if not players.is_empty():
			collector = players[0]

	if collector:
		_attract_all_pickups(collector)

	queue_free()

func _attract_all_pickups(target: Node3D) -> void:
	## Atrai TODOS os pickups do mapa para o jogador — escalonado em ondas
	## para evitar stutter quando ha muitos pickups simultaneos.
	var all_pickups: Array = []

	# Coleta todos os pickups validos de uma vez (1 query ao inves de 3)
	for p in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(p) and p != self and "being_attracted" in p and "_collected" in p and not p._collected:
			all_pickups.append(p)

	# Ordena por distancia ao player (mais pertos primeiro)
	var tgt_pos = target.global_position
	all_pickups.sort_custom(func(a, b): return a.global_position.distance_squared_to(tgt_pos) < b.global_position.distance_squared_to(tgt_pos))

	# Ativa atracao em ondas de BATCH_SIZE a cada BATCH_DELAY segundos
	const BATCH_SIZE := 25
	const BATCH_DELAY := 0.05  # 50ms entre ondas
	var batch_idx := 0
	for i in all_pickups.size():
		var pickup = all_pickups[i]
		if i > 0 and i % BATCH_SIZE == 0:
			batch_idx += 1
		# Primeira onda: imediata. Demais: timer escalonado
		if batch_idx == 0:
			_start_magnet_attract(pickup, target)
		else:
			var delay = batch_idx * BATCH_DELAY
			# Usa callable com bind para capturar referencia
			get_tree().create_timer(delay).timeout.connect(
				func(): _start_magnet_attract(pickup, target)
			)

func _start_magnet_attract(pickup: Node3D, target: Node3D) -> void:
	if not is_instance_valid(pickup) or not is_instance_valid(target):
		return
	if "_collected" in pickup and pickup._collected:
		return
	pickup.being_attracted = true
	pickup.attract_target = target
	# Desabilita colisao Area3D — ja sabemos o target, nao precisa de overlap detection
	if pickup is Area3D:
		pickup.monitoring = false
		pickup.monitorable = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		_collect()
