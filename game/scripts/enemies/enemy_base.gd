extends CharacterBody3D
class_name EnemyBase3D

## Inimigo base 3D. Persegue jogador, dano por contato, damage numbers, particulas, knockback.

@export var speed: float = 4.0
@export var max_hp: int = 20
@export var damage: int = 10
@export var xp_drop: int = 1
@export var enemy_color: Color = Color(0.8, 0.2, 0.2)

## Resistencias por tipo de dano. 0.5 = resistente, 1.0 = normal, 1.5 = fraco.
@export var resistances: Dictionary = {}

var hp: int = 20
var target: Node3D = null
var is_dead: bool = false
var knockback_velocity: Vector3 = Vector3.ZERO
var _animator: Node = null
var _hit_count: int = 0
var _flash_tween: Tween = null  # Reuse tween for flash to avoid creating new ones per hit
var _sprite_base_scale: Vector3 = Vector3.ONE  # Original scale, never changes
var _entrance_invincible: bool = false  # Boss entrance invincibility

## Stage behavior system — themed enemies get unique AI
var _behavior: String = ""
var _behavior_timer: float = 0.0
var _behavior_cooldown: float = 0.0
var _ambush_speed: float = 0.0
var _ambush_triggered: bool = false
var _stealth_range: float = 0.0
var _original_speed: float = 0.0
var _charge_dir: Vector3 = Vector3.ZERO
var _is_charging: bool = false
var _frame_counter: int = 0  # Performance: stagger per-enemy work across frames
var _cached_separation: Vector3 = Vector3.ZERO  # Cached separation vector (updated every 3rd frame)
var _cached_enemy_sprite: Node = null  # Cached EnemySprite node reference
var _cached_enemy_sprite_checked: bool = false  # Whether we've looked up the sprite node
var _last_hit_direction: Vector3 = Vector3.ZERO  # PRD 45: direction of last hit for ragdoll
var _cached_boss_aura: Node = null  # Performance: cached BossAura reference
var _boss_aura_checked: bool = false

static var _sprite_cache: Dictionary = {}  # Performance: avoid repeated disk loads for the same sprite
static var _sprite_path_cache: Dictionary = {}  # "type_stage" -> resolved path (avoids ResourceLoader.exists)
## Shared projectile mesh/material — avoid creating new ones every ranged attack
static var _shared_proj_mesh: SphereMesh = null
static var _shared_proj_mat: StandardMaterial3D = null

@onready var mesh: MeshInstance3D = $Mesh
@onready var hitbox: Area3D = $Hitbox

func _ready() -> void:
	# Multiplayer HP scaling
	var hp_mult = GameManager.get_mp_hp_mult()
	max_hp = int(max_hp * hp_mult)
	hp = max_hp
	add_to_group("enemies")
	# Mutation: furious bosses — start at 75% HP (phase 2)
	# Applied after boss subclass _ready() via deferred call
	call_deferred("_apply_furious_boss_mutation")
	# Desativa colisao fisica com player para evitar empurrar o jogador
	# Dano por contato e detectado via Area3D (Hitbox)
	collision_mask = 0
	hitbox.body_entered.connect(_on_body_entered)
	# Substitui mesh simples por sprite billboard (fallback: modelo procedural)
	_apply_sprite()
	# Apply stage-themed behavior if this enemy has a themed skin
	_apply_stage_behavior()

## Pool reuse: restaura estado para inimigos reutilizados do ObjectPool
func _reset_for_reuse() -> void:
	is_dead = false
	hp = max_hp
	_hit_count = 0
	knockback_velocity = Vector3.ZERO
	_last_hit_direction = Vector3.ZERO
	_entrance_invincible = false
	visible = true
	# Restaura collision layer (zerado em _die)
	collision_layer = 2  # Layer 2: Enemies
	collision_mask = 0   # Dano por contato via Area3D, nao fisica
	# Restaura processing (prewarm pode ter desativado)
	set_process(true)
	set_physics_process(true)
	# Restaura hitbox
	if hitbox:
		hitbox.monitoring = true
		hitbox.monitorable = true
		if not hitbox.body_entered.is_connected(_on_body_entered):
			hitbox.body_entered.connect(_on_body_entered)

func _get_base_enemy_type() -> String:
	## Derive the base enemy type from the scene file path, not from `name`
	## which may have been overwritten by stage skins (e.g. "Mushroom Slime").
	## "res://scenes/enemies/slime.tscn" -> "Slime"
	## "res://scenes/enemies/zombie_runner.tscn" -> "ZombieRunner"
	if scene_file_path and not scene_file_path.is_empty():
		var file = scene_file_path.get_file().get_basename()  # e.g. "zombie_runner"
		# Convert snake_case to PascalCase
		var parts = file.split("_")
		var result = ""
		for p in parts:
			if p.length() > 0:
				result += p[0].to_upper() + p.substr(1)
		return result
	return name

func get_bestiary_id() -> String:
	## Returns the bestiary-compatible ID for this enemy.
	## Themed enemies: "cemetery_zombie", Generics: "Slime", Bosses: "BossNecromancer"
	var base_type := _get_base_enemy_type()
	var stage := GameManager.selected_stage
	# Check if this enemy has a themed skin in the current stage
	if STAGE_ENEMY_SPRITES.has(stage):
		var mapping: Dictionary = STAGE_ENEMY_SPRITES[stage]
		if mapping.has(base_type):
			return mapping[base_type]  # e.g. "cemetery_zombie"
	return base_type  # e.g. "Slime" or "BossNecromancer"

