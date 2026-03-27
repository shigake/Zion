# PRD - Projeteis e Efeitos Visuais 3D

## Problema

Todos os projeteis do jogo sao primitivas geometricas genericas (SphereMesh amarela para balas, BoxMesh para espadas, CylinderMesh para areas). Nao tem identidade visual — uma bala de metralhadora parece igual a uma flecha, um shuriken eh uma bolinha amarela, o veneno eh um circulo verde plano.

## Objetivo

Substituir TODOS os projeteis e efeitos visuais por modelos 3D tematicos e efeitos de particulas ricos, dando identidade visual unica a cada arma.

## Abordagem

Usar meshes procedurais mais complexas (combinando primitivas) + shaders + GPUParticles3D para criar visuais que comuniquem claramente o que cada projetil/efeito eh.

---

## Projeteis Ranged (10 armas)

### 1. MACHINEGUN — Bala de Metal
**Atual:** SphereMesh amarela (0.08 radius)
**Novo:** CylinderMesh dourado alongado (ponta afilada) + trail amarelo curto
- Mesh: CylinderMesh (top: 0.02, bottom: 0.04, height: 0.15) rotacionado 90° no eixo X
- Material: Dourado metalico (0.9, 0.75, 0.2), metallic=0.8, roughness=0.3
- Trail: Linha fina amarela (3 pontos, 0.3 comprimento)
- Emissao: Ponta brilhante (emission 1.5)
- Muzzle flash: GPUParticles3D amarelo/laranja (5 particulas, 0.1s vida)

### 2. DUAL_PISTOL — Bala Prateada
**Atual:** SphereMesh amarela (0.08 radius)
**Novo:** Similar a machinegun mas prateado e menor
- Mesh: CylinderMesh (top: 0.015, bottom: 0.03, height: 0.12)
- Material: Prata (0.8, 0.8, 0.85), metallic=0.9
- Trail: Linha branca fina (2 pontos)
- Muzzle flash: Spark branco brilhante

### 3. BAZOOKA — Missil com Cauda de Fogo
**Atual:** SphereMesh laranja (0.15 radius)
**Novo:** Corpo cilindrico com cone na ponta + cauda de fogo/fumaca
- Corpo: CylinderMesh (top: 0.05, bottom: 0.08, height: 0.4) — corpo do missil
- Ponta: ConeMesh ou CylinderMesh (top: 0.0, bottom: 0.05, height: 0.15) — ogiva
- Aletas: 4x BoxMesh pequenos (0.01 x 0.08 x 0.06) na traseira
- Material corpo: Cinza escuro (0.3, 0.3, 0.32), metallic=0.6
- Material ponta: Vermelho (0.9, 0.2, 0.1)
- Trail: GPUParticles3D — fumaca cinza + fogo laranja (20 particulas, 0.8s vida)
- Emissao traseira: Laranja brilhante (glow do propulsor)

### 4. STAFF — Orbe Magico de Gelo
**Atual:** SphereMesh azul (0.15 radius)
**Novo:** Esfera cristalina com particulas de gelo orbitando
- Mesh: SphereMesh (0.12 radius) com material transparente azul
- Material: Azul translucido (0.3, 0.6, 1.0, 0.7 alpha), emission 2.0
- Particulas orbitantes: 8 flocos de neve minusculos girando ao redor
- Trail: Particulas de cristal de gelo azul claro caindo atras
- Impacto: Explosao de cristais de gelo (burst 12 particulas)

### 5. SHURIKEN — Estrela Ninja Girando
**Atual:** SphereMesh amarela (0.08 radius) — TERRIVEL, nao parece nada com shuriken
**Novo:** Modelo de estrela 4 pontas girando rapidamente
- Mesh: 4x BoxMesh finos cruzados formando estrela (0.01 x 0.15 x 0.05 cada, rotacionados 45° entre si)
- Material: Metal escuro (0.25, 0.25, 0.3), metallic=0.9, roughness=0.2
- Rotacao: Gira continuamente no eixo Y a 20 rad/s
- Trail: Brilho azul gelado leve (ice element)
- Som: Whoosh cortante

