class_name ViewConfig
extends RefCounted
## Presentation scale settings. All values are provisional (design question Q001).
##
## Three independent quantities:
##   1. Logical grid  - GridCoords.CELL_SIZE, world units per cell (gameplay).
##   2. Artwork       - source pixels per cell. Ground art uses ART_PX_PER_CELL;
##                      each sprite sheet records its own value in sprites.json.
##   3. Camera zoom   - DEFAULT_ZOOM etc., screen pixels per world unit.
## Art is always scaled to fit the grid, so changing any one of the three does
## not require changing the other two. Gameplay code never reads this file.

## Source pixels of ground art per logical cell. At DEFAULT_ZOOM on a 1080p
## screen a cell covers 64 screen pixels, so this is 2x oversampled there and
## still sharp when zoomed in or on a 4K display.
const ART_PX_PER_CELL := 128

## Camera zoom when a battle starts.
const DEFAULT_ZOOM := 2.0
## Closest zoom. The furthest zoom is whatever fits the whole map on screen.
const MAX_ZOOM := 4.0
## Zoom multiplier per mouse-wheel notch.
const ZOOM_STEP := 1.15
