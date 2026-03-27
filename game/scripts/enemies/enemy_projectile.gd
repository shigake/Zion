extends Area3D
class_name EnemyProjectile

## Projetil generico de inimigos. Usado por drones, snipers, cookie ninjas, fire imps.
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

func _ready() -> void:
	# Colisao: layer 5 (EnemyAttacks), mask 1 (Players)
	collision_layer = 16  # Layer 5
	collision_mask = 1    # Layer 1 (Players)
	monitoring = true
	monitorable = false

	# Criar mesh visual
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = projectile_radius
	sphere.height = projectile_radius * 2.0
	mesh_inst.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = projectile_color
	mat.emission_enabled = true
	mat.emission = projectile_color
	mat.emission_energy_multiplier = 2.0
	mesh_inst.material_override = mat
	add_child(mesh_inst)

	# Criar collision shape
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = projectile_radius * 1.5
	col.shape = shape
	add_child(col)

	# Conectar sinal de colisao
	body_entered.connect(_on_body_entered)

	# Velocidade inicial na direcao configurada
	_velocity = direction.normalized() * speed

func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= lifetime:
		queue_free()
		return

	# Aplicar gravidade (para projeteis em arco)
	_velocity.y -= proj_gravity * delta

	global_position += _velocity * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		queue_free()

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
