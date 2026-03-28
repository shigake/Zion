extends SceneTree

## Generates 32x32 pixel art sprites for themed enemies across 5 stages.
## Each stage has 4 enemy variants (weak, medium, strong, special).
## Run: godot --headless --path game --script res://scripts/tools/themed_enemies_gen1.gd

const S := 32  # Sprite size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	# Create directories
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/enemies/forest")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/enemies/farm")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/enemies/tokyo")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/enemies/volcano")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/enemies/ocean")

	# Forest (4)
	_gen_forest_wolf()
	_gen_forest_treant()
	_gen_forest_spider()
	_gen_forest_mushroom()

	# Farm (4)
	_gen_farm_chicken()
	_gen_farm_scarecrow()
	_gen_farm_pig()
	_gen_farm_crow()

	# Tokyo (4)
	_gen_tokyo_robot()
	_gen_tokyo_drone()
	_gen_tokyo_hacker()
	_gen_tokyo_mecha()

	# Volcano (4)
	_gen_volcano_imp()
	_gen_volcano_golem()
	_gen_volcano_hellhound()
	_gen_volcano_magma_slime()

	# Ocean (4)
	_gen_ocean_crab()
	_gen_ocean_fish()
	_gen_ocean_urchin()
	_gen_ocean_squid()

	print("All 20 themed enemy sprites generated!")

# ==================== HELPERS ====================

func _img() -> Image:
	return Image.create(S, S, false, Image.FORMAT_RGBA8)

func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(maxi(x, 0), mini(x + w, S)):
		for py in range(maxi(y, 0), mini(y + h, S)):
			img.set_pixel(px, py, color)

func _px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < S and y >= 0 and y < S:
		img.set_pixel(x, y, color)

func _add_outline(img: Image, color: Color) -> void:
	var outline_img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	for x in range(S):
		for y in range(S):
			if img.get_pixel(x, y).a > 0:
				continue
			for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx = x + offset.x
				var ny = y + offset.y
				if nx >= 0 and nx < S and ny >= 0 and ny < S:
					if img.get_pixel(nx, ny).a > 0:
						outline_img.set_pixel(x, y, color)
						break
	for x in range(S):
		for y in range(S):
			if outline_img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, outline_img.get_pixel(x, y))

func _save(img: Image, path: String) -> void:
	img.save_png(path)
	print("Saved: ", path)

func _circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for x in range(cx - r, cx + r + 1):
		for y in range(cy - r, cy + r + 1):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				_px(img, x, y, color)

func _line_h(img: Image, x: int, y: int, length: int, color: Color) -> void:
	for i in range(length):
		_px(img, x + i, y, color)

func _line_v(img: Image, x: int, y: int, length: int, color: Color) -> void:
	for i in range(length):
		_px(img, x, y + i, color)

# ==================== FOREST ====================

func _gen_forest_wolf() -> void:
	var img = _img()
	var body = Color(0.55, 0.55, 0.58)
	var body_dark = Color(0.4, 0.4, 0.43)
	var body_light = Color(0.7, 0.7, 0.73)
	var eye = Color(0.95, 0.85, 0.1)
	var nose = Color(0.15, 0.1, 0.1)
	var teeth = Color(0.95, 0.95, 0.95)
	var outline = Color(0.2, 0.2, 0.22)

	# Body (horizontal oval)
	_fill_rect(img, 6, 14, 16, 8, body)
	_fill_rect(img, 8, 12, 12, 2, body)
	_fill_rect(img, 7, 22, 14, 2, body_dark)

	# Head
	_fill_rect(img, 18, 8, 8, 8, body)
	_fill_rect(img, 20, 6, 4, 2, body)
	_fill_rect(img, 22, 16, 6, 4, body)  # snout

	# Ears (pointed)
	_px(img, 20, 5, body_dark)
	_px(img, 21, 4, body_dark)
	_px(img, 21, 5, body_light)
	_px(img, 24, 5, body_dark)
	_px(img, 25, 4, body_dark)
	_px(img, 25, 5, body_light)

	# Eyes (yellow, menacing)
	_fill_rect(img, 20, 10, 2, 2, eye)
	_fill_rect(img, 24, 10, 2, 2, eye)
	_px(img, 21, 11, Color(0.1, 0.1, 0.1))
	_px(img, 25, 11, Color(0.1, 0.1, 0.1))

	# Nose
	_fill_rect(img, 27, 17, 2, 2, nose)

	# Teeth (open mouth)
	_px(img, 23, 19, teeth)
	_px(img, 25, 19, teeth)
	_px(img, 27, 19, teeth)
	_fill_rect(img, 22, 18, 7, 1, Color(0.3, 0.1, 0.1))

	# Belly highlight
	_fill_rect(img, 9, 16, 8, 4, body_light)

	# Legs (4 legs)
	_fill_rect(img, 8, 24, 3, 4, body_dark)
	_fill_rect(img, 13, 24, 3, 4, body_dark)
	_fill_rect(img, 18, 24, 3, 4, body_dark)
	# Paws
	_fill_rect(img, 7, 27, 4, 2, body)
	_fill_rect(img, 12, 27, 4, 2, body)
	_fill_rect(img, 17, 27, 4, 2, body)

	# Tail
	_fill_rect(img, 2, 12, 4, 2, body)
	_fill_rect(img, 1, 11, 3, 2, body_light)
	_px(img, 1, 10, body_light)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/forest/forest_wolf.png")


func _gen_forest_treant() -> void:
	var img = _img()
	var bark = Color(0.4, 0.28, 0.15)
	var bark_dark = Color(0.3, 0.2, 0.1)
	var bark_light = Color(0.55, 0.4, 0.22)
	var leaves = Color(0.2, 0.55, 0.15)
	var leaves_dark = Color(0.15, 0.4, 0.1)
	var leaves_light = Color(0.35, 0.7, 0.25)
	var eye = Color(0.95, 0.3, 0.1)
	var mouth = Color(0.15, 0.08, 0.05)
	var outline = Color(0.15, 0.1, 0.05)

	# Trunk / body
	_fill_rect(img, 10, 12, 12, 14, bark)
	_fill_rect(img, 12, 10, 8, 2, bark)
	_fill_rect(img, 9, 14, 2, 8, bark_dark)
	_fill_rect(img, 21, 14, 2, 8, bark_dark)

	# Bark texture
	_fill_rect(img, 13, 18, 2, 3, bark_dark)
	_fill_rect(img, 17, 15, 2, 4, bark_dark)
	_fill_rect(img, 11, 22, 3, 2, bark_light)

	# Leafy crown
	_fill_rect(img, 7, 2, 18, 4, leaves)
	_fill_rect(img, 5, 4, 22, 4, leaves)
	_fill_rect(img, 8, 8, 16, 4, leaves)
	_fill_rect(img, 10, 6, 12, 2, leaves_dark)
	# Leaf highlights
	_fill_rect(img, 8, 3, 3, 2, leaves_light)
	_fill_rect(img, 18, 2, 4, 2, leaves_light)
	_fill_rect(img, 12, 5, 3, 2, leaves_light)

	# Angry face in trunk
	# Eyes (glowing orange)
	_fill_rect(img, 12, 14, 3, 3, eye)
	_fill_rect(img, 18, 14, 3, 3, eye)
	_px(img, 13, 15, Color(1.0, 0.9, 0.2))
	_px(img, 19, 15, Color(1.0, 0.9, 0.2))
	# Angry brows
	_px(img, 12, 13, mouth)
	_px(img, 13, 12, mouth)
	_px(img, 14, 12, mouth)
	_px(img, 20, 13, mouth)
	_px(img, 19, 12, mouth)
	_px(img, 18, 12, mouth)

	# Mouth (gnarled hole)
	_fill_rect(img, 13, 19, 6, 3, mouth)
	_px(img, 14, 19, bark_dark)
	_px(img, 17, 19, bark_dark)

	# Root-legs
	_fill_rect(img, 8, 26, 4, 4, bark_dark)
	_fill_rect(img, 20, 26, 4, 4, bark_dark)
	_fill_rect(img, 13, 26, 5, 3, bark_dark)
	_px(img, 7, 28, bark_dark)
	_px(img, 24, 28, bark_dark)

	# Branch arms
	_fill_rect(img, 3, 10, 6, 2, bark)
	_fill_rect(img, 2, 8, 3, 2, bark)
	_fill_rect(img, 1, 7, 2, 2, leaves)
	_fill_rect(img, 23, 10, 6, 2, bark)
	_fill_rect(img, 27, 8, 3, 2, bark)
	_fill_rect(img, 28, 7, 2, 2, leaves)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/forest/forest_treant.png")