func _apply_sprite() -> void:
	var enemy_type = _get_base_enemy_type()
	var is_boss := enemy_type.begins_with("Boss")
	# Always create sprite nodes — MultiMesh will hide them when active but they need
	# to exist for when MultiMesh deactivates or for visual correctness.
	var stage = GameManager.selected_stage
	var cache_key = "%s_%s" % [enemy_type, stage]
	var sprite_path: String
	# Use cached path resolution to avoid repeated ResourceLoader.exists() calls
	if _sprite_path_cache.has(cache_key):
		sprite_path = _sprite_path_cache[cache_key]
		if sprite_path.is_empty():
			_apply_procedural_model()
			return
	else:
		# Resolve path once — try candidates in priority order, stop at first hit
		sprite_path = _resolve_sprite_path(enemy_type, stage)
		_sprite_path_cache[cache_key] = sprite_path
		if sprite_path.is_empty():
			_apply_procedural_model()
			return
	var tex: Texture2D
	if _sprite_cache.has(sprite_path):
		tex = _sprite_cache[sprite_path]
	else:
		tex = load(sprite_path) as Texture2D
		if tex:
			_sprite_cache[sprite_path] = tex
	if tex == null:
		_apply_procedural_model()
		return
	# Hide ALL old visuals
	mesh.visible = false
	for child in get_children():
		if child is MeshInstance3D and child != mesh:
			child.visible = false
	# Static Sprite3D billboard
	var sprite = Sprite3D.new()
	sprite.texture = tex
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = 0.07 if is_boss else 0.05
	sprite.shaded = false
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.name = "EnemySprite"
	sprite.position.y = 0.65
	add_child(sprite)
	_sprite_base_scale = sprite.scale
	# Boss aura glow + floating name label
	if is_boss:
		var aura = Sprite3D.new()
		aura.texture = tex
		aura.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		aura.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		aura.pixel_size = sprite.pixel_size * 1.3
		aura.shaded = false
		aura.transparent = true
		aura.modulate = Color(enemy_color.r, enemy_color.g, enemy_color.b, 0.3)
		aura.name = "BossAura"
		aura.position = sprite.position
		add_child(aura)
		var label = Label3D.new()
		label.text = name.replace("Boss", "").to_upper()
		label.font_size = 24
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = sprite.position + Vector3(0, 1.2, 0)
		label.name = "BossLabel"
		add_child(label)

## Resolve sprite path efficiently — single-pass with minimal ResourceLoader.exists() calls
static func _resolve_sprite_path(enemy_type: String, stage: String) -> String:
	var snake_type = enemy_type.to_snake_case()
	# Priority 1: themed sprite for this stage
	if STAGE_ENEMY_SPRITES.has(stage):
		var stage_map: Dictionary = STAGE_ENEMY_SPRITES[stage]
		if stage_map.has(enemy_type):
			var themed_path = "res://assets/sprites/enemies/%s/%s.png" % [stage, stage_map[enemy_type]]
			if ResourceLoader.exists(themed_path):
				return themed_path
	# Priority 2: generic enemy sprite
	var generic_path = "res://assets/sprites/enemies/%s.png" % snake_type
	if ResourceLoader.exists(generic_path):
		return generic_path
	# Priority 3: boss sprite
	var boss_path = "res://assets/sprites/bosses/%s.png" % snake_type
	if ResourceLoader.exists(boss_path):
		return boss_path
	# Priority 4: fallback slime
	var fallback = "res://assets/sprites/enemies/slime.png"
	if ResourceLoader.exists(fallback):
		return fallback
	return ""

func _apply_stage_behavior() -> void:
	var stage = GameManager.selected_stage
	var enemy_type = _get_base_enemy_type()
	if not STAGE_ENEMY_SPRITES.has(stage):
		return
	var stage_map = STAGE_ENEMY_SPRITES[stage]
	if not stage_map.has(enemy_type):
		return
	var themed_name = stage_map[enemy_type]
	_original_speed = speed
	if EnemyStageBehavior.apply(self, themed_name):
		LogManager.debug("Enemy", "Stage behavior '%s' applied to %s" % [_behavior, themed_name])

func _apply_procedural_model() -> void:
	var enemy_type = _get_base_enemy_type()
	var model = ModelFactory.get_model_for_enemy(enemy_type)
	if model.get_child_count() > 0:
		mesh.visible = false
		model.name = "ProceduralModel"
		add_child(model)
		ModelFactory.apply_model_materials(model, enemy_color)
		_animator = preload("res://scripts/effects/procedural_animator.gd").new()
		_animator.setup(model)
		add_child(_animator)
	else:
		VisualSetup.apply_cel_shader_to_mesh(mesh, enemy_color)

