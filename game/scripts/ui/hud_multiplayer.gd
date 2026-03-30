class_name HUDMultiplayer

## Gerencia elementos de HUD especificos de multiplayer:
## Ally HP bars, ping, ally arrows, host migration overlay.
## Instanciado pelo HUD principal quando MultiplayerManager.is_online.

var hud: CanvasLayer

var ally_hp_panel: PanelContainer = null
var ally_hp_container: VBoxContainer = null
var ping_label: Label = null
var ally_arrows: Dictionary = {}
var migration_label: Label = null
var _prev_ally_hash: String = ""
var _ally_bars: Dictionary = {}
var _ally_name_labels: Dictionary = {}
var _ally_hp_labels: Dictionary = {}

func setup(parent_hud: CanvasLayer) -> void:
	hud = parent_hud
	_setup_ally_hp_panel()
	_setup_ping_label()
	_setup_migration_label()
	MultiplayerManager.host_migration_started.connect(_on_host_migration_started)
	MultiplayerManager.host_migration_completed.connect(_on_host_migration_completed)
	MultiplayerManager.reconnection_attempted.connect(_on_reconnection_attempted)
	MultiplayerManager.reconnection_succeeded.connect(_on_reconnection_succeeded)
	MultiplayerManager.reconnection_failed.connect(_on_reconnection_failed)

func update_ally_hp() -> void:
	if not ally_hp_container or not MultiplayerManager.is_online:
		if ally_hp_panel:
			ally_hp_panel.visible = false
		return
	var players_list = GameManager.get_players()
	if players_list.size() <= 1:
		if ally_hp_panel:
			ally_hp_panel.visible = false
		return
	if ally_hp_panel:
		ally_hp_panel.visible = true

	var ally_hash := ""
	for p in players_list:
		if not is_instance_valid(p) or not "player_id" in p:
			continue
		if p.is_local:
			continue
		ally_hash += str(p.player_id) + ","

	if ally_hash != _prev_ally_hash:
		_prev_ally_hash = ally_hash
		_ally_bars.clear()
		_ally_name_labels.clear()
		_ally_hp_labels.clear()
		for child in ally_hp_container.get_children():
			child.queue_free()

		var colors = MultiplayerManager.get_player_colors()
		for p in players_list:
			if not is_instance_valid(p) or not "player_id" in p:
				continue
			if p.is_local:
				continue
			var pid = p.player_id
			var color = colors.get(pid, Color.GREEN)
			_create_ally_bar(pid, color)
	else:
		for p in players_list:
			if not is_instance_valid(p) or not "player_id" in p:
				continue
			if p.is_local:
				continue
			var pid = p.player_id
			var ally_max_hp = MultiplayerManager.get_player_max_hp(pid)
			var ally_hp = MultiplayerManager.get_player_hp(pid)
			if pid in _ally_bars and is_instance_valid(_ally_bars[pid]):
				_ally_bars[pid].max_value = ally_max_hp
				_ally_bars[pid].value = lerpf(_ally_bars[pid].value, float(ally_hp), 0.15)
			if pid in _ally_hp_labels and is_instance_valid(_ally_hp_labels[pid]):
				_ally_hp_labels[pid].text = "%d/%d" % [ally_hp, ally_max_hp]
				if ally_max_hp > 0 and float(ally_hp) / float(ally_max_hp) < 0.25:
					_ally_hp_labels[pid].add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
				else:
					_ally_hp_labels[pid].add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))

func _create_ally_bar(pid: int, color: Color) -> void:
	var ally_vbox = VBoxContainer.new()
	ally_vbox.add_theme_constant_override("separation", 1)

	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 4)

	var color_dot = ColorRect.new()
	color_dot.custom_minimum_size = Vector2(8, 8)
	color_dot.color = color
	top_hbox.add_child(color_dot)

	var name_lbl = Label.new()
	var char_name = "P%d" % pid
	if pid in MultiplayerManager.players:
		var char_id = MultiplayerManager.players[pid].get("character", "")
		if char_id != "":
			char_name = char_id.capitalize()
	name_lbl.text = char_name
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", color)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(name_lbl)
	_ally_name_labels[pid] = name_lbl

	var hp_lbl = Label.new()
	var ally_hp = MultiplayerManager.get_player_hp(pid)
	var ally_max_hp = MultiplayerManager.get_player_max_hp(pid)
	hp_lbl.text = "%d/%d" % [ally_hp, ally_max_hp]
	hp_lbl.add_theme_font_size_override("font_size", 10)
	hp_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_hbox.add_child(hp_lbl)
	_ally_hp_labels[pid] = hp_lbl

	ally_vbox.add_child(top_hbox)

	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(140, 10)
	bar.max_value = ally_max_hp
	bar.value = ally_hp
	bar.show_percentage = false

	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)

	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	bar_bg.set_corner_radius_all(3)
	bar_bg.set_border_width_all(1)
	bar_bg.border_color = color * Color(1, 1, 1, 0.3)
	bar.add_theme_stylebox_override("background", bar_bg)

	ally_vbox.add_child(bar)
	ally_hp_container.add_child(ally_vbox)
	_ally_bars[pid] = bar

