# Zion — PRD v3.3 (Estado Real do Projeto)

> *"Zion nao e onde voce chega. E o que voce constroi no caminho."*

## Status: BETA — ~85% completo, jogavel de ponta a ponta

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
- 333+ sprites pixel art gerados proceduralmente
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
- 43 SFX conectados (sword_slash, gun_shot, explosion, boss_roar, etc.)
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
- Auto-play mode, CI/CD (GitHub Actions manual)
- Export preset Windows

---

## O QUE FALTA (Sprints Priorizados)

### SPRINT 1 — Fixes Rapidos (1 dia)
- [x] Decidir: flamethrower e gasoline mantidos desabilitados (sem mira manual)
- [x] Adicionar 4 SFX novas armas ao _valid_sfx (boomerang, tornado, chain_whip, blood_orb)
- [x] Garantir victory.wav toca ao matar boss (game_over_screen.gd)
- [ ] Testar export Windows localmente

### SPRINT 2 — Visual Polish (3-5 dias)
- [x] Walk animations: bob + flip + squash-stretch para personagens e inimigos
- [x] Boss entrance dramatica: letterbox + zoom + escalating shake + spawn particles + slow-mo
- [x] Efeito visual nas 4 armas novas (boomerang phase burst, tornado debris+shake, chain flash+shake, orb heal pulse)
- [x] Boss phase music: intensificar trilha ao mudar de fase
- [x] Creditos: sprites 2x, idle bobbing, heroi dancando
- [x] Menu principal: spacing logo/subtitulo corrigido

### SPRINT 3 — QA Completo (3-5 dias)
- [ ] Teste manual: cada personagem em cada stage (15 x 10 = 150 combinacoes)
- [ ] Teste multiplayer LAN (2 jogadores minimo)
- [ ] Stress test: 15 min com 300+ inimigos, target 60 FPS
- [ ] Verificar todas 12 evolucoes funcionam
- [ ] Verificar todos 10 eventos funcionam
- [ ] Fix de bugs encontrados

### SPRINT 4 — Build & Deploy (2-3 dias)
- [ ] Export Windows funcional (.exe testado em maquina limpa)
- [x] Linux export preset (export_presets.cfg + build.yml)
- [ ] Pagina Itch.io com screenshots e descricao
- [ ] Trailer de 30s (captura de gameplay)
- [ ] GitHub Release v1.0.0

### FUTURO (Pos-lancamento)
- [x] Steam Integration base (achievements sync, cloud save, lobby, networking — codigo pronto, falta plugin GodotSteam)
- [ ] Steam Networking Sockets (codigo pronto, falta GodotSteam binarios)
- [ ] Matchmaking online
- [ ] Workshop de mods
- [ ] DLC tematicos
- [ ] Localizacao EN/ES/JP
- [ ] Mac/Linux nativo
- [ ] Replays

### REFATORACAO (Concluida)
- [x] GameConstants: stage lists, FPS, resolutions centralizados
- [x] Synergy timers unificados (10 vars → 1 dict)
- [x] UICardBuilder compartilhado (bestiary, codex)
- [x] WeaponVFX compartilhado (6 armas melee) + slash trail pool
- [x] GameManager splitado: SpatialEnemyGrid + ItemBonusCalculator
- [x] EnemyStageBehavior data-driven (30 behaviors em dict)
- [x] Cache sprites inimigos + O(1) weapon level lookup
- [x] Projectile bugfix (escala, rotacao, sprites duplicados)
- [x] Ice+Dark crash fix
- [x] Musica dinamica completa (stage→boss→victory + intensificacao temporal)
- [x] Options R1/L1 tab navigation
- [x] Bestiary/Codex card alignment + text overflow

---

## NUMEROS

| Metrica | Valor |
|---------|-------|
| Scripts | ~160 .gd |
| Cenas | ~100 .tscn |
| Sprites | 333+ PNG |
| SFX | 43 WAV |
| Musicas | 16 MP3/WAV |
| Personagens | 15 |
| Armas | 32 (31 ativas) |
| Fases | 10 |
| Bosses | 10 |
| Monstros tematicos | 90 |
| Tamanho | ~71 MB |
| Erros/run | ~28 (cosmeticos) |
| FPS medio | ~238 |
