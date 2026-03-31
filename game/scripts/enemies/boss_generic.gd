extends "res://scripts/enemies/enemy_base.gd"

## Boss generico reutilizavel para bosses alternativos.
## Usa BossAttackPatterns para ataques de area (circulo, cone, ring).
## Configurado via metadata no _ready() da cena.

@export var boss_name: String = "Unknown Sentinel"
@export var boss_color: Color = Color(0.8, 0.2, 0.2)
@export var attack_style: String = "balanced"  # "melee", "ranged", "summoner", "balanced"

var phase: int = 1
var target: Node3D = null
var attack_timer: float = 3.0
var summon_timer: float = 5.0
var special_timer: float = 8.0

func _ready() -> void:
	super._ready()
	add_to_group("boss")
	enemy_color = boss_color
	_load_boss_sprite()

func _load_boss_sprite() -> void:
	# Tenta carregar sprite especifico do boss (ex: cemetery_lich.png)
	var snake_name = boss_name.to_snake_case().replace(" ", "_")
	var paths_to_try = [
		"res://assets/sprites/bosses/%s.png" % snake_name,
		"res://assets/sprites/bosses/%s.png" % name.to_snake_case(),
	]
	for path in paths_to_try:
		if ResourceLoader.exists(path):
			var tex = load(path) as Texture2D
			if tex:
				# Remove sprite existente do enemy_base e cria novo
				var old_sprite = get_node_or_null("EnemySprite")
				if old_sprite:
					old_sprite.queue_free()
				var sprite = Sprite3D.new()
				sprite.texture = tex
				sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				sprite.pixel_size = 0.07
				sprite.shaded = false
				sprite.transparent = true
				sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
				sprite.name = "EnemySprite"
				sprite.position.y = 0.65
				add_child(sprite)
				# Boss aura
				var aura = Sprite3D.new()
				aura.texture = tex
				aura.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				aura.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				aura.pixel_size = 0.09
				aura.shaded = false
				aura.transparent = true
				aura.modulate = Color(boss_color.r, boss_color.g, boss_color.b, 0.3)
				aura.name = "BossAura"
				aura.position.y = 0.65
				add_child(aura)
				# Name label
				var label = Label3D.new()
				label.text = boss_name.to_upper()
				label.font_size = 24
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				label.position = Vector3(0, 1.85, 0)
				label.name = "BossLabel"
				label.modulate = Color(boss_color.r, boss_color.g, boss_color.b, 0.9)
				add_child(label)
				return

func _process(delta: float) -> void:
	super._process(delta)
	if is_dead or not is_inside_tree():
		return

	# Update target
	var players = GameManager.get_players()
	if not players.is_empty():
		target = players[0]

	# Phase detection
	var hp_ratio = float(hp) / float(max_hp) if max_hp > 0 else 1.0
	var new_phase = 1
	if hp_ratio <= GameConstants.BOSS_PHASE_2_THRESHOLD:
		new_phase = 3
	elif hp_ratio <= GameConstants.BOSS_PHASE_1_THRESHOLD:
		new_phase = 2
	if new_phase != phase:
		phase = new_phase
		GameManager.boss_phase_changed.emit(boss_name, phase)
		AudioManager.play_sfx("boss_phase")

	# Fury mode
	if hp_ratio <= GameConstants.BOSS_FURY_THRESHOLD:
		speed = base_speed * 1.5

	# Timers
	attack_timer -= delta
	summon_timer -= delta
	special_timer -= delta

	_process_phase()

func _process_phase() -> void:
	var scene = get_tree().current_scene
	if not scene:
		return

	match phase:
		1:
			if attack_timer <= 0:
				attack_timer = 3.0
				_do_attack(scene, 1)
		2:
			if attack_timer <= 0:
				attack_timer = 2.0
				_do_attack(scene, 2)
			if special_timer <= 0:
				special_timer = 5.0
				_do_special(scene)
		3:
			if attack_timer <= 0:
				attack_timer = 1.2
				_do_attack(scene, 3)
			if special_timer <= 0:
				special_timer = 3.0
				_do_special(scene)
			if summon_timer <= 0:
				summon_timer = 4.0
				_do_summon(scene)

func _do_attack(scene: Node, intensity: int) -> void:
	match attack_style:
		"melee":
			# Cone AoE na direcao do jogador
			if target and is_instance_valid(target):
				var dir = (target.global_position - global_position).normalized()
				var cone_range = 4.0 + intensity
				BossAttackPatterns.cone_aoe(scene, global_position, dir, cone_range, 60.0 + intensity * 10, int(damage * 0.4), 0.8, Color(boss_color.r, boss_color.g, boss_color.b, 0.3))
			AudioManager.play_sfx("boss_attack")
		"ranged":
			# Projectile ring
			BossAttackPatterns.projectile_ring(scene, global_position, 4 + intensity * 2, int(damage * 0.3), 6.0 + intensity, boss_color)
		"summoner":
			# Circle AoE no proprio boss
			BossAttackPatterns.circle_aoe(scene, global_position, 3.0 + intensity, int(damage * 0.25), 1.0, Color(boss_color.r, boss_color.g, boss_color.b, 0.3))
		_:  # balanced
			# Alterna entre circle e projectile ring
			if randi() % 2 == 0:
				BossAttackPatterns.circle_aoe(scene, global_position, 3.5 + intensity * 0.5, int(damage * 0.3), 1.0, Color(boss_color.r, boss_color.g, boss_color.b, 0.3))
			else:
				BossAttackPatterns.projectile_ring(scene, global_position, 4 + intensity * 2, int(damage * 0.25), 7.0, boss_color)

func _do_special(scene: Node) -> void:
	if target and is_instance_valid(target):
		# Circle AoE na posicao do jogador (ataque surpresa)
		BossAttackPatterns.circle_aoe(scene, target.global_position, 3.0, int(damage * 0.5), 1.2, Color(boss_color.r * 0.8, boss_color.g * 0.8, boss_color.b * 0.8, 0.4))
	AudioManager.play_sfx("boss_attack")

func _do_summon(scene: Node) -> void:
	# Spawna 3-5 minions ao redor do boss
	var count = randi_range(3, 5)
	var slime_scene = preload("res://scenes/enemies/slime.tscn")
	for i in range(count):
		var angle = (float(i) / count) * TAU
		var spawn_pos = global_position + Vector3(cos(angle), 0, sin(angle)) * 3.0
		var minion = ObjectPool.get_instance(slime_scene)
		if minion is EnemyBase3D:
			minion.max_hp = int(minion.max_hp * 1.5)
			minion.hp = minion.max_hp
			minion.enemy_color = boss_color.lightened(0.3)
			minion.xp_drop = 0
		scene.add_child(minion)
		minion.global_position = spawn_pos
		GameManager.enemies_alive += 1
	AudioManager.play_sfx("summon_pop")
	ParticleFactory.spawn_explosion_particles(global_position, 2.0)

func get_max_hp() -> int:
	return max_hp
