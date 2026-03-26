# PRD — UI/UX Fixes & Melhorias

## 1. Opcoes: Scroll e Layout
- [x] Adicionar ScrollContainer na tela de opcoes para nao quebrar com muitos itens
- [x] Garantir que todos os controles cabem na tela em 1280x720

## 2. Localizacao Completa (PT-BR + EN)
- [x] Revisar TODOS os textos do jogo para ter traducao em PT-BR e EN
- [x] Menu principal: Play, Shop, Options, Quit, Leaderboard
- [x] Selecao de personagem: nomes, passivas, unlock descriptions
- [x] Selecao de fase: nomes e descricoes
- [x] Selecao de reliquia: nomes e descricoes
- [x] HUD: labels (Kills, Cristais, Dash, Level Up)
- [x] Level Up screen: titulos, opcoes
- [x] Game Over screen: stats labels
- [x] Loja: nomes dos upgrades, descricoes
- [x] Opcoes: labels dos sliders, checkboxes, keybindings
- [x] Achievements: nomes e descricoes
- [x] Eventos: nomes dos eventos
- [x] Modos de jogo: Normal, Endless, Boss Rush, Hyper

## 3. Navegacao com ESC
- [x] Em TODAS as telas fora do jogo, ESC volta para tela anterior

## 4. Botao Selecionado com Cor Diferente
- [x] Na selecao de personagem: botao selecionado com highlight azul
- [x] Na selecao de fase: botao selecionado com highlight azul
- [x] Na selecao de reliquia: botao selecionado com highlight azul

## 5. Loja: Barra de Rolagem Visual
- [x] ScrollContainer ja existia na loja

## 6. Controle de Gamepad Completo
- [x] D-Pad / Left Stick: navega entre botoes
- [x] A/X: confirma selecao
- [x] B/Circle: volta (equivalente a ESC)
- [x] Indicador visual (seta amarela) no botao focado
- [x] Suporta qualquer tipo de controle (Xbox, PS, Switch, generico)

## 7. Sistema de Mira com Analogico Direito
- [x] Analogico direito ativa mira manual
- [x] Armas ranged atiram na direcao do analogico (14 armas)
- [x] Armas melee atacam na direcao do analogico (7 armas)
- [x] Neutro = auto-attack (comportamento padrao)
- [x] manual_aim e aim_direction em GameManager
