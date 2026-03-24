#!/bin/bash
# HW6 T8 - Build script (call version)
# Run from repo root: bash HW6/T8/build_call.sh
#
# Temporarily swaps main_top.v to instantiate prog_call instead of prog,
# builds, then restores. With CALL, return goes back to output s2 so
# both s3 (0x06) and s2 (0x05) get written when sw[0]=1.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_REL="HW6/T8"
KCPSM="$REPO_ROOT/KCPSM6_Release9_30Sept14"

echo "=== HW6 T8: Jump/return/load (call version) ==="

cp "$KCPSM/Verilog/ROM_form_JTAGLoader_Vivado_2June14.v" "$TASK_DIR/ROM_form.v"
cp "$KCPSM/Verilog/kcpsm6.v" "$TASK_DIR/kcpsm6.v"

cd "$TASK_DIR"
"$KCPSM/kcpsm6.exe" prog_call.psm
cd "$REPO_ROOT"

rm "$TASK_DIR/ROM_form.v"

# Swap instantiation in main_top.v: prog -> prog_call
sed -i 's/prog #(/prog_call #(/g' "$TASK_DIR/main_top.v"

python run_hardware.py "$TASK_REL"

# Restore main_top.v
sed -i 's/prog_call #(/prog #(/g' "$TASK_DIR/main_top.v"
