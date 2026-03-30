extends Node

## Screen shake, flash, slow motion, low-HP vignette, damage feedback,
## level-up flash, kill streak text, boss entrance effects.

var shake_amount: float = 0.0
var shake_decay: float = 8.0
var camera: Camera3D = null
var _vignette_canvas: CanvasLayer = null
var _vignette_rect: ColorRect = null
var _vignette_visible: bool = false

# Damage flash overlay (separate from vignette)
var _damage_flash_rect: ColorRect = null
var _damage_flash_timer: float = 0.0
var _damage_flash_duration: float = 0.0

# Generic flash overlay (white flash for level-up, boss, etc.)
var _flash_overlay: ColorRect = null

# Directional damage indicator
var _damage_indicator_container: Control = null
var _damage_indicators: Array = []  # Array of {rect: ColorRect, timer: float, angle: float}

# Chromatic aberration / damage intensity
var _damage_intensity: float = 0.0  # 0-1, decays over time

# Kill streak tracking
var _kill_times: Array[float] = []  # Timestamps of recent kills
var _kill_streak_label: Label = null
var _kill_streak_tween: Tween = null
const KILL_STREAK_WINDOW: float = 2.0  # seconds to count kills
const KILL_STREAK_MIN: int = 5  # minimum kills for streak text
var _streak_messages: Array[String] = ["COMBO x%d!", "MASSACRE!", "UNSTOPPABLE!", "GODLIKE!"]

signal player_took_damage  # Emitted so HUD can react

func _ready() -> void:
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()
	# Create vignette overlay
	_vignette_canvas = CanvasLayer.new()
	_vignette_canvas.layer = 9
	_vignette_rect = ColorRect.new()
	_vignette_rect.anchors_preset = Control.PRESET_FULL_RECT
	_vignette_rect.color = Color(0.5, 0.0, 0.0, 0.0)
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_canvas.add_child(_vignette_rect)

	# Damage flash overlay (bright red, separate layer)
	_damage_flash_rect = ColorRect.new()
	_damage_flash_rect.anchors_preset = Control.PRESET_FULL_RECT
	_damage_flash_rect.color = Color(0.8, 0.0, 0.0, 0.0)
	_damage_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_canvas.add_child(_damage_flash_rect)

	# Generic flash overlay (white, for level-up / boss entrance)
	_flash_overlay = ColorRect.new()
	_flash_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_overlay.visible = false
	_vignette_canvas.add_child(_flash_overlay)

	# Kill streak label (centered, large, bold)
	_kill_streak_label = Label.new()
	_kill_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_kill_streak_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_kill_streak_label.anchors_preset = Control.PRESET_FULL_RECT
	_kill_streak_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill_streak_label.add_theme_font_size_override("font_size", 48)
	_kill_streak_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_kill_streak_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_kill_streak_label.add_theme_constant_override("outline_size", 4)
	_kill_streak_label.visible = false
	_vignette_canvas.add_child(_kill_streak_label)

	# Directional damage indicator container
	_damage_indicator_container = Control.new()
	_damage_indicator_container.anchors_preset = Control.PRESET_FULL_RECT
	_damage_indicator_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_canvas.add_child(_damage_indicator_container)

	add_child(_vignette_canvas)

	# Connect signals for juice effects
	GameManager.player_leveled_up.connect(_on_player_leveled_up)
	# Kill streak disabled — too noisy
	#GameManager.enemy_killed.connect(_on_enemy_killed_streak)
	GameManager.miniboss_spawned.connect(_on_boss_entrance)

func _process(delta: float) -> void:
	# Re-acquire camera if freed (after scene change)
	if not camera or not is_instance_valid(camera):
		camera = get_viewport().get_camera_3d()
	if shake_amount > 0.01 and camera:
		camera.h_offset = randf_range(-shake_amount, shake_amount)
		camera.v_offset = randf_range(-shake_amount, shake_amount)
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
	elif camera:
		camera.h_offset = 0
		camera.v_offset = 0

	# Low-HP vignette
	_update_vignette()

	# Damage flash decay
	_update_damage_flash(delta)

	# Damage intensity decay (for any post-process effects)
	if _damage_intensity > 0.0:
		_damage_intensity = maxf(0.0, _damage_intensity - delta * 3.0)

	# Directional damage indicators
	_update_damage_indicators(delta)

	# Prune expired kill timestamps from streak tracking
	var now = GameManager.game_time
	while not _kill_times.is_empty() and _kill_times[0] < now - KILL_STREAK_WINDOW:
		_kill_times.remove_at(0)

