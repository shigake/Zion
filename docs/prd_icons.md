# PRD - Sistema de Icones

## Objetivo

Criar icones para todos os elementos do jogo Zion, substituindo placeholders de texto/cor por icones visuais consistentes.

## Especificacoes Tecnicas

- **Formato**: SVG (vetorial, escalavel, leve)
- **Tamanho base**: 64x64 viewBox
- **Estilo**: Flat design com bordas arredondadas, cores vibrantes, fundo transparente
- **Paleta**: Cores consistentes por elemento (fogo=vermelho/laranja, gelo=azul/ciano, eletrico=amarelo, dark=roxo, poison=verde, physical=cinza)

## Estrutura de Pastas

```
game/assets/icons/
  weapons/       # 28 icones
  items/         # 19 icones
  characters/    # 12 icones
  relics/        # 7 icones
  evolutions/    # 12 icones
  upgrades/      # 12 icones
  achievements/  # 13 icones
  stages/        # 10 icones
  ui/            # icones de sistema
```

## Inventario Completo

### Armas (28)

| ID | Nome | Tipo | Elemento | Descricao do Icone |
|---|---|---|---|---|
| katana | Espada Samurai | melee | physical | Katana japonesa curvada |
| staff | Staff Magico | ranged | ice | Cajado com cristal de gelo no topo |
| scythe | Foice | melee | dark | Foice sombria com lamina roxa |
| machinegun | Metralhadora | ranged | electric | Metralhadora moderna com raios |
| bazooka | Bazuca | ranged | fire | Lancador de foguetes com chamas |
| necro | Necromante | summon | dark | Crânio flutuante com aura roxa |
| axe | Machado Viking | ranged | fire | Machado viking com fogo |
| shuriken | Shuriken | ranged | ice | Estrela ninja com gelo |
| drone | Drone | summon | electric | Drone tech com helices |
| totem | Totem Eletrico | summon | electric | Totem tribal com raios |
| poison_bottle | Garrafa de Veneno | ranged | poison | Garrafa com liquido verde borbulhante |
| lightning_chain | Relampago em Cadeia | summon | electric | Raio bifurcado |
| magic_book | Livro Magico | melee | physical | Livro aberto com runas brilhantes |
| whip | Chicote | melee | physical | Chicote enrolado |
| lance | Lanca | melee | physical | Lanca medieval |
| hammer | Martelo | melee | physical | Martelo de guerra |
| nunchaku | Nunchaku | melee | physical | Nunchaku com corrente |
| dual_katana | Katana Dupla | melee | physical | Duas katanas cruzadas |
| dual_pistol | Pistola Dupla | ranged | physical | Duas pistolas cruzadas |
| flamethrower | Lancachamas | ranged | fire | Lancachamas com labaredas |
| ice_staff | Cajado de Gelo | ranged | ice | Cajado congelado com flocos |
| crossbow | Crossbow | ranged | physical | Besta com flecha |
| plasma_cannon | Plasma Cannon | ranged | electric | Canhão futurista com plasma |
| cloud_sword | Espada Cloud | melee | physical | Espada buster grande (estilo FF7) |
| elven_bow | Arco Elfico | ranged | physical | Arco elegante elfico |
| boxing_gloves | Luvas de Boxe | melee | physical | Par de luvas vermelhas |
| time_bomb | Bomba Relogio | summon | fire | Bomba com relogio |
| portal_weapon | Portal | summon | dark | Portal circular roxo/negro |

### Itens Passivos (19)

| ID | Nome | Descricao do Icone |
|---|---|---|
| boots | Botas de Hermes | Botas aladas douradas |
| glove | Luva de Velocidade | Luva com linhas de velocidade |
| heart | Coracao de Dragao | Coracao vermelho brilhante |
| crystal | Cristal Arcano | Cristal geometrico roxo |
| magnet | Ima | Ima em U vermelho/azul |
| clock | Relogio Quebrado | Relogio com vidro rachado |
| cape | Capa das Sombras | Capa escura esvoaçante |
| xp_amulet | Amuleto de XP | Amuleto dourado com estrela |
| gunpowder | Polvora Extra | Barril de polvora |
| tesla | Bateria Tesla | Bobina com raios |
| vampire_blood | Sangue de Vampiro | Frasco de sangue vermelho escuro |
| thorn_shield | Escudo de Espinhos | Escudo com espinhos |
| lucky_coin | Moeda da Sorte | Moeda dourada brilhante |
| quiver | Aljava Infinita | Aljava com flechas infinitas |
| grimoire | Grimorio Negro | Livro negro com pentagrama |
| giant_elixir | Elixir de Gigante | Pocao verde grande |
| gasoline | Gasolina | Galao de gasolina vermelho |
| crown | Coroa | Coroa dourada com joias |
| laser_sight | Mira Laser | Mira com ponto laser vermelho |

### Personagens (12)

