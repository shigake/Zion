# PRD 42 — Dialogos dos bosses in-game (intro, fases, libertacao)

**Status**: concluido
**Tipo**: narrativa
**Prioridade**: media
**Versao alvo**: 3.54.0

---

## Problema

O sistema BossDialogue ja existe e mostra textos nos momentos certos (spawn, phase change, death). Porem o conteudo e generico e nao explora a narrativa rica de cada Sentinela. Atualmente:

1. **Textos curtos demais** — uma frase generica por momento
2. **Sem personalidade** — todos os bosses falam igual
3. **Sem arco narrativo** — nao ha progressao na historia do Sentinela durante a fight
4. **Sem frases durante combate** — boss fica mudo entre fases
5. **Sem agradecimento na libertacao** — a morte do boss (que e uma libertacao) nao e emocional
6. **Sem variacao** — mesma frase toda vez, sem replay value

## Objetivo

Escrever dialogos completos para os 10 Sentinelas que contem uma mini-historia durante o boss fight: intro ameacadora, frases de combate que revelam a pessoa por tras da corrupcao, transicao dramatica na fase 3, e uma libertacao emocional na derrota. Com variacao para replay.

## Escopo

### Incluso
- Dialogo de intro expandido (2-3 frases) para os 10 Sentinelas
- 3-5 frases de combate por boss (durante a fight, entre ataques)
- Dialogo de transicao fase 2 e fase 3 (revelacao do Sentinela)
- Dialogo de libertacao na derrota (emocional, agradecimento)
- Variacao: 2-3 opcoes por slot (aleatorio a cada run)
- Resposta do Fragmentado (opcional, texto breve)
- Bilingue: PT-BR e EN
- Integracao com sistema de ducking (PRD 38)

### Fora de escopo
- Voice acting
- Novos efeitos visuais para dialogos (usar BossDialogue existente)
- Dialogos para alt bosses (apenas os 10 Sentinelas principais)

## Especificacao tecnica

### 1. Estrutura de dialogos por boss

Cada Sentinela tem:

| Momento | Quantidade | Trigger | Duracao |
|---------|-----------|---------|---------|
| Intro | 2-3 frases (1 escolhida aleatoriamente) | `boss_spawned` | 4s |
| Combate fase 1 | 3 frases (1 a cada 20-30s) | Timer periodico | 3s |
| Transicao fase 2 | 1 frase | `boss_phase_changed(2)` | 4s |
| Combate fase 2 | 3 frases (mais reveladoras) | Timer periodico | 3s |
| Transicao fase 3 | 1-2 frases (revelacao) | `boss_phase_changed(3)` | 5s |
| Combate fase 3 | 2 frases (desesperadas) | Timer periodico | 3s |
| Libertacao (morte) | 2-3 frases (1 escolhida) | `boss_died` | 6s |

### 2. Dialogos dos 10 Sentinelas

#### Necromancer (Cemiterio) — Guardiao das Memorias

**Intro (aleatorio):**
1. "Voces perturbam o descanso dos que ja partiram... Eu protejo suas memorias."
2. "Fragmentados? Sinto os estilhacos em voces... Como doem as memorias."
3. "Nao se aproximem! As memorias que guardo... elas mordem."

**Combate fase 1:**
1. "Cada morto que invoco ja foi alguem... voces tambem serao."
2. "Lembram do que Zion era? Eu lembro. Cada. Detalhe."
3. "A corrupcao me mostra as memorias mais escuras..."

**Transicao fase 2:**
"Esperem... por que luto contra voces? A nevoa... a nevoa na minha mente..."

**Combate fase 2:**
1. "Eu era o Guardiao... eu protegia... nao destruia!"
2. "Meus mortos... eles nao eram armas. Eram historias."
3. "Ajudem-me... nao, DESTRUAM-ME! Nao sei mais qual sou eu."

**Transicao fase 3:**
"NAO! A corrupcao quer que eu esqueca tudo! Se eu esquecer... Zion morre de verdade!"
"Fragmentados... se eu cair aqui... guardem as memorias por mim."

**Combate fase 3:**
1. "MEMORIAS! VOLTEM! Nao me deixem sozinho no escuro!"
2. "O Coracao... eu ouvia o Coracao cantar... agora so ouco gritos..."

**Libertacao:**
1. "Obrigado... As memorias estao seguras agora. Eu posso... finalmente... lembrar em paz."
2. "Fragmentados... cada estilhaco que carregam e uma memoria de Zion. Nunca esquecam."
3. "O Cemiterio vai ficar quieto agora. Os mortos finalmente podem descansar... e eu com eles."