func _gen_forest_spider() -> void:
	var img = _img()
	var body = Color(0.15, 0.4, 0.12)
	var body_dark = Color(0.1, 0.3, 0.08)
	var body_light = Color(0.25, 0.55, 0.2)
	var eye = Color(0.9, 0.15, 0.1)
	var leg = Color(0.12, 0.35, 0.1)
	var fang = Color(0.9, 0.9, 0.85)
	var outline = Color(0.05, 0.18, 0.04)

	# Abdomen (back, larger)
	_circle(img, 16, 20, 6, body)
	_fill_rect(img, 13, 18, 2, 3, body_light)
	_fill_rect(img, 18, 22, 2, 2, body_dark)
	# Pattern on abdomen
	_px(img, 15, 18, body_light)
	_px(img, 17, 18, body_light)
	_px(img, 16, 20, body_light)

	# Cephalothorax (front, smaller)
	_circle(img, 16, 12, 4, body)
	_fill_rect(img, 14, 10, 2, 2, body_light)

	# 8 red eyes (2 rows)
	_px(img, 13, 10, eye)
	_px(img, 15, 10, eye)
	_px(img, 17, 10, eye)
	_px(img, 19, 10, eye)
	_px(img, 14, 9, eye)
	_px(img, 16, 9, eye)
	_px(img, 18, 9, eye)
	_px(img, 14, 11, Color(1.0, 0.3, 0.2))  # center eyes brighter

	# Fangs
	_px(img, 14, 14, fang)
	_px(img, 15, 15, fang)
	_px(img, 17, 14, fang)
	_px(img, 18, 15, fang)

	# Legs (8 legs, 4 per side)
	# Left legs
	_fill_rect(img, 8, 11, 4, 1, leg)
	_fill_rect(img, 5, 10, 3, 1, leg)
	_px(img, 4, 9, leg)
	_fill_rect(img, 8, 13, 4, 1, leg)
	_fill_rect(img, 5, 14, 3, 1, leg)
	_px(img, 4, 15, leg)
	_fill_rect(img, 9, 16, 3, 1, leg)
	_fill_rect(img, 6, 17, 3, 1, leg)
	_px(img, 5, 18, leg)
	_fill_rect(img, 10, 19, 2, 1, leg)
	_fill_rect(img, 7, 20, 3, 1, leg)
	_px(img, 6, 21, leg)

	# Right legs
	_fill_rect(img, 20, 11, 4, 1, leg)
	_fill_rect(img, 24, 10, 3, 1, leg)
	_px(img, 27, 9, leg)
	_fill_rect(img, 20, 13, 4, 1, leg)
	_fill_rect(img, 24, 14, 3, 1, leg)
	_px(img, 27, 15, leg)
	_fill_rect(img, 20, 16, 3, 1, leg)
	_fill_rect(img, 23, 17, 3, 1, leg)
	_px(img, 26, 18, leg)
	_fill_rect(img, 20, 19, 2, 1, leg)
	_fill_rect(img, 22, 20, 3, 1, leg)
	_px(img, 25, 21, leg)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/forest/forest_spider.png")


func _gen_forest_mushroom() -> void:
	var img = _img()
	var cap = Color(0.55, 0.15, 0.6)
	var cap_dark = Color(0.4, 0.1, 0.45)
	var cap_light = Color(0.7, 0.3, 0.75)
	var spot = Color(0.9, 0.85, 0.8)
	var stem = Color(0.85, 0.8, 0.7)
	var stem_dark = Color(0.7, 0.65, 0.55)
	var eye = Color(0.1, 0.1, 0.1)
	var eye_white = Color(0.95, 0.95, 0.95)
	var mouth = Color(0.3, 0.05, 0.1)
	var outline = Color(0.25, 0.05, 0.28)

	# Cap (large dome)
	_fill_rect(img, 4, 4, 24, 4, cap)
	_fill_rect(img, 6, 2, 20, 2, cap)
	_fill_rect(img, 3, 8, 26, 3, cap)
	_fill_rect(img, 5, 11, 22, 2, cap)
	_fill_rect(img, 9, 1, 14, 2, cap_dark)
	# Cap highlight
	_fill_rect(img, 8, 3, 5, 3, cap_light)
	# Spots on cap
	_fill_rect(img, 10, 3, 2, 2, spot)
	_fill_rect(img, 18, 4, 3, 2, spot)
	_fill_rect(img, 7, 7, 2, 2, spot)
	_fill_rect(img, 22, 6, 2, 2, spot)
	_fill_rect(img, 14, 6, 2, 2, spot)

	# Stem / body
	_fill_rect(img, 10, 13, 12, 10, stem)
	_fill_rect(img, 12, 11, 8, 2, stem)
	_fill_rect(img, 9, 15, 2, 4, stem_dark)
	_fill_rect(img, 21, 15, 2, 4, stem_dark)

	# Angry face
	# Eyes
	_fill_rect(img, 12, 16, 3, 3, eye_white)
	_fill_rect(img, 18, 16, 3, 3, eye_white)
	_fill_rect(img, 13, 17, 2, 2, eye)
	_fill_rect(img, 19, 17, 2, 2, eye)
	# Angry brows
	_px(img, 12, 15, eye)
	_px(img, 13, 14, eye)
	_px(img, 14, 14, eye)
	_px(img, 20, 15, eye)
	_px(img, 19, 14, eye)
	_px(img, 18, 14, eye)
	# Mouth (frowning)
	_fill_rect(img, 13, 21, 6, 1, mouth)
	_px(img, 12, 20, mouth)
	_px(img, 19, 20, mouth)

	# Feet (stubby)
	_fill_rect(img, 9, 23, 5, 4, stem_dark)
	_fill_rect(img, 18, 23, 5, 4, stem_dark)
	_fill_rect(img, 8, 26, 6, 3, stem)
	_fill_rect(img, 18, 26, 6, 3, stem)

	# Small arms
	_fill_rect(img, 6, 16, 3, 2, stem)
	_fill_rect(img, 23, 16, 3, 2, stem)
	_px(img, 5, 17, stem_dark)
	_px(img, 26, 17, stem_dark)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/forest/forest_mushroom.png")

# ==================== FARM ====================

