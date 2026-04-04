extends Control

## PRD 37 — Procedural synergy icons HUD with tooltips, banners, cooldown arcs,
## proc counters, responsive layout, and accessibility support.
## Replaces the old emoji-based synergy display.

# ---- Element type to shape mapping ----
enum ShapeType { TRIANGLE, HEXAGON, ZIGZAG, CRESCENT, DROP, BUBBLES, STAR6, FIST }

const ELEMENT_SHAPES := {
	"fire": ShapeType.TRIANGLE,
	"ice": ShapeType.HEXAGON,
	"electric": ShapeType.ZIGZAG,
	"dark": ShapeType.CRESCENT,
	"water": ShapeType.DROP,
	"poison": ShapeType.BUBBLES,
	"light": ShapeType.STAR6,
	"physical": ShapeType.FIST,
}

# ---- State ----
var _synergy_icons: Dictionary = {}       # synergy_id -> { panel, badge, icon_tex, elements }
var _first_activations: Dictionary = {}   # synergy_id -> true (track first activation per run)
var _icon_container: HFlowContainer
var _tooltip_panel: PanelContainer
var _tooltip_name_label: Label
var _tooltip_type_label: Label
var _tooltip_effect_label: Label
var _tooltip_trigger_label: Label
var _tooltip_cooldown_label: Label
var _tooltip_stats_label: Label
var _banner_container: Control
var _banner_queue: Array[Dictionary] = []
var _banner_active: bool = false
var _icon_cache: Dictionary = {}          # "shape_color_size" -> ImageTexture
var _focused_synergy: String = ""         # For gamepad navigation
var _focus_index: int = -1

func _ready() -> void:
	_build_ui()
	SynergySystem.synergy_activated.connect(_on_synergy_activated)
	SynergySystem.synergy_procced.connect(_on_synergy_procced)

func _build_ui() -> void:
	# Icon flow container — wraps to multiple rows when needed
	_icon_container = HFlowContainer.new()
	_icon_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_icon_container)

	_build_tooltip()
	_build_banner()

# ==================================================================
# TOOLTIP
# ==================================================================

func _build_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.z_index = 50
	_tooltip_panel.custom_minimum_size.x = GameConstants.SYNERGY_TOOLTIP_WIDTH

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.06, 0.92)
	style.border_color = Color(0.4, 0.5, 0.7, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	_tooltip_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)

	_tooltip_name_label = Label.new()
	_tooltip_name_label.add_theme_font_size_override("font_size", 14)
	_tooltip_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	_tooltip_name_label.uppercase = true
	vbox.add_child(_tooltip_name_label)

	_tooltip_type_label = Label.new()
	_tooltip_type_label.add_theme_font_size_override("font_size", 11)
	_tooltip_type_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(_tooltip_type_label)

	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	vbox.add_child(sep)

	_tooltip_effect_label = Label.new()
	_tooltip_effect_label.add_theme_font_size_override("font_size", 12)
	_tooltip_effect_label.add_theme_color_override("font_color", Color.WHITE)
	_tooltip_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_effect_label.custom_minimum_size.x = GameConstants.SYNERGY_TOOLTIP_WIDTH - 20
	vbox.add_child(_tooltip_effect_label)

	_tooltip_trigger_label = Label.new()
	_tooltip_trigger_label.add_theme_font_size_override("font_size", 11)
	_tooltip_trigger_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	vbox.add_child(_tooltip_trigger_label)

	_tooltip_cooldown_label = Label.new()
	_tooltip_cooldown_label.add_theme_font_size_override("font_size", 11)
	_tooltip_cooldown_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	vbox.add_child(_tooltip_cooldown_label)

	# Stats line: procs | DPS
	_tooltip_stats_label = Label.new()
	_tooltip_stats_label.add_theme_font_size_override("font_size", 11)
	_tooltip_stats_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
	vbox.add_child(_tooltip_stats_label)

	_tooltip_panel.add_child(vbox)
	add_child(_tooltip_panel)

# ==================================================================
# BANNER
# ==================================================================

