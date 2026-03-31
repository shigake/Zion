# ADR-012 — DBs separados por tipo de conteúdo

**Status:** Aceito
**Data:** 2024-02

---

## Contexto

O jogo tem muitos tipos de conteúdo com estruturas de dados distintas: armas, itens, personagens, relíquias, evoluções, upgrades de loja. Precisávamos decidir como organizar o acesso a esses dados.

## Decisão

**Um singleton de banco de dados por tipo de conteúdo**, todos registrados como autoloads:

| Singleton | Conteúdo |
|-----------|---------|
| `WeaponDB` | 32 armas — stats, sprites, tipo, elemento, evolução |
| `ItemDB` | 19 itens passivos — efeitos, condição de evolução |
| `CharacterDB` | 15 Fragmentados — stats, habilidade passiva, sprite, backstory |
| `RelicDB` | 7 relíquias — efeitos únicos de longa duração |
| `EvolutionDB` | 12 evoluções — pré-requisitos (arma + item nível), resultado |
| `ShopDB` | 12 upgrades permanentes — custo em cristais, efeito, nível máximo |

Cada DB expõe métodos como `get_weapon(id: String) -> Dictionary` e `get_all_weapons() -> Array`.

## Justificativa

### Por que separados e não um único `ContentDB`?

- **Coesão**: cada DB carrega exatamente o que precisa — `WeaponDB` não precisa saber nada sobre relíquias
- **Tamanho**: com 32 armas + 19 itens + 15 personagens + 7 relíquias + 12 evoluções + 12 upgrades, um único arquivo seria difícil de navegar
- **Carregamento**: Godot carrega autoloads em ordem — DBs menores carregam mais rápido individualmente
- **Encapsulamento**: validações específicas ficam no DB correto (ex: `EvolutionDB` valida se arma + item estão no nível certo)
- **O(1) lookups**: cada DB usa `Dictionary` indexado por ID de string — `WeaponDB._data["fire_staff"]` é O(1)

### Por que não arquivos JSON externos?

- Dados de jogo mudam frequentemente durante desenvolvimento — GDScript inline é mais fácil de editar e tem autocompletar no editor
- Sem parsing overhead em runtime
- DBs podem ter lógica (métodos de cálculo) junto dos dados, sem camada separada

## Estrutura Típica

```gdscript
# weapon_db.gd
extends Node

var _data: Dictionary = {}

func _ready() -> void:
    _data = {
        "fire_staff": {
            "name": "Cajado de Chamas",
            "damage": 25,
            "cooldown": 1.2,
            "element": "fire",
            "evolution": "inferno_staff",
            "required_item": "fire_gem",
        },
        # ... 31 armas
    }

func get_weapon(id: String) -> Dictionary:
    return _data.get(id, {})

func get_all_weapons() -> Array:
    return _data.values()
```

## Consequências

- Adicionar novo conteúdo = editar o DB correspondente + criar cena/script da entidade
- DBs são a fonte de verdade para IDs — strings como `"fire_staff"` devem bater exatamente entre DB, cenas e scripts
- `ItemBonusCalculator` (em `scripts/autoload/`) é um helper que computa bônus combinados de itens — depende de `ItemDB` e `WeaponDB`
