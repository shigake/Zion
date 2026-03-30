extends Control

## Character-themed HP bar with unique visuals per character.
## Replaces the generic ProgressBar with custom _draw() rendering.

# Public state (set by HUD)
var max_hp: float = 100.0
var current_hp: float = 100.0
var character_id: String = "ronin"

# Ghost HP (delayed damage indicator)
var _ghost_hp: float = -1.0
var _ghost_hp_delay: float = 0.0

# Punch animation
var _punch_timer: float = 0.0
var _punch_offset: Vector2 = Vector2.ZERO

# Flash on damage
var _flash_amount: float = 0.0

# Animation time (for decorative effects)
var _anim_time: float = 0.0

# Previous HP for damage detection
var _prev_hp: float = -1.0

# Character theme data
var _theme: Dictionary = {}

# Theme definitions per character
const THEMES = {
	"ronin": {
		"name": "Lâmina",
		"fill_color": Color(0.15, 0.75, 0.3),
		"fill_color2": Color(0.05, 0.45, 0.15),
		"border_color": Color(0.4, 0.85, 0.45, 0.9),
		"bg_color": Color(0.02, 0.12, 0.04),
		"icon": "blade",  # katana blade
		"shape": "blade",  # pointed right end
		"accent": Color(0.6, 1.0, 0.6, 0.4),
		"particle": "leaves",
	},
	"soldado": {
		"name": "Munição",
		"fill_color": Color(0.35, 0.55, 0.25),
		"fill_color2": Color(0.2, 0.35, 0.15),
		"border_color": Color(0.5, 0.6, 0.3, 0.9),
		"bg_color": Color(0.08, 0.08, 0.05),
		"icon": "bullet",
		"shape": "segmented",  # segmented military bar
		"accent": Color(0.7, 0.75, 0.4, 0.3),
		"particle": "none",
	},
	"mago": {
		"name": "Mana",
		"fill_color": Color(0.55, 0.2, 0.9),
		"fill_color2": Color(0.3, 0.1, 0.6),
		"border_color": Color(0.7, 0.4, 1.0, 0.9),
		"bg_color": Color(0.06, 0.02, 0.12),
		"icon": "crystal",
		"shape": "crystal",  # faceted gem shape
		"accent": Color(0.8, 0.6, 1.0, 0.5),
		"particle": "sparkle",
	},
	"berserker": {
		"name": "Fúria",
		"fill_color": Color(0.9, 0.2, 0.05),
		"fill_color2": Color(0.6, 0.1, 0.0),
		"border_color": Color(1.0, 0.4, 0.1, 0.9),
		"bg_color": Color(0.12, 0.03, 0.02),
		"icon": "flame",
		"shape": "jagged",  # jagged cracked edges
		"accent": Color(1.0, 0.6, 0.1, 0.5),
		"particle": "fire",
	},
	"ninja": {
		"name": "Sombra",
		"fill_color": Color(0.3, 0.15, 0.5),
		"fill_color2": Color(0.1, 0.05, 0.2),
		"border_color": Color(0.4, 0.2, 0.6, 0.7),
		"bg_color": Color(0.03, 0.02, 0.06),
		"icon": "claw",
		"shape": "sleek",  # ultra-thin sharp ends
		"accent": Color(0.5, 0.3, 0.8, 0.3),
		"particle": "smoke",
	},
	"necro": {
		"name": "Almas",
		"fill_color": Color(0.1, 0.7, 0.2),
		"fill_color2": Color(0.05, 0.35, 0.1),
		"border_color": Color(0.2, 0.8, 0.3, 0.8),
		"bg_color": Color(0.02, 0.08, 0.03),
		"icon": "skull",
		"shape": "drip",  # dripping bottom edge
		"accent": Color(0.3, 1.0, 0.4, 0.4),
		"particle": "drip",
	},
	"pirata": {
		"name": "Rum",
		"fill_color": Color(0.8, 0.55, 0.15),
		"fill_color2": Color(0.5, 0.3, 0.08),
		"border_color": Color(0.9, 0.7, 0.2, 0.9),
		"bg_color": Color(0.1, 0.06, 0.02),
		"icon": "bottle",
		"shape": "bottle",  # bottle silhouette
		"accent": Color(1.0, 0.85, 0.3, 0.4),
		"particle": "coins",
	},
	"engenheiro": {
		"name": "Bateria",
		"fill_color": Color(0.85, 0.75, 0.1),
		"fill_color2": Color(0.5, 0.45, 0.05),
		"border_color": Color(0.9, 0.8, 0.2, 0.9),
		"bg_color": Color(0.08, 0.07, 0.02),
		"icon": "battery",
		"shape": "battery",  # battery with terminal
		"accent": Color(1.0, 0.95, 0.4, 0.4),
		"particle": "circuit",
	},
	"vampiro": {
		"name": "Sangue",
		"fill_color": Color(0.7, 0.0, 0.1),
		"fill_color2": Color(0.35, 0.0, 0.05),
		"border_color": Color(0.8, 0.1, 0.15, 0.9),
		"bg_color": Color(0.1, 0.01, 0.02),
		"icon": "goblet",
		"shape": "goblet",  # chalice/goblet shape
		"accent": Color(1.0, 0.2, 0.3, 0.5),
		"particle": "blood",
	},
	"gladiador": {
		"name": "Honra",
		"fill_color": Color(0.85, 0.65, 0.15),
		"fill_color2": Color(0.55, 0.4, 0.1),
		"border_color": Color(1.0, 0.8, 0.2, 0.9),
		"bg_color": Color(0.1, 0.07, 0.02),
		"icon": "shield",
		"shape": "shield",  # shield-framed
		"accent": Color(1.0, 0.9, 0.5, 0.4),
		"particle": "sparks",
	},
	"chef": {
		"name": "Calor",
		"fill_color": Color(0.95, 0.5, 0.1),
		"fill_color2": Color(0.6, 0.25, 0.05),
		"border_color": Color(1.0, 0.65, 0.2, 0.9),
		"bg_color": Color(0.1, 0.05, 0.02),
		"icon": "thermometer",
		"shape": "thermometer",
		"accent": Color(1.0, 0.7, 0.3, 0.4),
		"particle": "steam",
	},
	"mystery": {
		"name": "???",
		"fill_color": Color(0.5, 0.5, 0.5),
		"fill_color2": Color(0.25, 0.25, 0.25),
		"border_color": Color(0.7, 0.7, 0.7, 0.7),
		"bg_color": Color(0.06, 0.06, 0.06),
		"icon": "glitch",
		"shape": "glitch",
		"accent": Color(0.8, 0.8, 0.8, 0.3),
		"particle": "static",
	},
}