func _build_banner() -> void:
	_banner_container = Control.new()
	_banner_container.visible = false
	_banner_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Position: center-left of screen (y = 40%)
	_banner_container.anchor_left = 0.0
	_banner_container.anchor_top = 0.0
	_banner_container.anchor_right = 0.0
	_banner_container.anchor_bottom = 0.0
	_banner_container.offset_left = -GameConstants.SYNERGY_BANNER_WIDTH
	_banner_container.offset_top = 720 * 0.4
	_banner_container.offset_right = 0
	_banner_container.offset_bottom = 720 * 0.4 + GameConstants.SYNERGY_BANNER_HEIGHT
	_banner_container.custom_minimum_size = Vector2(GameConstants.SYNERGY_BANNER_WIDTH, GameConstants.SYNERGY_BANNER_HEIGHT)
	add_child(_banner_container)

# ==================================================================
# PROCEDURAL ICON GENERATION
# ==================================================================

func _generate_synergy_icon(synergy_id: String, synergy_data: Dictionary, icon_size: int) -> ImageTexture:
	var cache_key = "%s_%d" % [synergy_id, icon_size]
	if cache_key in _icon_cache:
		return _icon_cache[cache_key]

	var img = Image.create(icon_size, icon_size, false, Image.FORMAT_RGBA8)
	var color: Color = synergy_data.get("color", Color.WHITE)
	var center = Vector2(icon_size / 2.0, icon_size / 2.0)
	var radius = icon_size / 2.0 - 2.0

	# Draw radial gradient background circle
	for y in range(icon_size):
		for x in range(icon_size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				var t = dist / radius
				var bg_color = color * 0.5
				bg_color.a = lerp(0.9, 0.4, t)
				img.set_pixel(x, y, bg_color)
			elif dist <= radius + 1.5:
				# Anti-aliased border
				var border_alpha = 1.0 - (dist - radius) / 1.5
				var border_color = color.lightened(0.3)
				border_color.a = border_alpha * 0.9
				img.set_pixel(x, y, border_color)

	# Draw border ring (2px)
	var border_thickness = 2
	if AccessibilityManager.high_contrast:
		border_thickness = 3
	for y in range(icon_size):
		for x in range(icon_size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist >= radius - border_thickness and dist <= radius:
				var border_color = color.lightened(0.4)
				border_color.a = 0.95
				img.set_pixel(x, y, border_color)

	# Determine which shapes to draw (cross-synergies get split icons)
	var elements = _get_synergy_elements(synergy_id)
	if elements.size() == 2 and elements[0] != elements[1]:
		# Cross synergy: draw both shapes side by side
		var left_shape = ELEMENT_SHAPES.get(elements[0], ShapeType.TRIANGLE)
		var right_shape = ELEMENT_SHAPES.get(elements[1], ShapeType.TRIANGLE)
		_draw_shape_on_image(img, left_shape, center + Vector2(-icon_size * 0.15, 0), icon_size * 0.25, color.lightened(0.5))
		_draw_shape_on_image(img, right_shape, center + Vector2(icon_size * 0.15, 0), icon_size * 0.25, color.lightened(0.5))
	else:
		# Single element synergy
		var elem = elements[0] if elements.size() > 0 else "fire"
		var shape = ELEMENT_SHAPES.get(elem, ShapeType.TRIANGLE)
		_draw_shape_on_image(img, shape, center, icon_size * 0.3, color.lightened(0.6))

	var tex = ImageTexture.create_from_image(img)
	_icon_cache[cache_key] = tex
	return tex

func _get_synergy_elements(synergy_id: String) -> Array[String]:
	var parts = synergy_id.split("_")
	if parts.size() >= 2:
		return [parts[0], parts[1]]
	return [synergy_id]

func _draw_shape_on_image(img: Image, shape: ShapeType, center: Vector2, shape_radius: float, color: Color) -> void:
	match shape:
		ShapeType.TRIANGLE:
			_draw_triangle(img, center, shape_radius, color)
		ShapeType.HEXAGON:
			_draw_polygon(img, center, shape_radius, 6, color)
		ShapeType.ZIGZAG:
			_draw_zigzag(img, center, shape_radius, color)
		ShapeType.CRESCENT:
			_draw_crescent(img, center, shape_radius, color)
		ShapeType.DROP:
			_draw_drop(img, center, shape_radius, color)
		ShapeType.BUBBLES:
			_draw_bubbles(img, center, shape_radius, color)
		ShapeType.STAR6:
			_draw_star(img, center, shape_radius, 6, color)
		ShapeType.FIST:
			_draw_fist(img, center, shape_radius, color)

func _draw_triangle(img: Image, center: Vector2, r: float, color: Color) -> void:
	# Upward-pointing triangle (flame shape)
	var p0 = center + Vector2(0, -r)
	var p1 = center + Vector2(-r * 0.87, r * 0.5)
	var p2 = center + Vector2(r * 0.87, r * 0.5)
	_fill_triangle_img(img, p0, p1, p2, color)

func _draw_polygon(img: Image, center: Vector2, r: float, sides: int, color: Color) -> void:
	var points: Array[Vector2] = []
	for i in range(sides):
		var angle = -PI / 2.0 + TAU * i / sides
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	for i in range(1, sides - 1):
		_fill_triangle_img(img, points[0], points[i], points[i + 1], color)

func _draw_zigzag(img: Image, center: Vector2, r: float, color: Color) -> void:
	# Lightning bolt shape
	var pts: Array[Vector2] = [
		center + Vector2(-r * 0.2, -r),
		center + Vector2(r * 0.3, -r),
		center + Vector2(-r * 0.1, -r * 0.1),
		center + Vector2(r * 0.4, -r * 0.1),
		center + Vector2(-r * 0.3, r),
		center + Vector2(r * 0.1, r * 0.1),
		center + Vector2(-r * 0.4, r * 0.1),
	]
	# Draw as filled triangles
	_fill_triangle_img(img, pts[0], pts[1], pts[2], color)
	_fill_triangle_img(img, pts[1], pts[2], pts[3], color)
	_fill_triangle_img(img, pts[2], pts[3], pts[5], color)
	_fill_triangle_img(img, pts[3], pts[4], pts[5], color)

func _draw_crescent(img: Image, center: Vector2, r: float, color: Color) -> void:
	# Crescent moon: full circle minus offset circle
	var w = img.get_width()
	var h = img.get_height()
	var offset = r * 0.4
	for y in range(h):
		for x in range(w):
			var pos = Vector2(x, y)
			var d_main = pos.distance_to(center)
			var d_cut = pos.distance_to(center + Vector2(offset, -offset * 0.3))
			if d_main <= r and d_cut > r * 0.85:
				img.set_pixel(x, y, color)

func _draw_drop(img: Image, center: Vector2, r: float, color: Color) -> void:
	# Water drop: circle at bottom, pointed top
	var w = img.get_width()
	var h = img.get_height()
	var circle_center = center + Vector2(0, r * 0.3)
	var circle_r = r * 0.7
	var tip = center + Vector2(0, -r)
	for y in range(h):
		for x in range(w):
			var pos = Vector2(x, y)
			# Bottom circle
			if pos.distance_to(circle_center) <= circle_r:
				img.set_pixel(x, y, color)
			# Top triangle leading to tip
			elif pos.y < circle_center.y and pos.y >= tip.y:
				var t = (circle_center.y - pos.y) / (circle_center.y - tip.y)
				var half_width = circle_r * (1.0 - t)
				if abs(pos.x - center.x) <= half_width:
					img.set_pixel(x, y, color)

func _draw_bubbles(img: Image, center: Vector2, r: float, color: Color) -> void:
	# 3 overlapping circles (toxic bubbles)
	var offsets = [Vector2(-r * 0.35, r * 0.2), Vector2(r * 0.35, r * 0.2), Vector2(0, -r * 0.3)]
	var bubble_r = r * 0.45
	var w = img.get_width()
	var h = img.get_height()
	for y in range(h):
		for x in range(w):
			var pos = Vector2(x, y)
			for off in offsets:
				if pos.distance_to(center + off) <= bubble_r:
					img.set_pixel(x, y, color)
					break

func _draw_star(img: Image, center: Vector2, r: float, points_count: int, color: Color) -> void:
	# 6-pointed star
	var inner_r = r * 0.5
	var pts: Array[Vector2] = []
	for i in range(points_count * 2):
		var angle = -PI / 2.0 + TAU * i / (points_count * 2)
		var rad = r if i % 2 == 0 else inner_r
		pts.append(center + Vector2(cos(angle), sin(angle)) * rad)
	for i in range(1, pts.size() - 1):
		_fill_triangle_img(img, pts[0], pts[i], pts[i + 1], color)

func _draw_fist(img: Image, center: Vector2, r: float, color: Color) -> void:
	# Simplified fist: square with notch lines
	var half = r * 0.8
	var w = img.get_width()
	var h = img.get_height()
	for y in range(h):
		for x in range(w):
			var pos = Vector2(x, y)
			if abs(pos.x - center.x) <= half and abs(pos.y - center.y) <= half:
				# Add finger notch lines
				var rel_x = pos.x - (center.x - half)
				var line_spacing = half * 2.0 / 4.0
				var on_line = false
				for li in range(1, 4):
					if abs(rel_x - li * line_spacing) < 0.8 and pos.y < center.y + half * 0.3:
						on_line = true
						break
				if on_line:
					img.set_pixel(x, y, color.darkened(0.3))
				else:
					img.set_pixel(x, y, color)

func _fill_triangle_img(img: Image, p0: Vector2, p1: Vector2, p2: Vector2, color: Color) -> void:
	# Simple scanline triangle fill on Image
	var min_y = int(max(0, min(p0.y, min(p1.y, p2.y))))
	var max_y = int(min(img.get_height() - 1, max(p0.y, max(p1.y, p2.y))))
	var min_x_bound = int(max(0, min(p0.x, min(p1.x, p2.x))))
	var max_x_bound = int(min(img.get_width() - 1, max(p0.x, max(p1.x, p2.x))))
	for y in range(min_y, max_y + 1):
		for x in range(min_x_bound, max_x_bound + 1):
			if _point_in_triangle(Vector2(x, y), p0, p1, p2):
				img.set_pixel(x, y, color)

func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 = _sign_2d(p, a, b)
	var d2 = _sign_2d(p, b, c)
	var d3 = _sign_2d(p, c, a)
	var has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
	var has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
	return not (has_neg and has_pos)

func _sign_2d(p1: Vector2, p2: Vector2, p3: Vector2) -> float:
	return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)

# ==================================================================
# RESPONSIVE LAYOUT
# ==================================================================

func _get_icon_size() -> int:
	var count = _synergy_icons.size()
	if count <= GameConstants.SYNERGY_ICON_LARGE_MAX:
		return GameConstants.SYNERGY_ICON_SIZE_LARGE
	elif count <= GameConstants.SYNERGY_ICON_MEDIUM_MAX:
		return GameConstants.SYNERGY_ICON_SIZE_MEDIUM
	else:
		return GameConstants.SYNERGY_ICON_SIZE_SMALL

func _show_names() -> bool:
	return _synergy_icons.size() <= GameConstants.SYNERGY_ICON_LARGE_MAX

func _rebuild_layout() -> void:
	var icon_size = _get_icon_size()
	var show_names = _show_names()
	_icon_container.add_theme_constant_override("h_separation", 4 if icon_size < 40 else 6)

	for syn_id in _synergy_icons:
		var data = _synergy_icons[syn_id]
		var panel: Panel = data["panel"]
		panel.custom_minimum_size = Vector2(icon_size, icon_size)

		# Regenerate icon texture at new size
		var info = SynergySystem.get_synergy_info(syn_id)
		var tex = _generate_synergy_icon(syn_id, info, icon_size)
		var tex_rect: TextureRect = data["tex_rect"]
		tex_rect.texture = tex
		tex_rect.custom_minimum_size = Vector2(icon_size, icon_size)

		# Update badge position
		var badge: Label = data["badge"]
		badge.position = Vector2(icon_size - 20, -4)

		# Show/hide name label
		var name_label: Label = data.get("name_label")
		if name_label:
			name_label.visible = show_names

# ==================================================================
# ICON MANAGEMENT
# ==================================================================

func _on_synergy_activated(synergy_id: String, synergy_data: Dictionary) -> void:
	if synergy_id in _synergy_icons:
		return
	_add_synergy_icon(synergy_id, synergy_data)

	# First activation banner
	if synergy_id not in _first_activations:
		_first_activations[synergy_id] = true
		_queue_banner(synergy_id, synergy_data)

func _add_synergy_icon(synergy_id: String, data: Dictionary) -> void:
	var icon_size = _get_icon_size()
	var color: Color = data.get("color", Color.WHITE)

	# Wrapper VBox: icon + optional name
	var wrapper = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 2)
	wrapper.alignment = BoxContainer.ALIGNMENT_END

	# Panel for the icon
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(icon_size, icon_size)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.7)
	style.border_color = color
	var bw = 3 if AccessibilityManager.high_contrast else 2
	style.set_border_width_all(bw)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	# Procedural icon texture
	var tex = _generate_synergy_icon(synergy_id, data, icon_size)
	var tex_rect = TextureRect.new()
	tex_rect.texture = tex
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tex_rect)

	# Proc count badge (top-right corner)
	var badge = Label.new()
	badge.text = ""
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	badge.add_theme_constant_override("outline_size", 2)
	badge.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	badge.position = Vector2(icon_size - 20, -4)
	badge.z_index = 5
	panel.add_child(badge)

	# Cooldown arc overlay (drawn via _draw)
	var cooldown_overlay = _CooldownArc.new()
	cooldown_overlay.synergy_id = synergy_id
	cooldown_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(cooldown_overlay)

	# Mouse hover for tooltip
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_entered.connect(_show_tooltip.bind(synergy_id, panel))
	panel.mouse_exited.connect(_hide_tooltip)

	# Focus for gamepad navigation
	panel.focus_mode = Control.FOCUS_ALL
	panel.focus_entered.connect(_show_tooltip.bind(synergy_id, panel))
	panel.focus_exited.connect(_hide_tooltip)

	wrapper.add_child(panel)

	# Name label (only visible for 1-3 synergies)
	var name_label = Label.new()
	var loc_key = "synergy_name_" + synergy_id
	var display_name = LocaleManager.tr_key(loc_key)
	if display_name == loc_key:
		display_name = data.get("name", synergy_id)
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", color.lightened(0.2))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.visible = _show_names()
	wrapper.add_child(name_label)

	_icon_container.add_child(wrapper)

	_synergy_icons[synergy_id] = {
		"panel": panel,
		"wrapper": wrapper,
		"badge": badge,
		"tex_rect": tex_rect,
		"name_label": name_label,
		"cooldown_overlay": cooldown_overlay,
	}

	# Entry animation
	if not AccessibilityManager.reduced_motion:
		panel.pivot_offset = Vector2(icon_size / 2.0, icon_size / 2.0)
		panel.scale = Vector2(0.3, 0.3)
		var tween = create_tween()
		tween.tween_property(panel, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_IN_OUT)

	# Rebuild layout with new count
	_rebuild_layout()

