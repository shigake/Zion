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
	## Atrai TODOS os pickups do mapa para o jogador
	# XP gems
	for gem in get_tree().get_nodes_in_group("xp_gems"):
		if is_instance_valid(gem) and not gem._collected:
			gem.being_attracted = true
			gem.attract_target = target

	# Cristais
	for crystal in get_tree().get_nodes_in_group("crystals"):
		if is_instance_valid(crystal) and not crystal._collected:
			crystal.being_attracted = true
			crystal.attract_target = target

	# Health pickups
	for hp_pickup in get_tree().get_nodes_in_group("health_pickups"):
		if is_instance_valid(hp_pickup) and hp_pickup != self and not hp_pickup._collected:
			hp_pickup.being_attracted = true
			hp_pickup.attract_target = target

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		_collect()
