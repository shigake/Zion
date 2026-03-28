extends SceneTree

## Generates pixel art sprites for ALL enemy types.
## Run headless: godot --headless --path game --script res://scripts/tools/enemy_sprite_generator.gd

const SPRITE_SIZE := 32
const OUT_DIR := "res://assets/sprites/enemies/"

func _init() -> void:
	# slime.png already exists, skip it
	_generate_slime_big()
	_generate_bat()
	_generate_skeleton()
	_generate_skeleton_archer()
	_generate_zombie_runner()
	_generate_ghost()
	_generate_ghost_white()
	_generate_ghost_green()
	_generate_ghost_blue()
	_generate_ghost_red()
	_generate_tank()
	_generate_bomber()
	_generate_swarm()
	_generate_mimic()
	_generate_tooth_fairy()
	print("All enemy sprites generated!")
	quit()

func _save_sprite(img: Image, filename: String) -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var path = OUT_DIR + filename
	img.save_png(path)
	print("Saved: ", path)

# ==================== HELPERS ====================
func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, mini(x + w, SPRITE_SIZE)):
		for py in range(y, mini(y + h, SPRITE_SIZE)):
			if px >= 0 and py >= 0:
				img.set_pixel(px, py, color)

func _add_outline(img: Image, color: Color) -> void:
	var outline_img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	for x in range(SPRITE_SIZE):
		for y in range(SPRITE_SIZE):
			if img.get_pixel(x, y).a > 0:
				continue
			var has_neighbor := false
			for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx = x + offset.x
				var ny = y + offset.y
				if nx >= 0 and nx < SPRITE_SIZE and ny >= 0 and ny < SPRITE_SIZE:
					if img.get_pixel(nx, ny).a > 0:
						has_neighbor = true
						break
			if has_neighbor:
				outline_img.set_pixel(x, y, color)
	for x in range(SPRITE_SIZE):
		for y in range(SPRITE_SIZE):
			if outline_img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, outline_img.get_pixel(x, y))

# ==================== SLIME BIG ====================
func _generate_slime_big() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body = Color(0.2, 0.6, 0.2)
	var body_light = Color(0.3, 0.7, 0.3)
	var body_dark = Color(0.12, 0.45, 0.12)
	var eye_white = Color(0.95, 0.95, 0.95)
	var pupil = Color(0.1, 0.1, 0.1)
	var inner_slime = Color(0.35, 0.85, 0.35, 0.7)
	var outline = Color(0.08, 0.25, 0.08)

	# Large blob body (fills most of the 32x32)
	_fill_rect(img, 10, 5, 12, 2, body)
	_fill_rect(img, 7, 7, 18, 2, body)
	_fill_rect(img, 5, 9, 22, 2, body)
	_fill_rect(img, 4, 11, 24, 10, body)
	_fill_rect(img, 5, 21, 22, 2, body)
	_fill_rect(img, 6, 23, 20, 2, body_dark)
	_fill_rect(img, 8, 25, 16, 2, body_dark)
	_fill_rect(img, 10, 27, 12, 2, body_dark)

	# Highlight top-left
	_fill_rect(img, 9, 7, 4, 3, body_light)
	_fill_rect(img, 7, 10, 3, 2, body_light)

	# Angry eyes (smaller, angled brows)
	# Left eye
	_fill_rect(img, 9, 14, 4, 4, eye_white)
	_fill_rect(img, 10, 15, 2, 2, pupil)
	# Right eye
	_fill_rect(img, 19, 14, 4, 4, eye_white)
	_fill_rect(img, 20, 15, 2, 2, pupil)
	# Angry eyebrows (diagonal lines above eyes)
	img.set_pixel(9, 13, pupil)
	img.set_pixel(10, 12, pupil)
	img.set_pixel(11, 12, pupil)
	img.set_pixel(22, 13, pupil)
	img.set_pixel(21, 12, pupil)
	img.set_pixel(20, 12, pupil)

	# Angry mouth (wide frown with teeth)
	_fill_rect(img, 12, 20, 8, 2, Color(0.1, 0.35, 0.1))
	img.set_pixel(13, 20, eye_white)
	img.set_pixel(15, 20, eye_white)
	img.set_pixel(17, 20, eye_white)
	img.set_pixel(19, 20, eye_white)

	# Inner mini slimes visible inside body
	_fill_rect(img, 8, 18, 3, 3, inner_slime)
	img.set_pixel(9, 18, Color(0.9, 0.9, 0.9, 0.6))
	_fill_rect(img, 21, 16, 3, 3, inner_slime)
	img.set_pixel(22, 16, Color(0.9, 0.9, 0.9, 0.6))
	_fill_rect(img, 14, 23, 3, 2, inner_slime)
	img.set_pixel(15, 23, Color(0.9, 0.9, 0.9, 0.6))

	# Bottom darkening
	for x in range(4, 28):
		for y in range(22, 30):
			var c = img.get_pixel(x, y)
			if c.a > 0:
				img.set_pixel(x, y, c.darkened(0.15))

	_add_outline(img, outline)
	_save_sprite(img, "slime_big.png")

