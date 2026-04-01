# PRD 22 — Lança: visual maior e mais visível durante o ataque

**Status:** pendente  
**Prioridade:** média  
**Área:** weapons / VFX  

---

## Problema

A animação da lança durante o ataque é quase imperceptível durante a jogabilidade. O sprite da arma é pequeno demais (`pixel_size = 0.015`) e o efeito de slash (`lance_thrust.png`) é discreto. O jogador frequentemente não consegue ver a lança "agindo" — a investida acontece mas não dá nenhuma satisfação visual, parecendo que o ataque nem aconteceu.

---

## Objetivo

Tornar o ataque da lança visualmente impactante e legível em tela. O jogador deve conseguir **ver claramente** a lança investindo em direção ao inimigo, com espessura e tamanho proporcionais às outras armas melee do jogo.

---

## Causa Raiz Técnica

Há três camadas visuais na lança — todas precisam de ajuste:

| Camada | Arquivo | Parâmetro atual | Problema |
|--------|---------|----------------|----------|
| Sprite da arma (Billboard) | `lance.gd` linha ~37 | `pixel_size = 0.015` | Sprite minúsculo na tela 3D |
| Slash trail (efeito de ataque) | `lance.gd` + `weapon_vfx.gd` | Tween scale `0.5 → 1.2` em 0.17s | Efeito pequeno e curto |
| Weapon trail (rastro) | `lance.gd` | `max_points = 8`, cor `(0.8, 0.7, 0.2, 0.6)` | Rastro pouco visível |
| ThrustMesh (BoxMesh) | `lance.gd` linha ~17 | `visible = false`, size `0.1×0.1×4.0` | Completamente invisível — poderia reforçar a leitura visual |

---

## Solução

### 1 — Aumentar o sprite da lança

Em `lance.gd`, aumentar o `pixel_size` do `Sprite3D` principal:

```gdscript
# Antes
sprite.pixel_size = 0.015

# Depois
sprite.pixel_size = 0.030   # 2× maior — equivalente ao tamanho dos outros sprites melee
```

Isso dobra o tamanho visual da lança em tela sem alterar hitbox nem balance.

---

### 2 — Efeito de slash maior e mais duradouro

Em `lance.gd` (ou `weapon_vfx.gd`, onde o slash trail é criado), aumentar a escala inicial e final do tween do `lance_thrust.png`:

```gdscript
# Antes
tween.tween_property(slash, "scale", Vector2(1.2, 1.2), 0.17).from(Vector2(0.5, 0.5))
tween.tween_property(slash, "modulate:a", 0.0, 0.17)

# Depois
tween.tween_property(slash, "scale", Vector2(2.0, 2.0), 0.22).from(Vector2(0.8, 0.8))
tween.tween_property(slash, "modulate:a", 0.0, 0.22)
```

Efeito começa maior (0.8 → 0.5) e termina mais largo (2.0 → 1.2), com duração um pouco mais longa (0.22s → 0.17s) para que o olho consiga registrar o ataque.

---

### 3 — Tornar o ThrustMesh visível como reforço visual

O `BoxMesh` existe mas está invisível. Ativá-lo com aparência de "brilho de investida" dá ao ataque uma presença física clara:

```gdscript
# Antes (lance.gd ~linha 17)
thrust_mesh.visible = false

# Depois
thrust_mesh.visible = true
# Ajustar o BoxMesh de 0.1×0.1×4.0 para 0.25×0.25×4.5 — mais grosso e um pouco mais longo
# Manter material emissivo existente (dourado) — já é visualmente correto
```

**Nota:** o `ThrustMesh` só é visível *durante* o ataque (o script já controla isso via `monitoring`), então não "flutua" na tela permanentemente.

---

### 4 — Reforçar o weapon trail

Em `lance.gd`, aumentar os pontos do trail e a opacidade:

```gdscript
# Antes
_trail.trail_color = Color(0.8, 0.7, 0.2, 0.6)
_trail.max_points = 8

# Depois
_trail.trail_color = Color(0.9, 0.8, 0.3, 0.85)   # Alpha mais alto
_trail.max_points = 14                              # Trail mais longo/denso
_trail.trail_width = 6.0                            # Se o parâmetro existir — mais grosso
```

---

## Arquivos a Modificar

| Arquivo | Mudança |
|---------|---------|
| `game/scripts/weapons/lance.gd` | `pixel_size`, `thrust_mesh.visible`, trail params |
| `game/scripts/weapons/lance.gd` ou `weapon_vfx.gd` | Tween scale do slash trail |
| *(Opcional)* `game/scenes/weapons/lance.tscn` | BoxMesh size se não for controlado via código |

**Não mexer:**
- `weapon_db.gd` — stats de damage, cooldown, area não mudam
- Qualquer outra arma melee — mudança é isolada na lança
- `game_constants.gd` — não adicionar constante específica para a lança (mudança é pontual)

---

## Critérios de Aceitação

- [ ] O sprite da lança é visivelmente maior em tela (ao menos 2× o tamanho atual)
- [ ] O efeito de investida (slash trail) é perceptível sem precisar procurar na tela
- [ ] O ThrustMesh aparece durante o ataque como brilho dourado de investida
- [ ] O weapon trail é mais denso e opaco, reforçando a direção do ataque
- [ ] A hitbox **não muda** — nenhum impacto em balance ou gameplay
- [ ] Funciona corretamente em todos os níveis da lança (scale por nível continua funcionando)
- [ ] Não quebra nenhuma outra arma melee

---

## Fora do Escopo

- Alterar o sprite `lance.png` (o arquivo de textura em si) — só o `pixel_size` e escala de display mudam
- Rebalancear dano, cooldown ou área da lança
- Afetar qualquer outra arma
