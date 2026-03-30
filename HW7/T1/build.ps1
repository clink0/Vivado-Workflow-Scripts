# HW7 T1 - Build script (SPI loopback demo)
# Run from repo root: .\HW7\T1\build.ps1

$TaskDir  = $PSScriptRoot
$RepoRoot = Split-Path (Split-Path $PSScriptRoot)
$TaskRel  = "HW7\T1"

Write-Host "=== HW7 T1: SPI loopback demo ==="

python "$RepoRoot\run_hardware.py" $TaskRel
