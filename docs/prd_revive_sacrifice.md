# PRD — Reviver com Sacrificio

> **Status: Pendente**
> Sistema de ressurreicao multiplayer onde aliados podem reviver jogadores caidos permanecendo perto da lapide por 5 segundos, com penalidade de debuff.

## Objetivo

Substituir o comportamento atual de morte no multiplayer (personagem some e dificuldade ajusta) por um sistema mais engajante: o jogador morto deixa uma lapide interativa que aliados podem usar para revive-lo, ao custo de um debuff temporario.

## Contexto

- Atualmente, quando um jogador morre no multiplayer, o personagem desaparece e o scaling de dificuldade ajusta automaticamente
- Existe um upgrade permanente de "Revive" na loja (renascer 1x por run)
- O sistema de atributos dinamicos ja suporta buffs/debuffs temporarios

## Fluxo

```
Jogador A morre
      ↓
Modelo substituido por Lapide/Fantasma (Node3D + Area3D)
      ↓
Timer de despawn: 60 segundos (lapide some apos isso = morte permanente)
      ↓
Aliado entra no Area3D → progress bar aparece (5 segundos)
      ↓
Se aliado permanece 5s contínuos → Revive!
      ↓
Jogador A renasce com 50% HP
Aliado recebe debuff temporario (30 segundos)
      ↓
Se aliado sai do area antes de 5s → progress reseta
```

## Tarefas

### 1. Estado de Morte
- [ ] Alterar logica de morte no multiplayer em `scripts/player/player_controller.gd`
- [ ] Em vez de `queue_free()`, instanciar modelo de Lapide na posicao de morte
- [ ] Modelo: lapide de pedra com particulas de alma flutuando (usar `ModelFactory` ou cena dedicada)
- [ ] Alternativa visual: fantasma semi-transparente do personagem (shader de transparencia + emissao)
- [ ] Camera do jogador morto segue a lapide ou fica em modo espectador (segue aliado mais proximo)
- [ ] HUD do jogador morto mostra: timer de despawn, mensagem "Esperando aliados..."

### 2. Area de Interacao
- [ ] Adicionar `Area3D` com `CollisionShape3D` (esfera, raio ~2.5 unidades) ao redor da lapide
- [ ] Detectar entrada/saida de jogadores aliados vivos via `body_entered` / `body_exited`
- [ ] Collision layer: Players (layer 1)
- [ ] Indicador visual: circulo no chao ao redor da lapide (decal ou mesh plano com shader pulsante)
- [ ] Icone de interacao flutuante visivel para aliados proximos

### 3. Timer de Ressurreicao
- [ ] Timer no servidor (Host): 5 segundos de presenca continua dentro da area
- [ ] Se um ou mais aliados estao no area, o timer conta; se todos saem, reseta
- [ ] Progress bar visual sincronizada via RPC para todos os clientes
- [ ] Ao completar:
  - `@rpc("authority") func _revive_player(peer_id, pos)`
  - Jogador renasce na posicao da lapide com 50% HP
  - 2 segundos de invulnerabilidade pos-revive
  - Efeito visual de ressurreicao (particulas, flash de luz)
  - Lapide destruida

### 4. Aplicacao de Debuff
- [ ] Debuff no aliado que realizou o sacrificio (quem estava no area ao completar):
  - **Opcao A**: -30% HP maximo por 30 segundos
  - **Opcao B**: -25% velocidade de movimento por 30 segundos
  - **Opcao C**: ambos com valores menores (-15% HP, -15% speed) por 20 segundos
- [ ] Usar sistema de atributos dinamicos existente para aplicar o debuff
- [ ] Indicador visual no HUD do jogador debuffado (icone + timer)
- [ ] Se multiplos aliados estao no area, o debuff e dividido entre eles (mais leve)
- [ ] Particulas visuais no jogador debuffado (aura sombria temporaria)

### 5. Interacao com Sistemas Existentes

- [ ] Upgrade "Revive" da loja: se o jogador tem revive, ele renasce automaticamente (sem lapide). Lapide so aparece se nao tem revive ou ja usou
- [ ] Scaling de dificuldade: manter jogador morto no count enquanto lapide existir (so remove se lapide expira)
- [ ] Achievement potencial: "Reviver 10 aliados em uma run"

## Arquivos Afetados

- `scripts/player/player_controller.gd` — logica de morte alterada
- `scripts/autoload/multiplayer_manager.gd` — RPCs de revive, estado de morte
- `scripts/effects/model_factory.gd` ou novo `scenes/player/tombstone.tscn` — modelo da lapide
- `scripts/effects/particle_factory.gd` — efeitos de ressurreicao
- `scripts/ui/hud.gd` — indicadores de revive e debuff

## Balanceamento

| Parametro | Valor Inicial | Notas |
|---|---|---|
| Timer de revive | 5 segundos | Presenca continua |
| Timer de despawn da lapide | 60 segundos | Morte permanente apos |
| HP ao reviver | 50% | Sem itens/armas perdidos |
| Invulnerabilidade pos-revive | 2 segundos | Evitar morte instantanea |
| Debuff do sacrificador | -30% HP max, 30s | Ajustavel |
| Raio da area de interacao | 2.5 unidades | ~5 metros no jogo |
