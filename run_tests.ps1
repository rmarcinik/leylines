function Invoke-Tests {
    $ErrorActionPreference = "Stop"

    $GODOT    = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" }
    $USER_DIR = "$env:APPDATA\Godot\app_userdata\leylines"
    $MP_FILES = @("mp_test_host.json", "mp_test_guest_1.json", "mp_test_guest_2.json")
    $PASSED   = $true

    Push-Location $PSScriptRoot
    try {
        # ── Unit + Integration (gdUnit4) ──────────────────────────────────────

        Write-Host "--- gdUnit4 tests ---"
        $proc = Start-Process $GODOT `
            -ArgumentList @("--headless", "--path", ".", "-s",
                "res://addons/gdUnit4/bin/GdUnitCmdTool.gd",
                "-a", "res://tests/unit",
                "-a", "res://tests/integration", "-c") `
            -NoNewWindow -PassThru -Wait
        if ($proc.ExitCode -ne 0) {
            Write-Host "FAIL gdUnit4 (exit $($proc.ExitCode))"
            $PASSED = $false
        } else {
            Write-Host "PASS gdUnit4"
        }

        # ── Multiplayer connection test (3 processes) ─────────────────────────

        Write-Host "--- multiplayer test ---"

        foreach ($f in $MP_FILES) {
            $p = Join-Path $USER_DIR $f
            if (Test-Path $p) { Remove-Item $p -Force }
        }

        $HOST_ARGS   = @("--headless", "--path", ".", "-s", "res://tests/mp_runners/mp_host_runner.gd")
        $GUEST_ARGS1 = @("--headless", "--path", ".", "-s", "res://tests/mp_runners/mp_guest_runner.gd", "--", "--guest-index", "1")
        $GUEST_ARGS2 = @("--headless", "--path", ".", "-s", "res://tests/mp_runners/mp_guest_runner.gd", "--", "--guest-index", "2")

        $hostProc = Start-Process $GODOT -ArgumentList $HOST_ARGS -NoNewWindow -PassThru
        Start-Sleep -Seconds 2

        $g1Proc = Start-Process $GODOT -ArgumentList $GUEST_ARGS1 -NoNewWindow -PassThru
        Start-Sleep -Milliseconds 500
        $g2Proc = Start-Process $GODOT -ArgumentList $GUEST_ARGS2 -NoNewWindow -PassThru

        $deadline = (Get-Date).AddSeconds(30)
        foreach ($p in @($hostProc, $g1Proc, $g2Proc)) {
            $ms = [int]($deadline - (Get-Date)).TotalMilliseconds
            if ($ms -le 0) { $p.Kill() }
            elseif (-not $p.WaitForExit($ms)) { $p.Kill() }
        }

        foreach ($f in $MP_FILES) {
            $full = Join-Path $USER_DIR $f
            if (-not (Test-Path $full)) {
                Write-Host "FAIL $f (missing result file)"
                $PASSED = $false
                continue
            }
            $d = Get-Content $full | ConvertFrom-Json
            if (-not $d.passed) {
                Write-Host "FAIL $f`: $($d.message)"
                $PASSED = $false
            } else {
                Write-Host "PASS $f`: $($d.message)"
            }
        }

        if ($PASSED) { Write-Host "Done — all tests passed" }
        else         { throw "one or more tests failed" }

    } finally {
        Pop-Location
    }
}

Invoke-Tests @args
