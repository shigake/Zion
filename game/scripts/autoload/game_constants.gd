class_name GameConstants

## Constantes centralizadas do projeto. Fonte unica de verdade para
## listas, valores de balance e configuracoes de display.
## Todas as magic numbers do jogo devem viver aqui.

# ==================================================================
# FENDAS
# ==================================================================
const ALL_STAGES: Array[String] = [
	"cemetery", "forest", "farm", "tokyo", "volcano",
	"ocean", "arena", "space", "castle", "candy",
]
const CAMPAIGN_STAGES: Array[String] = [
	"cemetery", "forest", "tokyo", "volcano", "ocean", "space", "castle",
]
const ANOMALY_STAGES: Array[String] = ["farm", "arena", "candy"]

const STAGE_SCENE_PATHS := {
	"cemetery": "res://scenes/stages/stage_cemetery.tscn",
	"forest": "res://scenes/stages/stage_forest.tscn",
	"farm": "res://scenes/stages/stage_farm.tscn",
	"tokyo": "res://scenes/stages/stage_tokyo.tscn",
	"volcano": "res://scenes/stages/stage_volcano.tscn",
	"ocean": "res://scenes/stages/stage_ocean.tscn",
	"arena": "res://scenes/stages/stage_arena.tscn",
	"space": "res://scenes/stages/stage_space.tscn",
	"castle": "res://scenes/stages/stage_castle.tscn",
	"candy": "res://scenes/stages/stage_candy.tscn",
}

const BOSS_SCENE_PATHS := {
	"cemetery": "res://scenes/enemies/boss_necromancer.tscn",
	"forest": "res://scenes/enemies/boss_fairy_queen.tscn",
	"farm": "res://scenes/enemies/boss_alien_cow.tscn",
	"tokyo": "res://scenes/enemies/boss_ai_overlord.tscn",
	"volcano": "res://scenes/enemies/boss_demon_lord.tscn",
	"ocean": "res://scenes/enemies/boss_leviathan.tscn",
	"arena": "res://scenes/enemies/boss_emperor.tscn",
	"space": "res://scenes/enemies/boss_singularity.tscn",
	"castle": "res://scenes/enemies/boss_dracula.tscn",
	"candy": "res://scenes/enemies/boss_sugar_king.tscn",
}

# ==================================================================
# DISPLAY
# ==================================================================
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

# ==================================================================
# BALANCE — XP & DIFICULDADE
# ==================================================================
const XP_SCALE_FACTOR := 1.15
const XP_FLAT_BONUS := 3
const DIFFICULTY_TIME_SCALE := 0.35
const BOSS_SPAWN_TIME := 720.0  # 12 minutos
const PICKUP_CAP := 200
const MAX_ENEMIES := 500

# ==================================================================
# PLAYER
# ==================================================================
const PLAYER_BASE_SPEED := 8.0
const PLAYER_DASH_SPEED := 24.0
const PLAYER_DASH_DURATION := 0.15
const PLAYER_DASH_COOLDOWN := 3.0
const PLAYER_HURT_COOLDOWN := 0.5
const PLAYER_HURT_FLASH_DURATION := 0.12
const PLAYER_SPRITE_PIXEL_SIZE := 0.07
const PLAYER_SPRITE_Y_OFFSET := 0.65
const PLAYER_FOOTSTEP_INTERVAL := 0.3
const PLAYER_DUST_INTERVAL := 0.2
const PLAYER_DUST_MIN_FPS := 40
const PLAYER_MOVEMENT_THRESHOLD := 0.5  # Velocidade minima para "andando"
const PLAYER_EMOTE_DURATION := 3.0
const PLAYER_EMOTE_WHEEL_RADIUS := 120.0

# ---- Walk Animation ----
const WALK_BOB_BASE_FREQ := 8.0
const WALK_BOB_SPEED_FACTOR := 0.3
const WALK_BOB_AMPLITUDE := 0.06
const WALK_LANDING_SQUASH := 0.08
const WALK_LANDING_THRESHOLD := 0.03
const WALK_LEAN_FACTOR := 0.06  # radianos
const WALK_LEAN_LERP_SPEED := 10.0
const WALK_SQUASH_DECAY_SPEED := 12.0

# ---- Idle Animation ----
const IDLE_BREATH_FREQ := 2.5
const IDLE_BREATH_AMPLITUDE := 0.015
const IDLE_BREATH_SCALE := 0.01
const IDLE_LEAN_RETURN_SPEED := 6.0

