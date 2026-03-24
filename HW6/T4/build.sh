#!/bin/bash
# HW6 T4 - Build script (Square Problem)
# Run from repo root: bash HW6/T4/build.sh
# REQUIRES: list_ch16_02_sio_rom.psm from Pong Chu textbook Chapter 16 resources
#           Place it in HW6/T4/ before running this script.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_REL="HW6/T4"
KCPSM="$REPO_ROOT/KCPSM6_Release9_30Sept14"
PSM="list_ch16_02_sio_rom.psm"

echo "=== HW6 T4: Square Problem ==="

if [ ! -f "$TASK_DIR/$PSM" ]; then
    echo "ERROR: $PSM not found in $TASK_REL/"
    echo "  Get it from Pong Chu textbook Ch.16 resources and place it here."
    exit 1
fi

cp "$KCPSM/Verilog/ROM_form_JTAGLoader_Vivado_2June14.v" "$TASK_DIR/ROM_form.v"
cp "$KCPSM/Verilog/kcpsm6.v" "$TASK_DIR/kcpsm6.v"

cd "$TASK_DIR"
"$KCPSM/kcpsm6.exe" "$PSM"
cd "$REPO_ROOT"

rm "$TASK_DIR/ROM_form.v"

python run_hardware.py "$TASK_REL"
