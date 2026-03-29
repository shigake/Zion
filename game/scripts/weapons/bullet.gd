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
	body_entered.connect(_on_body_entered)
	_ensure_bullet_mesh()
	_setup_billboard_sprite()
	_spawn_muzzle_flash()

func _setup_billboard_sprite() -> void:
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
	# Brief scale-up flash effect on spawn usando o sprite
	var original_scale = _sprite.scale
	_sprite.scale = original_scale * 2.5
	var tween = create_tween()
	tween.tween_property(_sprite, "scale", original_scale, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _update_sprite_rotation() -> void:
	if not _sprite:
		return
	# Rotaciona o sprite ao redor de Z local (que aponta pra cima no plano XZ)
	# para que a bala aponte na direcao de viagem vista de cima
	var angle = atan2(direction.x, direction.z)
	_sprite.rotation.z = angle


func _physics_process(delta: float) -> void:
	if _returning:
		return
	timer += delta
	if timer >= lifetime:
		_return_to_pool()
		return
	if is_inside_tree():
		global_position += direction * speed * delta
		# Mantem a bala na altura correta (acima do chao)
		global_position.y = maxf(global_position.y, 0.8)

func _on_body_entered(body: Node3D) -> void:
	if _returning or not is_inside_tree():
		return
	_returning = true  # Prevent double-trigger
	set_deferred("monitoring", false)
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		GameManager._last_attacking_weapon = weapon_id
		body.call_deferred("take_damage", damage, damage_type)
	elif body.has_method("take_damage") and body.is_in_group("players"):
		body.call_deferred("take_damage", damage)
	_return_to_pool()

func _return_to_pool() -> void:
	if _returning:
		return
	if not is_inside_tree():
		return
	_returning = true
	timer = 0.0
	direction = Vector3.FORWARD
	monitoring = false
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
	# Reconecta referencia do sprite (pode ter sido perdida no pool)
	if not _sprite:
		_sprite = get_node_or_null("ProjectileSprite")
	_update_sprite_rotation()
	_spawn_muzzle_flash()