func _ready() -> void:
	custom_minimum_size = Vector2(280, 36)
	_load_theme()

func _load_theme() -> void:
	_theme = THEMES.get(character_id, THEMES["ronin"])

func set_character(id: String) -> void:
	character_id = id
	_load_theme()
	queue_redraw()

func set_hp(hp: float, max_val: float) -> void:
	var old_hp = current_hp
	current_hp = hp
	max_hp = max_val

	if _prev_hp < 0:
		_prev_hp = hp
		_ghost_hp = -1.0

	# Detect damage
	if hp < _prev_hp:
		if _ghost_hp < 0 or _ghost_hp < _prev_hp:
			_ghost_hp = _prev_hp
		_ghost_hp_delay = 0.4
		_flash_amount = 1.0
		trigger_punch()

	_prev_hp = hp
	queue_redraw()

func trigger_punch() -> void:
	_punch_timer = 0.2

func _process(delta: float) -> void:
	_anim_time += delta

	# Ghost HP drain
	if _ghost_hp > 0:
		if _ghost_hp_delay > 0:
			_ghost_hp_delay -= delta
		else:
			_ghost_hp = lerpf(_ghost_hp, current_hp, delta * 4.0)
			if absf(_ghost_hp - current_hp) < 1.0:
				_ghost_hp = -1.0

	# Flash decay
	if _flash_amount > 0:
		_flash_amount = maxf(0.0, _flash_amount - delta * 5.0)

	# Punch animation
	if _punch_timer > 0:
		_punch_timer -= delta
		var intensity = _punch_timer / 0.2
		_punch_offset = Vector2(
			randf_range(-3.0, 3.0) * intensity,
			randf_range(-2.0, 2.0) * intensity
		)
	else:
		_punch_offset = Vector2.ZERO

	queue_redraw()

func _draw() -> void:
	if _theme.is_empty():
		return

	var bar_rect = Rect2(Vector2(38, 2) + _punch_offset, Vector2(size.x - 42, size.y - 4))
	var fill_pct = clampf(current_hp / maxf(max_hp, 1.0), 0.0, 1.0)
	var ghost_pct = 0.0
	if _ghost_hp > 0:
		ghost_pct = clampf(_ghost_hp / maxf(max_hp, 1.0), 0.0, 1.0)

	# Draw the themed bar
	var shape = _theme.get("shape", "blade")
	match shape:
		"blade":
			_draw_blade_bar(bar_rect, fill_pct, ghost_pct)
		"segmented":
			_draw_segmented_bar(bar_rect, fill_pct, ghost_pct)
		"crystal":
			_draw_crystal_bar(bar_rect, fill_pct, ghost_pct)
		"jagged":
			_draw_jagged_bar(bar_rect, fill_pct, ghost_pct)
		"sleek":
			_draw_sleek_bar(bar_rect, fill_pct, ghost_pct)
		"drip":
			_draw_drip_bar(bar_rect, fill_pct, ghost_pct)
		"bottle":
			_draw_bottle_bar(bar_rect, fill_pct, ghost_pct)
		"battery":
			_draw_battery_bar(bar_rect, fill_pct, ghost_pct)
		"goblet":
			_draw_goblet_bar(bar_rect, fill_pct, ghost_pct)
		"shield":
			_draw_shield_bar(bar_rect, fill_pct, ghost_pct)
		"thermometer":
			_draw_thermometer_bar(bar_rect, fill_pct, ghost_pct)
		"glitch":
			_draw_glitch_bar(bar_rect, fill_pct, ghost_pct)
		_:
			_draw_blade_bar(bar_rect, fill_pct, ghost_pct)

	# Draw icon on the left
	_draw_icon(Vector2(4 + _punch_offset.x, 2 + _punch_offset.y))

	# Draw HP text
	_draw_hp_text(bar_rect)

	# Draw decorative particles
	_draw_particles(bar_rect, fill_pct)

# ==================== BAR SHAPES ====================

func _draw_blade_bar(rect: Rect2, fill: float, ghost: float) -> void:
	# Katana blade shape — pointed right end
	var bg_points = _make_blade_points(rect, 1.0)
	draw_colored_polygon(bg_points, _theme.bg_color)

	if ghost > fill:
		var ghost_points = _make_blade_points(rect, ghost)
		draw_colored_polygon(ghost_points, Color(1.0, 1.0, 1.0, 0.15))

	if fill > 0:
		var fill_points = _make_blade_points(rect, fill)
		var fill_color = _get_fill_color(fill)
		draw_colored_polygon(fill_points, fill_color)

	# Border
	draw_polyline(bg_points + PackedVector2Array([bg_points[0]]), _theme.border_color, 1.5, true)

	# Gleam line along top
	var gleam_y = rect.position.y + 3
	var gleam_end = rect.position.x + rect.size.x * fill * 0.9
	if fill > 0.05:
		draw_line(
			Vector2(rect.position.x + 4, gleam_y),
			Vector2(gleam_end, gleam_y),
			Color(_theme.accent.r, _theme.accent.g, _theme.accent.b, 0.3 + sin(_anim_time * 2.0) * 0.1),
			1.0, true
		)