# ==================== BAT ====================
func _generate_bat() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body = Color(0.35, 0.18, 0.45)
	var wing = Color(0.45, 0.25, 0.55)
	var wing_dark = Color(0.28, 0.12, 0.38)
	var wing_membrane = Color(0.38, 0.2, 0.48)
	var eye = Color(0.95, 0.85, 0.1)
	var fang = Color(0.95, 0.95, 0.95)
	var ear = Color(0.5, 0.3, 0.6)
	var outline = Color(0.15, 0.05, 0.2)

	# Body (center, small oval)
	_fill_rect(img, 13, 12, 6, 8, body)
	_fill_rect(img, 12, 14, 8, 4, body)

	# Head (top center)
	_fill_rect(img, 12, 9, 8, 5, body)
	_fill_rect(img, 13, 8, 6, 1, body)

	# Ears (pointy triangles)
	img.set_pixel(12, 7, ear)
	img.set_pixel(11, 6, ear)
	img.set_pixel(11, 7, ear)
	img.set_pixel(19, 7, ear)
	img.set_pixel(20, 6, ear)
	img.set_pixel(20, 7, ear)

	# Yellow eyes (glowing)
	_fill_rect(img, 13, 11, 2, 2, eye)
	_fill_rect(img, 17, 11, 2, 2, eye)
	img.set_pixel(13, 11, Color(1.0, 1.0, 0.5))
	img.set_pixel(17, 11, Color(1.0, 1.0, 0.5))

	# Fangs
	img.set_pixel(14, 14, fang)
	img.set_pixel(17, 14, fang)
	img.set_pixel(14, 15, fang)
	img.set_pixel(17, 15, fang)

	# Mouth
	_fill_rect(img, 14, 13, 4, 1, Color(0.2, 0.05, 0.1))

	# Left wing (spread wide)
	_fill_rect(img, 4, 11, 8, 2, wing)
	_fill_rect(img, 2, 13, 10, 2, wing)
	_fill_rect(img, 1, 15, 11, 2, wing_membrane)
	_fill_rect(img, 2, 17, 10, 2, wing_membrane)
	_fill_rect(img, 4, 19, 8, 1, wing_dark)
	# Wing bone lines
	for i in range(8):
		img.set_pixel(4 + i, 12 + i / 2, wing_dark)
	img.set_pixel(3, 13, wing_dark)
	img.set_pixel(2, 15, wing_dark)

	# Right wing (mirror)
	_fill_rect(img, 20, 11, 8, 2, wing)
	_fill_rect(img, 20, 13, 10, 2, wing)
	_fill_rect(img, 20, 15, 11, 2, wing_membrane)
	_fill_rect(img, 20, 17, 10, 2, wing_membrane)
	_fill_rect(img, 20, 19, 8, 1, wing_dark)
	for i in range(8):
		img.set_pixel(27 - i, 12 + i / 2, wing_dark)
	img.set_pixel(28, 13, wing_dark)
	img.set_pixel(29, 15, wing_dark)

	# Small feet
	img.set_pixel(14, 20, body)
	img.set_pixel(17, 20, body)

	_add_outline(img, outline)
	_save_sprite(img, "bat.png")

# ==================== SKELETON ====================
func _generate_skeleton() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var bone = Color(0.9, 0.88, 0.82)
	var bone_dark = Color(0.7, 0.68, 0.62)
	var eye_socket = Color(0.1, 0.1, 0.1)
	var teeth = Color(0.95, 0.93, 0.88)
	var outline = Color(0.2, 0.18, 0.15)

	# Skull (rows 3-10)
	_fill_rect(img, 11, 3, 10, 2, bone)
	_fill_rect(img, 10, 5, 12, 4, bone)
	_fill_rect(img, 11, 9, 10, 2, bone)

	# Skull top curve
	_fill_rect(img, 12, 2, 8, 1, bone)

	# Eye sockets (dark holes)
	_fill_rect(img, 12, 6, 3, 2, eye_socket)
	_fill_rect(img, 17, 6, 3, 2, eye_socket)
	# Eye glow (tiny red dot)
	img.set_pixel(13, 6, Color(0.8, 0.1, 0.1))
	img.set_pixel(18, 6, Color(0.8, 0.1, 0.1))

	# Nose hole
	img.set_pixel(15, 8, eye_socket)
	img.set_pixel(16, 8, eye_socket)

	# Teeth/jaw
	_fill_rect(img, 12, 9, 8, 2, teeth)
	img.set_pixel(13, 9, eye_socket)
	img.set_pixel(15, 9, eye_socket)
	img.set_pixel(17, 9, eye_socket)
	img.set_pixel(19, 9, eye_socket)

	# Neck
	_fill_rect(img, 14, 11, 4, 1, bone)

	# Ribcage (rows 12-18)
	# Spine
	_fill_rect(img, 15, 12, 2, 8, bone_dark)
	# Ribs (horizontal lines with gaps)
	_fill_rect(img, 10, 12, 12, 1, bone)
	_fill_rect(img, 10, 14, 12, 1, bone)
	_fill_rect(img, 11, 16, 10, 1, bone)
	_fill_rect(img, 12, 18, 8, 1, bone)
	# Rib gaps
	img.set_pixel(13, 12, Color(0, 0, 0, 0))
	img.set_pixel(18, 12, Color(0, 0, 0, 0))
	img.set_pixel(13, 14, Color(0, 0, 0, 0))
	img.set_pixel(18, 14, Color(0, 0, 0, 0))

	# Pelvis
	_fill_rect(img, 11, 19, 10, 2, bone_dark)

	# Arms (thin bone lines)
	# Left arm
	_fill_rect(img, 8, 12, 2, 1, bone)
	_fill_rect(img, 7, 13, 2, 3, bone)
	_fill_rect(img, 6, 16, 2, 2, bone)
	img.set_pixel(5, 18, bone)
	img.set_pixel(6, 18, bone)
	img.set_pixel(4, 18, bone_dark)
	# Right arm
	_fill_rect(img, 22, 12, 2, 1, bone)
	_fill_rect(img, 23, 13, 2, 3, bone)
	_fill_rect(img, 24, 16, 2, 2, bone)
	img.set_pixel(25, 18, bone)
	img.set_pixel(26, 18, bone)
	img.set_pixel(27, 18, bone_dark)

	# Legs
	# Left leg
	_fill_rect(img, 12, 21, 2, 5, bone)
	_fill_rect(img, 11, 26, 4, 2, bone_dark)
	# Right leg
	_fill_rect(img, 18, 21, 2, 5, bone)
	_fill_rect(img, 17, 26, 4, 2, bone_dark)

	_add_outline(img, outline)
	_save_sprite(img, "skeleton.png")

