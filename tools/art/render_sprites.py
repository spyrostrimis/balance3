"""Builds Balance's original low-poly models and renders them to sprite frames.

Run with Blender (5.x), not with system Python:

    blender --background --factory-startup --python tools/art/render_sprites.py -- <out_dir> [name_filter]

Every sprite is rendered by the same rig so the whole game shares one viewing
angle and one light: an orthographic camera looking north and down at
ELEVATION_DEG, with the sun in the top-left of the screen. Shadows are baked
into each frame's alpha channel by a shadow-catcher ground plane.

Output: <out_dir>/<sprite>_<frame>.png plus <out_dir>/manifest.json, which
tools/art/pack_sprites.py turns into sprite sheets under assets/sprites/.

Units: 1 Blender unit = 1 logical grid cell. Models face +X (east); frame i of
a unit faces i * 45 degrees clockwise on screen (E, SE, S, SW, W, NW, N, NE).
"""

import json
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Vector

PX_PER_CELL = 128          # source pixels per grid cell
ELEVATION_DEG = 60.0       # camera elevation above the ground plane
SAMPLES = 96
DIRECTIONS = 8
UNIT_SCALE = 1.12          # units are drawn a little larger than life for readability

TILT = math.radians(90.0 - ELEVATION_DEG)   # camera tilt away from straight down


# --------------------------------------------------------------------------
# Scene rig
# --------------------------------------------------------------------------

