extends EnemyBase3D

## Boss: Singularidade (Space Stage). 3 fases baseadas em HP.
## Fase 1 (100-75%): Aneis de projeteis, spawna parasitas alienigenas (slimes)
## Fase 2 (75-25%): Buraco negro puxa inimigos, projeteis teleguiados, spawna drones (bats)
## Fase 3 (25-0%): Colapso - puxa player, spam de projeteis, spawna aliens mutantes (slime_big)

var phase: int = 1
var _phase3_transition_done: bool = false
var summon_timer: float = 0.0
var attack_timer: float = 0.0
var ring_timer: float = 0.0
var pull_timer: float = 0.0
var _fury_active := false

var bat_scene: PackedScene = preload("res://scenes/enemies/bat.tscn")
var slime_scene: PackedScene = preload("res://scenes/enemies/slime.tscn")
var slime_big_scene: PackedScene = preload("res://scenes/enemies/slime_big.tscn")
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _ready() -> void:
	resistances = {
		"physical": 0.5,  # Resistente a fisico (imaterial)
		"fire": 0.6,
		"ice": 0.6,
		"electric": 0.6,
		"dark": 0.6,
		"poison": 0.4,  # Entidade cosmica quase imune a veneno
	}
	super._ready()
	# Extra boss HP scaling for multiplayer
	var boss_extra = GameManager.get_mp_boss_hp_mult() / GameManager.get_mp_hp_mult()
	if boss_extra > 1.0:
		max_hp = int(max_hp * boss_extra)
		hp = max_hp
	add_to_group("boss")
	enemy_color = Color(0.1, 0.0, 0.15)

func _physics_process(delta: float) -> void:
	if is_dead or GameManager.paused or not is_inside_tree():
		return

	# Determina fase
	var old_phase = phase
	var hp_pct = float(hp) / float(max_hp) if max_hp > 0 else 1.0
	if hp_pct > 0.75:
		phase = 1
	elif hp_pct > 0.25:
		phase = 2
	else:
		phase = 3
	if phase != old_phase:
		AudioManager.play_sfx("boss_phase")
		ScreenEffects.shake(0.2)
		GameManager.boss_phase_changed.emit(name, phase)
		if phase == 3 and not _phase3_transition_done:
			_phase3_transition_done = true
			ScreenEffects.boss_phase3_transition(global_position, enemy_color)

	# Fury phase (HP < 10%)
	if hp < max_hp * 0.1 and not _fury_active:
		_fury_active = true
		speed *= 1.5
		var sprite = get_node_or_null("EnemySprite")
		if sprite:
			sprite.modulate = Color(1.5, 0.5, 0.5)

	# Velocidade por fase
	match phase:
		1: speed = 1.5
		2: speed = 2.0
		3: speed = 2.5
	if _fury_active:
		speed *= 1.5

	# Movimento
	_find_target()
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		direction.y = 0
		velocity = direction * speed
		move_and_slide()

	# Timers
	summon_timer -= delta
	attack_timer -= delta
	ring_timer -= delta
	pull_timer -= delta

	match phase:
		1:
			# Projectile rings outward
			if ring_timer <= 0:
				ring_timer = 3.5
				_telegraph_attack(global_position, 3.0)
				_fire_projectile_ring(6)
				BossAttackPatterns.circle_aoe(get_tree().current_scene, global_position, 3.5, int(damage * 0.25), 1.2, Color(0.5, 0.2, 1.0, 0.3))
			# Spawn alien parasites (slimes)
			if summon_timer <= 0:
				summon_timer = 5.0
				_telegraph_attack(global_position, 3.0)
				_summon_parasites(3)
		2:
			# Black hole pull on nearby enemies
			if pull_timer <= 0:
				pull_timer = 0.5
				_black_hole_pull(delta)
			# Homing projectiles
			if attack_timer <= 0:
				attack_timer = 2.5
				_telegraph_attack(global_position, 3.0)
				_fire_homing_projectiles(4)
			# Spawn drones (bats)
			if summon_timer <= 0:
				summon_timer = 5.0
				_telegraph_attack(global_position, 4.0)
				_summon_drones(4)
			if ring_timer <= 0:
				ring_timer = 4.0
				_telegraph_attack(global_position, 3.0)
				_fire_projectile_ring(8)
		3:
			# Singularity collapse - pull player toward boss
			_pull_player(delta)
			# Massive projectile spam
			if ring_timer <= 0:
				ring_timer = 1.5
				_telegraph_attack(global_position, 4.0)
				_fire_projectile_ring(12)
			if attack_timer <= 0:
				attack_timer = 2.0
				_telegraph_attack(global_position, 3.0)
				_fire_homing_projectiles(6)
			# Spawn mutated aliens (slime_big)
			if summon_timer <= 0:
				summon_timer = 4.0
				_telegraph_attack(global_position, 5.0)
				_summon_mutants(2)

