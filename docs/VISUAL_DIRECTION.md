# BALANCE — Visual Direction v0.2 (technical clarification)

## Locked intent

**Dune II visual DNA, with the polished/crisper feel of Dune Legacy HD and Dune II: The Maker.** Do *not* pursue Age of Empires II-style isometric art, cinematic photorealism, or a heavily cluttered C&C battlefield.

- **2D orthogonal projection**, grid-based world with raised-looking sprites drawn from a consistent angle.
- **Clarity first:** clean silhouettes, distinctive colors, understandable base footprints, terrain regions and resource deposits.
- **HD polish:** restrained material shading, smooth edges or tasteful pixel rendering, readable detail at normal gameplay zoom; avoid over-texturing.
- **Terrain:** large, coherent patches (forest soil, stone, desert sand, rock), subtle variation and well-defined boundaries. Different first-mission environments: Blue forest, Red desert.
- **Structures:** simple geometric industrial silhouettes, rectangular grid footprints, visibly grounded/foundation-like placement.
- **Units:** small, legible at RTS scale; teams distinguishable by more than color where possible (silhouette/markings) and should remain accessible under common color-vision deficiencies.
- **Camera:** orthographic/top-down 2D; smooth pan and adjustable zoom.
- **UI:** learn from Dune II's information architecture, but use modern controls and scalable readable text.
- **Hero concept art:** detailed illustrations can inform proportions, uniforms and story UI but are not suitable unmodified as RTS unit sprites.
- **Animation:** initially placeholder movement; later 8-direction units or equivalent, transform cycles, muzzle flashes, impact effects, restrained ambient motion.

## Scaling decisions — intentionally provisional

Logical grid cell size, source art dimensions and displayed camera zoom are different variables. Suggested experiments: **32 world units per cell**, **64×64 source art where appropriate**, and multiple camera zoom settings. Choose after testing onscreen visibility; don't permanently lock 48 vs 64 pixel tiles now.

## Asset ownership / licensing

`D:\Games\Dunes\dunedynasty` and `D:\Games\Dunes\DuneMaker` are **external reference projects**, outside the Balance Git repository and Godot project tree. They are available for the game designer's visual reference. **Coding agents should not inspect their source code or extract/import their assets** unless separately authorized after a license review. Do not modify them or copy files into Balance. Favor original/procedural placeholder artwork and properly licensed assets.

## Prototype 001 visual acceptance

- Small readable woodland battlefield, central Orichalcum rock, four Blue and four Red distinguishable placeholder units.
- Obstacles apparent at normal zoom; selection circles/feedback clear.
- Game window scales sensibly at 1920×1080.
- No dependence on copyrighted Dune artwork.