def setup_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = SAMPLES
    scene.cycles.use_denoising = False
    scene.render.film_transparent = True
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"

    world = bpy.data.worlds.new("World")
    scene.world = world
    try:
        world.use_nodes = True
    except Exception:
        pass
    background = world.node_tree.nodes.get("Background")
    if background is None:
        background = world.node_tree.nodes.new("ShaderNodeBackground")
        output = world.node_tree.nodes.new("ShaderNodeOutputWorld")
        world.node_tree.links.new(background.outputs[0], output.inputs[0])
    background.inputs[0].default_value = (0.80, 0.88, 1.0, 1.0)
    background.inputs[1].default_value = 1.0

    sun_data = bpy.data.lights.new("Sun", "SUN")
    sun_data.energy = 2.8
    sun_data.angle = math.radians(4.0)
    sun_data.color = (1.0, 0.96, 0.88)
    sun = bpy.data.objects.new("Sun", sun_data)
    scene.collection.objects.link(sun)
    # Light travels right, towards the bottom of the screen, and down.
    direction = Vector((0.42, -0.38, -1.0)).normalized()
    sun.rotation_mode = "QUATERNION"
    sun.rotation_quaternion = direction.to_track_quat("-Z", "Y")

    camera_data = bpy.data.cameras.new("Camera")
    camera_data.type = "ORTHO"
    camera_data.clip_end = 200.0
    camera = bpy.data.objects.new("Camera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.rotation_euler = (TILT, 0.0, 0.0)

    ground = bmesh.new()
    bmesh.ops.create_grid(ground, x_segments=1, y_segments=1, size=20.0)
    catcher = finish_object("ShadowCatcher", ground, material("777777", 1.0), smooth=False)
    catcher.is_shadow_catcher = True
    return scene, camera


def aim_camera(scene, camera, frame_cells, target_z):
    """Frames a square of frame_cells x frame_cells centred on (0, 0, target_z)."""
    width, height = frame_cells
    camera.data.ortho_scale = max(width, height)
    distance = 50.0
    camera.location = (0.0, -distance * math.sin(TILT), target_z + distance * math.cos(TILT))
    scene.render.resolution_x = int(round(width * PX_PER_CELL))
    scene.render.resolution_y = int(round(height * PX_PER_CELL))


# --------------------------------------------------------------------------
# Materials and mesh helpers
# --------------------------------------------------------------------------

_materials = {}


def linear(hex_color):
    values = [int(hex_color[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in values)


def material(hex_color, roughness=0.75, metallic=0.0, emission=0.0):
    key = (hex_color, roughness, metallic, emission)
    if key in _materials:
        return _materials[key]
    mat = bpy.data.materials.new("mat_%s_%d" % (hex_color, len(_materials)))
    try:
        mat.use_nodes = True
    except Exception:
        pass
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    color = linear(hex_color)
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission > 0.0:
        bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission
    _materials[key] = mat
    return mat


def finish_object(name, bm, mat, smooth=True, parent=None):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for polygon in mesh.polygons:
        polygon.use_smooth = smooth
    if smooth:
        try:
            mesh.set_sharp_from_angle(angle=math.radians(50.0))
        except Exception:
            pass
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    return obj


class Model:
    """A group of primitive meshes parented to one root, so it can be turned."""

    def __init__(self, name):
        self.root = bpy.data.objects.new(name, None)
        bpy.context.scene.collection.objects.link(self.root)
        self.parts = []

    def _add(self, obj, location, rotation=None):
        obj.location = location
        if rotation is not None:
            obj.rotation_euler = [math.radians(a) for a in rotation]
        self.parts.append(obj)
        return obj

    def box(self, size, location, mat, rotation=None, bevel=0.02):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        for vertex in bm.verts:
            vertex.co.x *= size[0]
            vertex.co.y *= size[1]
            vertex.co.z *= size[2]
        if bevel > 0.0:
            try:
                bmesh.ops.bevel(bm, geom=bm.edges[:], offset=bevel, segments=2, profile=0.5, affect="EDGES")
            except Exception:
                pass
        return self._add(finish_object("box", bm, mat, smooth=False, parent=self.root), location, rotation)

    def sphere(self, radius, location, mat, scale=(1.0, 1.0, 1.0), rotation=None):
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=14, radius=radius)
        obj = self._add(finish_object("sphere", bm, mat, parent=self.root), location, rotation)
        obj.scale = scale
        return obj

    def cone(self, radius1, radius2, depth, location, mat, rotation=None, segments=16, smooth=True):
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segments,
                              radius1=radius1, radius2=radius2, depth=depth)
        return self._add(finish_object("cone", bm, mat, smooth=smooth, parent=self.root), location, rotation)

    def limb(self, start, end, radius, mat, radius_end=None):
        """A cylinder (or tapered cylinder) between two points."""
        start, end = Vector(start), Vector(end)
        axis = end - start
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=12, radius1=radius,
                              radius2=radius if radius_end is None else radius_end, depth=axis.length)
        obj = finish_object("limb", bm, mat, parent=self.root)
        obj.location = (start + end) / 2.0
        obj.rotation_mode = "QUATERNION"
        obj.rotation_quaternion = axis.to_track_quat("Z", "Y")
        self.parts.append(obj)
        return obj

    def plank(self, start, end, width, thickness, mat):
        """A flat strip between two points: cloth, capes, scarf tails."""
        start, end = Vector(start), Vector(end)
        axis = end - start
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        for vertex in bm.verts:
            vertex.co.x *= thickness
            vertex.co.y *= width
            vertex.co.z *= axis.length * 1.08
        obj = finish_object("plank", bm, mat, smooth=False, parent=self.root)
        obj.location = (start + end) / 2.0
        obj.rotation_mode = "QUATERNION"
        obj.rotation_quaternion = axis.to_track_quat("Z", "X")
        self.parts.append(obj)
        return obj

    def lump(self, radius, location, mat, rng, jitter=0.18, scale=(1.0, 1.0, 1.0), subdivisions=2, smooth=False):
        """An icosphere with randomly displaced vertices: rocks and foliage."""
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=subdivisions, radius=radius)
        for vertex in bm.verts:
            vertex.co *= 1.0 + rng.uniform(-jitter, jitter)
        obj = self._add(finish_object("lump", bm, mat, smooth=smooth, parent=self.root), location)
        obj.scale = scale
        obj.rotation_euler = (rng.uniform(0, 6.28), rng.uniform(0, 6.28), rng.uniform(0, 6.28))
        return obj

    def remove(self):
        for obj in self.parts:
            mesh = obj.data
            bpy.data.objects.remove(obj, do_unlink=True)
            bpy.data.meshes.remove(mesh)
        bpy.data.objects.remove(self.root, do_unlink=True)


