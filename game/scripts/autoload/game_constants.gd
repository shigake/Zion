extends Node

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

## Boss pool por fenda — sorteio aleatorio a cada spawn.
## Primeiro da lista e o Sentinela original, os outros sao alternativos.
const BOSS_POOLS := {
	"cemetery": [
		"res://scenes/enemies/boss_necromancer.tscn",     # Sentinela original
		"res://scenes/enemies/boss_cemetery_lich.tscn",    # Lich King
		"res://scenes/enemies/boss_cemetery_reaper.tscn",  # Death Reaper
	],
	"forest": [
		"res://scenes/enemies/boss_fairy_queen.tscn",
		"res://scenes/enemies/boss_forest_elder.tscn",     # Elder Treant
		"res://scenes/enemies/boss_forest_spider.tscn",    # Spider Queen
	],
	"farm": [
		"res://scenes/enemies/boss_alien_cow.tscn",
		"res://scenes/enemies/boss_farm_scarecrow.tscn",   # Scarecrow King
		"res://scenes/enemies/boss_farm_harvester.tscn",   # The Harvester
	],
	"tokyo": [
		"res://scenes/enemies/boss_ai_overlord.tscn",
		"res://scenes/enemies/boss_tokyo_shogun.tscn",     # Cyber Shogun
		"res://scenes/enemies/boss_tokyo_kaiju.tscn",      # Mini Kaiju
	],
	"volcano": [
		"res://scenes/enemies/boss_demon_lord.tscn",
		"res://scenes/enemies/boss_volcano_phoenix.tscn",  # Ash Phoenix
		"res://scenes/enemies/boss_volcano_titan.tscn",    # Magma Titan
	],
	"ocean": [
		"res://scenes/enemies/boss_leviathan.tscn",
		"res://scenes/enemies/boss_ocean_siren.tscn",      # Siren Queen
		"res://scenes/enemies/boss_ocean_hydra.tscn",      # Deep Hydra
	],
	"arena": [
		"res://scenes/enemies/boss_emperor.tscn",
		"res://scenes/enemies/boss_arena_minotaur.tscn",   # Minotaur Champion
		"res://scenes/enemies/boss_arena_chimera.tscn",    # Chimera
	],
	"space": [
		"res://scenes/enemies/boss_singularity.tscn",
		"res://scenes/enemies/boss_space_hivemind.tscn",   # Hive Mind
		"res://scenes/enemies/boss_space_warden.tscn",     # Void Warden
	],
	"castle": [
		"res://scenes/enemies/boss_dracula.tscn",
		"res://scenes/enemies/boss_castle_werewolf.tscn",  # Alpha Werewolf
		"res://scenes/enemies/boss_castle_banshee.tscn",   # Banshee Queen
	],
	"candy": [
		"res://scenes/enemies/boss_sugar_king.tscn",
		"res://scenes/enemies/boss_candy_witch.tscn",      # Candy Witch
		"res://scenes/enemies/boss_candy_dragon.tscn",     # Gummy Dragon
	],
}

## Nota: funcoes utilitarias movidas para evitar dependencia circular.
## Use _get_random_boss_path() inline no enemy_spawner.gd.

# Legacy compatibility
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