# ==================== SKELETON ARCHER ====================
func _generate_skeleton_archer() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var bone = Color(0.9, 0.88, 0.82)
	var bone_dark = Color(0.7, 0.68, 0.62)
	var eye_socket = Color(0.1, 0.1, 0.1)
	var teeth = Color(0.95, 0.93, 0.88)
	var bow_wood = Color(0.55, 0.35, 0.15)
	var bow_string = Color(0.8, 0.75, 0.65)
	var arrow = Color(0.6, 0.4, 0.2)
	var arrow_tip = Color(0.6, 0.62, 0.65)
	var outline = Color(0.2, 0.18, 0.15)

	# Skull (same as skeleton but shifted left a bit to make room for bow)
	_fill_rect(img, 9, 3, 10, 2, bone)
	_fill_rect(img, 8, 5, 12, 4, bone)
	_fill_rect(img, 9, 9, 10, 2, bone)
	_fill_rect(img, 10, 2, 8, 1, bone)

	# Eye sockets
	_fill_rect(img, 10, 6, 3, 2, eye_socket)
	_fill_rect(img, 15, 6, 3, 2, eye_socket)
	img.set_pixel(11, 6, Color(0.8, 0.1, 0.1))
	img.set_pixel(16, 6, Color(0.8, 0.1, 0.1))

	# Nose and teeth
	img.set_pixel(13, 8, eye_socket)
	img.set_pixel(14, 8, eye_socket)
	_fill_rect(img, 10, 9, 8, 2, teeth)
	img.set_pixel(11, 9, eye_socket)
	img.set_pixel(13, 9, eye_socket)
	img.set_pixel(15, 9, eye_socket)
	img.set_pixel(17, 9, eye_socket)

	# Neck
	_fill_rect(img, 12, 11, 4, 1, bone)

	# Ribcage
	_fill_rect(img, 13, 12, 2, 8, bone_dark)
	_fill_rect(img, 8, 12, 12, 1, bone)
	_fill_rect(img, 8, 14, 12, 1, bone)
	_fill_rect(img, 9, 16, 10, 1, bone)
	_fill_rect(img, 10, 18, 8, 1, bone)

	# Pelvis
	_fill_rect(img, 9, 19, 10, 2, bone_dark)

	# Left arm (holding bow outward)
	_fill_rect(img, 5, 12, 3, 1, bone)
	_fill_rect(img, 4, 13, 2, 4, bone)
	img.set_pixel(3, 17, bone)

	# Right arm (pulling string back)
	_fill_rect(img, 20, 12, 3, 1, bone)
	_fill_rect(img, 22, 13, 2, 2, bone)
	_fill_rect(img, 23, 15, 2, 1, bone)

	# Bow (left side, curved)
	img.set_pixel(2, 8, bow_wood)
	img.set_pixel(2, 9, bow_wood)
	img.set_pixel(3, 10, bow_wood)
	img.set_pixel(3, 11, bow_wood)
	img.set_pixel(3, 12, bow_wood)
	img.set_pixel(3, 13, bow_wood)
	img.set_pixel(3, 14, bow_wood)
	img.set_pixel(3, 15, bow_wood)
	img.set_pixel(3, 16, bow_wood)
	img.set_pixel(3, 17, bow_wood)
	img.set_pixel(3, 18, bow_wood)
	img.set_pixel(2, 19, bow_wood)
	img.set_pixel(2, 20, bow_wood)

	# Bow string
	for y in range(8, 21):
		img.set_pixel(4, y, bow_string)

	# Arrow (horizontal, nocked)
	for x in range(4, 25):
		img.set_pixel(x, 14, arrow)
	# Arrow tip
	img.set_pixel(3, 14, arrow_tip)
	img.set_pixel(2, 13, arrow_tip)
	img.set_pixel(2, 15, arrow_tip)
	# Arrow fletching
	img.set_pixel(24, 13, Color(0.8, 0.2, 0.2))
	img.set_pixel(24, 15, Color(0.8, 0.2, 0.2))
	img.set_pixel(25, 13, Color(0.8, 0.2, 0.2))
	img.set_pixel(25, 15, Color(0.8, 0.2, 0.2))

	# Legs
	_fill_rect(img, 10, 21, 2, 5, bone)
	_fill_rect(img, 9, 26, 4, 2, bone_dark)
	_fill_rect(img, 16, 21, 2, 5, bone)
	_fill_rect(img, 15, 26, 4, 2, bone_dark)

	_add_outline(img, outline)
	_save_sprite(img, "skeleton_archer.png")

# ==================== ZOMBIE RUNNER ====================
func _generate_zombie_runner() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var skin = Color(0.45, 0.55, 0.35)
	var skin_dark = Color(0.35, 0.42, 0.28)
	var cloth = Color(0.35, 0.3, 0.28)
	var cloth_torn = Color(0.42, 0.38, 0.32)
	var eye = Color(0.9, 0.85, 0.2)
	var mouth = Color(0.5, 0.15, 0.1)
	var hair = Color(0.25, 0.2, 0.18)
	var outline = Color(0.15, 0.18, 0.1)

	# Head (tilted forward, hunched)
	_fill_rect(img, 13, 4, 8, 3, hair)
	_fill_rect(img, 12, 7, 9, 5, skin)
	_fill_rect(img, 14, 5, 6, 2, hair)

	# Eyes (uneven, zombie-like)
	_fill_rect(img, 14, 8, 2, 2, eye)
	img.set_pixel(14, 8, Color(0.1, 0.1, 0.1))
	_fill_rect(img, 18, 9, 2, 1, eye)
	img.set_pixel(18, 9, Color(0.1, 0.1, 0.1))

	# Open mouth (groaning)
	_fill_rect(img, 15, 10, 4, 2, mouth)
	img.set_pixel(16, 10, Color(0.9, 0.9, 0.8))
	img.set_pixel(18, 10, Color(0.9, 0.9, 0.8))

	# Neck (tilted forward)
	_fill_rect(img, 15, 12, 3, 1, skin_dark)

	# Torso (hunched, leaning forward)
	_fill_rect(img, 11, 13, 10, 5, cloth)
	_fill_rect(img, 12, 18, 8, 2, cloth)
	# Torn shirt details
	img.set_pixel(13, 17, skin)
	img.set_pixel(14, 16, skin)
	img.set_pixel(18, 15, skin)
	_fill_rect(img, 11, 13, 2, 3, cloth_torn)

	# Exposed ribs/skin through tears
	img.set_pixel(15, 14, skin_dark)
	img.set_pixel(16, 15, skin_dark)

	# Arms (reaching forward, hunched)
	# Left arm (extended forward)
	_fill_rect(img, 8, 13, 3, 2, skin)
	_fill_rect(img, 6, 14, 2, 2, skin)
	_fill_rect(img, 4, 15, 2, 2, skin_dark)
	# Right arm (dragging)
	_fill_rect(img, 21, 14, 3, 2, skin)
	_fill_rect(img, 23, 16, 2, 3, skin)
	_fill_rect(img, 24, 19, 2, 1, skin_dark)

	# Torn pants
	_fill_rect(img, 11, 20, 4, 4, cloth)
	_fill_rect(img, 17, 20, 4, 3, cloth)
	# Exposed skin on legs
	img.set_pixel(12, 23, skin)
	img.set_pixel(19, 22, skin)

	# Feet (shuffling)
	_fill_rect(img, 10, 24, 5, 2, Color(0.3, 0.22, 0.15))
	_fill_rect(img, 17, 23, 5, 2, Color(0.3, 0.22, 0.15))

	# Blood drips
	img.set_pixel(15, 12, Color(0.6, 0.1, 0.05))
	img.set_pixel(20, 17, Color(0.6, 0.1, 0.05))
	img.set_pixel(13, 19, Color(0.6, 0.1, 0.05))

	_add_outline(img, outline)
	_save_sprite(img, "zombie_runner.png")

