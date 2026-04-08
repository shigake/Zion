# PRD 60 — Efeitos de morte elementais dos inimigos

**Status**: pendente
**Prioridade**: media
**Tipo**: polish visual / juice

---

## Problema

O ragdoll de morte dos inimigos (PRD 45) ja esta implementado, mas todos morrem da mesma forma independente do tipo de dano que os matou. Matar com fogo, gelo, veneno ou eletricidade deveria ter visuais distintos — isso e uma das maiores fontes de "game feel" em survivors/roguelites.

## Solucao

7 efeitos de morte distintos baseados no elemento da arma que deu o golpe final, mais o ragdoll base como fallback.

## Especificacao tecnica

### 1. Tipos de morte elemental

| Elemento | Efeito | Descricao visual |
|---|---|---|
| **fire** | Incineracao | Inimigo pega fogo, encolhe, vira cinzas que se dissipam |
| **ice** | Congelamento + Quebra | Congela azul, racha, explode em fragmentos de gelo |
| **electric** | Eletrocucao | Flicker rapido branco/azul, esqueleto flash, desintegra em faiscas |
| **poison** | Dissolucao acida | Derrete de cima pra baixo, poca verde no chao |
| **dark** | Absorcao sombria | Sugado para dentro de si (implode), particulas roxas |
| **water** | Evaporacao | Fica translucido, evapora em bolhas que sobem |
| **physical/light** | Ragdoll padrao | Tomble + fade (comportamento atual, mantido) |

### 2. Script `elemental_death_vfx.gd`

**Local**: `scripts/effects/elemental_death_vfx.gd`
**Tipo**: singleton (autoload) ou instanciado pelo ObjectPool

**Interface**:
```gdscript
func play_death(enemy_node: Node3D, element: String, damage: int) -> void
```

### 3. Efeito: Incineracao (fire)

**Duracao**: 1.2s

**Sequencia**:
1. (0.0s) Spawn `GPUParticles3D` de chamas no corpo (cor: laranja→vermelho)
2. (0.0-0.5s) Tween escala Y do inimigo: 1.0 → 0.7 (encolhendo)
3. (0.0-0.8s) Tween cor do material: normal → `Color(0.2, 0.1, 0.05)` (carbonizado)
4. (0.5-1.0s) Tween escala total: 0.7 → 0.1
5. (0.8-1.2s) Spawn particulas de cinza (cinza escuro, gravidade leve pra cima, drift lateral)
6. (1.2s) Remove enemy node

**Assets**: reutilizar particulas de fogo existentes (`ParticleFactory`), adicionar preset "ash"

### 4. Efeito: Congelamento + Quebra (ice)

**Duracao**: 0.8s

**Sequencia**:
1. (0.0s) Tween cor do material: normal → `Color(0.6, 0.8, 1.0)` (azul gelado) em 0.15s
2. (0.0s) Spawn cristais de gelo na superficie (3-5 meshes pequenos, IcosahedronMesh)
3. (0.15-0.3s) Freeze: inimigo parado, leve tremor (shake posicao ±0.02)
4. (0.3s) CRACK: spawn 8-12 fragmentos rigidos (shard meshes) com velocidade radial
   - Cada fragmento: mesh triangular, cor azul gelado, rotacao aleatoria
   - Fisica: velocidade 3-6, gravidade, lifetime 1.5s
   - Particulas de gelo fino (poeira branca)
5. (0.3s) Esconder enemy mesh original
6. (1.5s) Fragments fade out e despawn

**Assets**: gerar shards proceduralmente (BoxMesh achatado + rotacao random)

### 5. Efeito: Eletrocucao (electric)

**Duracao**: 0.6s

**Sequencia**:
1. (0.0-0.3s) Flicker rapido: visivel/invisivel a cada 0.03s (10 flickers)
   - A cada flicker ON: cor alterna entre branco e amarelo eletrico
   - Spawn 2-3 arcos eletricos (lines entre pontos random no corpo)
2. (0.15s) Flash de "esqueleto": material todo branco por 0.05s (x-ray flash)
3. (0.3-0.5s) Tween escala: 1.0 → 0.3 com jitter (posicao random ±0.1)
4. (0.5-0.6s) Burst de faiscas (particulas amarelas, velocidade alta, bounce)
5. (0.6s) Remove

**Assets**: reutilizar particulas de faísca do totem

### 6. Efeito: Dissolucao acida (poison)

**Duracao**: 1.0s

**Sequencia**:
1. (0.0-0.5s) Tween cor: normal → `Color(0.2, 0.8, 0.1)` (verde toxico)
2. (0.0-1.0s) "Derretimento": tween posicao Y do mesh: 0 → -0.3 (afundando)
   - Simultaneo: tween escala Y: 1.0 → 0.3 (achatando)
   - Tween escala XZ: 1.0 → 1.3 (espalhando, como se derretesse)
