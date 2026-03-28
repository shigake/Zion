# PRD: Pendencias — O que falta polir

## Visual

### Efeitos faltando (circulos azul/amarelo placeholder)
Varias armas/efeitos ainda mostram circulos coloridos genericos ao inves de efeitos visuais proprios:

| Efeito | Situacao Atual | O que deveria ser |
|--------|---------------|-------------------|
| Katana swing area | Circulo azul transparente | Arco de corte brilhante |
| Scythe rotation | Circulo roxo girando | Trail roxo ao redor do player |
| Whip crack | Circulo marrom | Linha ondulada de chicote |
| Hammer ground slam | Circulo amarelo | Onda de choque no chao |
| Lance thrust | Linha azul | Linha reta com brilho na ponta |
| Cloud sword wave | Circulo grande azul | Onda de energia cortante |
| Totem aura | Circulo eletrico | Raios eletricos pulsando |
| Poison pool | Circulo verde | Poca toxica com bolhas |
| Flamethrower cone | Circulo laranja | Cone de chamas (DESABILITADO) |

**Solucao**: Substituir as Area3D de debug (circulos coloridos) por sprites Sprite3D flat no chao com texturas tematicas.

### Monstros gen3 nao integrados
50 novos sprites de monstros existem mas nomes no mapping nao batem:
- Os sprites gen3 usam nomes como `cemetery_ghoul`, `forest_fairy`, etc.
- O mapping em STAGE_ENEMY_SPRITES usa nomes diferentes como `cemetery_banshee`, `forest_wisp`, etc.
- Precisa alinhar os nomes ou mapear os novos

### Projéteis ainda pequenos
Mesmo com pixel_size 0.04, a metralhadora e dual_pistol disparam muitas balas pequenas que parecem pontos. Opcoes:
- Aumentar pixel_size pra 0.05
- Adicionar trail de 2-3 frames atras de cada bala
- Ou aumentar o sprite da bala pra 32x32

## Gameplay

### Armas novas sem scripts
As 4 novas armas (boomerang, tornado, chain_whip, blood_orb) tem dados no weapon_db mas nao tem scripts de comportamento (scenes/weapons/*.tscn + scripts/weapons/*.gd).
Precisam ser criadas:
- boomerang.gd + boomerang.tscn — vai e volta
- tornado.gd + tornado.tscn — vortex que puxa inimigos
- chain_whip.gd + chain_whip.tscn — chicote com chain
- blood_orb.gd + blood_orb.tscn — orbe que drena vida

### Chef sem starting weapon
O Chef tem `starting_weapon: "flamethrower"` mas flamethrower foi desabilitado. Precisa trocar pra outra arma.

## Audio

### SFX que precisam ser conectados
Os 33 SFX novos foram gerados mas muitos NAO estao conectados nos scripts:
- sword_slash, axe_chop, scythe_swoosh — precisam ser chamados nas armas melee
- gun_shot — precisa substituir "hit" na machinegun/dual_pistol
- bow_release — precisa ser chamado em elven_bow/crossbow
- magic_cast — precisa ser chamado em staff/ice_staff/magic_book
- explosion — precisa ser chamado no rocket/bazooka
- electric_zap — precisa ser chamado no lightning_chain/totem
- collect_crystal — precisa ser chamado no crystal_pickup
- footstep — precisa ser chamado a cada frame de walk
- achievement — precisa ser chamado no achievement_popup

### Musica da loja e vitoria
shop.wav e victory.wav foram geradas mas precisam ser tocadas:
- AudioManager.play_music("shop") quando abrir a loja
- AudioManager.play_music("victory") quando boss morrer

## Performance

### Arenas com muitos props
Alguns stages criam 100+ Sprite3D props que nao sao necessarios pra gameplay. Reduzir:
- Tombstones de 45+35+25=105 pra 30+20+15=65
- Outros stages similar

### Object Pool expandir
Bullets e rockets usam ObjectPool mas outros projectiles nao. Expandir pool pra:
- Staff projectile
- Ice crystal
- Magic book page
- Shuriken projectile

## Prioridades

1. **Conectar SFX** — impacto imediato na experiencia
2. **Efeitos de arma** — substituir circulos por sprites
3. **Scripts das 4 armas novas** — gameplay novo
4. **Integrar monstros gen3** — mais variedade
5. **Fix Chef starting weapon** — bug