| ID | Nome | Descricao do Icone |
|---|---|---|
| ronin | Ronin | Rosto com bandana e olhar determinado |
| soldado | Soldado | Rosto com capacete militar |
| mago | Mago | Rosto com chapeu de mago |
| berserker | Berserker | Rosto furioso com chifres |
| ninja | Ninja | Rosto com mascara ninja |
| necro | Necro | Rosto palido com capuz |
| pirata | Pirata | Rosto com tapa-olho e chapeu |
| engenheiro | Engenheiro | Rosto com oculos e capacete |
| vampiro | Vampiro | Rosto palido com presas |
| gladiador | Gladiador | Rosto com elmo romano |
| chef | Chef | Rosto com chapeu de chef |
| mystery | ??? | Silhueta com interrogacao |

### Reliquias (7)

| ID | Nome | Descricao do Icone |
|---|---|---|
| hourglass | Ampulheta | Ampulheta dourada com areia |
| golden_dice | Dados de Ouro | Dado dourado brilhante |
| extra_heart | Coracao Extra | Coracao com sinal de + |
| compass | Bussola | Bussola com agulha magnetica |
| scroll | Pergaminho Antigo | Pergaminho enrolado |
| veteran_medal | Medalha de Veterano | Medalha militar com estrela |
| master_key | Chave Mestre | Chave ornamentada dourada |

### Evolucoes (12)

| ID | Nome | Descricao do Icone |
|---|---|---|
| zangetsu | Zangetsu | Katana negra com aura vermelha |
| apocalypse_staff | Cajado do Apocalipse | Cajado com cristal flamejante |
| death_scythe | Death Scythe | Foice enorme com aura de morte |
| nuke_launcher | Nuke Launcher | Bazuca nuclear com simbolo radioativo |
| ragnarok_axe | Machado de Ragnarok | Machado flamejante epico |
| blizzard_star | Estrela do Blizzard | Shuriken de gelo gigante com nevasca |
| minigun_infernal | Minigun Infernal | Minigun com chamas infernais |
| lord_of_dead | Senhor dos Mortos | Cranio coroado com exercito de mortos |
| inferno_walker | Inferno Walker | Lancachamas demoníaco |
| vampire_whip | Vampire Whip | Chicote de sangue |
| electric_storm | Tempestade Eletrica | Tempestade com multiplos raios |
| arrow_storm | Tempestade de Flechas | Chuva de flechas |

### Upgrades da Loja (12)

| ID | Nome | Descricao do Icone |
|---|---|---|
| max_hp | HP Maximo | Coracao com seta pra cima |
| speed | Velocidade | Bota com asas |
| damage | Dano Base | Espada com seta pra cima |
| armor | Armadura | Escudo metalico |
| xp_bonus | XP Bonus | Estrela com +XP |
| magnetism | Magnetismo | Ima grande |
| cooldown_reduction | Cooldown | Relogio com seta rapida |
| luck | Sorte | Trevo de 4 folhas |
| revive | Revive | Fenix renascendo |
| weapon_slots | Slots de Arma | Grade com espadas |
| reroll_shop | Reroll Extra | Dados girando |
| banish_shop | Banish | X vermelho com proibido |

### Achievements (13)

| ID | Nome | Descricao do Icone |
|---|---|---|
| first_walk | Meu Primeiro Passeio | Pegadas com relogio 5min |
| evolved_6 | Isso Escala | 6 setas pra cima douradas |
| speedrunner | Speedrunner | Cronometro com raio |
| collector | Colecionador | Album completo com check |
| cow_brejo | A Vaca Foi Pro Brejo | Vaca com aureola |
| nobody_deserves | Ninguem Merece | Caveira com 10s |
| genocide | Genocidio | Cranio com 10K |
| sweet_revenge | Doce Vinganca | Cupcake com cara malefica |
| storm | I Am The Storm | 3 raios |
| pacifist | Pacifista | Pomba da paz |
| matrix | Matrix | Boneco desviando balas |
| one_punch | One Punch | Punho com estrela de impacto |
| lucky_day | Lucky Day | 5 estrelas douradas |

### Stages (10)

| ID | Nome | Descricao do Icone |
|---|---|---|
| cemetery | Cemiterio | Lapide com lua cheia |
| forest | Floresta | Arvore magica com brilho |
| farm | Fazenda | Celeiro com cerca |
| tokyo | Tokyo Cyberpunk | Predio neon com kanji |
| volcano | Vulcao | Vulcao em erupcao |
| ocean | Oceano | Onda com ancora |
| arena | Arena | Coliseu com espadas |
| space | Estacao Espacial | Estacao orbital com estrelas |
| castle | Castelo do Vampiro | Castelo gotico com morcegos |
| candy | Mundo Doce | Pirulito com doces |

### UI/Sistema (8)

| ID | Descricao |
|---|---|
| lock | Cadeado |
| currency | Cristal (moeda do jogo) |
| hp | Coracao de vida |
| xp | Barra/estrela de experiencia |
| timer | Relogio |
| kill_count | Cranio contador |
| element_fire | Chama |
| element_ice | Floco de neve |
| element_electric | Raio |
| element_dark | Lua crescente |
| element_poison | Gota toxica |
| element_physical | Espada |

## Total: 133 icones

## Implementacao

1. Gerar todos os SVGs programaticamente
2. Salvar em `game/assets/icons/{categoria}/{id}.svg`
3. Atualizar databases (weapon_db, item_db, etc.) com campo `icon_path`
4. Atualizar UI (level_up_screen, shop, character_select, etc.) para exibir icones
