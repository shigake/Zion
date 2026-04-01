# PRD 28 — Polish Pack: Sinergias, Áudio, Acessibilidade, Stats, Seeds & Tutorial

**Status**: pendente
**Prioridade**: alta (pré-lançamento)
**Estimativa**: grande (minor version bump)

---

## Contexto

O jogo está ~96% completo. Os sistemas core funcionam, mas vários têm **lacunas de polish** que impactam a experiência do jogador. Este PRD agrupa 6 áreas de melhoria que, juntas, elevam o jogo de "funcional" para "polido e profissional".

### Narrativa
Cada melhoria deve respeitar o universo de Zion:
- Sinergias = **ressonância cristalina** entre fragmentos
- Seeds = **coordenadas dimensionais** da fenda
- Tutorial = **memórias do Coração de Zion** guiando Fragmentados
- Stats = **registro dimensional** da expedição do Fragmentado
- Acessibilidade = **adaptação do estilhaço** ao portador
- Áudio = **harmonia dos cristais** (lore justifica ducking/mixing)

---

## 1. Tooltips Interativos de Sinergia

### Problema
O sistema de sinergias é complexo (6 base + 4 água + 8 cross-combo), mas a UI só mostra nomes coloridos em texto no canto da tela. O jogador não sabe **o que cada sinergia faz**, **quando ativa**, nem **qual o efeito**.

### Solução

#### 1.1 Ícones de Sinergia
- Criar sprite 32×32 para cada sinergia (6 base + 4 água + 8 cross = 18 ícones)
- Usar a paleta de cores já definida no `SynergySystem`
- Estilo: símbolo elemental simples (chama, gota, raio, etc.)
- Ícones gerados via script tool (consistente com pipeline existente em `scripts/tools/`)

#### 1.2 HUD de Sinergias Ativo
- Substituir lista de texto atual por **barra de ícones** no canto inferior-esquerdo
- Cada ícone ativo tem:
  - Borda brilhante quando a sinergia **procca** (flash 0.3s)
  - Cooldown circular overlay (se aplicável)
  - Badge "x2" / "x3" se empilhável
- Máximo 6 ícones visíveis (scroll horizontal se mais)
- Animação de entrada: scale 0→1 com ease-out quando sinergia é desbloqueada

#### 1.3 Tooltip ao Hover/Foco
- **Mouse**: hover sobre ícone mostra tooltip
- **Gamepad**: botão dedicado (LB/L1) abre painel de sinergias ativas
- Conteúdo do tooltip:
  ```
  [Ícone] Nome da Sinergia
  Tipo: [Base / Água / Cross-Combo]
  Efeito: "20% chance de explosão ao matar"
  Gatilho: Fogo + Fogo (2 armas de fogo)
  Cooldown: 3s | Dano: +45%
  ```
- Tooltip bilíngue (PT-BR/EN) via `LocaleManager`
- Background semi-transparente com borda na cor da sinergia

#### 1.4 Notificação de Ativação
- Ao proccar uma sinergia pela primeira vez na run:
  - Banner discreto no topo: "[Ícone] Ressonância Cristalina: Explosão ativada!"
  - Duração: 2s, fade out
  - SFX: som cristalino curto (reusar `crystal_pickup` com pitch shift)
- Procs subsequentes: apenas flash no ícone (sem banner)

### Arquivos a Criar/Modificar
- `scripts/ui/synergy_hud.gd` — novo (substitui lógica de texto em `hud.gd`)
- `scripts/ui/synergy_tooltip.gd` — novo
- `scripts/tools/generate_synergy_icons.gd` — novo (gerador de sprites)
- `scripts/autoload/synergy_system.gd` — adicionar sinais `synergy_activated`, `synergy_procced`
- `scenes/ui/hud.tscn` — integrar novo nó SynergyHUD
- `assets/sprites/synergies/` — 18 ícones gerados

### Critérios de Aceite
- [ ] 18 ícones de sinergia visíveis e distintos
- [ ] Tooltip aparece em <100ms no hover (mouse) e no LB (gamepad)
- [ ] Tooltip mostra nome, tipo, efeito, gatilho e cooldown
- [ ] Flash visual no ícone ao proccar
- [ ] Banner de primeira ativação aparece 1x por sinergia por run
- [ ] Bilíngue (PT-BR / EN)
- [ ] Cabe em 1280×720 sem sobrepor outros elementos do HUD

