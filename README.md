# Vivado Automation Scripts

Two Python scripts to automate Vivado workflows:
1. **Hardware Flow**: Synthesis → Implementation → Bitstream → Program Device
2. **Simulation Flow**: Compile → Elaborate → Simulate → View Waveforms

## Prerequisites

- Python 3.6 or higher
- Xilinx Vivado installed (tested with 2023.x versions)
- Vivado executable in your PATH, or specify the full path in the scripts

## Installation

1. Make the scripts executable:
```bash
chmod +x vivado_hardware_flow.py
chmod +x vivado_simulation_flow.py
```

## Hardware Flow Script

### Basic Usage

```bash
python vivado_hardware_flow.py <project_path> <project_name>
```

### Examples

```bash
# Run full hardware flow including device programming
python vivado_hardware_flow.py ~/fpgaProj my_project

# Run hardware flow without programming the device
python vivado_hardware_flow.py ~/fpgaProj my_project --no-program

# Using absolute path
python vivado_hardware_flow.py /home/username/vivado_projects/my_project my_project
```

### What it does:

1. **Synthesis** - Synthesizes the design
2. **Implementation** - Places and routes the design
3. **Bitstream Generation** - Creates the .bit file
4. **Device Programming** (optional) - Programs the connected FPGA

### Customization

Edit the script to specify a custom Vivado path:
```python
# Line ~175 in vivado_hardware_flow.py
vivado_path = "/tools/Xilinx/Vivado/2023.2/bin/vivado"
```

## Simulation Flow Script

### Basic Usage

```bash
python vivado_simulation_flow.py <project_path> <project_name> [options]
```

### Options

- `--testbench <name>` - Specify the testbench module name
- `--time <duration>` - Set simulation runtime (default: 1000ns)
  - Examples: 100ns, 10us, 1ms, 100ms

### Examples

```bash
# Run simulation with default settings (1000ns)
python vivado_simulation_flow.py ~/fpgaProj my_project

# Specify testbench and simulation time
python vivado_simulation_flow.py ~/fpgaProj my_project --testbench first_system_tb --time 500ns

# Longer simulation
python vivado_simulation_flow.py ~/fpgaProj my_project --testbench test1_tb --time 10us
```

### What it does:

1. **Compilation** - Compiles design and testbench files
2. **Elaboration** - Elaborates the design hierarchy
3. **Simulation** - Runs behavioral simulation for specified time
4. **Waveform** - Saves waveform data (.wdb file)

### Viewing Waveforms

After simulation completes, view waveforms in Vivado GUI:

```bash
vivado -mode gui
# Then: File → Open Waveform Database → select .wdb file
```

Or the script will show you the path to the .wdb files.

## Project Structure Example

Your Vivado project should have this structure:

```
my_project/
├── my_project.xpr           # Vivado project file
├── my_project.srcs/         # Source files
│   ├── sources_1/
│   │   └── new/
│   │       └── module.v
│   └── sim_1/
│       └── new/
│           └── testbench.v
├── my_project.sim/          # Simulation output (generated)
├── my_project.runs/         # Implementation runs (generated)
└── my_project.hw/           # Hardware manager (generated)
```

## Common Issues and Solutions

### Issue: "Vivado executable not found"

**Solution:** Add Vivado to your PATH or specify full path:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH=$PATH:/tools/Xilinx/Vivado/2023.2/bin

# Or specify in script (line ~175 in hardware flow, ~165 in simulation flow)
vivado_path = "/tools/Xilinx/Vivado/2023.2/bin/vivado"
```

### Issue: "Project file not found"

**Solution:** Ensure you're providing the correct paths:
- First argument: Path to the directory containing the .xpr file
- Second argument: Project name WITHOUT the .xpr extension

Example:
```bash
# Correct
python vivado_hardware_flow.py ~/fpgaProj my_project

# Incorrect (don't include .xpr)
python vivado_hardware_flow.py ~/fpgaProj my_project.xpr
```

### Issue: "Could not connect to hardware target"

**Solution:**
- Ensure FPGA board is connected and powered on
- Check USB drivers are installed
- Verify board shows up in Hardware Manager manually first
- Use `--no-program` flag to skip device programming

### Issue: Synthesis or Implementation fails

**Solution:**
- Check the output logs for specific errors
- Fix design errors in Vivado GUI first
- Ensure all constraint files are properly added
- Check for timing violations

## Integrating with Your Workflow

### Method 1: Command Line

Run directly from terminal:
```bash
python vivado_hardware_flow.py ~/fpgaProj my_project
```

### Method 2: Makefile

Create a Makefile in your project directory:

```makefile
PROJECT_PATH = $(shell pwd)
PROJECT_NAME = my_project

