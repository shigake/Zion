# Zion — Checklist Final Completo (v2.83)

## BUGS CRITICOS
- [x] Chef starting_weapon = "flamethrower" (desabilitado) — trocar pra outra arma
- [x] 50 monstros gen3 sprites existem mas nomes nao batem no STAGE_ENEMY_SPRITES mapping
- [x] Circulos coloridos placeholder nas areas de armas melee (katana=azul, scythe=roxo, hammer=amarelo, whip=marrom)
- [ ] Barrier walls no player.gd gera 24 erros is_inside_tree na criacao (inofensivo mas poluente)
- [ ] health_pickup.gd ainda gera 7 erros por run
- [ ] Totem area visual eh um circulo generico

## SFX NAO CONECTADOS (33 gerados, ~20 nao conectados)
### Combate
- [x] sword_slash.wav — conectar em katana.gd, dual_katana.gd, cloud_sword.gd (_attack)
- [x] axe_chop.wav — conectar em axe.gd (_throw)
- [x] scythe_swoosh.wav — conectar em scythe.gd (_on_body_entered)
- [x] whip_crack.wav — conectar em whip.gd (_attack)
- [x] hammer_slam.wav — conectar em hammer.gd (_attack)
- [x] lance_thrust.wav — conectar em lance.gd (_attack)
- [x] punch_hit.wav — conectar em boxing_gloves.gd (_do_punch), nunchaku.gd
- [x] gun_shot.wav — conectar em machinegun.gd, dual_pistol.gd (_fire) substituindo "hit"
- [x] bow_release.wav — conectar em elven_bow.gd, crossbow.gd (_fire)
- [x] magic_cast.wav — conectar em staff.gd, ice_staff.gd, magic_book.gd (_fire)
- [x] explosion.wav — conectar em rocket.gd (explosao), time_bomb.gd
- [x] electric_zap.wav — conectar em lightning_chain.gd (_cast), totem.gd
- [x] poison_splash.wav — conectar em poison_bottle.gd (_throw_bottle)
- [x] fire_whoosh.wav — reservado (flamethrower desabilitado)
- [x] summon_pop.wav — conectar em necro.gd (_summon), skeleton_summon.gd

### UI
- [x] collect_crystal.wav — conectar em crystal_pickup.gd (_collect)
- [x] heal.wav — conectar em health_pickup.gd (_collect)
- [x] achievement.wav — conectar em achievement_popup.gd
- [x] reroll.wav — conectar em level_up_screen.gd (_on_reroll)
- [x] banish.wav — conectar em level_up_screen.gd (_on_banish)
- [x] select.wav — conectar em level_up_screen.gd (_choose)
- [x] equip.wav — conectar em level_up_screen.gd (apos escolha aplicada)
- [x] error.wav — conectar quando tenta comprar sem cristais, personagem locked (shop + character_select)

### Ambiente
- [x] footstep.wav — conectar em player.gd (cada 0.3s de walk)
- [x] enemy_growl.wav — conectar em enemy_spawner.gd (spawn de elite/special)
- [x] chest_open.wav — conectar em evolution_chest.gd
- [x] portal_hum.wav — conectar em portal_weapon.gd, event_manager.gd (portal dimensional)
- [ ] lava_bubble.wav — conectar em volcano_props.gd (ambient loop)
- [ ] wind.wav — conectar em space_props.gd, cemetery_props.gd (ambient loop)

### Boss
- [x] boss_roar.wav — conectar em boss_dialogue.gd (intro)
- [x] boss_attack.wav — conectar em todos boss_*.gd (ataques especiais)
- [x] boss_phase.wav — conectar em todos boss_*.gd (threshold de fase do boss)
- [x] boss_death.wav — conectar em enemy_base.gd (_die para boss)

## MUSICA NAO CONECTADA
- [x] victory.wav — tocar quando boss morre (game_manager.gd ou game_over_screen.gd)
- [x] shop.wav — tocar quando abrir loja (shop.gd _ready)
- [x] lobby.wav — tocar quando abrir lobby (lobby_screen.gd _ready)
- [x] game_over_music.wav — tocar na tela de game over (game_over_screen.gd)

## ARMAS NOVAS SEM SCRIPTS (4)
- [x] boomerang.gd + boomerang.tscn — projetil que vai e volta, perfura na ida
- [x] tornado.gd + tornado.tscn — summon, vortex giratorio que puxa inimigos
- [x] chain_whip.gd + chain_whip.tscn — melee, chain entre inimigos proximos
- [x] blood_orb.gd + blood_orb.tscn — summon, orbe que drena vida em area

## EFEITOS VISUAIS PLACEHOLDER
- [ ] Katana swing area — substituir circulo azul por sprite de arco de corte
- [ ] Scythe rotation — substituir circulo roxo por trail roxo
- [ ] Hammer slam — substituir circulo amarelo por onda de choque sprite
- [ ] Whip area — substituir circulo marrom por linha de chicote
- [ ] Lance thrust — substituir linha azul por sprite de investida
- [ ] Cloud sword wave — substituir circulo grande por onda de energia
- [ ] Totem aura — substituir circulo eletrico por sprite de raios
- [ ] Poison pool — melhorar visual da poca (ja tem sprite mas pode melhorar)

## MONSTROS GEN3 NAO MAPEADOS
### Cemetery
- [ ] cemetery_ghoul → mapear a algum enemy type
- [ ] cemetery_banshee → ja mapeado? verificar
- [ ] cemetery_gravedigger → mapear
- [ ] cemetery_rat_swarm → mapear
- [ ] cemetery_bone_knight → mapear

