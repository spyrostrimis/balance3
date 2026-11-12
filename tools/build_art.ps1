# Regenerates all of Balance's art from the scripts in tools\art:
#   1. ground textures (Python + Pillow)      -> assets\terrain\
#   2. model renders   (Blender, about 1 min) -> art_build\frames\  (not committed)
#   3. sprite sheets   (Python + Pillow)      -> assets\sprites\
#
# Usage:  powershell -ExecutionPolicy Bypass -File tools\build_art.ps1
# Blender is taken from -Blender, then $env:BLENDER, then the default path below.
# Afterwards run tools\check.ps1 so Godot re-imports the changed images.
param(
	[string]$Blender = $env:BLENDER
)

if (-not $Blender) {
	$Blender = 'C:\Blender\blender.exe'
}
if (-not (Test-Path $Blender)) {
	Write-Host "Blender executable not found: $Blender"
	Write-Host 'Pass -Blender <path> or set the BLENDER environment variable.'
	exit 2
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# .gdignore stops Godot from importing the intermediate frames.
New-Item -ItemType Directory -Force art_build | Out-Null
if (-not (Test-Path art_build\.gdignore)) {
	New-Item -ItemType File art_build\.gdignore | Out-Null
}

Write-Host '== Ground textures'
python tools\art\make_ground_textures.py assets\terrain
if ($LASTEXITCODE -ne 0) { Write-Host 'BUILD ART FAILED'; exit 1 }

Write-Host '== Blender renders'
$output = & $Blender --background --factory-startup --python tools\art\render_sprites.py -- art_build\frames 2>&1 | ForEach-Object { $_.ToString() }
$blenderExit = $LASTEXITCODE
$output | Where-Object { $_ -match 'Traceback|Error|RENDER_SPRITES_DONE|^\s+File ' } | ForEach-Object { Write-Host "   $_" }
if ($blenderExit -ne 0 -or -not ($output -match 'RENDER_SPRITES_DONE')) { Write-Host 'BUILD ART FAILED'; exit 1 }

Write-Host '== Sprite sheets'
python tools\art\pack_sprites.py art_build\frames assets\sprites
if ($LASTEXITCODE -ne 0) { Write-Host 'BUILD ART FAILED'; exit 1 }

Write-Host 'BUILD ART DONE'
exit 0
