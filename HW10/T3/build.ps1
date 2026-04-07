# HW10 T3 - JA[0] rising edge counts on 7-segment (0-F)
# Run from repo root: .\HW10\T3\build.ps1

$TaskDir  = $PSScriptRoot
$RepoRoot = Split-Path (Split-Path $PSScriptRoot)
$TaskRel  = "HW10\T3"
$Kcpsm    = "$RepoRoot\Lab8\kcpsm6_files"

Write-Host "=== HW10 T3: JA[0] Rising Edge ISR - 7-Seg Counter ==="

Copy-Item "$Kcpsm\kcpsm6.v"   "$TaskDir\kcpsm6.v"   -Force
Copy-Item "$Kcpsm\ROM_form.v" "$TaskDir\ROM_form.v"  -Force

if (Test-Path "$TaskDir\prog.v") { Remove-Item "$TaskDir\prog.v" }

Push-Location $TaskDir
& "$Kcpsm\kcpsm6.exe" prog.psm
Pop-Location

Remove-Item "$TaskDir\ROM_form.v"

if (-not (Test-Path "$TaskDir\prog.v")) {
    Write-Host "ERROR: prog.v was not generated. Check that kcpsm6.exe ran correctly."
    exit 1
}

Write-Host "Assembly succeeded. Starting Vivado..."
python "$RepoRoot\run_hardware.py" $TaskRel
