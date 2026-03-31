extends CanvasLayer

## Intro cinematic — 4 visual acts shown once on first play.
## Establishes Zion, the shattering, the Fragmented, and the mission.
## Skippable on any input. Uses tweens for all visuals (lightweight).

var _root: Control
var _bg: ColorRect
var _fade: ColorRect
var _text_label: RichTextLabel
var _skip_label: Label
var _finished: bool = false
var _skipping: bool = false
var _container: Control  # Holds act visuals (cleared between acts)

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_base()
	_run_cinematic()

func _build_base() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.02, 0.02, 0.06)
	_root.add_child(_bg)

	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_container)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.anchor_left = 0.1
	_text_label.anchor_right = 0.9
	_text_label.anchor_top = 0.65
	_text_label.anchor_bottom = 0.9
	_text_label.add_theme_font_size_override("normal_font_size", 22)
	_text_label.add_theme_color_override("default_color", Color(0.85, 0.8, 0.65))
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_label.text = ""
	_text_label.visible_characters = 0
	_root.add_child(_text_label)

	_skip_label = Label.new()
	_skip_label.text = LocaleManager.tr_key("intro_skip")
	_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_skip_label.anchor_top = 0.94
	_skip_label.add_theme_font_size_override("font_size", 12)
	_skip_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45, 0.5))
	_skip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_skip_label)

	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fade)

func _unhandled_input(event: InputEvent) -> void:
	if _finished or _skipping:
		return
	var valid = false
	if event is InputEventKey and event.pressed and not event.echo:
		valid = true
	elif event is InputEventJoypadButton and event.pressed:
		valid = true
	elif event is InputEventMouseButton and event.pressed:
		valid = true
	if valid:
		if get_viewport():
			get_viewport().set_input_as_handled()
		_skip()

func _skip() -> void:
	if _skipping:
		return
	_skipping = true
	SaveManager.data["story_seen"] = true
	SaveManager.data["intro_seen"] = true
	SaveManager.save_game()
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade, "color:a", 1.0, 0.5)
	tw.tween_callback(func():
		_finished = true
		queue_free()
	)

# ---- Cinematic sequence ----

func _run_cinematic() -> void:
	# Fade in from black
	_fade.color.a = 1.0
	var fi = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fi.tween_property(_fade, "color:a", 0.0, 1.0)
	await fi.finished
	if _skipping: return

	await _act1()
	if _skipping: return
	await _transition()
	if _skipping: return

	await _act2()
	if _skipping: return
	await _transition()
	if _skipping: return

	await _act3()
	if _skipping: return
	await _transition()
	if _skipping: return

	await _act4()
	if _skipping: return

	# End
	_skip()

# ---- Act transitions ----

func _transition() -> void:
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade, "color:a", 1.0, 0.6)
	await tw.finished
	_clear_act()
	var tw2 = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(_fade, "color:a", 0.0, 0.6)
	await tw2.finished

func _clear_act() -> void:
	for c in _container.get_children():
		c.queue_free()
	_text_label.text = ""
	_text_label.visible_characters = 0

func _typewriter(text: String, duration: float) -> void:
	_text_label.text = text
	_text_label.visible_characters = 0
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_text_label, "visible_characters", text.length(), duration)
	await tw.finished

func _wait(seconds: float) -> void:
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(seconds)
	await tw.finished

# ---- Act 1: Zion existed ----

