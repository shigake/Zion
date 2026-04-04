class_name BossAttackPatterns

## Padroes de ataque compartilhados para todos os bosses.
## Ataques com telegraph visual antes do dano.

# ---- Circle AoE (telegraph + damage) ----

static func circle_aoe(
	scene: Node,
	center: Vector3,
	radius: float,
	damage: int,
	telegraph_time: float = 1.0,
	color: Color = Color(1.0, 0.2, 0.1, 0.3),
) -> void:
	## Cria um circulo vermelho no chao (telegraph), depois aplica dano na area.
	var indicator = _create_circle_indicator(center, radius, color)
	scene.add_child(indicator)

	# Telegraph: circulo cresce e pisca
	var tween = scene.create_tween()
	indicator.scale = Vector3(0.1, 1, 0.1)
	tween.tween_property(indicator, "scale", Vector3(1, 1, 1), telegraph_time * 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Flash antes do impacto
	tween.tween_callback(func():
		if is_instance_valid(indicator):
			var mat = indicator.material_override
			if mat:
				mat.albedo_color.a = 0.6
	)
	tween.tween_interval(telegraph_time * 0.3)
	# Dano
	tween.tween_callback(func():
		if not is_instance_valid(scene):
			return
		_apply_circle_damage(scene, center, radius, damage)
		ScreenEffects.shake(0.15)
		ParticleFactory.spawn_explosion_particles(center, radius * 0.5)
		AudioManager.play_sfx("explosion")
	)
	# Cleanup
	tween.tween_callback(func():
		if is_instance_valid(indicator):
			indicator.queue_free()
	)

static func _create_circle_indicator(center: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.05
	mesh_inst.mesh = disc
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_inst.material_override = mat
	mesh_inst.position = center + Vector3(0, 0.1, 0)
	return mesh_inst

static func _apply_circle_damage(scene: Node, center: Vector3, radius: float, damage: int) -> void:
	var players = GameManager.get_players()
	for p in players:
		if not is_instance_valid(p):
			continue
		var dist = center.distance_to(p.global_position)
		if dist <= radius:
			GameManager.take_damage(damage)

# ---- Cone AoE (telegraph + damage in cone direction) ----

static func cone_aoe(
	scene: Node,
	origin: Vector3,
	direction: Vector3,
	length: float,
	angle_degrees: float,
	damage: int,
	telegraph_time: float = 0.8,
	color: Color = Color(1.0, 0.5, 0.1, 0.3),
) -> void:
	## Cria um cone visual (telegraph), depois aplica dano em area conica.
	var indicator = _create_cone_indicator(origin, direction, length, angle_degrees, color)
	scene.add_child(indicator)

	var tween = scene.create_tween()
	indicator.modulate = Color(1, 1, 1, 0.3)
	tween.tween_property(indicator, "modulate:a", 0.8, telegraph_time * 0.7)
	tween.tween_interval(telegraph_time * 0.3)
	tween.tween_callback(func():
		if not is_instance_valid(scene):
			return
		_apply_cone_damage(origin, direction.normalized(), length, angle_degrees, damage)
		ScreenEffects.shake(0.12)
		AudioManager.play_sfx("boss_attack")
	)
	tween.tween_callback(func():
		if is_instance_valid(indicator):
			indicator.queue_free()
	)

static func _create_cone_indicator(origin: Vector3, direction: Vector3, length: float, angle_deg: float, color: Color) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	# Usa cilindro achatado como aproximacao visual do cone
	var cone = CylinderMesh.new()
	cone.top_radius = 0.1
	cone.bottom_radius = length * tan(deg_to_rad(angle_deg / 2.0))
	cone.height = length
	mesh_inst.mesh = cone
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mesh_inst.material_override = mat
	# Posiciona e rotaciona no chao
	mesh_inst.position = origin + Vector3(0, 0.1, 0)
	# Deita o cone no plano XZ apontando na direcao
	mesh_inst.rotation.x = PI / 2.0
	var angle_y = atan2(-direction.z, direction.x) - PI / 2.0
	mesh_inst.rotation.y = angle_y
	mesh_inst.position += direction.normalized() * (length / 2.0)
	return mesh_inst

static func _apply_cone_damage(origin: Vector3, direction: Vector3, length: float, angle_deg: float, damage: int) -> void:
	var half_angle = deg_to_rad(angle_deg / 2.0)
	var players = GameManager.get_players()
	for p in players:
		if not is_instance_valid(p):
			continue
		var to_player = p.global_position - origin
		to_player.y = 0
		var dist = to_player.length()
		if dist > length or dist < 0.1:
			continue
		var dir_flat = Vector3(direction.x, 0, direction.z).normalized()
		var angle = to_player.normalized().angle_to(dir_flat)
		if angle <= half_angle:
			GameManager.take_damage(damage)

# ---- Projectile Ring (boss fires projectiles in a circle) ----

static func projectile_ring(
	scene: Node,
	center: Vector3,
	count: int,
	damage: int,
	speed: float = 8.0,
	color: Color = Color(1.0, 0.3, 0.3),
) -> void:
	## Dispara projeteis em circulo uniforme a partir do centro.
	for i in range(count):
		var angle = (float(i) / count) * TAU
		var dir = Vector3(cos(angle), 0, sin(angle))
		_spawn_boss_projectile(scene, center + Vector3(0, 0.8, 0), dir, damage, speed, color)
	AudioManager.play_sfx("boss_attack")

static func _spawn_boss_projectile(scene: Node, pos: Vector3, dir: Vector3, damage: int, speed: float, color: Color) -> void:
	var proj: Node3D
	var proj_sprite_path = "res://assets/sprites/effects/boss_projectile.png"
	if ResourceLoader.exists(proj_sprite_path):
		proj = Node3D.new()
		var sprite = Sprite3D.new()
		sprite.texture = load(proj_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.04
		sprite.shaded = false
		sprite.transparent = true
		sprite.modulate = color
		proj.add_child(sprite)
	else:
		proj = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.2
		sphere.height = 0.4
		(proj as MeshInstance3D).mesh = sphere
	if proj is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
		proj.material_override = mat
	proj.global_position = pos

	# Area3D para detecao de colisao com jogador
	var area = Area3D.new()
	area.collision_layer = 16  # EnemyAttacks
	area.collision_mask = 1    # Players
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.3
	col.shape = shape
	area.add_child(col)
	proj.add_child(area)

	scene.add_child(proj)

	# Movimento via script inline
	var script = GDScript.new()
	script.source_code = """extends MeshInstance3D
var direction := Vector3(%s, %s, %s)
var speed := %s
var damage := %s
var lifetime := 3.0

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _ready() -> void:
	var area = get_child(0) as Area3D
	if area:
		area.body_entered.connect(func(body):
			if body.is_in_group(\"players\"):
				GameManager.take_damage(damage)
				queue_free()
		)
""" % [str(dir.x), str(dir.y), str(dir.z), str(speed), str(damage)]
	script.reload()
	proj.set_script(script)
