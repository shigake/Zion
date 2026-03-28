import bpy
import bmesh
import math
import os
from mathutils import Matrix, Vector

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "assets", "models", "weapons")

def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def mat(name, color, emission=None, emission_strength=0.5):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = color
    if emission:
        bsdf.inputs["Emission Color"].default_value = emission
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return m

def assign_mat(obj, material):
    obj.data.materials.append(material)

def export(name):
    path = os.path.join(OUT, name)
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=False)
    print(f"Exported: {path}")

# ============================================================
# 11. machinegun.glb
# ============================================================
clear()
dark_metal = mat("DarkMetal", (0.25, 0.25, 0.28, 1))

# Body
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
body = bpy.context.active_object
body.scale = (0.08, 0.06, 0.25)
body.name = "Body"
assign_mat(body, dark_metal)

# Barrel
bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=0.35, location=(0, 0, 0.3))
barrel = bpy.context.active_object
barrel.name = "Barrel"
assign_mat(barrel, dark_metal)

# Drum magazine
bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.06, location=(0, -0.06, -0.05))
drum = bpy.context.active_object
drum.rotation_euler.x = math.radians(90)
drum.name = "Drum"
assign_mat(drum, dark_metal)

# Stock
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.02, -0.22))
stock = bpy.context.active_object
stock.scale = (0.03, 0.04, 0.08)
stock.name = "Stock"
wood = mat("Wood", (0.4, 0.28, 0.14, 1))
assign_mat(stock, wood)

export("machinegun.glb")

# ============================================================
# 12. staff.glb
# ============================================================
clear()
# Shaft
bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=1.0, location=(0, 0, 0))
shaft = bpy.context.active_object
shaft.name = "Shaft"
wood = mat("Wood", (0.45, 0.3, 0.15, 1))
assign_mat(shaft, wood)

# Orb
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.07, location=(0, 0, 0.55))
orb = bpy.context.active_object
orb.name = "Orb"
blue_glow = mat("BlueGlow", (0.2, 0.4, 0.9, 1), emission=(0.3, 0.5, 1.0, 1), emission_strength=3.0)
assign_mat(orb, blue_glow)

# Cradle prongs
for angle in [0, 120, 240]:
    rad = math.radians(angle)
    x = math.cos(rad) * 0.03
    y = math.sin(rad) * 0.03
    bpy.ops.mesh.primitive_cylinder_add(radius=0.008, depth=0.12, location=(x, y, 0.48))
    prong = bpy.context.active_object
    prong.rotation_euler.x = math.cos(rad) * math.radians(15)
    prong.rotation_euler.y = math.sin(rad) * math.radians(15)
    prong.name = f"Prong{angle}"
    assign_mat(prong, wood)

export("staff.glb")

# ============================================================
# 13. bazooka.glb
# ============================================================
clear()
# Main tube
bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.8, location=(0, 0, 0))
tube = bpy.context.active_object
tube.rotation_euler.x = math.radians(90)
tube.name = "Tube"
green = mat("MilGreen", (0.3, 0.38, 0.22, 1))
assign_mat(tube, green)

# Sight
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.07, 0.1))
sight = bpy.context.active_object
sight.scale = (0.015, 0.03, 0.04)
sight.name = "Sight"
assign_mat(sight, green)

# Handle/grip
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.06, -0.05))
grip = bpy.context.active_object
grip.scale = (0.02, 0.05, 0.03)
grip.name = "Grip"
dark = mat("Dark", (0.15, 0.15, 0.15, 1))
assign_mat(grip, dark)

export("bazooka.glb")

# ============================================================
# 14. shuriken.glb
# ============================================================
clear()
silver = mat("Silver", (0.75, 0.75, 0.8, 1))

# 4 triangular prism blades arranged as star
for i in range(4):
    angle = math.radians(i * 90)
    x = math.cos(angle) * 0.08
    z = math.sin(angle) * 0.08
    bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=0.08, depth=0.015, location=(x, 0, z))
    blade = bpy.context.active_object
    blade.rotation_euler.x = math.radians(90)
    blade.rotation_euler.z = angle + math.radians(90)
    blade.name = f"Blade{i}"
    assign_mat(blade, silver)

