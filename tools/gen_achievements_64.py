"""Generate 64x64 achievement sprites for Zion.
Replaces tiny 16x16 stubs with detailed pixel art.
Run: python tools/gen_achievements_64.py
"""
from PIL import Image, ImageDraw
import os

S = 64
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "sprites", "achievements")
os.makedirs(OUT, exist_ok=True)


def img():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def c(r, g, b, a=255):
    return (int(r * 255), int(g * 255), int(b * 255), a)


def fill(im, x, y, w, h, color):
    d = ImageDraw.Draw(im)
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=color)


def px(im, x, y, color):
    if 0 <= x < S and 0 <= y < S:
        im.putpixel((x, y), color)


def circle(im, cx, cy, r, color):
    d = ImageDraw.Draw(im)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)


def circle_outline(im, cx, cy, r, color):
    d = ImageDraw.Draw(im)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color)


def line_h(im, x1, x2, y, color):
    for x in range(max(x1, 0), min(x2 + 1, S)):
        px(im, x, y, color)


def line_v(im, x, y1, y2, color):
    for y in range(max(y1, 0), min(y2 + 1, S)):
        px(im, x, y, color)


def outline(im, color):
    """Add 1px outline around non-transparent pixels."""
    copy = im.copy()
    for x in range(S):
        for y in range(S):
            if copy.getpixel((x, y))[3] > 0:
                for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < S and 0 <= ny < S and copy.getpixel((nx, ny))[3] == 0:
                        im.putpixel((nx, ny), color)


def save(im, name):
    path = os.path.join(OUT, name)
    im.save(path)
    print(f"Saved: {path}")


def triangle(im, pts, color):
    d = ImageDraw.Draw(im)
    d.polygon(pts, fill=color)


# ==================== ACHIEVEMENTS ====================

def gen_first_walk():
    """Meu Primeiro Passeio — survive 5 min. Hourglass with footprints."""
    im = img()
    sand_top = c(0.85, 0.75, 0.45)
    sand_bot = c(0.7, 0.6, 0.3)
    glass = c(0.75, 0.85, 0.95)
    glass_dk = c(0.55, 0.65, 0.8)
    frame = c(0.55, 0.45, 0.2)
    frame_lt = c(0.7, 0.6, 0.3)
    green = c(0.2, 0.7, 0.3)
    green_dk = c(0.12, 0.5, 0.2)
    ol = c(0.08, 0.25, 0.08)

    # Hourglass frame top/bottom
    fill(im, 18, 6, 28, 4, frame)
    fill(im, 20, 4, 24, 2, frame_lt)
    fill(im, 18, 54, 28, 4, frame)
    fill(im, 20, 58, 24, 2, frame_lt)

    # Glass body - top half
    fill(im, 22, 10, 20, 6, glass)
    fill(im, 24, 16, 16, 6, glass)
    fill(im, 26, 22, 12, 4, glass_dk)
    fill(im, 28, 26, 8, 4, glass_dk)

    # Neck
    fill(im, 30, 30, 4, 4, glass)

    # Glass body - bottom half
    fill(im, 28, 34, 8, 4, glass)
    fill(im, 26, 38, 12, 4, glass_dk)
    fill(im, 24, 42, 16, 6, glass)
    fill(im, 22, 48, 20, 6, glass)

    # Sand top
    fill(im, 24, 12, 16, 4, sand_top)
    fill(im, 26, 16, 12, 4, sand_top)

    # Sand bottom
    fill(im, 24, 48, 16, 4, sand_bot)
    fill(im, 26, 44, 12, 4, sand_bot)

    # Sand stream
    fill(im, 31, 28, 2, 8, sand_top)

    # Small footprints beside hourglass
    fill(im, 6, 40, 4, 6, green)
    fill(im, 6, 48, 4, 6, green)
    fill(im, 8, 38, 2, 2, green_dk)
    fill(im, 8, 46, 2, 2, green_dk)

    # Right footprint
    fill(im, 52, 36, 4, 6, green)
    fill(im, 52, 44, 4, 6, green)
    fill(im, 54, 34, 2, 2, green_dk)
    fill(im, 54, 42, 2, 2, green_dk)

    outline(im, ol)
    save(im, "first_walk.png")


