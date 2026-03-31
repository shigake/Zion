extends SceneTree

## Generates pixel art sprites for all 20 alternative bosses at 64x64.
## Run: godot --headless --path game --script res://scripts/tools/alt_boss_sprite_gen.gd

const S := 64
const OUT := "res://assets/sprites/bosses/"

const BOSSES := {
	# Cemetery
	"cemetery_lich": {"body": Color(0.2, 0.5, 0.2), "accent": Color(0.3, 0.9, 0.3), "crown": true, "robe": true},
	"cemetery_reaper": {"body": Color(0.08, 0.08, 0.1), "accent": Color(0.6, 0.1, 0.1), "hood": true, "scythe": true},
	# Forest
	"forest_elder": {"body": Color(0.3, 0.25, 0.15), "accent": Color(0.2, 0.6, 0.1), "wide": true, "leaves": true},
	"forest_spider": {"body": Color(0.3, 0.1, 0.4), "accent": Color(0.7, 0.2, 0.8), "legs": true},
	# Farm
	"farm_scarecrow": {"body": Color(0.5, 0.35, 0.1), "accent": Color(0.8, 0.5, 0.1), "hat": true, "arms_wide": true},
	"farm_harvester": {"body": Color(0.25, 0.25, 0.25), "accent": Color(0.7, 0.1, 0.1), "blade": true},
	# Tokyo
	"tokyo_shogun": {"body": Color(0.6, 0.1, 0.2), "accent": Color(0.9, 0.8, 0.2), "armor": true, "katana": true},
	"tokyo_kaiju": {"body": Color(0.15, 0.4, 0.2), "accent": Color(0.2, 0.8, 0.3), "wide": true, "spikes": true},
	# Volcano
	"volcano_phoenix": {"body": Color(0.9, 0.4, 0.0), "accent": Color(1.0, 0.8, 0.1), "wings": true, "fire": true},
	"volcano_titan": {"body": Color(0.35, 0.1, 0.0), "accent": Color(1.0, 0.3, 0.0), "wide": true, "cracks": true},
	# Ocean
	"ocean_siren": {"body": Color(0.2, 0.5, 0.7), "accent": Color(0.4, 0.8, 0.9), "tail": true, "hair": true},
	"ocean_hydra": {"body": Color(0.1, 0.15, 0.3), "accent": Color(0.2, 0.4, 0.7), "heads": true, "wide": true},
	# Arena
	"arena_minotaur": {"body": Color(0.45, 0.25, 0.1), "accent": Color(0.7, 0.4, 0.1), "horns": true, "wide": true},
	"arena_chimera": {"body": Color(0.4, 0.15, 0.4), "accent": Color(0.7, 0.3, 0.7), "wings": true, "tail": true},
	# Space
	"space_hivemind": {"body": Color(0.15, 0.5, 0.15), "accent": Color(0.3, 0.9, 0.3), "tentacles": true, "eyes": true},
	"space_warden": {"body": Color(0.25, 0.15, 0.5), "accent": Color(0.5, 0.3, 0.9), "armor": true, "glow": true},
	# Castle
	"castle_werewolf": {"body": Color(0.3, 0.2, 0.15), "accent": Color(0.5, 0.4, 0.3), "claws": true, "fangs": true},
	"castle_banshee": {"body": Color(0.4, 0.5, 0.7), "accent": Color(0.6, 0.8, 0.9), "float": true, "hair": true},
	# Candy
	"candy_witch": {"body": Color(0.7, 0.2, 0.5), "accent": Color(0.9, 0.4, 0.7), "hat": true, "wand": true},
	"candy_dragon": {"body": Color(0.15, 0.6, 0.3), "accent": Color(0.3, 0.9, 0.5), "wings": true, "wide": true},
}

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for boss_id in BOSSES:
		var config = BOSSES[boss_id]
		_generate_boss(boss_id, config)
	print("Generated %d alt boss sprites!" % BOSSES.size())
	quit()