func _act1() -> void:
	_bg.color = Color(0.02, 0.02, 0.08)

	# Stars
	for i in range(12):
		var star = ColorRect.new()
		star.size = Vector2(2, 2)
		star.color = Color(0.7, 0.7, 0.8, randf_range(0.3, 0.7))
		star.position = Vector2(randf_range(50, 1230), randf_range(30, 500))
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_container.add_child(star)

	# Golden crystal hexagon (6 rects arranged as hex)
	var center = Vector2(640, 280)
	var hex_node = Control.new()
	hex_node.position = center
	hex_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(hex_node)
	for i in range(6):
		var angle = float(i) / 6.0 * TAU
		var r = ColorRect.new()
		r.size = Vector2(20, 20)
		r.color = Color(1.0, 0.85, 0.2, 0.85)
		r.position = Vector2(cos(angle), sin(angle)) * 18 - Vector2(10, 10)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hex_node.add_child(r)
	# Center fill
	var core = ColorRect.new()
	core.size = Vector2(28, 28)
	core.color = Color(1.0, 0.9, 0.4, 0.9)
	core.position = Vector2(-14, -14)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hex_node.add_child(core)

	# Pulse crystal
	var pulse = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_loops(5)
	pulse.tween_property(hex_node, "scale", Vector2(1.08, 1.08), 0.8).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(hex_node, "scale", Vector2(0.95, 0.95), 0.8).set_trans(Tween.TRANS_SINE)

	await _typewriter(LocaleManager.tr_key("intro_act1_line1"), 2.5)
	if _skipping: return
	await _wait(1.5)
	if _skipping: return
	_text_label.text = ""
	_text_label.visible_characters = 0
	await _typewriter(LocaleManager.tr_key("intro_act1_line2"), 3.0)
	if _skipping: return
	await _wait(1.5)

# ---- Act 2: The shattering ----

