class_name ViewConfig
extends RefCounted
## Presentation scale settings. All values are provisional (design question Q001).
##
## Three independent quantities:
##   1. Logical grid  - GridCoords.CELL_SIZE, world units per cell (gameplay).
##   2. Artwork       - TERRAIN_ART_PX, source pixels per terrain tile.
##   3. Camera zoom   - DEFAULT_ZOOM etc., screen pixels per world unit.
## Art is scaled to fit a cell (art_scale()), so changing any one of the three
## does not require changing the other two. Gameplay code never reads this file.

## Source resolution of one square terrain tile, in pixels.
const TERRAIN_ART_PX := 64

## Camera zoom when a battle starts.
const DEFAULT_ZOOM := 2.0
## Closest zoom. The furthest zoom is whatever fits the whole map on screen.
const MAX_ZOOM := 4.0
## Zoom multiplier per mouse-wheel notch.
const ZOOM_STEP := 1.15


## Scale that makes one terrain tile exactly cover one logical cell.
static func art_scale() -> float:
	return float(GridCoords.CELL_SIZE) / float(TERRAIN_ART_PX)
