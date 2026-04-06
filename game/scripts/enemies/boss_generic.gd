extends "res://scripts/enemies/enemy_base.gd"

## Boss generico reutilizavel para bosses alternativos.
## Usa BossAttackPatterns para ataques de area (circulo, cone, ring).
## Configurado via metadata no _ready() da cena.

@export var boss_name: String = "Unknown Sentinel"
@export var boss_color: Color = Color(0.8, 0.2, 0.2)
@export var attack_style: String = "balanced"  # "melee", "ranged", "summoner", "balanced"

var phase: int = 1
# target is inherited from enemy_base.gd
var attack_timer: float = 3.0
var summon_timer: float = 5.0
var special_timer: float = 8.0
var _phase3_transition_done: bool = false
var _boss_base_speed: float = 0.0

func _ready() -> void:
	# Assign thematic resistances based on stage if not already set
	if resistances.is_empty():
		_assign_stage_resistances()
	super._ready()
	add_to_group("boss")
	enemy_color = boss_color
	_boss_base_speed = speed
	_load_boss_sprite()

func _assign_stage_resistances() -> void:
	## Alt bosses get partial resistances based on their stage theme.
	var stage = GameManager.selected_stage
	match stage:
		"cemetery":
			resistances = {"dark": 0.6, "poison": 0.6}
		"forest":
			resistances = {"poison": 0.7, "dark": 0.7}
		"farm":
			resistances = {"physical": 0.8}
		"tokyo":
			resistances = {"electric": 0.7}
		"volcano":
			resistances = {"fire": 0.5, "ice": 1.3}
		"ocean":
			resistances = {"ice": 0.7, "electric": 1.3}
		"arena":
			resistances = {"physical": 0.7}
		"space":
			resistances = {"dark": 0.7, "poison": 0.5}
		"castle":
			resistances = {"dark": 0.5, "poison": 0.6}
		"candy":
			resistances = {"fire": 1.3, "ice": 1.3}

func _load_boss_sprite() -> void:
	# Tenta varias variantes do nome para encontrar o sprite
	var snake_name = boss_name.to_snake_case().replace(" ", "_")
	var node_snake = name.to_snake_case()
	var node_no_prefix = node_snake.replace("boss_", "")
	var paths_to_try = [
		"res://assets/sprites/bosses/%s.png" % node_no_prefix,   # cemetery_reaper
		"res://assets/sprites/bosses/%s.png" % snake_name,        # death_reaper
		"res://assets/sprites/bosses/%s.png" % node_snake,        # boss_cemetery_reaper
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

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead or not is_inside_tree():
		return

	# Update target — closest player, not always first
	var players = GameManager.get_players()
	if not players.is_empty():
		var closest_dist := INF
		for p in players:
			if is_instance_valid(p):
				var d := global_position.distance_squared_to(p.global_position)
				if d < closest_dist:
					closest_dist = d
					target = p

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
		if new_phase == 3 and not _phase3_transition_done:
			_phase3_transition_done = true
			ScreenEffects.boss_phase3_transition(global_position, boss_color)

	# Fury mode
	if hp_ratio <= GameConstants.BOSS_FURY_THRESHOLD:
		speed = _boss_base_speed * 1.5

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
	if not is_inside_tree():
		return
	match attack_style:
		"melee":
			# Cone AoE na direcao do jogador
			if target and is_instance_valid(target) and target.is_inside_tree():
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
	if not is_inside_tree():
		return
	if target and is_instance_valid(target) and target.is_inside_tree():
		# Circle AoE na posicao do jogador (ataque surpresa)
		BossAttackPatterns.circle_aoe(scene, target.global_position, 3.0, int(damage * 0.5), 1.2, Color(boss_color.r * 0.8, boss_color.g * 0.8, boss_color.b * 0.8, 0.4))
	AudioManager.play_sfx("boss_attack")

func _do_summon(scene: Node) -> void:
	if not is_inside_tree():
		return
	# Cap summons to prevent performance death spiral
	var current_summons := get_tree().get_nodes_in_group("boss_summon").size()
	if current_summons >= GameConstants.BOSS_MAX_SUMMONS:
		return
	# Spawna 3-5 minions ao redor do boss
	var count = randi_range(3, 5)
	count = mini(count, GameConstants.BOSS_MAX_SUMMONS - current_summons)
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
			minion.add_to_group("boss_summon")
		scene.call_deferred("add_child", minion)
		minion.global_position = spawn_pos
		GameManager.enemies_alive += 1
	AudioManager.play_sfx("summon_pop")
	ParticleFactory.spawn_explosion_particles(global_position, 2.0)

func get_max_hp() -> int:
	return max_hp
