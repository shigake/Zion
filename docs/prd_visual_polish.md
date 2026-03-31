# PRD — Visual Polish e Atmosfera

> Melhorias visuais que aumentam percepção de qualidade sem mudar gameplay.

---

## Tarefa 1: Iluminação e atmosfera por fenda

**Objetivo:** Cada fenda tem iluminação, fog e cor ambiente únicos.

### Detalhes

No `base_stage.gd` ou em cada stage script, configurar `WorldEnvironment` com:

| Fenda | Ambient | Fog | Tonemap | Mood |
|-------|---------|-----|---------|------|
| Cemetery | Roxo frio | Denso cinza | Escuro | Horror |
| Forest | Verde quente | Leve verde | Natural | Misterio |
| Farm | Amarelo | Poeira | Quente | Western |
| Tokyo | Ciano/neon | Nenhum | Saturado | Cyberpunk |
| Volcano | Vermelho | Lava | Quente forte | Inferno |
| Ocean | Azul profundo | Denso azul | Frio | Abismo |
| Arena | Dourado | Leve | Contraste | Gladiador |
| Space | Roxo escuro | Nenhum | Frio | Cosmico |
| Castle | Vermelho escuro | Leve roxo | Escuro | Gotico |
| Candy | Rosa/pastel | Leve rosa | Saturado | Fantasia |

### Critérios de aceite

- [ ] 10 fendas com iluminação distinta
- [ ] Fog visível nas fendas atmosféricas
- [ ] Sem impacto em FPS (fog volumétrico OFF, usar fog linear)

---

## Tarefa 2: Reativar kill streak com UI melhorada

**Objetivo:** Mostrar combos de kill com feedback visual escalante.

### Detalhes

O ScreenEffects já tem infraestrutura de kill streak desabilitada. Reativar com:
- Texto centralizado (não no canto)
- Escala crescente por tier (5→10→20→50 kills)
- Cores por tier: branco → amarelo → laranja → vermelho
- Fade rápido (1.5s visível)

### Critérios de aceite

- [ ] Kill streak aparece ao matar 5+ inimigos em 2s
- [ ] 4 tiers visuais (combo, massacre, unstoppable, godlike)
- [ ] Não atrapalha gameplay (posição não bloqueia visão)

---

## Tarefa 3: Boss HP bar com feedback visual

**Objetivo:** Tornar a boss HP bar mais dramática e responsiva.

### Detalhes

- Shake horizontal quando boss toma dano
- Pulse vermelho intenso abaixo de 25% HP (já existe parcial)
- Flash branco quando muda de fase
- Barra de "ghost HP" (mostra dano recente como sombra)

### Critérios de aceite

- [ ] HP bar treme ao receber dano
- [ ] Ghost HP visível por 0.5s após cada hit
- [ ] Flash na mudança de fase

---

## Tarefa 4: Feedback visual nos inimigos especiais

**Objetivo:** Inimigos com behaviors especiais devem ter indicadores visuais.

### Detalhes

- Teleport: flash + partículas na posição antiga e nova
- Charge: trail de velocidade (afterimage)
- Stealth: semi-transparente quando escondido
- Elite: aura dourada pulsante
- Explode on death: brilho vermelho crescente antes de explodir

### Critérios de aceite

- [ ] Teleport tem efeito visual claro
- [ ] Charge tem indicação de direção
- [ ] Stealth inimigos ficam translúcidos
- [ ] Elites claramente distinguíveis

---

## Tarefa 5: Bloom e glow em momentos chave

**Objetivo:** Adicionar bloom sutil em pickups, level up e evolução.

### Detalhes

Usar `Environment.glow_enabled` com intensidade variável:
- Glow base: 0.3 (sutil, sempre ativo)
- Level up: spike para 0.8 por 0.5s
- Evolução: spike para 1.2 por 1s
- Boss morte: spike para 1.0 por 1s

### Critérios de aceite

- [ ] Bloom sutil sempre ativo
- [ ] Momentos especiais têm bloom intensificado
- [ ] Sem impacto em FPS (glow é pós-processamento leve)

---

## Ordem

| Fase | Tarefas | Impacto |
|------|---------|---------|
| A | 1 | Alto — muda completamente a atmosfera |
| B | 2, 3 | Médio — feedback de combate |
| C | 4, 5 | Médio — polish fino |