# ---- Barrier Walls ----
const BARRIER_SHOW_DIST := 12.0
const BARRIER_WALL_HEIGHT := 6.0
const BARRIER_WALL_THICKNESS := 0.3

# ==================================================================
# ENEMY — BASE
# ==================================================================
const ENEMY_BASE_SPEED := 4.0
const ENEMY_BASE_HP := 20
const ENEMY_BASE_DAMAGE := 10
const ENEMY_SPRITE_PIXEL_SIZE := 0.05
const ENEMY_BOSS_SPRITE_PIXEL_SIZE := 0.07
const ENEMY_SPRITE_Y_OFFSET := 0.65
const ENEMY_KNOCKBACK_FORCE := 3.5
const ENEMY_KNOCKBACK_DECAY := 8.0

# ---- Walk Animation (Inimigos) ----
const ENEMY_BOB_BASE_FREQ := 6.0
const ENEMY_BOB_SPEED_FACTOR := 0.5
const ENEMY_BOB_MIN_AMP := 0.02
const ENEMY_BOB_MAX_AMP := 0.06
const ENEMY_BOB_AMP_FACTOR := 0.006
const ENEMY_LEAN_MAX := 0.05
const ENEMY_LEAN_FACTOR := 0.01
const ENEMY_LEAN_LERP := 0.15
const ENEMY_SQUASH_X := 0.025
const ENEMY_SQUASH_Y := 0.035
const ENEMY_FLIP_THRESHOLD := 0.3

# ---- Idle Animation (Inimigos) ----
const ENEMY_IDLE_FREQ := 2.5
const ENEMY_IDLE_AMPLITUDE := 0.015

# ---- Separacao ----
const SEPARATION_RADIUS := 1.5
const SEPARATION_FORCE := 3.0
const MAX_NEIGHBORS_CHECK := 8

# ---- Projectile (Inimigo) ----
const ENEMY_PROJ_RADIUS := 0.15
const ENEMY_PROJ_HEIGHT := 0.3
const ENEMY_PROJ_RANGE := 15.0
const ENEMY_PROJ_TRAVEL_TIME := 1.5
const ENEMY_PROJ_COLLISION_RADIUS := 0.3
const ENEMY_PROJ_SPAWN_Y := 0.8
const ENEMY_PROJ_COLOR := Color(1.0, 0.3, 0.3)
const ENEMY_PROJ_EMISSION := Color(1.0, 0.2, 0.2)
const ENEMY_PROJ_EMISSION_ENERGY := 2.0

# ---- Hidden Player Detection ----
const HIDDEN_PLAYER_LOSE_RANGE := 5.0

# ==================================================================
# ENEMY — ELITE
# ==================================================================
const ELITE_HP_MULT := 3.0
const ELITE_DAMAGE_MULT := 1.5
const ELITE_XP_MULT := 5
const ELITE_SPEED_MULT := 1.2
const ELITE_SCALE := Vector3(1.3, 1.3, 1.3)
const ELITE_COLOR := Color(1.0, 0.85, 0.2)  # Dourado
const ELITE_MIN_MINUTE := 15.0
const ELITE_SPAWN_CHANCE := 0.1  # 10%

# ==================================================================
# ENEMY — SPAWNER
# ==================================================================
const SPAWN_MIN_INTERVAL := 0.15

# ---- Fases de Spawn (minutos) ----
const SPAWN_PHASE_1_END := 2.0    # So slimes
const SPAWN_PHASE_2_END := 5.0    # Slimes + Bats
const SPAWN_PHASE_3_END := 8.0    # Skeletons + Bats + Slimes grandes
const SPAWN_PHASE_4_END := 12.0   # Archers + Zombies + Ghosts + Bombers
const SPAWN_PHASE_5_END := 20.0   # Mix de tudo + Tanks + Swarms

# ---- Probabilidades de Spawn ----
const SPAWN_TOOTH_FAIRY_CHANCE := 0.03      # 3% a partir do minuto 5
const SPAWN_GHOST_CEMETERY_CHANCE := 0.8     # 80% threshold (roll > 0.8)
const SPAWN_GHOST_PHASE2_CHANCE := 0.25      # 25% fantasmas no cemiterio fase 2
const SPAWN_TANK_CHANCE := 0.06              # 6% tank
const SPAWN_SWARM_CHANCE := 0.10             # 10% swarm (acumulado)
const SPAWN_MIMIC_CHANCE := 0.13             # 13% mimic (acumulado)

