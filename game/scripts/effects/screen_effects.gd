extends Node

## Screen shake, flash, slow motion, low-HP vignette, damage feedback,
## level-up flash, kill streak text, boss entrance effects.

var shake_amount: float = 0.0
var shake_decay: float = GameConstants.SHAKE_DECAY
var camera: Camera3D = null
var _vignette_canvas: CanvasLayer = null
var _vignette_rect: ColorRect = null
var _vignette_visible: bool = false

# Damage flash overlay — DISABLED (PRD 09: ugly red flash removed)

# Generic flash overlay (white flash for level-up, boss, etc.)
var _flash_overlay: ColorRect = null

# Directional damage indicator — DISABLED (PRD 09: confusing "random bar" removed)

# Chromatic aberration / damage intensity
var _damage_intensity: float = 0.0  # 0-1, decays over time

# Kill streak tracking
var _kill_times: Array[float] = []  # Timestamps of recent kills
var _kill_streak_label: Label = null
var _kill_streak_tween: Tween = null
var KILL_STREAK_WINDOW: float = 2.0
var KILL_STREAK_MIN: int = 5
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
	_kill_streak_label.add_theme_font_size_override("font_size", GameConstants.KILL_STREAK_FONT_SIZE)
	_kill_streak_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_kill_streak_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_kill_streak_label.add_theme_constant_override("outline_size", 4)
	_kill_streak_label.visible = false
	_vignette_canvas.add_child(_kill_streak_label)

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

	# Damage intensity decay (for any post-process effects)
	if _damage_intensity > 0.0:
		_damage_intensity = maxf(0.0, _damage_intensity - delta * GameConstants.DAMAGE_INTENSITY_DECAY)

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
	if hp_pct < GameConstants.VIGNETTE_HP_THRESHOLD:
		# Pulse intensity based on HP% — stronger pulse at lower HP
		var intensity = (GameConstants.VIGNETTE_HP_THRESHOLD - hp_pct) / GameConstants.VIGNETTE_HP_THRESHOLD  # 0 at 30%, 1 at 0%
		var pulse_speed = lerpf(GameConstants.VIGNETTE_PULSE_MIN_SPEED, GameConstants.VIGNETTE_PULSE_MAX_SPEED, intensity)  # Faster pulse at lower HP
		var pulse = (sin(GameManager.game_time * pulse_speed) * 0.5 + 0.5) * GameConstants.VIGNETTE_PULSE_AMPLITUDE
		_vignette_rect.color.a = intensity * GameConstants.VIGNETTE_BASE_ALPHA + pulse
	else:
		_vignette_rect.color.a = 0.0


func shake(amount: float = 0.15) -> void:
	# PRD 28 §3 — Accessibility: skip shake if toggle is off
	if not GameManager.screen_shake_enabled:
		return
	# Accessibility: skip shake if reduced motion is on
	if AccessibilityManager.reduced_motion:
		return
	# Respect gfx_screen_shake setting: 0=Off, 1=Light, 2=Normal, 3=Strong
	var setting: int = SaveManager.data.get("gfx_screen_shake", 2)
	if setting == 0:
		return
	var multiplier: float = [0.0, 0.4, 1.0, 1.6][setting]
	shake_amount = maxf(shake_amount, amount * multiplier)

	# Chromatic aberration on strong shakes (amount >= 0.2)
	if amount >= 0.2 and not AccessibilityManager.reduced_motion:
		_apply_chromatic_aberration(amount)

var _time_scale_priority: int = 0  # Higher priority effects won't be overridden

func hit_freeze(duration: float = 0.05) -> void:
	# Accessibility: reduce hit freeze duration by 70% if reduced motion
	if AccessibilityManager.reduced_motion:
		duration *= 0.3
	if _time_scale_priority > 0:
		return  # Don't override higher-priority time effects (boss kill freeze)
	Engine.time_scale = 0.1
	await get_tree().create_timer(duration * 0.1).timeout
	if _time_scale_priority == 0:
		Engine.time_scale = 1.0

func boss_kill_freeze() -> void:
	var duration: float = GameConstants.BOSS_KILL_FREEZE_DURATION
	# Accessibility: reduced motion — pula o freeze, mantem so o flash
	if AccessibilityManager.reduced_motion:
		flash(0.12, GameConstants.BOSS_KILL_FLASH_ALPHA * 0.4)
		return
	# Pausa total + flash branco intenso (high priority — blocks hit_freeze)
	_time_scale_priority = 2
	Engine.time_scale = 0.0
	flash(0.12, GameConstants.BOSS_KILL_FLASH_ALPHA)
	# Timer com process_always=true para rodar mesmo com time_scale=0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_time_scale_priority = 0
	# Screen shake suave apos retomar
	shake(GameConstants.BOSS_KILL_SHAKE_AMOUNT)

