# PRD: Cenario e Camera — Polish Visual

## Camera

### Angulo mais baixo
- Camera mais inclinada pra baixo (mais isometrico)
- Atual: ~70-80 graus (quase top-down)
- Novo: ~55-60 graus (mostra mais profundidade 3D)
- Ajustar em: scripts/stages/stage_camera.gd

### FOV
- Aumentar FOV levemente pra dar sensacao de mais espaco
- Testar 30 → 35 graus

### Camera shake
- Manter shake existente mas ajustar pro novo angulo

## Cenario Cemiterio

### Props 3D como Sprites Billboard
- Lapides: 3-4 variantes de sprite, scattered pelo mapa
- Cruzes: sprites de cruz de madeira/pedra
- Arvores mortas: sprites de arvores secas sem folhas
- Nevoa rasteira: particulas de fog no chao
- Lua: sprite grande no fundo (skybox fake)

### Chao
- Textura de grama morta/terra pixelada tileable
- Variacao de cor (patches mais escuros/claros)

### Atmosfera
- Fog azulado/roxo (WorldEnvironment)
- Luz direcional fria (azul-branca)
- Sombras longas (sol baixo)
- Particulas ambientais: folhas mortas caindo

## Cenario Floresta

### Props
- Arvores verdes: 3-4 variantes de sprite grande
- Arbustos: sprites menores
- Cogumelos: sprites decorativos
- Flores: sprites pequenos coloridos
- Troncos caidos: props no chao

### Chao
- Textura de grama verde pixelada tileable
- Patches de terra/lama

### Atmosfera
- Fog verde suave
- Luz direcional quente (dourada)
- Raios de sol (god rays) via particulas
- Particulas ambientais: folhas verdes caindo, borboletas

## Implementacao

1. Ajustar camera (angulo + FOV)
2. Criar props sprites com gerador GDScript
3. Adicionar props nos stage scripts
4. Ajustar atmosfera/iluminacao por fase
5. Adicionar particulas ambientais
