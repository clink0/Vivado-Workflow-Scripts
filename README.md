# Vivado Automation Scripts

**The simplest way to go from Verilog code to working FPGA hardware**

Stop clicking through Vivado's GUI. Just write your `.v` files and run one command to simulate or program your FPGA.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.6+](https://img.shields.io/badge/python-3.6+-blue.svg)](https://www.python.org/downloads/)

## 🎯 What This Does

These Python scripts automate the entire Vivado workflow:

- **Simulation**: Auto-creates project → Runs simulation → **Opens waveform viewer**
- **Hardware**: Auto-creates project → Synthesis → Implementation → Bitstream → **Programs FPGA**

No manual project setup. No GUI clicking. Just code and results.

## ✨ Features

- 🚀 **Zero configuration** - Just point to a folder with `.v` files
- 🔄 **Fresh projects every time** - No stale configurations or conflicts
- 🎨 **Automatic waveform viewing** - Simulation plots open in GUI automatically
- 🎯 **Smart file detection** - Automatically finds design files, testbenches, and constraints
- ⚡ **Fast iteration** - Modify code, run script, see results
- 📊 **Real-time output** - See Vivado's progress as it runs
- 🛡️ **Error handling** - Clear messages when things go wrong

## 🚀 Quick Start

### Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/vivado-automation.git
cd vivado-automation
```

2. Add your constraint file to the project root:
```bash
# Copy your Basys3 (or other board) constraint file here
cp ~/Downloads/Basys3_Master.xdc .

# Verify it's there
ls *.xdc
```

3. Make scripts executable:
```bash
chmod +x run_simulation.py run_hardware.py
```

4. (Optional) Copy to your PATH for easy access:
```bash
cp run_simulation.py run_simulation.py run_hardware.py ~/.local/bin/
```

### Your First Simulation

1. Create a folder with your Verilog files:
```
my_project/
├── my_design.v          # Your design module
└── my_design_tb.v       # Your testbench (must end with _tb)
```

**Note:** No need to add a constraint file - the scripts use the shared one!

2. Run simulation:
```bash
python run_simulation.py my_project
```

3. The waveform viewer opens automatically! 🎉

### Program Your FPGA

The script automatically uses the constraint file from the project root:

```bash
python run_hardware.py my_project
```

Your design is now running on the FPGA! 🚀

**See [CONSTRAINT_SETUP.md](CONSTRAINT_SETUP.md) for details on the single constraint file approach.**

## 📚 Documentation

### Simulation Script

```bash
python run_simulation.py <directory> [options]
```

**Options:**
- `--time <duration>` - Simulation time (default: 1000ns)
  - Examples: `100ns`, `10us`, `1ms`
- `--no-gui` - Run in batch mode without opening waveform viewer
- `--board <name>` - Target board (default: basys3)

**Examples:**

```bash
# Run simulation with automatic waveform viewer
python run_simulation.py .

# Custom simulation time
python run_simulation.py . --time 5us

# Batch mode (no GUI)
python run_simulation.py . --no-gui

# Simulate code in another directory
python run_simulation.py ~/fpga_projects/lab3 --time 2ms
```

### Hardware Script

```bash
python run_hardware.py <directory> [options]
```

**Options:**
- `--no-program` - Generate bitstream but don't program device
- `--board <name>` - Target board (default: basys3)

**Examples:**

```bash
# Full flow: synthesize, implement, program FPGA
python run_hardware.py .

# Generate bitstream without programming
python run_hardware.py . --no-program

# Program a different board
python run_hardware.py . --board arty
```

## 📁 Project Structure

### Repository Layout

```
vivado-automation/
├── run_simulation.py     # Simulation with GUI
├── run_simulation.py         # Simulation batch mode
├── run_hardware.py           # Hardware flow
├── Basys3_Master.xdc         # Your constraint file (shared!)
├── README.md
└── your_projects/            # Your Verilog projects
    ├── lab1/
    │   ├── design.v
    │   └── design_tb.v
    └── lab2/
        ├── design.v
        └── design_tb.v
```

**Key Point:** The constraint file lives at the **project root** and is shared by all projects!

### Individual Project Folders

Your project folder should contain:

**Required Files**

**Design files** (`.v` files):
- `my_module.v`
- `submodule.v`
- `top_module.v`

**Testbench files** (must contain `_tb`, `_test`, or `testbench`):
- ✅ `my_module_tb.v`
- ✅ `testbench.v`
- ✅ `my_test.v`
- ❌ `my_module.v` (won't be recognized as testbench)

**Constraint files** *(optional - uses shared file by default)*:
- `*.xdc` - Only add if you need project-specific constraints
- Otherwise, the script uses the shared file at the project root

### Example Structure

```
alarm_system/
├── alarm_top.v              # Design files
├── sensor_module.v
├── alarm_controller.v
└── alarm_tb.v               # Testbench
                             # No .xdc needed!
```

Run with:
```bash
cd alarm_system
python ../run_simulation.py .     # Simulate
python ../run_hardware.py .           # Program FPGA (uses shared .xdc)
```

**See [CONSTRAINT_SETUP.md](CONSTRAINT_SETUP.md) for complete details on the single constraint file setup.**

## 🎓 Usage Examples

### Example 1: Seven-Segment Display

```bash
cd lab3_seven_segment

# Files in directory:
# - ssd_display.v
# - ssd_decoder.v  
# - ssd_display_tb.v
# - Basys3_Master.xdc

