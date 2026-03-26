extends CanvasLayer

## Gerencia navegacao por controle em todos os menus.
## Detecta input de gamepad vs mouse e mostra indicador visual (mao) no botao focado.

signal input_mode_changed(is_gamepad: bool)

var is_gamepad_mode: bool = false
var _hand_indicator: Control = null
var _current_focused: Control = null
var _tween: Tween = null

# Icone de mao apontando (desenhado proceduralmente)
const HAND_SIZE := Vector2(28, 28)
const HAND_OFFSET := Vector2(-32, 0)  # A esquerda do botao

func _ready() -> void:
	layer = 100  # Acima de tudo
	_create_hand_indicator()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_ui_actions()

func _register_ui_actions() -> void:
	# Garante que ui_accept tem o botao A do gamepad mapeado
	_ensure_joy_button("ui_accept", JOY_BUTTON_A)
	# Left stick para navegacao UI
	_ensure_joy_axis("ui_up", JOY_AXIS_LEFT_Y, -1.0)
	_ensure_joy_axis("ui_down", JOY_AXIS_LEFT_Y, 1.0)
	_ensure_joy_axis("ui_left", JOY_AXIS_LEFT_X, -1.0)
	_ensure_joy_axis("ui_right", JOY_AXIS_LEFT_X, 1.0)

func _ensure_joy_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	# Verifica se ja tem esse botao
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton and ev.button_index == button:
			return
	var event = InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

func _ensure_joy_axis(action: String, axis: int, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadMotion and ev.axis == axis and signf(ev.axis_value) == signf(axis_value):
			return
	var event = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)

func _create_hand_indicator() -> void:
	_hand_indicator = Control.new()
	_hand_indicator.name = "HandIndicator"
	_hand_indicator.custom_minimum_size = HAND_SIZE
	_hand_indicator.size = HAND_SIZE
	_hand_indicator.z_index = 100
	_hand_indicator.visible = false
	_hand_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_indicator.draw.connect(_draw_hand)
	add_child(_hand_indicator)

func _draw_hand() -> void:
	# Desenha uma seta/triangulo apontando para a direita (estilo mao)
	var points := PackedVector2Array()
	var cx = HAND_SIZE.x * 0.5
	var cy = HAND_SIZE.y * 0.5
	# Triangulo apontando para direita
	points.append(Vector2(4, cy - 10))
	points.append(Vector2(cx + 10, cy))
	points.append(Vector2(4, cy + 10))
	_hand_indicator.draw_colored_polygon(points, Color(1.0, 0.9, 0.2, 1.0))  # Amarelo
	# Borda
	points.append(points[0])  # Fecha o poligono
	_hand_indicator.draw_polyline(points, Color(0.8, 0.6, 0.0), 2.0)

func _input(event: InputEvent) -> void:
	var was_gamepad = is_gamepad_mode

	# Detecta input de gamepad
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadMotion:
			# Ignora deadzone
			if absf(event.axis_value) < 0.3:
				return
		if not is_gamepad_mode:
			is_gamepad_mode = true
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			_on_gamepad_activated()
			input_mode_changed.emit(true)

	# Detecta input de mouse/teclado
	elif event is InputEventMouseMotion or event is InputEventMouseButton:
		if is_gamepad_mode:
			is_gamepad_mode = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_hand_indicator.visible = false
			input_mode_changed.emit(false)

	# ui_accept (botao A) ja e tratado nativamente pelo Godot quando o botao tem foco

func _process(_delta: float) -> void:
	if not is_gamepad_mode:
		return

	var focused = _get_focused_control()
	if focused and focused != _current_focused:
		_current_focused = focused
		_move_hand_to(focused)
		AudioManager.play_sfx("menu_click")
	elif not focused:
		_hand_indicator.visible = false
		_current_focused = null
	elif focused and focused == _current_focused:
		# Atualiza posicao caso o botao tenha se movido
		_update_hand_position(focused)

