extends Control

## Tela de lobby multiplayer: criar sala, entrar, ver jogadores.
## Task 1 & 2: Sincroniza estado do lobby (personagem, reliquia, pronto).

@onready var host_btn: Button = $VBox/Buttons/HostButton
@onready var join_btn: Button = $VBox/Buttons/JoinButton
@onready var ip_input: LineEdit = $VBox/IPInput
@onready var status_label: Label = $VBox/StatusLabel
@onready var player_list: VBoxContainer = $VBox/PlayerList
@onready var start_btn: Button = $VBox/StartButton
@onready var back_btn: Button = $VBox/BackButton
@onready var ready_btn: Button = $VBox/ReadyButton

var _is_local_ready: bool = false

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	host_btn.pressed.connect(_on_host)
	join_btn.pressed.connect(_on_join)
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)
	ready_btn.pressed.connect(_on_ready_toggled)
	start_btn.visible = false
	ready_btn.visible = false
	_update_start_button()

	GamepadUI.notify_menu_opened()
	MultiplayerManager.player_connected.connect(_on_player_changed)
	MultiplayerManager.player_disconnected.connect(_on_player_changed)
	MultiplayerManager.server_created.connect(_on_server_created)
	MultiplayerManager.connection_succeeded.connect(_on_connected)
	MultiplayerManager.connection_failed.connect(_on_failed)
	MultiplayerManager.lobby_state_updated.connect(_on_lobby_state_updated)

func _on_host() -> void:
	var error = MultiplayerManager.create_server()
	if error == OK:
		status_label.text = LocaleManager.tr_key("lobby_server_created")
		host_btn.disabled = true
		join_btn.disabled = true
		ready_btn.visible = true
		# Host sends initial state
		_send_local_state()
	else:
		status_label.text = LocaleManager.tr_key("lobby_server_error")

func _on_join() -> void:
	var ip = ip_input.text if ip_input.text != "" else "127.0.0.1"
	var error = MultiplayerManager.join_server(ip)
	if error == OK:
		status_label.text = LocaleManager.tr_key("lobby_connecting") % ip
		host_btn.disabled = true
		join_btn.disabled = true
	else:
		status_label.text = LocaleManager.tr_key("lobby_connect_error")

func _on_server_created() -> void:
	start_btn.visible = true
	_update_player_list()

func _on_connected() -> void:
	status_label.text = LocaleManager.tr_key("lobby_connected")
	ready_btn.visible = true
	# Send initial state to host
	_send_local_state()
	_update_player_list()

func _on_failed() -> void:
	status_label.text = LocaleManager.tr_key("lobby_failed")
	host_btn.disabled = false
	join_btn.disabled = false

func _on_player_changed(_id: int) -> void:
	_update_player_list()
	_update_start_button()

func _on_lobby_state_updated() -> void:
	_update_player_list()
	_update_start_button()

func _on_ready_toggled() -> void:
	_is_local_ready = not _is_local_ready
	AudioManager.play_sfx("menu_click")
	if _is_local_ready:
		ready_btn.text = "Cancelar"
	else:
		ready_btn.text = "Pronto"
	_send_local_state()

func _send_local_state() -> void:
	var char_id = GameManager.selected_character
	var relic_id = GameManager.selected_relic
	MultiplayerManager.set_local_player_state(char_id, relic_id, _is_local_ready)

func _update_player_list() -> void:
	for child in player_list.get_children():
		child.queue_free()

	var colors = MultiplayerManager.get_player_colors()
	for pid in MultiplayerManager.players:
		var info = MultiplayerManager.players[pid]
		var row = HBoxContainer.new()
		row.set("theme_override_constants/separation", 8)

		# Character sprite (128x128 scaled to 48x48)
		var char_id = info["character"]
		var lobby_info = MultiplayerManager.lobby_state.get(pid, {})
		if not lobby_info.is_empty():
			char_id = lobby_info.get("char_id", char_id)

		var sprite_path = "res://assets/sprites/characters/%s.png" % char_id
		if ResourceLoader.exists(sprite_path):
			var tex_rect = TextureRect.new()
			tex_rect.texture = load(sprite_path)
			tex_rect.custom_minimum_size = Vector2(48, 48)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			row.add_child(tex_rect)

		# Player name and character
		var label = Label.new()
		var char_name = CharacterDB.get_character(char_id).get("name", "???")
		var is_local = LocaleManager.tr_key("lobby_you") if pid == MultiplayerManager.local_player_id else ""
		label.text = "Player %d — %s %s" % [pid, char_name, is_local]
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if pid in colors:
			label.modulate = colors[pid]
		row.add_child(label)

		# Ready status
		var ready_label = Label.new()
		ready_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if not lobby_info.is_empty() and lobby_info.get("is_ready", false):
			ready_label.text = "Pronto"
			ready_label.modulate = Color(0.2, 0.9, 0.3)
		else:
			ready_label.text = "Escolhendo..."
			ready_label.modulate = Color(0.95, 0.85, 0.2)
		row.add_child(ready_label)

		player_list.add_child(row)

	status_label.text = LocaleManager.tr_key("lobby_players") % [MultiplayerManager.get_player_count(), MultiplayerManager.MAX_PLAYERS]

func _update_start_button() -> void:
	if not MultiplayerManager.is_host():
		return
	if not start_btn.visible:
		return
	var all_ready = MultiplayerManager.all_players_ready()
	start_btn.disabled = not all_ready
	if all_ready:
		start_btn.text = "Iniciar partida"
	else:
		start_btn.text = "Aguardando jogadores..."

func _on_start() -> void:
	if not MultiplayerManager.is_host():
		return
	if not MultiplayerManager.all_players_ready():
		return
	# Carrega a fase selecionada em todos os peers
	var stage_path = "res://scenes/stages/stage_%s.tscn" % GameManager.selected_stage
	_load_game_scene.rpc(stage_path)
	_load_game_scene(stage_path)

@rpc("authority", "reliable")
func _load_game_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_viewport(): get_viewport().set_input_as_handled()
		_on_back()

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	_is_local_ready = false
	MultiplayerManager.disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
