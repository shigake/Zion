extends Node

## Sistema de localizacao PT-BR / EN.
## Uso: LocaleManager.tr("key") retorna o texto traduzido.

signal locale_changed(new_locale: String)

var current_locale: String = "pt"

var translations: Dictionary = {
	# ---- Menu Principal ----
	"menu_play": {"pt": "Jogar", "en": "Play"},
	"menu_multiplayer": {"pt": "Multiplayer", "en": "Multiplayer"},
	"menu_shop": {"pt": "Loja", "en": "Shop"},
	"menu_leaderboard": {"pt": "Leaderboard", "en": "Leaderboard"},
	"menu_options": {"pt": "Opcoes", "en": "Options"},
	"menu_quit": {"pt": "Sair", "en": "Quit"},
	"crystals": {"pt": "Cristais: %d", "en": "Crystals: %d"},

	# ---- HUD ----
	"kills": {"pt": "Kills: %d | Cristais: %d", "en": "Kills: %d | Crystals: %d"},
	"level": {"pt": "Lv. %d", "en": "Lv. %d"},

	# ---- Level Up ----
	"level_up_title": {"pt": "LEVEL UP! (Lv. %d)", "en": "LEVEL UP! (Lv. %d)"},
	"reroll": {"pt": "Reroll (%d)", "en": "Reroll (%d)"},
	"banish": {"pt": "Banish (%d)", "en": "Banish (%d)"},
	"banish_select": {"pt": "BANISH: Escolha uma opcao para remover", "en": "BANISH: Choose an option to remove"},
	"new": {"pt": "NOVO!", "en": "NEW!"},

	# ---- Pause ----
	"paused": {"pt": "PAUSADO", "en": "PAUSED"},
	"resume": {"pt": "Continuar", "en": "Resume"},
	"quit_to_menu": {"pt": "Sair pro Menu", "en": "Quit to Menu"},
	"options": {"pt": "Opcoes", "en": "Options"},
	"keybindings": {"pt": "Keybindings", "en": "Key Bindings"},

	# ---- Game Over ----
	"game_over": {"pt": "FIM DE JOGO", "en": "GAME OVER"},
	"time": {"pt": "Tempo: %s", "en": "Time: %s"},
	"kills_stat": {"pt": "Kills: %d", "en": "Kills: %d"},
	"level_stat": {"pt": "Level: %d", "en": "Level: %d"},
	"crystals_earned": {"pt": "Cristais ganhos: +%d", "en": "Crystals earned: +%d"},
	"retry": {"pt": "Tentar de Novo", "en": "Retry"},
	"back_to_menu": {"pt": "Voltar ao Menu", "en": "Back to Menu"},

	# ---- Character Select ----
	"select_character": {"pt": "Selecione o Personagem", "en": "Select Character"},
	"locked": {"pt": "BLOQUEADO", "en": "LOCKED"},
	"start": {"pt": "Iniciar", "en": "Start"},
	"back": {"pt": "Voltar", "en": "Back"},

	# ---- Stage Select ----
	"select_stage": {"pt": "Selecione a Fase", "en": "Select Stage"},
	"next": {"pt": "Proximo", "en": "Next"},

	# ---- Relic Select ----
	"select_relic": {"pt": "Escolha uma Reliquia", "en": "Choose a Relic"},
	"skip_relic": {"pt": "Pular", "en": "Skip"},

	# ---- Shop ----
	"shop_title": {"pt": "LOJA", "en": "SHOP"},
	"buy": {"pt": "Comprar", "en": "Buy"},
	"max_level": {"pt": "MAX", "en": "MAX"},

	# ---- Events ----
	"event_golden_horde": {"pt": "HORDA DOURADA!", "en": "GOLDEN HORDE!"},
	"event_treasure_goblin": {"pt": "TREASURE GOBLIN!", "en": "TREASURE GOBLIN!"},
	"event_merchant": {"pt": "MERCADOR APARECEU!", "en": "MERCHANT APPEARED!"},
	"event_roulette": {"pt": "RODA DA FORTUNA!", "en": "WHEEL OF FORTUNE!"},
	"event_eclipse": {"pt": "ECLIPSE!", "en": "ECLIPSE!"},
	"event_meteor_shower": {"pt": "CHUVA DE METEOROS!", "en": "METEOR SHOWER!"},
	"event_angel_challenge": {"pt": "DESAFIO DO ANJO!", "en": "ANGEL CHALLENGE!"},
	"event_portal_dimensional": {"pt": "PORTAL DIMENSIONAL!", "en": "DIMENSIONAL PORTAL!"},
	"event_chest_mimic": {"pt": "BAU MIMIC!", "en": "MIMIC CHEST!"},
	"event_fever_mode": {"pt": "FEVER MODE!", "en": "FEVER MODE!"},

	# ---- Tutorial ----
	"tutorial_move": {"pt": "WASD para mover, SPACE para dash", "en": "WASD to move, SPACE to dash"},
	"tutorial_xp": {"pt": "Inimigos dropam XP! Colete para subir de nivel", "en": "Enemies drop XP! Collect to level up"},
	"tutorial_levelup": {"pt": "Escolha um upgrade! Armas ou itens passivos", "en": "Choose an upgrade! Weapons or passive items"},
	"tutorial_events": {"pt": "Eventos especiais acontecem durante a run!", "en": "Special events occur during the run!"},
	"tutorial_evolution": {"pt": "Arma max + Item max = Evolucao! Aperte E", "en": "Max weapon + Max item = Evolution! Press E"},
	"tutorial_dash": {"pt": "Use o dash para esquivar de inimigos!", "en": "Use dash to dodge enemies!"},
	"tutorial_shop": {"pt": "Gaste cristais na loja para upgrades permanentes!", "en": "Spend crystals in the shop for permanent upgrades!"},

	# ---- Options ----
	"volume_master": {"pt": "Volume Master", "en": "Master Volume"},
	"volume_music": {"pt": "Volume Musica", "en": "Music Volume"},
	"volume_sfx": {"pt": "Volume Efeitos", "en": "SFX Volume"},
	"fullscreen": {"pt": "Tela Cheia", "en": "Fullscreen"},
	"language": {"pt": "Idioma", "en": "Language"},
	"reset_keybindings": {"pt": "Resetar Controles", "en": "Reset Controls"},

	# ---- Merchant ----
	"merchant_title": {"pt": "MERCADOR - Compre com Cristais", "en": "MERCHANT - Buy with Crystals"},
	"merchant_bought": {"pt": "COMPRADO!", "en": "BOUGHT!"},
	"merchant_close": {"pt": "Fechar", "en": "Close"},

	# ---- Leaderboard ----
	"leaderboard_title": {"pt": "LEADERBOARD - Modo Endless", "en": "LEADERBOARD - Endless Mode"},
	"leaderboard_empty": {"pt": "Nenhuma run registrada ainda!", "en": "No runs recorded yet!"},
	"leaderboard_header": {"pt": "  #   | Tempo      | Kills  | Personagem | Data", "en": "  #   | Time       | Kills  | Character  | Date"},

	# ---- Unlocks ----
	"unlocked": {"pt": "DESBLOQUEADO: %s!", "en": "UNLOCKED: %s!"},
}

func _ready() -> void:
	# Carrega idioma salvo
	var saved_locale = SaveManager.data.get("locale", "pt")
	current_locale = saved_locale

func tr_key(key: String) -> String:
	if key in translations:
		return translations[key].get(current_locale, translations[key].get("pt", key))
	return key

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
		"pt": return "Portugues (BR)"
		"en": return "English"
	return locale
