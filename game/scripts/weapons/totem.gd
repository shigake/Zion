extends Node3D

## Totem — planta uma torreta estacionaria que causa dano em area.

var place_timer: float = 0.0
var active_totems: Array = []

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("totem")
	if level <= 0:
		return

	# Clean up destroyed totems
	active_totems = active_totems.filter(func(t): return is_instance_valid(t))

	var max_totems = 1
	if level >= 5:
		max_totems = 2

	var cooldown = WeaponDB.get_cooldown("totem", level) * GameManager.cooldown_mult
	place_timer -= delta
	if place_timer <= 0 and active_totems.size() < max_totems:
		place_timer = cooldown
		_place_totem(level)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _place_totem(level: int) -> void:
	if not is_inside_tree():
		return
	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	var totem = Node3D.new()
	totem.name = "Totem"
	totem.global_position = player_pos

	# Visual: pixel art sprite billboard
	var sprite_path = "res://assets/sprites/weapons/totem.png"
	if ResourceLoader.exists(sprite_path):
		var sprite = Sprite3D.new()
		sprite.texture = load(sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.06
		sprite.shaded = false
		sprite.transparent = true
		sprite.position.y = 0.7
		sprite.name = "TotemSprite"
		totem.add_child(sprite)

	# Damage area
	var area = Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 2
	area.monitoring = true
	var shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	var area_radius = 4.0 + (level - 1) * 0.5
	sphere.radius = area_radius
	shape.shape = sphere
	area.add_child(shape)
	totem.add_child(area)

	# -- Electric zap sprite (pulsing around totem) --
	var zap_sprite_path = "res://assets/sprites/projectiles/lightning_bolt.png"
	if ResourceLoader.exists(zap_sprite_path):
		var zap_tex = load(zap_sprite_path)
		for i in range(3):
			var zap = Sprite3D.new()
			zap.texture = zap_tex
			zap.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			zap.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			zap.pixel_size = 0.03
			zap.shaded = false
			zap.transparent = true
			zap.modulate = Color(0.5, 0.9, 1.0, 0.6)
			var angle = i * TAU / 3.0
			zap.position = Vector3(cos(angle) * area_radius * 0.5, 0.5, sin(angle) * area_radius * 0.5)
			zap.name = "ZapSprite_%d" % i
			totem.add_child(zap)

	# Attach damage script behavior via timer
	var damage = int(WeaponDB.get_damage("totem", level))
	var lifetime = 15.0 + level * 2.0

	var script_node = Node.new()
	script_node.set_script(_TotemBehavior)
	script_node.set_meta("damage", damage)
	script_node.set_meta("lifetime", lifetime)
	script_node.set_meta("area", area)
	totem.add_child(script_node)

	active_totems.append(totem)
	get_tree().current_scene.call_deferred("add_child", totem)

	AudioManager.play_sfx("electric_zap")
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.2, 0.6, 1.0))

# Inner class for totem behavior
var _TotemBehavior: GDScript = preload("res://scripts/weapons/totem_behavior.gd")