# ==================== GHOST (base white) ====================
func _generate_ghost() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body = Color(0.92, 0.92, 0.95, 0.8)
	var body_light = Color(0.97, 0.97, 1.0, 0.85)
	var body_dark = Color(0.8, 0.8, 0.85, 0.7)
	var eye = Color(0.05, 0.05, 0.1)
	var mouth = Color(0.15, 0.15, 0.2, 0.8)
	var outline = Color(0.4, 0.4, 0.5)

	# Ghost body (rounded top, wavy bottom)
	_fill_rect(img, 13, 5, 6, 2, body)
	_fill_rect(img, 11, 7, 10, 2, body)
	_fill_rect(img, 9, 9, 14, 2, body)
	_fill_rect(img, 8, 11, 16, 8, body)
	_fill_rect(img, 7, 19, 18, 2, body)

	# Wavy bottom edge
	_fill_rect(img, 7, 21, 4, 2, body_dark)
	_fill_rect(img, 13, 21, 4, 3, body_dark)
	_fill_rect(img, 19, 21, 4, 2, body_dark)
	# Wave peaks
	_fill_rect(img, 10, 21, 4, 3, body)
	_fill_rect(img, 16, 21, 4, 3, body)
	_fill_rect(img, 22, 21, 3, 3, body)
	# Lowest wave tips
	img.set_pixel(8, 23, body_dark)
	img.set_pixel(14, 24, body_dark)
	img.set_pixel(20, 23, body_dark)

	# Highlight
	_fill_rect(img, 11, 8, 3, 3, body_light)
	img.set_pixel(12, 7, body_light)

	# Large black eyes
	_fill_rect(img, 10, 12, 4, 4, eye)
	_fill_rect(img, 18, 12, 4, 4, eye)
	# Eye shine
	img.set_pixel(11, 12, Color(0.6, 0.6, 0.7))
	img.set_pixel(19, 12, Color(0.6, 0.6, 0.7))

	# Small "o" mouth
	_fill_rect(img, 14, 17, 3, 2, mouth)
	img.set_pixel(15, 17, Color(0.3, 0.3, 0.4, 0.5))

	_add_outline(img, outline)
	_save_sprite(img, "ghost.png")

# ==================== GHOST WHITE ====================
func _generate_ghost_white() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body = Color(0.98, 0.98, 1.0, 0.9)
	var body_light = Color(1.0, 1.0, 1.0, 0.95)
	var body_dark = Color(0.88, 0.88, 0.95, 0.8)
	var eye = Color(0.3, 0.4, 0.8)
	var outline = Color(0.5, 0.5, 0.6)

	# Body shape (same as ghost)
	_fill_rect(img, 13, 5, 6, 2, body)
	_fill_rect(img, 11, 7, 10, 2, body)
	_fill_rect(img, 9, 9, 14, 2, body)
	_fill_rect(img, 8, 11, 16, 8, body)
	_fill_rect(img, 7, 19, 18, 2, body)

	# Wavy bottom
	_fill_rect(img, 7, 21, 4, 2, body_dark)
	_fill_rect(img, 13, 21, 4, 3, body_dark)
	_fill_rect(img, 19, 21, 4, 2, body_dark)
	_fill_rect(img, 10, 21, 4, 3, body)
	_fill_rect(img, 16, 21, 4, 3, body)
	_fill_rect(img, 22, 21, 3, 3, body)
	img.set_pixel(8, 23, body_dark)
	img.set_pixel(14, 24, body_dark)
	img.set_pixel(20, 23, body_dark)

	# Bright highlight
	_fill_rect(img, 11, 8, 3, 3, body_light)
	_fill_rect(img, 10, 9, 2, 2, body_light)

	# Blue tint eyes
	_fill_rect(img, 10, 12, 4, 4, eye)
	_fill_rect(img, 18, 12, 4, 4, eye)
	img.set_pixel(11, 12, Color(0.7, 0.8, 1.0))
	img.set_pixel(19, 12, Color(0.7, 0.8, 1.0))
	# Pupils
	_fill_rect(img, 11, 13, 2, 2, Color(0.1, 0.15, 0.4))
	_fill_rect(img, 19, 13, 2, 2, Color(0.1, 0.15, 0.4))

	# Gentle smile
	img.set_pixel(13, 17, Color(0.5, 0.5, 0.65))
	img.set_pixel(14, 18, Color(0.5, 0.5, 0.65))
	img.set_pixel(15, 18, Color(0.5, 0.5, 0.65))
	img.set_pixel(16, 18, Color(0.5, 0.5, 0.65))
	img.set_pixel(17, 17, Color(0.5, 0.5, 0.65))

	_add_outline(img, outline)
	_save_sprite(img, "ghost_white.png")

# ==================== GHOST GREEN ====================
func _generate_ghost_green() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body = Color(0.2, 0.75, 0.3, 0.8)
	var body_light = Color(0.35, 0.9, 0.45, 0.85)
	var body_dark = Color(0.12, 0.55, 0.18, 0.7)
	var eye = Color(0.4, 1.0, 0.4)
	var eye_pupil = Color(0.1, 0.3, 0.1)
	var outline = Color(0.05, 0.3, 0.08)

	# Body shape
	_fill_rect(img, 13, 5, 6, 2, body)
	_fill_rect(img, 11, 7, 10, 2, body)
	_fill_rect(img, 9, 9, 14, 2, body)
	_fill_rect(img, 8, 11, 16, 8, body)
	_fill_rect(img, 7, 19, 18, 2, body)

	# Wavy bottom
	_fill_rect(img, 7, 21, 4, 2, body_dark)
	_fill_rect(img, 13, 21, 4, 3, body_dark)
	_fill_rect(img, 19, 21, 4, 2, body_dark)
	_fill_rect(img, 10, 21, 4, 3, body)
	_fill_rect(img, 16, 21, 4, 3, body)
	_fill_rect(img, 22, 21, 3, 3, body)
	img.set_pixel(8, 23, body_dark)
	img.set_pixel(14, 24, body_dark)
	img.set_pixel(20, 23, body_dark)

	# Ectoplasm drips
	img.set_pixel(9, 22, body_dark)
	img.set_pixel(9, 23, body_dark)
	img.set_pixel(9, 24, body_dark)
	img.set_pixel(22, 22, body_dark)
	img.set_pixel(22, 23, body_dark)

	# Highlight
	_fill_rect(img, 11, 8, 3, 3, body_light)

	# Glowing green eyes
	_fill_rect(img, 10, 12, 4, 4, eye)
	_fill_rect(img, 18, 12, 4, 4, eye)
	_fill_rect(img, 11, 13, 2, 2, eye_pupil)
	_fill_rect(img, 19, 13, 2, 2, eye_pupil)
	# Glow around eyes
	img.set_pixel(9, 12, Color(0.3, 0.9, 0.3, 0.4))
	img.set_pixel(14, 12, Color(0.3, 0.9, 0.3, 0.4))
	img.set_pixel(17, 12, Color(0.3, 0.9, 0.3, 0.4))
	img.set_pixel(22, 12, Color(0.3, 0.9, 0.3, 0.4))

	# Eerie mouth
	_fill_rect(img, 13, 18, 6, 1, Color(0.08, 0.4, 0.1))
	img.set_pixel(13, 17, Color(0.08, 0.4, 0.1))
	img.set_pixel(18, 17, Color(0.08, 0.4, 0.1))

	_add_outline(img, outline)
	_save_sprite(img, "ghost_green.png")