def gen_evolved_6():
    """Isso Escala — 6 evolved weapons. Crystal star with 6 points."""
    im = img()
    purple = c(0.6, 0.2, 0.8)
    purple_dk = c(0.4, 0.1, 0.55)
    purple_lt = c(0.75, 0.4, 0.95)
    white = c(0.95, 0.9, 1.0)
    glow = c(0.8, 0.5, 1.0, 180)
    ol = c(0.2, 0.06, 0.3)

    # Central hexagon
    fill(im, 24, 20, 16, 24, purple)
    fill(im, 20, 24, 24, 16, purple)
    fill(im, 22, 22, 20, 20, purple_lt)
    fill(im, 26, 26, 12, 12, white)

    # 6 spikes (crystal points)
    # Top
    fill(im, 28, 4, 8, 16, purple)
    fill(im, 30, 2, 4, 6, purple_lt)
    # Bottom
    fill(im, 28, 44, 8, 16, purple)
    fill(im, 30, 56, 4, 6, purple_lt)
    # Top-left
    fill(im, 10, 12, 12, 8, purple_dk)
    fill(im, 12, 14, 8, 4, purple)
    # Top-right
    fill(im, 42, 12, 12, 8, purple_dk)
    fill(im, 44, 14, 8, 4, purple)
    # Bottom-left
    fill(im, 10, 44, 12, 8, purple_dk)
    fill(im, 12, 46, 8, 4, purple)
    # Bottom-right
    fill(im, 42, 44, 12, 8, purple_dk)
    fill(im, 44, 46, 8, 4, purple)

    # Number "6" in center
    fill(im, 28, 28, 8, 10, purple_dk)
    fill(im, 28, 28, 3, 10, white)
    fill(im, 28, 28, 8, 2, white)
    fill(im, 28, 33, 8, 2, white)
    fill(im, 34, 33, 2, 5, white)
    fill(im, 28, 36, 8, 2, white)

    outline(im, ol)
    save(im, "evolved_6.png")


def gen_speedrunner():
    """Speedrunner — kill boss < 15 min. Lightning bolt + clock."""
    im = img()
    yellow = c(1.0, 0.85, 0.1)
    yellow_dk = c(0.8, 0.65, 0.05)
    yellow_lt = c(1.0, 0.95, 0.5)
    blue = c(0.2, 0.4, 0.8)
    blue_dk = c(0.12, 0.25, 0.6)
    face = c(0.92, 0.9, 0.82)
    hand = c(0.15, 0.12, 0.1)
    ol = c(0.08, 0.18, 0.4)

    # Small clock in top-left
    circle(im, 16, 16, 10, blue)
    circle(im, 16, 16, 8, face)
    # Clock hands
    line_v(im, 16, 10, 16, hand)
    line_h(im, 16, 22, 16, hand)
    circle(im, 16, 16, 2, blue_dk)

    # Big lightning bolt
    # Top part
    fill(im, 34, 4, 12, 6, yellow_lt)
    fill(im, 30, 10, 14, 6, yellow)
    fill(im, 26, 16, 16, 6, yellow)
    fill(im, 22, 22, 18, 4, yellow)
    # Middle bar
    fill(im, 30, 26, 20, 4, yellow_lt)
    # Bottom part
    fill(im, 34, 30, 14, 6, yellow)
    fill(im, 30, 36, 14, 6, yellow_dk)
    fill(im, 26, 42, 12, 6, yellow)
    fill(im, 22, 48, 10, 6, yellow_dk)
    fill(im, 20, 54, 6, 6, yellow)

    # Speed lines
    for i in range(4):
        y = 18 + i * 10
        line_h(im, 2, 10, y, c(0.8, 0.8, 0.3, 140))
        line_h(im, 4, 8, y + 1, c(0.8, 0.8, 0.3, 100))

    outline(im, ol)
    save(im, "speedrunner.png")