func slow_motion(duration: float = 0.5, scale: float = 0.3) -> void:
	_time_scale_priority = 1
	Engine.time_scale = scale
	await get_tree().create_timer(duration * scale).timeout
	Engine.time_scale = 1.0
	_time_scale_priority = 0

## Brief white flash overlay (e.g. on heavy swing)
func flash(duration: float = 0.05, alpha: float = 0.1) -> void:
	if not _flash_overlay:
		return
	# Accessibility: rate-limit flashes; use subtle tint if blocked
	if not AccessibilityManager.can_flash():
		_flash_overlay.color = Color(1.0, 0.85, 0.85, alpha * 0.3)
		_flash_overlay.visible = true
		var tween = create_tween()
		tween.tween_property(_flash_overlay, "color:a", 0.0, duration * 2.0)
		tween.tween_callback(func(): _flash_overlay.visible = false)
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
	var shake_str = clampf(GameConstants.DAMAGE_SHAKE_BASE + damage_ratio * GameConstants.DAMAGE_SHAKE_SCALE, GameConstants.DAMAGE_SHAKE_BASE, GameConstants.DAMAGE_SHAKE_MAX)
	shake(shake_str)

	# 2. Hit freeze (micro-pause for impact feel)
	if damage_ratio > GameConstants.DAMAGE_FREEZE_THRESHOLD:
		hit_freeze(GameConstants.DAMAGE_FREEZE_DURATION)

	# 3. Damage intensity for post-processing
	_damage_intensity = clampf(damage_ratio * GameConstants.DAMAGE_INTENSITY_SCALE, GameConstants.DAMAGE_INTENSITY_MIN, 1.0)

	# 3b. Vibrant red flash on damage (scales with damage ratio)
	var flash_alpha_scale = clampf(damage_ratio * 2.0, 0.1, 0.25)
	if _flash_overlay and AccessibilityManager.can_flash():
		_flash_overlay.color = Color(1.0, 0.1, 0.05, flash_alpha_scale)
		_flash_overlay.visible = true
		var flash_tw = create_tween()
		flash_tw.tween_property(_flash_overlay, "color:a", 0.0, 0.15)
		flash_tw.tween_callback(func(): _flash_overlay.visible = false)

	# 4. Gamepad vibration
	_vibrate_gamepad(damage_ratio)

	# 5. Signal for HUD
	player_took_damage.emit()

## Red flash overlay on damage — re-enabled with brighter vibrant red
func damage_flash(duration: float = 0.15) -> void:
	if not _flash_overlay:
		return
	# Accessibility: rate-limit flashes
	if not AccessibilityManager.can_flash():
		return
	_flash_overlay.color = Color(1.0, 0.1, 0.05, 0.18)  # Vibrant bright red
	_flash_overlay.visible = true
	var tween = create_tween()
	tween.tween_property(_flash_overlay, "color:a", 0.0, duration)
	tween.tween_callback(func(): _flash_overlay.visible = false)

## Gamepad vibration on damage
func _vibrate_gamepad(intensity: float) -> void:
	var strong = clampf(intensity * GameConstants.VIBRATE_STRONG_SCALE, 0.1, GameConstants.VIBRATE_STRONG_MAX)
	var weak = clampf(intensity * GameConstants.VIBRATE_WEAK_SCALE, 0.2, GameConstants.VIBRATE_WEAK_MAX)
	Input.start_joy_vibration(0, weak, strong, GameConstants.VIBRATE_DURATION)

## Chromatic aberration effect during strong shakes — offset RGB channels briefly
var _chroma_overlay_r: ColorRect = null
var _chroma_overlay_b: ColorRect = null
var _chroma_tween: Tween = null