# ==================== GHOST BLUE ====================
func _generate_ghost_blue() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body = Color(0.4, 0.65, 0.9, 0.8)
	var body_light = Color(0.6, 0.82, 1.0, 0.85)
	var body_dark = Color(0.25, 0.45, 0.7, 0.7)
	var crystal = Color(0.7, 0.9, 1.0)
	var crystal_dark = Color(0.4, 0.6, 0.8)
	var eye = Color(0.85, 0.92, 1.0)
	var outline = Color(0.1, 0.2, 0.4)

	# Body shape
	_fill_rect(img, 13, 5, 6, 2, body)
	_fill_rect(img, 11, 7, 10, 2, body)
	_fill_rect(img, 9, 9, 14, 2, body)
	_fill_rect(img, 8, 11, 16, 8, body)
	_fill_rect(img, 7, 19, 18, 2, body)

	# Wavy bottom (icy, more angular)
	_fill_rect(img, 7, 21, 3, 2, body_dark)
	_fill_rect(img, 12, 21, 3, 3, body_dark)
	_fill_rect(img, 18, 21, 3, 2, body_dark)
	_fill_rect(img, 10, 21, 3, 3, body)
	_fill_rect(img, 15, 21, 4, 4, body)
	_fill_rect(img, 21, 21, 4, 3, body)
	# Icicle-like tips
	img.set_pixel(8, 23, crystal_dark)
	img.set_pixel(8, 24, crystal_dark)
	img.set_pixel(13, 24, crystal_dark)
	img.set_pixel(13, 25, crystal_dark)
	img.set_pixel(19, 23, crystal_dark)
	img.set_pixel(19, 24, crystal_dark)

	# Crystalline facets on body
	_fill_rect(img, 10, 10, 2, 3, crystal)
	_fill_rect(img, 20, 13, 2, 3, crystal)
	img.set_pixel(15, 8, crystal)
	img.set_pixel(16, 9, crystal)

	# Highlight
	_fill_rect(img, 11, 8, 3, 3, body_light)
	_fill_rect(img, 19, 10, 2, 2, body_light)

	# Icy white eyes
	_fill_rect(img, 10, 12, 4, 4, eye)
	_fill_rect(img, 18, 12, 4, 4, eye)
	_fill_rect(img, 11, 13, 2, 2, Color(0.2, 0.4, 0.7))
	_fill_rect(img, 19, 13, 2, 2, Color(0.2, 0.4, 0.7))

	# Cold breath / mouth
	_fill_rect(img, 14, 17, 4, 2, Color(0.5, 0.7, 0.9, 0.6))
	img.set_pixel(13, 18, Color(0.6, 0.8, 1.0, 0.3))
	img.set_pixel(18, 18, Color(0.6, 0.8, 1.0, 0.3))

	_add_outline(img, outline)
	_save_sprite(img, "ghost_blue.png")

# ==================== GHOST RED ====================
func _generate_ghost_red() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body = Color(0.85, 0.2, 0.15, 0.8)
	var body_light = Color(1.0, 0.4, 0.25, 0.85)
	var body_dark = Color(0.6, 0.1, 0.08, 0.7)
	var eye = Color(1.0, 0.7, 0.1)
	var flame = Color(1.0, 0.55, 0.1, 0.7)
	var flame_tip = Color(1.0, 0.85, 0.2, 0.5)
	var outline = Color(0.35, 0.05, 0.02)

	# Body shape
	_fill_rect(img, 13, 5, 6, 2, body)
	_fill_rect(img, 11, 7, 10, 2, body)
	_fill_rect(img, 9, 9, 14, 2, body)
	_fill_rect(img, 8, 11, 16, 8, body)
	_fill_rect(img, 7, 19, 18, 2, body)

	# Flame-like bottom (flickering, irregular)
	_fill_rect(img, 7, 21, 3, 2, flame)
	_fill_rect(img, 12, 21, 3, 3, flame)
	_fill_rect(img, 18, 21, 3, 2, flame)
	_fill_rect(img, 10, 21, 3, 4, body_dark)
	_fill_rect(img, 15, 21, 4, 3, flame)
	_fill_rect(img, 21, 21, 4, 2, body_dark)

	# Flame tips at bottom
	img.set_pixel(8, 23, flame_tip)
	img.set_pixel(8, 24, flame_tip)
	img.set_pixel(11, 25, flame_tip)
	img.set_pixel(13, 24, flame_tip)
	img.set_pixel(13, 25, flame_tip)
	img.set_pixel(16, 24, flame_tip)
	img.set_pixel(16, 25, flame_tip)
	img.set_pixel(19, 23, flame_tip)
	img.set_pixel(19, 24, flame_tip)
	img.set_pixel(22, 23, flame_tip)

	# Flame wisps on top
	img.set_pixel(14, 4, flame_tip)
	img.set_pixel(15, 3, flame)
	img.set_pixel(16, 4, flame_tip)
	img.set_pixel(17, 3, flame)

	# Highlight (hot spot)
	_fill_rect(img, 11, 8, 3, 3, body_light)
	_fill_rect(img, 10, 10, 2, 2, body_light)

	# Orange eyes (fiery)
	_fill_rect(img, 10, 12, 4, 4, eye)
	_fill_rect(img, 18, 12, 4, 4, eye)
	_fill_rect(img, 11, 13, 2, 2, Color(0.4, 0.05, 0.0))
	_fill_rect(img, 19, 13, 2, 2, Color(0.4, 0.05, 0.0))
	# Eye glow
	img.set_pixel(10, 11, Color(1.0, 0.6, 0.1, 0.4))
	img.set_pixel(13, 11, Color(1.0, 0.6, 0.1, 0.4))
	img.set_pixel(18, 11, Color(1.0, 0.6, 0.1, 0.4))
	img.set_pixel(21, 11, Color(1.0, 0.6, 0.1, 0.4))

	# Angry mouth
	_fill_rect(img, 13, 17, 6, 2, Color(0.3, 0.02, 0.0))
	img.set_pixel(14, 17, Color(1.0, 0.7, 0.1))
	img.set_pixel(16, 17, Color(1.0, 0.7, 0.1))

	_add_outline(img, outline)
	_save_sprite(img, "ghost_red.png")

