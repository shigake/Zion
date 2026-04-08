extends CharacterBody3D

## Jogador 3D top-down. Movimento, dash, vida. Suporta multiplayer.

@export var base_speed: float = GameConstants.PLAYER_BASE_SPEED
@export var player_id: int = 1  # peer_id no multiplayer
@export var dash_speed: float = GameConstants.PLAYER_DASH_SPEED
@export var dash_duration: float = GameConstants.PLAYER_DASH_DURATION
@export var dash_cooldown: float = GameConstants.PLAYER_DASH_COOLDOWN

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
var _footstep_timer: float = 0.0
var _dust_timer: float = 0.0

# Walk animation state
var _walk_phase: float = 0.0  # Continuous phase for smooth bob cycle
var _prev_bob_y: float = 0.0  # Previous bob height to detect landing
var _landing_squash: float = 0.0  # Current squash amount (decays over time)
var _sprite_base_scale: Vector3 = Vector3.ONE  # Stored after sprite creation

# ---- Emote System ----
var _emote_wheel_open: bool = false
var _emote_label: Label3D = null
var _emote_timer: float = 0.0

# World HP bar
var _world_hp_bar: MeshInstance3D = null
var _world_hp_bg: MeshInstance3D = null

# World XP bar
var _world_xp_bar: MeshInstance3D = null
var _world_xp_bg: MeshInstance3D = null
var _world_xp_y: float = 0.0

var _hp_bar_target_ratio: float = 1.0
var _xp_bar_target_ratio: float = 0.0
const BAR_LERP_SPEED: float = 8.0
# Highlight meshes
var _world_hp_highlight: MeshInstance3D = null
var _world_xp_highlight: MeshInstance3D = null

# Barrier walls (4 edges)
var _barrier_walls: Array[MeshInstance3D] = []

