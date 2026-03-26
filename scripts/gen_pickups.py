import bpy
import bmesh
import math
import os
from mathutils import Matrix, Vector

OUT = "C:/Users/shiga/projects/Zion/game/assets/models/pickups"

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
# 29. xp_gem.glb
# ============================================================
clear()
blue_glow = mat("BlueGlow", (0.2, 0.4, 0.95, 1), emission=(0.3, 0.5, 1.0, 1), emission_strength=2.5)

# Diamond shape using two cones
# Top cone
bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.08, depth=0.12, location=(0, 0, 0.06))
top = bpy.context.active_object
top.name = "TopHalf"
assign_mat(top, blue_glow)

# Bottom cone (inverted)
bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.08, depth=0.08, location=(0, 0, -0.04))
bottom = bpy.context.active_object
bottom.rotation_euler.x = math.radians(180)
bottom.name = "BottomHalf"
assign_mat(bottom, blue_glow)

export("xp_gem.glb")

# ============================================================
# 30. crystal.glb
# ============================================================
clear()
gold_crystal = mat("GoldCrystal", (0.85, 0.7, 0.2, 1), emission=(0.9, 0.75, 0.3, 1), emission_strength=1.5)

# Hexagonal prism (6-sided cylinder)
bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.1, depth=0.06, location=(0, 0, 0))
crystal = bpy.context.active_object
crystal.name = "Crystal"
assign_mat(crystal, gold_crystal)

# Small facet on top
bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.06, depth=0.02, location=(0, 0, 0.04))
facet = bpy.context.active_object
facet.name = "TopFacet"
sparkle = mat("Sparkle", (1.0, 0.9, 0.5, 1), emission=(1.0, 0.95, 0.6, 1), emission_strength=2.0)
assign_mat(facet, sparkle)

export("crystal.glb")

# ============================================================
# 31. evolution_chest.glb
# ============================================================
clear()
wood = mat("Wood", (0.5, 0.35, 0.18, 1))
gold_metal = mat("GoldMetal", (0.85, 0.7, 0.15, 1))
dark_wood = mat("DarkWood", (0.3, 0.2, 0.1, 1))

# Box body
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
body = bpy.context.active_object
body.scale = (0.18, 0.12, 0.1)
body.name = "Body"
assign_mat(body, wood)

# Rounded lid (half cylinder on top)
bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=0.24, location=(0, 0, 0.1))
lid = bpy.context.active_object
lid.rotation_euler.y = math.radians(90)
lid.scale = (0.5, 1, 0.5)
lid.name = "Lid"
assign_mat(lid, wood)

# Metal bands (horizontal)
for z in [-0.03, 0.03]:
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, z))
    band = bpy.context.active_object
    band.scale = (0.19, 0.125, 0.008)
    band.name = f"Band_{z}"
    assign_mat(band, gold_metal)

# Top band on lid
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.12))
top_band = bpy.context.active_object
top_band.scale = (0.19, 0.02, 0.008)
top_band.name = "TopBand"
assign_mat(top_band, gold_metal)

# Lock
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.125, 0.02))
lock = bpy.context.active_object
lock.scale = (0.025, 0.008, 0.03)
lock.name = "Lock"
assign_mat(lock, gold_metal)

# Lock keyhole
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.008, location=(0, 0.135, 0.02))
keyhole = bpy.context.active_object
keyhole.name = "Keyhole"
assign_mat(keyhole, dark_wood)

export("evolution_chest.glb")

print("=== ALL PICKUPS DONE ===")
