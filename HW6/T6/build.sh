#!/bin/bash
# HW6 T6 - Build script
# Run from repo root: bash HW6/T6/build.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_REL="HW6/T6"
KCPSM="$REPO_ROOT/KCPSM6_Release9_30Sept14"

echo "=== HW6 T6: Mask lower 2 bits ==="

cp "$KCPSM/Verilog/ROM_form_JTAGLoader_Vivado_2June14.v" "$TASK_DIR/ROM_form.v"
cp "$KCPSM/Verilog/kcpsm6.v" "$TASK_DIR/kcpsm6.v"

cd "$TASK_DIR"
"$KCPSM/kcpsm6.exe" prog.psm
cd "$REPO_ROOT"

rm "$TASK_DIR/ROM_form.v"

python run_hardware.py "$TASK_REL"
