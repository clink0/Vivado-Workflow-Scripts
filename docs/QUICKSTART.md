# Quick Start Tutorial

Get up and running with Vivado Automation Scripts in 5 minutes!

## 📦 Step 1: Get the Scripts

```bash
# Clone the repository
git clone https://github.com/yourusername/vivado-automation.git
cd vivado-automation

# Make scripts executable
chmod +x run_simulation_gui.py run_hardware.py

# (Optional) Add to PATH
echo 'export PATH="$PATH:$HOME/vivado-automation"' >> ~/.bashrc
source ~/.bashrc
```

## 🎯 Step 2: Create Your First Project

Let's create a simple AND gate project to test everything:

```bash
# Create project directory
mkdir -p ~/fpga_test/simple_and
cd ~/fpga_test/simple_and
```

### Create the Design File

Create `and_gate.v`:
```verilog
module and_gate(
    input a,
    input b,
    output y
);
    assign y = a & b;
endmodule
```

### Create the Testbench

Create `and_gate_tb.v`:
```verilog
`timescale 1ns / 1ps

module and_gate_tb;
    // Inputs
    reg a;
    reg b;
    
    // Outputs
    wire y;
    
    // Instantiate the Unit Under Test (UUT)
    and_gate uut (
        .a(a),
        .b(b),
        .y(y)
    );
    
    // Test stimulus
    initial begin
        // Initialize
        a = 0;
        b = 0;
        
        // Test all combinations
        #10 a = 0; b = 0;  // Expected: y = 0
        #10 a = 0; b = 1;  // Expected: y = 0
        #10 a = 1; b = 0;  // Expected: y = 0
        #10 a = 1; b = 1;  // Expected: y = 1
        
        // Finish simulation
        #10 $finish;
    end
    
    // Monitor outputs
    initial begin
        $monitor("Time=%0t a=%b b=%b y=%b", $time, a, b, y);
    end
endmodule
```

## 🧪 Step 3: Run Your First Simulation

```bash
# Make sure you're in the project directory
cd ~/fpga_test/simple_and

# Run simulation (waveform viewer opens automatically!)
python ~/vivado-automation/run_simulation_gui.py . --time 50ns
```

**What happens:**
1. Script creates Vivado project automatically
2. Adds your `.v` files
3. Runs simulation for 50ns
4. **Vivado GUI opens with waveforms** ✨
5. You can see the AND gate behavior in the waveform!

**In the waveform viewer, you should see:**
- `a` and `b` toggling through all 4 combinations
- `y` is high only when both `a` and `b` are high

Close Vivado when you're done viewing.

## 🎨 Step 4: Test on Real Hardware (Optional)

If you have a Basys3 board:

### Create Constraint File

Create `Basys3_simple.xdc`:
```tcl
## Switches
set_property PACKAGE_PIN V17 [get_ports {a}]
    set_property IOSTANDARD LVCMOS33 [get_ports {a}]
set_property PACKAGE_PIN V16 [get_ports {b}]
    set_property IOSTANDARD LVCMOS33 [get_ports {b}]

## LEDs
set_property PACKAGE_PIN U16 [get_ports {y}]
    set_property IOSTANDARD LVCMOS33 [get_ports {y}]
```

### Program the FPGA

```bash
# Generate bitstream and program
python ~/vivado-automation/run_hardware.py .

# The LED will turn on only when both switches are up!
```

**What happens:**
1. Script creates project
2. Runs synthesis
3. Runs implementation
4. Generates bitstream
5. **Programs your FPGA** 🎉

**Test it:**
- Flip switch 0 (a) and switch 1 (b) on the Basys3
- LED 0 lights up only when BOTH switches are up
- It's a working AND gate!

## 🎓 Step 5: Try Something More Complex

Let's create a 4-bit adder:

```bash
mkdir ~/fpga_test/adder
cd ~/fpga_test/adder
```

Create `adder.v`:
```verilog
module adder(
    input [3:0] a,
    input [3:0] b,
    output [4:0] sum
);
    assign sum = a + b;
endmodule
```

Create `adder_tb.v`:
```verilog
`timescale 1ns / 1ps

module adder_tb;
    reg [3:0] a, b;
    wire [4:0] sum;
    
    adder uut (.a(a), .b(b), .sum(sum));
    
    initial begin
        a = 4'd0; b = 4'd0;
        #10 a = 4'd3; b = 4'd5;   // 3 + 5 = 8
        #10 a = 4'd7; b = 4'd9;   // 7 + 9 = 16
        #10 a = 4'd15; b = 4'd1;  // 15 + 1 = 16
        #10 a = 4'd15; b = 4'd15; // 15 + 15 = 30
        #10 $finish;
    end
    
    initial begin
        $monitor("Time=%0t a=%d b=%d sum=%d", $time, a, b, sum);
    end
endmodule
```

Run simulation:
```bash
python ~/vivado-automation/run_simulation_gui.py . --time 60ns
```

Watch the addition happen in real-time in the waveform viewer!

## 💡 Pro Tips

### Tip 1: Use Aliases

Add to `~/.bashrc`:
```bash
alias vsim='python ~/vivado-automation/run_simulation_gui.py'
alias vhw='python ~/vivado-automation/run_hardware.py'
```

Then just:
```bash
vsim . --time 100ns
vhw .
```

### Tip 2: File Organization

Keep your projects organized:
```
fpga_projects/
├── lab1_gates/
│   ├── and_gate.v
│   └── and_gate_tb.v
├── lab2_adder/
│   ├── adder.v
│   ├── adder_tb.v
│   └── Basys3.xdc
└── lab3_display/
    ├── display.v
    ├── display_tb.v
    └── Basys3.xdc
```

### Tip 3: Quick Testing Workflow

```bash
# Edit → Test → Repeat
vim my_design.v
vsim . --time 1us
# See issue in waveforms
vim my_design.v
vsim . --time 1us
# Looks good!
vhw .
```

### Tip 4: Batch Mode for Quick Checks

```bash
# Just verify it compiles, no GUI
python run_simulation_gui.py . --no-gui --time 100ns
```

## 🎯 Common First-Time Issues

### "No testbench files found"

**Problem:** Testbench must have `_tb`, `_test`, or `testbench` in filename

**Fix:**
```bash
# Wrong
mv test.v test_tb.v

# Or
mv my_test.v my_module_tb.v
```

### "Vivado not found"

**Problem:** Vivado not in PATH

**Fix:**
```bash
# Add to ~/.bashrc
export PATH=$PATH:/tools/Xilinx/Vivado/2023.2/bin
source ~/.bashrc
```

### GUI doesn't open

**Problem:** X11 not configured (Linux SSH)

**Fix:**
```bash
# Enable X11 forwarding
ssh -X user@host

# Or use --no-gui mode
vsim . --no-gui
```

## 🎉 Next Steps

Now that you've got the basics:

1. ✅ You know how to simulate
2. ✅ You know how to program hardware
3. ✅ You understand the file structure

**Ready for more?**
- Try your actual course assignments
- Build more complex designs
- Experiment with state machines
- Create your own projects!

## 📚 Learn More

- **Full Documentation**: See [README.md](README.md)
- **All Options**: Check `--help` on each script
- **Examples**: See `examples/` directory
- **Troubleshooting**: See [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

## 🚀 You're All Set!

From zero to working FPGA in 5 minutes. That's the power of automation! 

Happy coding! 🎉

---

**Questions?** Open an issue or discussion on GitHub!