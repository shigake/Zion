# PRD: Icon Integration & Projectile Visual Polish

## Status: In Progress

## Problem
1. 44 SVG icons exist but aren't displayed in their respective UI screens (relics, achievements, mutations, UI indicators)
2. 4 weapon projectiles use basic geometric primitives or just lights, lacking visual identity

## Scope

### Part 1 — Icon Integration

All 133 SVGs already exist in `game/assets/icons/`. These screens need integration:

| Screen | File | Icons to Add | Count |
|--------|------|-------------|-------|
| Relic Select | `relic_select.gd` | `relics/{id}.svg` | 7 |
| Achievement popup (HUD) | `hud.gd` | `achievements/{id}.svg` | 13 |
| Mutations Panel | `mutations_panel.gd` | Replace emoji with SVG or keep emoji | 6 |
| Game Over Screen | `game_over_screen.gd` | Weapon/item icons in run summary | varies |

Pattern to follow (already used in hud.gd, level_up_screen.gd, shop.gd):
```gdscript
var icon_path = "res://assets/icons/{category}/{id}.svg"
var icon_tex = load(icon_path) if ResourceLoader.exists(icon_path) else null
if icon_tex:
    var tex_rect = TextureRect.new()
    tex_rect.texture = icon_tex
    tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
```

### Part 2 — Projectile Visual Upgrades

| Weapon | Current | Target |
|--------|---------|--------|
| Shuriken | 2 crossed BoxMesh | 4-point star mesh with metallic material + ice trail particles |
| Poison Pool | CylinderMesh disc | Bubbling toxic surface with animated scale + bubble particles |
| Flamethrower | BoxMesh cone | Layered cone with gradient material + ember particles + heat distortion |
| Lightning Chain | ImmediateMesh lines | Thicker zigzag with glow material + brighter spark particles + flash on hit |

Technical constraints:
- Max ~200 simultaneous particles total
- Use ObjectPool for reusable projectiles
- Low-vertex primitives only (performance)
- GPUParticles3D preferred over CPUParticles3D

## Priority
P0: Relic icons, projectile upgrades (gameplay-visible)
P1: Achievement icons, game over icons
P2: Mutations panel, UI indicator icons
