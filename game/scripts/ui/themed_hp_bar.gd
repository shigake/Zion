extends Control

## Themed HP bar that changes shape and style based on character.
## Replaces the basic ProgressBar with a visually rich, character-specific design.

# Character theme configs: shape, colors, icon hint
const THEMES := {
	"ronin": {
		"shape": "blade",
		"fill_color": Color(0.2, 0.85, 0.35),
		"fill_low": Color(0.95, 0.2, 0.15),
		"border_color": Color(0.6, 0.8, 0.6, 0.6),
		"bg_color": Color(0.08, 0.12, 0.06, 0.9),
		"label": "HP",
	},
	"soldado": {
		"shape": "military",
		"fill_color": Color(0.3, 0.7, 0.3),
		"fill_low": Color(0.9, 0.3, 0.1),
		"border_color": Color(0.4, 0.5, 0.35, 0.7),
		"bg_color": Color(0.1, 0.1, 0.08, 0.9),
		"label": "VIT",
	},
	"mago": {
		"shape": "orb",
		"fill_color": Color(0.4, 0.3, 0.95),
		"fill_low": Color(0.9, 0.2, 0.5),
		"border_color": Color(0.6, 0.5, 1.0, 0.6),
		"bg_color": Color(0.08, 0.05, 0.15, 0.9),
		"label": "MANA",
	},
	"berserker": {
		"shape": "flames",
		"fill_color": Color(0.95, 0.4, 0.1),
		"fill_low": Color(1.0, 0.1, 0.1),
		"border_color": Color(0.8, 0.4, 0.2, 0.7),
		"bg_color": Color(0.15, 0.05, 0.02, 0.9),
		"label": "FURIA",
	},
	"ninja": {
		"shape": "shadow",
		"fill_color": Color(0.5, 0.2, 0.8),
		"fill_low": Color(0.9, 0.15, 0.3),
		"border_color": Color(0.4, 0.2, 0.6, 0.5),
		"bg_color": Color(0.05, 0.03, 0.1, 0.92),
		"label": "CHI",
	},
	"necro": {
		"shape": "skull",
		"fill_color": Color(0.15, 0.85, 0.3),
		"fill_low": Color(0.6, 0.1, 0.6),
		"border_color": Color(0.2, 0.6, 0.3, 0.6),
		"bg_color": Color(0.05, 0.1, 0.05, 0.92),
		"label": "ALMA",
	},
	"pirata": {
		"shape": "bottle",
		"fill_color": Color(0.7, 0.5, 0.15),
		"fill_low": Color(0.9, 0.2, 0.1),
		"border_color": Color(0.6, 0.45, 0.2, 0.7),
		"bg_color": Color(0.12, 0.08, 0.03, 0.9),
		"label": "RUM",
	},
	"engenheiro": {
		"shape": "battery",
		"fill_color": Color(0.9, 0.8, 0.1),
		"fill_low": Color(0.9, 0.2, 0.1),
		"border_color": Color(0.7, 0.65, 0.2, 0.7),
		"bg_color": Color(0.1, 0.1, 0.05, 0.9),
		"label": "PWR",
	},
	"vampiro": {
		"shape": "goblet",
		"fill_color": Color(0.8, 0.05, 0.15),
		"fill_low": Color(0.4, 0.0, 0.05),
		"border_color": Color(0.7, 0.15, 0.2, 0.7),
		"bg_color": Color(0.12, 0.02, 0.04, 0.92),
		"label": "SANGUE",
	},
	"gladiador": {
		"shape": "shield",
		"fill_color": Color(0.85, 0.7, 0.2),
		"fill_low": Color(0.9, 0.2, 0.1),
		"border_color": Color(0.7, 0.55, 0.15, 0.7),
		"bg_color": Color(0.1, 0.08, 0.03, 0.9),
		"label": "VIGOR",
	},
	"chef": {
		"shape": "pot",
		"fill_color": Color(0.95, 0.5, 0.2),
		"fill_low": Color(0.9, 0.15, 0.1),
		"border_color": Color(0.8, 0.5, 0.2, 0.7),
		"bg_color": Color(0.12, 0.06, 0.02, 0.9),
		"label": "SABOR",
	},
	"mystery": {
		"shape": "glitch",
		"fill_color": Color(0.0, 1.0, 0.5),
		"fill_low": Color(1.0, 0.0, 0.3),
		"border_color": Color(0.0, 0.8, 0.4, 0.5),
		"bg_color": Color(0.02, 0.08, 0.04, 0.92),
		"label": "???",
	},
	"lealith": {
		"shape": "shadow",
		"fill_color": Color(0.2, 0.4, 0.95),
		"fill_low": Color(0.8, 0.15, 0.2),
		"border_color": Color(0.15, 0.3, 0.8, 0.6),
		"bg_color": Color(0.03, 0.04, 0.12, 0.92),
		"label": "NOVE",
	},
}