---

## 2. Balanceamento de Áudio Dinâmico

### Problema
Com 4 jogadores, sinergias, 51 SFX e música simultânea, o áudio pode virar caos. Não há ducking, limiter, nem categorização granular de sons.

### Solução

#### 2.1 Bus de Áudio por Categoria
Configurar AudioServer com buses separados:
```
Master
├── Music        (volume: -6dB)
├── SFX
│   ├── Combat   (armas, hits, explosões)
│   ├── UI       (clicks, menus, level up)
│   ├── Pickup   (cristais, itens, XP)
│   └── Ambient  (ambiente da fenda)
└── Voice        (diálogos de Sentinelas, tutorial)
```

#### 2.2 Ducking System
- Quando **Voice** toca → Music duca para -12dB (fade 0.3s)
- Quando **Boss phase** muda → Combat SFX duca 20% por 1s
- Recovery: fade back ao volume original em 0.5s
- Implementar via `Tween` no `AudioManager`

#### 2.3 Limiter de Sons Simultâneos
- **Por categoria**: máximo de sons simultâneos
  - Combat: 8 (atual: ilimitado via pool de 5)
  - Pickup: 4
  - UI: 2
  - Ambient: 2
  - Voice: 1
- **Prioridade**: Voice > UI > Combat > Pickup > Ambient
- Som de menor prioridade é cortado se limite atingido
- Cooldown por som único: manter 50ms atual, adicionar 30ms para mesma categoria

#### 2.4 Volume Scaling por Distância (Multiplayer)
- Sons de **outros jogadores** atenuam com distância (3D positional audio)
- Sons do **jogador local** sempre em volume cheio
- Raio de atenuação: 15 unidades (fade linear)
- Boss sounds: sempre volume cheio (global, sem atenuação)

#### 2.5 Opções de Áudio Expandidas
Adicionar ao menu de opções (tab Áudio):
- Slider: Volume Master (já existe)
- Slider: Volume Música (já existe)
- Slider: Volume SFX (já existe)
- **Novo** Slider: Volume Combate
- **Novo** Slider: Volume Ambiente
- **Novo** Toggle: Ducking automático (on/off, default: on)

### Arquivos a Criar/Modificar
- `scripts/autoload/audio_manager.gd` — refatorar: buses, ducking, limiter, distância
- `scripts/ui/options_screen.gd` — novos sliders de áudio
- `game/default_bus_layout.tres` — configurar bus tree (ou criar via código)
- `scenes/ui/options_screen.tscn` — UI dos novos controles

### Critérios de Aceite
- [ ] 5 buses de áudio configurados e funcionais
- [ ] Ducking ativa quando Voice toca (música abaixa visivelmente)
- [ ] Com 4 jogadores + sinergias, áudio não clippa nem vira ruído
- [ ] Limiter corta sons de baixa prioridade sem artefatos audíveis
- [ ] Sons de outros jogadores atenuam com distância
- [ ] 3 novos controles no menu de opções (combate, ambiente, ducking)
- [ ] Settings salvos em `SaveManager`

---

## 3. Acessibilidade — Implementação Real

### Problema
O menu de opções tem toggles para daltonismo, motion reduzido, flash reduzido, high contrast, UI scale e font scale — mas **nenhum está implementado de verdade**. São opções fantasma.

### Solução

#### 3.1 Modo Daltônico (Shader)
- Criar shader de pós-processamento com 3 matrizes de correção:
  - **Protanopia** (vermelho-cego): shift vermelho → amarelo
  - **Deuteranopia** (verde-cego): shift verde → amarelo
  - **Tritanopia** (azul-cego): shift azul → ciano
- Aplicar via `WorldEnvironment` ou `CanvasLayer` com `ColorRect` fullscreen
- Shader ativo = variável uniform controlada pelo `SaveManager`
- Preview: ao trocar opção, aplicar imediatamente (sem precisar reiniciar)

#### 3.2 Reduced Motion
Quando ativo:
- Desativar screen shake (`ScreenEffects.shake()` → no-op)
- Desativar camera bob/lean
- Reduzir velocidade de partículas em 70%
- Desativar idle bob dos sprites
- Manter animações essenciais (hit feedback, death)
- Implementar flag global `GameManager.reduced_motion` checado nos sistemas relevantes

