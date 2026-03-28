extends EnemyBase3D

## Boss: Rei Acucar (Candy Stage). 3 fases baseadas em HP.
## Fase 1 (100-75%): Lento e pegajoso, projeteis de doce, spawna gummy bears (slimes)
## Fase 2 (75-25%): Sugar rush - velocidade dobra, burst estrela 8 direcoes, cupcake bombers
## Fase 3 (25-0%): Meltdown - exercito de doces, projeteis constantes, cura 1% HP a cada 5s

var phase: int = 1
var summon_timer: float = 0.0
var attack_timer: float = 0.0
var heal_timer: float = 0.0
var star_timer: float = 0.0
var _fury_active := false

var slime_scene: PackedScene = preload("res://scenes/enemies/slime.tscn")
var slime_big_scene: PackedScene = preload("res://scenes/enemies/slime_big.tscn")
var bomber_scene: PackedScene = preload("res://scenes/enemies/bomber.tscn")
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

# Cores de doce aleatorias
var candy_colors: Array[Color] = [
	Color(1.0, 0.3, 0.5),   # Rosa
	Color(0.3, 1.0, 0.5),   # Verde menta
	Color(1.0, 0.8, 0.2),   # Amarelo
	Color(0.5, 0.3, 1.0),   # Roxo
	Color(1.0, 0.5, 0.2),   # Laranja
	Color(0.3, 0.8, 1.0),   # Azul claro
]

func _ready() -> void:
	resistances = {
		"physical": 0.8,
		"fire": 0.5,  # Fraco contra fogo (derrete)
		"ice": 0.5,   # Resistente a gelo (ja e doce gelado)
		"electric": 0.8,
		"dark": 0.8,
	}
	super._ready()
	# Extra boss HP scaling for multiplayer
	var boss_extra = GameManager.get_mp_boss_hp_mult() / GameManager.get_mp_hp_mult()
	if boss_extra > 1.0:
		max_hp = int(max_hp * boss_extra)
		hp = max_hp
	add_to_group("boss")
	enemy_color = Color(1.0, 0.5, 0.7)

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
		2: speed = 3.0  # Sugar rush - dobra
		3: speed = 4.0  # Meltdown - mais rapido ainda
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
	heal_timer -= delta
	star_timer -= delta

	match phase:
		1:
			# Candy projectiles
			if attack_timer <= 0:
				attack_timer = 3.0
				_telegraph_attack(global_position, 3.0)
				_candy_projectiles(4)
			# Summon gummy bears (slimes com cores aleatorias)
			if summon_timer <= 0:
				summon_timer = 5.0
				_telegraph_attack(global_position, 3.0)
				_summon_gummy_bears(3)
		2:
			# Star pattern burst (8 directions)
			if star_timer <= 0:
				star_timer = 2.5
				_telegraph_attack(global_position, 3.0)
				_star_burst(8)
			# Candy projectiles
			if attack_timer <= 0:
				attack_timer = 3.5
				_telegraph_attack(global_position, 3.0)
				_candy_projectiles(6)
			# Summon cupcake bombers
			if summon_timer <= 0:
				summon_timer = 5.0
				_telegraph_attack(global_position, 4.0)
				_summon_cupcake_bombers(2)
		3:
			# Meltdown: constant star projectiles
			if star_timer <= 0:
				star_timer = 1.5
				_telegraph_attack(global_position, 4.0)
				_star_burst(8)
			# Massive candy army
			if summon_timer <= 0:
				summon_timer = 3.5
				_telegraph_attack(global_position, 5.0)
				_summon_gummy_bears(5)
				_summon_cupcake_bombers(1)
			# Candy projectiles
			if attack_timer <= 0:
				attack_timer = 2.0
				_telegraph_attack(global_position, 3.0)
				_candy_projectiles(8)
			# Heal 1% HP every 5 seconds
			if heal_timer <= 0:
				heal_timer = 5.0
				var heal_amount = int(max_hp * 0.01)
				hp = min(hp + heal_amount, max_hp)
				# Visual feedback da cura
				ParticleFactory.spawn_death_particles(global_position, Color(1.0, 0.8, 0.9), 4)

func _candy_projectiles(count: int) -> void:
	if not target or not is_instance_valid(target):
		return
	AudioManager.play_sfx("boss_attack")
	var base_dir = (target.global_position - global_position).normalized()
	base_dir.y = 0
	for i in range(count):
		var proj = ObjectPool.get_instance(bullet_scene)
		var spread = Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
		var dir = (base_dir + spread).normalized()
		proj.global_position = global_position + dir * 1.5
		proj.direction = dir
		proj.damage = int(damage * 0.3)
		proj.speed = 7.0
		proj.lifetime = 4.0
		proj.collision_layer = 16
		proj.collision_mask = 1
		get_tree().current_scene.call_deferred("add_child", proj)

func _star_burst(count: int) -> void:
	AudioManager.play_sfx("boss_attack")
	for i in range(count):
		var proj = ObjectPool.get_instance(bullet_scene)
		var angle = (TAU / count) * i
		var dir = Vector3(cos(angle), 0, sin(angle))
		proj.global_position = global_position + dir * 1.5
		proj.direction = dir
		proj.damage = int(damage * 0.3)
		proj.speed = 9.0
		proj.lifetime = 4.0
		proj.collision_layer = 16
		proj.collision_mask = 1
		get_tree().current_scene.call_deferred("add_child", proj)

func _summon_gummy_bears(count: int) -> void:
	for i in range(count):
		var gummy = ObjectPool.get_instance(slime_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 3.0
		gummy.global_position = global_position + offset
		if gummy is EnemyBase3D:
			gummy.xp_drop = 0
			gummy.enemy_color = candy_colors[randi() % candy_colors.size()]
		get_tree().current_scene.call_deferred("add_child", gummy)
		GameManager.enemies_alive += 1

func _summon_cupcake_bombers(count: int) -> void:
	for i in range(count):
		var bomber = ObjectPool.get_instance(bomber_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 4.0
		bomber.global_position = global_position + offset
		if bomber is EnemyBase3D:
			bomber.xp_drop = 0
			bomber.enemy_color = Color(1.0, 0.6, 0.8)  # Rosa cupcake
		get_tree().current_scene.call_deferred("add_child", bomber)
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
