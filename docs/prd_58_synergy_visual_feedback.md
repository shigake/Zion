# PRD 58 — Feedback visual de sinergia in-world

**Status**: pendente
**Prioridade**: media
**Tipo**: polish visual / juice

---

## Problema

As sinergias ja tem icones no HUD (PRD 37), mas quando uma sinergia proca durante o gameplay, nao existe nenhum feedback visual no mundo 3D. O jogador nao percebe que o dano extra veio de uma sinergia. Falta o "wow factor" — a sensacao de poder quando elementos se combinam.

O sistema de sinergias rastreia procs e dano (`synergy_proc_counts`, `synergy_total_damage`), emite sinais (`synergy_procced`), mas nada acontece visualmente no mundo.

## Solucao

Tres camadas de feedback visual quando uma sinergia proca:

1. **Aura no personagem** — flash colorido do elemento da sinergia
2. **Texto flutuante** — nome da sinergia sobe do personagem
3. **Onda de impacto** — ring/shockwave no ponto de proc (onde o dano aconteceu)

## Especificacao tecnica

### 1. Aura no personagem (flash de sinergia)

**Quando**: toda vez que `SynergySystem.synergy_procced` emitir
**Visual**:
- Anel de luz ao redor do jogador (MeshInstance3D com torus ou ring shader)
- Cor baseada no elemento da sinergia:

| Sinergia | Cor primaria | Cor secundaria |
|---|---|---|
| fire_fire | `#FF4500` laranja | `#FFD700` amarelo |
| ice_ice | `#00BFFF` azul claro | `#FFFFFF` branco |
| electric_electric | `#FFD700` amarelo | `#FFFFFF` branco |
| dark_dark | `#8B00FF` roxo | `#1a0033` roxo escuro |
| water_water | `#0077BE` azul | `#00CED1` turquesa |
| poison_poison | `#32CD32` verde | `#90EE90` verde claro |
| light_light | `#FFFACD` creme | `#FFFFFF` branco |
| physical_physical | `#CD853F` bronze | `#FFD700` dourado |
| fire_ice (steam) | `#B0C4DE` cinza azulado | `#FF6347` vermelho |
| electric_ice | `#00FFFF` ciano | `#FFD700` amarelo |
| fire_poison | `#FF4500` laranja | `#32CD32` verde |
| ice_dark | `#8B00FF` roxo | `#00BFFF` azul |
| electric_poison | `#FFD700` amarelo | `#32CD32` verde |
| Cross-combos agua | `#0077BE` azul | cor do 2o elemento |

**Animacao**:
```
Scale: 0 → 1.2 → 1.0 (0.15s elastic)
Alpha: 0 → 0.6 → 0 (0.4s total)
```

**Pool**: 3 auras pre-instanciadas (sinergias rapidas podem sobrecarregar)

### 2. Texto flutuante de sinergia

**Quando**: no primeiro proc de cada sinergia por run E a cada 10o proc
**Visual**: texto 3D billboard com nome da sinergia

**Formato**:
```
⚡ Ressonancia Eletrica!
```

Cada sinergia tem um nome narrativo:

| ID | Nome exibido |
|---|---|
| fire_fire | Combustao Espontanea |
| ice_ice | Estilhacamento Glacial |
| electric_electric | Relampago em Cadeia |
| dark_dark | Veu da Escuridao |
| water_water | Onda Primordial |
| poison_poison | Praga Dimensional |
| light_light | Radiancia de Zion |
| physical_physical | Furia do Berserker |
| fire_ice | Nuvem de Vapor |
| electric_ice | Descarga Condutora |
| water_fire | Explosao de Vapor |
| water_electric | Eletrolise |
| water_ice | Zero Absoluto |
| water_dark | Profundezas Abissais |
| fire_poison | Chama Toxica |
| ice_dark | Congelamento Sombrio |
| electric_poison | Choque Toxico |

