extends CanvasLayer

## Achievement popup system — slide-in notification from right side.
## Registers itself to AchievementManager.achievement_unlocked signal.
## Queue system: if multiple achievements unlock at once, shows one at a time.

const POPUP_WIDTH := 320.0
const POPUP_HEIGHT := 80.0
const SLIDE_IN_DURATION := 0.3
const STAY_DURATION := 4.0
const SLIDE_OUT_DURATION := 0.3
const QUEUE_DELAY := 0.5
const MARGIN_RIGHT := 16.0
const MARGIN_TOP := 100.0

# Colors
const COLOR_BG_TOP := Color(0.18, 0.15, 0.06, 0.95)
const COLOR_BG_BOTTOM := Color(0.12, 0.10, 0.04, 0.95)
const COLOR_BORDER := Color(0.85, 0.7, 0.2)
const COLOR_GOLD := Color(1.0, 0.85, 0.2)
const COLOR_GOLD_FLASH := Color(1.0, 0.9, 0.4, 0.3)
const COLOR_WHITE := Color(0.95, 0.95, 0.97)
const COLOR_GRAY := Color(0.65, 0.65, 0.7)

var _achievement_queue: Array[Dictionary] = []
var _is_showing: bool = false
var _popup_panel: PanelContainer = null
var _icon_rect: TextureRect = null
var _title_label: Label = null
var _name_label: Label = null
var _desc_label: Label = null
var _flash_rect: ColorRect = null
var _sparkle_particles: Array[ColorRect] = []
var _sparkle_time: float = 0.0
var _is_sparkling: bool = false


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	_build_popup()


func _build_popup() -> void:
	# Panel container with custom stylebox
	_popup_panel = PanelContainer.new()
	_popup_panel.name = "AchievementPopup"
	_popup_panel.custom_minimum_size = Vector2(POPUP_WIDTH, POPUP_HEIGHT)
	_popup_panel.size = Vector2(POPUP_WIDTH, POPUP_HEIGHT)

	# Position off-screen to the right
	_popup_panel.position = Vector2(1280.0 + POPUP_WIDTH, MARGIN_TOP)
	_popup_panel.visible = false

	# Stylebox: dark gold gradient with gold border and rounded corners
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_BG_TOP
	sb.border_color = COLOR_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_popup_panel.add_theme_stylebox_override("panel", sb)

	# Flash overlay (gold flash on entry)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup_panel.add_child(_flash_rect)

	# Main HBox layout: [Icon] [Text VBox]
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Trophy/Icon area
	var icon_margin := MarginContainer.new()
	icon_margin.add_theme_constant_override("margin_top", 4)
	icon_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_icon_rect = TextureRect.new()
	_icon_rect.custom_minimum_size = Vector2(32, 32)
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_margin.add_child(_icon_rect)
	hbox.add_child(icon_margin)

	# Text column
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_title_label = Label.new()
	_title_label.text = "CONQUISTA!"
	_title_label.add_theme_font_size_override("font_size", 10)
	_title_label.add_theme_color_override("font_color", COLOR_GOLD)
	_title_label.uppercase = true
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_title_label)

	_name_label = Label.new()
	_name_label.text = ""
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.add_theme_color_override("font_color", COLOR_WHITE)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_name_label)

	_desc_label = Label.new()
	_desc_label.text = ""
	_desc_label.add_theme_font_size_override("font_size", 10)
	_desc_label.add_theme_color_override("font_color", COLOR_GRAY)
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_desc_label)

	hbox.add_child(vbox)
	_popup_panel.add_child(hbox)

	add_child(_popup_panel)

	# Create sparkle particles (hidden initially)
	for i in range(8):
		var sparkle := ColorRect.new()
		sparkle.size = Vector2(3, 3)
		sparkle.color = Color(1.0, 0.9, 0.4, 0.0)
		sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sparkle.visible = false
		add_child(sparkle)
		_sparkle_particles.append(sparkle)


func _on_achievement_unlocked(id: String, achievement_name: String) -> void:
	var ach_data := AchievementManager.achievements.get(id, {}) as Dictionary
	var desc: String = ach_data.get("description", "")
	_achievement_queue.append({
		"id": id,
		"name": achievement_name,
		"description": desc,
	})
	if not _is_showing:
		_show_next()


func _show_next() -> void:
	if _achievement_queue.is_empty():
		_is_showing = false
		return
	_is_showing = true
	var data: Dictionary = _achievement_queue.pop_front()
	_display_popup(data)


