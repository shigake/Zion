extends Control

## Stage selection screen — Super Mario World style map with connected nodes.

# ── Map layout ────────────────────────────────────────────────────────

const MAP_POSITIONS := {
	"cemetery": Vector2(100, 100),
	"forest": Vector2(300, 100),
	"farm": Vector2(500, 100),
	"tokyo": Vector2(100, 250),
	"volcano": Vector2(300, 250),
	"ocean": Vector2(500, 250),
	"arena": Vector2(100, 400),
	"space": Vector2(300, 400),
	"castle": Vector2(500, 400),
	"candy": Vector2(700, 350),
}

const MAP_CONNECTIONS := [
	["cemetery", "forest"], ["forest", "farm"],
	["cemetery", "tokyo"], ["farm", "ocean"],
	["tokyo", "volcano"], ["volcano", "ocean"],
	["tokyo", "arena"], ["ocean", "castle"],
	["arena", "space"], ["space", "castle"],
	["castle", "candy"],
]

# Adjacency built from MAP_CONNECTIONS for navigation
var _adjacency: Dictionary = {}

# Theme colors per stage
const STAGE_COLORS := {
	"cemetery": Color(0.5, 0.4, 0.6),
	"forest": Color(0.2, 0.6, 0.2),
	"farm": Color(0.7, 0.5, 0.2),
	"tokyo": Color(0.9, 0.2, 0.5),
	"volcano": Color(0.9, 0.3, 0.1),
	"ocean": Color(0.2, 0.4, 0.8),
	"arena": Color(0.8, 0.7, 0.3),
	"space": Color(0.4, 0.5, 0.9),
	"castle": Color(0.4, 0.2, 0.5),
	"candy": Color(0.9, 0.5, 0.6),
}

const BOSS_NAMES := {
	"cemetery": "Necromancer",
	"forest": "Fairy queen",
	"farm": "Alien cow",
	"tokyo": "AI overlord",
	"volcano": "Demon lord",
	"ocean": "Leviathan",
	"arena": "Emperor",
	"space": "Singularity",
	"castle": "Dracula",
	"candy": "Sugar king",
}

const ICON_SIZE := 32.0
const NODE_RADIUS := 22.0
const PATH_WIDTH := 3.0
const GLOW_RADIUS := 28.0
const MARKER_BOB_SPEED := 3.0
const MARKER_BOB_AMOUNT := 4.0
const HOVER_SCALE_TARGET := 1.2
const HOVER_SCALE_SPEED := 8.0

var stage_ids: Array[String] = [
	"cemetery", "forest", "farm", "tokyo", "volcano",
	"ocean", "arena", "space", "castle", "candy",
]

var selected_stage: String = "cemetery"
var _hovered_stage: String = "cemetery"
var _stage_scales: Dictionary = {}
var _marker_time: float = 0.0
var _stage_textures: Dictionary = {}

# Scene tree references
@onready var map_area: Control = $MapArea
@onready var info_panel: PanelContainer = $InfoPanel
@onready var info_name: Label = $InfoPanel/InfoVBox/InfoName
@onready var info_boss: Label = $InfoPanel/InfoVBox/InfoBoss
@onready var info_best_time: Label = $InfoPanel/InfoVBox/InfoBestTime
@onready var info_desc: Label = $InfoPanel/InfoVBox/InfoDesc
@onready var info_icon: TextureRect = $InfoPanel/InfoVBox/InfoIcon
@onready var play_btn: Button = $InfoPanel/InfoVBox/PlayButton
@onready var back_btn: Button = $ButtonRow/BackButton

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_adjacency()
	_load_textures()
	_init_scales()
	_style_info_panel()
	_style_play_button()
	_style_back_button()

	play_btn.pressed.connect(_on_play)
	back_btn.pressed.connect(_on_back)

	# Connect map_area draw
	map_area.draw.connect(_draw_map)
	map_area.mouse_filter = Control.MOUSE_FILTER_STOP
	map_area.gui_input.connect(_on_map_input)

	# Select first unlocked stage
	for sid in stage_ids:
		if SaveManager.is_stage_unlocked(sid):
			_hovered_stage = sid
			selected_stage = sid
			break

	_update_info_panel()
	play_btn.grab_focus()
	GamepadUI.notify_menu_opened()

