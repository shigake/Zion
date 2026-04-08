extends Control

## Tela de lobby multiplayer completa: seleção de personagem, relíquia e fenda in-lobby,
## descoberta LAN, chat, indicadores de ping, badge de host, reconexão visual, senha.
## PRD: docs/prd_multiplayer_menu.md (10 tasks)

# ---- Constants ----
var STAGE_ORDER: Array = GameConstants.ENABLED_STAGES
const STAGE_NAMES: Dictionary = {
	"cemetery": "Cemitério", "forest": "Floresta", "farm": "Fazenda",
	"tokyo": "Tóquio", "volcano": "Vulcão", "ocean": "Oceano",
	"arena": "Arena", "space": "Espaço", "castle": "Castelo", "candy": "Candy"
}
const STAGE_DIFFICULTY: Dictionary = {
	"cemetery": 1, "forest": 2, "farm": 2, "tokyo": 3, "volcano": 3,
	"ocean": 4, "arena": 4, "space": 5, "castle": 5, "candy": 3
}
const MAX_CHAT_MESSAGES := 8
const MAX_CHAT_LENGTH := 140
const FLOOD_MAX_MSGS := 3
const FLOOD_WINDOW := 5.0

# ---- State ----
var _is_local_ready: bool = false
var _in_lobby: bool = false  # true after host/join succeeded
var _chat_messages: Array = []  # [{name, text, color}]
var _flood_times: Array = []  # timestamps of local messages for anti-flood
var _ping_update_timer: float = 0.0
var _password_hash: String = ""  # SHA-256 of room password (empty = no password)

# ---- Pre-lobby UI (created in code) ----
var _pre_lobby_panel: VBoxContainer
var _host_btn: Button
var _join_btn: Button
var _ip_input: LineEdit
var _password_input: LineEdit
var _status_label: Label
var _back_btn: Button
var _lan_list: VBoxContainer
var _recent_list: VBoxContainer

# ---- Lobby UI (created in code) ----
var _lobby_panel: VBoxContainer
var _title_label: Label
var _columns: HBoxContainer
# Left column
var _char_grid: GridContainer
var _char_preview_label: Label
var _relic_option: OptionButton
# Center column
var _player_list: VBoxContainer
var _chat_display: RichTextLabel
var _chat_input: LineEdit
# Right column
var _stage_grid: GridContainer
var _stage_name_label: Label
var _stage_diff_label: Label
# Bottom
var _ready_btn: Button
var _start_btn: Button
var _lobby_back_btn: Button
# Reconnection overlay
var _reconnect_overlay: PanelContainer
var _reconnect_label: Label

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioManager.play_music("lobby")
	GamepadUI.notify_menu_opened()

	_build_ui()
	_show_pre_lobby()

	# Connect multiplayer signals
	MultiplayerManager.player_connected.connect(_on_player_changed)
	MultiplayerManager.player_disconnected.connect(_on_player_changed)
	MultiplayerManager.server_created.connect(_on_server_created)
	MultiplayerManager.connection_succeeded.connect(_on_connected)
	MultiplayerManager.connection_failed.connect(_on_failed)
	MultiplayerManager.lobby_state_updated.connect(_on_lobby_state_updated)
	MultiplayerManager.reconnection_attempted.connect(_on_reconnect_attempt)
	MultiplayerManager.reconnection_succeeded.connect(_on_reconnect_success)
	MultiplayerManager.reconnection_failed.connect(_on_reconnect_failed)
	if MultiplayerManager.has_signal("chat_message_received"):
		MultiplayerManager.chat_message_received.connect(_on_chat_received)
	if MultiplayerManager.has_signal("stage_selection_updated"):
		MultiplayerManager.stage_selection_updated.connect(_on_stage_updated)
	if MultiplayerManager.has_signal("lan_server_found"):
		MultiplayerManager.lan_server_found.connect(_on_lan_server_found)
	if MultiplayerManager.has_signal("password_required"):
		MultiplayerManager.password_required.connect(_on_password_required)

func _process(delta: float) -> void:
	if not _in_lobby:
		return
	# Update ping display every 2s
	_ping_update_timer += delta
	if _ping_update_timer >= 2.0:
		_ping_update_timer = 0.0
		_update_player_list()