func _ready() -> void:
	# Desativa colisao fisica com inimigos para evitar ser empurrado
	# Dano por contato e detectado via Area3D (Hitbox do inimigo)
	collision_mask = 0
	is_local = not MultiplayerManager.is_online or (player_id == MultiplayerManager.local_player_id)

	# Character data
	var char_data = CharacterDB.get_character(GameManager.selected_character)
	if not char_data.is_empty():
		original_color = char_data.get("color", original_color)

	# Character visual — try 3D model first, then sprite billboard, then procedural
	var char_id = GameManager.selected_character
	var char_model_path = "res://assets/models/characters/%s.glb" % char_id
	var char_sprite_path = "res://assets/sprites/characters/%s.png" % char_id
	if ResourceLoader.exists(char_model_path):
		# Priority 1: imported 3D model
		var model_scene = load(char_model_path)
		if model_scene:
			mesh.visible = false
			var char_model = model_scene.instantiate()
			char_model.name = "PlayerSprite"
			char_model.scale = Vector3(0.45, 0.45, 0.45)
			char_model.position.y = 0.25
			# Apply character-colored material (Hunyuan3D models have no textures)
			var char_mat = StandardMaterial3D.new()
			char_mat.albedo_color = original_color
			char_mat.roughness = 0.3
			char_mat.metallic = 0.2
			char_mat.emission_enabled = true
			char_mat.emission = original_color
			char_mat.emission_energy_multiplier = 1.2
			char_mat.rim_enabled = true
			char_mat.rim = 0.5
			char_mat.rim_tint = 0.3
			for c in char_model.get_children():
				if c is MeshInstance3D:
					c.material_override = char_mat
				for gc in c.get_children():
					if gc is MeshInstance3D:
						gc.material_override = char_mat
			add_child(char_model)
			_sprite_base_scale = char_model.scale
	elif ResourceLoader.exists(char_sprite_path):
		# Priority 2: static Sprite3D billboard
		mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(char_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = GameConstants.PLAYER_SPRITE_PIXEL_SIZE
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "PlayerSprite"
		sprite.position.y = GameConstants.PLAYER_SPRITE_Y_OFFSET
		add_child(sprite)
		_sprite_base_scale = sprite.scale
	else:
		# Priority 3: modelo procedural
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

	# World-space HP bar (pequena, abaixo do sprite)
	_create_world_hp_bar()
	_create_world_xp_bar()

	# Player aura
	var aura_script = preload("res://scripts/effects/player_aura.gd")
	var aura = MeshInstance3D.new()
	aura.set_script(aura_script)
	aura.base_color = Color(original_color.r, original_color.g, original_color.b, 0.15)
	add_child(aura)

	# Emote label (billboard text above player)
	_emote_label = Label3D.new()
	_emote_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_emote_label.pixel_size = 0.01
	_emote_label.font_size = 32
	_emote_label.outline_size = 4
	_emote_label.modulate = Color(1, 1, 0.8)
	_emote_label.position = Vector3(0, 2.0, 0)
	_emote_label.visible = false
	add_child(_emote_label)

	# Listen for emotes from other players
	if MultiplayerManager.has_signal("emote_received"):
		MultiplayerManager.emote_received.connect(_on_emote_received)

	# Barrier walls — 4 paredes vermelhas translucidas nas bordas do mapa
	# Wait 2 frames so global_position and scene tree are fully set up
	await get_tree().process_frame
	await get_tree().process_frame
	_create_barrier_walls()

func _create_world_hp_bar() -> void:
	# Barra verde de HP embaixo do sprite do jogador (world-space)
	var bar_width = 1.6
	var bar_height = 0.48
	var bar_y = 0.05  # Bem rente ao chao, abaixo do sprite
	var bar_z = 0.5   # Levemente a frente para nao ficar atras do personagem

	# Outer border (preto solido para contraste)
	var _world_hp_border = MeshInstance3D.new()
	var border_mesh = QuadMesh.new()
	border_mesh.size = Vector2(bar_width + 0.16, bar_height + 0.08)
	_world_hp_border.mesh = border_mesh
	var border_mat = StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.05, 0.35, 0.05, 0.95)
	border_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	border_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	border_mat.no_depth_test = true
	border_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	border_mat.render_priority = 10
	_world_hp_border.material_override = border_mat
	_world_hp_border.position = Vector3(0, bar_y, bar_z - 0.002)
	add_child(_world_hp_border)

	# Background (cinza escuro)
	_world_hp_bg = MeshInstance3D.new()
	var bg_mesh = QuadMesh.new()
	bg_mesh.size = Vector2(bar_width + 0.06, bar_height + 0.02)
	_world_hp_bg.mesh = bg_mesh
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.15, 0.15, 0.15, 0.9)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.no_depth_test = true
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	bg_mat.render_priority = 11
	_world_hp_bg.material_override = bg_mat
	_world_hp_bg.position = Vector3(0, bar_y, bar_z - 0.001)
	add_child(_world_hp_bg)

	# Fill (verde)
	_world_hp_bar = MeshInstance3D.new()
	var fill_mesh = QuadMesh.new()
	fill_mesh.size = Vector2(bar_width, bar_height)
	_world_hp_bar.mesh = fill_mesh
	var fill_mat = StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.2, 0.85, 0.2)
	fill_mat.emission_enabled = true
	fill_mat.emission = Color(0.1, 0.6, 0.1)
	fill_mat.emission_energy_multiplier = 0.6
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.no_depth_test = true
	fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	fill_mat.render_priority = 12
	_world_hp_bar.material_override = fill_mat
	_world_hp_bar.position = Vector3(0, bar_y, bar_z)
	add_child(_world_hp_bar)

	# Highlight (glossy strip)
	_world_hp_highlight = MeshInstance3D.new()
	var hl_mesh := QuadMesh.new()
	hl_mesh.size = Vector2(bar_width - 0.1, bar_height * 0.22)
	_world_hp_highlight.mesh = hl_mesh
	var hl_mat := StandardMaterial3D.new()
	hl_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.18)
	hl_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hl_mat.no_depth_test = true
	hl_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	hl_mat.render_priority = 13
	_world_hp_highlight.material_override = hl_mat
	_world_hp_highlight.position = Vector3(0, bar_y + bar_height * 0.28, bar_z + 0.001)
	add_child(_world_hp_highlight)