func _on_synergy_procced(synergy_id: String, _damage: float) -> void:
	if synergy_id not in _synergy_icons:
		return

	# Update badge
	var count = SynergySystem.synergy_proc_counts.get(synergy_id, 0)
	var badge: Label = _synergy_icons[synergy_id]["badge"]
	if count > 0:
		badge.text = "x%d" % count

	# Flash icon
	if not AccessibilityManager.reduced_flash:
		_flash_icon(synergy_id)

func _flash_icon(synergy_id: String) -> void:
	if synergy_id not in _synergy_icons:
		return
	var panel: Panel = _synergy_icons[synergy_id]["panel"]
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(2.5, 2.5, 2.5, 1.0), GameConstants.SYNERGY_PROC_FLASH_DURATION * 0.4)
	tween.tween_property(panel, "modulate", Color.WHITE, GameConstants.SYNERGY_PROC_FLASH_DURATION * 0.6)

# ==================================================================
# TOOLTIP
# ==================================================================

func _show_tooltip(synergy_id: String, anchor: Panel) -> void:
	var info = SynergySystem.get_synergy_info(synergy_id)
	var color: Color = info.get("color", Color.WHITE)

	# Name
	var loc_key = "synergy_name_" + synergy_id
	var display_name = LocaleManager.tr_key(loc_key)
	if display_name == loc_key:
		display_name = info.get("name", synergy_id)
	_tooltip_name_label.text = display_name
	_tooltip_name_label.add_theme_color_override("font_color", color.lightened(0.3))

	# Type
	var type_key := "synergy_tooltip_type_base"
	match info.get("type", "base"):
		"water": type_key = "synergy_tooltip_type_water"
		"cross": type_key = "synergy_tooltip_type_cross"
	_tooltip_type_label.text = LocaleManager.tr_key(type_key)

	# Effect
	var loc_effect_key = "synergy_effect_" + synergy_id
	var loc_effect = LocaleManager.tr_key(loc_effect_key)
	if loc_effect == loc_effect_key:
		loc_effect = info.get("effect", "")
	_tooltip_effect_label.text = loc_effect
	_tooltip_effect_label.add_theme_color_override("font_color", color.lightened(0.3))

	# Trigger
	_tooltip_trigger_label.text = info.get("trigger", "")

	# Cooldown
	var cd: float = info.get("cooldown", 0.0)
	if cd > 0.0:
		_tooltip_cooldown_label.text = LocaleManager.tr_key("synergy_tooltip_cooldown") % cd
		_tooltip_cooldown_label.visible = true
	else:
		_tooltip_cooldown_label.visible = false

	# Stats (proc count + DPS)
	var proc_count = SynergySystem.synergy_proc_counts.get(synergy_id, 0)
	var dps = SynergySystem.get_synergy_dps(synergy_id)
	var stats_parts: Array[String] = []
	stats_parts.append(LocaleManager.tr_key("synergy_procs_label") % proc_count)
	if dps > 0.0:
		stats_parts.append(LocaleManager.tr_key("synergy_dps_label") % int(dps))
	_tooltip_stats_label.text = "  |  ".join(stats_parts)
	_tooltip_stats_label.visible = true

	# Update border color to match synergy
	var style: StyleBoxFlat = _tooltip_panel.get_theme_stylebox("panel").duplicate()
	style.border_color = color
	_tooltip_panel.add_theme_stylebox_override("panel", style)

	# Position above the icon, clamped to screen
	var anchor_rect = anchor.get_global_rect()
	_tooltip_panel.reset_size()
	await get_tree().process_frame
	var tp_size = _tooltip_panel.size
	var tp_x = anchor_rect.position.x
	var tp_y = anchor_rect.position.y - tp_size.y - 8
	if tp_x + tp_size.x > 1280:
		tp_x = 1280 - tp_size.x - 4
	if tp_x < 0:
		tp_x = 4
	if tp_y < 0:
		tp_y = anchor_rect.position.y + anchor_rect.size.y + 8
	_tooltip_panel.global_position = Vector2(tp_x, tp_y)

	# Fade in
	if not AccessibilityManager.reduced_motion:
		_tooltip_panel.modulate.a = 0.0
		_tooltip_panel.visible = true
		var tween = create_tween()
		tween.tween_property(_tooltip_panel, "modulate:a", 1.0, GameConstants.SYNERGY_TOOLTIP_FADE_IN)
	else:
		_tooltip_panel.modulate.a = 1.0
		_tooltip_panel.visible = true