## Stage-themed enemy sprite mapping
## 16 generic types mapped per stage using all 90 themed sprites on disk
const STAGE_ENEMY_SPRITES := {
	"cemetery": {
		"Slime": "cemetery_zombie",
		"Bat": "cemetery_wraith",
		"Skeleton": "cemetery_reaper",
		"ZombieRunner": "cemetery_hand",
		"Ghost": "cemetery_banshee",
		"SlimeBig": "cemetery_ghoul",
		"Tank": "cemetery_bone_knight",
		"Bomber": "cemetery_gravedigger",
		"Swarm": "cemetery_rat_swarm",
		"SkeletonArcher": "cemetery_reaper",
		"GhostWhite": "cemetery_banshee",
		"GhostGreen": "cemetery_ghoul",
		"GhostBlue": "cemetery_wraith",
		"GhostRed": "cemetery_hand",
		"Mimic": "cemetery_gravedigger",
		"ToothFairy": "cemetery_banshee",
	},
	"forest": {
		"Slime": "forest_mushroom",
		"Bat": "forest_spider",
		"Skeleton": "forest_treant",
		"ZombieRunner": "forest_wolf",
		"Ghost": "forest_wisp",
		"SlimeBig": "forest_bear",
		"Tank": "forest_vine",
		"Bomber": "forest_owl",
		"Swarm": "forest_fairy",
		"SkeletonArcher": "forest_spider",
		"GhostWhite": "forest_wisp",
		"GhostGreen": "forest_mushroom",
		"GhostBlue": "forest_owl",
		"GhostRed": "forest_wolf",
		"Mimic": "forest_treant",
		"ToothFairy": "forest_fairy",
	},
	"farm": {
		"Slime": "farm_chicken",
		"Bat": "farm_crow",
		"Skeleton": "farm_scarecrow",
		"ZombieRunner": "farm_pig",
		"Ghost": "farm_worm",
		"SlimeBig": "farm_bull",
		"Tank": "farm_goat",
		"Bomber": "farm_rat",
		"Swarm": "farm_bee_swarm",
		"SkeletonArcher": "farm_scarecrow",
		"GhostWhite": "farm_worm",
		"GhostGreen": "farm_chicken",
		"GhostBlue": "farm_crow",
		"GhostRed": "farm_pig",
		"Mimic": "farm_rat",
		"ToothFairy": "farm_bee_swarm",
	},
	"tokyo": {
		"Slime": "tokyo_robot",
		"Bat": "tokyo_drone",
		"Skeleton": "tokyo_hacker",
		"ZombieRunner": "tokyo_mecha",
		"Ghost": "tokyo_hologram",
		"SlimeBig": "tokyo_cyborg",
		"Tank": "tokyo_turret",
		"Bomber": "tokyo_virus",
		"Swarm": "tokyo_yakuza",
		"SkeletonArcher": "tokyo_hacker",
		"GhostWhite": "tokyo_hologram",
		"GhostGreen": "tokyo_virus",
		"GhostBlue": "tokyo_drone",
		"GhostRed": "tokyo_cyborg",
		"Mimic": "tokyo_robot",
		"ToothFairy": "tokyo_hologram",
	},
	"volcano": {
		"Slime": "volcano_magma_slime",
		"Bat": "volcano_fire_bat",
		"Skeleton": "volcano_golem",
		"ZombieRunner": "volcano_hellhound",
		"Ghost": "volcano_ash_ghost",
		"SlimeBig": "volcano_lava_snake",
		"Tank": "volcano_obsidian_golem",
		"Bomber": "volcano_phoenix",
		"Swarm": "volcano_imp",
		"SkeletonArcher": "volcano_golem",
		"GhostWhite": "volcano_ash_ghost",
		"GhostGreen": "volcano_magma_slime",
		"GhostBlue": "volcano_fire_bat",
		"GhostRed": "volcano_phoenix",
		"Mimic": "volcano_lava_snake",
		"ToothFairy": "volcano_imp",
	},
	"ocean": {
		"Slime": "ocean_crab",
		"Bat": "ocean_squid",
		"Skeleton": "ocean_fish",
		"ZombieRunner": "ocean_urchin",
		"Ghost": "ocean_seahorse",
		"SlimeBig": "ocean_pufferfish",
		"Tank": "ocean_shark",
		"Bomber": "ocean_octopus",
		"Swarm": "ocean_eel",
		"SkeletonArcher": "ocean_fish",
		"GhostWhite": "ocean_seahorse",
		"GhostGreen": "ocean_eel",
		"GhostBlue": "ocean_squid",
		"GhostRed": "ocean_octopus",
		"Mimic": "ocean_crab",
		"ToothFairy": "ocean_seahorse",
	},
	"arena": {
		"Slime": "arena_gladiator",
		"Bat": "arena_eagle",
		"Skeleton": "arena_centurion",
		"ZombieRunner": "arena_chariot",
		"Ghost": "arena_prisoner",
		"SlimeBig": "arena_tiger",
		"Tank": "arena_net_fighter",
		"Bomber": "arena_archer",
		"Swarm": "arena_lion",
		"SkeletonArcher": "arena_archer",
		"GhostWhite": "arena_prisoner",
		"GhostGreen": "arena_gladiator",
		"GhostBlue": "arena_centurion",
		"GhostRed": "arena_chariot",
		"Mimic": "arena_tiger",
		"ToothFairy": "arena_eagle",
	},
	"space": {
		"Slime": "space_alien",
		"Bat": "space_drone_enemy",
		"Skeleton": "space_xenomorph",
		"ZombieRunner": "space_parasite",
		"Ghost": "space_crystal",
		"SlimeBig": "space_tentacle",
		"Tank": "space_sentinel",
		"Bomber": "space_robot",
		"Swarm": "space_worm",
		"SkeletonArcher": "space_xenomorph",
		"GhostWhite": "space_crystal",
		"GhostGreen": "space_alien",
		"GhostBlue": "space_drone_enemy",
		"GhostRed": "space_parasite",
		"Mimic": "space_robot",
		"ToothFairy": "space_crystal",
	},
	"castle": {
		"Slime": "castle_vampire",
		"Bat": "castle_gargoyle",
		"Skeleton": "castle_knight",
		"ZombieRunner": "castle_werewolf",
		"Ghost": "castle_ghost_maid",
		"SlimeBig": "castle_cursed_armor",
		"Tank": "castle_skeleton_mage",
		"Bomber": "castle_rat_king",
		"Swarm": "castle_bat_swarm",
		"SkeletonArcher": "castle_skeleton_mage",
		"GhostWhite": "castle_ghost_maid",
		"GhostGreen": "castle_vampire",
		"GhostBlue": "castle_gargoyle",
		"GhostRed": "castle_werewolf",
		"Mimic": "castle_cursed_armor",
		"ToothFairy": "castle_ghost_maid",
	},
	"candy": {
		"Slime": "candy_gummy",
		"Bat": "candy_cupcake",
		"Skeleton": "candy_jawbreaker",
		"ZombieRunner": "candy_licorice",
		"Ghost": "candy_cotton_candy_ghost",
		"SlimeBig": "candy_chocolate_golem",
		"Tank": "candy_cake_mimic",
		"Bomber": "candy_ice_cream_cone",
		"Swarm": "candy_sour_worm",
		"SkeletonArcher": "candy_jawbreaker",
		"GhostWhite": "candy_cotton_candy_ghost",
		"GhostGreen": "candy_gummy",
		"GhostBlue": "candy_cupcake",
		"GhostRed": "candy_licorice",
		"Mimic": "candy_cake_mimic",
		"ToothFairy": "candy_cotton_candy_ghost",
	},
}

## Separacao entre inimigos — raio e forca de repulsao
const SEPARATION_RADIUS := 1.5
const SEPARATION_FORCE := 3.0
const MAX_NEIGHBORS_CHECK := 8