# ==================== TANK ====================
func _generate_tank() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var armor = Color(0.4, 0.4, 0.45)
	var armor_light = Color(0.5, 0.5, 0.55)
	var armor_dark = Color(0.28, 0.28, 0.32)
	var skin = Color(0.55, 0.45, 0.4)
	var shield_main = Color(0.5, 0.5, 0.55)
	var shield_rim = Color(0.6, 0.58, 0.4)
	var shield_boss = Color(0.7, 0.68, 0.45)
	var eye = Color(0.9, 0.2, 0.15)
	var outline = Color(0.12, 0.12, 0.15)

	# Small head (armored helmet)
	_fill_rect(img, 13, 3, 6, 2, armor)
	_fill_rect(img, 12, 5, 8, 4, armor)
	# Helmet visor slit
	_fill_rect(img, 14, 6, 4, 1, Color(0.1, 0.1, 0.12))
	# Red eyes through visor
	img.set_pixel(14, 6, eye)
	img.set_pixel(17, 6, eye)
	# Helmet crest
	_fill_rect(img, 15, 2, 2, 1, armor_light)

	# Massive armored body
	_fill_rect(img, 8, 9, 16, 4, armor)
	_fill_rect(img, 6, 13, 20, 6, armor)
	_fill_rect(img, 7, 19, 18, 3, armor_dark)

	# Shoulder pauldrons (big)
	_fill_rect(img, 4, 9, 4, 5, armor_light)
	_fill_rect(img, 24, 9, 4, 5, armor_light)
	# Spikes on shoulders
	img.set_pixel(4, 8, armor_light)
	img.set_pixel(5, 7, armor_light)
	img.set_pixel(27, 8, armor_light)
	img.set_pixel(26, 7, armor_light)

	# Chest plate detail
	_fill_rect(img, 12, 10, 8, 3, armor_light)
	_fill_rect(img, 14, 11, 4, 1, shield_boss)

	# Belt
	_fill_rect(img, 8, 18, 16, 1, shield_rim)

	# Arms
	_fill_rect(img, 4, 14, 3, 5, armor)
	_fill_rect(img, 25, 14, 3, 5, armor)
	# Fists
	_fill_rect(img, 4, 19, 3, 2, skin)
	_fill_rect(img, 25, 19, 3, 2, skin)

	# Big shield (left side, in front)
	_fill_rect(img, 1, 10, 5, 12, shield_main)
	_fill_rect(img, 0, 12, 1, 8, shield_rim)
	_fill_rect(img, 6, 12, 1, 8, shield_rim)
	_fill_rect(img, 1, 10, 5, 1, shield_rim)
	_fill_rect(img, 1, 21, 5, 1, shield_rim)
	# Shield boss (center circle)
	_fill_rect(img, 2, 15, 3, 3, shield_boss)
	img.set_pixel(3, 16, Color(0.8, 0.78, 0.55))

	# Legs (thick, armored)
	_fill_rect(img, 9, 22, 5, 5, armor_dark)
	_fill_rect(img, 18, 22, 5, 5, armor_dark)
	# Boots
	_fill_rect(img, 8, 27, 7, 2, armor)
	_fill_rect(img, 17, 27, 7, 2, armor)

	_add_outline(img, outline)
	_save_sprite(img, "tank.png")

# ==================== BOMBER ====================
func _generate_bomber() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body = Color(0.8, 0.25, 0.2)
	var body_dark = Color(0.6, 0.15, 0.12)
	var eye_white = Color(0.95, 0.95, 0.95)
	var pupil = Color(0.1, 0.1, 0.1)
	var bomb = Color(0.15, 0.15, 0.18)
	var bomb_highlight = Color(0.3, 0.3, 0.35)
	var fuse = Color(0.6, 0.45, 0.2)
	var spark = Color(1.0, 0.9, 0.2)
	var spark_hot = Color(1.0, 0.5, 0.1)
	var outline = Color(0.25, 0.08, 0.05)

	# Small red creature body
	_fill_rect(img, 13, 14, 8, 6, body)
	_fill_rect(img, 12, 16, 10, 4, body)
	_fill_rect(img, 14, 20, 6, 2, body_dark)

	# Head
	_fill_rect(img, 14, 10, 6, 5, body)
	_fill_rect(img, 15, 9, 4, 1, body)
	# Pointy ears
	img.set_pixel(14, 9, body)
	img.set_pixel(13, 8, body)
	img.set_pixel(19, 9, body)
	img.set_pixel(20, 8, body)

	# Big worried eyes
	_fill_rect(img, 14, 11, 3, 3, eye_white)
	_fill_rect(img, 18, 11, 3, 3, eye_white)
	img.set_pixel(15, 12, pupil)
	img.set_pixel(16, 12, pupil)
	img.set_pixel(19, 12, pupil)
	img.set_pixel(20, 12, pupil)

	# Worried mouth
	img.set_pixel(16, 14, Color(0.5, 0.1, 0.08))
	img.set_pixel(17, 14, Color(0.5, 0.1, 0.08))

	# Arms (holding bomb up)
	_fill_rect(img, 11, 14, 2, 2, body)
	_fill_rect(img, 10, 12, 2, 2, body)
	_fill_rect(img, 22, 14, 2, 2, body)
	_fill_rect(img, 23, 12, 2, 2, body)

	# Little feet
	_fill_rect(img, 14, 22, 3, 2, body_dark)
	_fill_rect(img, 18, 22, 3, 2, body_dark)

	# BIG round bomb (above head, being carried)
	_fill_rect(img, 10, 1, 12, 2, bomb)
	_fill_rect(img, 8, 3, 16, 2, bomb)
	_fill_rect(img, 7, 5, 18, 4, bomb)
	_fill_rect(img, 8, 9, 16, 2, bomb)
	_fill_rect(img, 10, 11, 3, 1, bomb)
	_fill_rect(img, 20, 11, 3, 1, bomb)
	# Bomb highlight
	_fill_rect(img, 10, 3, 3, 2, bomb_highlight)
	img.set_pixel(10, 5, bomb_highlight)

	# Fuse (top of bomb)
	img.set_pixel(15, 0, fuse)
	img.set_pixel(16, 0, fuse)
	img.set_pixel(17, 0, fuse)
	# Spark/flame at fuse tip
	img.set_pixel(18, 0, spark)
	img.set_pixel(17, 0, spark_hot)
	img.set_pixel(19, 0, spark)
	img.set_pixel(18, 1, spark_hot)

	_add_outline(img, outline)
	_save_sprite(img, "bomber.png")

