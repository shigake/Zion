extends EnemyBase3D

## Boss: Imperador Corrompido (Arena Stage). 3 fases baseadas em HP.
## Fase 1 (100-75%): Comanda exercito - spawna gladiadores (skeletons), pilar de fogo (projetil alto dano)
## Fase 2 (75-25%): Combate pessoal - charge, sword sweep (dano frontal). Shield bearers (tanks)
## Fase 3 (25-0%): Corrupcao - chuva de fogo (thorn_rain fire), gladiadores constantes, muito rapido

var phase: int = 1
var summon_timer: float = 0.0
var attack_timer: float = 0.0
var charge_timer: float = 0.0
var sweep_timer: float = 0.0
var is_charging: bool = false
var charge_direction: Vector3 = Vector3.ZERO
var charge_speed: float = 14.0
var charge_duration: float = 0.0
var skeleton_scene: PackedScene = preload("res://scenes/enemies/skeleton.tscn")
var tank_scene: PackedScene = preload("res://scenes/enemies/tank.tscn")
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _ready() -> void:
	resistances = {
		"physical": 1.5,  # Resistente a fisico
		"fire": 0.7,
		"ice": 0.7,
		"electric": 0.7,
		"dark": 0.5,  # Fraco contra dark
	}
	super._ready()
	# Extra boss HP scaling for multiplayer
	var boss_extra = GameManager.get_mp_boss_hp_mult() / GameManager.get_mp_hp_mult()
	if boss_extra > 1.0:
		max_hp = int(max_hp * boss_extra)
		hp = max_hp
	add_to_group("boss")
	enemy_color = Color(0.8, 0.6, 0.1)

func _physics_process(delta: float) -> void:
	if is_dead or GameManager.paused:
		return

	# Determina fase
	var hp_pct = float(hp) / float(max_hp)
	if hp_pct > 0.75:
		phase = 1
	elif hp_pct > 0.25:
		phase = 2
	else:
		phase = 3

	# Velocidade por fase
	match phase:
		1: speed = 2.0
		2: speed = 3.5
		3: speed = 5.0

	# Charge movement override
	if is_charging:
		charge_duration -= delta
		velocity = charge_direction * charge_speed
		move_and_slide()
		if charge_duration <= 0:
			is_charging = false
			_sword_sweep()  # Sweep ao final do charge
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
	sweep_timer -= delta

	match phase:
		1:
			# Comanda exercito: gladiadores + pilar de fogo
			if summon_timer <= 0:
				summon_timer = 4.0
				_summon_gladiators(4)
			if attack_timer <= 0:
				attack_timer = 3.0
				_fire_pillar()
		2:
			# Combate pessoal: charge + sweep + shield bearers
			if charge_timer <= 0:
				charge_timer = 4.0
				_charge_at_player()
			if sweep_timer <= 0:
				sweep_timer = 3.0
				_sword_sweep()
			if summon_timer <= 0:
				summon_timer = 6.0
				_summon_shield_bearers(2)
			if attack_timer <= 0:
				attack_timer = 3.5
				_fire_pillar()
		3:
			# Corrupcao: chuva de fogo, gladiadores constantes, muito rapido
			if attack_timer <= 0:
				attack_timer = 1.5
				_fire_rain(10)
			if summon_timer <= 0:
				summon_timer = 3.0
				_summon_gladiators(6)
			if charge_timer <= 0:
				charge_timer = 3.0
				_charge_at_player()
			if sweep_timer <= 0:
				sweep_timer = 2.0
				_sword_sweep()

func _summon_gladiators(count: int) -> void:
	for i in range(count):
		var glad = skeleton_scene.instantiate()
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 4.0
		glad.global_position = global_position + offset
		if glad is EnemyBase3D:
			glad.xp_drop = 0  # Boss summons nao dao XP
			glad.enemy_color = Color(0.7, 0.5, 0.2)  # Bronze gladiador
		get_tree().current_scene.call_deferred("add_child", glad)
		GameManager.enemies_alive += 1

func _summon_shield_bearers(count: int) -> void:
	for i in range(count):
		var bearer = tank_scene.instantiate()
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 3.0
		bearer.global_position = global_position + offset
		if bearer is EnemyBase3D:
			bearer.xp_drop = 0  # Boss summons nao dao XP
			bearer.enemy_color = Color(0.8, 0.6, 0.2)  # Bronze
		get_tree().current_scene.call_deferred("add_child", bearer)
		GameManager.enemies_alive += 1

func _fire_pillar() -> void:
	if not target or not is_instance_valid(target):
		return
	# Projetil unico de alto dano direcionado ao player
	var dir = (target.global_position - global_position).normalized()
	dir.y = 0

	var proj = bullet_scene.instantiate()
	proj.global_position = global_position + Vector3(0, 0.8, 0)
	proj.direction = dir
	proj.damage = int(damage * 1.0)  # Alto dano
	proj.speed = 12.0
	proj.lifetime = 4.0
	proj.collision_layer = 16  # Layer 5 = EnemyAttacks
	proj.collision_mask = 1    # Layer 1 = Players
	get_tree().current_scene.call_deferred("add_child", proj)

func _charge_at_player() -> void:
	if not target or not is_instance_valid(target):
		return
	charge_direction = (target.global_position - global_position).normalized()
	charge_direction.y = 0
	is_charging = true
	charge_duration = 0.5
	ParticleFactory.spawn_death_particles(global_position, Color(0.9, 0.6, 0.1), 6)

func _sword_sweep() -> void:
	# Dano em arco frontal (180 graus na frente do boss)
	ParticleFactory.spawn_death_particles(global_position, Color(0.8, 0.6, 0.1), 8)
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist <= 4.0:
				# Verifica se esta na frente (arco 180 graus)
				var to_player = (player.global_position - global_position).normalized()
				var facing = velocity.normalized() if velocity.length() > 0.1 else Vector3.FORWARD
				facing.y = 0
				to_player.y = 0
				if facing.dot(to_player) > 0:  # Na frente
					if player.has_method("take_damage"):
						player.take_damage(int(damage * 0.6))

func _fire_rain(count: int) -> void:
	if not target or not is_instance_valid(target):
		return
	# Pilares de fogo caindo do ceu (como thorn_rain mas cor de fogo)
	var center = target.global_position
	for i in range(count):
		var proj = bullet_scene.instantiate()
		var rand_offset = Vector3(randf_range(-6.0, 6.0), 0, randf_range(-6.0, 6.0))
		proj.global_position = center + rand_offset + Vector3(0, 10.0, 0)
		proj.direction = Vector3(0, -1, 0)  # Cai pra baixo
		proj.damage = int(damage * 0.4)
		proj.speed = 12.0
		proj.lifetime = 3.0
		proj.collision_layer = 16  # Layer 5 = EnemyAttacks
		proj.collision_mask = 1    # Layer 1 = Players
		get_tree().current_scene.call_deferred("add_child", proj)

func _die() -> void:
	if is_dead:
		return
	# Boss death: slow motion + massive particles
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