def gen_collector():
    """Colecionador — unlock all chars. Trophy/crown with gems."""
    im = img()
    gold = c(0.85, 0.7, 0.15)
    gold_dk = c(0.6, 0.48, 0.08)
    gold_lt = c(1.0, 0.88, 0.35)
    gem_r = c(0.9, 0.15, 0.15)
    gem_b = c(0.15, 0.3, 0.9)
    gem_g = c(0.15, 0.8, 0.25)
    ol = c(0.2, 0.1, 0.02)

    # Trophy cup
    fill(im, 16, 10, 32, 6, gold_lt)
    fill(im, 12, 16, 40, 20, gold)
    fill(im, 14, 36, 36, 4, gold)
    fill(im, 18, 40, 28, 4, gold_dk)

    # Cup handles
    fill(im, 4, 18, 8, 12, gold)
    fill(im, 4, 18, 4, 16, gold_dk)
    fill(im, 8, 30, 6, 4, gold_dk)

    fill(im, 52, 18, 8, 12, gold)
    fill(im, 56, 18, 4, 16, gold_dk)
    fill(im, 50, 30, 6, 4, gold_dk)

    # Pedestal
    fill(im, 24, 44, 16, 4, gold_dk)
    fill(im, 20, 48, 24, 4, gold)
    fill(im, 16, 52, 32, 6, gold_dk)
    fill(im, 14, 56, 36, 4, gold)

    # Shine
    fill(im, 20, 14, 4, 4, gold_lt)
    fill(im, 18, 16, 2, 2, gold_lt)

    # Gems on trophy
    circle(im, 32, 24, 4, gem_r)
    circle(im, 22, 26, 3, gem_b)
    circle(im, 42, 26, 3, gem_g)

    # Star on top
    fill(im, 30, 4, 4, 6, gold_lt)
    fill(im, 28, 6, 8, 2, gold_lt)

    outline(im, ol)
    save(im, "collector.png")


def gen_cow_brejo():
    """A Vaca Foi Pro Brejo — Farm w/o cow damage. Cow head with no-damage shield."""
    im = img()
    white = c(0.95, 0.92, 0.88)
    brown = c(0.45, 0.3, 0.15)
    brown_dk = c(0.3, 0.18, 0.08)
    pink = c(0.9, 0.6, 0.6)
    black = c(0.12, 0.1, 0.08)
    green = c(0.3, 0.6, 0.2)
    green_dk = c(0.2, 0.4, 0.12)
    shield_b = c(0.2, 0.5, 0.85)
    shield_lt = c(0.4, 0.7, 1.0)
    ol = c(0.18, 0.12, 0.05)

    # Cow face
    fill(im, 16, 16, 32, 28, white)
    fill(im, 14, 20, 4, 16, white)
    fill(im, 46, 20, 4, 16, white)

    # Brown spots
    fill(im, 18, 18, 10, 8, brown)
    fill(im, 40, 20, 8, 6, brown)

    # Eyes
    fill(im, 22, 26, 6, 6, black)
    fill(im, 38, 26, 6, 6, black)
    px(im, 24, 28, white)
    px(im, 40, 28, white)

    # Nose/muzzle
    fill(im, 24, 36, 16, 8, pink)
    fill(im, 28, 38, 3, 3, black)
    fill(im, 35, 38, 3, 3, black)

    # Horns
    fill(im, 14, 12, 6, 8, brown_dk)
    fill(im, 12, 10, 4, 4, brown)
    fill(im, 44, 12, 6, 8, brown_dk)
    fill(im, 48, 10, 4, 4, brown)

    # Ears
    fill(im, 8, 18, 6, 8, brown)
    fill(im, 10, 20, 2, 4, pink)
    fill(im, 50, 18, 6, 8, brown)
    fill(im, 52, 20, 2, 4, pink)

    # Small shield icon bottom-right
    fill(im, 44, 44, 16, 16, shield_b)
    fill(im, 46, 42, 12, 4, shield_b)
    fill(im, 48, 56, 8, 4, shield_b)
    fill(im, 50, 58, 4, 4, shield_b)
    # Checkmark on shield
    px(im, 48, 52, shield_lt)
    px(im, 49, 53, shield_lt)
    px(im, 50, 54, shield_lt)
    px(im, 51, 53, shield_lt)
    px(im, 52, 52, shield_lt)
    px(im, 53, 51, shield_lt)
    px(im, 54, 50, shield_lt)

    outline(im, ol)
    save(im, "cow_brejo.png")