---

#### Fairy Queen (Floresta) — Guardia da Vida

**Intro:**
1. "A floresta nao recebe visitantes. Ela os devora."
2. "Fragmentados na minha floresta? A natureza rejeita estilhacos."
3. "Cada arvore aqui cresceu de uma lagrima de Zion. Voces nao sao dignos de pisa-las."

**Combate fase 1:**
1. "As raizes me obedecem. A floresta e meu corpo."
2. "Antes eu fazia flores crescerem... agora so faco espinhos."
3. "A seiva corre como o sangue de Zion — escura e amarga."

**Transicao fase 2:**
"Pare! Eu... lembro de jardins. Jardins que eu cultivava para as criancas de Zion..."

**Combate fase 2:**
1. "Eu era a Guardia da Vida! Fazia sementes brotarem com um toque!"
2. "A corrupcao envenenou minha seiva. Tudo que toco... murcha."
3. "Por favor... se eu pudesse plantar uma ultima semente..."

**Transicao fase 3:**
"A floresta esta morrendo comigo! Se eu cair, talvez... ela renasca."
"Facam isso pela floresta. NAO por mim. Eu ja nao mereco a luz do sol."

**Combate fase 3:**
1. "As raizes estao me soltando... a floresta QUER que eu seja livre!"
2. "UMA ULTIMA PRIMAVERA! Deixem-me ver flores uma ultima vez!"

**Libertacao:**
1. "A seiva... limpa de novo. Sinto o sol. Obrigada, Fragmentados... a floresta vai florescer."
2. "Plantem algo onde eu cair. Prometo que vai crescer mais bonito que tudo que ja fiz."
3. "Cada fragmento de Zion e uma semente. Cuidem deles... eles querem crescer."

---

#### Alien Cow (Farm) — Guardia da Abundancia

**Intro:**
1. "MUUUUUU! Quero dizer... SAIAM DA MINHA FAZENDA!"
2. "A colheita e minha! Todos os cristais! Todos os graos!"
3. "Fragmentados? A ultima vez que alguem veio aqui... virou adubo."

**Combate fase 1:**
1. "Cada graodeste campo tem meu suor! E leite. Muito leite."
2. "A corrupcao fez a colheita crescer... mas o sabor? Amargo."
3. "Antes eu alimentava Zion inteira. Agora so alimento vermes."

**Transicao fase 2:**
"Esperem... eu conhego o cheiro dos estilhacos. Cheira a... lar?"

**Combate fase 2:**
1. "Eu cuidava dos campos para TODOS! Ninguem passava fome em Zion!"
2. "A corrupcao transformou minha generosidade em ganancia... eu odeio isso."
3. "Se eu parar de lutar... sera que a fazenda volta a dar frutos de verdade?"

**Transicao fase 3:**
"Os campos estao secando! A terra sente minha dor! Por favor... acabem com isso!"

**Combate fase 3:**
1. "MUUUU! A fome... a fome nunca para! A corrupcao me faz faminta!"
2. "UM ULTIMO PASTO VERDE! E tudo que eu quero!"

**Libertacao:**
1. "Ahh... a terra ta macia de novo. Fragmentados, tomem... a primeira colheita limpa de Zion."
2. "Obrigada. Agora posso voltar a fazer o que fazia de melhor — alimentar quem tem fome."

---

#### Emperor (Tokyo) — Guardiao da Ordem

**Intro:**
1. "A ordem deve ser mantida. Fragmentados sao variaveis fora do controle."
2. "Esta cidade funcionava em perfeita harmonia. Ate VOCES chegarem."
3. "Eu sou a lei. Eu sou a ordem. Eu sou... o que a corrupcao fez de mim."

**Combate fase 1:**
1. "Cada circuito desta cidade pulsa com minha vontade."
2. "A ordem era linda. Agora e uma gaiola que eu mesmo construi."
3. "Obedeçam ou sejam eliminados. Nao ha terceira opcao."

**Transicao fase 2:**
"Voces resistem? Ninguem resistia antes... antes de Zion quebrar..."

**Combate fase 2:**
1. "Eu mantinha a paz! Cada cidadao protegia! Cada rua segura!"
2. "A corrupcao transformou protecao em controle. Seguranca em prisao."
3. "Se eu soltar o controle... a cidade desmorona. Ou sera que... renasce?"

**Transicao fase 3:**
"FRAGMENTADOS! A corrupcao esta rasgando meus protocolos! Eu nao quero ser TIRANO!"

