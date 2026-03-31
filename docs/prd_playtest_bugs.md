# PRD — Bugs de Playtest (Sessão 31/03/2026)

> Todos os bugs reportados durante playtest real. Cada item deve ser verificado, corrigido e testado.

---

## Bug 1: Quests travam antes de completar (CRÍTICO)

**Problema:** Quest "eliminar 50 inimigos" trava em 49/50. Quest "sobreviver sem dano 30s" trava em 29/30.

**Causa provável:** O `_update_quest_progress()` no `_process()` pode pular o frame exato de conclusão. O fix anterior (checar no signal `enemy_killed`) só cobriu o tipo "kill", não "survive".

**Fix necessário:**
- Tipo "survive": usar `>=` no check E verificar a cada frame sem depender de delta acumulado
- Tipo "kill": verificar se o fix anterior realmente funciona (testar `>=` vs `==`)
- TODOS os tipos: garantir que `_complete_quest()` é chamado no momento certo

### Critérios de aceite
- [ ] Quest kill 50 completa ao matar o 50o inimigo
- [ ] Quest survive 30s completa ao atingir 30s
- [ ] Quest collect_xp completa corretamente
- [ ] Quest find_chest completa ao coletar baú
- [ ] Quest reach_level completa ao subir de nível

---

## Bug 2: Baú não funciona ao tocar (CRÍTICO)

**Problema:** Player fica em cima do baú e nada acontece.

**Causa:** `body_entered` do Area3D pode não disparar se layers de colisão não batem, ou se o player já está dentro quando o baú spawna.

**Fix necessário:**
- Verificar se o fallback por distância (< 2.0) está funcionando
- Testar se `collision_mask = 1` detecta o player (layer 1)
- Se necessário, remover Area3D e usar só distância no `_process`

### Critérios de aceite
- [ ] Baú coletado ao se aproximar (< 2.0 unidades)
- [ ] Recompensa aparece (cristais, XP, heal ou reroll)
- [ ] VFX e SFX tocam ao coletar
- [ ] Baú desaparece após coleta

---

## Bug 3: Garrafa de veneno — só círculo verde (VISUAL)

**Problema:** A poça de veneno é um disco verde procedural sem textura. Parece placeholder.

**Fix necessário:** Criar sprite pixel art para a poça de veneno e aplicar no `poison_bottle.gd`.

### Critérios de aceite
- [ ] Poça de veneno tem sprite pixel art (não mesh procedural)
- [ ] Bolhas e pulsing mantidos

---

## Bug 4: Magic Book não orbita visivelmente (GAMEPLAY)

**Problema:** O livro mágico deveria orbitar o player mas o sprite não acompanha a órbita.

**Causa:** Sprite era child do parent errado. Fix parcial feito mas precisa verificar.

**Fix necessário:** Confirmar que o sprite segue `book_mesh.position` no `_process`.

### Critérios de aceite
- [ ] Sprite do livro visível orbitando o player
- [ ] Projéteis (páginas) disparam do livro na direção do inimigo
- [ ] Livro causa dano de contato ao tocar inimigos

---

## Bug 5: Mercador dimensional não vende (GAMEPLAY)

**Problema:** O NPC do mercador aparece mas não abre UI de compra.

**Causa:** O fix anterior adicionou overlap check deferred, mas pode não estar funcionando.

**Fix necessário:** Revisar toda a lógica do mercador — verificar se UI de compra existe e é mostrada.

### Critérios de aceite
- [ ] Ao se aproximar do mercador, UI de compra aparece
- [ ] 3 itens disponíveis para comprar com cristais
- [ ] Compra funciona e item é adicionado
- [ ] Mercador desaparece após tempo limite

---

## Bug 6: Orbe de Sangue — ataque visual fraco (VISUAL)

**Problema:** O blood_orb ataca com uma "linha vermelha safadinha" — visual sem impacto.

**Fix necessário:** Melhorar o visual do beam/ataque do blood_orb com partículas, glow, ou sprite.

### Critérios de aceite
- [ ] Ataque do blood orb tem visual impactante
- [ ] Trail ou partículas vermelhas no caminho do ataque

---

## Bug 7: Boss parece ter vida infinita (BALANCE)

**Problema:** Bosses (especialmente alt bosses) têm HP muito alto para o dano do player no início.

**Causa:** Alt bosses têm 2500-5000 HP. Player no início faz ~15 dano por hit.

**Fix necessário:** Reduzir HP dos alt bosses ou escalar com o tempo de jogo.

### Critérios de aceite
- [ ] Boss morre em tempo razoável (~1-2 min de luta)
- [ ] HP dos alt bosses balanceado (não mais que 2x do original)
- [ ] Boss do minuto 5 mais fraco que do minuto 10

---

## Bug 8: Performance degrada com tempo (PERFORMANCE)

**Problema:** FPS cai progressivamente, tela trava, causa enjoo.

**Causa provável:**
- Memory leak (nodes não sendo liberados)
- Partículas acumulando
- Tweens não finalizados
- Inimigos mortos não sendo removidos do pool