# --------------------------------------------------------------------------
# Palettes
# --------------------------------------------------------------------------

BLUE = {"armor": "2f6bc9", "armor_dark": "1f447f", "trim": "8f9cab", "accent": "35c8ff", "cloth": "b08a52"}
RED = {"armor": "b5281f", "armor_dark": "2a2423", "trim": "3a3331", "accent": "f0b838", "cloth": "241c1c"}
GUNMETAL = "33373d"
BOOT = "26221f"
SKIN = "c98f6b"


# --------------------------------------------------------------------------
# Units
# --------------------------------------------------------------------------

def body(model, palette, scale=1.0, torso_color=None):
    """Legs, torso, belt and arms holding a weapon forward. Returns nothing."""
    s = scale
    armor = material(torso_color or palette["armor"], 0.55, 0.15)
    dark = material(palette["armor_dark"], 0.7)
    boot = material(BOOT, 0.8)
    # Legs in a slight walking stance.
    model.limb((0.0, -0.10 * s, 0.50 * s), (0.07 * s, -0.11 * s, 0.06 * s), 0.075 * s, dark)
    model.limb((0.0, 0.10 * s, 0.50 * s), (-0.06 * s, 0.11 * s, 0.06 * s), 0.075 * s, dark)
    model.box((0.20 * s, 0.11 * s, 0.09 * s), (0.10 * s, -0.11 * s, 0.045 * s), boot)
    model.box((0.20 * s, 0.11 * s, 0.09 * s), (-0.03 * s, 0.11 * s, 0.045 * s), boot)
    # Torso and belt.
    model.box((0.27 * s, 0.40 * s, 0.38 * s), (0.0, 0.0, 0.67 * s), armor, bevel=0.05 * s)
    model.box((0.29 * s, 0.42 * s, 0.07 * s), (0.0, 0.0, 0.49 * s), dark, bevel=0.02 * s)


def arms(model, palette, scale=1.0):
    s = scale
    armor = material(palette["armor"], 0.55, 0.15)
    glove = material(BOOT, 0.8)
    model.limb((0.0, -0.25 * s, 0.80 * s), (0.14 * s, -0.27 * s, 0.62 * s), 0.062 * s, armor)
    model.limb((0.14 * s, -0.27 * s, 0.62 * s), (0.30 * s, -0.13 * s, 0.62 * s), 0.055 * s, armor)
    model.limb((0.0, 0.25 * s, 0.80 * s), (0.18 * s, 0.24 * s, 0.64 * s), 0.062 * s, armor)
    model.limb((0.18 * s, 0.24 * s, 0.64 * s), (0.42 * s, 0.00 * s, 0.64 * s), 0.055 * s, armor)
    model.sphere(0.06 * s, (0.30 * s, -0.13 * s, 0.62 * s), glove)
    model.sphere(0.06 * s, (0.42 * s, 0.00 * s, 0.64 * s), glove)


