extends Node
class_name LODManagerClass

## Gerenciador de Level of Detail (LOD) para props e meshes.
## Alterna entre alta/media/baixa qualidade baseado na distancia da camera.
## Tambem faz frustum culling manual para particulas e VFX nao essenciais.
##
## Uso:
##   LODManager.register_prop(mesh_node)
##   LODManager.register_prop(mesh_node, {high = 15.0, medium = 40.0, low = 60.0})
##   LODManager.register_particle(particle_node)
##   LODManager.unregister_prop(mesh_node)

# ---- Sinais ----
signal prop_lod_changed(node: Node3D, lod_level: int)  # 0=high, 1=medium, 2=low/hidden

# ---- Constantes ----
## Distancias padrao (squared) para troca de LOD (reduzidas para melhor performance)
const DEFAULT_HIGH_DIST_SQ := 225.0   # < 15 unidades (was 20)
const DEFAULT_MEDIUM_DIST_SQ := 1600.0 # < 40 unidades (was 50)
## Acima de 40 = low/hidden

## Quantidade maxima de props processados por frame (evita spikes)
const BATCH_SIZE := 150

## Intervalo entre checagens de LOD (segundos)
const CHECK_INTERVAL := 0.5

## Intervalo entre checagens de frustum para particulas (segundos)
const FRUSTUM_CHECK_INTERVAL := 0.3

# ---- Estruturas internas ----
## Cada prop registrado guarda suas distancias e estado atual
var _props: Array[Dictionary] = []
# Formato: {node: Node3D, high_sq: float, medium_sq: float, lod: int, original_visible: bool}

## Particulas registradas para frustum culling
var _particles: Array[Dictionary] = []
# Formato: {node: Node3D, was_emitting: bool, aabb_size: Vector3}

## Controle de batching
var _prop_batch_index: int = 0
var _particle_batch_index: int = 0

## Timers
var _lod_timer: float = 0.0
var _frustum_timer: float = 0.0
var _cleanup_timer: float = 0.0

## Camera ativa (cache)
var _camera: Camera3D = null

## Multiplicador de distancia (PerfMonitor pode aumentar para reduzir qualidade)
var lod_distance_multiplier: float = 1.0


func _ready() -> void:
	LogManager.info("LOD", "LODManager inicializado — batch=%d, intervalo=%.1fs" % [BATCH_SIZE, CHECK_INTERVAL])


func _process(delta: float) -> void:
	if GameManager.paused:
		return

	_lod_timer += delta
	_frustum_timer += delta
	_cleanup_timer += delta

	# Cleanup invalid entries on its own slower cycle (every 2s instead of every LOD batch)
	if _cleanup_timer >= 2.0:
		_cleanup_timer = 0.0
		_cleanup_invalid_entries()

	# Checagem de LOD em intervalos
	if _lod_timer >= CHECK_INTERVAL:
		_lod_timer = 0.0
		_process_lod_batch()

	# Checagem de frustum culling para particulas
	if _frustum_timer >= FRUSTUM_CHECK_INTERVAL:
		_frustum_timer = 0.0
		_process_frustum_batch()


# ===========================================================================
# API Publica — Registro de Props
# ===========================================================================

func register_prop(node: Node3D, lod_distances: Dictionary = {}) -> void:
	## Registra um prop para gerenciamento de LOD.
	## lod_distances opcional: {high: float, medium: float} (distancias lineares, nao squared)
	if not is_instance_valid(node):
		return

	# Verificar se ja esta registrado
	for entry in _props:
		if entry.node == node:
			return

	var high_sq: float = DEFAULT_HIGH_DIST_SQ
	var medium_sq: float = DEFAULT_MEDIUM_DIST_SQ

	if lod_distances.has("high"):
		high_sq = lod_distances.high * lod_distances.high
	if lod_distances.has("medium"):
		medium_sq = lod_distances.medium * lod_distances.medium

	_props.append({
		"node": node,
		"high_sq": high_sq,
		"medium_sq": medium_sq,
		"lod": 0,  # comeca em high
		"original_visible": node.visible,
	})


func unregister_prop(node: Node3D) -> void:
	## Remove um prop do gerenciamento de LOD.
	for i in range(_props.size() - 1, -1, -1):
		if _props[i].node == node:
			_props.remove_at(i)
			return


