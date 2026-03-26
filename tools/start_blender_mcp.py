"""
Script para iniciar o Blender com o MCP server ativo.
Uso: blender --python tools/start_blender_mcp.py
"""
import bpy
import sys
import os

# Adiciona o addon path
addon_path = os.path.expanduser("~\\AppData\\Roaming\\Blender\\5.1\\scripts\\addons")
if addon_path not in sys.path:
    sys.path.append(addon_path)

# Tenta ativar o addon
try:
    bpy.ops.preferences.addon_enable(module="blender_mcp")
    print("[MCP] Addon blender_mcp enabled")
except Exception as e:
    print(f"[MCP] Could not enable addon: {e}")
    # Try installing it first
    try:
        bpy.ops.preferences.addon_install(filepath=os.path.join(addon_path, "blender_mcp.py"))
        bpy.ops.preferences.addon_enable(module="blender_mcp")
        print("[MCP] Addon installed and enabled")
    except Exception as e2:
        print(f"[MCP] Install failed: {e2}")

print("[MCP] Blender ready. Please start MCP server from the BlenderMCP panel (press N in 3D View)")
print("[MCP] Or run: bpy.ops.blendermcp.start_server()")
