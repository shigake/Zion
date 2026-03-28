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

### 1. Smoke Test (rapido, ~2 min cada) ✅
Verifica que cada combinacao basica funciona sem crash:
- [x] Cada personagem (12) no Cemetery por 2 min
- [x] Cada stage (10) com Ronin por 2 min
- [x] Cada modo de jogo (Normal, Endless, Boss Rush, Hyper) por 2 min

### 2. Weapon Test (medio, ~5 min cada) ✅
Testa cada arma isoladamente:
- [x] Cada arma (28) solo — forca level up so dessa arma ate lv8
- [x] Mede: DPS real por level, kills por minuto, tempo ate morrer
- [x] Verifica: arma causa dano, inimigos morrem, sem crash

### 3. Evolution Test ✅
- [x] Cada evolucao (12) — forca arma lv8 + item lv5
- [x] Verifica: bau de evolucao aparece, evolucao funciona
- [x] Mede: DPS antes vs depois da evolucao

### 4. Full Run Test (longo, ~30 min cada) ✅
Simula uma run completa:
- [x] 3 personagens base (ronin, soldado, mago) no cemetery por 30 min
- [x] Mede: tempo sobrevivido, kills, level alcancado, armas obtidas, DPS final
- [x] Verifica: boss spawna, boss morre, vitoria registrada

### 5. Balance Test ✅
- [x] Curva de XP: levels alcancados por minuto
- [x] Curva de DPS: dano por segundo por personagem
- [x] Economy: cristais ganhos por run por stage
- [x] Kills por minuto

### 6. Stress Test ✅
- [x] 500+ inimigos simultaneos (verifica FPS) — Hyper mode
- [x] Modo Endless prolongado (10 min)
- [x] Max enemies stress test

### 7. Achievement Test ✅
- [x] first_walk: sobreviver 5+ minutos
- [x] nobody_deserves: morrer em < 10 segundos
- [x] genocide: 10000 kills (hyper mode)
- [x] speedrunner: boss em < 15 min
- [x] sweet_revenge: completar Candy
- [x] cow_brejo: Farm sem dano de vaca
- [x] pacifist: sobreviver 3 min sem atacar

### 8. Event Test ✅
- [x] Timeline completa (23 min) — golden_horde ate portal_dimensional
- [x] Eventos em diferentes stages (forest, volcano, candy)
- [x] Tracking de eventos triggered vs esperados

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
# Rodar smoke test (rapido, ~50 min — 26 testes de 2 min)
godot --path game --run -- --test=smoke

# Rodar weapon test (medio, ~1.5h — 28 armas x 3 min)
godot --path game --run -- --test=weapons

# Rodar evolution test (~1h — 12 evolucoes x 5 min)
godot --path game --run -- --test=evolution

# Rodar balance test (~45 min — curvas XP/DPS/economia)
godot --path game --run -- --test=balance

# Rodar achievement test (~1.5h — 7 achievements simulados)
godot --path game --run -- --test=achievements

# Rodar event test (~1h — timeline de eventos em 4 stages)
godot --path game --run -- --test=events

# Rodar full run test (longo, ~1.5h — 3 runs de 30 min)
godot --path game --run -- --test=full

# Rodar stress test (~20 min)
godot --path game --run -- --test=stress

# Rodar menu smoke test (rapido, ~2 min)
godot --path game --run -- --test=menu_smoke

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