#### 3.3 Reduced Flash
Quando ativo:
- Limitar frequência de flashes a máximo 3 por segundo (epilepsy-safe)
- Desativar hit flash branco no player (usar tint vermelho suave)
- Reduzir intensidade de explosões (alpha 50%)
- Desativar flash de level up (usar glow suave)
- Implementar via `ScreenEffects` com rate limiter

#### 3.4 High Contrast
Quando ativo:
- Inimigos ganham outline branco de 2px (shader outline)
- Pickups ganham glow mais intenso (+50% emission)
- Projectiles inimigos: borda vermelha brilhante
- Projectiles do jogador: borda azul brilhante
- Background escurece 20% (aumenta contraste com elementos de gameplay)
- Implementar via shader materials condicionais

#### 3.5 UI Scale (Funcional)
- Aplicar `Control.scale` no root do UI tree
- Opções: 80%, 100%, 120%, 150%
- Recalcular posições de elementos ancorados
- Testar que 150% ainda cabe em 1280×720 (simplificar se não couber)
- Aplicar em tempo real sem restart

#### 3.6 Font Scale (Funcional)
- Aplicar multiplicador global via `UITheme`
- Base sizes: Label (16), Title (28), Small (12)
- Multiplicadores: 0.8×, 1.0×, 1.2×, 1.5×
- Atualizar todos os `Label` nodes via group ou theme override
- Aplicar em tempo real

### Arquivos a Criar/Modificar
- `assets/shaders/colorblind.gdshader` — novo (shader de correção)
- `assets/shaders/outline_highcontrast.gdshader` — novo (outline de contraste)
- `scripts/autoload/accessibility_manager.gd` — novo singleton (centraliza todas as flags)
- `scripts/effects/screen_effects.gd` — respeitar reduced_motion e reduced_flash
- `scripts/effects/particle_factory.gd` — respeitar reduced_motion
- `scripts/effects/visual_setup.gd` — respeitar reduced_motion (idle bob)
- `scripts/ui/options_screen.gd` — conectar toggles ao AccessibilityManager
- `scripts/autoload/ui_theme.gd` — implementar font scale dinâmico
- `project.godot` — registrar AccessibilityManager como autoload

### Critérios de Aceite
- [ ] Modo daltônico (3 tipos) altera cores em tempo real, preview instantâneo
- [ ] Reduced motion elimina shake, bob, partículas rápidas
- [ ] Reduced flash limita a ≤3 flashes/segundo
- [ ] High contrast adiciona outlines visíveis em inimigos e projéteis
- [ ] UI scale 150% funciona sem overflow em 1280×720
- [ ] Font scale 150% legível sem quebrar layout
- [ ] Todas as settings persistem entre sessões (SaveManager)
- [ ] Todas as opções aplicam em tempo real (sem restart)

---

## 4. Estatísticas Pós-Run Expandidas

### Problema
A tela de game over mostra dados básicos (kills, tempo, nível, armas). Faltam métricas que roguelite players adoram e que incentivam "mais uma run".

### Solução

#### 4.1 Métricas Adicionais a Rastrear
Durante a run, acumular no `GameManager`:
```gdscript
var run_stats: Dictionary = {
    # Já existentes
    "kills": 0,
    "playtime": 0.0,
    "level": 1,
    "crystals": 0,
    
    # Novos — Combate
    "total_damage_dealt": 0,
    "total_damage_taken": 0,
    "highest_single_hit": 0,
    "dps_peak": 0.0,            # maior DPS em janela de 5s
    "deaths_avoided": 0,        # vezes que HP chegou <10%
    "dash_count": 0,
    "overkill_damage": 0,       # dano além do necessário pra matar
    
    # Novos — Armas
    "damage_per_weapon": {},     # {weapon_id: total_damage}
    "kills_per_weapon": {},      # {weapon_id: kills}
    "favorite_weapon": "",      # arma com mais kills
    
    # Novos — Sinergias
    "synergies_activated": [],   # lista de sinergias que proccaram
    "synergy_procs": {},         # {synergy_name: proc_count}
    "synergy_damage": {},        # {synergy_name: total_damage}
    
    # Novos — Economia
    "xp_collected": 0,
    "items_collected": 0,
    "chests_opened": 0,
    "health_pickups_used": 0,
    "magnets_collected": 0,
    
    # Novos — Tempo
    "time_per_phase": [],        # tempo gasto em cada "wave" de dificuldade
    "boss_kill_time": 0.0,       # tempo pra matar o boss
    "longest_survival_streak": 0.0,  # maior tempo sem tomar dano
}
```

