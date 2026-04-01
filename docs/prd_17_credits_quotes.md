# PRD 17 — Créditos: falas aprimoradas e balão posicional

## Status: pendente

## Problema

A tela de créditos tem carrossel de heróis com balões de fala, mas precisa de três melhorias:

1. **Poucas falas por herói** — cada personagem tem apenas 3 frases. A repetição é perceptível em sessões longas na tela.
2. **Balão aparece em qualquer herói** — o speaker é sorteado aleatoriamente, então o balão fica pulando por toda a tela sem âncora visual clara.
3. **Sem suporte a múltiplos idiomas** — as falas estão apenas em português. Quando o jogo estiver em inglês (LocaleManager), os textos continuam em PT-BR.

---

## Solução

### 1 — Expandir o banco de frases (3 → 8 por herói)

Cada personagem passa de 3 para **8 frases** em cada idioma (PT-BR e EN), totalizando 240 frases (15 heróis × 8 × 2 idiomas).

As frases devem:
- Ser curtas (máx. 2 linhas)
- Ter humor que reflita a personalidade do personagem
- Não se repetir em sequência (lógica já existe: `_last_speaker_idx`)

### 2 — Balão apenas na posição "palco" (baixo da fogueira)

Em vez de sortear o speaker, o balão só aparece para o herói que estiver **na posição frontal inferior do carrossel** — o ponto mais próximo da câmera, ângulo ≈ `PI/2` (em relação ao eixo Z do mundo 3D).

**Lógica de detecção:**
```
# Para cada herói, calcular ângulo atual no carrossel:
current_angle = base_angle + _carousel_angle

# Normalizar para [0, TAU)
current_angle = fmod(current_angle, TAU)

# O "palco" é o ponto mais próximo da câmera (frente, sin > 0)
# => ângulo ≈ PI/2, com tolerância de ±0.35 rad (~20°)
is_on_stage = abs(current_angle - PI/2.0) < 0.35 or abs(current_angle - PI/2.0 - TAU) < 0.35
```

O `_animate_speech_bubbles` passa a chamar `_find_stage_hero()` em vez de `_pick_next_speaker()`. O herói no palco fala; os outros ficam em silêncio.

**Troca de fala:** quando o herói no palco muda (outro entrou na zona de ±0.35 rad), a frase atual some com fade e a nova começa com fade-in.

### 3 — Falas bilíngues via LocaleManager

A dict `CHARACTER_QUOTES` é substituída por `CHARACTER_QUOTES_PT` e `CHARACTER_QUOTES_EN`.

Em `_show_bubble()`, a escolha do dicionário é:
```gdscript
var quotes_db = CHARACTER_QUOTES_EN if LocaleManager.get_locale() == "en" else CHARACTER_QUOTES_PT
var quotes: Array = quotes_db.get(char_id, ["..."])
```

---

## Banco de frases

### PT-BR

