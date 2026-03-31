extends Node

## Sistema de localização PT-BR / EN.
## Uso: LocaleManager.tr_key("key") retorna o texto traduzido.
## Regra de capitalização: Primeira letra maiúscula, resto minúsculo (sentence case).

signal locale_changed(new_locale: String)

var current_locale: String = "pt"
const AVAILABLE_LOCALES := ["pt", "en", "es", "fr", "de", "ja", "zh", "ko", "it", "ru"]
const LOCALE_NAMES := {
	"pt": "Português", "en": "English", "es": "Español", "fr": "Français",
	"de": "Deutsch", "ja": "日本語", "zh": "中文", "ko": "한국어",
	"it": "Italiano", "ru": "Русский",
}

var translations: Dictionary = {
	# ---- Menu principal ----
	"menu_play": {"pt": "Jogar", "en": "Play", "es": "Jugar", "fr": "Jouer", "de": "Spielen", "ja": "プレイ", "zh": "开始游戏", "ko": "플레이", "it": "Gioca", "ru": "Играть"},
	"menu_multiplayer": {"pt": "Multiplayer", "en": "Multiplayer", "es": "Multijugador", "fr": "Multijoueur", "de": "Mehrspieler", "ja": "マルチプレイ", "zh": "多人游戏", "ko": "멀티플레이", "it": "Multigiocatore", "ru": "Мультиплеер"},
	"menu_shop": {"pt": "Loja", "en": "Shop", "es": "Tienda", "fr": "Boutique", "de": "Laden", "ja": "ショップ", "zh": "商店", "ko": "상점", "it": "Negozio", "ru": "Магазин"},
	"menu_leaderboard": {"pt": "Leaderboard", "en": "Leaderboard", "es": "Clasificación", "fr": "Classement", "de": "Rangliste", "ja": "ランキング", "zh": "排行榜", "ko": "리더보드", "it": "Classifica", "ru": "Рейтинг"},
	"menu_options": {"pt": "Opções", "en": "Options", "es": "Opciones", "fr": "Options", "de": "Optionen", "ja": "設定", "zh": "选项", "ko": "설정", "it": "Opzioni", "ru": "Настройки"},
	"menu_quit": {"pt": "Sair", "en": "Quit", "es": "Salir", "fr": "Quitter", "de": "Beenden", "ja": "終了", "zh": "退出", "ko": "종료", "it": "Esci", "ru": "Выход"},
	"bestiary": {"pt": "Bestiario", "en": "Bestiary", "es": "Bestiario", "fr": "Bestiaire", "de": "Bestiarium", "ja": "図鑑", "zh": "怪物图鉴", "ko": "도감", "it": "Bestiario", "ru": "Бестиарий"},
	"codex": {"pt": "Codex de armas", "en": "Weapon codex", "es": "Códice de armas", "fr": "Codex d'armes", "de": "Waffenkodex", "ja": "武器図鑑", "zh": "武器图鉴", "ko": "무기 도감", "it": "Codice armi", "ru": "Кодекс оружия"},
	"new_game_plus": {"pt": "New game+", "en": "New game+", "es": "Nueva partida+", "fr": "Nouvelle partie+", "de": "Neues Spiel+", "ja": "ニューゲーム+", "zh": "新游戏+", "ko": "뉴 게임+", "it": "Nuova partita+", "ru": "Новая игра+"},
	"crystals": {"pt": "Cristais: %d", "en": "Crystals: %d", "es": "Cristales: %d", "fr": "Cristaux: %d", "de": "Kristalle: %d", "ja": "クリスタル: %d", "zh": "水晶: %d", "ko": "크리스탈: %d", "it": "Cristalli: %d", "ru": "Кристаллы: %d"},
	"menu_play_solo": {"pt": "Jogar solo", "en": "Play solo", "es": "Jugar solo", "fr": "Jouer solo", "de": "Solo spielen", "ja": "ソロプレイ", "zh": "单人游戏", "ko": "솔로 플레이", "it": "Gioca solo", "ru": "Одиночная"},

	# ---- HUD ----
	"kills": {"pt": "Kills: %d | Cristais: %d", "en": "Kills: %d | Crystals: %d", "es": "Muertes: %d | Cristales: %d", "fr": "Kills: %d | Cristaux: %d", "de": "Kills: %d | Kristalle: %d", "ja": "キル: %d | クリスタル: %d", "zh": "击杀: %d | 水晶: %d", "ko": "킬: %d | 크리스탈: %d", "it": "Uccisioni: %d | Cristalli: %d", "ru": "Убийства: %d | Кристаллы: %d"},
	"level": {"pt": "Lv. %d", "en": "Lv. %d", "es": "Nv. %d", "fr": "Nv. %d", "de": "Lv. %d", "ja": "Lv. %d", "zh": "等级 %d", "ko": "Lv. %d", "it": "Lv. %d", "ru": "Ур. %d"},
	"dash_label": {"pt": "[SPACE] Dash", "en": "[SPACE] Dash", "es": "[SPACE] Dash", "fr": "[ESPACE] Dash", "de": "[LEERTASTE] Dash", "ja": "[SPACE] ダッシュ", "zh": "[空格] 冲刺", "ko": "[SPACE] 대시", "it": "[SPAZIO] Scatto", "ru": "[ПРОБЕЛ] Рывок"},
	"achievement_label": {"pt": "Conquista: %s", "en": "Achievement: %s", "es": "Logro: %s", "fr": "Succès: %s", "de": "Erfolg: %s", "ja": "実績: %s", "zh": "成就: %s", "ko": "업적: %s", "it": "Obiettivo: %s", "ru": "Достижение: %s"},

	# ---- Level up ----
	"level_up_title": {"pt": "Level up! (Lv. %d)", "en": "Level up! (Lv. %d)", "es": "¡Subida de nivel! (Nv. %d)", "fr": "Niveau supérieur! (Nv. %d)", "de": "Level Up! (Lv. %d)", "ja": "レベルアップ！(Lv. %d)", "zh": "升级！(等级 %d)", "ko": "레벨 업! (Lv. %d)", "it": "Livello su! (Lv. %d)", "ru": "Уровень повышен! (Ур. %d)"},
	"reroll": {"pt": "Reroll (%d)", "en": "Reroll (%d)", "es": "Relanzar (%d)", "fr": "Relancer (%d)", "de": "Neu würfeln (%d)", "ja": "リロール (%d)", "zh": "重投 (%d)", "ko": "리롤 (%d)", "it": "Rilancia (%d)", "ru": "Перебросить (%d)"},
	"banish": {"pt": "Banish (%d)", "en": "Banish (%d)", "es": "Desterrar (%d)", "fr": "Bannir (%d)", "de": "Verbannen (%d)", "ja": "除外 (%d)", "zh": "放逐 (%d)", "ko": "추방 (%d)", "it": "Esilia (%d)", "ru": "Изгнать (%d)"},
	"banish_select": {"pt": "Banish: escolha uma opção para remover", "en": "Banish: choose an option to remove", "es": "Desterrar: elige una opción para eliminar", "fr": "Bannir: choisissez une option à supprimer", "de": "Verbannen: wähle eine Option zum Entfernen", "ja": "除外: 削除するオプションを選択", "zh": "放逐: 选择一个选项移除", "ko": "추방: 제거할 옵션을 선택하세요", "it": "Esilia: scegli un'opzione da rimuovere", "ru": "Изгнание: выберите вариант для удаления"},
	"new": {"pt": "Novo!", "en": "New!", "es": "¡Nuevo!", "fr": "Nouveau!", "de": "Neu!", "ja": "新規!", "zh": "新!", "ko": "신규!", "it": "Nuovo!", "ru": "Новый!"},

	# ---- Pause ----
	"paused": {"pt": "Pausado", "en": "Paused", "es": "Pausado", "fr": "Pause", "de": "Pausiert", "ja": "一時停止", "zh": "暂停", "ko": "일시정지", "it": "In pausa", "ru": "Пауза"},
	"resume": {"pt": "Continuar", "en": "Resume", "es": "Continuar", "fr": "Reprendre", "de": "Fortsetzen", "ja": "再開", "zh": "继续", "ko": "계속", "it": "Riprendi", "ru": "Продолжить"},
	"quit_to_menu": {"pt": "Sair pro menu", "en": "Quit to menu", "es": "Volver al menú", "fr": "Retour au menu", "de": "Zum Menü", "ja": "メニューに戻る", "zh": "返回菜单", "ko": "메뉴로", "it": "Torna al menu", "ru": "В меню"},
	"quit_game": {"pt": "Sair do jogo", "en": "Quit game", "es": "Salir del juego", "fr": "Quitter le jeu", "de": "Spiel beenden", "ja": "ゲーム終了", "zh": "退出游戏", "ko": "게임 종료", "it": "Esci dal gioco", "ru": "Выйти из игры"},
	"options": {"pt": "Opções", "en": "Options", "es": "Opciones", "fr": "Options", "de": "Optionen", "ja": "設定", "zh": "选项", "ko": "설정", "it": "Opzioni", "ru": "Настройки"},
	"close": {"pt": "Fechar", "en": "Close", "es": "Cerrar", "fr": "Fermer", "de": "Schließen", "ja": "閉じる", "zh": "关闭", "ko": "닫기", "it": "Chiudi", "ru": "Закрыть"},
	"keybindings": {"pt": "Controles", "en": "Controls", "es": "Controles", "fr": "Contrôles", "de": "Steuerung", "ja": "操作設定", "zh": "按键设置", "ko": "조작", "it": "Comandi", "ru": "Управление"},

	# ---- Game over ----
	"game_over": {"pt": "Fim de jogo", "en": "Game over", "es": "Fin del juego", "fr": "Fin de partie", "de": "Spielende", "ja": "ゲームオーバー", "zh": "游戏结束", "ko": "게임 오버", "it": "Fine partita", "ru": "Конец игры"},
	"victory_time": {"pt": "Vitória! Tempo: %s", "en": "Victory! Time: %s", "es": "¡Victoria! Tiempo: %s", "fr": "Victoire! Temps: %s", "de": "Sieg! Zeit: %s", "ja": "勝利！時間: %s", "zh": "胜利！时间: %s", "ko": "승리! 시간: %s", "it": "Vittoria! Tempo: %s", "ru": "Победа! Время: %s"},
	"time": {"pt": "Tempo: %s", "en": "Time: %s", "es": "Tiempo: %s", "fr": "Temps: %s", "de": "Zeit: %s", "ja": "時間: %s", "zh": "时间: %s", "ko": "시간: %s", "it": "Tempo: %s", "ru": "Время: %s"},
	"kills_stat": {"pt": "Kills: %d", "en": "Kills: %d", "es": "Muertes: %d", "fr": "Kills: %d", "de": "Kills: %d", "ja": "キル: %d", "zh": "击杀: %d", "ko": "킬: %d", "it": "Uccisioni: %d", "ru": "Убийств: %d"},
	"level_stat": {"pt": "Level: %d", "en": "Level: %d", "es": "Nivel: %d", "fr": "Niveau: %d", "de": "Level: %d", "ja": "レベル: %d", "zh": "等级: %d", "ko": "레벨: %d", "it": "Livello: %d", "ru": "Уровень: %d"},
	"crystals_earned": {"pt": "Cristais ganhos: +%d", "en": "Crystals earned: +%d", "es": "Cristales ganados: +%d", "fr": "Cristaux gagnés: +%d", "de": "Kristalle verdient: +%d", "ja": "獲得クリスタル: +%d", "zh": "获得水晶: +%d", "ko": "획득 크리스탈: +%d", "it": "Cristalli guadagnati: +%d", "ru": "Кристаллов получено: +%d"},
	"retry": {"pt": "Tentar de novo", "en": "Retry", "es": "Reintentar", "fr": "Réessayer", "de": "Erneut versuchen", "ja": "リトライ", "zh": "重试", "ko": "재시도", "it": "Riprova", "ru": "Повторить"},
	"back_to_menu": {"pt": "Voltar ao menu", "en": "Back to menu", "es": "Volver al menú", "fr": "Retour au menu", "de": "Zurück zum Menü", "ja": "メニューに戻る", "zh": "返回菜单", "ko": "메뉴로 돌아가기", "it": "Torna al menu", "ru": "В главное меню"},
	"stage_complete": {"pt": "Fase %s completa!", "en": "Stage %s complete!", "es": "¡Fase %s completada!", "fr": "Étape %s terminée!", "de": "Stufe %s abgeschlossen!", "ja": "ステージ %s クリア!", "zh": "%s 关卡完成!", "ko": "스테이지 %s 클리어!", "it": "Fase %s completata!", "ru": "Этап %s пройден!"},
	"total_damage": {"pt": "Dano total: %d", "en": "Total damage: %d", "es": "Daño total: %d", "fr": "Dégâts totaux: %d", "de": "Gesamtschaden: %d", "ja": "総ダメージ: %d", "zh": "总伤害: %d", "ko": "총 피해: %d", "it": "Danno totale: %d", "ru": "Общий урон: %d"},
	"unlocked": {"pt": "Desbloqueado: %s!", "en": "Unlocked: %s!", "es": "¡Desbloqueado: %s!", "fr": "Débloqué: %s!", "de": "Freigeschaltet: %s!", "ja": "解放: %s!", "zh": "解锁: %s!", "ko": "해금: %s!", "it": "Sbloccato: %s!", "ru": "Разблокировано: %s!"},
	"leaderboard_rank": {"pt": "Leaderboard: #%d!", "en": "Leaderboard: #%d!", "es": "Clasificación: #%d!", "fr": "Classement: #%d!", "de": "Rangliste: #%d!", "ja": "ランキング: #%d!", "zh": "排行榜: #%d!", "ko": "리더보드: #%d!", "it": "Classifica: #%d!", "ru": "Рейтинг: #%d!"},

	# ---- Character select ----
	"select_character": {"pt": "Selecione o personagem", "en": "Select character", "es": "Elige personaje", "fr": "Choisir personnage", "de": "Charakter wählen", "ja": "キャラクター選択", "zh": "选择角色", "ko": "캐릭터 선택", "it": "Scegli personaggio", "ru": "Выбор персонажа"},
	"locked": {"pt": "Bloqueado", "en": "Locked", "es": "Bloqueado", "fr": "Verrouillé", "de": "Gesperrt", "ja": "ロック", "zh": "未解锁", "ko": "잠김", "it": "Bloccato", "ru": "Заблокировано"},
	"start": {"pt": "Iniciar", "en": "Start", "es": "Empezar", "fr": "Commencer", "de": "Starten", "ja": "開始", "zh": "开始", "ko": "시작", "it": "Inizia", "ru": "Начать"},
	"back": {"pt": "Voltar", "en": "Back", "es": "Volver", "fr": "Retour", "de": "Zurück", "ja": "戻る", "zh": "返回", "ko": "뒤로", "it": "Indietro", "ru": "Назад"},

	# ---- Stage select ----
	"select_stage": {"pt": "Selecione a fase", "en": "Select stage", "es": "Elige fase", "fr": "Choisir étape", "de": "Stufe wählen", "ja": "ステージ選択", "zh": "选择关卡", "ko": "스테이지 선택", "it": "Scegli fase", "ru": "Выбор этапа"},
	"next": {"pt": "Próximo", "en": "Next", "es": "Siguiente", "fr": "Suivant", "de": "Weiter", "ja": "次へ", "zh": "下一个", "ko": "다음", "it": "Avanti", "ru": "Далее"},

	# ---- Relic select ----
	"select_relic": {"pt": "Escolha uma relíquia", "en": "Choose a relic", "es": "Elige una reliquia", "fr": "Choisir une relique", "de": "Relikt wählen", "ja": "レリック選択", "zh": "选择遗物", "ko": "유물 선택", "it": "Scegli una reliquia", "ru": "Выберите реликвию"},
	"skip_relic": {"pt": "Pular", "en": "Skip", "es": "Omitir", "fr": "Passer", "de": "Überspringen", "ja": "スキップ", "zh": "跳过", "ko": "건너뛰기", "it": "Salta", "ru": "Пропустить"},

	# ---- Shop ----
	"shop_title": {"pt": "Loja", "en": "Shop", "es": "Tienda", "fr": "Boutique", "de": "Laden", "ja": "ショップ", "zh": "商店", "ko": "상점", "it": "Negozio", "ru": "Магазин"},
	"buy": {"pt": "Comprar (%d)", "en": "Buy (%d)", "es": "Comprar (%d)", "fr": "Acheter (%d)", "de": "Kaufen (%d)", "ja": "購入 (%d)", "zh": "购买 (%d)", "ko": "구매 (%d)", "it": "Compra (%d)", "ru": "Купить (%d)"},
	"max_level": {"pt": "Max", "en": "Max", "es": "Máx", "fr": "Max", "de": "Max", "ja": "最大", "zh": "满级", "ko": "최대", "it": "Max", "ru": "Макс"},

	# ---- Events (gameplay) ----
	"event_golden_horde": {"pt": "Horda dourada!", "en": "Golden horde!", "es": "¡Horda dorada!", "fr": "Horde dorée!", "de": "Goldene Horde!", "ja": "黄金の群れ!", "zh": "黄金部落!", "ko": "황금 무리!", "it": "Orda dorata!", "ru": "Золотая орда!"},
	"event_treasure_goblin": {"pt": "Treasure goblin!", "en": "Treasure goblin!", "es": "¡Duende del tesoro!", "fr": "Gobelin au trésor!", "de": "Schatzgoblin!", "ja": "トレジャーゴブリン!", "zh": "宝藏哥布林!", "ko": "보물 고블린!", "it": "Goblin del tesoro!", "ru": "Гоблин-сокровище!"},
	"event_merchant": {"pt": "Mercador apareceu!", "en": "Merchant appeared!", "es": "¡Mercader apareció!", "fr": "Marchand apparu!", "de": "Händler erschienen!", "ja": "商人出現!", "zh": "商人出现了!", "ko": "상인 등장!", "it": "Mercante apparso!", "ru": "Торговец появился!"},
	"event_roulette": {"pt": "Roda da fortuna!", "en": "Wheel of fortune!", "es": "¡Rueda de la fortuna!", "fr": "Roue de la fortune!", "de": "Glücksrad!", "ja": "運命の輪!", "zh": "幸运转盘!", "ko": "행운의 룰렛!", "it": "Ruota della fortuna!", "ru": "Колесо фортуны!"},
	"event_eclipse": {"pt": "Eclipse!", "en": "Eclipse!", "es": "¡Eclipse!", "fr": "Éclipse!", "de": "Finsternis!", "ja": "日食!", "zh": "日食!", "ko": "일식!", "it": "Eclissi!", "ru": "Затмение!"},
	"event_meteor_shower": {"pt": "Chuva de meteoros!", "en": "Meteor shower!", "es": "¡Lluvia de meteoros!", "fr": "Pluie de météores!", "de": "Meteorregen!", "ja": "流星群!", "zh": "流星雨!", "ko": "유성우!", "it": "Pioggia di meteore!", "ru": "Метеоритный дождь!"},
	"event_angel_challenge": {"pt": "Desafio do anjo!", "en": "Angel challenge!", "es": "¡Desafío del ángel!", "fr": "Défi de l'ange!", "de": "Engelsprüfung!", "ja": "天使の試練!", "zh": "天使挑战!", "ko": "천사의 시련!", "it": "Sfida dell'angelo!", "ru": "Испытание ангела!"},
	"event_portal_dimensional": {"pt": "Portal dimensional!", "en": "Dimensional portal!", "es": "¡Portal dimensional!", "fr": "Portail dimensionnel!", "de": "Dimensionsportal!", "ja": "次元の門!", "zh": "次元传送门!", "ko": "차원의 문!", "it": "Portale dimensionale!", "ru": "Портал измерений!"},
	"event_chest_mimic": {"pt": "Baú mimic!", "en": "Mimic chest!", "es": "¡Cofre imitador!", "fr": "Coffre mimique!", "de": "Mimiktruhe!", "ja": "ミミックの宝箱!", "zh": "宝箱怪!", "ko": "미믹 상자!", "it": "Forziere mimetico!", "ru": "Сундук-мимик!"},
	"event_fever_mode": {"pt": "Fever mode!", "en": "Fever mode!", "es": "¡Modo fiebre!", "fr": "Mode fièvre!", "de": "Fiebermodus!", "ja": "フィーバーモード!", "zh": "狂热模式!", "ko": "피버 모드!", "it": "Modalità febbre!", "ru": "Режим лихорадки!"},

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
	"leaderboard_title": {"pt": "Ranking global", "en": "Global ranking"},
	"leaderboard_empty": {"pt": "Nenhuma run registrada ainda!", "en": "No runs recorded yet!"},
	"leaderboard_header": {"pt": "  #   | Tempo      | Kills  | Personagem | Data", "en": "  #   | Time       | Kills  | Character  | Date"},
	"leaderboard_tab_daily": {"pt": "Diario", "en": "Daily"},
	"leaderboard_tab_endless": {"pt": "Endless", "en": "Endless"},
	"leaderboard_tab_normal": {"pt": "Normal", "en": "Normal"},
	"leaderboard_tab_boss_rush": {"pt": "Boss rush", "en": "Boss rush"},
	"leaderboard_your_best": {"pt": "Seu melhor: #%d — %s", "en": "Your best: #%d — %s"},
	"leaderboard_refresh": {"pt": "Atualizar", "en": "Refresh"},
	"leaderboard_offline": {"pt": "Offline — mostrando dados locais", "en": "Offline — showing local data"},
	"leaderboard_loading": {"pt": "Carregando...", "en": "Loading..."},

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

	# ---- Narrativa / Lore ----
	"lore_death": {"pt": "O estilhaço te puxa de volta. Zion ainda precisa de você.", "en": "The shard pulls you back. Zion still needs you."},
	"lore_victory": {"pt": "O Sentinela está livre. A fenda se fecha.", "en": "The Sentinel is free. The rift closes."},
	"lore_victory_final": {"pt": "O último fragmento se encaixa. Zion respira de novo.\nMas não é o mesmo Zion — é melhor. É seu.", "en": "The last fragment falls into place. Zion breathes again.\nBut it's not the same Zion — it's better. It's yours."},
	"lore_mystery_unlock": {"pt": "Todos os estilhaços ressoam juntos... Zion acorda.\n\"Vocês não me reconstruíram. Vocês me reinventaram.\"", "en": "All the shards resonate together... Zion awakens.\n\"You didn't rebuild me. You reinvented me.\""},

	# ---- Backstories dos personagens ----
	"backstory_ronin": {"pt": "Samurai sem mestre do Japão feudal. Vagava entre vilas quando o céu se abriu e o arrancou de seu mundo.", "en": "A masterless samurai from feudal Japan. He wandered between villages when the sky tore open and ripped him away."},
	"backstory_soldado": {"pt": "Operativo militar em missão quando a realidade glitchou ao seu redor. Acordou entre fendas, com a arma na mão.", "en": "A military operative on a mission when reality glitched around him. He woke up between rifts, weapon in hand."},
	"backstory_mago": {"pt": "Estudava anomalias arcanas num reino de alta fantasia. A maior de todas as anomalias o engoliu.", "en": "He studied arcane anomalies in a high fantasy kingdom. The greatest anomaly of all swallowed him."},
	"backstory_berserker": {"pt": "Guerreiro nórdico que morreu em batalha e acordou no Vulcão. Achou que tinha chegado ao Valhalla.", "en": "A Norse warrior who died in battle and woke up in the Volcano. He thought he'd reached Valhalla."},
	"backstory_ninja": {"pt": "Operativo clandestino de uma Tóquio futurista. Sobreviveu ao blackout da IA quando todos os outros caíram.", "en": "A covert operative from a futuristic Tokyo. He survived the AI blackout when everyone else fell."},
	"backstory_necro": {"pt": "Aprendiz do Necromancer King antes da corrupção. Entrou na fenda para salvar o mestre.", "en": "Apprentice of the Necromancer King before the corruption. She entered the rift to save her master."},
	"backstory_pirata": {"pt": "Navegava mares desconhecidos na Era da Pirataria. Caiu por uma fenda no Triângulo das Bermudas.", "en": "He sailed unknown seas in the Age of Piracy. He fell through a rift in the Bermuda Triangle."},
	"backstory_engenheiro": {"pt": "Última sobrevivente da Estação Zenith, ano 2187. Construiu drones com sucata para não enlouquecer.", "en": "Last survivor of Zenith Station, year 2187. She built drones from scrap to keep from going insane."},
	"backstory_vampiro": {"pt": "Mordido por Drácula na Transilvânia do séc. XVIII, mas o estilhaço impediu a transformação completa.", "en": "Bitten by Dracula in 18th century Transylvania, but the shard prevented his full transformation."},
	"backstory_gladiador": {"pt": "Espírito da Arena de Roma Antiga que ganhou corpo quando a anomalia foi perturbada.", "en": "A spirit of the Ancient Roman Arena who gained a body when the anomaly was disturbed."},
	"backstory_chef": {"pt": "Confeiteiro da Paris Belle Époque que caiu no Mundo Doce e tentou civilizar os doces com culinária.", "en": "A pastry chef from Belle Époque Paris who fell into Candy World and tried to civilize the sweets with cooking."},
	"backstory_amazona": {"pt": "Guerreira tribal da Amazônia primordial que defendia sua terra quando as vacas mutantes invadiram.", "en": "A tribal warrior from the primordial Amazon who defended her land when mutant cows invaded."},
	"backstory_bruxa": {"pt": "Fugiu da fogueira em Salem, 1692, e caiu direto na Floresta Encantada. Adaptou-se rápido.", "en": "She escaped the pyre in Salem, 1692, and fell right into the Enchanted Forest. She adapted quickly."},
	"backstory_mystery": {"pt": "Quando todos os estilhaços ressoam juntos, o próprio Zion ganha consciência.", "en": "When all the shards resonate together, Zion itself gains consciousness."},

	# ---- Lore das fases ----
	"stage_cemetery_lore": {"pt": "A primeira fenda. Onde a morte parou de funcionar.", "en": "The first rift. Where death stopped working."},
	"stage_forest_lore": {"pt": "A natureza não morreu. Ela ficou furiosa.", "en": "Nature didn't die. It got furious."},
	"stage_farm_lore": {"pt": "Uma fenda menor que caiu no lugar mais improvável.", "en": "A minor rift that fell in the most unlikely place."},
	"stage_tokyo_lore": {"pt": "A IA não se rebelou. Ela acordou... e viu o cristal.", "en": "The AI didn't rebel. It woke up... and saw the crystal."},
	"stage_volcano_lore": {"pt": "Não é lava. É a raiva cristalizada de Zion.", "en": "It's not lava. It's Zion's crystallized rage."},
	"stage_ocean_lore": {"pt": "Nas profundezas, as memórias de Zion ainda ecoam.", "en": "In the depths, Zion's memories still echo."},
	"stage_arena_lore": {"pt": "Não é uma fenda. É um eco do passado.", "en": "It's not a rift. It's an echo of the past."},
	"stage_space_lore": {"pt": "Entre as estrelas, o vazio entre dimensões é mais fino.", "en": "Among the stars, the void between dimensions is thinner."},
	"stage_castle_lore": {"pt": "O último guardião não foi corrompido. Ele escolheu o cristal.", "en": "The last guardian wasn't corrupted. He chose the crystal."},
	"stage_candy_lore": {"pt": "Isto é o que acontece quando uma dimensão sonha.", "en": "This is what happens when a dimension dreams."},

	# ---- Lore das fases (descricao completa) ----
	"stage_cemetery_lore_full": {"pt": "O fragmento corrompeu o ciclo da morte. Os mortos se levantam, a neblina nunca dissipa.", "en": "The fragment corrupted the cycle of death. The dead rise, the fog never lifts."},
	"stage_forest_lore_full": {"pt": "Magia selvagem transformou a floresta numa armadilha viva. Fadas que guiavam viajantes agora os caçam.", "en": "Wild magic transformed the forest into a living trap. Fairies that once guided travelers now hunt them."},
	"stage_farm_lore_full": {"pt": "Um estilhaço deu consciência distorcida aos animais. Vacas zumbis, galinhas explosivas, porcos mutantes.", "en": "A shard gave the animals a twisted consciousness. Zombie cows, explosive chickens, mutant pigs."},
	"stage_tokyo_lore_full": {"pt": "A IA da cidade absorveu energia dimensional e decidiu eliminar todo orgânico.", "en": "The city's AI absorbed dimensional energy and decided to eliminate all organics."},
	"stage_volcano_lore_full": {"pt": "Energia pura do cristal se manifestou como fogo e fúria. Demônios nasceram do calor dimensional.", "en": "Pure crystal energy manifested as fire and fury. Demons were born from dimensional heat."},
	"stage_ocean_lore_full": {"pt": "Ruínas de uma civilização pré-dimensional. Criaturas marinhas mutaram e o mar ganhou vontade própria.", "en": "Ruins of a pre-dimensional civilization. Sea creatures mutated and the ocean gained a will of its own."},
	"stage_arena_lore_full": {"pt": "Memória de Zion — onde os Sentinelas treinavam. O coliseu persiste como um loop temporal.", "en": "Zion's memory — where the Sentinels trained. The coliseum persists as a temporal loop."},
	"stage_space_lore_full": {"pt": "Estação científica consumida pelas fendas. Gravidade falha, parasitas dimensionais se alimentam.", "en": "Science station consumed by rifts. Gravity fails, dimensional parasites feed."},
	"stage_castle_lore_full": {"pt": "A fortaleza de Drácula. Ele absorveu o cristal voluntariamente — acredita que Zion não deve ser restaurado.", "en": "Dracula's fortress. He absorbed the crystal willingly — he believes Zion shouldn't be restored."},
	"stage_candy_lore_full": {"pt": "Alucinação dimensional — o subconsciente de Zion tentando lembrar do paraíso. Mas a memória está corrompida.", "en": "Dimensional hallucination — Zion's subconscious trying to remember paradise. But the memory is corrupted."},

	# ---- Stage intro lore (fragment narrative) ----
	"stage_intro_cemetery": {"pt": "O Primeiro Fragmento: onde os mortos ainda caminham.", "en": "The First Fragment: where the dead still walk."},
	"stage_intro_forest": {"pt": "O Segundo Fragmento: uma floresta que devora quem entra.", "en": "The Second Fragment: a forest that devours all who enter."},
	"stage_intro_farm": {"pt": "O Terceiro Fragmento: a terra que alimentava, agora consome.", "en": "The Third Fragment: the land that once fed, now consumes."},
	"stage_intro_tokyo": {"pt": "O Quarto Fragmento: a cidade que nunca dorme... nem morre.", "en": "The Fourth Fragment: the city that never sleeps... nor dies."},
	"stage_intro_volcano": {"pt": "O Quinto Fragmento: as chamas da corrupcao queimam eternas.", "en": "The Fifth Fragment: the flames of corruption burn eternal."},
	"stage_intro_ocean": {"pt": "O Sexto Fragmento: abaixo das ondas, horrores antigos esperam.", "en": "The Sixth Fragment: below the waves, ancient horrors await."},
	"stage_intro_arena": {"pt": "O Setimo Fragmento: um coliseu onde a morte eh espetaculo.", "en": "The Seventh Fragment: a coliseum where death is spectacle."},
	"stage_intro_space": {"pt": "O Oitavo Fragmento: no vazio do espaco, ninguem ouve seus gritos.", "en": "The Eighth Fragment: in the void of space, no one hears your screams."},
	"stage_intro_castle": {"pt": "O Nono Fragmento: o castelo do vampiro, trono da escuridao.", "en": "The Ninth Fragment: the vampire's castle, throne of darkness."},
	"stage_intro_candy": {"pt": "O Decimo Fragmento: docura que esconde veneno mortal.", "en": "The Tenth Fragment: sweetness that hides deadly poison."},

	# ---- Victory lore per stage ----
	"victory_lore_cemetery": {"pt": "O Primeiro Fragmento foi restaurado. Os mortos finalmente descansam.", "en": "The First Fragment has been restored. The dead finally rest."},
	"victory_lore_forest": {"pt": "O Segundo Fragmento brilha novamente. A floresta renasce.", "en": "The Second Fragment shines again. The forest is reborn."},
	"victory_lore_farm": {"pt": "O Terceiro Fragmento pulsa com vida. A terra volta a dar frutos.", "en": "The Third Fragment pulses with life. The land bears fruit again."},
	"victory_lore_tokyo": {"pt": "O Quarto Fragmento se estabiliza. A cidade respira.", "en": "The Fourth Fragment stabilizes. The city breathes."},
	"victory_lore_volcano": {"pt": "O Quinto Fragmento esfria. As chamas cedem ao silencio.", "en": "The Fifth Fragment cools. The flames yield to silence."},
	"victory_lore_ocean": {"pt": "O Sexto Fragmento emerge. O mar se acalma.", "en": "The Sixth Fragment emerges. The sea grows calm."},
	"victory_lore_arena": {"pt": "O Setimo Fragmento reverbera. O coliseu finalmente descansa.", "en": "The Seventh Fragment reverberates. The coliseum finally rests."},
	"victory_lore_space": {"pt": "O Oitavo Fragmento orbita em paz. O vazio recua.", "en": "The Eighth Fragment orbits in peace. The void recedes."},
	"victory_lore_castle": {"pt": "O Nono Fragmento se liberta. A escuridao perde seu trono.", "en": "The Ninth Fragment is freed. Darkness loses its throne."},
	"victory_lore_candy": {"pt": "O Decimo Fragmento se encaixa. O sonho se torna real.", "en": "The Tenth Fragment falls into place. The dream becomes real."},

	# ---- Final victory (all stages complete) ----
	"victory_all_stages": {"pt": "Todos os fragmentos restaurados.\nZion renasce das cinzas.\n\nVoce e um verdadeiro Fragmentado.\nO paraiso esta salvo... por enquanto.", "en": "All fragments restored.\nZion rises from the ashes.\n\nYou are a true Fragmented.\nParadise is saved... for now."},

	# ---- Nomes narrativos dos bosses ----
	"boss_cemetery": {"pt": "Necromancer King — Sentinela da morte", "en": "Necromancer King — Sentinel of death"},
	"boss_forest": {"pt": "Rainha das Fadas — Sentinela da natureza", "en": "Fairy Queen — Sentinel of nature"},
	"boss_farm": {"pt": "Mega Vaca Alienígena", "en": "Alien Mega Cow"},
	"boss_tokyo": {"pt": "AI Overlord — Sentinela da lógica", "en": "AI Overlord — Sentinel of logic"},
	"boss_volcano": {"pt": "Demon Lord — nascido da destruição", "en": "Demon Lord — born of destruction"},
	"boss_ocean": {"pt": "Leviathan — o Sentinela mais antigo", "en": "Leviathan — the oldest Sentinel"},
	"boss_arena": {"pt": "Imperador Corrompido — eco do passado", "en": "Corrupted Emperor — echo of the past"},
	"boss_space": {"pt": "Singularidade — guardião do espaço-tempo", "en": "Singularity — guardian of spacetime"},
	"boss_castle": {"pt": "Conde Drácula — o guardião que escolheu", "en": "Count Dracula — the guardian who chose"},
	"boss_candy": {"pt": "Rei Açúcar — último fragmento do Coração", "en": "Sugar King — last fragment of the Heart"},
	# Boss dialogue - intro
	"boss_intro_necromancer": {"pt": "Eu guardava a fronteira entre vida e morte.\nAgora SOU a fronteira!", "en": "I guarded the border between life and death.\nNow I AM the border!"},
	"boss_intro_fairy_queen": {"pt": "A floresta era minha para proteger.\nAgora é minha para devorar!", "en": "The forest was mine to protect.\nNow it's mine to devour!"},
	"boss_intro_alien_cow": {"pt": "MUUUU! O cristal me deu\nconsciência! E FOME!", "en": "MOOO! The crystal gave me\nconsciousness! And HUNGER!"},
	"boss_intro_ai_overlord": {"pt": "SENTINELA DA LÓGICA ONLINE.\nVARIÁVEIS ORGÂNICAS: ELIMINAR.", "en": "SENTINEL OF LOGIC ONLINE.\nORGANIC VARIABLES: ELIMINATE."},
	"boss_intro_demon_lord": {"pt": "Não fui corrompido. EU NASCI\nda destruição de Zion!", "en": "I was not corrupted. I was BORN\nfrom Zion's destruction!"},
	"boss_intro_leviathan": {"pt": "Eu existo desde antes de Zion ter nome.\nVocês são efêmeros!", "en": "I existed before Zion had a name.\nYou are ephemeral!"},
	"boss_intro_emperor": {"pt": "Ajoelhem-se! Nesta arena,\nEU SOU ETERNO!", "en": "Kneel! In this arena,\nI AM ETERNAL!"},
	"boss_intro_singularity": {"pt": "EU GUARDO AS FRONTEIRAS DO ESPAÇO-TEMPO.\nNADA PASSA.", "en": "I GUARD THE BORDERS OF SPACETIME.\nNOTHING PASSES."},
	"boss_intro_dracula": {"pt": "Eu não fui corrompido. Eu ESCOLHI.\nZion não deve ser restaurado!", "en": "I was not corrupted. I CHOSE.\nZion must not be restored!"},
	"boss_intro_sugar_king": {"pt": "Eu sou tudo que resta do Coração!\nE NÃO VOU SER CONSERTADO!", "en": "I am all that remains of the Heart!\nAnd I WILL NOT be fixed!"},
	# Alt boss intros
	"boss_intro_cemetery_lich": {"pt": "Eu dominei a própria morte.\nVocê não tem essa sorte.", "en": "I conquered death itself.\nYou won't be so lucky."},
	"boss_intro_cemetery_reaper": {"pt": "Cada alma tem seu prazo.\nO seu... acabou.", "en": "Every soul has its deadline.\nYours... is up."},
	"boss_intro_forest_elder": {"pt": "Mil anos eu esperei.\nA floresta cobra seu tributo.", "en": "A thousand years I waited.\nThe forest collects its due."},
	"boss_intro_forest_spider": {"pt": "Minha teia é vasta, pequeno.\nVocê já está preso.", "en": "My web is vast, little one.\nYou're already caught."},
	"boss_intro_farm_scarecrow": {"pt": "Os corvos me temem.\nVocê deveria também.", "en": "The crows fear me.\nSo should you."},
	"boss_intro_farm_harvester": {"pt": "Hora da colheita.\nE VOCÊ é a safra.", "en": "Harvest time.\nAnd YOU are the crop."},
	"boss_intro_tokyo_shogun": {"pt": "Bushido digital. Um corte.\nUma morte. Sem exceções.", "en": "Digital bushido. One cut.\nOne death. No exceptions."},
	"boss_intro_tokyo_kaiju": {"pt": "ROOOOAR!\n*a terra treme*", "en": "ROOOOAR!\n*the earth shakes*"},
	"boss_intro_volcano_phoenix": {"pt": "Das cinzas eu renasço.\nDas cinzas VOCÊ não volta.", "en": "From ashes I rise.\nFrom ashes YOU won't return."},
	"boss_intro_volcano_titan": {"pt": "Eu SOU a montanha.\nE montanhas não se movem... para VOCÊ.", "en": "I AM the mountain.\nAnd mountains don't move... for YOU."},
	"boss_intro_ocean_siren": {"pt": "Ouça minha canção...\nEla será a última que você ouve.", "en": "Listen to my song...\nIt'll be the last you ever hear."},
	"boss_intro_ocean_hydra": {"pt": "Corte uma cabeça.\nDuas crescerão.", "en": "Cut one head.\nTwo will grow."},
	"boss_intro_arena_minotaur": {"pt": "O labirinto é meu domínio.\nNão há saída para você.", "en": "The labyrinth is my domain.\nThere's no exit for you."},
	"boss_intro_arena_chimera": {"pt": "Três feras. Uma mente.\nNENHUMA misericórdia.", "en": "Three beasts. One mind.\nNO mercy."},
	"boss_intro_space_hivemind": {"pt": "Nós somos legião.\nVocê é... irrelevante.", "en": "We are legion.\nYou are... irrelevant."},
	"boss_intro_space_warden": {"pt": "O vazio me moldou.\nAgora EU moldo o vazio.", "en": "The void shaped me.\nNow I shape the void."},
	"boss_intro_castle_werewolf": {"pt": "A lua cheia brilha.\nMinha fome... TAMBÉM.", "en": "The full moon shines.\nMy hunger... ALSO."},
	"boss_intro_castle_banshee": {"pt": "Meu grito atravessa dimensões.\nSua alma... não resistirá.", "en": "My scream crosses dimensions.\nYour soul... won't resist."},
	"boss_intro_candy_witch": {"pt": "Doces ou travessuras?\nSó tenho TRAVESSURAS.", "en": "Trick or treat?\nI only have TRICKS."},
	"boss_intro_candy_dragon": {"pt": "Feito de açúcar, mas\nminha mordida é REAL.", "en": "Made of sugar, but\nmy bite is REAL."},
	# Boss dialogue - death
	"boss_death_necromancer": {"pt": "Livre... finalmente livre.\nObrigado, Fragmentado...", "en": "Free... finally free.\nThank you, Fragmented..."},
	"boss_death_fairy_queen": {"pt": "A harmonia... eu lembro agora.\nEu era... a guardiã...", "en": "The harmony... I remember now.\nI was... the guardian..."},
	"boss_death_alien_cow": {"pt": "Muu... o brilho... está sumindo...\n*static*", "en": "Moo... the glow... is fading...\n*static*"},
	"boss_death_ai_overlord": {"pt": "ERRO... eu era protetor?\nDados corrompidos... restaurando...", "en": "ERROR... I was a protector?\nCorrupted data... restoring..."},
	"boss_death_demon_lord": {"pt": "A raiva se dissolve...\nO que resta... é vazio...", "en": "The rage dissolves...\nWhat remains... is void..."},
	"boss_death_leviathan": {"pt": "As profundezas... se aquietam.\nO mais antigo... descansa...", "en": "The depths... grow still.\nThe oldest one... rests..."},
	"boss_death_emperor": {"pt": "O loop... se quebra.\nRoma... pode descansar...", "en": "The loop... breaks.\nRome... can rest..."},
	"boss_death_singularity": {"pt": "O horizonte... colapsa.\nAs fronteiras... se abrem...", "en": "The horizon... collapses.\nThe borders... open..."},
	"boss_death_dracula": {"pt": "Talvez... eu estivesse errado.\nTalvez vocês mereçam... um novo Zion...", "en": "Perhaps... I was wrong.\nPerhaps you deserve... a new Zion..."},
	"boss_death_sugar_king": {"pt": "O último fragmento...\nO coração... bate de novo...", "en": "The last fragment...\nThe heart... beats again..."},
	# Alt boss deaths
	"boss_death_cemetery_lich": {"pt": "A coroa... pesa demais.\nLiberte-me...", "en": "The crown... too heavy.\nFree me..."},
	"boss_death_cemetery_reaper": {"pt": "A foice... cai.\nMeu trabalho... terminou.", "en": "The scythe... falls.\nMy work... is done."},
	"boss_death_forest_elder": {"pt": "As raízes... se soltam.\nA terra respira...", "en": "The roots... release.\nThe earth breathes..."},
	"boss_death_forest_spider": {"pt": "A teia... se dissolve.\nLuz... pela primeira vez...", "en": "The web... dissolves.\nLight... for the first time..."},
	"boss_death_farm_scarecrow": {"pt": "Os corvos... voltam.\nEu era... o espantalho...", "en": "The crows... return.\nI was... the scarecrow..."},
	"boss_death_farm_harvester": {"pt": "A colheita... acaba.\nA terra... pode descansar.", "en": "The harvest... ends.\nThe land... can rest."},
	"boss_death_tokyo_shogun": {"pt": "Honra... restaurada.\nO código... se completa.", "en": "Honor... restored.\nThe code... completes."},
	"boss_death_tokyo_kaiju": {"pt": "rooar...\n*deita e dorme*", "en": "rooar...\n*lies down and sleeps*"},
	"boss_death_volcano_phoenix": {"pt": "Desta vez... não renasço.\nFinalmente... paz.", "en": "This time... I don't rise.\nFinally... peace."},
	"boss_death_volcano_titan": {"pt": "A montanha... adormece.\nO fogo... se apaga.", "en": "The mountain... sleeps.\nThe fire... goes out."},
	"boss_death_ocean_siren": {"pt": "A canção... se silencia.\nO mar... acalma.", "en": "The song... silences.\nThe sea... calms."},
	"boss_death_ocean_hydra": {"pt": "Todas as cabeças... fecham os olhos.\nFinalmente... uma só mente.", "en": "All heads... close their eyes.\nFinally... one mind."},
	"boss_death_arena_minotaur": {"pt": "O labirinto... se abre.\nLivre... do ciclo.", "en": "The labyrinth... opens.\nFree... from the cycle."},
	"boss_death_arena_chimera": {"pt": "Três vozes... em harmonia.\nUm último... suspiro.", "en": "Three voices... in harmony.\nOne last... breath."},
	"boss_death_space_hivemind": {"pt": "Nós éramos... um só.\nAgora... somos livres.", "en": "We were... one.\nNow... we are free."},
	"boss_death_space_warden": {"pt": "O vazio... recua.\nA luz... retorna.", "en": "The void... recedes.\nThe light... returns."},
	"boss_death_castle_werewolf": {"pt": "A maldição... se quebra.\nSou... humano de novo.", "en": "The curse... breaks.\nI'm... human again."},
	"boss_death_castle_banshee": {"pt": "O grito... se cala.\nFinalmente... silêncio.", "en": "The scream... stops.\nFinally... silence."},
	"boss_death_candy_witch": {"pt": "Os doces... perdem o sabor.\nMas o mundo... fica mais doce.", "en": "The sweets... lose their taste.\nBut the world... gets sweeter."},
	"boss_death_candy_dragon": {"pt": "O açúcar... derrete.\nMas a memória... fica.", "en": "The sugar... melts.\nBut the memory... remains."},
	# Boss dialogue - phase 2 (entering rage)
	"boss_phase2_necromancer": {"pt": "Vocês não entendem... a morte é um PRESENTE!", "en": "You don't understand... death is a GIFT!"},
	"boss_phase2_fairy_queen": {"pt": "A floresta GRITA! Vocês a ouvem?!", "en": "The forest SCREAMS! Can you hear it?!"},
	"boss_phase2_alien_cow": {"pt": "MUUU! MODO FÚRIA ATIVADO!", "en": "MOOO! FURY MODE ACTIVATED!"},
	"boss_phase2_ai_overlord": {"pt": "RECALCULANDO... PROTOCOLO ELIMINAÇÃO AVANÇADO.", "en": "RECALCULATING... ADVANCED ELIMINATION PROTOCOL."},
	"boss_phase2_demon_lord": {"pt": "Sintam a fúria que CRIOU este mundo!", "en": "Feel the fury that CREATED this world!"},
	"boss_phase2_leviathan": {"pt": "O abismo responde ao meu chamado...", "en": "The abyss answers my call..."},
	"boss_phase2_emperor": {"pt": "Gladiadores! Defendam seu IMPERADOR!", "en": "Gladiators! Defend your EMPEROR!"},
	"boss_phase2_singularity": {"pt": "AUMENTANDO CAMPO GRAVITACIONAL.\nCOLAPSO IMINENTE.", "en": "INCREASING GRAVITATIONAL FIELD.\nCOLLAPSE IMMINENT."},
	"boss_phase2_dracula": {"pt": "Sangue... eu preciso de MAIS SANGUE!", "en": "Blood... I need MORE BLOOD!"},
	"boss_phase2_sugar_king": {"pt": "Vocês vão DERRETER neste açúcar!", "en": "You will MELT in this sugar!"},
	# Boss dialogue - phase 3 (desperate)
	"boss_phase3_necromancer": {"pt": "NÃO! Eu não vou... voltar àquele vazio!", "en": "NO! I won't... go back to that void!"},
	"boss_phase3_fairy_queen": {"pt": "A floresta... está me abandonando...\nNÃO!", "en": "The forest... is abandoning me...\nNO!"},
	"boss_phase3_alien_cow": {"pt": "M-MUUU... SISTEMA... INSTÁVEL...", "en": "M-MOOO... SYSTEM... UNSTABLE..."},
	"boss_phase3_ai_overlord": {"pt": "FALHA CRÍTICA. INICIANDO\nAUTODESTRUIÇÃO...", "en": "CRITICAL FAILURE. INITIATING\nSELF-DESTRUCTION..."},
	"boss_phase3_demon_lord": {"pt": "A raiva... está me consumindo...\nEu não consigo... parar!", "en": "The rage... is consuming me...\nI can't... stop!"},
	"boss_phase3_leviathan": {"pt": "As profundezas... tremem.\nAlgo antigo está... acordando...", "en": "The depths... tremble.\nSomething ancient is... awakening..."},
	"boss_phase3_emperor": {"pt": "Roma... NÃO PODE CAIR!\nEU NÃO PERMITO!", "en": "Rome... CANNOT FALL!\nI WON'T ALLOW IT!"},
	"boss_phase3_singularity": {"pt": "HORIZONTE DE EVENTOS INSTÁVEL.\nREALIDADE... FRAGMENTANDO...", "en": "EVENT HORIZON UNSTABLE.\nREALITY... FRAGMENTING..."},
	"boss_phase3_dracula": {"pt": "Mil anos... eu esperei mil anos...\nNão vai acabar assim!", "en": "A thousand years... I waited a thousand years...\nIt won't end like this!"},
	"boss_phase3_sugar_king": {"pt": "O Coração... está me puxando de volta...\nEU NÃO QUERO IR!", "en": "The Heart... is pulling me back...\nI DON'T WANT TO GO!"},
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
	return AVAILABLE_LOCALES

func get_locale_name(locale: String) -> String:
	return LOCALE_NAMES.get(locale, locale)