### Forest
- [ ] forest_fairy → mapear
- [ ] forest_vine → mapear
- [ ] forest_bear → mapear
- [ ] forest_owl → mapear
- [ ] forest_wisp → verificar

### Farm
- [ ] farm_bull → mapear
- [ ] farm_rat → mapear
- [ ] farm_goat → mapear
- [ ] farm_bee_swarm → mapear
- [ ] farm_worm → mapear

### Tokyo
- [ ] tokyo_yakuza → mapear
- [ ] tokyo_cyborg → mapear
- [ ] tokyo_hologram → verificar
- [ ] tokyo_turret → mapear
- [ ] tokyo_virus → mapear

### Volcano
- [ ] volcano_phoenix → mapear
- [ ] volcano_lava_snake → mapear
- [ ] volcano_ash_ghost → mapear
- [ ] volcano_fire_bat → mapear
- [ ] volcano_obsidian_golem → mapear

### Ocean
- [ ] ocean_shark → mapear
- [ ] ocean_pufferfish → mapear
- [ ] ocean_eel → mapear
- [ ] ocean_seahorse → mapear
- [ ] ocean_octopus → mapear

### Arena
- [ ] arena_archer → mapear
- [ ] arena_tiger → mapear
- [ ] arena_prisoner → mapear
- [ ] arena_eagle → mapear
- [ ] arena_net_fighter → mapear

### Space
- [ ] space_robot → mapear
- [ ] space_tentacle → mapear
- [ ] space_crystal → mapear
- [ ] space_worm → mapear
- [ ] space_sentinel → mapear

### Castle
- [ ] castle_ghost_maid → mapear
- [ ] castle_rat_king → mapear
- [ ] castle_skeleton_mage → mapear
- [ ] castle_bat_swarm → verificar
- [ ] castle_cursed_armor → mapear

### Candy
- [ ] candy_chocolate_golem → mapear
- [ ] candy_ice_cream_cone → mapear
- [ ] candy_cotton_candy_ghost → mapear
- [ ] candy_cake_mimic → mapear
- [ ] candy_sour_worm → mapear

## PERFORMANCE
- [x] Reduzir props por stage: cemetery 105→65, outros similar
- [x] Expandir ObjectPool pra staff_projectile, ice_crystal, magic_book page, shuriken
- [ ] Cachear texturas de sprites (evitar load() repetido)
- [ ] Bullet trail — adicionar rastro visual (so quando FPS > 45)
- [ ] MultiMesh pra pickups quando > 100 no chao

## UI/UX
- [ ] Barra de XP — mostrar quanto falta pro proximo nivel (tooltip ou texto)
- [ ] Timer mais visivel — font maior, cor diferente pros ultimos 3 minutos
- [x] Boss HP bar — nome do boss + icone acima da barra
- [ ] Dash cooldown — indicador visual no HUD (barra ou icone)
- [x] Tela de pausa — mostrar inventario resumido (armas + itens equipados)
- [ ] Options: slider de volume com preview de som
- [ ] Options: sensibilidade do gamepad
- [x] Tela de creditos — atualizar com todos os assets usados (Suno, Quaternius, etc.)

## MULTIPLAYER
- [ ] Level up assincrono (design aprovado, implementacao pendente)
- [x] Ping display no HUD durante gameplay
- [x] Ally HP bars com nomes dos jogadores
- [ ] Sync de weapon_damage_dealt pro game over screen multiplayer

## CONTEUDO
- [ ] Mais dialogos de boss (falas durante a luta, nao so intro/morte)
- [ ] Descricoes de stages no mapa (lore text)
- [x] Tips de loading variados (adicionar 20+ tips) — agora 41 tips
- [ ] Personagem desbloqueavel por completar todos stages: "Fragmentado" (lore-related)
- [ ] Evento especial: "Eclipse Total" — tela escurece, so inimigos brilham

## POLISH
- [ ] Tela titulo: logo do jogo (sprite ou texto estilizado)
- [ ] Animacao de transicao entre menus (fade + slide)
- [ ] Efeito de poeira ao andar (particula simples no pe do player)
- [ ] Inimigos piscam vermelho ao tomar dano (adicionar ao squash-stretch)
- [ ] XP gems brilham mais (aumentar emission)
- [ ] Cristais giram mais rapido
- [ ] Boss HP bar pulsa quando boss < 25% HP
- [ ] Camera shake diferenciado: leve pra hits, medio pra kills, forte pra boss

## DOCUMENTACAO
- [ ] Atualizar CLAUDE.md com estado atual (sprites, 32 armas, 14 chars, etc.)
- [ ] Atualizar README.md pro publico
- [ ] Atualizar gdd.md com mecanicas novas (sinergias, mutacoes, etc.)
- [ ] Atualizar personagens.md com Amazona e Bruxa
- [ ] Atualizar fases.md com mecanicas de stage
- [ ] Atualizar itens.md com 4 novas armas
- [ ] Atualizar balance_analysis.md com DPS das novas armas

## BUILD/DEPLOY
- [ ] Export preset Windows Desktop
- [ ] Testar export em maquina limpa
- [ ] Itch.io page com screenshots
- [ ] Trailer de 30s (captura de gameplay)
- [ ] Steam store page (requer App ID)

## TOTAL: ~150 items
### Por prioridade:
- **Critico (5)**: Chef weapon, barrier errors, health pickup, circle placeholders, gen3 mapping
- **Alto (35)**: SFX conexoes, musica conexoes, 4 armas novas
- **Medio (50)**: Efeitos visuais, monstros gen3, UI/UX, polish
- **Baixo (30)**: Performance extras, multiplayer, conteudo, docs
- **Build (5)**: Export, deploy, trailer