# ==================== SWARM ====================
func _generate_swarm() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var bug_dark = Color(0.2, 0.18, 0.15)
	var bug_brown = Color(0.4, 0.32, 0.22)
	var bug_light = Color(0.5, 0.42, 0.3)
	var wing = Color(0.6, 0.58, 0.5, 0.6)
	var outline = Color(0.1, 0.08, 0.05)

	# Draw a buzzing cluster of insects scattered across the sprite
	# Each "bug" is 2-3 pixels with tiny wing pixels

	# Bug cluster positions (x, y) - scattered in a cloud pattern
	var bugs = [
		Vector2i(8, 6), Vector2i(14, 4), Vector2i(20, 7), Vector2i(24, 5),
		Vector2i(6, 10), Vector2i(11, 9), Vector2i(17, 8), Vector2i(22, 11),
		Vector2i(9, 13), Vector2i(15, 12), Vector2i(19, 14), Vector2i(25, 13),
		Vector2i(5, 16), Vector2i(12, 15), Vector2i(16, 17), Vector2i(23, 16),
		Vector2i(7, 19), Vector2i(13, 20), Vector2i(18, 19), Vector2i(22, 21),
		Vector2i(10, 22), Vector2i(15, 23), Vector2i(20, 22), Vector2i(26, 19),
		Vector2i(4, 13), Vector2i(27, 10), Vector2i(11, 17), Vector2i(21, 17),
	]

	for bug_pos in bugs:
		var bx = bug_pos.x
		var by = bug_pos.y
		if bx >= 0 and bx < 31 and by >= 0 and by < 31:
			# Bug body (2 pixels)
			img.set_pixel(bx, by, bug_dark)
			img.set_pixel(bx + 1, by, bug_brown)
			# Wing (1 pixel above or to side)
			if by > 0:
				img.set_pixel(bx, by - 1, wing)
			if bx + 2 < SPRITE_SIZE:
				img.set_pixel(bx + 2, by, wing)

	# Add some motion lines / buzzing effect (scattered light pixels)
	var buzz_spots = [
		Vector2i(10, 5), Vector2i(18, 6), Vector2i(6, 12),
		Vector2i(24, 9), Vector2i(8, 21), Vector2i(17, 24),
		Vector2i(25, 17), Vector2i(3, 15), Vector2i(14, 10),
	]
	for spot in buzz_spots:
		if spot.x >= 0 and spot.x < SPRITE_SIZE and spot.y >= 0 and spot.y < SPRITE_SIZE:
			img.set_pixel(spot.x, spot.y, bug_light)

	# Denser center cluster
	_fill_rect(img, 13, 13, 6, 5, Color(0.25, 0.2, 0.15, 0.3))
	# Center bugs more visible
	img.set_pixel(14, 14, bug_dark)
	img.set_pixel(15, 15, bug_dark)
	img.set_pixel(17, 14, bug_dark)
	img.set_pixel(16, 16, bug_dark)
	img.set_pixel(15, 14, wing)
	img.set_pixel(18, 15, wing)

	_add_outline(img, outline)
	_save_sprite(img, "swarm.png")

# ==================== MIMIC ====================
func _generate_mimic() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var chest_main = Color(0.55, 0.35, 0.15)
	var chest_dark = Color(0.4, 0.25, 0.1)
	var chest_light = Color(0.65, 0.45, 0.2)
	var metal = Color(0.7, 0.65, 0.3)
	var metal_dark = Color(0.5, 0.45, 0.2)
	var eye_white = Color(0.95, 0.95, 0.2)
	var pupil = Color(0.15, 0.1, 0.05)
	var tooth = Color(0.95, 0.92, 0.85)
	var tongue = Color(0.8, 0.25, 0.2)
	var outline = Color(0.2, 0.12, 0.05)

	# Chest bottom (main box)
	_fill_rect(img, 4, 16, 24, 10, chest_main)
	_fill_rect(img, 5, 17, 22, 8, chest_main)
	# Bottom darker
	_fill_rect(img, 4, 24, 24, 2, chest_dark)
	# Side shading
	_fill_rect(img, 4, 16, 2, 10, chest_dark)
	_fill_rect(img, 26, 16, 2, 10, chest_dark)
	# Bottom highlight
	_fill_rect(img, 8, 18, 16, 2, chest_light)

	# Metal bands on chest
	_fill_rect(img, 4, 16, 24, 1, metal)
	_fill_rect(img, 4, 22, 24, 1, metal_dark)
	# Metal corners
	_fill_rect(img, 4, 16, 2, 2, metal)
	_fill_rect(img, 26, 16, 2, 2, metal)
	_fill_rect(img, 4, 24, 2, 2, metal)
	_fill_rect(img, 26, 24, 2, 2, metal)

	# Chest lid (slightly open, tilted back)
	_fill_rect(img, 4, 10, 24, 6, chest_dark)
	_fill_rect(img, 5, 11, 22, 4, chest_main)
	_fill_rect(img, 4, 10, 24, 1, metal)
	# Lid top edge
	_fill_rect(img, 6, 9, 20, 1, chest_dark)
	_fill_rect(img, 8, 8, 16, 1, chest_dark)

	# Lock/clasp
	_fill_rect(img, 14, 15, 4, 3, metal)
	_fill_rect(img, 15, 16, 2, 1, metal_dark)

	# Eyes peeking from gap between lid and box
	_fill_rect(img, 9, 13, 4, 3, eye_white)
	_fill_rect(img, 19, 13, 4, 3, eye_white)
	# Pupils (looking at player)
	_fill_rect(img, 10, 14, 2, 2, pupil)
	_fill_rect(img, 20, 14, 2, 2, pupil)
	# Eye shine
	img.set_pixel(10, 13, Color(1.0, 1.0, 0.7))
	img.set_pixel(20, 13, Color(1.0, 1.0, 0.7))

	# Teeth on the lid edge (bottom of lid)
	var teeth_y = 15
	for tx in range(6, 26, 2):
		if tx < 9 or tx > 12:
			if tx < 19 or tx > 22:
				img.set_pixel(tx, teeth_y, tooth)
				img.set_pixel(tx, teeth_y + 1, tooth)

	# Tongue sticking out
	_fill_rect(img, 14, 17, 4, 2, tongue)
	_fill_rect(img, 15, 19, 3, 1, tongue)
	img.set_pixel(16, 20, Color(0.7, 0.15, 0.12))

	_add_outline(img, outline)
	_save_sprite(img, "mimic.png")