func register_particle(node: Node3D, aabb_size: Vector3 = Vector3(2, 2, 2)) -> void:
	## Registra um emissor de particulas para frustum culling manual.
	## aabb_size define o tamanho da bounding box para teste de visibilidade.
	if not is_instance_valid(node):
		return

	for entry in _particles:
		if entry.node == node:
			return

	var was_emitting := false
	if node is GPUParticles3D:
		was_emitting = node.emitting
	elif node is CPUParticles3D:
		was_emitting = node.emitting

	_particles.append({
		"node": node,
		"was_emitting": was_emitting,
		"aabb_size": aabb_size,
	})


func unregister_particle(node: Node3D) -> void:
	## Remove um emissor de particulas do frustum culling.
	for i in range(_particles.size() - 1, -1, -1):
		if _particles[i].node == node:
			_particles.remove_at(i)
			return


func get_stats() -> Dictionary:
	## Retorna estatisticas do LOD para debug overlay.
	var high_count := 0
	var medium_count := 0
	var low_count := 0
	for entry in _props:
		match entry.lod:
			0: high_count += 1
			1: medium_count += 1
			2: low_count += 1

	var particles_active := 0
	var particles_culled := 0
	for entry in _particles:
		if is_instance_valid(entry.node):
			if _is_particle_emitting(entry.node):
				particles_active += 1
			else:
				particles_culled += 1

	return {
		"total_props": _props.size(),
		"high": high_count,
		"medium": medium_count,
		"low": low_count,
		"particles_total": _particles.size(),
		"particles_active": particles_active,
		"particles_culled": particles_culled,
	}


# ===========================================================================
# Processamento de LOD em batches
# ===========================================================================

func _process_lod_batch() -> void:
	## Processa um lote de props, verificando distancia da camera.
	_update_camera()
	if not _camera:
		return

	var camera_pos := _camera.global_position
	var count := 0
	var total := _props.size()

	if total == 0:
		return

	# Garante que o indice nao ultrapasse o array
	if _prop_batch_index >= total:
		_prop_batch_index = 0

	while count < BATCH_SIZE and count < total:
		var idx := _prop_batch_index
		var entry: Dictionary = _props[idx]
		var node: Node3D = entry.node

		if is_instance_valid(node) and node.is_inside_tree():
			# Distancia ao quadrado (evita sqrt)
			var dist_sq := camera_pos.distance_squared_to(node.global_position)

			# Aplica multiplicador de distancia (PerfMonitor pode reduzir)
			var adj_high_sq: float = entry.high_sq * lod_distance_multiplier
			var adj_medium_sq: float = entry.medium_sq * lod_distance_multiplier

			var new_lod := 0
			if dist_sq < adj_high_sq:
				new_lod = 0  # Alta qualidade
			elif dist_sq < adj_medium_sq:
				new_lod = 1  # Media qualidade
			else:
				new_lod = 2  # Baixa qualidade / escondido

			if new_lod != entry.lod:
				_apply_lod(node, new_lod, entry)
				entry.lod = new_lod
				prop_lod_changed.emit(node, new_lod)

		# Avanca indice circular
		_prop_batch_index = (_prop_batch_index + 1) % total
		count += 1


func _apply_lod(node: Node3D, lod: int, entry: Dictionary) -> void:
	## Aplica o nivel de LOD ao node.
	match lod:
		0:  # High — totalmente visivel, sombras ativadas
			node.visible = true
			_set_shadow_casting(node, true)
			_set_mesh_detail(node, 1.0)
		1:  # Medium — visivel, sombras desativadas, mesh simplificado
			node.visible = true
			_set_shadow_casting(node, false)
			_set_mesh_detail(node, 0.5)
		2:  # Low — escondido completamente
			node.visible = false


func _set_shadow_casting(node: Node3D, enabled: bool) -> void:
	## Ativa/desativa sombras em todas as MeshInstance3D filhas.
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for child in node.get_children():
		if child is MeshInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _set_mesh_detail(node: Node3D, detail_scale: float) -> void:
	## Controla nivel de detalhe do mesh.
	## detail_scale 1.0 = full detail, 0.5 = reduced (disable sub-meshes, reduce material).
	if node is MeshInstance3D:
		_apply_mesh_lod(node, detail_scale)
	for child in node.get_children():
		if child is MeshInstance3D:
			_apply_mesh_lod(child, detail_scale)
		# Desativa particulas filhas em LOD medio/baixo
		if child is GPUParticles3D and detail_scale < 1.0:
			child.emitting = false
		elif child is GPUParticles3D and detail_scale >= 1.0:
			if child.has_meta("lod_was_emitting"):
				child.emitting = child.get_meta("lod_was_emitting")


