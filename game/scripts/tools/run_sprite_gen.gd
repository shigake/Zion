extends SceneTree

func _init() -> void:
	var gen = load("res://scripts/tools/sprite_generator.gd").new()
	root.add_child(gen)
	# Wait for _ready to execute
	await root.get_tree().process_frame
	await root.get_tree().process_frame
	quit()
