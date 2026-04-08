class_name StageAtmosphere

## Configura iluminação, fog e ambiente por fenda.
## Chamado pelo BaseStage._ready() após setup do jogador.

const STAGE_CONFIGS := {
	"cemetery": {
		"ambient_color": Color(0.1, 0.07, 0.18),
		"ambient_energy": 0.3,
		"bg_color": Color(0.03, 0.02, 0.06),
		"fog_enabled": true,
		"fog_color": Color(0.12, 0.08, 0.22),
		"fog_density": 0.012,
		"fog_aerial": 0.5,
		"light_color": Color(0.4, 0.3, 0.6),
		"light_energy": 0.6,
		"glow_intensity": 0.4,
		"tonemap": Environment.TONE_MAPPER_ACES,
	},
	"forest": {
		"ambient_color": Color(0.08, 0.15, 0.06),
		"ambient_energy": 0.5,
		"bg_color": Color(0.02, 0.05, 0.02),
		"fog_enabled": true,
		"fog_color": Color(0.08, 0.16, 0.06),
		"fog_density": 0.006,
		"fog_aerial": 0.4,
		"light_color": Color(0.5, 0.7, 0.3),
		"light_energy": 0.8,
		"glow_intensity": 0.3,
		"tonemap": Environment.TONE_MAPPER_FILMIC,
	},
	"farm": {
		"ambient_color": Color(0.12, 0.08, 0.04),
		"ambient_energy": 0.35,
		"bg_color": Color(0.05, 0.03, 0.01),
		"fog_enabled": true,
		"fog_color": Color(0.15, 0.1, 0.05),
		"fog_density": 0.008,
		"light_color": Color(0.8, 0.55, 0.25),
		"light_energy": 0.6,
		"glow_intensity": 0.2,
		"tonemap": Environment.TONE_MAPPER_ACES,
	},
	"tokyo": {
		"ambient_color": Color(0.05, 0.1, 0.15),
		"ambient_energy": 0.4,
		"bg_color": Color(0.02, 0.02, 0.05),
		"fog_enabled": false,
		"fog_color": Color(0.05, 0.1, 0.15),
		"fog_density": 0.0,
		"light_color": Color(0.3, 0.8, 1.0),
		"light_energy": 0.7,
		"glow_intensity": 0.6,
		"tonemap": Environment.TONE_MAPPER_ACES,
	},
	"volcano": {
		"ambient_color": Color(0.1, 0.02, 0.01),
		"ambient_energy": 0.25,
		"bg_color": Color(0.04, 0.01, 0.005),
		"fog_enabled": true,
		"fog_color": Color(0.15, 0.04, 0.01),
		"fog_density": 0.015,
		"light_color": Color(0.9, 0.3, 0.05),
		"light_energy": 0.55,
		"glow_intensity": 0.6,
		"tonemap": Environment.TONE_MAPPER_ACES,
	},
	"ocean": {
		"ambient_color": Color(0.04, 0.08, 0.15),
		"ambient_energy": 0.35,
		"bg_color": Color(0.01, 0.03, 0.08),
		"fog_enabled": true,
		"fog_color": Color(0.05, 0.1, 0.2),
		"fog_density": 0.02,
		"light_color": Color(0.2, 0.5, 0.8),
		"light_energy": 0.5,
		"glow_intensity": 0.3,
		"tonemap": Environment.TONE_MAPPER_FILMIC,
	},
	"arena": {
		"ambient_color": Color(0.15, 0.12, 0.05),
		"ambient_energy": 0.5,
		"bg_color": Color(0.05, 0.04, 0.02),
		"fog_enabled": true,
		"fog_color": Color(0.2, 0.15, 0.08),
		"fog_density": 0.004,
		"light_color": Color(1.0, 0.85, 0.4),
		"light_energy": 1.0,
		"glow_intensity": 0.4,
		"tonemap": Environment.TONE_MAPPER_ACES,
	},
	"space": {
		"ambient_color": Color(0.05, 0.03, 0.1),
		"ambient_energy": 0.25,
		"bg_color": Color(0.01, 0.01, 0.03),
		"fog_enabled": false,
		"fog_color": Color(0.05, 0.03, 0.1),
		"fog_density": 0.0,
		"light_color": Color(0.5, 0.3, 0.9),
		"light_energy": 0.6,
		"glow_intensity": 0.5,
		"tonemap": Environment.TONE_MAPPER_ACES,
	},
	"castle": {
		"ambient_color": Color(0.1, 0.04, 0.06),
		"ambient_energy": 0.3,
		"bg_color": Color(0.04, 0.02, 0.03),
		"fog_enabled": true,
		"fog_color": Color(0.12, 0.05, 0.08),
		"fog_density": 0.01,
		"light_color": Color(0.6, 0.2, 0.2),
		"light_energy": 0.6,
		"glow_intensity": 0.35,
		"tonemap": Environment.TONE_MAPPER_FILMIC,
	},
	"candy": {
		"ambient_color": Color(0.2, 0.12, 0.15),
		"ambient_energy": 0.6,
		"bg_color": Color(0.1, 0.05, 0.08),
		"fog_enabled": true,
		"fog_color": Color(0.25, 0.15, 0.2),
		"fog_density": 0.003,
		"light_color": Color(1.0, 0.7, 0.8),
		"light_energy": 1.0,
		"glow_intensity": 0.5,
		"tonemap": Environment.TONE_MAPPER_ACES,
	},
}

static func apply(scene: Node3D, stage_id: String) -> void:
	var config = STAGE_CONFIGS.get(stage_id, STAGE_CONFIGS["cemetery"])

	# Environment
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = config["bg_color"]
	env.ambient_light_color = config["ambient_color"]
	env.ambient_light_energy = config["ambient_energy"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = config["tonemap"]

	# Fog
	if config["fog_enabled"]:
		env.fog_enabled = true
		env.fog_light_color = config["fog_color"]
		env.fog_density = config["fog_density"]
		env.fog_aerial_perspective = config.get("fog_aerial", 0.3)

	# Glow (bloom)
	env.glow_enabled = true
	env.glow_intensity = config["glow_intensity"]
	env.glow_bloom = 0.15
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	var world_env = WorldEnvironment.new()
	world_env.name = "StageEnvironment"
	world_env.environment = env
	scene.add_child(world_env)

	# Directional light
	var sun = DirectionalLight3D.new()
	sun.name = "StageLight"
	sun.light_color = config["light_color"]
	sun.light_energy = config["light_energy"]
	sun.rotation.x = deg_to_rad(-45)
	sun.rotation.y = deg_to_rad(30)
	sun.shadow_enabled = false  # Desativado para performance
	scene.add_child(sun)

	LogManager.info("Stage", "Atmosphere applied: %s (fog=%s, glow=%.1f)" % [stage_id, config["fog_enabled"], config["glow_intensity"]])

## Aumenta glow temporariamente (level up, evolução, boss morte)
static func bloom_spike(scene: Node3D, intensity: float = 0.8, duration: float = 0.5) -> void:
	var world_env = scene.get_node_or_null("StageEnvironment") as WorldEnvironment
	if not world_env or not world_env.environment:
		return
	var env = world_env.environment
	var original = env.glow_intensity
	env.glow_intensity = intensity
	var tween = scene.create_tween()
	tween.tween_property(env, "glow_intensity", original, duration).set_ease(Tween.EASE_OUT)