#### 4.2 Tela de Stats Pós-Run (Redesign)
Reorganizar o `game_over_screen.gd` com **2 tabs**:

**Tab 1 — Resumo** (tela atual melhorada):
```
┌─────────────────────────────────────────┐
│  [Sprite]  RONIN  —  Lv. 23            │
│  Tempo: 12:45   |   Kills: 847         │
│  Cristais: 1,250 (×1.5 mutação)        │
│                                         │
│  ⚔ Armas        🧪 Itens     ✨ Evoluções │
│  [grid]         [grid]       [grid]     │
│                                         │
│  🏆 Melhor Hit: 2,450 dano              │
│  📊 DPS Pico: 380/s                     │
│  💀 Quase-mortes: 3                      │
│  🎯 Arma Favorita: Katana (312 kills)   │
│                                         │
│  [📸 Screenshot]  [🔄 Retry]  [🏠 Menu] │
└─────────────────────────────────────────┘
```

**Tab 2 — Detalhes**:
```
┌─────────────────────────────────────────┐
│  REGISTRO DIMENSIONAL                   │
│                                         │
│  ── Combate ──                          │
│  Dano total: 45,230                     │
│  Dano recebido: 3,120                   │
│  Dashes: 87                             │
│  Overkill: 12,400                       │
│                                         │
│  ── Armas (por dano) ──                 │
│  1. Katana      18,200 (40%)  ████████  │
│  2. Fireball     9,800 (22%)  ████      │
│  3. Lightning    7,100 (16%)  ███       │
│                                         │
│  ── Sinergias ──                        │
│  Explosão: 23 procs (4,500 dano)        │
│  Steam: 8 procs (1,200 dano)           │
│                                         │
│  ── Economia ──                         │
│  XP: 2,340  |  Baús: 5  |  HP drops: 8 │
│                                         │
│  [Tab 1: Resumo]           [Tab 2: ◆]   │
└─────────────────────────────────────────┘
```

#### 4.3 Comparação com Melhor Run
- Armazenar best run stats por personagem no `SaveManager`
- Na tela de stats, mostrar setas ▲▼ comparando com a melhor run:
  - `Kills: 847 ▲ (+52)` (verde se melhor, vermelho se pior)
- Apenas para: kills, tempo, nível, DPS pico, cristais

#### 4.4 Narrativa
- Título da tab 2: "Registro Dimensional" (lore-friendly)
- Se o jogador morreu: "O estilhaço registrou esta expedição antes do rebobinamento"
- Se venceu: "O Sentinela foi libertado. O estilhaço guardou esta memória"

### Arquivos a Criar/Modificar
- `scripts/autoload/game_manager.gd` — adicionar `run_stats` dict e tracking
- `scripts/ui/game_over_screen.gd` — redesign com tabs, novos dados
- `scripts/ui/stats_detail_tab.gd` — novo (tab de detalhes)
- `scenes/ui/game_over_screen.tscn` — redesign UI
- `scripts/autoload/save_manager.gd` — persistir best run stats
- `scripts/weapons/*.gd` — emitir sinal de dano com weapon_id
- `scripts/autoload/synergy_system.gd` — emitir sinal com damage dealt

### Critérios de Aceite
- [ ] 15+ métricas novas rastreadas durante a run
- [ ] Tab "Resumo" mostra dados principais + highlights
- [ ] Tab "Detalhes" mostra breakdown por arma, sinergia, economia
- [ ] Comparação com melhor run (setas ▲▼) para 5 métricas principais
- [ ] Best run salva por personagem no SaveManager
- [ ] Textos narrativos (lore-friendly, não genéricos)
- [ ] Bilíngue (PT-BR / EN)
- [ ] Cabe em 1280×720 sem scroll (tabs resolvem espaço)
- [ ] Gamepad navega entre tabs com L1/R1

---