func _physics_process(delta: float) -> void:
	if is_dead or GameManager.paused or not is_inside_tree():
		return

	_frame_counter += 1

	# Boss aura pulse (every 3rd frame, cached reference)
	if _frame_counter % 3 == 0:
		if not _boss_aura_checked:
			_boss_aura_checked = true
			_cached_boss_aura = get_node_or_null("BossAura")
		if _cached_boss_aura:
			_cached_boss_aura.modulate.a = 0.2 + sin(Time.get_ticks_msec() * 0.004) * 0.15

	# Knockback decay
	if knockback_velocity.length() > 0.1:
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, 8.0 * delta)
		velocity = knockback_velocity
		move_and_slide()
		return

	_find_target()

	# --- Stage behavior processing (every other frame for non-critical behaviors) ---
	if _behavior != "" and target and is_instance_valid(target):
		var is_critical_behavior = _behavior == "charge" or _behavior == "teleport" or _is_charging
		if is_critical_behavior or _frame_counter % 2 == 0:
			_process_stage_behavior(delta)

	if target and is_instance_valid(target):
		# Charging override: move in straight line ignoring target
		if _is_charging:
			velocity = _charge_dir * speed * 3.0
			move_and_slide()
			return
		var direction = (target.global_position - global_position).normalized()
		direction.y = 0
		var effective_speed = speed
		# Veteran relic: enemies 15% faster
		if GameManager.veteran_relic_active:
			effective_speed *= 1.15
		# Mutation: speed demons
		effective_speed *= MutationManager.get_enemy_speed_modifier()
		# Separacao: repulsao de inimigos proximos (every 3rd frame, cache result)
		if _frame_counter % 3 == 0:
			_cached_separation = _get_separation_vector()
		var final_dir = (direction * effective_speed + _cached_separation).normalized()
		velocity = final_dir * effective_speed
		# Flying behavior: erratic vertical movement
		if _behavior == "flying":
			velocity.y = sin(GameManager.game_time * 3.0 + global_position.x) * 2.0
		move_and_slide()
		# Walk bob on sprite (speed-proportional bob + lean + flip + squash-stretch)
		var _walk_sprite = _get_cached_sprite()
		if _walk_sprite and _walk_sprite.visible:
			var _move_spd = velocity.length()
			var _bob_freq = 6.0 + _move_spd * 0.5  # Faster enemies bob faster
			var _bob_amp = clampf(_move_spd * 0.006, 0.02, 0.06)  # Amplitude scales with speed
			var phase = GameManager.game_time * _bob_freq + global_position.x
			_walk_sprite.position.y = 0.65 + abs(sin(phase)) * _bob_amp
			# Flip sprite toward player
			if target and is_instance_valid(target):
				var dir_x = target.global_position.x - global_position.x
				if dir_x > 0.3:
					_walk_sprite.flip_h = false
				elif dir_x < -0.3:
					_walk_sprite.flip_h = true
			# Lean toward movement direction (subtle tilt)
			var _lean_target = 0.0
			if abs(velocity.x) > 0.1:
				_lean_target = -sign(velocity.x) * clampf(abs(velocity.x) * 0.01, 0.0, 0.05)
			_walk_sprite.rotation.z = lerp(_walk_sprite.rotation.z, _lean_target, 0.15)
			# Subtle squash-stretch
			var walk_phase = sin(phase)
			_walk_sprite.scale = Vector3(
				_sprite_base_scale.x * (1.0 - abs(walk_phase) * 0.025),
				_sprite_base_scale.y * (1.0 + abs(walk_phase) * 0.035),
				_sprite_base_scale.z
			)
		if _animator:
			_animator.set_walking(true)
	else:
		# Idle bob + reset scale + return lean to neutral
		var _idle_sprite = _get_cached_sprite()
		if _idle_sprite and _idle_sprite.visible:
			_idle_sprite.position.y = 0.65 + sin(GameManager.game_time * 2.5 + global_position.z) * 0.015
			_idle_sprite.position.x = 0.0
			_idle_sprite.rotation.z = lerp(_idle_sprite.rotation.z, 0.0, 0.1)
			_idle_sprite.scale = _sprite_base_scale
		if _animator:
			_animator.set_walking(false)