var _theme: Dictionary = {}
var _hp_ratio: float = 1.0
var _display_ratio: float = 1.0  # Smoothly interpolated
var _ghost_ratio: float = 1.0
var _ghost_delay: float = 0.0
var _time: float = 0.0
var _hit_flash: float = 0.0
var _char_icon: Texture2D = null
var _hp_text_label: Label = null
var _theme_label: Label = null

func _ready() -> void:
	var char_id = GameManager.selected_character
	_theme = THEMES.get(char_id, THEMES["ronin"])

	# Try loading character icon
	var icon_path = "res://assets/icons/characters/%s.svg" % char_id
	if ResourceLoader.exists(icon_path):
		_char_icon = load(icon_path)

	# HP text (right side)
	_hp_text_label = Label.new()
	_hp_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hp_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_text_label.add_theme_font_size_override("font_size", 11)
	_hp_text_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	add_child(_hp_text_label)

	# Theme label (left side, small)
	_theme_label = Label.new()
	_theme_label.text = _theme.get("label", "HP")
	_theme_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_theme_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_theme_label.add_theme_font_size_override("font_size", 9)
	_theme_label.add_theme_color_override("font_color", _theme["border_color"])
	add_child(_theme_label)

	custom_minimum_size = Vector2(260, 28)

func update_hp(current: int, max_hp: int) -> void:
	var new_ratio = clampf(float(current) / maxf(1.0, float(max_hp)), 0.0, 1.0)
	if new_ratio < _hp_ratio:
		# Damage taken
		_ghost_ratio = _display_ratio
		_ghost_delay = 0.5
		_hit_flash = 0.3
	_hp_ratio = new_ratio
	if _hp_text_label:
		_hp_text_label.text = "%d / %d" % [current, max_hp]

func _process(delta: float) -> void:
	_time += delta

	# Smooth interpolation of fill
	_display_ratio = lerp(_display_ratio, _hp_ratio, delta * 8.0)

	# Ghost bar drain
	if _ghost_delay > 0:
		_ghost_delay -= delta
	elif _ghost_ratio > _display_ratio:
		_ghost_ratio = lerp(_ghost_ratio, _display_ratio, delta * 3.0)

	# Hit flash decay
	if _hit_flash > 0:
		_hit_flash -= delta

	# Position labels
	if _hp_text_label:
		var icon_offset = 32 if _char_icon else 4
		_hp_text_label.position = Vector2(icon_offset, 2)
		_hp_text_label.size = Vector2(size.x - icon_offset - 8, size.y - 4)
	if _theme_label:
		var icon_offset = 32 if _char_icon else 4
		_theme_label.position = Vector2(icon_offset + 6, 2)
		_theme_label.size = Vector2(80, size.y - 4)

	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	var icon_w = 30 if _char_icon else 0
	var bar_x = icon_w + 2
	var bar_w = w - bar_x - 2
	var bar_h = h - 4
	var bar_y = 2.0

	# Draw character icon
	if _char_icon:
		var icon_rect = Rect2(0, 0, 28, 28)
		draw_texture_rect(_char_icon, icon_rect, false)

	# Background
	var bg_rect = Rect2(bar_x, bar_y, bar_w, bar_h)
	draw_rect(bg_rect, _theme["bg_color"], true)

	# Ghost bar (recent damage, fades)
	if _ghost_ratio > _display_ratio + 0.01:
		var ghost_w = bar_w * _ghost_ratio
		var ghost_rect = Rect2(bar_x, bar_y, ghost_w, bar_h)
		draw_rect(ghost_rect, Color(1, 1, 1, 0.15), true)

	# Fill bar
	var fill_w = bar_w * _display_ratio
	if fill_w > 0:
		var fill_color: Color
		if _hit_flash > 0:
			fill_color = Color(1.0, 0.9, 0.9)
		elif _hp_ratio < 0.25:
			# Pulse red when low HP
			var pulse = sin(_time * 6.0) * 0.3 + 0.7
			fill_color = _theme["fill_low"].lerp(_theme["fill_color"], pulse * 0.3)
		elif _hp_ratio < 0.5:
			fill_color = _theme["fill_color"].lerp(_theme["fill_low"], 0.4)
		else:
			fill_color = _theme["fill_color"]

		var fill_rect = Rect2(bar_x, bar_y, fill_w, bar_h)
		draw_rect(fill_rect, fill_color, true)

		# Gradient highlight on top half
		var highlight_rect = Rect2(bar_x, bar_y, fill_w, bar_h * 0.4)
		draw_rect(highlight_rect, Color(1, 1, 1, 0.1), true)

		# Themed shape overlay
		_draw_theme_overlay(bar_x, bar_y, fill_w, bar_h)

	# Border
	draw_rect(bg_rect, _theme["border_color"], false, 1.5)

	# Tick marks (25%, 50%, 75%)
	for pct in [0.25, 0.5, 0.75]:
		var tick_x = bar_x + bar_w * pct
		draw_line(Vector2(tick_x, bar_y), Vector2(tick_x, bar_y + bar_h), Color(1, 1, 1, 0.08), 1.0)

