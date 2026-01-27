#!/usr/bin/env python3
"""
Vivado Hardware Workflow Automation Script
Automates: Synthesis -> Implementation -> Bitstream Generation -> Program Device
"""

import subprocess
import sys
import os
from pathlib import Path

class VivadoHardwareFlow:
    def __init__(self, project_path, project_name):
        """
        Initialize the Vivado hardware flow automation
        
        Args:
            project_path: Path to the Vivado project directory
            project_name: Name of the Vivado project (without .xpr extension)
        """
        self.project_path = Path(project_path).resolve()
        self.project_name = project_name
        self.project_file = self.project_path / f"{project_name}.xpr"
        
        # Check if project exists
        if not self.project_file.exists():
            raise FileNotFoundError(f"Project file not found: {self.project_file}")
    
    def create_tcl_script(self, program_device=True):
        """
        Create a Tcl script for Vivado automation
        
        Args:
            program_device: Whether to program the device after bitstream generation
        """
        tcl_commands = f"""
# Open the project
open_project {{{self.project_file}}}

# Run Synthesis
puts "========================================="
puts "Starting Synthesis..."
puts "========================================="
reset_run synth_1
launch_runs synth_1
wait_on_run synth_1

# Check synthesis status
set synth_status [get_property STATUS [get_runs synth_1]]
if {{$synth_status != "synth_design Complete!"}} {{
    puts "ERROR: Synthesis failed with status: $synth_status"
    exit 1
}}
puts "Synthesis completed successfully"

# Run Implementation
puts "========================================="
puts "Starting Implementation..."
puts "========================================="
reset_run impl_1
launch_runs impl_1
wait_on_run impl_1

# Check implementation status
set impl_status [get_property STATUS [get_runs impl_1]]
if {{$impl_status != "route_design Complete!"}} {{
    puts "ERROR: Implementation failed with status: $impl_status"
    exit 1
}}
puts "Implementation completed successfully"

# Generate Bitstream
puts "========================================="
puts "Generating Bitstream..."
puts "========================================="
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Check bitstream generation status
set bit_status [get_property STATUS [get_runs impl_1]]
if {{$bit_status != "write_bitstream Complete!"}} {{
    puts "ERROR: Bitstream generation failed with status: $bit_status"
    exit 1
}}
puts "Bitstream generated successfully"

"""
        
        if program_device:
            tcl_commands += """
# Program Device
puts "========================================="
puts "Programming Device..."
puts "========================================="

# Open hardware manager
open_hw_manager
connect_hw_server -allow_non_jtag

# Try to open target
if {{[catch {{open_hw_target}}]}} {{
    puts "ERROR: Could not connect to hardware target"
    puts "Make sure the FPGA board is connected and powered on"
    exit 1
}}

# Get the device
set device [lindex [get_hw_devices] 0]
if {{$device == ""}} {{
    puts "ERROR: No hardware device found"
    exit 1
}}

current_hw_device $device
refresh_hw_device $device

# Get bitstream file
set bit_file [get_property DIRECTORY [current_run]]/[get_property top [current_fileset]].bit

# Program the device
set_property PROGRAM.FILE $bit_file $device
program_hw_devices $device
refresh_hw_device $device

puts "Device programmed successfully!"

# Close hardware manager
close_hw_target
disconnect_hw_server
close_hw_manager
"""
        
        tcl_commands += """
# Close project
close_project

puts "========================================="
puts "Hardware flow completed successfully!"
puts "========================================="
exit 0
"""
        
        tcl_file = self.project_path / "run_hardware_flow.tcl"
        with open(tcl_file, 'w') as f:
            f.write(tcl_commands)
        
        return tcl_file
    
    def run(self, program_device=True, vivado_path="vivado"):
        """
        Execute the hardware flow
        
        Args:
            program_device: Whether to program the device after bitstream generation
            vivado_path: Path to Vivado executable (default: "vivado" from PATH)
        """
        print(f"Starting Vivado Hardware Flow for project: {self.project_name}")
        print(f"Project location: {self.project_path}")
        print("=" * 60)
        
        # Create the Tcl script
        tcl_file = self.create_tcl_script(program_device)
        print(f"Generated Tcl script: {tcl_file}")
        
        # Run Vivado in batch mode
        cmd = [
            vivado_path,
            "-mode", "batch",
            "-source", str(tcl_file)
        ]
        
        print(f"Executing command: {' '.join(cmd)}")
        print("=" * 60)
        
        try:
            # Run the command and capture output in real-time
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                cwd=str(self.project_path)
            )
            
            # Print output in real-time
            for line in process.stdout:
                print(line, end='')
            
            # Wait for completion
            return_code = process.wait()
            
            if return_code == 0:
                print("\n" + "=" * 60)
                print("SUCCESS: Hardware flow completed successfully!")
                print("=" * 60)
                return True
            else:
                print("\n" + "=" * 60)
                print(f"ERROR: Hardware flow failed with return code {return_code}")
                print("=" * 60)
                return False
                
        except FileNotFoundError:
            print(f"ERROR: Vivado executable not found at: {vivado_path}")
            print("Please ensure Vivado is installed and in your PATH,")
            print("or provide the full path to the Vivado executable.")
            return False
        except Exception as e:
            print(f"ERROR: An unexpected error occurred: {e}")
            return False


def main():
    """Main entry point for the script"""
    
    # Example usage - modify these values for your project
    # You can also accept command-line arguments
    
    if len(sys.argv) < 3:
        print("Usage: python vivado_hardware_flow.py <project_path> <project_name> [--no-program]")
        print("\nExample:")
        print("  python vivado_hardware_flow.py /path/to/vivado/project my_project")
        print("  python vivado_hardware_flow.py /path/to/vivado/project my_project --no-program")
        sys.exit(1)
    
    project_path = sys.argv[1]
    project_name = sys.argv[2]
    program_device = "--no-program" not in sys.argv
    
    # Optional: specify custom Vivado path
    # vivado_path = "/tools/Xilinx/Vivado/2023.2/bin/vivado"
    vivado_path = "vivado"  # Use PATH by default
    
    try:
        flow = VivadoHardwareFlow(project_path, project_name)
        success = flow.run(program_device=program_device, vivado_path=vivado_path)
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()