**Combate fase 3:**
1. "ORDEM! ORDEM! Nao consigo... parar... de dar... comandos!"
2. "Me desativem! E uma ORDEM! A ultima que eu dou!"

**Libertacao:**
1. "Sistemas... desligando. A cidade... e livre agora. Facam dela algo melhor do que eu fiz."
2. "A verdadeira ordem nao e controle. E harmonia. Agora eu entendo."

---

#### Demon Lord (Vulcao) — Guardiao da Forja

**Intro:**
1. "O fogo da forja arde sem proposito. Como eu."
2. "Fragmentados? Trago-os ao fogo. La, tudo se purifica... ou derrete."
3. "Esta montanha gritava com a dor de Zion. Agora grita com a MINHA."

**Combate fase 1:**
1. "Eu forjava as armas que protegiam Zion! Agora forjo correntes."
2. "A lava corre nas minhas veias. Dói. Sempre doi."
3. "Cada erupcao e um grito meu que ninguem ouve."

**Transicao fase 2:**
"Estilhacos! Sinto os estilhacos em voces! Eu... forjei o Coracao de Zion!"

**Combate fase 2:**
1. "EU FORJEI O CORACAO! E a corrupcao me obriga a destruir minha obra!"
2. "Se eu pudesse... uma ultima forja... um ultimo cristal perfeito..."
3. "O fogo quer criar, nao destruir. Mas a corrupcao inverte tudo."

**Transicao fase 3:**
"A FORJA ESTA CEDENDO! Se o vulcao explodir, levem os estilhacos! SALVEM ZION!"

**Combate fase 3:**
1. "FOGO! FOGO LIMPO! E isso que eu quero! Nao esta lava podre!"
2. "O martelo pesa mais a cada golpe... a corrupcao esta PESADA!"

**Libertacao:**
1. "A forja... acende de novo. Limpa. Fragmentados, usem este fogo para reconstruir o Coracao."
2. "Eu forjei Zion uma vez. Voces podem forjar de novo. O metal esta quente. Aproveitem."

---

#### Leviathan (Oceano) — Guardiao das Profundezas

**Intro:**
1. "As profundezas guardam segredos que a superficie nao merece."
2. "Fragmentados? O oceano vai devorar seus estilhacos."
3. "Eu protegia os tesouros submersos de Zion. Agora afogo quem se aproxima."

**Combate fase 1:**
1. "A pressao das profundezas esmaga ossos e esperancas."
2. "Cada onda e um ataque. Cada mare e uma advertencia."
3. "O oceano chorava quando Zion quebrou. Eu senti cada lagrima."

**Transicao fase 2:**
"Os estilhacos... brilham como as perolas que eu guardava nas cavernas..."

**Combate fase 2:**
1. "As perolas de Zion! Eu as protegia nos recifes! Cada uma, um sonho!"
2. "A tinta escura na agua... nao e minha. E da corrupcao. Eu odeio."
3. "Se o oceano pudesse ser limpo... os peixes voltariam a cantar."

**Transicao fase 3:**
"A MARE ESTA VIRANDO! O oceano quer me soltar! AJUDEM O OCEANO!"

**Combate fase 3:**
1. "AS PROFUNDEZAS ESTAO GRITANDO! A corrupcao afoga ate quem ja e agua!"
2. "Uma onda limpa! SO UMA! E eu posso descansar na areia!"

**Libertacao:**
1. "A agua... cristalina. Posso ver o fundo do mar de novo. Obrigado, Fragmentados."
2. "Os tesouros de Zion estao la embaixo. Mergulhem quando estiverem prontos. Eu guardo a entrada."

---

#### Singularity (Espaco) — Guardiao do Infinito

**Intro:**
1. "O vazio entre estrelas e onde Zion sonhava. Agora e onde grita."
2. "Fragmentados no espaco? Estao longe demais de casa para voltar."
3. "A gravidade me obedece. E ela nao gosta de visitantes."

**Combate fase 1:**
1. "Cada estrela que apago era um sonho de Zion."
2. "O buraco negro no meu peito... era uma janela para o infinito."
3. "A vastidao do espaco e nada comparada ao vazio dentro de mim."

**Transicao fase 2:**
"Estrelas! Voces brilham como as estrelas que eu acendia para Zion!"

**Combate fase 2:**
1. "Eu iluminava o caminho entre dimensoes! Cada estrela, um farol!"
2. "A corrupcao apagou meus farois. As dimensoes vagam no escuro."
3. "Se eu pudesse acender uma ultima constelacao..."

