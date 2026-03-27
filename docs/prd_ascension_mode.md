# PRD — Modo Ascensao (Meta-progressao / Mutacoes)

> **Status: Pendente**
> Sistema de mutacoes pre-run que aumentam a dificuldade em troca de multiplicadores de cristais. Interface no lobby, modificadores de gameplay, e economia atualizada.

## Objetivo

Adicionar uma camada de meta-progressao e rejogabilidade atraves de "Mutacoes" (modificadores de dificuldade) que o jogador ativa antes de iniciar uma run. Quanto mais mutacoes ativas, maior o multiplicador de cristais ganhos.

Inspiracao: Heat System de Hades, Ascension de Slay the Spire, Torments de Diablo 3.

## Contexto

- O fluxo pre-run atual permite escolher: Personagem → Fase → Modo → 1 Reliquia
- Os cristais sao creditados na "Tela de Resultado" no fim da run
- O sistema de telemetria ja envia dados de run via POST /telemetry
- Sinergias elementais, eventos e bosses com fases ja existem

---

## Parte 1 — Interface do Sistema de Mutacao

### 1.1 UI do Lobby
- [ ] Criar painel "Mutacoes" na interface de preparacao de partida
- [ ] Posicionamento: apos selecao de reliquia, antes do Host confirmar inicio
- [ ] No multiplayer: apenas o Host configura as mutacoes (outros jogadores veem as escolhas)
- [ ] Layout: grid de cards, cada card = uma mutacao com icone, nome e descricao
- [ ] Nova cena: `scenes/ui/mutations_panel.tscn` com script `scripts/ui/mutations_panel.gd`

### 1.2 Seletores
- [ ] Cada mutacao tem um checkbox (on/off) ou slider (niveis 0-3 para mutacoes escalaveis)
- [ ] Icones visuais distintos por mutacao (podem ser emojis/ASCII inicialmente, depois SVG/sprites)
- [ ] Tooltip ao hover com descricao detalhada e bonus de cristais
- [ ] Animacao sutil ao ativar/desativar (scale bounce + color flash)

### 1.3 Feedback Visual de Multiplicador
- [ ] Label dinamico no topo do painel: "Multiplicador de Cristais: x1.0"
- [ ] Atualiza em tempo real conforme mutacoes sao ativadas/desativadas
- [ ] Cor escala com o multiplicador: branco (1.0x) → amarelo (1.5x) → laranja (2.0x) → vermelho (3.0x+)
- [ ] Previsao estimada de cristais baseada em run media

---

## Parte 2 — Modificadores de Dificuldade

### 2.1 Mutacao "Inimigos Explosivos"
- **Efeito**: Todos os inimigos explodem ao morrer (como o Bomber)
- **Implementacao**:
  - [ ] No trigger de morte dos inimigos (`scripts/enemies/enemy_base.gd`), verificar se mutacao esta ativa
  - [ ] Reutilizar a mecanica de explosao do Bomber existente (`scripts/enemies/bomber.gd`)
  - [ ] Dano da explosao: 50% do HP max do inimigo (ajustavel)
  - [ ] Raio: 1.5 unidades
  - [ ] Particulas de explosao via `ParticleFactory`
- **Bonus cristais**: +25%
- **Dificuldade**: Media

### 2.2 Mutacao "Chefes Furiosos"
- **Efeito**: Bosses comecam na fase 2 (75% HP), pulando a fase 1
- **Implementacao**:
  - [ ] Modificar logica de spawn dos bosses em `scripts/enemies/boss_behavior.gd`
  - [ ] Se mutacao ativa: setar HP inicial em 75% e forcar transicao para fase 2
  - [ ] Bosses ja mudam de padrao a cada 25% HP — apenas pular a primeira fase
  - [ ] Boss fica mais agressivo desde o inicio da luta
- **Bonus cristais**: +30%
- **Dificuldade**: Alta