def blue_trooper():
    model = Model("blue_trooper")
    p = BLUE
    armor = material(p["armor"], 0.55, 0.15)
    trim = material(p["trim"], 0.5, 0.1)
    metal = material(GUNMETAL, 0.45, 0.6)
    body(model, p)
    arms(model, p)
    # Chest plate and round shoulder guards: Blue reads as rounded shapes.
    model.box((0.08, 0.28, 0.22), (0.13, 0.0, 0.71), trim, bevel=0.03)
    model.sphere(0.125, (0.0, -0.25, 0.83), trim, scale=(1.1, 1.0, 0.8))
    model.sphere(0.125, (0.0, 0.25, 0.83), trim, scale=(1.1, 1.0, 0.8))
    # Dome helmet with a dark visor band.
    model.sphere(0.155, (0.01, 0.0, 0.99), armor, scale=(1.08, 1.0, 0.95))
    model.box((0.07, 0.23, 0.065), (0.135, 0.0, 0.975), material("10202c", 0.2, 0.3), bevel=0.02)
    model.box((0.30, 0.035, 0.03), (0.0, 0.0, 1.135), trim, bevel=0.01)
    # Backpack with an antenna.
    model.box((0.15, 0.28, 0.30), (-0.20, 0.0, 0.70), material("7d8791", 0.7), bevel=0.03)
    model.limb((-0.22, 0.10, 0.84), (-0.26, 0.10, 1.30), 0.012, metal)
    model.sphere(0.03, (-0.26, 0.10, 1.31), material(p["accent"], 0.4, 0.0, 2.0))
    # Rifle.
    model.box((0.56, 0.065, 0.10), (0.34, -0.06, 0.63), metal, bevel=0.015)
    model.limb((0.60, -0.06, 0.64), (0.82, -0.06, 0.64), 0.022, metal)
    model.box((0.10, 0.05, 0.14), (0.30, -0.06, 0.53), metal, bevel=0.01)
    return model


def red_trooper():
    model = Model("red_trooper")
    p = RED
    armor = material(p["armor"], 0.5, 0.2)
    dark = material(p["armor_dark"], 0.6, 0.2)
    accent = material(p["accent"], 0.5, 0.2)
    metal = material(GUNMETAL, 0.45, 0.6)
    body(model, p)
    arms(model, p)
    # Angular chest wedge and slab shoulder plates: Red reads as hard edges.
    model.box((0.09, 0.30, 0.24), (0.13, 0.0, 0.70), dark, bevel=0.015)
    model.box((0.05, 0.10, 0.10), (0.18, 0.0, 0.74), accent, bevel=0.01)
    model.box((0.30, 0.20, 0.07), (0.0, -0.30, 0.86), dark, rotation=(-22, 0, 0), bevel=0.015)
    model.box((0.30, 0.20, 0.07), (0.0, 0.30, 0.86), dark, rotation=(22, 0, 0), bevel=0.015)
    model.box((0.31, 0.05, 0.075), (0.0, -0.38, 0.83), accent, rotation=(-22, 0, 0), bevel=0.01)
    model.box((0.31, 0.05, 0.075), (0.0, 0.38, 0.83), accent, rotation=(22, 0, 0), bevel=0.01)
    # Boxy helmet with a tall black crest running front to back.
    model.box((0.27, 0.25, 0.24), (0.01, 0.0, 0.99), armor, bevel=0.035)
    model.box((0.06, 0.20, 0.05), (0.14, 0.0, 0.97), material("f2d060", 0.3, 0.0, 1.5), bevel=0.01)
    model.box((0.40, 0.05, 0.16), (-0.03, 0.0, 1.16), dark, bevel=0.012)
    # Short back tabard.
    model.box((0.03, 0.30, 0.40), (-0.17, 0.0, 0.60), material(p["cloth"], 0.9), rotation=(0, 12, 0), bevel=0.0)
    # Heavy twin-barrel gun.
    model.box((0.44, 0.11, 0.13), (0.30, -0.06, 0.63), metal, bevel=0.015)
    model.limb((0.50, -0.09, 0.66), (0.80, -0.09, 0.66), 0.026, metal)
    model.limb((0.50, -0.03, 0.66), (0.80, -0.03, 0.66), 0.026, metal)
    model.box((0.10, 0.12, 0.08), (0.20, -0.06, 0.73), accent, bevel=0.01)
    return model


