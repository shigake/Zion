extends Node

## Sistema de localização PT-BR / EN.
## Uso: LocaleManager.tr_key("key") retorna o texto traduzido.
## Regra de capitalização: Primeira letra maiúscula, resto minúsculo (sentence case).

signal locale_changed(new_locale: String)

var current_locale: String = "pt"

var translations: Dictionary = {
	# ---- Menu principal ----
	"menu_play": {"pt": "Jogar", "en": "Play"},
	"menu_multiplayer": {"pt": "Multiplayer", "en": "Multiplayer"},
	"menu_shop": {"pt": "Loja", "en": "Shop"},
	"menu_leaderboard": {"pt": "Leaderboard", "en": "Leaderboard"},
	"menu_options": {"pt": "Opções", "en": "Options"},
	"menu_quit": {"pt": "Sair", "en": "Quit"},
	"bestiary": {"pt": "Bestiario", "en": "Bestiary"},
	"codex": {"pt": "Codex de armas", "en": "Weapon codex"},
	"new_game_plus": {"pt": "New game+", "en": "New game+"},
	"crystals": {"pt": "Cristais: %d", "en": "Crystals: %d"},
	"menu_play_solo": {"pt": "Jogar solo", "en": "Play solo"},

	# ---- HUD ----
	"kills": {"pt": "Kills: %d | Cristais: %d", "en": "Kills: %d | Crystals: %d"},
	"level": {"pt": "Lv. %d", "en": "Lv. %d"},
	"dash_label": {"pt": "[SPACE] Dash", "en": "[SPACE] Dash"},
	"achievement_label": {"pt": "Conquista: %s", "en": "Achievement: %s"},

	# ---- Level up ----
	"level_up_title": {"pt": "Level up! (Lv. %d)", "en": "Level up! (Lv. %d)"},
	"reroll": {"pt": "Reroll (%d)", "en": "Reroll (%d)"},
	"banish": {"pt": "Banish (%d)", "en": "Banish (%d)"},
	"banish_select": {"pt": "Banish: escolha uma opção para remover", "en": "Banish: choose an option to remove"},
	"new": {"pt": "Novo!", "en": "New!"},

	# ---- Pause ----
	"paused": {"pt": "Pausado", "en": "Paused"},
	"resume": {"pt": "Continuar", "en": "Resume"},
	"quit_to_menu": {"pt": "Sair pro menu", "en": "Quit to menu"},
	"quit_game": {"pt": "Sair do jogo", "en": "Quit game"},
	"options": {"pt": "Opções", "en": "Options"},
	"close": {"pt": "Fechar", "en": "Close"},
	"keybindings": {"pt": "Controles", "en": "Controls"},

	# ---- Game over ----
	"game_over": {"pt": "Fim de jogo", "en": "Game over"},
	"victory_time": {"pt": "Vitória! Tempo: %s", "en": "Victory! Time: %s"},
	"time": {"pt": "Tempo: %s", "en": "Time: %s"},
	"kills_stat": {"pt": "Kills: %d", "en": "Kills: %d"},
	"level_stat": {"pt": "Level: %d", "en": "Level: %d"},
	"crystals_earned": {"pt": "Cristais ganhos: +%d", "en": "Crystals earned: +%d"},
	"retry": {"pt": "Tentar de novo", "en": "Retry"},
	"back_to_menu": {"pt": "Voltar ao menu", "en": "Back to menu"},
	"stage_complete": {"pt": "Fase %s completa!", "en": "Stage %s complete!"},
	"total_damage": {"pt": "Dano total: %d", "en": "Total damage: %d"},
	"unlocked": {"pt": "Desbloqueado: %s!", "en": "Unlocked: %s!"},
	"leaderboard_rank": {"pt": "Leaderboard: #%d!", "en": "Leaderboard: #%d!"},

	# ---- Character select ----
	"select_character": {"pt": "Selecione o personagem", "en": "Select character"},
	"locked": {"pt": "Bloqueado", "en": "Locked"},
	"start": {"pt": "Iniciar", "en": "Start"},
	"back": {"pt": "Voltar", "en": "Back"},

	# ---- Stage select ----
	"select_stage": {"pt": "Selecione a fase", "en": "Select stage"},
	"next": {"pt": "Próximo", "en": "Next"},

	# ---- Relic select ----
	"select_relic": {"pt": "Escolha uma relíquia", "en": "Choose a relic"},
	"skip_relic": {"pt": "Pular", "en": "Skip"},

	# ---- Shop ----
	"shop_title": {"pt": "Loja", "en": "Shop"},
	"buy": {"pt": "Comprar (%d)", "en": "Buy (%d)"},
	"max_level": {"pt": "Max", "en": "Max"},

	# ---- Events (gameplay) ----
	"event_golden_horde": {"pt": "Horda dourada!", "en": "Golden horde!"},
	"event_treasure_goblin": {"pt": "Treasure goblin!", "en": "Treasure goblin!"},
	"event_merchant": {"pt": "Mercador apareceu!", "en": "Merchant appeared!"},
	"event_roulette": {"pt": "Roda da fortuna!", "en": "Wheel of fortune!"},
	"event_eclipse": {"pt": "Eclipse!", "en": "Eclipse!"},
	"event_meteor_shower": {"pt": "Chuva de meteoros!", "en": "Meteor shower!"},
	"event_angel_challenge": {"pt": "Desafio do anjo!", "en": "Angel challenge!"},
	"event_portal_dimensional": {"pt": "Portal dimensional!", "en": "Dimensional portal!"},
	"event_chest_mimic": {"pt": "Baú mimic!", "en": "Mimic chest!"},
	"event_fever_mode": {"pt": "Fever mode!", "en": "Fever mode!"},

	# ---- Tutorial ----
	"tutorial_move": {"pt": "WASD para mover, SPACE para dash", "en": "WASD to move, SPACE to dash"},
	"tutorial_xp": {"pt": "Inimigos dropam XP! Colete para subir de nível", "en": "Enemies drop XP! Collect to level up"},
	"tutorial_levelup": {"pt": "Escolha um upgrade! Armas ou itens passivos", "en": "Choose an upgrade! Weapons or passive items"},
	"tutorial_events": {"pt": "Eventos especiais acontecem durante a run!", "en": "Special events occur during the run!"},
	"tutorial_evolution": {"pt": "Arma max + Item max = Evolução! Aperte E", "en": "Max weapon + Max item = Evolution! Press E"},
	"tutorial_dash": {"pt": "Dash te deixa invulnerável! Use para esquivar", "en": "Dash makes you invulnerable! Use it to dodge"},
	"tutorial_shop": {"pt": "Gaste cristais na loja para upgrades permanentes!", "en": "Spend crystals in the shop for permanent upgrades!"},
	"tutorial_crystals": {"pt": "Cristais dropam dos inimigos. Gaste na loja entre runs!", "en": "Crystals drop from enemies. Spend them in the shop between runs!"},
	"tutorial_synergy": {"pt": "2 armas do mesmo elemento = sinergia bônus!", "en": "2 weapons of the same element = bonus synergy!"},

	# ---- Options ----
	"volume_master": {"pt": "Volume master", "en": "Master volume"},
	"volume_music": {"pt": "Volume música", "en": "Music volume"},
	"volume_sfx": {"pt": "Volume efeitos", "en": "SFX volume"},
	"fullscreen": {"pt": "Tela cheia", "en": "Fullscreen"},
	"window_mode": {"pt": "Modo janela", "en": "Window mode"},
	"window_windowed": {"pt": "Janela", "en": "Windowed"},
	"window_fullscreen": {"pt": "Tela cheia", "en": "Fullscreen"},
	"window_borderless": {"pt": "Borderless", "en": "Borderless"},
	"resolution": {"pt": "Resolução", "en": "Resolution"},
	"language": {"pt": "Idioma", "en": "Language"},
	"telemetry_toggle": {"pt": "Enviar dados anônimos", "en": "Send anonymous data"},
	"reset_keybindings": {"pt": "Resetar controles", "en": "Reset controls"},
	"controls_title": {"pt": "Controles", "en": "Controls"},

	# ---- Merchant ----
	"merchant_title": {"pt": "Mercador - compre com cristais", "en": "Merchant - buy with crystals"},
	"merchant_bought": {"pt": "Comprado!", "en": "Bought!"},
	"merchant_close": {"pt": "Fechar", "en": "Close"},

	# ---- Leaderboard ----
	"leaderboard_title": {"pt": "Leaderboard - modo endless", "en": "Leaderboard - endless mode"},
	"leaderboard_empty": {"pt": "Nenhuma run registrada ainda!", "en": "No runs recorded yet!"},
	"leaderboard_header": {"pt": "  #   | Tempo      | Kills  | Personagem | Data", "en": "  #   | Time       | Kills  | Character  | Date"},

	# ---- Lobby ----
	"lobby_server_created": {"pt": "Servidor criado! Aguardando jogadores...", "en": "Server created! Waiting for players..."},
	"lobby_server_error": {"pt": "Erro ao criar servidor!", "en": "Error creating server!"},
	"lobby_connecting": {"pt": "Conectando a %s...", "en": "Connecting to %s..."},
	"lobby_connect_error": {"pt": "Erro ao conectar!", "en": "Error connecting!"},
	"lobby_connected": {"pt": "Conectado! Aguardando host iniciar...", "en": "Connected! Waiting for host to start..."},
	"lobby_failed": {"pt": "Falha na conexão!", "en": "Connection failed!"},
	"lobby_players": {"pt": "%d/%d jogadores", "en": "%d/%d players"},
	"lobby_you": {"pt": "(Você)", "en": "(You)"},

	# ---- Keybinding display names ----
	"action_move_up": {"pt": "Mover cima", "en": "Move up"},
	"action_move_down": {"pt": "Mover baixo", "en": "Move down"},
	"action_move_left": {"pt": "Mover esquerda", "en": "Move left"},
	"action_move_right": {"pt": "Mover direita", "en": "Move right"},
	"action_dash": {"pt": "Dash", "en": "Dash"},
	"action_interact": {"pt": "Interagir", "en": "Interact"},
	"action_pause": {"pt": "Pausar", "en": "Pause"},

	# ---- Stage names ----
	"stage_cemetery": {"pt": "Cemitério", "en": "Cemetery"},
	"stage_forest": {"pt": "Floresta", "en": "Forest"},
	"stage_farm": {"pt": "Fazenda", "en": "Farm"},
	"stage_tokyo": {"pt": "Tóquio", "en": "Tokyo"},
	"stage_volcano": {"pt": "Vulcão", "en": "Volcano"},
	"stage_ocean": {"pt": "Oceano", "en": "Ocean"},
	"stage_arena": {"pt": "Arena", "en": "Arena"},
	"stage_space": {"pt": "Espaço", "en": "Space"},
	"stage_castle": {"pt": "Castelo", "en": "Castle"},
	"stage_candy": {"pt": "Mundo doce", "en": "Candy world"},

	# ---- Stage descriptions ----
	"stage_cemetery_desc": {"pt": "Um cemitério sombrio cheio de mortos-vivos.", "en": "A dark cemetery full of undead."},
	"stage_forest_desc": {"pt": "Floresta mágica com cogumelos e fadas.", "en": "Magical forest with mushrooms and fairies."},
	"stage_farm_desc": {"pt": "Fazenda destruída com vacas zumbis.", "en": "Destroyed farm with zombie cows."},
	"stage_tokyo_desc": {"pt": "Cidade cyberpunk com robôs e neon.", "en": "Cyberpunk city with robots and neon."},
	"stage_volcano_desc": {"pt": "Cavernas de lava com demônios.", "en": "Lava caverns with demons."},
	"stage_ocean_desc": {"pt": "Ruínas submarinas com tubarões zumbis.", "en": "Underwater ruins with zombie sharks."},
	"stage_arena_desc": {"pt": "Coliseu gladiador com leões e centuriões.", "en": "Gladiator coliseum with lions and centurions."},
	"stage_space_desc": {"pt": "Estação espacial com aliens e parasitas.", "en": "Space station with aliens and parasites."},
	"stage_castle_desc": {"pt": "Castelo gótico com vampiros e gárgulas.", "en": "Gothic castle with vampires and gargoyles."},
	"stage_candy_desc": {"pt": "Terra de doces com gummy bears.", "en": "Candy land with gummy bears."},

	# ---- Game modes ----
	"mode_normal": {"pt": "Normal", "en": "Normal"},
	"mode_endless": {"pt": "Endless", "en": "Endless"},
	"mode_boss_rush": {"pt": "Boss rush", "en": "Boss rush"},
	"mode_hyper": {"pt": "Hyper", "en": "Hyper"},
	"mode_normal_desc": {"pt": "Modo normal — 30 min, boss no final", "en": "Normal mode — 30 min, boss at the end"},
	"mode_endless_desc": {"pt": "Modo endless — sem limite, sobreviva o máximo", "en": "Endless mode — no limit, survive as long as you can"},
	"mode_boss_rush_desc": {"pt": "Boss rush — 10 bosses em sequência!", "en": "Boss rush — 10 bosses in sequence!"},
	"mode_hyper_desc": {"pt": "Modo hyper — 2x velocidade, 2x spawns, 2x rewards", "en": "Hyper mode — 2x speed, 2x spawns, 2x rewards"},

	# ---- Relic ----
	"no_relic": {"pt": "Nenhuma", "en": "None"},
	"no_relic_desc": {"pt": "Sem bônus", "en": "No bonus"},

	# ---- Aliases ----
	"play": {"pt": "Jogar", "en": "Play"},
	"shop": {"pt": "Loja", "en": "Shop"},
	"quit": {"pt": "Sair", "en": "Quit"},
	"leaderboard": {"pt": "Leaderboard", "en": "Leaderboard"},
	"multiplayer": {"pt": "Multiplayer", "en": "Multiplayer"},
	"choose_character": {"pt": "Selecione o personagem", "en": "Choose character"},
	"choose_stage": {"pt": "Selecione a fase", "en": "Choose stage"},
	"choose_relic": {"pt": "Escolha uma relíquia", "en": "Choose a relic"},
	"normal": {"pt": "Normal", "en": "Normal"},
	"endless": {"pt": "Endless", "en": "Endless"},
	"boss_rush": {"pt": "Boss rush", "en": "Boss rush"},
	"hyper": {"pt": "Hyper", "en": "Hyper"},
	"dash_ready": {"pt": "Dash pronto", "en": "Dash ready"},
	"dash_cooldown": {"pt": "Dash em cooldown", "en": "Dash cooldown"},
	"level_up": {"pt": "Level up!", "en": "Level up!"},
	"victory": {"pt": "Vitória!", "en": "Victory!"},
	"kills_label": {"pt": "Kills", "en": "Kills"},
	"level_label": {"pt": "Level", "en": "Level"},
	"damage_dealt": {"pt": "Dano causado: %d", "en": "Damage dealt: %d"},
	"menu": {"pt": "Menu", "en": "Menu"},
	"crystals_label": {"pt": "Cristais", "en": "Crystals"},
}

func _ready() -> void:
	# Carrega idioma salvo
	var saved_locale = SaveManager.data.get("locale", "pt")
	current_locale = saved_locale

func tr_key(key: String) -> String:
	if key in translations:
		return translations[key].get(current_locale, translations[key].get("pt", key))
	return key

## Converte texto para sentence case: primeira letra maiúscula, resto minúsculo.
## Preserva formatação especial como %d, %s, Lv., etc.
static func to_sentence_case(text: String) -> String:
	if text.is_empty():
		return text
	return text[0].to_upper() + text.substr(1)

func set_locale(locale: String) -> void:
	current_locale = locale
	SaveManager.data["locale"] = locale
	SaveManager.save_game()
	locale_changed.emit(locale)

func get_locale() -> String:
	return current_locale

func get_available_locales() -> Array:
	return ["pt", "en"]

func get_locale_name(locale: String) -> String:
	match locale:
		"pt": return "Português (BR)"
		"en": return "English"
	return locale