func _make_blade_points(rect: Rect2, pct: float) -> PackedVector2Array:
	var w = rect.size.x * pct
	var h = rect.size.y
	var x = rect.position.x
	var y = rect.position.y
	var tip = mini(int(w), 8)
	return PackedVector2Array([
		Vector2(x, y + 4),
		Vector2(x + 4, y),
		Vector2(x + w - tip, y),
		Vector2(x + w, y + h * 0.5),
		Vector2(x + w - tip, y + h),
		Vector2(x + 4, y + h),
		Vector2(x, y + h - 4),
	])

func _draw_segmented_bar(rect: Rect2, fill: float, ghost: float) -> void:
	# Military segmented bar with notch marks
	var r = 3.0
	draw_rect(Rect2(rect.position - Vector2(1,1), rect.size + Vector2(2,2)), _theme.border_color, false, 1.5)
	draw_rect(rect, _theme.bg_color, true)

	if ghost > fill:
		var ghost_rect = Rect2(rect.position, Vector2(rect.size.x * ghost, rect.size.y))
		draw_rect(ghost_rect, Color(1.0, 1.0, 1.0, 0.12), true)

	if fill > 0:
		var fill_rect = Rect2(rect.position, Vector2(rect.size.x * fill, rect.size.y))
		draw_rect(fill_rect, _get_fill_color(fill), true)

	# Draw segment lines (every 10%)
	for i in range(1, 10):
		var seg_x = rect.position.x + rect.size.x * (i / 10.0)
		var seg_color = Color(_theme.border_color.r, _theme.border_color.g, _theme.border_color.b, 0.4)
		draw_line(Vector2(seg_x, rect.position.y), Vector2(seg_x, rect.end.y), seg_color, 1.0)

	# Ammo-style notches on top
	for i in range(0, 5):
		var notch_x = rect.position.x + rect.size.x * ((i * 2 + 1) / 10.0)
		draw_line(
			Vector2(notch_x, rect.position.y - 2),
			Vector2(notch_x, rect.position.y + 3),
			_theme.border_color, 1.5
		)

func _draw_crystal_bar(rect: Rect2, fill: float, ghost: float) -> void:
	# Faceted crystal/gem shape
	var bg_pts = _make_crystal_points(rect, 1.0)
	draw_colored_polygon(bg_pts, _theme.bg_color)

	if ghost > fill:
		draw_colored_polygon(_make_crystal_points(rect, ghost), Color(1.0, 1.0, 1.0, 0.15))

	if fill > 0:
		draw_colored_polygon(_make_crystal_points(rect, fill), _get_fill_color(fill))

	draw_polyline(bg_pts + PackedVector2Array([bg_pts[0]]), _theme.border_color, 1.5, true)

	# Sparkle facet lines
	if fill > 0.1:
		var fx = rect.position.x + rect.size.x * fill * 0.5
		var fy = rect.position.y + rect.size.y * 0.3
		var sparkle_alpha = 0.2 + sin(_anim_time * 3.0) * 0.15
		draw_line(
			Vector2(fx - 8, fy), Vector2(fx + 8, fy),
			Color(1.0, 1.0, 1.0, sparkle_alpha), 1.0, true
		)
		draw_line(
			Vector2(fx, fy - 5), Vector2(fx, fy + 5),
			Color(1.0, 1.0, 1.0, sparkle_alpha), 1.0, true
		)

func _make_crystal_points(rect: Rect2, pct: float) -> PackedVector2Array:
	var w = rect.size.x * pct
	var h = rect.size.y
	var x = rect.position.x
	var y = rect.position.y
	return PackedVector2Array([
		Vector2(x, y + h * 0.5),
		Vector2(x + 8, y),
		Vector2(x + w * 0.4, y),
		Vector2(x + w * 0.5, y - 2),
		Vector2(x + w * 0.6, y),
		Vector2(x + w, y + 2),
		Vector2(x + w, y + h - 2),
		Vector2(x + w * 0.6, y + h),
		Vector2(x + w * 0.5, y + h + 2),
		Vector2(x + w * 0.4, y + h),
		Vector2(x + 8, y + h),
	])

func _draw_jagged_bar(rect: Rect2, fill: float, ghost: float) -> void:
	# Jagged cracked edges — berserker rage
	var bg_pts = _make_jagged_points(rect, 1.0)
	draw_colored_polygon(bg_pts, _theme.bg_color)

	if ghost > fill:
		draw_colored_polygon(_make_jagged_points(rect, ghost), Color(1.0, 1.0, 1.0, 0.15))

	if fill > 0:
		draw_colored_polygon(_make_jagged_points(rect, fill), _get_fill_color(fill))

	draw_polyline(bg_pts + PackedVector2Array([bg_pts[0]]), _theme.border_color, 1.5, true)

	# Rage glow when low HP
	if fill < 0.3 and fill > 0:
		var pulse = 0.3 + sin(_anim_time * 6.0) * 0.2
		var glow_rect = Rect2(rect.position - Vector2(2,2), Vector2(rect.size.x * fill + 4, rect.size.y + 4))
		draw_rect(glow_rect, Color(1.0, 0.3, 0.0, pulse), false, 2.0)

