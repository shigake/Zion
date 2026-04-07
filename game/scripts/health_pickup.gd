extends Area3D

## Pickup de vida (coração). Dropa dos inimigos, cura o jogador ao coletar.

@export var heal_value: int = 10
@export var attract_speed: float = 14.0
@export var base_attract_range: float = 3.5

var being_attracted: bool = false
var attract_target: Node3D = null
var _collected := false
var _spawn_time: float = 0.0
var _frame_counter: int = 0
const MAX_PICKUPS := GameConstants.PICKUP_CAP
const _HEALTH_TEXTURE := preload("res://assets/sprites/pickups/health_pickup.png")

@onready var mesh: MeshInstance3D = $Mesh
var _pickup_sprite: Sprite3D = null

func _ready() -> void:
	add_to_group("pickups")
	add_to_group("health_pickups")
	body_entered.connect(_on_body_entered)
	_spawn_time = GameManager.game_time
	_frame_counter = randi() % 10
	# Glow vermelho pulsante
	if mesh:
		mesh.material_override = VisualSetup.create_glow_material(Color(1.0, 0.2, 0.3), 2.5)
	# Billboard sprite (hides mesh if sprite texture exists)
	if _HEALTH_TEXTURE:
		if mesh:
			mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = _HEALTH_TEXTURE
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.025
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "PickupSprite"
		add_child(sprite)
		_pickup_sprite = sprite
	# O(1) pickup cap via global counter
	GameManager.active_pickup_count += 1
	if GameManager.active_pickup_count > MAX_PICKUPS:
		_collect()
		return

func _exit_tree() -> void:
	GameManager.active_pickup_count = maxi(0, GameManager.active_pickup_count - 1)

func _physics_process(delta: float) -> void:
	if _collected or not is_inside_tree():
		return
	if GameManager.paused:
		return

	_frame_counter += 1

	# Bobbing + pulsacao de escala (heartbeat), staggered to avoid 1 update per pickup per frame.
	var t = GameManager.game_time
	if _frame_counter % 3 == 0:
		var bob = sin(t * 3.5 + global_position.x * 2.0) * 0.12
		var pulse = 1.0 + sin(t * 6.0) * 0.1
		if _pickup_sprite:
			_pickup_sprite.position.y = bob
			_pickup_sprite.scale = Vector3(pulse, pulse, pulse)
		else:
			position.y = 0.35 + bob
			if mesh:
				mesh.scale = Vector3(pulse, pulse, pulse)

	# Atracao ao jogador
	if not being_attracted and _frame_counter % 10 == 0:
		var players = GameManager.get_players()
		var range_sq = pow(base_attract_range * GameManager.magnet_mult, 2.0)
		for p in players:
			if is_instance_valid(p) and global_position.distance_squared_to(p.global_position) < range_sq:
				being_attracted = true
				attract_target = p
				break

	if being_attracted and attract_target and is_instance_valid(attract_target):
		var dir = (attract_target.global_position - global_position).normalized()
		global_position += dir * attract_speed * delta
		if global_position.distance_squared_to(attract_target.global_position) < 0.25:
			_collect()

	# Despawn apos 30 segundos
	if GameManager.game_time - _spawn_time > 30.0:
		queue_free()

## Throttle para coleta em massa (magnetica)
static var _collect_sfx_cooldown: float = 0.0

func _collect() -> void:
	if _collected or not is_inside_tree():
		return
	_collected = true
	ParticleFactory.spawn_collect_particles(global_position, Color(1.0, 0.3, 0.4))
	var now = GameManager.game_time
	if now - _collect_sfx_cooldown > 0.06:
		_collect_sfx_cooldown = now
		AudioManager.play_sfx("heal")
	GameManager.heal(heal_value)
	GameManager.health_pickups_used += 1
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if _collected or not is_inside_tree():
		return
	if body.is_in_group("players"):
		_collect()

func attract_to(target: Node3D) -> void:
	## Chamado pelo magnet pickup para forcar atracao
	being_attracted = true
	attract_target = target
