extends Area3D
class_name EnemyProjectile

## Projetil generico de inimigos. Usa pool para reuso (performance).
## Configuravel: velocidade, dano, tipo de dano, visual (cor/tamanho), gravidade, lifetime.

@export var speed: float = 12.0
@export var damage: int = 8
@export var damage_type: String = "physical"
@export var lifetime: float = 5.0
@export var proj_gravity: float = 0.0  ## Gravidade (para projeteis em arco)
@export var projectile_color: Color = Color(1.0, 0.3, 0.1)
@export var projectile_radius: float = 0.12

var direction: Vector3 = Vector3.FORWARD
var _velocity: Vector3 = Vector3.ZERO
var _timer: float = 0.0
var _sprite: Sprite3D = null
var _col_shape: CollisionShape3D = null
var _initialized: bool = false

func _ready() -> void:
	# Colisao: layer 5 (EnemyAttacks), mask 1 (Players)
	collision_layer = 16  # Layer 5
	collision_mask = 1    # Layer 1 (Players)
	monitoring = true
	monitorable = false

	if not _initialized:
		_setup_visuals()
		_initialized = true
	else:
		_update_visuals()

	# Conectar sinal de colisao (only once)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# Velocidade inicial na direcao configurada
	_velocity = direction.normalized() * speed

func _setup_visuals() -> void:
	_sprite = Sprite3D.new()
	# Create a small circle dot texture
	var size = 8
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for x in range(size):
		for y in range(size):
			var dx = x - size / 2
			var dy = y - size / 2
			if dx * dx + dy * dy < 12:
				img.set_pixel(x, y, projectile_color)
	_sprite.texture = ImageTexture.create_from_image(img)
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.pixel_size = projectile_radius * 0.25
	_sprite.shaded = false
	_sprite.transparent = true
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

	_col_shape = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = projectile_radius * 1.5
	_col_shape.shape = shape
	add_child(_col_shape)

func _update_visuals() -> void:
	if _sprite:
		# Regenerate texture with new color
		var size = 8
		var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
		for x in range(size):
			for y in range(size):
				var dx = x - size / 2
				var dy = y - size / 2
				if dx * dx + dy * dy < 12:
					img.set_pixel(x, y, projectile_color)
		_sprite.texture = ImageTexture.create_from_image(img)
		_sprite.pixel_size = projectile_radius * 0.25

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	_timer += delta
	if _timer >= lifetime:
		_deactivate()
		return

	# Aplicar gravidade (para projeteis em arco)
	_velocity.y -= proj_gravity * delta

	global_position += _velocity * delta

func _on_body_entered(body: Node3D) -> void:
	if not is_inside_tree():
		return
	if body.is_in_group("players") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		_deactivate()

func _deactivate() -> void:
	# Return to pool instead of queue_free
	set_physics_process(false)
	monitoring = false
	visible = false
	if get_parent():
		get_parent().remove_child(self)

## Reset for reuse from pool
func _reset_for_reuse() -> void:
	_timer = 0.0
	_velocity = Vector3.ZERO
	set_physics_process(true)
	monitoring = true
	visible = true

## Cria e retorna um EnemyProjectile configurado (factory method)
static func create(
	pos: Vector3,
	dir: Vector3,
	p_speed: float = 12.0,
	p_damage: int = 8,
	p_type: String = "physical",
	p_color: Color = Color(1.0, 0.3, 0.1),
	p_proj_gravity: float = 0.0,
	p_radius: float = 0.12,
	p_lifetime: float = 5.0
) -> EnemyProjectile:
	var proj = EnemyProjectile.new()
	proj.global_position = pos
	proj.direction = dir.normalized()
	proj.speed = p_speed
	proj.damage = p_damage
	proj.damage_type = p_type
	proj.projectile_color = p_color
	proj.proj_gravity = p_proj_gravity
	proj.projectile_radius = p_radius
	proj.lifetime = p_lifetime
	return proj
