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

# Barrier walls (4 edges)
var _barrier_walls: Array[MeshInstance3D] = []
const BARRIER_SHOW_DIST: float = 12.0  # distancia para comecar a mostrar
const BARRIER_WALL_HEIGHT: float = 6.0
const BARRIER_WALL_THICKNESS: float = 0.3

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
	var char_id = GameManager.selected_character
	var walk_sprite_path = "res://assets/sprites/characters/%s_walk.png" % char_id
	var char_sprite_path = "res://assets/sprites/characters/%s.png" % char_id
	if ResourceLoader.exists(walk_sprite_path):
		# Walk spritesheet available — use AnimatedSprite3D
		mesh.visible = false
		var anim_sprite = AnimatedSprite3D.new()
		var frames = SpriteFrames.new()
		var walk_tex = load(walk_sprite_path) as Texture2D

		# "walk" animation: 4 frames (0,1,2,3)
		frames.add_animation("walk")
		frames.set_animation_speed("walk", 8)
		frames.set_animation_loop("walk", true)
		for i in range(4):
			var atlas = AtlasTexture.new()
			atlas.atlas = walk_tex
			atlas.region = Rect2(i * 32, 0, 32, 32)
			frames.add_frame("walk", atlas)

		# "idle" animation: frames 0 and 2 (both are the neutral stance)
		frames.add_animation("idle")
		frames.set_animation_speed("idle", 2)
		frames.set_animation_loop("idle", true)
		for i in [0, 2]:
			var atlas = AtlasTexture.new()
			atlas.atlas = walk_tex
			atlas.region = Rect2(i * 32, 0, 32, 32)
			frames.add_frame("idle", atlas)

		# Remove the auto-created "default" animation
		if frames.has_animation("default"):
			frames.remove_animation("default")

		anim_sprite.sprite_frames = frames
		anim_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		anim_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		anim_sprite.pixel_size = 0.04
		anim_sprite.shaded = false
		anim_sprite.transparent = true
		anim_sprite.name = "PlayerSprite"
		anim_sprite.position.y = 0.65
		anim_sprite.play("idle")
		add_child(anim_sprite)
	elif ResourceLoader.exists(char_sprite_path):
		# Fallback: static Sprite3D
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

	# Barrier walls — 4 paredes vermelhas translucidas nas bordas do mapa
	_create_barrier_walls()

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

	# Update barrier walls visibility
	_update_barrier_walls()

	# All weapons auto-aim at nearest enemy (no mouse/stick aiming)
	GameManager.manual_aim = false
	GameManager.aim_direction = Vector3.ZERO

	# Update walk animation (AnimatedSprite3D)
	var _anim_sprite = get_node_or_null("PlayerSprite")
	if _anim_sprite and _anim_sprite is AnimatedSprite3D:
		if velocity.length() > 0.5:
			if _anim_sprite.animation != "walk":
				_anim_sprite.play("walk")
		else:
			if _anim_sprite.animation != "idle":
				_anim_sprite.play("idle")

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
	# Red flash + squash-stretch on sprite
	var sprite = get_node_or_null("PlayerSprite")
	if sprite:
		sprite.modulate = Color(3, 0.3, 0.3)  # Bright red flash
		var orig_scale = sprite.scale
		sprite.scale = Vector3(orig_scale.x * 1.3, orig_scale.y * 0.7, orig_scale.z)
		var hit_tween = create_tween()
		hit_tween.set_parallel(true)
		hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
		hit_tween.tween_property(sprite, "scale", orig_scale, 0.18).set_trans(Tween.TRANS_ELASTIC)
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
		{"pos": Vector3(half, BARRIER_WALL_HEIGHT * 0.5, 0), "rot": PI * 0.5, "len": wall_length},   # +X (leste) — perpendicular ao X
		{"pos": Vector3(-half, BARRIER_WALL_HEIGHT * 0.5, 0), "rot": PI * 0.5, "len": wall_length},  # -X (oeste) — perpendicular ao X
		{"pos": Vector3(0, BARRIER_WALL_HEIGHT * 0.5, half), "rot": 0.0, "len": wall_length},        # +Z (sul) — perpendicular ao Z
		{"pos": Vector3(0, BARRIER_WALL_HEIGHT * 0.5, -half), "rot": 0.0, "len": wall_length},       # -Z (norte) — perpendicular ao Z
	]

	for i in range(configs.size()):
		var cfg = configs[i]
		var wall = MeshInstance3D.new()
		var quad = QuadMesh.new()
		quad.size = Vector2(cfg["len"], BARRIER_WALL_HEIGHT)
		wall.mesh = quad

		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("alpha", 0.0)
		mat.set_shader_parameter("time_offset", float(i) * 1.5)
		wall.material_override = mat

		wall.global_position = cfg["pos"]
		if cfg["rot"] != 0.0:
			wall.rotation.y = cfg["rot"]

		wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wall.name = "BarrierWall_%d" % i
		wall.visible = false
		get_tree().current_scene.call_deferred("add_child", wall)
		_barrier_walls.append(wall)

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
		if dist < BARRIER_SHOW_DIST:
			var alpha = 1.0 - (dist / BARRIER_SHOW_DIST)
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