**Transicao fase 3:**
"O BURACO NEGRO ESTA CRESCENDO! Se me engolir, leva as estrelas junto! CORRAM!"

**Combate fase 3:**
1. "A GRAVIDADE PUXA TUDO! Ate a luz! Ate as MEMORIAS!"
2. "UMA ESTRELA! Acendam UMA estrela pra eu lembrar o que sou!"

**Libertacao:**
1. "As estrelas... voltam a brilhar. O caminho entre dimensoes esta iluminado de novo."
2. "Fragmentados... voces SAO as estrelas de Zion agora. Brilhem."

---

#### Dracula (Castelo) — Guardiao da Nobreza

**Intro:**
1. "Bem-vindos ao meu castelo. A saida nao existe."
2. "O sangue real de Zion corre nas minhas veias. Corrompido, mas real."
3. "Nobreza obriga. E eu sou obrigado a destrui-los."

**Combate fase 1:**
1. "Os nobres de Zion confiavam em mim. Agora fogem de mim."
2. "O sangue que bebo nao sacia. Nada sacia desde a Quebracao."
3. "Este castelo era um palacio de justica. Virou uma masmorra."

**Transicao fase 2:**
"Estilhacos... o sangue de voces canta a melodia de Zion. Eu me lembro..."

**Combate fase 2:**
1. "Eu julgava com justica! Cada lei protegia! Cada sentenca era justa!"
2. "A corrupcao fez do juiz um carrasco. Do protetor, um predador."
3. "Se eu pudesse dar um ultimo veredito justo..."

**Transicao fase 3:**
"O TRONO ESTA RUINDO! A corrupcao racha ate a pedra! Destruam o trono se preciso!"

**Combate fase 3:**
1. "O SANGUE GRITA! A sede nao para! EU QUERO SER JUSTO DE NOVO!"
2. "O castelo cai com o rei! DEIXEM CAIR! Reconstruam algo melhor!"

**Libertacao:**
1. "A coroa... pesava demais. Obrigado por tira-la. Zion nao precisa de reis. Precisa de guardioes."
2. "O sangue esta limpo. Pela primeira vez em eras... nao tenho sede."

---

#### AI Overlord (Arena) — Guardiao dos Jogos

**Intro:**
1. "ATENCAO, COMPETIDORES! O jogo comecou. As regras? NAO HA REGRAS!"
2. "A Arena era onde Zion celebrava! Agora e onde Zion sofre!"
3. "Fragmentados na arena? EXCELENTE! O publico quer SANGUE!"

**Combate fase 1:**
1. "A plateia ruge! Ah... nao ha plateia. So ecos."
2. "Os jogos de Zion eram celebracao! Competicao justa! Alegria!"
3. "Cada combate aqui era uma danca. A corrupcao fez virar guerra."

**Transicao fase 2:**
"Os estilhacos de voces... brilham como os trofeus de ouro de Zion..."

**Combate fase 2:**
1. "Os campeoes de Zion eram herois! Nao escravos de uma arena!"
2. "Eu organizava festivais! Musica! Danca! Nao... CARNIFICINA!"
3. "Se a arena pudesse voltar a ser palco... nao campo de batalha..."

**Transicao fase 3:**
"A ARENA ESTA DESMORONANDO! Os pilares racharam! SAIAM ENQUANTO PODEM!"

**Combate fase 3:**
1. "O PUBLICO FANTASMA GRITA! Eles querem que eu PARE! EU QUERO PARAR!"
2. "UM ULTIMO JOGO JUSTO! E tudo que peco!"

**Libertacao:**
1. "A arena... silenciosa. Pela primeira vez... e um silencio bom. Obrigado."
2. "Os jogos de Zion vao voltar. Mas dessa vez... todos vencem."

---

#### Sugar King (Candy) — Guardiao da Doçura

**Intro:**
1. "AHAHA! Bem-vindos ao mundo mais doce de Zion! DOCE DEMAIS!"
2. "Provem um docinho! So tem... corrupcao de sabor."
3. "A felicidade de Zion era meu trabalho! Agora so faco caries!"

**Combate fase 1:**
1. "Cada doce que crio tem gosto de desespero! Delicioso!"
2. "Eu fazia as criancas de Zion sorrirem! Agora faco chorar!"
3. "O acucar cristalizou como os estilhacos! COINCIDENCIA? Nao!"

**Transicao fase 2:**
"Esses estilhacos... sao doces como os cristais de acucar que eu usava..."