# ==================== TOOTH FAIRY ====================
func _generate_tooth_fairy() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var skin = Color(0.95, 0.75, 0.8)
	var skin_dark = Color(0.85, 0.6, 0.65)
	var hair = Color(0.9, 0.55, 0.7)
	var dress = Color(0.9, 0.5, 0.7)
	var dress_light = Color(1.0, 0.7, 0.85)
	var wing = Color(0.8, 0.85, 1.0, 0.6)
	var wing_edge = Color(0.6, 0.7, 0.95, 0.7)
	var sparkle = Color(1.0, 1.0, 0.7, 0.8)
	var eye = Color(0.2, 0.6, 0.3)
	var outline = Color(0.4, 0.2, 0.3)

	# Hair (fluffy, pink)
	_fill_rect(img, 12, 5, 8, 2, hair)
	_fill_rect(img, 11, 7, 10, 3, hair)
	_fill_rect(img, 10, 8, 1, 4, hair)
	_fill_rect(img, 21, 8, 1, 4, hair)
	# Hair bangs
	_fill_rect(img, 12, 7, 8, 1, Color(0.85, 0.5, 0.65))

	# Face
	_fill_rect(img, 12, 8, 8, 5, skin)
	_fill_rect(img, 13, 13, 6, 1, skin)

	# Eyes (big, mischievous)
	_fill_rect(img, 13, 9, 2, 2, Color(0.95, 0.95, 0.95))
	_fill_rect(img, 17, 9, 2, 2, Color(0.95, 0.95, 0.95))
	img.set_pixel(13, 10, eye)
	img.set_pixel(14, 10, Color(0.1, 0.1, 0.1))
	img.set_pixel(17, 10, eye)
	img.set_pixel(18, 10, Color(0.1, 0.1, 0.1))
	# Eye shine
	img.set_pixel(13, 9, Color(1.0, 1.0, 1.0))
	img.set_pixel(17, 9, Color(1.0, 1.0, 1.0))

	# Mischievous grin (wide, showing teeth)
	img.set_pixel(13, 12, skin_dark)
	_fill_rect(img, 14, 12, 4, 1, Color(0.7, 0.2, 0.25))
	img.set_pixel(19, 12, skin_dark)
	# Teeth in grin
	img.set_pixel(15, 12, Color(0.95, 0.95, 0.9))
	img.set_pixel(17, 12, Color(0.95, 0.95, 0.9))

	# Small body / dress
	_fill_rect(img, 12, 14, 8, 3, dress)
	_fill_rect(img, 11, 17, 10, 3, dress)
	_fill_rect(img, 10, 20, 12, 2, dress_light)
	# Dress ruffle at bottom
	_fill_rect(img, 9, 22, 14, 1, dress_light)
	img.set_pixel(9, 22, dress)
	img.set_pixel(12, 22, dress)
	img.set_pixel(15, 22, dress)
	img.set_pixel(18, 22, dress)
	img.set_pixel(22, 22, dress)

	# Arms (tiny)
	_fill_rect(img, 10, 15, 2, 3, skin)
	_fill_rect(img, 20, 15, 2, 3, skin)

	# Little feet
	_fill_rect(img, 12, 23, 2, 1, skin)
	_fill_rect(img, 18, 23, 2, 1, skin)

	# Wings (sparkly, spread)
	# Left wing
	_fill_rect(img, 4, 10, 6, 2, wing)
	_fill_rect(img, 3, 12, 7, 3, wing)
	_fill_rect(img, 4, 15, 6, 2, wing)
	_fill_rect(img, 5, 17, 5, 1, wing)
	# Wing edge
	img.set_pixel(3, 12, wing_edge)
	img.set_pixel(3, 13, wing_edge)
	img.set_pixel(3, 14, wing_edge)
	img.set_pixel(4, 10, wing_edge)
	img.set_pixel(4, 16, wing_edge)

	# Right wing
	_fill_rect(img, 22, 10, 6, 2, wing)
	_fill_rect(img, 22, 12, 7, 3, wing)
	_fill_rect(img, 22, 15, 6, 2, wing)
	_fill_rect(img, 22, 17, 5, 1, wing)
	img.set_pixel(28, 12, wing_edge)
	img.set_pixel(28, 13, wing_edge)
	img.set_pixel(28, 14, wing_edge)
	img.set_pixel(27, 10, wing_edge)
	img.set_pixel(27, 16, wing_edge)

	# Sparkles around the fairy
	var sparkle_positions = [
		Vector2i(7, 8), Vector2i(24, 8), Vector2i(3, 16),
		Vector2i(28, 16), Vector2i(10, 5), Vector2i(22, 5),
		Vector2i(6, 20), Vector2i(25, 20), Vector2i(16, 3),
	]
	for sp in sparkle_positions:
		if sp.x >= 0 and sp.x < SPRITE_SIZE and sp.y >= 0 and sp.y < SPRITE_SIZE:
			img.set_pixel(sp.x, sp.y, sparkle)

	# Wand in right hand (tiny star on top)
	img.set_pixel(22, 14, Color(0.7, 0.55, 0.2))
	img.set_pixel(22, 13, Color(0.7, 0.55, 0.2))
	img.set_pixel(22, 12, Color(0.7, 0.55, 0.2))
	# Star
	img.set_pixel(22, 11, sparkle)
	img.set_pixel(21, 11, sparkle)
	img.set_pixel(23, 11, sparkle)
	img.set_pixel(22, 10, sparkle)

	_add_outline(img, outline)
	_save_sprite(img, "tooth_fairy.png")