func _apply_mesh_lod(mesh_node: MeshInstance3D, detail_scale: float) -> void:
	## Ajusta propriedades do mesh para reduzir custo de rendering.
	if detail_scale >= 1.0:
		# Full detail: restore
		mesh_node.transparency = 0.0
		if mesh_node.has_meta("lod_original_gi"):
			mesh_node.gi_mode = mesh_node.get_meta("lod_original_gi")
	else:
		# Reduced detail: disable GI, simplify rendering
		if not mesh_node.has_meta("lod_original_gi"):
			mesh_node.set_meta("lod_original_gi", mesh_node.gi_mode)
		mesh_node.gi_mode = GeometryInstance3D.GI_MODE_DISABLED


# ===========================================================================
# Frustum Culling para Particulas
# ===========================================================================

func _process_frustum_batch() -> void:
	## Verifica se particulas estao dentro do frustum da camera.
	## Pausa emissores fora da tela, retoma quando visiveis.
	_update_camera()
	if not _camera:
		return

	var count := 0
	var total := _particles.size()

	if total == 0:
		return

	if _particle_batch_index >= total:
		_particle_batch_index = 0

	# Obtem os planos do frustum da camera
	var frustum_planes: Array[Plane] = _camera.get_frustum()

	while count < BATCH_SIZE and count < total:
		var idx := _particle_batch_index
		var entry: Dictionary = _particles[idx]
		var node: Node3D = entry.node

		if is_instance_valid(node) and node.is_inside_tree():
			# Constroi AABB ao redor da posicao da particula
			var half_size: Vector3 = entry.aabb_size * 0.5
			var aabb := AABB(node.global_position - half_size, entry.aabb_size)

			var is_visible := _aabb_in_frustum(aabb, frustum_planes)

			if is_visible:
				# Particula visivel — retoma emissao se estava emitindo antes
				if entry.was_emitting:
					_set_particle_emitting(node, true)
			else:
				# Particula fora da tela — pausa emissao
				if _is_particle_emitting(node):
					entry.was_emitting = true
					_set_particle_emitting(node, false)

		_particle_batch_index = (_particle_batch_index + 1) % total
		count += 1


func _aabb_in_frustum(aabb: AABB, planes: Array[Plane]) -> bool:
	## Testa se uma AABB esta dentro do frustum definido pelos planos.
	## Retorna true se a AABB esta pelo menos parcialmente visivel.
	for plane in planes:
		# Encontra o ponto mais proximo do plano (vertice positivo)
		var positive := Vector3(
			aabb.end.x if plane.normal.x >= 0 else aabb.position.x,
			aabb.end.y if plane.normal.y >= 0 else aabb.position.y,
			aabb.end.z if plane.normal.z >= 0 else aabb.position.z,
		)
		# Se o vertice positivo esta atras do plano, AABB esta totalmente fora
		if plane.distance_to(positive) < 0:
			return false
	return true


func _is_particle_emitting(node: Node3D) -> bool:
	if node is GPUParticles3D:
		return node.emitting
	elif node is CPUParticles3D:
		return node.emitting
	return false


func _set_particle_emitting(node: Node3D, emitting: bool) -> void:
	if node is GPUParticles3D:
		node.emitting = emitting
	elif node is CPUParticles3D:
		node.emitting = emitting


# ===========================================================================
# Utilidades
# ===========================================================================

func _update_camera() -> void:
	## Atualiza referencia da camera ativa.
	if _camera and is_instance_valid(_camera):
		return
	var viewport := get_viewport()
	if viewport:
		_camera = viewport.get_camera_3d()


func _cleanup_invalid_entries() -> void:
	## Remove entradas cujos nodes foram destruidos.
	for i in range(_props.size() - 1, -1, -1):
		if not is_instance_valid(_props[i].node):
			_props.remove_at(i)

	for i in range(_particles.size() - 1, -1, -1):
		if not is_instance_valid(_particles[i].node):
			_particles.remove_at(i)
