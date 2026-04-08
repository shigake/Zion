# PRD 57 — Painel "proxima evolucao" no HUD

**Status**: pendente
**Prioridade**: alta
**Tipo**: quality-of-life / UX

---

## Problema

O sistema de evolucao requer arma nivel 8 + item especifico, mas nao existe indicacao no HUD de quais combinacoes sao possiveis. O jogador precisa decorar as 12 evolucoes ou sair do jogo para consultar. Isso e especialmente frustrante para novos jogadores que nao sabem por que "nada aconteceu" quando a arma chegou no nivel maximo.

## Solucao

Painel compacto no HUD que mostra, para cada arma equipada, qual item e necessario para evoluir e o progresso atual (nivel da arma + se tem o item).

## Especificacao tecnica

### 1. Componente `evolution_tracker.gd`

**Local**: `scripts/ui/evolution_tracker.gd`
**Tipo**: `Control` node filho do HUD

### 2. Modo de exibicao

Dois modos de visualizacao:

**Modo compacto (padrao)**: icone pequeno ao lado de cada arma no HUD
- Se a arma tem evolucao possivel: icone do item necessario com borda cinza (nao tem) ou dourada (tem o item)
- Se a arma ja evoluiu: icone de estrela dourada
- Se a arma nao tem evolucao: nada

**Modo expandido (toggle com tecla)**: painel lateral com detalhes
- Tecla: `Tab` (ou configuravel via KeybindingManager)
- Lista todas as armas equipadas com:
  ```
  [Icone Arma] Katana Lv.6/8  →  [Icone Item] Luva (precisa)
  [Icone Arma] Staff Lv.8/8   →  [Icone Item] Cristal ✓ (pronto!)
  [Icone Arma] Chicote Lv.4/8 →  [Icone Item] Sangue Vampiro (precisa)
  ```

### 3. Layout do modo compacto

Integrado ao display de armas existente no HUD (bottom-left):
```
┌────────┐
│ [arma] │  ← icone da arma (existente)
│ Lv.6   │  ← nivel (existente)
│ [item]○│  ← NOVO: mini-icone do item necessario (16x16)
└────────┘      ○ = borda cinza (nao tem) / ● = borda dourada (tem)
```

Se a arma nao tem evolucao, a terceira linha nao aparece.

### 4. Layout do modo expandido

Painel lateral direito:
```
┌─── Ressonancias ────────────────────┐
│                                      │
│  [katana] Katana         Lv 6/8     │
│           → Luva de Combate ○       │
│                                      │
│  [staff]  Cajado Arcano   Lv 8/8    │
│           → Cristal Magico ●  PRONTO│
│                                      │
│  [arco]   Arco Elfico     Lv 3/8    │
│           → Capa Sombria ○          │
│                                      │
│  [fogo]   Lancachamas     Lv 5/8    │
│           (sem evolucao)             │
│                                      │
└──────────────────────────────────────┘
```

**Estilo**:
- Fundo: `Color(0.08, 0.08, 0.12, 0.9)`
- Titulo: fonte UITheme, tamanho 18, cor dourada `Color(1.0, 0.85, 0.3)`
- Texto normal: branco, tamanho 14
- "PRONTO": texto verde pulsante `Color(0.3, 1.0, 0.3)`
- Borda: `Color(0.3, 0.25, 0.1, 0.6)` — dourada sutil

### 5. Dados do EvolutionDB

Consultar `EvolutionDB.EVOLUTIONS` para mapear arma → item necessario:
```gdscript
func get_evolution_info(weapon_id: String) -> Dictionary:
    for evo_id in EvolutionDB.EVOLUTIONS:
        var evo = EvolutionDB.EVOLUTIONS[evo_id]
        if evo.weapon == weapon_id:
            return {
                "evolution_id": evo_id,
                "item_needed": evo.item,
                "item_name": ItemDB.get_item(evo.item).name,
                "has_item": GameManager.has_item(evo.item),
                "weapon_level": GameManager.get_weapon_level(weapon_id),
                "is_ready": GameManager.get_weapon_level(weapon_id) >= 8 and GameManager.has_item(evo.item),
                "is_evolved": weapon_id in EvolutionDB.evolved_weapons
            }
    return {}  # sem evolucao
```

### 6. Atualizacao

O tracker atualiza quando:
- `GameManager.weapon_added` — nova arma adquirida
- `GameManager.weapon_upgraded` — arma subiu de nivel
- `GameManager.item_added` — novo item adquirido (pode completar combo)
- `EvolutionDB.weapon_evolved` — evolucao ocorreu

### 7. Notificacao de evolucao disponivel

Quando uma arma atinge nivel 8 E o jogador tem o item necessario:
- Flash dourado no icone compacto (pulse 3x)
- Texto flutuante: "Evolucao disponivel!" (sobe e desaparece em 2s)
- SFX: som de cristal ressonando (reutilizar sfx existente de evolucao)

### 8. Opcoes

- Toggle no menu de opcoes: "Mostrar evolucoes no HUD" (padrao: ligado)
- O modo expandido pode ser desligado independentemente
- Salvo em SaveManager

## Criterios de aceite

- [ ] Modo compacto mostra mini-icone do item necessario ao lado de cada arma
- [ ] Modo expandido (Tab) mostra painel com todas as armas e seus requisitos
- [ ] Indicacao visual clara: cinza (falta), dourado (tem item), verde (pronto), estrela (evoluido)
- [ ] Notificacao com flash e texto quando evolucao fica disponivel
- [ ] Atualiza em tempo real conforme armas e itens sao adquiridos
- [ ] Armas sem evolucao nao mostram nada (compacto) ou "(sem evolucao)" (expandido)
- [ ] Todas as 12 evolucoes mapeadas corretamente
- [ ] Toggle funcional nas opcoes
- [ ] Nao obstrui gameplay no modo compacto
- [ ] Cabe em 1280x720

## Narrativa

O painel representa a "percepcao de ressonancia cristalina" do Fragmentado. Os estilhacos de Zion dentro de cada arma e item vibram quando estao proximos de uma combinacao possivel, e o Fragmentado sente intuitivamente quais pecas se completam.

## Estimativa

~3-4 horas. EvolutionDB ja tem todas as informacoes, e mais UI e logica de display.
