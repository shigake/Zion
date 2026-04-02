extends SceneTree

## Generates 32x32 pixel art icons for all 18 synergies.
## Each icon uses the synergy's color with simple elemental shapes.
## Run: godot --headless --script res://scripts/tools/generate_synergy_icons.gd

const S := 32  # Sprite size
const OUT_DIR := "res://assets/sprites/synergies"

# Synergy definitions: id -> {color, shape}
# Colors match synergy_system.gd get_synergy_info()
const SYNERGIES := {
	"fire_fire":        {"color": Color(1.0, 0.3, 0.1),  "shape": "flame"},
	"ice_ice":          {"color": Color(0.3, 0.7, 1.0),  "shape": "crystal"},
	"electric_electric":{"color": Color(1.0, 1.0, 0.2),  "shape": "bolt"},
	"dark_dark":        {"color": Color(0.7, 0.3, 0.9),  "shape": "moon"},
	"water_water":      {"color": Color(0.2, 0.5, 1.0),  "shape": "wave"},
	"fire_ice":         {"color": Color(0.8, 0.5, 0.6),  "shape": "steam"},
	"electric_ice":     {"color": Color(0.5, 0.8, 1.0),  "shape": "bolt_crystal"},
	"water_fire":       {"color": Color(0.7, 0.4, 0.3),  "shape": "steam_drop"},
	"water_electric":   {"color": Color(0.3, 0.6, 0.8),  "shape": "bolt_drop"},
	"water_ice":        {"color": Color(0.2, 0.3, 0.9),  "shape": "ice_drop"},
	"water_dark":       {"color": Color(0.3, 0.1, 0.5),  "shape": "dark_wave"},
	"fire_poison":      {"color": Color(0.6, 0.8, 0.1),  "shape": "toxic_flame"},
	"ice_dark":         {"color": Color(0.2, 0.2, 0.5),  "shape": "shadow_crystal"},
	"electric_poison":  {"color": Color(0.7, 0.9, 0.2),  "shape": "toxic_bolt"},
	"poison_poison":    {"color": Color(0.4, 0.8, 0.2),  "shape": "skull"},
	"fire_dark":        {"color": Color(0.8, 0.2, 0.4),  "shape": "dark_flame"},
	"ice_electric":     {"color": Color(0.5, 0.8, 1.0),  "shape": "bolt_crystal"},
	"poison_dark":      {"color": Color(0.5, 0.2, 0.6),  "shape": "dark_skull"},
}

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	for syn_id in SYNERGIES:
		var data = SYNERGIES[syn_id]
		var img = _generate_icon(data["color"], data["shape"])
		_save(img, OUT_DIR + "/" + syn_id + ".png")

	print("All %d synergy icons generated!" % SYNERGIES.size())

func _generate_icon(color: Color, shape: String) -> Image:
	var img = _img()

	# Dark background with colored border
	var bg = color * 0.15
	bg.a = 0.9
	_fill(img, 0, 0, S, S, bg)

	# Border
	var border = color * 0.7
	border.a = 1.0
	_draw_border(img, border)

	# Inner glow gradient
	_draw_radial_glow(img, color * 0.3)

	# Draw shape based on type
	match shape:
		"flame":
			_draw_flame(img, color)
		"crystal":
			_draw_crystal(img, color)
		"bolt":
			_draw_bolt(img, color)
		"moon":
			_draw_moon(img, color)
		"wave":
			_draw_wave(img, color)
		"steam":
			_draw_steam(img, color)
		"bolt_crystal":
			_draw_bolt_small(img, color, 6)
			_draw_crystal_small(img, color, 18)
		"steam_drop":
			_draw_steam_small(img, color, 8)
			_draw_drop(img, color, 20)
		"bolt_drop":
			_draw_bolt_small(img, color, 6)
			_draw_drop(img, color, 20)
		"ice_drop":
			_draw_crystal_small(img, color, 6)
			_draw_drop(img, color, 20)
		"dark_wave":
			_draw_moon_small(img, color, 6)
			_draw_wave_small(img, color, 20)
		"toxic_flame":
			_draw_skull_small(img, color, 6)
			_draw_flame_small(img, color, 20)
		"shadow_crystal":
			_draw_moon_small(img, color, 6)
			_draw_crystal_small(img, color, 20)
		"toxic_bolt":
			_draw_skull_small(img, color, 6)
			_draw_bolt_small(img, color, 20)
		"skull":
			_draw_skull(img, color)
		"dark_flame":
			_draw_moon_small(img, color, 6)
			_draw_flame_small(img, color, 20)
		"dark_skull":
			_draw_moon_small(img, color, 6)
			_draw_skull_small(img, color, 20)

	# Highlight pixel (top-left sparkle)
	var hi = color.lightened(0.6)
	_px(img, 4, 4, hi)
	_px(img, 5, 3, hi)

	return img

# ==================== HELPERS ====================

