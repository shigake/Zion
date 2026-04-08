extends CharacterBody3D

## Esqueleto invocado pelo Necromante. Persegue e ataca inimigos.

@export var speed: float = 5.0
@export var damage: int = 6
@export var lifetime: float = 10.0
@export var attack_range: float = 1.2
@export var attack_cooldown: float = 0.8

var target: Node3D = null
var timer: float = 0.0
var attack_timer: float = 0.0

func _ready() -> void:
	add_to_group("player_summons")
	_apply_skeleton_model()

func _apply_skeleton_model() -> void:
	var model_path = "res://assets/models/skeleton_minion.glb"
	var _skel_scene = EnemyBase3D._safe_load_model(model_path)
	if _skel_scene:
		var model: Node3D = _skel_scene.instantiate()
		model.name = "SummonModel"
		model.scale = Vector3(0.4, 0.4, 0.4)
		model.position.y = 0.0
		add_child(model)
	else:
		# Fallback: sprite-based skeleton
		var sprite_path = "res://assets/sprites/enemies/skeleton.png"
		if ResourceLoader.exists(sprite_path):
			var sprite = Sprite3D.new()
			sprite.texture = load(sprite_path)
			sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			sprite.pixel_size = 0.035
			sprite.shaded = false
			sprite.transparent = true
			sprite.modulate = Color(0.7, 1.0, 0.7)  # Green tint for summoned
			sprite.name = "SummonSprite"
			sprite.position.y = 0.5
			add_child(sprite)

func _physics_process(delta: float) -> void:
	if GameManager.paused or not is_inside_tree():
		return

	timer += delta
	if timer >= lifetime:
		queue_free()
		return

	attack_timer -= delta

	_find_target()
	if target and is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		dir.y = 0
		var dist = global_position.distance_to(target.global_position)

		if dist > attack_range:
			velocity = dir * speed
			move_and_slide()
		elif attack_timer <= 0:
			_attack()
			attack_timer = attack_cooldown

func _find_target() -> void:
	var enemies = GameManager.get_enemies()
	if enemies.is_empty():
		target = null
		return
	var min_dist = INF
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d = global_position.distance_squared_to(e.global_position)
		if d < min_dist:
			min_dist = d
			target = e

func _attack() -> void:
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		GameManager._last_attacking_weapon = "necro"
		target.call_deferred("take_damage", damage, "dark")