# ===========================================================
# UI CONSTRUCTION
# ===========================================================

func _build_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.05, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ---- Pre-Lobby Panel ----
	_pre_lobby_panel = VBoxContainer.new()
	_pre_lobby_panel.set_anchors_preset(Control.PRESET_CENTER)
	_pre_lobby_panel.offset_left = -300
	_pre_lobby_panel.offset_top = -280
	_pre_lobby_panel.offset_right = 300
	_pre_lobby_panel.offset_bottom = 280
	_pre_lobby_panel.set("theme_override_constants/separation", 10)
	add_child(_pre_lobby_panel)

	var pre_title = Label.new()
	pre_title.text = "MULTIPLAYER"
	pre_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pre_lobby_panel.add_child(pre_title)

	# Host / Join buttons
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.set("theme_override_constants/separation", 12)
	_pre_lobby_panel.add_child(btn_row)

	_host_btn = Button.new()
	_host_btn.text = "Criar sala"
	_host_btn.custom_minimum_size = Vector2(150, 40)
	_host_btn.focus_mode = Control.FOCUS_ALL
	_host_btn.pressed.connect(_on_host)
	btn_row.add_child(_host_btn)

	_join_btn = Button.new()
	_join_btn.text = "Entrar"
	_join_btn.custom_minimum_size = Vector2(150, 40)
	_join_btn.focus_mode = Control.FOCUS_ALL
	_join_btn.pressed.connect(_on_join)
	btn_row.add_child(_join_btn)

	# IP input
	_ip_input = LineEdit.new()
	_ip_input.placeholder_text = "IP do host (ex: 192.168.1.10)"
	_ip_input.focus_mode = Control.FOCUS_ALL
	_pre_lobby_panel.add_child(_ip_input)

	# Password input
	_password_input = LineEdit.new()
	_password_input.placeholder_text = "Senha da sala (opcional)"
	_password_input.secret = true
	_password_input.focus_mode = Control.FOCUS_ALL
	_pre_lobby_panel.add_child(_password_input)

	# Status
	_status_label = Label.new()
	_status_label.text = "Escolha criar ou entrar em uma sala"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pre_lobby_panel.add_child(_status_label)

	# Separator - LAN servers
	var lan_title = Label.new()
	lan_title.text = "Servidores LAN"
	lan_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lan_title.modulate = Color(0.7, 0.8, 1.0)
	_pre_lobby_panel.add_child(lan_title)

	_lan_list = VBoxContainer.new()
	_lan_list.custom_minimum_size = Vector2(0, 80)
	_pre_lobby_panel.add_child(_lan_list)

	var scan_btn = Button.new()
	scan_btn.text = "Atualizar"
	scan_btn.custom_minimum_size = Vector2(0, 30)
	scan_btn.focus_mode = Control.FOCUS_ALL
	scan_btn.pressed.connect(_refresh_lan)
	_pre_lobby_panel.add_child(scan_btn)

	# Recent servers
	var recent_title = Label.new()
	recent_title.text = "Servidores recentes"
	recent_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recent_title.modulate = Color(0.7, 0.8, 1.0)
	_pre_lobby_panel.add_child(recent_title)

	_recent_list = VBoxContainer.new()
	_recent_list.custom_minimum_size = Vector2(0, 60)
	_pre_lobby_panel.add_child(_recent_list)

	# Back
	_back_btn = Button.new()
	_back_btn.text = "Voltar"
	_back_btn.custom_minimum_size = Vector2(0, 35)
	_back_btn.focus_mode = Control.FOCUS_ALL
	_back_btn.pressed.connect(_on_back)
	_pre_lobby_panel.add_child(_back_btn)

	# ---- Lobby Panel (3 columns) ----
	_lobby_panel = VBoxContainer.new()
	_lobby_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lobby_panel.anchor_left = 0.02
	_lobby_panel.anchor_top = 0.02
	_lobby_panel.anchor_right = 0.98
	_lobby_panel.anchor_bottom = 0.98
	_lobby_panel.set("theme_override_constants/separation", 8)
	_lobby_panel.visible = false
	add_child(_lobby_panel)

	_title_label = Label.new()
	_title_label.text = "MULTIPLAYER — Lobby"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lobby_panel.add_child(_title_label)

	# 3 columns
	_columns = HBoxContainer.new()
	_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_columns.set("theme_override_constants/separation", 12)
	_lobby_panel.add_child(_columns)

	_build_left_column()
	_build_center_column()
	_build_right_column()
	_build_bottom_bar()
	_build_reconnect_overlay()

