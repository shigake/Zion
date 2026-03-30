class_name WeaponVFX

## Utilitario compartilhado para efeitos visuais de armas melee.
## Elimina duplicacao de _spawn_slash_trail() em 10+ scripts de armas.

static func spawn_slash_trail(
	caller: Node,
	texture: Texture2D,
	pos: Vector3,
	pixel_size: float = 0.03,
	final_scale: float = 1.2,
	duration: float = 0.18,
) -> void:
	if not caller.is_inside_tree() or not texture:
		return
	if Engine.get_frames_per_second() < 40:
		return
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if not scene:
		return
	var sprite = Sprite3D.new()
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = pixel_size
	sprite.shaded = false
	sprite.transparent = true
	sprite.no_depth_test = true
	scene.add_child(sprite)
	sprite.global_position = pos
	sprite.scale = Vector3(0.5, 0.5, 0.5)
	sprite.modulate = Color(1, 1, 1, 1)
	var tween = caller.create_tween()
	tween.set_parallel(true)
	var s = Vector3(final_scale, final_scale, final_scale)
	tween.tween_property(sprite, "scale", s, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(sprite.queue_free)

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
	var tween = caller.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", target_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(mat, "albedo_color:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)