func _generate_boss(id: String, cfg: Dictionary) -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var body: Color = cfg["body"]
	var accent: Color = cfg["accent"]
	var outline = Color(0.05, 0.05, 0.08)

	var is_wide = cfg.get("wide", false)
	var body_w = 24 if is_wide else 16
	var body_x = (S - body_w) / 2

	# Body
	_fill(img, body_x, 16, body_w, 30, body)

	# Head
	var head_w = 14
	var head_x = (S - head_w) / 2
	_fill(img, head_x, 8, head_w, 12, body.lightened(0.1))

	# Eyes (menacing)
	_fill(img, head_x + 3, 12, 3, 2, accent)
	_fill(img, head_x + head_w - 6, 12, 3, 2, accent)

	# Crown/hat
	if cfg.get("crown", false):
		_fill(img, head_x + 2, 5, 10, 3, accent)
		img.set_pixel(head_x + 3, 4, accent)
		img.set_pixel(head_x + 7, 4, accent)
		img.set_pixel(head_x + 11, 4, accent)
	if cfg.get("hat", false):
		_fill(img, head_x - 2, 5, head_w + 4, 3, accent.darkened(0.2))
		_fill(img, head_x + 2, 2, head_w - 4, 3, accent)
	if cfg.get("hood", false):
		_fill(img, head_x - 1, 6, head_w + 2, 6, body.darkened(0.3))

	# Robe
	if cfg.get("robe", false):
		_fill(img, body_x - 2, 20, body_w + 4, 26, body.darkened(0.15))

	# Armor
	if cfg.get("armor", false):
		_fill(img, body_x + 2, 18, body_w - 4, 10, accent.darkened(0.3))
		_fill(img, body_x + 4, 20, body_w - 8, 2, accent)

	# Wings
	if cfg.get("wings", false):
		_fill(img, body_x - 10, 16, 8, 16, accent.darkened(0.2))
		_fill(img, body_x + body_w + 2, 16, 8, 16, accent.darkened(0.2))

	# Horns
	if cfg.get("horns", false):
		_fill(img, head_x - 2, 6, 3, 8, accent)
		_fill(img, head_x + head_w - 1, 6, 3, 8, accent)

	# Legs/tail
	if cfg.get("legs", false):
		for i in range(4):
			var lx = body_x - 4 + i * 8
			_fill(img, lx, 44, 2, 12, body.darkened(0.2))
	if cfg.get("tail", false):
		_fill(img, body_x + body_w, 38, 10, 3, accent.darkened(0.1))

	# Weapon elements
	if cfg.get("scythe", false):
		_fill(img, body_x + body_w + 2, 12, 2, 30, Color(0.5, 0.5, 0.5))
		_fill(img, body_x + body_w, 10, 8, 3, accent)
	if cfg.get("katana", false):
		_fill(img, body_x - 4, 14, 2, 28, Color(0.7, 0.7, 0.8))
	if cfg.get("blade", false):
		_fill(img, body_x + body_w + 1, 10, 4, 20, Color(0.6, 0.6, 0.65))
	if cfg.get("wand", false):
		_fill(img, body_x - 3, 16, 2, 20, accent.lightened(0.2))
		_fill(img, body_x - 4, 14, 4, 4, accent)
	if cfg.get("claws", false):
		_fill(img, body_x - 2, 30, 3, 6, accent.lightened(0.3))
		_fill(img, body_x + body_w - 1, 30, 3, 6, accent.lightened(0.3))

	# Misc features
	if cfg.get("fire", false):
		for i in range(5):
			var fx = body_x + randi() % body_w
			var fy = 6 + randi() % 10
			img.set_pixel(clampi(fx, 0, S-1), clampi(fy, 0, S-1), Color(1.0, 0.6, 0.1))
	if cfg.get("cracks", false):
		for i in range(8):
			var cx = body_x + randi() % body_w
			var cy = 20 + randi() % 20
			img.set_pixel(clampi(cx, 0, S-1), clampi(cy, 0, S-1), accent)
	if cfg.get("leaves", false):
		for i in range(6):
			var lx = body_x - 4 + randi() % (body_w + 8)
			var ly = 10 + randi() % 8
			_fill(img, clampi(lx, 0, S-3), clampi(ly, 0, S-3), 3, 2, Color(0.1, 0.5, 0.1))
	if cfg.get("spikes", false):
		for i in range(4):
			var sx = body_x + 4 + i * 5
			img.set_pixel(clampi(sx, 0, S-1), 15, accent)
			img.set_pixel(clampi(sx, 0, S-1), 14, accent)
	if cfg.get("eyes", false):
		for i in range(3):
			var ex = head_x + 2 + i * 4
			img.set_pixel(clampi(ex, 0, S-1), 11, accent)
	if cfg.get("tentacles", false):
		for i in range(4):
			var tx = body_x + i * 6
			_fill(img, clampi(tx, 0, S-2), 46, 2, 10, body.lightened(0.1))
	if cfg.get("hair", false):
		_fill(img, head_x - 2, 8, head_w + 4, 5, accent.darkened(0.1))
	if cfg.get("float", false):
		# Erase legs area for floating bosses
		_fill(img, 0, 50, S, 14, Color(0, 0, 0, 0))
	if cfg.get("heads", false):
		_fill(img, head_x - 10, 10, 8, 8, body.lightened(0.05))
		_fill(img, head_x + head_w + 2, 10, 8, 8, body.lightened(0.05))
		# Eyes on extra heads
		_fill(img, head_x - 8, 13, 2, 1, accent)
		_fill(img, head_x + head_w + 4, 13, 2, 1, accent)
	if cfg.get("fangs", false):
		img.set_pixel(head_x + 4, 18, Color.WHITE)
		img.set_pixel(head_x + head_w - 5, 18, Color.WHITE)
	if cfg.get("glow", false):
		# Glowing outline effect
		for x in range(S):
			for y in range(S):
				if img.get_pixel(x, y).a > 0:
					for dx in [-1, 1]:
						for dy in [-1, 1]:
							var nx = x + dx
							var ny = y + dy
							if nx >= 0 and nx < S and ny >= 0 and ny < S and img.get_pixel(nx, ny).a == 0:
								img.set_pixel(nx, ny, Color(accent.r, accent.g, accent.b, 0.3))

	# Arms (unless wide/special)
	if not cfg.get("arms_wide", false) and not cfg.get("legs", false) and not cfg.get("tentacles", false):
		_fill(img, body_x - 3, 20, 3, 14, body.darkened(0.1))
		_fill(img, body_x + body_w, 20, 3, 14, body.darkened(0.1))
	if cfg.get("arms_wide", false):
		_fill(img, body_x - 8, 18, 8, 3, body.darkened(0.1))
		_fill(img, body_x + body_w, 18, 8, 3, body.darkened(0.1))

	# Feet
	if not cfg.get("float", false) and not cfg.get("tail", false) and not cfg.get("legs", false) and not cfg.get("tentacles", false):
		_fill(img, body_x + 2, 46, 5, 4, body.darkened(0.2))
		_fill(img, body_x + body_w - 7, 46, 5, 4, body.darkened(0.2))

	# Outline
	_add_outline(img, outline)

	_save(img, id + ".png")

func _fill(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for px in range(maxi(x, 0), mini(x + w, S)):
		for py in range(maxi(y, 0), mini(y + h, S)):
			img.set_pixel(px, py, c)

func _add_outline(img: Image, color: Color) -> void:
	var copy = img.duplicate()
	for x in range(S):
		for y in range(S):
			if copy.get_pixel(x, y).a > 0:
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < S and ny >= 0 and ny < S and copy.get_pixel(nx, ny).a == 0:
							img.set_pixel(nx, ny, color)

func _save(img: Image, filename: String) -> void:
	img.save_png(OUT + filename)
	print("Saved: %s%s" % [OUT, filename])