func _update_world_hp_bar(delta: float) -> void:
	if not _world_hp_bar or not _world_hp_bg:
		return
	const BAR_W: float = 1.6
	var max_hp = GameManager.get_effective_max_hp()
	_hp_bar_target_ratio = clampf(float(GameManager.player_hp) / float(max_hp), 0.0, 1.0) if max_hp > 0 else 1.0
	var fill_mesh := _world_hp_bar.mesh as QuadMesh
	var current_ratio := fill_mesh.size.x / BAR_W
	var new_ratio := lerpf(current_ratio, _hp_bar_target_ratio, BAR_LERP_SPEED * delta)
	fill_mesh.size.x = BAR_W * new_ratio
	# Ancora borda esquerda em -0.8: centro = -0.8 + metade_width
	_world_hp_bar.position.x = -BAR_W / 2.0 + (BAR_W * new_ratio) / 2.0
	# Highlight acompanha o fill
	if _world_hp_highlight:
		var hl_mesh := _world_hp_highlight.mesh as QuadMesh
		hl_mesh.size.x = maxf((BAR_W - 0.1) * new_ratio, 0.0)
		_world_hp_highlight.position.x = _world_hp_bar.position.x

func _create_world_xp_bar() -> void:
	var bar_width: float = 1.6
	var bar_height: float = 0.48
	var gap: float = 0.06
	var xp_y: float = 0.05 - bar_height - gap
	var bar_z: float = 0.5

	# Border (black)
	var xp_border := MeshInstance3D.new()
	var border_mesh := QuadMesh.new()
	border_mesh.size = Vector2(bar_width + 0.16, bar_height + 0.08)
	xp_border.mesh = border_mesh
	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.03, 0.10, 0.30, 0.95)
	border_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	border_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	border_mat.no_depth_test = true
	border_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	border_mat.render_priority = 10
	xp_border.material_override = border_mat
	xp_border.position = Vector3(0, xp_y, bar_z - 0.002)
	add_child(xp_border)

	# Background (dark gray)
	_world_xp_bg = MeshInstance3D.new()
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(bar_width + 0.06, bar_height + 0.02)
	_world_xp_bg.mesh = bg_mesh
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.08, 0.12, 0.22, 0.9)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.no_depth_test = true
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	bg_mat.render_priority = 11
	_world_xp_bg.material_override = bg_mat
	_world_xp_bg.position = Vector3(0, xp_y, bar_z - 0.001)
	add_child(_world_xp_bg)

	# Fill (crystal purple)
	_world_xp_bar = MeshInstance3D.new()
	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(bar_width, bar_height)
	_world_xp_bar.mesh = fill_mesh
	var fill_mat := StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.15, 0.55, 0.95)
	fill_mat.emission_enabled = true
	fill_mat.emission = Color(0.05, 0.3, 0.7)
	fill_mat.emission_energy_multiplier = 0.5
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.no_depth_test = true
	fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	fill_mat.render_priority = 12
	_world_xp_bar.material_override = fill_mat
	# Começa vazia: borda esquerda em -bar_width/2, mesh com largura 0
	(fill_mesh as QuadMesh).size.x = 0.0
	_world_xp_bar.position = Vector3(-bar_width / 2.0, xp_y, bar_z)
	add_child(_world_xp_bar)

	# Highlight (glossy strip)
	_world_xp_highlight = MeshInstance3D.new()
	var hl_mesh := QuadMesh.new()
	hl_mesh.size = Vector2(0.0, bar_height * 0.22)
	_world_xp_highlight.mesh = hl_mesh
	var hl_mat := StandardMaterial3D.new()
	hl_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.18)
	hl_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hl_mat.no_depth_test = true
	hl_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	hl_mat.render_priority = 13
	_world_xp_highlight.material_override = hl_mat
	_world_xp_highlight.position = Vector3(-bar_width / 2.0, xp_y + bar_height * 0.28, bar_z + 0.001)
	add_child(_world_xp_highlight)

	_world_xp_y = xp_y

