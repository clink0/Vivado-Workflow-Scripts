# CE433 Course Project — Pulse Sensor ASIC Design

## Overview

| Task | Points | What it does |
|------|--------|--------------|
| T1 | 50 | Pmod OLED on Basys3 — static text display, no Picoblaze |
| T2 | 50 | Picoblaze reads XADC (analog input on JXADC), shows binary on LEDs |
| T3 | 50 | Picoblaze measures BPM from Arduino pulse on JC, displays on OLED; UART streams raw waveform to PC |

---

## Prerequisites

- **Vivado 2018.3** installed at `C:\Xilinx\Vivado\2018.3\`
- **kcpsm6 assembler** at `Lab8\kcpsm6_files\kcpsm6.exe` (Tasks 2 and 3 only)
- **Python 3** with `pyserial` and `matplotlib` (Task 3 waveform viewer only)
- Basys3 board connected via USB

Install Python dependencies (one time, Task 3 only):

```powershell
pip install pyserial matplotlib
```

---

## Hardware Connections

### Task 1
| Signal | Basys3 Connector | Pin |
|--------|-----------------|-----|
| CS     | JB1             | A14 |
| SDIN   | JB2             | A16 |
| SCLK   | JB4             | B16 |
| DC     | JB7             | A15 |
| RES    | JB8             | A17 |
| VBAT   | JB9             | C15 |
| VDD    | JB10            | C16 |

Plug the Pmod OLED into the **upper row of JB** (pins 1–6) and **lower row** (pins 7–12).

### Task 2
Same OLED connection as Task 1 is **not required** for T2. T2 only needs:

| Signal | Basys3 Connector | Pin |
|--------|-----------------|-----|
| Analog+ (from Arduino/sensor) | JXADC XA1_P | J3 |
| Analog− | JXADC XA1_N | K3 |

JXADC is the 12-pin analog header directly below JA on the Basys3.

### Task 3
| Signal | Basys3 Connector | Pin |
|--------|-----------------|-----|
| CS     | JB1             | A14 |
| SDIN   | JB2             | A16 |
| SCLK   | JB4             | B16 |
| DC     | JB7             | A15 |
| RES    | JB8             | A17 |
| VBAT   | JB9             | C15 |
| VDD    | JB10            | C16 |
| Analog+ | JXADC XA1_P   | J3  |
| Analog− | JXADC XA1_N   | K3  |
| Arduino digital pulse | JC1 | K17 |

The Arduino connects to **JC pin 1** (top-left pin of JC). Make sure the Arduino and Basys3 share a common ground.

---

## Task 1 — Build and Program

All commands run from the **repo root** (`Vivado-Workflow-Scripts\`).

### Step 1 — Build (synthesize, implement, generate bitstream)

```powershell
.\CourseProject\T1\build.ps1
```

This takes several minutes. When it finishes you will see:

```
Bitstream: CourseProject\T1\vivado_project\CP_T1.runs\impl_1\cp_t1_top.bit
```

### Step 2 — Program the FPGA

```powershell
$bit = (Resolve-Path "CourseProject\T1\vivado_project\CP_T1.runs\impl_1\cp_t1_top.bit").Path
@"
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set_property PROGRAM.FILE {$bit} [current_hw_device]
program_hw_devices [current_hw_device]
disconnect_hw_server
"@ | Out-File -FilePath "CourseProject\T1\program.tcl" -Encoding ASCII
& "C:\Xilinx\Vivado\2018.3\bin\vivado.bat" -mode batch -source "CourseProject\T1\program.tcl" -log "CourseProject\T1\program.log" -journal "CourseProject\T1\program.jou"
```

### Expected result

The OLED displays:
```
HELLO  BASYS3!
SSD1306  128x32
 PMOD OLED DEMO
  CE433  2026
