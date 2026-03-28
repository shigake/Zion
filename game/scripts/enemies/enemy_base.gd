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

func _apply_sprite() -> void:
	var enemy_type = _get_base_enemy_type()
	var sprite_path = "res://assets/sprites/enemies/%s.png" % enemy_type.to_snake_case()
	if not ResourceLoader.exists(sprite_path):
		# Also try bosses/ folder (e.g. BossNecromancer -> boss_necromancer.png)
		var boss_sprite = "res://assets/sprites/bosses/%s.png" % enemy_type.to_snake_case()
		if ResourceLoader.exists(boss_sprite):
			sprite_path = boss_sprite
		else:
			LogManager.debug("Enemy", "Sprite not found: %s, trying slime fallback" % sprite_path)
			sprite_path = "res://assets/sprites/enemies/slime.png"
	if not ResourceLoader.exists(sprite_path):
		LogManager.debug("Enemy", "No sprites found at all, using procedural model")
		_apply_procedural_model()
		return
	var tex = load(sprite_path) as Texture2D
	if tex == null:
		_apply_procedural_model()
		return
	# Hide ALL old visuals
	mesh.visible = false
	for child in get_children():
		if child is MeshInstance3D and child != mesh:
			child.visible = false
	# Create billboard sprite
	var sprite = Sprite3D.new()
	sprite.texture = tex
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = 0.06 if enemy_type.begins_with("Boss") else 0.05
	sprite.shaded = false
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sprite.name = "EnemySprite"
	sprite.position.y = 0.65
	add_child(sprite)
	LogManager.debug("Enemy", "Sprite loaded: %s for %s" % [sprite_path, enemy_type])

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

## Separacao entre inimigos — raio e forca de repulsao
const SEPARATION_RADIUS := 1.5
const SEPARATION_FORCE := 3.0
const MAX_NEIGHBORS_CHECK := 8

func _physics_process(delta: float) -> void:
	if is_dead or GameManager.paused or not is_inside_tree():
		return

	# Knockback decay
	if knockback_velocity.length() > 0.1:
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, 8.0 * delta)
		velocity = knockback_velocity
		move_and_slide()
		return

	_find_target()
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		direction.y = 0
		var effective_speed = speed
		# Veteran relic: enemies 15% faster
		if GameManager.veteran_relic_active:
			effective_speed *= 1.15
		# Mutation: speed demons
		effective_speed *= MutationManager.get_enemy_speed_modifier()
		# Separacao: repulsao de inimigos proximos
		var separation = _get_separation_vector()
		var final_dir = (direction * effective_speed + separation).normalized()
		velocity = final_dir * effective_speed
		move_and_slide()
		if _animator:
			_animator.set_walking(true)
	else:
		if _animator:
			_animator.set_walking(false)

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
		if not is_instance_valid(p):
			continue
		var dist = global_position.distance_squared_to(p.global_position)
		if dist < min_dist:
			min_dist = dist
			target = p

func take_damage(amount: int, damage_type: String = "physical") -> void:
	if is_dead or not is_inside_tree():
		return
	# Apply resistance multiplier (minimum 1 damage)
	var resist_mult: float = resistances.get(damage_type, 1.0)
	var is_crit = GameManager.crit_chance > 0.0 and randf() < GameManager.crit_chance
	var crit_mult = GameManager.crit_multiplier if is_crit else 1.0
	var final_damage = maxi(1, int(amount * GameManager.get_effective_damage_mult() * resist_mult * crit_mult))
	hp -= final_damage
	GameManager.total_damage_dealt += final_damage
	AchievementManager.on_attack()
	# Cross-combo check (multiplayer)
	if MultiplayerManager.is_online and damage_type != "physical":
		var peer = MultiplayerManager.local_player_id
		SynergySystem.try_cross_combo(global_position, damage_type, peer, final_damage)
	_hit_count += 1

	if not is_inside_tree():
		return
	# Damage number - color by type (crits are yellow and larger)
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
	dmg_label.position = pos + Vector3(randf_range(-0.3, 0.3), 1.2, 0)
	dmg_label.visible = true
	dmg_label.set_process(true)
	if not dmg_label.get_parent():
		get_tree().current_scene.call_deferred("add_child", dmg_label)
	elif dmg_label.is_inside_tree():
		dmg_label.global_position = pos + Vector3(randf_range(-0.3, 0.3), 1.2, 0)

	# Hit particles + screen shake (throttled: skip particles at low FPS to save performance)
	var fps = Engine.get_frames_per_second()
	if fps > 30 or randf() < 0.3:
		ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.5, 0), Color.WHITE, 3 if fps < 40 else 6)
	if fps > 20:
		ScreenEffects.shake(0.04)

	# Knockback
	if target and is_instance_valid(target):
		var kb_dir = (global_position - target.global_position).normalized()
		knockback_velocity = kb_dir * 3.5

	AudioManager.play_sfx("hit")
	if _animator:
		_animator.play_hit()
	_flash_white()
	if hp <= 0:
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
		sprite.modulate = Color(10, 10, 10)  # Bright flash
		# Reuse tween to avoid creating hundreds per second
		if _flash_tween and _flash_tween.is_valid():
			_flash_tween.kill()
		_flash_tween = create_tween()
		_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)
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
	AudioManager.play_sfx("kill")
	# Track in bestiary
	SaveManager.track_bestiary(name)
	# One Punch achievement: boss killed in 1 hit
	if is_in_group("boss") and _hit_count <= 1:
		AchievementManager.on_boss_killed_one_hit()
	# Telemetry: boss killed event
	if is_in_group("boss"):
		Telemetry.send_event("boss_killed", {
			"boss_name": name,
			"stage": GameManager.selected_stage,
			"time": GameManager.game_time,
		})
	GameManager.enemies_alive -= 1
	GameManager.total_kills += 1
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
			ScreenEffects.shake(0.06)
		SynergySystem.apply_on_kill_synergies(pos)
		# Mutation: explosive enemies
		if MutationManager.is_active("explosive_enemies") and not is_in_group("boss"):
			_mutation_explode(pos)
		_spawn_xp_gem(pos)
		_spawn_crystal(pos)
		_spawn_health_pickup(pos)
		_spawn_magnet_pickup(pos)
		# Gasoline item: fire ground on enemy death
		if GameManager.fire_ground_active:
			_spawn_fire_ground(pos)
	if _animator:
		_animator.play_death()
		# Delay queue_free for death animation
		var tween = create_tween()
		tween.tween_callback(queue_free).set_delay(0.5)
	else:
		queue_free()

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
		# Track cow damage for achievement
		if GameManager.selected_stage == "farm":
			var cow_names = ["Zombie Cow", "Cow Slime", "Bull", "Mud Blob"]
			if name in cow_names:
				AchievementManager.on_cow_damage()