## Mini-boss pool por fenda — 3 opcoes aleatorias cada.
const MINIBOSS_POOL := {
	"cemetery": [
		{"name": "Giant Zombie", "hp": 500, "dmg": 25, "spd": 2.5, "color": Color(0.4, 0.15, 0.15)},
		{"name": "Bone Colossus", "hp": 700, "dmg": 20, "spd": 2.0, "color": Color(0.8, 0.8, 0.7)},
		{"name": "Phantom Knight", "hp": 550, "dmg": 30, "spd": 4.0, "color": Color(0.3, 0.3, 0.6)},
	],
	"forest": [
		{"name": "Shadow Treant", "hp": 600, "dmg": 25, "spd": 5.0, "color": Color(0.1, 0.0, 0.2)},
		{"name": "Poison Hydra", "hp": 500, "dmg": 35, "spd": 3.0, "color": Color(0.2, 0.7, 0.1)},
		{"name": "Dire Wolf Alpha", "hp": 450, "dmg": 28, "spd": 7.0, "color": Color(0.5, 0.4, 0.3)},
	],
	"farm": [
		{"name": "Mad Bull", "hp": 700, "dmg": 28, "spd": 5.5, "color": Color(0.5, 0.5, 0.5)},
		{"name": "Mutant Rooster", "hp": 500, "dmg": 35, "spd": 6.0, "color": Color(0.8, 0.2, 0.1)},
		{"name": "Corn Golem", "hp": 900, "dmg": 20, "spd": 2.0, "color": Color(0.9, 0.8, 0.2)},
	],
	"tokyo": [
		{"name": "Mecha Ninja", "hp": 750, "dmg": 30, "spd": 5.0, "color": Color(0.2, 0.2, 0.3)},
		{"name": "Yakuza Boss", "hp": 600, "dmg": 40, "spd": 4.0, "color": Color(0.1, 0.1, 0.1)},
		{"name": "Rogue Drone Swarm", "hp": 400, "dmg": 20, "spd": 8.0, "color": Color(0.5, 0.5, 0.8)},
	],
	"volcano": [
		{"name": "Cerberus", "hp": 850, "dmg": 32, "spd": 4.0, "color": Color(0.6, 0.1, 0.0)},
		{"name": "Lava Serpent", "hp": 700, "dmg": 28, "spd": 5.0, "color": Color(1.0, 0.4, 0.0)},
		{"name": "Obsidian Golem", "hp": 1200, "dmg": 20, "spd": 1.5, "color": Color(0.2, 0.2, 0.25)},
	],
	"ocean": [
		{"name": "Baby Kraken", "hp": 800, "dmg": 30, "spd": 4.5, "color": Color(0.1, 0.3, 0.5)},
		{"name": "Shark King", "hp": 650, "dmg": 40, "spd": 6.0, "color": Color(0.3, 0.4, 0.5)},
		{"name": "Giant Crab", "hp": 1000, "dmg": 22, "spd": 2.0, "color": Color(0.8, 0.3, 0.1)},
	],
	"arena": [
		{"name": "Champion Gladiator", "hp": 900, "dmg": 35, "spd": 4.5, "color": Color(0.7, 0.5, 0.1)},
		{"name": "War Rhino", "hp": 1100, "dmg": 25, "spd": 6.0, "color": Color(0.5, 0.5, 0.5)},
		{"name": "Dual Blade Assassin", "hp": 500, "dmg": 42, "spd": 7.0, "color": Color(0.2, 0.0, 0.3)},
	],
	"space": [
		{"name": "Alien Queen", "hp": 950, "dmg": 32, "spd": 4.0, "color": Color(0.3, 0.6, 0.2)},
		{"name": "Cosmic Jellyfish", "hp": 700, "dmg": 25, "spd": 3.0, "color": Color(0.6, 0.3, 0.9)},
		{"name": "Mech Sentinel", "hp": 800, "dmg": 38, "spd": 5.0, "color": Color(0.4, 0.4, 0.6)},
	],
	"castle": [
		{"name": "Vampiress", "hp": 1000, "dmg": 35, "spd": 5.0, "color": Color(0.5, 0.0, 0.2)},
		{"name": "Armored Gargoyle", "hp": 1200, "dmg": 28, "spd": 3.0, "color": Color(0.4, 0.4, 0.45)},
		{"name": "Ghost Samurai", "hp": 600, "dmg": 45, "spd": 6.5, "color": Color(0.2, 0.5, 0.7)},
	],
	"candy": [
		{"name": "Triple Layer Cake", "hp": 1100, "dmg": 30, "spd": 3.5, "color": Color(0.9, 0.6, 0.7)},
		{"name": "Chocolate Golem", "hp": 1300, "dmg": 22, "spd": 2.0, "color": Color(0.4, 0.2, 0.1)},
		{"name": "Sugar Rush Pixie", "hp": 400, "dmg": 35, "spd": 9.0, "color": Color(1.0, 0.8, 0.3)},
	],
}

## Nota: get_random_miniboss() movida para event_manager.gd.

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
const XP_SCALE_FACTOR := 1.12
const XP_FLAT_BONUS := 3
const DIFFICULTY_TIME_SCALE := 0.35
const BOSS_SPAWN_TIME := 300.0  # 5 minutos (1o boss)
const BOSS_SPAWN_INTERVAL := 300.0  # Boss a cada 5 min
const RUN_TIME_NORMAL := 600.0  # 10 minutos por partida