def gen_nobody_deserves():
    """Ninguem Merece — die in 10 sec. Skull with broken timer."""
    im = img()
    bone = c(0.9, 0.88, 0.82)
    bone_dk = c(0.7, 0.65, 0.55)
    red = c(0.85, 0.15, 0.1)
    red_dk = c(0.6, 0.08, 0.05)
    dark = c(0.15, 0.1, 0.08)
    ol = c(0.25, 0.02, 0.02)

    # Skull
    fill(im, 16, 10, 32, 28, bone)
    fill(im, 14, 14, 36, 20, bone)
    fill(im, 18, 8, 28, 6, bone)
    fill(im, 20, 38, 24, 6, bone_dk)

    # Eye sockets
    fill(im, 20, 18, 10, 10, dark)
    fill(im, 34, 18, 10, 10, dark)
    # X eyes (dead)
    for i in range(6):
        px(im, 22 + i, 20 + i, red)
        px(im, 27 - i, 20 + i, red)
        px(im, 36 + i, 20 + i, red)
        px(im, 41 - i, 20 + i, red)

    # Nose
    fill(im, 28, 30, 3, 4, dark)
    fill(im, 33, 30, 3, 4, dark)

    # Teeth
    for i in range(5):
        fill(im, 20 + i * 5, 38, 4, 6, bone)
        fill(im, 20 + i * 5, 42, 4, 2, bone_dk)

    # Broken clock pieces scattered
    fill(im, 4, 4, 8, 8, red_dk)
    fill(im, 6, 6, 4, 4, red)
    fill(im, 52, 4, 8, 8, red_dk)
    fill(im, 54, 6, 4, 4, red)

    # "10s" indicator
    fill(im, 22, 48, 20, 10, red)
    fill(im, 24, 50, 4, 6, bone)  # "1"
    fill(im, 30, 50, 6, 6, bone)  # "0"
    fill(im, 32, 52, 2, 2, red)   # "0" hole
    fill(im, 38, 54, 2, 2, bone)  # "s"

    outline(im, ol)
    save(im, "nobody_deserves.png")


