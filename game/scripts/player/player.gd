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
var _animator: Node = null

func _ready() -> void:
	# Desativa colisao fisica com inimigos para evitar ser empurrado
	# Dano por contato e detectado via Area3D (Hitbox do inimigo)
	collision_mask = 0
	is_local = not MultiplayerManager.is_online or (player_id == MultiplayerManager.local_player_id)

	# Modelo procedural do personagem
	var char_data = CharacterDB.get_character(GameManager.selected_character)
	if not char_data.is_empty():
		original_color = char_data.get("color", original_color)
	var model = ModelFactory.get_model_for_character(GameManager.selected_character)
	if model.get_child_count() > 0:
		mesh.visible = false
		model.name = "ProceduralModel"
		add_child(model)
		ModelFactory.apply_model_materials(model, original_color)
	else:
		VisualSetup.apply_cel_shader_to_mesh(mesh, original_color)

	# Arma inicial e configurada pelo stage_cemetery.gd
	# Se nenhuma arma foi setada (fallback), usa katana
	if GameManager.player_weapons.is_empty():
		GameManager.add_weapon("katana")
		_spawn_weapon("katana")

	# Procedural animation
	var proc_model = get_node_or_null("ProceduralModel")
	if proc_model:
		_animator = preload("res://scripts/effects/procedural_animator.gd").new()
		_animator.setup(proc_model)
		add_child(_animator)

	# Player aura
	var aura_script = preload("res://scripts/effects/player_aura.gd")
	var aura = MeshInstance3D.new()
	aura.set_script(aura_script)
	aura.base_color = Color(original_color.r, original_color.g, original_color.b, 0.15)
	add_child(aura)

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
			AudioManager.play_sfx("dash")

	move_and_slide()

	# Update procedural animation
	if _animator:
		_animator.set_walking(velocity.length() > 0.5)

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
	if _animator:
		_animator.play_hit()
	GameManager.take_damage(amount)
	can_be_hurt = false
	hurt_cooldown = 0.5
	# Flash vermelho
	_set_color(Color(1, 0.2, 0.2))
	hurt_flash_timer = 0.12

func _set_color(color: Color) -> void:
	var proc_model = get_node_or_null("ProceduralModel")
	if proc_model:
		if color.is_equal_approx(original_color):
			ModelFactory.apply_model_materials(proc_model, original_color)
			return
		for child in proc_model.get_children():
			if child is MeshInstance3D and child.material_override is ShaderMaterial:
				child.material_override.set_shader_parameter("albedo_color", color)
		return
	var mat = mesh.material_override
	if mat is ShaderMaterial:
		mat.set_shader_parameter("albedo_color", color)

var weapon_scenes: Dictionary = {
	"katana": preload("res://scenes/weapons/katana.tscn"),
	"staff": preload("res://scenes/weapons/staff.tscn"),
	"scythe": preload("res://scenes/weapons/scythe.tscn"),
	"machinegun": preload("res://scenes/weapons/machinegun.tscn"),
	"bazooka": preload("res://scenes/weapons/bazooka.tscn"),
	"necro": preload("res://scenes/weapons/necro.tscn"),
	"axe": preload("res://scenes/weapons/axe.tscn"),
	"shuriken": preload("res://scenes/weapons/shuriken.tscn"),
	"drone": preload("res://scenes/weapons/drone.tscn"),
	"totem": preload("res://scenes/weapons/totem.tscn"),
	"poison_bottle": preload("res://scenes/weapons/poison_bottle.tscn"),
	"lightning_chain": preload("res://scenes/weapons/lightning_chain.tscn"),
	"magic_book": preload("res://scenes/weapons/magic_book.tscn"),
	"whip": preload("res://scenes/weapons/whip.tscn"),
	"lance": preload("res://scenes/weapons/lance.tscn"),
	"hammer": preload("res://scenes/weapons/hammer.tscn"),
	"nunchaku": preload("res://scenes/weapons/nunchaku.tscn"),
	"dual_katana": preload("res://scenes/weapons/dual_katana.tscn"),
	"dual_pistol": preload("res://scenes/weapons/dual_pistol.tscn"),
	"flamethrower": preload("res://scenes/weapons/flamethrower.tscn"),
	"ice_staff": preload("res://scenes/weapons/ice_staff.tscn"),
	"crossbow": preload("res://scenes/weapons/crossbow.tscn"),
	"plasma_cannon": preload("res://scenes/weapons/plasma_cannon.tscn"),
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