# ---- Reward Chests ----
const CHEST_SPAWN_INTERVAL := 45.0  # Bau a cada 45 segundos
const CHEST_REWARD_CRYSTALS_MIN := 5
const CHEST_REWARD_CRYSTALS_MAX := 15
const CHEST_REWARD_XP := 20
const CHEST_ARROW_COLOR := Color(1.0, 0.85, 0.2)  # Dourado
const MERCHANT_ARROW_COLOR := Color(0.4, 0.85, 1.0)  # Ciano azulado
const CHEST_DESPAWN_TIME := 20.0  # Desaparece em 20s se nao coletar

# ---- Quest System ----
const QUEST_INTERVAL := 60.0  # Nova quest a cada 60s
const QUEST_REWARD_CRYSTALS := 10
const QUEST_REWARD_XP := 30
const PICKUP_CAP := 200
const MAX_ENEMIES := 150

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
const ELITE_MIN_MINUTE := 10.0  # Elites a partir do min 10 (era 15)
const ELITE_SPAWN_CHANCE := 0.1  # 10%

# ==================================================================
# ENEMY — SPAWNER
# ==================================================================
const SPAWN_MIN_INTERVAL := 0.15

# ---- Fases de Spawn (minutos) ----
const SPAWN_PHASE_1_END := 1.0    # So slimes (era 2 min)
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
const ENEMIES_CAP_CRITICAL := 10
const ENEMIES_CAP_LOW := 20
const ENEMIES_CAP_MEDIUM := 40

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
const HEALTH_DROP_CHANCE := 0.04         # 4% base (era 2%)
const HEALTH_DROP_BONUS_THRESHOLD := 0.3 # 30% HP threshold (era 40%)
const HEALTH_DROP_BONUS_CHANCE := 0.03   # 3% extra quando HP baixo (era 2%)
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

# ==================================================================
# ANNULUS SPAWNING
# ==================================================================
const ANNULUS_MIN_RADIUS := 15.0       # Logo fora da visao da camera top-down
const ANNULUS_MAX_RADIUS := 20.0       # Limite maximo do anel
const BOSS_ANNULUS_MIN_RADIUS := 18.0  # Bosses surgem mais longe
const BOSS_ANNULUS_MAX_RADIUS := 22.0

# ==================================================================
# MULTIPLAYER SCALING
# ==================================================================
const MP_HP_MULT := [1.0, 1.0, 1.3, 1.6, 2.0]
const MP_SPAWN_MULT := [0.85, 1.0, 1.2, 1.4, 1.6]  # Solo = 0.85x (era 1.0)
const MP_BOSS_HP_MULT := [0.85, 1.0, 1.5, 2.0, 2.5]  # Boss solo = 0.85x HP

# ==================================================================
# DIFFICULTY
# ==================================================================
const DIFFICULTY_CAP := 12.0
const HYPER_XP_MULT := 2.0
const XP_LEVEL_SCALE := 1.12
const XP_LEVEL_FLAT := 3
const ARMOR_DIMINISH_DIVISOR := 50   # reduction = armor / (armor + 50)
const ONESHOT_THRESHOLD_RATIO := 0.5 # Alerta se dano > 50% max HP
const REVIVE_HP_FRACTION := 0.5      # Revive com 50% HP

# ==================================================================
# TOMBSTONE (Multiplayer Revive)
# ==================================================================
const TOMBSTONE_DESPAWN_TIME := 60.0
const TOMBSTONE_REVIVE_TIME := 5.0
const TOMBSTONE_REVIVE_HP_PCT := 0.5
const TOMBSTONE_INVULN_DURATION := 2.0
const TOMBSTONE_DEBUFF_HP_REDUCTION := 0.30
const TOMBSTONE_DEBUFF_DURATION := 30.0
const TOMBSTONE_INTERACT_RADIUS := 2.5
const TOMBSTONE_SPRITE_PIXEL_SIZE := 0.06
const TOMBSTONE_SPRITE_Y := 0.8
const TOMBSTONE_RING_PIXEL_SIZE := 0.12
const TOMBSTONE_SOUL_PARTICLES := 12
const TOMBSTONE_PROGRESS_BAR_Y := 1.6

# ==================================================================
# EVENT MANAGER
# ==================================================================
const EVENT_WARNING_TIME := 10.0        # Aviso N segundos antes
const EVENT_FIRST_RANDOM_MIN := 120.0   # Primeiro evento aleatorio: min
const EVENT_FIRST_RANDOM_MAX := 240.0   # Primeiro evento aleatorio: max
const EVENT_RANDOM_INTERVAL_MIN := 90.0
const EVENT_RANDOM_INTERVAL_MAX := 180.0