func update_ping() -> void:
	if not ping_label or not MultiplayerManager.is_online:
		return
	if hud.multiplayer.is_server():
		ping_label.text = "Host"
		ping_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	else:
		var rtt = MultiplayerManager.get_ping()
		ping_label.text = "Ping: %dms" % rtt
		ping_label.add_theme_color_override("font_color", MultiplayerManager.get_ping_color())

func update_ally_arrows() -> void:
	if not MultiplayerManager.is_online:
		return
	var camera = hud.get_viewport().get_camera_3d()
	if not camera:
		return
	var viewport_size = hud.get_viewport().get_visible_rect().size
	var local_player = hud.get_tree().get_first_node_in_group("players")
	if not local_player or not is_instance_valid(local_player):
		return
	var players_in_group = GameManager.get_players()
	var colors = MultiplayerManager.get_player_colors()
	for p in players_in_group:
		if not is_instance_valid(p) or p == local_player:
			continue
		var pid = p.player_id if "player_id" in p else 0
		var dist_3d = local_player.global_position.distance_to(p.global_position)
		var behind_camera = camera.global_transform.basis.z.dot(p.global_position - camera.global_position) > 0
		var screen_pos = camera.unproject_position(p.global_position)
		if behind_camera:
			screen_pos = viewport_size - screen_pos
		var margin = 40.0
		var is_offscreen = behind_camera or screen_pos.x < margin or screen_pos.x > viewport_size.x - margin or screen_pos.y < margin or screen_pos.y > viewport_size.y - margin
		if not is_offscreen:
			if pid in ally_arrows and is_instance_valid(ally_arrows[pid]):
				ally_arrows[pid].visible = false
			continue
		if pid not in ally_arrows or not is_instance_valid(ally_arrows[pid]):
			var arrow = Label.new()
			arrow.add_theme_font_size_override("font_size", 18)
			arrow.add_theme_color_override("font_color", colors.get(pid, Color.GREEN))
			arrow.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
			arrow.add_theme_constant_override("shadow_offset_x", 1)
			arrow.add_theme_constant_override("shadow_offset_y", 1)
			hud.add_child(arrow)
			ally_arrows[pid] = arrow
		var arrow: Label = ally_arrows[pid]
		arrow.visible = true
		var clamped = Vector2(
			clampf(screen_pos.x, margin, viewport_size.x - margin),
			clampf(screen_pos.y, margin, viewport_size.y - margin)
		)
		arrow.position = clamped
		var dir = (screen_pos - viewport_size / 2).normalized()
		var arrow_char: String
		if absf(dir.x) > absf(dir.y):
			arrow_char = "►" if dir.x > 0 else "◄"
		else:
			arrow_char = "▼" if dir.y > 0 else "▲"
		var dist_text = "%dm" % int(dist_3d) if dist_3d >= 10 else "%.0fm" % dist_3d
		arrow.text = "%s P%d %s" % [arrow_char, pid, dist_text]
		var alpha = clampf(remap(dist_3d, 5.0, 50.0, 0.5, 1.0), 0.5, 1.0)
		arrow.modulate.a = alpha

# ---- Setup helpers ----

func _setup_ally_hp_panel() -> void:
	ally_hp_panel = PanelContainer.new()
	ally_hp_panel.name = "AllyHPPanel"
	ally_hp_panel.anchor_left = 1.0
	ally_hp_panel.anchor_top = 0.0
	ally_hp_panel.anchor_right = 1.0
	ally_hp_panel.anchor_bottom = 0.0
	ally_hp_panel.offset_left = -180.0
	ally_hp_panel.offset_top = 60.0
	ally_hp_panel.offset_right = -10.0
	ally_hp_panel.offset_bottom = 200.0
	ally_hp_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.1, 0.75)
	panel_style.set_corner_radius_all(6)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(0.2, 0.3, 0.5, 0.6)
	panel_style.set_content_margin_all(8)
	ally_hp_panel.add_theme_stylebox_override("panel", panel_style)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	var title = Label.new()
	title.text = "Aliados"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	ally_hp_container = VBoxContainer.new()
	ally_hp_container.add_theme_constant_override("separation", 4)
	vbox.add_child(ally_hp_container)
	ally_hp_panel.add_child(vbox)
	hud.add_child(ally_hp_panel)

