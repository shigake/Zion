# PRD — Melhorias Futuras & Proximos Passos

## Prioridade Alta

### Audio Assets
- [ ] Criar/adquirir 12 musicas (menu, 10 stages, boss) em .ogg
- [ ] Criar/adquirir 10 SFX (hit, kill, collect_xp, collect_crystal, level_up, evolve, boss_appear, dash, player_hurt, menu_click) em .wav
- [ ] Colocar em game/assets/audio/music/ e game/assets/audio/sfx/
- [ ] O AudioManager ja carrega automaticamente - zero codigo necessario

### Steam Integration
- [ ] Instalar GodotSteam GDExtension (https://godotsteam.com)
- [ ] Obter Steam App ID (teste ou producao)
- [ ] Descomentar codigo em multiplayer_manager.gd (_create_server_peer, _create_client_peer)
- [ ] Implementar Steam Lobby (create, list, join por convite)
- [ ] Implementar Steam Achievements (13 achievements ja trackeados)
- [ ] Implementar Steam Cloud Save
- [ ] Implementar Steam Rich Presence
- [ ] Criar Steam Store page (capsulas, screenshots, trailer)

---

## Prioridade Media

### Performance
- [ ] MultiMeshInstance3D para renderizar hordas de 1000+ inimigos
- [ ] Profiling com Godot debugger para identificar bottlenecks
- [ ] LOD (Level of Detail) para props distantes
- [ ] Frustum culling manual para particulas

### Multiplayer Polish
- [ ] Ally HP bars mostrando HP real de cada jogador (precisa sync per-player)
- [ ] Setas direcionais indicando aliados fora da tela
- [ ] Display de ping/latencia no HUD
- [ ] Host migration (complexo, mas importante para UX)
- [ ] Reconnect apos desconexao

### Modos de Jogo Adicionais
- [ ] Daily Challenge (seed fixa por dia, leaderboard online)
- [ ] Boss Rush (todos os 10 bosses em sequencia)
- [ ] Hyper Mode (2x velocidade, 2x spawns, 2x rewards)
- [ ] New Game+ (comeca com armas do run anterior)

### Inimigos Especificos por Stage
- [ ] Criar scripts dedicados para inimigos tematicos (fadas, robos, aliens)
- [ ] Comportamentos unicos por tipo (fada voa e teleporta, robo atira laser)
- [ ] Atualmente os inimigos sao reskins visuais dos genericos

---

## Prioridade Baixa

### Workshop & Mods
- [ ] Steam Workshop integration
- [ ] Sistema de mods (custom stages, weapons, characters via JSON/GDScript)
- [ ] Editor de stage in-game (drag & drop props)

### Social
- [ ] Ranking online (leaderboard global via Steam)
- [ ] Replays (gravacao de inputs para assistir depois)
- [ ] Spectator mode

### Conteudo DLC
- [ ] DLC packs tematicos (novos stages + personagens)
- [ ] Modo Inverse (jogue como o boss contra hordas de heróis)
- [ ] Crossover events (personagens de outros jogos)

### Plataformas
- [ ] Linux build (Godot suporta nativamente)
- [ ] Mac build
- [ ] Controle de Switch Pro / PS5 DualSense (haptics)

### QA & Testing
- [ ] Testes automatizados de balanceamento (simulated runs)
- [ ] Testes de networking (latencia, desync, packet loss)
- [ ] Testes de performance em hardware variado
- [ ] CI/CD pipeline para builds automaticos

---

## Ajustes de Design Pendentes

### Sinergias
- [ ] Adicionar elemento "water" a armas relevantes (Cajado de Gelo -> Water/Ice)
- [ ] Implementar sinergia Water + Electric (condutor) como alternativa a Ice + Electric

### Balanceamento
- [ ] Teste extensivo de todas as 28 armas em runs completas
- [ ] Ajustar DPS curves para stages 4-10 (atualmente usam curva do cemetery)
- [ ] Balancear bosses dos stages novos (HP, damage, fase timing)
- [ ] Verificar que evolucoes novas nao quebram o power curve

### UX
- [ ] Tela de stats detalhada pos-run (DPS por arma, dano por tipo, etc)
- [ ] Bestiary (catalogo de inimigos encontrados)
- [ ] Weapon codex (catalogo de armas com descricoes e evolucoes)
- [ ] Mini-mapa mostrando direcao de eventos/bosses