# ---- Event Durations ----
const EVENT_GOLDEN_HORDE_DURATION := 20.0
const EVENT_ELITE_HORDE_DURATION := 25.0
const EVENT_MASSIVE_HORDE_DURATION := 30.0
const EVENT_ECLIPSE_DURATION := 15.0
const EVENT_METEOR_DURATION := 12.0
const EVENT_ROULETTE_DURATION := 5.0
const EVENT_MERCHANT_DURATION := 30.0
const EVENT_PORTAL_DURATION := 30.0
const EVENT_CHEST_MIMIC_DURATION := 30.0
const EVENT_GOBLIN_DURATION := 30.0

# ---- Event Spawn Counts ----
const EVENT_GOLDEN_HORDE_COUNT := 30
const EVENT_ELITE_HORDE_COUNT := 20
const EVENT_MASSIVE_NORMAL_COUNT := 50
const EVENT_MASSIVE_ELITE_COUNT := 10
const EVENT_PORTAL_ENEMY_COUNT := 10
const EVENT_STRONG_MINIBOSS_ESCORTS := 5

# ---- Fever Mode ----
const FEVER_KILL_WINDOW := 5.0       # Janela de tempo para contar kills
const FEVER_KILL_THRESHOLD := 20     # Kills necessarios para ativar
const FEVER_DURATION := 10.0         # Duracao do modo febre
const FEVER_DAMAGE_MULT := 2.0
const FEVER_SPEED_MULT := 1.5
const FEVER_SHAKE_INTERVAL := 2.0
const FEVER_SHAKE_INTENSITY := 0.06

# ---- Eclipse ----
const ECLIPSE_LIGHT_ENERGY := 0.15
const ECLIPSE_DARKEN_COLOR := Color(0.2, 0.2, 0.3)
const ECLIPSE_ENEMY_GLOW := Color(2.0, 2.0, 2.5)
const ECLIPSE_XP_MULT := 1.5

# ---- Meteor Shower ----
const METEOR_COUNT := 15
const METEOR_SPAWN_DURATION := 10.0
const METEOR_DAMAGE := 50
const METEOR_RADIUS := 2.0
const METEOR_OFFSET_RANGE := 12.0
const METEOR_FALL_HEIGHT := 20.0

# ---- Roulette ----
const ROULETTE_SPEED_BOOST := 0.5
const ROULETTE_DAMAGE_BOOST := 0.3
const ROULETTE_HEAL_AMOUNT := 50
const ROULETTE_SLOW_AMOUNT := 0.3
const ROULETTE_SLOW_MIN := 0.5

# ---- Portal Dimensional ----
const PORTAL_DUNGEON_POS := Vector3(500, 0, 500)
const PORTAL_SPAWN_MIN := 8.0
const PORTAL_SPAWN_MAX := 15.0
const PORTAL_REWARD_XP := 50

# ---- Treasure Goblin ----
const GOBLIN_SPEED := 8.0
const GOBLIN_HP := 100
const GOBLIN_XP := 30
const GOBLIN_SCALE := Vector3(1.5, 1.5, 1.5)

# ---- Chest Mimic ----
const MIMIC_HP := 300
const MIMIC_DAMAGE := 30
const MIMIC_XP := 30
const MIMIC_SCALE := Vector3(1.5, 1.5, 1.5)

# ---- Miniboss Strong Multipliers ----
const MINIBOSS_STRONG_HP_MULT := 2.0
const MINIBOSS_STRONG_DMG_MULT := 1.5
const MINIBOSS_STRONG_SPD_MULT := 1.3
const MINIBOSS_STRONG_SCALE := 3.0
const MINIBOSS_NORMAL_SCALE := 2.5
const MINIBOSS_STRONG_XP := 100
const MINIBOSS_NORMAL_XP := 50
const MINIBOSS_ESCORT_HP_MULT := 2.0
const MINIBOSS_ESCORT_DMG_MULT := 1.3
const MINIBOSS_ESCORT_SCALE := Vector3(1.5, 1.5, 1.5)
const MINIBOSS_ESCORT_RADIUS := 5.0

# ---- Camera ----
const CAMERA_SMOOTH_SPEED := 5.0
const CAMERA_LOOK_AHEAD := 0.3