def gen_genocide():
    """Genocidio — 10000 kills. Sword stabbed in pile of skulls."""
    im = img()
    steel = c(0.75, 0.78, 0.82)
    steel_dk = c(0.5, 0.52, 0.58)
    steel_lt = c(0.88, 0.9, 0.95)
    handle = c(0.4, 0.15, 0.1)
    red = c(0.75, 0.1, 0.08)
    red_dk = c(0.5, 0.05, 0.05)
    bone = c(0.8, 0.75, 0.65)
    bone_dk = c(0.6, 0.55, 0.45)
    dark = c(0.12, 0.1, 0.08)
    ol = c(0.18, 0.02, 0.02)

    # Sword blade
    fill(im, 30, 2, 4, 32, steel)
    fill(im, 28, 2, 2, 28, steel_dk)
    fill(im, 34, 2, 2, 28, steel_lt)
    # Sword tip
    fill(im, 30, 2, 4, 4, steel_lt)
    px(im, 31, 0, steel_lt)
    px(im, 32, 0, steel_lt)

    # Cross guard
    fill(im, 22, 34, 20, 4, handle)
    fill(im, 22, 34, 20, 2, c(0.5, 0.2, 0.15))

    # Handle
    fill(im, 29, 38, 6, 10, handle)
    fill(im, 31, 38, 2, 10, c(0.5, 0.22, 0.15))

    # Pommel
    circle(im, 32, 50, 4, c(0.7, 0.2, 0.15))

    # Skull pile at base
    # Left skull
    circle(im, 14, 52, 8, bone)
    fill(im, 10, 48, 4, 4, dark)
    fill(im, 16, 48, 4, 4, dark)
    fill(im, 12, 56, 6, 2, bone_dk)

    # Right skull
    circle(im, 50, 52, 8, bone)
    fill(im, 46, 48, 4, 4, dark)
    fill(im, 52, 48, 4, 4, dark)
    fill(im, 48, 56, 6, 2, bone_dk)

    # Center skull (behind sword)
    circle(im, 32, 56, 6, bone_dk)
    fill(im, 30, 54, 2, 2, dark)
    fill(im, 34, 54, 2, 2, dark)

    # Blood drips on sword
    fill(im, 30, 18, 2, 4, red)
    fill(im, 33, 24, 2, 6, red)
    fill(im, 28, 28, 2, 4, red_dk)

    outline(im, ol)
    save(im, "genocide.png")


def gen_sweet_revenge():
    """Doce Vinganca — complete Candy stage. Candy with bite mark + victory."""
    im = img()
    pink = c(0.95, 0.45, 0.65)
    pink_dk = c(0.75, 0.3, 0.45)
    pink_lt = c(1.0, 0.6, 0.8)
    white = c(0.95, 0.92, 0.88)
    yellow = c(1.0, 0.9, 0.3)
    brown = c(0.5, 0.3, 0.15)
    ol = c(0.3, 0.1, 0.15)

    # Lollipop stick
    fill(im, 30, 38, 4, 22, brown)
    fill(im, 32, 38, 2, 22, c(0.6, 0.38, 0.2))

    # Candy circle
    circle(im, 32, 24, 18, pink)
    circle(im, 32, 24, 14, pink_lt)
    circle(im, 32, 24, 10, pink)

    # Swirl pattern
    fill(im, 26, 18, 4, 4, white)
    fill(im, 34, 14, 4, 4, white)
    fill(im, 38, 22, 4, 4, white)
    fill(im, 34, 30, 4, 4, white)
    fill(im, 26, 28, 4, 4, white)
    fill(im, 22, 22, 4, 4, white)

    # Bite mark (chunk missing from right)
    fill(im, 42, 16, 10, 14, (0, 0, 0, 0))
    fill(im, 44, 18, 6, 10, (0, 0, 0, 0))

    # Victory stars
    fill(im, 4, 6, 6, 2, yellow)
    fill(im, 6, 4, 2, 6, yellow)
    fill(im, 52, 8, 6, 2, yellow)
    fill(im, 54, 6, 2, 6, yellow)
    fill(im, 8, 50, 4, 2, yellow)
    fill(im, 9, 49, 2, 4, yellow)

    outline(im, ol)
    save(im, "sweet_revenge.png")