```

Press **btnC** to reset and restart the init sequence.

---

## Task 2 — Build and Program

### Step 1 — Build

```powershell
.\CourseProject\T2\build.ps1
```

When it finishes:

```
Bitstream: CourseProject\T2\vivado_project\CP_T2.runs\impl_1\cp_t2_top.bit
```

### Step 2 — Program the FPGA

```powershell
$bit = (Resolve-Path "CourseProject\T2\vivado_project\CP_T2.runs\impl_1\cp_t2_top.bit").Path
@"
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set_property PROGRAM.FILE {$bit} [current_hw_device]
program_hw_devices [current_hw_device]
disconnect_hw_server
"@ | Out-File -FilePath "CourseProject\T2\program.tcl" -Encoding ASCII
& "C:\Xilinx\Vivado\2018.3\bin\vivado.bat" -mode batch -source "CourseProject\T2\program.tcl" -log "CourseProject\T2\program.log" -journal "CourseProject\T2\program.jou"
```

### Expected result

`led[7:0]` shows the 8 MSBs of the XADC reading as binary. With no signal connected the LEDs will sit near 0. Applying a voltage on JXADC XA1_P (0–1 V range, referenced to XA1_N) drives the LEDs proportionally. Press **btnC** to reset.

---

## Task 3 — Build, Program, and Run Waveform

### Step 1 — Build

```powershell
.\CourseProject\T3\build.ps1
```

When it finishes:

```
Bitstream: CourseProject\T3\vivado_project\CP_T3.runs\impl_1\cp_t3_top.bit
```

### Step 2 — Program the FPGA

```powershell
$bit = (Resolve-Path "CourseProject\T3\vivado_project\CP_T3.runs\impl_1\cp_t3_top.bit").Path
@"
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set_property PROGRAM.FILE {$bit} [current_hw_device]
program_hw_devices [current_hw_device]
disconnect_hw_server
"@ | Out-File -FilePath "CourseProject\T3\program.tcl" -Encoding ASCII
& "C:\Xilinx\Vivado\2018.3\bin\vivado.bat" -mode batch -source "CourseProject\T3\program.tcl" -log "CourseProject\T3\program.log" -journal "CourseProject\T3\program.jou"
```

### Step 3 — Find the Basys3 COM port

Open Device Manager → Ports (COM & LPT). Look for **USB Serial Port** or **Digilent USB Device**. Note the COM number (e.g. `COM4`).

PowerShell shortcut to list ports:

```powershell
[System.IO.Ports.SerialPort]::GetPortNames()
```

### Step 4 — Run the real-time waveform plot

```powershell
python CourseProject\T3\plot_waveform.py COM4
```

Replace `COM4` with your actual port. A live plot window opens showing the raw analog waveform from JXADC at ~1 kSPS. Close the window to stop.

### Expected result

- **OLED** displays `  BPM:  --  BPM` initially, then updates with the measured heart rate (e.g. `  BPM:  72  BPM`) once the Arduino begins sending pulses.
- **led[7:0]** shows the raw XADC value for debugging.
- **Waveform plot** shows the live analog signal on JXADC.
- Press **btnC** to reset everything.

---

## Rebuilding after changes

If you edit a `.psm` file (Tasks 2 or 3), re-run the build script — it re-assembles the PSM and re-runs Vivado automatically.

If you only edit a `.v` file, re-run the build script — Vivado will re-synthesize from scratch (the `-force` flag on `create_project` rebuilds the project each time).

---

## File structure

```
CourseProject/
├── README.md               ← this file
├── T1/
│   ├── cp_t1_top.v         top module
│   ├── OledEX.v            character display FSM
│   ├── OledInit.v          SSD1306 power-up sequence
│   ├── OledSPI.v           4-wire SPI byte transmitter
│   ├── charLib.v           8x8 font BRAM
│   ├── constraints.xdc     pin assignments (JB OLED)
│   └── build.ps1           build script
├── T2/
│   ├── cp_t2_top.v         top module (XADC + Picoblaze)
│   ├── prog.psm            Picoblaze assembly
│   ├── constraints.xdc     pin assignments (JXADC, LEDs)
│   └── build.ps1           build script (assembles PSM then Vivado)
└── T3/
    ├── cp_t3_top.v         top module (XADC + Picoblaze + OLED + UART)
    ├── OledEX_t3.v         OLED driver with live BPM digits
    ├── OledInit.v
    ├── OledSPI.v
    ├── charLib.v
    ├── uart_tx.v           8N1 UART transmitter (115200 baud)
    ├── prog.psm            Picoblaze BPM algorithm
    ├── constraints.xdc     pin assignments (JB, JXADC, JC1, UART)
    ├── build.ps1           build script
    └── plot_waveform.py    PC-side live waveform viewer
```
