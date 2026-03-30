# PRD — UI Polish, Bugfixes e Cena de Créditos

> Melhorias de interface nos menus, correções de crashes no GameManager e adição de animações procedurais na tela de conclusão.

---

## Tarefa 1: Cena de Créditos (Animação e Escala)

**Objetivo:** Feature: Escala e Animação Idle/Dança na Tela de Créditos.

### Descrição
Na cena de créditos, temos os heróis (Fragmentados) reunidos em volta de uma fogueira. Atualmente eles estão estáticos e pequenos. As seguintes alterações devem ser feitas:
- Dobre a escala global de todos os nós `Sprite3D` dos heróis na cena (ex: `scale = Vector3(2, 2, 2)`).
- Implemente um script de animação procedural simples anexado a esses nós ou gerenciado por um nó pai. Eles devem ter um leve movimento randômico de 'idle' (ex: um leve bobbing vertical usando `sin(Time.get_ticks_msec())` e offsets randômicos para não ficarem iguais).
- Adicione uma lógica específica para que pelo menos **um herói aleatório** execute uma animação de 'dança' no final (um Tween de rotação e pulo repetitivo). Mantenha o código modular para podermos adicionar isso facilmente à árvore da cena.

### Critérios de aceite
- [ ] Escala dos Sprite3D de heróis dobrada sem borrar a pixel-art (usar a flag Nearest caso afete o texture-filter).
- [ ] Animação procedural de 'bobbing' vertical rodando em sin() estabilizada com offset randômico por boneco.
- [ ] Um herói sorteado randomicamente é alvejado por um Tween instanciando a dança.

---

## Tarefa 2: Bugfix do GameManager (Crash de Cura)

**Objetivo:** Bugfix: Implementação da função `heal_player` no GameManager para barrar erro de Crash.

### Descrição
Durante o gameplay da run, o jogo apresentou um crash fatal ao tentar processar itens de cura do jogador com a devolução: `Invalid call. Nonexistent function 'heal_player' in base 'Node (game_manager.gd)'`. Precisamos da implementação correta da função `heal_player(amount: int)` no script Autoload `game_manager.gd`.

A função deve obrigatoriamente:
- Checar se a referência instanciada do nó do jogador (`player`) é válida e não está na fila de deleção do garbage collector (`is_instance_valid(player)` e `not player.is_queued_for_deletion()`).
- Adicionar o valor `amount` ao HP atual do jogador matematicamente, clampando-o pelo HP Máximo nativo do status base atual.
- Emitir o sinal correspondente ao sistema de interface (ex: `player_hp_changed` ou chamada direta de `HUD.update_hp()`) para que a UI nativa da barra de HP reaja instantaneamente.

### Critérios de aceite
- [ ] Função `heal_player(amount: int)` formalmente adicionada ao Autoload global.
- [ ] Trancas de verificação de nulidade e integridade do nó aplicadas antes do cálculo para contornar mortes perigosas no frame da coleta.
- [ ] HP clampado em sua margem máxima superior.
- [ ] Sinal de evento da árvore emitido corretamente e interface alterada.

---

## Tarefa 3: Ajuste de UI do Menu Principal (Sobreposição)

**Objetivo:** UI Polish: Correção de Layout Crítico no Menu Principal (Logo vs Subtítulo).

### Descrição
No Menu Principal, o texto de subtítulo motivacional *"Survive the horde. Ascend beyond."* está sendo renderizado literalmente corrompido em cima do Logo Pixel Art nativo **'ZION'**.

- Verifique a hierarquia bruta dos nós `Control` do Title Screen.
- Utilize contêineres autônomos e limpos `VBoxContainer`, para empilhar o Logo superior e o Subtítulo inferior verticalmente.
- Adicione as constantes de separação adequadas (`Theme Overrides > Constants > Separation`) para dar o respiro visual entre a marca e o subtítulo. O texto deve possuir a flag Size de alinhamento que o mantenha rigorosamente centralizado, e o VBox deve manter o design responsivo em caso de redimensionamento da janela do jogador.

### Critérios de aceite
- [ ] Texto inferior e Logo descolados da sobreposição agressiva.
- [ ] Uso rígido do contêiner empilhado (VBoxContainer) e constantes de Separação.
- [ ] Elementos flexíveis e responsivos na Root do Canvas.

---

## Tarefa 4: Ajuste de UI do Bestiário

**Objetivo:** UI Polish: Centralização absoluta e padronização de Texto nos Botões de Coleção do Bestiário.

### Descrição
Na arquitetura do Menu do Bestiário, os botões base que emitem os nomes dos 90 monstros e as frases de lore/conquista estão correndo livres e desalinhados visualmente.
- Ajuste a Cena empacotada instanciável original do Botão do Bestiário e force que o conteúdo escrito ganhe formatação centralizada no bloco.
- Usando um nó de `Button` nativo, basta repassar a propriedade de `alignment = HORIZONTAL_ALIGNMENT_CENTER`. 
- Caso o construtor adote um Node atrelado de fonte (como `Label`), a sua âncora `horizontal_alignment` e `vertical_alignment` devem forçar repouso sobre a centralidade do bloco contíguo `CENTER`. O nó em si tem de adotar flags `Fill/Expand` para ocupar o corpo completo da área do Botão-Pai.

### Critérios de aceite
- [ ] Elementos descritivos e textuais centralizados com rigor no container.
- [ ] Hierarquia das flags de alinhamento expandem adequadamente nos nós-filhos do botão instanciado.

---

## Tarefa 5: Ajuste de UI do Codex de Armas

**Objetivo:** UI Polish: Centralização textual padronizada dos Botões de Itemização do Codex de Armas e Proteção Textual.

### Descrição
Na mesma esteira de correção de UX do Bestiário, a meta aqui é alinhar rigorosamente as abas do Codex de Armas (32 itens coletáveis).
- Os botões instanciados na lista da grid rolando as 32 opções de arsenal devem herdar a formatação tipográfica e o alinhamento estrito "Centralizado".
- Refatore o Node que exibe a tipografia no Root do Codex mantendo a base do alinhamento atrelada no centro.
- **Implementação Crucial:** O tamanho longo do nome de armas evolutivas e complexas exige proteção da UI. Ative o `Text Clipping` ou as flags dinâmicas de `Autowrap` para assegurar que uma arma extensa não quebre/vaze para fora dos contornos predefinidos do seu container nativo de HUD.

### Critérios de aceite
- [ ] Grid textual das armas formatada para o centro, harmonizando com o menu colecionável.
- [ ] Proteção de limite ativa (Autowrap ou Clip Text) evadindo estouro das margens de exibição visual.
- [ ] Padronização estética total entre Codex de Armas e Bestiário nas formatações da Base.
