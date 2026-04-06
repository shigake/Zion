extends SceneTree

## Generates walk spritesheets (4 frames, 128x32) for characters and enemies.
## Frame 0: original sprite (idle)
## Frame 1: bottom half shifted 1px left, top half shifted 1px right (left step lean)
## Frame 2: original sprite (idle)
## Frame 3: bottom half shifted 1px right, top half shifted 1px left (right step lean)
## Run: godot --headless --script res://scripts/tools/walk_spritesheet_gen.gd

const FRAME_SIZE := 32
const SHEET_WIDTH := 128  # 4 frames * 32px
const SHEET_HEIGHT := 32

# All characters
const CHARACTERS := [
	"ronin", "soldado", "mago", "berserker", "ninja", "bruxa",
	"pirata", "engenheiro", "vampiro", "gladiador", "chef", "mystery",
	"amazona", "lealith", "fragmentado"
]

# All generic enemies
const ENEMIES := [
	"bat", "bomber", "ghost", "ghost_blue", "ghost_green", "ghost_red",
	"ghost_white", "mimic", "skeleton", "skeleton_archer", "slime",
	"slime_big", "swarm", "tank", "tooth_fairy", "zombie_runner"
]

func _init() -> void:
	print("=== Walk Spritesheet Generator ===")

	# Generate character walk spritesheets
	for char_id in CHARACTERS:
		var src_path = "res://assets/sprites/characters/%s.png" % char_id
		var dst_path = "res://assets/sprites/characters/%s_walk.png" % char_id
		_generate_walk_sheet(src_path, dst_path, char_id)

	# Generate enemy walk spritesheets
	for enemy_id in ENEMIES:
		var src_path = "res://assets/sprites/enemies/%s.png" % enemy_id
		var dst_path = "res://assets/sprites/enemies/%s_walk.png" % enemy_id
		_generate_walk_sheet(src_path, dst_path, enemy_id)

	print("=== Walk spritesheet generation complete! ===")
	quit()

func _generate_walk_sheet(src_path: String, dst_path: String, id: String) -> void:
	if not ResourceLoader.exists(src_path):
		print("SKIP (not found): ", src_path)
		return

	var tex = load(src_path) as Texture2D
	if tex == null:
		print("SKIP (load failed): ", src_path)
		return

	var src_img = tex.get_image()
	if src_img == null:
		print("SKIP (no image data): ", src_path)
		return

	# Ensure we work with RGBA8
	src_img.convert(Image.FORMAT_RGBA8)

	var src_w = src_img.get_width()
	var src_h = src_img.get_height()

	# Create the 128x32 spritesheet (4 frames side by side)
	var sheet = Image.create(FRAME_SIZE * 4, FRAME_SIZE, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	# Frame 0: original (idle) — blit at x=0
	_blit_centered(sheet, src_img, 0)

	# Frame 1: left step lean (bottom half 1px left, top half 1px right)
	var frame1 = _lean_image(src_img, -1, 1)
	_blit_centered(sheet, frame1, FRAME_SIZE)

	# Frame 2: original (idle) — blit at x=64
	_blit_centered(sheet, src_img, FRAME_SIZE * 2)

	# Frame 3: right step lean (bottom half 1px right, top half 1px left)
	var frame3 = _lean_image(src_img, 1, -1)
	_blit_centered(sheet, frame3, FRAME_SIZE * 3)

	# Save
	var dir_path = dst_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	sheet.save_png(dst_path)
	print("Saved: ", dst_path, " (from ", src_w, "x", src_h, " source)")

func _lean_image(src: Image, bottom_dx: int, top_dx: int) -> Image:
	## Create a walk frame by splitting the image at the midpoint:
	## - Top half is shifted by top_dx pixels horizontally (body leans)
	## - Bottom half is shifted by bottom_dx pixels horizontally (legs step)
	var w = src.get_width()
	var h = src.get_height()
	var mid_y = h / 2  # Split at midpoint
	var result = Image.create(w, h, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))

	for x in range(w):
		for y in range(h):
			var dx = top_dx if y < mid_y else bottom_dx
			var sx = x - dx
			if sx >= 0 and sx < w:
				result.set_pixel(x, y, src.get_pixel(sx, y))
	return result

func _blit_centered(sheet: Image, src: Image, offset_x: int) -> void:
	## Blit src image centered within a FRAME_SIZE x FRAME_SIZE cell at offset_x on the sheet.
	var sw = src.get_width()
	var sh = src.get_height()

	# If source is larger than frame, scale it down
	var img = src
	if sw > FRAME_SIZE or sh > FRAME_SIZE:
		img = src.duplicate()
		var scale_factor = minf(float(FRAME_SIZE) / sw, float(FRAME_SIZE) / sh)
		var new_w = maxi(1, int(sw * scale_factor))
		var new_h = maxi(1, int(sh * scale_factor))
		img.resize(new_w, new_h, Image.INTERPOLATE_NEAREST)
		sw = new_w
		sh = new_h

	# Center within the 32x32 frame
	var dx = (FRAME_SIZE - sw) / 2
	var dy = (FRAME_SIZE - sh) / 2

	for x in range(sw):
		for y in range(sh):
			var px = offset_x + dx + x
			var py = dy + y
			if px >= 0 and px < sheet.get_width() and py >= 0 and py < FRAME_SIZE:
				var color = img.get_pixel(x, y)
				if color.a > 0:
					sheet.set_pixel(px, py, color)
