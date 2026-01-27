#!/usr/bin/env python3
"""
Vivado Simulation Workflow Automation Script
Automates: Compilation -> Elaboration -> Simulation -> Waveform viewing
"""

import subprocess
import sys
import os
from pathlib import Path

class VivadoSimulationFlow:
    def __init__(self, project_path, project_name, testbench=""):
        """
        Initialize the Vivado simulation flow automation
        
        Args:
            project_path: Path to the Vivado project directory
            project_name: Name of the Vivado project (without .xpr extension)
            testbench: Name of the testbench module (optional, will use default sim set)
        """
        self.project_path = Path(project_path).resolve()
        self.project_name = project_name
        self.project_file = self.project_path / f"{project_name}.xpr"
        self.testbench = testbench
        
        # Check if project exists
        if not self.project_file.exists():
            raise FileNotFoundError(f"Project file not found: {self.project_file}")
    
    def create_tcl_script(self, sim_time="1000ns", open_waveform=True):
        """
        Create a Tcl script for Vivado simulation automation
        
        Args:
            sim_time: Simulation runtime (e.g., "1000ns", "10us", "1ms")
            open_waveform: Whether to open the waveform viewer after simulation
        """
        tcl_commands = f"""
# Open the project
open_project {{{self.project_file}}}

puts "========================================="
puts "Starting Simulation Flow..."
puts "========================================="

# Set the simulation fileset as current
current_fileset -simset [get_filesets sim_1]

"""
        
        if self.testbench:
            tcl_commands += f"""
# Set top module for simulation
set_property top {self.testbench} [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
"""
        
        tcl_commands += """
# Update compile order
update_compile_order -fileset sim_1

# Launch simulation
puts "========================================="
puts "Launching Behavioral Simulation..."
puts "========================================="

# Launch simulation
launch_simulation -mode behavioral

"""
        
        tcl_commands += f"""
# Run simulation for specified time
puts "Running simulation for {sim_time}..."
run {sim_time}

# Check if simulation completed successfully
set sim_status [current_sim]
if {{$sim_status == ""}} {{
    puts "ERROR: Simulation failed to run"
    exit 1
}}

puts "Simulation completed successfully"

"""
        
        if open_waveform:
            tcl_commands += """
# Save waveform
puts "Saving waveform data..."
save_wave_config

"""
        
        tcl_commands += """
# Close simulation
close_sim

# Close project
close_project

puts "========================================="
puts "Simulation flow completed successfully!"
puts "========================================="
exit 0
"""
        
        tcl_file = self.project_path / "run_simulation_flow.tcl"
        with open(tcl_file, 'w') as f:
            f.write(tcl_commands)
        
        return tcl_file
    
    def run(self, sim_time="1000ns", open_waveform=True, vivado_path="vivado"):
        """
        Execute the simulation flow
        
        Args:
            sim_time: Simulation runtime (e.g., "1000ns", "10us", "1ms")
            open_waveform: Whether to open the waveform viewer after simulation
            vivado_path: Path to Vivado executable (default: "vivado" from PATH)
        """
        print(f"Starting Vivado Simulation Flow for project: {self.project_name}")
        print(f"Project location: {self.project_path}")
        if self.testbench:
            print(f"Testbench: {self.testbench}")
        print(f"Simulation time: {sim_time}")
        print("=" * 60)
        
        # Create the Tcl script
        tcl_file = self.create_tcl_script(sim_time, open_waveform)
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
                print("SUCCESS: Simulation flow completed successfully!")
                print("=" * 60)
                
                # Show where to find results
                sim_dir = self.project_path / f"{self.project_name}.sim" / "sim_1" / "behav" / "xsim"
                if sim_dir.exists():
                    print(f"\nSimulation results location:")
                    print(f"  {sim_dir}")
                    
                    wdb_files = list(sim_dir.glob("*.wdb"))
                    if wdb_files:
                        print(f"\nWaveform database files:")
                        for wdb in wdb_files:
                            print(f"  {wdb}")
                        print(f"\nTo view waveforms, run:")
                        print(f"  vivado -mode gui")
                        print(f"  Then: File -> Open Waveform Database -> select .wdb file")
                
                return True
            else:
                print("\n" + "=" * 60)
                print(f"ERROR: Simulation flow failed with return code {return_code}")
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
    
    if len(sys.argv) < 3:
        print("Usage: python vivado_simulation_flow.py <project_path> <project_name> [options]")
        print("\nOptions:")
        print("  --testbench <name>    Specify testbench module name")
        print("  --time <duration>     Simulation runtime (default: 1000ns)")
        print("                        Examples: 100ns, 10us, 1ms")
        print("\nExamples:")
        print("  python vivado_simulation_flow.py /path/to/project my_project")
        print("  python vivado_simulation_flow.py /path/to/project my_project --testbench test1_tb --time 5us")
        sys.exit(1)
    
    project_path = sys.argv[1]
    project_name = sys.argv[2]
    
    # Parse optional arguments
    testbench = ""
    sim_time = "1000ns"
    
    i = 3
    while i < len(sys.argv):
        if sys.argv[i] == "--testbench" and i + 1 < len(sys.argv):
            testbench = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--time" and i + 1 < len(sys.argv):
            sim_time = sys.argv[i + 1]
            i += 2
        else:
            print(f"Warning: Unknown argument '{sys.argv[i]}', ignoring...")
            i += 1
    
    # Optional: specify custom Vivado path
    # vivado_path = "/tools/Xilinx/Vivado/2023.2/bin/vivado"
    vivado_path = "vivado"  # Use PATH by default
    
    try:
        flow = VivadoSimulationFlow(project_path, project_name, testbench)
        success = flow.run(sim_time=sim_time, vivado_path=vivado_path)
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()