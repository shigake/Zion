# Mecanicas de Gameplay

## Sistema de Sinergias Elementais

Armas do mesmo elemento combinam para efeitos extras:

| Combinacao | Efeito |
|---|---|
| **Fogo + Fogo** | Chance de causar explosao ao matar |
| **Gelo + Gelo** | Inimigos congelados explodem em estilhacos |
| **Eletrico + Eletrico** | Chain lightning mais longo |
| **Dark + Dark** | Area de trevas que da dano passivo |
| **Fogo + Gelo** | Steam cloud (dano + cegueira nos inimigos) |
| **Eletrico + Agua** | Condutor (dano em area massivo) |

### Cross-Combo (Multiplayer)
- Armas com elemento criam "zonas elementais" persistentes
- Quando projetil de um aliado com elemento diferente atinge a zona, dispara Cross-Combo
- 1.5x dano em AoE + efeito visual
- Combinacoes: Fogo+Gelo (Steam Cloud), Eletrico+Veneno (Toxic Shock), etc.
- Cooldown de 2 segundos por par de jogadores

### Reviver com Sacrificio (Multiplayer)
- Jogador morto deixa uma Lapide na posicao de morte
- Aliados podem reviver ficando 5 segundos perto da lapide
- Jogador renasce com 50% HP
- Aliado que reviveu recebe -30% HP maximo por 30 segundos
- Lapide desaparece apos 60 segundos (morte permanente)

### Mutacoes (Modo Ascensao)
- Modificadores de dificuldade opcionais ativados antes da run
- 6 mutacoes: Inimigos Explosivos, Chefes Furiosos, Cura Enfraquecida, Speed Demons, Horda Infinita, Sem Evolucao
- Cada mutacao aumenta o multiplicador de cristais ganhos
- Maximo teorico: x2.65 cristais com todas as mutacoes ativas

---

## Mecanicas Unicas por Stage

Cada stage tem uma zona ambiental (Area3D) com efeito especial:

| Stage | Mecanica | Efeito |
|---|---|---|
| **Cemiterio** | Tumulos destrutiveis | Dropam power-ups aleatorios |
| **Floresta** | Cogumelos de buff | Buff aleatorio 10s (speed/damage/area) |
| **Fazenda** | Milharal | Jogador invisivel pra inimigos dentro do milho |
| **Toquio** | Paineis eletricos | 5 dano/s eletrico |
| **Vulcao** | Lava pools | 10 dano/s fogo, inimigos de fogo imunes |
| **Oceano** | Correntes | Empurram jogador e inimigos |
| **Arena** | Plateia | Itens aleatorios (cura/bomba) a cada 30s |
| **Espaco** | Zero-G zones | +50% speed, -30% controle |
| **Castelo** | Zonas escuras | Inimigos +30% dano, tochas = zonas seguras |
| **Mundo Doce** | Caramelo | -50% speed |

---

## Leaderboard Global

- Tabs: Geral, Por fase, Por personagem, Desafio diario
- Colunas: posicao, nome, pontuacao, kills, tempo, personagem, fase
- Dados mockados para teste (integracao online futura)

---

## Sistema de Reliquias

Escolhe 1 reliquia no inicio de cada run. Define a estrategia da partida.

| Reliquia | Efeito |
|---|---|
| **Ampulheta** | Tempo da run aumenta de 30 pra 40 min |
| **Dados de Ouro** | 1 reroll extra em cada level up |
| **Bussola** | Mostra direcao do proximo evento especial |
| **Coracao Extra** | Comeca com +50% HP |
| **Pergaminho Antigo** | Comeca com 1 arma extra aleatoria |
| **Medalha de Veterano** | +20% XP mas inimigos +15% mais rapidos |
| **Chave Mestre** | Baus dropam 2x itens |

---

## Eventos Especiais (durante a run)

| Evento | Minuto | Descricao |
|---|---|---|
| **Horda Dourada** | 5 | Onda de inimigos dourados que dropam muito gold |
| **Eclipse** | 8 | Tela escurece, inimigos ficam invisiveis, dura 30s |
| **Chuva de Meteoros** | 12 | Meteoros caem aleatoriamente, dano em tudo |
| **Treasure Goblin** | Aleatorio | Inimigo que foge, se matar dropa bau epico |
| **Desafio do Anjo** | 15 | Anjo oferece: dobrar dano MAS metade do HP |
| **Portal Dimensional** | 20 | Teletransporta pra mini-dungeon com boss + recompensa |
| **Fever Mode** | Ao coletar muita XP rapido | 10s de dano dobrado + velocidade |
| **Merchant** | Aleatorio | NPC vendendo 3 itens raros por gold |
| **Chest Mimic** | Aleatorio | Bau que e na verdade um mini-boss |
| **Roda da Fortuna** | 10 | Roda gira, pode dar buff insano ou debuff temporario |