# ==================================================================
# HUD ICON SIZES
# ==================================================================
const HUD_ICON_SIZES = {
	"large": { "panel": Vector2(80, 80), "texture": Vector2(68, 68), "font": 14 },
	"medium": { "panel": Vector2(64, 64), "texture": Vector2(54, 54), "font": 12 },
	"small": { "panel": Vector2(52, 52), "texture": Vector2(44, 44), "font": 10 },
}
const HUD_ICON_LARGE_MAX = 4
const HUD_ICON_MEDIUM_MAX = 6
const HUD_ICON_SEPARATION = 6
const HUD_ICON_MAX_PER_ROW = 9

# ==================================================================
# BOSS PHASE 3 TRANSITION (PRD 36)
# ==================================================================
const BOSS_P3_SLOW_MO_SCALE = 0.15
const BOSS_P3_SLOW_MO_DURATION = 1.3
const BOSS_P3_ZOOM_AMOUNT = 20.0
const BOSS_P3_SHAKE_1 = 0.3
const BOSS_P3_SHAKE_2 = 0.5
const BOSS_P3_SHAKE_3 = 0.7
const BOSS_P3_FLASH_ALPHA = 0.15
const BOSS_P3_PARTICLES_1 = 20
const BOSS_P3_PARTICLES_2 = 30
const BOSS_P3_TITLE_SCALE_OVERSHOOT = 1.3
const BOSS_P3_RUMBLE_WEAK = 1.0
const BOSS_P3_RUMBLE_STRONG = 1.0
const BOSS_P3_RUMBLE_DURATION = 0.4

# ==================================================================
# SYNERGY HUD ICONS (PRD 37)
# ==================================================================
const SYNERGY_ICON_SIZE_LARGE = 48
const SYNERGY_ICON_SIZE_MEDIUM = 40
const SYNERGY_ICON_SIZE_SMALL = 36
const SYNERGY_ICON_LARGE_MAX = 3
const SYNERGY_ICON_MEDIUM_MAX = 6
const SYNERGY_TOOLTIP_WIDTH = 280
const SYNERGY_TOOLTIP_FADE_IN = 0.15
const SYNERGY_TOOLTIP_FADE_OUT = 0.1
const SYNERGY_BANNER_WIDTH = 400
const SYNERGY_BANNER_HEIGHT = 80
const SYNERGY_BANNER_DURATION = 2.5
const SYNERGY_BANNER_SLIDE_TIME = 0.3
const SYNERGY_PROC_FLASH_DURATION = 0.3
const SYNERGY_COOLDOWN_ARC_COLOR = Color(1, 1, 1, 0.4)

# ==================================================================
# AUDIO DUCKING (PRD 38)
# ==================================================================
const DUCK_VOICE_MUSIC_DB = -18.0
const DUCK_VOICE_SFX_DB = -8.0
const DUCK_CINEMATIC_MUSIC_DB = -15.0
const DUCK_CINEMATIC_SFX_DB = -6.0
const DUCK_BOSS_AMBIENT_DB = -10.0
const DUCK_TRANSITION_TIME = 0.3
const DUCK_RESTORE_TIME = 0.5
const AUDIO_BUS_LIMITS = {
	"Combat": 8, "Pickup": 4, "Ambient": 2, "UI_Audio": 2, "Voice": 1
}
const AUDIO_ENEMY_THRESHOLD_LOW = 20
const AUDIO_ENEMY_THRESHOLD_MED = 50
const AUDIO_ENEMY_THRESHOLD_HIGH = 100
const AUDIO_ENEMY_DUCK_LOW = -3.0
const AUDIO_ENEMY_DUCK_MED = -6.0
const AUDIO_ENEMY_DUCK_HIGH = -9.0
const MASTER_COMPRESSOR_THRESHOLD = -6.0
const MASTER_COMPRESSOR_RATIO = 4.0
const MASTER_COMPRESSOR_ATTACK_US = 20000.0
const MASTER_COMPRESSOR_RELEASE_MS = 200.0

# ==================================================================
# ACHIEVEMENT TRACKER HUD (PRD 39)
# ==================================================================
const ACH_TRACKER_MAX_VISIBLE = 3
const ACH_TRACKER_WIDTH = 260
const ACH_TRACKER_ITEM_HEIGHT = 24
const ACH_TRACKER_BAR_WIDTH = 80
const ACH_TRACKER_BAR_HEIGHT = 6
const ACH_TRACKER_UPDATE_INTERVAL = 1.0
const ACH_TRACKER_LERP_SPEED = 4.0
const ACH_ALMOST_THRESHOLD = 0.90
const ACH_ALMOST_NOTIFICATION_DURATION = 2.0
const ACH_TRACKER_BG_ALPHA = 0.6
const ACH_TRACKER_FONT_SIZE_NAME = 11
const ACH_TRACKER_FONT_SIZE_PROGRESS = 10
const ACH_EXPANDED_BG_ALPHA = 0.7

