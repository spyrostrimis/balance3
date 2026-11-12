"""Packs rendered frames into sprite sheets for Godot.

    python tools/art/pack_sprites.py [frames_dir] [assets_dir]

Reads <frames_dir>/manifest.json and the frames written by render_sprites.py,
adds a thin dark outline around each model (not around its shadow) so units
and props keep a clean silhouette on any ground, and writes one horizontal
sheet per sprite plus assets/sprites/sprites.json, which the game loads.
"""

import json
import os
import sys

from PIL import Image, ImageChops, ImageFilter

OUTLINE_PX = 2                       # at source resolution
OUTLINE_COLOR = (18, 20, 24)
OUTLINE_ALPHA = 0.85
SOLID_ALPHA = 200                    # alpha above this is model, below is shadow


def add_outline(frame):
    alpha = frame.getchannel("A")
    solid = alpha.point(lambda a: 255 if a >= SOLID_ALPHA else 0)
    grown = solid.filter(ImageFilter.MaxFilter(OUTLINE_PX * 2 + 1)).filter(ImageFilter.GaussianBlur(0.6))
    ring = ImageChops.subtract(grown, solid).point(lambda a: int(a * OUTLINE_ALPHA))
    outline = Image.new("RGBA", frame.size, OUTLINE_COLOR + (0,))
    outline.putalpha(ring)
    # Shadow first, then the outline, then the model on top.
    result = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    result.alpha_composite(frame)
    result.alpha_composite(outline)
    model_only = frame.copy()
    model_only.putalpha(ImageChops.multiply(alpha, solid))
    result.alpha_composite(model_only)
    return result


def main():
    frames_dir = sys.argv[1] if len(sys.argv) > 1 else "art_build/frames"
    assets_dir = sys.argv[2] if len(sys.argv) > 2 else "assets/sprites"
    os.makedirs(assets_dir, exist_ok=True)
    with open(os.path.join(frames_dir, "manifest.json"), encoding="utf-8") as handle:
        manifest = json.load(handle)

    catalog = {}
    for name, info in sorted(manifest.items()):
        width, height, count = info["frame_width"], info["frame_height"], info["frames"]
        sheet = Image.new("RGBA", (width * count, height), (0, 0, 0, 0))
        for index in range(count):
            frame = Image.open(os.path.join(frames_dir, "%s_%d.png" % (name, index))).convert("RGBA")
            sheet.paste(add_outline(frame), (index * width, 0))
        file_name = name + ".png"
        sheet.save(os.path.join(assets_dir, file_name), optimize=True)
        catalog[name] = {
            "file": file_name,
            "frames": count,
            "frame_width": width,
            "frame_height": height,
            "anchor": [round(info["anchor"][0], 2), round(info["anchor"][1], 2)],
            "px_per_cell": info["px_per_cell"],
            "directional": info["directional"],
        }
        print("packed %-16s %d frames -> %s" % (name, count, file_name))

    with open(os.path.join(assets_dir, "sprites.json"), "w", encoding="utf-8", newline="\n") as handle:
        json.dump(catalog, handle, indent="\t")
        handle.write("\n")


main()