## 5. Seeded Runs Compartilháveis

### Problema
O sistema de seeds existe para Daily Challenge, mas o jogador não pode criar runs customizadas com seed nem compartilhar com amigos.

### Solução

#### 5.1 Input de Seed Customizado
- Na tela de seleção de fenda (world map), adicionar botão "Coordenada Dimensional"
- Ao clicar, abre popup com:
  - Campo de texto para seed (alfanumérico, max 20 chars)
  - Botão "Gerar aleatório" (preenche com seed random)
  - Preview: mostra fenda, modificadores e dificuldade que aquele seed gera
  - Botão "Iniciar Expedição"
- Seed vazio = run normal (sem seed, totalmente aleatório)

#### 5.2 Lógica de Seed
- Converter string → hash numérico (consistente cross-platform)
- Seed controla:
  - Spawn timing e posições de inimigos
  - Drops (quais itens/armas aparecem no level up)
  - Eventos dimensionais (qual evento, quando)
  - Posição de baús
- Seed **não** controla:
  - Ações do jogador
  - Boss AI (mantém padrão determinístico atual)
  - Música (mantém por fenda)

#### 5.3 Exibição e Compartilhamento
- Seed aparece no canto do HUD (texto pequeno, alpha 50%)
- Na tela de game over: seed exibido com botão "Copiar"
- Ao copiar: `"Zion | Seed: ABC123 | Cemetery | Lv.23 | 847 kills"` no clipboard
- Screenshot inclui o seed automaticamente

#### 5.4 Leaderboard por Seed
- Runs com mesmo seed competem entre si
- Ranking por: kills, tempo, nível (3 critérios)
- Leaderboard acessível pela tela de game over (se run teve seed)
- Separado do leaderboard principal e do daily

#### 5.5 Narrativa
- Seed = "Coordenada Dimensional" — cada combinação abre uma fenda específica
- Texto no popup: "Insira as coordenadas para sintonizar a fenda"
- No HUD: "Coordenada: ABC123"

### Arquivos a Criar/Modificar
- `scripts/ui/seed_input_popup.gd` — novo (popup de input)
- `scenes/ui/seed_input_popup.tscn` — novo
- `scripts/autoload/game_manager.gd` — integrar seed no RNG de spawn/drops
- `scripts/stages/*.gd` — usar seeded RNG para spawns
- `scripts/enemies/enemy_spawner.gd` — seeded spawn positions
- `scripts/ui/hud.gd` — exibir seed
- `scripts/ui/game_over_screen.gd` — exibir seed + botão copiar
- `scripts/ui/world_map.gd` — botão de seed input

### Critérios de Aceite
- [ ] Input de seed funcional (alfanumérico, max 20 chars)
- [ ] Mesma seed = mesma sequência de spawns, drops e eventos
- [ ] Seed exibido no HUD e na tela de game over
- [ ] Botão "Copiar" gera texto formatado no clipboard
- [ ] Preview do seed mostra fenda e modificadores antes de iniciar
- [ ] Leaderboard por seed funcional
- [ ] Runs sem seed funcionam normalmente (sem regressão)
- [ ] Bilíngue (PT-BR / EN)

---

## 6. Tutorial Expandido

### Problema
O tutorial cobre apenas 5 mecânicas básicas (mover, atacar, coletar XP, level up, dash). Não ensina sinergias, itens, relíquias, mutações, baús, quests nem o sistema de revive — sistemas que definem o roguelite.

### Solução

#### 6.1 Tutorial em 2 Fases

**Fase 1 — Básico** (tutorial atual, runs 1-2):
Manter os 5 passos existentes. Sem alteração.

**Fase 2 — Avançado** (ativa na 3ª run se `tutorial_advanced_completed == false`):
5 novos passos contextuais (aparecem quando o evento ocorre naturalmente):

| Passo | Gatilho | Mensagem |
|-------|---------|----------|
| 6. Baú | Primeiro baú spawna | "Siga a seta! Baús contêm armas e itens." |
| 7. Item | Jogador pega primeiro item | "Itens dão bônus passivos. Combine com armas certas para evoluções!" |
| 8. Sinergia | Primeira sinergia ativa | "Ressonância cristalina! Armas do mesmo elemento criam sinergias." |
| 9. Quest | Primeira quest aparece | "Mini-objetivos aparecem durante a run. Complete para bônus!" |
| 10. Evento | Primeiro evento dimensional | "Anomalia dimensional! Eventos especiais alteram o campo de batalha." |