**Animacao**:
```
Posicao: sobe 1.5 unidades em 1.2s
Scale: 0.5 → 1.0 em 0.2s (bounce)
Alpha: 0 → 1 → 1 → 0 (fade in 0.1s, sustain 0.7s, fade out 0.4s)
Cor: gradiente entre cor primaria e secundaria da sinergia
```

**Implementacao**: reutilizar o sistema de damage numbers existente (`floating_text` ou similar), adicionando suporte a cores customizadas e tamanho maior.

### 3. Onda de impacto no ponto de proc

**Quando**: sinergias que causam dano em area (fire_fire explosion, ice_ice shatter, electric_electric chain, etc.)
**Visual**: ring/shockwave que expande do ponto de dano

**Implementacao**:
- `MeshInstance3D` com `TorusMesh` (raio interno 0.05, raio externo dinamico)
- Shader com gradiente da cor da sinergia → transparente
- OU particulas GPU em anel (`GPUParticles3D` com shape ring)

**Animacao**:
```
Radius: 0 → raio_da_sinergia em 0.3s (ease out)
Alpha: 0.5 → 0 em 0.3s
Height: 0.02 (praticamente no chao)
```

**Pool**: 4 ondas pre-instanciadas

### 4. Script `synergy_vfx_manager.gd`

**Local**: `scripts/effects/synergy_vfx_manager.gd`
**Registro**: autoload OU filho do player node

**Interface**:
```gdscript
func play_synergy_proc(synergy_name: String, proc_position: Vector3) -> void:
    var colors = SYNERGY_COLORS[synergy_name]

    # Aura no player (sempre)
    _play_aura(colors.primary, colors.secondary)

    # Texto flutuante (1o proc e a cada 10)
    var count = SynergySystem.synergy_proc_counts.get(synergy_name, 0)
    if count == 1 or count % 10 == 0:
        _play_floating_name(synergy_name, colors.primary)

    # Shockwave (so sinergias de area)
    if synergy_name in AOE_SYNERGIES:
        _play_shockwave(proc_position, colors.primary, _get_synergy_radius(synergy_name))
```

### 5. Conexao com SynergySystem

Em `synergy_system.gd`, o sinal `synergy_procced` ja existe. Modificar para incluir posicao:

```gdscript
signal synergy_procced(synergy_name: String, damage: int, position: Vector3)
```

Nos metodos de proc individuais, passar a posicao do inimigo/efeito:
```gdscript
synergy_procced.emit(synergy_name, damage, enemy.global_position)
```

### 6. Throttle de efeitos

Para evitar spam visual em builds com muitas sinergias:
- Cooldown minimo entre efeitos da MESMA sinergia: 0.5s
- Maximo de efeitos simultaneos totais: 6
- Se muitas sinergias procam ao mesmo tempo, priorizar as de maior dano

### 7. Opcao de intensidade

No menu de opcoes:
- "Efeitos de sinergia": Completo / Reduzido / Desligado
  - **Completo**: aura + texto + shockwave
  - **Reduzido**: so aura (sem texto e shockwave)
  - **Desligado**: nenhum efeito extra (mantem so o icone no HUD)

## Criterios de aceite

- [ ] Aura colorida aparece no jogador quando qualquer sinergia proca
- [ ] Cores corretas para todas as 17 sinergias
- [ ] Texto flutuante com nome narrativo no 1o proc e a cada 10o
- [ ] Onda de impacto para sinergias de area
- [ ] Throttle funciona — sem spam visual
- [ ] Pool de objetos (sem instanciacao runtime)
- [ ] Opcao de intensidade (completo/reduzido/desligado)
- [ ] Performance: <0.5ms por proc no profiler
- [ ] Localizado (pt_BR e en)

## Narrativa

Os efeitos visuais representam a "ressonancia cristalina" em acao. Quando dois estilhacos de Zion vibram na mesma frequencia (mesma elemento ou elementos complementares), a energia se manifesta como ondas visiveis de poder dimensional. Os nomes das sinergias sao termos que os Fragmentados usam para descrever esses fenomenos.

## Estimativa

~4-5 horas. Tres sistemas de efeito (aura, texto, shockwave) com pools e throttle.
