# HW8 — XADC (Analog-to-Digital Converter)

## Overview

HW8 uses the Xilinx XADC block built into the Artix-7 FPGA to read an analog voltage (0–1V) and display it on the 7-segment display and LED bar graph.

| Task | What it does |
|------|-------------|
| **T1** | Uses the **provided** `xadc_wiz_0.xci` IP from the official Basys3 XADC demo |
| **T2** | **Creates** the `xadc_wiz_0` IP from scratch using Vivado's `create_ip` Tcl command |

Both tasks are functionally identical. The only difference is how the IP is added to the project.

---

## Hardware Setup (same for both tasks)

You need a **potentiometer** wired as a voltage divider to produce 0–1V:

```
3.3V ──┬── [pot outer pin]
       │
       ├── [pot wiper] ──────────── JXADC Pin 1 (vauxp6)
       │
GND  ──┴── [pot outer pin]
GND  ────────────────────────────── JXADC Pin 5 (vauxn6)
```

> **Critical:** The XADC input range is **0–1V max**. Use a 3.3V supply with the pot — the wiper voltage will be somewhere between 0 and 3.3V but you should only rotate it within the 0–1V range to avoid damaging the ADC. Alternatively use a 1V supply.

### Full JXADC pin table

The JXADC header is on the **bottom-left** of the Basys 3 board.

| JXADC Pin | Signal | Connect to |
|-----------|--------|-----------|
| 1 (J3) | vauxp6 | Potentiometer wiper |
| 2 (L3) | vauxp14 | GND |
| 3 (M2) | vauxp7 | GND |
| 4 (N2) | vauxp15 | GND |
| 5 (K3) | vauxn6 | GND |
| 6 (M3) | vauxn14 | GND |
| 7 (M1) | vauxn7 | GND |
| 8 (N1) | vauxn15 | GND |

> Short all unused JXADC pins to GND to prevent floating inputs from adding noise to the ADC result.

### Switch mapping

| `sw[1:0]` | Channel | Physical pin |
|-----------|---------|-------------|
| `00` | vauxp6/n6 | JXADC pin 1 (use this one — pot is here) |
| `01` | vauxp7/n7 | JXADC pin 3 |
| `10` | vauxp14/n14 | JXADC pin 2 |
| `11` | vauxp15/n15 | JXADC pin 4 |

Keep `sw[1:0] = 00` to read from the potentiometer.

---

## Task 1 — Using the Provided IP

### Step 1: Build

From the **repo root** in PowerShell:

```powershell
.\HW8\T1\build.ps1
```

The script generates a Tcl file and runs Vivado in batch mode. It will:
1. Create the Vivado project
2. Add all `.v` source files
3. Add the provided `xadc_wiz_0.xci` IP, upgrade it (to match your Vivado version), synthesize it
4. Run synthesis → implementation → write bitstream

Wait ~10–15 min.

> **Note:** The `.xci` file was originally created in Vivado 2018.2. Running `upgrade_ip` in the build script automatically updates it to 2018.3 so it is no longer "locked."

### Step 2: Program the board

1. Open **Vivado Hardware Manager**
2. Click **Open Target → Auto Connect**
3. Click **Program Device**
4. Bitstream is at:
   ```
   HW8\T1\vivado_project\T1.runs\impl_1\XADCdemo.bit
   ```
5. Click **Program**

### Step 3: Test

| Action | Expected result |
|--------|----------------|
| `sw[1:0] = 00`, rotate pot to 0V | 7-seg shows `0.000`, 1 LED on |
| Rotate pot to midpoint (~0.5V) | 7-seg shows `0.500`, ~8 LEDs on |
| Rotate pot to 1V | 7-seg shows `1.000`, all 16 LEDs on |

The 7-segment display shows voltage in millivolts (e.g. `0500` = 500mV displayed as `0.500`).

---

## Task 2 — Creating the IP from Scratch

### Step 1: Build

