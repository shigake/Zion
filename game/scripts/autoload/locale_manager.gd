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
