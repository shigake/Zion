# PRD — Sinergia de Equipe (Cross-Combo)

> **Status: Pendente**
> Permite que jogadores em co-op combinem elementos de armas diferentes para criar sinergias cruzadas entre aliados.

## Objetivo

Expandir o sistema de sinergias elementais existente para funcionar **entre jogadores** no modo multiplayer. Quando o projetil de um jogador atinge a area de efeito criada por um aliado, uma sinergia cruzada e disparada com efeitos visuais e dano bonus.

Isso incentiva comunicacao e posicionamento estrategico entre jogadores.

## Contexto

O sistema de sinergias elementais ja existe e funciona para um unico jogador:
- Fogo + Fogo = explosao ao matar
- Gelo + Gelo = estilhacos ao congelar
- Eletrico + Eletrico = chain lightning mais longo
- Dark + Dark = area de trevas passiva
- Fogo + Gelo = steam cloud
- Eletrico + Gelo = condutor massivo

Ver `scripts/autoload/synergy_system.gd` para a implementacao atual.

## Arquitetura

```
Jogador A (Arma Fogo) → cria AoE com "estado elementar" no Area3D
Jogador B (Arma Gelo) → projetil entra na area de Jogador A
                              ↓
                    Host detecta colisao cruzada
                              ↓
                    Dispara Cross-Combo (Steam Cloud)
                    Dano = media(dano_A, dano_B) * multiplicador
                              ↓
                    Efeito visual GPUParticles3D + feedback UI
```

## Tarefas

### 1. Modificar Areas de Efeito (AoE)
- [ ] Atualizar armas que criam areas persistentes (Garrafa de Veneno, Corrente Eletrica, etc.)
- [ ] Cada Area3D deve registrar um "estado elementar" como metadata: `element_type`, `owner_peer_id`, `damage_base`
- [ ] Armas afetadas: todas que criam `Area3D` persistente com elemento (Fogo, Gelo, Eletrico, Dark)
- [ ] O estado deve ter um TTL (time-to-live) compativel com a duracao da AoE

### 2. Logica de Detecao no Host
- [ ] Atualizar `multiplayer_manager.gd` ou `synergy_system.gd` para detectar colisao cruzada
- [ ] Condicao: projetil de Jogador X com elemento E1 entra em Area3D de Jogador Y (Y != X) com elemento E2
- [ ] Lookup na tabela de sinergias existente para verificar se E1 + E2 tem combo definido
- [ ] Toda logica roda no Host (server authority) para evitar dessincronia
- [ ] RPC para clientes: `@rpc("authority") func _trigger_cross_combo(pos, combo_type, damage)`

### 3. Efeitos Visuais
- [ ] Criar efeitos de particula (`GPUParticles3D`) para cada combinacao cruzada:
  - Fogo + Gelo = nuvem de vapor (steam cloud) — particulas brancas/cinza com glow
  - Eletrico + Veneno = veneno eletrificado — raios verdes + sparks
  - Fogo + Dark = chamas sombrias — particulas roxas com fogo
  - Gelo + Eletrico = condutor massivo — cristais azuis + arcos eletricos
- [ ] Usar `ParticleFactory` existente como base para os novos efeitos
- [ ] Flash de tela sutil (`ScreenEffects`) quando cross-combo ativa
- [ ] Label flutuante "CROSS-COMBO!" com nome da sinergia

### 4. Balanceamento
- [ ] Dano do cross-combo: `(dano_jogador_A + dano_jogador_B) / 2 * CROSS_COMBO_MULTIPLIER`
- [ ] `CROSS_COMBO_MULTIPLIER` inicial: 1.5x (ajustavel via balanceamento)
- [ ] Cooldown por par de jogadores: 2 segundos (evitar spam)
- [ ] O dano escala com os stats dos DOIS jogadores, incentivando builds complementares
- [ ] Cristais bonus por cross-combos na tela de resultado

## Arquivos Afetados

- `scripts/autoload/synergy_system.gd` — adicionar logica de cross-combo
- `scripts/autoload/multiplayer_manager.gd` — RPCs de cross-combo
- `scripts/weapons/*.gd` — armas com AoE registram estado elementar
- `scripts/effects/particle_factory.gd` — novos efeitos de particula
- `scripts/effects/screen_effects.gd` — flash de cross-combo

## Metricas de Sucesso

- Cross-combos acontecem naturalmente em partidas multiplayer sem tutorial
- Jogadores buscam builds complementares (diversidade de elementos no time)
- Dano nao e broken — cross-combo e bonus, nao substitui builds individuais