func _update_vignette() -> void:
	if not _vignette_rect:
		return
	var max_hp = GameManager.get_effective_max_hp()
	if max_hp <= 0:
		return
	var hp_pct = float(GameManager.player_hp) / float(max_hp)
	if hp_pct < 0.3:
		# Pulse intensity based on HP% — stronger pulse at lower HP
		var intensity = (0.3 - hp_pct) / 0.3  # 0 at 30%, 1 at 0%
		var pulse_speed = lerpf(4.0, 8.0, intensity)  # Faster pulse at lower HP
		var pulse = (sin(GameManager.game_time * pulse_speed) * 0.5 + 0.5) * 0.2
		_vignette_rect.color.a = intensity * 0.35 + pulse
	else:
		_vignette_rect.color.a = 0.0

func _update_damage_flash(delta: float) -> void:
	if not _damage_flash_rect:
		return
	if _damage_flash_timer > 0.0:
		_damage_flash_timer -= delta
		# Quick fade: starts bright, fades out
		var t = clampf(_damage_flash_timer / _damage_flash_duration, 0.0, 1.0)
		_damage_flash_rect.color.a = t * 0.25
	else:
		_damage_flash_rect.color.a = 0.0

func _update_damage_indicators(delta: float) -> void:
	var to_remove := []
	for i in range(_damage_indicators.size()):
		var ind = _damage_indicators[i]
		ind["timer"] -= delta
		if ind["timer"] <= 0.0:
			to_remove.append(i)
			if is_instance_valid(ind["rect"]):
				ind["rect"].queue_free()
		else:
			# Fade out
			var alpha = clampf(ind["timer"] / 0.5, 0.0, 0.8)
			if is_instance_valid(ind["rect"]):
				ind["rect"].modulate.a = alpha
	# Remove expired (reverse order)
	for i in range(to_remove.size() - 1, -1, -1):
		_damage_indicators.remove_at(to_remove[i])

func shake(amount: float = 0.15) -> void:
	# Respect gfx_screen_shake setting: 0=Off, 1=Light, 2=Normal, 3=Strong
	var setting: int = SaveManager.data.get("gfx_screen_shake", 2)
	if setting == 0:
		return
	var multiplier: float = [0.0, 0.4, 1.0, 1.6][setting]
	shake_amount = maxf(shake_amount, amount * multiplier)

func hit_freeze(duration: float = 0.05) -> void:
	Engine.time_scale = 0.1
	await get_tree().create_timer(duration * 0.1).timeout
	Engine.time_scale = 1.0

func slow_motion(duration: float = 0.5, scale: float = 0.3) -> void:
	Engine.time_scale = scale
	await get_tree().create_timer(duration * scale).timeout
	Engine.time_scale = 1.0

## Brief white flash overlay (e.g. on heavy swing)
func flash(duration: float = 0.05, alpha: float = 0.1) -> void:
	if not _flash_overlay:
		return
	_flash_overlay.color = Color(1.0, 1.0, 1.0, alpha)
	_flash_overlay.visible = true
	var tween = create_tween()
	tween.tween_property(_flash_overlay, "color:a", 0.0, duration)
	tween.tween_callback(func(): _flash_overlay.visible = false)

## Full damage feedback package — call this when player takes damage
func damage_feedback(damage_amount: int, damage_source_pos: Vector3 = Vector3.ZERO) -> void:
	var max_hp = GameManager.get_effective_max_hp()
	var damage_ratio = float(damage_amount) / float(maxi(max_hp, 1))

	# 1. Screen shake (scales with damage)
	var shake_str = clampf(0.08 + damage_ratio * 0.3, 0.08, 0.25)
	shake(shake_str)

	# 2. Hit freeze (micro-pause for impact feel)
	if damage_ratio > 0.15:
		hit_freeze(0.04)

	# 3. Red screen flash
	damage_flash(0.15 + damage_ratio * 0.1)

	# 4. Damage intensity for post-processing
	_damage_intensity = clampf(damage_ratio * 2.0, 0.3, 1.0)

	# 5. Directional damage indicator
	if damage_source_pos != Vector3.ZERO:
		_spawn_damage_indicator(damage_source_pos)

	# 6. Gamepad vibration
	_vibrate_gamepad(damage_ratio)

	# 7. Signal for HUD
	player_took_damage.emit()

## Red flash overlay on damage
func damage_flash(duration: float = 0.15) -> void:
	_damage_flash_timer = duration
	_damage_flash_duration = duration