func _process_stage_behavior(delta: float) -> void:
	if not target or not is_instance_valid(target) or not target.is_inside_tree():
		return
	var dist_to_target = global_position.distance_to(target.global_position)
	match _behavior:
		"teleport":
			_behavior_timer -= delta
			if _behavior_timer <= 0.0:
				_behavior_timer = _behavior_cooldown
				# Flash na posição antiga
				ParticleFactory.spawn_hit_particles(global_position + Vector3(0, 0.5, 0), Color(0.5, 0.2, 0.8), 10)
				var offset = Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
				global_position = target.global_position + offset
				# Flash na posição nova
				ParticleFactory.spawn_hit_particles(global_position + Vector3(0, 0.5, 0), Color(0.7, 0.3, 1.0), 10)
				AudioManager.play_sfx("hit")
				# Scale-in animation
				var sprite = _get_cached_sprite()
				if sprite:
					sprite.scale = Vector3(0.3, 0.3, 0.3)
					var tw = create_tween()
					tw.tween_property(sprite, "scale", _sprite_base_scale if _sprite_base_scale != Vector3.ZERO else Vector3.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		"ambush":
			if not _ambush_triggered and dist_to_target < 8.0:
				_ambush_triggered = true
				speed = _ambush_speed
				ParticleFactory.spawn_hit_particles(global_position + Vector3(0, 0.5, 0), Color(0.2, 0.8, 0.2), 6)
		"ranged":
			_behavior_timer -= delta
			if _behavior_timer <= 0.0:
				_behavior_timer = _behavior_cooldown
				_spawn_enemy_projectile()
		"charge":
			if _is_charging:
				_behavior_timer -= delta
				# Trail de velocidade durante charge
				if Engine.get_frames_per_second() > 40 and _frame_counter % 3 == 0:
					ParticleFactory.spawn_hit_particles(global_position + Vector3(0, 0.3, 0), Color(1.0, 0.6, 0.1, 0.5), 2)
				if _behavior_timer <= 0.0:
					_is_charging = false
					_behavior_timer = _behavior_cooldown
			else:
				_behavior_timer -= delta
				if _behavior_timer <= 0.0 and dist_to_target < 12.0:
					_is_charging = true
					_charge_dir = (target.global_position - global_position).normalized()
					_charge_dir.y = 0
					_behavior_timer = 0.8
					# Warning flash antes do charge
					ParticleFactory.spawn_hit_particles(global_position + Vector3(0, 0.5, 0), Color(1.0, 0.3, 0.1), 8)
					AudioManager.play_sfx("enemy_growl")
		"stealth":
			var alpha = clampf(1.0 - (dist_to_target / _stealth_range), 0.05, 1.0)
			var sprite = _get_cached_sprite()
			if sprite:
				sprite.modulate.a = alpha
			var proc = get_node_or_null("ProceduralModel")
			if proc:
				for child in proc.get_children():
					if child is MeshInstance3D:
						child.transparency = 1.0 - alpha
		"paralyze":
			pass  # Handled in _on_body_entered
		"flying":
			pass  # Handled in _physics_process movement

func _get_cached_sprite() -> Node:
	## Cached EnemySprite lookup — avoids get_node_or_null() every frame.
	if not _cached_enemy_sprite_checked:
		_cached_enemy_sprite_checked = true
		_cached_enemy_sprite = get_node_or_null("EnemySprite")
	return _cached_enemy_sprite


static func _get_shared_proj_mesh() -> SphereMesh:
	if not _shared_proj_mesh:
		_shared_proj_mesh = SphereMesh.new()
		_shared_proj_mesh.radius = 0.15
		_shared_proj_mesh.height = 0.3
	return _shared_proj_mesh


static func _get_shared_proj_mat() -> StandardMaterial3D:
	if not _shared_proj_mat:
		_shared_proj_mat = StandardMaterial3D.new()
		_shared_proj_mat.albedo_color = Color(1.0, 0.3, 0.3)
		_shared_proj_mat.emission_enabled = true
		_shared_proj_mat.emission = Color(1.0, 0.2, 0.2)
		_shared_proj_mat.emission_energy_multiplier = 2.0
	return _shared_proj_mat


func _spawn_enemy_projectile() -> void:
	if not target or not is_instance_valid(target) or not is_inside_tree():
		return
	var dir = (target.global_position - global_position).normalized()
	var projectile = MeshInstance3D.new()
	projectile.mesh = _get_shared_proj_mesh()
	projectile.material_override = _get_shared_proj_mat()
	projectile.global_position = global_position + Vector3(0, 0.8, 0)
	var start_pos = global_position + Vector3(0, 0.8, 0)
	var end_pos = start_pos + dir * 15.0
	get_tree().current_scene.add_child(projectile)
	var tween = projectile.create_tween()
	tween.tween_property(projectile, "global_position", end_pos, 1.5)
	tween.tween_callback(projectile.queue_free)
	# Area3D for collision detection
	var area = Area3D.new()
	area.collision_layer = 16  # EnemyAttacks (layer 5)
	area.collision_mask = 1  # Players (layer 1)
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.3
	col.shape = shape
	area.add_child(col)
	projectile.add_child(area)
	var dmg = damage
	area.body_entered.connect(func(body):
		if body.is_in_group("players") and body.has_method("take_damage"):
			body.take_damage(dmg, projectile.global_position)
			projectile.queue_free()
	)

func _get_separation_vector() -> Vector3:
	var sep := Vector3.ZERO
	# Use spatial grid for O(1) neighbor lookup instead of iterating all enemies
	var nearby = GameManager.get_nearby_enemies(global_position, SEPARATION_RADIUS)
	var checked := 0
	for enemy in nearby:
		if enemy == self or not is_instance_valid(enemy) or enemy.is_dead:
			continue
		var diff = global_position - enemy.global_position
		diff.y = 0
		var dist_sq = diff.length_squared()
		if dist_sq < SEPARATION_RADIUS * SEPARATION_RADIUS and dist_sq > 0.0001:
			var dist = sqrt(dist_sq)
			sep += diff * ((SEPARATION_RADIUS - dist) / (SEPARATION_RADIUS * dist) * SEPARATION_FORCE)
			checked += 1
			if checked >= MAX_NEIGHBORS_CHECK:
				break
	return sep

func _find_target() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		target = null
		return
	# If player is hidden in cornfield and far away, lose target
	if GameManager.player_hidden:
		if target and is_instance_valid(target):
			if global_position.distance_to(target.global_position) > 5.0:
				target = null
				return
	var min_dist = INF
	for p in players:
		if not is_instance_valid(p) or not p.is_inside_tree():
			continue
		var dist = global_position.distance_squared_to(p.global_position)
		if dist < min_dist:
			min_dist = dist
			target = p

func take_damage(amount: int, damage_type: String = "physical") -> void:
	if is_dead or not is_inside_tree():
		return
	# Boss entrance invincibility — ignore all damage during entrance animation
	if _entrance_invincible:
		return
	# Apply resistance multiplier (minimum 1 damage)
	var resist_mult: float = resistances.get(damage_type, 1.0)
	var is_crit = GameManager.crit_chance > 0.0 and randf() < GameManager.crit_chance
	var crit_mult = GameManager.crit_multiplier if is_crit else 1.0
	# Apply element-specific item multipliers
	var element_mult := 1.0
	if damage_type == "electric" and GameManager.electric_damage_mult > 1.0:
		element_mult *= GameManager.electric_damage_mult
	if damage_type == "fire" and GameManager.explosion_damage_mult > 1.0:
		element_mult *= GameManager.explosion_damage_mult
	# Apply summon damage mult for summon weapons
	var weapon_id = GameManager._last_attacking_weapon
	if GameManager.summon_damage_mult > 1.0 and weapon_id in ["necro", "drone", "totem", "tornado", "blood_orb", "portal_weapon", "time_bomb"]:
		element_mult *= GameManager.summon_damage_mult
	var final_damage = maxi(1, int(amount * GameManager.get_effective_damage_mult() * resist_mult * crit_mult * element_mult))
	hp -= final_damage
	GameManager.total_damage_dealt += final_damage
	GameManager.record_weapon_damage(GameManager._last_attacking_weapon, final_damage)
	AchievementManager.on_attack()
	# Lifesteal: chance-based per hit (prevents OP with fast weapons)
	# 5% lifesteal = 5% chance to heal 15% of damage dealt
	if GameManager.lifesteal > 0.0 and final_damage > 0:
		if randf() < GameManager.lifesteal:
			var heal_amount = maxi(1, ceili(final_damage * 0.15))
			GameManager.heal(heal_amount)
	# Cross-combo check (multiplayer)
	if MultiplayerManager.is_online and damage_type != "physical":
		var peer = MultiplayerManager.local_player_id
		SynergySystem.try_cross_combo(global_position, damage_type, peer, final_damage)
	_hit_count += 1

	if not is_inside_tree():
		return
	# Damage number - skip at low FPS to reduce draw calls (Label3D = 1 draw call each)
	# PRD 28 §3 — Accessibility: skip damage numbers if toggle is off
	var fps = Engine.get_frames_per_second()
	var show_dmg_number = GameManager.damage_numbers_enabled
	if fps < 25:
		show_dmg_number = is_crit  # Only show crits at very low FPS
	elif fps < 35:
		show_dmg_number = is_crit or randf() < 0.3  # 30% chance at low FPS
	if show_dmg_number:
		var dmg_color: Color
		if is_crit:
			dmg_color = Color(1.0, 0.9, 0.2)
		else:
			dmg_color = _get_damage_color(damage_type)
		var pos = global_position
		var dmg_label = ParticleFactory.get_damage_number()
		dmg_label.text = str(final_damage) + ("!" if is_crit else "")
		dmg_label.font_size = 40 if is_crit else 28
		dmg_label.outline_size = 6
		dmg_label.modulate = dmg_color
		dmg_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		dmg_label.position = global_position + Vector3(randf_range(-0.5, 0.5), 1.8, 0)
		dmg_label.visible = true
		dmg_label.set_process(true)
		if not dmg_label.get_parent():
			get_tree().current_scene.call_deferred("add_child", dmg_label)
		elif dmg_label.is_inside_tree():
			dmg_label.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 1.8, 0)

	# Hit particles + screen shake (throttled: skip particles at low FPS to save performance)
	if fps > 30 or randf() < 0.3:
		ParticleFactory.spawn_hit_particles(global_position + Vector3(0, 0.5, 0), Color.WHITE, 3 if fps < 40 else 6)
	if fps > 20:
		ScreenEffects.shake(0.03)  # Subtle shake on enemy hit

	# Knockback
	if target and is_instance_valid(target):
		var kb_dir = (global_position - target.global_position).normalized()
		knockback_velocity = kb_dir * 3.5
		_last_hit_direction = kb_dir  # PRD 45: guarda direcao para ragdoll de morte

	AudioManager.play_sfx("hit")
	if _animator:
		_animator.play_hit()
	_flash_white()
	if hp <= 0:
		if is_in_group("boss"):
			ScreenEffects.boss_kill_freeze()  # PRD 44: freeze dramatico no kill do boss
		call_deferred("_die")

