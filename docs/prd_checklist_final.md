# Zion — Checklist Final Completo (v2.93)

## BUGS CRITICOS
- [x] Chef starting_weapon = "flamethrower" (desabilitado) — trocar pra outra arma
- [x] 50 monstros gen3 sprites existem mas nomes nao batem no STAGE_ENEMY_SPRITES mapping
- [x] Circulos coloridos placeholder nas areas de armas melee (katana=azul, scythe=roxo, hammer=amarelo, whip=marrom)
- [x] Barrier walls no player.gd gera 24 erros is_inside_tree na criacao — corrigido com call_deferred (player.gd:139)
- [x] health_pickup.gd ainda gera 7 erros por run — corrigido com _collected guard (health_pickup.gd:11,42,81,90)
- [x] Totem area visual eh um circulo generico — mesh nulled, placeholder removed

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
- [x] lava_bubble.wav — conectar em volcano_props.gd (ambient loop)
- [x] wind.wav — conectar em space_props.gd, cemetery_props.gd (ambient loop)

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
- [x] Katana swing area — mesh nulled, placeholder circle removed
- [x] Scythe rotation — mesh nulled, placeholder circle removed
- [x] Hammer slam — mesh nulled, placeholder circle removed
- [x] Whip area — mesh nulled, placeholder circle removed
- [x] Lance thrust — mesh nulled, placeholder circle removed
- [x] Cloud sword wave — mesh nulled, placeholder circle removed
- [x] Totem aura — mesh nulled, placeholder circle removed
- [x] Poison pool — mesh nulled, placeholder circle removed

## MONSTROS GEN3 — TODOS MAPEADOS
### Cemetery (all mapped in STAGE_ENEMY_SPRITES + sprites on disk + behaviors)
- [x] cemetery_ghoul → SlimeBig
- [x] cemetery_banshee → Ghost, GhostWhite, ToothFairy (behavior: teleport)
- [x] cemetery_gravedigger → Bomber, Mimic
- [x] cemetery_rat_swarm → Swarm
- [x] cemetery_bone_knight → Tank (behavior: charge)

### Forest (all mapped + sprites on disk + behaviors)
- [x] forest_fairy → Swarm, ToothFairy
- [x] forest_vine → Tank
- [x] forest_bear → SlimeBig (behavior: charge)
- [x] forest_owl → Bomber, GhostBlue
- [x] forest_wisp → Ghost, GhostWhite (behavior: flying)

### Farm (all mapped + sprites on disk)
- [x] farm_bull → SlimeBig
- [x] farm_rat → Bomber, Mimic
- [x] farm_goat → Tank
- [x] farm_bee_swarm → Swarm, ToothFairy
- [x] farm_worm → Ghost, GhostWhite

### Tokyo (all mapped + sprites on disk + behaviors)
- [x] tokyo_yakuza → Swarm
- [x] tokyo_cyborg → SlimeBig, GhostRed
- [x] tokyo_hologram → Ghost, GhostWhite, ToothFairy (behavior: stealth)
- [x] tokyo_turret → Tank
- [x] tokyo_virus → Bomber, GhostGreen

### Volcano (all mapped + sprites on disk)
- [x] volcano_phoenix → Bomber, GhostRed
- [x] volcano_lava_snake → SlimeBig, Mimic
- [x] volcano_ash_ghost → Ghost, GhostWhite
- [x] volcano_fire_bat → Bat, GhostBlue
- [x] volcano_obsidian_golem → Tank

### Ocean (all mapped + sprites on disk)
- [x] ocean_shark → Tank
- [x] ocean_pufferfish → SlimeBig (behavior: explode_on_death)
- [x] ocean_eel → Swarm, GhostGreen
- [x] ocean_seahorse → Ghost, GhostWhite, ToothFairy
- [x] ocean_octopus → Bomber, GhostRed

### Arena (all mapped + sprites on disk)
- [x] arena_archer → Bomber, SkeletonArcher
- [x] arena_tiger → SlimeBig, Mimic
- [x] arena_prisoner → Ghost, GhostWhite
- [x] arena_eagle → Bat, ToothFairy
- [x] arena_net_fighter → Tank

### Space (all mapped + sprites on disk)
- [x] space_robot → Bomber, Mimic
- [x] space_tentacle → SlimeBig
- [x] space_crystal → Ghost, GhostWhite, ToothFairy
- [x] space_worm → Swarm
- [x] space_sentinel → Tank