func _update_world_xp_bar(delta: float) -> void:
	if not _world_xp_bar:
		return
	const BAR_W: float = 1.6
	_xp_bar_target_ratio = clampf(
		float(GameManager.player_xp) / float(GameManager.player_xp_to_next),
		0.0, 1.0
	) if GameManager.player_xp_to_next > 0 else 0.0
	var xp_fill_mesh := _world_xp_bar.mesh as QuadMesh
	var current_ratio := xp_fill_mesh.size.x / BAR_W if BAR_W > 0.0 else 0.0
	var new_ratio := lerpf(current_ratio, _xp_bar_target_ratio, BAR_LERP_SPEED * delta)
	xp_fill_mesh.size.x = BAR_W * new_ratio
	# Ancora borda esquerda em -0.8: centro = -0.8 + metade_width
	_world_xp_bar.position.x = -BAR_W / 2.0 + (BAR_W * new_ratio) / 2.0
	# XP highlight acompanha o fill
	if _world_xp_highlight:
		var hl_mesh := _world_xp_highlight.mesh as QuadMesh
		hl_mesh.size.x = maxf((BAR_W - 0.1) * new_ratio, 0.0)
		_world_xp_highlight.position.x = _world_xp_bar.position.x

func _physics_process(delta: float) -> void:
	_update_world_hp_bar(delta)
	_update_world_xp_bar(delta)
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
		var speed = base_speed * GameManager.perm_speed_mult * GameManager.speed_mult
		velocity = move_direction * speed

		# Trigger dash
		if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and move_direction.length() > 0.1:
			is_dashing = true
			dash_timer = dash_duration
			dash_cooldown_timer = dash_cooldown
			dash_direction = move_direction.normalized()
			GameManager.dash_count += 1
			AudioManager.play_sfx("dash")

	move_and_slide()

	# Footstep SFX
	if velocity.length() > GameConstants.PLAYER_MOVEMENT_THRESHOLD:
		_footstep_timer += delta
		if _footstep_timer > GameConstants.PLAYER_FOOTSTEP_INTERVAL:
			_footstep_timer = 0.0
			AudioManager.play_sfx("footstep")
	else:
		_footstep_timer = 0.0

	# Dust particles when walking (only when FPS > 40)
	if velocity.length() > 1.0 and Engine.get_frames_per_second() > GameConstants.PLAYER_DUST_MIN_FPS:
		_dust_timer += delta
		if _dust_timer > GameConstants.PLAYER_DUST_INTERVAL:
			_dust_timer = 0.0
			_spawn_dust()
	else:
		_dust_timer = 0.0

	# Clamp position to map boundaries
	var half = GameManager.map_half_size
	global_position.x = clampf(global_position.x, -half, half)
	global_position.z = clampf(global_position.z, -half, half)

	# Update barrier walls visibility
	_update_barrier_walls()

	# All weapons auto-aim at nearest enemy (no mouse/stick aiming)
	GameManager.manual_aim = false
	GameManager.aim_direction = Vector3.ZERO

	# Update walk animation (AnimatedSprite3D)
	var _anim_sprite = get_node_or_null("PlayerSprite")
	if _anim_sprite and _anim_sprite is AnimatedSprite3D:
		if velocity.length() > GameConstants.PLAYER_MOVEMENT_THRESHOLD:
			if _anim_sprite.animation != "walk":
				_anim_sprite.play("walk")
		else:
			if _anim_sprite.animation != "idle":
				_anim_sprite.play("idle")

	# Enhanced walk animation on sprite or 3D model (bob + lean + squash-stretch + flip + idle breathing)
	var player_sprite = get_node_or_null("PlayerSprite")
	if player_sprite and (player_sprite is Sprite3D or player_sprite is Node3D):
		var spd = velocity.length()
		if spd > GameConstants.PLAYER_MOVEMENT_THRESHOLD:
			# Advance walk phase based on actual speed for natural rhythm
			_walk_phase += delta * (GameConstants.WALK_BOB_BASE_FREQ + spd * GameConstants.WALK_BOB_SPEED_FACTOR)

			# Smooth vertical bob using sin (full cycle = 2*PI)
			var bob_val = abs(sin(_walk_phase))
			var bob_height = bob_val * GameConstants.WALK_BOB_AMPLITUDE
			player_sprite.position.y = GameConstants.PLAYER_SPRITE_Y_OFFSET + bob_height

			# Detect landing (bob descending past midpoint) for squash-stretch
			if bob_height < _prev_bob_y and _prev_bob_y > GameConstants.WALK_LANDING_THRESHOLD:
				_landing_squash = GameConstants.WALK_LANDING_SQUASH  # Trigger subtle squash on landing
			_prev_bob_y = bob_height

			# Face movement direction
			if player_sprite is Sprite3D:
				if move_direction.x > 0.1:
					player_sprite.flip_h = false
				elif move_direction.x < -0.1:
					player_sprite.flip_h = true
			else:
				# 3D model: rotate Y to face movement
				if move_direction.length() > 0.1:
					var target_angle = atan2(-move_direction.x, -move_direction.z)
					player_sprite.rotation.y = lerp_angle(player_sprite.rotation.y, target_angle, delta * 10.0)

			# Horizontal lean: tilt sprite slightly in movement direction
			var lean_target = -move_direction.x * GameConstants.WALK_LEAN_FACTOR  # Lean into movement (radians)
			player_sprite.rotation.z = lerp(player_sprite.rotation.z, lean_target, delta * GameConstants.WALK_LEAN_LERP_SPEED)

			# Squash-stretch on landing (decay smoothly)
			if _landing_squash > 0.001:
				var sq = _landing_squash
				player_sprite.scale = Vector3(
					_sprite_base_scale.x * (1.0 + sq),
					_sprite_base_scale.y * (1.0 - sq),
					_sprite_base_scale.z
				)
				_landing_squash = lerp(_landing_squash, 0.0, delta * GameConstants.WALK_SQUASH_DECAY_SPEED)
			else:
				player_sprite.scale = _sprite_base_scale
		else:
			# Idle: gentle breathing / floating effect
			var breath = sin(GameManager.game_time * GameConstants.IDLE_BREATH_FREQ) * GameConstants.IDLE_BREATH_AMPLITUDE
			player_sprite.position.y = GameConstants.PLAYER_SPRITE_Y_OFFSET + breath

			# Subtle idle scale pulse (breathing)
			var breath_scale = sin(GameManager.game_time * GameConstants.IDLE_BREATH_FREQ) * GameConstants.IDLE_BREATH_SCALE
			player_sprite.scale = Vector3(
				_sprite_base_scale.x * (1.0 - breath_scale * 0.5),
				_sprite_base_scale.y * (1.0 + breath_scale),
				_sprite_base_scale.z
			)

			# Smoothly return lean to neutral
			player_sprite.rotation.z = lerp(player_sprite.rotation.z, 0.0, delta * GameConstants.IDLE_LEAN_RETURN_SPEED)

			# Reset walk state
			_prev_bob_y = 0.0
			_landing_squash = 0.0

	# Update procedural animation
	if _animator:
		_animator.set_walking(velocity.length() > GameConstants.PLAYER_MOVEMENT_THRESHOLD)
		_animator.set_move_direction(move_direction)

	# Emote timer
	if _emote_timer > 0:
		_emote_timer -= delta
		if _emote_timer <= 0 and _emote_label:
			_emote_label.visible = false

	# Emote wheel (T key)
	if is_local and InputMap.has_action("emote") and Input.is_action_just_pressed("emote"):
		_toggle_emote_wheel()

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
	GameManager._last_damage_source_pos = source_pos
	GameManager.take_damage(amount)
	GameManager._last_damage_source_pos = Vector3.ZERO
	can_be_hurt = false
	hurt_cooldown = GameConstants.PLAYER_HURT_COOLDOWN
	# Flash vermelho no mesh
	_set_color(Color(1, 0.2, 0.2))
	hurt_flash_timer = GameConstants.PLAYER_HURT_FLASH_DURATION
	# Red flash + squash-stretch on sprite
	var sprite = get_node_or_null("PlayerSprite")
	if sprite:
		sprite.modulate = GameConstants.PLAYER_HIT_FLASH_COLOR
		var orig_scale = sprite.scale
		sprite.scale = Vector3(orig_scale.x * GameConstants.PLAYER_HIT_SQUASH_X, orig_scale.y * GameConstants.PLAYER_HIT_SQUASH_Y, orig_scale.z)
		var hit_tween = create_tween()
		hit_tween.set_parallel(true)
		hit_tween.tween_property(sprite, "modulate", Color.WHITE, GameConstants.PLAYER_HIT_FLASH_FADE)
		hit_tween.tween_property(sprite, "scale", orig_scale, GameConstants.PLAYER_HIT_SQUASH_FADE).set_trans(Tween.TRANS_ELASTIC)
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
	"shadow_claw": preload("res://scenes/weapons/shadow_claw.tscn"),
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
	"boomerang": preload("res://scenes/weapons/boomerang.tscn"),
	"tornado": preload("res://scenes/weapons/tornado.tscn"),
	"chain_whip": preload("res://scenes/weapons/chain_whip.tscn"),
	"blood_orb": preload("res://scenes/weapons/blood_orb.tscn"),
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