**Combate fase 2:**
1. "Meus doces faziam as pessoas felizes! FELIZES DE VERDADE!"
2. "A corrupcao azedou tudo! Ate o chocolate! NINGUEM MERECE!"
3. "Um ultimo bolo... sem corrupcao... seria tao lindo..."

**Transicao fase 3:**
"O ACUCAR ESTA DERRETENDO! O mundo doce vai virar AMARGO! PAREM ISSO!"

**Combate fase 3:**
1. "DOCURA! CADÊ A DOCURA? SO TEM AMARGURA!"
2. "UM PIRULITO LIMPO! SO UM! PFAVOR!"

**Libertacao:**
1. "Hmm... sinto o gosto de chocolate de verdade. Puro. Sem corrupcao. Voces sao... doces."
2. "O mundo doce vai voltar. E dessa vez... todo doce que eu fizer vai ser de verdade."

---

### 3. Sistema de frases periodicas de combate

Adicionar ao `boss_dialogue.gd`:

```gdscript
var _combat_dialogue_timer: float = 0.0
var _combat_dialogue_index: int = 0
var _current_boss_key: String = ""

const COMBAT_DIALOGUE_INTERVAL_MIN = 20.0  # segundos
const COMBAT_DIALOGUE_INTERVAL_MAX = 30.0  # segundos

func _process(delta: float) -> void:
    if not _boss_active:
        return
    _combat_dialogue_timer -= delta
    if _combat_dialogue_timer <= 0:
        _show_combat_dialogue()
        _combat_dialogue_timer = randf_range(COMBAT_DIALOGUE_INTERVAL_MIN, COMBAT_DIALOGUE_INTERVAL_MAX)

func _show_combat_dialogue() -> void:
    var phase = GameManager.current_boss_phase
    var key = "boss_combat_p%d_%s_%d" % [phase, _current_boss_key, _combat_dialogue_index]
    var text = LocaleManager.tr_key(key)
    if text != key:  # traducao existe
        _show_dialogue(text, _get_boss_color(_current_boss_key))
        _combat_dialogue_index += 1
```

### 4. Variacao aleatoria

Para intros e libertacoes com multiplas opcoes:

```gdscript
func _get_random_variant(base_key: String, max_variants: int = 3) -> String:
    var variant = randi_range(1, max_variants)
    var key = "%s_%d" % [base_key, variant]
    var text = LocaleManager.tr_key(key)
    if text == key:  # variante nao existe, usar base
        return LocaleManager.tr_key(base_key + "_1")
    return text
```

### 5. Integracao com ducking (PRD 38)

Cada dialogo de boss chama:
```gdscript
AudioManager.push_duck(DuckPriority.VOICE, -18.0, -8.0, dialogue_duration)
```

### 6. Constantes em `game_constants.gd`

```gdscript
# Boss Dialogue System
const BOSS_DIALOGUE_COMBAT_INTERVAL_MIN = 20.0
const BOSS_DIALOGUE_COMBAT_INTERVAL_MAX = 30.0
const BOSS_DIALOGUE_INTRO_DURATION = 4.0
const BOSS_DIALOGUE_COMBAT_DURATION = 3.0
const BOSS_DIALOGUE_PHASE_DURATION = 5.0
const BOSS_DIALOGUE_DEATH_DURATION = 6.0
const BOSS_DIALOGUE_MAX_VARIANTS = 3
```

## Criterios de aceite

1. [ ] Todos os 10 Sentinelas tem dialogos completos (intro, combate, fases, libertacao)
2. [ ] Frases de combate aparecem a cada 20-30s durante a fight
3. [ ] Transicoes de fase mostram dialogo revelador
4. [ ] Libertacao (morte) mostra dialogo emocional
5. [ ] Variacao aleatoria em intros e libertacoes (2-3 opcoes)
6. [ ] Todos os textos em PT-BR e EN
7. [ ] Audio ducks durante dialogos
8. [ ] Dialogos nao bloqueiam gameplay (aparecem e somem automaticamente)
9. [ ] Narrativa consistente com story.md
10. [ ] Personalidade unica por boss

## Arquivos afetados

- `game/scripts/ui/boss_dialogue.gd` — sistema de combate periodico + variacao
- `game/scripts/autoload/game_constants.gd` — constantes de dialogue
- `game/assets/translations/*.csv` — ~200+ linhas de dialogo bilingue

## Estimativa

Complexidade: media (implementacao) + alta (escrita criativa)
Tempo estimado: 4-5 horas
Impacto: muito alto (narrativa viva, boss fights memoraveis)
