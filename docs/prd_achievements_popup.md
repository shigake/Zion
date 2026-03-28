# PRD: Achievement Popup System (Marcos da Restauracao)

> Cada conquista marca um momento na jornada dos Fragmentados para restaurar Zion.

## Objetivo
Conquistas devem se sentir recompensadoras e memoraveis. Cada achievement tem um **flavor text narrativo** que conecta a acao ao lore (ver `progressao.md` para lista com flavor texts).

## Design Visual

### Layout do Popup
```
┌─────────────────────────────────────┐
│  🏆  [ICON 32x32]  ACHIEVEMENT!    │
│       Nome da Conquista             │
│       Descricao curta aqui          │
│  ████████████████████ Progress bar  │
└─────────────────────────────────────┘
```

### Especificacoes
- **Tamanho**: 320x80 pixels
- **Posicao**: Slide-in do lado direito, 100px do topo
- **Fundo**: Gradiente dourado escuro (Color(0.15, 0.12, 0.05, 0.95))
- **Borda**: Dourada 2px (Color(0.85, 0.7, 0.2))
- **Cantos**: Arredondados 8px
- **Icone**: Sprite do achievement 32x32 (ja existem em assets/sprites/achievements/)
- **Titulo**: "CONQUISTA!" em dourado, font size 10, caps
- **Nome**: Nome do achievement, font size 14, branco
- **Descricao**: Descricao curta, font size 10, cinza claro
- **Barra**: Se achievement tem progresso (ex: "mate 1000 inimigos"), mostra barra

### Animacao
1. **Entrada** (0.3s): Slide da direita com easing EASE_OUT_BACK (bounce sutil)
2. **Brilho** (0.2s): Flash dourado no fundo (alpha 0.3 -> 0)
3. **Permanencia**: 4 segundos visivel
4. **Saida** (0.3s): Slide pra direita com EASE_IN
5. **Particulas**: 5-8 sparkles douradas ao redor do popup durante a permanencia

### Som
- SFX dedicado: achievement.wav (fanfarra curta, tipo coin collect mas mais dramatico)
- Volume: 80% do SFX normal (se destaca mas nao assusta)

### Queue System
- Se multiplos achievements desbloqueiam ao mesmo tempo, mostra um por vez
- Delay de 0.5s entre popups
- Array _achievement_queue com shift/append

### Tela de Achievements (menu)
- Acessivel do menu principal: botao "Conquistas"
- Grid 3 colunas com todos os 13 achievements
- Desbloqueados: icone colorido + nome + descricao + data
- Bloqueados: icone cinza + "???" + dica de como desbloquear
- Contador: "7/13 conquistas desbloqueadas"
- Barra de progresso global no topo

## Implementacao
1. Criar `game/scripts/ui/achievement_popup.gd` (CanvasLayer separado, layer 10)
2. Conectar a `AchievementManager.achievement_unlocked` signal
3. Criar `game/scenes/ui/achievements_screen.tscn` pra tela de conquistas
4. Adicionar botao no main menu
5. Salvar achievement progress no SaveManager
