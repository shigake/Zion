# PRD: Pivot para Billboard Sprites

## Objetivo

Substituir TODOS os modelos 3D (procedurais + GLBs) por sprites pixel art 2D renderizados como billboards no mundo 3D. Estilo Vampire Survivors / Brotato / Halls of Torment.

## Justificativa

- Modelos 3D procedurais parecem "blocos"
- GLBs externos (KayKit, Quaternius) não integram bem e causam lag
- Billboard sprites são o padrão do gênero survivors roguelite
- Mais leves, mais rápidos, visual coerente
- Estilo pixel art é charmoso e atemporal

## Especificacoes Tecnicas

### Formato dos Sprites
- **Tamanho**: 32x32 pixels (personagens e inimigos), 16x16 (pickups, projeteis)
- **Formato**: PNG com transparência
- **Estilo**: Pixel art 16-bit, cores vibrantes, outline preto 1px
- **Animacoes**: Spritesheet horizontal (idle 2 frames, walk 4 frames, attack 2 frames, death 2 frames)
- **Direcao**: Frente apenas (billboard sempre vira pra camera)

### Renderizacao no Godot
- `Sprite3D` com `billboard = BaseMaterial3D.BILLBOARD_ENABLED`
- `texture_filter = TEXTURE_FILTER_NEAREST` (pixels crispy, sem blur)
- `pixel_size = 0.04` (32px * 0.04 = 1.28 unidades = ~1.3m de altura)
- `shaded = false` (cores flat, sem iluminacao 3D)
- `transparent = true` (fundo transparente)

### Animacao
- `AnimatedSprite3D` ou troca de frames manual via script
- Idle: 2 frames alternando a cada 0.5s (leve bounce)
- Walk: 4 frames a cada 0.15s (pernas alternando)
- Attack: 2 frames rapidos (0.1s cada)
- Death: 2 frames + fade out
- Hit: flash branco 0.1s (shader ou modulate)

### Estrutura de Arquivos
```
game/assets/sprites/
  characters/          # 12 personagens
    ronin.png          # Spritesheet 128x32 (4 frames idle+walk)
    ronin_attack.png   # 64x32 (2 frames)
    soldado.png
    mago.png
    berserker.png
    ninja.png
    necro.png
    pirata.png
    engenheiro.png
    vampiro.png
    gladiador.png
    chef.png
    mystery.png
  enemies/             # 11 genericos + variantes
    slime.png
    slime_big.png
    bat.png
    skeleton.png
    skeleton_archer.png
    zombie.png
    ghost.png
    ghost_white.png
    ghost_green.png
    ghost_blue.png
    ghost_red.png
    tank.png
    bomber.png
    swarm.png
    mimic.png
    tooth_fairy.png
  bosses/              # 10 bosses
    boss_necromancer.png
    boss_fairy_queen.png
    boss_alien_cow.png
    boss_ai_overlord.png
    boss_demon_lord.png
    boss_leviathan.png
    boss_emperor.png
    boss_singularity.png
    boss_dracula.png
    boss_sugar_king.png
  weapons/             # 28 armas (icones pequenos)
    katana.png         # 16x16
    staff.png
    ... (28 total)
  pickups/
    xp_gem.png         # 16x16
    crystal.png        # 16x16
  effects/
    hit_spark.png      # 16x16
    death_poof.png     # 32x32 (4 frames)
```

## Inventario Completo (133 sprites)

### Personagens (12 sprites, cada com idle+walk+attack+death)

| ID | Visual | Cores principais | Elementos distintos |
|----|--------|-----------------|---------------------|
| ronin | Samurai esbelto | Verde + vermelho | Headband vermelha, katana nas costas, hakama |
| soldado | Militar robusto | Verde militar | Capacete, mochila, ombreiras |
| mago | Mago barbudo | Roxo + dourado | Chapeu pontudo, barba branca, orbe azul |
| berserker | Viking musculoso | Vermelho escuro | Chifres no capacete, sem camisa, machado |
| ninja | Shinobi agil | Preto + vermelho | Mascara, cachecol, olhos vermelhos |
| necro | Necromante sombrio | Verde escuro | Capuz, olhos verdes brilhantes, cajado caveira |
| pirata | Capitao pirata | Marrom + dourado | Chapeu tricornio, tapa-olho, duas pistolas |
| engenheiro | Engenheiro inventor | Amarelo + cinza | Oculos de protecao, macacao, chave inglesa |
| vampiro | Vampiro elegante | Vermelho carmesim | Capa longa, pele palida, presas |
| gladiador | Gladiador romano | Dourado + bronze | Armadura romana, escudo, lanca |
| chef | Chef cozinheiro | Branco + vermelho | Chapeu de chef alto, bigode, frigideira |
| mystery | Entidade glitchada | Verde neon + preto | Corpo pixelado/glitchado, "?" no peito |

### Inimigos Genericos (16 sprites)