func _apply_chromatic_aberration(intensity: float) -> void:
	if not _vignette_canvas:
		return
	# Use two semi-transparent color overlays offset in opposite directions
	# to simulate chromatic aberration cheaply (no shader needed)
	var offset = clampf(intensity * 3.0, 1.0, 4.0)
	var alpha = clampf(intensity * 0.15, 0.02, 0.08)

	if not _chroma_overlay_r:
		_chroma_overlay_r = ColorRect.new()
		_chroma_overlay_r.anchors_preset = Control.PRESET_FULL_RECT
		_chroma_overlay_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_chroma_overlay_r.color = Color(1.0, 0.0, 0.0, 0.0)
		_vignette_canvas.add_child(_chroma_overlay_r)

	if not _chroma_overlay_b:
		_chroma_overlay_b = ColorRect.new()
		_chroma_overlay_b.anchors_preset = Control.PRESET_FULL_RECT
		_chroma_overlay_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_chroma_overlay_b.color = Color(0.0, 0.0, 1.0, 0.0)
		_vignette_canvas.add_child(_chroma_overlay_b)

	# Offset the overlays slightly
	_chroma_overlay_r.position = Vector2(-offset, 0)
	_chroma_overlay_b.position = Vector2(offset, 0)
	_chroma_overlay_r.color.a = alpha
	_chroma_overlay_b.color.a = alpha
	_chroma_overlay_r.visible = true
	_chroma_overlay_b.visible = true

	# Kill previous tween if still running
	if _chroma_tween and _chroma_tween.is_valid():
		_chroma_tween.kill()

	# Fade out quickly
	_chroma_tween = create_tween().set_parallel(true)
	_chroma_tween.tween_property(_chroma_overlay_r, "color:a", 0.0, 0.2)
	_chroma_tween.tween_property(_chroma_overlay_b, "color:a", 0.0, 0.2)
	_chroma_tween.chain().tween_callback(func():
		_chroma_overlay_r.visible = false
		_chroma_overlay_b.visible = false
		_chroma_overlay_r.position = Vector2.ZERO
		_chroma_overlay_b.position = Vector2.ZERO
	)

# ---- Level Up Flash ----

func _on_player_leveled_up(_new_level: int) -> void:
	level_up_flash()

## Brief white flash when player levels up
func level_up_flash() -> void:
	if not _flash_overlay:
		return
	# Accessibility: rate-limit flashes
	if not AccessibilityManager.can_flash():
		return
	_flash_overlay.color = Color(1.0, 1.0, 1.0, GameConstants.LEVEL_UP_FLASH_ALPHA)
	_flash_overlay.visible = true
	var tween = create_tween()
	tween.tween_property(_flash_overlay, "color:a", 0.0, GameConstants.LEVEL_UP_FLASH_DURATION)
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
	if count >= GameConstants.KILL_STREAK_TIER_4:
		msg = _streak_messages[3]  # GODLIKE!
	elif count >= GameConstants.KILL_STREAK_TIER_3:
		msg = _streak_messages[2]  # UNSTOPPABLE!
	elif count >= GameConstants.KILL_STREAK_TIER_2:
		msg = _streak_messages[1]  # MASSACRE!
	else:
		msg = _streak_messages[0] % count  # COMBO x5!

	# Cor por tier
	var streak_color: Color
	if count >= GameConstants.KILL_STREAK_TIER_4:
		streak_color = Color(1.0, 0.2, 0.2)  # Vermelho GODLIKE
	elif count >= GameConstants.KILL_STREAK_TIER_3:
		streak_color = Color(1.0, 0.5, 0.0)  # Laranja UNSTOPPABLE
	elif count >= GameConstants.KILL_STREAK_TIER_2:
		streak_color = Color(1.0, 0.85, 0.0)  # Amarelo MASSACRE
	else:
		streak_color = Color(1.0, 1.0, 1.0)  # Branco COMBO
	_kill_streak_label.text = msg
	_kill_streak_label.visible = true
	_kill_streak_label.add_theme_color_override("font_color", streak_color)
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
	# Accessibility: skip most visual effects if reduced motion
	if AccessibilityManager.reduced_motion:
		# Keep audio cues only
		AudioManager.play_sfx("boss_roar")
		AudioManager.play_sfx("boss_appear")
		Input.start_joy_vibration(0, GameConstants.BOSS_ENTRANCE_RUMBLE_1_WEAK, GameConstants.BOSS_ENTRANCE_RUMBLE_1_STRONG, GameConstants.BOSS_ENTRANCE_RUMBLE_1_DURATION)
		return
	# 0. Cinematic letterbox bars (top and bottom black bars)
	_show_letterbox(GameConstants.BOSS_ENTRANCE_LETTERBOX_DURATION)

	# 1. Dark vignette overlay (builds tension)
	if _vignette_rect:
		var vig_tween = create_tween()
		_vignette_rect.color = Color(0.0, 0.0, 0.0, 0.0)
		vig_tween.tween_property(_vignette_rect, "color:a", GameConstants.BOSS_ENTRANCE_VIGNETTE_ALPHA, GameConstants.BOSS_ENTRANCE_VIGNETTE_FADE_IN)
		vig_tween.tween_interval(GameConstants.BOSS_ENTRANCE_VIGNETTE_HOLD)
		vig_tween.tween_property(_vignette_rect, "color:a", 0.0, GameConstants.BOSS_ENTRANCE_VIGNETTE_FADE_OUT)

	# 2. Escalating camera shake — starts light, gets intense
	shake(GameConstants.BOSS_ENTRANCE_SHAKE_1)
	_escalate_shake()

	# 3. White flash → deep red flash → fade (respects flash accessibility)
	if _flash_overlay and AccessibilityManager.can_flash():
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
	slow_motion(GameConstants.BOSS_ENTRANCE_SLOW_MO_DURATION, GameConstants.BOSS_ENTRANCE_SLOW_MO_SCALE)

	# 6. Camera zoom pulse (deeper zoom, dramatic snap-back)
	_boss_camera_zoom()

	# 7. Extended gamepad rumble (two waves)
	Input.start_joy_vibration(0, GameConstants.BOSS_ENTRANCE_RUMBLE_1_WEAK, GameConstants.BOSS_ENTRANCE_RUMBLE_1_STRONG, GameConstants.BOSS_ENTRANCE_RUMBLE_1_DURATION)
	_delayed_rumble()

	# 8. Boss spawn particles (ground shockwave)
	_boss_spawn_particles()