func _process(delta: float) -> void:
	_marker_time += delta

	# Animate scales toward target
	for sid in stage_ids:
		var target := HOVER_SCALE_TARGET if sid == _hovered_stage else 1.0
		_stage_scales[sid] = lerpf(_stage_scales[sid], target, HOVER_SCALE_SPEED * delta)

	map_area.queue_redraw()

# ── Data helpers ──────────────────────────────────────────────────────

func _get_stage_data(stage_id: String) -> Dictionary:
	return {
		"id": stage_id,
		"name": LocaleManager.tr_key("stage_" + stage_id),
		"description": LocaleManager.tr_key("stage_" + stage_id + "_desc"),
	}

func _build_adjacency() -> void:
	for sid in stage_ids:
		_adjacency[sid] = []
	for conn in MAP_CONNECTIONS:
		var a: String = conn[0]
		var b: String = conn[1]
		if b not in _adjacency[a]:
			_adjacency[a].append(b)
		if a not in _adjacency[b]:
			_adjacency[b].append(a)

func _load_textures() -> void:
	for sid in stage_ids:
		var path := "res://assets/sprites/stages/%s.png" % sid
		if ResourceLoader.exists(path):
			_stage_textures[sid] = load(path)

func _init_scales() -> void:
	for sid in stage_ids:
		_stage_scales[sid] = 1.0

# ── Map drawing ───────────────────────────────────────────────────────

func _draw_map() -> void:
	var area_size := map_area.size
	# Scale map coordinates to fit the area
	var scale_x := area_size.x / 800.0
	var scale_y := area_size.y / 500.0

	# Draw connections (paths)
	for conn in MAP_CONNECTIONS:
		var a: String = conn[0]
		var b: String = conn[1]
		var pos_a := MAP_POSITIONS[a] * Vector2(scale_x, scale_y)
		var pos_b := MAP_POSITIONS[b] * Vector2(scale_x, scale_y)
		var a_unlocked := SaveManager.is_stage_unlocked(a)
		var b_unlocked := SaveManager.is_stage_unlocked(b)

		var line_color: Color
		if a_unlocked and b_unlocked:
			line_color = Color(0.85, 0.7, 0.2, 0.9)  # Gold
		else:
			line_color = Color(0.25, 0.25, 0.3, 0.5)  # Gray

		map_area.draw_line(pos_a, pos_b, line_color, PATH_WIDTH, true)

	# Draw stage nodes
	for sid in stage_ids:
		var pos := MAP_POSITIONS[sid] * Vector2(scale_x, scale_y)
		var unlocked := SaveManager.is_stage_unlocked(sid)
		var theme_color: Color = STAGE_COLORS.get(sid, Color(0.4, 0.4, 0.5))
		var sc: float = _stage_scales.get(sid, 1.0)

		if unlocked:
			# Glow circle behind
			var glow_color := theme_color
			glow_color.a = 0.25
			map_area.draw_circle(pos, GLOW_RADIUS * sc, glow_color)

			# Node circle
			map_area.draw_circle(pos, NODE_RADIUS * sc, theme_color.lerp(Color(0.08, 0.08, 0.12), 0.3))

			# Border
			map_area.draw_arc(pos, NODE_RADIUS * sc, 0, TAU, 32, theme_color.lerp(Color.WHITE, 0.3), 2.0, true)

			# Stage icon
			if sid in _stage_textures:
				var tex: Texture2D = _stage_textures[sid]
				var icon_sc := (ICON_SIZE * sc) / max(tex.get_width(), 1)
				var icon_size := tex.get_size() * icon_sc
				var icon_pos := pos - icon_size * 0.5
				map_area.draw_texture_rect(tex, Rect2(icon_pos, icon_size), false)
		else:
			# Locked — gray circle
			map_area.draw_circle(pos, NODE_RADIUS * sc, Color(0.12, 0.12, 0.15))
			map_area.draw_arc(pos, NODE_RADIUS * sc, 0, TAU, 32, Color(0.2, 0.2, 0.25), 1.5, true)

			# Lock icon (simple "X")
			var half := 6.0 * sc
			map_area.draw_line(pos - Vector2(half, half), pos + Vector2(half, half), Color(0.35, 0.35, 0.4), 2.0, true)
			map_area.draw_line(pos - Vector2(-half, half), pos + Vector2(-half, half), Color(0.35, 0.35, 0.4), 2.0, true)

		# Name label below node
		var label_text := LocaleManager.tr_key("stage_" + sid)
		var font := ThemeDB.fallback_font
		var font_size := 11
		if font:
			var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_pos := Vector2(pos.x - text_size.x * 0.5, pos.y + NODE_RADIUS * sc + 14)
			var text_color := Color(0.75, 0.75, 0.8) if unlocked else Color(0.3, 0.3, 0.35)
			map_area.draw_string(font, text_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

	# Draw player marker on hovered stage
	if _hovered_stage != "":
		var marker_pos := MAP_POSITIONS[_hovered_stage] * Vector2(scale_x, scale_y)
		var bob_offset := sin(_marker_time * MARKER_BOB_SPEED) * MARKER_BOB_AMOUNT
		var marker_y := marker_pos.y - NODE_RADIUS - 10 + bob_offset

		# Small triangle pointing down
		var tri_size := 7.0
		var p1 := Vector2(marker_pos.x, marker_y + tri_size)
		var p2 := Vector2(marker_pos.x - tri_size, marker_y - tri_size * 0.5)
		var p3 := Vector2(marker_pos.x + tri_size, marker_y - tri_size * 0.5)
		map_area.draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(1.0, 0.85, 0.2))