3. (0.3s) Spawn poca verde no chao (decal ou mesh plano com shader animado)
   - Poca expande de 0 → 0.8 radius em 0.3s
   - Formato irregular (noise na borda, reutilizar logica da poca de veneno PRD 48)
   - Fade out em 2s (fica um pouco mais que o inimigo)
4. (0.5-1.0s) Gotinhas verdes subindo (particulas, bolhas toxicas)
5. (1.0s) Remove enemy

### 7. Efeito: Absorcao sombria (dark)

**Duracao**: 0.7s

**Sequencia**:
1. (0.0-0.3s) Tween cor: normal → `Color(0.1, 0.0, 0.15)` (roxo escuro)
2. (0.0-0.5s) Tween escala uniforme: 1.0 → 0.05 (implosao)
   - Ease: cubic in (acelera no final — efeito de "sugado")
3. (0.0-0.5s) Spawn particulas convergentes: particulas roxas que se movem EM DIRECAO ao centro do inimigo (emission_direction: inward)
4. (0.5s) Flash roxo brilhante no ponto central (point light, 0.1s)
5. (0.5-0.7s) Spawn 6 wisps roxos que flutuam pra cima e somem
6. (0.7s) Remove

### 8. Efeito: Evaporacao (water)

**Duracao**: 0.8s

**Sequencia**:
1. (0.0-0.4s) Tween alpha do material: 1.0 → 0.2 (ficando translucido)
   - Cor shift: normal → azul agua `Color(0.5, 0.7, 1.0)`
2. (0.2-0.6s) Spawn bolhas subindo (particulas: esferas pequenas, velocidade Y positiva, leve random XZ)
3. (0.4-0.8s) "Vapor": particulas de nevoa branca subindo (maiores que bolhas, mais lentas)
4. (0.6-0.8s) Tween escala Y: 1.0 → 0 (encolhe de baixo pra cima)
5. (0.8s) Remove

### 9. Selecao do elemento de morte

Modificar o sistema de dano do inimigo para rastrear o ultimo elemento que causou dano:

```gdscript
# Em enemy_base.gd ou equivalente
var _last_damage_element: String = "physical"

func take_damage(amount: int, source: Node = null, element: String = "physical"):
    _last_damage_element = element
    # ... logica existente ...
    if hp <= 0:
        _die()

func _die():
    ElementalDeathVFX.play_death(self, _last_damage_element, _last_damage_amount)
```

As armas precisam passar o elemento ao causar dano. Verificar `WeaponDB` para mapear weapon_id → element.

### 10. Pool e performance

- Cada tipo de efeito tem pool proprio (4 instancias cada)
- Total: 7 tipos × 4 = 28 efeitos pre-instanciados
- Particulas usam `GPUParticles3D` com `one_shot = true`
- Shards de gelo: pool de 48 (12 por efeito × 4 pool)
- Se todos os slots estao ocupados: fallback para ragdoll padrao

### 11. Opcao de qualidade

Menu de opcoes:
- "Efeitos de morte": Completo / Simples / Desligado
  - **Completo**: todos os efeitos elementais com particulas
  - **Simples**: so a mudanca de cor + fade (sem particulas extras)
  - **Desligado**: morte instantanea (sem efeito, maximo performance)

## Criterios de aceite

- [ ] 7 efeitos de morte distintos por elemento
- [ ] Elemento correto detectado baseado na arma que matou
- [ ] Cada efeito dura <1.5s
- [ ] Pool de efeitos funciona sem instanciacao runtime
- [ ] Fallback para ragdoll quando pool esta cheio
- [ ] Opcao de qualidade (completo/simples/desligado)
- [ ] Performance: <1ms por morte no profiler (mesmo com 5+ mortes simultaneas)
- [ ] Visual distinto e satisfatorio para cada elemento
- [ ] Funciona com todos os tipos de inimigo (genericos, tematicos, mini-bosses)
- [ ] Bosses usam versao ampliada do efeito (2x escala, duracao 1.5x)

## Narrativa

A morte dos inimigos corrompidos reflete a natureza do fragmento de Zion que os purificou. Fogo purifica pela chama dimensional, gelo cristaliza e devolve ao vazio, eletricidade desintegra a corrupcao, veneno dissolve a forma corrompida, trevas reabsorvem a essencia, agua lava a corrupcao. Cada morte e uma pequena restauracao de Zion.

## Estimativa

~8-10 horas. 7 efeitos distintos com particulas, shaders, pools, e integracao com o sistema de dano existente.