func _build_left_column() -> void:
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.3
	left.set("theme_override_constants/separation", 6)
	_columns.add_child(left)

	var char_title = Label.new()
	char_title.text = "Fragmentado"
	char_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	char_title.modulate = Color(0.9, 0.8, 1.0)
	left.add_child(char_title)

	# Scrollable character grid
	var char_scroll = ScrollContainer.new()
	char_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	char_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(char_scroll)

	_char_grid = GridContainer.new()
	_char_grid.columns = 5
	_char_grid.set("theme_override_constants/h_separation", 4)
	_char_grid.set("theme_override_constants/v_separation", 4)
	char_scroll.add_child(_char_grid)

	_char_preview_label = Label.new()
	_char_preview_label.text = "..."
	_char_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_char_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	left.add_child(_char_preview_label)

	# Relic selector
	var relic_title = Label.new()
	relic_title.text = "Relíquia"
	relic_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_title.modulate = Color(0.9, 0.8, 1.0)
	left.add_child(relic_title)

	_relic_option = OptionButton.new()
	_relic_option.focus_mode = Control.FOCUS_ALL
	_relic_option.item_selected.connect(_on_relic_selected)
	left.add_child(_relic_option)

func _build_center_column() -> void:
	var center = VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_stretch_ratio = 0.4
	center.set("theme_override_constants/separation", 6)
	_columns.add_child(center)

	var pl_title = Label.new()
	pl_title.text = "Jogadores"
	pl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl_title.modulate = Color(0.9, 0.8, 1.0)
	center.add_child(pl_title)

	_player_list = VBoxContainer.new()
	_player_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_player_list.custom_minimum_size = Vector2(0, 100)
	center.add_child(_player_list)

	# Chat
	var chat_title = Label.new()
	chat_title.text = "Chat"
	chat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chat_title.modulate = Color(0.7, 0.8, 1.0)
	center.add_child(chat_title)

	_chat_display = RichTextLabel.new()
	_chat_display.bbcode_enabled = true
	_chat_display.scroll_following = true
	_chat_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_display.custom_minimum_size = Vector2(0, 80)
	center.add_child(_chat_display)

	var chat_row = HBoxContainer.new()
	chat_row.set("theme_override_constants/separation", 4)
	center.add_child(chat_row)

	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Mensagem..."
	_chat_input.max_length = MAX_CHAT_LENGTH
	_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_input.focus_mode = Control.FOCUS_ALL
	_chat_input.text_submitted.connect(_on_chat_submit)
	chat_row.add_child(_chat_input)

	var send_btn = Button.new()
	send_btn.text = "Enviar"
	send_btn.custom_minimum_size = Vector2(70, 0)
	send_btn.focus_mode = Control.FOCUS_ALL
	send_btn.pressed.connect(func(): _on_chat_submit(_chat_input.text))
	chat_row.add_child(send_btn)

func _build_right_column() -> void:
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.3
	right.set("theme_override_constants/separation", 6)
	_columns.add_child(right)

	var stage_title = Label.new()
	stage_title.text = "Fenda"
	stage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_title.modulate = Color(0.9, 0.8, 1.0)
	right.add_child(stage_title)

	var stage_scroll = ScrollContainer.new()
	stage_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(stage_scroll)

	_stage_grid = GridContainer.new()
	_stage_grid.columns = 2
	_stage_grid.set("theme_override_constants/h_separation", 4)
	_stage_grid.set("theme_override_constants/v_separation", 4)
	stage_scroll.add_child(_stage_grid)

	_stage_name_label = Label.new()
	_stage_name_label.text = "..."
	_stage_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(_stage_name_label)

	_stage_diff_label = Label.new()
	_stage_diff_label.text = ""
	_stage_diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_diff_label.modulate = Color(0.95, 0.85, 0.2)
	right.add_child(_stage_diff_label)

