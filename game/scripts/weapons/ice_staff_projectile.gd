extends Area3D

## Projetil cristal de gelo do Ice Staff — gira lentamente enquanto viaja.

@export var speed: float = 10.0
@export var damage: int = 10
@export var lifetime: float = 4.0

var direction: Vector3 = Vector3.FORWARD
var timer: float = 0.0
var damage_type: String = "ice"
var weapon_id: String = ""
var _returning: bool = false
var _spin_speed: float = 3.0
var _sprite: Sprite3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_setup_billboard_sprite()

func _setup_billboard_sprite() -> void:
	# Guard: nao recria sprite se ja existe (pool reuse)
	if _sprite and is_instance_valid(_sprite):
		return
	_sprite = get_node_or_null("ProjectileSprite")
	if _sprite:
		return
	var sprite_path = "res://assets/sprites/projectiles/ice_crystal.png"
	if ResourceLoader.exists(sprite_path):
		var existing_mesh = get_node_or_null("Mesh")
		if not existing_mesh:
			existing_mesh = get_node_or_null("MeshInstance3D")
		if existing_mesh:
			existing_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.04
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "ProjectileSprite"
		add_child(sprite)
		_sprite = sprite

func _physics_process(delta: float) -> void:
	if _returning:
		return
	timer += delta
	if timer >= lifetime:
		_return_to_pool()
		return

	# Slow spin on travel axis
	rotate_y(_spin_speed * delta)

	if is_inside_tree():
		global_position += direction * speed * delta
		# Performance: confia nos signals body_entered + area_entered.
		# Overlap check manual removido — era O(n) por projetil por frame.

func _on_body_entered(body: Node3D) -> void:
	if _returning:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		GameManager._last_attacking_weapon = "ice_staff"
		body.call_deferred("take_damage", damage, damage_type)
		# Don't free here — ice_staff.gd handles freeze_area via signal

## Detecao alternativa via Area3D (Hitbox do inimigo)
func _on_area_entered(area: Area3D) -> void:
	if _returning:
		return
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage") and parent.is_in_group("enemies"):
		GameManager._last_attacking_weapon = "ice_staff"
		parent.call_deferred("take_damage", damage, damage_type)

func _return_to_pool() -> void:
	if _returning:
		return
	_returning = true
	timer = 0.0
	direction = Vector3.FORWARD
	monitoring = false
	call_deferred("_do_return")

func _do_return() -> void:
	if scene_file_path and not scene_file_path.is_empty():
		ObjectPool.return_instance(self, scene_file_path)
	else:
		queue_free()

func _reset_for_reuse() -> void:
	_returning = false
	monitoring = true
	timer = 0.0
	# RESET CRITICO: limpa rotacao/escala residual da "vida anterior" no pool
	transform.basis = Basis()
	visible = true
	set_physics_process(true)
	# Reconecta signals se nao estiverem conectados
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	# Reconecta referencia do sprite (pode ter sido perdida no pool)
	if not _sprite:
		_sprite = get_node_or_null("ProjectileSprite")
	# Forca escala base (previne acumulo no pool)
	if _sprite:
		_sprite.scale = Vector3.ONE
	# Forca sincronizacao da posicao antes de rodar
	force_update_transform()
