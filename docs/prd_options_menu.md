# PRD - Menu de Opcoes Completo

## Objetivo

Criar um menu de opcoes completo e profissional com todas as configuracoes possiveis, organizado em abas.

## Layout

Menu com **7 abas** navegaveis por tabs no topo:

```
[Video] [Graficos] [Audio] [Gameplay] [Controles] [Acessibilidade] [Idioma]
```

Cada aba eh um ScrollContainer com opcoes organizadas em secoes.

---

## Aba 1: VIDEO

### Modo de Tela
- **Modo janela**: Janela / Tela cheia / Sem bordas (OptionButton, 3 opcoes)
- **Resolucao**: Dropdown com resolucoes detectadas do monitor (OptionButton, dinamico)
- **V-Sync**: Liga/Desliga (CheckButton)
- **Limite de FPS**: 30 / 60 / 120 / 144 / 240 / Ilimitado (OptionButton)
- **Brilho/Gamma**: Slider 0.5 a 2.0 (HSlider, default 1.0)

---

## Aba 2: GRAFICOS

### Preset Rapido
- **Qualidade**: Baixa / Media / Alta / Ultra / Personalizado (OptionButton)
  - Muda todos os graficos abaixo de uma vez

### Anti-Aliasing
- **MSAA**: Desligado / 2x / 4x / 8x (OptionButton)
- **FXAA**: Liga/Desliga (CheckButton)

### Iluminacao e Sombras
- **Qualidade de sombras**: Desligado / Baixa / Media / Alta (OptionButton)
- **Distancia de sombras**: Slider 10-100 (HSlider)
- **Sombras suaves**: Liga/Desliga (CheckButton)

### Pos-Processamento
- **Bloom/Glow**: Liga/Desliga (CheckButton)
- **Intensidade do Bloom**: Slider 0.0-2.0 (HSlider)
- **SSAO**: Desligado / Baixo / Medio / Alto (OptionButton)
- **SSR (Reflexos)**: Liga/Desliga (CheckButton)
- **Tone Mapping**: Linear / Reinhardt / Filmic / ACES / AGX (OptionButton)

### Efeitos Visuais
- **Particulas**: Baixo / Medio / Alto (OptionButton) — multiplica quantidade de particulas
- **Screen Shake**: Desligado / Leve / Normal / Forte (OptionButton)
- **Hit Freeze**: Liga/Desliga (CheckButton)
- **Cel Shader**: Liga/Desliga (CheckButton)
- **Outline**: Liga/Desliga (CheckButton)
- **Distancia de renderizacao**: Slider 20-200 (HSlider)

---

## Aba 3: AUDIO

### Volumes
- **Volume Master**: Slider 0-100% (HSlider)
- **Volume Musica**: Slider 0-100% (HSlider)
- **Volume Efeitos (SFX)**: Slider 0-100% (HSlider)
- **Volume UI**: Slider 0-100% (HSlider)

### Audio Avancado
- **Audio 3D/Espacial**: Liga/Desliga (CheckButton)

---

## Aba 4: GAMEPLAY

### HUD
- **Numeros de dano**: Liga/Desliga (CheckButton)
- **Barra de HP inimigos**: Liga/Desliga (CheckButton)
- **Mini mapa**: Liga/Desliga (CheckButton)
- **FPS Counter**: Liga/Desliga (CheckButton)
- **Timer visivel**: Liga/Desliga (CheckButton)
- **Kill counter**: Liga/Desliga (CheckButton)
- **Indicador de direcao do boss**: Liga/Desliga (CheckButton)

### Jogo
- **Auto-coleta de XP**: Liga/Desliga (CheckButton)
- **Velocidade de texto**: Lento / Normal / Rapido / Instantaneo (OptionButton)
- **Confirmacao ao sair**: Liga/Desliga (CheckButton)
- **Pausa ao perder foco**: Liga/Desliga (CheckButton)

### Telemetria
- **Enviar dados anonimos**: Liga/Desliga (CheckButton)

---

## Aba 5: CONTROLES

### Teclado
- Lista de acoes remapeaveis (11 acoes existentes)
- Botao "Redefinir padrao"

### Gamepad
- **Sensibilidade do analogico**: Slider 0.1-2.0 (HSlider)
- **Dead zone**: Slider 0.05-0.5 (HSlider)
- **Vibracao**: Liga/Desliga (CheckButton)
- **Layout**: Xbox / PlayStation / Personalizado (OptionButton)

### Mouse
- **Sensibilidade de mira**: Slider 0.1-3.0 (HSlider)

---

## Aba 6: ACESSIBILIDADE

### Visual
- **Modo daltonico**: Desligado / Protanopia / Deuteranopia / Tritanopia (OptionButton)
- **Tamanho da fonte UI**: 80% / 100% / 120% / 150% (OptionButton)
- **Escala da UI**: 80% / 100% / 120% / 150% (OptionButton)
- **Alto contraste**: Liga/Desliga (CheckButton)
- **Flash reduzido**: Liga/Desliga (CheckButton)

### Movimento
- **Movimento reduzido**: Liga/Desliga (CheckButton) — desativa screen shake, particulas reduzidas
- **Slow motion permanente**: Liga/Desliga (CheckButton)

---

## Aba 7: IDIOMA

- **Idioma**: Portugues (BR) / English (OptionButton)
- Preview do idioma selecionado

---

## Implementacao Tecnica

### Salvamento
- Todas as opcoes salvas em SaveManager.data com prefixo por categoria
- Ex: `gfx_msaa`, `gfx_bloom`, `audio_master`, `gameplay_damage_numbers`, etc.
- Aplicar imediatamente ao mudar (sem botao "Aplicar")
- Restaurar na inicializacao via `_restore_settings()`

### Aplicacao em Tempo Real
- Video: DisplayServer API
- Graficos: RenderingServer + Environment + ProjectSettings
- Audio: AudioServer bus volumes
- Gameplay: Flags em GameManager
- Acessibilidade: UITheme + ScreenEffects

### Botoes Globais (rodape de todas as abas)
- **Restaurar padrao** — reseta a aba atual
- **Voltar** — volta ao menu anterior

### Navegacao
- Tabs navegaveis com teclado (Tab/Shift+Tab)
- Gamepad: LB/RB para trocar aba
- Scroll dentro de cada aba
