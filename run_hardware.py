#!/usr/bin/env python3
"""
Integrated Vivado Hardware Workflow
Automatically creates project from .v files and programs FPGA
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

def create_and_program(source_dir, program_device=True, board="basys3", vivado_path="vivado"):
    """Create project and run hardware flow"""
    
    design_files, testbench_files, source_path = find_verilog_files(source_dir)
    
    if not design_files:
        print("ERROR: No Verilog design files found!")
        return False
    
    # Get module names
    design_top = detect_top_module(design_files[0])
    
    project_name = source_path.name
    project_dir = source_path / "vivado_project"
    
    # Look for constraint file in script directory (project root)
    script_dir = Path(__file__).parent.resolve()
    constraint_files = list(script_dir.glob("*.xdc"))
    
    # Fall back to source directory if not found in script directory
    if not constraint_files:
        constraint_files = list(source_path.glob("*.xdc"))
    
    if not constraint_files:
        print("WARNING: No constraint file (.xdc) found!")
        print("Synthesis will likely fail without pin constraints.")
        response = input("Continue anyway? (y/n): ")
        if response.lower() != 'y':
            return False
    
    print("=" * 70)
    print("Integrated Vivado Hardware Workflow")
    print("=" * 70)
    print(f"Source directory: {source_path}")
    print(f"Design files: {len(design_files)}")
    for df in design_files:
        print(f"  - {df.name}")
    if constraint_files:
        print(f"Constraint file: {constraint_files[0].name}")
        if constraint_files[0].parent == script_dir:
            print(f"  (from script directory: {script_dir})")
        else:
            print(f"  (from source directory)")
    if design_top:
        print(f"Top module: {design_top}")
    print(f"Program device: {program_device}")
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
    
    if testbench_files:
        for vfile in testbench_files:
            tcl_script += f'add_files -fileset sim_1 -norecurse {{{vfile}}}\n'
    
    if constraint_files:
        tcl_script += f'add_files -fileset constrs_1 -norecurse {{{constraint_files[0]}}}\n'
    
    if design_top:
        tcl_script += f'set_property top {design_top} [current_fileset]\n'
    
    tcl_script += """
update_compile_order -fileset sources_1

puts "========================================="
puts "Running Synthesis..."
puts "========================================="

reset_run synth_1
launch_runs synth_1
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
if {$synth_status != "synth_design Complete!"} {
    puts "ERROR: Synthesis failed: $synth_status"
    exit 1
}
puts "Synthesis completed successfully"

puts "========================================="
puts "Running Implementation..."
puts "========================================="

reset_run impl_1
launch_runs impl_1
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
if {$impl_status != "route_design Complete!"} {
    puts "ERROR: Implementation failed: $impl_status"
    exit 1
}
puts "Implementation completed successfully"

puts "========================================="
puts "Generating Bitstream..."
puts "========================================="

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

set bit_status [get_property STATUS [get_runs impl_1]]
if {$bit_status != "write_bitstream Complete!"} {
    puts "ERROR: Bitstream generation failed: $bit_status"
    exit 1
}
puts "Bitstream generated successfully"

"""
    
    if program_device:
        tcl_script += """
puts "========================================="
puts "Programming Device..."
puts "========================================="

open_hw_manager
connect_hw_server -allow_non_jtag

if {[catch {open_hw_target}]} {
    puts "ERROR: Could not connect to hardware target"
    puts "Make sure FPGA board is connected and powered on"
    exit 1
}

set device [lindex [get_hw_devices] 0]
if {$device == ""} {
    puts "ERROR: No hardware device found"
    exit 1
}

current_hw_device $device
refresh_hw_device $device

set bit_file [get_property DIRECTORY [current_run]]/[get_property top [current_fileset]].bit

set_property PROGRAM.FILE $bit_file $device
program_hw_devices $device
refresh_hw_device $device

puts "Device programmed successfully!"

close_hw_target
disconnect_hw_server
close_hw_manager
"""
    
    tcl_script += """
close_project

puts "========================================="
puts "Hardware flow completed successfully!"
puts "========================================="

exit 0
"""
    
    # Clean old project
    if project_dir.exists():
        print(f"Removing old project: {project_dir}")
        shutil.rmtree(project_dir)
    
    # Write Tcl script
    tcl_file = source_path / "run_hardware.tcl"
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
            print("SUCCESS: Hardware flow completed!")
            
            # Show bitstream location
            runs_dir = project_dir / f"{project_name}.runs" / "impl_1"
            if runs_dir.exists() and design_top:
                bit_file = runs_dir / f"{design_top}.bit"
                if bit_file.exists():
                    print(f"\nBitstream file: {bit_file}")
            
            print("=" * 70)
            return True
        else:
            print(f"\nERROR: Hardware flow failed with return code {return_code}")
            return False
            
    except FileNotFoundError:
        print(f"ERROR: Vivado not found: {vivado_path}")
        return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False


def main():
    if len(sys.argv) < 2:
        print("Usage: python run_hardware.py <source_dir> [options]")
        print("\nOptions:")
        print("  --no-program    Generate bitstream but don't program device")
        print("  --board <name>  Target board (default: basys3)")
        print("\nExamples:")
        print("  python run_hardware.py .")
        print("  python run_hardware.py ~/my_design")
        print("  python run_hardware.py . --no-program")
        print("  python run_hardware.py . --board arty")
        sys.exit(1)
    
    source_dir = sys.argv[1]
    program_device = "--no-program" not in sys.argv
    
    board = "basys3"
    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "--board" and i + 1 < len(sys.argv):
            board = sys.argv[i + 1]
            i += 2
        else:
            i += 1
    
    vivado_path = "vivado"
    
    success = create_and_program(source_dir, program_device, board, vivado_path)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()