| Herói | Frases (8) |
|---|---|
| **Ronin** | "Minha espada tem nome. Não vou dizer qual. É constrangedor." / "Bushido: o caminho do guerreiro. Hoje o caminho vai ali no armazém." / "Silêncio é sabedoria. Pelo menos é o que digo quando não sei a resposta." / "Medito todo dia às 5h. Bem, todo dia não. Às vezes." / "Dizem que estou sempre sério. Mentira. Às vezes estou muito sério." / "Cada cicatriz tem uma história. A maioria é embaraçosa." / "O inimigo que me subestima é o inimigo favorito." / "Já não lembro como era antes de Zion. Bom sinal, acho." |
| **Soldado** | "TATATATATA! Opa. Desculpa. Reflexo." / "Protocolo de combate ativo. Café também. Principalmente o café." / "Munição infinita seria ótimo. Alguém anota pra mim?" / "Regra nº1: nunca deixe o inimigo saber seu plano. Regra nº2: tenha um plano." / "Meu superior disse que eu era irrefreável. Concordo." / "Granadas? Sim. Coordenação? Em desenvolvimento." / "Dormia 4h por dia no exército. Agora durmo 3. Evolução." / "Fenda dimensional? Já vi coisa pior. Quase." |
| **Mago** | "Área de efeito? Eu chamo de 'zona de respeito'." / "Estudei 40 anos de magia pra isso. Valeu a pena. Acho." / "Meu cajado é decorativo. O dano não é." / "Feitiço de invisibilidade existe. Eu é que escolho não usar." / "Magia é ciência. Ciência é magia. Filosofia é complicada." / "O grimório me avisou que esta fenda era perigosa. Ignorei. Claro." / "Toda explosão tem um propósito. Descobrir qual é a parte difícil." / "Aprendi com os melhores. Eles sobreviveram. Inspirador." |
| **Berserker** | "O médico mandou relaxar. Ele não trabalha mais aqui." / "Com 30% de HP fico mais forte. É motivação às avessas." / "Raiva? Isso se chama foco. Intenso. Muito intenso." / "Musculação é meditação. Não leia estudos sobre isso." / "Minha armadura pesava 80kg. Sinto falta dela." / "Estratégia? Ir na frente é estratégia." / "Quanto mais inimigos, mais eficiente fica minha área de dano." / "Não sou violento. Sou vigoroso. Grande diferença." |
| **Ninja** | "Você não me viu chegar? Perfeito. Funcionou." / "A sombra que te protege. Ou assusta. Tanto faz." / "Invisível não é superpoder, é modo de vida." / "Treino 16h por dia. As outras 8h finjo que estou dormindo." / "O nome é segredo. O rosto também. Até eu esqueci como sou." / "Movo-me em silêncio. Exceto quando tropeço. Isso não acontece." / "Fumaça não é fuga. É... reposicionamento tático." / "Vivo nas sombras. Mas meu coração é de ouro. Desculpe o clichê." |
| **Pirata** | "Cristais valem mais que ouro. Não conta pra ninguém." / "Tive um barco. Longa história. Alguém tem cristal sobrando?" / "Mapa do tesouro? Esse aqui. Guarda segredo." / "Sete mares? Já naveguei dez. Os outros três são dimensionais." / "Rum dimensional é diferente. Não bebo mais. Quase." / "O código pirata diz: não deixar aliado pra trás. Exceto o chef." / "Tempestade não me assusta. Fenda dimensional também não. Cebola sim." / "Todo pirata tem um papagaio. O meu me abandonou. Respeito." |
| **Engenheiro** | "Meu drone faz tudo. Inclusive me envergonhar em público." / "Cooldown 15% menor. Burocracia não tem cooldown infelizmente." / "Tecnologia resolve tudo. Exceto esse bug. E aquele outro." / "Construí meu primeiro robô aos 8 anos. Ele fugiu. Traição." / "Sistemas automatizados: eficientes e sem reclamação de hora extra." / "Nunca terceirize o que você pode automatizar. Filosofia de vida." / "O drone tem nome. Não vou revelar. Ele prefere assim." / "Análise concluída: há 99% de chance de vitória. O 1% me preocupa." |
| **Vampiro** | "Lifesteal não é vampirismo. É nutrição alternativa." / "Durmo de dia, acordo de noite. Sou do turno da tarde, ok?" / "Não mordo ninguém. Há décadas. Quase." / "Imortalidade é superestimada. Mas é melhor que a alternativa." / "O sol é inconveniente. Não letal. Só muito, muito inconveniente." / "Século XVIII foi meu melhor período. A moda era excelente." / "Vampiro é um rótulo. Prefiro 'consumidor de força vital'." / "Tenho 400 anos de experiência. Em tudo. Menos em culinária." |
| **Gladiador** | "Armadura +20%? É porque combina com os olhos." / "No arena, ou você vence ou... também vence, se for eu." / "Escudo não é pra se esconder. É pra bater na cabeça do inimigo." / "Multidão gritando meu nome. Saudades. As fendas são muito silenciosas." / "Honra em combate. Vitória em estilo. Isso não é negociável." / "Já lutei leões, ursos e um Sentinela. O Sentinela foi o mais educado." / "Minha armadura pesa mais que alguns inimigos. Conveniente." / "Público adorava minha entrada no arena. Aqui não tem público. Triste." |
| **Chef** | "Avó tinha razão: comida cura tudo." / "Receita secreta de cura: amor, carinho e fungos dimensionais." / "Faca de cozinha também é arma. Pergunta pro último Sentinela." / "Cozinhei em 3 dimensões diferentes. Esta aqui tem os melhores ingredientes." / "Tempero certo faz milagre. No prato e no campo de batalha." / "Não desperdiço nada. Nem inimigos. Eles viram caldo." / "Michelin de dimensão? Não sei se existe. Mas merecia." / "A fome é o pior inimigo. Felizmente, sou o chef." |
| **Amazona** | "Minha lança não erra. As piadas do Ronin é que deixam a desejar." / "Filha de Zion não recua. Só dá um passo estratégico pra trás." / "Atirei o pau no gato... No sentido figurado. Ou não." / "Caça desde os 5 anos. Presas dimensionais são as mais interessantes." / "Floresta ou fenda, o instinto é o mesmo. Atacar primeiro." / "Minha tribo dizia: nunca atire sem mirar. Mas às vezes é mais rápido." / "Conheço cada planta medicinal de 3 biomas. E cada veneno também." / "Guerreira antes de ser Fragmentada. A ordem importa." |
| **Bruxa** | "Transformei o último inimigo em sapo. Ele nem reclamou." / "Feitiço de amor? Não, obrigada. Prefiro feitiço de dano em área." / "A lua me dá poderes. E insônia. Principalmente insônia." / "Meu grimório tem 600 anos. Ainda não terminei de ler." / "Poção de invisibilidade: testada. Efeito colateral: visibilidade inversa." / "Gato preto dá azar? Meu gato dá azar pra quem me ataca." / "Magia negra é relativismo. Depende de quem está perguntando." / "Vassoura é transporte. Caldeirão é ferramenta. Chapéu é estilo." |
| **Lealith** | "Velocidade é tudo. Inclusive pra fugir do chef." / "Dodge 15%? Na teoria. Na prática é 100% estilo." / "Passei tão rápido que nem me vi passar." / "Quem corre mais rápido chega primeiro. Filosofia simples, resultado garantido." / "Já corri de dragões, guardas e contas de padaria. Treino variado." / "Velocidade não é só física. É comprometimento. Bem, principalmente física." / "O vento me segue. Ou sou eu que sigo ele. Detalhes." / "Invisível em movimento. Presente na vitória. Essa é a arte." |
| **Mystery** | "..." / "Eu sei coisas. Não, não vou contar." / "???" / "Nem meu nome você sabe. Nem eu." / "A resposta está aqui. Você só não sabe a pergunta." / "Mistério não é ausência de resposta. É excesso de perguntas." / "Talvez eu seja real. Talvez não. Zion sabe." / "Cada vez que me observam, mudo um pouco. Mecânica quântica?" |
| **Fragmentado** | "Estou bem. São só 10 fendas por dia." / "Tenho um estilhaço de Zion dentro de mim. Arde um pouco." / "Comecei com 50% de HP. Ainda assim cheguei aqui." / "Ser Fragmentado não é defeito. É diferencial competitivo." / "O cristal dentro de mim tem opiniões próprias. Ignoro a maioria." / "Zion me escolheu. Ou eu escolhi Zion. A linha é tênue." / "Cada fenda que restauro, me sinto um pouco mais inteiro. Irônico." / "Fragmentado, mas não quebrado. Tem diferença." |