### 2.3 Mutacao "Cura Enfraquecida"
- **Efeito**: Toda cura (lifesteal, drops, itens) e reduzida em 50%
- **Implementacao**:
  - [ ] Adicionar modificador global em `GameManager` ou novo `MutationManager`
  - [ ] Interceptar toda logica de cura: lifesteal do Vampiro, drops de cura, itens passivos
  - [ ] Multiplicador de cura: `heal_amount * mutation_heal_modifier` (default 1.0, com mutacao 0.5)
  - [ ] Indicador visual: coracao com icone de "enfraquecido" no HUD
- **Bonus cristais**: +20%
- **Dificuldade**: Media

### 2.4 Mutacoes Adicionais (Futuras)
- [ ] "Velocidade Mortal": inimigos 30% mais rapidos (+15% cristais)
- [ ] "Horda Infinita": +50% taxa de spawn (+35% cristais)
- [ ] "Sem Evolucao": armas nao podem evoluir (+40% cristais)
- [ ] "Fog of War": visao reduzida em 40% (+20% cristais)
- [ ] "Tempo Cruel": timer da run reduzido em 25% (+25% cristais)

---

## Parte 3 — Economia e Recompensas

### 3.1 Multiplicador de Recompensas
- [ ] Atualizar funcao de calculo de cristais na tela de resultado
- [ ] Formula: `cristais_base * (1.0 + soma_bonus_mutacoes)`
- [ ] Exemplo: run normal = 100 cristais. Com "Explosivos" (+25%) e "Chefes Furiosos" (+30%) = 100 * 1.55 = 155 cristais
- [ ] Exibir breakdown na tela de resultado: "Base: 100 | Mutacoes: +55 | Total: 155"
- [ ] Mutacoes ativas exibidas como icones na tela de resultado

### 3.2 Telemetria
- [ ] Adicionar campo `mutations_active: Array[String]` no JSON enviado via POST /telemetry
- [ ] Exemplo: `"mutations_active": ["explosive_enemies", "furious_bosses"]`
- [ ] Dashboard no servidor: grafico de mutacoes mais populares
- [ ] Dados para balanceamento: correlacao mutacao ↔ taxa de vitoria

---

## Arquitetura Tecnica

### Novo Singleton: MutationManager
```
scripts/autoload/mutation_manager.gd
- active_mutations: Dictionary  (mutation_id → level)
- get_crystal_multiplier() → float
- is_active(mutation_id) → bool
- get_heal_modifier() → float
- get_spawn_modifier() → float
- reset()  (chamado no inicio de cada run)
```

### Dados de Mutacao
```gdscript
var MUTATIONS = {
    "explosive_enemies": {
        "name": "Inimigos explosivos",
        "description": "Inimigos explodem ao morrer",
        "icon": "bomb",
        "crystal_bonus": 0.25,
        "max_level": 1
    },
    "furious_bosses": { ... },
    "weakened_healing": { ... },
}
```

## Arquivos Afetados

- **Novo**: `scripts/autoload/mutation_manager.gd` — singleton de mutacoes
- **Novo**: `scenes/ui/mutations_panel.tscn` + `scripts/ui/mutations_panel.gd` — UI
- `scripts/enemies/enemy_base.gd` — explosao na morte
- `scripts/enemies/boss_behavior.gd` — fase inicial do boss
- `scripts/player/player_controller.gd` — modificador de cura
- `scripts/autoload/game_manager.gd` — multiplicador de cristais
- `scripts/ui/result_screen.gd` — breakdown de cristais
- `scripts/autoload/telemetry.gd` — campo mutations_active
- `project.godot` — registrar autoload MutationManager

## Balanceamento

| Mutacao | Bonus Cristais | Dificuldade |
|---|---|---|
| Inimigos Explosivos | +25% | Media |
| Chefes Furiosos | +30% | Alta |
| Cura Enfraquecida | +20% | Media |
| Velocidade Mortal | +15% | Baixa-Media |
| Horda Infinita | +35% | Alta |
| Sem Evolucao | +40% | Muito Alta |

Bonus sao cumulativos. Maximo teorico com todas: ~165% bonus (x2.65 cristais).