func _get_damage_color(damage_type: String) -> Color:
	match damage_type:
		"fire":
			return Color(1.0, 0.5, 0.2)
		"ice":
			return Color(0.4, 0.8, 1.0)
		"electric":
			return Color(1.0, 1.0, 0.3)
		"dark":
			return Color(0.7, 0.3, 0.9)
		"poison":
			return Color(0.3, 0.9, 0.3)
		_:
			return Color(1, 1, 0.8)

func _flash_white() -> void:
	var sprite = get_node_or_null("EnemySprite")
	if sprite:
		sprite.modulate = Color(5, 2, 2)  # Red-tinted flash
		# Squash-stretch on hit — always use base scale to prevent accumulation
		sprite.scale = Vector3(_sprite_base_scale.x * 1.3, _sprite_base_scale.y * 0.7, _sprite_base_scale.z)
		# Reuse tween to avoid creating hundreds per second
		if _flash_tween and _flash_tween.is_valid():
			_flash_tween.kill()
		_flash_tween = create_tween()
		_flash_tween.set_parallel(true)
		_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		_flash_tween.tween_property(sprite, "scale", _sprite_base_scale, 0.12).set_trans(Tween.TRANS_ELASTIC)
		return
	var proc_model = get_node_or_null("ProceduralModel")
	if proc_model:
		for child in proc_model.get_children():
			if child is MeshInstance3D and child.material_override is ShaderMaterial:
				child.material_override.set_shader_parameter("albedo_color", Color.WHITE)
		if _flash_tween and _flash_tween.is_valid():
			_flash_tween.kill()
		_flash_tween = create_tween()
		_flash_tween.tween_callback(func():
			if is_instance_valid(proc_model):
				for child in proc_model.get_children():
					if child is MeshInstance3D and child.material_override is ShaderMaterial:
						child.material_override.set_shader_parameter("albedo_color", enemy_color)
		).set_delay(0.15)
	else:
		var mat = mesh.material_override
		if mat is ShaderMaterial:
			mat.set_shader_parameter("albedo_color", Color.WHITE)
			if _flash_tween and _flash_tween.is_valid():
				_flash_tween.kill()
			_flash_tween = create_tween()
			_flash_tween.tween_callback(func(): mat.set_shader_parameter("albedo_color", enemy_color)).set_delay(0.15)

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	# Stop processing but keep visible for ragdoll animation (PRD 45)
	set_physics_process(false)
	set_process(false)
	AudioManager.play_sfx("kill")
	# Track in bestiary using the proper bestiary ID
	var bestiary_id := get_bestiary_id()
	var milestone_info := SaveManager.track_bestiary(bestiary_id)
	if milestone_info.has("milestone_reached"):
		GameManager.bestiary_milestone_reached.emit(
			bestiary_id, milestone_info["milestone_reached"],
			milestone_info["milestone_label"], milestone_info["crystals_awarded"]
		)
	# One Punch achievement: boss killed in 1 hit
	if is_in_group("boss") and _hit_count <= 1:
		AchievementManager.on_boss_killed_one_hit()
	# Telemetry: boss killed event + boss death dialogue
	if is_in_group("boss"):
		AudioManager.play_sfx("boss_death")
		GameManager.boss_died.emit(name)
		# Bloom spike na morte do boss
		if get_tree() and get_tree().current_scene:
			load("res://scripts/stages/stage_atmosphere.gd").bloom_spike(get_tree().current_scene, 1.0, 1.0)
		Telemetry.send_event("boss_killed", {
			"boss_name": name,
			"stage": GameManager.selected_stage,
			"time": GameManager.game_time,
		})
	GameManager.enemies_alive -= 1
	GameManager.total_kills += 1
	# Track kill per weapon and overkill (PRD 28)
	GameManager.record_kill(GameManager._last_attacking_weapon)
	if hp < 0:
		GameManager.record_overkill(float(abs(hp)))
	var pos = global_position if is_inside_tree() else Vector3.ZERO
	GameManager.enemy_killed.emit(pos, xp_drop)
	if is_inside_tree():
		# Throttle death particles at low FPS
		var _fps = Engine.get_frames_per_second()
		if _fps > 25 or randf() < 0.4:
			ParticleFactory.spawn_death_particles(pos + Vector3(0, 0.3, 0), enemy_color, 6 if _fps < 40 else 12)
			# Gold particles for elite enemies
			if enemy_color == Color(1.0, 0.85, 0.2) or scale.x > 1.2:
				ParticleFactory.spawn_death_particles(pos + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.2), 8)
		if _fps > 20:
			ScreenEffects.shake(0.03)  # Subtle shake on enemy kill
		SynergySystem.apply_on_kill_synergies(pos)
		# Mutation: explosive enemies
		if MutationManager.is_active("explosive_enemies") and not is_in_group("boss"):
			_mutation_explode(pos)
		# Stage behavior: death effects
		_apply_death_behavior(pos)
		_spawn_xp_gem(pos)
		_spawn_crystal(pos)
		_spawn_health_pickup(pos)
		_spawn_magnet_pickup(pos)
		# Gasoline item: fire ground on enemy death
		if GameManager.fire_ground_active:
			_spawn_fire_ground(pos)
	# Disable all processing/collision during death animation to prevent errors
	set_physics_process(false)
	set_process(false)
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	collision_layer = 0
	collision_mask = 0
	# Death animation: ragdoll with directional fly + spin (PRD 45)
	var sprite = get_node_or_null("EnemySprite")
	if sprite:
		sprite.modulate = Color(10, 10, 10)  # Flash branco mantido
		visible = true  # Garantir visibilidade para ragdoll
		_play_ragdoll_death(sprite)
		return  # Don't queue_free immediately — tween handles it
	if _animator:
		_animator.play_death()
		# Delay queue_free for death animation
		var tween = create_tween()
		tween.tween_callback(queue_free).set_delay(0.5)
	else:
		queue_free()

