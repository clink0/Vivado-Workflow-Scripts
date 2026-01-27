# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- SystemVerilog support
- VHDL support
- Web-based simulation viewer
- Docker container support
- CI/CD integration examples

## [1.0.0] - 2026-01-27

### Added
- Initial release of Vivado automation scripts
- `run_simulation_gui.py` - Automated simulation with GUI waveform viewer
- `run_simulation.py` - Automated simulation in batch mode
- `run_hardware.py` - Automated hardware workflow (synthesis to programming)
- Automatic project creation from Verilog files
- Smart detection of design files, testbenches, and constraints
- Support for Basys3 and Arty boards
- Real-time output from Vivado commands
- Comprehensive error handling and reporting
- Detailed documentation and usage examples

### Features
- Zero-configuration workflow
- Automatic waveform viewer opening after simulation
- Fresh project creation for every run
- Configurable simulation time
- Optional device programming (--no-program flag)
- Top module auto-detection
- Support for multi-file projects

### Documentation
- Complete README with examples
- Contributing guidelines
- MIT License
- Troubleshooting guide
- Usage examples for students and engineers

## [0.1.0] - Development

### Added
- Prototype scripts for concept validation
- Basic Tcl generation
- Command-line argument parsing

---

## Release Notes

### v1.0.0 - Initial Release

This is the first public release of Vivado Automation Scripts!

**Key Features:**
- ✨ Automatic project setup from Verilog files
- 🎨 GUI waveform viewer opens automatically after simulation
- 🚀 One-command hardware programming
- 📊 Real-time Vivado output
- 🛡️ Comprehensive error handling

**Who Should Use This:**
- FPGA students learning digital design
- Engineers who want faster iteration
- Anyone tired of clicking through Vivado's GUI
- Teams needing consistent workflows

**Getting Started:**
```bash
git clone https://github.com/yourusername/vivado-automation.git
cd vivado-automation
python run_simulation_gui.py your_project_folder
```

**Known Limitations:**
- Currently supports Verilog only (SystemVerilog and VHDL planned)
- Tested primarily on Linux (Windows testing welcome!)
- Assumes single top module per project

**Feedback Welcome:**
Please report bugs, suggest features, or contribute improvements!

---

[Unreleased]: https://github.com/yourusername/vivado-automation/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/vivado-automation/releases/tag/v1.0.0
[0.1.0]: https://github.com/yourusername/vivado-automation/releases/tag/v0.1.0