extends SceneTree

func _init() -> void:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var body_dark = Color(0.06, 0.08, 0.1)
	var body_mid = Color(0.1, 0.14, 0.18)
	var circuit = Color(0.1, 0.9, 0.6)  # Neon green circuit lines
	var circuit_dim = Color(0.05, 0.5, 0.35)
	var glow_cyan = Color(0.2, 0.95, 0.85, 0.7)  # Cyan glow
	var glow_green = Color(0.3, 1.0, 0.5, 0.8)  # Bright green glow
	var eyes = Color(0.2, 1.0, 0.4)  # Bright green eyes
	var edge_transparent = Color(0.1, 0.8, 0.6, 0.35)  # Semi-transparent edges
	var glitch_green = Color(0.0, 1.0, 0.5, 0.9)
	var glitch_cyan = Color(0.0, 0.9, 0.9, 0.85)
	var outline = Color(0.0, 0.3, 0.2)

	# === HEAD ===
	# Fragmented/glitchy head shape
	_fill(img, 13, 2, 6, 1, body_mid)
	_fill(img, 12, 3, 8, 4, body_dark)
	_fill(img, 13, 3, 6, 3, body_mid)

	# Eyes - bright green, glowing
	img.set_pixel(14, 5, eyes)
	img.set_pixel(17, 5, eyes)
	# Eye glow
	img.set_pixel(13, 5, Color(0.1, 0.6, 0.3, 0.5))
	img.set_pixel(18, 5, Color(0.1, 0.6, 0.3, 0.5))

	# "?" symbol on forehead
	img.set_pixel(14, 3, circuit)
	img.set_pixel(15, 3, circuit)
	img.set_pixel(16, 3, circuit)
	img.set_pixel(16, 4, circuit)
	img.set_pixel(15, 4, circuit)
	img.set_pixel(15, 5, Color(0, 0, 0, 0))  # gap for ? dot below
	img.set_pixel(15, 6, circuit)  # dot of ?

	# === NECK ===
	_fill(img, 14, 7, 4, 1, body_dark)
	img.set_pixel(15, 7, circuit_dim)

	# === TORSO ===
	_fill(img, 11, 8, 10, 6, body_dark)
	_fill(img, 12, 8, 8, 5, body_mid)

	# Circuit lines on torso (vertical center line)
	for y in range(8, 14):
		img.set_pixel(15, y, circuit_dim)
		img.set_pixel(16, y, circuit_dim)

	# Circuit horizontal lines
	img.set_pixel(12, 9, circuit)
	img.set_pixel(13, 9, circuit)
	img.set_pixel(18, 9, circuit)
	img.set_pixel(19, 9, circuit)

	img.set_pixel(13, 11, circuit)
	img.set_pixel(14, 11, circuit)
	img.set_pixel(17, 11, circuit)
	img.set_pixel(18, 11, circuit)

	# Chest circuit nodes
	img.set_pixel(14, 10, glow_green)
	img.set_pixel(17, 10, glow_green)

	# === ARMS ===
	# Left arm
	_fill(img, 9, 9, 2, 5, body_dark)
	img.set_pixel(9, 10, circuit_dim)
	img.set_pixel(9, 12, circuit)
	# Left hand (semi-transparent glitch)
	img.set_pixel(9, 14, edge_transparent)
	img.set_pixel(10, 14, edge_transparent)

	# Right arm
	_fill(img, 21, 9, 2, 5, body_dark)
	img.set_pixel(22, 10, circuit_dim)
	img.set_pixel(22, 12, circuit)
	# Right hand
	img.set_pixel(21, 14, edge_transparent)
	img.set_pixel(22, 14, edge_transparent)

	# === LEGS ===
	# Left leg
	_fill(img, 12, 14, 3, 5, body_dark)
	img.set_pixel(13, 15, circuit_dim)
	img.set_pixel(13, 17, circuit)

	# Right leg
	_fill(img, 17, 14, 3, 5, body_dark)
	img.set_pixel(18, 15, circuit_dim)
	img.set_pixel(18, 17, circuit)

	# Feet
	_fill(img, 11, 19, 4, 2, body_dark)
	_fill(img, 17, 19, 4, 2, body_dark)
	img.set_pixel(12, 19, circuit_dim)
	img.set_pixel(18, 19, circuit_dim)

	# === GLITCH EFFECTS ===
	# Random scattered neon pixels (glitch/digital artifacts)
	var glitch_positions = [
		Vector2i(10, 3), Vector2i(22, 4), Vector2i(8, 11),
		Vector2i(23, 8), Vector2i(11, 16), Vector2i(20, 15),
		Vector2i(7, 6), Vector2i(24, 12), Vector2i(16, 1),
		Vector2i(10, 18), Vector2i(21, 17), Vector2i(25, 6),
		Vector2i(6, 14), Vector2i(23, 2), Vector2i(8, 8),
	]
	for i in range(glitch_positions.size()):
		var pos = glitch_positions[i]
		if i % 2 == 0:
			img.set_pixel(pos.x, pos.y, glitch_green)
		else:
			img.set_pixel(pos.x, pos.y, glitch_cyan)

	# === SEMI-TRANSPARENT EDGES (holographic feel) ===
	# Left edge transparency
	for y in range(8, 19):
		if img.get_pixel(11, y).a > 0:
			img.set_pixel(11, y, Color(img.get_pixel(11, y).r, img.get_pixel(11, y).g, img.get_pixel(11, y).b, 0.5))
	# Right edge transparency
	for y in range(8, 19):
		if img.get_pixel(20, y).a > 0:
			img.set_pixel(20, y, Color(img.get_pixel(20, y).r, img.get_pixel(20, y).g, img.get_pixel(20, y).b, 0.5))

	# Head edges semi-transparent
	img.set_pixel(12, 3, edge_transparent)
	img.set_pixel(19, 3, edge_transparent)
	img.set_pixel(12, 6, edge_transparent)
	img.set_pixel(19, 6, edge_transparent)

	# === GLOW AURA (faint surrounding glow) ===
	var aura_positions = [
		Vector2i(11, 2), Vector2i(19, 2), Vector2i(10, 7),
		Vector2i(21, 7), Vector2i(8, 13), Vector2i(23, 13),
		Vector2i(11, 20), Vector2i(20, 20),
	]
	for pos in aura_positions:
		img.set_pixel(pos.x, pos.y, Color(0.1, 0.7, 0.5, 0.25))

	_outline(img, outline)
	img.save_png("res://assets/sprites/characters/fragmentado.png")
	print("Saved: fragmentado.png")
	quit()

func _fill(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for px in range(x, mini(x + w, 32)):
		for py in range(y, mini(y + h, 32)):
			if px >= 0 and py >= 0:
				img.set_pixel(px, py, c)

func _outline(img: Image, color: Color) -> void:
	var out = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for x in range(32):
		for y in range(32):
			if img.get_pixel(x, y).a > 0:
				continue
			for off in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
				var nx = x + off.x
				var ny = y + off.y
				if nx >= 0 and nx < 32 and ny >= 0 and ny < 32:
					if img.get_pixel(nx, ny).a > 0:
						out.set_pixel(x, y, color)
						break
	for x in range(32):
		for y in range(32):
			if out.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, out.get_pixel(x, y))