func _gen_farm_chicken() -> void:
	var img = _img()
	var body = Color(0.9, 0.88, 0.82)
	var body_dark = Color(0.75, 0.72, 0.65)
	var wing = Color(0.85, 0.82, 0.75)
	var eye = Color(0.85, 0.1, 0.1)
	var beak = Color(0.9, 0.65, 0.15)
	var comb = Color(0.85, 0.15, 0.12)
	var feet = Color(0.9, 0.6, 0.1)
	var outline = Color(0.35, 0.3, 0.25)

	# Body (round)
	_circle(img, 16, 18, 7, body)
	_fill_rect(img, 11, 14, 10, 6, body)
	_fill_rect(img, 12, 20, 8, 4, body_dark)

	# Head
	_circle(img, 16, 9, 5, body)
	_fill_rect(img, 13, 6, 6, 3, body)

	# Comb (on top)
	_fill_rect(img, 14, 3, 2, 3, comb)
	_fill_rect(img, 16, 4, 2, 3, comb)
	_fill_rect(img, 18, 5, 2, 2, comb)

	# Red evil eyes
	_fill_rect(img, 13, 8, 2, 2, eye)
	_fill_rect(img, 18, 8, 2, 2, eye)
	_px(img, 13, 8, Color(1.0, 0.3, 0.3))
	_px(img, 18, 8, Color(1.0, 0.3, 0.3))

	# Beak
	_fill_rect(img, 15, 11, 3, 2, beak)
	_px(img, 16, 13, beak)

	# Wings (flapping up slightly)
	_fill_rect(img, 4, 14, 6, 4, wing)
	_fill_rect(img, 3, 13, 4, 2, wing)
	_fill_rect(img, 22, 14, 6, 4, wing)
	_fill_rect(img, 25, 13, 4, 2, wing)

	# Tail feathers
	_fill_rect(img, 13, 24, 2, 2, body_dark)
	_fill_rect(img, 17, 24, 2, 2, body_dark)

	# Feet
	_fill_rect(img, 12, 25, 2, 4, feet)
	_fill_rect(img, 19, 25, 2, 4, feet)
	_line_h(img, 10, 28, 5, feet)
	_line_h(img, 18, 28, 5, feet)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/farm/farm_chicken.png")


func _gen_farm_scarecrow() -> void:
	var img = _img()
	var cloth = Color(0.55, 0.4, 0.2)
	var cloth_dark = Color(0.4, 0.28, 0.12)
	var cloth_torn = Color(0.65, 0.5, 0.28)
	var hat = Color(0.35, 0.25, 0.1)
	var face = Color(0.7, 0.6, 0.4)
	var eye_glow = Color(0.3, 0.95, 0.15)
	var straw = Color(0.85, 0.75, 0.3)
	var outline = Color(0.2, 0.15, 0.05)

	# Hat (wide brim)
	_fill_rect(img, 4, 3, 24, 2, hat)
	_fill_rect(img, 9, 1, 14, 3, hat)
	_fill_rect(img, 11, 0, 10, 1, Color(0.3, 0.2, 0.08))

	# Head (burlap sack)
	_fill_rect(img, 11, 5, 10, 8, face)
	_fill_rect(img, 12, 4, 8, 1, face)

	# Glowing eyes
	_fill_rect(img, 13, 7, 2, 2, eye_glow)
	_fill_rect(img, 18, 7, 2, 2, eye_glow)
	_px(img, 13, 7, Color(0.5, 1.0, 0.3))
	_px(img, 18, 7, Color(0.5, 1.0, 0.3))

	# Stitched mouth
	_line_h(img, 13, 11, 6, Color(0.3, 0.2, 0.1))
	_px(img, 14, 10, Color(0.3, 0.2, 0.1))
	_px(img, 16, 10, Color(0.3, 0.2, 0.1))
	_px(img, 18, 10, Color(0.3, 0.2, 0.1))

	# Body (tattered shirt)
	_fill_rect(img, 10, 13, 12, 10, cloth)
	_fill_rect(img, 12, 12, 8, 1, cloth)
	# Torn patches
	_fill_rect(img, 11, 16, 3, 2, cloth_torn)
	_fill_rect(img, 18, 19, 3, 2, cloth_torn)
	_px(img, 10, 22, cloth_torn)
	_px(img, 21, 21, cloth_torn)

	# Arms (spread wide, stick-like)
	_fill_rect(img, 2, 14, 8, 2, cloth)
	_fill_rect(img, 22, 14, 8, 2, cloth)
	# Straw sticking out of sleeves
	_px(img, 1, 13, straw)
	_px(img, 1, 15, straw)
	_px(img, 0, 14, straw)
	_px(img, 30, 13, straw)
	_px(img, 30, 15, straw)
	_px(img, 31, 14, straw)

	# Straw from neck
	_px(img, 11, 12, straw)
	_px(img, 20, 12, straw)
	_px(img, 10, 13, straw)
	_px(img, 21, 13, straw)

	# Legs (stick legs with patches)
	_fill_rect(img, 12, 23, 3, 6, cloth_dark)
	_fill_rect(img, 18, 23, 3, 6, cloth_dark)
	# Feet
	_fill_rect(img, 11, 28, 5, 2, cloth)
	_fill_rect(img, 17, 28, 5, 2, cloth)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/farm/farm_scarecrow.png")


func _gen_farm_pig() -> void:
	var img = _img()
	var body = Color(0.9, 0.65, 0.6)
	var body_dark = Color(0.75, 0.5, 0.45)
	var body_light = Color(0.95, 0.75, 0.72)
	var eye = Color(0.85, 0.15, 0.1)
	var snout = Color(0.85, 0.5, 0.48)
	var tusk = Color(0.95, 0.95, 0.9)
	var hoof = Color(0.5, 0.35, 0.3)
	var outline = Color(0.4, 0.2, 0.18)

	# Body (large, round)
	_fill_rect(img, 5, 12, 22, 10, body)
	_fill_rect(img, 7, 10, 18, 2, body)
	_fill_rect(img, 6, 22, 20, 2, body_dark)
	# Belly
	_fill_rect(img, 10, 16, 12, 5, body_light)

	# Head
	_fill_rect(img, 19, 6, 10, 8, body)
	_fill_rect(img, 21, 4, 6, 3, body)

	# Ears (floppy)
	_fill_rect(img, 21, 3, 3, 2, body_dark)
	_fill_rect(img, 26, 3, 3, 2, body_dark)
	_px(img, 20, 2, body_dark)
	_px(img, 29, 2, body_dark)

	# Angry eyes (red)
	_fill_rect(img, 21, 8, 2, 2, eye)
	_fill_rect(img, 26, 8, 2, 2, eye)
	_px(img, 21, 7, Color(0.15, 0.1, 0.1))  # angry brow
	_px(img, 27, 7, Color(0.15, 0.1, 0.1))

	# Snout
	_fill_rect(img, 23, 11, 4, 3, snout)
	_px(img, 24, 12, Color(0.3, 0.15, 0.12))  # nostril
	_px(img, 26, 12, Color(0.3, 0.15, 0.12))

	# Tusks (protruding upward)
	_px(img, 22, 11, tusk)
	_px(img, 22, 10, tusk)
	_px(img, 28, 11, tusk)
	_px(img, 28, 10, tusk)

	# Legs (4 hooves)
	_fill_rect(img, 7, 24, 4, 4, body_dark)
	_fill_rect(img, 14, 24, 4, 4, body_dark)
	_fill_rect(img, 21, 24, 4, 4, body_dark)
	_fill_rect(img, 7, 27, 4, 2, hoof)
	_fill_rect(img, 14, 27, 4, 2, hoof)
	_fill_rect(img, 21, 27, 4, 2, hoof)

	# Curly tail
	_px(img, 3, 13, body_dark)
	_px(img, 2, 12, body_dark)
	_px(img, 2, 11, body_dark)
	_px(img, 3, 10, body_dark)
	_px(img, 4, 11, body_dark)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/farm/farm_pig.png")


