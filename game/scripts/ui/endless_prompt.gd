extends CanvasLayer

## Painel de escolha exibido apos a morte do Sentinela.
## Oferece ao jogador a opcao de encerrar a run ou entrar na Fenda Infinita.
## Pausa o jogo enquanto visivel.

var _panel: PanelContainer
var _btn_end: Button
var _btn_endless: Button


func _ready() -> void:
	layer = 100
	visible = false
	_build_ui()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func show_prompt() -> void:
	## Exibe o painel e pausa o jogo.
	visible = true
	GameManager.paused = true
	get_tree().paused = true
	_btn_endless.grab_focus()


func hide_prompt() -> void:
	## Esconde o painel e despausa o jogo.
	visible = false
	GameManager.paused = false
	get_tree().paused = false


# ---------------------------------------------------------------------------
# UI Construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Fundo escuro semi-transparente cobrindo tela inteira
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Container central
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	# Painel principal
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 310)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.04, 0.1, 0.95)
	panel_style.border_color = Color(0.85, 0.7, 0.2, 1.0)  # Ouro
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(_panel)

	# Layout vertical
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(vbox)

	# Titulo
	var title := Label.new()
	title.text = "Sentinela libertado!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4, 1.0))
	vbox.add_child(title)

	# Separador
	vbox.add_child(HSeparator.new())

	# Texto narrativo
	var narrative := Label.new()
	narrative.text = "A fenda se estabiliza...\nmas a corrupcao ainda pulsa nas profundezas.\nVoce pode partir em seguranca,\nou enfrentar o que resta."
	narrative.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	narrative.add_theme_font_size_override("font_size", 14)
	narrative.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 1.0))
	narrative.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(narrative)

	# Aviso de dificuldade
	var warning := Label.new()
	warning.text = "A dificuldade nao para de subir"
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.add_theme_font_size_override("font_size", 12)
	warning.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 0.9))
	vbox.add_child(warning)

	# Espacador
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8
	vbox.add_child(spacer)

	# Botoes
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	_btn_end = _create_button("Encerrar run", Color(0.5, 0.5, 0.55, 1.0))
	_btn_end.pressed.connect(_on_end_run)
	btn_row.add_child(_btn_end)

	_btn_endless = _create_button("Fenda infinita", Color(0.85, 0.7, 0.2, 1.0))
	_btn_endless.pressed.connect(_on_fenda_infinita)
	btn_row.add_child(_btn_endless)

	# Processar mesmo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS


func _create_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(160, 40)

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.12, 0.1, 0.18, 1.0)
	style_normal.border_color = color
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	style_normal.content_margin_left = 12
	style_normal.content_margin_right = 12
	style_normal.content_margin_top = 8
	style_normal.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover := style_normal.duplicate()
	style_hover.bg_color = Color(0.18, 0.15, 0.25, 1.0)
	btn.add_theme_stylebox_override("hover", style_hover)

	var style_pressed := style_normal.duplicate()
	style_pressed.bg_color = Color(0.08, 0.06, 0.12, 1.0)
	btn.add_theme_stylebox_override("pressed", style_pressed)

	var style_focus := style_normal.duplicate()
	style_focus.border_color = Color(1.0, 1.0, 1.0, 0.8)
	btn.add_theme_stylebox_override("focus", style_focus)

	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", color)

	return btn


# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------

func _on_end_run() -> void:
	## Encerra a run normalmente com vitoria.
	hide_prompt()
	# Fluxo normal de vitoria
	GameManager.is_victory = true
	GameManager.is_game_over = true
	GameManager.game_over.emit()


func _on_fenda_infinita() -> void:
	## Ativa o modo endless e retoma o jogo.
	hide_prompt()
	EndlessMode.activate_endless()
	LogManager.info("EndlessPrompt", "Player chose Fenda Infinita")