func _make_jagged_points(rect: Rect2, pct: float) -> PackedVector2Array:
	var w = rect.size.x * pct
	var h = rect.size.y
	var x = rect.position.x
	var y = rect.position.y
	var pts = PackedVector2Array()
	# Top edge with jagged teeth
	pts.append(Vector2(x, y + 3))
	var steps = maxi(int(w / 12), 1)
	var step_w = w / steps
	for i in range(steps):
		var sx = x + i * step_w
		pts.append(Vector2(sx + step_w * 0.3, y - randf_range(0, 3)))
		pts.append(Vector2(sx + step_w * 0.7, y + randf_range(0, 2)))
	pts.append(Vector2(x + w, y + 3))
	pts.append(Vector2(x + w, y + h - 3))
	# Bottom edge jagged
	for i in range(steps - 1, -1, -1):
		var sx = x + i * step_w
		pts.append(Vector2(sx + step_w * 0.7, y + h + randf_range(0, 2)))
		pts.append(Vector2(sx + step_w * 0.3, y + h - randf_range(0, 3)))
	pts.append(Vector2(x, y + h - 3))
	return pts

func _draw_sleek_bar(rect: Rect2, fill: float, ghost: float) -> void:
	# Ultra-thin sleek bar with sharp ends — ninja style
	var slim_rect = Rect2(rect.position + Vector2(0, 6), Vector2(rect.size.x, rect.size.y - 12))
	var bg_pts = _make_sleek_points(slim_rect, 1.0)
	draw_colored_polygon(bg_pts, _theme.bg_color)

	if ghost > fill:
		draw_colored_polygon(_make_sleek_points(slim_rect, ghost), Color(1.0, 1.0, 1.0, 0.1))

	if fill > 0:
		draw_colored_polygon(_make_sleek_points(slim_rect, fill), _get_fill_color(fill))

	draw_polyline(bg_pts + PackedVector2Array([bg_pts[0]]), _theme.border_color, 1.0, true)

	# Shadow trail effect
	if fill > 0.05:
		var trail_x = rect.position.x + rect.size.x * fill
		var mid_y = rect.position.y + rect.size.y * 0.5
		var alpha = 0.15 + sin(_anim_time * 4.0) * 0.1
		for i in range(3):
			var offset = (i + 1) * 8
			draw_circle(Vector2(trail_x - offset, mid_y), 2.0 - i * 0.5, Color(0.3, 0.1, 0.5, alpha * (1.0 - i * 0.3)))

func _make_sleek_points(rect: Rect2, pct: float) -> PackedVector2Array:
	var w = rect.size.x * pct
	var h = rect.size.y
	var x = rect.position.x
	var y = rect.position.y
	return PackedVector2Array([
		Vector2(x, y + h * 0.5),
		Vector2(x + 6, y),
		Vector2(x + w, y),
		Vector2(x + w + 4, y + h * 0.5),
		Vector2(x + w, y + h),
		Vector2(x + 6, y + h),
	])

func _draw_drip_bar(rect: Rect2, fill: float, ghost: float) -> void:
	# Necromancer — bar with dripping bottom edge
	draw_rect(Rect2(rect.position - Vector2(1,1), rect.size + Vector2(2,2)), _theme.border_color, false, 1.5)
	draw_rect(rect, _theme.bg_color, true)

	if ghost > fill:
		var gr = Rect2(rect.position, Vector2(rect.size.x * ghost, rect.size.y))
		draw_rect(gr, Color(1.0, 1.0, 1.0, 0.12), true)

	if fill > 0:
		var fr = Rect2(rect.position, Vector2(rect.size.x * fill, rect.size.y))
		draw_rect(fr, _get_fill_color(fill), true)

	# Drip drops below the fill
	if fill > 0.05:
		var drip_count = 3
		for i in range(drip_count):
			var dx = rect.position.x + rect.size.x * fill * ((i + 1.0) / (drip_count + 1.0))
			var drip_phase = fmod(_anim_time * 0.8 + i * 1.3, 2.0)
			var dy = rect.end.y + drip_phase * 8.0
			var drip_alpha = 1.0 - drip_phase / 2.0
			var drip_size = 2.5 - drip_phase * 0.8
			if drip_size > 0:
				draw_circle(Vector2(dx, dy), drip_size, Color(_theme.fill_color.r, _theme.fill_color.g, _theme.fill_color.b, drip_alpha * 0.6))

func _draw_bottle_bar(rect: Rect2, fill: float, ghost: float) -> void:
	# Pirate rum bottle silhouette
	var bg_pts = _make_bottle_points(rect, 1.0)
	draw_colored_polygon(bg_pts, _theme.bg_color)

	if ghost > fill:
		draw_colored_polygon(_make_bottle_points(rect, ghost), Color(1.0, 1.0, 1.0, 0.12))

	if fill > 0:
		draw_colored_polygon(_make_bottle_points(rect, fill), _get_fill_color(fill))

	draw_polyline(bg_pts + PackedVector2Array([bg_pts[0]]), _theme.border_color, 1.5, true)

	# Liquid slosh animation
	if fill > 0.05:
		var wave_y = rect.position.y + rect.size.y * 0.3
		var wave_x = rect.position.x + rect.size.x * fill
		for i in range(3):
			var wx = wave_x - 10 - i * 15
			if wx > rect.position.x:
				var wy = wave_y + sin(_anim_time * 2.0 + i) * 2.0
				draw_circle(Vector2(wx, wy), 1.5, Color(1.0, 0.9, 0.5, 0.2))

func _make_bottle_points(rect: Rect2, pct: float) -> PackedVector2Array:
	var w = rect.size.x * pct
	var h = rect.size.y
	var x = rect.position.x
	var y = rect.position.y
	# Bottle: narrow neck on left, wide body
	return PackedVector2Array([
		Vector2(x, y + h * 0.3),
		Vector2(x + 6, y + h * 0.15),
		Vector2(x + 14, y),
		Vector2(x + w, y),
		Vector2(x + w, y + h),
		Vector2(x + 14, y + h),
		Vector2(x + 6, y + h * 0.85),
		Vector2(x, y + h * 0.7),
	])

