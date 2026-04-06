extends SceneTree

## Generates hand-crafted pixel art sprites for all 20 alternative bosses at 64x64.
## Run: godot --headless --path game --script res://scripts/tools/alt_boss_sprite_gen.gd

const S := 64
const OUT := "res://assets/sprites/bosses/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_generate_cemetery_lich()
	_generate_cemetery_reaper()
	_generate_forest_elder()
	_generate_forest_spider()
	_generate_farm_scarecrow()
	_generate_farm_harvester()
	_generate_tokyo_shogun()
	_generate_tokyo_kaiju()
	_generate_volcano_phoenix()
	_generate_volcano_titan()
	_generate_ocean_siren()
	_generate_ocean_hydra()
	_generate_arena_minotaur()
	_generate_arena_chimera()
	_generate_space_hivemind()
	_generate_space_warden()
	_generate_castle_werewolf()
	_generate_castle_banshee()
	_generate_candy_witch()
	_generate_candy_dragon()
	print("Generated 20 alt boss sprites!")
	quit()

# ==================== HELPERS ====================
func _fill(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for px in range(maxi(x, 0), mini(x + w, S)):
		for py in range(maxi(y, 0), mini(y + h, S)):
			img.set_pixel(px, py, c)

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and x < S and y >= 0 and y < S:
		img.set_pixel(x, y, c)

func _circle(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for x in range(cx - r, cx + r + 1):
		for y in range(cy - r, cy + r + 1):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				_px(img, x, y, c)

func _line_h(img: Image, x1: int, x2: int, y: int, c: Color) -> void:
	for x in range(x1, x2 + 1):
		_px(img, x, y, c)

func _line_v(img: Image, x: int, y1: int, y2: int, c: Color) -> void:
	for y in range(y1, y2 + 1):
		_px(img, x, y, c)

func _outline(img: Image, color: Color) -> void:
	var copy = img.duplicate()
	for x in range(S):
		for y in range(S):
			if copy.get_pixel(x, y).a > 0:
				for d in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
					var nx = x + d.x
					var ny = y + d.y
					if nx >= 0 and nx < S and ny >= 0 and ny < S and copy.get_pixel(nx, ny).a == 0:
						img.set_pixel(nx, ny, color)

func _save(img: Image, filename: String) -> void:
	img.save_png(OUT + filename)
	print("Saved: %s%s" % [OUT, filename])

# ==================== CEMETERY LICH ====================
func _generate_cemetery_lich() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var robe = Color(0.15, 0.38, 0.15)
	var robe_dk = Color(0.08, 0.25, 0.08)
	var robe_lt = Color(0.22, 0.50, 0.22)
	var bone = Color(0.85, 0.82, 0.72)
	var bone_dk = Color(0.65, 0.60, 0.50)
	var eye = Color(0.3, 1.0, 0.3)
	var eye_br = Color(0.6, 1.0, 0.6)
	var crown = Color(0.85, 0.75, 0.2)
	var crown_dk = Color(0.65, 0.55, 0.12)
	var gem = Color(0.3, 0.9, 0.3)
	var aura = Color(0.2, 0.8, 0.2, 0.3)
	var ol = Color(0.05, 0.15, 0.05)

	# Ghostly aura
	_circle(img, 32, 32, 28, aura)
	_circle(img, 32, 30, 22, Color(0.2, 0.7, 0.2, 0.2))

	# Crown
	_fill(img, 20, 2, 24, 4, crown_dk)
	_fill(img, 22, 0, 20, 3, crown)
	# Crown points
	for i in range(5):
		_px(img, 23 + i * 4, 0, crown)
		_px(img, 23 + i * 4, -1 if i % 2 == 0 else 0, crown)
	# Crown gem
	_fill(img, 30, 1, 4, 3, gem)
	_px(img, 31, 2, eye_br)

	# Skull head
	_fill(img, 22, 6, 20, 14, bone)
	_fill(img, 24, 5, 16, 2, bone)
	_fill(img, 20, 10, 24, 8, bone)
	# Skull shading
	_fill(img, 22, 6, 4, 4, bone_dk)
	_fill(img, 38, 6, 4, 4, bone_dk)

	# Eye sockets (dark holes with glow)
	_fill(img, 25, 10, 5, 5, Color(0.05, 0.05, 0.05))
	_fill(img, 34, 10, 5, 5, Color(0.05, 0.05, 0.05))
	# Glowing pupils
	_fill(img, 26, 11, 3, 3, eye)
	_fill(img, 35, 11, 3, 3, eye)
	_px(img, 27, 12, eye_br)
	_px(img, 36, 12, eye_br)

	# Nose hole
	_fill(img, 30, 15, 2, 3, bone_dk)
	_fill(img, 32, 15, 2, 3, bone_dk)

	# Teeth
	_fill(img, 26, 18, 12, 2, bone)
	for i in range(6):
		_px(img, 27 + i * 2, 20, bone)
		_px(img, 27 + i * 2, 19, bone_dk)

	# Robes - flowing shape
	_fill(img, 18, 20, 28, 6, robe)
	_fill(img, 15, 26, 34, 6, robe)
	_fill(img, 13, 32, 38, 6, robe_dk)
	_fill(img, 11, 38, 42, 8, robe)
	_fill(img, 12, 46, 40, 6, robe_dk)
	_fill(img, 14, 52, 36, 6, robe)
	_fill(img, 16, 58, 32, 5, robe_dk)

	# Robe highlights
	_fill(img, 22, 28, 3, 16, robe_lt)
	_fill(img, 38, 30, 3, 14, robe_lt)
	_fill(img, 30, 48, 4, 10, robe_lt)

	# Skeletal hands
	_fill(img, 11, 32, 4, 6, bone)
	_fill(img, 49, 32, 4, 6, bone)
	# Fingers
	_px(img, 10, 38, bone)
	_px(img, 12, 38, bone)
	_px(img, 50, 38, bone)
	_px(img, 52, 38, bone)

	# Tattered bottom edges
	for i in range(8):
		var bx = 16 + i * 4
		_fill(img, bx, 62, 2, 1, robe_dk)

	_outline(img, ol)
	_save(img, "cemetery_lich.png")

# ==================== CEMETERY REAPER ====================
func _generate_cemetery_reaper() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var cloak = Color(0.06, 0.06, 0.08)
	var cloak_dk = Color(0.03, 0.03, 0.05)
	var cloak_lt = Color(0.12, 0.12, 0.15)
	var red = Color(0.7, 0.08, 0.08)
	var red_br = Color(0.95, 0.15, 0.15)
	var scythe_blade = Color(0.7, 0.72, 0.75)
	var scythe_dk = Color(0.5, 0.52, 0.55)
	var staff_c = Color(0.35, 0.25, 0.18)
	var staff_dk = Color(0.22, 0.15, 0.10)
	var bone = Color(0.82, 0.78, 0.68)
	var shadow = Color(0.04, 0.04, 0.06, 0.5)
	var ol = Color(0.02, 0.02, 0.04)

	# Shadow beneath
	_circle(img, 32, 58, 14, shadow)

	# Hood - pointed shape
	_fill(img, 22, 8, 20, 4, cloak)
	_fill(img, 20, 12, 24, 6, cloak)
	_fill(img, 19, 14, 26, 4, cloak_dk)
	# Hood peak
	_fill(img, 28, 4, 8, 4, cloak)
	_fill(img, 30, 2, 4, 3, cloak)
	_fill(img, 31, 1, 2, 2, cloak_dk)

	# Hood interior (dark)
	_fill(img, 24, 12, 16, 6, Color(0.02, 0.02, 0.03))

	# Glowing red eyes inside hood
	_fill(img, 26, 14, 4, 2, red)
	_fill(img, 34, 14, 4, 2, red)
	_px(img, 27, 14, red_br)
	_px(img, 35, 14, red_br)

	# Cloak body (flowing)
	_fill(img, 18, 18, 28, 6, cloak)
	_fill(img, 16, 24, 32, 6, cloak_dk)
	_fill(img, 14, 30, 36, 8, cloak)
	_fill(img, 13, 38, 38, 8, cloak_dk)
	_fill(img, 12, 46, 40, 6, cloak)
	_fill(img, 14, 52, 36, 6, cloak_dk)
	_fill(img, 16, 58, 32, 5, cloak)

	# Cloak highlights (folds)
	_fill(img, 22, 26, 2, 18, cloak_lt)
	_fill(img, 40, 28, 2, 16, cloak_lt)
	_fill(img, 30, 50, 3, 8, cloak_lt)

	# Skeletal hands reaching out
	_fill(img, 12, 30, 5, 4, bone)
	_fill(img, 11, 34, 3, 2, bone)
	_fill(img, 14, 34, 2, 2, bone)

	# Scythe staff (left side going up)
	_fill(img, 8, 4, 3, 52, staff_c)
	_fill(img, 7, 6, 1, 48, staff_dk)

	# Scythe blade (curved, top)
	_fill(img, 8, 2, 16, 3, scythe_blade)
	_fill(img, 20, 4, 6, 2, scythe_blade)
	_fill(img, 24, 5, 4, 2, scythe_dk)
	_fill(img, 26, 7, 3, 2, scythe_dk)
	_fill(img, 10, 1, 12, 1, scythe_dk)
	# Blade edge highlight
	_line_h(img, 10, 22, 2, Color(0.85, 0.87, 0.9))

	# Tattered bottom
	for i in range(8):
		var bx = 16 + i * 4
		_fill(img, bx, 62, 2, 1 + (i % 2), cloak_dk)

	_outline(img, ol)
	_save(img, "cemetery_reaper.png")

# ==================== FOREST ELDER ====================
func _generate_forest_elder() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var bark = Color(0.35, 0.25, 0.15)
	var bark_dk = Color(0.22, 0.15, 0.08)
	var bark_lt = Color(0.48, 0.35, 0.22)
	var leaf = Color(0.18, 0.55, 0.12)
	var leaf_lt = Color(0.3, 0.7, 0.2)
	var leaf_dk = Color(0.1, 0.38, 0.06)
	var eye = Color(0.9, 0.8, 0.2)
	var eye_br = Color(1.0, 0.95, 0.5)
	var moss = Color(0.2, 0.45, 0.15)
	var ol = Color(0.1, 0.08, 0.04)

	# Canopy (tree crown - leaves)
	_circle(img, 32, 10, 16, leaf_dk)
	_circle(img, 32, 8, 14, leaf)
	_circle(img, 24, 6, 8, leaf)
	_circle(img, 40, 6, 8, leaf)
	_circle(img, 32, 4, 10, leaf_lt)
	# Leaf highlights
	_circle(img, 28, 4, 5, leaf_lt)
	_circle(img, 38, 5, 4, leaf_lt)
	_fill(img, 20, 2, 3, 2, leaf_dk)
	_fill(img, 40, 3, 3, 2, leaf_dk)

	# Main trunk body (wide, gnarled)
	_fill(img, 20, 18, 24, 8, bark)
	_fill(img, 18, 26, 28, 8, bark)
	_fill(img, 16, 34, 32, 8, bark_dk)
	_fill(img, 18, 42, 28, 8, bark)
	_fill(img, 20, 50, 24, 8, bark_dk)

	# Bark texture (vertical lines)
	_line_v(img, 24, 20, 56, bark_dk)
	_line_v(img, 30, 22, 54, bark_lt)
	_line_v(img, 36, 20, 56, bark_dk)
	_line_v(img, 40, 24, 52, bark_lt)

	# Face in bark
	# Eyes (glowing amber)
	_fill(img, 23, 24, 5, 4, Color(0.1, 0.08, 0.05))
	_fill(img, 36, 24, 5, 4, Color(0.1, 0.08, 0.05))
	_fill(img, 24, 25, 3, 2, eye)
	_fill(img, 37, 25, 3, 2, eye)
	_px(img, 25, 25, eye_br)
	_px(img, 38, 25, eye_br)

	# Mouth (dark hollow in bark)
	_fill(img, 27, 32, 10, 4, Color(0.08, 0.05, 0.02))
	_fill(img, 28, 31, 8, 1, bark_dk)
	_fill(img, 28, 36, 8, 1, bark_dk)

	# Branch arms
	_fill(img, 8, 22, 10, 4, bark)
	_fill(img, 4, 20, 6, 3, bark_dk)
	_fill(img, 2, 18, 4, 3, bark)
	_fill(img, 46, 22, 10, 4, bark)
	_fill(img, 54, 20, 6, 3, bark_dk)
	_fill(img, 58, 18, 4, 3, bark)

	# Leaves on branches
	_circle(img, 4, 17, 4, leaf)
	_circle(img, 60, 17, 4, leaf)
	_circle(img, 6, 15, 3, leaf_lt)
	_circle(img, 58, 15, 3, leaf_lt)

	# Roots at bottom
	_fill(img, 14, 56, 6, 6, bark_dk)
	_fill(img, 44, 56, 6, 6, bark_dk)
	_fill(img, 10, 58, 6, 4, bark)
	_fill(img, 48, 58, 6, 4, bark)

	# Moss patches
	_fill(img, 18, 30, 4, 2, moss)
	_fill(img, 40, 36, 5, 2, moss)
	_fill(img, 22, 48, 3, 2, moss)

	_outline(img, ol)
	_save(img, "forest_elder.png")

# ==================== FOREST SPIDER ====================
func _generate_forest_spider() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var body = Color(0.28, 0.08, 0.35)
	var body_dk = Color(0.18, 0.04, 0.22)
	var body_lt = Color(0.42, 0.18, 0.50)
	var leg = Color(0.35, 0.12, 0.42)
	var leg_dk = Color(0.22, 0.06, 0.28)
	var eye = Color(0.7, 0.15, 0.8)
	var eye_br = Color(0.9, 0.4, 1.0)
	var fang = Color(0.85, 0.82, 0.75)
	var mark = Color(0.8, 0.2, 0.9)
	var web = Color(0.9, 0.9, 0.92, 0.5)
	var ol = Color(0.1, 0.02, 0.12)

	# Abdomen (large, back)
	_circle(img, 32, 42, 14, body_dk)
	_circle(img, 32, 40, 12, body)
	_circle(img, 32, 38, 8, body_lt)

	# Abdomen markings (hourglass)
	_fill(img, 30, 36, 4, 2, mark)
	_fill(img, 29, 38, 6, 1, mark)
	_fill(img, 30, 39, 4, 2, mark)
	_fill(img, 29, 42, 6, 1, mark)
	_fill(img, 30, 43, 4, 2, mark)

	# Cephalothorax (front section)
	_circle(img, 32, 24, 10, body)
	_circle(img, 32, 22, 8, body_lt)

	# Eight eyes (4 pairs, different sizes)
	# Main pair (large)
	_fill(img, 26, 18, 4, 4, Color(0.05, 0.02, 0.06))
	_fill(img, 34, 18, 4, 4, Color(0.05, 0.02, 0.06))
	_fill(img, 27, 19, 2, 2, eye)
	_fill(img, 35, 19, 2, 2, eye)
	_px(img, 27, 19, eye_br)
	_px(img, 35, 19, eye_br)
	# Secondary pair
	_fill(img, 23, 16, 2, 2, eye)
	_fill(img, 39, 16, 2, 2, eye)
	# Third pair (small)
	_px(img, 25, 15, eye)
	_px(img, 38, 15, eye)
	# Fourth pair (tiny)
	_px(img, 30, 16, eye)
	_px(img, 34, 16, eye)

	# Fangs (chelicerae)
	_fill(img, 28, 26, 2, 5, fang)
	_fill(img, 34, 26, 2, 5, fang)
	_px(img, 28, 30, Color(0.65, 0.6, 0.5))
	_px(img, 35, 30, Color(0.65, 0.6, 0.5))

	# Legs (4 pairs, segmented)
	# Front left legs
	_fill(img, 18, 18, 6, 2, leg)
	_fill(img, 12, 16, 6, 2, leg_dk)
	_fill(img, 6, 14, 6, 2, leg)
	_fill(img, 4, 16, 3, 2, leg_dk)
	# Second left
	_fill(img, 16, 24, 6, 2, leg)
	_fill(img, 10, 22, 6, 2, leg_dk)
	_fill(img, 4, 24, 6, 2, leg)
	_fill(img, 2, 26, 3, 2, leg_dk)
	# Third left
	_fill(img, 16, 30, 6, 2, leg)
	_fill(img, 10, 32, 6, 2, leg_dk)
	_fill(img, 4, 34, 6, 2, leg)
	_fill(img, 2, 36, 3, 2, leg_dk)
	# Back left
	_fill(img, 18, 38, 6, 2, leg)
	_fill(img, 12, 40, 6, 2, leg_dk)
	_fill(img, 6, 42, 6, 2, leg)
	_fill(img, 4, 44, 3, 2, leg_dk)

	# Front right legs
	_fill(img, 40, 18, 6, 2, leg)
	_fill(img, 46, 16, 6, 2, leg_dk)
	_fill(img, 52, 14, 6, 2, leg)
	_fill(img, 57, 16, 3, 2, leg_dk)
	# Second right
	_fill(img, 42, 24, 6, 2, leg)
	_fill(img, 48, 22, 6, 2, leg_dk)
	_fill(img, 54, 24, 6, 2, leg)
	_fill(img, 59, 26, 3, 2, leg_dk)
	# Third right
	_fill(img, 42, 30, 6, 2, leg)
	_fill(img, 48, 32, 6, 2, leg_dk)
	_fill(img, 54, 34, 6, 2, leg)
	_fill(img, 59, 36, 3, 2, leg_dk)
	# Back right
	_fill(img, 40, 38, 6, 2, leg)
	_fill(img, 46, 40, 6, 2, leg_dk)
	_fill(img, 52, 42, 6, 2, leg)
	_fill(img, 57, 44, 3, 2, leg_dk)

	# Web strands
	_px(img, 3, 13, web)
	_px(img, 60, 13, web)
	_px(img, 1, 25, web)
	_px(img, 62, 25, web)

	_outline(img, ol)
	_save(img, "forest_spider.png")

# ==================== FARM SCARECROW ====================
func _generate_farm_scarecrow() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var cloth = Color(0.55, 0.38, 0.15)
	var cloth_dk = Color(0.40, 0.25, 0.08)
	var cloth_lt = Color(0.68, 0.50, 0.25)
	var straw = Color(0.85, 0.75, 0.30)
	var straw_dk = Color(0.70, 0.60, 0.20)
	var hat = Color(0.35, 0.22, 0.10)
	var hat_dk = Color(0.22, 0.14, 0.06)
	var eye = Color(0.9, 0.5, 0.0)
	var eye_br = Color(1.0, 0.7, 0.2)
	var wood = Color(0.45, 0.30, 0.18)
	var wood_dk = Color(0.32, 0.20, 0.10)
	var patch = Color(0.3, 0.45, 0.2)
	var ol = Color(0.15, 0.10, 0.04)

	# Hat brim
	_fill(img, 16, 8, 32, 4, hat)
	_fill(img, 14, 10, 36, 2, hat_dk)

	# Hat top
	_fill(img, 22, 0, 20, 8, hat)
	_fill(img, 24, 0, 16, 2, hat_dk)
	_fill(img, 23, 2, 18, 4, hat)
	# Hat band
	_fill(img, 22, 6, 20, 2, cloth)

	# Straw poking from hat
	_px(img, 20, 6, straw)
	_px(img, 18, 7, straw)
	_px(img, 44, 6, straw)
	_px(img, 46, 7, straw)

	# Head (burlap sack)
	_fill(img, 24, 12, 16, 12, cloth)
	_fill(img, 22, 14, 20, 8, cloth)
	_fill(img, 26, 12, 12, 2, cloth_lt)

	# Stitched eyes (X marks)
	_px(img, 27, 16, eye)
	_px(img, 29, 16, eye)
	_px(img, 28, 17, eye)
	_px(img, 27, 18, eye)
	_px(img, 29, 18, eye)
	_px(img, 35, 16, eye)
	_px(img, 37, 16, eye)
	_px(img, 36, 17, eye)
	_px(img, 35, 18, eye)
	_px(img, 37, 18, eye)
	# Glowing center
	_px(img, 28, 17, eye_br)
	_px(img, 36, 17, eye_br)

	# Stitched mouth
	_line_h(img, 28, 36, 21, cloth_dk)
	_px(img, 30, 20, cloth_dk)
	_px(img, 32, 22, cloth_dk)
	_px(img, 34, 20, cloth_dk)

	# Cross-beam (horizontal wood)
	_fill(img, 2, 26, 60, 3, wood)
	_fill(img, 4, 25, 56, 1, wood_dk)

	# Vertical post
	_fill(img, 30, 24, 4, 38, wood)
	_fill(img, 29, 26, 1, 34, wood_dk)

	# Shirt body
	_fill(img, 22, 28, 20, 16, cloth)
	_fill(img, 24, 30, 16, 12, cloth_lt)

	# Patches
	_fill(img, 26, 32, 4, 4, patch)
	_fill(img, 35, 36, 4, 3, Color(0.5, 0.2, 0.2))

	# Straw arms (hanging from cross-beam)
	_fill(img, 4, 28, 6, 3, cloth)
	_fill(img, 2, 30, 5, 8, cloth_dk)
	# Straw from sleeves
	_px(img, 1, 38, straw)
	_px(img, 3, 39, straw)
	_px(img, 2, 37, straw_dk)
	_fill(img, 54, 28, 6, 3, cloth)
	_fill(img, 57, 30, 5, 8, cloth_dk)
	_px(img, 62, 38, straw)
	_px(img, 60, 39, straw)
	_px(img, 61, 37, straw_dk)

	# Tattered pants
	_fill(img, 24, 44, 7, 12, cloth_dk)
	_fill(img, 33, 44, 7, 12, cloth_dk)
	# Straw from pants
	_px(img, 24, 56, straw)
	_px(img, 26, 57, straw)
	_px(img, 38, 56, straw)
	_px(img, 36, 57, straw)

	_outline(img, ol)
	_save(img, "farm_scarecrow.png")

# ==================== FARM HARVESTER ====================
func _generate_farm_harvester() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var metal = Color(0.30, 0.30, 0.32)
	var metal_dk = Color(0.18, 0.18, 0.20)
	var metal_lt = Color(0.45, 0.45, 0.48)
	var red = Color(0.65, 0.08, 0.08)
	var red_dk = Color(0.45, 0.04, 0.04)
	var eye = Color(0.9, 0.12, 0.12)
	var eye_br = Color(1.0, 0.3, 0.2)
	var blade = Color(0.6, 0.62, 0.65)
	var blade_lt = Color(0.78, 0.80, 0.82)
	var rust = Color(0.5, 0.3, 0.15)
	var ol = Color(0.08, 0.08, 0.10)

	# Head (angular, mechanical)
	_fill(img, 22, 4, 20, 14, metal)
	_fill(img, 20, 6, 24, 10, metal)
	_fill(img, 24, 4, 16, 2, metal_lt)

	# Visor slit
	_fill(img, 24, 10, 16, 3, Color(0.05, 0.05, 0.06))
	# Red eyes behind visor
	_fill(img, 26, 10, 4, 2, eye)
	_fill(img, 34, 10, 4, 2, eye)
	_px(img, 27, 10, eye_br)
	_px(img, 35, 10, eye_br)

	# Exhaust pipes on head
	_fill(img, 18, 4, 4, 8, metal_dk)
	_fill(img, 42, 4, 4, 8, metal_dk)
	# Smoke
	_px(img, 19, 2, Color(0.4, 0.4, 0.4, 0.4))
	_px(img, 43, 3, Color(0.4, 0.4, 0.4, 0.4))

	# Torso (heavy, industrial)
	_fill(img, 18, 18, 28, 8, metal)
	_fill(img, 16, 22, 32, 10, metal_dk)
	_fill(img, 18, 32, 28, 8, metal)
	_fill(img, 20, 40, 24, 6, metal_dk)

	# Chest plate details
	_fill(img, 22, 20, 20, 2, metal_lt)
	_fill(img, 28, 24, 8, 6, red_dk)
	_fill(img, 30, 25, 4, 4, red)

	# Rust patches
	_fill(img, 20, 28, 3, 2, rust)
	_fill(img, 38, 34, 4, 2, rust)

	# Left arm (normal)
	_fill(img, 10, 20, 6, 4, metal)
	_fill(img, 8, 24, 6, 10, metal_dk)
	_fill(img, 10, 34, 4, 4, metal)

	# Right arm (BLADE arm)
	_fill(img, 48, 20, 6, 4, metal)
	_fill(img, 50, 24, 6, 10, metal_dk)
	# Blade extending down
	_fill(img, 52, 34, 4, 24, blade)
	_fill(img, 54, 32, 2, 28, blade_lt)
	_fill(img, 51, 36, 1, 20, metal_dk)
	# Blade edge
	_line_v(img, 56, 34, 58, blade_lt)

	# Legs (heavy, mechanical)
	_fill(img, 20, 46, 8, 12, metal)
	_fill(img, 36, 46, 8, 12, metal)
	_fill(img, 22, 48, 4, 2, metal_lt)
	_fill(img, 38, 48, 4, 2, metal_lt)

	# Feet (heavy)
	_fill(img, 18, 56, 12, 4, metal_dk)
	_fill(img, 34, 56, 12, 4, metal_dk)

	_outline(img, ol)
	_save(img, "farm_harvester.png")

# ==================== TOKYO SHOGUN ====================
func _generate_tokyo_shogun() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var armor = Color(0.6, 0.08, 0.12)
	var armor_dk = Color(0.4, 0.04, 0.08)
	var armor_lt = Color(0.75, 0.15, 0.18)
	var gold = Color(0.85, 0.72, 0.18)
	var gold_dk = Color(0.65, 0.52, 0.10)
	var eye = Color(0.9, 0.85, 0.2)
	var eye_br = Color(1.0, 1.0, 0.5)
	var katana_b = Color(0.72, 0.74, 0.78)
	var katana_lt = Color(0.88, 0.90, 0.92)
	var handle = Color(0.15, 0.08, 0.05)
	var skin = Color(0.82, 0.72, 0.58)
	var ol = Color(0.2, 0.04, 0.06)

	# Kabuto helmet
	# Main dome
	_fill(img, 20, 4, 24, 10, armor)
	_fill(img, 18, 6, 28, 6, armor)
	_fill(img, 24, 2, 16, 4, armor_dk)
	# Helmet crest (maedate)
	_fill(img, 30, 0, 4, 4, gold)
	_fill(img, 29, 1, 6, 2, gold_dk)
	# Helmet horns (kuwagata)
	_fill(img, 14, 2, 4, 6, gold)
	_fill(img, 12, 0, 3, 4, gold)
	_fill(img, 46, 2, 4, 6, gold)
	_fill(img, 49, 0, 3, 4, gold)
	# Shikoro (neck guard)
	_fill(img, 16, 12, 32, 4, armor_dk)
	_fill(img, 18, 14, 28, 2, armor)

	# Face (menpo mask)
	_fill(img, 22, 8, 20, 8, armor_dk)
	# Eyes
	_fill(img, 25, 9, 4, 3, Color(0.05, 0.02, 0.02))
	_fill(img, 35, 9, 4, 3, Color(0.05, 0.02, 0.02))
	_fill(img, 26, 10, 2, 1, eye)
	_fill(img, 36, 10, 2, 1, eye)
	_px(img, 26, 10, eye_br)
	_px(img, 36, 10, eye_br)

	# Do (chest armor)
	_fill(img, 18, 16, 28, 10, armor)
	_fill(img, 16, 18, 32, 6, armor)
	_fill(img, 20, 16, 24, 2, armor_lt)
	# Gold trim
	_line_h(img, 18, 46, 16, gold)
	_line_h(img, 16, 48, 24, gold)

	# Kusazuri (waist plates)
	_fill(img, 14, 26, 36, 4, armor_dk)
	_fill(img, 16, 30, 32, 4, armor)
	_fill(img, 18, 34, 28, 4, armor_dk)
	# Gold trim on plates
	_line_h(img, 14, 50, 26, gold_dk)
	_line_h(img, 16, 48, 30, gold_dk)

	# Sode (shoulder guards)
	_fill(img, 8, 16, 8, 10, armor)
	_fill(img, 6, 18, 10, 6, armor_dk)
	_fill(img, 48, 16, 8, 10, armor)
	_fill(img, 50, 18, 10, 6, armor_dk)
	# Gold edge
	_line_h(img, 6, 16, 16, gold)
	_line_h(img, 48, 58, 16, gold)

	# Arms
	_fill(img, 10, 26, 5, 12, armor_dk)
	_fill(img, 49, 26, 5, 12, armor_dk)
	# Kote (arm guards)
	_fill(img, 10, 30, 5, 4, armor_lt)
	_fill(img, 49, 30, 5, 4, armor_lt)

	# Katana (left side)
	_fill(img, 6, 10, 2, 40, katana_b)
	_line_v(img, 7, 12, 48, katana_lt)
	# Handle
	_fill(img, 5, 44, 4, 10, handle)
	_fill(img, 6, 46, 2, 6, Color(0.3, 0.15, 0.08))
	# Tsuba (guard)
	_fill(img, 4, 42, 6, 2, gold)

	# Legs (suneate - shin guards)
	_fill(img, 20, 38, 8, 16, armor)
	_fill(img, 36, 38, 8, 16, armor)
	_fill(img, 22, 42, 4, 4, armor_lt)
	_fill(img, 38, 42, 4, 4, armor_lt)

	# Feet
	_fill(img, 18, 54, 12, 4, armor_dk)
	_fill(img, 34, 54, 12, 4, armor_dk)

	_outline(img, ol)
	_save(img, "tokyo_shogun.png")

# ==================== TOKYO KAIJU ====================
func _generate_tokyo_kaiju() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var skin_c = Color(0.12, 0.35, 0.18)
	var skin_dk = Color(0.06, 0.22, 0.10)
	var skin_lt = Color(0.20, 0.48, 0.25)
	var belly = Color(0.35, 0.50, 0.25)
	var eye_c = Color(0.2, 0.85, 0.3)
	var eye_br = Color(0.4, 1.0, 0.5)
	var spike = Color(0.55, 0.6, 0.35)
	var spike_dk = Color(0.40, 0.45, 0.22)
	var teeth = Color(0.9, 0.88, 0.82)
	var ol = Color(0.04, 0.12, 0.05)

	# Head (large, reptilian)
	_fill(img, 20, 6, 24, 16, skin_c)
	_fill(img, 18, 8, 28, 12, skin_c)
	_fill(img, 22, 4, 20, 4, skin_dk)

	# Brow ridge
	_fill(img, 18, 8, 28, 3, skin_dk)

	# Eyes (set in skull)
	_fill(img, 22, 10, 5, 5, Color(0.05, 0.08, 0.04))
	_fill(img, 37, 10, 5, 5, Color(0.05, 0.08, 0.04))
	_fill(img, 23, 11, 3, 3, eye_c)
	_fill(img, 38, 11, 3, 3, eye_c)
	_px(img, 24, 12, eye_br)
	_px(img, 39, 12, eye_br)

	# Snout
	_fill(img, 24, 16, 16, 6, skin_c)
	_fill(img, 26, 14, 12, 4, skin_lt)
	# Nostrils
	_px(img, 28, 16, skin_dk)
	_px(img, 35, 16, skin_dk)

	# Open jaw with teeth
	_fill(img, 22, 20, 20, 4, Color(0.15, 0.06, 0.06))
	for i in range(5):
		_fill(img, 24 + i * 4, 20, 2, 2, teeth)
		_fill(img, 24 + i * 4, 22, 2, 2, teeth)

	# Back spikes (dorsal plates)
	_fill(img, 28, 0, 3, 6, spike)
	_fill(img, 33, 1, 3, 5, spike)
	_fill(img, 26, 2, 2, 4, spike_dk)
	_fill(img, 36, 2, 2, 4, spike_dk)

	# Massive body
	_fill(img, 14, 24, 36, 8, skin_c)
	_fill(img, 12, 28, 40, 8, skin_dk)
	_fill(img, 14, 36, 36, 8, skin_c)
	_fill(img, 16, 44, 32, 6, skin_dk)

	# Belly
	_fill(img, 22, 28, 20, 16, belly)
	_fill(img, 24, 30, 16, 12, Color(0.40, 0.55, 0.30))

	# Arms (short, muscular)
	_fill(img, 6, 26, 8, 6, skin_c)
	_fill(img, 4, 28, 6, 8, skin_dk)
	_fill(img, 50, 26, 8, 6, skin_c)
	_fill(img, 54, 28, 6, 8, skin_dk)
	# Claws
	_px(img, 3, 36, teeth)
	_px(img, 5, 36, teeth)
	_px(img, 59, 36, teeth)
	_px(img, 57, 36, teeth)

	# Thick legs
	_fill(img, 16, 48, 10, 10, skin_c)
	_fill(img, 38, 48, 10, 10, skin_c)
	# Feet with claws
	_fill(img, 14, 56, 14, 4, skin_dk)
	_fill(img, 36, 56, 14, 4, skin_dk)
	_px(img, 13, 60, teeth)
	_px(img, 28, 60, teeth)
	_px(img, 35, 60, teeth)
	_px(img, 50, 60, teeth)

	# Tail
	_fill(img, 48, 44, 10, 4, skin_c)
	_fill(img, 56, 42, 6, 3, skin_dk)
	_fill(img, 60, 40, 3, 3, skin_c)

	# Back spikes (on body)
	_fill(img, 30, 24, 4, 2, spike)
	_fill(img, 28, 36, 3, 2, spike_dk)
	_fill(img, 34, 32, 3, 2, spike)

	_outline(img, ol)
	_save(img, "tokyo_kaiju.png")

# ==================== VOLCANO PHOENIX ====================
func _generate_volcano_phoenix() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var body_c = Color(0.9, 0.35, 0.0)
	var body_dk = Color(0.7, 0.2, 0.0)
	var body_lt = Color(1.0, 0.55, 0.1)
	var fire = Color(1.0, 0.7, 0.0)
	var fire_br = Color(1.0, 0.9, 0.3)
	var fire_dk = Color(0.8, 0.2, 0.0)
	var eye_c = Color(1.0, 1.0, 0.8)
	var beak = Color(0.85, 0.65, 0.1)
	var beak_dk = Color(0.65, 0.45, 0.05)
	var wing_tip = Color(1.0, 0.85, 0.2)
	var ol = Color(0.35, 0.1, 0.0)

	# Fire aura
	_circle(img, 32, 28, 26, Color(1.0, 0.5, 0.0, 0.2))
	_circle(img, 32, 26, 18, Color(1.0, 0.6, 0.1, 0.15))

	# Left wing (spread wide)
	_fill(img, 2, 18, 14, 4, body_c)
	_fill(img, 4, 14, 12, 4, body_dk)
	_fill(img, 6, 10, 10, 4, body_c)
	_fill(img, 8, 22, 10, 4, body_dk)
	_fill(img, 10, 26, 8, 3, body_c)
	# Wing feather tips (fire-like)
	_fill(img, 0, 16, 4, 3, fire)
	_fill(img, 2, 12, 4, 3, fire)
	_fill(img, 4, 8, 4, 3, fire_br)
	_fill(img, 6, 6, 3, 3, wing_tip)

	# Right wing (spread wide)
	_fill(img, 48, 18, 14, 4, body_c)
	_fill(img, 48, 14, 12, 4, body_dk)
	_fill(img, 48, 10, 10, 4, body_c)
	_fill(img, 46, 22, 10, 4, body_dk)
	_fill(img, 46, 26, 8, 3, body_c)
	# Wing feather tips
	_fill(img, 60, 16, 4, 3, fire)
	_fill(img, 58, 12, 4, 3, fire)
	_fill(img, 56, 8, 4, 3, fire_br)
	_fill(img, 55, 6, 3, 3, wing_tip)

	# Body (sleek bird shape)
	_circle(img, 32, 28, 10, body_c)
	_circle(img, 32, 26, 8, body_lt)
	_fill(img, 26, 32, 12, 8, body_dk)
	_fill(img, 28, 40, 8, 4, body_c)

	# Neck
	_fill(img, 28, 14, 8, 8, body_c)
	_fill(img, 30, 12, 4, 4, body_lt)

	# Head
	_circle(img, 32, 10, 6, body_c)
	_circle(img, 32, 9, 5, body_lt)

	# Crown crest (fire plume)
	_fill(img, 30, 2, 4, 5, fire)
	_fill(img, 28, 0, 3, 4, fire_br)
	_fill(img, 33, 0, 3, 4, fire_br)
	_px(img, 29, 0, wing_tip)
	_px(img, 34, 0, wing_tip)

	# Eyes
	_fill(img, 28, 8, 3, 3, Color(0.15, 0.05, 0.0))
	_fill(img, 33, 8, 3, 3, Color(0.15, 0.05, 0.0))
	_px(img, 29, 9, eye_c)
	_px(img, 34, 9, eye_c)

	# Beak
	_fill(img, 30, 12, 4, 2, beak)
	_fill(img, 31, 14, 2, 2, beak_dk)

	# Tail feathers (dramatic, downward flame)
	_fill(img, 28, 44, 8, 4, fire_dk)
	_fill(img, 26, 48, 12, 4, fire)
	_fill(img, 24, 52, 16, 4, fire_br)
	_fill(img, 22, 56, 20, 4, wing_tip)
	_fill(img, 20, 60, 24, 3, Color(1.0, 0.95, 0.5))
	# Central tail flame
	_fill(img, 30, 52, 4, 10, fire_br)
	_px(img, 31, 62, wing_tip)
	_px(img, 32, 62, wing_tip)

	# Fire particles
	_px(img, 16, 28, fire)
	_px(img, 48, 26, fire)
	_px(img, 22, 44, fire_br)
	_px(img, 42, 46, fire_br)

	_outline(img, ol)
	_save(img, "volcano_phoenix.png")

# ==================== VOLCANO TITAN ====================
func _generate_volcano_titan() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var rock = Color(0.32, 0.18, 0.08)
	var rock_dk = Color(0.20, 0.10, 0.04)
	var rock_lt = Color(0.45, 0.28, 0.14)
	var lava = Color(1.0, 0.4, 0.0)
	var lava_br = Color(1.0, 0.7, 0.2)
	var lava_dk = Color(0.8, 0.15, 0.0)
	var eye_c = Color(1.0, 0.6, 0.0)
	var eye_br = Color(1.0, 0.9, 0.4)
	var ol = Color(0.12, 0.06, 0.02)

	# Massive head/shoulders (no neck, brutish)
	_fill(img, 16, 4, 32, 16, rock)
	_fill(img, 14, 6, 36, 12, rock)
	_fill(img, 18, 2, 28, 4, rock_dk)
	# Top ridge
	_fill(img, 20, 0, 8, 3, rock_lt)
	_fill(img, 36, 0, 8, 3, rock_lt)

	# Eyes (lava glow in rock)
	_fill(img, 20, 8, 6, 5, Color(0.08, 0.04, 0.02))
	_fill(img, 38, 8, 6, 5, Color(0.08, 0.04, 0.02))
	_fill(img, 21, 9, 4, 3, eye_c)
	_fill(img, 39, 9, 4, 3, eye_c)
	_px(img, 22, 10, eye_br)
	_px(img, 40, 10, eye_br)

	# Jaw
	_fill(img, 22, 16, 20, 4, rock_dk)
	_fill(img, 24, 18, 16, 2, Color(0.08, 0.04, 0.02))
	# Lava in mouth
	_fill(img, 26, 18, 12, 2, lava_dk)
	_fill(img, 28, 18, 8, 1, lava)

	# Massive torso
	_fill(img, 10, 20, 44, 10, rock)
	_fill(img, 8, 24, 48, 10, rock_dk)
	_fill(img, 10, 34, 44, 8, rock)
	_fill(img, 12, 42, 40, 6, rock_dk)

	# Lava cracks throughout body
	_line_v(img, 20, 22, 40, lava)
	_line_v(img, 21, 24, 38, lava_dk)
	_line_h(img, 28, 36, 30, lava)
	_line_v(img, 42, 24, 42, lava)
	_line_v(img, 43, 26, 40, lava_dk)
	_line_h(img, 16, 24, 36, lava_dk)
	_line_h(img, 38, 48, 38, lava)
	# Bright spots at intersections
	_px(img, 20, 30, lava_br)
	_px(img, 42, 38, lava_br)
	_px(img, 32, 30, lava_br)

	# Massive arms
	_fill(img, 2, 20, 8, 8, rock)
	_fill(img, 0, 24, 8, 14, rock_dk)
	_fill(img, 2, 38, 6, 6, rock)
	_fill(img, 54, 20, 8, 8, rock)
	_fill(img, 56, 24, 8, 14, rock_dk)
	_fill(img, 56, 38, 6, 6, rock)
	# Lava in arm cracks
	_px(img, 4, 30, lava)
	_px(img, 58, 32, lava)

	# Fists (huge)
	_fill(img, 0, 42, 8, 6, rock_dk)
	_fill(img, 56, 42, 8, 6, rock_dk)

	# Legs (thick, stumpy)
	_fill(img, 14, 48, 12, 10, rock)
	_fill(img, 38, 48, 12, 10, rock)
	# Lava cracks in legs
	_line_v(img, 18, 50, 56, lava_dk)
	_line_v(img, 42, 50, 56, lava_dk)

	# Feet
	_fill(img, 12, 56, 16, 4, rock_dk)
	_fill(img, 36, 56, 16, 4, rock_dk)

	# Rock texture highlights
	_fill(img, 24, 24, 3, 2, rock_lt)
	_fill(img, 36, 28, 3, 2, rock_lt)
	_fill(img, 18, 42, 2, 2, rock_lt)
	_fill(img, 44, 44, 2, 2, rock_lt)

	_outline(img, ol)
	_save(img, "volcano_titan.png")

# ==================== OCEAN SIREN ====================
func _generate_ocean_siren() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var skin_c = Color(0.55, 0.78, 0.85)
	var skin_dk = Color(0.40, 0.62, 0.72)
	var skin_lt = Color(0.70, 0.88, 0.92)
	var hair = Color(0.15, 0.55, 0.70)
	var hair_lt = Color(0.25, 0.70, 0.82)
	var hair_dk = Color(0.08, 0.38, 0.50)
	var tail_c = Color(0.12, 0.45, 0.55)
	var tail_lt = Color(0.20, 0.60, 0.70)
	var tail_dk = Color(0.06, 0.30, 0.40)
	var scale = Color(0.25, 0.65, 0.75)
	var eye_c = Color(0.2, 0.9, 0.95)
	var eye_br = Color(0.5, 1.0, 1.0)
	var lip = Color(0.65, 0.45, 0.55)
	var jewel = Color(0.3, 0.85, 0.9)
	var ol = Color(0.05, 0.2, 0.28)

	# Flowing hair (background layer)
	_fill(img, 12, 4, 8, 24, hair_dk)
	_fill(img, 44, 4, 8, 24, hair_dk)
	_fill(img, 10, 8, 6, 20, hair)
	_fill(img, 48, 8, 6, 20, hair)
	_fill(img, 8, 12, 4, 16, hair_lt)
	_fill(img, 52, 12, 4, 16, hair_lt)

	# Hair on top
	_fill(img, 20, 0, 24, 6, hair)
	_fill(img, 18, 2, 28, 6, hair)
	_fill(img, 22, 0, 20, 3, hair_lt)
	_fill(img, 16, 6, 32, 6, hair_dk)

	# Face
	_fill(img, 22, 8, 20, 14, skin_c)
	_fill(img, 24, 6, 16, 4, skin_c)
	_fill(img, 20, 10, 24, 10, skin_c)
	# Face shading
	_fill(img, 20, 10, 4, 6, skin_dk)
	_fill(img, 40, 10, 4, 6, skin_dk)

	# Eyes (large, enchanting)
	_fill(img, 24, 12, 5, 4, Color.WHITE)
	_fill(img, 35, 12, 5, 4, Color.WHITE)
	_fill(img, 25, 13, 3, 2, eye_c)
	_fill(img, 36, 13, 3, 2, eye_c)
	_px(img, 26, 13, eye_br)
	_px(img, 37, 13, eye_br)
	# Eyelashes
	_px(img, 23, 12, hair_dk)
	_px(img, 29, 12, hair_dk)
	_px(img, 34, 12, hair_dk)
	_px(img, 40, 12, hair_dk)

	# Nose
	_px(img, 31, 17, skin_dk)
	_px(img, 32, 17, skin_dk)

	# Lips
	_fill(img, 29, 19, 6, 2, lip)
	_px(img, 32, 19, Color(0.75, 0.55, 0.65))

	# Jewel on forehead
	_fill(img, 30, 7, 4, 3, jewel)
	_px(img, 31, 8, eye_br)

	# Upper body / torso
	_fill(img, 24, 22, 16, 10, skin_c)
	_fill(img, 22, 24, 20, 6, skin_c)
	_fill(img, 26, 22, 12, 2, skin_lt)
	# Shell top
	_fill(img, 25, 26, 5, 3, scale)
	_fill(img, 34, 26, 5, 3, scale)

	# Arms (graceful)
	_fill(img, 14, 22, 6, 4, skin_c)
	_fill(img, 10, 24, 6, 10, skin_dk)
	_fill(img, 8, 32, 4, 4, skin_c)
	_fill(img, 44, 22, 6, 4, skin_c)
	_fill(img, 48, 24, 6, 10, skin_dk)
	_fill(img, 52, 32, 4, 4, skin_c)
	# Fingers
	_px(img, 7, 36, skin_lt)
	_px(img, 9, 36, skin_lt)
	_px(img, 54, 36, skin_lt)
	_px(img, 56, 36, skin_lt)

	# Tail (merging from waist)
	_fill(img, 22, 32, 20, 6, tail_c)
	_fill(img, 20, 36, 24, 6, tail_c)
	_fill(img, 22, 42, 20, 6, tail_dk)
	_fill(img, 24, 48, 16, 4, tail_c)
	_fill(img, 26, 52, 12, 4, tail_dk)

	# Scales on tail
	for i in range(4):
		_fill(img, 24 + i * 4, 38, 3, 2, scale)
		_fill(img, 22 + i * 4, 44, 3, 2, scale)

	# Tail fin (flared)
	_fill(img, 18, 54, 10, 4, tail_lt)
	_fill(img, 36, 54, 10, 4, tail_lt)
	_fill(img, 14, 56, 8, 4, tail_c)
	_fill(img, 42, 56, 8, 4, tail_c)
	_fill(img, 12, 58, 6, 3, tail_lt)
	_fill(img, 46, 58, 6, 3, tail_lt)

	_outline(img, ol)
	_save(img, "ocean_siren.png")

# ==================== OCEAN HYDRA ====================
func _generate_ocean_hydra() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var body_c = Color(0.08, 0.18, 0.35)
	var body_dk = Color(0.04, 0.10, 0.22)
	var body_lt = Color(0.14, 0.28, 0.48)
	var belly = Color(0.18, 0.35, 0.45)
	var eye_c = Color(0.2, 0.5, 0.9)
	var eye_br = Color(0.4, 0.7, 1.0)
	var teeth = Color(0.9, 0.88, 0.82)
	var scale_c = Color(0.12, 0.25, 0.42)
	var ol = Color(0.02, 0.08, 0.15)

	# Central neck/body
	_fill(img, 26, 20, 12, 30, body_c)
	_fill(img, 24, 24, 16, 24, body_dk)
	_fill(img, 28, 26, 8, 18, belly)

	# Left neck
	_fill(img, 12, 10, 8, 20, body_c)
	_fill(img, 10, 14, 8, 14, body_dk)
	_fill(img, 16, 18, 8, 6, body_c)

	# Right neck
	_fill(img, 44, 10, 8, 20, body_c)
	_fill(img, 46, 14, 8, 14, body_dk)
	_fill(img, 40, 18, 8, 6, body_c)

	# Central head (largest)
	_fill(img, 24, 8, 16, 14, body_c)
	_fill(img, 22, 10, 20, 10, body_c)
	_fill(img, 26, 6, 12, 4, body_dk)
	# Eyes
	_fill(img, 26, 10, 4, 3, Color(0.02, 0.04, 0.08))
	_fill(img, 34, 10, 4, 3, Color(0.02, 0.04, 0.08))
	_fill(img, 27, 11, 2, 1, eye_c)
	_fill(img, 35, 11, 2, 1, eye_c)
	_px(img, 27, 11, eye_br)
	_px(img, 35, 11, eye_br)
	# Jaw and teeth
	_fill(img, 26, 18, 12, 3, Color(0.04, 0.06, 0.12))
	for i in range(4):
		_px(img, 27 + i * 3, 18, teeth)
		_px(img, 27 + i * 3, 20, teeth)

	# Left head
	_fill(img, 6, 2, 12, 10, body_c)
	_fill(img, 4, 4, 14, 6, body_c)
	_fill(img, 8, 0, 8, 3, body_dk)
	# Eyes
	_fill(img, 7, 4, 3, 2, Color(0.02, 0.04, 0.08))
	_fill(img, 14, 4, 3, 2, Color(0.02, 0.04, 0.08))
	_px(img, 8, 4, eye_c)
	_px(img, 15, 4, eye_c)
	# Jaw
	_fill(img, 6, 10, 10, 2, Color(0.04, 0.06, 0.12))
	_px(img, 8, 10, teeth)
	_px(img, 12, 10, teeth)

	# Right head
	_fill(img, 46, 2, 12, 10, body_c)
	_fill(img, 46, 4, 14, 6, body_c)
	_fill(img, 48, 0, 8, 3, body_dk)
	# Eyes
	_fill(img, 48, 4, 3, 2, Color(0.02, 0.04, 0.08))
	_fill(img, 55, 4, 3, 2, Color(0.02, 0.04, 0.08))
	_px(img, 49, 4, eye_c)
	_px(img, 56, 4, eye_c)
	# Jaw
	_fill(img, 48, 10, 10, 2, Color(0.04, 0.06, 0.12))
	_px(img, 50, 10, teeth)
	_px(img, 54, 10, teeth)

	# Body mass (lower)
	_fill(img, 18, 44, 28, 8, body_dk)
	_fill(img, 20, 52, 24, 6, body_c)

	# Scales
	for i in range(5):
		_fill(img, 22 + i * 4, 32, 3, 2, scale_c)
		_fill(img, 24 + i * 3, 46, 2, 2, scale_c)

	# Tail
	_fill(img, 26, 56, 12, 4, body_dk)
	_fill(img, 30, 58, 8, 4, body_c)
	_fill(img, 34, 60, 6, 3, body_dk)

	_outline(img, ol)
	_save(img, "ocean_hydra.png")

# ==================== ARENA MINOTAUR ====================
func _generate_arena_minotaur() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var fur = Color(0.45, 0.28, 0.12)
	var fur_dk = Color(0.30, 0.18, 0.06)
	var fur_lt = Color(0.58, 0.38, 0.18)
	var skin_c = Color(0.55, 0.35, 0.18)
	var horn = Color(0.82, 0.78, 0.65)
	var horn_dk = Color(0.62, 0.58, 0.45)
	var eye_c = Color(0.9, 0.2, 0.1)
	var eye_br = Color(1.0, 0.4, 0.2)
	var nose_r = Color(0.6, 0.25, 0.2)
	var armor_c = Color(0.55, 0.42, 0.18)
	var armor_dk = Color(0.40, 0.30, 0.10)
	var ol = Color(0.15, 0.08, 0.04)

	# Horns (large, curved outward)
	# Left horn
	_fill(img, 8, 4, 4, 10, horn)
	_fill(img, 6, 2, 4, 6, horn)
	_fill(img, 4, 0, 4, 4, horn_dk)
	_fill(img, 10, 6, 2, 6, horn_dk)
	# Right horn
	_fill(img, 52, 4, 4, 10, horn)
	_fill(img, 54, 2, 4, 6, horn)
	_fill(img, 56, 0, 4, 4, horn_dk)
	_fill(img, 52, 6, 2, 6, horn_dk)

	# Bull head (wide)
	_fill(img, 18, 4, 28, 16, fur)
	_fill(img, 16, 6, 32, 12, fur)
	_fill(img, 20, 2, 24, 4, fur_dk)
	# Forehead ridge
	_fill(img, 22, 4, 20, 3, fur_dk)

	# Eyes (angry, deep-set)
	_fill(img, 22, 10, 5, 4, Color(0.1, 0.05, 0.02))
	_fill(img, 37, 10, 5, 4, Color(0.1, 0.05, 0.02))
	_fill(img, 23, 11, 3, 2, eye_c)
	_fill(img, 38, 11, 3, 2, eye_c)
	_px(img, 24, 11, eye_br)
	_px(img, 39, 11, eye_br)

	# Snout
	_fill(img, 24, 16, 16, 6, fur_lt)
	_fill(img, 26, 14, 12, 4, skin_c)
	# Nostrils (with nose ring)
	_fill(img, 28, 17, 3, 2, nose_r)
	_fill(img, 33, 17, 3, 2, nose_r)
	# Nose ring
	_fill(img, 30, 19, 4, 2, armor_c)
	_px(img, 31, 20, armor_dk)
	_px(img, 32, 20, armor_dk)

	# Massive muscular torso
	_fill(img, 12, 20, 40, 8, fur)
	_fill(img, 10, 24, 44, 8, fur_dk)
	_fill(img, 12, 32, 40, 8, fur)
	_fill(img, 14, 40, 36, 4, fur_dk)

	# Chest
	_fill(img, 22, 22, 20, 10, skin_c)
	_fill(img, 24, 24, 16, 6, Color(0.6, 0.4, 0.22))

	# Armor belt
	_fill(img, 14, 40, 36, 3, armor_c)
	_fill(img, 16, 42, 32, 1, armor_dk)

	# Arms (massive)
	_fill(img, 2, 22, 10, 6, fur)
	_fill(img, 0, 26, 10, 12, fur_dk)
	_fill(img, 2, 38, 8, 6, fur)
	_fill(img, 52, 22, 10, 6, fur)
	_fill(img, 54, 26, 10, 12, fur_dk)
	_fill(img, 54, 38, 8, 6, fur)

	# Fists
	_fill(img, 0, 42, 10, 6, skin_c)
	_fill(img, 54, 42, 10, 6, skin_c)

	# Loincloth
	_fill(img, 20, 44, 10, 8, armor_dk)
	_fill(img, 34, 44, 10, 8, armor_dk)
	_fill(img, 28, 44, 8, 6, armor_c)

	# Legs (thick, hooved)
	_fill(img, 16, 48, 10, 8, fur)
	_fill(img, 38, 48, 10, 8, fur)
	# Hooves
	_fill(img, 14, 56, 14, 4, fur_dk)
	_fill(img, 36, 56, 14, 4, fur_dk)

	_outline(img, ol)
	_save(img, "arena_minotaur.png")

# ==================== ARENA CHIMERA ====================
func _generate_arena_chimera() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var lion = Color(0.65, 0.45, 0.15)
	var lion_dk = Color(0.48, 0.30, 0.08)
	var lion_lt = Color(0.78, 0.58, 0.25)
	var mane = Color(0.55, 0.30, 0.08)
	var mane_dk = Color(0.38, 0.18, 0.04)
	var wing_c = Color(0.45, 0.18, 0.48)
	var wing_dk = Color(0.30, 0.10, 0.32)
	var wing_lt = Color(0.60, 0.30, 0.62)
	var eye_c = Color(0.8, 0.3, 0.8)
	var eye_br = Color(1.0, 0.5, 1.0)
	var snake = Color(0.25, 0.45, 0.15)
	var snake_dk = Color(0.15, 0.30, 0.08)
	var teeth = Color(0.9, 0.88, 0.82)
	var ol = Color(0.18, 0.08, 0.20)

	# Wings (bat-like, purple)
	# Left wing
	_fill(img, 2, 12, 12, 4, wing_c)
	_fill(img, 0, 8, 10, 4, wing_dk)
	_fill(img, 4, 16, 10, 4, wing_c)
	_fill(img, 6, 20, 8, 3, wing_dk)
	# Wing membrane lines
	_line_v(img, 4, 10, 18, wing_lt)
	_line_v(img, 8, 8, 20, wing_lt)
	# Right wing
	_fill(img, 50, 12, 12, 4, wing_c)
	_fill(img, 54, 8, 10, 4, wing_dk)
	_fill(img, 50, 16, 10, 4, wing_c)
	_fill(img, 50, 20, 8, 3, wing_dk)
	_line_v(img, 56, 10, 18, wing_lt)
	_line_v(img, 60, 8, 20, wing_lt)

	# Lion mane
	_circle(img, 32, 12, 12, mane)
	_circle(img, 32, 10, 10, mane_dk)
	_circle(img, 28, 8, 6, mane)
	_circle(img, 36, 8, 6, mane)

	# Lion head
	_fill(img, 24, 6, 16, 14, lion)
	_fill(img, 22, 8, 20, 10, lion)
	_fill(img, 26, 4, 12, 4, lion_dk)

	# Eyes
	_fill(img, 26, 10, 4, 3, Color(0.1, 0.05, 0.08))
	_fill(img, 34, 10, 4, 3, Color(0.1, 0.05, 0.08))
	_fill(img, 27, 11, 2, 1, eye_c)
	_fill(img, 35, 11, 2, 1, eye_c)
	_px(img, 27, 11, eye_br)
	_px(img, 35, 11, eye_br)

	# Nose and mouth
	_fill(img, 30, 14, 4, 2, lion_dk)
	_fill(img, 28, 16, 8, 3, Color(0.12, 0.06, 0.06))
	# Fangs
	_px(img, 29, 16, teeth)
	_px(img, 35, 16, teeth)
	_px(img, 29, 17, teeth)
	_px(img, 35, 17, teeth)

	# Lion body
	_fill(img, 16, 22, 32, 10, lion)
	_fill(img, 14, 26, 36, 8, lion_dk)
	_fill(img, 16, 34, 32, 6, lion)

	# Belly
	_fill(img, 22, 28, 20, 8, lion_lt)

	# Front legs
	_fill(img, 14, 38, 8, 14, lion)
	_fill(img, 42, 38, 8, 14, lion)
	_fill(img, 16, 42, 4, 4, lion_dk)
	_fill(img, 44, 42, 4, 4, lion_dk)
	# Paws
	_fill(img, 12, 52, 12, 4, lion_dk)
	_fill(img, 40, 52, 12, 4, lion_dk)

	# Back legs (goat hooves would be hidden)
	_fill(img, 18, 52, 6, 8, lion_dk)
	_fill(img, 40, 52, 6, 8, lion_dk)

	# Snake tail (coming from back)
	_fill(img, 46, 34, 8, 4, snake)
	_fill(img, 52, 32, 6, 3, snake)
	_fill(img, 56, 30, 4, 3, snake_dk)
	_fill(img, 58, 28, 4, 4, snake)
	# Snake head
	_fill(img, 60, 26, 4, 4, snake)
	_px(img, 62, 27, eye_c)
	_px(img, 63, 28, Color(0.1, 0.05, 0.02))

	_outline(img, ol)
	_save(img, "arena_chimera.png")

# ==================== SPACE HIVEMIND ====================
func _generate_space_hivemind() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var flesh = Color(0.15, 0.42, 0.15)
	var flesh_dk = Color(0.08, 0.28, 0.08)
	var flesh_lt = Color(0.22, 0.55, 0.22)
	var eye_c = Color(0.3, 0.9, 0.3)
	var eye_br = Color(0.5, 1.0, 0.5)
	var eye_dk = Color(0.1, 0.3, 0.1)
	var tentacle = Color(0.12, 0.38, 0.12)
	var tentacle_dk = Color(0.06, 0.25, 0.06)
	var sucker = Color(0.25, 0.55, 0.30)
	var brain = Color(0.35, 0.55, 0.35)
	var brain_dk = Color(0.22, 0.38, 0.22)
	var ol = Color(0.04, 0.15, 0.04)

	# Brain-like dome (top)
	_circle(img, 32, 14, 16, flesh)
	_circle(img, 32, 12, 14, flesh_lt)
	_circle(img, 32, 10, 10, brain)
	# Brain folds
	_line_h(img, 22, 42, 8, brain_dk)
	_line_h(img, 24, 40, 12, brain_dk)
	_line_h(img, 20, 44, 6, brain_dk)
	_line_h(img, 26, 38, 16, brain_dk)

	# Central eye cluster
	# Main eye (large)
	_circle(img, 32, 22, 6, Color(0.08, 0.12, 0.08))
	_circle(img, 32, 22, 4, Color.WHITE * 0.9)
	_circle(img, 32, 22, 2, eye_c)
	_px(img, 32, 22, eye_br)

	# Secondary eyes (surrounding)
	for data in [[24, 18, 3], [40, 18, 3], [22, 26, 2], [42, 26, 2], [28, 28, 2], [36, 28, 2]]:
		var ex = data[0]
		var ey = data[1]
		var er = data[2]
		_circle(img, ex, ey, er, Color(0.08, 0.12, 0.08))
		_circle(img, ex, ey, er - 1, eye_c)
		_px(img, ex, ey, eye_br)

	# Body mass (amorphous)
	_fill(img, 18, 28, 28, 10, flesh)
	_fill(img, 16, 32, 32, 8, flesh_dk)
	_fill(img, 20, 38, 24, 6, flesh)

	# Tentacles (8 total, spreading outward)
	# Left tentacles
	_fill(img, 10, 32, 6, 3, tentacle)
	_fill(img, 4, 34, 8, 3, tentacle)
	_fill(img, 0, 38, 6, 3, tentacle_dk)
	_fill(img, 0, 42, 4, 3, tentacle)
	# Suckers
	_px(img, 6, 35, sucker)
	_px(img, 2, 39, sucker)

	_fill(img, 12, 40, 6, 3, tentacle)
	_fill(img, 6, 44, 8, 3, tentacle_dk)
	_fill(img, 2, 48, 6, 3, tentacle)
	_fill(img, 0, 52, 4, 3, tentacle_dk)
	_px(img, 8, 45, sucker)
	_px(img, 4, 49, sucker)

	# Right tentacles
	_fill(img, 48, 32, 6, 3, tentacle)
	_fill(img, 52, 34, 8, 3, tentacle)
	_fill(img, 58, 38, 6, 3, tentacle_dk)
	_fill(img, 60, 42, 4, 3, tentacle)
	_px(img, 56, 35, sucker)
	_px(img, 62, 39, sucker)

	_fill(img, 46, 40, 6, 3, tentacle)
	_fill(img, 50, 44, 8, 3, tentacle_dk)
	_fill(img, 56, 48, 6, 3, tentacle)
	_fill(img, 60, 52, 4, 3, tentacle_dk)
	_px(img, 54, 45, sucker)
	_px(img, 60, 49, sucker)

	# Bottom tentacles
	_fill(img, 22, 44, 4, 10, tentacle)
	_fill(img, 20, 52, 4, 8, tentacle_dk)
	_fill(img, 38, 44, 4, 10, tentacle)
	_fill(img, 40, 52, 4, 8, tentacle_dk)
	_fill(img, 30, 44, 4, 12, tentacle)
	_fill(img, 28, 54, 4, 8, tentacle_dk)

	_outline(img, ol)
	_save(img, "space_hivemind.png")

# ==================== SPACE WARDEN ====================
func _generate_space_warden() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var armor_c = Color(0.22, 0.12, 0.45)
	var armor_dk = Color(0.12, 0.06, 0.30)
	var armor_lt = Color(0.35, 0.22, 0.58)
	var glow_c = Color(0.5, 0.3, 0.9)
	var glow_br = Color(0.7, 0.5, 1.0)
	var visor = Color(0.3, 0.8, 1.0)
	var visor_br = Color(0.5, 0.9, 1.0)
	var metal = Color(0.5, 0.5, 0.55)
	var metal_dk = Color(0.35, 0.35, 0.38)
	var ol = Color(0.08, 0.04, 0.18)

	# Energy aura
	_circle(img, 32, 30, 28, Color(0.4, 0.2, 0.8, 0.15))

	# Helmet (angular, futuristic)
	_fill(img, 20, 2, 24, 16, armor_c)
	_fill(img, 18, 4, 28, 12, armor_c)
	_fill(img, 22, 0, 20, 4, armor_dk)
	# Helmet ridges
	_fill(img, 30, 0, 4, 4, armor_lt)
	_fill(img, 18, 6, 2, 8, armor_lt)
	_fill(img, 44, 6, 2, 8, armor_lt)

	# Visor (T-shaped, glowing)
	_fill(img, 22, 8, 20, 3, visor)
	_fill(img, 30, 10, 4, 6, visor)
	# Visor highlights
	_fill(img, 24, 8, 4, 2, visor_br)
	_fill(img, 36, 8, 4, 2, visor_br)
	_px(img, 31, 12, visor_br)

	# Neck piece
	_fill(img, 24, 16, 16, 4, metal)
	_fill(img, 26, 18, 12, 2, metal_dk)

	# Shoulder pads (large, angular)
	_fill(img, 4, 18, 14, 8, armor_c)
	_fill(img, 2, 20, 16, 4, armor_dk)
	_fill(img, 6, 16, 10, 3, armor_lt)
	# Glow lines on shoulders
	_line_h(img, 4, 16, 22, glow_c)
	_px(img, 10, 22, glow_br)

	_fill(img, 46, 18, 14, 8, armor_c)
	_fill(img, 46, 20, 16, 4, armor_dk)
	_fill(img, 48, 16, 10, 3, armor_lt)
	_line_h(img, 48, 60, 22, glow_c)
	_px(img, 54, 22, glow_br)

	# Torso armor
	_fill(img, 18, 20, 28, 10, armor_c)
	_fill(img, 16, 24, 32, 8, armor_dk)
	_fill(img, 18, 32, 28, 6, armor_c)
	_fill(img, 20, 38, 24, 4, armor_dk)

	# Chest plate details
	_fill(img, 24, 22, 16, 2, armor_lt)
	# Central power core
	_circle(img, 32, 28, 4, Color(0.1, 0.06, 0.2))
	_circle(img, 32, 28, 3, glow_c)
	_circle(img, 32, 28, 1, glow_br)

	# Glow lines on torso
	_line_v(img, 22, 24, 36, glow_c)
	_line_v(img, 42, 24, 36, glow_c)

	# Arms
	_fill(img, 8, 26, 6, 14, armor_dk)
	_fill(img, 10, 28, 4, 4, armor_lt)
	_fill(img, 50, 26, 6, 14, armor_dk)
	_fill(img, 50, 28, 4, 4, armor_lt)

	# Gauntlets
	_fill(img, 6, 38, 8, 6, armor_c)
	_fill(img, 50, 38, 8, 6, armor_c)
	# Glowing fists
	_fill(img, 8, 40, 4, 3, glow_c)
	_fill(img, 52, 40, 4, 3, glow_c)

	# Legs
	_fill(img, 20, 42, 10, 12, armor_c)
	_fill(img, 34, 42, 10, 12, armor_c)
	_fill(img, 22, 46, 6, 4, armor_lt)
	_fill(img, 36, 46, 6, 4, armor_lt)

	# Boots
	_fill(img, 18, 54, 12, 6, armor_dk)
	_fill(img, 34, 54, 12, 6, armor_dk)
	# Glow trim on boots
	_line_h(img, 18, 30, 54, glow_c)
	_line_h(img, 34, 46, 54, glow_c)

	_outline(img, ol)
	_save(img, "space_warden.png")

# ==================== CASTLE WEREWOLF ====================
func _generate_castle_werewolf() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var fur_c = Color(0.32, 0.22, 0.14)
	var fur_dk = Color(0.20, 0.12, 0.06)
	var fur_lt = Color(0.45, 0.32, 0.20)
	var belly_c = Color(0.50, 0.40, 0.28)
	var eye_c = Color(0.9, 0.7, 0.1)
	var eye_br = Color(1.0, 0.85, 0.3)
	var nose_c = Color(0.15, 0.10, 0.08)
	var teeth = Color(0.92, 0.90, 0.84)
	var claw = Color(0.85, 0.82, 0.72)
	var tongue = Color(0.7, 0.25, 0.25)
	var ol = Color(0.10, 0.06, 0.03)

	# Ears (pointed, on top)
	_fill(img, 18, 0, 6, 8, fur_c)
	_fill(img, 20, 0, 4, 4, fur_dk)
	_fill(img, 21, 2, 2, 3, Color(0.55, 0.35, 0.30))
	_fill(img, 40, 0, 6, 8, fur_c)
	_fill(img, 40, 0, 4, 4, fur_dk)
	_fill(img, 41, 2, 2, 3, Color(0.55, 0.35, 0.30))

	# Head (wolf-like, elongated)
	_fill(img, 20, 6, 24, 14, fur_c)
	_fill(img, 18, 8, 28, 10, fur_c)
	_fill(img, 22, 4, 20, 4, fur_dk)
	# Brow
	_fill(img, 20, 8, 24, 3, fur_dk)

	# Eyes (feral, yellow)
	_fill(img, 22, 10, 5, 4, Color(0.08, 0.05, 0.03))
	_fill(img, 37, 10, 5, 4, Color(0.08, 0.05, 0.03))
	_fill(img, 23, 11, 3, 2, eye_c)
	_fill(img, 38, 11, 3, 2, eye_c)
	_px(img, 24, 11, eye_br)
	_px(img, 39, 11, eye_br)

	# Snout (protruding)
	_fill(img, 26, 14, 12, 6, fur_lt)
	_fill(img, 24, 16, 16, 4, fur_c)
	# Nose
	_fill(img, 30, 14, 4, 3, nose_c)
	# Open mouth
	_fill(img, 26, 18, 12, 4, Color(0.2, 0.08, 0.08))
	_fill(img, 28, 19, 8, 2, tongue)
	# Fangs
	_fill(img, 27, 18, 2, 3, teeth)
	_fill(img, 35, 18, 2, 3, teeth)
	_px(img, 30, 18, teeth)
	_px(img, 33, 18, teeth)

	# Fur ruff (neck/chest)
	_fill(img, 16, 20, 32, 4, fur_lt)
	_fill(img, 18, 22, 28, 3, belly_c)

	# Hunched torso
	_fill(img, 14, 24, 36, 8, fur_c)
	_fill(img, 12, 28, 40, 8, fur_dk)
	_fill(img, 14, 36, 36, 6, fur_c)

	# Chest fur
	_fill(img, 24, 26, 16, 10, belly_c)

	# Arms (long, muscular, reaching forward)
	_fill(img, 4, 24, 8, 6, fur_c)
	_fill(img, 0, 28, 8, 12, fur_dk)
	_fill(img, 52, 24, 8, 6, fur_c)
	_fill(img, 56, 28, 8, 12, fur_dk)

	# Clawed hands
	_fill(img, 0, 38, 8, 4, fur_c)
	_px(img, 0, 42, claw)
	_px(img, 2, 43, claw)
	_px(img, 4, 42, claw)
	_px(img, 6, 43, claw)
	_fill(img, 56, 38, 8, 4, fur_c)
	_px(img, 57, 42, claw)
	_px(img, 59, 43, claw)
	_px(img, 61, 42, claw)
	_px(img, 63, 43, claw)

	# Legs (digitigrade, powerful)
	_fill(img, 18, 42, 10, 8, fur_c)
	_fill(img, 16, 48, 8, 6, fur_dk)
	_fill(img, 36, 42, 10, 8, fur_c)
	_fill(img, 40, 48, 8, 6, fur_dk)

	# Feet with claws
	_fill(img, 12, 54, 14, 4, fur_dk)
	_fill(img, 38, 54, 14, 4, fur_dk)
	_px(img, 12, 58, claw)
	_px(img, 16, 58, claw)
	_px(img, 38, 58, claw)
	_px(img, 42, 58, claw)

	# Tail (bushy)
	_fill(img, 48, 36, 8, 4, fur_c)
	_fill(img, 54, 34, 6, 3, fur_dk)
	_fill(img, 58, 32, 4, 4, fur_lt)

	_outline(img, ol)
	_save(img, "castle_werewolf.png")

# ==================== CASTLE BANSHEE ====================
func _generate_castle_banshee() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var ghost = Color(0.55, 0.62, 0.78)
	var ghost_dk = Color(0.38, 0.45, 0.62)
	var ghost_lt = Color(0.72, 0.78, 0.88)
	var hair_c = Color(0.65, 0.72, 0.85)
	var hair_dk = Color(0.48, 0.55, 0.72)
	var eye_c = Color(0.6, 0.85, 1.0)
	var eye_br = Color(0.8, 0.95, 1.0)
	var mouth = Color(0.2, 0.25, 0.35)
	var aura = Color(0.5, 0.6, 0.8, 0.25)
	var tear = Color(0.4, 0.5, 0.7, 0.6)
	var ol = Color(0.2, 0.25, 0.38)

	# Ghostly aura
	_circle(img, 32, 28, 26, aura)
	_circle(img, 32, 26, 20, Color(0.5, 0.6, 0.8, 0.15))

	# Flowing hair (spreads wide)
	_fill(img, 6, 4, 14, 30, hair_dk)
	_fill(img, 44, 4, 14, 30, hair_dk)
	_fill(img, 8, 6, 10, 26, hair_c)
	_fill(img, 46, 6, 10, 26, hair_c)
	_fill(img, 4, 10, 6, 20, hair_dk)
	_fill(img, 54, 10, 6, 20, hair_dk)
	# Hair flowing upward at tips
	_fill(img, 2, 6, 6, 8, hair_c)
	_fill(img, 56, 6, 6, 8, hair_c)
	_fill(img, 0, 4, 4, 6, hair_dk)
	_fill(img, 60, 4, 4, 6, hair_dk)

	# Hair on top
	_fill(img, 18, 0, 28, 6, hair_c)
	_fill(img, 16, 2, 32, 6, hair_dk)
	_fill(img, 20, 0, 24, 3, hair_c)

	# Face (pale, spectral)
	_fill(img, 22, 6, 20, 16, ghost)
	_fill(img, 20, 8, 24, 12, ghost)
	_fill(img, 24, 6, 16, 2, ghost_lt)

	# Hollow eyes (large, glowing)
	_fill(img, 24, 10, 6, 5, Color(0.1, 0.12, 0.18))
	_fill(img, 34, 10, 6, 5, Color(0.1, 0.12, 0.18))
	_fill(img, 25, 11, 4, 3, eye_c)
	_fill(img, 35, 11, 4, 3, eye_c)
	_px(img, 26, 12, eye_br)
	_px(img, 27, 12, eye_br)
	_px(img, 36, 12, eye_br)
	_px(img, 37, 12, eye_br)

	# Tear streaks
	_line_v(img, 26, 15, 20, tear)
	_line_v(img, 37, 15, 20, tear)

	# Screaming mouth (open wide)
	_fill(img, 28, 18, 8, 6, mouth)
	_fill(img, 26, 19, 12, 4, mouth)
	# Mouth highlight
	_fill(img, 30, 19, 4, 2, Color(0.15, 0.18, 0.28))

	# Ghostly body (fading downward)
	_fill(img, 20, 22, 24, 8, ghost)
	_fill(img, 18, 28, 28, 8, ghost_dk)
	_fill(img, 16, 34, 32, 6, ghost)
	_fill(img, 18, 40, 28, 6, Color(ghost.r, ghost.g, ghost.b, 0.8))
	_fill(img, 20, 46, 24, 6, Color(ghost.r, ghost.g, ghost.b, 0.6))
	_fill(img, 22, 52, 20, 4, Color(ghost.r, ghost.g, ghost.b, 0.4))
	_fill(img, 26, 56, 12, 4, Color(ghost.r, ghost.g, ghost.b, 0.2))
	_fill(img, 30, 60, 4, 3, Color(ghost.r, ghost.g, ghost.b, 0.1))

	# Arms (reaching out, ghostly)
	_fill(img, 12, 26, 6, 4, ghost)
	_fill(img, 8, 28, 6, 6, ghost_dk)
	_fill(img, 4, 30, 6, 4, ghost)
	_fill(img, 46, 26, 6, 4, ghost)
	_fill(img, 50, 28, 6, 6, ghost_dk)
	_fill(img, 54, 30, 6, 4, ghost)

	# Ghostly wisps from arms
	_px(img, 2, 32, ghost_lt)
	_px(img, 60, 32, ghost_lt)

	_outline(img, ol)
	_save(img, "castle_banshee.png")

# ==================== CANDY WITCH ====================
func _generate_candy_witch() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var dress = Color(0.72, 0.18, 0.48)
	var dress_dk = Color(0.52, 0.10, 0.35)
	var dress_lt = Color(0.85, 0.30, 0.58)
	var skin_c = Color(0.95, 0.80, 0.75)
	var skin_dk = Color(0.82, 0.68, 0.62)
	var hat_c = Color(0.58, 0.12, 0.42)
	var hat_dk = Color(0.42, 0.06, 0.30)
	var hat_band = Color(0.9, 0.4, 0.7)
	var hair_c = Color(0.85, 0.45, 0.65)
	var hair_dk = Color(0.68, 0.32, 0.50)
	var eye_c = Color(0.9, 0.35, 0.7)
	var eye_br = Color(1.0, 0.5, 0.85)
	var wand_c = Color(0.9, 0.5, 0.75)
	var star = Color(1.0, 0.85, 0.3)
	var candy = Color(0.4, 0.85, 0.5)
	var ol = Color(0.25, 0.06, 0.18)

	# Witch hat
	# Brim
	_fill(img, 14, 14, 36, 3, hat_c)
	_fill(img, 12, 15, 40, 2, hat_dk)
	# Hat body
	_fill(img, 22, 6, 20, 8, hat_c)
	_fill(img, 24, 4, 16, 4, hat_c)
	_fill(img, 26, 2, 12, 3, hat_dk)
	_fill(img, 28, 0, 8, 3, hat_c)
	_fill(img, 30, 0, 4, 1, hat_dk)
	# Hat band
	_fill(img, 22, 12, 20, 2, hat_band)
	# Candy decoration on hat
	_fill(img, 42, 10, 4, 4, candy)
	_px(img, 43, 11, Color(0.5, 0.95, 0.6))

	# Hair (flowing from under hat)
	_fill(img, 14, 16, 8, 14, hair_c)
	_fill(img, 42, 16, 8, 14, hair_c)
	_fill(img, 12, 18, 6, 10, hair_dk)
	_fill(img, 46, 18, 6, 10, hair_dk)
	# Hair curls at bottom
	_circle(img, 14, 30, 3, hair_c)
	_circle(img, 48, 30, 3, hair_c)

	# Face
	_fill(img, 22, 16, 20, 12, skin_c)
	_fill(img, 20, 18, 24, 8, skin_c)
	_fill(img, 24, 16, 16, 2, Color(0.98, 0.85, 0.80))

	# Eyes (large, cute but menacing)
	_fill(img, 24, 20, 5, 4, Color.WHITE)
	_fill(img, 35, 20, 5, 4, Color.WHITE)
	_fill(img, 25, 21, 3, 2, eye_c)
	_fill(img, 36, 21, 3, 2, eye_c)
	_px(img, 26, 21, eye_br)
	_px(img, 37, 21, eye_br)
	# Eyelashes
	_px(img, 23, 20, hat_dk)
	_px(img, 29, 20, hat_dk)
	_px(img, 34, 20, hat_dk)
	_px(img, 40, 20, hat_dk)

	# Smile (devious)
	_fill(img, 28, 26, 8, 1, dress_dk)
	_px(img, 27, 25, dress_dk)
	_px(img, 36, 25, dress_dk)

	# Dress body
	_fill(img, 20, 28, 24, 8, dress)
	_fill(img, 18, 32, 28, 8, dress)
	_fill(img, 16, 38, 32, 8, dress_dk)
	_fill(img, 14, 44, 36, 6, dress)
	_fill(img, 12, 48, 40, 6, dress_dk)

	# Dress highlights/stripes
	_fill(img, 24, 30, 3, 18, dress_lt)
	_fill(img, 36, 32, 3, 16, dress_lt)

	# Candy buttons
	_fill(img, 30, 30, 4, 3, candy)
	_fill(img, 30, 36, 4, 3, Color(1.0, 0.5, 0.5))
	_fill(img, 30, 42, 4, 3, Color(0.5, 0.5, 1.0))

	# Arms
	_fill(img, 10, 28, 6, 4, dress)
	_fill(img, 8, 32, 5, 8, skin_c)

	# Wand (right hand)
	_fill(img, 50, 28, 6, 4, dress)
	_fill(img, 52, 32, 4, 4, skin_c)
	_line_v(img, 54, 14, 32, wand_c)
	_line_v(img, 55, 16, 30, Color(0.7, 0.35, 0.55))
	# Star on wand tip
	_fill(img, 52, 10, 6, 6, star)
	_fill(img, 50, 12, 10, 2, star)
	_px(img, 55, 13, Color(1.0, 1.0, 0.6))

	# Tattered dress bottom
	for i in range(6):
		var bx = 14 + i * 6
		_fill(img, bx, 52 + (i % 2) * 2, 3, 4 - (i % 2), dress)

	_outline(img, ol)
	_save(img, "candy_witch.png")

# ==================== CANDY DRAGON ====================
func _generate_candy_dragon() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var body_c = Color(0.35, 0.75, 0.50)
	var body_dk = Color(0.22, 0.58, 0.35)
	var body_lt = Color(0.50, 0.88, 0.62)
	var belly_c = Color(0.85, 0.90, 0.55)
	var wing_c = Color(0.85, 0.50, 0.70)
	var wing_dk = Color(0.68, 0.35, 0.55)
	var wing_lt = Color(0.95, 0.65, 0.80)
	var eye_c = Color(0.9, 0.4, 0.65)
	var eye_br = Color(1.0, 0.6, 0.8)
	var horn = Color(0.90, 0.75, 0.4)
	var horn_dk = Color(0.72, 0.58, 0.28)
	var teeth = Color(0.95, 0.93, 0.88)
	var candy_r = Color(1.0, 0.4, 0.4)
	var candy_b = Color(0.4, 0.5, 1.0)
	var ol = Color(0.12, 0.30, 0.18)

	# Wings (spread, candy-colored)
	# Left wing
	_fill(img, 2, 14, 14, 4, wing_c)
	_fill(img, 0, 10, 12, 4, wing_dk)
	_fill(img, 4, 18, 12, 4, wing_c)
	_fill(img, 6, 22, 10, 3, wing_dk)
	# Wing membrane details
	_line_v(img, 4, 12, 20, wing_lt)
	_line_v(img, 8, 10, 22, wing_lt)
	# Candy swirl on wing
	_px(img, 6, 14, candy_r)
	_px(img, 10, 16, candy_b)

	# Right wing
	_fill(img, 48, 14, 14, 4, wing_c)
	_fill(img, 52, 10, 12, 4, wing_dk)
	_fill(img, 48, 18, 12, 4, wing_c)
	_fill(img, 48, 22, 10, 3, wing_dk)
	_line_v(img, 56, 12, 20, wing_lt)
	_line_v(img, 60, 10, 22, wing_lt)
	_px(img, 54, 14, candy_r)
	_px(img, 58, 16, candy_b)

	# Horns (candy-corn colored)
	_fill(img, 18, 2, 4, 6, horn)
	_fill(img, 16, 0, 4, 3, horn_dk)
	_fill(img, 42, 2, 4, 6, horn)
	_fill(img, 44, 0, 4, 3, horn_dk)
	# Candy-corn tip
	_px(img, 17, 0, Color.WHITE)
	_px(img, 45, 0, Color.WHITE)

	# Head (round, cute-dragon)
	_fill(img, 22, 6, 20, 14, body_c)
	_fill(img, 20, 8, 24, 10, body_c)
	_fill(img, 24, 4, 16, 4, body_dk)
	# Cheeks
	_circle(img, 22, 14, 3, body_lt)
	_circle(img, 42, 14, 3, body_lt)

	# Eyes (large, sparkly)
	_fill(img, 24, 10, 5, 5, Color.WHITE)
	_fill(img, 35, 10, 5, 5, Color.WHITE)
	_fill(img, 25, 11, 3, 3, eye_c)
	_fill(img, 36, 11, 3, 3, eye_c)
	_px(img, 26, 11, eye_br)
	_px(img, 37, 11, eye_br)
	# Sparkle in eyes
	_px(img, 26, 11, Color.WHITE)
	_px(img, 37, 11, Color.WHITE)

	# Snout
	_fill(img, 28, 14, 8, 4, body_lt)
	# Nostrils
	_px(img, 30, 15, body_dk)
	_px(img, 34, 15, body_dk)

	# Smile with tiny fangs
	_fill(img, 28, 18, 8, 2, Color(0.18, 0.35, 0.22))
	_px(img, 29, 18, teeth)
	_px(img, 35, 18, teeth)

	# Body (round, dragon shape)
	_fill(img, 18, 20, 28, 10, body_c)
	_fill(img, 16, 24, 32, 10, body_dk)
	_fill(img, 18, 34, 28, 8, body_c)
	_fill(img, 20, 42, 24, 4, body_dk)

	# Belly
	_fill(img, 24, 24, 16, 14, belly_c)
	_fill(img, 26, 26, 12, 10, Color(0.90, 0.92, 0.60))

	# Candy spots on body
	_circle(img, 20, 28, 2, candy_r)
	_circle(img, 44, 32, 2, candy_b)
	_circle(img, 22, 38, 2, Color(0.9, 0.7, 0.2))

	# Arms (short, cute)
	_fill(img, 10, 24, 6, 4, body_c)
	_fill(img, 8, 28, 6, 6, body_dk)
	_fill(img, 48, 24, 6, 4, body_c)
	_fill(img, 50, 28, 6, 6, body_dk)

	# Legs (stubby)
	_fill(img, 18, 44, 10, 10, body_c)
	_fill(img, 36, 44, 10, 10, body_c)
	# Feet
	_fill(img, 16, 52, 14, 4, body_dk)
	_fill(img, 34, 52, 14, 4, body_dk)

	# Tail (curled, with candy-stripe)
	_fill(img, 44, 38, 8, 4, body_c)
	_fill(img, 50, 36, 6, 3, body_dk)
	_fill(img, 54, 34, 4, 4, body_c)
	_fill(img, 56, 32, 4, 4, body_lt)
	# Candy stripe on tail
	_px(img, 46, 39, candy_r)
	_px(img, 52, 37, candy_b)

	# Spikes along back (candy-colored)
	_px(img, 28, 20, candy_r)
	_px(img, 32, 19, candy_b)
	_px(img, 36, 20, Color(0.9, 0.7, 0.2))

	_outline(img, ol)
	_save(img, "candy_dragon.png")
