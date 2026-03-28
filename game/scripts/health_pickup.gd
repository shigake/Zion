extends Area3D

## Pickup de vida (coração). Dropa dos inimigos, cura o jogador ao coletar.

@export var heal_value: int = 10
@export var attract_speed: float = 14.0
@export var base_attract_range: float = 3.5

var being_attracted: bool = false
var attract_target: Node3D = null
var _collected := false
var _spawn_time: float = 0.0

@onready var mesh: MeshInstance3D = $Mesh
var _pickup_sprite: Sprite3D = null

func _ready() -> void:
	add_to_group("pickups")
	add_to_group("health_pickups")
	body_entered.connect(_on_body_entered)
	_spawn_time = GameManager.game_time
	# Glow vermelho pulsante
	if mesh:
		mesh.material_override = VisualSetup.create_glow_material(Color(1.0, 0.2, 0.3), 2.5)
	# Billboard sprite (hides mesh if sprite texture exists)
	var sprite_path = "res://assets/sprites/pickups/health.png"
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

	# Bobbing + pulsacao de escala (heartbeat)
	var t = GameManager.game_time
	var bob = sin(t * 3.5 + global_position.x * 2.0) * 0.12
	if _pickup_sprite:
		_pickup_sprite.position.y = bob
		var pulse = 1.0 + sin(t * 6.0) * 0.1
		_pickup_sprite.scale = Vector3(pulse, pulse, pulse)
	else:
		position.y = 0.35 + bob
		if mesh:
			var pulse = 1.0 + sin(t * 6.0) * 0.1
			mesh.scale = Vector3(pulse, pulse, pulse)

	# Atracao ao jogador
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

	# Despawn apos 30 segundos
	if GameManager.game_time - _spawn_time > 30.0:
		queue_free()

func _collect() -> void:
	if _collected or not is_inside_tree():
		return
	_collected = true
	AudioManager.play_sfx("heal")
	ParticleFactory.spawn_collect_particles(global_position, Color(1.0, 0.3, 0.4))
	GameManager.heal(heal_value)
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		_collect()

func attract_to(target: Node3D) -> void:
	## Chamado pelo magnet pickup para forcar atracao
	being_attracted = true
	attract_target = target