### Castle (all mapped + sprites on disk + behaviors)
- [x] castle_ghost_maid → Ghost, GhostWhite, ToothFairy
- [x] castle_rat_king → Bomber
- [x] castle_skeleton_mage → Tank, SkeletonArcher
- [x] castle_bat_swarm → Swarm
- [x] castle_cursed_armor → SlimeBig, Mimic

### Candy (all mapped + sprites on disk)
- [x] candy_chocolate_golem → SlimeBig
- [x] candy_ice_cream_cone → Bomber
- [x] candy_cotton_candy_ghost → Ghost, GhostWhite
- [x] candy_cake_mimic → Tank, Mimic
- [x] candy_sour_worm → Swarm

## PERFORMANCE
- [x] Reduzir props por stage: cemetery 105→65, outros similar
- [x] Expandir ObjectPool pra staff_projectile, ice_crystal, magic_book page, shuriken
- [x] Cachear texturas de sprites (evitar load() repetido) — static _sprite_cache dict em enemy_base.gd:36
- [ ] Bullet trail — adicionar rastro visual (so quando FPS > 45)
- [ ] MultiMesh pra pickups quando > 100 no chao

## UI/UX
- [x] Barra de XP — mostrar quanto falta pro proximo nivel — texto "X/Y" sobreposto na barra (hud.gd:128-136,269)
- [x] Timer mais visivel — font size 18, pulsa vermelho quando < 3 min restantes (hud.gd:175,274-282)
- [x] Boss HP bar — nome do boss + icone acima da barra
- [x] Dash cooldown — indicador visual no HUD com barra + label numerico (hud.gd:12,166-172,571-580)
- [x] Tela de pausa — mostrar inventario resumido (armas + itens equipados)
- [x] Options: slider de volume com preview de som — preview adicionado
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
- [x] Personagem desbloqueavel por completar todos stages: "Fragmentado" — adicionado
- [x] Evento especial: "Eclipse Total" — tela escurece, inimigos brilham, bonus XP

## POLISH
- [ ] Tela titulo: logo do jogo (sprite ou texto estilizado) — atualmente texto "ZION" simples
- [x] Animacao de transicao entre menus (fade + slide) — LoadingScreen autoload com fade transitions
- [x] Efeito de poeira ao andar — Sprite3D dust spawns a cada 0.2s no player (FPS > 40)
- [x] Inimigos piscam vermelho ao tomar dano (adicionar ao squash-stretch)
- [x] XP gems brilham mais — modulate 1.2,1.2,1.5 aplicado
- [x] Cristais giram mais rapido — spin rate 5.0
- [x] Boss HP bar pulsa quando boss < 25% HP — implementado em hud.gd:558-562
- [x] Camera shake diferenciado: enemy hit 0.03, enemy kill 0.03, player hit 0.08+, boss entrance 0.35, boss death 0.5

## DOCUMENTACAO
- [ ] Atualizar CLAUDE.md com estado atual (sprites, 32 armas, 14 chars, etc.)
- [ ] Atualizar README.md pro publico
- [ ] Atualizar gdd.md com mecanicas novas (sinergias, mutacoes, etc.)
- [ ] Atualizar personagens.md com Amazona e Bruxa
- [ ] Atualizar fases.md com mecanicas de stage
- [ ] Atualizar itens.md com 4 novas armas
- [x] Atualizar balance_analysis.md com DPS das novas armas

## BUILD/DEPLOY
- [ ] Export preset Windows Desktop
- [ ] Testar export em maquina limpa
- [ ] Itch.io page com screenshots
- [ ] Trailer de 30s (captura de gameplay)
- [ ] Steam store page (requer App ID)

## TOTAL: ~150 items (~125 concluidos, ~25 pendentes)
### Por prioridade:
- **Critico (5/5 DONE)**: Chef weapon, barrier errors, health pickup, circle placeholders, gen3 mapping
- **Alto (35/35 DONE)**: SFX conexoes, musica conexoes, 4 armas novas
- **Medio (~10 pendentes)**: UI/UX restantes (1), conteudo (2), performance (2)
- **Baixo (~15 pendentes)**: Multiplayer (2), docs (5), build (5)
