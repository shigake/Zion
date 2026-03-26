import bpy
import bmesh
import math
import os
from mathutils import Matrix, Vector

OUT = "C:/Users/shiga/projects/Zion/game/assets/models/weapons"

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
# 21. necro_tome.glb
# ============================================================
clear()
# Book cover (slightly open)
dark_cover = mat("DarkCover", (0.08, 0.06, 0.08, 1))
green_pages = mat("GreenPages", (0.3, 0.8, 0.3, 1), emission=(0.2, 0.9, 0.2, 1), emission_strength=2.0)

# Back cover
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
back = bpy.context.active_object
back.scale = (0.12, 0.14, 0.01)
back.name = "BackCover"
assign_mat(back, dark_cover)

# Front cover (tilted open)
bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.08, 0, 0.05))
front = bpy.context.active_object
front.scale = (0.12, 0.14, 0.01)
front.rotation_euler.y = math.radians(30)
front.name = "FrontCover"
assign_mat(front, dark_cover)

# Pages (green glow)
bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.03, 0, 0.02))
pages = bpy.context.active_object
pages.scale = (0.1, 0.12, 0.015)
pages.rotation_euler.y = math.radians(15)
pages.name = "Pages"
assign_mat(pages, green_pages)

# Spine
bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=0.28, location=(0.12, 0, 0.01))
spine = bpy.context.active_object
spine.rotation_euler.x = math.radians(90)
spine.name = "Spine"
assign_mat(spine, dark_cover)

export("necro_tome.glb")

# ============================================================
# 22. drone.glb
# ============================================================
clear()
blue_metal = mat("BlueMetal", (0.3, 0.45, 0.7, 1))
dark = mat("Dark", (0.15, 0.15, 0.18, 1))
led = mat("LED", (0.2, 0.9, 0.3, 1), emission=(0.2, 1.0, 0.3, 1), emission_strength=3.0)

# Body
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
body = bpy.context.active_object
body.scale = (0.08, 0.08, 0.03)
body.name = "Body"
assign_mat(body, blue_metal)

# 4 rotor arms + rotors
for i, (dx, dy) in enumerate([(1,1), (1,-1), (-1,1), (-1,-1)]):
    ax = dx * 0.1
    ay = dy * 0.1
    # Arm
    bpy.ops.mesh.primitive_cylinder_add(radius=0.008, depth=0.1, location=(ax*0.5, ay*0.5, 0))
    arm = bpy.context.active_object
    arm.rotation_euler.x = math.radians(90) if dy != 0 else 0
    angle = math.atan2(ay, ax)
    arm.rotation_euler.z = angle
    arm.name = f"Arm{i}"
    assign_mat(arm, dark)

    # Rotor
    bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.005, location=(ax, ay, 0.02))
    rotor = bpy.context.active_object
    rotor.name = f"Rotor{i}"
    assign_mat(rotor, dark)

# LED
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.015, location=(0, 0, -0.025))
led_obj = bpy.context.active_object
led_obj.name = "LED"
assign_mat(led_obj, led)

export("drone.glb")

# ============================================================
# 23. totem.glb
# ============================================================
clear()
wood = mat("Wood", (0.45, 0.3, 0.15, 1))
white = mat("White", (0.9, 0.9, 0.85, 1))
red = mat("Red", (0.8, 0.15, 0.1, 1))

# Pole
bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.4, location=(0, 0, 0))
pole = bpy.context.active_object
pole.name = "Pole"
assign_mat(pole, wood)

# Left eye
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.02, location=(-0.025, 0.03, 0.12))
eye_l = bpy.context.active_object
eye_l.name = "EyeL"
assign_mat(eye_l, white)

# Right eye
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.02, location=(0.025, 0.03, 0.12))
eye_r = bpy.context.active_object
eye_r.name = "EyeR"
assign_mat(eye_r, white)

# Mouth
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.035, 0.05))
mouth = bpy.context.active_object
mouth.scale = (0.03, 0.01, 0.015)
mouth.name = "Mouth"
assign_mat(mouth, red)

# Top decoration
bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.05, depth=0.06, location=(0, 0, 0.23))
top = bpy.context.active_object
top.name = "Top"
assign_mat(top, wood)

export("totem.glb")

# ============================================================
# 24. poison_bottle.glb
# ============================================================
clear()
green_glass = mat("GreenGlass", (0.2, 0.7, 0.25, 1), emission=(0.15, 0.6, 0.2, 1), emission_strength=1.0)
cork_mat = mat("Cork", (0.6, 0.45, 0.25, 1))

# Bottle body
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.08, location=(0, 0, 0))
body = bpy.context.active_object
body.scale = (1, 1, 0.85)
body.name = "Body"
assign_mat(body, green_glass)

# Neck
bpy.ops.mesh.primitive_cylinder_add(radius=0.025, depth=0.08, location=(0, 0, 0.1))
neck = bpy.context.active_object
neck.name = "Neck"
assign_mat(neck, green_glass)

# Cork
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.028, location=(0, 0, 0.15))
cork = bpy.context.active_object
cork.name = "Cork"
assign_mat(cork, cork_mat)

export("poison_bottle.glb")

# ============================================================
# 25. lightning_orb.glb
# ============================================================
clear()
yellow_glow = mat("YellowGlow", (1, 0.9, 0.3, 1), emission=(1, 0.85, 0.2, 1), emission_strength=3.0)
white_spark = mat("WhiteSpark", (1, 1, 0.9, 1), emission=(1, 1, 0.8, 1), emission_strength=4.0)