# ── Map input (mouse) ────────────────────────────────────────────────

func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var area_size := map_area.size
		var scale_x := area_size.x / 800.0
		var scale_y := area_size.y / 500.0
		var mouse_pos: Vector2 = event.position

		# Find closest stage node
		var closest_id := ""
		var closest_dist := 999999.0
		for sid in stage_ids:
			var pos := MAP_POSITIONS[sid] * Vector2(scale_x, scale_y)
			var dist := mouse_pos.distance_to(pos)
			if dist < NODE_RADIUS * 1.8 and dist < closest_dist:
				closest_dist = dist
				closest_id = sid

		if closest_id != "" and SaveManager.is_stage_unlocked(closest_id):
			_hovered_stage = closest_id

		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if closest_id != "" and SaveManager.is_stage_unlocked(closest_id):
				selected_stage = closest_id
				_hovered_stage = closest_id
				_update_info_panel()

		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if closest_id != "" and closest_id == selected_stage:
				# Double-click or click on already selected -> play
				pass  # Single click selects; use Play button to start

# ── Keyboard / gamepad navigation ────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		if get_viewport():
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_accept"):
		if _hovered_stage != "" and SaveManager.is_stage_unlocked(_hovered_stage):
			selected_stage = _hovered_stage
			_update_info_panel()
			_on_play()
			if get_viewport():
				get_viewport().set_input_as_handled()
		return

	var dir := Vector2.ZERO
	if event.is_action_pressed("ui_left"):
		dir = Vector2.LEFT
	elif event.is_action_pressed("ui_right"):
		dir = Vector2.RIGHT
	elif event.is_action_pressed("ui_up"):
		dir = Vector2.UP
	elif event.is_action_pressed("ui_down"):
		dir = Vector2.DOWN

	if dir != Vector2.ZERO and _hovered_stage != "":
		_navigate_map(dir)
		if get_viewport():
			get_viewport().set_input_as_handled()

func _navigate_map(direction: Vector2) -> void:
	var current_pos: Vector2 = MAP_POSITIONS[_hovered_stage]
	var neighbors: Array = _adjacency.get(_hovered_stage, [])

	# Find the neighbor that best matches the direction
	var best_id := ""
	var best_score := -999.0

	for nid in neighbors:
		if not SaveManager.is_stage_unlocked(nid):
			continue
		var npos: Vector2 = MAP_POSITIONS[nid]
		var delta := (npos - current_pos).normalized()
		var score := delta.dot(direction)
		if score > 0.3 and score > best_score:
			best_score = score
			best_id = nid

	if best_id != "":
		_hovered_stage = best_id
		selected_stage = best_id
		_update_info_panel()
		AudioManager.play_sfx("menu_hover")

# ── Info panel ────────────────────────────────────────────────────────

