class_name GameConstants

## Constantes centralizadas do projeto. Fonte unica de verdade para
## listas, valores de balance e configuracoes de display.

# ---- Fendas ----
const ALL_STAGES: Array[String] = [
	"cemetery", "forest", "farm", "tokyo", "volcano",
	"ocean", "arena", "space", "castle", "candy",
]
const CAMPAIGN_STAGES: Array[String] = [
	"cemetery", "forest", "tokyo", "volcano", "ocean", "space", "castle",
]
const ANOMALY_STAGES: Array[String] = ["farm", "arena", "candy"]

const STAGE_SCENE_PATHS := {
	"cemetery": "res://scenes/stages/cemetery.tscn",
	"forest": "res://scenes/stages/forest.tscn",
	"farm": "res://scenes/stages/farm.tscn",
	"tokyo": "res://scenes/stages/tokyo.tscn",
	"volcano": "res://scenes/stages/volcano.tscn",
	"ocean": "res://scenes/stages/ocean.tscn",
	"arena": "res://scenes/stages/arena.tscn",
	"space": "res://scenes/stages/space.tscn",
	"castle": "res://scenes/stages/castle.tscn",
	"candy": "res://scenes/stages/candy.tscn",
}

# ---- Display ----
const FPS_OPTIONS := [30, 60, 120, 144, 240, 0]
const FPS_LABELS := ["30", "60", "120", "144", "240", "Ilimitado"]

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(854, 480),
	Vector2i(1024, 576),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

# ---- Balance ----
const XP_SCALE_FACTOR := 1.15
const XP_FLAT_BONUS := 3
const DIFFICULTY_TIME_SCALE := 0.35
const BOSS_SPAWN_TIME := 720.0  # 12 minutos
const PICKUP_CAP := 200
const MAX_ENEMIES := 500
