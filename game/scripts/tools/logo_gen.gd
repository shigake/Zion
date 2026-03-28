extends SceneTree

## Generates a 128x32 "ZION" pixel art logo in gold with dark outline.

func _init() -> void:
	var img := Image.create(128, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var gold := Color(0.9, 0.8, 0.3)
	var gold_light := Color(1.0, 0.95, 0.5)
	var outline := Color(0.15, 0.1, 0.0)

	# Pixel font for "ZION" — each letter is 5 wide x 7 tall, 1px gap between
	# Total: 4 letters * 5px + 3 gaps = 23px wide
	# Center horizontally in 128px: offset_x = (128 - 23*4) / 2 = (128 - 23*4) ... scale up 4x
	# At 4x scale: 23*4 = 92px wide, 7*4 = 28px tall
	# offset_x = (128 - 92) / 2 = 18
	# offset_y = (32 - 28) / 2 = 2

	var letters := {
		"Z": [
			[1,1,1,1,1],
			[0,0,0,0,1],
			[0,0,0,1,0],
			[0,0,1,0,0],
			[0,1,0,0,0],
			[1,0,0,0,0],
			[1,1,1,1,1],
		],
		"I": [
			[1,1,1,1,1],
			[0,0,1,0,0],
			[0,0,1,0,0],
			[0,0,1,0,0],
			[0,0,1,0,0],
			[0,0,1,0,0],
			[1,1,1,1,1],
		],
		"O": [
			[0,1,1,1,0],
			[1,0,0,0,1],
			[1,0,0,0,1],
			[1,0,0,0,1],
			[1,0,0,0,1],
			[1,0,0,0,1],
			[0,1,1,1,0],
		],
		"N": [
			[1,0,0,0,1],
			[1,1,0,0,1],
			[1,0,1,0,1],
			[1,0,1,0,1],
			[1,0,0,1,1],
			[1,0,0,1,1],
			[1,0,0,0,1],
		],
	}

	var word := "ZION"
	var scale := 4
	var letter_w := 5
	var gap := 1
	var total_w := word.length() * letter_w + (word.length() - 1) * gap
	var offset_x := int((128 - total_w * scale) / 2)
	var offset_y := int((32 - 7 * scale) / 2)

	# First pass: draw outline (1px offset in all 8 directions at scale)
	for li in range(word.length()):
		var ch: String = word[li]
		var grid: Array = letters[ch]
		var base_x: int = offset_x + li * (letter_w + gap) * scale
		for row in range(grid.size()):
			var row_data: Array = grid[row]
			for col in range(row_data.size()):
				if row_data[col] == 1:
					# Draw outline around this pixel (at scale)
					for dy in range(-1, scale + 1):
						for dx in range(-1, scale + 1):
							var px: int = base_x + col * scale + dx
							var py: int = offset_y + row * scale + dy
							if px >= 0 and px < 128 and py >= 0 and py < 32:
								if img.get_pixel(px, py).a < 0.01:
									img.set_pixel(px, py, outline)

	# Second pass: draw gold pixels on top
	for li in range(word.length()):
		var ch: String = word[li]
		var grid: Array = letters[ch]
		var base_x: int = offset_x + li * (letter_w + gap) * scale
		for row in range(grid.size()):
			var row_data: Array = grid[row]
			for col in range(row_data.size()):
				if row_data[col] == 1:
					for dy in range(scale):
						for dx in range(scale):
							var px: int = base_x + col * scale + dx
							var py: int = offset_y + row * scale + dy
							if px >= 0 and px < 128 and py >= 0 and py < 32:
								# Top highlight row
								var c: Color = gold_light if dy == 0 else gold
								img.set_pixel(px, py, c)

	var dir := DirAccess.open("res://assets/sprites")
	if dir and not dir.dir_exists("ui"):
		dir.make_dir("ui")

	var err := img.save_png("res://assets/sprites/ui/logo.png")
	if err == OK:
		print("Logo saved to res://assets/sprites/ui/logo.png")
	else:
		print("Failed to save logo: ", err)

	quit()