func _gen_farm_crow() -> void:
	var img = _img()
	var body = Color(0.1, 0.1, 0.12)
	var body_light = Color(0.18, 0.18, 0.22)
	var wing = Color(0.08, 0.08, 0.1)
	var wing_tip = Color(0.15, 0.15, 0.18)
	var eye = Color(0.9, 0.12, 0.1)
	var beak = Color(0.35, 0.3, 0.15)
	var feet = Color(0.3, 0.25, 0.1)
	var outline = Color(0.25, 0.2, 0.2)

	# Body
	_circle(img, 16, 16, 5, body)
	_fill_rect(img, 13, 12, 6, 4, body)

	# Head
	_circle(img, 16, 9, 4, body)
	_fill_rect(img, 14, 7, 4, 3, body_light)

	# Red eyes
	_fill_rect(img, 14, 8, 2, 2, eye)
	_fill_rect(img, 18, 8, 2, 2, eye)
	_px(img, 14, 8, Color(1.0, 0.3, 0.3))
	_px(img, 18, 8, Color(1.0, 0.3, 0.3))

	# Beak
	_fill_rect(img, 15, 12, 3, 1, beak)
	_px(img, 16, 13, beak)
	_px(img, 16, 11, beak)

	# Wings (large, spread)
	_fill_rect(img, 3, 12, 9, 3, wing)
	_fill_rect(img, 1, 11, 5, 2, wing)
	_fill_rect(img, 2, 15, 6, 2, wing_tip)
	_px(img, 1, 10, wing_tip)
	_fill_rect(img, 20, 12, 9, 3, wing)
	_fill_rect(img, 26, 11, 5, 2, wing)
	_fill_rect(img, 24, 15, 6, 2, wing_tip)
	_px(img, 30, 10, wing_tip)

	# Tail feathers
	_fill_rect(img, 13, 21, 6, 3, body)
	_fill_rect(img, 12, 23, 3, 2, wing)
	_fill_rect(img, 17, 23, 3, 2, wing)

	# Feet
	_fill_rect(img, 13, 24, 2, 4, feet)
	_fill_rect(img, 18, 24, 2, 4, feet)
	_line_h(img, 11, 27, 5, feet)
	_line_h(img, 17, 27, 5, feet)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/farm/farm_crow.png")

# ==================== TOKYO ====================

func _gen_tokyo_robot() -> void:
	var img = _img()
	var metal = Color(0.72, 0.75, 0.8)
	var metal_dark = Color(0.5, 0.53, 0.58)
	var metal_light = Color(0.85, 0.88, 0.92)
	var cyan = Color(0.1, 0.85, 0.9)
	var cyan_dim = Color(0.05, 0.5, 0.55)
	var joint = Color(0.4, 0.42, 0.45)
	var outline = Color(0.25, 0.28, 0.32)

	# Head (boxy)
	_fill_rect(img, 10, 3, 12, 10, metal)
	_fill_rect(img, 11, 2, 10, 1, metal_light)
	# Antenna
	_line_v(img, 16, 0, 3, joint)
	_px(img, 16, 0, cyan)

	# LED eyes (cyan glow)
	_fill_rect(img, 12, 6, 3, 3, cyan)
	_fill_rect(img, 18, 6, 3, 3, cyan)
	_px(img, 13, 7, Color(0.7, 1.0, 1.0))
	_px(img, 19, 7, Color(0.7, 1.0, 1.0))

	# Mouth (LED strip)
	_line_h(img, 13, 10, 6, cyan_dim)
	_px(img, 14, 10, cyan)
	_px(img, 17, 10, cyan)

	# Body (boxy torso)
	_fill_rect(img, 9, 13, 14, 10, metal)
	_fill_rect(img, 10, 12, 12, 1, metal_dark)
	# Chest panel
	_fill_rect(img, 12, 15, 8, 5, metal_dark)
	_fill_rect(img, 14, 16, 4, 3, cyan_dim)
	_px(img, 15, 17, cyan)
	_px(img, 17, 17, cyan)

	# Arms (angular)
	_fill_rect(img, 4, 14, 5, 3, metal)
	_fill_rect(img, 3, 17, 4, 4, metal_dark)
	_fill_rect(img, 23, 14, 5, 3, metal)
	_fill_rect(img, 25, 17, 4, 4, metal_dark)
	# Claw hands
	_px(img, 3, 21, joint)
	_px(img, 5, 21, joint)
	_px(img, 26, 21, joint)
	_px(img, 28, 21, joint)

	# Legs
	_fill_rect(img, 11, 23, 4, 5, metal_dark)
	_fill_rect(img, 18, 23, 4, 5, metal_dark)
	_fill_rect(img, 10, 27, 5, 3, metal)
	_fill_rect(img, 17, 27, 5, 3, metal)
	# Knee joints
	_px(img, 12, 24, joint)
	_px(img, 19, 24, joint)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/tokyo/tokyo_robot.png")


func _gen_tokyo_drone() -> void:
	var img = _img()
	var body = Color(0.15, 0.15, 0.18)
	var body_light = Color(0.25, 0.25, 0.3)
	var prop = Color(0.4, 0.42, 0.45)
	var laser = Color(0.9, 0.1, 0.1)
	var led = Color(0.9, 0.15, 0.12)
	var lens = Color(0.2, 0.2, 0.25)
	var outline = Color(0.35, 0.3, 0.3)

	# Central body (flat disc)
	_fill_rect(img, 10, 14, 12, 5, body)
	_fill_rect(img, 12, 13, 8, 1, body_light)
	_fill_rect(img, 12, 19, 8, 1, body)

	# Camera/sensor dome on bottom
	_fill_rect(img, 14, 19, 4, 2, lens)
	_px(img, 15, 20, laser)
	_px(img, 16, 20, laser)

	# Red laser beam
	_line_v(img, 15, 21, 8, Color(0.9, 0.1, 0.1, 0.7))
	_line_v(img, 16, 21, 8, Color(0.9, 0.1, 0.1, 0.5))

	# Propeller arms (4 arms extending from body)
	# Top-left
	_fill_rect(img, 4, 10, 6, 1, prop)
	_fill_rect(img, 3, 8, 4, 2, prop)
	_line_h(img, 1, 8, 6, Color(0.6, 0.6, 0.65))  # blade
	_line_h(img, 2, 9, 4, Color(0.5, 0.5, 0.55))
	# Top-right
	_fill_rect(img, 22, 10, 6, 1, prop)
	_fill_rect(img, 25, 8, 4, 2, prop)
	_line_h(img, 25, 8, 6, Color(0.6, 0.6, 0.65))
	_line_h(img, 26, 9, 4, Color(0.5, 0.5, 0.55))
	# Bottom-left
	_fill_rect(img, 4, 18, 6, 1, prop)
	_fill_rect(img, 3, 19, 4, 2, prop)
	_line_h(img, 1, 19, 6, Color(0.6, 0.6, 0.65))
	# Bottom-right
	_fill_rect(img, 22, 18, 6, 1, prop)
	_fill_rect(img, 25, 19, 4, 2, prop)
	_line_h(img, 25, 19, 6, Color(0.6, 0.6, 0.65))

	# LED indicators
	_px(img, 11, 16, led)
	_px(img, 20, 16, led)
	_px(img, 15, 14, Color(0.1, 0.8, 0.1))  # green indicator

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/tokyo/tokyo_drone.png")