| ID | Visual | Tamanho | Cores |
|----|--------|---------|-------|
| slime | Gota gelatinosa | 32x32 | Verde, olhinhos brancos |
| slime_big | Slime 2x | 48x48 | Verde escuro, slimes dentro |
| bat | Morcego asas abertas | 32x32 | Roxo escuro, olhos amarelos |
| skeleton | Esqueleto andando | 32x32 | Branco/bege, maxilar articulado |
| skeleton_archer | Esqueleto com arco | 32x32 | Branco + arco marrom |
| zombie | Zumbi corredor | 32x32 | Verde podre, roupas rasgadas |
| ghost | Fantasma flutuante | 32x32 | Branco translucido |
| ghost_white | Fantasma branco | 32x32 | Branco puro |
| ghost_green | Fantasma verde | 32x32 | Verde ectoplasma |
| ghost_blue | Fantasma azul | 32x32 | Azul gelado |
| ghost_red | Fantasma vermelho | 32x32 | Vermelho fogo |
| tank | Bruto com escudo | 32x32 | Cinza escuro, escudo grande |
| bomber | Criatura com bomba | 32x32 | Vermelho, bomba nas costas |
| swarm | Enxame de insetos | 32x32 | Marrom/preto, muitos pontos |
| mimic | Bau com dentes | 32x32 | Marrom madeira, dentes brancos |
| tooth_fairy | Fada dente | 24x24 | Rosa, asas brilhantes |

### Bosses (10 sprites, 64x64 para presenca maior)

| ID | Visual | Tamanho | Cores |
|----|--------|---------|-------|
| boss_necromancer | Mago gigante com cajado | 64x64 | Roxo escuro, aura verde |
| boss_fairy_queen | Fada com asas borboleta | 64x64 | Verde + rosa, coroa de flores |
| boss_alien_cow | Vaca com tech alienigena | 64x64 | Branco + verde neon |
| boss_ai_overlord | Entidade digital | 64x64 | Cyan + preto, cara de monitor |
| boss_demon_lord | Demonio classico | 64x64 | Vermelho, chifres, asas |
| boss_leviathan | Serpente marinha | 64x96 | Azul escuro, tentaculos |
| boss_emperor | Imperador romano corrompido | 64x64 | Dourado, armadura ornamentada |
| boss_singularity | Buraco negro | 64x64 | Preto + roxo, anel de acrecao |
| boss_dracula | Vampiro aristocrata | 64x64 | Vermelho + preto, capa |
| boss_sugar_king | Rei de doces derretendo | 64x64 | Rosa + multicolorido |

### Armas (28 sprites, 16x16)

Todas as 28 armas como icone pixel art 16x16.

### Pickups (4 sprites, 16x16)
- xp_gem (azul brilhante)
- crystal (dourado girando)
- health_pickup (coracao vermelho)
- magnet_pickup (ima cinza)

### Efeitos (6 sprites)
- hit_spark (16x16, 2 frames)
- death_poof (32x32, 4 frames)
- level_up_flash (32x32, 3 frames)
- dash_trail (16x32, 2 frames)
- collect_sparkle (16x16, 3 frames)
- damage_number_bg (decorativo)

## Implementacao

### Fase 1 — Personagens + Slime (POC) ✓
- [x] Gerar sprites base (ronin, soldado, mago, slime)
- [x] Testar billboard rendering
- [x] Validar visual e escala

### Fase 2 — Todos os Inimigos (16 sprites)
- [ ] Gerar todos 16 sprites de inimigos
- [ ] Substituir `_apply_procedural_model()` no enemy_base.gd por Sprite3D
- [ ] Testar in-game com spawning

### Fase 3 — Todos os Personagens (12 sprites)
- [ ] Gerar os 9 personagens restantes
- [ ] Walk animation (4 frames)
- [ ] Substituir modelo do player por AnimatedSprite3D
- [ ] Atualizar character_select pra mostrar sprites

### Fase 4 — Bosses (10 sprites, 64x64)
- [ ] Gerar todos 10 boss sprites
- [ ] Integrar nos boss scripts

### Fase 5 — Armas + Pickups + Efeitos
- [ ] 28 weapon sprites (16x16)
- [ ] 4 pickup sprites
- [ ] 6 effect sprites
- [ ] Substituir weapon meshes por sprites
- [ ] Substituir pickup meshes por sprites

### Fase 6 — Cleanup
- [ ] Remover ModelFactory procedural models (ou manter como fallback)
- [ ] Remover Quaternius/KayKit assets nao usados
- [ ] Remover model_factory.gd funcoes de modelo procedural
- [ ] Atualizar docs

## Modificacoes de Codigo Necessarias

### enemy_base.gd
```gdscript
# Substituir _apply_procedural_model() por:
func _apply_sprite() -> void:
    var enemy_type = _get_base_enemy_type()
    var sprite_path = "res://assets/sprites/enemies/%s.png" % enemy_type.to_snake_case()
    if not ResourceLoader.exists(sprite_path):
        sprite_path = "res://assets/sprites/enemies/slime.png"  # fallback
    var sprite = Sprite3D.new()
    sprite.texture = load(sprite_path)
    sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    sprite.pixel_size = 0.04
    sprite.shaded = false
    sprite.transparent = true
    sprite.name = "Sprite"
    add_child(sprite)
```

### player.gd
```gdscript
# Substituir modelo procedural por AnimatedSprite3D
# Walk animation: troca frames baseado em velocity
# Hit: modulate = Color(10, 10, 10) por 0.1s (flash branco)
```

### character_select.gd
```gdscript
# Usar Sprite3D no SubViewport em vez de modelo 3D
# Ou mostrar sprite 2D direto na UI (TextureRect)
```

## Total de Assets
- 12 personagens (com animacoes)
- 16 inimigos genericos
- 10 bosses
- 28 armas
- 4 pickups
- 6 efeitos
- **Total: ~76 sprites + spritesheets**

## Estimativa
- Geracao de sprites: automatizada via sprite_generator.gd
- Integracao no codigo: ~6 arquivos principais
- Teste e polish: ajuste de escala, cores, animacoes