From the **repo root** in PowerShell:

```powershell
.\HW8\T2\build.ps1
```

This is identical to T1 but uses `create_ip` in Tcl to generate `xadc_wiz_0` fresh — no `.xci` file needed.

Wait ~10–15 min.

### Step 2: Program the board

Same hardware, same wiring as T1.

1. Open **Vivado Hardware Manager → Auto Connect**
2. Click **Program Device**
3. Bitstream is at:
   ```
   HW8\T2\vivado_project\T2.runs\impl_1\xadc_top.bit
   ```
4. Click **Program**

### Step 3: Test

Same behavior as T1 — rotate the potentiometer and watch the 7-seg and LED bar graph respond.

---

## File Reference

### T1
| File | Purpose |
|------|---------|
| `T1/XADCdemo.v` | Top module (from official demo) — instantiates xadc_wiz_0, drives LEDs and 7-seg |
| `T1/xadc_wiz_0.xci` | Provided XADC IP configuration (Vivado 2018.2 — auto-upgraded on build) |
| `T1/xadc.xdc` | Pin constraints for CLK, sw, led, seg, an, dp, JXADC pins |
| `T1/bin2dec.v` | Converts 16-bit binary ADC value to 4-digit BCD |
| `T1/DigitToSeg.v` | Drives the 4-digit 7-segment display |
| `T1/build.ps1` | Build script |

### T2
| File | Purpose |
|------|---------|
| `T2/xadc_top.v` | Top module (student-created) — functionally identical to XADCdemo.v |
| `T2/xadc.xdc` | Same pin constraints as T1 |
| `T2/build.ps1` | Build script — uses `create_ip` to generate the XADC IP via Tcl |
| *(supporting .v files)* | Same bin2dec, DigitToSeg, etc. as T1 |

---

## Key Concepts for Report

### XADC output format
The XADC returns a **16-bit** result where bits `[15:4]` hold the 12-bit ADC value (left-aligned). Bits `[3:0]` are always zero.

```
data[15:4] = 12-bit ADC result
data[15:8] = top 8 bits (used for LED bar graph)
```

To convert to millivolts: `mV = (data[15:4] / 4096) × 1000`

### LED bar graph logic (from `XADCdemo.v`)
`data[15:12]` (top 4 bits, values 0–15) determines how many LEDs light up:

```verilog
case (data[15:12])
    1:  led <= 16'b11;           // 2 LEDs
    2:  led <= 16'b111;          // 3 LEDs
    ...
    15: led <= 16'b1111111111111111;  // all 16 LEDs
    default: led <= 16'b1;       // 1 LED (0V)
endcase
```

### T1 vs T2 difference
| | T1 | T2 |
|--|----|----|
| IP source | Load from `.xci` file | Create fresh with `create_ip` |
| Tcl command | `add_files xadc_wiz_0.xci` → `upgrade_ip` | `create_ip -name xadc_wiz ...` → `set_property -dict [list CONFIG...]` |
| Top module | `XADCdemo` | `xadc_top` |

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `Cannot change read-only property 'generate_synth_checkpoint'` | IP locked due to Vivado version mismatch | Already fixed — build.ps1 now calls `upgrade_ip` instead |
| `IP 'xadc_wiz_0' is locked` warning | `.xci` from older Vivado | `upgrade_ip` handles this automatically |
| 7-seg stuck at `0.000` | Pot not connected or sw ≠ `00` | Check JXADC pin 1 wiring and set `sw[1:0] = 00` |
| 7-seg shows garbage / flickers | Floating JXADC pins picking up noise | Short all unused JXADC pins (2–4, 6–8) to GND |
| No LEDs change | Pot voltage > 1V — ADC saturated | Reduce voltage; XADC max input is 1V |
| Bitstream not found after build | Synthesis or impl error | Check `HW8\T1\vivado.log` or `HW8\T2\vivado.log` for `ERROR:` lines |
