# PRD 62 — Armas AoE: tiros e danos em área com visual 3D premium

**Status**: pendente
**Prioridade**: alta
**Tipo**: polish visual / direção de arte / produção 3D / game feel

---

## Problema

Hoje, as armas com dano em área já funcionam no gameplay, mas o resultado visual ainda parece provisório. Em vários casos:

- o projétil principal ainda parece simples demais para um jogo 3D
- a leitura do impacto não tem profundidade suficiente
- a zona de dano em área não conversa bem com o volume real do hitbox
- há mistura de `Sprite3D`, meshes primitivos, partículas genéricas e efeitos sem linguagem visual unificada
- vários efeitos estão tecnicamente "ok", mas ainda não estão bonitos, charmosos, premium e memoráveis

Na prática, o jogador vê o dano acontecer, mas não sente que está disparando uma arma AoE heroica. Falta:

- silhueta forte
- profundidade
- materiais melhores
- animação com mais vida
- camadas de FX mais legíveis
- consistência entre disparo, impacto, linger e dissipação

---

## Objetivo

Dar um passe visual completo em **todas as famílias de armas AoE** para que:

- os tiros sejam claramente 3D
- o dano em área tenha presença, volume e boa leitura
- os efeitos sejam "bem bonitinhos" no melhor sentido: estilizados, charmosos, gostosos de ver e com apelo premium
- cada arma tenha identidade própria, mas ainda pareça pertencer ao mesmo jogo
- o raio visual do efeito seja coerente com o raio real de gameplay

---

## Meta de qualidade visual

O alvo não é "efeito técnico funcional". O alvo é:

- **3D de verdade** para os elementos hero da arma
- **direção de arte sênior**, não placeholder procedural com acabamento de protótipo
- leitura clara vista de cima em combate caótico
- impacto satisfatório mesmo com dezenas de inimigos na tela
- visual com personalidade, cor, ritmo e camadas

Regra central deste PRD:

- `Sprite3D` pode continuar existindo apenas para micro-partículas secundárias, faíscas pequenas ou fallback de performance
- o **shape principal** do tiro, da explosão, da poça, do cone, da aura ou do vórtice não pode depender de billboard 2D como solução final

---

## Escopo

### Dentro do escopo

- projétil principal
- charge-up visual
- impacto principal
- zona de dano persistente
- shockwave / anel de área
- dissipação final
- variantes evoluídas que reutilizam a mesma família visual

### Fora do escopo

- slashes melee sem componente de área persistente
- VFX de morte dos inimigos
- UI, ícones e thumbnails
- telegraphs de bosses e inimigos

---

## Cobertura obrigatória

Este PRD cobre as seguintes famílias AoE:

| Família | Armas incluídas | Problema atual | Entrega visual esperada |
|---|---|---|---|
| Explosão pesada | `bazooka`, `nuke_launcher` | foguete e explosão ainda sem acabamento premium | foguete hero 3D + explosão em camadas + shockwave de chão + fumaça bonita |
| Veneno de solo | `poison_bottle` | poça e splash ainda com leitura pouco elegante | garrafa 3D, splash tóxico, poça irregular premium, vapor venenoso bonito |
| Vórtice | `tornado` | vórtice ainda parece técnico e não memorável | tornado estilizado, com ribbons, debris e sucção forte |
| Emissor fixo de área | `totem` | já é 3D, mas ainda parece bloco procedural | totem hero com modelagem forte, cristal central e campo elétrico bonito |
| Cone contínuo | `flamethrower`, `inferno_walker` | cone ainda sem shape de fogo premium | lança-chamas volumétrico, combustão contínua, brasas e trilha de fogo convincente |
| Gelo explosivo | `ice_staff` | projétil e burst ainda pouco heroicos | cristal 3D bonito, impacto com shards, névoa fria e freeze ring |
| Beam de energia | `plasma_cannon` | beam e charge já existem, mas sem acabamento final sênior | núcleo de carga, feixe com camadas, bloom, impacto e dissipação premium |
| Explosivo de chão | `time_bomb` | bomba já cumpre função, mas ainda parece montagem de primitives | bomba hero, fuse bonito, contagem clara, explosão forte e debris |
| Implosão espacial | `portal_weapon` | portal funciona, mas ainda não tem look final marcante | portal com profundidade, distorção, sucção, núcleo e burst de saída |
| Aura de drenagem | `blood_orb` | orb 3D atual é funcional, mas ainda rough | orbe premium, shell viva, aura blood-magic, tether de drenagem e heal pulse |
| Eletricidade em área | `lightning_chain`, `electric_storm` | arco elétrico ainda técnico demais | bolts estilizados, branching bonito, nodos de impacto e strikes premium |
| Chuva / meteoros | `apocalypse_staff`, `arrow_storm` | família AoE evoluída precisa mesma régua de qualidade | meteoros, impacto, chuva e decals com mesma linguagem visual do resto |

