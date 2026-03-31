extends EnemyBase3D

## Boss: Demon Lord (Volcano Stage). 3 fases baseadas em HP.
## Fase 1 (100-75%): Lento e poderoso. Aneis de fogo, spawna imps (bats como proxy, laranja)
## Fase 2 (75-25%): Lava floor damage. Charge no player, ground slam (dano em raio 4.0)
## Fase 3 (25-0%): Apocalypse - projeteis espiral, rapido, spawna lava golems (tanks como proxy)

var phase: int = 1
var summon_timer: float = 0.0
var attack_timer: float = 0.0
var charge_timer: float = 0.0
var slam_timer: float = 0.0
var lava_damage_timer: float = 0.0
var _fury_active := false
var is_charging: bool = false
var charge_direction: Vector3 = Vector3.ZERO
var charge_speed: float = 15.0
var charge_duration: float = 0.0
var bat_scene: PackedScene = preload("res://scenes/enemies/bat.tscn")
var tank_scene: PackedScene = preload("res://scenes/enemies/tank.tscn")
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _ready() -> void:
	resistances = {
		"physical": 0.7,
		"fire": 1.5,  # Imune a fogo
		"ice": 0.5,   # Fraco contra gelo
		"electric": 0.7,
		"dark": 0.7,
	}
	super._ready()
	# Extra boss HP scaling for multiplayer
	var boss_extra = GameManager.get_mp_boss_hp_mult() / GameManager.get_mp_hp_mult()
	if boss_extra > 1.0:
		max_hp = int(max_hp * boss_extra)
		hp = max_hp
	add_to_group("boss")
	enemy_color = Color(0.9, 0.2, 0.0)

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
		1: speed = 1.5
		2: speed = 3.0
		3: speed = 4.5
	if _fury_active:
		speed *= 1.5

	# Charge movement override
	if is_charging:
		charge_duration -= delta
		velocity = charge_direction * charge_speed
		move_and_slide()
		if charge_duration <= 0:
			is_charging = false
		return

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
	charge_timer -= delta
	slam_timer -= delta
	lava_damage_timer -= delta

	match phase:
		1:
			# Flame rings + spawn imps
			if attack_timer <= 0:
				attack_timer = 3.0
				_telegraph_attack(global_position, 3.0)
				_fire_flame_ring(8)
			if summon_timer <= 0:
				summon_timer = 5.0
				_telegraph_attack(global_position, 3.0)
				_summon_imps(3)
		2:
			# Lava floor damage + charge + ground slam
			if lava_damage_timer <= 0:
				lava_damage_timer = 1.0
				_lava_floor_damage()
			if charge_timer <= 0:
				charge_timer = 4.0
				_telegraph_attack(global_position, 4.0)
				_charge_at_player()
			if slam_timer <= 0:
				slam_timer = 5.0
				_telegraph_attack(global_position, 4.0)
				_ground_slam(4.0)
				BossAttackPatterns.circle_aoe(get_tree().current_scene, global_position, 4.0, int(damage * 0.5), 1.0, Color(1.0, 0.3, 0.0, 0.4))
			if attack_timer <= 0:
				attack_timer = 3.5
				_telegraph_attack(global_position, 3.0)
				_fire_flame_ring(6)
			if summon_timer <= 0:
				summon_timer = 6.0
				_telegraph_attack(global_position, 3.0)
				_summon_imps(4)
		3:
			# Apocalypse: spiral flames, fast, lava golems
			if attack_timer <= 0:
				attack_timer = 1.5
				_telegraph_attack(global_position, 4.0)
				_fire_flame_spiral(12)
				if target and is_instance_valid(target):
					var dir_to_player = (target.global_position - global_position).normalized()
					BossAttackPatterns.cone_aoe(get_tree().current_scene, global_position, dir_to_player, 6.0, 60.0, int(damage * 0.4), 0.8, Color(1.0, 0.4, 0.0, 0.3))
			if summon_timer <= 0:
				summon_timer = 5.0
				_telegraph_attack(global_position, 4.0)
				_summon_lava_golems(2)
			if slam_timer <= 0:
				slam_timer = 3.0
				_telegraph_attack(global_position, 4.0)
				_ground_slam(4.0)
			if lava_damage_timer <= 0:
				lava_damage_timer = 0.8
				_lava_floor_damage()

func _fire_flame_ring(count: int) -> void:
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
		proj.speed = 8.0
		proj.lifetime = 4.0
		proj.collision_layer = 16  # Layer 5 = EnemyAttacks
		proj.collision_mask = 1    # Layer 1 = Players
		get_tree().current_scene.call_deferred("add_child", proj)

func _fire_flame_spiral(count: int) -> void:
	if not target or not is_instance_valid(target):
		return
	AudioManager.play_sfx("boss_attack")
	var base_angle = fmod(Time.get_ticks_msec() / 500.0, TAU)
	for i in range(count):
		var angle = base_angle + (TAU / count) * i
		var dir = Vector3(cos(angle), 0, sin(angle))

		var proj = ObjectPool.get_instance(bullet_scene)
		proj.global_position = global_position + Vector3(0, 0.8, 0)
		proj.direction = dir
		proj.damage = int(damage * 0.4)
		proj.speed = 9.0
		proj.lifetime = 4.0
		proj.collision_layer = 16  # Layer 5 = EnemyAttacks
		proj.collision_mask = 1    # Layer 1 = Players
		get_tree().current_scene.call_deferred("add_child", proj)

func _summon_imps(count: int) -> void:
	for i in range(count):
		var imp = ObjectPool.get_instance(bat_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 3.0
		imp.global_position = global_position + offset
		if imp is EnemyBase3D:
			imp.xp_drop = 0  # Boss summons nao dao XP
			imp.enemy_color = Color(1.0, 0.5, 0.1)  # Laranja
		get_tree().current_scene.call_deferred("add_child", imp)
		GameManager.enemies_alive += 1

func _summon_lava_golems(count: int) -> void:
	for i in range(count):
		var golem = ObjectPool.get_instance(tank_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 4.0
		golem.global_position = global_position + offset
		if golem is EnemyBase3D:
			golem.xp_drop = 0  # Boss summons nao dao XP
			golem.enemy_color = Color(0.9, 0.3, 0.0)  # Lava
		get_tree().current_scene.call_deferred("add_child", golem)
		GameManager.enemies_alive += 1

func _charge_at_player() -> void:
	if not target or not is_instance_valid(target):
		return
	charge_direction = (target.global_position - global_position).normalized()
	charge_direction.y = 0
	is_charging = true
	charge_duration = 0.5
	ParticleFactory.spawn_death_particles(global_position, Color(1.0, 0.3, 0.0), 6)

func _ground_slam(radius: float) -> void:
	AudioManager.play_sfx("boss_attack")
	ParticleFactory.spawn_explosion_particles(global_position, radius)
	# Dano em area ao redor do boss
	var players = GameManager.get_players()
	for player in players:
		if is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist <= radius:
				if player.has_method("take_damage"):
					player.take_damage(int(damage * 0.6), global_position)

func _lava_floor_damage() -> void:
	# Dano periodico em todos os players (simulando lava floor)
	var players = GameManager.get_players()
	for player in players:
		if is_instance_valid(player) and player.has_method("take_damage"):
			player.take_damage(int(damage * 0.1), global_position)

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
