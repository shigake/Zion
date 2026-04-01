extends BaseStage

## Fase Mundo Doce — PRD-27: mapa reduzido pela metade para teste de tamanho

const MAP_HALF_SIZE_CANDY: float = 47.5    # metade de 95 (padrão global)
const MAP_HALF_SIZE_DEFAULT: float = 95.0

func _ready() -> void:
	music_track = "candy"
	GameManager.map_half_size = MAP_HALF_SIZE_CANDY  # PRD-27: barreira no limite do novo mapa
	super._ready()

func _exit_tree() -> void:
	GameManager.map_half_size = MAP_HALF_SIZE_DEFAULT  # restaura para outros estágios
	super._exit_tree()
