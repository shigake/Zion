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

	# Character data
	var char_data = CharacterDB.get_character(GameManager.selected_character)
	if not char_data.is_empty():
		original_color = char_data.get("color", original_color)

	# Sprite billboard do personagem (prioridade sobre modelo procedural)
	var char_sprite_path = "res://assets/sprites/characters/%s.png" % GameManager.selected_character
	if ResourceLoader.exists(char_sprite_path):
		mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(char_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.04
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "PlayerSprite"
		sprite.position.y = 0.65
		add_child(sprite)
	else:
		# Fallback: modelo procedural
		var model = ModelFactory.get_model_for_character(GameManager.selected_character)
		if model.get_child_count() > 0:
			mesh.visible = false
			model.name = "ProceduralModel"
			add_child(model)
			ModelFactory.apply_model_materials(model, original_color)
		else:
			VisualSetup.apply_cel_shader_to_mesh(mesh, original_color)

	# Arma inicial e configurada pelo base_stage via CharacterDB.
	# Fallback: usa a arma inicial do personagem selecionado (ou katana se nao encontrar).
	if GameManager.player_weapons.is_empty():
		var start_weapon = "katana"
		if not char_data.is_empty() and "starting_weapon" in char_data:
			start_weapon = char_data["starting_weapon"]
		GameManager.add_weapon(start_weapon)
		_spawn_weapon(start_weapon)

	# Procedural animation (only when using procedural model fallback)
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

	# Clamp position to map boundaries
	var half = GameManager.map_half_size
	global_position.x = clampf(global_position.x, -half, half)
	global_position.z = clampf(global_position.z, -half, half)

	# Right stick aiming (controller)
	var aim_input = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	if aim_input.length() > 0.3:  # Dead zone
		GameManager.manual_aim = true
		GameManager.aim_direction = Vector3(aim_input.x, 0, aim_input.y).normalized()
	else:
		# Mouse aiming — project mouse onto ground plane
		var camera = get_viewport().get_camera_3d()
		if camera:
			var mouse_pos = get_viewport().get_mouse_position()
			var from = camera.project_ray_origin(mouse_pos)
			var dir = camera.project_ray_normal(mouse_pos)
			# Intersect with Y=0 plane
			if abs(dir.y) > 0.001:
				var t = -from.y / dir.y
				if t > 0:
					var ground_point = from + dir * t
					var aim_vec = ground_point - global_position
					aim_vec.y = 0
					if aim_vec.length() > 0.5:
						GameManager.manual_aim = true
						GameManager.aim_direction = aim_vec.normalized()
					else:
						GameManager.manual_aim = false
						GameManager.aim_direction = Vector3.ZERO
				else:
					GameManager.manual_aim = false
					GameManager.aim_direction = Vector3.ZERO
			else:
				GameManager.manual_aim = false
				GameManager.aim_direction = Vector3.ZERO
		else:
			GameManager.manual_aim = false
			GameManager.aim_direction = Vector3.ZERO

	# Update procedural animation
	if _animator:
		_animator.set_walking(velocity.length() > 0.5)
		_animator.set_move_direction(move_direction)

	# Sync posicao no multiplayer
	if MultiplayerManager.is_online:
		_sync_position.rpc(global_position)

@rpc("any_peer", "unreliable")
func _sync_position(pos: Vector3) -> void:
	if not is_local:
		# Registra posição no histórico para interpolação suave
		MultiplayerManager.register_remote_position(player_id, pos)
		# Usa interpolação preditiva para reduzir jitter
		global_position = MultiplayerManager.get_interpolated_position(player_id, global_position)

func take_damage(amount: int, source_pos: Vector3 = Vector3.ZERO) -> void:
	if not can_be_hurt or is_dashing:
		return
	if _animator:
		_animator.play_hit()
	GameManager.take_damage(amount)
	can_be_hurt = false
	hurt_cooldown = 0.5
	# Flash vermelho no mesh
	_set_color(Color(1, 0.2, 0.2))
	hurt_flash_timer = 0.12
	# Full damage feedback (shake, flash, freeze, indicator, vibration)
	ScreenEffects.damage_feedback(amount, source_pos)

func _set_color(color: Color) -> void:
	var sprite = get_node_or_null("PlayerSprite")
	if sprite:
		if color == original_color:
			sprite.modulate = Color.WHITE
		else:
			sprite.modulate = Color(10, 10, 10)  # Bright flash for damage
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
	"cloud_sword": preload("res://scenes/weapons/cloud_sword.tscn"),
	"elven_bow": preload("res://scenes/weapons/elven_bow.tscn"),
	"boxing_gloves": preload("res://scenes/weapons/boxing_gloves.tscn"),
	"time_bomb": preload("res://scenes/weapons/time_bomb.tscn"),
	"portal_weapon": preload("res://scenes/weapons/portal_weapon.tscn"),
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