---

## Direção visual compartilhada

Todas as famílias acima devem seguir as mesmas regras de linguagem:

### 1. Silhueta forte

Cada arma AoE precisa ser reconhecível em menos de 0.3s:

- bazuca: massa e explosão pesada
- veneno: orgânico, líquido, tóxico
- tornado: espiral e verticalidade
- totem: altar / foco energético
- lança-chamas: cone de calor e turbulência
- gelo: cristalino e afiado
- plasma: sci-fi limpo e concentrado
- bomba: massa, fuse e blast
- portal: profundidade e distorção
- blood orb: magia sanguínea viva
- eletricidade: energia nervosa e ramificada

### 2. Regra das 4 camadas

Toda arma AoE deve ter, no mínimo:

1. `Core`: forma principal da arma ou impacto
2. `Accent`: glow, ring, ribbon, sparks ou fragments
3. `Area Read`: elemento que deixa claro onde o dano acontece
4. `Exit`: fade, dissipação, fumaça, brasas, neblina, poeira ou resíduos

### 3. Coerência com gameplay

- o raio visual deve bater com o raio real em até `±10%`
- a altura do efeito não pode esconder inimigos demais
- a opacidade nunca pode comprometer legibilidade do player
- o efeito precisa continuar bonito em `1x`, `3x` e `6x` inimigos simultâneos

### 4. Regra de materiais

- preferir `StandardMaterial3D` ou shader simples e barato
- emissive deve existir, mas sem virar borrão branco
- alpha deve ser usada com intenção, não como muleta
- look final: low-poly estilizado premium, não realista e não neon genérico

### 5. Regra de performance

- evitar criar mesh/material por frame
- hero meshes compartilhados por família sempre que possível
- partículas principais com budget fixo por instância
- fallback de qualidade baixa permitido, mas não como look padrão

---

## Especificação por família

## 1. Bazuca / Nuke Launcher

### Entregáveis

- foguete 3D hero com corpo, aletas e exaustão
- trilha com fumaça e fogo
- explosão em 3 camadas:
  - flash central
  - anel de pressão
  - volume de fumaça
- decal / ring de impacto no chão
- mushroom cloud para `nuke_launcher`

### Sensação desejada

- pesada
- destrutiva
- satisfatória
- com leitura instantânea de splash radius

---

## 2. Garrafa de Veneno

### Entregáveis

- garrafa 3D arremessável, com vidro estilizado e líquido interno
- splash no momento do impacto
- poça irregular premium, não um disco simples
- gotículas e respingos periféricos
- vapor tóxico baixo e bonito
- ring sutil de área para leitura

### Sensação desejada

- tóxica
- viva
- borbulhante
- nojenta de um jeito bonito

---

## 3. Tornado

### Entregáveis

- funil principal com silhueta forte
- ribbon secundário em contra-rotação
- debris orbitando
- sucção visual no chão
- dissipação elegante no final

### Sensação desejada

- vertical
- instável
- com força de puxão perceptível

---

## 4. Totem Elétrico

### Entregáveis

- modelo hero do totem
- base, corpo e cabeça bem desenhados
- cristal / núcleo central premium
- arcos elétricos com variação viva
- anel de área bonito no chão
- estado idle, tick de dano e dissipação

### Sensação desejada

- artefato místico-tech de Zion
- bonito mesmo parado

---

## 5. Lança-chamas / Inferno Walker

### Entregáveis

- cone de fogo volumétrico convincente
- chamas em camadas, não só um mesh aberto
- ember particles e heat shimmer melhores
- início, sustain e fim do cone bem definidos
- trilha de fogo no chão para `inferno_walker`
- solo queimado / residue curto para leitura

### Sensação desejada

- calor
- pressão
- queimadura contínua

---

## 6. Cajado de Gelo

### Entregáveis

- projétil cristalino hero
- trail frio bonito
- burst de impacto com shards
- freeze mist
- freeze ring coerente com o raio

### Sensação desejada

- afiado
- frio
- elegante
- cristalino

---

## 7. Plasma Cannon

### Entregáveis

- charge core bonito e premium
- muzzle energy ring
- beam com core + shell + bloom
- impacto final com flare e vapor energético
- dissipação rápida e limpa

### Sensação desejada