func _escalate_shake() -> void:
	await get_tree().create_timer(GameConstants.BOSS_ENTRANCE_SHAKE_DELAY_1).timeout
	shake(GameConstants.BOSS_ENTRANCE_SHAKE_2)
	await get_tree().create_timer(GameConstants.BOSS_ENTRANCE_SHAKE_DELAY_2).timeout
	shake(GameConstants.BOSS_ENTRANCE_SHAKE_3)

func _delayed_rumble() -> void:
	await get_tree().create_timer(GameConstants.BOSS_ENTRANCE_RUMBLE_2_DELAY).timeout
	Input.start_joy_vibration(0, GameConstants.BOSS_ENTRANCE_RUMBLE_2_WEAK, GameConstants.BOSS_ENTRANCE_RUMBLE_2_STRONG, GameConstants.BOSS_ENTRANCE_RUMBLE_2_DURATION)

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

	var bar_height = GameConstants.BOSS_ENTRANCE_LETTERBOX_HEIGHT
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

## Boss phase 3 fury transition — dramatic cinematic sequence
var _phase3_title_label: Label = null

func boss_phase3_transition(boss_position: Vector3, boss_color: Color) -> void:
	# Accessibility: reduced mode
	if AccessibilityManager.reduced_motion:
		shake(0.15)
		AudioManager.play_sfx("boss_phase")
		Input.start_joy_vibration(0, GameConstants.BOSS_P3_RUMBLE_WEAK, GameConstants.BOSS_P3_RUMBLE_STRONG, GameConstants.BOSS_P3_RUMBLE_DURATION)
		_show_phase3_title()
		return

	# Slow-mo
	Engine.time_scale = GameConstants.BOSS_P3_SLOW_MO_SCALE

	# Letterbox
	_show_letterbox(1.5)

	# Camera zoom
	_phase3_camera_zoom()

	# Escalating shakes
	shake(GameConstants.BOSS_P3_SHAKE_1)
	_phase3_shake_sequence()

	# Flash 1
	if AccessibilityManager.can_flash():
		flash(0.08, GameConstants.BOSS_P3_FLASH_ALPHA)

	# Particles burst
	ParticleFactory.spawn_death_particles(boss_position, boss_color, GameConstants.BOSS_P3_PARTICLES_1)

	# SFX
	AudioManager.play_sfx("boss_phase")
	# Cinematic ducking during phase 3 transition (PRD 38)
	AudioManager.push_duck(
		AudioManager.DuckPriority.CINEMATIC,
		GameConstants.DUCK_CINEMATIC_MUSIC_DB,
		GameConstants.DUCK_CINEMATIC_SFX_DB
	)

	# Gamepad rumble
	Input.start_joy_vibration(0, GameConstants.BOSS_P3_RUMBLE_WEAK, GameConstants.BOSS_P3_RUMBLE_STRONG, GameConstants.BOSS_P3_RUMBLE_DURATION)

	# Title text
	_show_phase3_title()

	# Second burst + flash after delay
	_phase3_delayed_effects(boss_position, boss_color)

	# Restore time scale
	_phase3_restore_timescale()

