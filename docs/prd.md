# Zion — PRD v3.26 (Estado Real do Projeto)

> *"Zion nao e onde voce chega. E o que voce constroi no caminho."*

## Status: BETA — ~94% completo, jogavel de ponta a ponta

---

## O QUE FUNCIONA (Implementado)

### Core
- 15 personagens jogaveis (amazona, bruxa, ronin, soldado, mago, berserker, ninja, necro, pirata, engenheiro, vampiro, gladiador, chef, mystery, fragmentado)
- 32 armas (31 ativas, flamethrower desabilitado)
- 19 itens passivos (18 ativos, gasoline desabilitado)
- 12 evolucoes de arma (arma lv8 + item lv5)
- 7 reliquias pre-run
- 10 fases com mecanicas unicas (lava, correntes, zero-G, caramelo, etc.)
- 10 bosses com 3 fases, telegraph, fury mode (<10% HP), dialogos
- 90 monstros tematicos (9 por stage, sprites unicos)
- 10 enemy behaviors unicos (teleport, charge, stealth, split, etc.)
- 9 sinergias elementais (6 base + 3 avancadas)
- 10 eventos especiais + Eclipse Total
- 13 achievements com popup dourado + tela dedicada
- 6 mutacoes/ascensao com bonus de cristais
- Modos: Normal (15 min), Endless, Boss Rush, Hyper, New Game+, Daily Challenge
- Loja com 12 upgrades permanentes
- Tutorial interativo (5 passos)
- Inventario TAB (armas, itens, sinergias, evolucoes)
- World map stage select (estilo Super Mario World)
- Boss dialogos (intro + morte + taunts durante luta)
- Story: intro typewriter + stage lore + victory lore + final ending
- Leaderboard online (server Express + SQLite)
- Desafio Diario com seed fixo

### Visual (Pixel Art Billboard)
- 428+ sprites pixel art gerados proceduralmente
- Billboard Sprite3D com NEAREST filter
- Themed HP bar unico por personagem (MANA pro mago, SANGUE pro vampiro, etc.)
- HUD: armas (esquerda) separadas de itens (direita)
- Death animation: flash + scale up + shrink + fade
- Hit: squash-stretch elastico com flash vermelho
- Screen flash branco no level up
- Vignette vermelha pulsante no low HP
- Boss: aura pulsante + name label + entrance (shake + slowmo + flash)
- Slash trails em todas 10 armas melee
- Props animados em todos 10 stages (lanternas piscam, cogumelos pulsam, etc.)
- Loading screen com tips aleatorios + sprite + stage lore
- Poeira ao andar do player
- Level up: cards coloridos por tipo, hover, bounce animation
- Logo ZION pixel art + particulas douradas no menu
- Damage numbers grandes (48pt normal, 64pt crit)

### Audio
- 16 musicas (12 Suno AI chiptune + victory, shop, lobby, game_over)
- 51 SFX conectados (sword_slash, gun_shot, explosion, boss_roar, etc.)
- AudioManager com crossfade, pool, cooldown, loop automatico

### Multiplayer
- Co-op 2-4 jogadores via ENet
- Host-client, scaling de dificuldade, projeteis falsos
- Level up sincrono + modo assincrono (opcao no menu)
- Host migration + reconnect (3 tentativas)
- Lobby state sync com sprites + ready system
- Revive com sacrificio (tombstone 60s)

### Sistemas
- Save local JSON, balanceamento matematico verificado
- Object pooling, MultiMesh (hordas + pickups)
- Spatial grid O(1), sprite cache, FPS-aware throttling
- Auto-play mode, CI/CD (GitHub Actions Windows + Linux)
- Export presets Windows + Linux
- Testes automatizados (9 suites: smoke, combo, weapons, evolution, events, stress, achievements, balance, menu_smoke)

---

## O QUE FALTA (Sprints Priorizados)

### SPRINT 1 — Fixes Rapidos ✅ CONCLUIDO
- [x] Decidir: flamethrower e gasoline mantidos desabilitados
- [x] Adicionar SFX novas armas ao _valid_sfx
- [x] Garantir victory.wav toca ao matar boss
- [x] Testar export Windows (CI/CD funcional)

### SPRINT 2 — Visual Polish ✅ CONCLUIDO
- [x] Walk animations: bob + flip + squash-stretch
- [x] Boss entrance dramatica: letterbox + zoom + shake + slow-mo
- [x] Efeitos visuais nas 4 armas novas
- [x] Boss phase music intensification
- [x] Creditos: sprites 2x, idle bobbing, heroi dancando
- [x] Menu principal: spacing corrigido

### SPRINT 3 — QA Completo (pendente execucao)
- [x] Suite `combo` implementada (150 combinacoes = 15 chars × 10 stages)
- [x] Suite `stress` implementada (hyper, max enemies, endless)
- [x] Suite `evolution` implementada (12 evolucoes)
- [x] Suite `events` implementada (timeline completa)
- [ ] Rodar suite `combo` e verificar 150/150 sem crash
- [ ] Rodar stress test e verificar FPS > 30 sustentado
- [ ] Teste multiplayer LAN manual (2-4 jogadores)
- [ ] Fix de bugs encontrados

### SPRINT 4 — Build & Deploy (infra pronta, falta execucao)
- [x] Export preset Windows + Linux configurados
- [x] CI/CD `build.yml` completo (validate → build → package → release)
- [ ] Testar .exe em maquina limpa
- [ ] Pagina Itch.io com screenshots e descricao
- [ ] Trailer de 30s (captura de gameplay)
- [ ] Disparar GitHub Release v1.0.0

### FUTURO (Pos-lancamento)
- [x] Steam Integration base (codigo pronto, falta plugin GodotSteam)
- [ ] Instalar GodotSteam GDExtension
- [ ] Matchmaking online
- [ ] Workshop de mods
- [ ] DLC tematicos
- [ ] Localizacao EN/ES/JP
- [ ] Mac export
- [ ] Replays

### REFATORACAO ✅ CONCLUIDA
- [x] GameConstants: 561 linhas, 29 categorias, zero magic numbers
- [x] Synergy timers unificados (10 vars → 1 dict)
- [x] UICardBuilder compartilhado (bestiary, codex)
- [x] WeaponVFX compartilhado (6 armas melee) + slash trail pool
- [x] GameManager splitado: SpatialEnemyGrid + ItemBonusCalculator
- [x] EnemyStageBehavior data-driven (30 behaviors em dict)
- [x] Cache sprites inimigos + O(1) weapon level lookup
- [x] Projectile bugfix (escala, rotacao, sprites duplicados)
- [x] Musica dinamica completa (stage→boss→victory + intensificacao)
- [x] UI polish: R1/L1 navigation, card alignment, text overflow
- [x] Annulus spawning centralizado
- [x] HUD split (HUDMultiplayer extraido)
- [x] Magic numbers fase 2 (event_manager, tombstone, 100+ extraidos)
- [x] Weapon audit (5 icones SVG + shadow_claw slash)
- [x] Bruxa visual update (dark skin)

---

## NUMEROS

| Metrica | Valor |
|---------|-------|
| Scripts | 216 .gd |
| Cenas | 103 .tscn |
| Sprites | 428+ PNG |
| SFX | 51 WAV |
| Musicas | 16 MP3/WAV |
| Personagens | 15 |
| Armas | 32 (31 ativas) |
| Fases | 10 |
| Bosses | 10 |
| Monstros tematicos | 90 |
| Docs | 12 |
| PRDs ativos | 3 (qa, build, steam) |
| Tamanho | ~71 MB |
| FPS medio | ~238 |
| Suites de teste | 9 |
