extends CharacterBody3D

## Jogador 3D top-down. Movimento, dash, vida. Suporta multiplayer.

@export var base_speed: float = 8.0
@export var player_id: int = 1  # peer_id no multiplayer
@export var dash_speed: float = 24.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 3.0

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var can_be_hurt: bool = true
var hurt_cooldown: float = 0.0
var move_direction: Vector3 = Vector3.ZERO

# Referencia ao node de armas
@onready var weapon_pivot: Node3D = $WeaponPivot
@onready var mesh: MeshInstance3D = $Mesh
@onready var hurt_flash_timer: float = 0.0
var original_color: Color = Color(0.2, 0.85, 0.3)
var is_local: bool = true  # Se este jogador e controlado localmente

func _ready() -> void:
	is_local = not MultiplayerManager.is_online or (player_id == MultiplayerManager.local_player_id)
	# Arma inicial e configurada pelo stage_cemetery.gd
	# Se nenhuma arma foi setada (fallback), usa katana
	if GameManager.player_weapons.is_empty():
		GameManager.add_weapon("katana")
		_spawn_weapon("katana")

func _physics_process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.paused:
		return

	# Jogador remoto: so recebe sync
	if not is_local:
		return

	# Hurt cooldown
	if hurt_cooldown > 0:
		hurt_cooldown -= delta
		if hurt_cooldown <= 0:
			can_be_hurt = true

	# Hurt flash
	if hurt_flash_timer > 0:
		hurt_flash_timer -= delta
		if hurt_flash_timer <= 0:
			_set_color(original_color)

	# Dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Dash
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * dash_speed
		if dash_timer <= 0:
			is_dashing = false
	else:
		# Movement input
		var input_dir = Vector2.ZERO
		input_dir.x = Input.get_axis("move_left", "move_right")
		input_dir.y = Input.get_axis("move_up", "move_down")
		input_dir = input_dir.normalized()

		move_direction = Vector3(input_dir.x, 0, input_dir.y)
		var speed = base_speed * GameManager.speed_mult
		velocity = move_direction * speed

		# Trigger dash
		if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and move_direction.length() > 0.1:
			is_dashing = true
			dash_timer = dash_duration
			dash_cooldown_timer = dash_cooldown
			dash_direction = move_direction.normalized()

	move_and_slide()

	# Sync posicao no multiplayer
	if MultiplayerManager.is_online:
		_sync_position.rpc(global_position)

@rpc("any_peer", "unreliable")
func _sync_position(pos: Vector3) -> void:
	if not is_local:
		global_position = global_position.lerp(pos, 0.3)

func take_damage(amount: int) -> void:
	if not can_be_hurt or is_dashing:
		return
	GameManager.take_damage(amount)
	can_be_hurt = false
	hurt_cooldown = 0.5
	# Flash vermelho
	_set_color(Color(1, 0.2, 0.2))
	hurt_flash_timer = 0.12

func _set_color(color: Color) -> void:
	var mat = mesh.get_surface_override_material(0)
	if mat is StandardMaterial3D:
		mat.albedo_color = color

var weapon_scenes: Dictionary = {
	"katana": preload("res://scenes/weapons/katana.tscn"),
	"staff": preload("res://scenes/weapons/staff.tscn"),
	"scythe": preload("res://scenes/weapons/scythe.tscn"),
	"machinegun": preload("res://scenes/weapons/machinegun.tscn"),
	"bazooka": preload("res://scenes/weapons/bazooka.tscn"),
	"necro": preload("res://scenes/weapons/necro.tscn"),
}

func _spawn_weapon(weapon_id: String) -> void:
	if weapon_id not in weapon_scenes:
		return
	var weapon = weapon_scenes[weapon_id].instantiate()
	weapon_pivot.add_child(weapon)

func add_weapon_node(weapon_id: String) -> void:
	_spawn_weapon(weapon_id)

func get_weapon_nodes() -> Array:
	return weapon_pivot.get_children()