def blue_commander():
    model = Model("blue_commander")
    p = BLUE
    s = 1.14
    armor = material("3a66a8", 0.65, 0.15)      # weathered blue
    trim = material(p["trim"], 0.5, 0.1)
    gold = material("d8b24a", 0.35, 0.7)
    cloth = material(p["cloth"], 0.95)
    metal = material(GUNMETAL, 0.45, 0.6)
    glow = material(p["accent"], 0.3, 0.0, 2.2)
    body(model, p, s, torso_color="3a66a8")
    # Right arm holds a sidearm forward; left arm is raised with the field medic gauntlet.
    model.limb((0.0, -0.25 * s, 0.80 * s), (0.16 * s, -0.27 * s, 0.64 * s), 0.062 * s, armor)
    model.limb((0.16 * s, -0.27 * s, 0.64 * s), (0.40 * s, -0.20 * s, 0.68 * s), 0.055 * s, armor)
    model.box((0.22 * s, 0.05 * s, 0.09 * s), (0.50 * s, -0.20 * s, 0.70 * s), metal, bevel=0.012)
    model.limb((0.0, 0.25 * s, 0.80 * s), (0.10 * s, 0.38 * s, 0.70 * s), 0.062 * s, armor)
    model.limb((0.10 * s, 0.38 * s, 0.70 * s), (0.30 * s, 0.40 * s, 0.84 * s), 0.060 * s, armor)
    model.limb((0.22 * s, 0.39 * s, 0.78 * s), (0.31 * s, 0.40 * s, 0.85 * s), 0.075 * s, trim)
    model.sphere(0.075 * s, (0.37 * s, 0.41 * s, 0.91 * s), glow)
    # Chest plate with gold collar, round guards (Blue language) edged in gold.
    model.box((0.08 * s, 0.30 * s, 0.24 * s), (0.13 * s, 0.0, 0.71 * s), trim, bevel=0.03)
    model.box((0.05 * s, 0.12 * s, 0.05 * s), (0.18 * s, 0.0, 0.80 * s), gold, bevel=0.01)
    model.sphere(0.135 * s, (0.0, -0.26 * s, 0.84 * s), armor, scale=(1.1, 1.0, 0.8))
    model.sphere(0.135 * s, (0.0, 0.26 * s, 0.84 * s), armor, scale=(1.1, 1.0, 0.8))
    model.sphere(0.075 * s, (0.0, -0.27 * s, 0.92 * s), gold, scale=(1.2, 1.1, 0.5))
    model.sphere(0.075 * s, (0.0, 0.27 * s, 0.92 * s), gold, scale=(1.2, 1.1, 0.5))
    # Bare head with dark hair tied back; no helmet, so she reads differently from troopers.
    model.sphere(0.125 * s, (0.02 * s, 0.0, 1.00 * s), material(SKIN, 0.8))
    model.sphere(0.135 * s, (-0.02 * s, 0.0, 1.02 * s), material("2e211b", 0.85), scale=(1.0, 1.02, 0.95))
    model.sphere(0.07 * s, (-0.17 * s, 0.0, 1.00 * s), material("2e211b", 0.85), scale=(1.3, 0.9, 0.9))
    # Desert scarf: a thick wrap around the neck and a long tail flying behind.
    model.sphere(0.17 * s, (0.0, 0.0, 0.89 * s), cloth, scale=(1.05, 1.25, 0.42))
    tail = [(-0.10, 0.07, 0.90), (-0.27, 0.10, 0.87), (-0.41, 0.16, 0.80), (-0.52, 0.24, 0.71)]
    for start, end, width in zip(tail, tail[1:], (0.14, 0.12, 0.09)):
        model.plank([c * s for c in start], [c * s for c in end], width * s, 0.035 * s, cloth)
    # Medic pack on the back with a glowing cell.
    model.box((0.15 * s, 0.26 * s, 0.26 * s), (-0.20 * s, 0.0, 0.66 * s), trim, bevel=0.03)
    model.box((0.03 * s, 0.10 * s, 0.10 * s), (-0.285 * s, 0.0, 0.68 * s), glow, bevel=0.01)
    return model