.PHONY: hardware sim clean

hardware:
	python vivado_hardware_flow.py $(PROJECT_PATH) $(PROJECT_NAME)

hardware-no-prog:
	python vivado_hardware_flow.py $(PROJECT_PATH) $(PROJECT_NAME) --no-program

sim:
	python vivado_simulation_flow.py $(PROJECT_PATH) $(PROJECT_NAME)

sim-long:
	python vivado_simulation_flow.py $(PROJECT_PATH) $(PROJECT_NAME) --time 10us

clean:
	rm -f run_hardware_flow.tcl run_simulation_flow.tcl
```

Then run:
```bash
make hardware        # Run full hardware flow
make hardware-no-prog  # Hardware flow without programming
make sim            # Run simulation
```

### Method 3: Bash Script

Create a wrapper script `run_fpga.sh`:

```bash
#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_NAME="my_project"

case "$1" in
    hw|hardware)
        python $SCRIPT_DIR/vivado_hardware_flow.py $SCRIPT_DIR $PROJECT_NAME
        ;;
    sim|simulation)
        python $SCRIPT_DIR/vivado_simulation_flow.py $SCRIPT_DIR $PROJECT_NAME "${@:2}"
        ;;
    *)
        echo "Usage: $0 {hardware|simulation} [sim options]"
        echo "Examples:"
        echo "  $0 hardware"
        echo "  $0 simulation --testbench tb_top --time 5us"
        exit 1
        ;;
esac
```

Make it executable and use:
```bash
chmod +x run_fpga.sh
./run_fpga.sh hardware
./run_fpga.sh simulation --time 5us
```

## Advanced Features

### Modifying the Hardware Flow

Edit `vivado_hardware_flow.py` to add custom steps:

```python
# Add before bitstream generation (around line 70):
tcl_commands += """
# Generate timing reports
open_run impl_1
report_timing_summary -file timing_summary.rpt
report_utilization -file utilization.rpt
"""
```

### Modifying the Simulation Flow

Edit `vivado_simulation_flow.py` to add waveform configuration:

```python
# Add after launching simulation (around line 85):
tcl_commands += """
# Add all signals to waveform
add_wave /*

# Configure waveform display
set_property display_name "Clock" [get_waves clk]
```
```

## Tips for Your Lab Work

Based on your project files (dataflow, structural, behavioral modeling), here's how to use these scripts:

### For Week 1 Labs (Modeling Methods):

```bash
# Test dataflow modeling
python vivado_simulation_flow.py ~/fpgaProj first_system --testbench first_system_tb --time 400ns

# Test structural modeling
python vivado_simulation_flow.py ~/fpgaProj first_system --testbench first_system_tb --time 400ns

# Test behavioral modeling
python vivado_simulation_flow.py ~/fpgaProj first_system --testbench first_system_tb --time 400ns
```

### For Lab 3 (Seven Segment Display):

```bash
# Run simulation first to verify logic
python vivado_simulation_flow.py ~/fpgaProj ssd_project --testbench ssd_tb --time 1ms

# Then program the hardware
python vivado_hardware_flow.py ~/fpgaProj ssd_project
```

## Troubleshooting Checklist

- [ ] Vivado is installed and in PATH
- [ ] Project file (.xpr) exists
- [ ] All source files are added to the project
- [ ] Constraint file is added (for hardware flow)
- [ ] Testbench is added to sim_1 fileset (for simulation)
- [ ] FPGA board is connected and powered (for programming)
- [ ] Python 3.6+ is installed

## Additional Resources

- [Vivado Tcl Command Reference](https://docs.xilinx.com/r/en-US/ug835-vivado-tcl-commands)
- [Vivado Design Suite User Guide](https://docs.xilinx.com/v/u/en-US/ug893-vivado-ide)
- [Basys3 Reference Manual](https://digilent.com/reference/programmable-logic/basys-3/reference-manual)

## License

These scripts are provided as-is for educational purposes.# Vivado-Workflow-Scripts