def gen_storm():
    """I Am The Storm — 3 electric evolved weapons. Triple lightning."""
    im = img()
    yellow = c(1.0, 0.9, 0.2)
    yellow_dk = c(0.85, 0.7, 0.1)
    yellow_lt = c(1.0, 1.0, 0.6)
    blue = c(0.3, 0.5, 0.9)
    blue_dk = c(0.15, 0.3, 0.7)
    white = c(0.98, 0.98, 1.0)
    ol = c(0.18, 0.18, 0.22)

    # Storm cloud
    fill(im, 8, 4, 48, 12, blue_dk)
    fill(im, 12, 2, 40, 4, blue)
    fill(im, 4, 8, 8, 8, blue)
    fill(im, 52, 8, 8, 8, blue)
    fill(im, 16, 12, 32, 6, blue_dk)

    # Cloud highlights
    fill(im, 16, 4, 12, 4, blue)
    fill(im, 36, 4, 12, 4, blue)

    # Lightning bolt 1 (left)
    fill(im, 14, 18, 6, 8, yellow)
    fill(im, 10, 26, 8, 4, yellow_lt)
    fill(im, 14, 30, 6, 8, yellow)
    fill(im, 10, 38, 6, 6, yellow_dk)
    fill(im, 8, 44, 4, 6, yellow)

    # Lightning bolt 2 (center, bigger)
    fill(im, 30, 18, 8, 8, yellow_lt)
    fill(im, 24, 26, 12, 4, white)
    fill(im, 30, 30, 8, 8, yellow)
    fill(im, 24, 38, 10, 4, yellow_lt)
    fill(im, 28, 42, 8, 8, yellow)
    fill(im, 26, 50, 6, 8, yellow_dk)
    fill(im, 28, 56, 4, 6, yellow)

    # Lightning bolt 3 (right)
    fill(im, 46, 18, 6, 8, yellow)
    fill(im, 44, 26, 8, 4, yellow_lt)
    fill(im, 46, 30, 6, 8, yellow)
    fill(im, 48, 38, 6, 6, yellow_dk)
    fill(im, 50, 44, 4, 6, yellow)

    # Electric sparks
    px(im, 6, 22, white)
    px(im, 56, 24, white)
    px(im, 22, 46, white)
    px(im, 42, 48, white)

    outline(im, ol)
    save(im, "storm.png")


def gen_pacifist():
    """Pacifista — survive 3 min w/o attacking. Dove/peace symbol."""
    im = img()
    white = c(0.95, 0.95, 0.98)
    white_dk = c(0.8, 0.82, 0.88)
    blue = c(0.4, 0.55, 0.85)
    blue_lt = c(0.6, 0.75, 1.0)
    green = c(0.3, 0.7, 0.25)
    green_dk = c(0.2, 0.5, 0.15)
    beak = c(0.9, 0.7, 0.2)
    eye = c(0.12, 0.12, 0.15)
    ol = c(0.35, 0.35, 0.4)

    # Dove body
    fill(im, 18, 24, 28, 20, white)
    fill(im, 16, 28, 32, 12, white)
    fill(im, 22, 22, 20, 4, white)

    # Head
    circle(im, 42, 22, 8, white)
    circle(im, 42, 22, 6, white_dk)

    # Eye
    fill(im, 44, 20, 3, 3, eye)
    px(im, 45, 21, c(0.5, 0.5, 0.6))

    # Beak
    fill(im, 50, 22, 6, 3, beak)
    fill(im, 54, 23, 4, 2, c(0.8, 0.6, 0.15))

    # Wing (raised)
    fill(im, 10, 12, 22, 12, white)
    fill(im, 8, 10, 18, 6, white_dk)
    fill(im, 6, 8, 14, 4, white)
    # Wing feather detail
    fill(im, 8, 14, 4, 6, white_dk)
    fill(im, 14, 12, 4, 6, white_dk)
    fill(im, 20, 14, 4, 4, white_dk)

    # Tail
    fill(im, 8, 32, 10, 8, white_dk)
    fill(im, 4, 34, 6, 6, white)

    # Olive branch
    fill(im, 50, 30, 8, 2, green_dk)
    fill(im, 56, 28, 4, 2, green)
    fill(im, 54, 26, 4, 4, green)
    fill(im, 58, 30, 4, 4, green)
    fill(im, 52, 32, 4, 4, green)

    # Peace glow
    circle(im, 32, 52, 6, blue_lt)
    circle(im, 32, 52, 4, blue)
    line_v(im, 32, 47, 57, white)
    line_h(im, 27, 37, 52, white)

    outline(im, ol)
    save(im, "pacifist.png")