func _fire_projectile_ring(count: int) -> void:
	AudioManager.play_sfx("boss_attack")
	for i in range(count):
		var proj = ObjectPool.get_instance(bullet_scene)
		var angle = (TAU / count) * i
		var dir = Vector3(cos(angle), 0, sin(angle))
		proj.global_position = global_position + dir * 1.5
		proj.direction = dir
		proj.damage = int(damage * 0.3)
		proj.speed = 8.0
		proj.lifetime = 4.0
		proj.collision_layer = 16  # Layer 5 = EnemyAttacks
		proj.collision_mask = 1    # Layer 1 = Players
		get_tree().current_scene.call_deferred("add_child", proj)

func _fire_homing_projectiles(count: int) -> void:
	if not target or not is_instance_valid(target):
		return
	AudioManager.play_sfx("boss_attack")
	for i in range(count):
		var proj = ObjectPool.get_instance(bullet_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 2.0
		proj.global_position = global_position + offset
		var dir = (target.global_position - global_position).normalized()
		dir.y = 0
		proj.direction = dir
		proj.damage = int(damage * 0.35)
		proj.speed = 10.0
		proj.lifetime = 5.0
		proj.collision_layer = 16
		proj.collision_mask = 1
		get_tree().current_scene.call_deferred("add_child", proj)

func _black_hole_pull(_delta: float) -> void:
	# Pull all enemies toward self
	var enemies = GameManager.get_enemies()
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue
		if enemy is EnemyBase3D and not enemy.is_dead:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < 15.0 and dist > 1.0:
				var pull_dir = (global_position - enemy.global_position).normalized()
				enemy.global_position += pull_dir * 2.0 * _delta

func _pull_player(delta: float) -> void:
	if not target or not is_instance_valid(target):
		return
	var dist = global_position.distance_to(target.global_position)
	if dist > 2.0 and dist < 20.0:
		var pull_dir = (global_position - target.global_position).normalized()
		pull_dir.y = 0
		target.global_position += pull_dir * 1.5 * delta

func _summon_parasites(count: int) -> void:
	for i in range(count):
		var parasite = ObjectPool.get_instance(slime_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 3.0
		parasite.global_position = global_position + offset
		if parasite is EnemyBase3D:
			parasite.xp_drop = 0
			parasite.enemy_color = Color(0.4, 0.0, 0.6)  # Roxo alienigena
		get_tree().current_scene.call_deferred("add_child", parasite)
		GameManager.enemies_alive += 1

func _summon_drones(count: int) -> void:
	for i in range(count):
		var drone = ObjectPool.get_instance(bat_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 4.0
		drone.global_position = global_position + offset
		if drone is EnemyBase3D:
			drone.xp_drop = 0
			drone.enemy_color = Color(0.2, 0.0, 0.3)  # Roxo escuro
		get_tree().current_scene.call_deferred("add_child", drone)
		GameManager.enemies_alive += 1

func _summon_mutants(count: int) -> void:
	for i in range(count):
		var mutant = ObjectPool.get_instance(slime_big_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 5.0
		mutant.global_position = global_position + offset
		if mutant is EnemyBase3D:
			mutant.xp_drop = 0
			mutant.enemy_color = Color(0.15, 0.0, 0.2)  # Roxo escuro profundo
		get_tree().current_scene.call_deferred("add_child", mutant)
		GameManager.enemies_alive += 1

func _telegraph_attack(pos: Vector3, radius: float = 3.0) -> void:
	var indicator = Sprite3D.new()
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for x in range(32):
		for y in range(32):
			var dx = x - 16
			var dy = y - 16
			if dx * dx + dy * dy < 14 * 14:
				img.set_pixel(x, y, Color(1, 0, 0, 0.3))
	indicator.texture = ImageTexture.create_from_image(img)
	indicator.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	indicator.rotation.x = deg_to_rad(-90)
	indicator.pixel_size = radius * 0.06
	indicator.position = pos + Vector3(0, 0.05, 0)
	indicator.shaded = false
	indicator.transparent = true
	get_tree().current_scene.add_child(indicator)
	var tween = get_tree().create_tween()
	tween.tween_property(indicator, "modulate:a", 0.6, 0.3)
	tween.tween_property(indicator, "modulate:a", 0.0, 0.2)
	tween.tween_callback(indicator.queue_free)

func _die() -> void:
	if is_dead:
		return
	# Boss death: slow motion + massive particles
	ScreenEffects.hit_freeze(0.15)
	ScreenEffects.shake(0.5)
	ScreenEffects.slow_motion(1.0, 0.2)
	ParticleFactory.spawn_death_particles(global_position, enemy_color, 30)
	ParticleFactory.spawn_explosion_particles(global_position, 5.0)
	# Marca fase como completa
	SaveManager.complete_stage(GameManager.selected_stage)
	# Vitoria!
	GameManager.is_victory = true
	GameManager.is_game_over = true
	GameManager.game_over.emit()
	super._die()
