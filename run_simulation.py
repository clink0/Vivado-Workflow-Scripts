#!/usr/bin/env python3
"""
Integrated Vivado Simulation Workflow
Automatically creates project from .v files and runs simulation
"""

import subprocess
import sys
from pathlib import Path
import shutil

def find_verilog_files(source_dir):
    """Find all .v files"""
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
    """Extract module name from Verilog file"""
    with open(vfile, 'r') as f:
        for line in f:
            if line.strip().startswith("module"):
                module_name = line.split()[1].split('(')[0].strip()
                return module_name
    return None

def create_and_simulate(source_dir, sim_time="1000ns", board="basys3", vivado_path="vivado"):
    """Create project and run simulation"""
    
    design_files, testbench_files, source_path = find_verilog_files(source_dir)
    
    if not design_files:
        print("ERROR: No Verilog design files found!")
        return False
    
    if not testbench_files:
        print("ERROR: No testbench files found!")
        print("Testbench files should contain '_tb', '_test', or 'testbench' in the name")
        return False
    
    # Get module names
    design_top = detect_top_module(design_files[0])
    testbench_top = detect_top_module(testbench_files[0])
    
    project_name = source_path.name
    project_dir = source_path / "vivado_project"
    constraint_file = list(source_path.glob("*.xdc"))
    
    print("=" * 70)
    print("Integrated Vivado Simulation Workflow")
    print("=" * 70)
    print(f"Source directory: {source_path}")
    print(f"Design files: {len(design_files)}")
    for df in design_files:
        print(f"  - {df.name}")
    print(f"Testbench files: {len(testbench_files)}")
    for tf in testbench_files:
        print(f"  - {tf.name}")
    if design_top:
        print(f"Design top module: {design_top}")
    if testbench_top:
        print(f"Testbench top module: {testbench_top}")
    print(f"Simulation time: {sim_time}")
    print("=" * 70)
    
    # Board configurations
    board_configs = {
        "basys3": {"part": "xc7a35tcpg236-1", "board_part": "digilentinc.com:basys3:part0:1.2"},
        "arty": {"part": "xc7a35ticsg324-1L", "board_part": "digilentinc.com:arty-a7-35:part0:1.1"},
    }
    
    if board not in board_configs:
        board = "basys3"
    
    board_cfg = board_configs[board]
    
    # Create Tcl script
    tcl_script = f"""
# Create project
create_project {project_name} {{{project_dir}}} -part {board_cfg['part']} -force
set_property board_part {board_cfg['board_part']} [current_project]
set_property target_language Verilog [current_project]

puts "Adding design files..."
"""
    
    for vfile in design_files:
        tcl_script += f'add_files -norecurse {{{vfile}}}\n'
    
    tcl_script += '\nputs "Adding testbench files..."\n'
    for vfile in testbench_files:
        tcl_script += f'add_files -fileset sim_1 -norecurse {{{vfile}}}\n'
    
    if constraint_file:
        tcl_script += f'add_files -fileset constrs_1 -norecurse {{{constraint_file[0]}}}\n'
    
    if design_top:
        tcl_script += f'set_property top {design_top} [current_fileset]\n'
    
    if testbench_top:
        tcl_script += f'set_property top {testbench_top} [get_filesets sim_1]\n'
    
    tcl_script += """
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "========================================="
puts "Launching simulation..."
puts "========================================="

launch_simulation -mode behavioral

"""
    
    tcl_script += f'run {sim_time}\n'
    
    tcl_script += """
puts "========================================="
puts "Simulation completed!"
puts "========================================="

# Save waveform
save_wave_config

close_sim
close_project

exit 0
"""
    
    # Clean old project
    if project_dir.exists():
        print(f"Removing old project: {project_dir}")
        shutil.rmtree(project_dir)
    
    # Write Tcl script
    tcl_file = source_path / "run_sim.tcl"
    with open(tcl_file, 'w') as f:
        f.write(tcl_script)
    
    print(f"\nGenerated Tcl script: {tcl_file}")
    print("=" * 70)
    
    # Run Vivado
    cmd = [vivado_path, "-mode", "batch", "-source", str(tcl_file)]
    
    try:
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            cwd=str(source_path)
        )
        
        for line in process.stdout:
            print(line, end='')
        
        return_code = process.wait()
        
        if return_code == 0:
            print("\n" + "=" * 70)
            print("SUCCESS: Simulation completed!")
            
            # Find waveform file
            sim_dir = project_dir / f"{project_name}.sim" / "sim_1" / "behav" / "xsim"
            if sim_dir.exists():
                wdb_files = list(sim_dir.glob("*.wdb"))
                if wdb_files:
                    print(f"\nWaveform database: {wdb_files[0]}")
                    print("\nTo view waveform in GUI:")
                    print(f"  cd {source_path}")
                    print(f"  vivado -mode gui")
                    print(f"  Then: File → Open Waveform Database → {wdb_files[0].name}")
            
            print("=" * 70)
            return True
        else:
            print(f"\nERROR: Simulation failed with return code {return_code}")
            return False
            
    except FileNotFoundError:
        print(f"ERROR: Vivado not found: {vivado_path}")
        return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False


def main():
    if len(sys.argv) < 2:
        print("Usage: python run_simulation.py <source_dir> [options]")
        print("\nOptions:")
        print("  --time <duration>  Simulation time (default: 1000ns)")
        print("                     Examples: 100ns, 10us, 1ms")
        print("  --board <name>     Target board (default: basys3)")
        print("\nExamples:")
        print("  python run_simulation.py .")
        print("  python run_simulation.py ~/my_design --time 500ns")
        print("  python run_simulation.py . --time 10us --board arty")
        sys.exit(1)
    
    source_dir = sys.argv[1]
    sim_time = "1000ns"
    board = "basys3"
    
    # Parse options
    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "--time" and i + 1 < len(sys.argv):
            sim_time = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--board" and i + 1 < len(sys.argv):
            board = sys.argv[i + 1]
            i += 2
        else:
            i += 1
    
    vivado_path = "vivado"
    
    success = create_and_simulate(source_dir, sim_time, board, vivado_path)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()