func _gen_tokyo_hacker() -> void:
	var img = _img()
	var hood = Color(0.12, 0.12, 0.15)
	var hood_dark = Color(0.08, 0.08, 0.1)
	var coat = Color(0.15, 0.15, 0.18)
	var coat_dark = Color(0.1, 0.1, 0.12)
	var face_glow = Color(0.1, 0.85, 0.2)
	var face_dim = Color(0.05, 0.4, 0.1)
	var digital = Color(0.15, 1.0, 0.3)
	var outline = Color(0.05, 0.3, 0.08)

	# Hood
	_fill_rect(img, 9, 2, 14, 10, hood)
	_fill_rect(img, 11, 1, 10, 1, hood_dark)
	_fill_rect(img, 8, 5, 2, 5, hood)
	_fill_rect(img, 22, 5, 2, 5, hood)

	# Digital face (green matrix-style)
	_fill_rect(img, 11, 4, 10, 7, Color(0.02, 0.05, 0.02))
	# Green digital pattern
	_px(img, 12, 5, face_dim)
	_px(img, 14, 5, face_dim)
	_px(img, 16, 5, face_dim)
	_px(img, 18, 5, face_dim)
	# Glowing eyes
	_fill_rect(img, 12, 6, 3, 2, face_glow)
	_fill_rect(img, 17, 6, 3, 2, face_glow)
	_px(img, 13, 7, digital)
	_px(img, 18, 7, digital)
	# Digital mouth
	_line_h(img, 13, 9, 6, face_dim)
	_px(img, 14, 9, face_glow)
	_px(img, 17, 9, face_glow)

	# Body (long coat)
	_fill_rect(img, 9, 12, 14, 14, coat)
	_fill_rect(img, 10, 11, 12, 1, coat)
	# Coat folds
	_line_v(img, 16, 14, 10, coat_dark)
	_fill_rect(img, 9, 20, 1, 6, coat_dark)
	_fill_rect(img, 22, 20, 1, 6, coat_dark)

	# Arms
	_fill_rect(img, 4, 13, 5, 3, coat)
	_fill_rect(img, 3, 16, 4, 5, coat_dark)
	_fill_rect(img, 23, 13, 5, 3, coat)
	_fill_rect(img, 25, 16, 4, 5, coat_dark)

	# Hands with green glow (typing)
	_fill_rect(img, 3, 21, 3, 2, face_dim)
	_fill_rect(img, 26, 21, 3, 2, face_dim)

	# Feet (barely visible under coat)
	_fill_rect(img, 10, 26, 4, 3, hood_dark)
	_fill_rect(img, 18, 26, 4, 3, hood_dark)

	# Green digital particles floating
	_px(img, 6, 8, face_dim)
	_px(img, 25, 4, face_dim)
	_px(img, 3, 12, face_glow)
	_px(img, 28, 10, face_glow)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/tokyo/tokyo_hacker.png")


func _gen_tokyo_mecha() -> void:
	var img = _img()
	var armor = Color(0.55, 0.55, 0.6)
	var armor_dark = Color(0.4, 0.4, 0.45)
	var armor_light = Color(0.7, 0.7, 0.75)
	var red = Color(0.85, 0.15, 0.12)
	var red_dark = Color(0.6, 0.1, 0.08)
	var visor = Color(0.1, 0.8, 0.95)
	var joint = Color(0.3, 0.3, 0.35)
	var outline = Color(0.2, 0.2, 0.25)

	# Head (angular helmet)
	_fill_rect(img, 11, 2, 10, 8, armor)
	_fill_rect(img, 10, 4, 12, 4, armor)
	_fill_rect(img, 12, 1, 8, 1, red)
	# V-shaped crest
	_px(img, 14, 1, red)
	_px(img, 13, 2, red)
	_px(img, 18, 1, red)
	_px(img, 19, 2, red)

	# Visor (cyan slit)
	_fill_rect(img, 12, 5, 8, 2, visor)
	_px(img, 13, 5, Color(0.6, 1.0, 1.0))
	_px(img, 18, 5, Color(0.6, 1.0, 1.0))

	# Torso (bulky armor)
	_fill_rect(img, 8, 10, 16, 10, armor)
	_fill_rect(img, 9, 9, 14, 1, armor_dark)
	# Chest plate details
	_fill_rect(img, 10, 12, 5, 4, red)
	_fill_rect(img, 17, 12, 5, 4, red)
	_fill_rect(img, 13, 11, 6, 2, red_dark)
	# Vent/reactor in center
	_fill_rect(img, 14, 14, 4, 3, visor)
	_px(img, 15, 15, Color(0.7, 1.0, 1.0))

	# Shoulder armor (wide)
	_fill_rect(img, 3, 10, 6, 4, armor)
	_fill_rect(img, 4, 9, 4, 1, red)
	_fill_rect(img, 23, 10, 6, 4, armor)
	_fill_rect(img, 24, 9, 4, 1, red)

	# Arms (mechanical)
	_fill_rect(img, 4, 14, 4, 6, armor_dark)
	_fill_rect(img, 24, 14, 4, 6, armor_dark)
	_px(img, 5, 16, joint)
	_px(img, 25, 16, joint)
	# Fists
	_fill_rect(img, 3, 20, 5, 3, armor)
	_fill_rect(img, 24, 20, 5, 3, armor)

	# Legs (heavy)
	_fill_rect(img, 10, 20, 5, 5, armor_dark)
	_fill_rect(img, 17, 20, 5, 5, armor_dark)
	_px(img, 12, 22, joint)
	_px(img, 19, 22, joint)
	# Feet (wide)
	_fill_rect(img, 8, 25, 7, 4, armor)
	_fill_rect(img, 17, 25, 7, 4, armor)
	_fill_rect(img, 9, 28, 5, 2, red_dark)
	_fill_rect(img, 18, 28, 5, 2, red_dark)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/tokyo/tokyo_mecha.png")

# ==================== VOLCANO ====================

func _gen_volcano_imp() -> void:
	var img = _img()
	var skin = Color(0.85, 0.2, 0.12)
	var skin_dark = Color(0.65, 0.12, 0.08)
	var skin_light = Color(0.95, 0.35, 0.2)
	var horn = Color(0.3, 0.15, 0.1)
	var eye = Color(0.95, 0.85, 0.1)
	var fire = Color(1.0, 0.6, 0.1)
	var fire_tip = Color(1.0, 0.9, 0.3)
	var outline = Color(0.35, 0.08, 0.05)

	# Body (small, hunched)
	_circle(img, 16, 18, 6, skin)
	_fill_rect(img, 12, 14, 8, 4, skin)
	_fill_rect(img, 13, 20, 6, 4, skin_dark)

	# Head
	_circle(img, 16, 10, 5, skin)
	_fill_rect(img, 13, 7, 6, 3, skin_light)

	# Horns (curved)
	_px(img, 11, 7, horn)
	_px(img, 10, 6, horn)
	_px(img, 10, 5, horn)
	_px(img, 9, 4, horn)
	_px(img, 21, 7, horn)
	_px(img, 22, 6, horn)
	_px(img, 22, 5, horn)
	_px(img, 23, 4, horn)

	# Yellow eyes (menacing)
	_fill_rect(img, 13, 9, 2, 2, eye)
	_fill_rect(img, 18, 9, 2, 2, eye)
	_px(img, 14, 10, Color(0.1, 0.1, 0.1))
	_px(img, 19, 10, Color(0.1, 0.1, 0.1))

	# Grinning mouth
	_line_h(img, 14, 13, 5, Color(0.15, 0.05, 0.02))
	_px(img, 14, 12, Color(0.95, 0.95, 0.9))  # fang
	_px(img, 18, 12, Color(0.95, 0.95, 0.9))

	# Arms (thin, clawed)
	_fill_rect(img, 6, 14, 4, 2, skin)
	_fill_rect(img, 4, 16, 3, 2, skin_dark)
	_px(img, 3, 17, Color(0.2, 0.1, 0.05))  # claws
	_px(img, 4, 18, Color(0.2, 0.1, 0.05))
	_fill_rect(img, 22, 14, 4, 2, skin)
	_fill_rect(img, 25, 16, 3, 2, skin_dark)
	_px(img, 28, 17, Color(0.2, 0.1, 0.05))
	_px(img, 27, 18, Color(0.2, 0.1, 0.05))

	# Legs (short)
	_fill_rect(img, 11, 24, 4, 4, skin_dark)
	_fill_rect(img, 18, 24, 4, 4, skin_dark)
	_fill_rect(img, 10, 27, 5, 2, skin)
	_fill_rect(img, 17, 27, 5, 2, skin)

	# Tail with fire tip
	_fill_rect(img, 7, 20, 3, 1, skin_dark)
	_fill_rect(img, 5, 19, 2, 1, skin_dark)
	_px(img, 4, 18, fire)
	_px(img, 3, 17, fire_tip)
	_px(img, 4, 17, fire)

	# Fire aura on head
	_px(img, 14, 4, fire)
	_px(img, 16, 3, fire_tip)
	_px(img, 18, 4, fire)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/volcano/volcano_imp.png")


