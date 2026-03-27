# PRD — Art Direction (Prompts de Personagens e Fases)

> **Status: Pendente**
> Concept art de alta qualidade para todos os 12 personagens e 10 fases usando geracao por IA ou artistas. Prompts detalhados em `docs/art_prompts.md`.

## Objetivo

Gerar concept art de referencia para todos os personagens jogaveis e fases do jogo, no estilo visual inspirado em Zelda BotW / Genshin Impact. Esses concepts servem como:
1. Referencia para modelagem 3D (ver `prd_3d_models.md`)
2. Assets para UI (tela de selecao, loading screens, codex)
3. Material de marketing e redes sociais

## Estilo Visual

- **Inspiracao**: Zelda Breath of the Wild, Genshin Impact
- **Estetica**: High-end anime, cel-shading vibrante, toon shader
- **Qualidade**: 8K, detalhes intricados, gradientes suaves, contornos nitidos
- **Iluminacao**: Dinamica, suave, rim lighting

---

## Parte 1 — Personagens (12 concepts)

### Prompt Base
```
A highly detailed 3D character design of a [CHARACTER]. Visual style inspired
by Zelda Breath of the Wild and Genshin Impact, high-end anime aesthetic,
vibrant cel-shading, toon shader. Intricate details on clothing and weapons,
smooth gradients, crisp outlines. Soft dynamic lighting, rim lighting, 8k
resolution, masterpiece, trending on ArtStation, character concept art, clean
background.
```

### Checklist

- [ ] **Ronin** — Japanese samurai warrior, elegant upright posture, loose dark blue hakama, open kimono, green primary color accents, topknot hair, red headband, katana in scabbard, geta sandals
- [ ] **Soldado** — Robust military soldier, tactical vest with digital blue camouflage, cargo pants, combat boots, military helmet with visor, tactical backpack, chest bandolier, dog tags, steel blue primary color
- [ ] **Mago** — Classic wizard, long flowing purple robe with glowing stars and runes, wide-brimmed pointy hat, short beard, magical staff with glowing blue orb, belt with pouches
- [ ] **Berserker** — Huge intimidating viking, shirtless muscular torso with scars and tribal tattoos, leather pants, fur boots, horned viking helmet, long braided red beard, bone and skull belt, red war paint
- [ ] **Ninja** — Agile shinobi crouched posture, tight black ninja suit, long flowing red scarf, mask covering mouth/nose, glowing red eyes, red bandages on arms, shuriken holster, wakizashi on back
- [ ] **Necromante** — Dark skeletal lich, torn dark green robe, deep hood hiding face, glowing green eyes, floating grimoire, hanging chains, skull on shoulder, green soul particles
- [ ] **Pirata** — Pirate captain, large tricorn hat with feather, eyepatch, short black beard, open dark red captain's coat with golden buttons, white shirt, high boots, two flintlock pistols, short sword, rum bottle
- [ ] **Engenheiro** — Compact mechanic, yellow/gold work overalls with oil patches, thick gloves, safety boots, goggles on forehead, messy hair, backpack with antenna and blue LEDs, tool belt, holding wrench
- [ ] **Vampiro** — Elegant aristocratic vampire, Victorian suit, vest, long flowing cape with blood-red lining and silver buttons, slicked-back white hair, pale skin, fangs, glowing red eyes, white gloves, red rose on lapel
- [ ] **Gladiador** — Roman gladiator in shiny golden armor, lorica chestplate, pteruges leather skirt, gladius sandals, roman helmet with red crest, round shield with eagle emblem, holding spear, short cape
- [ ] **Chef** — Smiling cook, white chef uniform, tall toque blanche hat, thick mustache, apron with sauce stains, checkered pants, neckerchief, frying pan on back, knives on apron, holding wooden spoon
- [ ] **Mystery (???)** — Mysterious glitching humanoid entity, body made of TV static and corrupted pixel textures, floating fragmented polygons, large glowing question mark on face, rainbow glitch effects, scanlines

