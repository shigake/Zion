# PRD — Modelos 3D (Asset Bible)

## Resumo

O jogo precisa de **~140 modelos 3D** para substituir toda a geometria procedural (capsulas, cubos, esferas) por assets de verdade. Este documento especifica CADA modelo com detalhes visuais, estilo, cores, e referencia de tamanho.

**Estilo visual**: Low-poly estilizado com cel-shader (toon shading). Pense em Vampire Survivors 3D / Crossy Road / Boneraiser Minions. Sem texturas fotorrealistas — cores solidas com gradientes suaves, contornos escuros (outline shader), sombras em 2-3 passos.

**Formato**: `.glb` (glTF Binary) — compativel nativamente com Godot 4.
**Polycount alvo**: 300-800 tris por modelo (low-poly). Bosses podem ter ate 2000 tris.
**Escala**: 1 unidade Godot = 1 metro. Personagem humano ~1.6 unidades de altura.
**Rig**: Personagens e inimigos precisam de skeleton rig para animacoes.
**Animacoes**: idle, walk, attack, hit, death (5 basicas). Podem ser procedurais (atual) ou baked.

---

## PRIORIDADE 1 — Personagens (12 modelos)

Todos os personagens sao humanoides estilizados, proporcoes levemente chibi (cabeca grande, corpo compacto). Cada um PRECISA ter silhueta distinta para ser reconhecivel a distancia no meio do caos.

