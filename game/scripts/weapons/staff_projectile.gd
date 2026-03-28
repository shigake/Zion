extends Area3D

## Projetil homing do Staff. Persegue o alvo e causa dano ao colidir.

@export var speed: float = 14.0
@export var damage: int = 8
@export var lifetime: float = 5.0
@export var homing_strength: float = 8.0

var target: Node3D = null
var direction: Vector3 = Vector3.FORWARD
var timer: float = 0.0
var damage_type: String = "ice"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	# Blue weapon trail
	var trail = Node3D.new()
	trail.set_script(preload("res://scripts/effects/weapon_trail.gd"))
	trail.trail_color = Color(0.3, 0.5, 1.0, 0.6)
	add_child(trail)
	_setup_billboard_sprite()

func _setup_billboard_sprite() -> void:
	var sprite_path = "res://assets/sprites/projectiles/staff_projectile.png"
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

func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
		return

	# Homing: ajusta direcao em direcao ao alvo
	if target and is_instance_valid(target):
		var to_target = (target.global_position - global_position).normalized()
		to_target.y = 0
		direction = direction.lerp(to_target, homing_strength * delta).normalized()

	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		GameManager._last_attacking_weapon = "staff"
		body.call_deferred("take_damage", damage, damage_type)
		queue_free()
