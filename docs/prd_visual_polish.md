# PRD — Visual Polish & Game Feel

## Objetivo
Transformar cubos e capsulas em algo que pareca um jogo de verdade. Efeitos de particula, screen shake, damage numbers, ambiente do cemiterio com props.

---

## Particulas

### Hit Effects
- [x] Particula branca ao acertar inimigo (burst de 5-8 particulas)
- [x] Particula vermelha ao tomar dano
- [x] Particula azul ao coletar XP gem
- [x] Particula roxa ao coletar cristal
- [x] Particula dourada ao matar elite

### Death Effects
- [x] Inimigo: burst de particulas na cor do inimigo + scale down rapido
- [x] Player: explosion vermelha + slow motion 0.5s

### Weapon Effects
- [x] Katana: trail de corte (linha brilhante)
- [x] Staff: trail azul no projetil
- [x] Bazuca: smoke trail + explosao com particulas de fogo
- [x] Metralhadora: muzzle flash
- [x] Foice: trail roxo
- [x] Necro: particulas de invocacao (circulo verde no chao)

### Coleta
- [x] XP gems: glow pulsante
- [x] Cristais: rotacao + sparkle
- [x] Level up: flash branco na tela + particulas subindo

---

## Screen Effects
- [x] Screen shake ao tomar dano (intensidade proporcional)
- [x] Screen shake leve ao matar inimigos
- [x] Flash branco sutil ao dar level up
- [x] Slow motion (0.3s) ao matar o boss
- [x] Vignette escurecendo conforme HP baixa

---

## Damage Numbers
- [x] Numeros flutuantes ao causar dano (pop up e fade)
- [x] Cor: branco normal, amarelo critico, vermelho no player
- [x] Tamanho: maior = mais dano

---

## Ambiente Cemiterio
- [x] Lapides (boxes low-poly espalhados aleatoriamente)
- [x] Arvores mortas (cilindros finos com galhos)
- [x] Neblina volumetrica no chao (particula ground fog)
- [x] Lua no skybox (esfera emissiva distante)
- [x] Chao com variacao de cor (shader de noise)

---

## UI Polish
- [x] Icones de arma no HUD (retangulos coloridos por tipo)
- [x] Icones de item no HUD
- [x] Boss HP bar grande no topo durante boss fight
- [x] Dash cooldown visual (barra ou icone)
- [x] Animacao de texto "LEVEL UP!" (scale bounce)
- [x] Ally HP bars no multiplayer
- [x] Resolucao + Borderless nas opcoes
- [x] Achievement notification popup