func _draw_battery_bar(rect: Rect2, fill: float, ghost: float) -> void:
	# Engineer battery with terminal nub on right
	var body = Rect2(rect.position, Vector2(rect.size.x - 6, rect.size.y))
	draw_rect(body, _theme.bg_color, true)
	draw_rect(Rect2(body.position - Vector2(1,1), body.size + Vector2(2,2)), _theme.border_color, false, 1.5)

	# Terminal nub
	var nub = Rect2(Vector2(body.end.x, rect.position.y + rect.size.y * 0.25), Vector2(6, rect.size.y * 0.5))
	draw_rect(nub, _theme.border_color, true)

	if ghost > fill:
		var gr = Rect2(body.position, Vector2(body.size.x * ghost, body.size.y))
		draw_rect(gr, Color(1.0, 1.0, 1.0, 0.12), true)

	if fill > 0:
		var fr = Rect2(body.position, Vector2(body.size.x * fill, body.size.y))
		draw_rect(fr, _get_fill_color(fill), true)

	# Battery segment lines (every 25%)
	for i in range(1, 4):
		var seg_x = body.position.x + body.size.x * (i / 4.0)
		draw_line(Vector2(seg_x, body.position.y), Vector2(seg_x, body.end.y), Color(_theme.border_color.r, _theme.border_color.g, _theme.border_color.b, 0.5), 1.5)

	# Circuit traces decoration
	if fill > 0.1:
		var cy = body.position.y + body.size.y * 0.5
		var trace_alpha = 0.15 + sin(_anim_time * 3.0) * 0.1
		for i in range(0, int(body.size.x * fill), 20):
			var tx = body.position.x + i
			draw_line(Vector2(tx, cy - 3), Vector2(tx + 8, cy - 3), Color(1.0, 1.0, 0.5, trace_alpha), 0.5)
			draw_line(Vector2(tx + 8, cy - 3), Vector2(tx + 8, cy + 3), Color(1.0, 1.0, 0.5, trace_alpha), 0.5)

func _draw_goblet_bar(rect: Rect2, fill: float, ghost: float) -> void:
	# Vampire blood goblet/chalice shape
	var bg_pts = _make_goblet_points(rect, 1.0)
	draw_colored_polygon(bg_pts, _theme.bg_color)

	if ghost > fill:
		draw_colored_polygon(_make_goblet_points(rect, ghost), Color(1.0, 0.8, 0.8, 0.15))

	if fill > 0:
		draw_colored_polygon(_make_goblet_points(rect, fill), _get_fill_color(fill))

	draw_polyline(bg_pts + PackedVector2Array([bg_pts[0]]), _theme.border_color, 1.5, true)

	# Blood surface animation (meniscus)
	if fill > 0.05:
		var surface_x = rect.position.x + rect.size.x * fill
		var mid_y = rect.position.y + rect.size.y * 0.5
		var wave = sin(_anim_time * 1.5) * 2.0
		draw_line(
			Vector2(surface_x - 1, mid_y - 4 + wave),
			Vector2(surface_x - 1, mid_y + 4 + wave),
			Color(0.9, 0.1, 0.15, 0.4), 2.0
		)

	# Blood drip from rim
	var drip_phase = fmod(_anim_time * 0.5, 3.0)
	if drip_phase < 1.5:
		var drip_x = rect.position.x + rect.size.x * 0.7
		var drip_y = rect.position.y - 1 + drip_phase * 6.0
		draw_circle(Vector2(drip_x, drip_y), 1.5, Color(0.7, 0.0, 0.1, 0.5 * (1.0 - drip_phase / 1.5)))

func _make_goblet_points(rect: Rect2, pct: float) -> PackedVector2Array:
	var w = rect.size.x * pct
	var h = rect.size.y
	var x = rect.position.x
	var y = rect.position.y
	return PackedVector2Array([
		Vector2(x + 3, y),
		Vector2(x + w, y),
		Vector2(x + w + 2, y + 3),
		Vector2(x + w - 2, y + h * 0.4),
		Vector2(x + w, y + h * 0.6),
		Vector2(x + w + 2, y + h - 3),
		Vector2(x + w, y + h),
		Vector2(x + 3, y + h),
		Vector2(x, y + h - 3),
		Vector2(x + 3, y + h * 0.6),
		Vector2(x + 1, y + h * 0.4),
		Vector2(x + 3, y + 3),
	])

func _draw_shield_bar(rect: Rect2, fill: float, ghost: float) -> void:
	# Gladiator shield-framed bar
	var bg_pts = _make_shield_points(rect, 1.0)
	draw_colored_polygon(bg_pts, _theme.bg_color)

	if ghost > fill:
		draw_colored_polygon(_make_shield_points(rect, ghost), Color(1.0, 1.0, 0.8, 0.15))

	if fill > 0:
		draw_colored_polygon(_make_shield_points(rect, fill), _get_fill_color(fill))

	draw_polyline(bg_pts + PackedVector2Array([bg_pts[0]]), _theme.border_color, 2.0, true)

	# Golden laurel accent lines on sides
	var accent_alpha = 0.25 + sin(_anim_time * 1.5) * 0.1
	draw_line(
		Vector2(rect.position.x + 2, rect.position.y + 4),
		Vector2(rect.position.x + 2, rect.end.y - 4),
		Color(1.0, 0.85, 0.3, accent_alpha), 2.0
	)