#### 6.2 Visual Highlights
- Ao mostrar tooltip de tutorial:
  - **Seta animada** apontando para o elemento relevante (baú, ícone de sinergia, quest, etc.)
  - **Pulse glow** no elemento alvo (shader de outline pulsante)
  - Resto da tela escurece levemente (vignette 15%)
- Seta: sprite 2D com animação de bounce (cima/baixo, 0.5s cycle)

#### 6.3 Barra de Progresso
- Mostrar "Passo X de Y" no canto do tooltip
- Pontos preenchidos para passos completos
- Sutil, não intrusivo

#### 6.4 Opção de Resetar Tutorial
- No menu de opções (tab Gameplay): "Resetar tutorial"
- Reseta `tutorial_completed` e `tutorial_advanced_completed`
- Confirmação antes de resetar

### Arquivos a Criar/Modificar
- `scripts/ui/tutorial_overlay.gd` — expandir com fase 2, highlights, seta, progresso
- `scripts/ui/tutorial_arrow.gd` — novo (seta animada apontando para alvos)
- `scenes/ui/tutorial_arrow.tscn` — novo
- `assets/sprites/ui/tutorial_arrow.png` — novo (sprite de seta)
- `scripts/autoload/save_manager.gd` — adicionar `tutorial_advanced_completed`
- `scripts/ui/options_screen.gd` — botão de resetar tutorial

### Critérios de Aceite
- [ ] Fase 2 do tutorial ativa na 3ª run automaticamente
- [ ] 5 novos passos contextuais (aparecem no evento, não forçados)
- [ ] Seta animada aponta para elemento relevante
- [ ] Highlight/glow no elemento alvo
- [ ] Barra de progresso (passo X de Y) visível
- [ ] Opção de resetar tutorial no menu
- [ ] Bilíngue (PT-BR / EN)
- [ ] Skip funciona em qualquer passo (pula toda a fase)
- [ ] Não interfere com gameplay (jogador pode agir durante tooltip)

---

## Ordem de Implementação Sugerida

| Fase | Item | Justificativa |
|------|------|---------------|
| 1 | §3 Acessibilidade | Opções já existem no menu — implementar é "ligar o que já tem" |
| 2 | §2 Áudio | Impacto em todas as runs, especialmente multiplayer |
| 3 | §1 Sinergias | Melhora compreensão do sistema mais complexo do jogo |
| 4 | §4 Stats Pós-Run | Maior "bang for the buck" em replay value |
| 5 | §6 Tutorial | Beneficia novos jogadores (onboarding) |
| 6 | §5 Seeds | Feature adicional, não bloqueia lançamento |

---

## Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| Shader daltônico impacta performance | Baixa | Shader é simples (3×3 matrix multiply), testar em GPU mínima |
| Tracking de stats aumenta lag | Baixa | Incrementos atômicos em dict, sem allocation por frame |
| Seed não é determinístico cross-platform | Média | Usar `hash()` do GDScript (consistente) + testes automatizados |
| UI de stats não cabe em 720p | Média | Tabs resolvem; testar layout em 1280×720 antes de finalizar |
| Ducking de áudio causa artefatos | Baixa | Fade suave (0.3s), nunca corte abrupto |
| Tutorial avançado irrita veteranos | Baixa | Skip button visível, auto-disable após completar |

---

## Métricas de Sucesso

- **Acessibilidade**: ≥4 opções funcionais (daltônico, motion, flash, contrast)
- **Áudio**: 0 clipping reports com 4 jogadores simultâneos
- **Sinergias**: jogadores entendem sinergias sem consultar wiki
- **Stats**: tempo médio na tela de game over aumenta (engajamento)
- **Seeds**: ≥10% das runs usam seed customizado após 1 mês
- **Tutorial**: taxa de abandono na 1ª hora reduz ≥20%

---

## Fora de Escopo

- Bestiary/Codex (PRD separado)
- Modifiers/Mutators customizáveis (PRD separado)
- Replay system (pós-lançamento)
- Localização ES/JP (pós-lançamento)
- Matchmaking online (pós-lançamento)
