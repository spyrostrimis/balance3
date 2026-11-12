"""Generates Balance's original seamless ground textures with Pillow.

    python tools/art/make_ground_textures.py [out_dir]

Writes grass.png, forest_floor.png, dirt.png, stone.png (each tiles
seamlessly) and variation.png (three independent low-frequency noise channels
the ground shader uses for boundary wobble, brightness drift and ore veins).
The output is deterministic: the same script always produces the same files.
"""

import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageOps

SIZE = 512          # texture size in pixels; the shader repeats it every 4 cells


def value_noise(size, cells, rng):
    """Seamless greyscale noise with `cells` random values across the image."""
    small = Image.new("L", (cells, cells))
    small.putdata([rng.randrange(256) for _ in range(cells * cells)])
    tiled = Image.new("L", (cells * 3, cells * 3))
    for y in range(3):
        for x in range(3):
            tiled.paste(small, (x * cells, y * cells))
    big = tiled.resize((size * 3, size * 3), Image.BICUBIC)
    return big.crop((size, size, size * 2, size * 2))


def fractal_noise(size, cells, octaves, rng, persistence=0.5):
    """Sum of value-noise octaves, stretched to the full 0-255 range."""
    result = None
    total = 0.0
    weight = 1.0
    for _ in range(octaves):
        layer = value_noise(size, cells, rng)
        total += weight
        result = layer if result is None else Image.blend(result, layer, weight / total)
        weight *= persistence
        cells *= 2
    return ImageOps.autocontrast(result)


def colorize(grey, dark, mid, light):
    return ImageOps.colorize(grey, black=dark, white=light, mid=mid).convert("RGBA")


def wrapped(image, draw_one):
    """Calls draw_one(draw, dx, dy) for the nine wrap offsets, so marks tile."""
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for dy in (-image.height, 0, image.height):
        for dx in (-image.width, 0, image.width):
            draw_one(draw, dx, dy)
    image.alpha_composite(overlay)


def hex_rgba(hex_color, alpha):
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def add_grain(image, rng, amount):
    grain = value_noise(SIZE, 192, rng).convert("RGBA")
    grain.putalpha(int(255 * amount))
    base = image.copy()
    base.alpha_composite(grain)
    # Keep the hue: use the grain only as a soft-light style brightness nudge.
    return Image.blend(image, base, 0.5)


def grass(rng):
    image = colorize(fractal_noise(SIZE, 4, 5, rng), "#42622f", "#4a6b35", "#55763f")
    image = add_grain(image, rng, 0.10)
    blades = []
    for _ in range(3200):
        x, y = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
        angle = rng.gauss(-math.pi / 2, 0.5)
        length = rng.uniform(3, 8)
        color = hex_rgba(rng.choice(["6f9148", "557a3a", "324f26", "7f9c52", "2f4a25"]), rng.randint(70, 130))
        blades.append((x, y, x + math.cos(angle) * length, y + math.sin(angle) * length, color))
    wrapped(image, lambda draw, dx, dy: [draw.line((a + dx, b + dy, c + dx, d + dy), fill=color, width=1)
                                          for a, b, c, d, color in blades])
    return image.filter(ImageFilter.GaussianBlur(0.4))


def forest_floor(rng):
    image = colorize(fractal_noise(SIZE, 4, 5, rng), "#2a3220", "#373d26", "#46452b")
    image = add_grain(image, rng, 0.10)
    litter = []
    for _ in range(1500):
        x, y = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
        w, h = rng.uniform(3, 7), rng.uniform(2, 4)
        color = hex_rgba(rng.choice(["5c4a28", "6c5830", "3a2e1a", "55602f", "7a6234"]), rng.randint(90, 150))
        litter.append((x, y, w, h, color))
    wrapped(image, lambda draw, dx, dy: [draw.ellipse((x + dx, y + dy, x + dx + w, y + dy + h), fill=color)
                                          for x, y, w, h, color in litter])
    twigs = []
    for _ in range(140):
        x, y = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
        angle = rng.uniform(0, math.tau)
        length = rng.uniform(8, 20)
        twigs.append((x, y, x + math.cos(angle) * length, y + math.sin(angle) * length))
    wrapped(image, lambda draw, dx, dy: [draw.line((a + dx, b + dy, c + dx, d + dy), fill=hex_rgba("241c12", 130), width=2)
                                          for a, b, c, d in twigs])
    return image.filter(ImageFilter.GaussianBlur(0.5))


def dirt(rng):
    image = colorize(fractal_noise(SIZE, 4, 5, rng), "#6a563a", "#806a47", "#958055")
    image = add_grain(image, rng, 0.12)
    pebbles = []
    for _ in range(420):
        x, y = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
        r = rng.uniform(1.5, 4.0)
        pebbles.append((x, y, r, hex_rgba(rng.choice(["a8987a", "b6a688", "8f8068"]), 210)))
    def draw_pebbles(draw, dx, dy):
        for x, y, r, color in pebbles:
            draw.ellipse((x + dx - r + 1, y + dy - r + 1.5, x + dx + r + 1, y + dy + r + 1.5), fill=hex_rgba("3d2f1e", 120))
            draw.ellipse((x + dx - r, y + dy - r, x + dx + r, y + dy + r), fill=color)
    wrapped(image, draw_pebbles)
    return image.filter(ImageFilter.GaussianBlur(0.4))


def stone(rng):
    image = colorize(fractal_noise(SIZE, 6, 5, rng, 0.6), "#66676a", "#7e7f7c", "#96958e")
    image = add_grain(image, rng, 0.10)
    cracks = []
    for _ in range(16):
        x, y = rng.uniform(0, SIZE), rng.uniform(0, SIZE)
        angle = rng.uniform(0, math.tau)
        points = [(x, y)]
        for _ in range(rng.randint(8, 18)):
            angle += rng.gauss(0, 0.45)
            x += math.cos(angle) * rng.uniform(8, 18)
            y += math.sin(angle) * rng.uniform(8, 18)
            points.append((x, y))
        cracks.append(points)
    def draw_cracks(draw, dx, dy):
        for points in cracks:
            lit = [(x + dx + 1.5, y + dy + 1.5) for x, y in points]
            dark = [(x + dx, y + dy) for x, y in points]
            draw.line(lit, fill=hex_rgba("b4b3ab", 110), width=2, joint="curve")
            draw.line(dark, fill=hex_rgba("35363a", 190), width=2, joint="curve")
    wrapped(image, draw_cracks)
    return image.filter(ImageFilter.GaussianBlur(0.4))


def variation(rng):
    channels = [
        fractal_noise(256, 4, 4, rng),          # R: boundary wobble
        fractal_noise(256, 3, 3, rng),          # G: large-scale brightness drift
        fractal_noise(256, 6, 4, rng, 0.6),     # B: ore vein pattern
    ]
    return Image.merge("RGB", channels)


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "assets/terrain"
    os.makedirs(out_dir, exist_ok=True)
    rng = random.Random(20261112)
    for name, build in (("grass", grass), ("forest_floor", forest_floor), ("dirt", dirt), ("stone", stone)):
        build(rng).convert("RGB").save(os.path.join(out_dir, name + ".png"), optimize=True)
        print("wrote", name)
    variation(rng).save(os.path.join(out_dir, "variation.png"), optimize=True)
    print("wrote variation")


main()
