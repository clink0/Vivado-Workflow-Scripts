# HW10 T2 - Button press: toggle LED[0], count 0-F on 7-segment
# Run from repo root: .\HW10\T2\build.ps1

$TaskDir  = $PSScriptRoot
$RepoRoot = Split-Path (Split-Path $PSScriptRoot)
$TaskRel  = "HW10\T2"
$Kcpsm    = "$RepoRoot\Lab8\kcpsm6_files"

Write-Host "=== HW10 T2: Button ISR - Toggle LED + 7-Seg Counter ==="

Copy-Item "$Kcpsm\kcpsm6.v"   "$TaskDir\kcpsm6.v"   -Force
Copy-Item "$Kcpsm\ROM_form.v" "$TaskDir\ROM_form.v"  -Force

if (Test-Path "$TaskDir\prog.v") { Remove-Item "$TaskDir\prog.v" }

Push-Location $TaskDir
& "$Kcpsm\kcpsm6.exe" prog.psm
Pop-Location

# kcpsm6.exe spawns a subprocess and returns early — keep ROM_form.v alive
# until prog.v actually appears, then clean up.
$timeout = 30
$elapsed = 0
Write-Host "Waiting for prog.v..."
while (-not (Test-Path "$TaskDir\prog.v") -and $elapsed -lt $timeout) {
    Start-Sleep -Seconds 1
    $elapsed++
}

Remove-Item "$TaskDir\ROM_form.v" -ErrorAction SilentlyContinue

if (-not (Test-Path "$TaskDir\prog.v")) {
    Write-Host "ERROR: prog.v was not generated after $timeout seconds. Check kcpsm6.exe output."
    exit 1
}

Write-Host "Assembly succeeded. Starting Vivado..."
python "$RepoRoot\run_hardware.py" $TaskRel