func _spawn_dust() -> void:
	if not is_inside_tree():
		return
	var dust = Sprite3D.new()
	# Small white-gray dot
	var img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.6, 0.55, 0.5, 0.4))
	dust.texture = ImageTexture.create_from_image(img)
	dust.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dust.pixel_size = GameConstants.SPRITE_PIXEL_SIZE_SMALL
	dust.shaded = false
	dust.transparent = true
	dust.position = global_position + Vector3(randf_range(-0.2, 0.2), 0.1, randf_range(-0.2, 0.2))
	get_tree().current_scene.add_child(dust)
	var tw = dust.create_tween()
	tw.tween_property(dust, "modulate:a", 0.0, 0.3)
	tw.tween_callback(dust.queue_free)

func _create_barrier_walls() -> void:
	if not is_inside_tree():
		return
	var half = GameManager.map_half_size
	var wall_length = half * 2.0 + 4.0  # um pouco maior que o mapa

	# Shader para efeito de barreira com gradiente e pulso
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform float alpha : hint_range(0.0, 1.0) = 0.0;
uniform float time_offset = 0.0;

void fragment() {
	// Gradiente vertical: mais forte na base, some no topo
	float grad = 1.0 - UV.y;
	grad = grad * grad;

	// Linhas horizontais animadas (tipo campo de forca)
	float lines = sin((UV.y * 40.0) + TIME * 3.0 + time_offset) * 0.5 + 0.5;
	lines = lines * 0.3 + 0.7;

	// Pulso suave
	float pulse = sin(TIME * 2.0 + time_offset) * 0.15 + 0.85;

	ALBEDO = vec3(1.0, 0.1, 0.05);
	ALPHA = grad * lines * pulse * alpha * 0.6;
}
"""

	# 4 paredes: +X, -X, +Z, -Z
	# QuadMesh default: plano XY (spana eixo X). rot=PI/2 gira para spanar eixo Z.
	var configs = [
		{"pos": Vector3(half, GameConstants.BARRIER_WALL_HEIGHT * 0.5, 0), "rot": PI * 0.5, "len": wall_length},   # +X (leste) — perpendicular ao X
		{"pos": Vector3(-half, GameConstants.BARRIER_WALL_HEIGHT * 0.5, 0), "rot": PI * 0.5, "len": wall_length},  # -X (oeste) — perpendicular ao X
		{"pos": Vector3(0, GameConstants.BARRIER_WALL_HEIGHT * 0.5, half), "rot": 0.0, "len": wall_length},        # +Z (sul) — perpendicular ao Z
		{"pos": Vector3(0, GameConstants.BARRIER_WALL_HEIGHT * 0.5, -half), "rot": 0.0, "len": wall_length},       # -Z (norte) — perpendicular ao Z
	]

	for i in range(configs.size()):
		var cfg = configs[i]
		var wall = MeshInstance3D.new()
		var quad = QuadMesh.new()
		quad.size = Vector2(cfg["len"], GameConstants.BARRIER_WALL_HEIGHT)
		wall.mesh = quad

		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("alpha", 0.0)
		mat.set_shader_parameter("time_offset", float(i) * 1.5)
		wall.material_override = mat

		wall.position = cfg["pos"]
		if cfg["rot"] != 0.0:
			wall.rotation.y = cfg["rot"]

		wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wall.name = "BarrierWall_%d" % i
		wall.visible = false
		get_tree().current_scene.call_deferred("add_child", wall)
		_barrier_walls.append(wall)

# ---- Emote System ----

func _toggle_emote_wheel() -> void:
	if _emote_wheel_open:
		_close_emote_wheel()
		return
	_emote_wheel_open = true
	# Create a simple radial menu as a CanvasLayer overlay
	var canvas = CanvasLayer.new()
	canvas.name = "EmoteWheel"
	canvas.layer = 100
	add_child(canvas)

	var center_screen = get_viewport().get_visible_rect().size / 2.0
	var radius = GameConstants.PLAYER_EMOTE_WHEEL_RADIUS

	for i in range(MultiplayerManager.EMOTE_LIST.size()):
		var angle = (i / float(MultiplayerManager.EMOTE_LIST.size())) * TAU - PI / 2.0
		var btn = Button.new()
		btn.text = MultiplayerManager.EMOTE_LIST[i]
		btn.custom_minimum_size = Vector2(80, 30)
		btn.position = center_screen + Vector2(cos(angle), sin(angle)) * radius - Vector2(40, 15)
		btn.pressed.connect(_send_emote.bind(i))
		canvas.add_child(btn)

	# Close button in center
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.position = center_screen - Vector2(15, 15)
	close_btn.pressed.connect(_close_emote_wheel)
	canvas.add_child(close_btn)

func _close_emote_wheel() -> void:
	_emote_wheel_open = false
	var wheel = get_node_or_null("EmoteWheel")
	if wheel:
		wheel.queue_free()

func _send_emote(emote_id: int) -> void:
	_close_emote_wheel()
	MultiplayerManager.send_emote(emote_id)
	_show_emote(emote_id)

func _on_emote_received(peer_id: int, emote_id: int) -> void:
	if peer_id == player_id:
		_show_emote(emote_id)

func _show_emote(emote_id: int) -> void:
	if not _emote_label:
		return
	if emote_id < 0 or emote_id >= MultiplayerManager.EMOTE_LIST.size():
		return
	_emote_label.text = MultiplayerManager.EMOTE_LIST[emote_id]
	_emote_label.visible = true
	_emote_timer = GameConstants.PLAYER_EMOTE_DURATION
	# Pop animation
	_emote_label.scale = Vector3(0.5, 0.5, 0.5)
	var tw = create_tween()
	tw.tween_property(_emote_label, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_barrier_walls() -> void:
	if _barrier_walls.is_empty():
		return

	var half = GameManager.map_half_size
	var px = global_position.x
	var pz = global_position.z

	# Distancias ate cada borda
	var dists = [
		half - px,     # +X (leste)
		half + px,     # -X (oeste)
		half - pz,     # +Z (sul)
		half + pz,     # -Z (norte)
	]

	for i in range(4):
		if i >= _barrier_walls.size():
			break
		var wall = _barrier_walls[i]
		if not is_instance_valid(wall):
			continue
		var dist = dists[i]
		if dist < GameConstants.BARRIER_SHOW_DIST:
			var alpha = 1.0 - (dist / GameConstants.BARRIER_SHOW_DIST)
			alpha = alpha * alpha  # easing quadratico — mais forte perto da borda
			wall.visible = true
			var mat = wall.material_override as ShaderMaterial
			if mat:
				mat.set_shader_parameter("alpha", alpha)
			# Reposiciona a parede para acompanhar o jogador no eixo perpendicular
			if i <= 1:  # paredes X — seguem no Z
				wall.global_position.z = pz
			else:  # paredes Z — seguem no X
				wall.global_position.x = px
		else:
			wall.visible = false