## PRD 45: Ragdoll death animation — directional fly + spin + fade
func _play_ragdoll_death(sprite: Node3D) -> void:
	# Direcao de voo: oposta ao golpe (se nao houve hit, usa direcao aleatoria para cima)
	var fly_dir := -_last_hit_direction if _last_hit_direction.length() > 0.01 else Vector3(randf_range(-1, 1), 1, 0).normalized()
	fly_dir.y = absf(fly_dir.y) + 0.4  # Sempre tem componente para cima
	fly_dir = fly_dir.normalized()

	var fly_dist := randf_range(GameConstants.RAGDOLL_FLY_MIN, GameConstants.RAGDOLL_FLY_MAX)
	var spin_sign := 1.0 if randf() > 0.5 else -1.0
	var spin_amount := spin_sign * randf_range(GameConstants.RAGDOLL_SPIN_MIN, GameConstants.RAGDOLL_SPIN_MAX)

	# Bosses voam mais longe e giram mais
	if is_in_group("boss"):
		fly_dist *= GameConstants.RAGDOLL_BOSS_SCALE
		spin_amount *= GameConstants.RAGDOLL_BOSS_SCALE

	# Acessibilidade: reduced motion
	if AccessibilityManager.reduced_motion:
		fly_dist *= 0.12
		spin_amount = 0.0

	var target_pos := sprite.position + fly_dir * fly_dist
	var target_rot := sprite.rotation + Vector3(0, 0, spin_amount)
	var duration := GameConstants.RAGDOLL_DURATION

	# Flash branco inicial por 2 frames, depois volta ao normal antes de voar
	await get_tree().process_frame
	await get_tree().process_frame
	sprite.modulate = Color(1, 1, 1, 1)

	var tween := create_tween()
	tween.set_parallel(true)
	# Voo: ease out (desacelera no final)
	tween.tween_property(sprite, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Rotacao: linear (continua girando)
	tween.tween_property(sprite, "rotation", target_rot, duration).set_trans(Tween.TRANS_LINEAR)
	# Fade: comeca depois de 30% do tempo
	tween.tween_property(sprite, "modulate:a", 0.0, duration * 0.7).set_delay(duration * 0.3)
	# Escala: leve stretch na direcao do voo (squash-stretch)
	tween.tween_property(sprite, "scale", sprite.scale * Vector3(0.7, 1.3, 1.0), duration * 0.1)
	tween.chain().tween_property(sprite, "scale", sprite.scale * Vector3(0.4, 0.4, 1.0), duration * 0.9)
	# Cleanup
	tween.chain().tween_callback(queue_free)

func _apply_death_behavior(pos: Vector3) -> void:
	if not is_inside_tree():
		return
	match _behavior:
		"spawn_on_death":
			# Scarecrow: spawns 3 mini crows on death
			for i in 3:
				var crow = preload("res://scenes/enemies/bat.tscn").instantiate()
				crow.max_hp = maxi(1, max_hp / 4)
				crow.hp = crow.max_hp
				crow.damage = maxi(1, damage / 2)
				crow.scale = Vector3(0.5, 0.5, 0.5)
				crow.xp_drop = 1
				var offset = Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
				get_tree().current_scene.call_deferred("add_child", crow)
				crow.global_position = pos + offset
				GameManager.enemies_alive += 1
		"explode_on_death":
			# Golem: AoE fire damage in radius 2.5
			var radius = 2.5
			ParticleFactory.spawn_explosion_particles(pos + Vector3(0, 0.3, 0))
			ScreenEffects.shake(0.12)
			var nearby = GameManager.get_enemies_in_radius(pos, radius)
			for e in nearby:
				if e == self or not is_instance_valid(e) or e.is_dead:
					continue
				if e.has_method("take_damage"):
					e.call_deferred("take_damage", max_hp, "fire")
			# Also damage players in radius
			for p in GameManager.get_players():
				if is_instance_valid(p) and pos.distance_to(p.global_position) < radius:
					if p.has_method("take_damage"):
						p.take_damage(damage * 2, pos)
		"split":
			# Gummy: splits into 2 smaller copies (only if not already a split clone)
			if scale.x < 0.5:
				return  # Too small — don't split further (prevents infinite loop)
			for i in 2:
				var clone = preload("res://scenes/enemies/slime.tscn").instantiate()
				clone.max_hp = maxi(1, max_hp / 2)
				clone.hp = clone.max_hp
				clone.damage = maxi(1, damage / 2)
				clone.scale = self.scale * 0.6
				clone.xp_drop = 1
				clone.set_meta("no_split", true)  # Prevent recursive splitting
				var offset = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
				var scene_root = get_tree().current_scene
				if is_instance_valid(scene_root):
					scene_root.add_child(clone)
					clone.global_position = pos + offset
					GameManager.enemies_alive += 1

func _spawn_xp_gem(pos: Vector3) -> void:
	var gem_scene = preload("res://scenes/xp_gem.tscn")
	var gem = gem_scene.instantiate()
	var value = xp_drop
	if GameManager.master_key_active:
		value *= 2
	gem.xp_value = value
	get_tree().current_scene.add_child(gem)
	gem.global_position = pos + Vector3(0, 0.3, 0)

func _spawn_crystal(pos: Vector3) -> void:
	# 30% chance de dropar cristal (50% with master key)
	var drop_chance = 0.5 if GameManager.master_key_active else 0.3
	if randf() > drop_chance:
		return
	var crystal_scene = preload("res://scenes/crystal_pickup.tscn")
	var crystal = crystal_scene.instantiate()
	var value = maxi(1, xp_drop)
	if GameManager.master_key_active:
		value *= 2
	crystal.crystal_value = value
	get_tree().current_scene.add_child(crystal)
	crystal.global_position = pos + Vector3(0.3, 0.3, 0.3)

func _spawn_health_pickup(pos: Vector3) -> void:
	# 5% base chance (10% com lucky coin, 8% when low HP)
	var base_chance = 0.05
	# Chance aumenta quando jogador tem pouca vida (< 40% HP)
	var hp_ratio = float(GameManager.player_hp) / float(maxi(1, GameManager.get_effective_max_hp()))
	if hp_ratio < 0.4:
		base_chance += 0.03
	# Luck multiplier
	var drop_chance = base_chance * GameManager.luck_mult
	if randf() > drop_chance:
		return
	var hp_scene = preload("res://scenes/health_pickup.tscn")
	var hp_pickup = hp_scene.instantiate()
	# Cura escala com level do jogador e max HP
	var base_heal = maxi(5, int(GameManager.get_effective_max_hp() * 0.08))
	if GameManager.master_key_active:
		base_heal *= 2
	hp_pickup.heal_value = base_heal
	get_tree().current_scene.add_child(hp_pickup)
	hp_pickup.global_position = pos + Vector3(-0.3, 0.3, 0.2)

func _spawn_magnet_pickup(pos: Vector3) -> void:
	# 1% base chance (raro, mas impactante), dobra com master key
	var base_chance = 0.01
	if GameManager.master_key_active:
		base_chance = 0.02
	var drop_chance = base_chance * GameManager.luck_mult
	if randf() > drop_chance:
		return
	var magnet_scene = preload("res://scenes/magnet_pickup.tscn")
	var magnet = magnet_scene.instantiate()
	get_tree().current_scene.add_child(magnet)
	magnet.global_position = pos + Vector3(0.2, 0.3, -0.3)

func _spawn_fire_ground(pos: Vector3) -> void:
	# Lightweight fire ground: just disc mesh + Area3D collision (no GPUParticles3D)
	var fire_scene = preload("res://scripts/effects/fire_ground_effect.gd")
	var fire = Area3D.new()
	fire.set_script(fire_scene)
	fire.collision_layer = 0
	fire.collision_mask = 2  # Enemies
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.5
	col.shape = shape
	fire.add_child(col)
	# Visual — simple fire disc (no particles for performance)
	var mesh_inst = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 1.5
	disc.bottom_radius = 1.5
	disc.height = 0.05
	mesh_inst.mesh = disc
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.2, 0.05, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.0)
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_inst.material_override = mat
	fire.add_child(mesh_inst)
	fire.global_position = pos
	fire.monitoring = true
	get_tree().current_scene.call_deferred("add_child", fire)
	# Register as elemental zone for cross-combo
	var owner_peer = MultiplayerManager.local_player_id if MultiplayerManager.is_online else 1
	SynergySystem.register_elemental_zone(pos, "fire", owner_peer, 5.0)