func _build_bottom_bar() -> void:
	var bottom = HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.set("theme_override_constants/separation", 12)
	_lobby_panel.add_child(bottom)

	_ready_btn = Button.new()
	_ready_btn.text = "Pronto"
	_ready_btn.custom_minimum_size = Vector2(120, 40)
	_ready_btn.focus_mode = Control.FOCUS_ALL
	_ready_btn.pressed.connect(_on_ready_toggled)
	bottom.add_child(_ready_btn)

	_start_btn = Button.new()
	_start_btn.text = "Aguardando jogadores..."
	_start_btn.custom_minimum_size = Vector2(180, 45)
	_start_btn.focus_mode = Control.FOCUS_ALL
	_start_btn.pressed.connect(_on_start)
	_start_btn.visible = false
	bottom.add_child(_start_btn)

	_lobby_back_btn = Button.new()
	_lobby_back_btn.text = "Sair"
	_lobby_back_btn.custom_minimum_size = Vector2(80, 35)
	_lobby_back_btn.focus_mode = Control.FOCUS_ALL
	_lobby_back_btn.pressed.connect(_on_back)
	bottom.add_child(_lobby_back_btn)

func _build_reconnect_overlay() -> void:
	_reconnect_overlay = PanelContainer.new()
	_reconnect_overlay.set_anchors_preset(Control.PRESET_CENTER)
	_reconnect_overlay.offset_left = -200
	_reconnect_overlay.offset_top = -40
	_reconnect_overlay.offset_right = 200
	_reconnect_overlay.offset_bottom = 40
	_reconnect_overlay.visible = false
	# Semi-transparent dark background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.85)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_reconnect_overlay.add_theme_stylebox_override("panel", style)
	add_child(_reconnect_overlay)

	_reconnect_label = Label.new()
	_reconnect_label.text = "Reconectando..."
	_reconnect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reconnect_overlay.add_child(_reconnect_label)

# ===========================================================
# PRE-LOBBY: LAN + RECENTES + HOST/JOIN
# ===========================================================

func _show_pre_lobby() -> void:
	_pre_lobby_panel.visible = true
	_lobby_panel.visible = false
	_in_lobby = false
	_populate_recent_servers()
	_refresh_lan()
	# Bug 4 fix — grab focus on host button for gamepad
	if GamepadUI.is_gamepad_mode:
		_host_btn.call_deferred("grab_focus")

func _show_lobby() -> void:
	_pre_lobby_panel.visible = false
	_lobby_panel.visible = true
	_in_lobby = true
	_populate_char_grid()
	_populate_relic_dropdown()
	_populate_stage_grid()
	_update_player_list()
	_update_start_button()
	# Bug 6 fix — grab focus on ready button for gamepad
	if GamepadUI.is_gamepad_mode:
		_ready_btn.call_deferred("grab_focus")

func _refresh_lan() -> void:
	for child in _lan_list.get_children():
		child.queue_free()
	if MultiplayerManager.has_method("start_lan_discovery"):
		MultiplayerManager.start_lan_discovery()
	var hint = Label.new()
	hint.text = "Procurando servidores..."
	hint.modulate = Color(0.6, 0.6, 0.6)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lan_list.add_child(hint)

func _on_lan_server_found(server_info: Dictionary) -> void:
	# Remove "procurando" hint
	for child in _lan_list.get_children():
		if child is Label and "Procurando" in child.text:
			child.queue_free()

	var row = HBoxContainer.new()
	row.set("theme_override_constants/separation", 8)

	var info_label = Label.new()
	var name = server_info.get("host_name", "Sala")
	var players = server_info.get("players", 1)
	var max_p = server_info.get("max_players", 4)
	var stage = STAGE_NAMES.get(server_info.get("stage", ""), "?")
	info_label.text = "%s (%d/%d) — %s" % [name, players, max_p, stage]
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_label)

	var connect_btn = Button.new()
	connect_btn.text = "Conectar"
	connect_btn.custom_minimum_size = Vector2(80, 28)
	var ip = server_info.get("ip", "127.0.0.1")
	var port = server_info.get("port", MultiplayerManager.DEFAULT_PORT)
	connect_btn.pressed.connect(func(): _join_server(ip, port))
	row.add_child(connect_btn)

	_lan_list.add_child(row)

