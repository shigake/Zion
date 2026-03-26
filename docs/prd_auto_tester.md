# PRD — Sistema de Teste Automatizado (Auto-Tester)

## Objetivo

Criar um "jogador virtual" que testa todas as funcionalidades do jogo automaticamente, logando metricas detalhadas para verificar que tudo funciona e para balancear o jogo.

O sistema roda N simulacoes em sequencia (headless ou visual), cada uma com configuracoes diferentes, e gera um relatorio completo no final.

---

## Arquitetura

### AutoTester (autoload singleton)
- Controla a execucao dos testes
- Configura cada run (personagem, stage, armas, modo)
- Coleta metricas durante a run
- Gera relatorio ao final

### AutoPlayer (script attachado ao Player)
- Movimenta o jogador automaticamente (fugir de inimigos, coletar XP)
- Faz level up automatico (escolhe opcoes aleatorias ou especificas)
- Interage com baus, merchants, etc
- Simula dash quando cercado

---

## Testes a Executar

### 1. Smoke Test (rapido, ~2 min cada)
Verifica que cada combinacao basica funciona sem crash:
- [ ] Cada personagem (12) no Cemetery por 2 min
- [ ] Cada stage (10) com Ronin por 2 min
- [ ] Cada modo de jogo (Normal, Endless, Boss Rush, Hyper) por 2 min

### 2. Weapon Test (medio, ~5 min cada)
Testa cada arma isoladamente:
- [ ] Cada arma (28) solo — forca level up so dessa arma ate lv8
- [ ] Mede: DPS real por level, kills por minuto, tempo ate morrer
- [ ] Verifica: arma causa dano, inimigos morrem, sem crash

### 3. Evolution Test
- [ ] Cada evolucao (12) — forca arma lv8 + item lv5
- [ ] Verifica: bau de evolucao aparece, evolucao funciona
- [ ] Mede: DPS antes vs depois da evolucao

### 4. Full Run Test (longo, ~30 min cada)
Simula uma run completa:
- [ ] Cada personagem em cada stage (120 combinacoes)
- [ ] Mede: tempo sobrevivido, kills, level alcancado, armas obtidas, DPS final
- [ ] Verifica: boss spawna, boss morre, vitoria registrada

### 5. Balance Test
- [ ] Curva de XP: levels alcancados por minuto
- [ ] Curva de DPS: dano por segundo por minuto
- [ ] Curva de HP: HP do jogador ao longo do tempo
- [ ] Spawn rate: inimigos spawados vs mortos por minuto
- [ ] Economy: cristais ganhos por run

### 6. Stress Test
- [ ] 500+ inimigos simultaneos (verifica FPS)
- [ ] 1000+ inimigos (verifica MultiMesh ativa)
- [ ] Todas as armas lv8 + todos os itens lv5 (max power)

### 7. Achievement Test
- [ ] Verifica que cada achievement (13) pode ser desbloqueado
- [ ] Simula condicoes especificas (morrer em 10s, sobreviver 5min, etc)

### 8. Event Test
- [ ] Cada evento (10) dispara e funciona
- [ ] Merchant: compra funciona
- [ ] Portal Dimensional: teletransporte funciona
- [ ] Eclipse: inimigos ficam invisiveis

---

## Metricas Coletadas (por run)

```
{
  "config": {
    "character": "ronin",
    "stage": "cemetery",
    "mode": "normal",
    "forced_weapons": [],
    "test_type": "full_run"
  },
  "result": {
    "survived": true,
    "victory": false,
    "time_survived": 1234.5,
    "total_kills": 5678,
    "total_damage_dealt": 123456,
    "total_damage_taken": 789,
    "level_reached": 35,
    "weapons_obtained": ["katana:8", "staff:6", "scythe:4"],
    "items_obtained": ["boots:3", "glove:2"],
    "evolutions": ["zangetsu"],
    "events_triggered": ["golden_horde", "eclipse"],
    "achievements_unlocked": ["first_walk"],
    "crystals_earned": 234,
    "boss_killed": true,
    "boss_time": 1500.0,
    "fps_min": 45,
    "fps_avg": 58,
    "fps_max": 60,
    "enemies_peak": 487,
    "errors": []
  },
  "timeline": [
    {"time": 60, "level": 5, "kills": 120, "dps": 45, "hp": 100},
    {"time": 120, "level": 10, "kills": 380, "dps": 120, "hp": 95},
    ...
  ]
}
```

---

## Output

### Log File
- `user://test_results/[timestamp]_[test_type].json`
- Um arquivo JSON por suite de testes
- Contem todas as runs com metricas

### Console Summary
- Print resumo no console ao final
- Destaca: crashes, runs muito curtas (< 1 min), DPS outliers, FPS drops

### Balance Report
- Compara DPS real vs esperado (da tabela do prd_balancing.md)
- Identifica armas over/underpowered
- Identifica stages muito faceis/dificeis

---

## Como Usar

```bash
# Rodar smoke test (rapido, ~30 min)
godot --path game --run -- --test=smoke

# Rodar weapon test (medio, ~2h)
godot --path game --run -- --test=weapons

# Rodar full test (longo, ~8h)
godot --path game --run -- --test=full

# Rodar stress test
godot --path game --run -- --test=stress

# Rodar todos os testes
godot --path game --run -- --test=all
```

---

## Implementacao

### Arquivos
- `game/scripts/autoload/auto_tester.gd` — Controlador principal
- `game/scripts/tests/auto_player.gd` — IA do jogador virtual
- `game/scripts/tests/test_runner.gd` — Executa suites de testes
- `game/scripts/tests/test_report.gd` — Gera relatorios

### AutoPlayer AI
O jogador virtual usa logica simples:
1. **Movimento**: Foge do grupo mais proximo de inimigos (vetor oposto ao centroide)
2. **Coleta**: Move em direcao a XP gems quando seguro (sem inimigos perto)
3. **Dash**: Usa quando 3+ inimigos dentro de raio 3.0
4. **Level Up**: Escolhe opcao aleatoria (ou forcada para testes especificos)
5. **Interacao**: Interage com baus/merchants quando perto (pressiona E)

### Integracao
- AutoTester e registrado como autoload (so ativo em modo teste)
- Detecta `--test=X` nos argumentos de linha de comando
- Sobrescreve o input do jogador com o AutoPlayer
- Ao final de cada run, salva metricas e inicia proxima run
