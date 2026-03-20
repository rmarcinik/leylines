function Invoke-Build {
    param(
        [string]$BuildDir = ".\build"
    )

    $ErrorActionPreference = "Stop"

    $GODOT  = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
    $PRESET = "Windows Desktop"
    $EXE    = "leylines.exe"
    $ZIP    = "leylines-dist.zip"
    $FILES  = @(
        "leylines.exe",
        "steam_api64.dll",
        "libgodotsteam.windows.template_release.x86_64.dll"
    )

    Push-Location $BuildDir
    try {
        Write-Host "Exporting '$PRESET'..."
        & $GODOT --headless --export-release $PRESET $EXE

        Write-Host "Zipping...$ZIP"
        if (Test-Path $ZIP) { Remove-Item $ZIP }
        Compress-Archive -Path $FILES -DestinationPath $ZIP

        Write-Host "Done -> $ZIP"
    } finally {
        Pop-Location
    }
}

Invoke-Build @args
