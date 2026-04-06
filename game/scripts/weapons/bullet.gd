extends Area3D

## Projetil generico (metralhadora, etc). Vai reto e causa dano ao colidir.

@export var speed: float = 22.0
@export var damage: int = 4
@export var lifetime: float = 2.0

var direction: Vector3 = Vector3.FORWARD
var timer: float = 0.0
var damage_type: String = "physical"
var weapon_id: String = ""  # Set by weapon spawner for damage tracking
var _returning: bool = false
var _trail_counter: int = 0
var _sprite: Sprite3D = null

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	_ensure_bullet_mesh()
	_setup_billboard_sprite()
	_spawn_muzzle_flash()

func _setup_billboard_sprite() -> void:
	# Guard: nao recria sprite se ja existe (pool reuse)
	if _sprite and is_instance_valid(_sprite):
		_update_sprite_rotation()
		return
	_sprite = get_node_or_null("ProjectileSprite")
	if _sprite:
		_update_sprite_rotation()
		return
	var sprite_path = "res://assets/sprites/projectiles/bullet.png"
	if ResourceLoader.exists(sprite_path):
		var existing_mesh = get_node_or_null("Mesh")
		if not existing_mesh:
			existing_mesh = get_node_or_null("MeshInstance3D")
		if existing_mesh:
			existing_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.04
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "ProjectileSprite"
		# Deita o sprite no plano XZ (virado pra camera top-down)
		sprite.rotation.x = -PI / 2.0
		add_child(sprite)
		_sprite = sprite
		# Rotaciona pra apontar na direcao de viagem
		_update_sprite_rotation()

func _ensure_bullet_mesh() -> void:
	var mesh_instance = get_node_or_null("Mesh")
	if not mesh_instance:
		mesh_instance = get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		return
	# Esconde o mesh 3D — usamos apenas o sprite
	mesh_instance.visible = false

func _spawn_muzzle_flash() -> void:
	if not _sprite:
		return
	# Sempre usa escala base constante (previne acumulo exponencial no pool)
	_sprite.scale = Vector3.ONE * 1.8
	var tween = create_tween()
	tween.tween_property(_sprite, "scale", Vector3.ONE, 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _update_sprite_rotation() -> void:
	if not _sprite:
		return
	# Com rotation.x = -PI/2, o eixo +X da imagem mapeia para +X do mundo.
	# atan2(-z, x) da o angulo correto a partir do eixo +X no plano XZ.
	var angle = atan2(-direction.z, direction.x)
	_sprite.rotation.z = angle

## Alinha o no 3D inteiro na direcao de viagem (para mesh 3D em vez de sprite).
## Chamar 1x apos setar direction. Ponta do modelo deve apontar pra -Z.
func _align_to_direction() -> void:
	if direction == Vector3.ZERO:
		return
	var target_point = global_position + direction
	var up = Vector3.UP if abs(direction.normalized().dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	look_at(target_point, up)


func _physics_process(delta: float) -> void:
	if _returning:
		return
	timer += delta
	if timer >= lifetime:
		_return_to_pool()
		return
	if is_inside_tree():
		global_position += direction * speed * delta
		# Mantem a bala acima do chao mas baixa o suficiente pra acertar inimigos pequenos (slime Y=0.0-0.4)
		global_position.y = maxf(global_position.y, 0.3)
		# Performance: confia nos signals body_entered + area_entered.
		# Overlap check manual removido — era O(n) por bala por frame.

func _on_body_entered(body: Node3D) -> void:
	if _returning or not is_inside_tree():
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		GameManager._last_attacking_weapon = weapon_id
		body.call_deferred("take_damage", damage, damage_type)
	elif body.has_method("take_damage") and body.is_in_group("players"):
		body.call_deferred("take_damage", damage)
	_return_to_pool()

## Detecao alternativa via Area3D (Hitbox do inimigo)
func _on_area_entered(area: Area3D) -> void:
	if _returning or not is_inside_tree():
		return
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage") and parent.is_in_group("enemies"):
		GameManager._last_attacking_weapon = weapon_id
		parent.call_deferred("take_damage", damage, damage_type)
		_return_to_pool()

func _return_to_pool() -> void:
	if _returning:
		return
	if not is_inside_tree():
		return
	_returning = true
	timer = 0.0
	direction = Vector3.FORWARD
	set_deferred("monitoring", false)
	call_deferred("_do_return")

func _do_return() -> void:
	if not is_inside_tree():
		return
	if scene_file_path and not scene_file_path.is_empty():
		ObjectPool.return_instance(self, scene_file_path)
	else:
		queue_free()

func _reset_for_reuse() -> void:
	_returning = false
	monitoring = true
	timer = 0.0
	_trail_counter = 0
	visible = true
	# RESET CRITICO: limpa rotacao/escala residual da "vida anterior" no pool
	transform.basis = Basis()
	# Restaura collision layer/mask (podem ter sido zerados por visual-only ou outro motivo)
	collision_layer = 8  # Layer 4: PlayerAttacks
	collision_mask = 2   # Layer 2: Enemies
	# Garante que processing esta ativo (prewarm pode ter desativado)
	set_process(true)
	set_physics_process(true)
	# Reconecta signals se nao estiverem conectados
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	# Reconecta referencia do sprite (pode ter sido perdida no pool)
	if not _sprite or not is_instance_valid(_sprite):
		_sprite = get_node_or_null("ProjectileSprite")
	# Se sprite nao existe (primeira vez via pool), cria via setup
	if not _sprite:
		_setup_billboard_sprite()
	# Forca escala base e visibilidade antes de qualquer efeito (previne acumulo)
	if _sprite:
		_sprite.visible = true
		_sprite.scale = Vector3.ONE
	# Esconde mesh 3D (pode ter voltado visivel no pool)
	_ensure_bullet_mesh()
	# Forca sincronizacao da posicao antes de calcular rotacao visual
	if is_inside_tree():
		force_update_transform()
	_update_sprite_rotation()
	_spawn_muzzle_flash()
