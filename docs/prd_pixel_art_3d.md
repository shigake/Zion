# PRD: Pixel Art 3D — Visual Overhaul

## Visao Geral

Transformar o visual do Zion de "modelos 3D AI genéricos" para **Pixel Art 3D** — sprites pixel art estilizados com profundidade, iluminação e efeitos 3D. Inspiração: Octopath Traveler, Paper Mario, Vampire Survivors com profundidade.

## Principio de Design

**Sprites 2D como cidadãos de primeira classe no mundo 3D.** Os sprites pixel art são o visual do jogo — não são placeholders pra modelos 3D. Eles recebem iluminação, sombras, outline e efeitos que os fazem pertencer ao mundo 3D.

---

## Fase 1: Shader Pipeline (Prioridade CRITICA)

### 1.1 Sprite Pixel Art Shader
- Shader customizado para Sprite3D que aplica:
  - **Outline preto** (1-2px) ao redor do sprite
  - **Cel shading** (2-3 tons de sombra, não gradiente suave)
  - **Recebe iluminação 3D** (luz direcional afeta o sprite)
  - **Sombra projetada** no chão (circle shadow blob ou projected)
- Aplicar em: player, enemies, bosses, weapon sprites
- Parametros: outline_color, outline_width, shadow_intensity

### 1.2 Ground Shadow
- Cada entidade projeta uma sombra circular no chão
- Sombra é um disco semi-transparente escuro sob o sprite
- Escala com tamanho do sprite (boss = sombra maior)
- Opcional: sombra oval que estica na direção da luz

### 1.3 Depth & Parallax
- Sprites têm leve inclinação em Y (não 100% billboard)
- Ao andar, sprite inclina ligeiramente na direção do movimento
- Isso já existe (procedural_animator) — manter e polish

---

## Fase 2: Sprites Refinados (Prioridade ALTA)

### 2.1 Personagens (16)
- Sprites 64x64 com paleta consistente
- Cada personagem com idle e walk frames (2-4 frames cada)
- Cor dominante clara e reconhecível
- Outline preto forte
- Gerar via Blender (render low-poly com shader pixel art) ou redesenhar

### 2.2 Monstros Cemitério (9 + 2 bosses)
- Sprites 32x32 (normais) e 64x64 (bosses)
- Paleta dark: roxo, verde-doentio, cinza-osso, vermelho-sangue
- Silhuetas distintas (não todos humanoides)

### 2.3 Monstros Floresta (9 + 2 bosses)
- Sprites 32x32 (normais) e 64x64 (bosses)
- Paleta natural: verde, marrom, dourado, azul-wisp
- Mix de animais e criaturas fantásticas

### 2.4 Monstros Genéricos (9)
- Slime, skeleton, bat, ghost, zombie, tank, bomber, etc.
- Usados como base em todas as fases
- Paleta neutra que aceita tinting por fase

### 2.5 Armas (32)
- Sprites 32x32 icônicos
- Silhueta clara e reconhecível mesmo pequeno
- Cor dominante baseada no elemento (fogo=laranja, gelo=azul, etc.)

---

## Fase 3: Efeitos Visuais Pixel Art (Prioridade MEDIA)

### 3.1 Hit Sparks
- Sprites de impacto em pixel art (não partículas 3D genéricas)
- 3-4 frames de animação
- Cor baseada no elemento da arma

### 3.2 Death Effects
- Sprite de morte: flash branco → partículas pixel explodindo
- Variação por elemento (fogo=chamas pixel, gelo=estilhacos, etc.)

### 3.3 Trails & Slashes
- Slash trails como sprites animados (não mesh trails)
- 2-3 frames de arco cortante
- Cor baseada na arma

### 3.4 Explosões & AoE
- Círculos de impacto como sprites pixel expandindo
- Poison pool como sprite animado borbulhando
- Tornado como sprite espiral rodando

---

## Fase 4: Ambiente Pixel Art 3D (Prioridade MEDIA)

### 4.1 Props do Cenário
- Lápides, árvores, cogumelos como sprites billboard no mundo 3D
- Recebem sombra e iluminação do shader
- Variação (3-4 sprites diferentes por tipo de prop)

### 4.2 Chão e Atmosfera
- Manter ground plane 3D mas com textura pixel art tileable
- Fog/atmosfera combinando com a paleta da fase
- Partículas ambientais (folhas na floresta, névoa no cemitério)

### 4.3 Iluminação por Fase
- Cemitério: luz fria azulada, sombras longas, névoa
- Floresta: luz quente dourada, raios de sol entre árvores

---

## Fase 5: UI Pixel Art (Prioridade BAIXA)

### 5.1 HUD
- Barra de HP/XP em pixel art
- Ícones de armas/itens em pixel art consistente
- Números de dano em fonte pixel art

### 5.2 Menus
- Bordas e painéis com estilo pixel art (9-patch sprites)
- Botões com visual retro mas elegante
- Character select com sprites grandes e detalhados

---

## Decisoes Tecnicas

### Modelos 3D AI
- **REMOVER** modelos .glb dos enemies/bosses/characters do carregamento
- **MANTER** os arquivos .glb como backup (não deletar)
- Voltar a usar billboard Sprite3D como visual principal
- Aplicar o novo shader pixel art nos sprites

### Performance
- Sprites são MUITO mais leves que modelos 3D
- Sem limite de 50 enemies 3D — sprites escalam pra centenas
- Shader pixel art é leve (fragment shader simples)

### Modelos 3D das Armas
- **MANTER** modelos 3D apenas para armas que ficaram boas
- Ou converter pra sprites pixel art renderizados do Blender
- Decisão por arma individual

---

## Ordem de Implementacao

1. **Shader pixel art** (outline + cel + sombra) — base de tudo
2. **Desabilitar modelos 3D** de enemies/characters — usar sprites
3. **Aplicar shader** nos sprites existentes
4. **Testar e ajustar** — ver como fica no jogo
5. **Refinar sprites** dos personagens (Blender render ou redesenho)
6. **Refinar monstros** do cemitério e floresta
7. **Efeitos visuais** pixel art (hit, death, trails)
8. **Ambiente** (props, chão, atmosfera)
9. **UI** pixel art polish

---

## Inspiracoes Visuais

- **Octopath Traveler**: sprites 2D em mundo 3D com iluminação bonita
- **Vampire Survivors**: pixel art simples mas efetivo, muitos inimigos
- **Enter the Gungeon**: pixel art com efeitos visuais ricos
- **Dead Cells**: pixel art com animação fluida e partículas
- **Crossy Road**: voxel 3D com estética pixel art

## Meta

O jogo deve parecer **intencionalmente pixel art** — não "sprites placeholder esperando modelos 3D". Cada sprite deve ser bonito e reconhecível. A iluminação 3D deve valorizar os sprites, não competir com eles.
