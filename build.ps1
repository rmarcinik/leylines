function Invoke-Build {
    $ErrorActionPreference = "Stop"

    $GODOT  = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
    $PRESET = "Windows Desktop"
    $EXE    = ".\build\leylines.exe"
    $ZIP    = ".\build\leylines-dist.zip"
    $FILES  = @(
        $EXE,
        ".\build\steam_api64.dll",
        ".\build\libgodotsteam.windows.template_release.x86_64.dll"
    )

    Push-Location $PSScriptRoot
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