# Main orb
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.08, location=(0, 0, 0))
orb = bpy.context.active_object
orb.name = "Orb"
assign_mat(orb, yellow_glow)

# Electric arc spikes
for i in range(8):
    phi = math.radians(i * 45)
    theta = math.radians(30 + (i % 3) * 30)
    x = math.sin(theta) * math.cos(phi) * 0.08
    y = math.sin(theta) * math.sin(phi) * 0.08
    z = math.cos(theta) * 0.08
    bpy.ops.mesh.primitive_cylinder_add(radius=0.004, depth=0.12, location=(x*1.5, y*1.5, z*1.5))
    spike = bpy.context.active_object
    # Point outward
    spike.rotation_euler.x = theta
    spike.rotation_euler.z = phi
    spike.name = f"Arc{i}"
    assign_mat(spike, white_spark)

export("lightning_orb.glb")

# ============================================================
# 26. magic_book.glb
# ============================================================
clear()
gold = mat("Gold", (0.8, 0.65, 0.2, 1))
page = mat("Page", (0.95, 0.92, 0.82, 1))
brown = mat("Brown", (0.5, 0.35, 0.18, 1))

# Left page (tilted)
bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.06, 0, 0.02))
left = bpy.context.active_object
left.scale = (0.1, 0.13, 0.003)
left.rotation_euler.y = math.radians(-15)
left.name = "LeftPage"
assign_mat(left, page)

# Right page (tilted)
bpy.ops.mesh.primitive_cube_add(size=1, location=(0.06, 0, 0.02))
right = bpy.context.active_object
right.scale = (0.1, 0.13, 0.003)
right.rotation_euler.y = math.radians(15)
right.name = "RightPage"
assign_mat(right, page)

# Spine
bpy.ops.mesh.primitive_cylinder_add(radius=0.015, depth=0.26, location=(0, 0, 0))
spine = bpy.context.active_object
spine.rotation_euler.x = math.radians(90)
spine.name = "Spine"
assign_mat(spine, brown)

# Gold corner accents
for (x, y) in [(-0.1, 0.12), (-0.1, -0.12), (0.1, 0.12), (0.1, -0.12)]:
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, 0.03))
    accent = bpy.context.active_object
    accent.scale = (0.012, 0.012, 0.006)
    accent.name = f"Accent_{x}_{y}"
    assign_mat(accent, gold)

export("magic_book.glb")

# ============================================================
# 27. time_bomb.glb
# ============================================================
clear()
black = mat("Black", (0.08, 0.08, 0.08, 1))
gold_clock = mat("GoldClock", (0.85, 0.75, 0.2, 1))
white_face = mat("WhiteFace", (0.9, 0.9, 0.88, 1))

# Bomb sphere
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.1, location=(0, 0, 0))
bomb = bpy.context.active_object
bomb.name = "Bomb"
assign_mat(bomb, black)

# Clock face (flat cylinder on front)
bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.01, location=(0, 0.1, 0))
face = bpy.context.active_object
face.rotation_euler.x = math.radians(90)
face.name = "ClockFace"
assign_mat(face, white_face)

# Clock rim
bpy.ops.mesh.primitive_torus_add(major_radius=0.062, minor_radius=0.005, location=(0, 0.105, 0))
rim = bpy.context.active_object
rim.rotation_euler.x = math.radians(90)
rim.name = "ClockRim"
assign_mat(rim, gold_clock)

# Clock hands
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.11, 0.015))
hand1 = bpy.context.active_object
hand1.scale = (0.003, 0.003, 0.04)
hand1.name = "HourHand"
assign_mat(hand1, black)

bpy.ops.mesh.primitive_cube_add(size=1, location=(0.01, 0.11, 0))
hand2 = bpy.context.active_object
hand2.scale = (0.03, 0.003, 0.003)
hand2.name = "MinuteHand"
assign_mat(hand2, black)

# Fuse
bpy.ops.mesh.primitive_cylinder_add(radius=0.008, depth=0.06, location=(0, 0, 0.12))
fuse = bpy.context.active_object
fuse.rotation_euler.x = math.radians(15)
fuse.name = "Fuse"
fuse_mat = mat("Fuse", (0.5, 0.4, 0.2, 1))
assign_mat(fuse, fuse_mat)

export("time_bomb.glb")

# ============================================================
# 28. portal.glb
# ============================================================
clear()
purple_ring = mat("PurpleRing", (0.4, 0.15, 0.6, 1), emission=(0.5, 0.2, 0.8, 1), emission_strength=2.0)
blue_energy = mat("BlueEnergy", (0.3, 0.4, 0.9, 1), emission=(0.4, 0.5, 1.0, 1), emission_strength=3.0)

# Torus ring
bpy.ops.mesh.primitive_torus_add(major_radius=0.15, minor_radius=0.02, location=(0, 0, 0))
ring = bpy.context.active_object
ring.name = "Ring"
assign_mat(ring, purple_ring)

# Inner glow disc
bpy.ops.mesh.primitive_cylinder_add(radius=0.13, depth=0.005, location=(0, 0, 0))
disc = bpy.context.active_object
disc.name = "InnerGlow"
assign_mat(disc, blue_energy)

# Small orbiting spheres for energy effect
for i in range(6):
    angle = math.radians(i * 60)
    x = math.cos(angle) * 0.15
    y = math.sin(angle) * 0.15
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.012, location=(x, y, 0))
    orb = bpy.context.active_object
    orb.name = f"EnergyOrb{i}"
    assign_mat(orb, blue_energy)

export("portal.glb")

print("=== ALL SUMMON WEAPONS DONE ===")