func _gen_volcano_golem() -> void:
	var img = _img()
	var rock = Color(0.4, 0.35, 0.3)
	var rock_dark = Color(0.28, 0.24, 0.2)
	var rock_light = Color(0.55, 0.48, 0.42)
	var lava = Color(1.0, 0.5, 0.05)
	var lava_bright = Color(1.0, 0.8, 0.2)
	var lava_dark = Color(0.8, 0.25, 0.02)
	var eye = Color(1.0, 0.6, 0.1)
	var outline = Color(0.15, 0.12, 0.1)

	# Body (large, blocky)
	_fill_rect(img, 7, 8, 18, 16, rock)
	_fill_rect(img, 9, 6, 14, 2, rock)
	_fill_rect(img, 8, 24, 16, 2, rock_dark)

	# Lava cracks throughout body
	_line_v(img, 12, 10, 8, lava)
	_line_v(img, 20, 12, 6, lava)
	_line_h(img, 14, 16, 6, lava)
	_px(img, 10, 14, lava_bright)
	_px(img, 22, 11, lava_bright)
	_px(img, 16, 20, lava)
	_line_h(img, 9, 22, 4, lava_dark)
	_line_h(img, 19, 22, 4, lava_dark)

	# Head (merged with body, rocky)
	_fill_rect(img, 10, 3, 12, 5, rock)
	_fill_rect(img, 12, 1, 8, 2, rock_dark)
	# Rock protrusions
	_px(img, 11, 2, rock)
	_px(img, 20, 2, rock)

	# Glowing eyes
	_fill_rect(img, 12, 5, 3, 2, eye)
	_fill_rect(img, 18, 5, 3, 2, eye)
	_px(img, 13, 5, lava_bright)
	_px(img, 19, 5, lava_bright)

	# Mouth (lava-filled gap)
	_fill_rect(img, 13, 8, 6, 2, lava_dark)
	_px(img, 14, 8, lava)
	_px(img, 17, 8, lava)

	# Arms (massive rocky)
	_fill_rect(img, 1, 10, 6, 5, rock)
	_fill_rect(img, 2, 15, 5, 5, rock_dark)
	_fill_rect(img, 1, 20, 5, 3, rock)
	_line_v(img, 3, 12, 4, lava)
	_fill_rect(img, 25, 10, 6, 5, rock)
	_fill_rect(img, 25, 15, 5, 5, rock_dark)
	_fill_rect(img, 26, 20, 5, 3, rock)
	_line_v(img, 28, 12, 4, lava)

	# Legs (stumpy)
	_fill_rect(img, 9, 26, 6, 4, rock_dark)
	_fill_rect(img, 17, 26, 6, 4, rock_dark)
	_fill_rect(img, 8, 29, 7, 2, rock)
	_fill_rect(img, 17, 29, 7, 2, rock)
	# Lava in leg cracks
	_px(img, 11, 27, lava)
	_px(img, 20, 27, lava)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/volcano/volcano_golem.png")


func _gen_volcano_hellhound() -> void:
	var img = _img()
	var body = Color(0.12, 0.1, 0.1)
	var body_dark = Color(0.06, 0.05, 0.05)
	var fire = Color(1.0, 0.5, 0.05)
	var fire_bright = Color(1.0, 0.8, 0.2)
	var fire_dark = Color(0.85, 0.3, 0.02)
	var eye = Color(0.95, 0.3, 0.05)
	var teeth = Color(0.95, 0.95, 0.9)
	var outline = Color(0.35, 0.15, 0.05)

	# Body (lean, aggressive)
	_fill_rect(img, 6, 14, 18, 7, body)
	_fill_rect(img, 8, 12, 14, 2, body)
	_fill_rect(img, 7, 21, 16, 2, body_dark)

	# Head (angular, wolf-like)
	_fill_rect(img, 19, 8, 8, 6, body)
	_fill_rect(img, 21, 6, 4, 2, body)
	_fill_rect(img, 23, 14, 5, 3, body)  # jaw

	# Fire mane (along back and head)
	_fill_rect(img, 10, 10, 4, 3, fire)
	_fill_rect(img, 14, 9, 4, 3, fire)
	_fill_rect(img, 18, 8, 3, 2, fire)
	_px(img, 11, 9, fire_bright)
	_px(img, 15, 8, fire_bright)
	_px(img, 12, 8, fire_bright)
	_px(img, 16, 7, fire_bright)
	_px(img, 19, 7, fire_bright)
	# Fire tips
	_px(img, 10, 8, fire_dark)
	_px(img, 13, 7, fire_bright)
	_px(img, 17, 6, fire_bright)

	# Ears
	_px(img, 21, 5, body)
	_px(img, 25, 5, body)
	_px(img, 21, 4, fire_dark)
	_px(img, 25, 4, fire_dark)

	# Glowing eyes
	_fill_rect(img, 21, 9, 2, 2, eye)
	_fill_rect(img, 25, 9, 2, 2, eye)
	_px(img, 21, 9, Color(1.0, 0.6, 0.1))
	_px(img, 25, 9, Color(1.0, 0.6, 0.1))

	# Open mouth with teeth
	_fill_rect(img, 24, 13, 5, 1, Color(0.4, 0.05, 0.02))
	_px(img, 24, 13, teeth)
	_px(img, 26, 13, teeth)
	_px(img, 28, 13, teeth)
	_px(img, 25, 14, Color(0.4, 0.05, 0.02))

	# Legs (4)
	_fill_rect(img, 8, 23, 3, 5, body_dark)
	_fill_rect(img, 13, 23, 3, 5, body_dark)
	_fill_rect(img, 19, 23, 3, 5, body_dark)
	# Paws with fire
	_fill_rect(img, 7, 27, 4, 2, body)
	_fill_rect(img, 12, 27, 4, 2, body)
	_fill_rect(img, 18, 27, 4, 2, body)
	_px(img, 7, 27, fire_dark)
	_px(img, 12, 27, fire_dark)
	_px(img, 18, 27, fire_dark)

	# Fire tail
	_fill_rect(img, 3, 13, 3, 2, fire)
	_fill_rect(img, 1, 12, 3, 2, fire_bright)
	_px(img, 0, 11, fire_bright)
	_px(img, 1, 10, fire_dark)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/volcano/volcano_hellhound.png")


