extends EnemyBase3D

## Boss: Conde Dracula (Castle Stage). 3 fases baseadas em HP.
## Fase 1 (100-75%): Teleporta em forma de morcego, spawna enxames, drena vida
## Fase 2 (75-25%): Transforma (maior), leque de projeteis, vampiros minions, charme
## Fase 3 (25-0%): Morcego gigante - muito rapido, chuva de sangue, drenagem constante

var phase: int = 1
var summon_timer: float = 0.0
var attack_timer: float = 0.0
var teleport_timer: float = 0.0
var charm_timer: float = 0.0
var transformed: bool = false
var _fury_active := false

var bat_scene: PackedScene = preload("res://scenes/enemies/bat.tscn")
var skeleton_scene: PackedScene = preload("res://scenes/enemies/skeleton.tscn")
var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

func _ready() -> void:
	resistances = {
		"physical": 0.8,
		"fire": 0.5,  # Fraco contra fogo
		"ice": 0.8,
		"electric": 0.8,
		"dark": 0.3,  # Resistente a dark
	}
	super._ready()
	# Extra boss HP scaling for multiplayer
	var boss_extra = GameManager.get_mp_boss_hp_mult() / GameManager.get_mp_hp_mult()
	if boss_extra > 1.0:
		max_hp = int(max_hp * boss_extra)
		hp = max_hp
	add_to_group("boss")
	enemy_color = Color(0.4, 0.0, 0.1)

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
		1: speed = 2.5
		2: speed = 3.5
		3: speed = 6.0
	if _fury_active:
		speed *= 1.5

	# Transformacao na fase 2
	if phase >= 2 and not transformed:
		transformed = true
		scale = Vector3(1.3, 1.3, 1.3) * scale

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
	charm_timer -= delta

	match phase:
		1:
			# Bat form teleport every 6s
			if teleport_timer <= 0:
				teleport_timer = 6.0
				_teleport_bat_form()
			# Summon bat swarms
			if summon_timer <= 0:
				summon_timer = 5.0
				_telegraph_attack(global_position, 3.0)
				_summon_bats(4)
		2:
			# Blood fan projectiles
			if attack_timer <= 0:
				attack_timer = 3.0
				_telegraph_attack(global_position, 3.0)
				_blood_fan(5)
			# Summon vampire minions (skeletons)
			if summon_timer <= 0:
				summon_timer = 5.0
				_telegraph_attack(global_position, 4.0)
				_summon_vampires(3)
			# Charm attack
			if charm_timer <= 0:
				charm_timer = 8.0
				_telegraph_attack(global_position, 2.0)
				_charm_projectile()
			# Teleport
			if teleport_timer <= 0:
				teleport_timer = 5.0
				_teleport_bat_form()
		3:
			# Giant bat form: constant bat summons
			if summon_timer <= 0:
				summon_timer = 2.5
				_telegraph_attack(global_position, 4.0)
				_summon_bats(6)
			# Blood rain (projectiles from sky)
			if attack_timer <= 0:
				attack_timer = 2.0
				if target and is_instance_valid(target):
					_telegraph_attack(target.global_position, 7.0)
				_blood_rain(8)
			# Rapid teleport
			if teleport_timer <= 0:
				teleport_timer = 3.0
				_teleport_bat_form()
			# Charm
			if charm_timer <= 0:
				charm_timer = 6.0
				_telegraph_attack(global_position, 2.0)
				_charm_projectile()

func _teleport_bat_form() -> void:
	if not target or not is_instance_valid(target):
		return
	# Efeito visual no ponto de origem
	ParticleFactory.spawn_death_particles(global_position, Color(0.3, 0.0, 0.05), 6)
	var angle = randf() * TAU
	var dist = randf_range(4.0, 8.0)
	var offset = Vector3(cos(angle), 0, sin(angle)) * dist
	global_position = target.global_position + offset
	# Efeito visual no destino
	ParticleFactory.spawn_death_particles(global_position, enemy_color, 6)