func _make_shield_points(rect: Rect2, pct: float) -> PackedVector2Array:
	var w = rect.size.x * pct
	var h = rect.size.y
	var x = rect.position.x
	var y = rect.position.y
	return PackedVector2Array([
		Vector2(x, y + 4),
		Vector2(x + 4, y),
		Vector2(x + w - 4, y),
		Vector2(x + w, y + 4),
		Vector2(x + w, y + h - 4),
		Vector2(x + w - 4, y + h),
		Vector2(x + w * 0.5, y + h + 3),  # shield point at bottom center
		Vector2(x + 4, y + h),
		Vector2(x, y + h - 4),
	])

func _draw_thermometer_bar(rect: Rect2, fill: float, ghost: float) -> void:
	# Chef thermometer — bulb on left, tube extending right
	# Bulb
	var bulb_center = Vector2(rect.position.x + 4, rect.position.y + rect.size.y * 0.5)
	var bulb_r = rect.size.y * 0.45
	draw_circle(bulb_center, bulb_r + 1, _theme.border_color)
	draw_circle(bulb_center, bulb_r, _get_fill_color(fill) if fill > 0 else _theme.bg_color)

	# Tube
	var tube_rect = Rect2(
		Vector2(rect.position.x + 12, rect.position.y + 4),
		Vector2(rect.size.x - 16, rect.size.y - 8)
	)
	draw_rect(tube_rect, _theme.bg_color, true)
	draw_rect(Rect2(tube_rect.position - Vector2(1,1), tube_rect.size + Vector2(2,2)), _theme.border_color, false, 1.0)

	if ghost > fill:
		var gr = Rect2(tube_rect.position, Vector2(tube_rect.size.x * ghost, tube_rect.size.y))
		draw_rect(gr, Color(1.0, 1.0, 1.0, 0.12), true)

	if fill > 0:
		var fr = Rect2(tube_rect.position, Vector2(tube_rect.size.x * fill, tube_rect.size.y))
		draw_rect(fr, _get_fill_color(fill), true)

	# Temperature marks
	for i in range(1, 5):
		var mx = tube_rect.position.x + tube_rect.size.x * (i / 5.0)
		draw_line(
			Vector2(mx, tube_rect.position.y - 2),
			Vector2(mx, tube_rect.position.y + 3),
			Color(_theme.border_color.r, _theme.border_color.g, _theme.border_color.b, 0.5), 1.0
		)

	# Steam wisps above when HP is high
	if fill > 0.7:
		for i in range(2):
			var sx = tube_rect.position.x + tube_rect.size.x * fill * (0.5 + i * 0.3)
			var sy = tube_rect.position.y - 3
			var steam_phase = fmod(_anim_time + i * 0.7, 1.5)
			var steam_alpha = 0.3 * (1.0 - steam_phase / 1.5)
			draw_circle(Vector2(sx + sin(steam_phase * 3.0) * 3.0, sy - steam_phase * 8.0), 2.0, Color(1.0, 1.0, 1.0, steam_alpha))

func _draw_glitch_bar(rect: Rect2, fill: float, ghost: float) -> void:
	# Mystery character — glitchy shifting bar
	draw_rect(rect, _theme.bg_color, true)

	if ghost > fill:
		var gr = Rect2(rect.position, Vector2(rect.size.x * ghost, rect.size.y))
		draw_rect(gr, Color(1.0, 1.0, 1.0, 0.1), true)

	if fill > 0:
		# Glitch: draw fill in offset slices
		var slice_h = rect.size.y / 4.0
		for i in range(4):
			var glitch_offset = sin(_anim_time * 8.0 + i * 2.0) * 3.0
			var slice_rect = Rect2(
				Vector2(rect.position.x + glitch_offset, rect.position.y + i * slice_h),
				Vector2(rect.size.x * fill, slice_h)
			)
			# Rainbow color cycling per slice
			var hue = fmod(_anim_time * 0.3 + i * 0.25, 1.0)
			var glitch_color = Color.from_hsv(hue, 0.7, 0.9)
			glitch_color = glitch_color.lerp(_get_fill_color(fill), 0.5)
			draw_rect(slice_rect, glitch_color, true)

	# Glitch border with occasional offset
	var border_offset = Vector2.ZERO
	if fmod(_anim_time, 0.5) < 0.05:
		border_offset = Vector2(randf_range(-2, 2), randf_range(-1, 1))
	draw_rect(Rect2(rect.position + border_offset - Vector2(1,1), rect.size + Vector2(2,2)), _theme.border_color, false, 1.5)

	# Scanlines
	for i in range(0, int(rect.size.y), 3):
		var line_y = rect.position.y + i
		draw_line(Vector2(rect.position.x, line_y), Vector2(rect.end.x, line_y), Color(0, 0, 0, 0.15), 1.0)

# ==================== ICON DRAWING ====================