### EN

| Herói | Frases (8) |
|---|---|
| **Ronin** | "My sword has a name. I won't say what. It's embarrassing." / "Bushido: the warrior's path. Today the path leads to the supply room." / "Silence is wisdom. That's what I say when I don't know the answer." / "I meditate every day at 5am. Well. Most days. Sometimes." / "They say I'm always serious. False. Sometimes I'm very serious." / "Every scar has a story. Most are embarrassing." / "The enemy who underestimates me is my favorite enemy." / "I no longer remember life before Zion. That's probably a good sign." |
| **Soldado** | "RATATATA! Sorry. Reflex." / "Combat protocol active. Coffee too. Especially the coffee." / "Infinite ammo would be great. Someone write that down." / "Rule #1: never let the enemy know your plan. Rule #2: have a plan." / "My commander called me unstoppable. I agree." / "Grenades? Yes. Coordination? In progress." / "I slept 4h a day in the army. Now I sleep 3. Growth." / "Dimensional rift? I've seen worse. Almost." |
| **Mago** | "Area of effect? I call it the 'zone of respect'." / "I studied magic for 40 years for this. Worth it. Probably." / "My staff is decorative. The damage is not." / "Invisibility spells exist. I just choose not to use them." / "Magic is science. Science is magic. Philosophy is complicated." / "The grimoire warned me this rift was dangerous. I ignored it. Obviously." / "Every explosion has a purpose. Finding it is the hard part." / "I learned from the best. They survived. Inspirational." |
| **Berserker** | "Doctor told me to relax. He no longer works here." / "At 30% HP I get stronger. Reverse motivation." / "Anger? This is called focus. Intense. Very intense." / "Weightlifting is meditation. Don't read studies about it." / "My armor weighed 80kg. I miss it." / "Strategy? Charging first is strategy." / "More enemies means my AoE gets more efficient." / "I'm not violent. I'm vigorous. Big difference." |
| **Ninja** | "You didn't see me coming? Perfect. It worked." / "The shadow that protects you. Or frightens you. Either way." / "Invisible isn't a superpower — it's a lifestyle." / "I train 16 hours a day. The other 8 I pretend to sleep." / "My name is a secret. My face too. I've forgotten what I look like." / "I move in silence. Except when I trip. That doesn't happen." / "Smoke isn't fleeing. It's... tactical repositioning." / "I live in shadows. But my heart is gold. Sorry for the cliché." |
| **Pirata** | "Crystals are worth more than gold. Don't tell anyone." / "I had a ship. Long story. Anyone have spare crystals?" / "Treasure map? Right here. Keep it secret." / "Seven seas? I've sailed ten. Three of them are dimensional." / "Dimensional rum is different. I don't drink anymore. Almost." / "The pirate code says: leave no ally behind. Except the chef." / "Storms don't scare me. Dimensional rifts don't either. Onions do." / "Every pirate has a parrot. Mine left me. Respect." |
| **Engenheiro** | "My drone does everything. Including embarrass me in public." / "15% cooldown reduction. Bureaucracy has no cooldown unfortunately." / "Technology solves everything. Except that bug. And the other one." / "I built my first robot at 8. It ran away. Betrayal." / "Automated systems: efficient and no overtime complaints." / "Never outsource what you can automate. Life philosophy." / "The drone has a name. I won't say it. It prefers that." / "Analysis complete: 99% chance of victory. The 1% worries me." |
| **Vampiro** | "Lifesteal isn't vampirism. It's alternative nutrition." / "Sleep during the day, wake at night. I'm on the late shift, ok?" / "I don't bite anyone. Haven't in decades. Almost." / "Immortality is overrated. But better than the alternative." / "The sun is inconvenient. Not lethal. Just very, very inconvenient." / "The 18th century was my best period. The fashion was excellent." / "Vampire is a label. I prefer 'life force consumer'." / "I have 400 years of experience. In everything. Except cooking." |
| **Gladiador** | "Armor +20%? It matches my eyes." / "In the arena, you either win or... you also win, if it's me." / "A shield isn't for hiding. It's for hitting enemies on the head." / "Crowds chanting my name. I miss it. Rifts are too quiet." / "Honor in combat. Victory in style. Non-negotiable." / "I've fought lions, bears and a Sentinel. The Sentinel was the most polite." / "My armor weighs more than some enemies. Convenient." / "The crowd loved my arena entrance. There's no crowd here. Sad." |
| **Chef** | "Grandma was right: food heals everything." / "Secret healing recipe: love, care and dimensional mushrooms." / "Kitchen knife is also a weapon. Ask the last Sentinel." / "I've cooked in 3 different dimensions. This one has the best ingredients." / "The right seasoning works miracles. On the plate and on the battlefield." / "I waste nothing. Not even enemies. They become broth." / "Dimensional Michelin star? Don't know if it exists. But I'd deserve it." / "Hunger is the worst enemy. Luckily, I'm the chef." |
| **Amazona** | "My spear never misses. Unlike Ronin's jokes." / "A daughter of Zion doesn't retreat. She takes a strategic step back." / "I threw the stick at the cat... Figuratively. Or not." / "I've hunted since I was 5. Dimensional prey is the most interesting." / "Forest or rift, the instinct is the same. Strike first." / "My tribe said: never shoot without aiming. But sometimes it's faster." / "I know every medicinal plant in 3 biomes. And every poison too." / "Warrior before being Fragmented. The order matters." |
| **Bruxa** | "I turned the last enemy into a frog. He didn't even complain." / "Love spell? No thanks. I prefer area damage spells." / "The moon gives me power. And insomnia. Mainly insomnia." / "My grimoire is 600 years old. I haven't finished reading it." / "Invisibility potion: tested. Side effect: inverse visibility." / "Black cat brings bad luck? Mine brings bad luck to those who attack me." / "Dark magic is relativism. Depends on who's asking." / "Broom is transport. Cauldron is a tool. Hat is style." |
| **Lealith** | "Speed is everything. Including for escaping the chef." / "15% dodge? In theory. In practice it's 100% style." / "I passed so fast I didn't even see myself go by." / "Whoever runs faster gets there first. Simple philosophy, guaranteed results." / "I've run from dragons, guards and bakery bills. Varied training." / "Speed isn't just physical. It's commitment. Well, mainly physical." / "The wind follows me. Or I follow it. Details." / "Invisible in motion. Present in victory. That's the art." |
| **Mystery** | "..." / "I know things. No, I won't tell you." / "???" / "You don't even know my name. Neither do I." / "The answer is right here. You just don't know the question." / "Mystery isn't the absence of an answer. It's an excess of questions." / "Maybe I'm real. Maybe not. Zion knows." / "Every time someone observes me, I change a little. Quantum mechanics?" |
| **Fragmentado** | "I'm fine. It's only 10 rifts a day." / "I have a shard of Zion inside me. It stings a little." / "I started at 50% HP. Still made it here." / "Being Fragmented isn't a flaw. It's a competitive advantage." / "The crystal inside me has its own opinions. I ignore most of them." / "Zion chose me. Or I chose Zion. The line is blurry." / "Every rift I restore, I feel a little more whole. Ironic." / "Fragmented, but not broken. There's a difference." |

