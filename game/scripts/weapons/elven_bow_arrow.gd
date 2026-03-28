extends Area3D

## Flecha elfica — perfura todos os inimigos e ricocheta uma vez apos distancia.

@export var speed: float = 20.0
@export var damage: int = 12
@export var lifetime: float = 4.0

var direction: Vector3 = Vector3.FORWARD
var timer: float = 0.0
var damage_type: String = "physical"
var pierce: bool = true
var ricochet_distance: float = 15.0
var distance_traveled: float = 0.0
var has_ricocheted: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_billboard_sprite()

func _setup_billboard_sprite() -> void:
	var sprite_path = "res://assets/sprites/projectiles/arrow.png"
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
		sprite.pixel_size = 0.02
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "ProjectileSprite"
		add_child(sprite)

func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
		return

	var move = direction * speed * delta
	global_position += move
	distance_traveled += move.length()

	# Ricocheta uma vez apos percorrer ricochet_distance
	if not has_ricocheted and distance_traveled >= ricochet_distance:
		has_ricocheted = true
		var angle = randf_range(-PI, PI)
		direction = direction.rotated(Vector3.UP, angle).normalized()
		_spawn_ricochet_flash()

func _spawn_ricochet_flash() -> void:
	# Brief bright green flash on bounce
	var flash = MeshInstance3D.new()
	var flash_mesh = SphereMesh.new()
	flash_mesh.radius = 0.01
	flash_mesh.height = 0.02
	flash.mesh = flash_mesh

	var flash_mat = StandardMaterial3D.new()
	flash_mat.albedo_color = Color(0.3, 1.0, 0.3)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(0.2, 1.0, 0.3)
	flash_mat.emission_energy_multiplier = 4.0
	flash.material_override = flash_mat
	flash.scale = Vector3.ZERO

	get_tree().current_scene.add_child(flash)
	flash.global_position = global_position

	# Scale up then down: 0 -> 0.3 -> 0 in 0.15s
	var tween = flash.create_tween()
	tween.tween_property(flash, "scale", Vector3(0.3, 0.3, 0.3) * 30.0, 0.075).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(flash, "scale", Vector3.ZERO, 0.075).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(flash.queue_free)


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		GameManager._last_attacking_weapon = "elven_bow"
		body.call_deferred("take_damage", damage, damage_type)
		# Nao faz queue_free — perfura todos os inimigos