func _populate_recent_servers() -> void:
	for child in _recent_list.get_children():
		child.queue_free()

	var recents = SaveManager.data.get("recent_servers", [])
	if recents.is_empty():
		var hint = Label.new()
		hint.text = "Nenhum servidor recente"
		hint.modulate = Color(0.5, 0.5, 0.5)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_recent_list.add_child(hint)
		return

	for entry in recents:
		var row = HBoxContainer.new()
		row.set("theme_override_constants/separation", 8)
		var lbl = Label.new()
		lbl.text = "%s:%d — %s" % [entry.get("ip", "?"), entry.get("port", 7777), entry.get("host_name", "?")]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var btn = Button.new()
		btn.text = "Conectar"
		btn.custom_minimum_size = Vector2(80, 28)
		var ip = entry.get("ip", "127.0.0.1")
		var port = entry.get("port", MultiplayerManager.DEFAULT_PORT)
		btn.pressed.connect(func(): _join_server(ip, port))
		row.add_child(btn)
		_recent_list.add_child(row)

# ===========================================================
# HOST / JOIN
# ===========================================================

func _on_host() -> void:
	# Set password if provided
	var pw = _password_input.text.strip_edges()
	if pw != "":
		_password_hash = pw.sha256_text()
		if MultiplayerManager.has_method("set_room_password"):
			MultiplayerManager.set_room_password(_password_hash)
	else:
		_password_hash = ""
		if MultiplayerManager.has_method("set_room_password"):
			MultiplayerManager.set_room_password("")

	var error = MultiplayerManager.create_server()
	if error == OK:
		_status_label.text = "Sala criada! Aguardando jogadores..."
		# Start LAN broadcast
		if MultiplayerManager.has_method("start_lan_broadcast"):
			MultiplayerManager.start_lan_broadcast()
		_show_lobby()
		_start_btn.visible = true
		_send_local_state()
	else:
		_status_label.text = "Erro ao criar sala"

func _on_join() -> void:
	var ip = _ip_input.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	_join_server(ip, MultiplayerManager.DEFAULT_PORT)

func _join_server(ip: String, port: int = 0) -> void:
	if port == 0:
		port = MultiplayerManager.DEFAULT_PORT

	# Save password for handshake
	var pw = _password_input.text.strip_edges()
	if pw != "":
		_password_hash = pw.sha256_text()
		if MultiplayerManager.has_method("set_client_password"):
			MultiplayerManager.set_client_password(_password_hash)
	else:
		_password_hash = ""

	var error = MultiplayerManager.join_server(ip, port)
	if error == OK:
		_status_label.text = "Conectando a %s:%d..." % [ip, port]
		_host_btn.disabled = true
		_join_btn.disabled = true
	else:
		_status_label.text = "Erro de conexão"

func _on_server_created() -> void:
	_start_btn.visible = true
	_update_player_list()

func _on_connected() -> void:
	# Save to recent servers
	_save_recent_server(MultiplayerManager._last_address, MultiplayerManager._last_port, "Sala")
	_show_lobby()
	_send_local_state()
	_update_player_list()

func _on_failed() -> void:
	_status_label.text = "Conexão falhou"
	_host_btn.disabled = false
	_join_btn.disabled = false

func _on_password_required() -> void:
	_status_label.text = "Sala protegida — digite a senha"

func _on_player_changed(_id: int) -> void:
	_update_player_list()
	_update_start_button()

func _on_lobby_state_updated() -> void:
	_update_player_list()
	_update_start_button()
	_update_stage_display()

# ===========================================================
# CHARACTER GRID (Task 2)
# ===========================================================

