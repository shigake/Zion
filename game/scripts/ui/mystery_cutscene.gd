extends CanvasLayer

## Cutscene for the mystery character awakening.
## Plays when all 13 characters are unlocked, revealing Zion's consciousness.
## Skippable on any input. ~15 seconds total.

signal cutscene_finished

var _root: Control
var _fade_rect: ColorRect
var _bg: ColorRect
var _skipping: bool = false
var _finished: bool = false
var _active_tweens: Array = []

const CHAR_IDS := [
	"ronin", "soldado", "mago", "berserker", "ninja",
	"bruxa", "pirata", "engenheiro", "vampiro", "gladiador",
	"chef", "amazona", "lealith"
]

const VIEWPORT_SIZE := Vector2(1280, 720)
const CIRCLE_RADIUS := 200.0
const ICON_SIZE := Vector2(48, 48)
const CRYSTAL_COUNT := 12
const GOLDEN := Color(1.0, 0.85, 0.2)


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_play_cutscene()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	# Dark background
	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.02, 0.02, 0.04)
	_bg.modulate.a = 0.0
	_root.add_child(_bg)

	# Fade rect for transitions
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fade_rect)

	# Skip hint
	var skip_label = Label.new()
	skip_label.text = "Pressione qualquer tecla para pular"
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	skip_label.anchor_top = 0.93
	skip_label.add_theme_font_size_override("font_size", 14)
	skip_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.4))
	_root.add_child(skip_label)


