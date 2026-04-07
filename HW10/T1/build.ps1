# HW10 T1 - Button press triggers ISR, toggles LED[0]
# Run from repo root: .\HW10\T1\build.ps1

$TaskDir  = $PSScriptRoot
$RepoRoot = Split-Path (Split-Path $PSScriptRoot)
$TaskRel  = "HW10\T1"
$Kcpsm    = "$RepoRoot\Lab8\kcpsm6_files"

Write-Host "=== HW10 T1: Button ISR - Toggle LED ==="

# Copy kcpsm6 core and ROM template for assembler
Copy-Item "$Kcpsm\kcpsm6.v"    "$TaskDir\kcpsm6.v"    -Force
Copy-Item "$Kcpsm\ROM_form.v"  "$TaskDir\ROM_form.v"  -Force

# Remove stale ROM so we can detect assembly failure
if (Test-Path "$TaskDir\prog.v") { Remove-Item "$TaskDir\prog.v" }

# Assemble prog.psm -> prog.v
Push-Location $TaskDir
& "$Kcpsm\kcpsm6.exe" prog.psm
Pop-Location

Remove-Item "$TaskDir\ROM_form.v"

# kcpsm6.exe can return before it finishes writing prog.v — poll until it appears
$timeout = 30
$elapsed = 0
Write-Host "Waiting for prog.v..."
while (-not (Test-Path "$TaskDir\prog.v") -and $elapsed -lt $timeout) {
    Start-Sleep -Seconds 1
    $elapsed++
}

if (-not (Test-Path "$TaskDir\prog.v")) {
    Write-Host "ERROR: prog.v was not generated after $timeout seconds. Check kcpsm6.exe output."
    exit 1
}

Write-Host "Assembly succeeded. Starting Vivado..."
python "$RepoRoot\run_hardware.py" $TaskRel