func _populate_char_grid() -> void:
	for child in _char_grid.get_children():
		child.queue_free()

	var all_chars = CharacterDB.get_all_character_ids()
	for char_id in all_chars:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(48, 48)
		btn.focus_mode = Control.FOCUS_ALL
		btn.tooltip_text = CharacterDB.get_character(char_id).get("name", char_id)

		# Try to load sprite as icon
		var sprite_path = "res://assets/sprites/characters/%s.png" % char_id
		if ResourceLoader.exists(sprite_path):
			btn.icon = load(sprite_path)
			btn.expand_icon = true

		var unlocked = SaveManager.is_character_unlocked(char_id)
		if not unlocked:
			btn.modulate = Color(0.3, 0.3, 0.3)
			btn.disabled = true

		# Check if another player picked this one
		var taken_by_other = false
		for pid in MultiplayerManager.lobby_state:
			if pid != MultiplayerManager.local_player_id:
				if MultiplayerManager.lobby_state[pid].get("char_id", "") == char_id:
					taken_by_other = true
					break

		if taken_by_other:
			btn.modulate = Color(1.0, 0.5, 0.5)  # Red tint warning

		# Highlight current selection
		if char_id == GameManager.selected_character:
			btn.modulate = Color(1.2, 1.2, 0.6)

		btn.pressed.connect(_on_char_selected.bind(char_id))
		_char_grid.add_child(btn)

	_update_char_preview()

func _on_char_selected(char_id: String) -> void:
	GameManager.selected_character = char_id
	AudioManager.play_sfx("menu_click")
	_send_local_state()
	_populate_char_grid()  # Refresh highlights

func _update_char_preview() -> void:
	var char_data = CharacterDB.get_character(GameManager.selected_character)
	if char_data.is_empty():
		_char_preview_label.text = "???"
		return
	var name = char_data.get("name", "???")
	var passive = char_data.get("passive", "")
	_char_preview_label.text = "%s\n%s" % [name, passive]

# ===========================================================
# RELIC DROPDOWN (Task 3)
# ===========================================================

func _populate_relic_dropdown() -> void:
	_relic_option.clear()
	_relic_option.add_item("Nenhuma", 0)
	var all_relics = RelicDB.get_all_relic_ids()
	var idx = 1
	for relic_id in all_relics:
		var relic = RelicDB.get_relic(relic_id)
		var relic_name = relic.get("name", relic_id)
		_relic_option.add_item(relic_name, idx)
		_relic_option.set_item_metadata(idx, relic_id)
		idx += 1

	# Select current relic
	if GameManager.selected_relic != "":
		for i in range(_relic_option.item_count):
			if _relic_option.get_item_metadata(i) == GameManager.selected_relic:
				_relic_option.select(i)
				break

func _on_relic_selected(index: int) -> void:
	if index == 0:
		GameManager.selected_relic = ""
	else:
		var relic_id = _relic_option.get_item_metadata(index)
		if relic_id:
			GameManager.selected_relic = relic_id
	AudioManager.play_sfx("menu_click")
	_send_local_state()

# ===========================================================
# STAGE GRID — HOST ONLY (Task 4)
# ===========================================================

func _populate_stage_grid() -> void:
	for child in _stage_grid.get_children():
		child.queue_free()

	var is_host = MultiplayerManager.is_host()
	for stage_id in STAGE_ORDER:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 40)
		btn.focus_mode = Control.FOCUS_ALL
		btn.text = STAGE_NAMES.get(stage_id, stage_id)

		var unlocked = SaveManager.is_stage_unlocked(stage_id)
		if not unlocked:
			btn.modulate = Color(0.3, 0.3, 0.3)
			btn.disabled = true
		elif not is_host:
			btn.disabled = true
			btn.modulate = Color(0.7, 0.7, 0.7)

		# Highlight selected
		var current_stage = MultiplayerManager.lobby_stage if MultiplayerManager.get("lobby_stage") else GameManager.selected_stage
		if stage_id == current_stage:
			btn.modulate = Color(1.2, 1.2, 0.6)

		btn.pressed.connect(_on_stage_selected.bind(stage_id))
		_stage_grid.add_child(btn)

	_update_stage_display()

func _on_stage_selected(stage_id: String) -> void:
	if not MultiplayerManager.is_host():
		return
	GameManager.selected_stage = stage_id
	if MultiplayerManager.has_method("broadcast_stage_selection"):
		MultiplayerManager.broadcast_stage_selection(stage_id)
	AudioManager.play_sfx("menu_click")
	_populate_stage_grid()

func _on_stage_updated() -> void:
	_populate_stage_grid()