func _gen_volcano_magma_slime() -> void:
	var img = _img()
	var body = Color(0.9, 0.4, 0.05)
	var body_dark = Color(0.7, 0.2, 0.02)
	var body_light = Color(1.0, 0.6, 0.15)
	var lava = Color(1.0, 0.8, 0.2)
	var bubble = Color(1.0, 0.9, 0.4)
	var eye = Color(0.95, 0.95, 0.9)
	var pupil = Color(0.1, 0.05, 0.02)
	var outline = Color(0.5, 0.15, 0.02)

	# Blob body (rounded, oozing)
	_fill_rect(img, 8, 10, 16, 4, body)
	_fill_rect(img, 6, 14, 20, 6, body)
	_fill_rect(img, 5, 18, 22, 4, body)
	_fill_rect(img, 7, 22, 18, 3, body_dark)
	_fill_rect(img, 9, 25, 14, 2, body_dark)
	_fill_rect(img, 10, 8, 12, 2, body)
	_fill_rect(img, 12, 6, 8, 2, body_light)

	# Highlight on top
	_fill_rect(img, 10, 8, 5, 3, body_light)
	_fill_rect(img, 12, 7, 3, 2, lava)

	# Bubbles (popping on surface)
	_circle(img, 20, 12, 2, bubble)
	_px(img, 20, 11, Color(1.0, 1.0, 0.8))
	_circle(img, 9, 16, 1, bubble)
	_px(img, 22, 18, bubble)
	_px(img, 11, 20, bubble)
	_px(img, 18, 22, bubble)

	# Dark lava swirls
	_px(img, 14, 15, body_dark)
	_px(img, 15, 16, body_dark)
	_px(img, 16, 15, body_dark)
	_px(img, 18, 18, body_dark)
	_px(img, 10, 19, body_dark)

	# Eyes
	_fill_rect(img, 11, 13, 3, 3, eye)
	_fill_rect(img, 18, 13, 3, 3, eye)
	_fill_rect(img, 12, 14, 2, 2, pupil)
	_fill_rect(img, 19, 14, 2, 2, pupil)

	# Dripping bits on sides
	_fill_rect(img, 4, 20, 2, 3, body)
	_px(img, 4, 23, body_dark)
	_fill_rect(img, 26, 19, 2, 3, body)
	_px(img, 26, 22, body_dark)

	# Bottom ooze
	_px(img, 8, 26, body_dark)
	_px(img, 14, 27, body_dark)
	_px(img, 20, 26, body_dark)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/volcano/volcano_magma_slime.png")

# ==================== OCEAN ====================

func _gen_ocean_crab() -> void:
	var img = _img()
	var shell = Color(0.85, 0.35, 0.15)
	var shell_dark = Color(0.65, 0.22, 0.08)
	var shell_light = Color(0.95, 0.5, 0.25)
	var claw = Color(0.9, 0.4, 0.18)
	var eye_stalk = Color(0.7, 0.3, 0.12)
	var eye = Color(0.1, 0.1, 0.1)
	var belly = Color(0.95, 0.8, 0.6)
	var outline = Color(0.4, 0.15, 0.05)

	# Shell (wide oval)
	_fill_rect(img, 7, 12, 18, 8, shell)
	_fill_rect(img, 9, 10, 14, 2, shell)
	_fill_rect(img, 8, 20, 16, 2, shell_dark)
	# Highlight
	_fill_rect(img, 11, 11, 6, 3, shell_light)

	# Belly
	_fill_rect(img, 11, 16, 10, 4, belly)

	# Eye stalks
	_fill_rect(img, 11, 7, 2, 3, eye_stalk)
	_fill_rect(img, 19, 7, 2, 3, eye_stalk)
	# Eyes
	_circle(img, 12, 6, 2, eye_stalk)
	_circle(img, 20, 6, 2, eye_stalk)
	_px(img, 12, 5, eye)
	_px(img, 20, 5, eye)

	# Big claws
	# Left claw
	_fill_rect(img, 1, 10, 6, 4, claw)
	_fill_rect(img, 0, 12, 4, 2, shell_dark)
	_fill_rect(img, 0, 8, 4, 3, claw)
	_px(img, 0, 8, shell_light)
	_fill_rect(img, 4, 7, 2, 2, claw)
	# Right claw
	_fill_rect(img, 25, 10, 6, 4, claw)
	_fill_rect(img, 28, 12, 4, 2, shell_dark)
	_fill_rect(img, 28, 8, 4, 3, claw)
	_px(img, 31, 8, shell_light)
	_fill_rect(img, 26, 7, 2, 2, claw)

	# Legs (6 legs, 3 per side)
	# Left legs
	_fill_rect(img, 4, 14, 3, 1, shell_dark)
	_px(img, 3, 15, shell_dark)
	_px(img, 2, 16, shell_dark)
	_fill_rect(img, 4, 17, 3, 1, shell_dark)
	_px(img, 3, 18, shell_dark)
	_px(img, 2, 19, shell_dark)
	_fill_rect(img, 5, 20, 3, 1, shell_dark)
	_px(img, 4, 21, shell_dark)
	_px(img, 3, 22, shell_dark)
	# Right legs
	_fill_rect(img, 25, 14, 3, 1, shell_dark)
	_px(img, 28, 15, shell_dark)
	_px(img, 29, 16, shell_dark)
	_fill_rect(img, 25, 17, 3, 1, shell_dark)
	_px(img, 28, 18, shell_dark)
	_px(img, 29, 19, shell_dark)
	_fill_rect(img, 24, 20, 3, 1, shell_dark)
	_px(img, 27, 21, shell_dark)
	_px(img, 28, 22, shell_dark)

	# Mouth
	_line_h(img, 14, 18, 4, Color(0.3, 0.1, 0.05))

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/ocean/ocean_crab.png")


func _gen_ocean_fish() -> void:
	var img = _img()
	var body = Color(0.2, 0.22, 0.3)
	var body_dark = Color(0.12, 0.14, 0.2)
	var body_light = Color(0.3, 0.32, 0.4)
	var belly = Color(0.45, 0.5, 0.55)
	var eye = Color(0.95, 0.95, 0.9)
	var pupil = Color(0.1, 0.1, 0.1)
	var teeth = Color(0.95, 0.95, 0.9)
	var lantern = Color(0.3, 0.9, 1.0)
	var lantern_glow = Color(0.5, 1.0, 1.0)
	var outline = Color(0.06, 0.08, 0.12)

	# Body (wide oval, anglerfish shape)
	_fill_rect(img, 6, 12, 18, 10, body)
	_fill_rect(img, 8, 10, 14, 2, body)
	_fill_rect(img, 7, 22, 16, 2, body_dark)
	_fill_rect(img, 10, 8, 10, 2, body)

	# Belly (lighter underside)
	_fill_rect(img, 9, 18, 12, 5, belly)

	# Head highlight
	_fill_rect(img, 8, 11, 6, 4, body_light)

	# Large eye
	_fill_rect(img, 9, 13, 4, 4, eye)
	_fill_rect(img, 10, 14, 3, 3, pupil)
	_px(img, 10, 14, Color(0.2, 0.2, 0.2))

	# Wide jaw with teeth
	_fill_rect(img, 7, 17, 14, 1, Color(0.08, 0.06, 0.1))
	_px(img, 8, 16, teeth)
	_px(img, 10, 16, teeth)
	_px(img, 12, 16, teeth)
	_px(img, 14, 16, teeth)
	_px(img, 16, 16, teeth)
	_px(img, 18, 16, teeth)
	_px(img, 9, 18, teeth)
	_px(img, 11, 18, teeth)
	_px(img, 13, 18, teeth)
	_px(img, 15, 18, teeth)
	_px(img, 17, 18, teeth)

	# Lantern (angler lure)
	_line_v(img, 14, 4, 4, body_dark)
	_px(img, 13, 5, body_dark)
	_px(img, 12, 6, body_dark)
	_circle(img, 12, 3, 2, lantern)
	_px(img, 12, 3, lantern_glow)
	# Glow effect
	_px(img, 10, 2, Color(0.2, 0.6, 0.7, 0.5))
	_px(img, 14, 2, Color(0.2, 0.6, 0.7, 0.5))
	_px(img, 12, 1, Color(0.2, 0.6, 0.7, 0.5))

	# Tail fin
	_fill_rect(img, 24, 12, 4, 3, body)
	_fill_rect(img, 26, 10, 4, 3, body_dark)
	_fill_rect(img, 26, 17, 4, 3, body_dark)
	_fill_rect(img, 28, 13, 3, 4, body)

	# Dorsal fin
	_fill_rect(img, 16, 8, 5, 2, body_dark)
	_px(img, 18, 7, body_dark)

	# Pectoral fin
	_fill_rect(img, 14, 22, 4, 2, body_dark)
	_px(img, 15, 24, body_dark)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/ocean/ocean_fish.png")