func _apply_furious_boss_mutation() -> void:
	if is_in_group("boss") and MutationManager.is_active("furious_bosses"):
		hp = int(max_hp * 0.75)

## Dramatic boss entrance: scale from 0 to full size with invincibility period.
## Called by enemy_spawner after adding the boss to the scene tree.
func play_boss_entrance() -> void:
	_entrance_invincible = true
	# Store original scale and start at zero
	var original_scale = scale
	scale = Vector3.ZERO
	# Scale up from 0 to full size over 0.5s with elastic overshoot
	var entrance_tween = create_tween()
	entrance_tween.tween_property(self, "scale", original_scale * 1.15, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	entrance_tween.tween_property(self, "scale", original_scale, 0.15).set_ease(Tween.EASE_IN_OUT)
	# Ground impact particles when scale-up finishes
	var self_ref = self
	entrance_tween.tween_callback(func():
		if is_instance_valid(self_ref):
			ParticleFactory.spawn_explosion_particles(self_ref.global_position + Vector3(0, 0.3, 0))
			ScreenEffects.shake(0.3)
	)
	# Remove invincibility after 1 second
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(self_ref):
			self_ref._entrance_invincible = false
	)

func _mutation_explode(pos: Vector3) -> void:
	## Mutation "explosive_enemies": AoE damage on death (like Bomber)
	var explosion_damage = maxi(1, max_hp / 2)
	var explosion_radius = 1.5
	ParticleFactory.spawn_explosion_particles(pos + Vector3(0, 0.3, 0))
	# Use spatial grid for O(1) radius query instead of iterating all enemies
	var nearby = GameManager.get_enemies_in_radius(pos, explosion_radius)
	for e in nearby:
		if e == self or not is_instance_valid(e) or e.is_dead:
			continue
		if e.has_method("take_damage"):
			e.call_deferred("take_damage", explosion_damage, "fire")

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		# Paralyze behavior: stun player for 1 second on contact
		if _behavior == "paralyze" and body.has_method("apply_stun"):
			body.apply_stun(1.0)
		elif _behavior == "paralyze":
			# Fallback: slow player temporarily if no stun method
			if "speed" in body:
				var original_spd = body.speed
				body.speed = original_spd * 0.3
				get_tree().create_timer(1.0).timeout.connect(func():
					if is_instance_valid(body):
						body.speed = original_spd
				)
		# Track cow damage for achievement
		if GameManager.selected_stage == "farm":
			var cow_names = ["Zombie Cow", "Cow Slime", "Bull", "Mud Blob"]
			if name in cow_names:
				AchievementManager.on_cow_damage()