def red_commander():
    model = Model("red_commander")
    p = RED
    s = 1.2
    armor = material("8f1d18", 0.45, 0.3)
    dark = material(p["armor_dark"], 0.55, 0.3)
    accent = material(p["accent"], 0.4, 0.5)
    cloth = material(p["cloth"], 0.95)
    lining = material("7a1512", 0.9)
    metal = material(GUNMETAL, 0.4, 0.7)
    glow = material("ff4a1c", 0.3, 0.0, 2.4)
    body(model, p, s, torso_color="8f1d18")
    # Both hands on a long lance carried at the hip.
    model.limb((0.0, -0.26 * s, 0.82 * s), (0.14 * s, -0.30 * s, 0.64 * s), 0.07 * s, dark)
    model.limb((0.14 * s, -0.30 * s, 0.64 * s), (0.32 * s, -0.22 * s, 0.62 * s), 0.062 * s, dark)
    model.limb((0.0, 0.26 * s, 0.82 * s), (0.20 * s, 0.22 * s, 0.66 * s), 0.07 * s, dark)
    model.limb((0.20 * s, 0.22 * s, 0.66 * s), (0.10 * s, -0.16 * s, 0.60 * s), 0.062 * s, dark)
    model.limb((-0.45 * s, -0.22 * s, 0.56 * s), (0.80 * s, -0.22 * s, 0.66 * s), 0.024 * s, metal)
    model.cone(0.075 * s, 0.0, 0.30 * s, (0.92 * s, -0.22 * s, 0.67 * s), glow, rotation=(0, 86, 0), segments=4, smooth=False)
    model.box((0.06 * s, 0.20 * s, 0.05 * s), (0.76 * s, -0.22 * s, 0.655 * s), accent, bevel=0.01)
    # Heavy angular chest, wide spiked slab shoulders.
    model.box((0.10 * s, 0.32 * s, 0.26 * s), (0.13 * s, 0.0, 0.70 * s), dark, bevel=0.015)
    model.box((0.06 * s, 0.14 * s, 0.12 * s), (0.18 * s, 0.0, 0.74 * s), accent, bevel=0.01)
    for side in (-1.0, 1.0):
        model.box((0.36 * s, 0.26 * s, 0.09 * s), (0.0, side * 0.33 * s, 0.88 * s), armor,
                  rotation=(side * 24, 0, 0), bevel=0.015)
        model.box((0.37 * s, 0.05 * s, 0.095 * s), (0.0, side * 0.44 * s, 0.83 * s), accent,
                  rotation=(side * 24, 0, 0), bevel=0.01)
        model.cone(0.05 * s, 0.0, 0.20 * s, (0.0, side * 0.36 * s, 0.99 * s), dark,
                   rotation=(side * -20, 0, 0), segments=4, smooth=False)
    # Boxy helmet with a tall crest and two swept horns.
    model.box((0.29 * s, 0.27 * s, 0.26 * s), (0.01 * s, 0.0, 1.00 * s), dark, bevel=0.035)
    model.box((0.06 * s, 0.22 * s, 0.045 * s), (0.15 * s, 0.0, 0.98 * s), glow, bevel=0.01)
    model.box((0.46 * s, 0.06 * s, 0.24 * s), (-0.04 * s, 0.0, 1.21 * s), armor, bevel=0.012)
    for side in (-1.0, 1.0):
        model.cone(0.045 * s, 0.0, 0.30 * s, (0.04 * s, side * 0.20 * s, 1.16 * s), accent,
                   rotation=(side * -38, 20, 0), segments=5, smooth=False)
    # Long cape, black outside with a crimson lining edge, flaring towards the hem.
    model.box((0.04 * s, 0.50 * s, 0.50 * s), (-0.22 * s, 0.0, 0.60 * s), cloth, rotation=(0, 16, 0), bevel=0.0)
    model.box((0.04 * s, 0.66 * s, 0.34 * s), (-0.36 * s, 0.0, 0.26 * s), cloth, rotation=(0, 34, 0), bevel=0.0)
    model.box((0.045 * s, 0.70 * s, 0.07 * s), (-0.45 * s, 0.0, 0.11 * s), lining, rotation=(0, 34, 0), bevel=0.0)
    return model