## Directional damage indicator (red arc on screen edge toward damage source)
func _spawn_damage_indicator(source_pos: Vector3) -> void:
	if not _damage_indicator_container:
		return
	var players = GameManager.get_players()
	if players.is_empty():
		return
	var player_pos = players[0].global_position
	var dir = (source_pos - player_pos).normalized()
	# Convert 3D direction to 2D angle (top-down: x,z plane)
	var angle = atan2(dir.x, -dir.z)  # -z is forward in Godot

	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2.0

	# Create directional arc indicator
	var indicator = ColorRect.new()
	indicator.color = Color(1.0, 0.1, 0.05, 0.8)
	indicator.custom_minimum_size = Vector2(60, 8)
	indicator.size = Vector2(60, 8)
	indicator.pivot_offset = Vector2(30, 4)
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Position on screen edge in direction of damage
	var edge_dist = minf(viewport_size.x, viewport_size.y) * 0.42
	var pos = center + Vector2(sin(angle), -cos(angle)) * edge_dist
	indicator.position = pos - indicator.pivot_offset
	indicator.rotation = angle

	_damage_indicator_container.add_child(indicator)
	_damage_indicators.append({"rect": indicator, "timer": 0.6, "angle": angle})

## Gamepad vibration on damage
func _vibrate_gamepad(intensity: float) -> void:
	var strong = clampf(intensity * 0.6, 0.1, 0.5)
	var weak = clampf(intensity * 0.8, 0.2, 0.7)
	Input.start_joy_vibration(0, weak, strong, 0.2)

# ---- Level Up Flash ----

func _on_player_leveled_up(_new_level: int) -> void:
	level_up_flash()

## Brief white flash when player levels up
func level_up_flash() -> void:
	if not _flash_overlay:
		return
	_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.4)
	_flash_overlay.visible = true
	var tween = create_tween()
	tween.tween_property(_flash_overlay, "color:a", 0.0, 0.3)
	tween.tween_callback(func(): _flash_overlay.visible = false)

# ---- Kill Streak ----

func _on_enemy_killed_streak(_position: Vector3, _xp_value: int) -> void:
	_kill_times.append(GameManager.game_time)
	var streak_count = _kill_times.size()
	if streak_count >= KILL_STREAK_MIN:
		_show_kill_streak(streak_count)

## Show kill streak text with bounce animation
func _show_kill_streak(count: int) -> void:
	if not _kill_streak_label:
		return
	# Pick message based on streak tier
	var msg: String
	if count >= 30:
		msg = _streak_messages[3]  # GODLIKE!
	elif count >= 20:
		msg = _streak_messages[2]  # UNSTOPPABLE!
	elif count >= 10:
		msg = _streak_messages[1]  # MASSACRE!
	else:
		msg = _streak_messages[0] % count  # COMBO x5!

	_kill_streak_label.text = msg
	_kill_streak_label.visible = true
	_kill_streak_label.modulate = Color(1, 1, 1, 1)
	_kill_streak_label.scale = Vector2(0.5, 0.5)
	_kill_streak_label.pivot_offset = _kill_streak_label.size / 2.0

	# Kill previous tween if still running
	if _kill_streak_tween and _kill_streak_tween.is_valid():
		_kill_streak_tween.kill()

	_kill_streak_tween = create_tween()
	# Scale bounce in
	_kill_streak_tween.tween_property(_kill_streak_label, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT)
	_kill_streak_tween.tween_property(_kill_streak_label, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN)
	# Hold briefly, then fade out
	_kill_streak_tween.tween_interval(0.6)
	_kill_streak_tween.tween_property(_kill_streak_label, "modulate:a", 0.0, 0.4)
	_kill_streak_tween.tween_callback(func(): _kill_streak_label.visible = false)

# ---- Boss Entrance Effect ----

var _boss_title_label: Label = null
var _boss_subtitle_label: Label = null

func _on_boss_entrance(_boss_name: String) -> void:
	boss_entrance_effect()

## Boss names for title display
var _boss_display_names: Dictionary = {
	"BossNecromancer": "SENTINELA NECROMANTE",
	"BossFairyQueen": "SENTINELA RAINHA FADA",
	"BossAlienCow": "SENTINELA VACA ALIENIGENA",
	"BossAiOverlord": "SENTINELA IA SUPREMA",
	"BossDemonLord": "SENTINELA SENHOR DEMONIO",
	"BossLeviathan": "SENTINELA LEVIATA",
	"BossEmperor": "SENTINELA IMPERADOR",
	"BossSingularity": "SENTINELA SINGULARIDADE",
	"BossDracula": "SENTINELA DRACULA",
	"BossSugarKing": "SENTINELA REI DO ACUCAR",
}