---

## Arquivos a alterar

| Arquivo | Mudança |
|---|---|
| `game/scripts/ui/credits_screen.gd` | Substituir `CHARACTER_QUOTES` por `CHARACTER_QUOTES_PT` e `CHARACTER_QUOTES_EN` com 8 frases cada; alterar `_pick_next_speaker()` por `_find_stage_hero()`; atualizar `_show_bubble()` para consultar LocaleManager |

---

## Comportamento detalhado do "palco"

```
Palco = ângulo do carrossel mais próximo de PI/2 (herói na frente, ao sul da fogueira)
Tolerância = ±0.35 rad

A cada frame:
  - Calcular qual herói está no palco (ângulo atual dentro da tolerância)
  - Se mudou de herói → fade-out do balão atual → fade-in com nova frase
  - Se nenhum herói está no palco (zona de transição) → balão oculto
```

Vantagem: o balão nunca "voa" pela tela. Fica sempre ancorado ao herói que está na posição de destaque, bem embaixo da fogueira, centralizado na câmera.

---

## Critérios de aceitação

- [ ] Cada herói tem ≥ 8 frases em PT-BR e ≥ 8 frases em EN
- [ ] Balão de fala aparece apenas para o herói na posição frontal do carrossel (±0.35 rad de PI/2)
- [ ] Quando o idioma é `"en"`, as falas aparecem em inglês
- [ ] Quando o idioma é `"pt_BR"` (ou qualquer outro não-EN), as falas aparecem em português
- [ ] Troca de herói no palco → fade-out → nova frase sem delay visual brusco
- [ ] Frases não se repetem em sequência consecutiva para o mesmo herói
- [ ] Nenhuma quebra visual em 1280×720