def gen_matrix():
    """Matrix — dodge 100 projectiles. Silhouette dodging with green rain."""
    im = img()
    green = c(0.0, 0.85, 0.15)
    green_dk = c(0.0, 0.55, 0.08)
    green_lt = c(0.3, 1.0, 0.4)
    dark = c(0.02, 0.06, 0.02)
    silhouette = c(0.05, 0.12, 0.05)
    ol = c(0.0, 0.25, 0.02)

    # Dark background
    fill(im, 0, 0, 64, 64, dark)

    # Matrix rain columns
    import random
    random.seed(42)  # deterministic
    for col in range(0, 64, 4):
        length = random.randint(4, 12)
        start = random.randint(0, 50)
        for row in range(start, min(start + length * 3, 64), 3):
            brightness = max(0.2, 1.0 - (row - start) / (length * 3))
            g = c(0.0, brightness * 0.85, 0.0, int(brightness * 200))
            fill(im, col, row, 2, 2, g)

    # Silhouette figure in dodge pose (leaning back)
    # Torso leaning back
    fill(im, 26, 20, 8, 16, silhouette)
    fill(im, 24, 22, 4, 12, silhouette)
    # Head
    circle(im, 30, 16, 5, silhouette)
    # Legs spread
    fill(im, 22, 36, 6, 14, silhouette)
    fill(im, 32, 36, 6, 14, silhouette)
    # Arms out
    fill(im, 16, 22, 8, 4, silhouette)
    fill(im, 34, 24, 10, 4, silhouette)

    # Bullet trails (projectiles being dodged)
    for y_pos in [18, 26, 34]:
        for x in range(44, 58, 2):
            px(im, x, y_pos, green_lt)
            px(im, x + 1, y_pos, green)

    # Green highlight on figure edges
    for y in range(14, 52):
        for x in range(14, 50):
            if 0 <= x < S and 0 <= y < S:
                p = im.getpixel((x, y))
                if p == silhouette:
                    # Check if edge
                    for dx, dy in [(-1, 0), (1, 0)]:
                        nx = x + dx
                        if 0 <= nx < S:
                            np = im.getpixel((nx, y))
                            if np != silhouette:
                                px(im, x, y, green_dk)

    save(im, "matrix.png")


def gen_one_punch():
    """One Punch — kill boss with 1 hit. Giant fist with impact."""
    im = img()
    skin = c(0.9, 0.72, 0.55)
    skin_dk = c(0.7, 0.52, 0.35)
    skin_lt = c(1.0, 0.82, 0.65)
    red = c(0.9, 0.2, 0.1)
    red_lt = c(1.0, 0.4, 0.2)
    yellow = c(1.0, 0.9, 0.3)
    white = c(1.0, 1.0, 1.0)
    ol = c(0.3, 0.08, 0.05)

    # Fist (front view, punching forward)
    # Main fist body
    fill(im, 14, 16, 36, 28, skin)
    fill(im, 12, 20, 4, 20, skin)
    fill(im, 48, 20, 4, 20, skin)

    # Fingers (curled)
    fill(im, 14, 14, 8, 6, skin)
    fill(im, 24, 12, 8, 6, skin)
    fill(im, 34, 14, 8, 6, skin)
    fill(im, 44, 16, 6, 6, skin)

    # Knuckle highlights
    fill(im, 16, 16, 6, 4, skin_lt)
    fill(im, 26, 14, 6, 4, skin_lt)
    fill(im, 36, 16, 6, 4, skin_lt)

    # Thumb
    fill(im, 10, 34, 8, 10, skin_dk)
    fill(im, 12, 36, 4, 6, skin)

    # Wrist
    fill(im, 20, 44, 24, 10, skin_dk)
    fill(im, 22, 46, 20, 6, skin)

    # Knuckle shadows
    fill(im, 14, 20, 36, 2, skin_dk)

    # Impact lines
    # Top-left
    for i in range(3):
        x1, y1 = 2 + i * 2, 2 + i * 2
        x2, y2 = 8 + i, 8 + i
        line_h(im, x1, x2, y1, yellow)
        line_v(im, x1, y1, y2, yellow)

    # Top-right
    for i in range(3):
        line_h(im, 54 - i, 62 - i * 2, 2 + i * 2, yellow)

    # Stars/sparkles
    fill(im, 4, 52, 4, 2, red_lt)
    fill(im, 5, 51, 2, 4, red_lt)
    fill(im, 56, 50, 4, 2, red_lt)
    fill(im, 57, 49, 2, 4, red_lt)

    # Impact burst behind
    fill(im, 0, 28, 6, 4, red)
    fill(im, 58, 26, 6, 4, red)

    outline(im, ol)
    save(im, "one_punch.png")


