# build.ps1 — export and zip for distribution
# Usage: .\build.ps1
# Requires Godot 4 to be on PATH as 'godot4' (adjust $GODOT if needed)
$ErrorActionPreference = "Stop"

$GODOT  = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
$PRESET = "Windows Desktop"
$EXE    = ".\build\leylines.exe"
$DLL    = ".\build\steam_api64.dll"
$ZIP    = ".\build\leylines-dist.zip"

Write-Host "Exporting '$PRESET'..."
& $GODOT --headless --export-release $PRESET $EXE

Write-Host "Zipping..."
if (Test-Path $ZIP) { Remove-Item $ZIP }
Compress-Archive -Path $EXE, $DLL -DestinationPath $ZIP

Write-Host "Done -> $ZIP"
