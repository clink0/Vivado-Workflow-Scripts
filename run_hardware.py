#!/usr/bin/env python3
"""
Integrated Vivado Hardware Workflow (Clean Output)
Automatically creates project from .v files and programs FPGA
"""

import subprocess
import sys
import os
from pathlib import Path
import shutil
import threading
import time

# Fix Windows PowerShell encoding for unicode output
if sys.platform == "win32":
    os.system("chcp 65001 >nul 2>&1")

# ─────────────────────────────────────────────────────────────
# Terminal UI
# ─────────────────────────────────────────────────────────────
W = 60  # banner width

def banner(title):
    print("\n" + "=" * W)
    print(f"  {title}")
    print("=" * W)

def divider():
    print("-" * W)

class Spinner:
    """Animated spinner that runs on a background thread.
    Usage:
        with Spinner("Doing thing"):
            ...work...
    Prints  ✓  on success, ✗  on failure.
    Call .fail() before the block exits to mark it failed.
    """
    _frames = ['⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏']

    def __init__(self, message):
        self.message = message
        self._running = False
        self._failed = False
        self._thread = None

    def _loop(self):
        idx = 0
        while self._running:
            sys.stdout.write(f'\r  {self._frames[idx % len(self._frames)]}  {self.message}...')
            sys.stdout.flush()
            idx += 1
            time.sleep(0.08)

    def fail(self):
        self._failed = True

    def __enter__(self):
        self._running = True
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()
        return self

    def __exit__(self, *_):
        self._running = False
        self._thread.join()
        symbol = '✗' if self._failed else '✓'
        sys.stdout.write(f'\r  {symbol}  {self.message}\n')
        sys.stdout.flush()


class ProgressBar:
    """Indeterminate progress bar that pulses while work is running.
    Usage:
        with ProgressBar("Doing thing"):
            ...work...
    """
    def __init__(self, message, width=40):
        self.message = message
        self.width = width
        self._running = False
        self._failed = False
        self._thread = None

    def _loop(self):
        pos = 0
        direction = 1
        bar_len = 12          # length of the bright segment
        while self._running:
            bar = [' '] * self.width
            for i in range(bar_len):
                idx = (pos + i) % self.width
                bar[idx] = '█' if i == 0 or i == bar_len - 1 else '▓'
            sys.stdout.write(f'\r  [{("".join(bar))}]  {self.message}')
            sys.stdout.flush()
            pos += direction
            if pos >= self.width or pos <= 0:
                direction *= -1
            time.sleep(0.04)

    def fail(self):
        self._failed = True

    def __enter__(self):
        self._running = True
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()
        return self

    def __exit__(self, *_):
        self._running = False
        self._thread.join()
        symbol = '✗' if self._failed else '✓'
        sys.stdout.write(f'\r  {symbol}  {self.message}\n')
        sys.stdout.flush()


# ─────────────────────────────────────────────────────────────
# Verilog helpers  (unchanged logic)
# ─────────────────────────────────────────────────────────────
def find_verilog_files(source_dir):
    """Find all .v files, separating top modules from design modules"""
    source_path = Path(source_dir).resolve()
    design_files = []
    top_file = None

    for vfile in source_path.glob("*.v"):
        if "_tb" in vfile.stem.lower() or "_test" in vfile.stem.lower() or "testbench" in vfile.stem.lower():
            continue
        elif "_top" in vfile.stem.lower():
            top_file = vfile
            design_files.append(vfile)
        else:
            design_files.append(vfile)

    return design_files, top_file, source_path

def detect_top_module(vfile):
    """Extract module name from Verilog file - handles various formatting"""
    with open(vfile, 'r') as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("/*") or stripped == "":
                continue
            if stripped.startswith("module "):
                remainder = stripped[len("module"):].strip()
                module_name = ""
                for ch in remainder:
                    if ch in ('(', ' ', '\t', ';'):
                        break
                    module_name += ch
                if module_name:
                    return module_name
    return None


# ─────────────────────────────────────────────────────────────
# Vivado helpers
# ─────────────────────────────────────────────────────────────
def run_vivado_batch(tcl_file, vivado_path, cwd):
    """Run Vivado in batch mode, return (success, stdout_text)"""
    cmd = [vivado_path, "-mode", "batch", "-source", str(tcl_file)]
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        universal_newlines=True,
        cwd=str(cwd)
    )
    output = process.stdout.read()
    process.wait()
    return process.returncode == 0, output

def open_vivado_gui(project_dir, vivado_path):
    """Launch Vivado GUI with the project already open, then open Hardware Manager.
    This is fire-and-forget -- we don't wait for the user to close it."""
    project_file = list(project_dir.glob("*.viv"))
    if not project_file:
        return False

    # Tcl that opens the project and launches the hardware manager
    tcl = (
        f'open_project {{{project_file[0]}}}\n'
        'open_hw_manager\n'
        'connect_hw_target\n'
    )
    tcl_file = project_dir / "open_hw.tcl"
    with open(tcl_file, 'w') as f:
        f.write(tcl)

    # Launch GUI -- don't wait, user interacts from here
    subprocess.Popen(
        [vivado_path, "-mode", "gui", "-source", str(tcl_file)],
        cwd=str(project_dir)
    )
    return True