func _draw_icon(pos: Vector2) -> void:
	var cx = pos.x + 16
	var cy = pos.y + size.y * 0.5 - 2
	var icon = _theme.get("icon", "")
	var c = _theme.border_color

	match icon:
		"blade":
			# Small katana
			draw_line(Vector2(cx - 8, cy + 8), Vector2(cx + 8, cy - 8), c, 2.5)
			draw_line(Vector2(cx - 2, cy + 2), Vector2(cx + 2, cy - 2), Color(c.r, c.g, c.b, 0.5), 5.0)  # guard
		"bullet":
			# Bullet shape
			draw_rect(Rect2(cx - 3, cy - 6, 6, 10), c, true)
			draw_circle(Vector2(cx, cy - 6), 3, c)
		"crystal":
			# Diamond shape
			var pts = PackedVector2Array([
				Vector2(cx, cy - 10), Vector2(cx + 7, cy),
				Vector2(cx, cy + 10), Vector2(cx - 7, cy)
			])
			draw_colored_polygon(pts, Color(c.r, c.g, c.b, 0.6))
			draw_polyline(pts + PackedVector2Array([pts[0]]), c, 1.5, true)
		"flame":
			# Flame icon
			var flame_pts = PackedVector2Array([
				Vector2(cx, cy - 10), Vector2(cx + 5, cy - 3),
				Vector2(cx + 3, cy + 2), Vector2(cx + 6, cy + 8),
				Vector2(cx, cy + 5), Vector2(cx - 6, cy + 8),
				Vector2(cx - 3, cy + 2), Vector2(cx - 5, cy - 3),
			])
			draw_colored_polygon(flame_pts, Color(1.0, 0.4, 0.1, 0.7))
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx, cy - 5), Vector2(cx + 3, cy + 2),
				Vector2(cx, cy + 6), Vector2(cx - 3, cy + 2),
			]), Color(1.0, 0.8, 0.2, 0.8))
		"claw":
			# 3 claw slash marks
			for i in range(3):
				var ox = (i - 1) * 5.0
				var pts = PackedVector2Array([
					Vector2(cx + ox - 1, cy - 7), Vector2(cx + ox + 1, cy - 7),
					Vector2(cx + ox + 2, cy + 7), Vector2(cx + ox - 2, cy + 7),
				])
				draw_colored_polygon(pts, c)
		"skull":
			# Simple skull
			draw_circle(Vector2(cx, cy - 2), 7, c)
			draw_circle(Vector2(cx - 3, cy - 3), 2, _theme.bg_color)  # left eye
			draw_circle(Vector2(cx + 3, cy - 3), 2, _theme.bg_color)  # right eye
			draw_rect(Rect2(cx - 4, cy + 3, 8, 5), c, true)  # jaw
			for i in range(3):
				draw_line(Vector2(cx - 3 + i * 3, cy + 3), Vector2(cx - 3 + i * 3, cy + 8), _theme.bg_color, 1.0)
		"bottle":
			# Rum bottle
			draw_rect(Rect2(cx - 2, cy - 10, 4, 5), c, true)  # neck
			draw_rect(Rect2(cx - 5, cy - 5, 10, 13), c, true)  # body
			draw_circle(Vector2(cx, cy - 5), 5, c)  # shoulder
		"battery":
			# Battery
			draw_rect(Rect2(cx - 6, cy - 7, 12, 14), c, false, 1.5)
			draw_rect(Rect2(cx - 2, cy - 9, 4, 3), c, true)  # terminal
			draw_rect(Rect2(cx - 4, cy - 4, 8, 8), Color(c.r, c.g, c.b, 0.5), true)  # charge
		"goblet":
			# Blood goblet
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 6, cy - 8), Vector2(cx + 6, cy - 8),
				Vector2(cx + 4, cy - 2), Vector2(cx + 2, cy),
				Vector2(cx + 4, cy + 3), Vector2(cx + 6, cy + 8),
				Vector2(cx - 6, cy + 8), Vector2(cx - 4, cy + 3),
				Vector2(cx - 2, cy), Vector2(cx - 4, cy - 2),
			]), c)
			# Blood inside
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 4, cy - 6), Vector2(cx + 4, cy - 6),
				Vector2(cx + 3, cy - 3), Vector2(cx - 3, cy - 3),
			]), Color(0.8, 0.0, 0.1, 0.7))
		"shield":
			# Shield
			var shield_pts = PackedVector2Array([
				Vector2(cx - 7, cy - 8), Vector2(cx + 7, cy - 8),
				Vector2(cx + 7, cy + 2), Vector2(cx, cy + 10),
				Vector2(cx - 7, cy + 2),
			])
			draw_colored_polygon(shield_pts, Color(c.r, c.g, c.b, 0.6))
			draw_polyline(shield_pts + PackedVector2Array([shield_pts[0]]), c, 1.5, true)
			# Cross emblem
			draw_line(Vector2(cx, cy - 5), Vector2(cx, cy + 4), Color(1,1,1,0.4), 2.0)
			draw_line(Vector2(cx - 4, cy - 1), Vector2(cx + 4, cy - 1), Color(1,1,1,0.4), 2.0)
		"thermometer":
			# Thermometer
			draw_circle(Vector2(cx, cy + 5), 5, c)
			draw_rect(Rect2(cx - 2, cy - 10, 4, 14), c, true)
			# Mercury
			draw_circle(Vector2(cx, cy + 5), 3, Color(1.0, 0.3, 0.1, 0.8))
			draw_rect(Rect2(cx - 1, cy - 6, 2, 10), Color(1.0, 0.3, 0.1, 0.8), true)
		"glitch":
			# Glitch question mark
			var offset = Vector2.ZERO
			if fmod(_anim_time, 0.3) < 0.05:
				offset = Vector2(randf_range(-2, 2), randf_range(-2, 2))
			draw_string(ThemeDB.fallback_font, Vector2(cx - 5 + offset.x, cy + 8 + offset.y), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, c)

# ==================== HP TEXT ====================

func _draw_hp_text(rect: Rect2) -> void:
	var text = "%d/%d" % [int(current_hp), int(max_hp)]
	var font = ThemeDB.fallback_font
	var font_size = 11
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = Vector2(
		rect.position.x + (rect.size.x - text_size.x) * 0.5,
		rect.position.y + rect.size.y * 0.5 + text_size.y * 0.3
	)
	# Shadow
	draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, 0.6))
	# Text
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 1, 1, 0.9))

# ==================== PARTICLES ====================

