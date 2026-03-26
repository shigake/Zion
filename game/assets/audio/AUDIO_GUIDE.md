# Audio Assets Guide

## Formatos aceitos
- **SFX**: `.wav` (preferido) ou `.ogg`
- **Music**: `.ogg` (preferido) ou `.mp3`

## Estrutura de pastas

```
audio/
├── music/
│   ├── menu/          # Musica do menu principal
│   │   └── menu.ogg
│   ├── stages/        # Musica de cada fase (loop)
│   │   ├── cemetery.ogg
│   │   ├── forest.ogg
│   │   ├── farm.ogg
│   │   ├── tokyo.ogg
│   │   ├── volcano.ogg
│   │   ├── ocean.ogg
│   │   ├── arena.ogg
│   │   ├── space.ogg
│   │   ├── castle.ogg
│   │   └── candy.ogg
│   └── boss/          # Musica de boss fight
│       └── boss.ogg
│
└── sfx/
    ├── combat/        # Sons de combate
    │   ├── hit.wav          # Acerto em inimigo
    │   └── kill.wav         # Inimigo morrendo
    │
    ├── player/        # Sons do jogador
    │   ├── dash.wav         # Dash/esquiva
    │   ├── player_hurt.wav  # Jogador tomando dano
    │   └── level_up.wav     # Subiu de nivel
    │
    ├── pickup/        # Sons de coleta
    │   ├── collect_xp.wav      # Coletar gema de XP
    │   └── collect_crystal.wav # Coletar cristal
    │
    ├── ui/            # Sons de interface
    │   └── menu_click.wav   # Clique em botao
    │
    ├── enemies/       # Sons de inimigos
    │   └── (sons de inimigos especificos)
    │
    ├── boss/          # Sons de boss
    │   └── boss_appear.wav  # Boss aparecendo
    │
    └── environment/   # Sons ambientais
        └── (sons de ambiente por fase)
```

## Como o AudioManager carrega

O AudioManager busca os arquivos pelo **nome** (sem subpasta):
- `AudioManager.play_sfx("hit")` → procura `res://assets/audio/sfx/hit.wav` (ou .ogg, .mp3)
- `AudioManager.play_music("cemetery")` → procura `res://assets/audio/music/cemetery.ogg` (ou .mp3, .wav)

**IMPORTANTE**: Os arquivos precisam estar na raiz de `sfx/` ou `music/` para o AudioManager encontrar.
As subpastas sao apenas para organizacao visual — copie/symlink os arquivos finais para a raiz.

## SFX necessarios (10)

| Nome             | Descricao                  | Duracao sugerida |
|------------------|----------------------------|------------------|
| hit              | Acerto em inimigo          | 0.1-0.3s         |
| kill             | Inimigo morrendo           | 0.3-0.5s         |
| collect_xp       | Coletar gema de XP         | 0.2-0.4s         |
| collect_crystal  | Coletar cristal            | 0.3-0.5s         |
| level_up         | Subiu de nivel             | 0.5-1.0s         |
| evolve           | Arma evoluiu               | 1.0-1.5s         |
| boss_appear      | Boss aparecendo            | 1.0-2.0s         |
| dash             | Dash/esquiva               | 0.1-0.3s         |
| player_hurt      | Jogador tomando dano       | 0.2-0.4s         |
| menu_click       | Clique em botao de menu    | 0.05-0.15s       |

## Musicas necessarias (12)

| Nome      | Contexto               | Estilo sugerido          |
|-----------|------------------------|--------------------------|
| menu      | Menu principal         | Calmo, misterioso        |
| cemetery  | Fase 1 - Cemiterio     | Sombrio, gotico          |
| forest    | Fase 2 - Floresta      | Natureza, misterio       |
| farm      | Fase 3 - Fazenda       | Rural, levemente tenso   |
| tokyo     | Fase 4 - Tokyo         | Cyberpunk, eletronico    |
| volcano   | Fase 5 - Vulcao        | Intenso, epico           |
| ocean     | Fase 6 - Oceano        | Fluido, aventureiro      |
| arena     | Fase 7 - Arena         | Heavy, combate           |
| space     | Fase 8 - Espaco        | Sintetico, cosmico       |
| castle    | Fase 9 - Castelo       | Medieval, orquestral     |
| candy     | Fase 10 - Candy Land   | Alegre, fantasioso       |
| boss      | Boss fight (todas)     | Tenso, epico, acelerado  |