### 1.1 Ronin (Samurai)
- **Silhueta**: Guerreiro japones elegante, postura ereta
- **Corpo**: Hakama (calca larga samurai), kimono aberto mostrando peitoral
- **Cabeca**: Topknot (coque samurai), olhos determinados, sem barba
- **Acessorios**: Headband vermelho, katana na cintura (bainha), sandalia geta
- **Cor principal**: Verde vibrante (#33D94D)
- **Detalhes**: Faixa vermelha na cintura, hakama azul escuro
- **Tamanho**: 1.6 unidades de altura
- **Referencia**: Yasuo (LoL) + Jetstream Sam (MGR) versao chibi

### 1.2 Soldado (Military)
- **Silhueta**: Soldado robusto, postura militar, ombros largos
- **Corpo**: Colete tatico, calcas cargo, botas de combate
- **Cabeca**: Capacete militar com viseira, queixo quadrado
- **Acessorios**: Mochila tatica nas costas, cartucheira no peito, dog tags
- **Cor principal**: Azul aco (#4D80E6)
- **Detalhes**: Camuflagem digital azul no colete, joelheiras
- **Tamanho**: 1.7 unidades (mais alto que o Ronin)
- **Referencia**: Soldier 76 (Overwatch) versao chibi low-poly

### 1.3 Mago (Wizard)
- **Silhueta**: Mago classico, robe longo, chapeu pontudo
- **Corpo**: Robe longo fluindo ate o chao, mangas largas
- **Cabeca**: Chapeu de mago pontudo com aba larga, barba curta
- **Acessorios**: Staff magico na mao (orbe brilhante no topo), cinto com pouch
- **Cor principal**: Roxo (#B34DE6)
- **Detalhes**: Estrelas/runas brilhantes no robe, orbe flutuante
- **Tamanho**: 1.5 unidades (menor por causa do robe)
- **Referencia**: Gandalf chibi + Veigar (LoL)

### 1.4 Berserker (Viking)
- **Silhueta**: GRANDE e intimidador, ombros enormes, sem camisa
- **Corpo**: Torso nu musculoso, calca de couro, botas de pele
- **Cabeca**: Elmo viking com 2 chifres, barba ruiva longa trancada
- **Acessorios**: Cinto de pele com caveiras, braceletes de metal, war paint vermelho
- **Cor principal**: Vermelho escuro (#CC3319)
- **Detalhes**: Cicatrizes no peito, tatuagens tribais nos bracos
- **Tamanho**: 1.9 unidades (o maior personagem)
- **Referencia**: Olaf (LoL) + Kratos versao chibi

### 1.5 Ninja (Shinobi)
- **Silhueta**: Fino e agil, postura agachada, scarf esvoancante
- **Corpo**: Traje shinobi apertado, faixas nos bracos e pernas
- **Cabeca**: Mascara cobrindo boca/nariz, apenas olhos visiveis
- **Acessorios**: Scarf longo esvoancante, shuriken holster na cintura, wakizashi nas costas
- **Cor principal**: Preto (#1A1A1A)
- **Detalhes**: Faixas vermelhas nos bracos, olhos vermelhos brilhantes
- **Tamanho**: 1.4 unidades (o menor, agachado)
- **Referencia**: Shen/Zed (LoL) versao chibi

### 1.6 Necromancer
- **Silhueta**: Sombrio, robe escuro, capuz cobrindo rosto
- **Corpo**: Robe rasgado verde escuro, magro esqueletico
- **Cabeca**: Capuz profundo, olhos verdes brilhantes no escuro
- **Acessorios**: Grimorio flutuante, correntes penduradas, caveira no ombro
- **Cor principal**: Verde escuro (#267326)
- **Detalhes**: Particulas de almas verdes ao redor, dedos ossudos
- **Tamanho**: 1.6 unidades
- **Referencia**: Karthus (LoL) + Lich medieval

### 1.7 Pirata (Captain)
- **Silhueta**: Chapeu tricornio grande, casaco longo
- **Corpo**: Casaco de capitao aberto, camisa branca, botas de cano alto
- **Cabeca**: Chapeu tricornio com pena, tapa-olho, barba negra curta
- **Acessorios**: 2x pistolas na cintura, espada curta, garrafa de rum
- **Cor principal**: Marrom (#996633)
- **Detalhes**: Casaco vermelho escuro, botoes dourados, cinto com fivela
- **Tamanho**: 1.6 unidades
- **Referencia**: Gangplank (LoL) + Jack Sparrow chibi

### 1.8 Engenheiro (Engineer)
- **Silhueta**: Compacto, oculos/goggles, muitas ferramentas
- **Corpo**: Macacao de trabalho, luvas grossas, botas de seguranca
- **Cabeca**: Goggles na testa, cabelo bagunçado, sorriso confiante
- **Acessorios**: Mochila com antena e drone, cinto de ferramentas, chave inglesa
- **Cor principal**: Dourado/amarelo (#E6B333)
- **Detalhes**: Patches de oil no macacao, LEDs azuis na mochila
- **Tamanho**: 1.5 unidades
- **Referencia**: Torbjorn (Overwatch) + Engineer (TF2) chibi

### 1.9 Vampiro (Dracula)
- **Silhueta**: Elegante, capa longa, postura aristocratica
- **Corpo**: Terno vitoriano, colete, capa com forro vermelho
- **Cabeca**: Cabelo slicked back, pele palida, presas visiveis, olhos vermelhos
- **Acessorios**: Capa esvoancante, colarinho alto, luvas brancas, rosa na lapela
- **Cor principal**: Crimson escuro (#801A1A)
- **Detalhes**: Interior da capa vermelho sangue, botoes prateados
- **Tamanho**: 1.7 unidades (alto e magro)
- **Referencia**: Alucard (Castlevania) + Dracula classico chibi

### 1.10 Gladiador (Roman)
- **Silhueta**: Armadura romana, crista no elmo, escudo
- **Corpo**: Armadura de peito (lorica), saia de couro (pteruges), sandalia gladius
- **Cabeca**: Elmo romano com crista vermelha, visor protegendo olhos
- **Acessorios**: Escudo redondo (parma) no braco, lanca na mao, capa curta
- **Cor principal**: Dourado/bronze (#CCA633)
- **Detalhes**: Emblema de aguia no escudo, armadura brilhante
- **Tamanho**: 1.7 unidades
- **Referencia**: Pantheon (LoL) + gladiador romano classico

### 1.11 Chef (Cook)
- **Silhueta**: Chapeu de chef alto e branco, avental
- **Corpo**: Uniforme de chef branco, avental, calcas xadrez, sapatos
- **Cabeca**: Toque blanche (chapeu de chef alto), bigode grosso, sorriso
- **Acessorios**: Frigideira nas costas, facas no avental, colher de pau
- **Cor principal**: Branco (#FFF2E6)
- **Detalhes**: Manchas de molho no avental, lenco no pescoco
- **Tamanho**: 1.6 unidades
- **Referencia**: Chef de ratatouille + Gordon Ramsay chibi

### 1.12 ??? (Mystery/Glitch)
- **Silhueta**: Forma humanoide generica que "glitcha" — contorno instavel
- **Corpo**: Corpo generico com textura de TV estatica / pixelado
- **Cabeca**: Rosto com "?" grande, sem features distintas
- **Acessorios**: Particulas de glitch/pixels ao redor, fragmentos flutuando
- **Cor principal**: Cinza (#808080) com rainbow glitch
- **Detalhes**: Partes do corpo parecem estar "corrompidas" — pixels, scan lines
- **Tamanho**: 1.6 unidades
- **Referencia**: Missingno (Pokemon) + glitch art

---

## PRIORIDADE 2 — Inimigos (11 modelos + 10 bosses)

### Inimigos Genericos

### 2.1 Slime
- **Forma**: Gota organica achatada, sem pernas
- **Detalhes**: 2 olhos circulares, boca sorridente simples, superfie gelatinosa
- **Animacao**: Bounce/squish ao mover, tremor idle
- **Cor**: Cor do stage (default verde, mas reskinado por stage)
- **Tamanho**: 0.5 x 0.4 unidades
- **Referencia**: Dragon Quest Slime

### 2.2 Slime Grande
- **Forma**: Versao 2x do Slime, com slimes menores "dentro"
- **Detalhes**: Mesma base, mas com 2-3 slimes menores visiveis dentro do corpo translucido
- **Animacao**: Ao morrer, split em 2 slimes normais
- **Tamanho**: 1.0 x 0.8 unidades

### 2.3 Bat (Morcego)
- **Forma**: Corpo redondo pequeno, asas de membrana grandes
- **Detalhes**: Orelhas pontudas, olhos vermelhos, presas, asas batendo
- **Animacao**: Asa batendo constantemente (flap), voa levemente acima do chao
- **Tamanho**: 0.6 largura (com asas), 0.3 corpo
- **Referencia**: Castlevania bat, Terraria bat

### 2.4 Skeleton (Esqueleto)
- **Forma**: Esqueleto humanoide, ossos visiveis
- **Detalhes**: Cranio com mandibula movel, costelas, pelvis, ossos dos bracos
- **Animacao**: Andar desengoncado, mandibula abrindo/fechando
- **Tamanho**: 1.4 unidades
- **Referencia**: Minecraft skeleton + Dark Souls skeleton

### 2.5 Skeleton Archer
- **Forma**: Mesmo esqueleto mas segurando arco
- **Detalhes**: Arco e aljava nas costas, postura de arqueiro
- **Variacao**: Fica parado e atira, nao persegue

### 2.6 Zombie Runner
- **Forma**: Humanoide decadente, inclinado pra frente
- **Detalhes**: Roupas rasgadas, pele esverdeada, bracos estendidos, olho caido
- **Animacao**: Corrida desesperada com bracos pra frente
- **Tamanho**: 1.5 unidades (inclinado)
- **Referencia**: L4D zombie + Plants vs Zombies

### 2.7 Ghost (Fantasma)
- **Forma**: Forma comica sem pernas, cauda esvoancante
- **Detalhes**: Corpo semitransparente, 2 olhos grandes brilhantes, boca aberta "OoOo"
- **Material**: Transparencia 50%, emissivo (glow)
- **Animacao**: Flutua, oscila suavemente
- **Tamanho**: 1.0 unidade
- **Referencia**: Pac-Man ghost + Mario Boo

### 2.8 Tank (Brute)
- **Forma**: Humanoides massivo, muito largo, quase quadrado
- **Detalhes**: Armadura pesada, escudo gigante na frente, cara pequena
- **Animacao**: Andar lento e pesado com screen shake leve
- **Tamanho**: 1.8 x 1.5 unidades (largo!)
- **Referencia**: Roadhog (Overwatch) + Iron Golem

### 2.9 Bomber
- **Forma**: Criatura pequena carregando bomba enorme
- **Detalhes**: Corpo de goblin/imp, bomba redonda preta com pavio aceso nas costas
- **Animacao**: Corre rapido com a bomba, pavio brilhando. Ao morrer: explode
- **Tamanho**: 0.8 unidade (pequeno mas a bomba e grande)
- **Referencia**: Creeper (Minecraft) + Bob-omb (Mario)

### 2.10 Swarm (Enxame)
- **Forma**: Cluster de 20+ insetos minusculos
- **Detalhes**: Cada inseto e uma esferinha com asinhas, grupo se move junto
- **Material**: Particulas ou instancias MultiMesh
- **Animacao**: Nuvem organica que pulsa e se contrai
- **Tamanho**: 1.0 unidade de raio para o cluster
- **Referencia**: Zerg swarm + insect swarm RPG

### 2.11 Mimic (Bau Falso)
- **Forma**: Bau do tesouro que abre revelando dentes e lingua
- **Detalhes**: Bau de madeira com metal, ao ativar: tampa abre como boca com dentes, lingua vermelha, olho unico
- **Animacao**: Idle = parece bau normal. Activate = tampa abre, pula
- **Tamanho**: 0.8 x 0.6 unidades
- **Referencia**: Dark Souls Mimic + Dungeons & Dragons

---

### Bosses (10 modelos, maior polycount)

### 2.12 Necromancer King (Cemetery Boss)
- **Forma**: Mago gigante sombrio, 3x tamanho do jogador
- **Detalhes**: Robe negro rasgado, coroa de ossos, olhos roxos brilhantes, staff com cranio no topo
- **Fases visuais**: Normal → robe comeca a brilhar roxo → aura de fogo roxo
- **Tamanho**: 4.0 unidades
- **Referencia**: Lich King + Ainz Ooal Gown

### 2.13 Rainha das Fadas (Forest Boss)
- **Forma**: Fada gigante elegante com asas de borboleta
- **Detalhes**: Vestido de petala, coroa de flores, asas translucidas iridescentes, cetro de cristal
- **Fases visuais**: Bela → olhos ficam vermelhos → forma corrompida (asas rasgadas, espinhos)
- **Tamanho**: 3.5 unidades
- **Referencia**: Titania (mitologia) + Fairy Queen (SMT)

### 2.14 Mega Vaca Alienigena (Farm Boss)
- **Forma**: Vaca gigante com tecnologia alien
- **Detalhes**: Corpo de vaca com implantes metalicos, olhos verdes brilhantes, disco voador acoplado nas costas, raio trator saindo da barriga
- **Fases visuais**: Normal → olhos ficam vermelhos → disco ativa, levita
- **Tamanho**: 4.0 unidades
- **Referencia**: Cow abduction meme + alien tech

### 2.15 AI Overlord (Tokyo Boss)
- **Forma**: Entidade digital/holografica, forma humanoide geometrica
- **Detalhes**: Corpo feito de triangulos/poligonos flutuantes, rosto de tela/monitor, tentaculos de dados
- **Fases visuais**: Azul estavel → glitch amarelo → vermelho com fragmentacao
- **Tamanho**: 4.0 unidades
- **Referencia**: Agent Smith (Matrix) + Ultron + digital art

### 2.16 Demon Lord (Volcano Boss)
- **Forma**: Demonio classico gigante, chifres, asas de morcego
- **Detalhes**: Pele vermelha/negra, chifres curvos, asas de morcego rasgadas, espada de fogo, cauda com ponta de flecha
- **Fases visuais**: Normal → corpo pega fogo → lava escorrendo pelo corpo
- **Tamanho**: 4.5 unidades (o maior boss)
- **Referencia**: Diablo + Ifrit (FF) + Doom demon

### 2.17 Leviathan (Ocean Boss)
- **Forma**: Serpente marinha colossal, so cabeca e tentaculos visiveis
- **Detalhes**: Cabeca de serpente com escamas, olhos amarelos brilhantes, tentaculos saindo da agua, boca com dentes afiados
- **Fases visuais**: So olhos → cabeca emerge → corpo inteiro visivel
- **Tamanho**: 5.0 unidades (cabeca)
- **Referencia**: Kraken + Jormungandr

### 2.18 Imperador Corrompido (Arena Boss)
- **Forma**: Imperador romano em armadura dourada corrompida
- **Detalhes**: Armadura ornamentada rachada, capa purpura rasgada, coroa de louros torta, olhos vermelhos, espada flamejante
- **Fases visuais**: Armadura brilhante → rachaduras com luz vermelha → armadura quebra, forma demoniak
- **Tamanho**: 4.0 unidades
- **Referencia**: Caligula corrupto + boss de God of War

### 2.19 Singularidade (Space Boss)
- **Forma**: Esfera de buraco negro com aneis orbitais
- **Detalhes**: Centro negro absoluto, anel de acreccao brilhante (laranja/branco), fragmentos orbitando, distorcao visual ao redor
- **Fases visuais**: Pequena → cresce → anel fica vermelho, puxa tudo
- **Tamanho**: 3.0 unidades (esfera) + 5.0 (anel)
- **Referencia**: Interstellar black hole + cosmic horror

### 2.20 Conde Dracula (Castle Boss)
- **Forma**: Vampiro aristocrata gigante com capa
- **Detalhes**: Terno vitoriano ornamentado, capa enorme, rosto palido com presas, olhos vermelhos, cabelo branco
- **Fases visuais**: Forma humana → semi-morcego (asas brotam) → morcego gigante completo
- **Tamanho**: 3.5 unidades (humano) → 5.0 (morcego)
- **Referencia**: Castlevania Dracula + Strahd (D&D)

### 2.21 Rei Acucar (Candy Boss)
- **Forma**: Rei gordo feito de doce, coroa de pirulitos
- **Detalhes**: Corpo de marshmallow/bolo, bracos de chocolate, pernas de gummy, coroa de pirulitos coloridos, cetro de candy cane
- **Fases visuais**: Inteiro → comeca a derreter → derretendo com caramelo escorrendo
- **Tamanho**: 4.0 unidades
- **Referencia**: Rei Candy Crush + boss de Wreck-It Ralph

---

## PRIORIDADE 3 — Armas (28 modelos + 10 projeteis)

Armas sao props pequenos. Quando equipadas, ficam visiveis no personagem ou como efeito visual durante o ataque.

### Melee (10 armas)

| # | Arma | Descricao Visual | Tamanho |
|---|------|-----------------|---------|
| 1 | **Katana** | Lamina curva japonesa, tsuba (guarda) circular, cabo enrolado com fita | 1.2m |
| 2 | **Foice (Scythe)** | Cabo longo escuro, lamina curva prateada com brilho roxo, runas na lamina | 1.5m |
| 3 | **Machado Viking** | Cabeca de machado dupla, cabo de madeira com couro, metal envelhecido | 0.8m |
| 4 | **Chicote (Whip)** | Chicote de couro trancado, cabo com pomo de metal, estalando | 2.0m |
| 5 | **Lanca (Lance)** | Hasta longa de madeira, ponta metalica triangular, fita vermelha | 2.5m |
| 6 | **Martelo (Hammer)** | Cabeca de martelo de guerra massiva, cabo curto grosso, metal pesado | 0.9m |
| 7 | **Nunchaku** | 2 bastoes de madeira conectados por corrente, madeira escura polida | 0.4m cada |
| 8 | **Katana Dupla** | 2 katanas cruzadas, laminas gemeas, uma com fita vermelha outra azul | 1.0m cada |
| 9 | **Espada Cloud** | Buster Sword enorme, lamina retangular grossa, cabo com fita | 1.8m |
| 10 | **Luvas de Boxe** | Par de luvas vermelhas de boxe, grandes e brilhantes | 0.3m |

### Ranged (10 armas)

| # | Arma | Descricao Visual | Projetil |
|---|------|-----------------|---------|
| 1 | **Metralhadora** | SMG compacta, tambor, cano curto | Balas douradas (cilindros) |
| 2 | **Staff Magico** | Cajado de madeira com orbe azul no topo | Orbe azul homing |
| 3 | **Bazuca** | Tubo de lancamento verde militar, mira | Foguete com cauda de fumaca |
| 4 | **Shuriken** | Estrela de arremesso 4 pontas metalica | A propria estrela girando |
| 5 | **Pistola Dupla** | 2 pistolas de pirata flintlock, metal+madeira | Flash de tiro + bala |
| 6 | **Lanca-chamas** | Tanque nas costas + bico de metal | Cone de fogo |
| 7 | **Cajado de Gelo** | Cajado de cristal azul, flocos de neve | Orbe de gelo azul |
| 8 | **Besta (Crossbow)** | Besta medieval de madeira+metal | Virote (bolt) |
| 9 | **Canhao de Plasma** | Arma sci-fi com tubo brilhante | Beam de plasma azul |
| 10 | **Arco Elfico** | Arco elegante de madeira clara com runas | Flechas verdes brilhantes |

### Summon/Special (8 armas)

| # | Arma | Descricao Visual |
|---|------|-----------------|
| 1 | **Necromante (Tome)** | Livro negro flutuante com correntes, paginas brilham verde |
| 2 | **Drone** | Quadcopter metalico azul com LEDs, helices girando |
| 3 | **Totem** | Poste de madeira entalhado com rosto tribal, olhos brilhantes |
| 4 | **Garrafa de Veneno** | Frasco de vidro verde com liquido borbulhante, rolha |
| 5 | **Corrente Eletrica** | Orbe de energia eletrica com raios saindo (efeito) |
| 6 | **Livro Magico** | Livro aberto flutuante, paginas se soltando, aura dourada |
| 7 | **Bomba Relogio** | Bomba redonda com relogio analogico na frente, pavio |
| 8 | **Portal** | Anel flutuante com energia roxa/azul girando dentro |

---

## PRIORIDADE 4 — Pickups (3 modelos)

| # | Item | Descricao Visual | Tamanho |
|---|------|-----------------|---------|
| 1 | **XP Gem** | Gema facetada tetraedrica, azul brilhante, glow pulsante, flutua e bobbing | 0.15m |
| 2 | **Crystal (Moeda)** | Cristal hexagonal dourado/ambar, multi-facetado, sparkle particles, rotaciona | 0.20m |
| 3 | **Bau de Evolucao** | Bau de tesouro ornamentado, madeira escura com faixas de metal dourado, glow magico, tampa levemente aberta com luz saindo de dentro | 0.6m |

---

## PRIORIDADE 5 — Props de Stage (80+ modelos, 10 stages)

### Stage 1: Cemiterio Assombrado

| # | Prop | Descricao | Qtd no mapa |
|---|------|-----------|-------------|
| 1 | **Lapide simples** | Pedra retangular cinza, texto ilegivel, musgo | 30 |
| 2 | **Lapide cruz** | Cruz de pedra, rachada, coberta de hera | 15 |
| 3 | **Lapide anjo** | Anjo de pedra chorando, asas quebradas | 5 |
| 4 | **Arvore morta** | Tronco retorcido sem folhas, galhos quebrados, corvos | 15 |
| 5 | **Cerca de ferro** | Grades de ferro envelhecido, portao | 10 |
| 6 | **Caixao** | Caixao de madeira semi-enterrado, tampa deslocada | 5 |
| 7 | **Lua** | Esfera emissiva distante, lua cheia amarela | 1 |

### Stage 2: Floresta Encantada

| # | Prop | Descricao | Qtd |
|---|------|-----------|-----|
| 1 | **Cogumelo pequeno** | Cogumelo colorido (5 cores), tronco fino, chapeu redondo | 30 |
| 2 | **Cogumelo gigante** | Cogumelo 2m+, tronco grosso, chapeu enorme com pontos | 10 |
| 3 | **Arvore magica** | Arvore com tronco torcido, copa brilhante verde/azul | 20 |
| 4 | **Rio brilhante** | Segmentos de agua azul emissiva, pedras nas margens | 15 seg |
| 5 | **Cristal de terra** | Cristal rosa/roxo crescendo do chao | 8 |
| 6 | **Vaga-lume** | Particula de luz flutuante (nao precisa modelo) | N/A |

### Stage 3: Fazenda do Apocalipse

| # | Prop | Descricao | Qtd |
|---|------|-----------|-----|
| 1 | **Silo** | Cilindro metalico alto com teto conico, enferrujado | 3 |
| 2 | **Milho** | Pe de milho com folhas e espiga, em fileiras | 20+ |
| 3 | **Fardo de feno** | Cilindrico ou retangular, amarelo palha | 10 |
| 4 | **Cerca quebrada** | Estacas de madeira com barras horizontais, algumas caidas | 5 |
| 5 | **Trator quebrado** | Trator vermelho enferrujado, roda faltando, capot torto | 1 |
| 6 | **Moinho** | Moinho de vento com pas quebradas | 1 |
| 7 | **Espantalho** | Espantalho de palha com chapeu, bracos abertos | 3 |

### Stage 4: Toquio Cyberpunk

| # | Prop | Descricao | Qtd |
|---|------|-----------|-----|
| 1 | **Predio neon** | Predio retangular com faixas de neon (rosa, azul, verde) | 35 |
| 2 | **Billboard holografico** | Painel flutuante com texto japones brilhante | 20 |
| 3 | **Maquina de vending** | Vending machine japonesa com bebidas, LEDs | 5 |
| 4 | **Poste de luz** | Poste com luz neon, fios pendurados | 10 |
| 5 | **Carro futurista** | Carro compacto estacionado, design cyberpunk | 3 |
| 6 | **Painel eletrico** | Placa metalica no chao com faiscas | 12 |

### Stage 5: Vulcao Infernal

| # | Prop | Descricao | Qtd |
|---|------|-----------|-----|
| 1 | **Rio de lava** | Lava laranja brilhante, bolhas, fluxo | 8 |
| 2 | **Rocha flutuante** | Rocha escura com glow laranja embaixo, levitando | 25 |
| 3 | **Geyser** | Abertura no chao com vapor/fogo saindo | 10 |
| 4 | **Pilar de obsidiana** | Coluna negra brilhante, angular | 30 |
| 5 | **Cranio gigante** | Cranio de demonio enorme semi-enterrado na rocha | 2 |

### Stage 6: Fundo do Oceano

| # | Prop | Descricao | Qtd |
|---|------|-----------|-----|
| 1 | **Coral (3 tipos)** | Coral bolha, coral tubo, coral leque (cores variadas) | 40 |
| 2 | **Ruina submersa** | Coluna grega quebrada, bloco de pedra com musgo | 15 |
| 3 | **Alga marinha** | Folhas verdes longas ondulando | 30 |
| 4 | **Ancora** | Ancora enferrujada fincada no chao | 3 |
| 5 | **Bau do tesouro** | Bau de pirata no fundo do mar, moedas saindo | 2 |
| 6 | **Bolhas** | Particulas de bolha subindo (nao precisa modelo) | N/A |

### Stage 7: Arena Gladiadora

| # | Prop | Descricao | Qtd |
|---|------|-----------|-----|
| 1 | **Parede do coliseu** | Arco romano com colunas, pedra bege | 24 |
| 2 | **Coluna romana** | Coluna com flauta, capitel corintio, base | 20 |
| 3 | **Portao de ferro** | Grade de ferro com barras verticais | 4 |
| 4 | **Tocha** | Poste com fogo no topo, suporte de ferro | 16 |
| 5 | **Bandeira** | Estandarte romano pendurado (SPQR) | 8 |
| 6 | **Areia** | Textura/shader de areia no chao | N/A |

### Stage 8: Estacao Espacial

| # | Prop | Descricao | Qtd |
|---|------|-----------|-----|
| 1 | **Painel de corredor** | Modulo metalico de parede com luzes LED | 25 |
| 2 | **Janela espacial** | Painel com vidro mostrando estrelas | 20 |
| 3 | **Console** | Painel de controle com tela brilhante | 15 |
| 4 | **Tubo/cano** | Cano metalico (horizontal ou vertical) | 30 |
| 5 | **Container** | Caixa de carga espacial com logo | 5 |
| 6 | **Airlock** | Porta automatica (aberta) | 3 |

### Stage 9: Castelo do Vampiro

| # | Prop | Descricao | Qtd |
|---|------|-----------|-----|
| 1 | **Pilar gotico** | Coluna com topo pontudo, pedra escura | 30 |
| 2 | **Candelabro** | Suporte de velas com 3-5 bracos, velas acesas | 12 |
| 3 | **Vitral** | Painel de vidro colorido com padrao (5 cores) | 15 |
| 4 | **Caixao vampiro** | Caixao ornamentado, alguns abertos | 20 |
| 5 | **Trono** | Cadeira alta gotica com estofado vermelho | 1 |
| 6 | **Armadura vazia** | Armadura medieval em pe segurando espada | 4 |

### Stage 10: Mundo Doce

| # | Prop | Descricao | Qtd |
|---|------|-----------|-----|
| 1 | **Candy Cane** | Bastao listrado vermelho/branco, curvado no topo | 25 |
| 2 | **Sorvete** | Casquinha com 1-3 bolas (5 sabores/cores) | 15 |
| 3 | **Gummy Bear** | Ursinho de goma translucido (5 cores) | 30 |
| 4 | **Chocolate** | Patch de chocolate no chao com pedacos | 20 |
| 5 | **Pirulito** | Disco colorido em espiral no palito | 10 |
| 6 | **Cupcake** | Cupcake com cobertura e cereja | 5 |
| 7 | **Rosquinha** | Donut com cobertura rosa e confeitos | 5 |

---

## PRIORIDADE 6 — UI/HUD (2D)

| # | Asset | Descricao |
|---|-------|-----------|
| 1 | **Icones de arma** | 28 icones 64x64, estilo pixel art ou hand-drawn, fundo transparente |
| 2 | **Icones de item** | 19 icones 64x64, mesmo estilo |
| 3 | **Icones de reliquia** | 7 icones 64x64 |
| 4 | **Retratos de personagem** | 12 retratos 128x128, bust shot, para selecao |
| 5 | **Logo do jogo** | "ZION" estilizado, para menu principal |
| 6 | **Fundo de menu** | Arte 2D para tela titulo |

---

## Resumo de Quantidades

| Categoria | Quantidade | Prioridade |
|-----------|-----------|------------|
| Personagens | 12 | P1 |
| Inimigos genericos | 11 | P2 |
| Bosses | 10 | P2 |
| Armas (props) | 28 | P3 |
| Projeteis | ~10 | P3 |
| Pickups | 3 | P4 |
| Props de stage | ~80 | P5 |
| Assets 2D (icones) | ~70 | P6 |
| **TOTAL** | **~224** | — |

---

## Pipeline de Producao Sugerido

1. **Modelagem**: Blender (gratuito) com workflow low-poly
2. **Textura**: Vertex coloring (pintar nos vertices) OU palette texture (1 textura atlas com cores)
3. **Rigging**: Armature simples para personagens (15-20 bones)
4. **Animacao**: 5 anims por personagem (idle, walk, attack, hit, death) — 1-2s cada
5. **Export**: .glb com materiais embedded
6. **Import Godot**: Arrastar .glb para res://assets/models/[categoria]/
7. **Integracao**: Atualizar model_factory.gd para carregar .glb ao inves de gerar proceduralmente

### Ferramentas Alternativas
- **Asset Forge**: Gerador rapido de modelos low-poly por blocos
- **Kenney Assets**: Packs gratuitos de modelos low-poly
- **Mixamo**: Rig e animacoes automaticas (gratis)
- **itch.io**: Marketplace com packs de modelos low-poly baratos
- **AI 3D generation**: Meshy, Tripo3D, Luma (gerar modelos base e refinar)