func _draw_theme_overlay(x: float, y: float, w: float, h: float) -> void:
	# Draw subtle pattern on the fill based on theme shape
	var shape = _theme.get("shape", "blade")
	var pattern_color = Color(1, 1, 1, 0.04)
	match shape:
		"blade":
			# Diagonal slashes
			for i in range(int(w / 12)):
				var sx = x + i * 12
				draw_line(Vector2(sx, y + h), Vector2(sx + 6, y), pattern_color, 1.0)
		"orb":
			# Circular arcs
			for i in range(int(w / 18)):
				var cx = x + i * 18 + 9
				draw_arc(Vector2(cx, y + h * 0.5), h * 0.3, 0, TAU, 8, pattern_color, 1.0)
		"flames":
			# Zigzag top edge
			for i in range(int(w / 8)):
				var fx = x + i * 8
				draw_line(Vector2(fx, y + 2), Vector2(fx + 4, y), Color(1, 0.8, 0.2, 0.08), 1.0)
				draw_line(Vector2(fx + 4, y), Vector2(fx + 8, y + 2), Color(1, 0.8, 0.2, 0.08), 1.0)
		"goblet":
			# Drip lines from top
			for i in range(int(w / 14)):
				var dx = x + i * 14 + 7
				var drip_h = sin(_time * 2.0 + i) * 3 + 5
				draw_line(Vector2(dx, y), Vector2(dx, y + drip_h), Color(0.6, 0, 0.05, 0.12), 1.5)
		"battery":
			# Segment blocks
			for i in range(int(w / 16)):
				var bx = x + i * 16 + 1
				draw_rect(Rect2(bx, y + 1, 13, h - 2), pattern_color, false, 0.5)
		"shield":
			# Cross pattern
			for i in range(int(w / 20)):
				var cx = x + i * 20 + 10
				draw_line(Vector2(cx - 4, y + h * 0.5), Vector2(cx + 4, y + h * 0.5), pattern_color, 1.0)
				draw_line(Vector2(cx, y + 3), Vector2(cx, y + h - 3), pattern_color, 1.0)
		"shadow":
			# Fading dots
			for i in range(int(w / 10)):
				var dx = x + i * 10 + 5
				var alpha = 0.03 + sin(_time * 3.0 + i * 0.5) * 0.02
				draw_circle(Vector2(dx, y + h * 0.5), 2.0, Color(1, 1, 1, alpha))
		"skull":
			# Small crosses
			for i in range(int(w / 16)):
				var cx = x + i * 16 + 8
				draw_line(Vector2(cx - 2, y + h * 0.5), Vector2(cx + 2, y + h * 0.5), pattern_color, 1.0)
				draw_line(Vector2(cx, y + h * 0.3), Vector2(cx, y + h * 0.7), pattern_color, 1.0)
		"bottle":
			# Bubble circles
			for i in range(int(w / 12)):
				var bx = x + i * 12 + 6
				var by = y + h * 0.5 + sin(_time * 1.5 + i) * 3
				draw_circle(Vector2(bx, by), 1.5, Color(1, 1, 1, 0.05))
		"glitch":
			# Random pixel blocks
			for i in range(int(w / 6)):
				if (i + int(_time * 8)) % 3 == 0:
					var gx = x + i * 6
					draw_rect(Rect2(gx, y + 1, 4, h - 2), Color(0, 1, 0.5, 0.06), true)
