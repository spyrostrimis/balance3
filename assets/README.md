# assets/

Everything here is original art made for Balance by the scripts in
`tools/art/`. Nothing is copied or derived from any other game.

| Folder | Contents | Made by |
| --- | --- | --- |
| `terrain/` | Seamless ground textures and `variation.png` (noise the ground shader uses) | `tools/art/make_ground_textures.py` (Python + Pillow) |
| `sprites/` | Unit and scenery sprite sheets, and `sprites.json` describing them | `tools/art/render_sprites.py` (Blender) then `tools/art/pack_sprites.py` |

Do not edit these images by hand: change the script and run
`tools\build_art.ps1`, so the art stays reproducible. Hand-made or licensed
art added later belongs in its own folder with a note of its origin and licence.

Commit the `*.import` file next to each image. They have
`mipmaps/generate=true`, which keeps the art clean when zoomed out; set the
same on any new image.
