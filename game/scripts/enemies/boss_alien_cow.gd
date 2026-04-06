extends EnemyBase3D

## Boss: Mega Vaca Alienigena (Farm Stage). 3 fases baseadas em HP.
## Fase 1 (100-75%): Movimento lento, dispara aneis de projeteis
## Fase 2 (75-25%): Raio de abducao - puxa inimigo, buffa (3x HP, dourado), joga no player
## Fase 3 (25-0%): Frenzy - spawna vacas mutantes (slime_big), spam de projeteis

var phase: int = 1
var _phase3_transition_done: bool = false
var summon_timer: float = 0.0
var attack_timer: float = 0.0
var abduct_timer: float = 0.0
var _fury_active := false
var slime_big_scene: PackedScene = preload("res://scenes/enemies/slime_big.tscn")
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _ready() -> void:
	resistances = {
		"physical": 0.7,
		"fire": 0.7,
		"ice": 0.7,
		"electric": 1.3,  # Fraca contra eletricidade (alienigena metalica)
		"dark": 0.7,
	}
	super._ready()
	# Extra boss HP scaling for multiplayer
	var boss_extra = GameManager.get_mp_boss_hp_mult() / GameManager.get_mp_hp_mult()
	if boss_extra > 1.0:
		max_hp = int(max_hp * boss_extra)
		hp = max_hp
	add_to_group("boss")
	enemy_color = Color(0.3, 0.9, 0.3)

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
		2: speed = 2.5
		3: speed = 4.0
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
	abduct_timer -= delta

	match phase:
		1:
			# Slow projectile rings
			if attack_timer <= 0:
				attack_timer = 3.0
				_telegraph_attack(global_position, 3.0)
				_fire_projectile_ring(6, 5.0)
				BossAttackPatterns.circle_aoe(get_tree().current_scene, global_position, 3.0, int(damage * 0.3), 1.0, Color(0.3, 1.0, 0.3, 0.3))
		2:
			# Abduction beam + projectiles
			if abduct_timer <= 0:
				abduct_timer = 6.0
				_telegraph_attack(global_position, 4.0)
				_abduction_beam()
			if attack_timer <= 0:
				attack_timer = 2.5
				_telegraph_attack(global_position, 3.0)
				_fire_projectile_ring(8, 7.0)
		3:
			# Frenzy: spawn mutant cows + constant projectile spam
			if summon_timer <= 0:
				summon_timer = 4.0
				_telegraph_attack(global_position, 4.0)
				_spawn_mutant_cows(3)
			if attack_timer <= 0:
				attack_timer = 1.0
				_telegraph_attack(global_position, 3.0)
				_fire_projectile_ring(10, 9.0)
			if abduct_timer <= 0:
				abduct_timer = 4.0
				_telegraph_attack(global_position, 4.0)
				_abduction_beam()

func _fire_projectile_ring(count: int, proj_speed: float) -> void:
	if not target or not is_instance_valid(target):
		return
	AudioManager.play_sfx("boss_attack")
	for i in range(count):
		var angle = (TAU / count) * i
		var dir = Vector3(cos(angle), 0, sin(angle))

		var proj = ObjectPool.get_instance(bullet_scene)
		proj.global_position = global_position + Vector3(0, 0.8, 0)
		proj.direction = dir
		proj.damage = int(damage * 0.5)
		proj.speed = proj_speed
		proj.lifetime = 4.0
		proj.collision_layer = 16  # Layer 5 = EnemyAttacks
		proj.collision_mask = 1    # Layer 1 = Players
		get_tree().current_scene.call_deferred("add_child", proj)

func _abduction_beam() -> void:
	AudioManager.play_sfx("boss_attack")
	# Encontra inimigo mais proximo que nao seja boss
	var enemies = GameManager.get_enemies()
	var nearest: Node3D = null
	var nearest_dist: float = 999.0
	for e in enemies:
		if e == self or e.is_in_group("boss"):
			continue
		if not is_instance_valid(e):
			continue
		if e is EnemyBase3D and e.is_dead:
			continue
		var dist = global_position.distance_to(e.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = e
	if nearest == null:
		# Nenhum inimigo disponivel, spawna um novo buffado
		_spawn_buffed_minion()
		return
	# Buffa o inimigo capturado
	if nearest is EnemyBase3D:
		nearest.max_hp = nearest.max_hp * 3
		nearest.hp = nearest.max_hp
		nearest.enemy_color = Color(1.0, 0.85, 0.2)  # Dourado
		nearest.damage = int(nearest.damage * 2.0)
	# Joga na direcao do player
	if target and is_instance_valid(target) and is_instance_valid(nearest):
		var throw_dir = (target.global_position - global_position).normalized()
		nearest.global_position = global_position + throw_dir * 3.0
	# Visual feedback
	ParticleFactory.spawn_death_particles(global_position, Color(0.3, 0.9, 0.3), 10)

func _spawn_buffed_minion() -> void:
	var current_summons := get_tree().get_nodes_in_group("boss_summon").size()
	if current_summons >= GameConstants.BOSS_MAX_SUMMONS:
		return
	var minion = ObjectPool.get_instance(slime_big_scene)
	if minion is EnemyBase3D:
		minion.max_hp = minion.max_hp * 3
		minion.hp = minion.max_hp
		minion.enemy_color = Color(1.0, 0.85, 0.2)
		minion.xp_drop = 0
		minion.add_to_group("boss_summon")
	minion.global_position = global_position + Vector3(2, 0, 0)
	get_tree().current_scene.call_deferred("add_child", minion)
	GameManager.enemies_alive += 1

func _spawn_mutant_cows(count: int) -> void:
	var current_summons := get_tree().get_nodes_in_group("boss_summon").size()
	if current_summons >= GameConstants.BOSS_MAX_SUMMONS:
		return
	count = mini(count, GameConstants.BOSS_MAX_SUMMONS - current_summons)
	for i in range(count):
		var cow = ObjectPool.get_instance(slime_big_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 3.0
		cow.global_position = global_position + offset
		if cow is EnemyBase3D:
			cow.xp_drop = 0  # Boss summons nao dao XP
			cow.enemy_color = Color(0.3, 0.9, 0.3)  # Verde alienigena
			cow.max_hp = int(cow.max_hp * 1.5)
			cow.hp = cow.max_hp
			cow.add_to_group("boss_summon")
		get_tree().current_scene.call_deferred("add_child", cow)
		GameManager.enemies_alive += 1

func _telegraph_attack(pos: Vector3, radius: float = 3.0) -> void:
	var indicator = Sprite3D.new()
	indicator.texture = EnemyBase3D.get_telegraph_texture()
	indicator.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	indicator.rotation.x = deg_to_rad(-90)
	indicator.pixel_size = radius * 0.06
	indicator.position = pos + Vector3(0, 0.05, 0)
	indicator.shaded = false
	indicator.transparent = true
	var scene = get_tree().current_scene
	if scene and is_instance_valid(scene):
		scene.add_child(indicator)
	else:
		indicator.queue_free()
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