func _update_stage_display() -> void:
	var current = MultiplayerManager.lobby_stage if MultiplayerManager.get("lobby_stage") else GameManager.selected_stage
	_stage_name_label.text = STAGE_NAMES.get(current, current)
	var diff = STAGE_DIFFICULTY.get(current, 1)
	var stars = ""
	for i in range(5):
		stars += "★" if i < diff else "☆"
	_stage_diff_label.text = "Dificuldade: %s" % stars
	if not MultiplayerManager.is_host():
		_stage_name_label.text += " (host escolhe)"

# ===========================================================
# PLAYER LIST WITH PING + HOST BADGE (Task 7)
# ===========================================================

func _update_player_list() -> void:
	for child in _player_list.get_children():
		child.queue_free()

	var colors = MultiplayerManager.get_player_colors()
	for pid in MultiplayerManager.players:
		var info = MultiplayerManager.players[pid]
		var row = HBoxContainer.new()
		row.set("theme_override_constants/separation", 6)

		# Host badge (crown)
		var is_host_peer = (pid == 1) or (pid == MultiplayerManager.current_host_id)
		if is_host_peer:
			var crown = Label.new()
			crown.text = "♛"
			crown.modulate = Color(1.0, 0.85, 0.2)
			crown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(crown)

		# Character sprite
		var char_id = info["character"]
		var lobby_info = MultiplayerManager.lobby_state.get(pid, {})
		if not lobby_info.is_empty():
			char_id = lobby_info.get("char_id", char_id)

		var sprite_path = "res://assets/sprites/characters/%s.png" % char_id
		if ResourceLoader.exists(sprite_path):
			var tex_rect = TextureRect.new()
			tex_rect.texture = load(sprite_path)
			tex_rect.custom_minimum_size = Vector2(36, 36)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			row.add_child(tex_rect)

		# Player name + character name
		var label = Label.new()
		var char_name = CharacterDB.get_character(char_id).get("name", "???")
		var is_local = " (você)" if pid == MultiplayerManager.local_player_id else ""
		var host_txt = " (Host)" if is_host_peer else ""
		label.text = "%s%s%s" % [char_name, host_txt, is_local]
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if pid in colors:
			label.modulate = colors[pid]
		row.add_child(label)

		# Relic indicator
		var relic_id = lobby_info.get("relic_id", "")
		if relic_id != "":
			var relic_data = RelicDB.get_relic(relic_id)
			var relic_lbl = Label.new()
			relic_lbl.text = relic_data.get("name", relic_id)
			relic_lbl.modulate = Color(0.7, 0.6, 1.0)
			relic_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(relic_lbl)

		# Ready status
		var ready_label = Label.new()
		ready_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if not lobby_info.is_empty() and lobby_info.get("is_ready", false):
			ready_label.text = "✓"
			ready_label.modulate = Color(0.2, 0.9, 0.3)
		else:
			ready_label.text = "..."
			ready_label.modulate = Color(0.95, 0.85, 0.2)
		row.add_child(ready_label)

		# Ping indicator
		var ping_label = Label.new()
		ping_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if is_host_peer:
			ping_label.text = "0ms"
			ping_label.modulate = Color(0.2, 0.9, 0.3)
		elif pid == MultiplayerManager.local_player_id and not MultiplayerManager.is_host():
			var ping = MultiplayerManager.get_ping()
			ping_label.text = "%dms" % ping
			ping_label.modulate = MultiplayerManager.get_ping_color()
		else:
			ping_label.text = ""
		row.add_child(ping_label)

		_player_list.add_child(row)

	# Player count in title
	_title_label.text = "MULTIPLAYER — %d/%d jogadores" % [MultiplayerManager.get_player_count(), MultiplayerManager.MAX_PLAYERS]

# ===========================================================
# READY / START
# ===========================================================

func _on_ready_toggled() -> void:
	_is_local_ready = not _is_local_ready
	AudioManager.play_sfx("menu_click")
	_ready_btn.text = "Cancelar" if _is_local_ready else "Pronto"
	_send_local_state()

func _send_local_state() -> void:
	var char_id = GameManager.selected_character
	var relic_id = GameManager.selected_relic
	MultiplayerManager.set_local_player_state(char_id, relic_id, _is_local_ready)