func _play_cutscene() -> void:
	var center = VIEWPORT_SIZE * 0.5

	# === 0.0s: Fade in dark background ===
	var tw_bg = _create_tween()
	tw_bg.tween_property(_bg, "modulate:a", 1.0, 0.5)
	await tw_bg.finished

	if _skipping:
		return

	# === 0.5s: First text with typewriter ===
	var text1 = _create_label(LocaleManager.tr_key("cutscene_mystery_1"), 24, GOLDEN, center + Vector2(0, -80))
	_root.add_child(text1)
	await _typewriter(text1, 0.05)

	if _skipping:
		return

	# Hold text briefly
	await _wait(1.5)
	if _skipping:
		return

	# === 3.0s: Brief fade to black ===
	var tw_fade1 = _create_tween()
	tw_fade1.tween_property(_fade_rect, "modulate:a", 1.0, 0.4)
	await tw_fade1.finished
	if _skipping:
		return

	text1.queue_free()

	# === 3.5s: Fade back, show 13 character icons in circle ===
	var tw_fade2 = _create_tween()
	tw_fade2.tween_property(_fade_rect, "modulate:a", 0.0, 0.3)
	await tw_fade2.finished
	if _skipping:
		return

	var char_icons: Array = []
	for i in range(CHAR_IDS.size()):
		var angle = float(i) / float(CHAR_IDS.size()) * TAU - PI / 2.0
		var pos = center + Vector2(cos(angle), sin(angle)) * CIRCLE_RADIUS

		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = ICON_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var icon_path = "res://assets/sprites/characters/%s.png" % CHAR_IDS[i]
		if ResourceLoader.exists(icon_path):
			tex_rect.texture = load(icon_path)
		tex_rect.position = pos - ICON_SIZE * 0.5
		tex_rect.modulate.a = 0.0
		_root.add_child(tex_rect)
		char_icons.append(tex_rect)

		# Staggered fade-in
		var tw_icon = _create_tween()
		tw_icon.tween_interval(i * 0.12)
		tw_icon.tween_property(tex_rect, "modulate:a", 1.0, 0.3)

	# Wait for all icons to appear
	await _wait(CHAR_IDS.size() * 0.12 + 0.5)
	if _skipping:
		return

	# === 5.5s: Golden crystal particles rise from edges toward center ===
	var crystals: Array = []
	for i in range(CRYSTAL_COUNT):
		var crystal = ColorRect.new()
		crystal.size = Vector2(6, 6)
		crystal.color = GOLDEN
		crystal.modulate.a = 0.8

		# Start from random edge positions
		var edge_angle = randf() * TAU
		var edge_dist = CIRCLE_RADIUS + 80.0 + randf() * 60.0
		var start_pos = center + Vector2(cos(edge_angle), sin(edge_angle)) * edge_dist
		crystal.position = start_pos
		_root.add_child(crystal)
		crystals.append(crystal)

		var tw_crystal = _create_tween()
		tw_crystal.tween_interval(i * 0.1)
		tw_crystal.tween_property(crystal, "position", center - Vector2(3, 3), 1.2 + randf() * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_crystal.parallel().tween_property(crystal, "modulate:a", 0.0, 1.0).set_delay(0.5)

	await _wait(1.5)
	if _skipping:
		return

	# === 7.0s: White flash ===
	var flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(1.0, 1.0, 1.0)
	flash_rect.modulate.a = 0.0
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(flash_rect)

	AudioManager.play_sfx("achievement")

	var tw_flash = _create_tween()
	tw_flash.tween_property(flash_rect, "modulate:a", 1.0, 0.15)
	tw_flash.tween_property(flash_rect, "modulate:a", 0.0, 0.8)
	await tw_flash.finished
	if _skipping:
		return

	# Remove character icons and crystals after flash
	for icon in char_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	for c in crystals:
		if is_instance_valid(c):
			c.queue_free()
	if is_instance_valid(flash_rect):
		flash_rect.queue_free()

	# === 7.5s: Mystery character sprite with scale bounce ===
	var mystery_sprite = TextureRect.new()
	mystery_sprite.custom_minimum_size = Vector2(96, 96)
	mystery_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mystery_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mystery_path = "res://assets/sprites/characters/mystery.png"
	if ResourceLoader.exists(mystery_path):
		mystery_sprite.texture = load(mystery_path)
	mystery_sprite.position = center - Vector2(48, 48)
	mystery_sprite.modulate = Color(1.2, 1.1, 0.9, 0.0)
	mystery_sprite.pivot_offset = Vector2(48, 48)
	mystery_sprite.scale = Vector2(0.5, 0.5)
	_root.add_child(mystery_sprite)

	var tw_mystery = _create_tween()
	tw_mystery.tween_property(mystery_sprite, "modulate:a", 1.0, 0.4)
	tw_mystery.parallel().tween_property(mystery_sprite, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw_mystery.finished
	if _skipping:
		return

	# === 8.5s: Main text with typewriter ===
	var text2 = _create_label(LocaleManager.tr_key("cutscene_mystery_2"), 28, Color(1.0, 0.95, 0.85), center + Vector2(0, 100))
	text2.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	text2.add_theme_constant_override("outline_size", 3)
	_root.add_child(text2)
	await _typewriter(text2, 0.045)

	if _skipping:
		return

	# === 12.0s: Hold ===
	await _wait(3.5)
	if _skipping:
		return

	# === 14.0s: Fade out ===
	var tw_out = _create_tween()
	tw_out.tween_property(_fade_rect, "modulate:a", 1.0, 1.0)
	await tw_out.finished

	if _skipping:
		return

	# === 15.0s: Done ===
	_finish()


func _create_label(text: String, font_size: int, color: Color, pos: Vector2) -> Label:
	var label = Label.new()
	label.text = ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.anchor_left = 0.1
	label.anchor_right = 0.9
	label.offset_left = 0
	label.offset_right = 0
	label.position.y = pos.y - font_size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.set_meta("full_text", text)
	return label


func _typewriter(label: Label, speed: float) -> void:
	var full_text = label.get_meta("full_text")
	for i in range(full_text.length()):
		if _skipping:
			return
		label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(speed).timeout


func _wait(seconds: float) -> void:
	var elapsed = 0.0
	while elapsed < seconds:
		if _skipping:
			return
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05


func _create_tween() -> Tween:
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_active_tweens.append(tw)
	return tw


func _unhandled_input(event: InputEvent) -> void:
	if _finished or _skipping:
		return

	var is_valid = false
	if event is InputEventKey and event.pressed and not event.echo:
		is_valid = true
	elif event is InputEventJoypadButton and event.pressed:
		is_valid = true
	elif event is InputEventMouseButton and event.pressed:
		is_valid = true

	if is_valid:
		if get_viewport():
			get_viewport().set_input_as_handled()
		_skip()


func _skip() -> void:
	if _skipping:
		return
	_skipping = true

	# Kill all active tweens
	for tw in _active_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_active_tweens.clear()

	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true

	# Mark as seen
	SaveManager.data["mystery_cutscene_seen"] = true
	SaveManager.save_game()

	cutscene_finished.emit()
	queue_free()
