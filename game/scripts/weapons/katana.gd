extends Node3D

## Espada Samurai — ataque automatico em arco na frente do jogador.

var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.2

@onready var slash_area: Area3D = $SlashArea
@onready var slash_mesh: MeshInstance3D = $SlashMesh

var hit_enemies: Array = []  # Evita multi-hit no mesmo swing
var _trail: Node3D = null
var _slash_tex: Texture2D = null

func _ready() -> void:
	slash_mesh.visible = false
	slash_mesh.mesh = null  # Hide debug geometry; trail + slash sprites provide visual feedback
	slash_area.body_entered.connect(_on_body_entered)
	# Load slash trail sprite
	var _slash_path2 = "res://assets/sprites/effects/slashes/katana_slash.png"
	if ResourceLoader.exists(_slash_path2):
		_slash_tex = load(_slash_path2)
	# Weapon trail — bright white-to-light-blue gradient
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(1.0, 1.0, 1.0, 0.8)
	_trail.trail_color_tip = Color(0.6, 0.8, 1.0, 0.9)
	_trail.max_points = 18
	_trail.trail_width = 0.35  # PRD 34: thicker, more visible trail
	slash_mesh.add_child(_trail)
	# Billboard sprite
	var _sprite_path = "res://assets/sprites/weapons/katana.png"
	if ResourceLoader.exists(_sprite_path):
		slash_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.045  # PRD 34: larger katana visual
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "WeaponSprite"
		slash_area.add_child(sprite)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("katana")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("katana", level) / GameManager.attack_speed_mult

	if is_attacking:
		attack_anim_timer -= delta
		# Rotaciona o slash durante o ataque (arco de 120 graus)
		var progress = 1.0 - (attack_anim_timer / attack_duration)
		var arc_angle = lerp(-1.05, 1.05, progress)  # ~60 graus pra cada lado
		slash_area.rotation.y = arc_angle
		slash_mesh.rotation.y = arc_angle

		if attack_anim_timer <= 0:
			is_attacking = false
			slash_mesh.visible = false
			slash_area.monitoring = false
			hit_enemies.clear()
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			_attack(level)
			attack_timer = cooldown

func _attack(level: int) -> void:
	if not is_inside_tree():
		return
	is_attacking = true
	attack_anim_timer = attack_duration
	slash_mesh.visible = true
	slash_area.monitoring = true
	hit_enemies.clear()

	# Auto-aim toward nearest enemy (instinto dimensional)
	var player = get_parent().get_parent() if get_parent() else null
	if player and is_instance_valid(player):
		var aimed = false
		if GameManager.manual_aim and GameManager.aim_direction.length_squared() > 0.01:
			var aim_angle = atan2(-GameManager.aim_direction.x, -GameManager.aim_direction.z)
			global_rotation.y = aim_angle
			aimed = true
		else:
			var enemies = GameManager.get_enemies()
			if not enemies.is_empty():
				var nearest: Node3D = null
				var min_dist = INF
				for e in enemies:
					if not is_instance_valid(e):
						continue
					var d = player.global_position.distance_squared_to(e.global_position)
					if d < min_dist:
						min_dist = d
						nearest = e
				if nearest:
					var dir = nearest.global_position - player.global_position
					dir.y = 0.0
					if dir.length_squared() > 0.01:
						dir = dir.normalized()
						global_rotation.y = atan2(-dir.x, -dir.z)
						aimed = true
		# Fallback: aim in player's movement direction
		if not aimed and player is CharacterBody3D:
			var vel = player.velocity
			vel.y = 0.0
			if vel.length_squared() > 0.1:
				global_rotation.y = atan2(-vel.x, -vel.z)

	# Escala o slash com base no level
	var area_scale = 1.0 + (level - 1) * 0.15
	slash_area.scale = Vector3.ONE * area_scale
	slash_mesh.scale = Vector3.ONE * area_scale

	AudioManager.play_sfx("sword_slash")

	# Slash trail visual
	_spawn_slash_trail()

func _spawn_slash_trail() -> void:
	WeaponVFX.spawn_slash_trail(self, _slash_tex, global_position + Vector3(0, 0.5, 0))

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("katana")
		var dmg = int(WeaponDB.get_damage("katana", level))
		GameManager._last_attacking_weapon = "katana"
		body.call_deferred("take_damage", dmg, "physical")
		hit_enemies.append(body)
		# Impact sparks at hit position
		ParticleFactory.spawn_slash_sparks(body.global_position + Vector3(0, 0.5, 0), 5)
		ScreenEffects.shake(0.03)
