# Runs Balance's command-line checks: asset import, automated tests and a
# bounded startup of the main scene. Exits 0 only if every step succeeds
# and Godot prints no errors.
#
# Usage:  powershell -ExecutionPolicy Bypass -File tools\check.ps1
# Godot is taken from -Godot, then $env:GODOT, then the default path below.
param(
	[string]$Godot = $env:GODOT
)

if (-not $Godot) {
	$Godot = 'C:\Godot\Godot_v4.7.2-stable_win64_console.exe'
}
if (-not (Test-Path $Godot)) {
	Write-Host "Godot executable not found: $Godot"
	Write-Host 'Pass -Godot <path> or set the GODOT environment variable.'
	exit 2
}

$ErrorActionPreference = 'Continue'
$projectRoot = Split-Path -Parent $PSScriptRoot
$script:failed = $false

function Invoke-GodotStep {
	param([string]$Name, [string[]]$Arguments)

	Write-Host ''
	Write-Host "== $Name"
	Write-Host "   godot --headless --path . $($Arguments -join ' ')"
	$output = & $Godot --headless --path $projectRoot @Arguments 2>&1 | ForEach-Object { $_.ToString() }
	$exitCode = $LASTEXITCODE
	$output | ForEach-Object { Write-Host "   $_" }

	$errors = @($output | Where-Object { $_ -match '^\s*(SCRIPT |USER )?ERROR' })
	$warnings = @($output | Where-Object { $_ -match '^\s*(USER )?WARNING' })
	Write-Host "   exit code: $exitCode, errors: $($errors.Count), warnings: $($warnings.Count)"
	if ($exitCode -ne 0 -or $errors.Count -gt 0) {
		$script:failed = $true
	}
}

Invoke-GodotStep -Name 'Import' -Arguments @('--import')
Invoke-GodotStep -Name 'Tests' -Arguments @('res://tests/test_runner.tscn')
Invoke-GodotStep -Name 'Startup (main scene, 120 frames)' -Arguments @('--quit-after', '120')

Write-Host ''
if ($script:failed) {
	Write-Host 'CHECK FAILED'
	exit 1
}
Write-Host 'CHECK PASSED'
exit 0
