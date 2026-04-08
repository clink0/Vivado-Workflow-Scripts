# HW11 T1 — Pmod OLED static text display (no Picoblaze)
# Run from repo root: .\HW11\T1\build.ps1

$RepoRoot = Split-Path (Split-Path $PSScriptRoot)
Write-Host "=== HW11 T1: Pmod OLED Character Display ==="
python "$RepoRoot\run_hardware.py" "HW11\T1"
