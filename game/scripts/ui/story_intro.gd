extends CanvasLayer

## Story intro screen — shown once on first play.
## Typewriter effect over dark background, skippable on any input.

var _root: Control
var _label: RichTextLabel
var _fade_rect: ColorRect
var _timer: float = 0.0
var _char_index: int = 0
var _finished: bool = false
var _skipping: bool = false
var _full_text: String = ""
var _display_speed: float = 0.04  # seconds per character
var _hold_time: float = 3.0  # seconds to hold after text is fully shown
var _hold_timer: float = 0.0

const STORY_TEXT_PT := """Zion... o paraiso perdido.

Um reino que existia entre mundos,
destruido por uma forca antiga.

10 fragmentos espalhados pela realidade.
10 guardioes corrompidos.

Voce e um Fragmentado —
escolhido para restaurar o que foi perdido.

Sobreviva. Evolua. Restaure Zion."""

const STORY_TEXT_EN := """Zion... the lost paradise.

A realm that existed between worlds,
destroyed by an ancient force.

10 fragments scattered across reality.
10 corrupted guardians.

You are a Fragmented —
chosen to restore what was lost.

Survive. Evolve. Restore Zion."""


func _ready() -> void:
	layer = 110  # Above everything
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Pick language
	var locale = SaveManager.data.get("locale", "pt")
	if locale == "en":
		_full_text = STORY_TEXT_EN
	else:
		_full_text = STORY_TEXT_PT

	_build_ui()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	# Dark background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.04)
	_root.add_child(bg)

	# Centered text label
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.anchor_left = 0.15
	_label.anchor_right = 0.85
	_label.anchor_top = 0.2
	_label.anchor_bottom = 0.8
	_label.offset_left = 0
	_label.offset_right = 0
	_label.offset_top = 0
	_label.offset_bottom = 0
	_label.add_theme_font_size_override("normal_font_size", 22)
	_label.add_theme_color_override("default_color", Color(0.85, 0.8, 0.65))
	_label.text = ""
	_root.add_child(_label)

	# "Skip" hint at bottom
	var skip_label = Label.new()
	skip_label.text = "Pressione qualquer tecla para pular"
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	skip_label.anchor_top = 0.92
	skip_label.add_theme_font_size_override("font_size", 14)
	skip_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.6))
	_root.add_child(skip_label)

	# Fade rect for transition out
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fade_rect)


func _process(delta: float) -> void:
	if _finished:
		return

	if _skipping:
		return

	# Typewriter effect
	if _char_index < _full_text.length():
		_timer += delta
		while _timer >= _display_speed and _char_index < _full_text.length():
			_timer -= _display_speed
			_char_index += 1
			_label.text = _full_text.substr(0, _char_index)
	else:
		# Text fully shown, hold then fade
		_hold_timer += delta
		if _hold_timer >= _hold_time:
			_skip()


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

	# Mark story as seen
	SaveManager.data["story_seen"] = true
	SaveManager.save_game()

	# Fade out
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_rect.modulate.a = 0.0
	tween.tween_property(_fade_rect, "modulate:a", 1.0, 0.8)
	tween.tween_callback(_finish)


func _finish() -> void:
	_finished = true
	queue_free()