func _update_start_button() -> void:
	if not MultiplayerManager.is_host():
		_start_btn.visible = false
		return
	_start_btn.visible = true
	var all_ready = MultiplayerManager.all_players_ready()
	_start_btn.disabled = not all_ready
	_start_btn.text = "Iniciar partida" if all_ready else "Aguardando jogadores..."

func _on_start() -> void:
	if not MultiplayerManager.is_host():
		return
	if not MultiplayerManager.all_players_ready():
		return
	var stage = MultiplayerManager.lobby_stage if MultiplayerManager.get("lobby_stage") else GameManager.selected_stage
	var stage_path = "res://scenes/stages/stage_%s.tscn" % stage
	_load_game_scene.rpc(stage_path)
	_load_game_scene(stage_path)

@rpc("authority", "reliable")
func _load_game_scene(scene_path: String) -> void:
	LoadingScreen.load_stage(scene_path)

# ===========================================================
# CHAT (Task 8)
# ===========================================================

func _on_chat_submit(text: String) -> void:
	text = text.strip_edges()
	if text == "":
		return
	_chat_input.text = ""
	_chat_input.call_deferred("grab_focus")

	# Anti-flood
	var now = Time.get_ticks_msec() / 1000.0
	_flood_times = _flood_times.filter(func(t): return now - t < FLOOD_WINDOW)
	if _flood_times.size() >= FLOOD_MAX_MSGS:
		_add_chat_message("Sistema", "Aguarde antes de enviar mais mensagens", Color(0.9, 0.4, 0.3))
		return
	_flood_times.append(now)

	# Send via MultiplayerManager
	if MultiplayerManager.has_method("send_chat_message"):
		MultiplayerManager.send_chat_message(text)
	else:
		# Fallback: local-only display
		var name = SaveManager.data.get("player_name", "Jogador")
		_add_chat_message(name, text, Color(0.8, 0.8, 0.8))

func _on_chat_received(sender_name: String, text: String, color: Color) -> void:
	_add_chat_message(sender_name, text, color)

func _add_chat_message(name: String, text: String, color: Color) -> void:
	var hex = color.to_html(false)
	_chat_display.append_text("[color=#%s]%s:[/color] %s\n" % [hex, name, text])

# ===========================================================
# RECONNECTION OVERLAY (Task 7)
# ===========================================================

func _on_reconnect_attempt(attempt: int, max_attempts: int) -> void:
	_reconnect_overlay.visible = true
	_reconnect_label.text = "Reconectando... (tentativa %d/%d)" % [attempt, max_attempts]

func _on_reconnect_success() -> void:
	_reconnect_overlay.visible = true
	_reconnect_label.text = "Reconectado!"
	# Hide after 2s
	var tw = create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(func(): _reconnect_overlay.visible = false)

func _on_reconnect_failed() -> void:
	_reconnect_overlay.visible = true
	_reconnect_label.text = "Conexão perdida. Voltando ao menu..."
	var tw = create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(_on_back)

# ===========================================================
# RECENT SERVERS (Task 6)
# ===========================================================

func _save_recent_server(ip: String, port: int, host_name: String) -> void:
	if "recent_servers" not in SaveManager.data:
		SaveManager.data["recent_servers"] = []
	var recents: Array = SaveManager.data["recent_servers"]

	# Remove duplicate
	recents = recents.filter(func(e): return e.get("ip", "") != ip or e.get("port", 0) != port)

	recents.push_front({
		"ip": ip,
		"port": port,
		"host_name": host_name,
		"last_connected": Time.get_date_string_from_system()
	})

	# Keep max 5
	if recents.size() > 5:
		recents.resize(5)

	SaveManager.data["recent_servers"] = recents
	SaveManager.save_game()

# ===========================================================
# NAVIGATION
# ===========================================================

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_viewport():
			get_viewport().set_input_as_handled()
		_on_back()

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	_is_local_ready = false
	if MultiplayerManager.has_method("stop_lan_broadcast"):
		MultiplayerManager.stop_lan_broadcast()
	if MultiplayerManager.has_method("stop_lan_discovery"):
		MultiplayerManager.stop_lan_discovery()
	MultiplayerManager.disconnect_from_game()
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")