### 6. AXE — Machado Girando
**Atual:** SphereMesh amarela com particles — nao parece machado
**Novo:** Modelo de machado girando no ar
- Lamina: BoxMesh (0.02 x 0.2 x 0.15) — lamina trapezoidal
- Cabo: CylinderMesh (top: 0.02, bottom: 0.02, height: 0.25)
- Material lamina: Metal brilhante (0.7, 0.7, 0.75), metallic=0.8
- Material cabo: Madeira (0.45, 0.3, 0.15)
- Rotacao: Gira no eixo Z a 15 rad/s (efeito de arremesso)
- Trail: Rastro de fogo laranja (fire element)
- Particulas: Fagulhas de fogo (5 particulas, 0.3s vida)

### 7. CROSSBOW — Flecha/Virote
**Atual:** SphereMesh amarela — nao parece flecha
**Novo:** Modelo de virote/bolt de besta
- Haste: CylinderMesh (top: 0.01, bottom: 0.01, height: 0.35)
- Ponta: CylinderMesh (top: 0.0, bottom: 0.03, height: 0.08) — ponta de ferro
- Penas: 3x BoxMesh (0.005 x 0.03 x 0.04) na traseira, rotacionados 120° entre si
- Material haste: Madeira (0.5, 0.35, 0.2)
- Material ponta: Metal (0.5, 0.5, 0.55), metallic=0.7
- Velocidade visual: Mais rapido que flechas (28 u/s)

### 8. ELVEN BOW — Flecha Elfica Elegante
**Atual:** CylinderMesh basico — ok mas sem charme
**Novo:** Flecha elegante com brilho verde e particulas
- Haste: CylinderMesh (top: 0.008, bottom: 0.008, height: 0.5) — fina e longa
- Ponta: CylinderMesh (top: 0.0, bottom: 0.025, height: 0.1) — ponta folha
- Penas: 2x BoxMesh curvados (elficos, verdes)
- Material: Verde brilhante (0.3, 0.8, 0.3), emission 1.0
- Trail: Particulas verdes luminosas (natureza elfica)
- Ricochet: Flash verde brilhante ao ricochete

### 9. PLASMA CANNON — Esfera de Plasma Pulsante
**Atual:** SphereMesh azul basica
**Novo:** Esfera de energia instavel com arcos eletricos
- Mesh: SphereMesh (0.3 radius) com shader de distorcao
- Nucleo: Branco-azulado brilhante (emission 5.0)
- Halo: Aneis de energia ao redor (TorusMesh 2x, rotacoes diferentes)
- Particulas: Arcos eletricos aleatorios (linhas finas azuis)
- Charging: Cresce de 0.1 a 0.3, particulas convergem para centro
- Beam: BoxMesh com shader de energia ondulante (nao um retangulo solido)

### 10. ICE STAFF — Estilhaco de Gelo
**Atual:** SphereMesh amarela com override — nao parece gelo
**Novo:** Cristal de gelo irregular voando
- Mesh: Varias BoxMesh combinadas em formato de cristal irregular
- Material: Azul translucido (0.5, 0.8, 1.0, 0.6 alpha), metallic=0.3
- Reflexo: Cintilacao cristalina
- Trail: Flocos de neve e particulas de neve caindo
- Impacto: Explosao de estilhacos de gelo + anel de congelamento azul

---

## Efeitos de Area (6 tipos)

### 1. POISON POOL — Gosma Toxica Borbulhante
**Atual:** CylinderMesh verde plano — so um circulo verde
**Novo:** Pocas de gosma com bolhas subindo e vapores
- Base: CylinderMesh (radius variavel, height: 0.08) — mais grosso
- Material: Verde escuro translucido (0.1, 0.5, 0.05, 0.7), roughness=0.1 (brilhante/viscoso)
- Shader: Ondulacao no vertex shader (simula liquido)
- Bolhas: GPUParticles3D — esferas verdes pequenas subindo e estourando (15 particulas, randomizadas)
- Vapores: GPUParticles3D — nuvem verde translucida subindo (10 particulas, 1.5s vida, fade out)
- Borda: Anel mais escuro na borda (simula poça irregularidade)

### 2. EXPLOSION — Explosao de Fogo Real
**Atual:** SphereMesh laranja que fade — muito basico
**Novo:** Explosao multi-camada com onda de choque
- Flash: SphereMesh branca brilhante (0.1s, emission 10.0) — flash inicial
- Bola de fogo: SphereMesh que expande (0.5 a radius final em 0.3s)
  - Material: Gradiente laranja→vermelho→preto (simula fogo esfriando)