# ---- Performance Throttle ----
const FPS_CRITICAL := 20.0       # FPS critico: para spawning
const FPS_LOW := 30.0            # FPS baixo: limita spawning
const FPS_MEDIUM := 45.0         # FPS medio: soft cap
const FPS_LOW_SPAWN_MULT := 0.5  # Multiplicador de spawn em FPS baixo
const ENEMIES_CAP_CRITICAL := 30
const ENEMIES_CAP_LOW := 60
const ENEMIES_CAP_MEDIUM := 120

# ---- Boss Rush ----
const BOSS_RUSH_FILLER_INTERVAL := 1.5
const BOSS_RUSH_MULT_PER_BOSS := 0.3
const BOSS_RUSH_COOLDOWN := 3.0
const BOSS_RUSH_HEAL_FRACTION := 0.5  # Cura 50% entre bosses
const BOSS_RUSH_XP_REWARD := 20

# ---- Miniboss ----
const MINIBOSS_XP_DROP := 50
const MINIBOSS_SCALE := Vector3(2.5, 2.5, 2.5)

# ==================================================================
# BOSS — FASES & COMPORTAMENTO
# ==================================================================
const BOSS_PHASE_1_THRESHOLD := 0.75   # 100%-75% HP
const BOSS_PHASE_2_THRESHOLD := 0.25   # 75%-25% HP
const BOSS_FURY_THRESHOLD := 0.10      # 10% HP — modo furia
const BOSS_FURY_SPEED_MULT := 1.5
const BOSS_FURY_COLOR := Color(1.5, 0.5, 0.5)
const BOSS_CHARGE_DURATION := 0.5
const BOSS_PROJ_DAMAGE_MULT := 0.3     # Dano do projetil = damage * 0.3
const BOSS_MINION_SPAWN_RADIUS := 3.0
const BOSS_MINION_SPAWN_RADIUS_LARGE := 4.0
const BOSS_AURA_PIXEL_MULT := 1.3
const BOSS_AURA_BASE_ALPHA := 0.3
const BOSS_AURA_MIN_ALPHA := 0.2
const BOSS_AURA_PULSE_SPEED := 0.004
const BOSS_AURA_PULSE_AMP := 0.15
const BOSS_LABEL_FONT_SIZE := 24
const BOSS_LABEL_Y_OFFSET := 1.2
const BOSS_ENTRANCE_SCALE_OVERSHOOT := 1.15
const BOSS_FURIOUS_MUTATION_HP := 0.75  # Bosses furiosos comecam com 75% HP

# ==================================================================
# DROPS & PICKUPS
# ==================================================================
const CRYSTAL_DROP_CHANCE := 0.3         # 30% base
const CRYSTAL_DROP_CHANCE_KEY := 0.5     # 50% com master key
const HEALTH_DROP_CHANCE := 0.05         # 5% base
const HEALTH_DROP_BONUS_THRESHOLD := 0.4 # 40% HP threshold
const HEALTH_DROP_BONUS_CHANCE := 0.03   # 3% extra quando HP baixo
const HEALTH_HEAL_FRACTION := 0.08       # 8% do max HP
const MAGNET_DROP_CHANCE := 0.01         # 1% base
const MAGNET_DROP_CHANCE_KEY := 0.02     # 2% com master key
const PICKUP_DESPAWN_TIME := 30.0        # Segundos ate despawn

# ---- Atracao ----
const XP_ATTRACT_SPEED := 15.0
const XP_ATTRACT_RANGE := 4.0
const CRYSTAL_ATTRACT_SPEED := 12.0
const CRYSTAL_ATTRACT_RANGE := 3.0
const HEALTH_ATTRACT_SPEED := 14.0
const HEALTH_ATTRACT_RANGE := 3.5
const MAGNET_ATTRACT_SPEED := 10.0
const MAGNET_ATTRACT_RANGE := 3.5
const PICKUP_COLLECT_DIST_SQ := 0.25    # Distancia ao quadrado para coletar
const PICKUP_COLLECT_DIST := 0.5        # Distancia normal para coletar (health/magnet)
const PICKUP_FRAME_STAGGER := 5         # Checa atracao a cada N frames