func _phase3_camera_zoom() -> void:
	if not camera or not is_instance_valid(camera):
		camera = get_viewport().get_camera_3d()
	if not camera:
		return
	var original_fov = camera.fov
	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "fov", original_fov - GameConstants.BOSS_P3_ZOOM_AMOUNT, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	zoom_tween.tween_interval(0.6)
	zoom_tween.tween_property(camera, "fov", original_fov + 5.0, 0.15).set_ease(Tween.EASE_OUT)
	zoom_tween.tween_property(camera, "fov", original_fov, 0.2).set_ease(Tween.EASE_IN_OUT)

func _phase3_shake_sequence() -> void:
	await get_tree().create_timer(0.3 * Engine.time_scale).timeout
	shake(GameConstants.BOSS_P3_SHAKE_2)
	await get_tree().create_timer(0.4 * Engine.time_scale).timeout
	shake(GameConstants.BOSS_P3_SHAKE_3)

func _phase3_delayed_effects(boss_pos: Vector3, boss_color: Color) -> void:
	await get_tree().create_timer(0.5 * Engine.time_scale).timeout
	if AccessibilityManager.can_flash():
		if _flash_overlay:
			_flash_overlay.color = Color(boss_color.r, boss_color.g, boss_color.b, 0.2)
			_flash_overlay.visible = true
			var t = create_tween()
			t.tween_property(_flash_overlay, "color:a", 0.0, 0.1)
			t.tween_callback(func(): _flash_overlay.visible = false)
	await get_tree().create_timer(0.4 * Engine.time_scale).timeout
	ParticleFactory.spawn_death_particles(boss_pos, boss_color, GameConstants.BOSS_P3_PARTICLES_2)

func _phase3_restore_timescale() -> void:
	await get_tree().create_timer(GameConstants.BOSS_P3_SLOW_MO_DURATION * GameConstants.BOSS_P3_SLOW_MO_SCALE).timeout
	# Gradual restore
	var restore_tween = create_tween()
	restore_tween.tween_method(func(v): Engine.time_scale = v, GameConstants.BOSS_P3_SLOW_MO_SCALE, 1.0, 0.2)
	await restore_tween.finished
	AudioManager.pop_duck(AudioManager.DuckPriority.CINEMATIC)

func _show_phase3_title() -> void:
	if not _vignette_canvas:
		return
	if _phase3_title_label and is_instance_valid(_phase3_title_label):
		_phase3_title_label.queue_free()
	_phase3_title_label = Label.new()
	_phase3_title_label.text = LocaleManager.tr_key("boss_phase3_fury") if LocaleManager.has_method("tr_key") else "FURIA DESPERTA"
	_phase3_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase3_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_phase3_title_label.anchors_preset = Control.PRESET_CENTER
	_phase3_title_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_phase3_title_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_phase3_title_label.add_theme_font_size_override("font_size", 42)
	_phase3_title_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.1))
	_phase3_title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_phase3_title_label.add_theme_constant_override("outline_size", 6)
	_phase3_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phase3_title_label.modulate.a = 0.0
	_phase3_title_label.scale = Vector2(0.2, 0.2)
	_phase3_title_label.pivot_offset = Vector2(200, 25)
	_vignette_canvas.add_child(_phase3_title_label)

	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(_phase3_title_label, "modulate:a", 1.0, 0.15)
	t.tween_property(_phase3_title_label, "scale", Vector2(GameConstants.BOSS_P3_TITLE_SCALE_OVERSHOOT, GameConstants.BOSS_P3_TITLE_SCALE_OVERSHOOT), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.chain().tween_property(_phase3_title_label, "scale", Vector2(1.0, 1.0), 0.15)
	t.chain().tween_interval(1.0)
	t.chain().tween_property(_phase3_title_label, "modulate:a", 0.0, 0.3)
	t.chain().tween_callback(func():
		if is_instance_valid(_phase3_title_label):
			_phase3_title_label.queue_free()
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
