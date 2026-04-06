extends EnemyBase3D

## Boss: AI Overlord (Tokyo Stage). 3 fases baseadas em HP.
## Fase 1 (100-75%): Spawna drones (bats como proxy, azul eletrico), laser grid (8 projeteis em cruz)
## Fase 2 (75-25%): Glitch - teleporta a cada 2s, spawna virus (slimes, verde), mais lasers
## Fase 3 (25-0%): System overload - drones constantes, laser rapido, speed boost

var phase: int = 1
var _phase3_transition_done: bool = false
var summon_timer: float = 0.0
var attack_timer: float = 0.0
var teleport_timer: float = 0.0
var _fury_active := false
var bat_scene: PackedScene = preload("res://scenes/enemies/bat.tscn")
var slime_scene: PackedScene = preload("res://scenes/enemies/slime.tscn")
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _ready() -> void:
	resistances = {
		"physical": 0.7,
		"fire": 0.5,  # Fraco contra fogo
		"ice": 0.7,
		"electric": 1.5,  # Resistente a eletrico
		"dark": 0.7,
	}
	super._ready()
	# Extra boss HP scaling for multiplayer
	var boss_extra = GameManager.get_mp_boss_hp_mult() / GameManager.get_mp_hp_mult()
	if boss_extra > 1.0:
		max_hp = int(max_hp * boss_extra)
		hp = max_hp
	add_to_group("boss")
	enemy_color = Color(0.2, 0.8, 1.0)

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
		1: speed = 2.0
		2: speed = 3.0
		3: speed = 5.0
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
	teleport_timer -= delta

	match phase:
		1:
			# Spawn drone swarms, fire laser grid
			if summon_timer <= 0:
				summon_timer = 4.0
				_telegraph_attack(global_position, 3.0)
				_summon_drones(3)
			if attack_timer <= 0:
				attack_timer = 3.0
				_telegraph_attack(global_position, 3.0)
				_fire_laser_grid(8)
				BossAttackPatterns.circle_aoe(get_tree().current_scene, global_position, 4.0, int(damage * 0.3), 1.0, Color(0.2, 0.5, 1.0, 0.3))
		2:
			# Glitch: teleport, virus minions, more lasers
			if teleport_timer <= 0:
				teleport_timer = 2.0
				_teleport_near_player()
			if summon_timer <= 0:
				summon_timer = 4.0
				_telegraph_attack(global_position, 3.0)
				_summon_virus_minions(3)
			if attack_timer <= 0:
				attack_timer = 2.0
				_telegraph_attack(global_position, 3.0)
				_fire_laser_grid(8)
		3:
			# System overload: constant drones, rapid lasers, speed boost
			if teleport_timer <= 0:
				teleport_timer = 2.0
				_teleport_near_player()
			if summon_timer <= 0:
				summon_timer = 2.0
				_telegraph_attack(global_position, 4.0)
				_summon_drones(5)
			if attack_timer <= 0:
				attack_timer = 1.0
				_telegraph_attack(global_position, 3.0)
				_fire_laser_grid(8)

func _teleport_near_player() -> void:
	if not target or not is_instance_valid(target):
		return
	var angle = randf() * TAU
	var dist = randf_range(5.0, 10.0)
	var offset = Vector3(cos(angle), 0, sin(angle)) * dist
	global_position = target.global_position + offset
	ParticleFactory.spawn_death_particles(global_position, enemy_color, 8)

func _summon_drones(count: int) -> void:
	for i in range(count):
		var drone = ObjectPool.get_instance(bat_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 3.0
		drone.global_position = global_position + offset
		if drone is EnemyBase3D:
			drone.xp_drop = 0  # Boss summons nao dao XP
			drone.enemy_color = Color(0.2, 0.6, 1.0)  # Azul eletrico
		get_tree().current_scene.call_deferred("add_child", drone)
		GameManager.enemies_alive += 1

func _summon_virus_minions(count: int) -> void:
	for i in range(count):
		var virus = ObjectPool.get_instance(slime_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 3.0
		virus.global_position = global_position + offset
		if virus is EnemyBase3D:
			virus.xp_drop = 0  # Boss summons nao dao XP
			virus.enemy_color = Color(0.2, 1.0, 0.2)  # Verde brilhante
		get_tree().current_scene.call_deferred("add_child", virus)
		GameManager.enemies_alive += 1

func _fire_laser_grid(count: int) -> void:
	if not target or not is_instance_valid(target):
		return
	AudioManager.play_sfx("boss_attack")
	# Cross pattern: 8 direcoes (cardeal + diagonal)
	for i in range(count):
		var angle = (TAU / count) * i
		var dir = Vector3(cos(angle), 0, sin(angle))

		var proj = ObjectPool.get_instance(bullet_scene)
		proj.global_position = global_position + Vector3(0, 0.8, 0)
		proj.direction = dir
		proj.damage = int(damage * 0.4)
		proj.speed = 10.0
		proj.lifetime = 4.0
		proj.collision_layer = 16  # Layer 5 = EnemyAttacks
		proj.collision_mask = 1    # Layer 1 = Players
		get_tree().current_scene.call_deferred("add_child", proj)

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