**Fix necessário:** Auditar todos os sistemas que criam nodes em runtime.

### Critérios de aceite
- [ ] FPS estável acima de 30 após 10 min de gameplay
- [ ] Sem memory leaks (RAM não cresce indefinidamente)
- [ ] Nodes mortos são limpos corretamente

---

## Bug 9: Sangue de Vampiro balanceamento (BALANCE)

**Problema:** Lifesteal era OP (curava a cada hit). Fix mudou para chance-based mas precisa teste.

**Status:** Rebalanceado para chance-based (5% chance, heal 15% do dano, min 1 HP).

### Critérios de aceite
- [ ] Lifesteal não é OP com armas rápidas (machinegun)
- [ ] Lifesteal perceptível com armas lentas (katana)
- [ ] Mínimo 1 HP quando ativa

---

## Bug 10: Lealith arma inicial (Shadow Claw) difícil de ver (VISUAL)

**Problema:** O ataque do shadow claw é quase invisível. Jogador não entende o que a arma faz.

**Status:** Adicionado arco roxo mesh durante swipe. Precisa verificar se ficou visível o suficiente.

### Critérios de aceite
- [ ] Ataque claramente visível (arco roxo + trail)
- [ ] Jogador entende que é uma arma melee de curto alcance

---

## Bug 11: HP bar do player (VISUAL)

**Problema:** Barra verde grande em cima da tela é feia.

**Status:** Adicionada barra world-space embaixo do sprite. Precisa verificar se a barra temática do HUD (CharacterHPBar) ainda aparece redundante.

### Critérios de aceite
- [ ] Barra de HP visível embaixo do personagem
- [ ] Cor muda com HP (verde → amarelo → vermelho)
- [ ] Sem barra duplicada/redundante no HUD

---

## Bug 12: Boss HP bar difícil de ler (VISUAL)

**Problema:** A barra de HP do boss é esquisita, difícil saber a vida.

**Status:** Melhorada (mais fina, mais estreita). Shake e ghost HP adicionados.

### Critérios de aceite
- [ ] HP bar do boss claramente visível no topo
- [ ] Nome do boss legível
- [ ] Shake visual ao tomar dano

---

## Bug 13: Cruz do cemitério chão rosa (VISUAL)

**Status:** ✅ Corrigido (cor mudada de roxo para cinza-pedra).

### Critérios de aceite
- [ ] Sem chão rosa no cemitério

---

## Bug 14: Alt bosses sem sprite (VISUAL)

**Status:** ✅ Corrigido (lookup por node name sem prefix "boss_").

### Critérios de aceite
- [ ] 20 alt bosses mostram sprite pixel art

---

## Bug 15: Fantasma branco teleportando (GAMEPLAY)

**Status:** ✅ Corrigido (removido teleport da cemetery_banshee).

### Critérios de aceite
- [ ] Fantasmas brancos se movem normalmente, sem teleportar

---

## Bug 16: Meteoros sem sprite (VISUAL)

**Status:** ✅ Corrigido (sprite meteor.png gerado e aplicado).

### Critérios de aceite
- [ ] Meteoros têm visual de fireball, não bola laranja

---

## Bug 17: Baú sem sprite (VISUAL)

**Status:** ✅ Corrigido (sprite chest.png gerado e aplicado).

### Critérios de aceite
- [ ] Baú tem visual de treasure chest pixel art

---

## Bug 18: Magic Book projéteis invisíveis (GAMEPLAY)

**Status:** ✅ Corrigido (bullet.gd _reset_for_reuse garante sprite visível).

### Critérios de aceite
- [ ] Projéteis do Magic Book visíveis ao disparar

---

## Bug 19: GameConstants parse error quebrando tudo (CRÍTICO)

**Status:** ✅ Corrigido (GameConstants virou autoload, removidas static funcs com ResourceLoader).

### Critérios de aceite
- [ ] Jogo inicia sem erros de parse

---

## Bug 20: Quest kill 49/50 (GAMEPLAY)

**Status:** ⚠️ Fix parcial (adicionado check no signal). Bug 1 é continuação deste.

### Critérios de aceite
- [ ] Coberto pelo Bug 1

---

## Bug 21: Sprites/designs faltando em geral (VISUAL)

**Status:** ⚠️ Parcial. Auditoria mostrou 99.8% cobertura de PNGs, mas código nem sempre carrega.

### Critérios de aceite
- [ ] Nenhum mesh procedural visível onde deveria ter sprite
- [ ] Todas armas mostram sprite no HUD e in-game

---

## Ordem de implementação

| Prioridade | Bugs | Tipo |
|---|---|---|
| P0 | 1, 2 | Gameplay quebrado |
| P1 | 5, 8 | Gameplay/performance |
| P2 | 3, 4, 6, 7, 10 | Visual/balance |
| P3 | 9, 11, 12, 21 | Polish |
| Done | 13-20 | Já corrigidos |
