extends EnemyBase3D

## Boss: Leviathan (Ocean Stage). 3 fases baseadas em HP.
## Fase 1 (100-75%): Quase invisivel. Ataca com tentaculos - projeteis de 4 direcoes
## Fase 2 (75-25%): Visivel, rapido. Vortex puxa player, ink cloud (overlay escuro 3s)
## Fase 3 (25-0%): Rage total. Tentacle slam (area 5.0), barrage constante, spawna jellyfish (ghosts)

var phase: int = 1
var summon_timer: float = 0.0
var attack_timer: float = 0.0
var vortex_timer: float = 0.0
var ink_timer: float = 0.0
var slam_timer: float = 0.0
var _fury_active := false
var ink_cloud_active: bool = false
var ink_cloud_remaining: float = 0.0
var ghost_scene: PackedScene = preload("res://scenes/enemies/ghost.tscn")
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _ready() -> void:
	resistances = {
		"physical": 0.7,
		"fire": 0.7,
		"ice": 1.5,  # Resistente a gelo
		"electric": 0.5,  # Fraco contra eletrico
		"dark": 0.7,
	}
	super._ready()
	# Extra boss HP scaling for multiplayer
	var boss_extra = GameManager.get_mp_boss_hp_mult() / GameManager.get_mp_hp_mult()
	if boss_extra > 1.0:
		max_hp = int(max_hp * boss_extra)
		hp = max_hp
	add_to_group("boss")
	enemy_color = Color(0.1, 0.2, 0.4)

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
		2: speed = 3.5
		3: speed = 4.5
	if _fury_active:
		speed *= 1.5

	# Invisibilidade na fase 1
	_update_visibility()

	# Movimento
	_find_target()
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		direction.y = 0
		velocity = direction * speed
		move_and_slide()

	# Ink cloud timer
	if ink_cloud_active:
		ink_cloud_remaining -= delta
		if ink_cloud_remaining <= 0:
			ink_cloud_active = false

	# Timers
	summon_timer -= delta
	attack_timer -= delta
	vortex_timer -= delta
	ink_timer -= delta
	slam_timer -= delta

	match phase:
		1:
			# Tentacle attack: projectiles from 4 directions toward player
			if attack_timer <= 0:
				attack_timer = 3.0
				if target and is_instance_valid(target):
					_telegraph_attack(target.global_position, 3.0)
				_tentacle_attack(4)
		2:
			# Visible, faster. Vortex + ink cloud
			if attack_timer <= 0:
				attack_timer = 2.5
				if target and is_instance_valid(target):
					_telegraph_attack(target.global_position, 4.0)
				_tentacle_attack(6)
			if vortex_timer <= 0:
				vortex_timer = 4.0
				_telegraph_attack(global_position, 5.0)
				_water_vortex()
			if ink_timer <= 0:
				ink_timer = 8.0
				if target and is_instance_valid(target):
					_telegraph_attack(target.global_position, 5.0)
				_ink_cloud()
		3:
			# Full rage: tentacle slam, barrage, jellyfish
			if attack_timer <= 0:
				attack_timer = 1.0
				if target and is_instance_valid(target):
					_telegraph_attack(target.global_position, 4.0)
				_tentacle_attack(8)
			if slam_timer <= 0:
				slam_timer = 3.0
				_telegraph_attack(global_position, 5.0)
				_tentacle_slam(5.0)
			if summon_timer <= 0:
				summon_timer = 4.0
				_telegraph_attack(global_position, 3.0)
				_summon_jellyfish(4)
			if vortex_timer <= 0:
				vortex_timer = 5.0
				_telegraph_attack(global_position, 5.0)
				_water_vortex()

func _update_visibility() -> void:
	var mesh = get_node_or_null("Mesh")
	if mesh:
		if phase == 1:
			# Quase invisivel - apenas olhos brilham
			mesh.transparency = 0.85
		else:
			mesh.transparency = 0.0

func _tentacle_attack(count: int) -> void:
	if not target or not is_instance_valid(target):
		return
	# Projeteis disparados de posicoes ao redor do player em direcao a ele
	var center = target.global_position
	for i in range(count):
		var angle = (TAU / count) * i
		var spawn_offset = Vector3(cos(angle), 0, sin(angle)) * 8.0
		var spawn_pos = center + spawn_offset
		var dir = (center - spawn_pos).normalized()

		var proj = ObjectPool.get_instance(bullet_scene)
		proj.global_position = spawn_pos + Vector3(0, 0.8, 0)
		proj.direction = dir
		proj.damage = int(damage * 0.4)
		proj.speed = 10.0
		proj.lifetime = 3.0
		proj.collision_layer = 16  # Layer 5 = EnemyAttacks
		proj.collision_mask = 1    # Layer 1 = Players
		get_tree().current_scene.call_deferred("add_child", proj)

func _water_vortex() -> void:
	if not target or not is_instance_valid(target):
		return
	# Puxa player em direcao ao boss
	var players = GameManager.get_players()
	for player in players:
		if is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist <= 12.0 and dist > 1.0:
				var pull_dir = (global_position - player.global_position).normalized()
				pull_dir.y = 0
				player.global_position += pull_dir * 2.0
	ParticleFactory.spawn_death_particles(global_position, Color(0.2, 0.4, 0.8), 10)

func _ink_cloud() -> void:
	ink_cloud_active = true
	ink_cloud_remaining = 3.0
	# Visual: dark particles around player area
	if target and is_instance_valid(target):
		for i in range(8):
			var offset = Vector3(randf_range(-5.0, 5.0), 0, randf_range(-5.0, 5.0))
			ParticleFactory.spawn_death_particles(target.global_position + offset, Color(0.05, 0.05, 0.1), 5)

func _tentacle_slam(radius: float) -> void:
	ParticleFactory.spawn_explosion_particles(global_position, radius)
	# Dano em area ao redor do boss
	var players = GameManager.get_players()
	for player in players:
		if is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist <= radius:
				if player.has_method("take_damage"):
					player.take_damage(int(damage * 0.7), global_position)

func _summon_jellyfish(count: int) -> void:
	for i in range(count):
		var jelly = ObjectPool.get_instance(ghost_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 3.0
		jelly.global_position = global_position + offset
		if jelly is EnemyBase3D:
			jelly.xp_drop = 0  # Boss summons nao dao XP
			jelly.enemy_color = Color(0.3, 0.5, 1.0)  # Azul jellyfish
		get_tree().current_scene.call_deferred("add_child", jelly)
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
