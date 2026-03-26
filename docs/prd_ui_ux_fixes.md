# PRD — UI/UX Fixes & Melhorias

## 1. Opcoes: Scroll e Layout
- [ ] Adicionar ScrollContainer na tela de opcoes para nao quebrar com muitos itens
- [ ] Garantir que todos os controles cabem na tela em 1280x720

## 2. Localizacao Completa (PT-BR + EN)
- [ ] Revisar TODOS os textos do jogo para ter traducao em PT-BR e EN
- [ ] Menu principal: Play, Shop, Options, Quit, Leaderboard
- [ ] Selecao de personagem: nomes, passivas, unlock descriptions
- [ ] Selecao de fase: nomes e descricoes
- [ ] Selecao de reliquia: nomes e descricoes
- [ ] HUD: labels (Kills, Cristais, Dash, Level Up)
- [ ] Level Up screen: titulos, opcoes
- [ ] Game Over screen: stats labels
- [ ] Loja: nomes dos upgrades, descricoes
- [ ] Opcoes: labels dos sliders, checkboxes, keybindings
- [ ] Achievements: nomes e descricoes
- [ ] Eventos: nomes dos eventos
- [ ] Modos de jogo: Normal, Endless, Boss Rush, Hyper

## 3. Navegacao com ESC
- [ ] Em TODAS as telas fora do jogo (menu, selecao, loja, opcoes, leaderboard):
  - Pressionar ESC volta para a tela anterior
  - Menu principal: ESC nao faz nada (ou confirma sair)
  - Selecao de personagem: ESC → Menu principal
  - Selecao de fase: ESC → Selecao de personagem
  - Selecao de reliquia: ESC → Selecao de fase
  - Loja: ESC → Menu principal
  - Opcoes: ESC → Menu principal
  - Leaderboard: ESC → Menu principal
  - Lobby multiplayer: ESC → Menu principal

## 4. Botao Selecionado com Cor Diferente
- [ ] Na selecao de personagem: botao do personagem selecionado fica com cor de destaque
- [ ] Na selecao de fase: botao da fase selecionada fica com cor de destaque
- [ ] Na selecao de reliquia: botao da reliquia selecionada fica com cor de destaque
- [ ] Cor de destaque: usar ACCENT_BLUE do UITheme ou similar

## 5. Loja: Barra de Rolagem Visual
- [ ] Adicionar ScrollContainer na loja
- [ ] Garantir que barra de rolagem e visivel e estilizada

## 6. Controle de Gamepad Completo
- [ ] Adaptar TODAS as telas de menu para navegacao com gamepad
  - D-Pad / Left Stick: navega entre botoes
  - A/X: confirma selecao
  - B/Circle: volta (equivalente a ESC)
  - Shoulders: troca de pagina (onde aplicavel)
- [ ] Suportar qualquer tipo de controle (Xbox, PS, Switch, generico)
- [ ] InputMap: adicionar acoes para UI navigation se nao existirem
- [ ] Focus: garantir que botoes tem focus_neighbor configurado

## 7. Sistema de Mira com Analogico Direito
- [ ] Quando jogador move o analogico direito do controle:
  - Desliga auto-attack
  - Armas ranged atiram na direcao do analogico direito
  - Armas melee atacam na direcao do analogico direito
- [ ] Quando analogico direito esta neutro (sem input):
  - Reativa auto-attack (comportamento padrao atual)
- [ ] Funciona para TODOS os personagens e armas
- [ ] Variavel em GameManager: `manual_aim: bool = false`
- [ ] Variavel: `aim_direction: Vector3 = Vector3.ZERO`
- [ ] Atualizar player.gd para ler right stick
- [ ] Atualizar armas ranged (machinegun, staff, etc) para usar aim_direction quando manual_aim