- Onda de choque: TorusMesh que expande rapidamente (0.1 a radius final em 0.2s)
  - Material: Branco translucido (0.3 alpha), emission 3.0
- Fumaca: GPUParticles3D — nuvens cinzas subindo (20 particulas, 2.0s vida)
- Fagulhas: GPUParticles3D — pontos laranjas espalhando (30 particulas, 0.5s)
- Debris: GPUParticles3D — pedacinhos escuros caindo com gravidade (10 particulas)

### 3. FREEZE AREA — Zona de Congelamento
**Atual:** Burst de particulas azuis — sem presenca visual no chao
**Novo:** Circulo de gelo cristalino no chao com cristais crescendo
- Base: CylinderMesh achatado com textura de gelo rachado
- Material: Azul claro translucido (0.6, 0.85, 1.0, 0.5), metallic=0.4
- Cristais: 5-8 BoxMesh verticais randomizados no anel (simulam cristais de gelo saindo do chao)
  - Crescem de 0 a tamanho final em 0.3s
  - Material: Azul gelado com emission
- Neblina: GPUParticles3D — vapor frio branco rente ao chao (15 particulas)
- Flocos: GPUParticles3D — flocos de neve caindo na area (10 particulas, lentos)

### 4. FIRE GROUND — Rastro de Fogo
**Atual:** Mesh basica laranja com fade
**Novo:** Chamas reais com particulas de fogo
- Base: CylinderMesh baixo com material vermelho/laranja ondulante
- Chamas: GPUParticles3D — labaredas subindo (30 particulas, cores laranja→amarelo→vermelho)
  - Movimento: Subindo com leve oscilacao lateral
  - Escala: Diminui conforme sobe
- Brasas: GPUParticles3D — pontos vermelhos no chao (10 particulas, lentas)
- Fumaca leve: GPUParticles3D — fina fumaca cinza acima das chamas

### 5. ELECTRIC CHAIN — Raio entre Inimigos
**Atual:** Linhas azuis entre alvos + particulas
**Novo:** Arcos eletricos ramificados com flash e faiscas
- Raio principal: ImmediateMesh com linha ondulante (nao reta — zigzag randomizado)
  - 8-12 segmentos com offsets aleatorios perpendiculares
  - Material: Branco-azulado (0.8, 0.9, 1.0), emission 5.0
- Raio secundario: Linhas mais finas paralelas (ramificacoes)
- Flash: Luz pontual momentanea em cada ponto de impacto (0.1s)
- Faiscas: GPUParticles3D em cada ponto de contato (8 particulas, rapidas)
- Som: Crackle eletrico

### 6. TOTEM AURA — Aura Eletrica do Totem
**Atual:** Sem mesh de aura visivel
**Novo:** Anel de energia pulsante ao redor do totem
- Anel: TorusMesh no chao (inner: 0.1, outer: radius da area)
- Material: Azul eletrico translucido com pulso (alpha oscila 0.2-0.5)
- Particulas: Arcos eletricos aleatorios dentro da area (5-8 linhas, mudam posicao)
- Pulso: Escala do anel oscila levemente (0.95x a 1.05x)

---

## Projeteis Melee (melhorias visuais)

### KATANA — Arco de Corte Afiado
**Atual:** BoxMesh com trail azul
**Novo:** Manter trail mas adicionar efeito de corte
- Trail: Mais brilhante, com gradiente branco→azul
- Impacto: Linha de corte brilhante momentanea (slash mark)
- Particulas: Faiscas metalicas no impacto (5 particulas)

### CLOUD SWORD — Onda de Energia no Corte
**Atual:** BoxMesh grande com trail azul
**Novo:** Manter mesh mas adicionar onda de energia
- Trail: Mais largo, com efeito de vento/pressao
- Nivel 5+: Dispara onda de energia frontal (extra projectile)
- Screen shake: Manter, adicionar flash branco leve

### SCYTHE — Foice Sombria com Almas
**Atual:** BoxMesh fino com trail roxo
**Novo:** Trail mais dramatico + efeitos de alma
- Trail: Roxo escuro com wisps fantasmagoricos
- Lifesteal visual: Particulas verdes viajando do inimigo para o jogador
- Orbita: Deixar rastro de sombra (afterimage)