def gen_lucky_day():
    """Lucky Day — 5 legendary items. Four-leaf clover with sparkles."""
    im = img()
    green = c(0.15, 0.7, 0.2)
    green_dk = c(0.08, 0.5, 0.12)
    green_lt = c(0.3, 0.85, 0.35)
    gold = c(1.0, 0.85, 0.2)
    gold_lt = c(1.0, 0.95, 0.5)
    stem = c(0.1, 0.45, 0.08)
    ol = c(0.3, 0.25, 0.05)

    # Stem
    fill(im, 30, 38, 4, 20, stem)
    fill(im, 28, 56, 8, 4, stem)
    fill(im, 32, 40, 2, 16, c(0.15, 0.55, 0.12))

    # Four leaves
    # Top leaf
    fill(im, 24, 8, 16, 14, green)
    fill(im, 26, 6, 12, 4, green)
    fill(im, 28, 10, 8, 4, green_lt)

    # Bottom leaf
    fill(im, 24, 34, 16, 14, green)
    fill(im, 26, 46, 12, 4, green)
    fill(im, 28, 38, 8, 4, green_lt)

    # Left leaf
    fill(im, 8, 16, 14, 16, green)
    fill(im, 6, 20, 4, 8, green)
    fill(im, 12, 20, 4, 8, green_lt)

    # Right leaf
    fill(im, 42, 16, 14, 16, green)
    fill(im, 54, 20, 4, 8, green)
    fill(im, 46, 20, 4, 8, green_lt)

    # Center
    circle(im, 32, 28, 4, green_dk)

    # Leaf veins (center lines)
    line_v(im, 32, 8, 20, green_dk)
    line_v(im, 32, 36, 48, green_dk)
    line_h(im, 10, 20, 24, green_dk)
    line_h(im, 44, 54, 24, green_dk)

    # Gold sparkles around
    for sx, sy in [(4, 4), (56, 6), (60, 36), (2, 42), (52, 54), (10, 56)]:
        fill(im, sx, sy, 4, 2, gold)
        fill(im, sx + 1, sy - 1, 2, 4, gold)

    # Central sparkle
    fill(im, 30, 26, 4, 2, gold_lt)
    fill(im, 31, 25, 2, 4, gold_lt)

    outline(im, ol)
    save(im, "lucky_day.png")


if __name__ == "__main__":
    gen_first_walk()
    gen_evolved_6()
    gen_speedrunner()
    gen_collector()
    gen_cow_brejo()
    gen_nobody_deserves()
    gen_genocide()
    gen_sweet_revenge()
    gen_storm()
    gen_pacifist()
    gen_matrix()
    gen_one_punch()
    gen_lucky_day()
    print(f"\nGenerated 13 achievement sprites at 64x64 in {OUT}")
