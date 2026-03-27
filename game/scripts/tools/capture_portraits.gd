extends SceneTree

## Captures 3D model portraits for all 12 characters.
## Run: godot --path game --script res://scripts/tools/capture_portraits.gd

const CHARACTERS := [
	"ronin", "soldado", "mago", "berserker", "ninja", "necro",
	"pirata", "engenheiro", "vampiro", "gladiador", "chef", "mystery"
]
const PORTRAIT_SIZE := Vector2i(128, 128)
const OUTPUT_DIR := "res://assets/icons/characters/"

const CHARACTER_SCALE := Vector3(1.2, 1.2, 1.2)

# KayKit animation paths (same as model_factory.gd)
const KAYKIT_ANIM_PATHS: Array[String] = [
	"res://assets/models/downloaded/kaykit/adventurers/KayKit_Adventurers_2.0_FREE/Animations/gltf/Rig_Medium/Rig_Medium_General.glb",
	"res://assets/models/downloaded/kaykit/adventurers/KayKit_Adventurers_2.0_FREE/Animations/gltf/Rig_Medium/Rig_Medium_MovementBasic.glb",
	"res://assets/models/downloaded/kaykit/skeletons/KayKit_Skeletons_1.1_FREE/Animations/gltf/Rig_Medium/Rig_Medium_General.glb",
]

var _cached_anim_lib: AnimationLibrary = null

func _init() -> void:
	# Wait for tree to be ready
	await process_frame
	await process_frame

	for char_id in CHARACTERS:
		await _capture_character(char_id)

	print("All %d portraits captured!" % CHARACTERS.size())
	quit()

func _capture_character(char_id: String) -> void:
	# Create SubViewport for rendering
	var viewport := SubViewport.new()
	viewport.size = PORTRAIT_SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	# Camera - full body centered, far enough to see entire character
	var camera := Camera3D.new()
	camera.position = Vector3(0.3, 1.0, 4.0)
	camera.look_at(Vector3(0, 0.5, 0))
	camera.fov = 18
	viewport.add_child(camera)

	# Key light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 40, 0)
	light.light_energy = 1.8
	viewport.add_child(light)

	# Fill light
	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-20, -80, 0)
	fill_light.light_energy = 0.6
	viewport.add_child(fill_light)

	# Rim light
	var rim_light := DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-10, 180, 0)
	rim_light.light_energy = 0.4
	viewport.add_child(rim_light)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_color = Color(0.5, 0.55, 0.65)
	env.ambient_light_energy = 0.7
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	viewport.add_child(world_env)

	# Load character model directly (without ModelFactory autoload)
	var model := _load_character_model(char_id)
	if model:
		viewport.add_child(model)
		# Try to play idle animation
		var anim_player := _find_node_by_type(model, "AnimationPlayer") as AnimationPlayer
		if anim_player:
			for anim_name in anim_player.get_animation_list():
				if "idle" in anim_name.to_lower():
					anim_player.play(anim_name)
					break

	# Wait many frames for animation to settle and render
	for i in range(30):
		await process_frame

	# Capture
	var img := viewport.get_texture().get_image()
	var path := OUTPUT_DIR + char_id + ".png"
	var global_path := ProjectSettings.globalize_path(path)
	img.save_png(global_path)
	print("Saved portrait: %s (%dx%d)" % [char_id, img.get_width(), img.get_height()])

	# Cleanup
	viewport.queue_free()
	await process_frame

func _load_character_model(char_id: String) -> Node3D:
	var glb_path := "res://assets/models/characters/%s.glb" % char_id
	if not ResourceLoader.exists(glb_path):
		print("  Model not found: %s" % glb_path)
		return null
	var scene := load(glb_path) as PackedScene
	if scene == null:
		return null
	var instance := scene.instantiate()
	if instance == null:
		return null

	# Inject animations if needed
	_inject_animations(instance)

	var model_root := Node3D.new()
	model_root.set_meta("glb_model", true)
	instance.scale = CHARACTER_SCALE
	model_root.add_child(instance)
	return model_root

func _inject_animations(instance: Node) -> void:
	var anim_player := _find_node_by_type(instance, "AnimationPlayer") as AnimationPlayer
	if not anim_player:
		var skeleton := _find_node_by_type(instance, "Skeleton3D") as Skeleton3D
		if not skeleton:
			return
		anim_player = AnimationPlayer.new()
		anim_player.name = "InjectedAnimationPlayer"
		skeleton.add_child(anim_player)
		anim_player.owner = instance

	# Check if has real anims
	var real_anims := 0
	for anim_name in anim_player.get_animation_list():
		if anim_name != "RESET" and anim_name != "T-Pose":
			real_anims += 1
	if real_anims > 0:
		return

	# Load external anims
	var lib := _get_anim_library()
	if lib == null:
		return
	for anim_name in lib.get_animation_list():
		if not anim_player.has_animation(anim_name):
			var anim_lib: AnimationLibrary
			if anim_player.has_animation_library(""):
				anim_lib = anim_player.get_animation_library("")
			else:
				anim_lib = AnimationLibrary.new()
				anim_player.add_animation_library("", anim_lib)
			anim_lib.add_animation(anim_name, lib.get_animation(anim_name))

func _get_anim_library() -> AnimationLibrary:
	if _cached_anim_lib:
		return _cached_anim_lib
	_cached_anim_lib = AnimationLibrary.new()
	for anim_path in KAYKIT_ANIM_PATHS:
		if not ResourceLoader.exists(anim_path):
			continue
		var scene := load(anim_path) as PackedScene
		if scene == null:
			continue
		var instance := scene.instantiate()
		if instance == null:
			continue
		var ap := _find_node_by_type(instance, "AnimationPlayer") as AnimationPlayer
		if ap:
			for anim_name in ap.get_animation_list():
				if anim_name == "RESET":
					continue
				if not _cached_anim_lib.has_animation(anim_name):
					_cached_anim_lib.add_animation(anim_name, ap.get_animation(anim_name).duplicate())
		instance.queue_free()
	if _cached_anim_lib.get_animation_list().size() > 0:
		return _cached_anim_lib
	_cached_anim_lib = null
	return null

func _find_node_by_type(node: Node, type_name: String) -> Node:
	for child in node.get_children():
		if child.get_class() == type_name:
			return child
		var found := _find_node_by_type(child, type_name)
		if found:
			return found
	return null
