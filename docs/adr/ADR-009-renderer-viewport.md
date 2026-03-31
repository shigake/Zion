# ADR-009 — Renderer Forward Plus, MSAA 2x, viewport 1280x720

**Status:** Aceito
**Data:** 2024-01

---

## Contexto

Zion é um jogo 3D com muitos inimigos simultâneos, efeitos de partículas, luzes dinâmicas por fenda e cel-shading. Precisávamos escolher renderer, resolução alvo e configurações de qualidade que equilibrassem visual e performance em hardware mid-range.

## Decisão

- **Renderer:** Forward Plus
- **Anti-aliasing:** MSAA 2x (3D)
- **Viewport base:** 1280×720
- **Stretch mode:** `canvas_items` com aspect `expand` — a UI é desenhada em 720p e escalada para a resolução da janela
- **Cor de fundo padrão:** `Color(0.05, 0.06, 0.04)` — quase preto esverdeado, coerente com o tom de "dimensão corrompida"

## Justificativa

### Forward Plus vs Mobile vs Compatibility

| Renderer | Prós | Contras |
|----------|------|---------|
| **Forward Plus** ✅ | Suporte a muitas luzes dinâmicas; MSAA nativo; shaders modernos (compute) | Maior requisito de GPU |
| Mobile | Performance em hardware fraco | Sem luzes dinâmicas em cluster; shaders limitados |
| Compatibility | Roda em hardware antigo; OpenGL | Sem MSAA; sem shaders avançados |

O Zion usa iluminação dinâmica por fenda (cada fenda tem paleta de luz própria) e cel-shading via shader material — Forward Plus é o único renderer que suporta tudo isso nativamente.

### Por que 1280×720?

- Resolução mínima Steam recomendada para jogos indie
- Garante que toda a UI cabe em tela sem scroll (regra de UI do projeto)
- Com `stretch: expand`, o jogo escala limpo para 1080p, 1440p e 4K
- MSAA 2x em 720p tem custo muito menor que em 1080p, com qualidade visual adequada

### Camadas de física (5 layers)

```
Layer 1 — Players
Layer 2 — Enemies
Layer 3 — Pickups
Layer 4 — PlayerAttacks
Layer 5 — EnemyAttacks
```

Separar `PlayerAttacks` de `EnemyAttacks` permite configurar colisões precisas na máscara de cada hitbox, evitando que projéteis do jogador acertem o jogador ou que inimigos se acertem.

## Consequências

- **Regra de UI**: toda tela deve caber em 1280×720 sem scroll. ScrollContainer só é aceito dentro de tabs individuais
- Hardware mínimo recomendado: GPU com suporte a Vulkan (Forward Plus usa Vulkan no Godot 4)
- Para máquinas mais fracas: futuro preset "baixo" pode trocar para Compatibility renderer (tradeoff documentado)
- MSAA 2x é configurável via options — o `SaveManager` persiste a preferência