# ---- Spawn Offsets ----
const XP_SPAWN_OFFSET := Vector3(0, 0.3, 0)
const CRYSTAL_SPAWN_OFFSET := Vector3(0.3, 0.3, 0.3)
const HEALTH_SPAWN_OFFSET := Vector3(-0.3, 0.3, 0.2)
const MAGNET_SPAWN_OFFSET := Vector3(0.2, 0.3, -0.3)

# ---- Sprite ----
const PICKUP_SPRITE_PIXEL_SIZE := 0.025

# ==================================================================
# VISUAL — SPRITES & ANIMACAO
# ==================================================================
const SPRITE_PIXEL_SIZE_SMALL := 0.02   # Poeira, particulas pequenas
const HIT_PARTICLE_COUNT := 6
const HIT_PARTICLE_COUNT_LOW_FPS := 3
const DEATH_PARTICLE_COUNT := 12
const DEATH_PARTICLE_COUNT_LOW_FPS := 6
const BOSS_SHOCKWAVE_PARTICLES := 12
const BOSS_SHOCKWAVE_RADIUS := 3.0
const BOSS_SHOCKWAVE_SPHERE_RADIUS := 0.12

# ---- Hit Flash ----
const HIT_FLASH_COLOR := Color(5, 2, 2)  # Red-tinted flash
const HIT_SQUASH_X := 1.3
const HIT_SQUASH_Y := 0.7
const HIT_FLASH_DURATION := 0.1
const HIT_SQUASH_DURATION := 0.12
const DEATH_FLASH_COLOR := Color(10, 10, 10)
const DEATH_FADE_DURATION := 0.3
const DEATH_SCALE_UP := 1.5
const DEATH_SCALE_DOWN := 0.1
const DEATH_ANIM_DELAY := 0.5

# ---- Player Hit Flash ----
const PLAYER_HIT_FLASH_COLOR := Color(3, 0.3, 0.3)
const PLAYER_HIT_SQUASH_X := 1.3
const PLAYER_HIT_SQUASH_Y := 0.7
const PLAYER_HIT_FLASH_FADE := 0.15
const PLAYER_HIT_SQUASH_FADE := 0.18

# ---- Damage Numbers ----
const DMG_FONT_SIZE := 48
const DMG_FONT_SIZE_CRIT := 64
const DMG_OUTLINE_SIZE := 10
const DMG_SPAWN_X_RANGE := 0.3
const DMG_SPAWN_Y := 1.2
const DMG_CRIT_COLOR := Color(1.0, 0.9, 0.2)

# ---- Performance Thresholds (Visual) ----
const FPS_SKIP_PARTICLES := 30
const FPS_SKIP_SHAKE := 20
const FPS_CRIT_ONLY_DMG := 25       # So mostra crits abaixo deste FPS
const FPS_PARTIAL_DMG := 35          # 30% chance de mostrar dmg number
const FPS_PARTIAL_DMG_CHANCE := 0.3
const FPS_DEATH_PARTICLES := 25
const FPS_DEATH_PARTICLES_CHANCE := 0.4

# ==================================================================
# SCREEN EFFECTS
# ==================================================================
const SHAKE_DECAY := 8.0
const SHAKE_DEFAULT := 0.15
const SHAKE_ON_ENEMY_HIT := 0.03
const SHAKE_ON_ENEMY_KILL := 0.03

# ---- Damage Feedback ----
const DAMAGE_SHAKE_BASE := 0.08
const DAMAGE_SHAKE_SCALE := 0.3
const DAMAGE_SHAKE_MAX := 0.25
const DAMAGE_FREEZE_THRESHOLD := 0.15   # Ratio de dano para ativar hit freeze
const DAMAGE_FREEZE_DURATION := 0.04
const DAMAGE_FLASH_BASE := 0.15
const DAMAGE_FLASH_SCALE := 0.1
const DAMAGE_INTENSITY_SCALE := 2.0
const DAMAGE_INTENSITY_MIN := 0.3
const DAMAGE_INTENSITY_DECAY := 3.0

# ---- Vignette (Low HP) ----
const VIGNETTE_HP_THRESHOLD := 0.3      # 30% HP
const VIGNETTE_BASE_ALPHA := 0.35
const VIGNETTE_PULSE_MIN_SPEED := 4.0
const VIGNETTE_PULSE_MAX_SPEED := 8.0
const VIGNETTE_PULSE_AMPLITUDE := 0.2