## Dramatic boss entrance: letterbox + vignette + zoom + title card + shake + slow-mo + roar + particles
func boss_entrance_effect() -> void:
	# 0. Cinematic letterbox bars (top and bottom black bars)
	_show_letterbox(2.5)

	# 1. Dark vignette overlay (builds tension)
	if _vignette_rect:
		var vig_tween = create_tween()
		_vignette_rect.color = Color(0.0, 0.0, 0.0, 0.0)
		vig_tween.tween_property(_vignette_rect, "color:a", 0.6, 0.2)
		vig_tween.tween_interval(1.8)
		vig_tween.tween_property(_vignette_rect, "color:a", 0.0, 0.5)

	# 2. Escalating camera shake — starts light, gets intense
	shake(0.15)
	_escalate_shake()

	# 3. White flash → deep red flash → fade
	if _flash_overlay:
		_flash_overlay.color = Color(1.0, 0.95, 0.85, 0.7)
		_flash_overlay.visible = true
		var flash_tween = create_tween()
		flash_tween.tween_property(_flash_overlay, "color", Color(0.9, 0.15, 0.0, 0.5), 0.15)
		flash_tween.tween_property(_flash_overlay, "color", Color(0.6, 0.0, 0.0, 0.2), 0.3)
		flash_tween.tween_property(_flash_overlay, "color:a", 0.0, 0.4)
		flash_tween.tween_callback(func(): _flash_overlay.visible = false)

	# 4. Boss roar SFX + appearance SFX
	AudioManager.play_sfx("boss_roar")
	AudioManager.play_sfx("boss_appear")

	# 5. Dramatic slow-motion (middle ground: 0.5s at 0.25 scale)
	slow_motion(0.5, 0.25)

	# 6. Camera zoom pulse (deeper zoom, dramatic snap-back)
	_boss_camera_zoom()

	# 7. Extended gamepad rumble (two waves)
	Input.start_joy_vibration(0, 0.6, 0.4, 0.3)
	_delayed_rumble()

	# 8. Boss spawn particles (ground shockwave)
	_boss_spawn_particles()

func _escalate_shake() -> void:
	await get_tree().create_timer(0.2).timeout
	shake(0.35)
	await get_tree().create_timer(0.15).timeout
	shake(0.6)

func _delayed_rumble() -> void:
	await get_tree().create_timer(0.3).timeout
	Input.start_joy_vibration(0, 1.0, 0.9, 0.8)

## Cinematic letterbox bars
var _letterbox_top: ColorRect = null
var _letterbox_bottom: ColorRect = null