func _display_popup(data: Dictionary) -> void:
	var id: String = data.get("id", "")
	var ach_name: String = data.get("name", "")
	var desc: String = data.get("description", "")

	# Set text
	_name_label.text = ach_name
	_desc_label.text = desc

	# Load icon
	var icon_path := "res://assets/sprites/achievements/%s.png" % id
	if ResourceLoader.exists(icon_path):
		_icon_rect.texture = load(icon_path)
		_icon_rect.visible = true
	else:
		# Fallback: create a simple trophy-colored placeholder
		_icon_rect.texture = _create_placeholder_icon()
		_icon_rect.visible = true

	# Reset position (off-screen right)
	var target_x := 1280.0 - POPUP_WIDTH - MARGIN_RIGHT
	_popup_panel.position = Vector2(1280.0 + 10.0, MARGIN_TOP)
	_popup_panel.visible = true
	_popup_panel.modulate = Color.WHITE

	# Play sound
	if AudioManager.has_method("play_sfx"):
		# Try "achievement" first, fallback to "level_up"
		var sfx_list: Array = AudioManager.get("sfx_list") if AudioManager.get("sfx_list") else []
		if "achievement" in sfx_list:
			AudioManager.play_sfx("achievement")
		else:
			AudioManager.play_sfx("level_up")

	# Slide-in animation with EASE_OUT_BACK (bouncy entrance)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Slide in
	tween.tween_property(_popup_panel, "position:x", target_x, SLIDE_IN_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Gold flash on entry
	tween.parallel().tween_property(_flash_rect, "color", COLOR_GOLD_FLASH, 0.05)
	tween.tween_property(_flash_rect, "color", Color(0, 0, 0, 0), 0.2)

	# Start sparkles
	_is_sparkling = true
	_sparkle_time = 0.0
	_start_sparkles()

	# Stay
	tween.tween_interval(STAY_DURATION)

	# Stop sparkles before sliding out
	tween.tween_callback(func(): _is_sparkling = false; _hide_sparkles())

	# Slide out
	tween.tween_property(_popup_panel, "position:x", 1280.0 + 10.0, SLIDE_OUT_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Hide and process queue
	tween.tween_callback(func():
		_popup_panel.visible = false
	)
	tween.tween_interval(QUEUE_DELAY)
	tween.tween_callback(_show_next)


func _start_sparkles() -> void:
	for sparkle in _sparkle_particles:
		sparkle.visible = true
		_randomize_sparkle(sparkle)


func _hide_sparkles() -> void:
	for sparkle in _sparkle_particles:
		sparkle.visible = false
		sparkle.color.a = 0.0


func _randomize_sparkle(sparkle: ColorRect) -> void:
	# Random position around the popup panel
	var panel_pos := _popup_panel.position
	var rx := randf_range(-8.0, POPUP_WIDTH + 8.0)
	var ry := randf_range(-8.0, POPUP_HEIGHT + 8.0)
	sparkle.position = panel_pos + Vector2(rx, ry)
	sparkle.size = Vector2(randf_range(2.0, 4.0), randf_range(2.0, 4.0))
	sparkle.color = Color(1.0, randf_range(0.8, 1.0), randf_range(0.3, 0.6), randf_range(0.4, 0.9))


func _process(delta: float) -> void:
	if not _is_sparkling:
		return
	_sparkle_time += delta
	# Animate sparkles: twinkle effect
	for i in range(_sparkle_particles.size()):
		var sparkle := _sparkle_particles[i]
		if not sparkle.visible:
			continue
		# Twinkle: oscillate alpha
		var phase := _sparkle_time * 3.0 + float(i) * 0.8
		sparkle.color.a = (sin(phase) * 0.5 + 0.5) * 0.8
		# Slowly drift upward
		sparkle.position.y -= 8.0 * delta
		# Re-randomize when faded or drifted too far
		if sparkle.position.y < _popup_panel.position.y - 15.0:
			_randomize_sparkle(sparkle)


func _create_placeholder_icon() -> ImageTexture:
	# Create a simple gold trophy-like 32x32 placeholder
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Draw a simple gold circle as placeholder
	var center := Vector2(16, 16)
	for x in range(32):
		for y in range(32):
			var dist := Vector2(x, y).distance_to(center)
			if dist < 12.0:
				var alpha := clampf(1.0 - (dist / 12.0) * 0.3, 0.0, 1.0)
				img.set_pixel(x, y, Color(0.9, 0.75, 0.2, alpha))
			elif dist < 13.0:
				img.set_pixel(x, y, Color(0.7, 0.55, 0.1, 0.8))
	return ImageTexture.create_from_image(img)