func _draw_particles(rect: Rect2, fill: float) -> void:
	var particle = _theme.get("particle", "none")
	if particle == "none" or fill <= 0.01:
		return

	match particle:
		"leaves":
			_draw_leaf_particles(rect, fill)
		"sparkle":
			_draw_sparkle_particles(rect, fill)
		"fire":
			_draw_fire_particles(rect, fill)
		"smoke":
			_draw_smoke_particles(rect, fill)
		"drip":
			pass  # Already drawn in bar shape
		"coins":
			_draw_coin_particles(rect, fill)
		"circuit":
			pass  # Already drawn in bar shape
		"blood":
			_draw_blood_particles(rect, fill)
		"sparks":
			_draw_spark_particles(rect, fill)
		"steam":
			pass  # Already drawn in bar shape
		"static":
			_draw_static_particles(rect, fill)

func _draw_leaf_particles(rect: Rect2, fill: float) -> void:
	for i in range(2):
		var phase = fmod(_anim_time * 0.6 + i * 1.5, 3.0)
		var lx = rect.position.x + rect.size.x * fill - phase * 15
		var ly = rect.position.y - 3 + sin(phase * 2.0) * 4.0
		if lx > rect.position.x:
			var alpha = 0.4 * (1.0 - phase / 3.0)
			draw_circle(Vector2(lx, ly), 2.0, Color(0.3, 0.8, 0.2, alpha))

func _draw_sparkle_particles(rect: Rect2, fill: float) -> void:
	for i in range(3):
		var phase = fmod(_anim_time * 1.2 + i * 0.8, 2.0)
		var sx = rect.position.x + fmod((_anim_time * 30 + i * 73), rect.size.x * fill)
		var sy = rect.position.y + rect.size.y * 0.5 + sin(phase * PI) * 8.0 - 4.0
		var alpha = sin(phase * PI) * 0.6
		var spark_size = 1.5 + sin(phase * PI) * 1.5
		if alpha > 0:
			draw_circle(Vector2(sx, sy), spark_size, Color(1.0, 0.9, 1.0, alpha))

func _draw_fire_particles(rect: Rect2, fill: float) -> void:
	for i in range(3):
		var phase = fmod(_anim_time * 1.5 + i * 0.6, 1.0)
		var fx = rect.position.x + rect.size.x * fill * ((i + 1.0) / 4.0)
		var fy = rect.position.y - phase * 10.0
		var alpha = 0.5 * (1.0 - phase)
		var fire_color = Color(1.0, 0.5 - phase * 0.3, 0.0, alpha)
		draw_circle(Vector2(fx + sin(phase * 4.0) * 3.0, fy), 2.0 - phase, fire_color)

func _draw_smoke_particles(rect: Rect2, fill: float) -> void:
	for i in range(2):
		var phase = fmod(_anim_time * 0.4 + i * 1.2, 2.5)
		var sx = rect.position.x + rect.size.x * fill - 5 - i * 20
		var sy = rect.position.y - phase * 6.0
		if sx > rect.position.x:
			var alpha = 0.2 * (1.0 - phase / 2.5)
			draw_circle(Vector2(sx + sin(phase) * 4.0, sy), 3.0 + phase, Color(0.3, 0.2, 0.4, alpha))

func _draw_coin_particles(rect: Rect2, fill: float) -> void:
	var phase = fmod(_anim_time * 0.3, 4.0)
	if phase < 1.0:
		var cx = rect.position.x + rect.size.x * fill * 0.8
		var cy = rect.position.y - 2 - phase * 8.0
		var alpha = 0.6 * (1.0 - phase)
		draw_circle(Vector2(cx, cy), 3.0, Color(1.0, 0.85, 0.2, alpha))
		draw_circle(Vector2(cx, cy), 2.0, Color(1.0, 0.95, 0.5, alpha))

func _draw_blood_particles(rect: Rect2, fill: float) -> void:
	for i in range(2):
		var phase = fmod(_anim_time * 0.7 + i * 1.0, 2.0)
		var bx = rect.position.x + rect.size.x * fill * (0.3 + i * 0.4)
		var by = rect.end.y + phase * 5.0
		var alpha = 0.4 * (1.0 - phase / 2.0)
		draw_circle(Vector2(bx, by), 1.5, Color(0.7, 0.0, 0.1, alpha))

func _draw_spark_particles(rect: Rect2, fill: float) -> void:
	var phase = fmod(_anim_time * 2.0, 1.5)
	if phase < 0.3:
		var sx = rect.position.x + rect.size.x * fill
		var sy = rect.position.y + rect.size.y * 0.5
		for i in range(3):
			var angle = randf() * TAU
			var dist = phase * 15.0
			var sp = Vector2(sx + cos(angle + i) * dist, sy + sin(angle + i) * dist)
			draw_circle(sp, 1.0, Color(1.0, 0.9, 0.4, 0.5 * (1.0 - phase / 0.3)))

func _draw_static_particles(rect: Rect2, fill: float) -> void:
	# Random noise dots
	var rng = RandomNumberGenerator.new()
	rng.seed = int(_anim_time * 10) * 12345
	for i in range(8):
		var nx = rect.position.x + rng.randf() * rect.size.x * fill
		var ny = rect.position.y + rng.randf() * rect.size.y
		var nc = rng.randf()
		draw_rect(Rect2(nx, ny, 2, 2), Color(nc, nc, nc, 0.3), true)

# ==================== HELPERS ====================

func _get_fill_color(fill_pct: float) -> Color:
	var base = _theme.fill_color.lerp(_theme.fill_color2, 1.0 - fill_pct)
	# Flash white on damage
	if _flash_amount > 0:
		base = base.lerp(Color(1.0, 0.9, 0.9), _flash_amount * 0.6)
	# Danger pulse when low
	if fill_pct < 0.25 and fill_pct > 0:
		var pulse = sin(_anim_time * 5.0) * 0.15
		base = base.lerp(Color(1.0, 0.1, 0.1), 0.3 + pulse)
	return base
