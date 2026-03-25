extends Control

## Tela de lobby multiplayer: criar sala, entrar, ver jogadores.

@onready var host_btn: Button = $VBox/Buttons/HostButton
@onready var join_btn: Button = $VBox/Buttons/JoinButton
@onready var ip_input: LineEdit = $VBox/IPInput
@onready var status_label: Label = $VBox/StatusLabel
@onready var player_list: VBoxContainer = $VBox/PlayerList
@onready var start_btn: Button = $VBox/StartButton
@onready var back_btn: Button = $VBox/BackButton

func _ready() -> void:
	host_btn.pressed.connect(_on_host)
	join_btn.pressed.connect(_on_join)
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)
	start_btn.visible = false

	MultiplayerManager.player_connected.connect(_on_player_changed)
	MultiplayerManager.player_disconnected.connect(_on_player_changed)
	MultiplayerManager.server_created.connect(_on_server_created)
	MultiplayerManager.connection_succeeded.connect(_on_connected)
	MultiplayerManager.connection_failed.connect(_on_failed)

func _on_host() -> void:
	var error = MultiplayerManager.create_server()
	if error == OK:
		status_label.text = "Servidor criado! Aguardando jogadores..."
		host_btn.disabled = true
		join_btn.disabled = true
	else:
		status_label.text = "Erro ao criar servidor!"

func _on_join() -> void:
	var ip = ip_input.text if ip_input.text != "" else "127.0.0.1"
	var error = MultiplayerManager.join_server(ip)
	if error == OK:
		status_label.text = "Conectando a %s..." % ip
		host_btn.disabled = true
		join_btn.disabled = true
	else:
		status_label.text = "Erro ao conectar!"

func _on_server_created() -> void:
	start_btn.visible = true
	_update_player_list()

func _on_connected() -> void:
	status_label.text = "Conectado! Aguardando host iniciar..."
	_update_player_list()

func _on_failed() -> void:
	status_label.text = "Falha na conexao!"
	host_btn.disabled = false
	join_btn.disabled = false

func _on_player_changed(_id: int) -> void:
	_update_player_list()

func _update_player_list() -> void:
	for child in player_list.get_children():
		child.queue_free()

	var colors = MultiplayerManager.get_player_colors()
	for pid in MultiplayerManager.players:
		var info = MultiplayerManager.players[pid]
		var label = Label.new()
		var char_name = CharacterDB.get_character(info["character"]).get("name", "???")
		var is_local = "(Voce)" if pid == MultiplayerManager.local_player_id else ""
		label.text = "Player %d — %s %s" % [pid, char_name, is_local]
		if pid in colors:
			label.modulate = colors[pid]
		player_list.add_child(label)

	status_label.text = "%d/%d jogadores" % [MultiplayerManager.get_player_count(), MultiplayerManager.MAX_PLAYERS]

func _on_start() -> void:
	if not MultiplayerManager.is_host():
		return
	# Carrega a fase selecionada
	var stage_path = "res://scenes/stages/stage_%s.tscn" % GameManager.selected_stage
	get_tree().change_scene_to_file(stage_path)

func _on_back() -> void:
	MultiplayerManager.disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