# ==================================================================
# EVOLUTION TREE (PRD 40)
# ==================================================================
const EVO_TREE_CARD_WIDTH = 140
const EVO_TREE_CARD_HEIGHT = 180
const EVO_TREE_COLUMNS = 4
const EVO_TREE_ICON_WEAPON_SIZE = 32
const EVO_TREE_ICON_EVOLUTION_SIZE = 48
const EVO_TREE_DETAIL_WIDTH = 280
const EVO_TREE_AVAILABLE_PULSE_SPEED = 2.0
const EVO_TREE_AVAILABLE_PULSE_ALPHA_MIN = 0.6
const EVO_TREE_AVAILABLE_PULSE_ALPHA_MAX = 1.0
const EVO_AVAILABLE_NOTIFICATION_DURATION = 3.0

# ==================================================================
# BESTIARY MILESTONES (PRD 41)
# ==================================================================
const BESTIARY_MILESTONE_KILLS = [10, 50, 100, 500, 1000]
const BESTIARY_MILESTONE_CRYSTALS = [5, 15, 30, 75, 150]
const BESTIARY_MILESTONE_LABELS = ["Identificado", "Estudado", "Compreendido", "Dominado", "Exterminado"]
const BESTIARY_CARD_SIZE = Vector2(130, 160)
const BESTIARY_CARD_EXPANDED_WIDTH = 380
const BESTIARY_SPRITE_SIZE = 64
const BESTIARY_NOTIFICATION_DURATION = 2.5
const BESTIARY_STAR_SIZE = 12

# ==================================================================
# BOSS DIALOGUE SYSTEM (PRD 42)
# ==================================================================
const BOSS_DIALOGUE_COMBAT_INTERVAL_MIN = 20.0
const BOSS_DIALOGUE_COMBAT_INTERVAL_MAX = 30.0
const BOSS_DIALOGUE_INTRO_DURATION = 4.0
const BOSS_DIALOGUE_COMBAT_DURATION = 3.0
const BOSS_DIALOGUE_PHASE_DURATION = 5.0
const BOSS_DIALOGUE_DEATH_DURATION = 6.0
const BOSS_DIALOGUE_MAX_VARIANTS = 3

# ==================================================================
# BOSS KILL FREEZE (PRD 44)
# ==================================================================
const BOSS_KILL_FREEZE_DURATION := 0.07   # Segundos reais de pausa total (~4 frames a 60fps)
const BOSS_KILL_FLASH_ALPHA := 0.55       # Opacidade do flash branco no kill
const BOSS_KILL_SHAKE_AMOUNT := 18.0      # Intensidade do screen shake pos-freeze

# ==================================================================
# RAGDOLL DEATH (PRD 45)
# ==================================================================
const RAGDOLL_DURATION := 0.35            # Duracao total da animacao (s)
const RAGDOLL_FLY_MIN := 0.4              # Distancia minima de voo (unidades 3D)
const RAGDOLL_FLY_MAX := 1.2              # Distancia maxima de voo
const RAGDOLL_SPIN_MIN := 1.2             # Rotacao minima em radianos (~70 graus)
const RAGDOLL_SPIN_MAX := 3.5             # Rotacao maxima em radianos (~200 graus)
const RAGDOLL_BOSS_SCALE := 1.5           # Multiplica fly_dist e spin para bosses

# ==================================================================
# MYSTERY TEASER (PRD 46)
# ==================================================================
const TEASER_GLOW_COLOR := Color(0.35, 0.15, 0.6)    # Roxo cristal de Zion
const TEASER_GLOW_MAX_ALPHA := 0.18                   # Brilho maximo do pulso (sutil)
const TEASER_PULSE_IN := 1.2                           # Segundos para atingir maximo
const TEASER_PULSE_OUT := 1.8                          # Segundos para voltar a 0
const TEASER_GLITCH_MIN_WAIT := 2.0                    # Minimo entre glitches (s)
const TEASER_GLITCH_MAX_WAIT := 5.0                    # Maximo entre glitches (s)
const TEASER_GLITCH_DURATION := 0.05                   # Duracao do glitch (~3 frames)