# --------------------------------------------------------------------------
# Props
# --------------------------------------------------------------------------

LEAF_COLORS = ["2c5a2a", "356b2f", "3f7a36", "4b8a3e"]
PINE_COLORS = ["1f4a33", "275a3c", "2f6a45"]


def broadleaf_tree(seed):
    rng = random.Random(seed)
    model = Model("tree")
    bark = material("5a4030", 0.9)
    lean = (rng.uniform(-0.05, 0.05), rng.uniform(-0.05, 0.05))
    model.limb((0, 0, 0), (lean[0], lean[1], 0.66), 0.095, bark, radius_end=0.06)
    for i in range(rng.randint(8, 10)):
        angle = rng.uniform(0, math.tau)
        distance = rng.uniform(0.0, 0.36)
        height = rng.uniform(0.70, 1.12) - distance * 0.45
        radius = rng.uniform(0.25, 0.35)
        leaf = material(rng.choice(LEAF_COLORS), 0.9)
        model.lump(radius, (lean[0] + math.cos(angle) * distance, lean[1] + math.sin(angle) * distance, height),
                   leaf, rng, jitter=0.12, scale=(1.0, 1.0, 0.82), smooth=True)
    return model


def pine_tree(seed):
    rng = random.Random(seed)
    model = Model("tree")
    bark = material("4c3628", 0.9)
    model.limb((0, 0, 0), (0, 0, 0.45), 0.07, bark)
    tiers = [(0.52, 0.52, 0.44), (0.41, 0.48, 0.76), (0.29, 0.44, 1.05), (0.16, 0.36, 1.30)]
    for radius, depth, height in tiers:
        needle = material(rng.choice(PINE_COLORS), 0.9)
        model.cone(radius * rng.uniform(0.93, 1.05), 0.03, depth, (0, 0, height), needle,
                   rotation=(rng.uniform(-4, 4), rng.uniform(-4, 4), rng.uniform(0, 360)), segments=9, smooth=False)
    return model


def boulder(seed):
    rng = random.Random(seed)
    model = Model("rock")
    stones = [material(c, 0.9) for c in ("8b8a86", "7c7b78", "969490")]
    model.lump(rng.uniform(0.40, 0.46), (rng.uniform(-0.04, 0.04), rng.uniform(-0.04, 0.04), 0.16), stones[0], rng,
               jitter=0.16, scale=(1.0, rng.uniform(0.82, 0.95), 0.66))
    for i in range(rng.randint(2, 3)):
        angle = rng.uniform(0, math.tau)
        distance = rng.uniform(0.34, 0.46)
        model.lump(rng.uniform(0.12, 0.20), (math.cos(angle) * distance, math.sin(angle) * distance, 0.06),
                   rng.choice(stones), rng, jitter=0.2, scale=(1.0, 1.0, 0.7), subdivisions=1)
    return model


def orichalcum(seed):
    rng = random.Random(seed)
    model = Model("orichalcum")
    base = material("5d5964", 0.9)
    model.lump(0.44, (0.0, 0.0, 0.02), base, rng, jitter=0.14, scale=(1.05, 0.95, 0.30))
    crystals = [material(c, 0.22, 0.0, 0.35) for c in ("e8952e", "f2ad3c", "d9812a")]
    bright = material("ffcf6a", 0.18, 0.0, 1.1)
    count = rng.randint(6, 8)
    for i in range(count):
        # The first crystal stands tall in the middle; the rest lean outwards around it.
        angle = rng.uniform(0, math.tau)
        distance = 0.0 if i == 0 else rng.uniform(0.12, 0.30)
        length = rng.uniform(0.78, 0.95) if i == 0 else rng.uniform(0.36, 0.66) * (1.15 - distance)
        radius = length * rng.uniform(0.15, 0.19)
        lean = distance * rng.uniform(0.9, 1.5)
        foot = Vector((math.cos(angle) * distance, math.sin(angle) * distance, 0.05))
        axis = Vector((math.cos(angle) * lean, math.sin(angle) * lean, 1.0)).normalized()
        shoulder = foot + axis * length * 0.72
        tip = foot + axis * length
        mat = bright if i == 0 else rng.choice(crystals)
        for start, end, r1, r2 in ((foot, shoulder, radius, radius), (shoulder, tip, radius, radius * 0.06)):
            bm = bmesh.new()
            bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=6, radius1=r1, radius2=r2,
                                  depth=(end - start).length)
            part = finish_object("crystal", bm, mat, smooth=False, parent=model.root)
            part.location = (start + end) / 2.0
            part.rotation_mode = "QUATERNION"
            part.rotation_quaternion = (end - start).to_track_quat("Z", "Y")
            model.parts.append(part)
    return model


