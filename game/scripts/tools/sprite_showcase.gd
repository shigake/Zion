extends Node3D

## Showcases the billboard sprites in a 3D scene.
## Run this scene to see how they look.

func _ready() -> void:
	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(0, 1.5, 5)
	cam.look_at(Vector3(0, 0.8, 0))
	cam.fov = 40
	add_child(cam)

	# Light
	var light = DirectionalLight3D.new()
	light.rotation.x = deg_to_rad(-45)
	light.rotation.y = deg_to_rad(30)
	light.light_energy = 2.0
	add_child(light)

	# Ground
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(20, 20)
	ground.mesh = plane
	var ground_mat = StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.15, 0.2, 0.12)
	ground.material_override = ground_mat
	add_child(ground)

	# Labels
	var sprites = {
		"Ronin": "res://assets/sprites/characters/ronin.png",
		"Soldado": "res://assets/sprites/characters/soldado.png",
		"Mago": "res://assets/sprites/characters/mago.png",
		"Slime": "res://assets/sprites/enemies/slime.png",
	}

	var x_offset = -2.5
	for label in sprites:
		var path = sprites[label]
		if not ResourceLoader.exists(path):
			x_offset += 1.8
			continue

		var tex = load(path) as Texture2D
		if tex == null:
			x_offset += 1.8
			continue

		# Billboard sprite
		var sprite = Sprite3D.new()
		sprite.texture = tex
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.pixel_size = 0.04  # Each pixel = 0.04 units = ~1.28m for 32px sprite
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Crisp pixels
		sprite.position = Vector3(x_offset, 0.65, 0)
		sprite.shaded = false
		sprite.transparent = true
		add_child(sprite)

		# Name label
		var name_label = Label3D.new()
		name_label.text = label
		name_label.font_size = 32
		name_label.position = Vector3(x_offset, -0.1, 0)
		name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		name_label.pixel_size = 0.01
		add_child(name_label)

		x_offset += 1.8
