# PRD 23 — Pause menu: visual aprimorado

## Status: pendente

## Problema

O menu de pause atual é um `PanelContainer` genérico centralizado (300×280 px), com fundo cinza padrão do Godot, título "Pause" em texto simples e quatro botões sem estilo. Não combina em nada com a identidade visual do jogo — fundo escuro profundo, dourado cristalino, partículas e brilhos mágicos — e soa descontextualizado no meio de uma run.

---

## Solução

Redesenhar o menu de pause **inteiramente por código** em `pause_menu.gd`, sem criar assets externos. O layout permanece funcional (mesmos botões, mesmas conexões), apenas a camada visual muda.

A identidade a seguir é a mesma do `main_menu.gd`:
- Fundo escuro (`#080810`, `Color(0.03, 0.03, 0.06)`)
- Dourado como cor de destaque (`Color(0.9, 0.8, 0.3)`)
- Azul cristal como cor secundária (`Color(0.45, 0.85, 0.95)`)
- Bordas finas, cantos arredondados, glow sutil nos botões
- Sem texto genérico — usar terminologia narrativa de Zion

---

## Especificação visual

### Overlay de fundo

Substituir o `ColorRect` preto opaco (50%) por um overlay com **gradiente radial simulado**:
- Criar dois `ColorRect` sobrepostos:
  1. Fundo sólido: `Color(0.0, 0.0, 0.0, 0.72)` — escurece o jogo atrás
  2. Vinheta central suave: `Color(0.05, 0.04, 0.10, 0.55)` com tamanho menor e centralizado, para dar profundidade de "janela aberta"

### Painel central (substituir `PanelContainer` nu)

- Largura: **320 px** | Altura: **auto** (mínimo 280 px)
- Fundo: `StyleBoxFlat` com:
  - `bg_color = Color(0.05, 0.04, 0.10, 0.97)`
  - `border_width_all = 1`
  - `border_color = Color(0.9, 0.8, 0.3, 0.45)` (dourado translúcido)
  - `corner_radius_all = 8`
  - `shadow_color = Color(0.9, 0.75, 0.2, 0.18)`, `shadow_size = 12`

### Linha decorativa dourada

Logo abaixo do título, adicionar um `ColorRect` fino:
- Largura: 200 px, Altura: 2 px
- Cor: `Color(0.9, 0.8, 0.3, 0.6)`
- Centralizado horizontalmente com `MarginContainer` + `CENTER`

### Título

Trocar o texto "Pause" por **"⏸ Zion em pausa"** (PT) / **"⏸ Zion paused"** (EN) via `LocaleManager.tr_key`.
- `font_size = 26`
- Cor: `Color(0.9, 0.8, 0.3)` (dourado)
- `horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER`
- Letra-caixa sentencial (sem maiúsculas forçadas)

> Adicionar as chaves `pause_title_pt = "Zion em pausa"` e `pause_title_en = "Zion paused"` em `LocaleManager` (ou usar a chave já existente `"pause"` se houver).

### Botões

Aplicar `StyleBoxFlat` em cada botão via `add_theme_stylebox_override` para os estados `normal`, `hover` e `pressed`:

| Estado   | BG                            | Borda                              |
|----------|-------------------------------|-------------------------------------|
| normal   | `Color(0.10, 0.09, 0.14)`    | `Color(0.28, 0.26, 0.35, 0.7)`    |
| hover    | `Color(0.16, 0.14, 0.22)`    | `Color(0.9, 0.8, 0.3, 0.75)`      |
| pressed  | `Color(0.20, 0.18, 0.28)`    | `Color(0.95, 0.85, 0.35, 0.9)`    |

- `corner_radius_all = 5`
- `border_width_all = 1`
- `font_color` normal: `Color(0.82, 0.82, 0.88)`
- `font_color` hover: `Color(1.0, 0.95, 0.7)`
- `font_size = 18`
- `custom_minimum_size = Vector2(0, 44)` (botões mais altos que os atuais 40 px)

**Botão "Continuar"** recebe destaque especial (igual ao "Play" no main menu):
- BG normal: `Color(0.14, 0.12, 0.08)`
- Borda normal: `Color(0.85, 0.72, 0.22, 0.7)`
- BG hover: `Color(0.20, 0.17, 0.10)`
- Borda hover: `Color(0.95, 0.82, 0.30, 0.95)` + glow suave
- Texto hover: `Color(1.0, 0.92, 0.55)`

**Botão "Sair do Jogo"** recebe tom avermelado discreto:
- BG normal: `Color(0.08, 0.07, 0.08)`
- Borda normal: `Color(0.30, 0.22, 0.22, 0.6)`
- BG hover: `Color(0.14, 0.09, 0.09)`
- Borda hover: `Color(0.85, 0.45, 0.40, 0.8)`
- Texto hover: `Color(0.95, 0.60, 0.55)`

### Separador

Trocar `HSeparator` genérico por um `ColorRect` fino (`1 px`) colorido:
- Cor: `Color(0.9, 0.8, 0.3, 0.25)` (dourado bem translúcido)

### Glow pulsante no título (opcional, leve)

Adicionar um `ColorRect` atrás do título com:
- `Color(0.9, 0.75, 0.2, 0.0)` (começa invisível)
- Em `_process`, pulsar o alpha entre `0.0` e `0.06` com `sin(time * 1.5)`
- `corner_radius_all = 4`, mesmo largura do painel

### Efeito de entrada (animação)

Ao abrir o pause (`_pause()`), animar o painel com `Tween`:
```gdscript
panel.modulate.a = 0.0
panel.position.y += 18
var tw = create_tween()
tw.set_parallel(true)
tw.tween_property(panel, "modulate:a", 1.0, 0.18)
tw.tween_property(panel, "position:y", panel.position.y - 18, 0.18).set_ease(Tween.EASE_OUT)
```

---

## Painel de stats (lado direito)

O `stats_panel` já tem cores adequadas. Ajustes menores para harmonizar:
- Aplicar o mesmo `StyleBoxFlat` do painel central (fundo `Color(0.05, 0.04, 0.10, 0.95)`, borda dourada fina)
- Adicionar `shadow_color = Color(0.9, 0.75, 0.2, 0.12)`, `shadow_size = 10`
- Entrada com Tween simétrica (slide da direita, 0.20 s)

---

## Arquivos afetados

| Arquivo | Mudança |
|---|---|
| `game/scripts/ui/pause_menu.gd` | Refatorar `_ready()`, `_pause()`, `_show_stats()` com os novos estilos |
| `game/scenes/ui/pause_menu.tscn` | Nenhuma mudança — layout base permanece |
| `game/scripts/autoload/locale_manager.gd` | Adicionar chave `pause_title` se ainda não existir |

---

## O que NÃO muda

- Lógica de pause/resume — sem alteração
- Painel de opções (`_on_options`) — sem alteração
- Painel de stats (conteúdo) — só estilo do container
- Loading antes da jogatina — sem alteração
- Funcionamento de keybindings — sem alteração

---

## Critérios de aceitação

- [ ] Menu de pause visualmente alinhado com o estilo dark + dourado do main menu
- [ ] Botão "Continuar" se destaca visivelmente dos demais
- [ ] Botão "Sair do Jogo" tem tom avermelado discreto
- [ ] Animação de entrada suave (fade + slide, ≤ 0.2 s)
- [ ] Painel de stats usa mesmo estilo visual do painel de ações
- [ ] Tudo cabe em 1280×720 sem scroll
- [ ] Gamepad e teclado continuam funcionando normalmente
