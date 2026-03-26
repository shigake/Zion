extends EnemyBase3D

## Boss: Necromancer King. 3 fases de comportamento baseadas em HP.
## Fase 1 (100-75%): Persegue lentamente, invoca esqueletos
## Fase 2 (75-25%): Mais rapido, dispara projeteis + invoca
## Fase 3 (25-0%): Frenzy mode, muito rapido, spam de invocacoes

var phase: int = 1
var summon_timer: float = 0.0
var attack_timer: float = 0.0
var skeleton_scene: PackedScene = preload("res://scenes/enemies/skeleton.tscn")
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _ready() -> void:
	# Boss tem resistencia parcial a todos os tipos
	resistances = {
		"physical": 0.7,
		"fire": 0.7,
		"ice": 0.7,
		"electric": 0.7,
		"dark": 0.5,  # Mais resistente a dark (ele e necromante)
	}
	super._ready()
	# Extra boss HP scaling for multiplayer (on top of base enemy scaling)
	var boss_extra = GameManager.get_mp_boss_hp_mult() / GameManager.get_mp_hp_mult()
	if boss_extra > 1.0:
		max_hp = int(max_hp * boss_extra)
		hp = max_hp
	add_to_group("boss")
	enemy_color = Color(0.2, 0.0, 0.3)
	# Modelo procedural já aplicado pelo enemy_base._ready()

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

	# Movimento (herda do base)
	_find_target()
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		direction.y = 0
		velocity = direction * speed
		move_and_slide()

	# Acoes por fase
	summon_timer -= delta
	attack_timer -= delta

	match phase:
		1:
			if summon_timer <= 0:
				summon_timer = 5.0
				_summon_skeletons(3)
		2:
			if summon_timer <= 0:
				summon_timer = 4.0
				_summon_skeletons(5)
			if attack_timer <= 0:
				attack_timer = 2.0
				_fire_projectiles(4)
		3:
			if summon_timer <= 0:
				summon_timer = 2.0
				_summon_skeletons(8)
			if attack_timer <= 0:
				attack_timer = 1.0
				_fire_projectiles(8)

func _summon_skeletons(count: int) -> void:
	for i in range(count):
		var sk = skeleton_scene.instantiate()
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 3.0
		sk.global_position = global_position + offset
		if sk is EnemyBase3D:
			sk.xp_drop = 0  # Boss summons nao dao XP
		get_tree().current_scene.call_deferred("add_child", sk)
		GameManager.enemies_alive += 1

func _fire_projectiles(count: int) -> void:
	if not target or not is_instance_valid(target):
		return
	for i in range(count):
		var angle = (TAU / count) * i
		var dir = Vector3(cos(angle), 0, sin(angle))

		var proj = bullet_scene.instantiate()
		proj.global_position = global_position + Vector3(0, 0.8, 0)
		proj.direction = dir
		proj.damage = int(damage * 0.5)
		proj.speed = 8.0
		proj.lifetime = 4.0
		# Muda collision pra acertar player
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