# Test with simulation
python run_simulation.py . --time 2ms

# Waveform viewer opens, verify the display patterns
# Close Vivado when satisfied

# Program the FPGA
python run_hardware.py .

# Seven-segment display now shows your pattern!
```

### Example 2: Comparing Design Approaches

Testing different modeling styles (structural, dataflow, behavioral):

```bash
# Test dataflow version
cd dataflow_version
python run_simulation.py . --time 400ns

# Test structural version
cd ../structural_version  
python run_simulation.py . --time 400ns

# Test behavioral version
cd ../behavioral_version
python run_simulation.py . --time 400ns

# Pick the best one and program it
cd ../dataflow_version
python run_hardware.py .
```

### Example 3: Rapid Prototyping

```bash
# Quick edit-test-debug cycle
vim my_design.v                              # Edit design
python run_simulation.py . --time 1us    # Test (GUI opens)
# See issue in waveforms, close Vivado
vim my_design.v                              # Fix issue
python run_simulation.py . --time 1us    # Test again
# Looks good!
python run_hardware.py .                     # Deploy to FPGA
```

## 🔧 Advanced Usage

### Create Aliases for Faster Workflow

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias vsim='python ~/path/to/run_simulation.py'
alias vhw='python ~/path/to/run_hardware.py'
```

Then use:
```bash
cd my_project
vsim . --time 500ns    # Simulate
vhw .                  # Program FPGA
```

### Makefile Integration

Create a `Makefile` in your project:

```makefile
.PHONY: sim hw clean

sim:
	python ~/scripts/run_simulation.py . --time 1us

hw:
	python ~/scripts/run_hardware.py .

hw-no-prog:
	python ~/scripts/run_hardware.py . --no-program

clean:
	rm -rf vivado_project/ *.tcl *.log *.jou
```

Use with:
```bash
make sim    # Simulate
make hw     # Program FPGA
make clean  # Clean up
```

### Custom Vivado Installation Path

If Vivado is not in your PATH, edit the scripts:

```python
# Near the end of main() in both scripts
# Change this line:
vivado_path = "vivado"

# To your installation path:
vivado_path = "/tools/Xilinx/Vivado/2023.2/bin/vivado"
```

### Adding More Boards

Edit the `board_configs` dictionary in either script:

```python
board_configs = {
    "basys3": {
        "part": "xc7a35tcpg236-1",
        "board_part": "digilentinc.com:basys3:part0:1.2"
    },
    "arty": {
        "part": "xc7a35ticsg324-1L",
        "board_part": "digilentinc.com:arty-a7-35:part0:1.1"
    },
    "your_board": {
        "part": "xc7a100tcsg324-1",
        "board_part": "xilinx.com:yourboard:part0:1.0"
    }
}
```

## 🛠️ Troubleshooting

### "Vivado executable not found"

**Solution:** Add Vivado to your PATH or specify the full path in the scripts.

```bash
# Add to ~/.bashrc
export PATH=$PATH:/tools/Xilinx/Vivado/2023.2/bin
```

### "No Verilog design files found"

**Solution:** Ensure `.v` files are in the directory you're pointing to.

```bash
# Check what files exist
ls *.v

# Make sure you're in the right directory
pwd
```

### "No testbench files found"

**Solution:** Testbench filename must contain `_tb`, `_test`, or `testbench`.

```bash
# ❌ Wrong
test.v
my_module.v

# ✅ Correct
my_module_tb.v
testbench.v
test_bench.v
```

### "Could not connect to hardware target"

**Solutions:**
- Ensure FPGA board is connected via USB and powered on
- Check that USB drivers are installed (Digilent Adept for Digilent boards)
- Verify the board appears in Vivado Hardware Manager manually first
- Use `--no-program` flag to just generate bitstream

### GUI doesn't open (Linux)

**Solution:** Ensure X11 is working:

```bash
# Test X11
xeyes

# If SSH, enable X11 forwarding
ssh -X user@host

# Or use VNC/X2Go for remote desktop
```

## 🎯 Perfect For

- ✅ **Students** - Focus on Verilog, not tool mechanics
- ✅ **Lab assignments** - Quick iteration and testing
- ✅ **Rapid prototyping** - Edit, test, deploy cycle
- ✅ **Learning FPGA design** - Immediate visual feedback
- ✅ **Team projects** - Consistent workflow for all members

## 📋 Requirements

- Python 3.6 or higher
- Xilinx Vivado (tested with 2023.x, should work with 2022.x+)
- FPGA development board (for hardware programming)
  - Basys3 (default)
  - Arty A7
  - Other Xilinx FPGA boards (with configuration)

## 🤝 Contributing

Contributions are welcome! Here are some ways you can help:

- 🐛 Report bugs or issues
- 💡 Suggest new features
- 📝 Improve documentation
- 🔧 Add support for more boards
- ⭐ Star this repo if you find it useful!

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test with your Vivado installation
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License

## 🙏 Acknowledgments

- Created to simplify the FPGA development workflow for students and engineers
- Inspired by the need for faster iteration in digital design education
- Special thanks to the Vivado Tcl scripting documentation

## 📧 Support

- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/vivado-automation/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/vivado-automation/discussions)
- 📖 Documentation: See `docs/` folder for detailed guides

## 🌟 Star History

If this project helped you, please consider giving it a star! ⭐


---

**Made with ❤️ for the FPGA community**

From Verilog to working hardware in one command. That's the dream. 🚀