# --------------------------------------------------------------------------
# Sprite list and rendering
# --------------------------------------------------------------------------

def variants(builder, seeds):
    return [lambda seed=seed: builder(seed) for seed in seeds]


SPRITES = [
    # name, frame size in cells, camera target height, list of model builders or one unit builder
    {"name": "blue_trooper", "frame": (2.0, 2.0), "target_z": 0.45, "unit": blue_trooper},
    {"name": "blue_commander", "frame": (2.5, 2.5), "target_z": 0.50, "unit": blue_commander},
    {"name": "red_trooper", "frame": (2.0, 2.0), "target_z": 0.45, "unit": red_trooper},
    {"name": "red_commander", "frame": (2.5, 2.5), "target_z": 0.50, "unit": red_commander},
    {"name": "tree", "frame": (2.5, 2.5), "target_z": 0.60,
     "models": variants(broadleaf_tree, [11, 12, 13, 14]) + variants(pine_tree, [21, 22])},
    {"name": "rock", "frame": (2.0, 2.0), "target_z": 0.15, "models": variants(boulder, [31, 32, 33, 34])},
    {"name": "orichalcum", "frame": (2.0, 2.0), "target_z": 0.30, "models": variants(orichalcum, [41, 42, 43, 44])},
]


def main():
    arguments = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_dir = os.path.abspath(arguments[0] if arguments else "art_build/frames")
    name_filter = arguments[1] if len(arguments) > 1 else ""
    os.makedirs(out_dir, exist_ok=True)

    scene, camera = setup_scene()
    manifest = {}
    for sprite in SPRITES:
        name = sprite["name"]
        width, height = sprite["frame"]
        aim_camera(scene, camera, sprite["frame"], sprite["target_z"])
        frame_count = DIRECTIONS if "unit" in sprite else len(sprite["models"])
        manifest[name] = {
            "frames": frame_count,
            "frame_width": scene.render.resolution_x,
            "frame_height": scene.render.resolution_y,
            # Pixel that the model's ground origin lands on, from the frame's top-left.
            "anchor": [
                scene.render.resolution_x / 2.0,
                scene.render.resolution_y / 2.0 + sprite["target_z"] * math.sin(TILT) * PX_PER_CELL,
            ],
            "px_per_cell": PX_PER_CELL,
            "directional": "unit" in sprite,
        }
        if name_filter and name_filter not in name:
            continue
        if "unit" in sprite:
            model = sprite["unit"]()
            model.root.scale = (UNIT_SCALE, UNIT_SCALE, UNIT_SCALE)
            for direction in range(DIRECTIONS):
                # Screen-clockwise turn = negative rotation about Blender's Z.
                model.root.rotation_euler = (0.0, 0.0, -direction * math.tau / DIRECTIONS)
                scene.render.filepath = os.path.join(out_dir, "%s_%d.png" % (name, direction))
                bpy.ops.render.render(write_still=True)
            model.remove()
        else:
            for index, build in enumerate(sprite["models"]):
                model = build()
                scene.render.filepath = os.path.join(out_dir, "%s_%d.png" % (name, index))
                bpy.ops.render.render(write_still=True)
                model.remove()

    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent="\t")
    print("RENDER_SPRITES_DONE %s" % out_dir)


main()
