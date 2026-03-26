# Zion

Jogo estilo Vampire Survivors / The Spell Brigade, feito com Godot 4.

## Sobre

Zion e um survivors roguelite com tematicas variadas, 12 personagens jogaveis, 28 armas, 10 fases com bosses unicos e sistema de progressao entre runs. O objetivo e sobreviver a hordas de inimigos cada vez maiores enquanto evolui armas e coleta itens. Suporta co-op online ate 4 jogadores.

## Requisitos

- [Godot Engine 4.6+](https://godotengine.org/download) (versao com console para debug)
- Windows 10/11
- Git

## Como abrir o projeto

1. Clone o repositorio:
```bash
git clone <url-do-repo>
cd Zion
```

2. Abra no editor do Godot:
```bash
# Via linha de comando
godot --editor --path game

# Ou abra o Godot Editor e importe game/project.godot
```

3. Na primeira vez, o Godot vai importar todos os assets automaticamente.

## Como rodar o jogo

### Pelo Editor
- Abra o projeto no Godot Editor
- Pressione F5 ou clique no botao Play

### Pela linha de comando
```bash
# Rodar diretamente (Windows, com Godot instalado via WinGet)
godot --path game --run

# Ou com caminho completo
"/c/Users/shiga/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.1-stable_win64_console.exe" --path game --run
```

## Como compilar (build/export)

1. Abra o projeto no Godot Editor
2. Va em **Project > Export**
3. Adicione um preset (ex: Windows Desktop)
4. Configure o caminho de saida
5. Clique em **Export Project**

Para export via linha de comando:
```bash
# Export para Windows (precisa configurar export preset antes no editor)
godot --headless --path game --export-release "Windows Desktop" ../build/zion.exe
```

## Estrutura do Projeto

```
docs/                    # Documentacao de game design
game/                    # Projeto Godot 4
  project.godot          # Arquivo principal do projeto
  scenes/                # Cenas (.tscn)
    enemies/             # 11 inimigos genericos + 10 bosses
    stages/              # 10 fases com ambientes procedurais
    weapons/             # 28 cenas de armas
    ui/                  # HUD, menus, level up, shop, leaderboard
    player/              # Cena do jogador
  scripts/               # Scripts GDScript (.gd)
    autoload/            # Singletons globais
    player/              # Controlador do jogador
    enemies/             # Base de inimigos + spawner + bosses
    weapons/             # Logica das armas
    ui/                  # Logica das telas
    stages/              # Logica dos stages + props procedurais
    effects/             # Particulas, shaders, animacoes
  assets/                # Materiais, shaders, audio
```

## Conteudo Implementado

### 12 Personagens
Ronin, Soldado, Mago, Berserker, Ninja, Necro, Pirata, Engenheiro, Vampiro, Gladiador, Chef, ???

### 28 Armas
- **Melee**: Katana, Foice, Machado, Chicote, Lanca, Martelo, Nunchaku, Katana Dupla, Espada Cloud, Luvas de Boxe
- **Ranged**: Metralhadora, Staff, Bazuca, Shuriken, Pistola Dupla, Lanca-chamas, Cajado de Gelo, Besta, Canhao de Plasma, Arco Elfico
- **Summon**: Necromante, Drone, Totem, Garrafa de Veneno, Corrente Eletrica, Livro Magico, Bomba Relogio, Portal

### 10 Fases
| Fase | Ambiente | Boss |
|------|---------|------|
| Cemiterio | Neblina, lapides | Necromancer King |
| Floresta | Cogumelos magicos | Rainha das Fadas |
| Fazenda | Silos, milharal | Mega Vaca Alienigena |
| Toquio | Neon cyberpunk | AI Overlord |
| Vulcao | Lava, cavernas | Demon Lord |
| Oceano | Ruinas submarinas | Leviathan |
| Arena | Coliseu romano | Imperador Corrompido |
| Espaco | Estacao espacial | Singularidade |
| Castelo | Gotico, vampiros | Conde Dracula |
| Mundo Doce | Chocolate, sorvete | Rei Acucar |

### Sistemas
- 19 itens passivos com efeitos funcionais
- 12 evolucoes de armas (arma lv8 + item lv5)
- 7 reliquias pre-run
- 10 eventos especiais (Horda Dourada, Eclipse, Chuva de Meteoros, etc)
- 13 achievements
- Loja com 12 upgrades permanentes
- Leaderboard local (modo Endless)
- Multiplayer co-op ate 4 jogadores (ENet)
- Sistema de sinergias elementais (6 combinacoes)

## Controles

| Acao | Teclado | Gamepad |
|------|---------|---------|
| Mover | WASD | Left Stick |
| Dash | Space | A/X |
| Interagir | E | B/Circle |
| Pause | ESC | Start |

## Documentacao

- [Game Design Document](docs/gdd.md)
- [Personagens e Armas](docs/personagens.md)
- [Fases e Inimigos](docs/fases.md)
- [Itens e Evolucoes](docs/itens.md)
- [Progressao e Loja](docs/progressao.md)
- [Mecanicas de Gameplay](docs/mecanicas.md)

## Plataforma

- Steam (PC Windows)

## Status

Em desenvolvimento ativo. Todas as 10 fases e 12 personagens implementados.