### HAMMER — Impacto com Rachaduras
**Atual:** CylinderMesh que expande
**Novo:** Onda de choque no chao + rachaduras
- Impacto: Anel de pedras/debris saindo do ponto
- Particulas: Poeira marrom subindo (15 particulas)
- Onda: TorusMesh expandindo rapidamente

### WHIP — Chicote com Estalo
**Atual:** BoxMesh fino com trail vermelho
**Novo:** Trail mais dinamico com efeito de estalo
- Ponta: Flash branco na extremidade (crack effect)
- Trail: Mais pontos, curvatura mais organica
- Impacto: Mini explosao vermelha

---

## Efeitos de Armas Especiais

### NECRO SUMMON — Invocacao Sombria
**Atual:** Disco verde no chao + CapsuleMesh branco
**Novo:** Portal sombrio + esqueleto estilizado
- Portal: Pentagrama roxo/verde girando no chao
- Particulas: Almas subindo do portal (wisps verdes)
- Esqueleto: Manter CapsuleMesh mas adicionar "ossos" (BoxMesh extras)

### TOTEM — Torre Mistica
**Atual:** CylinderMesh simples azul
**Novo:** Pilar com runas brilhantes
- Base: Manter CylinderMesh mas adicionar textura de runas (emission patterns)
- Topo: Esfera de energia no topo (SphereMesh pequena, pulsante)
- Aura: Aneis de energia orbitando

### TIME BOMB — Bomba Ticking
**Atual:** SphereMesh vermelha com label
**Novo:** Bomba estilizada com pavio
- Corpo: SphereMesh com "costuras" (linhas escuras)
- Pavio: CylinderMesh fino saindo do topo com particula de faisca na ponta
- Countdown: Numero 3D pulsando (escala oscila)
- Explosao: Usar o novo sistema de explosao descrito acima

### PORTAL — Vortex Dimensional
**Atual:** TorusMesh roxo — ok mas basico
**Novo:** Vortex multi-camada com distorcao
- Anel externo: TorusMesh com rotacao (mantido)
- Anel interno: Segundo TorusMesh menor, rotacao oposta
- Centro: SphereMesh escura (buraco negro visual)
- Particulas: Estrelas/pontos de luz sendo sugados para o centro
- Distorcao: Shader de distorcao no centro (warp visual)

---

## Prioridades de Implementacao

### P0 — Critico (maior impacto visual)
1. Shuriken (estrela ninja ao inves de bolinha)
2. Bazooka/Rocket (missil com trail de fogo)
3. Poison Pool (gosma com bolhas)
4. Explosion (explosao multi-camada)
5. Bullets machinegun/pistol (balas metalicas)

### P1 — Alto (melhoria significativa)
6. Axe (machado girando)
7. Crossbow/Elven Bow (flechas reais)
8. Staff projectile (orbe de gelo)
9. Freeze Area (cristais de gelo)
10. Fire Ground (chamas com particulas)

### P2 — Medio (polish)
11. Electric Chain (zigzag + faiscas)
12. Plasma Cannon (esfera de energia)
13. Ice Staff (cristal de gelo)
14. Trail melhorias (katana, scythe, whip)
15. Totem aura visivel

### P3 — Baixo (detalhes extras)
16. Necro summon portal
17. Time bomb visual
18. Portal vortex
19. Screen effects (shake, flash)
20. Impact effects gerais

---

## Especificacoes Tecnicas

- **Todos os projeteis devem ser leves** — usar meshes com poucos vertices (primitivas combinadas, nao modelos high-poly)
- **Object Pool**: Todos os projeteis sao reutilizados via ObjectPool — nao instanciar meshes novas a cada tiro
- **GPUParticles3D**: Usar para efeitos volumetricos (fumaca, fogo, gelo, faiscas) — mais performatico que CPUParticles
- **Trails**: Usar o sistema de weapon_trail.gd existente com mais pontos e cores melhores
- **Shaders**: Usar shaders simples para efeitos especiais (ondulacao de liquido, pulsacao de energia)
- **Materials**: StandardMaterial3D com emission para brilho, transparency para efeitos translucidos
- **Performance**: Limitar particulas totais em tela (max ~200 particulas simultaneas)
