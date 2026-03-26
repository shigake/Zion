import bpy
import bmesh
import math
import os
import sys
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
# 1. katana.glb
# ============================================================
clear()
# Blade - thin flat box, slightly sheared
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.45))
blade = bpy.context.active_object
blade.scale = (0.03, 0.12, 0.5)
blade.name = "Blade"
# Slight curve via shear
blade.rotation_euler.y = math.radians(5)
silver = mat("Silver", (0.85, 0.85, 0.9, 1))
assign_mat(blade, silver)

# Guard - disc
bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.015, location=(0, 0, -0.05))
guard = bpy.context.active_object
guard.name = "Guard"
gold = mat("Gold", (0.8, 0.7, 0.2, 1))
assign_mat(guard, gold)

# Handle - cylinder
bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=0.25, location=(0, 0, -0.18))
handle = bpy.context.active_object
handle.name = "Handle"
dark = mat("DarkHandle", (0.15, 0.1, 0.08, 1))
assign_mat(handle, dark)

export("katana.glb")

# ============================================================
# 2. scythe.glb
# ============================================================
clear()
# Long handle
bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=1.2, location=(0, 0, 0))
handle = bpy.context.active_object
handle.name = "Handle"
dark_h = mat("DarkHandle", (0.12, 0.08, 0.06, 1))
assign_mat(handle, dark_h)

# Blade - curved arc (flattened torus segment approximation using a box)
bpy.ops.mesh.primitive_cube_add(size=1, location=(0.15, 0, 0.5))
blade = bpy.context.active_object
blade.scale = (0.25, 0.015, 0.12)
blade.rotation_euler.z = math.radians(-20)
blade.name = "Blade"
silver_b = mat("SilverBlade", (0.8, 0.8, 0.85, 1))
assign_mat(blade, silver_b)

# Blade tip extension
bpy.ops.mesh.primitive_cube_add(size=1, location=(0.32, 0, 0.42))
tip = bpy.context.active_object
tip.scale = (0.1, 0.015, 0.08)
tip.rotation_euler.z = math.radians(-50)
tip.name = "BladeTip"
assign_mat(tip, silver_b)

# Purple glow orb at junction
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.04, location=(0, 0, 0.52))
orb = bpy.context.active_object
orb.name = "GlowOrb"
purple = mat("Purple", (0.4, 0.1, 0.6, 1), emission=(0.6, 0.1, 0.8, 1), emission_strength=2.0)
assign_mat(orb, purple)

export("scythe.glb")

# ============================================================
# 3. axe.glb
# ============================================================
clear()
# Handle
bpy.ops.mesh.primitive_cylinder_add(radius=0.025, depth=0.8, location=(0, 0, 0))
handle = bpy.context.active_object
handle.name = "Handle"
brown = mat("Brown", (0.45, 0.28, 0.12, 1))
assign_mat(handle, brown)

# Axe head left
bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=0.2, depth=0.05, location=(-0.1, 0, 0.3))
head_l = bpy.context.active_object
head_l.rotation_euler.y = math.radians(90)
head_l.rotation_euler.z = math.radians(90)
head_l.name = "HeadL"
metal = mat("Metal", (0.55, 0.55, 0.58, 1))
assign_mat(head_l, metal)

# Axe head right
bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=0.2, depth=0.05, location=(0.1, 0, 0.3))
head_r = bpy.context.active_object
head_r.rotation_euler.y = math.radians(-90)
head_r.rotation_euler.z = math.radians(90)
head_r.name = "HeadR"
assign_mat(head_r, metal)

export("axe.glb")

# ============================================================
# 4. whip.glb
# ============================================================
clear()
leather = mat("Leather", (0.4, 0.22, 0.1, 1))
# Chain of small cylinders
for i in range(12):
    angle = math.radians(i * 8)
    x = i * 0.06
    z = -i * 0.03 + math.sin(i * 0.5) * 0.05
    bpy.ops.mesh.primitive_cylinder_add(radius=0.02 - i*0.001, depth=0.06, location=(x, 0, z))
    seg = bpy.context.active_object
    seg.rotation_euler.y = math.radians(15 + i * 3)
    seg.name = f"Seg{i}"
    assign_mat(seg, leather)

# Handle
bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=0.18, location=(-0.05, 0, 0.05))
handle = bpy.context.active_object
handle.name = "Handle"
dark = mat("DarkBrown", (0.2, 0.12, 0.06, 1))
assign_mat(handle, dark)

export("whip.glb")

# ============================================================
# 5. lance.glb
# ============================================================
clear()
# Shaft
bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=1.2, location=(0, 0, 0))
shaft = bpy.context.active_object
shaft.name = "Shaft"
wood = mat("Wood", (0.5, 0.35, 0.18, 1))
assign_mat(shaft, wood)

# Tip cone
bpy.ops.mesh.primitive_cone_add(radius1=0.05, depth=0.2, location=(0, 0, 0.7))
tip = bpy.context.active_object
tip.name = "Tip"
metal = mat("Metal", (0.7, 0.7, 0.75, 1))
assign_mat(tip, metal)

# Red ribbon
bpy.ops.mesh.primitive_cube_add(size=1, location=(0.04, 0, 0.5))
ribbon = bpy.context.active_object
ribbon.scale = (0.08, 0.005, 0.12)
ribbon.rotation_euler.z = math.radians(15)
ribbon.name = "Ribbon"
red = mat("Red", (0.85, 0.1, 0.1, 1))
assign_mat(ribbon, red)

export("lance.glb")