func _update_info_panel() -> void:
	var stage := _get_stage_data(selected_stage)
	var theme_color: Color = STAGE_COLORS.get(selected_stage, Color(0.4, 0.4, 0.5))

	info_name.text = stage["name"]
	info_name.add_theme_color_override("font_color", theme_color.lerp(Color.WHITE, 0.4))

	info_boss.text = "Boss: %s" % BOSS_NAMES.get(selected_stage, "???")
	info_desc.text = stage["description"]

	# Best time
	var best := SaveManager.data.get("best_time", 0.0) as float
	if best > 0.0:
		var mins := int(best) / 60
		var secs := int(best) % 60
		info_best_time.text = "Melhor tempo: %d:%02d" % [mins, secs]
	else:
		info_best_time.text = ""

	# Large icon
	if selected_stage in _stage_textures:
		info_icon.texture = _stage_textures[selected_stage]
		info_icon.visible = true
	else:
		info_icon.visible = false

	# Update panel border color
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.07, 0.07, 0.1, 1.0)
	panel_sb.set_corner_radius_all(6)
	panel_sb.set_border_width_all(1)
	panel_sb.border_color = theme_color.lerp(Color(0.07, 0.07, 0.1), 0.5)
	panel_sb.content_margin_left = 16.0
	panel_sb.content_margin_right = 16.0
	panel_sb.content_margin_top = 14.0
	panel_sb.content_margin_bottom = 14.0
	info_panel.add_theme_stylebox_override("panel", panel_sb)

	# Enable/disable play button
	play_btn.disabled = not SaveManager.is_stage_unlocked(selected_stage)

# ── Styling ───────────────────────────────────────────────────────────

func _style_info_panel() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.07, 0.1, 1.0)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 14.0
	sb.content_margin_bottom = 14.0
	info_panel.add_theme_stylebox_override("panel", sb)

func _style_play_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.15, 0.4, 0.15, 1.0)
	normal.set_corner_radius_all(6)
	normal.set_border_width_all(1)
	normal.border_color = Color(0.3, 0.6, 0.3, 1.0)
	play_btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.2, 0.5, 0.2, 1.0)
	hover.set_corner_radius_all(6)
	hover.set_border_width_all(1)
	hover.border_color = Color(0.4, 0.7, 0.4, 1.0)
	play_btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.1, 0.3, 0.1, 1.0)
	pressed.set_corner_radius_all(6)
	pressed.set_border_width_all(1)
	pressed.border_color = Color(0.25, 0.5, 0.25, 1.0)
	play_btn.add_theme_stylebox_override("pressed", pressed)

	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.18, 0.45, 0.18, 1.0)
	focus.set_corner_radius_all(6)
	focus.set_border_width_all(2)
	focus.border_color = Color(0.4, 0.8, 0.4, 1.0)
	play_btn.add_theme_stylebox_override("focus", focus)

	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color(0.08, 0.08, 0.1, 1.0)
	disabled.set_corner_radius_all(6)
	play_btn.add_theme_stylebox_override("disabled", disabled)

	play_btn.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9))
	play_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	play_btn.add_theme_font_size_override("font_size", 16)

func _style_back_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.12, 0.16, 1.0)
	normal.set_corner_radius_all(6)
	normal.set_border_width_all(1)
	normal.border_color = Color(0.25, 0.25, 0.3, 1.0)
	back_btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.16, 0.16, 0.22, 1.0)
	hover.set_corner_radius_all(6)
	hover.set_border_width_all(1)
	hover.border_color = Color(0.4, 0.4, 0.5, 1.0)
	back_btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.1, 0.1, 0.14, 1.0)
	pressed.set_corner_radius_all(6)
	pressed.set_border_width_all(1)
	pressed.border_color = Color(0.3, 0.5, 0.8, 1.0)
	back_btn.add_theme_stylebox_override("pressed", pressed)

	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.14, 0.14, 0.2, 1.0)
	focus.set_corner_radius_all(6)
	focus.set_border_width_all(2)
	focus.border_color = Color(0.3, 0.5, 0.9, 1.0)
	back_btn.add_theme_stylebox_override("focus", focus)

	back_btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	back_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	back_btn.add_theme_font_size_override("font_size", 14)

# ── Actions ───────────────────────────────────────────────────────────

func _on_play() -> void:
	if not SaveManager.is_stage_unlocked(selected_stage):
		return
	AudioManager.play_sfx("menu_click")
	GameManager.selected_stage = selected_stage
	LoadingScreen.transition_to("res://scenes/ui/relic_select.tscn")

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/character_select.tscn")