- sci-fi
- controlado
- poderoso
- tecnológico

---

## 8. Time Bomb

### Entregáveis

- bomba hero com shape marcante
- fuse claro e visualmente gostoso
- countdown mais charmoso
- explosão com peso
- debris / fragments
- ring de chão forte e legível

### Sensação desejada

- tensão
- payoff
- explosão divertida

---

## 9. Portal Weapon

### Entregáveis

- portal com profundidade real
- inner core escuro / volumétrico
- borda energética premium
- partículas de sucção
- implosão + burst de saída
- leitura clara do centro do evento

### Sensação desejada

- distorção espacial
- magia dark / dimensional
- evento raro e especial

---

## 10. Blood Orb

### Entregáveis

- orb hero com shell, core e detalhes orbitais premium
- aura de área de drenagem mais bonita
- tether de drenagem entre orb e inimigo
- pulse de cura no player
- dissipação final orgânica

### Sensação desejada

- viva
- sombria
- luxuosa
- mágica

---

## 11. Lightning Chain / Electric Storm

### Entregáveis

- bolts com shape mais autoral
- branching secundário bonito
- impact node em cada alvo
- strike marker premium para tempestade
- glow controlado
- estado de chain e estado de storm compartilhando a mesma família

### Sensação desejada

- nervosa
- rápida
- elétrica
- bonita sem virar bagunça visual

---

## 12. Apocalypse Staff / Arrow Storm

### Entregáveis

- meteoros 3D hero com trail e crater look
- chuva de flechas com leitura de origem e impacto
- area burst bonito no chão
- dissipação coerente com a família base

### Sensação desejada

- evento raro
- ultimate
- grandioso

---

## Diretriz de produção

O time técnico pode:

- preparar hooks
- ajustar scripts
- integrar meshes
- otimizar materiais
- configurar particles

Mas **não deve tratar primitives atuais como acabamento final**.

### TODO obrigatório

- [ ] Alocar **designer sênior de 3D/VFX** para modelar e dirigir o passe final das armas AoE
- [ ] Definir kit visual por família: mesh hero, material hero, partículas hero e decal/ring hero
- [ ] Fazer revisão de silhueta e leitura em câmera real de gameplay
- [ ] Aprovar cada família com comparativo `antes x depois`

### Responsabilidade esperada do designer sênior

- modelar os assets hero das famílias AoE
- definir palette, material e acabamento
- elevar os placeholders procedurais para visual final
- garantir que o efeito fique bonito em movimento, não só parado
- fechar a linguagem visual comum entre fantasy, sci-fi e dark magic sem parecer jogo remendado

---

## Arquivos mais impactados

| Área | Arquivos prováveis |
|---|---|
| Armas | `game/scripts/weapons/bazooka.gd`, `rocket.gd`, `poison_bottle.gd`, `tornado.gd`, `totem.gd`, `flamethrower.gd`, `ice_staff.gd`, `ice_staff_projectile.gd`, `plasma_cannon.gd`, `time_bomb.gd`, `portal_weapon.gd`, `blood_orb.gd`, `lightning_chain.gd` |
| FX compartilhado | `game/scripts/weapons/weapon_vfx.gd`, `game/scripts/effects/particle_factory.gd`, `game/scripts/effects/model_factory.gd` |
| Assets | `game/assets/models/weapons/`, `game/assets/materials/`, `game/assets/sprites/projectiles/` |

---

## Critérios de aceite

- [ ] Todas as famílias AoE listadas neste PRD possuem shape hero 3D
- [ ] O tiro principal não depende de billboard como solução final
- [ ] O impacto principal possui pelo menos 3 camadas visuais
- [ ] A zona de dano em área é legível e coerente com o raio real
- [ ] Cada família possui identidade própria clara
- [ ] O conjunto parece parte de uma direção de arte unificada
- [ ] O resultado final está visivelmente acima do estado atual em charme, profundidade e acabamento
- [ ] Há sign-off explícito de direção de arte / designer sênior para considerar o trabalho concluído
- [ ] Performance continua estável com múltiplos efeitos simultâneos

---

## Não considerar concluído se

- o efeito só trocar sprite por primitive mesh simples
- o raio visual continuar desalinhado do hitbox
- a arma continuar parecendo placeholder técnico
- faltar passe de modelagem / acabamento de designer sênior

---

## Resultado esperado

Depois deste PRD, as armas AoE de Zion devem parecer:

- 3D de verdade
- bonitas de verdade
- premium de verdade
- e dignas de um passe final assinado por um designer sênior

Hoje elas já funcionam. Depois deste passe, elas precisam **encantar**.