func _hide_tooltip() -> void:
	if not AccessibilityManager.reduced_motion:
		var tween = create_tween()
		tween.tween_property(_tooltip_panel, "modulate:a", 0.0, GameConstants.SYNERGY_TOOLTIP_FADE_OUT)
		tween.tween_callback(func(): _tooltip_panel.visible = false)
	else:
		_tooltip_panel.visible = false

# ==================================================================
# BANNER — First activation dramatic notification
# ==================================================================

func _queue_banner(synergy_id: String, synergy_data: Dictionary) -> void:
	_banner_queue.append({"id": synergy_id, "data": synergy_data})
	if not _banner_active:
		_play_next_banner()

func _play_next_banner() -> void:
	if _banner_queue.is_empty():
		_banner_active = false
		return

	_banner_active = true
	var entry = _banner_queue.pop_front()
	var synergy_id: String = entry["id"]
	var synergy_data: Dictionary = entry["data"]
	var color: Color = synergy_data.get("color", Color(1.0, 0.9, 0.4))

	# Clear previous banner children
	for child in _banner_container.get_children():
		child.queue_free()

	# Background panel with gradient
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = color * 0.3
	bg_style.bg_color.a = 0.85
	bg_style.set_corner_radius_all(8)
	bg_style.set_border_width_all(2)
	bg_style.border_color = color.lightened(0.2)
	bg.add_theme_stylebox_override("panel", bg_style)
	_banner_container.add_child(bg)

	# Icon on the left
	var icon_size = 48
	var tex = _generate_synergy_icon(synergy_id, synergy_data, icon_size)
	var icon_rect = TextureRect.new()
	icon_rect.texture = tex
	icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
	icon_rect.position = Vector2(12, (GameConstants.SYNERGY_BANNER_HEIGHT - icon_size) / 2.0)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_banner_container.add_child(icon_rect)

	# Title text: "SINERGIA ATIVADA!"
	var title_label = Label.new()
	title_label.text = LocaleManager.tr_key("synergy_activated_title")
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", color.lightened(0.4))
	title_label.add_theme_constant_override("outline_size", 2)
	title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	title_label.position = Vector2(72, 8)
	_banner_container.add_child(title_label)

	# Synergy name (typewriter effect)
	var loc_key = "synergy_name_" + synergy_id
	var display_name = LocaleManager.tr_key(loc_key)
	if display_name == loc_key:
		display_name = synergy_data.get("name", synergy_id)

	var name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_constant_override("outline_size", 3)
	name_label.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.0))
	name_label.position = Vector2(72, 30)
	_banner_container.add_child(name_label)

	# Trigger subtitle
	var trigger_label = Label.new()
	trigger_label.text = synergy_data.get("trigger", "")
	trigger_label.add_theme_font_size_override("font_size", 11)
	trigger_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	trigger_label.position = Vector2(72, 56)
	trigger_label.modulate.a = 0.0
	_banner_container.add_child(trigger_label)

	# Play SFX (reuse evolve sound with higher pitch)
	AudioManager.play_sfx("evolve", 0.8, 1.2)

	_banner_container.visible = true

	if AccessibilityManager.reduced_motion:
		# No animation — show instantly
		name_label.text = display_name
		trigger_label.modulate.a = 1.0
		_banner_container.offset_left = 0
		_banner_container.modulate.a = 1.0

		# Icon bounce skipped
		var timer = get_tree().create_timer(GameConstants.SYNERGY_BANNER_DURATION)
		timer.timeout.connect(func():
			_banner_container.visible = false
			# Small delay before next banner
			get_tree().create_timer(0.3).timeout.connect(_play_next_banner)
		)
		return

	# ---- Animated sequence ----
	var tween = create_tween()
	_banner_container.offset_left = -GameConstants.SYNERGY_BANNER_WIDTH
	_banner_container.offset_right = 0
	_banner_container.modulate.a = 1.0

	# 0.0s: Slide in from left (EASE_OUT_BACK)
	tween.tween_property(_banner_container, "offset_left", 20.0, GameConstants.SYNERGY_BANNER_SLIDE_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(_banner_container, "offset_right", 20.0 + GameConstants.SYNERGY_BANNER_WIDTH, GameConstants.SYNERGY_BANNER_SLIDE_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# 0.1s: Icon scale bounce
	icon_rect.pivot_offset = Vector2(icon_size / 2.0, icon_size / 2.0)
	icon_rect.scale = Vector2(0.3, 0.3)
	tween.parallel().tween_property(icon_rect, "scale", Vector2(1.2, 1.2), 0.15).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(icon_rect, "scale", Vector2.ONE, 0.1)

	# 0.3s: Typewriter name text
	if not AccessibilityManager.reduced_motion:
		name_label.text = ""
		var char_delay = 0.02
		for i in range(display_name.length()):
			tween.tween_callback(func():
				name_label.text = display_name.substr(0, name_label.text.length() + 1)
			).set_delay(char_delay if i > 0 else 0.0)

	# 0.5s: Subtitle fade in
	tween.tween_property(trigger_label, "modulate:a", 1.0, 0.2)

	# Flash effect on screen (subtle)
	if not AccessibilityManager.reduced_flash:
		ScreenEffects.flash(color, 0.1, 0.15)

	# 2.0s: Fade out
	tween.tween_interval(GameConstants.SYNERGY_BANNER_DURATION - 1.0)
	tween.tween_property(_banner_container, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		_banner_container.visible = false
		_banner_container.modulate.a = 1.0
		# Delay before next in queue
		get_tree().create_timer(0.3).timeout.connect(_play_next_banner)
	)

# ==================================================================
# GAMEPAD NAVIGATION
# ==================================================================

func _input(event: InputEvent) -> void:
	if not visible or _synergy_icons.is_empty():
		return
	# Gamepad bumpers to cycle focus through synergy icons
	if event is InputEventJoypadButton:
		if event.pressed:
			var keys = _synergy_icons.keys()
			if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
				_focus_index = max(0, _focus_index - 1)
				_focus_synergy_at(_focus_index)
			elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
				_focus_index = min(keys.size() - 1, _focus_index + 1)
				_focus_synergy_at(_focus_index)

func _focus_synergy_at(idx: int) -> void:
	var keys = _synergy_icons.keys()
	if idx < 0 or idx >= keys.size():
		return
	var syn_id = keys[idx]
	var panel: Panel = _synergy_icons[syn_id]["panel"]
	panel.grab_focus()

# ==================================================================
# STALE SYNERGY REMOVAL
# ==================================================================

func remove_stale_synergies() -> void:
	var to_remove: Array[String] = []
	for syn_id in _synergy_icons:
		if syn_id not in SynergySystem.active_synergies:
			to_remove.append(syn_id)
	for syn_id in to_remove:
		var data = _synergy_icons[syn_id]
		var wrapper = data.get("wrapper")
		if is_instance_valid(wrapper):
			wrapper.queue_free()
		_synergy_icons.erase(syn_id)
	if not to_remove.is_empty():
		_rebuild_layout()

# ==================================================================
# RESET
# ==================================================================

func reset() -> void:
	_first_activations.clear()
	_banner_queue.clear()
	_banner_active = false
	for data in _synergy_icons.values():
		var wrapper = data.get("wrapper")
		if is_instance_valid(wrapper):
			wrapper.queue_free()
	_synergy_icons.clear()
	_hide_tooltip()
	_banner_container.visible = false
	_focus_index = -1

# ==================================================================
# COOLDOWN ARC OVERLAY (inner class)
# ==================================================================

class _CooldownArc extends Control:
	var synergy_id: String = ""

	func _process(_delta: float) -> void:
		var info = SynergySystem.get_synergy_info(synergy_id)
		var cd: float = info.get("cooldown", 0.0)
		if cd <= 0.0:
			if visible:
				visible = false
			return

		# Map synergy_id to timer key used in SynergySystem
		var timer_key = _get_timer_key(synergy_id)
		var elapsed = SynergySystem._synergy_timers.get(timer_key, 0.0)
		var ratio = clamp(elapsed / cd, 0.0, 1.0)
		if ratio <= 0.01:
			if visible:
				visible = false
			return
		visible = true
		queue_redraw()

	func _draw() -> void:
		var info = SynergySystem.get_synergy_info(synergy_id)
		var cd: float = info.get("cooldown", 0.0)
		if cd <= 0.0:
			return
		var timer_key = _get_timer_key(synergy_id)
		var elapsed = SynergySystem._synergy_timers.get(timer_key, 0.0)
		var ratio = clamp(elapsed / cd, 0.0, 1.0)
		if ratio <= 0.01:
			return

		var center = size / 2.0
		var radius = min(size.x, size.y) / 2.0 - 3.0
		# Draw arc from top, clockwise, representing cooldown progress
		var start_angle = -PI / 2.0
		var end_angle = start_angle + TAU * (1.0 - ratio)
		# Draw semi-transparent overlay on the "cooling down" portion
		var arc_color = GameConstants.SYNERGY_COOLDOWN_ARC_COLOR
		var point_count = 32
		var points: PackedVector2Array = PackedVector2Array()
		points.append(center)
		for i in range(point_count + 1):
			var angle = start_angle + (end_angle - start_angle) * i / point_count
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		if points.size() >= 3:
			draw_colored_polygon(points, arc_color)

	func _get_timer_key(syn_id: String) -> String:
		# Map synergy IDs to their timer keys in SynergySystem
		match syn_id:
			"dark_dark": return "dark_aura"
			"fire_ice": return "steam_cloud"
			"electric_ice": return "conductor"
			"water_water": return "tidal_wave"
			"water_fire": return "steam_explosion"
			"water_ice": return "absolute_zero"
			"water_dark": return "abyssal_depths"
			"fire_poison": return "toxic_fire"
			"ice_dark": return "shadow_freeze"
			"electric_poison": return "toxic_shock"
		return syn_id