func _setup_ping_label() -> void:
	ping_label = Label.new()
	ping_label.name = "PingLabel"
	ping_label.anchor_left = 1.0
	ping_label.anchor_top = 0.0
	ping_label.anchor_right = 1.0
	ping_label.anchor_bottom = 0.0
	ping_label.offset_left = -100.0
	ping_label.offset_top = 8.0
	ping_label.offset_right = -10.0
	ping_label.offset_bottom = 28.0
	ping_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ping_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ping_label.add_theme_font_size_override("font_size", 11)
	ping_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	hud.add_child(ping_label)

func _setup_migration_label() -> void:
	migration_label = Label.new()
	migration_label.name = "MigrationLabel"
	migration_label.set_anchors_preset(Control.PRESET_CENTER)
	migration_label.offset_left = -200.0
	migration_label.offset_top = -30.0
	migration_label.offset_right = 200.0
	migration_label.offset_bottom = 30.0
	migration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	migration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	migration_label.add_theme_font_size_override("font_size", 22)
	migration_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	migration_label.visible = false
	hud.add_child(migration_label)
	var bg = ColorRect.new()
	bg.name = "MigrationBG"
	bg.color = Color(0.0, 0.0, 0.0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.visible = false
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(bg)
	bg.move_to_front()
	migration_label.move_to_front()

# ---- Migration overlay ----

var _migration_bg: ColorRect :
	get:
		return hud.get_node_or_null("MigrationBG") if hud else null

func _show_migration_overlay(text: String) -> void:
	if migration_label:
		migration_label.text = text
		migration_label.visible = true
		migration_label.modulate = Color.WHITE
		var tween = hud.create_tween().set_loops()
		tween.tween_property(migration_label, "modulate:a", 0.4, 0.6)
		tween.tween_property(migration_label, "modulate:a", 1.0, 0.6)
		migration_label.set_meta("pulse_tween", tween)
	if _migration_bg:
		_migration_bg.visible = true

func _hide_migration_overlay() -> void:
	if migration_label:
		if migration_label.has_meta("pulse_tween"):
			var tw = migration_label.get_meta("pulse_tween") as Tween
			if tw and tw.is_valid():
				tw.kill()
		migration_label.visible = false
	if _migration_bg:
		_migration_bg.visible = false

func _flash_migration_message(text: String, color: Color, duration: float = 3.0) -> void:
	if migration_label:
		if migration_label.has_meta("pulse_tween"):
			var tw = migration_label.get_meta("pulse_tween") as Tween
			if tw and tw.is_valid():
				tw.kill()
		migration_label.text = text
		migration_label.modulate = color
		migration_label.visible = true
	if _migration_bg:
		_migration_bg.visible = true
	var tween = hud.create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(_hide_migration_overlay)

func _on_host_migration_started() -> void:
	_show_migration_overlay("Migrando host...")

func _on_host_migration_completed(_new_host_id: Variant = null) -> void:
	var is_new_host = (typeof(_new_host_id) == TYPE_INT and _new_host_id == MultiplayerManager.local_player_id)
	var msg = "Voce e o novo host!" if is_new_host else "Host migrado com sucesso"
	_flash_migration_message(msg, Color(0.3, 0.95, 0.4), 3.0)

func _on_reconnection_attempted(attempt: Variant = null, max_attempts: Variant = null) -> void:
	var a = attempt if typeof(attempt) == TYPE_INT else 0
	var m = max_attempts if typeof(max_attempts) == TYPE_INT else MultiplayerManager.MAX_RECONNECT_ATTEMPTS
	_show_migration_overlay("Reconectando... (%d/%d)" % [a, m])

func _on_reconnection_succeeded() -> void:
	_flash_migration_message("Reconectado!", Color(0.3, 0.95, 0.4), 2.5)

func _on_reconnection_failed() -> void:
	_flash_migration_message("Desconectado", Color(0.95, 0.3, 0.3), 3.0)
	MultiplayerManager.disconnect_from_game()
	var timer = hud.get_tree().create_timer(3.0)
	await timer.timeout
	hud.get_tree().paused = false
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")