func _gen_ocean_urchin() -> void:
	var img = _img()
	var body = Color(0.45, 0.18, 0.55)
	var body_dark = Color(0.32, 0.1, 0.4)
	var body_light = Color(0.6, 0.3, 0.7)
	var spine = Color(0.35, 0.12, 0.45)
	var spine_tip = Color(0.55, 0.25, 0.65)
	var eye = Color(0.9, 0.85, 0.1)
	var outline = Color(0.2, 0.08, 0.28)

	# Body (round, spiky)
	_circle(img, 16, 16, 7, body)
	_fill_rect(img, 12, 12, 8, 4, body_light)
	_fill_rect(img, 13, 20, 6, 3, body_dark)

	# Spines radiating outward (all directions)
	# Top spines
	_line_v(img, 16, 2, 5, spine)
	_px(img, 16, 2, spine_tip)
	_line_v(img, 13, 3, 4, spine)
	_px(img, 13, 3, spine_tip)
	_line_v(img, 19, 3, 4, spine)
	_px(img, 19, 3, spine_tip)
	# Top-left diagonal
	_px(img, 10, 5, spine)
	_px(img, 9, 4, spine)
	_px(img, 8, 3, spine_tip)
	# Top-right diagonal
	_px(img, 22, 5, spine)
	_px(img, 23, 4, spine)
	_px(img, 24, 3, spine_tip)
	# Left spines
	_line_h(img, 3, 16, 5, spine)
	_px(img, 3, 16, spine_tip)
	_line_h(img, 4, 13, 4, spine)
	_px(img, 4, 13, spine_tip)
	_line_h(img, 4, 19, 4, spine)
	_px(img, 4, 19, spine_tip)
	# Right spines
	_line_h(img, 24, 16, 5, spine)
	_px(img, 28, 16, spine_tip)
	_line_h(img, 24, 13, 4, spine)
	_px(img, 27, 13, spine_tip)
	_line_h(img, 24, 19, 4, spine)
	_px(img, 27, 19, spine_tip)
	# Bottom spines
	_line_v(img, 16, 24, 5, spine)
	_px(img, 16, 28, spine_tip)
	_line_v(img, 13, 23, 4, spine)
	_px(img, 13, 26, spine_tip)
	_line_v(img, 19, 23, 4, spine)
	_px(img, 19, 26, spine_tip)
	# Bottom-left diagonal
	_px(img, 10, 24, spine)
	_px(img, 9, 25, spine)
	_px(img, 8, 26, spine_tip)
	# Bottom-right diagonal
	_px(img, 22, 24, spine)
	_px(img, 23, 25, spine)
	_px(img, 24, 26, spine_tip)

	# Small eyes
	_fill_rect(img, 13, 14, 2, 2, eye)
	_fill_rect(img, 18, 14, 2, 2, eye)
	_px(img, 14, 15, Color(0.1, 0.1, 0.1))
	_px(img, 19, 15, Color(0.1, 0.1, 0.1))

	# Small mouth
	_line_h(img, 15, 18, 3, body_dark)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/ocean/ocean_urchin.png")


func _gen_ocean_squid() -> void:
	var img = _img()
	var body = Color(0.35, 0.2, 0.6)
	var body_dark = Color(0.25, 0.12, 0.45)
	var body_light = Color(0.5, 0.35, 0.75)
	var tentacle = Color(0.4, 0.25, 0.65)
	var tentacle_light = Color(0.55, 0.4, 0.8)
	var sucker = Color(0.65, 0.5, 0.85)
	var eye = Color(0.95, 0.9, 0.85)
	var pupil = Color(0.1, 0.08, 0.15)
	var outline = Color(0.15, 0.08, 0.3)

	# Mantle (elongated head/body)
	_fill_rect(img, 11, 2, 10, 12, body)
	_fill_rect(img, 10, 4, 12, 8, body)
	_fill_rect(img, 13, 1, 6, 2, body_light)
	# Highlight
	_fill_rect(img, 12, 3, 4, 4, body_light)

	# Eyes (large, expressive)
	_fill_rect(img, 11, 8, 3, 4, eye)
	_fill_rect(img, 18, 8, 3, 4, eye)
	_fill_rect(img, 12, 9, 2, 3, pupil)
	_fill_rect(img, 19, 9, 2, 3, pupil)

	# Fins (side flaps)
	_fill_rect(img, 6, 4, 4, 4, body_light)
	_fill_rect(img, 7, 3, 2, 1, body)
	_fill_rect(img, 22, 4, 4, 4, body_light)
	_fill_rect(img, 23, 3, 2, 1, body)

	# Tentacles (8 flowing down)
	# Center tentacles
	_line_v(img, 12, 14, 8, tentacle)
	_px(img, 11, 20, tentacle)
	_px(img, 11, 22, tentacle)
	_line_v(img, 14, 14, 9, tentacle)
	_px(img, 13, 23, tentacle)
	_line_v(img, 16, 14, 10, tentacle)
	_line_v(img, 18, 14, 9, tentacle)
	_px(img, 19, 23, tentacle)
	_line_v(img, 20, 14, 8, tentacle)
	_px(img, 21, 20, tentacle)
	_px(img, 21, 22, tentacle)
	# Outer tentacles (curving outward)
	_line_v(img, 10, 14, 6, tentacle)
	_px(img, 9, 19, tentacle)
	_px(img, 8, 20, tentacle)
	_px(img, 7, 21, tentacle)
	_line_v(img, 22, 14, 6, tentacle)
	_px(img, 23, 19, tentacle)
	_px(img, 24, 20, tentacle)
	_px(img, 25, 21, tentacle)

	# Suckers on tentacles
	_px(img, 12, 16, sucker)
	_px(img, 14, 18, sucker)
	_px(img, 16, 17, sucker)
	_px(img, 18, 16, sucker)
	_px(img, 20, 18, sucker)
	_px(img, 16, 20, sucker)
	_px(img, 14, 21, sucker)
	_px(img, 18, 21, sucker)

	# Darkening on lower body
	_fill_rect(img, 11, 12, 10, 2, body_dark)

	_add_outline(img, outline)
	_save(img, "res://assets/sprites/enemies/ocean/ocean_squid.png")