func _img() -> Image:
	return Image.create(S, S, false, Image.FORMAT_RGBA8)

func _fill(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(maxi(x, 0), mini(x + w, S)):
		for py in range(maxi(y, 0), mini(y + h, S)):
			img.set_pixel(px, py, color)

func _px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < S and y >= 0 and y < S:
		img.set_pixel(x, y, color)

func _save(img: Image, path: String) -> void:
	img.save_png(path)
	print("Saved: ", path)

func _draw_border(img: Image, color: Color) -> void:
	for i in range(S):
		_px(img, i, 0, color)
		_px(img, i, 1, color)
		_px(img, i, S - 1, color)
		_px(img, i, S - 2, color)
		_px(img, 0, i, color)
		_px(img, 1, i, color)
		_px(img, S - 1, i, color)
		_px(img, S - 2, i, color)
	# Rounded corners — clear outer corners
	var bg = Color(0, 0, 0, 0)
	for c in [Vector2i(0, 0), Vector2i(S - 1, 0), Vector2i(0, S - 1), Vector2i(S - 1, S - 1)]:
		_px(img, c.x, c.y, bg)

func _draw_radial_glow(img: Image, color: Color) -> void:
	var center = Vector2(S / 2.0, S / 2.0)
	var max_dist = center.length()
	for x in range(3, S - 3):
		for y in range(3, S - 3):
			var dist = Vector2(x, y).distance_to(center)
			var t = 1.0 - clampf(dist / max_dist, 0.0, 1.0)
			if t > 0.1:
				var glow = color
				glow.a = t * 0.3
				var existing = img.get_pixel(x, y)
				img.set_pixel(x, y, existing.blend(glow))

# ==================== SINGLE ELEMENT SHAPES (centered) ====================

func _draw_flame(img: Image, color: Color) -> void:
	var hi = color.lightened(0.4)
	var lo = color.darkened(0.2)
	# Flame body
	_fill(img, 13, 8, 6, 4, lo)
	_fill(img, 12, 12, 8, 6, color)
	_fill(img, 11, 18, 10, 5, lo)
	_fill(img, 13, 23, 6, 3, lo)
	# Flame tip
	_px(img, 15, 6, hi)
	_px(img, 16, 6, hi)
	_px(img, 15, 7, hi)
	_px(img, 16, 7, hi)
	# Inner highlight
	_fill(img, 14, 13, 4, 3, hi)

func _draw_crystal(img: Image, color: Color) -> void:
	var hi = color.lightened(0.5)
	var lo = color.darkened(0.2)
	# Diamond shape
	for i in range(6):
		_fill(img, 16 - i, 8 + i, 1 + i * 2, 1, color)
	for i in range(6):
		_fill(img, 11 + i, 14 + i, 11 - i * 2, 1, lo)
	# Center highlight
	_fill(img, 14, 11, 4, 3, hi)
	# Sparkle
	_px(img, 12, 9, hi)

func _draw_bolt(img: Image, color: Color) -> void:
	var hi = color.lightened(0.4)
	var lo = color.darkened(0.1)
	# Lightning bolt shape
	_fill(img, 17, 6, 5, 3, hi)
	_fill(img, 15, 9, 5, 3, color)
	_fill(img, 13, 12, 8, 3, hi)
	_fill(img, 15, 15, 5, 3, color)
	_fill(img, 13, 18, 5, 3, lo)
	_fill(img, 11, 21, 5, 3, color)

func _draw_moon(img: Image, color: Color) -> void:
	var hi = color.lightened(0.3)
	var lo = color.darkened(0.2)
	var center = Vector2(16, 16)
	# Outer circle
	for x in range(4, 28):
		for y in range(4, 28):
			var dist = Vector2(x, y).distance_to(center)
			if dist < 10.0:
				_px(img, x, y, color)
	# Inner cutout (offset circle for crescent)
	var cut_center = Vector2(19, 13)
	for x in range(4, 28):
		for y in range(4, 28):
			var dist = Vector2(x, y).distance_to(cut_center)
			if dist < 7.0:
				var bg = img.get_pixel(x, y)
				if bg.a > 0.5:
					var dark = color * 0.15
					dark.a = 0.9
					_px(img, x, y, dark)
	# Highlight edge
	_px(img, 9, 10, hi)
	_px(img, 8, 14, hi)
	_px(img, 9, 18, hi)

func _draw_wave(img: Image, color: Color) -> void:
	var hi = color.lightened(0.4)
	var lo = color.darkened(0.2)
	# Three wave lines
	for row in range(3):
		var base_y = 10 + row * 6
		for x in range(4, 28):
			var wave_y = base_y + int(sin(x * 0.8) * 2.0)
			var c = hi if row == 0 else (color if row == 1 else lo)
			_px(img, x, wave_y, c)
			_px(img, x, wave_y + 1, c)

func _draw_steam(img: Image, color: Color) -> void:
	var hi = color.lightened(0.4)
	# Rising steam wisps
	for col in [10, 16, 22]:
		for y in range(6, 26):
			var x_off = int(sin(y * 0.6 + col) * 2.0)
			var alpha = 1.0 - float(26 - y) / 20.0
			var c = hi
			c.a = clampf(alpha, 0.3, 1.0)
			_px(img, col + x_off, y, c)
			_px(img, col + x_off + 1, y, c)

func _draw_skull(img: Image, color: Color) -> void:
	var hi = color.lightened(0.3)
	var lo = color.darkened(0.2)
	# Skull top
	_fill(img, 11, 7, 10, 8, color)
	_fill(img, 10, 9, 12, 5, color)
	# Eyes
	var eye_color = Color(0.1, 0.1, 0.1, 0.9)
	_fill(img, 12, 11, 3, 3, eye_color)
	_fill(img, 18, 11, 3, 3, eye_color)
	# Jaw
	_fill(img, 12, 16, 8, 4, lo)
	# Teeth
	_fill(img, 13, 17, 2, 2, hi)
	_fill(img, 17, 17, 2, 2, hi)

# ==================== SMALL ELEMENT SHAPES (for combos) ====================

func _draw_flame_small(img: Image, color: Color, cx: int) -> void:
	var hi = color.lightened(0.4)
	_fill(img, cx - 2, 10, 4, 3, color)
	_fill(img, cx - 3, 13, 6, 4, color)
	_fill(img, cx - 2, 17, 4, 3, color.darkened(0.2))
	_fill(img, cx - 1, 11, 2, 2, hi)

func _draw_crystal_small(img: Image, color: Color, cx: int) -> void:
	var hi = color.lightened(0.5)
	for i in range(4):
		_fill(img, cx - i, 11 + i, 1 + i * 2, 1, color)
	for i in range(4):
		_fill(img, cx - 3 + i, 15 + i, 7 - i * 2, 1, color.darkened(0.2))
	_px(img, cx, 13, hi)

func _draw_bolt_small(img: Image, color: Color, cx: int) -> void:
	var hi = color.lightened(0.4)
	_fill(img, cx, 8, 4, 2, hi)
	_fill(img, cx - 1, 10, 4, 2, color)
	_fill(img, cx - 2, 12, 6, 2, hi)
	_fill(img, cx, 14, 4, 2, color)
	_fill(img, cx - 1, 16, 4, 2, color.darkened(0.1))

func _draw_moon_small(img: Image, color: Color, cx: int) -> void:
	var center = Vector2(cx, 15)
	for x in range(cx - 5, cx + 5):
		for y in range(10, 20):
			if Vector2(x, y).distance_to(center) < 5.0:
				if Vector2(x, y).distance_to(Vector2(cx + 2, 13)) >= 3.5:
					_px(img, x, y, color)

func _draw_drop(img: Image, color: Color, cx: int) -> void:
	var hi = color.lightened(0.4)
	# Teardrop shape
	_px(img, cx, 9, hi)
	_fill(img, cx - 1, 10, 3, 2, color)
	_fill(img, cx - 2, 12, 5, 3, color)
	_fill(img, cx - 3, 15, 7, 3, color)
	_fill(img, cx - 2, 18, 5, 2, color.darkened(0.2))
	_fill(img, cx - 1, 20, 3, 1, color.darkened(0.3))
	# Highlight
	_px(img, cx - 1, 13, hi)

func _draw_wave_small(img: Image, color: Color, cx: int) -> void:
	var hi = color.lightened(0.3)
	for row in range(2):
		var base_y = 12 + row * 5
		for x in range(cx - 5, cx + 5):
			var wave_y = base_y + int(sin(x * 0.8) * 1.5)
			var c = hi if row == 0 else color
			_px(img, x, wave_y, c)
			_px(img, x, wave_y + 1, c)

func _draw_steam_small(img: Image, color: Color, cx: int) -> void:
	var hi = color.lightened(0.4)
	for col in [cx - 2, cx + 2]:
		for y in range(9, 22):
			var x_off = int(sin(y * 0.7 + col) * 1.5)
			var alpha = 1.0 - float(22 - y) / 13.0
			var c = hi
			c.a = clampf(alpha, 0.3, 1.0)
			_px(img, col + x_off, y, c)

func _draw_skull_small(img: Image, color: Color, cx: int) -> void:
	var hi = color.lightened(0.3)
	var eye_color = Color(0.1, 0.1, 0.1, 0.9)
	_fill(img, cx - 3, 10, 6, 5, color)
	_fill(img, cx - 4, 11, 8, 3, color)
	_fill(img, cx - 2, 10, 2, 2, eye_color)
	_fill(img, cx + 1, 10, 2, 2, eye_color)
	_fill(img, cx - 2, 15, 5, 3, color.darkened(0.2))
	_px(img, cx - 1, 16, hi)
	_px(img, cx + 1, 16, hi)
