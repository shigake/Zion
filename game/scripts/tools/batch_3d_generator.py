"""
Batch 3D Model Generator — converts all enemy/boss sprites to 3D models via Hunyuan3D local API.
Usage: python batch_3d_generator.py
Requires: Hunyuan3D server running on localhost:8081
"""

import base64
import glob
import os
import sys
import time
import requests
from PIL import Image
from io import BytesIO

API_URL = "http://localhost:8081/generate"
GAME_DIR = os.path.join(os.path.dirname(__file__), "..", "..")
ENEMIES_SPRITE_DIR = os.path.join(GAME_DIR, "assets", "sprites", "enemies")
BOSSES_SPRITE_DIR = os.path.join(GAME_DIR, "assets", "sprites", "bosses")
ENEMIES_MODEL_DIR = os.path.join(GAME_DIR, "assets", "models", "enemies")
BOSSES_MODEL_DIR = os.path.join(GAME_DIR, "assets", "models", "bosses")

UPSCALE_SIZE = 512
NUM_STEPS = 20
GUIDANCE_SCALE = 5.5
OCTREE_RESOLUTION = 256
TIMEOUT = 180  # seconds per model


def upscale_sprite(sprite_path: str) -> str:
    """Upscale a small sprite to 512x512 with white background for better 3D generation."""
    img = Image.open(sprite_path).convert("RGBA")
    # Create white background
    bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
    bg.paste(img, mask=img.split()[3])
    # Upscale
    upscaled = bg.resize((UPSCALE_SIZE, UPSCALE_SIZE), Image.LANCZOS)
    # Convert to base64
    buffer = BytesIO()
    upscaled.save(buffer, format="PNG")
    return base64.b64encode(buffer.getvalue()).decode()


def generate_3d(image_b64: str, output_path: str) -> bool:
    """Send image to Hunyuan3D and save the resulting .glb model."""
    try:
        resp = requests.post(API_URL, json={
            "image": image_b64,
            "num_steps": NUM_STEPS,
            "guidance_scale": GUIDANCE_SCALE,
            "octree_resolution": OCTREE_RESOLUTION,
        }, timeout=TIMEOUT)

        if resp.status_code == 200 and len(resp.content) > 1000:
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            with open(output_path, "wb") as f:
                f.write(resp.content)
            return True
        else:
            print(f"  ERROR: status={resp.status_code}, size={len(resp.content)}")
            return False
    except Exception as e:
        print(f"  ERROR: {e}")
        return False


def process_sprites(sprite_dir: str, model_dir: str, label: str):
    """Process all sprites in a directory tree."""
    patterns = [
        os.path.join(sprite_dir, "*.png"),
        os.path.join(sprite_dir, "**", "*.png"),
    ]

    sprites = []
    for pattern in patterns:
        sprites.extend(glob.glob(pattern, recursive=True))

    # Remove .import files and duplicates
    sprites = sorted(set(s for s in sprites if not s.endswith(".import")))

    total = len(sprites)
    success = 0
    skipped = 0
    failed = 0

    print(f"\n{'='*60}")
    print(f"  Processing {total} {label} sprites")
    print(f"{'='*60}\n")

    for i, sprite_path in enumerate(sprites, 1):
        # Determine output path
        rel_path = os.path.relpath(sprite_path, sprite_dir)
        model_name = os.path.splitext(rel_path)[0] + ".glb"
        output_path = os.path.join(model_dir, model_name)

        # Skip if already generated
        if os.path.exists(output_path) and os.path.getsize(output_path) > 1000:
            print(f"[{i}/{total}] SKIP (exists): {rel_path}")
            skipped += 1
            continue

        print(f"[{i}/{total}] Generating: {rel_path} ...", end=" ", flush=True)
        start = time.time()

        # Upscale sprite
        image_b64 = upscale_sprite(sprite_path)

        # Generate 3D model
        ok = generate_3d(image_b64, output_path)
        elapsed = time.time() - start

        if ok:
            size_kb = os.path.getsize(output_path) / 1024
            print(f"OK ({elapsed:.1f}s, {size_kb:.0f}KB)")
            success += 1
        else:
            print(f"FAILED ({elapsed:.1f}s)")
            failed += 1

        # Small delay to avoid GPU overload
        time.sleep(1)

    print(f"\n--- {label} Results ---")
    print(f"  Success: {success}")
    print(f"  Skipped: {skipped}")
    print(f"  Failed:  {failed}")
    print(f"  Total:   {total}")

    return success, skipped, failed


def main():
    print("=" * 60)
    print("  ZION — Batch 3D Model Generator")
    print("  Hunyuan3D Local (image-to-3D)")
    print("=" * 60)

    # Check server
    try:
        requests.get(f"http://localhost:8081/", timeout=5)
        print("\nServer: OK (localhost:8081)")
    except:
        print("\nERROR: Hunyuan3D server not running on localhost:8081!")
        print("Start with: cd Hunyuan3D-2 && python api_server.py --port 8081")
        sys.exit(1)

    # Process enemies
    e_success, e_skip, e_fail = process_sprites(ENEMIES_SPRITE_DIR, ENEMIES_MODEL_DIR, "enemies")

    # Process bosses
    b_success, b_skip, b_fail = process_sprites(BOSSES_SPRITE_DIR, BOSSES_MODEL_DIR, "bosses")

    # Summary
    total_success = e_success + b_success
    total_fail = e_fail + b_fail
    total_skip = e_skip + b_skip

    print(f"\n{'='*60}")
    print(f"  BATCH COMPLETE")
    print(f"  Generated: {total_success}")
    print(f"  Skipped:   {total_skip}")
    print(f"  Failed:    {total_fail}")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
