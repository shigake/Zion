class_name WeaponVFX

## Utilitario compartilhado para efeitos visuais de armas melee.
## Elimina duplicacao de _spawn_slash_trail() em 10+ scripts de armas.
## Usa pool interno para evitar alocacoes durante combate.

# Pool de Sprite3D para slash trails — evita Sprite3D.new() por ataque
static var _slash_pool: Array[Sprite3D] = []
static var _slash_pool_idx: int = 0
const SLASH_POOL_SIZE := 24

static func _get_or_create_slash(scene: Node) -> Sprite3D:
	# Tenta reutilizar sprite existente que ja terminou a animacao
	for i in range(_slash_pool.size()):
		var idx = (_slash_pool_idx + i) % _slash_pool.size()
		var sprite = _slash_pool[idx]
		if is_instance_valid(sprite) and sprite.modulate.a < 0.01:
			_slash_pool_idx = (idx + 1) % _slash_pool.size()
			sprite.visible = true
			sprite.modulate = Color(1, 1, 1, 1)
			return sprite
	# Pool cheio ou vazio — cria novo se ainda tem espaco
	if _slash_pool.size() < SLASH_POOL_SIZE:
		var sprite = Sprite3D.new()
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.shaded = false
		sprite.transparent = true
		sprite.no_depth_test = true
		scene.add_child(sprite)
		_slash_pool.append(sprite)
		return sprite
	# Pool esgotado — reutiliza o mais antigo
	_slash_pool_idx = (_slash_pool_idx + 1) % _slash_pool.size()
	var oldest = _slash_pool[_slash_pool_idx]
	if is_instance_valid(oldest):
		oldest.visible = true
		oldest.modulate = Color(1, 1, 1, 1)
		return oldest
	# Fallback: cria novo (nao deveria acontecer)
	var sprite = Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.transparent = true
	sprite.no_depth_test = true
	scene.add_child(sprite)
	_slash_pool[_slash_pool_idx] = sprite
	return sprite

static func spawn_slash_trail(
	caller: Node,
	texture: Texture2D,
	pos: Vector3,
	pixel_size: float = 0.015,
	final_scale: float = 1.2,
	duration: float = 0.18,
	start_scale: Vector3 = Vector3(0.5, 0.5, 0.5),
) -> void:
	if not caller.is_inside_tree() or not texture:
		return
	if Engine.get_frames_per_second() < 40:
		return
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if not scene:
		return
	var sprite = _get_or_create_slash(scene)
	sprite.texture = texture
	sprite.pixel_size = pixel_size
	sprite.global_position = pos
	sprite.scale = start_scale
	sprite.modulate = Color(1, 1, 1, 1)
	# Use sprite's own tween so it survives even if caller is freed
	var tween = sprite.create_tween()
	tween.set_parallel(true)
	var s = Vector3(final_scale, final_scale, final_scale)
	tween.tween_property(sprite, "scale", s, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)

static func spawn_shockwave_ring(
	caller: Node,
	pos: Vector3,
	color: Color = Color(0.7, 0.45, 0.2, 0.6),
	emission_color: Color = Color(0.8, 0.5, 0.2),
	area_scale: float = 1.5,
	duration: float = 0.25,
) -> void:
	if not caller.is_inside_tree():
		return
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if not scene:
		return
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.2
	torus.outer_radius = 0.35
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = emission_color
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	torus.surface_set_material(0, mat)
	ring.mesh = torus
	scene.add_child(ring)
	ring.global_position = pos + Vector3(0, 0.05, 0)
	ring.scale = Vector3(0.3, 0.1, 0.3)
	var target_scale = Vector3(area_scale, 0.1, area_scale)
	# Use ring's own tween so it survives even if caller is freed
	var tween = ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", target_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(mat, "albedo_color:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)
