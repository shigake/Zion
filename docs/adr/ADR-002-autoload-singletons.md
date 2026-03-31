# ADR-002 — Padrão Autoload/Singleton para serviços globais

**Status:** Aceito
**Data:** 2024-01

---

## Contexto

O jogo tem muitos sistemas que precisam ser acessíveis de qualquer lugar: gerenciamento de audio, banco de dados de armas, save, multiplayer, conquistas, etc. Precisávamos de um padrão de acesso global consistente.

## Decisão

Usar o sistema de **Autoload** do Godot 4 para registrar todos os serviços globais como singletons no `project.godot`.

**34 autoloads registrados**, organizados por responsabilidade:

| Categoria | Singletons |
|-----------|-----------|
| Core | `GameManager`, `GameConstants`, `LogManager`, `PlatformHelper` |
| Dados | `WeaponDB`, `ItemDB`, `CharacterDB`, `RelicDB`, `EvolutionDB`, `ShopDB` |
| Persistência | `SaveManager` |
| Multiplayer | `MultiplayerManager` |
| Audio | `AudioManager` |
| Visual | `UITheme`, `ScreenEffects`, `ParticleFactory`, `VisualSetup`, `ModelFactory`, `MultiMeshManager` |
| Input | `KeybindingManager`, `GamepadUI` |
| Sistemas | `ObjectPool`, `SynergySystem`, `MutationManager`, `ChestManager`, `QuestManager` |
| Progressão | `AchievementManager`, `DailyChallenge` |
| UI Global | `LoadingScreen`, `AchievementPopup`, `BossDialogue`, `InventoryOverlay`, `DebugOverlay` |
| Infra | `Telemetry`, `SteamManager`, `AutoTester`, `LocaleManager` |

## Justificativa

- **Acesso direto** de qualquer cena sem injeção de dependência manual: `AudioManager.play_sfx("hit")`
- **Carregamento garantido** antes de qualquer cena — Godot carrega autoloads em sequência definida no project.godot
- **Ordem importa**: `GameConstants` → `LogManager` → `GameManager` → demais (respeita dependências)
- **Testável via CLI**: autoloads ficam disponíveis nos testes headless
- Padrão idiomático do Godot — usado em todos os jogos sérios da engine

## Alternativas Descartadas

| Alternativa | Por que descartada |
|-------------|-------------------|
| Injeção de dependência manual | Muito verboso para uma equipe pequena; Godot não tem container DI nativo |
| Nodes filhos da cena principal | Ordem de carregamento imprevisível; difícil acessar de cenas filho |
| Variáveis globais simples | Não tem ciclo de vida (`_ready`, `_process`); não pode emitir signals |

## Consequências

- Qualquer autoload pode depender de autoloads registrados **antes** dele na lista
- `LodManager` e `PerfMonitor` existem em `scripts/autoload/` mas **não** são registrados — são instanciados manualmente pelas cenas de fenda (só carregam durante gameplay)
- Adicionar novo serviço global = 1 linha no `[autoload]` do `project.godot`
