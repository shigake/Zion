extends EnemyBase3D

## Boss: Rainha das Fadas (Forest Stage). 3 fases baseadas em HP.
## Fase 1 (100-75%): Teleporta a cada 5s, spawna fadas (bats como proxy)
## Fase 2 (75-25%): Cria 2 clones (1HP), chuva de espinhos (projeteis pra baixo)
## Fase 3 (25-0%): Frenzy - teleport rapido 2s, chuva constante, mais fadas

var phase: int = 1
var summon_timer: float = 0.0
var attack_timer: float = 0.0
var teleport_timer: float = 0.0
var clone_spawned: bool = false
var _fury_active := false
var bat_scene: PackedScene = preload("res://scenes/enemies/bat.tscn")
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _ready() -> void:
	resistances = {
		"physical": 0.8,
		"fire": 0.7,
		"ice": 0.7,
		"electric": 0.7,
		"dark": 0.5,  # Fraca contra dark
	}
	super._ready()
	# Extra boss HP scaling for multiplayer
	var boss_extra = GameManager.get_mp_boss_hp_mult() / GameManager.get_mp_hp_mult()
	if boss_extra > 1.0:
		max_hp = int(max_hp * boss_extra)
		hp = max_hp
	add_to_group("boss")
	enemy_color = Color(0.9, 0.3, 0.9)

func _physics_process(delta: float) -> void:
	if is_dead or GameManager.paused:
		return

	# Determina fase
	var old_phase = phase
	var hp_pct = float(hp) / float(max_hp)
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
	teleport_timer -= delta

	match phase:
		1:
			# Teleport every 5s, spawn fairies
			if teleport_timer <= 0:
				teleport_timer = 5.0
				_teleport_near_player()
			if summon_timer <= 0:
				summon_timer = 4.0
				_telegraph_attack(global_position, 3.0)
				_summon_fairies(3)
		2:
			# Clones + thorn rain
			if not clone_spawned:
				clone_spawned = true
				_telegraph_attack(global_position, 4.0)
				_spawn_clones(2)
			if attack_timer <= 0:
				attack_timer = 3.0
				if target and is_instance_valid(target):
					_telegraph_attack(target.global_position, 6.0)
					BossAttackPatterns.circle_aoe(get_tree().current_scene, target.global_position, 3.5, int(damage * 0.3), 1.0, Color(0.2, 0.8, 0.3, 0.3))
				_thorn_rain(6)
			if summon_timer <= 0:
				summon_timer = 5.0
				_telegraph_attack(global_position, 3.0)
				_summon_fairies(4)
			if teleport_timer <= 0:
				teleport_timer = 4.0
				_teleport_near_player()
		3:
			# Frenzy: rapid teleports, constant thorn rain, more fairies
			if teleport_timer <= 0:
				teleport_timer = 2.0
				_teleport_near_player()
			if attack_timer <= 0:
				attack_timer = 1.5
				if target and is_instance_valid(target):
					_telegraph_attack(target.global_position, 6.0)
				_thorn_rain(10)
			if summon_timer <= 0:
				summon_timer = 3.0
				_telegraph_attack(global_position, 4.0)
				_summon_fairies(6)

func _teleport_near_player() -> void:
	if not target or not is_instance_valid(target):
		return
	var angle = randf() * TAU
	var dist = randf_range(5.0, 10.0)
	var offset = Vector3(cos(angle), 0, sin(angle)) * dist
	global_position = target.global_position + offset
	# Visual feedback
	ParticleFactory.spawn_death_particles(global_position, enemy_color, 8)

func _summon_fairies(count: int) -> void:
	for i in range(count):
		var fairy = ObjectPool.get_instance(bat_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 3.0
		fairy.global_position = global_position + offset
		if fairy is EnemyBase3D:
			fairy.xp_drop = 0  # Boss summons nao dao XP
			fairy.enemy_color = Color(0.8, 0.5, 0.9)  # Cor de fada
		get_tree().current_scene.call_deferred("add_child", fairy)
		GameManager.enemies_alive += 1

func _spawn_clones(count: int) -> void:
	for i in range(count):
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 4.0
		var clone = ObjectPool.get_instance(bat_scene)
		if clone is EnemyBase3D:
			clone.max_hp = 1
			clone.hp = 1
			clone.damage = damage
			clone.speed = speed
			clone.xp_drop = 0
			clone.enemy_color = Color(0.9, 0.3, 0.9, 0.6)  # Semi-transparente
		clone.scale = Vector3(2.0, 2.0, 2.0)
		clone.global_position = global_position + offset
		get_tree().current_scene.call_deferred("add_child", clone)
		GameManager.enemies_alive += 1

func _thorn_rain(count: int) -> void:
	if not target or not is_instance_valid(target):
		return
	AudioManager.play_sfx("boss_attack")
	# Projeteis caindo do ceu em area ao redor do player
	var center = target.global_position
	for i in range(count):
		var proj = ObjectPool.get_instance(bullet_scene)
		var rand_offset = Vector3(randf_range(-6.0, 6.0), 0, randf_range(-6.0, 6.0))
		proj.global_position = center + rand_offset + Vector3(0, 10.0, 0)
		proj.direction = Vector3(0, -1, 0)  # Cai pra baixo
		proj.damage = int(damage * 0.4)
		proj.speed = 12.0
		proj.lifetime = 3.0
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