func _show_letterbox(duration: float) -> void:
	if not _vignette_canvas:
		return
	# Top bar
	if _letterbox_top and is_instance_valid(_letterbox_top):
		_letterbox_top.queue_free()
	_letterbox_top = ColorRect.new()
	_letterbox_top.color = Color(0, 0, 0, 1)
	_letterbox_top.anchor_left = 0.0
	_letterbox_top.anchor_right = 1.0
	_letterbox_top.anchor_top = 0.0
	_letterbox_top.anchor_bottom = 0.0
	_letterbox_top.offset_bottom = 0.0
	_letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_canvas.add_child(_letterbox_top)

	# Bottom bar
	if _letterbox_bottom and is_instance_valid(_letterbox_bottom):
		_letterbox_bottom.queue_free()
	_letterbox_bottom = ColorRect.new()
	_letterbox_bottom.color = Color(0, 0, 0, 1)
	_letterbox_bottom.anchor_left = 0.0
	_letterbox_bottom.anchor_right = 1.0
	_letterbox_bottom.anchor_top = 1.0
	_letterbox_bottom.anchor_bottom = 1.0
	_letterbox_bottom.offset_top = 0.0
	_letterbox_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_canvas.add_child(_letterbox_bottom)

	var bar_height = 60.0
	# Slide in
	var in_tween = create_tween().set_parallel(true)
	in_tween.tween_property(_letterbox_top, "offset_bottom", bar_height, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	in_tween.tween_property(_letterbox_bottom, "offset_top", -bar_height, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Slide out after duration
	var out_tween = create_tween()
	out_tween.tween_interval(duration)
	out_tween.set_parallel(true)
	out_tween.tween_property(_letterbox_top, "offset_bottom", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out_tween.tween_property(_letterbox_bottom, "offset_top", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out_tween.chain().tween_callback(func():
		if is_instance_valid(_letterbox_top): _letterbox_top.queue_free()
		if is_instance_valid(_letterbox_bottom): _letterbox_bottom.queue_free()
	)

## Boss spawn ground shockwave particles
func _boss_spawn_particles() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	# Spawn a ring of particles around the player
	var center = players[0].global_position
	var scene = get_tree().current_scene
	if not scene:
		return
	for i in range(12):
		var angle = float(i) / 12.0 * TAU
		var pos = center + Vector3(cos(angle) * 3.0, 0.2, sin(angle) * 3.0)
		var particle = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.24
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.3, 0.1, 0.8)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.4, 0.15)
		mat.emission_energy_multiplier = 6.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sphere.surface_set_material(0, mat)
		particle.mesh = sphere
		scene.add_child(particle)
		particle.global_position = center + Vector3(0, 0.2, 0)
		# Expand outward in a ring
		var tween = particle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", pos + Vector3(0, 0.5, 0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "scale", Vector3(0.01, 0.01, 0.01), 0.6)
		tween.chain().tween_callback(particle.queue_free)

## Boss title card — displays boss name with dramatic animation
func boss_title_card(boss_name: String) -> void:
	var display_name = _boss_display_names.get(boss_name, boss_name.to_upper())
	if not _vignette_canvas:
		return

	# Title label
	if _boss_title_label and is_instance_valid(_boss_title_label):
		_boss_title_label.queue_free()
	_boss_title_label = Label.new()
	_boss_title_label.text = display_name
	_boss_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_boss_title_label.anchors_preset = Control.PRESET_CENTER
	_boss_title_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boss_title_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_boss_title_label.position.y = -40
	_boss_title_label.add_theme_font_size_override("font_size", 36)
	_boss_title_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))
	_boss_title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_boss_title_label.add_theme_constant_override("outline_size", 6)
	_boss_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_title_label.modulate.a = 0.0
	_boss_title_label.scale = Vector2(0.3, 0.3)
	_boss_title_label.pivot_offset = Vector2(300, 20)
	_vignette_canvas.add_child(_boss_title_label)

	# Subtitle
	if _boss_subtitle_label and is_instance_valid(_boss_subtitle_label):
		_boss_subtitle_label.queue_free()
	_boss_subtitle_label = Label.new()
	_boss_subtitle_label.text = "— Guardiao corrompido —"
	_boss_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_boss_subtitle_label.anchors_preset = Control.PRESET_CENTER
	_boss_subtitle_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boss_subtitle_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_boss_subtitle_label.position.y = 10
	_boss_subtitle_label.add_theme_font_size_override("font_size", 16)
	_boss_subtitle_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	_boss_subtitle_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_boss_subtitle_label.add_theme_constant_override("outline_size", 3)
	_boss_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_subtitle_label.modulate.a = 0.0
	_vignette_canvas.add_child(_boss_subtitle_label)

	# Animate title: zoom in with bounce
	var title_tween = create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property(_boss_title_label, "modulate:a", 1.0, 0.3)
	title_tween.tween_property(_boss_title_label, "scale", Vector2(1.1, 1.1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	title_tween.chain().tween_property(_boss_title_label, "scale", Vector2(1.0, 1.0), 0.15)

	# Subtitle fade in delayed
	var sub_tween = create_tween()
	sub_tween.tween_interval(0.4)
	sub_tween.tween_property(_boss_subtitle_label, "modulate:a", 1.0, 0.3)

	# Hold then fade out
	var fade_tween = create_tween()
	fade_tween.tween_interval(2.5)
	fade_tween.set_parallel(true)
	fade_tween.tween_property(_boss_title_label, "modulate:a", 0.0, 0.5)
	fade_tween.tween_property(_boss_subtitle_label, "modulate:a", 0.0, 0.5)
	fade_tween.chain().tween_callback(func():
		if is_instance_valid(_boss_title_label):
			_boss_title_label.queue_free()
		if is_instance_valid(_boss_subtitle_label):
			_boss_subtitle_label.queue_free()
	)

## Camera zoom pulse for boss entrance — deeper zoom, dramatic snap-back
func _boss_camera_zoom() -> void:
	if not camera or not is_instance_valid(camera):
		camera = get_viewport().get_camera_3d()
	if not camera:
		return
	var original_fov = camera.fov
	var zoom_tween = create_tween()
	# Quick zoom in (dramatic)
	zoom_tween.tween_property(camera, "fov", original_fov - 15.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Hold at zoom
	zoom_tween.tween_interval(0.8)
	# Snap back with slight overshoot
	zoom_tween.tween_property(camera, "fov", original_fov + 3.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	zoom_tween.tween_property(camera, "fov", original_fov, 0.3).set_ease(Tween.EASE_IN_OUT)