### Entrega
- Formato: PNG 2048x2048 ou superior
- Fundo: limpo (transparente ou solido neutro)
- Cada personagem com visao frontal (obrigatoria) + 3/4 (desejavel)
- Salvar em: `game/assets/art/characters/[char_id].png`

---

## Parte 2 — Fases (10 concepts)

### Prompt Base
```
A breathtaking vast landscape of a [STAGE DETAILS]. Video game environment
concept art inspired by Zelda Breath of the Wild and Genshin Impact. Lush
stylized graphics, beautiful cel-shading, vibrant color palette, volumetric
fog, god rays, highly detailed fantasy world, unreal engine 5 render,
cinematic lighting, masterpiece, wide angle view.
```

### Checklist

- [ ] **Fase 1 — Cemiterio Assombrado**: Spooky haunted graveyard at night, stylized cracked tombstones covered in ivy, twisted dead trees with crows, gothic iron fences, glowing yellow full moon, thick volumetric ground fog, mysterious lighting
- [ ] **Fase 2 — Floresta Encantada**: Magical colorful forest, giant glowing mushrooms, twisted magical trees with glowing blue and green canopies, glowing rivers of light, floating fireflies, purple crystal formations on the ground
- [ ] **Fase 3 — Fazenda do Apocalipse**: Destroyed countryside farm, vast cornfields with thick stylized cornstalks, rusted silos, broken red tractor, wooden fences, eerie scarecrows, apocalyptic twilight sky
- [ ] **Fase 4 — Toquio Cyberpunk**: Futuristic neon cyberpunk city, raining, stylized glowing skyscrapers with pink/blue/green neon strips, holographic billboards with japanese text, floating flying cars, neon-lit vending machines, electrical panels
- [ ] **Fase 5 — Vulcao Infernal**: Hellish volcanic cavern, flowing rivers of bright orange lava, floating dark obsidian rocks with orange glow underneath, smoking geysers, giant demonic skulls embedded in stone walls
- [ ] **Fase 6 — Fundo do Oceano**: Deep underwater sunken ruins, ancient greek columns covered in moss, colorful coral reefs, glowing jellyfish, tall green seaweed swaying, beams of sunlight filtering from surface, rising bubbles
- [ ] **Fase 7 — Arena Gladiadora**: Ancient roman colosseum, grand stone arches, fluted roman columns, iron gates, burning torches, hanging SPQR banners, sandy arena floor, stylized stadium
- [ ] **Fase 8 — Estacao Espacial**: Sci-fi space station interior, sleek metallic corridors with blue LED lights, large observation windows showing starry cosmos and distant planets, futuristic consoles, zero-gravity zones
- [ ] **Fase 9 — Castelo do Vampiro**: Dark gothic vampire castle interior, tall pointed pillars, stained glass windows with rich colors, glowing candelabras, ornate coffins, red velvet throne, standing empty suits of armor
- [ ] **Fase 10 — Mundo Doce**: Whimsical candy land, ground made of chocolate blocks, towering ice cream mountains, rivers of liquid caramel, giant candy canes, translucent gummy bears, giant lollipops, vibrant pastel colors

### Entrega
- Formato: PNG 2560x1440 ou superior (widescreen landscape)
- Estilo: paisagem panoramica, angulo aberto
- Cada fase com 1 concept art principal + 1 variante de iluminacao (desejavel)
- Salvar em: `game/assets/art/stages/[stage_id].png`
- Uso secundario: loading screen entre fases

---

## Ferramentas Sugeridas

- **Geracao IA**: Midjourney v6+, DALL-E 3, Stable Diffusion XL (com LoRA de anime/cel-shading)
- **Pos-processamento**: Photoshop/GIMP para limpeza e ajuste de cores
- **Modelagem 3D** (referencia): Blender 3.0+ (obrigatorio conforme CLAUDE.md)

## Referencia Completa

Todos os prompts detalhados estao em `docs/art_prompts.md`.
