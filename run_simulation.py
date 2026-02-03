#!/usr/bin/env python3
"""
Integrated Vivado Simulation Workflow with GUI
Automatically creates project, runs simulation, and opens waveform viewer
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
# Terminal UI  (mirrored exactly from run_hardware.py)
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
# Verilog helpers
# ─────────────────────────────────────────────────────────────
def find_verilog_files(source_dir):
    """Find all .v files, separating design and testbench"""
    source_path = Path(source_dir).resolve()
    design_files = []
    testbench_files = []

    for vfile in source_path.glob("*.v"):
        if "_tb" in vfile.stem.lower() or "_test" in vfile.stem.lower() or "testbench" in vfile.stem.lower():
            testbench_files.append(vfile)
        else:
            design_files.append(vfile)

    return design_files, testbench_files, source_path

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


# ─────────────────────────────────────────────────────────────
# Tcl generation  (shared between GUI and batch paths)
# ─────────────────────────────────────────────────────────────
def build_tcl_project(project_name, project_dir, board_cfg, design_files,
                      testbench_files, constraint_file, design_top, testbench_top):
    """Generate the project-setup portion of the Tcl script.
    Returns the Tcl string up to (but not including) the simulation commands."""
    tcl = f"""
create_project {project_name} {{{project_dir}}} -part {board_cfg['part']} -force

if {{[catch {{set_property board_part {board_cfg['board_part']} [current_project]}}]}} {{
    puts "Note: Board part not available, using part only"
}}

set_property target_language Verilog [current_project]
"""
    for vfile in design_files:
        tcl += f'add_files -norecurse {{{vfile}}}\n'

    for vfile in testbench_files:
        tcl += f'add_files -fileset sim_1 -norecurse {{{vfile}}}\n'

    if constraint_file:
        tcl += f'add_files -fileset constrs_1 -norecurse {{{constraint_file[0]}}}\n'

    tcl += f'set_property top {design_top} [current_fileset]\n'
    tcl += f'set_property top {testbench_top} [get_filesets sim_1]\n'

    tcl += """
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
"""
    return tcl


# ─────────────────────────────────────────────────────────────
# Main flow
# ─────────────────────────────────────────────────────────────
def create_and_simulate(source_dir, sim_time="1000ns", open_gui=True, board="basys3", vivado_path="vivado"):
    """Create project and run simulation"""

    design_files, testbench_files, source_path = find_verilog_files(source_dir)

    # ── early validation ─────────────────────────────────────
    if not design_files:
        print("\n  ERROR: No Verilog design files found!")
        return False

    if not testbench_files:
        print("\n  ERROR: No testbench files found!")
        print("          Testbench files need '_tb', '_test', or 'testbench' in the name")
        return False

    design_top    = detect_top_module(design_files[0])
    testbench_top = detect_top_module(testbench_files[0])

    if not design_top:
        print(f"\n  ERROR: Could not detect module name in: {design_files[0]}")
        return False
    if not testbench_top:
        print(f"\n  ERROR: Could not detect module name in: {testbench_files[0]}")
        return False

    project_name = source_path.name
    project_dir  = source_path / "vivado_project"

    # Constraint file -- script dir first, then source dir
    script_dir = Path(__file__).parent.resolve()
    constraint_file = list(script_dir.glob("*.xdc"))
    if not constraint_file:
        constraint_file = list(source_path.glob("*.xdc"))

    # ── summary ──────────────────────────────────────────────
    banner("Vivado Simulation Flow")
    print(f"  Project     {project_name}")
    print(f"  Design      {design_top}")
    print(f"  Testbench   {testbench_top}")
    print(f"  Sim time    {sim_time}")
    print(f"  Mode        {'GUI' if open_gui else 'Batch'}")
    divider()
    print("  Design files")
    for df in design_files:
        print(f"    {df.name}")
    print("  Testbench files")
    for tf in testbench_files:
        print(f"    {tf.name}")
    if constraint_file:
        print("  Constraints")
        print(f"    {constraint_file[0].name}")
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

    # ── shared project Tcl ───────────────────────────────────
    tcl_project = build_tcl_project(
        project_name, project_dir, board_cfg,
        design_files, testbench_files, constraint_file,
        design_top, testbench_top
    )

    # ── GUI mode ─────────────────────────────────────────────
    if open_gui:
        tcl_script = tcl_project + f"""
launch_simulation -mode behavioral

run {sim_time}

catch {{
    add_wave {{/*}}
}}
"""
        tcl_file = source_path / "run_sim_gui.tcl"
        with open(tcl_file, 'w') as f:
            f.write(tcl_script)

        print()
        with Spinner("Opening Vivado GUI"):
            cmd = [vivado_path, "-mode", "gui", "-source", str(tcl_file)]
            # GUI mode blocks until the user closes Vivado
            subprocess.run(cmd, cwd=str(source_path))

        banner("Done")
        print("  Vivado closed. Simulation complete.")
        divider()
        return True

    # ── Batch mode ───────────────────────────────────────────
    else:
        tcl_script = tcl_project + f"""
launch_simulation -mode behavioral

run {sim_time}

save_wave_config

close_sim
close_project

exit 0
"""
        tcl_file = source_path / "run_sim.tcl"
        with open(tcl_file, 'w') as f:
            f.write(tcl_script)

        print()
        with ProgressBar("Running simulation") as pb:
            success, output = run_vivado_batch(tcl_file, vivado_path, source_path)
            if not success:
                pb.fail()

        if not success:
            errors = [l.strip() for l in output.splitlines() if "ERROR" in l]
            if errors:
                print(f"\n  {errors[-1]}")
            print(f"\n  Full log: {project_dir}")
            return False

        # ── find and report waveform file ────────────────────
        banner("Done")
        sim_dir = project_dir / f"{project_name}.sim" / "sim_1" / "behav" / "xsim"
        if sim_dir.exists():
            wdb_files = list(sim_dir.glob("*.wdb"))
            if wdb_files:
                print(f"  Waveform    {wdb_files[0]}")
                print()
                print("  To view:")
                print(f"    vivado -mode gui")
                print(f"    File -> Open Waveform Database -> {wdb_files[0].name}")
        print()
        divider()
        return True


# ─────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────
def main():
    if len(sys.argv) < 2:
        print("\n  Usage:  python run_simulation_gui.py <source_dir> [options]")
        print()
        print("  Options:")
        print("    --time <duration>  Simulation time (default: 1000ns)")
        print("                       Examples: 100ns, 10us, 1ms")
        print("    --gui              Open waveform viewer automatically (default)")
        print("    --no-gui           Run in batch mode, save waveform for later")
        print("    --board <n>        Target board (default: basys3)")
        print()
        print("  Examples:")
        print("    python run_simulation_gui.py .")
        print("    python run_simulation_gui.py . --time 500ns")
        print("    python run_simulation_gui.py . --no-gui")
        print("    python run_simulation_gui.py HW3T3 --time 10us")
        print()
        sys.exit(1)

    source_dir = sys.argv[1]
    sim_time   = "1000ns"
    board      = "basys3"
    open_gui   = True

    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "--time" and i + 1 < len(sys.argv):
            sim_time = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--board" and i + 1 < len(sys.argv):
            board = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--no-gui":
            open_gui = False
            i += 1
        elif sys.argv[i] == "--gui":
            open_gui = True
            i += 1
        else:
            i += 1

    vivado_path = "C:/Xilinx/Vivado/2018.3/bin/vivado.bat"

    success = create_and_simulate(source_dir, sim_time, open_gui, board, vivado_path)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