# Center disc
bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=0.02, location=(0, 0, 0))
center = bpy.context.active_object
center.rotation_euler.x = math.radians(90)
center.name = "Center"
assign_mat(center, silver)

export("shuriken.glb")

# ============================================================
# 15. dual_pistol.glb
# ============================================================
clear()
metal = mat("Metal", (0.4, 0.4, 0.42, 1))
wood = mat("Wood", (0.5, 0.35, 0.18, 1))

for side, sx in [("L", -0.08), ("R", 0.08)]:
    # Gun body
    bpy.ops.mesh.primitive_cube_add(size=1, location=(sx, 0, 0))
    body = bpy.context.active_object
    body.scale = (0.03, 0.04, 0.12)
    body.name = f"Body{side}"
    assign_mat(body, metal)

    # Barrel
    bpy.ops.mesh.primitive_cylinder_add(radius=0.012, depth=0.1, location=(sx, 0, 0.11))
    barrel = bpy.context.active_object
    barrel.name = f"Barrel{side}"
    assign_mat(barrel, metal)

    # Grip
    bpy.ops.mesh.primitive_cube_add(size=1, location=(sx, 0.01, -0.1))
    grip = bpy.context.active_object
    grip.scale = (0.025, 0.035, 0.06)
    grip.rotation_euler.x = math.radians(15)
    grip.name = f"Grip{side}"
    assign_mat(grip, wood)

export("dual_pistol.glb")

# ============================================================
# 16. flamethrower.glb
# ============================================================
clear()
# Tank
bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.25, location=(0, -0.04, -0.1))
tank = bpy.context.active_object
tank.name = "Tank"
red = mat("Red", (0.75, 0.15, 0.1, 1))
assign_mat(tank, red)

# Nozzle
bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=0.4, location=(0, 0, 0.15))
nozzle = bpy.context.active_object
nozzle.name = "Nozzle"
black = mat("Black", (0.1, 0.1, 0.1, 1))
assign_mat(nozzle, black)

# Nozzle tip (wider)
bpy.ops.mesh.primitive_cone_add(radius1=0.04, radius2=0.02, depth=0.06, location=(0, 0, 0.38))
tip = bpy.context.active_object
tip.name = "NozzleTip"
assign_mat(tip, black)

# Pilot light
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.015, location=(0, 0.03, 0.35))
light = bpy.context.active_object
light.name = "PilotLight"
flame = mat("Flame", (1, 0.6, 0.1, 1), emission=(1, 0.5, 0.1, 1), emission_strength=3.0)
assign_mat(light, flame)

export("flamethrower.glb")

# ============================================================
# 17. ice_staff.glb
# ============================================================
clear()
# Shaft
bpy.ops.mesh.primitive_cylinder_add(radius=0.018, depth=0.9, location=(0, 0, 0))
shaft = bpy.context.active_object
shaft.name = "Shaft"
ice_blue = mat("IceBlue", (0.6, 0.75, 0.9, 1))
assign_mat(shaft, ice_blue)

# Crystal top - icosphere
bpy.ops.mesh.primitive_ico_sphere_add(radius=0.08, subdivisions=1, location=(0, 0, 0.5))
crystal = bpy.context.active_object
crystal.name = "Crystal"
blue_crystal = mat("BlueCrystal", (0.3, 0.5, 0.95, 1), emission=(0.4, 0.6, 1.0, 1), emission_strength=2.5)
assign_mat(crystal, blue_crystal)

# Small ice shards
for i, (x, z) in enumerate([(0.04, 0.35), (-0.04, 0.38), (0.02, 0.33)]):
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.015, depth=0.08, location=(x, 0, z))
    shard = bpy.context.active_object
    shard.rotation_euler.x = math.radians(20 * (i - 1))
    shard.name = f"Shard{i}"
    assign_mat(shard, blue_crystal)

export("ice_staff.glb")

# ============================================================
# 18. crossbow.glb
# ============================================================
clear()
wood = mat("Wood", (0.45, 0.3, 0.14, 1))
metal = mat("Metal", (0.5, 0.5, 0.52, 1))