# ============================================================
# 6. hammer.glb
# ============================================================
clear()
# Handle
bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.6, location=(0, 0, 0))
handle = bpy.context.active_object
handle.name = "Handle"
wood = mat("Wood", (0.4, 0.28, 0.15, 1))
assign_mat(handle, wood)

# Head - large box
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.35))
head = bpy.context.active_object
head.scale = (0.15, 0.12, 0.1)
head.name = "Head"
grey = mat("Grey", (0.5, 0.5, 0.52, 1))
assign_mat(head, grey)

export("hammer.glb")

# ============================================================
# 7. nunchaku.glb
# ============================================================
clear()
brown = mat("Brown", (0.4, 0.25, 0.1, 1))

# Stick 1
bpy.ops.mesh.primitive_cylinder_add(radius=0.025, depth=0.3, location=(-0.05, 0, 0.15))
s1 = bpy.context.active_object
s1.rotation_euler.y = math.radians(10)
s1.name = "Stick1"
assign_mat(s1, brown)

# Stick 2
bpy.ops.mesh.primitive_cylinder_add(radius=0.025, depth=0.3, location=(0.05, 0, -0.15))
s2 = bpy.context.active_object
s2.rotation_euler.y = math.radians(-10)
s2.name = "Stick2"
assign_mat(s2, brown)

# Chain - small spheres
chain_mat = mat("Chain", (0.5, 0.5, 0.5, 1))
for i in range(5):
    t = i / 4.0
    x = -0.05 + t * 0.1
    z = 0.0 + math.sin(t * math.pi) * 0.03
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.012, location=(x, 0, z))
    link = bpy.context.active_object
    link.name = f"Chain{i}"
    assign_mat(link, chain_mat)

export("nunchaku.glb")

# ============================================================
# 8. dual_katana.glb
# ============================================================
clear()
silver = mat("Silver", (0.85, 0.85, 0.9, 1))
red_r = mat("RedRibbon", (0.85, 0.1, 0.1, 1))
blue_r = mat("BlueRibbon", (0.1, 0.2, 0.85, 1))
dark = mat("Dark", (0.15, 0.1, 0.08, 1))

# Blade 1
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
b1 = bpy.context.active_object
b1.scale = (0.025, 0.1, 0.5)
b1.rotation_euler.z = math.radians(20)
b1.name = "Blade1"
assign_mat(b1, silver)

# Handle 1
bpy.ops.mesh.primitive_cylinder_add(radius=0.018, depth=0.2, location=(-0.12, 0, -0.35))
h1 = bpy.context.active_object
h1.rotation_euler.z = math.radians(20)
h1.name = "Handle1"
assign_mat(h1, dark)

# Red ribbon
bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.08, 0, -0.25))
r1 = bpy.context.active_object
r1.scale = (0.04, 0.005, 0.03)
r1.name = "Ribbon1"
assign_mat(r1, red_r)

# Blade 2
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
b2 = bpy.context.active_object
b2.scale = (0.025, 0.1, 0.5)
b2.rotation_euler.z = math.radians(-20)
b2.name = "Blade2"
assign_mat(b2, silver)

# Handle 2
bpy.ops.mesh.primitive_cylinder_add(radius=0.018, depth=0.2, location=(0.12, 0, -0.35))
h2 = bpy.context.active_object
h2.rotation_euler.z = math.radians(-20)
h2.name = "Handle2"
assign_mat(h2, dark)

# Blue ribbon
bpy.ops.mesh.primitive_cube_add(size=1, location=(0.08, 0, -0.25))
r2 = bpy.context.active_object
r2.scale = (0.04, 0.005, 0.03)
r2.name = "Ribbon2"
assign_mat(r2, blue_r)

export("dual_katana.glb")

# ============================================================
# 9. cloud_sword.glb
# ============================================================
clear()
# HUGE flat blade
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.3))
blade = bpy.context.active_object
blade.scale = (0.18, 0.03, 0.6)
blade.name = "Blade"
blue_metal = mat("BlueMetal", (0.5, 0.55, 0.65, 1))
assign_mat(blade, blue_metal)

# Small handle
bpy.ops.mesh.primitive_cylinder_add(radius=0.025, depth=0.2, location=(0, 0, -0.35))
handle = bpy.context.active_object
handle.name = "Handle"
dark = mat("Dark", (0.15, 0.12, 0.1, 1))
assign_mat(handle, dark)

# Guard
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, -0.25))
guard = bpy.context.active_object
guard.scale = (0.08, 0.04, 0.02)
guard.name = "Guard"
gold = mat("Gold", (0.8, 0.7, 0.2, 1))
assign_mat(guard, gold)

export("cloud_sword.glb")

# ============================================================
# 10. boxing_gloves.glb
# ============================================================
clear()
red = mat("Red", (0.85, 0.12, 0.1, 1))
skin = mat("Skin", (0.7, 0.55, 0.4, 1))

# Glove 1
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.1, location=(-0.12, 0, 0.05))
g1 = bpy.context.active_object
g1.scale = (1, 0.85, 0.9)
g1.name = "Glove1"
assign_mat(g1, red)

# Wrist 1
bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.1, location=(-0.12, 0, -0.1))
w1 = bpy.context.active_object
w1.name = "Wrist1"
assign_mat(w1, skin)

# Glove 2
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.1, location=(0.12, 0, 0.05))
g2 = bpy.context.active_object
g2.scale = (1, 0.85, 0.9)
g2.name = "Glove2"
assign_mat(g2, red)

# Wrist 2
bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.1, location=(0.12, 0, -0.1))
w2 = bpy.context.active_object
w2.name = "Wrist2"
assign_mat(w2, skin)

export("boxing_gloves.glb")

print("=== ALL MELEE WEAPONS DONE ===")