# ---- Directional Indicator ----
const DAMAGE_INDICATOR_DURATION := 0.6
const DAMAGE_INDICATOR_SIZE := Vector2(60, 8)
const DAMAGE_INDICATOR_EDGE_DIST := 0.42  # Fração do viewport

# ---- Gamepad Vibration ----
const VIBRATE_STRONG_SCALE := 0.6
const VIBRATE_STRONG_MAX := 0.5
const VIBRATE_WEAK_SCALE := 0.8
const VIBRATE_WEAK_MAX := 0.7
const VIBRATE_DURATION := 0.2

# ---- Level Up Flash ----
const LEVEL_UP_FLASH_ALPHA := 0.4
const LEVEL_UP_FLASH_DURATION := 0.3

# ---- Kill Streak ----
const KILL_STREAK_WINDOW := 2.0   # Segundos para contar kills
const KILL_STREAK_MIN := 5        # Kills minimos para streak text
const KILL_STREAK_FONT_SIZE := 48
const KILL_STREAK_TIER_2 := 10    # MASSACRE!
const KILL_STREAK_TIER_3 := 20    # UNSTOPPABLE!
const KILL_STREAK_TIER_4 := 30    # GODLIKE!

# ---- Boss Entrance ----
const BOSS_ENTRANCE_LETTERBOX_DURATION := 2.5
const BOSS_ENTRANCE_LETTERBOX_HEIGHT := 60.0
const BOSS_ENTRANCE_VIGNETTE_FADE_IN := 0.2
const BOSS_ENTRANCE_VIGNETTE_ALPHA := 0.6
const BOSS_ENTRANCE_VIGNETTE_HOLD := 1.8
const BOSS_ENTRANCE_VIGNETTE_FADE_OUT := 0.5
const BOSS_ENTRANCE_SHAKE_1 := 0.15
const BOSS_ENTRANCE_SHAKE_2 := 0.35
const BOSS_ENTRANCE_SHAKE_3 := 0.6
const BOSS_ENTRANCE_SHAKE_DELAY_1 := 0.2
const BOSS_ENTRANCE_SHAKE_DELAY_2 := 0.15
const BOSS_ENTRANCE_SLOW_MO_DURATION := 0.5
const BOSS_ENTRANCE_SLOW_MO_SCALE := 0.25
const BOSS_ENTRANCE_RUMBLE_1_WEAK := 0.6
const BOSS_ENTRANCE_RUMBLE_1_STRONG := 0.4
const BOSS_ENTRANCE_RUMBLE_1_DURATION := 0.3
const BOSS_ENTRANCE_RUMBLE_2_WEAK := 1.0
const BOSS_ENTRANCE_RUMBLE_2_STRONG := 0.9
const BOSS_ENTRANCE_RUMBLE_2_DURATION := 0.8
const BOSS_ENTRANCE_RUMBLE_2_DELAY := 0.3

# ==================================================================
# STAGE BEHAVIORS
# ==================================================================
const BEHAVIOR_TELEPORT_OFFSET := 3.0
const BEHAVIOR_AMBUSH_RANGE := 8.0
const BEHAVIOR_CHARGE_DURATION := 0.8
const BEHAVIOR_CHARGE_SPEED_MULT := 3.0
const BEHAVIOR_CHARGE_RANGE := 12.0
const BEHAVIOR_SPLIT_MIN_SCALE := 0.5

# ==================================================================
# DAMAGE TYPE COLORS
# ==================================================================
const DAMAGE_COLORS := {
	"fire": Color(1.0, 0.5, 0.2),
	"ice": Color(0.4, 0.8, 1.0),
	"electric": Color(1.0, 1.0, 0.3),
	"dark": Color(0.7, 0.3, 0.9),
	"poison": Color(0.3, 0.9, 0.3),
	"physical": Color(1, 1, 0.8),
}

# ==================================================================
# VETERAN RELIC
# ==================================================================
const VETERAN_RELIC_SPEED_MULT := 1.15  # Inimigos 15% mais rapidos

# ==================================================================
# SPAWN ON DEATH BEHAVIOR
# ==================================================================
const SPAWN_ON_DEATH_COUNT := 3
const SPAWN_ON_DEATH_HP_DIV := 4
const SPAWN_ON_DEATH_DMG_DIV := 2
const SPAWN_ON_DEATH_SCALE := Vector3(0.5, 0.5, 0.5)
const SPAWN_ON_DEATH_OFFSET := 1.5
const EXPLODE_ON_DEATH_RADIUS := 2.5
