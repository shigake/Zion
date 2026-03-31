# ADR-001 — Engine: Godot 4 + GDScript

**Status:** Aceito
**Data:** 2024-01 (início do projeto)

---

## Contexto

Precisávamos escolher uma engine para um roguelite survivors co-op online com suporte a 1000+ entidades simultâneas, efeitos visuais ricos, multiplayer online e distribuição no Steam.

## Decisão

Usar **Godot 4** com **GDScript** como linguagem principal.

## Justificativa

- **Gratuita e open-source** — sem royalties, sem limite de receita
- **GDScript** é simples e produtivo para uma equipe pequena (3 devs)
- **Godot 4** tem renderer Forward Plus com suporte a cel-shading, MSAA, partículas 3D e MultiMesh nativos — tudo que o Zion exige
- **GDExtension** permite integração nativa com GodotSteam para Steam Networking Sockets
- **Cenas + Autoloads** se encaixam perfeitamente no padrão de singletons que o jogo precisa
- **ENet embutido** no Godot 4 para multiplayer sem dependência externa
- **Export para Windows/Linux/Mac** gratuito e sem assinatura

## Alternativas Descartadas

| Engine | Por que descartada |
|--------|-------------------|
| Unity | Mudanças de licença em 2023 criaram incerteza; royalties por install; ecosystem mais pesado para indie |
| Unreal 5 | Curva de aprendizado muito alta; C++ obrigatório para performance; 5% royalty acima de $1M |
| GameMaker | 2D-first; suporte a 3D fraco; custo de licença anual |
| Defold | Comunidade pequena; falta de recursos 3D nativos |

## Consequências

- Todo o código é GDScript (`.gd`), exceto possíveis extensões nativas futuras (GodotSteam)
- Ferramental de CI/CD usa `godot --headless` para validação e export
- Limitação: GDScript é tipagem dinâmica por padrão — adotamos static typing (`var x: int`) onde possível