func _act2() -> void:
	_bg.color = Color(0.1, 0.02, 0.02)

	var center = Vector2(640, 280)

	# Shattering: 10 shards fly outward
	var stage_colors = [
		Color(0.4, 0.5, 0.3), Color(0.2, 0.6, 0.2), Color(0.7, 0.6, 0.2),
		Color(0.9, 0.2, 0.3), Color(0.9, 0.5, 0.1), Color(0.2, 0.4, 0.9),
		Color(0.6, 0.3, 0.7), Color(0.15, 0.15, 0.4), Color(0.5, 0.5, 0.5),
		Color(0.9, 0.5, 0.7),
	]
	# Start with crystal at center, then shatter
	var crystal = ColorRect.new()
	crystal.size = Vector2(30, 30)
	crystal.color = Color(1.0, 0.9, 0.3)
	crystal.position = center - Vector2(15, 15)
	crystal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(crystal)

	await _wait(0.8)
	if _skipping: return

	# Flash + shatter
	_fade.color = Color(1, 1, 1, 0.8)
	var flash_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	flash_tw.tween_property(_fade, "color:a", 0.0, 0.5)
	AudioManager.play_sfx("boss_roar")

	# Shake container
	var orig_pos = _container.position
	for s in range(6):
		_container.position = orig_pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		await _wait(0.05)
	_container.position = orig_pos

	crystal.visible = false

	# Shards fly out
	for i in range(10):
		var shard = ColorRect.new()
		shard.size = Vector2(8, 12)
		shard.color = stage_colors[i]
		shard.position = center - Vector2(4, 6)
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_container.add_child(shard)
		var angle = float(i) / 10.0 * TAU
		var target = center + Vector2(cos(angle), sin(angle)) * 350
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(shard, "position", target, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(shard, "modulate:a", 0.3, 1.2)

	await _wait(0.5)
	if _skipping: return

	await _typewriter(LocaleManager.tr_key("intro_act2_line1"), 3.0)
	if _skipping: return
	await _wait(1.0)
	if _skipping: return
	_text_label.text = ""
	_text_label.visible_characters = 0
	await _typewriter(LocaleManager.tr_key("intro_act2_line2"), 2.5)
	if _skipping: return
	await _wait(1.5)

# ---- Act 3: The Fragmented ----

func _act3() -> void:
	_bg.color = Color(0.03, 0.03, 0.08)

	var center = Vector2(640, 260)

	# Glowing shard
	var shard = ColorRect.new()
	shard.size = Vector2(12, 18)
	shard.color = Color(0.5, 0.8, 1.2, 0.9)
	shard.position = center + Vector2(-6, -40)
	shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(shard)
	var shard_pulse = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_loops(8)
	shard_pulse.tween_property(shard, "modulate:a", 0.5, 0.6)
	shard_pulse.tween_property(shard, "modulate:a", 1.0, 0.6)

	# Character silhouette (ronin sprite with blue tint)
	var char_path = "res://assets/sprites/characters/ronin.png"
	if ResourceLoader.exists(char_path):
		var sprite = TextureRect.new()
		sprite.texture = load(char_path)
		sprite.custom_minimum_size = Vector2(96, 96)
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = center - Vector2(48, 48)
		sprite.modulate = Color(0.4, 0.6, 1.0, 0.0)
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_container.add_child(sprite)
		var sp_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		sp_tw.tween_property(sprite, "modulate:a", 0.9, 2.0)

	await _wait(1.0)
	if _skipping: return
	await _typewriter(LocaleManager.tr_key("intro_act3_line1"), 3.0)
	if _skipping: return
	await _wait(1.0)
	if _skipping: return
	_text_label.text = ""
	_text_label.visible_characters = 0
	await _typewriter(LocaleManager.tr_key("intro_act3_line2"), 2.0)
	if _skipping: return
	await _wait(1.0)
	if _skipping: return
	_text_label.text = ""
	_text_label.visible_characters = 0
	await _typewriter(LocaleManager.tr_key("intro_act3_line3"), 2.5)
	if _skipping: return
	await _wait(1.5)

# ---- Act 4: The mission ----

func _act4() -> void:
	_bg.color = Color(0.03, 0.02, 0.05)

	# 10 colored portals in an arc
	var stage_colors = [
		Color(0.4, 0.5, 0.3), Color(0.2, 0.6, 0.2), Color(0.7, 0.6, 0.2),
		Color(0.9, 0.2, 0.3), Color(0.9, 0.5, 0.1), Color(0.2, 0.4, 0.9),
		Color(0.6, 0.3, 0.7), Color(0.15, 0.2, 0.5), Color(0.5, 0.5, 0.5),
		Color(0.9, 0.5, 0.7),
	]
	var arc_center = Vector2(640, 300)
	for i in range(10):
		var angle = PI + float(i) / 9.0 * PI  # Arc from left to right
		var pos = arc_center + Vector2(cos(angle), sin(angle) * 0.5) * 280

		# Portal glow
		var portal = ColorRect.new()
		portal.size = Vector2(36, 36)
		portal.color = stage_colors[i].lightened(0.1)
		portal.position = pos - Vector2(18, 18)
		portal.modulate.a = 0.0
		portal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_container.add_child(portal)

		# Dark center (sentinel shadow)
		var shadow = ColorRect.new()
		shadow.size = Vector2(16, 16)
		shadow.color = Color(0.05, 0.05, 0.08, 0.9)
		shadow.position = Vector2(10, 10)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portal.add_child(shadow)

		# Staggered fade in
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(portal, "modulate:a", 1.0, 0.4).set_delay(i * 0.15)

	await _wait(2.0)
	if _skipping: return
	await _typewriter(LocaleManager.tr_key("intro_act4_line1"), 3.0)
	if _skipping: return
	await _wait(1.0)
	if _skipping: return
	_text_label.text = ""
	_text_label.visible_characters = 0
	await _typewriter(LocaleManager.tr_key("intro_act4_line2"), 2.0)
	if _skipping: return
	await _wait(1.0)
	if _skipping: return

	# Final line — gold, larger
	_text_label.add_theme_font_size_override("normal_font_size", 32)
	_text_label.add_theme_color_override("default_color", Color(1.0, 0.85, 0.2))
	_text_label.text = ""
	_text_label.visible_characters = 0
	await _typewriter(LocaleManager.tr_key("intro_act4_line3"), 1.5)
	if _skipping: return
	await _wait(2.5)