func _get_focused_control() -> Control:
	var viewport = get_viewport()
	if not viewport:
		return null
	var focused = viewport.gui_get_focus_owner()
	return focused

func _move_hand_to(ctrl: Control) -> void:
	_hand_indicator.visible = true

	# Cancelar tween anterior
	if _tween and _tween.is_valid():
		_tween.kill()

	var target_pos = _get_hand_position(ctrl)
	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_tween.tween_property(_hand_indicator, "global_position", target_pos, 0.1).set_ease(Tween.EASE_OUT)

	# Bounce sutil
	_tween.tween_property(_hand_indicator, "global_position:x", target_pos.x - 3, 0.15).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_hand_indicator, "global_position:x", target_pos.x, 0.15).set_ease(Tween.EASE_IN_OUT)

func _update_hand_position(ctrl: Control) -> void:
	if not _hand_indicator.visible:
		return
	# So atualiza se nao tem tween ativo
	if _tween and _tween.is_valid() and _tween.is_running():
		return
	_hand_indicator.global_position = _get_hand_position(ctrl)

func _get_hand_position(ctrl: Control) -> Vector2:
	var ctrl_rect = ctrl.get_global_rect()
	# Posiciona a mao a esquerda do botao, centralizada verticalmente
	return Vector2(
		ctrl_rect.position.x + HAND_OFFSET.x,
		ctrl_rect.position.y + (ctrl_rect.size.y - HAND_SIZE.y) * 0.5
	)

func _on_gamepad_activated() -> void:
	# Quando ativa o modo gamepad, foca no primeiro botao visivel da tela
	var focused = _get_focused_control()
	if focused:
		return  # Ja tem algo focado

	# Procura botoes visiveis na cena atual
	_focus_first_button()

func _focus_first_button() -> void:
	var root = get_tree().current_scene
	if not root:
		return

	# Primeiro tenta CanvasLayers visiveis (menus em overlay como pause, level up, game over)
	var canvas_layers := _find_visible_canvas_layers(root)
	# Ordena por layer (maior layer = mais na frente)
	canvas_layers.sort_custom(func(a, b): return a.layer > b.layer)

	for cl in canvas_layers:
		var btn = _find_first_focusable_button(cl)
		if btn:
			btn.grab_focus()
			return

	# Se nao achou em CanvasLayer, procura na cena raiz
	var btn = _find_first_focusable_button(root)
	if btn:
		btn.grab_focus()

func _find_visible_canvas_layers(node: Node) -> Array[CanvasLayer]:
	var result: Array[CanvasLayer] = []
	if node is CanvasLayer:
		# Verifica se tem algum painel visivel
		var has_visible_panel := false
		for child in node.get_children():
			if child is Control and child.visible:
				has_visible_panel = true
				break
		if has_visible_panel:
			result.append(node)
	for child in node.get_children():
		result.append_array(_find_visible_canvas_layers(child))
	return result

func _find_first_focusable_button(node: Node) -> BaseButton:
	if node is BaseButton:
		var btn := node as BaseButton
		if btn.visible and not btn.disabled and btn.focus_mode != Control.FOCUS_NONE:
			# Verifica se todos os pais estao visiveis
			if _is_fully_visible(btn):
				return btn

	for child in node.get_children():
		var found = _find_first_focusable_button(child)
		if found:
			return found
	return null

func _is_fully_visible(ctrl: Control) -> bool:
	var node: Node = ctrl
	while node:
		if node is CanvasItem and not node.visible:
			return false
		node = node.get_parent()
	return true

## Chamado pelos menus quando abrem para garantir que o primeiro botao receba foco
func notify_menu_opened() -> void:
	if is_gamepad_mode:
		# Delay de 1 frame para garantir que os botoes ja existam
		await get_tree().process_frame
		_focus_first_button()

## Chamado quando um menu cria botoes dinamicamente e quer garantir foco
func focus_node(ctrl: Control) -> void:
	if is_gamepad_mode and ctrl and ctrl.visible:
		ctrl.grab_focus()
