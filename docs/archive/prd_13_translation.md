# PRD 13 — Traducao incompleta e idioma nao persiste

## Status: CONCLUIDO

## Problema
1. Nem todos os textos estao traduzidos (ex: tela de opcoes inteira em portugues hardcoded)
2. Ao trocar idioma na tela principal, voltar ao menu mostra o idioma antigo

## Causa raiz

### Traducao incompleta
A tela de opcoes (`options_screen.gd`) usa texto hardcoded em portugues em TODAS as labels:
```gdscript
# Exemplos (linhas 255+):
"Modo de janela"
"Resolucao"
"V-Sync"
"Limite de FPS"
"Brilho"
"Predefinicao de qualidade"
"MSAA"
"Bloom / Glow"
# ... e muitas outras
```
NENHUMA dessas labels usa `LocaleManager.tr_key()`.

Outras telas (main menu, HUD, pause menu, shop) usam `tr_key()` corretamente.

### Idioma nao persiste entre cenas
O `LocaleManager.set_locale()` salva corretamente:
```gdscript
func set_locale(locale: String) -> void:
    current_locale = locale
    SaveManager.data["locale"] = locale
    SaveManager.save_game()
    locale_changed.emit(locale)
```

**Porem**, no pause menu, ao trocar idioma:
- `set_locale()` eh chamado
- A cena NAO eh recarregada
- Textos ja construidos ficam no idioma antigo
- So textos que usam `tr_key()` em tempo real (HUD) atualizam

No main menu, ao trocar idioma:
- `set_locale()` eh chamado
- `get_tree().change_scene_to_file()` recarrega — funciona

## Idiomas suportados
Portuguese, English, Spanish, French, German, Japanese, Chinese, Korean, Italian, Russian (10 idiomas).

## Arquivos envolvidos
| Arquivo | Funcao |
|---------|--------|
| `scripts/ui/options_screen.gd` | Labels hardcoded em portugues (~L255+) |
| `scripts/autoload/locale_manager.gd` | Sistema de traducao, ~150+ keys, `set_locale()` (~L411), `_ready()` (~L394) |
| `scripts/ui/pause_menu.gd` | Language selector sem reload de cena |
| `scripts/ui/main_menu.gd` | Language selector COM reload (funciona) |
| `scripts/autoload/save_manager.gd` | Persiste `locale` em `save_data.json` |

## Plano de implementacao

### Passo 1 — Auditar todos os textos hardcoded
Buscar por strings hardcoded em portugues em TODOS os scripts de UI:
```bash
grep -rn '"[A-Z][a-z].*"' scripts/ui/ --include="*.gd"
```

Lista conhecida de arquivos com texto hardcoded:
- `options_screen.gd` — TODAS as labels de opcao
- Possivelmente outros scripts de UI

### Passo 2 — Adicionar chaves ao LocaleManager
Para cada texto hardcoded encontrado, adicionar chave traduzida:

```gdscript
# Em locale_manager.gd, adicionar ao dicionario:
"options_window_mode": {"pt": "Modo de janela", "en": "Window mode", "es": "Modo de ventana", ...},
"options_resolution": {"pt": "Resolucao", "en": "Resolution", "es": "Resolucion", ...},
"options_vsync": {"pt": "V-Sync", "en": "V-Sync", "es": "V-Sync", ...},
"options_fps_limit": {"pt": "Limite de FPS", "en": "FPS limit", "es": "Limite de FPS", ...},
"options_brightness": {"pt": "Brilho", "en": "Brightness", "es": "Brillo", ...},
"options_quality": {"pt": "Predefinicao de qualidade", "en": "Quality preset", "es": "Calidad", ...},
"options_msaa": {"pt": "MSAA", "en": "MSAA", "es": "MSAA", ...},
"options_bloom": {"pt": "Bloom / Glow", "en": "Bloom / Glow", "es": "Bloom / Glow", ...},
# ... todas as labels da tela de opcoes
# ... e qualquer outro texto hardcoded encontrado na auditoria
```

### Passo 3 — Substituir hardcoded por tr_key() na options_screen
```gdscript
# Antes:
label.text = "Modo de janela"

# Depois:
label.text = LocaleManager.tr_key("options_window_mode")
```

### Passo 4 — Implementar reload de UI ao trocar idioma
Conectar ao sinal `locale_changed` em todas as telas que constroem UI estatica:

```gdscript
func _ready():
    LocaleManager.locale_changed.connect(_on_locale_changed)

func _on_locale_changed(_locale: String) -> void:
    _rebuild_ui()  # Reconstroi toda a UI com novos textos
```

OU, mais simples: recarregar a cena apos trocar idioma (como o main menu ja faz).

### Passo 5 — Corrigir pause menu
No pause menu, apos trocar idioma, rebuild a UI:
```gdscript
# Apos set_locale():
_rebuild_pause_menu()  # Reconstroi labels com novas traducoes
```

### Passo 6 — Verificar persistencia
1. Trocar idioma para ingles
2. Fechar o jogo
3. Reabrir → verificar que abre em ingles
4. Ir em opcoes → verificar que labels estao em ingles

## Validacao
- [ ] Tela de opcoes totalmente traduzida em todos os 10 idiomas
- [ ] Nenhum texto hardcoded em portugues em nenhuma tela
- [ ] Trocar idioma atualiza TODAS as telas imediatamente
- [ ] Idioma persiste ao fechar e reabrir o jogo
- [ ] Trocar idioma no pause menu atualiza o menu
- [ ] Trocar idioma no main menu funciona (ja funciona)