# Frame body
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
frame = bpy.context.active_object
frame.scale = (0.03, 0.04, 0.2)
frame.name = "Frame"
assign_mat(frame, wood)

# Limb left
bpy.ops.mesh.primitive_cylinder_add(radius=0.012, depth=0.25, location=(-0.12, 0, 0.15))
limb_l = bpy.context.active_object
limb_l.rotation_euler.z = math.radians(70)
limb_l.name = "LimbL"
assign_mat(limb_l, wood)

# Limb right
bpy.ops.mesh.primitive_cylinder_add(radius=0.012, depth=0.25, location=(0.12, 0, 0.15))
limb_r = bpy.context.active_object
limb_r.rotation_euler.z = math.radians(-70)
limb_r.name = "LimbR"
assign_mat(limb_r, wood)

# String (thin cylinder)
bpy.ops.mesh.primitive_cylinder_add(radius=0.003, depth=0.3, location=(0, 0, 0.18))
string = bpy.context.active_object
string.rotation_euler.y = math.radians(90)
string.name = "String"
string_mat = mat("String", (0.8, 0.75, 0.65, 1))
assign_mat(string, string_mat)

# Grip
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, -0.15))
grip = bpy.context.active_object
grip.scale = (0.025, 0.04, 0.06)
grip.name = "Grip"
assign_mat(grip, wood)

export("crossbow.glb")

# ============================================================
# 19. plasma_cannon.glb
# ============================================================
clear()
dark_metal = mat("DarkMetal", (0.2, 0.2, 0.25, 1))
blue_glow = mat("BlueGlow", (0.2, 0.5, 1.0, 1), emission=(0.3, 0.6, 1.0, 1), emission_strength=3.0)

# Main body cylinder
bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.5, location=(0, 0, 0))
body = bpy.context.active_object
body.name = "Body"
assign_mat(body, dark_metal)

# Glowing tube
bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=0.55, location=(0, 0, 0))
glow_tube = bpy.context.active_object
glow_tube.name = "GlowTube"
assign_mat(glow_tube, blue_glow)

# Front ring
bpy.ops.mesh.primitive_torus_add(major_radius=0.065, minor_radius=0.01, location=(0, 0, 0.25))
ring = bpy.context.active_object
ring.name = "FrontRing"
assign_mat(ring, dark_metal)

# Grip
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.06, -0.1))
grip = bpy.context.active_object
grip.scale = (0.025, 0.04, 0.06)
grip.name = "Grip"
assign_mat(grip, dark_metal)

export("plasma_cannon.glb")

# ============================================================
# 20. elven_bow.glb
# ============================================================
clear()
wood = mat("LightWood", (0.65, 0.5, 0.3, 1))
green_accent = mat("GreenRune", (0.2, 0.7, 0.3, 1), emission=(0.2, 0.8, 0.3, 1), emission_strength=1.5)

# Curved bow - approximate with segments
for i in range(8):
    t = (i - 3.5) / 3.5
    angle = t * math.radians(60)
    x = math.sin(angle) * 0.3
    z = math.cos(angle) * 0.3 - 0.05
    bpy.ops.mesh.primitive_cylinder_add(radius=0.012, depth=0.1, location=(x, 0, z))
    seg = bpy.context.active_object
    seg.rotation_euler.y = angle
    seg.name = f"BowSeg{i}"
    assign_mat(seg, wood)

# String
bpy.ops.mesh.primitive_cylinder_add(radius=0.003, depth=0.55, location=(0, 0, 0))
string = bpy.context.active_object
string.name = "String"
string_mat = mat("String", (0.8, 0.78, 0.7, 1))
assign_mat(string, string_mat)

# Green rune accents
for z in [-0.1, 0.0, 0.1]:
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.28, 0, z))
    rune = bpy.context.active_object
    rune.scale = (0.008, 0.008, 0.02)
    rune.name = f"Rune{z}"
    assign_mat(rune, green_accent)

export("elven_bow.glb")

print("=== ALL RANGED WEAPONS DONE ===")
