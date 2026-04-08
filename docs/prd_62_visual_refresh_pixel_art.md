# PRD 62: Visual Refresh — Pixel Art via Blender IA

**Status**: pendente
**Prioridade**: alta
**Tipo**: arte/visual

## Objetivo

Revitalizar todos os assets visuais do jogo usando modelos 3D gerados via Hunyuan3D (IA local no Blender), renderizados como pixel art 64x64 com camera ortografica. Manter consistencia visual entre todos os sprites.

## Contexto

O jogo tem 450+ sprites. Muitos sao placeholders minimalistas (< 400 bytes). Os icones de armas ja foram atualizados (v4.6.4) com renders dos modelos 3D. Este PRD expande essa abordagem para todos os assets restantes.

## Pipeline de producao

1. Criar modelo 3D no Blender (na mao ou via Hunyuan3D com imagem de referencia)
2. Aplicar materiais com cores, metallic, roughness e emission
3. Normalizar escala para 1.0 unidade
4. Renderizar com camera ortografica 64x64 pixels, fundo transparente
5. Exportar como PNG RGBA
6. Substituir sprite antigo

## Fases

### Fase 1 — Efeitos e particulas (ALTA PRIORIDADE)
Sprites placeholder < 270 bytes que aparecem constantemente no gameplay.

| Sprite | Tamanho atual | Descricao |
|--------|--------------|-----------|
| collect_sparkle.png | 132 bytes | Brilho ao coletar item |
| damage_number_bg.png | 144 bytes | Fundo dos numeros de dano |
| dash_trail.png | 163 bytes | Rastro de dash |
| death_poof.png | 188 bytes | Efeito de morte |
| hit_spark.png | 182 bytes | Faísca de hit |
| level_up_flash.png | 267 bytes | Flash de level up |

### Fase 2 — Projeteis (13 sprites)
Todos < 460 bytes, aparecem em grande quantidade na tela.

| Sprite | Tamanho | Descricao |
|--------|---------|-----------|
| bullet.png | 227 bytes | Bala generica |
| arrow.png | 291 bytes | Flecha |
| axe_thrown.png | 299 bytes | Machado arremessado |
| crossbow_bolt.png | 312 bytes | Virote de besta |
| rocket.png | 304 bytes | Foguete |
| lightning_bolt.png | 304 bytes | Raio |
| ice_crystal.png | 327 bytes | Cristal de gelo |
| magic_orb.png | 360 bytes | Orbe magico |
| fireball.png | 393 bytes | Bola de fogo |
| shuriken_projectile.png | 391 bytes | Shuriken arremessada |
| staff_projectile.png | 439 bytes | Projetil do cajado |
| plasma_bolt.png | 440 bytes | Tiro plasma |
| poison_cloud.png | 458 bytes | Nuvem de veneno |

### Fase 3 — Pickups (5 sprites)
Drops que o jogador coleta constantemente.

| Sprite | Tamanho | Descricao |
|--------|---------|-----------|
| xp_gem.png | 415 bytes | Gema de XP azul |
| crystal.png | 346 bytes | Cristal dourado (moeda) |
| health_pickup.png | 360 bytes | Cura vermelha |
| magnet_pickup.png | 347 bytes | Ima azul |
| chest.png | 386 bytes | Bau de recompensa |

### Fase 4 — Icones de itens passivos (19 sprites)
Mostrados no HUD e tela de level-up.

| Sprite | Tamanho | Descricao |
|--------|---------|-----------|
| boots.png | 467 bytes | Botas de Hermes |
| glove.png | 581 bytes | Luva de velocidade |
| heart.png | 623 bytes | Coracao de dragao |
| crystal.png | 737 bytes | Cristal arcano |
| magnet.png | 434 bytes | Ima |
| clock.png | 831 bytes | Relogio quebrado |
| cape.png | 589 bytes | Capa das sombras |
| xp_amulet.png | 778 bytes | Amuleto de XP |
| gunpowder.png | 724 bytes | Polvora extra |
| tesla.png | 697 bytes | Bateria tesla |
| vampire_blood.png | 476 bytes | Sangue de vampiro |
| thorn_shield.png | 681 bytes | Escudo de espinhos |
| lucky_coin.png | 920 bytes | Moeda da sorte |
| quiver.png | 562 bytes | Aljava infinita |
| grimoire.png | 584 bytes | Grimorio negro |
| giant_elixir.png | 683 bytes | Elixir de gigante |
| gasoline.png | 568 bytes | Gasolina |
| crown.png | 671 bytes | Coroa |
| laser_sight.png | 487 bytes | Mira laser |

### Fase 5 — Icones de UI (13 sprites)
Elementos do HUD e menus.

| Sprite | Tamanho | Descricao |
|--------|---------|-----------|
| crystal_icon.png | 335 bytes | Icone cristal HUD |
| currency.png | 255 bytes | Moeda HUD |
| element_*.png | 196-284 bytes | 6 icones elementais |
| hp.png | 243 bytes | Icone HP |
| kill_count.png | 231 bytes | Icone kills |
| lock.png | 205 bytes | Cadeado |
| timer.png | 254 bytes | Relogio HUD |
| xp.png | 214 bytes | Icone XP |

### Fase 6 — Icones de stages (10 sprites)
Selecao de fenda no mapa.

| Sprite | Tamanho | Descricao |
|--------|---------|-----------|
| arena.png | 283 bytes | Arena romana |
| candy.png | 356 bytes | Mundo doce |
| castle.png | 316 bytes | Castelo gotico |
| cemetery.png | 289 bytes | Cemiterio |
| farm.png | 267 bytes | Fazenda |
| forest.png | 298 bytes | Floresta |
| ocean.png | 377 bytes | Oceano |
| space.png | 374 bytes | Espaco |
| tokyo.png | 328 bytes | Tokyo neon |
| volcano.png | 360 bytes | Vulcao |

### Fase 7 — Reliquias e evolucoes (19 sprites)
Ja tem qualidade boa, refresh para consistencia visual.

- 7 reliquias (496-950 bytes)
- 12 evolucoes (564-1.2K bytes)

### Fase 8 — Sinergias e upgrades (30 sprites)
Ja tem qualidade boa, refresh para consistencia visual.

- 18 sinergias (648-957 bytes)
- 12 upgrades (463-801 bytes)

## Criterios de aceite

- [ ] Todos os sprites tem estilo visual consistente (pixel art 3D renderizado)
- [ ] Todos os sprites sao 64x64 RGBA com fundo transparente
- [ ] Cores distintas por tipo (azul=XP, dourado=moeda, vermelho=HP, etc.)
- [ ] Nenhum sprite placeholder < 200 bytes restante
- [ ] Modelos 3D fonte salvos no Blender para futuros ajustes
- [ ] Compilado e testado no Godot sem erros

## Assets NAO incluidos neste PRD

- Sprites de personagens (32 sprites) — estilo ja consolidado, billboard pixel art
- Sprites de enemies (106 sprites) — muitos, fase separada
- Sprites de bosses (30 sprites) — qualidade ja boa
- Props de stage (103 sprites) — volume grande, fase separada
- Slash effects (12 sprites) — qualidade ja boa
- Achievement icons (13 sprites) — qualidade ja boa

## Total estimado

~100 sprites em 8 fases. Pipeline automatizado via Blender script.