# ─────────────────────────────────────────────────────────────
# Main flow  (logic unchanged, output cleaned up)
# ─────────────────────────────────────────────────────────────
def create_and_program(source_dir, program_device=True, board="basys3", vivado_path="vivado"):
    """Create project and run hardware flow"""

    design_files, top_file, source_path = find_verilog_files(source_dir)

    if not design_files:
        print("\n  ERROR: No Verilog design files found!")
        return False

    if not top_file:
        print("\n  ERROR: No top module file found!")
        print("          Hardware flow requires a file with '_top' in the name")
        print("          Example: two_bit_comparator_top.v")
        return False

    design_top = detect_top_module(top_file)
    if not design_top:
        print(f"\n  ERROR: Could not detect module name in: {top_file}")
        return False

    project_name = source_path.name
    project_dir  = source_path / "vivado_project"

    # Constraint file -- script dir first, then source dir
    script_dir = Path(__file__).parent.resolve()
    constraint_files = list(script_dir.glob("*.xdc"))
    if not constraint_files:
        constraint_files = list(source_path.glob("*.xdc"))

    if not constraint_files:
        print("\n  WARNING: No constraint file (.xdc) found!")
        response = input("  Continue anyway? (y/n): ")
        if response.lower() != 'y':
            return False

    # ── summary ──────────────────────────────────────────────
    banner("Vivado Hardware Flow")
    print(f"  Project     {project_name}")
    print(f"  Top         {design_top}")
    print(f"  Target      {board.upper()}")
    divider()
    print("  Files")
    for df in design_files:
        tag = "  [top]" if df == top_file else ""
        print(f"    {df.name}{tag}")
    if constraint_files:
        print("  Constraints")
        print(f"    {constraint_files[0].name}")
    divider()

    # ── board config ─────────────────────────────────────────
    board_configs = {
        "basys3": {"part": "xc7a35tcpg236-1",  "board_part": "digilentinc.com:basys3:part0:1.2"},
        "arty":   {"part": "xc7a35ticsg324-1L","board_part": "digilentinc.com:arty-a7-35:part0:1.1"},
    }
    if board not in board_configs:
        board = "basys3"
    board_cfg = board_configs[board]

    # ── clean old project ────────────────────────────────────
    if project_dir.exists():
        with Spinner("Cleaning old project"):
            shutil.rmtree(project_dir)

    # ── generate Tcl ─────────────────────────────────────────
    tcl_script = f"""
create_project {project_name} {{{project_dir}}} -part {board_cfg['part']} -force

if {{[catch {{set_property board_part {board_cfg['board_part']} [current_project]}}]}} {{
    puts "Note: Board part not available, using part only"
}}

set_property target_language Verilog [current_project]
"""
    for vfile in design_files:
        tcl_script += f'add_files -norecurse {{{vfile}}}\n'

    if constraint_files:
        tcl_script += f'add_files -fileset constrs_1 -norecurse {{{constraint_files[0]}}}\n'

    tcl_script += f'set_property top {design_top} [current_fileset]\n'

    tcl_script += """
update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
if {$synth_status != "synth_design Complete!"} {
    puts "ERROR: Synthesis failed: $synth_status"
    exit 1
}

reset_run impl_1
launch_runs impl_1
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
if {$impl_status != "route_design Complete!"} {
    puts "ERROR: Implementation failed: $impl_status"
    exit 1
}

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
set bit_status [get_property STATUS [get_runs impl_1]]
if {$bit_status != "write_bitstream Complete!"} {
    puts "ERROR: Bitstream generation failed: $bit_status"
    exit 1
}

close_project
"""

    tcl_file = source_path / "run_hardware.tcl"
    with open(tcl_file, 'w') as f:
        f.write(tcl_script)

    # ── run Vivado batch ─────────────────────────────────────
    print()
    with ProgressBar("Running Vivado  Synth + Impl + Bitstream") as pb:
        success, output = run_vivado_batch(tcl_file, vivado_path, source_path)
        if not success:
            pb.fail()

    if not success:
        # Pull the last ERROR line out of Vivado output for the user
        errors = [l.strip() for l in output.splitlines() if "ERROR" in l]
        if errors:
            print(f"\n  {errors[-1]}")
        print(f"\n  Full log: {source_path / 'vivado_project'}")
        return False

    # ── success ──────────────────────────────────────────────
    bit_file = project_dir / f"{project_name}.runs" / "impl_1" / f"{design_top}.bit"

    banner("Done")
    if bit_file.exists():
        print(f"  Bitstream   {bit_file}")
    print()

    # ── open Vivado GUI for programming ──────────────────────
    if program_device:
        with Spinner("Opening Vivado Hardware Manager"):
            opened = open_vivado_gui(project_dir, vivado_path)
        if opened:
            print()
            print("  Vivado is opening. When it's ready:")
            print("    1. Wait for Hardware Manager to connect")
            print("    2. Right-click the device -> Program Device")
            print("    3. Bitstream file is already set")
        else:
            print("  Could not auto-open Vivado. Open it manually and")
            print(f"  program {bit_file.name} via Hardware Manager.")
    print()
    divider()
    return True


# ─────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────
def main():
    if len(sys.argv) < 2:
        print("\n  Usage:  python run_hardware.py <source_dir> [options]")
        print()
        print("  Options:")
        print("    --board <n>        Target board (default: basys3)")
        print("    --no-program       Skip opening Hardware Manager")
        print()
        print("  Examples:")
        print("    python run_hardware.py HW3T3")
        print("    python run_hardware.py . --board basys3")
        print("    python run_hardware.py HW3T3 --no-program")
        print()
        sys.exit(1)

    source_dir     = sys.argv[1]
    board          = "basys3"
    program_device = True

    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "--board" and i + 1 < len(sys.argv):
            board = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--no-program":
            program_device = False
            i += 1
        else:
            i += 1

    vivado_path = "C:/Xilinx/Vivado/2018.3/bin/vivado.bat"

    success = create_and_program(source_dir, program_device, board, vivado_path)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