func _summon_bats(count: int) -> void:
	for i in range(count):
		var bat = ObjectPool.get_instance(bat_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 3.0
		bat.global_position = global_position + offset
		if bat is EnemyBase3D:
			bat.xp_drop = 0
			bat.enemy_color = Color(0.3, 0.0, 0.05)  # Vermelho escuro
		get_tree().current_scene.call_deferred("add_child", bat)
		GameManager.enemies_alive += 1

func _summon_vampires(count: int) -> void:
	for i in range(count):
		var vamp = ObjectPool.get_instance(skeleton_scene)
		var angle = (TAU / count) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * 4.0
		vamp.global_position = global_position + offset
		if vamp is EnemyBase3D:
			vamp.xp_drop = 0
			vamp.enemy_color = Color(0.7, 0.6, 0.6)  # Palido
		get_tree().current_scene.call_deferred("add_child", vamp)
		GameManager.enemies_alive += 1

func _blood_fan(count: int) -> void:
	if not target or not is_instance_valid(target):
		return
	AudioManager.play_sfx("boss_attack")
	var base_dir = (target.global_position - global_position).normalized()
	base_dir.y = 0
	var base_angle = atan2(base_dir.z, base_dir.x)
	var spread = PI / 4.0  # 45 grau spread total
	for i in range(count):
		var proj = ObjectPool.get_instance(bullet_scene)
		var angle_offset = -spread / 2.0 + (spread / (count - 1)) * i
		var angle = base_angle + angle_offset
		var dir = Vector3(cos(angle), 0, sin(angle))
		proj.global_position = global_position + dir * 1.5
		proj.direction = dir
		proj.damage = int(damage * 0.35)
		proj.speed = 10.0
		proj.lifetime = 4.0
		proj.collision_layer = 16
		proj.collision_mask = 1
		get_tree().current_scene.call_deferred("add_child", proj)

func _blood_rain(count: int) -> void:
	if not target or not is_instance_valid(target):
		return
	AudioManager.play_sfx("boss_attack")
	var center = target.global_position
	for i in range(count):
		var proj = ObjectPool.get_instance(bullet_scene)
		var rand_offset = Vector3(randf_range(-7.0, 7.0), 0, randf_range(-7.0, 7.0))
		proj.global_position = center + rand_offset + Vector3(0, 10.0, 0)
		proj.direction = Vector3(0, -1, 0)
		proj.damage = int(damage * 0.4)
		proj.speed = 12.0
		proj.lifetime = 3.0
		proj.collision_layer = 16
		proj.collision_mask = 1
		get_tree().current_scene.call_deferred("add_child", proj)

func _charm_projectile() -> void:
	if not target or not is_instance_valid(target):
		return
	var proj = ObjectPool.get_instance(bullet_scene)
	var dir = (target.global_position - global_position).normalized()
	dir.y = 0
	proj.global_position = global_position + dir * 1.5
	proj.direction = dir
	proj.damage = int(damage * 0.2)
	proj.speed = 5.0  # Lento
	proj.lifetime = 6.0
	proj.collision_layer = 16
	proj.collision_mask = 1
	# Sinaliza charme via metadata para o player detectar
	proj.set_meta("charm", true)
	proj.set_meta("charm_duration", 3.0)
	get_tree().current_scene.call_deferred("add_child", proj)

## Drena vida: cura o boss com base no dano causado
func take_damage(amount: int, type: String = "physical") -> void:
	super.take_damage(amount, type)

## Override do contato para drenar vida
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players") and not is_dead:
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
			# Lifedrain: cura 10% do dano causado (fase 1+), mais em fase 3
			var drain_pct = 0.1
			if phase == 3:
				drain_pct = 0.2
			var heal_amount = int(damage * drain_pct)
			hp = min(hp + heal_amount, max_hp)

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
